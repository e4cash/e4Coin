#!/bin/bash
# Entrypoint del nodo e4Coin. Corre como root solo para arreglar permisos del
# volumen y luego baja a usuario 'e4coin' con gosu.
set -e

DATA_DIR="${E4COIN_DATA:-/home/e4coin/.e4coincore}"

if [ "$(id -u)" = "0" ]; then
  mkdir -p "$DATA_DIR"
  chown -R e4coin:e4coin "$DATA_DIR"
  # Si el primer argumento es un binario e4coin, re-ejecuta como usuario e4coin
  case "$1" in
    e4coind|e4coin-cli|e4coin-tx|e4coin-wallet)
      exec gosu e4coin "$0" "$@"
      ;;
  esac
fi

# Permite pasar flags extra por E4COIN_EXTRA_ARGS (p.ej. -masternodeblsprivkey=...)
if [ "$1" = "e4coind" ]; then
  shift
  exec e4coind -datadir="$DATA_DIR" -printtoconsole ${E4COIN_EXTRA_ARGS:-} "$@"
fi

exec "$@"
