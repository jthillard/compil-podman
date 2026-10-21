FROM debian:stable-slim AS builder

# Build dependencies
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        autoconf automake autotools-dev build-essential bison flex texinfo \
        gawk libtool zlib1g-dev device-tree-compiler \
        gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf \
        git ca-certificates

WORKDIR /installation

# Build spike
RUN git clone --depth 1 https://github.com/riscv-software-src/riscv-isa-sim.git \
    && cd riscv-isa-sim && mkdir build && cd build \
    && ../configure \
    && make -j$(nproc) && make install

# Build newlib
RUN git clone --depth 1 https://sourceware.org/git/newlib-cygwin.git \
    && mkdir newlib-build && cd newlib-build \
    && ../newlib-cygwin/configure \
        --target=riscv64-unknown-elf --prefix=/usr/lib --disable-multilib \
        CFLAGS_FOR_TARGET="-O2 -mcmodel=medany" \
    && make -j$(nproc) && make install

# Build riscv-pk
RUN git clone --depth 1 https://github.com/riscv/riscv-pk.git \
    && cd riscv-pk && mkdir build && cd build \
    && ../configure --host=riscv64-unknown-elf --with-arch=rv64gc_zicsr_zifencei \
    && make -j$(nproc) && make install

RUN strip /usr/local/bin/* /usr/local/lib/*.so 2>/dev/null || true \
    && rm -rf /usr/local/include /usr/local/lib/*.a

FROM debian:stable-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        python3 python3-pip python3-pytest python3-antlr4 antlr4 \
        make nodejs device-tree-compiler libstdc++6 \
        gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf \
    && rm -rf /var/lib/apt/lists/*

# Pyright and pytest-cov are not available as system packages
RUN pip install --no-cache-dir --break-system-packages pyright pytest-cov

# spike + pk
COPY --from=builder /usr/local /usr/local
# newlib
COPY --from=builder /usr/lib/riscv64-unknown-elf/lib /usr/lib/riscv64-unknown-elf/lib
COPY --from=builder /usr/lib/riscv64-unknown-elf/include /usr/lib/riscv64-unknown-elf/include
RUN ldconfig

ENV ANTLR4=antlr4
WORKDIR /app
