# 80 / 443 server 블록이 공통으로 include 하는 스니펫
root  /usr/share/nginx/html;
index index.html;

location / {
    include /etc/nginx/conf.d/_security.inc;
    try_files $uri $uri/ /index.html;
}

# 관리 페이지 (검색엔진 수집 대상에서 제외된다)
# ^~ 를 붙이는 이유: 아래의 확장자 규칙(css, js, 이미지)이 정규식이라
# 접두사 규칙보다 우선한다. ^~ 가 없으면 /admin/static/admin.css 가
# 확장자 규칙에 걸려 사이트 폴더에서 파일을 찾다가 404 가 된다.
location ^~ /admin/ {
    include /etc/nginx/conf.d/_security.inc;
    proxy_pass http://admin:8000/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Prefix /admin;
    proxy_read_timeout 300s;
    client_max_body_size 200m;
    access_log off;
}

# 이미지 / 폰트 / 동영상
location ~* \.(?:png|jpe?g|gif|webp|avif|svg|ico|woff2?|ttf|eot|mp4)$ {
    include /etc/nginx/conf.d/_security.inc;
    expires 30d;
    add_header Cache-Control "public" always;
    access_log off;
}

# CSS / JS
location ~* \.(?:css|js)$ {
    include /etc/nginx/conf.d/_security.inc;
    expires 7d;
    add_header Cache-Control "public" always;
}

# HTML 은 항상 재검증 (expires -1 이 Cache-Control: no-cache 를 생성한다)
location ~* \.html$ {
    include /etc/nginx/conf.d/_security.inc;
    expires -1;
}

location = /robots.txt  { include /etc/nginx/conf.d/_security.inc; access_log off; }
# 사이트맵은 기록을 남긴다. 검색엔진이 언제 가져갔는지 확인해야 할 일이 생긴다.
# 실제로 "가져올 수 없음" 문의를 받았을 때 기록이 없어 확인이 늦어졌다.
location = /sitemap.xml { include /etc/nginx/conf.d/_security.inc; }

# 숨김 파일 차단
location ~ /\. { deny all; }
