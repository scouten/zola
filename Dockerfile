FROM ubuntu:20.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates tzdata build-essential golang wget && apt-get clean

RUN go version

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.52.1

RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='fb3a7425e3f10d51f0480ac3cdb3e725977955b2ba21c9bdac35309563b115e8' ;; \
        armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='f263e170da938888601a8e0bc822f8b40664ab067b390cf6c4fdb1d7c2d844e7' ;; \
        arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='de1dddd8213644cba48803118c7c16387838b4d53b901059e01729387679dd2a' ;; \
        i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='66c03055119cecdfc20828c95429212ae5051372513f148342758bb5d0130997' ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.24.1/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

WORKDIR /app
COPY . .

# I do the fetch separately so as to minimize build time in case of
# build failures. (There were many while creating this image.)
RUN cargo fetch

RUN cargo build --release --target x86_64-unknown-linux-gnu --verbose

RUN mkdir -p /release
WORKDIR /release

RUN cp -R /app/target/x86_64-unknown-linux-gnu/release/zola ./zola
RUN tar -c zola -f zola.tar
RUN gzip zola.tar

RUN ls -al .

ENTRYPOINT [ "/bin/sh" ]
