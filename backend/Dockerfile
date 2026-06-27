# Nexus CSF — Drogon C++ API (Podman/Docker, works on Apple Silicon)
FROM docker.io/library/fedora:40 AS drogon-builder

RUN dnf install -y \
    git cmake gcc-c++ make \
    jsoncpp-devel openssl-devel zlib-devel \
    c-ares-devel libuuid-devel libpq-devel \
    && dnf clean all

ARG DROGON_VERSION=v1.9.13
RUN git clone --depth 1 --branch ${DROGON_VERSION} \
        https://github.com/drogonframework/drogon.git /opt/drogon \
    && cd /opt/drogon && git submodule update --init \
    && cmake -B /opt/drogon/build -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_EXAMPLES=OFF -DBUILD_CTL=OFF -DBUILD_POSTGRESQL=ON \
    && cmake --build /opt/drogon/build -j"$(nproc)" \
    && cmake --install /opt/drogon/build

FROM docker.io/library/fedora:40 AS app-builder

COPY --from=drogon-builder /usr/local /usr/local

RUN dnf install -y cmake gcc-c++ jsoncpp-devel openssl-devel curl \
    c-ares-devel libuuid-devel zlib-devel libpq-devel \
    && dnf clean all

ENV CMAKE_PREFIX_PATH=/usr/local
ENV LD_LIBRARY_PATH=/usr/local/lib

WORKDIR /build
COPY CMakeLists.txt .
COPY include ./include
COPY src ./src
COPY data ./data
COPY openapi.yaml ./openapi.yaml

RUN cmake -B out -DCMAKE_BUILD_TYPE=Release \
    && cmake --build out --config Release

FROM docker.io/library/fedora:40

COPY --from=drogon-builder /usr/local /usr/local

RUN dnf install -y jsoncpp openssl-libs curl libpq \
    && dnf clean all

# Runtime libs linked by Drogon/Trantor (avoid extra dnf in final stage)
COPY --from=app-builder /usr/lib64/libcares.so.2 /usr/lib64/
COPY --from=app-builder /usr/lib64/libuuid.so.1 /usr/lib64/
COPY --from=app-builder /usr/lib64/libz.so.1 /usr/lib64/
COPY --from=app-builder /usr/lib64/libpq.so.5 /usr/lib64/

ENV LD_LIBRARY_PATH=/usr/local/lib

WORKDIR /app
COPY --from=app-builder /build/out/nexus_server ./nexus_server
COPY data/catalog.json ./data/catalog.json
COPY data/users.json ./data/users.json
COPY data/orders.json ./data/orders.json
COPY openapi.yaml ./openapi.yaml

EXPOSE 8848

HEALTHCHECK --interval=15s --timeout=5s --retries=3 --start-period=20s \
    CMD curl -f http://127.0.0.1:8848/api/health || exit 1

CMD ["./nexus_server"]
