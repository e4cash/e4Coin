# e4Coin Core — nodo/masternode. Build multi-stage desde fuente.
# Uso:
#   docker build -f deploy/Dockerfile -t ab4cus/e4coin-core:latest .
# ------------------------------------------------------------------------------
FROM ubuntu:24.04 AS build

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential libtool autotools-dev automake pkg-config bsdmainutils \
      python3 bison flex cmake curl ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . /src

# Dependencias (sin Qt/GUI; ZMQ activo para la integración con la L2 en Fase 4)
RUN make -C depends -j"$(nproc)" NO_QT=1 NO_QR=1 NO_UPNP=1 NO_NATPMP=1
RUN HOST_PREFIX="$(ls -d depends/x86_64-*-linux-gnu)" && \
    ./autogen.sh && \
    CONFIG_SITE="$PWD/$HOST_PREFIX/share/config.site" ./configure \
      --disable-tests --disable-bench --without-gui --disable-fuzz-binary \
      --enable-zmq && \
    make -j"$(nproc)" && \
    strip src/e4coind src/e4coin-cli src/e4coin-tx src/e4coin-wallet

# ------------------------------------------------------------------------------
FROM ubuntu:24.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      libstdc++6 libgcc-s1 ca-certificates gosu \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -r -m -d /home/e4coin -s /usr/sbin/nologin e4coin

COPY --from=build /src/src/e4coind      /usr/local/bin/e4coind
COPY --from=build /src/src/e4coin-cli   /usr/local/bin/e4coin-cli
COPY --from=build /src/src/e4coin-tx    /usr/local/bin/e4coin-tx
COPY --from=build /src/src/e4coin-wallet /usr/local/bin/e4coin-wallet
COPY deploy/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV E4COIN_DATA=/home/e4coin/.e4coincore
VOLUME ["/home/e4coin/.e4coincore"]

# P2P mainnet / RPC mainnet / P2P testnet / RPC testnet
EXPOSE 7834 7832 17834 17832

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["e4coind"]
