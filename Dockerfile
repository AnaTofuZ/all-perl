FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl ca-certificates patch bison libdevel-patchperl-perl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /all-perl
COPY versions.txt build.sh all-perl ./
COPY patches ./patches
ARG VERSIONS=all
ARG BUILD_JOBS=8
RUN ./build.sh "$VERSIONS"

ENTRYPOINT ["./all-perl"]
