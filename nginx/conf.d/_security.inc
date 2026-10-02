# 보안 헤더 스니펫
# nginx 의 add_header 는 하위 location 에 add_header 가 하나라도 있으면
# 상위 레벨 헤더를 상속하지 않는다. 따라서 모든 location 에서 이 파일을 include 한다.
add_header X-Content-Type-Options   "nosniff"                         always;
add_header X-Frame-Options          "SAMEORIGIN"                      always;
add_header Referrer-Policy          "strict-origin-when-cross-origin" always;
