# Brotli beats gzip by ~23% on the Dart bundle — around 280 KB off a cold
# visit — but nginx ships without it, so the module is built here against the
# exact version we serve with. `--with-compat` is already part of the official
# image's configure line, which is what makes the module loadable.
FROM nginx:1.28.0-alpine3.21-slim AS brotli-module
ARG NGINX_VERSION=1.28.0
RUN apk add --no-cache build-base git cmake curl linux-headers \
      pcre-dev zlib-dev openssl-dev \
 && git clone --depth=1 --recursive https://github.com/google/ngx_brotli.git /ngx_brotli \
 # ngx_brotli links against its vendored libbrotli, which it does not build
 # itself, so it has to be produced before nginx's configure runs.
 && cmake -S /ngx_brotli/deps/brotli -B /ngx_brotli/deps/brotli/out \
      -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
 && cmake --build /ngx_brotli/deps/brotli/out --config Release --target brotlienc \
 && curl -fsSL "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" | tar -xz -C /tmp \
 && cd "/tmp/nginx-${NGINX_VERSION}" \
 && ./configure --with-compat --add-dynamic-module=/ngx_brotli \
 && make -j"$(nproc)" modules

# Compressing once at build time keeps every request cheap: nginx only has to
# pick the right pre-built file, never to compress on the fly.
FROM alpine:3.21 AS assets
RUN apk add --no-cache brotli gzip findutils
COPY ./build/web/ /app/html
# `*.symbols` are the renderer's debug symbol maps — 11 MB of them, used only to
# turn a stack trace back into function names offline. No browser ever requests
# one, so they were pure image weight, and compressing them at `brotli -q 11`
# was several minutes of build time spent on files nobody downloads.
RUN find /app/html/ -name '*.symbols' -delete
RUN find /app/html/ -type f -size +512c \
      -regex '.*\.\(html\|css\|js\|json\|svg\|ttf\|otf\|woff2\|wasm\|mjs\|yaml\|env\|bin\)' \
      \( -exec gzip -k9 {} + -o -exec true {} + \) \
 && find /app/html/ -type f -size +512c \
      -regex '.*\.\(html\|css\|js\|json\|svg\|ttf\|otf\|woff2\|wasm\|mjs\|yaml\|env\|bin\)' \
      -exec brotli -q 11 -k {} +

FROM nginx:1.28.0-alpine3.21-slim
COPY --from=brotli-module \
     /tmp/nginx-1.28.0/objs/ngx_http_brotli_static_module.so \
     /usr/lib/nginx/modules/
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=assets /app/html /app/html
