import secrets

# 32바이트 길이의 임의의 문자열 생성
jwt_secret_key = secrets.token_urlsafe(32)
print(jwt_secret_key)
