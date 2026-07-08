#!/bin/sh
# e4Coin — instalador CLI para Linux y macOS.
#
#   curl -fsSL https://raw.githubusercontent.com/ab4cus/e4Coin-core/develop/install.sh | sh
#
# Prácticas aplicadas (estilo rustup/foundryup):
#   - todo el código vive en funciones y main() se invoca al final: una descarga
#     parcial del script no ejecuta nada a medias
#   - sin sudo: instala en ~/.e4coin/bin (E4COIN_DIR para cambiarlo)
#   - verifica SHA256 contra el asset SHA256SUMS del release (si existe)
#   - versión fijable: E4COIN_VERSION=v22.1.3-e4coin.1  (por defecto: latest)
#   - E4COIN_NO_MODIFY_PATH=1 para no tocar el profile de la shell
set -eu

REPO="ab4cus/e4Coin-core"
INSTALL_DIR="${E4COIN_DIR:-$HOME/.e4coin}"
VERSION="${E4COIN_VERSION:-latest}"
NO_MODIFY_PATH="${E4COIN_NO_MODIFY_PATH:-0}"
BINARIES="e4coind e4coin-cli e4coin-tx e4coin-wallet"

say()  { printf 'e4coin-install: %s\n' "$1"; }
err()  { printf 'e4coin-install: ERROR: %s\n' "$1" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || err "se necesita '$1' y no está instalado"; }

download() { # $1 url  $2 destino
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$1" -o "$2"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$1" -O "$2"
    else
        err "se necesita curl o wget"
    fi
}

detect_platform() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"
    case "$OS" in
        Linux)
            [ "$ARCH" = "x86_64" ] || err "Linux $ARCH aún no tiene binarios publicados (solo x86_64); compila desde fuente (README)"
            ASSET_SUFFIX="linux-x86_64.tar.gz"
            PAYLOAD_DIR="e4coin-linux-x86_64"
            ;;
        Darwin)
            [ "$ARCH" = "arm64" ] || say "aviso: los binarios macOS publicados son arm64 (Apple Silicon); en Intel compila desde fuente"
            ASSET_SUFFIX="macos.tar.gz"
            PAYLOAD_DIR="e4coin-macos"
            ;;
        *)
            err "plataforma no soportada: $OS (en Windows usa install.ps1)"
            ;;
    esac
}

resolve_version() {
    if [ "$VERSION" = "latest" ]; then
        say "consultando la última versión…"
        TAG="$(download "https://api.github.com/repos/$REPO/releases/latest" - 2>/dev/null \
            | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')" || TAG=""
        [ -n "$TAG" ] || err "no se pudo resolver la última versión (¿hay releases publicados en github.com/$REPO?)"
    else
        TAG="$VERSION"
    fi
    say "versión: $TAG"
}

verify_checksum() { # $1 dir con asset y SHA256SUMS  $2 nombre del asset
    if [ ! -f "$1/SHA256SUMS" ]; then
        say "aviso: el release no publica SHA256SUMS; se omite la verificación"
        return 0
    fi
    expected="$(grep " $2\$" "$1/SHA256SUMS" | awk '{print $1}')" || expected=""
    [ -n "$expected" ] || { say "aviso: $2 no aparece en SHA256SUMS; se omite la verificación"; return 0; }
    if command -v sha256sum >/dev/null 2>&1; then
        actual="$(sha256sum "$1/$2" | awk '{print $1}')"
    else
        actual="$(shasum -a 256 "$1/$2" | awk '{print $1}')"
    fi
    [ "$actual" = "$expected" ] || err "checksum SHA256 INCORRECTO para $2 (esperado $expected, obtenido $actual)"
    say "checksum SHA256 verificado ✓"
}

add_to_path() {
    [ "$NO_MODIFY_PATH" = "1" ] && { say "PATH no modificado (E4COIN_NO_MODIFY_PATH=1)"; return 0; }
    case ":$PATH:" in *":$INSTALL_DIR/bin:"*) return 0 ;; esac
    case "${SHELL:-}" in
        */zsh)  PROFILE="$HOME/.zshenv" ;;
        */bash) PROFILE="$HOME/.bashrc" ;;
        *)      PROFILE="$HOME/.profile" ;;
    esac
    LINE="export PATH=\"$INSTALL_DIR/bin:\$PATH\""
    if [ ! -f "$PROFILE" ] || ! grep -qs "$INSTALL_DIR/bin" "$PROFILE"; then
        printf '\n# e4Coin\n%s\n' "$LINE" >> "$PROFILE"
        say "PATH añadido a $PROFILE (abre una nueva terminal o ejecuta: $LINE)"
    fi
}

main() {
    need uname; need tar; need grep; need awk
    detect_platform
    resolve_version

    ASSET="e4coin-$TAG-$ASSET_SUFFIX"
    URL="https://github.com/$REPO/releases/download/$TAG/$ASSET"
    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT

    say "descargando $ASSET…"
    download "$URL" "$TMP/$ASSET" || err "no se pudo descargar $URL"
    download "https://github.com/$REPO/releases/download/$TAG/SHA256SUMS" "$TMP/SHA256SUMS" 2>/dev/null || true
    verify_checksum "$TMP" "$ASSET"

    say "instalando en $INSTALL_DIR/bin…"
    tar -xzf "$TMP/$ASSET" -C "$TMP"
    mkdir -p "$INSTALL_DIR/bin"
    for b in $BINARIES; do
        [ -f "$TMP/$PAYLOAD_DIR/$b" ] && install -m 755 "$TMP/$PAYLOAD_DIR/$b" "$INSTALL_DIR/bin/$b"
    done

    add_to_path
    say "listo ✓  ($("$INSTALL_DIR/bin/e4coind" --version 2>/dev/null | head -1 || echo "e4coind instalado"))"
    say "arrancar un nodo:   e4coind -daemon      (config: ~/.e4coincore/e4coin.conf)"
    say "desinstalar:        rm -rf $INSTALL_DIR"
}

main "$@"
