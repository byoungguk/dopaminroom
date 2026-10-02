# -*- coding: utf-8 -*-
"""
도파민 사이트 관리 페이지.

동작 방식
  - content/site.json 과 public/images/gallery 를 직접 읽고 쓴다.
  - 저장하면 /state/rebuild.request 파일을 남긴다.
    호스트의 감시 스크립트가 이 파일을 보고 사이트를 다시 빌드한다.
    (관리 컨테이너에 도커 권한을 주지 않기 위한 구조다)

보안
  - 비밀번호는 환경변수 ADMIN_PASSWORD 로 주입한다.
  - 로그인 시도 횟수를 제한한다.
  - https 적용 전에는 비밀번호가 네트워크에 노출될 수 있다.
"""
import datetime
import hmac
import io
import json
import os
import re
import secrets
import tarfile
import time
from functools import wraps

from flask import (Flask, abort, flash, redirect, render_template, request,
                   send_file, send_from_directory, session, url_for)
from werkzeug.utils import secure_filename

DATA_FILE = os.environ.get("DATA_FILE", "/data/site.json")
GALLERY_DIR = os.environ.get("GALLERY_DIR", "/gallery")
STATE_DIR = os.environ.get("STATE_DIR", "/state")
BACKUP_DIR = os.path.join(STATE_DIR, "backups")
USERNAME = os.environ.get("ADMIN_USER", "admin")
PASSWORD = os.environ.get("ADMIN_PASSWORD", "")
MAX_UPLOAD_MB = int(os.environ.get("MAX_UPLOAD_MB", "20"))

ALLOWED_EXT = {".webp", ".jpg", ".jpeg", ".png", ".avif"}

app = Flask(__name__)


class PrefixMiddleware:
    """nginx 가 /admin/ 을 떼고 넘겨주므로, 앱이 만드는 주소에 다시 붙여준다.
    이 처리가 없으면 화면 안의 링크가 /prices 처럼 만들어져
    관리 페이지가 아니라 사이트 본문으로 이동한다."""

    def __init__(self, wsgi_app):
        self.wsgi_app = wsgi_app

    def __call__(self, environ, start_response):
        prefix = environ.get("HTTP_X_FORWARDED_PREFIX", "")
        if prefix:
            environ["SCRIPT_NAME"] = "/" + prefix.strip("/")
        return self.wsgi_app(environ, start_response)


app.wsgi_app = PrefixMiddleware(app.wsgi_app)
app.secret_key = os.environ.get("SECRET_KEY") or secrets.token_hex(32)
app.config["MAX_CONTENT_LENGTH"] = MAX_UPLOAD_MB * 1024 * 1024
app.config["SESSION_COOKIE_HTTPONLY"] = True
app.config["SESSION_COOKIE_SAMESITE"] = "Lax"

os.makedirs(STATE_DIR, exist_ok=True)
os.makedirs(BACKUP_DIR, exist_ok=True)


# ---------------------------------------------------------------- 데이터 입출력

def load_data():
    with open(DATA_FILE, encoding="utf-8") as f:
        return json.load(f)


def save_data(data):
    """임시 파일에 쓰고 교체한다. 저장이 깨져 사이트 빌드가 실패하는 것을 막는다."""
    tmp = DATA_FILE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    os.replace(tmp, DATA_FILE)
    request_rebuild()


def request_rebuild():
    with open(os.path.join(STATE_DIR, "rebuild.request"), "w", encoding="utf-8") as f:
        f.write(datetime.datetime.now().isoformat())


def build_status():
    pending = os.path.exists(os.path.join(STATE_DIR, "rebuild.request"))
    log = os.path.join(STATE_DIR, "last-build.txt")
    last = ""
    if os.path.exists(log):
        with open(log, encoding="utf-8") as f:
            last = f.read().strip()
    return {"pending": pending, "last": last}


def to_int(value):
    """'150,000원' 처럼 입력해도 숫자로 받는다."""
    digits = re.sub(r"[^0-9]", "", value or "")
    return int(digits) if digits else 0


# ---------------------------------------------------------------- 로그인

FAILS = {}
MAX_FAILS = 5
LOCK_SECONDS = 300


def locked(ip):
    rec = FAILS.get(ip)
    if not rec:
        return False
    count, until = rec
    return count >= MAX_FAILS and time.time() < until


def login_required(fn):
    @wraps(fn)
    def wrapper(*a, **kw):
        if not session.get("auth"):
            return redirect(url_for("login", next=request.path))
        return fn(*a, **kw)
    return wrapper


@app.route("/login", methods=["GET", "POST"])
def login():
    ip = request.remote_addr or "?"
    if request.method == "POST":
        if locked(ip):
            flash("로그인 시도가 많습니다. 잠시 후 다시 시도하세요.", "error")
            return render_template("login.html"), 429
        user = request.form.get("username", "")
        pw = request.form.get("password", "")
        ok = bool(PASSWORD) and hmac.compare_digest(user, USERNAME) and hmac.compare_digest(pw, PASSWORD)
        if ok:
            FAILS.pop(ip, None)
            session["auth"] = True
            session.permanent = False
            target = request.args.get("next") or url_for("index")
            # 외부 주소로 넘어가지 않도록 내부 경로만 허용한다
            if not target.startswith("/"):
                target = url_for("index")
            return redirect(target)
        count = FAILS.get(ip, (0, 0))[0] + 1
        FAILS[ip] = (count, time.time() + LOCK_SECONDS)
        flash("아이디 또는 비밀번호가 올바르지 않습니다.", "error")
    return render_template("login.html")


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


@app.route("/healthz")
def healthz():
    return "ok", 200


# ---------------------------------------------------------------- 홈

@app.route("/")
@login_required
def index():
    data = load_data()
    return render_template("index.html", status=build_status(), data=data,
                           photo_count=len(gallery_items()))


@app.route("/rebuild", methods=["POST"])
@login_required
def rebuild():
    request_rebuild()
    flash("사이트 반영을 요청했습니다. 1~2분 뒤 홈페이지에서 확인하세요.", "ok")
    return redirect(url_for("index"))


# ---------------------------------------------------------------- 기본 정보

INFO_FIELDS = [
    ("name", "업소명", "text"),
    ("category", "업종 표기", "text"),
    ("tagline", "한 줄 소개", "text"),
    ("intro", "소개 문구", "textarea"),
    ("phone", "예약 전화번호", "text"),
    ("kakao", "카카오톡 링크 (비우면 버튼 숨김)", "text"),
    ("manager", "담당자", "text"),
    ("smsTemplate", "문자 예약 기본 문구", "textarea"),
    ("address", "주소", "text"),
    ("mapQuery", "지도 검색어", "text"),
    ("hours", "영업시간", "text"),
    ("hoursNote", "영업시간 보조 문구", "text"),
]


@app.route("/info", methods=["GET", "POST"])
@login_required
def info():
    data = load_data()
    if request.method == "POST":
        # 폼에 없는 항목은 기존 값을 유지한다 (일부만 전송돼도 내용이 지워지지 않도록)
        for key, _label, _kind in INFO_FIELDS:
            if key in request.form:
                data["venue"][key] = request.form.get(key, "").strip()
        if "access" in request.form:
            data["venue"]["access"] = [
                line.strip() for line in request.form["access"].splitlines() if line.strip()
            ]
        save_data(data)
        flash("기본 정보를 저장했습니다.", "ok")
        return redirect(url_for("info"))
    return render_template("info.html", fields=INFO_FIELDS, venue=data["venue"],
                           status=build_status())


# ---------------------------------------------------------------- 가격

@app.route("/prices", methods=["GET", "POST"])
@login_required
def prices():
    data = load_data()
    if request.method == "POST":
        tiers = []
        for idx, tier in enumerate(data["tiers"]):
            name = request.form.get("name_%d" % idx, "").strip()
            if not name:
                continue
            tiers.append({
                "id": tier.get("id") or "tier%d" % idx,
                "name": name,
                "price": to_int(request.form.get("price_%d" % idx)),
                "note": request.form.get("note_%d" % idx, "").strip(),
            })
        new_name = request.form.get("new_name", "").strip()
        if new_name:
            slug = re.sub(r"[^a-z0-9]+", "", new_name.lower()) or "tier%d" % len(tiers)
            tiers.append({
                "id": slug,
                "name": new_name,
                "price": to_int(request.form.get("new_price")),
                "note": request.form.get("new_note", "").strip(),
            })
        data["tiers"] = tiers
        data["fees"]["tcPerHour"] = to_int(request.form.get("tcPerHour"))
        data["fees"]["rt"] = to_int(request.form.get("rt"))
        data["priceNote"] = request.form.get("priceNote", "").strip()
        save_data(data)
        flash("가격을 저장했습니다.", "ok")
        return redirect(url_for("prices"))
    return render_template("prices.html", data=data, status=build_status())


# ---------------------------------------------------------------- 목록형 내용

LIST_SECTIONS = {
    "strengths": ("강점", ["title", "desc"], ["제목", "설명"]),
    "rooms": ("룸 안내", ["name", "capacity", "desc"], ["룸 이름", "인원", "설명"]),
    "steps": ("이용 절차", ["title", "desc"], ["단계 제목", "설명"]),
    "events": ("이벤트", ["title", "desc"], ["제목", "설명"]),
    "faq": ("자주 묻는 질문", ["q", "a"], ["질문", "답변"]),
}


@app.route("/sections/<key>", methods=["GET", "POST"])
@login_required
def sections(key):
    if key not in LIST_SECTIONS:
        abort(404)
    title, fields, labels = LIST_SECTIONS[key]
    data = load_data()
    if request.method == "POST":
        rows = []
        count = len(data[key]) + 1  # 기존 행 + 새로 추가하는 빈 행 1개
        for idx in range(count):
            row = {}
            for field in fields:
                row[field] = request.form.get("%s_%d" % (field, idx), "").strip()
            if any(row.values()):
                rows.append(row)
        data[key] = rows
        save_data(data)
        flash("%s 내용을 저장했습니다." % title, "ok")
        return redirect(url_for("sections", key=key))
    return render_template("sections.html", key=key, title=title, fields=fields,
                           labels=labels, rows=data[key], status=build_status())


@app.route("/amenities", methods=["GET", "POST"])
@login_required
def amenities():
    data = load_data()
    if request.method == "POST":
        data["amenities"] = [
            line.strip() for line in request.form.get("items", "").splitlines() if line.strip()
        ]
        save_data(data)
        flash("시설 목록을 저장했습니다.", "ok")
        return redirect(url_for("amenities"))
    return render_template("amenities.html", items=data["amenities"], status=build_status())


# ---------------------------------------------------------------- 갤러리

def gallery_items():
    if not os.path.isdir(GALLERY_DIR):
        return []
    files = [f for f in os.listdir(GALLERY_DIR)
             if os.path.splitext(f)[1].lower() in ALLOWED_EXT]
    files.sort()
    items = []
    for name in files:
        stem, ext = os.path.splitext(name)
        m = re.match(r"^(\d+)[-_](.*)$", stem)
        if m:
            order, label = m.group(1), m.group(2)
        else:
            order, label = "", stem
        items.append({"file": name, "order": order,
                      "label": label.replace("-", " "), "ext": ext})
    return items


@app.route("/gallery")
@login_required
def gallery():
    return render_template("gallery.html", items=gallery_items(), status=build_status())


@app.route("/gallery/file/<path:name>")
@login_required
def gallery_file(name):
    return send_from_directory(GALLERY_DIR, name)


def build_filename(order, label, ext):
    digits = re.sub(r"[^0-9]", "", order or "")[:3] or "99"
    clean = re.sub(r"[\\/:*?\"<>|]+", "", (label or "사진")).strip().replace(" ", "-")
    return "%s-%s%s" % (digits.zfill(2), clean, ext.lower())


@app.route("/gallery/upload", methods=["POST"])
@login_required
def gallery_upload():
    files = request.files.getlist("photos")
    saved = 0
    for storage in files:
        if not storage or not storage.filename:
            continue
        ext = os.path.splitext(storage.filename)[1].lower()
        if ext not in ALLOWED_EXT:
            flash("%s: 지원하지 않는 형식입니다." % storage.filename, "error")
            continue
        order = str(len(gallery_items()) + saved + 1)
        base = secure_filename(os.path.splitext(storage.filename)[0]) or "photo"
        name = build_filename(order, base, ext)
        storage.save(os.path.join(GALLERY_DIR, name))
        saved += 1
    if saved:
        request_rebuild()
        flash("사진 %d장을 올렸습니다." % saved, "ok")
    return redirect(url_for("gallery"))


@app.route("/gallery/update", methods=["POST"])
@login_required
def gallery_update():
    changed = 0
    for item in gallery_items():
        old = item["file"]
        order = request.form.get("order_%s" % old, item["order"])
        label = request.form.get("label_%s" % old, item["label"])
        new = build_filename(order, label, item["ext"])
        if new != old and not os.path.exists(os.path.join(GALLERY_DIR, new)):
            os.rename(os.path.join(GALLERY_DIR, old), os.path.join(GALLERY_DIR, new))
            changed += 1
    if changed:
        request_rebuild()
        flash("%d장의 순서·설명을 바꿨습니다." % changed, "ok")
    return redirect(url_for("gallery"))


@app.route("/gallery/delete", methods=["POST"])
@login_required
def gallery_delete():
    name = os.path.basename(request.form.get("file", ""))
    target = os.path.join(GALLERY_DIR, name)
    if name and os.path.isfile(target):
        os.remove(target)
        request_rebuild()
        flash("사진을 삭제했습니다.", "ok")
    return redirect(url_for("gallery"))


# ---------------------------------------------------------------- 백업

@app.route("/backup")
@login_required
def backup():
    return render_template("backup.html", status=build_status())


@app.route("/backup/download")
@login_required
def backup_download():
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz") as tar:
        tar.add(DATA_FILE, arcname="site.json")
        if os.path.isdir(GALLERY_DIR):
            tar.add(GALLERY_DIR, arcname="gallery")
    buf.seek(0)
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    return send_file(buf, mimetype="application/gzip", as_attachment=True,
                     download_name="dopamin-backup-%s.tar.gz" % stamp)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=False)
