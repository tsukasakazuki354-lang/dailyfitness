FROM debian:bookworm-slim AS build

RUN apt-get update && apt-get install -y curl git unzip xz-utils && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter precache --web
RUN flutter doctor -v

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

# Serve with nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
RUN printf 'server {\n  listen 80;\n  server_name _;\n  root /usr/share/nginx/html;\n  index index.html;\n  location / {\n    try_files $uri $uri/ /index.html;\n  }\n}\n' > /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
