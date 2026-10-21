FROM debian:stable-slim AS builder

# Build dependencies
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential texinfo \
        gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf \
        git ca-certificates

WORKDIR /installation

# Build newlib
RUN git clone --depth 1 https://sourceware.org/git/newlib-cygwin.git \
    && mkdir newlib-build && cd newlib-build \
    && ../newlib-cygwin/configure \
        --target=riscv64-unknown-elf --prefix=/usr/lib --disable-multilib \
        CFLAGS_FOR_TARGET="-O2 -mcmodel=medany" \
    && make -j$(nproc) && make install

FROM debian:stable-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        python3 python3-pip python3-pytest python3-antlr4 antlr4 \
        make nodejs \
        gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf qemu-system-riscv \
    && rm -rf /var/lib/apt/lists/*

# Pyright and pytest-cov are not available as system packages
RUN pip install --no-cache-dir --break-system-packages pyright pytest-cov

# newlib
COPY --from=builder /usr/lib/riscv64-unknown-elf/lib /usr/lib/riscv64-unknown-elf/lib
COPY --from=builder /usr/lib/riscv64-unknown-elf/include /usr/lib/riscv64-unknown-elf/include

ENV ANTLR4=antlr4
WORKDIR /app
