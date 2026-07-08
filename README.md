# e4Coin Core

**e4Coin (E4C)** es la blockchain de capa 1 (L1) del ecosistema **PlayChain** — una
plataforma de gaming Web3 donde los recursos que los jugadores ganan en distintos juegos
se intercambian en un marketplace único. e4Coin provee el token de reserva, la
gobernanza, el colateral de masternodes y el *settlement* del puente hacia la L2.

e4Coin Core es un fork de **Dash Core v22.1.3** con identidad propia (heredada del
proyecto e4Coin original de 2019) y una economía diseñada a medida para el caso de uso
de gaming. Conserva la infraestructura de Dash: masternodes deterministas, **ChainLocks**
(protección contra ataques del 51%), **InstantSend** (confirmaciones en 1-2 s), gobernanza
on-chain y superbloques de tesorería.

> Parte del monorepo [heliomultiverso](../). Documentos de referencia:
> [PLAN-UNIFICADO](../docs/PLAN-UNIFICADO.md) · [DISEÑO-ECONÓMICO-L1](../docs/DISENO-ECONOMICO-L1.md) ·
> [whitepaper](../whitepaper/).

---

## Especificaciones de la cadena

### Parámetros de consenso

| Parámetro | Valor | Notas |
|---|---|---|
| Base | Dash Core v22.1.3 | Bitcoin Core + masternodes/LLMQ |
| Algoritmo PoW | **X11** | 11 funciones de hash encadenadas |
| Tiempo de bloque | **30 segundos** | "efectivo digital"; UX instantánea vía InstantSend |
| Bloques por año | 1 051 200 | 2 880/día |
| Recompensa inicial | **5 E4C/bloque** | base fija (V20 activo desde el génesis) |
| Curva de emisión | **−1/14 (≈7,14 %) anual** | reducción suave, sin *halvings* abruptos |
| Supply máximo | **≈ 73,58 M E4C** | asintótico |
| `MAX_MONEY` | 80 M E4C | sanity check de consenso |
| Divisibilidad | 8 decimales | unidad mínima: `e4sat` |
| Ajuste de dificultad | **DGW v3** desde el bloque 1 | Dark Gravity Wave |
| Colateral de masternode | **1 000 E4C** | |
| Ciclo de superbloque | 86 400 bloques (~30 días) | tesorería de gobernanza |

### Reparto de la recompensa de bloque

| Destino | % | Vehículo |
|---|---|---|
| Minero (PoW) | **40 %** | coinbase |
| Masternodes | **40 %** | pago determinista |
| Tesorería (DAO) | **20 %** | superbloques mensuales |

### Premine (bloque 1 — 10 % del supply, ~7 358 400 E4C)

| Tramo | % | Destino |
|---|---|---|
| Airdrop por países | 6 % | distribución per-cápita vía claims en L2 (Merkle proof) |
| Devs e impulso | 3 % | equipo/marketing/listados, con *vesting* on-chain |
| Operativo | 1 % | colaterales de la federación + liquidez del puente |

### Identidad de red

| Elemento | Mainnet | Testnet | Regtest | Devnet |
|---|---|---|---|---|
| Puerto P2P | 7834 | 17834 | 17835 | 17836 |
| Puerto RPC | 7832 | 17832 | 17839 | 17838 |
| Magic bytes | `65 34 43 04` ("e4C") | `04 65 34 43` | `fc c1 b7 dc` | `e2 ca ff ce` |
| Prefijo dirección | 33 → **'E'** | 140 → 'y' | — | — |
| Prefijo WIF | 204 | 239 | 239 | 239 |
| BIP44 coin type | 7834 *(pendiente SLIP-44)* | 1 | 1 | 1 |
| DNS seeds | dnsseed.e4coin.io, dnsseed.e4cash.net | testnet-seed.e4coin.io | — | — |

### Génesis (definitivos, minados 2026-07-06)

Mensaje del génesis (heredado de 2019):
> *"The Times 14/Feb/2019 JPMorgan Chase Moves to Be First Big U.S. Bank With Its Own Cryptocurrency"*

| Red | Hash del bloque génesis | nTime | Nonce |
|---|---|---|---|
| Mainnet | `00000296515ef56205354214c0fed3f62f3b0853567c24deeee97a5cb9bfafe8` | 1550102400 | 4031864 |
| Testnet | `0000099dd3627a16a3001409ad78f96a7e4aea9b1692af650ab4a05881a4f205` | 1550102401 | 938882 |
| Regtest | `104908776176fd034a5e75a2df6f85256c3f74385933dab455f3aaea228ccaa7` | 1550102403 | 2 |
| Devnet | `7238bfec58655550af0dfba9f3b492d567ef033cf91bdcb1db74f9aa99ed89b7` | 1550102402 | 1 |

Merkle root (común): `15b32d1e87d5adbf95e9810d565b8a8bbe2d95661768b3fec41c68c303283aed`

### Quórums LLMQ (federación de 25-30 masternodes)

| Uso | Quórum | Umbral |
|---|---|---|
| ChainLocks / gobernanza / EHF | `LLMQ_25_67` | 17 de 25 |
| InstantSend (DIP0024) | `LLMQ_DEVNET_DIP0024` | 4 de 8 (rotativo) |

> Al crecer la red se migrará a quórums grandes (`LLMQ_50_60` / `LLMQ_400_60`) vía hard fork.

---

## Diferencias clave respecto a Dash Core

1. **Emisión rediseñada**: subsidio fijo de 5 E4C (se eliminó la curva por dificultad de
   Dash y sus alturas históricas de 2014).
2. **Pago de masternode plano al 50 %** (sin la escalera histórica ni la reasignación BRR).
3. **Reglas modernas activas desde el génesis**: la cadena nace nueva, sin activaciones
   diferidas ni checkpoints heredados.
4. **Límite de scriptSig del coinbase 100 → 120 bytes**: el mensaje de génesis de 2019
   (97 caracteres) excedía el límite de Bitcoin/Dash. Cambio de consenso deliberado.
5. **PrivateSend/CoinJoin desactivado** (riesgo regulatorio, sin valor para el caso de uso).
6. **Plataforma Dash (Evo/credit pool) no utilizada**: `MN_RRHeight` en el futuro.
7. Identidad completa e4Coin (nombres, puertos, magic, prefijos, seeds, ticker E4C).

---

## Binarios

| Binario | Rol |
|---|---|
| `e4coind` | Daemon del nodo (full node / masternode) |
| `e4coin-cli` | Cliente RPC de línea de comandos |
| `e4coin-tx` | Utilidad de construcción/decodificación de transacciones |
| `e4coin-wallet` | Herramienta de wallet offline |

Datadir por defecto: `~/.e4coincore` · Config: `e4coin.conf` · Ticker: **E4C**

---

## Instalación rápida (CLI)

Binarios oficiales del último release, con verificación SHA256 y sin sudo/admin
(instala en `~/.e4coin/bin` o `%LOCALAPPDATA%\e4Coin\bin`):

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/ab4cus/e4Coin-core/develop/install.sh | sh
```

```powershell
# Windows (PowerShell)
irm https://raw.githubusercontent.com/ab4cus/e4Coin-core/develop/install.ps1 | iex
```

Versión concreta: `E4COIN_VERSION=vX.Y.Z` (sh) o `$env:E4COIN_VERSION="vX.Y.Z"` (ps).
Si prefieres inspeccionar antes de ejecutar (recomendado), descarga el script y
léelo: son ~150 líneas comentadas.

## Compilar desde fuente

### Dependencias (Debian/Ubuntu)

```bash
sudo apt-get install build-essential libtool autotools-dev automake pkg-config \
  bsdmainutils python3 bison flex cmake curl
```

### Build

```bash
# 1) dependencias empaquetadas (boost, libevent, gmp, bdb, sqlite, zmq...)
make -C depends -j"$(nproc)" NO_QT=1 NO_UPNP=1 NO_NATPMP=1

# 2) configurar y compilar
./autogen.sh
CONFIG_SITE="$PWD/depends/x86_64-pc-linux-gnu/share/config.site" ./configure \
  --without-gui --enable-zmq
make -j"$(nproc)"
```

Guías detalladas por plataforma en [doc/](doc/) (build-unix, build-osx, build-windows).

### Binarios precompilados

Los releases (`v*`) generan binarios de **Linux, Windows y macOS** e imagen Docker
automáticamente vía [GitHub Actions](.github/workflows/e4coin-release.yml).

---

## Ejecutar un nodo

```bash
# Mainnet
e4coind -daemon
e4coin-cli getblockchaininfo

# Testnet
e4coind -testnet -daemon
```

Config de ejemplo (RPC, ZMQ, índices, masternode): [deploy/e4coin.conf.example](deploy/e4coin.conf.example).

## Despliegue (Docker / Kubernetes)

Artefactos para unraid, servidor físico y Kubernetes en [deploy/](deploy/):

```bash
# Docker (unraid / servidor físico)
docker compose -f deploy/docker-compose.yml up -d

# Kubernetes (nodos semilla)
kubectl apply -f deploy/k8s/e4coin-seed.yaml
```

Ver [deploy/README.md](deploy/README.md) para detalles y puertos.

---

## Estado del proyecto

**Fase 1 (L1) — validada en local.** DKG real, ChainLocks, InstantSend y firmas de
quórum verificados con los parámetros e4Coin (tests funcionales de Dash adaptados, en
verde). Génesis definitivos minados; claves spork regeneradas.

Pendiente para testnet pública → mainnet: seeders DNS, explorer, sporks multi-clave
(2-de-3), builds reproducibles (Guix), registro SLIP-44 y ceremonia de claves de la
federación. Ver el checklist en [DISEÑO-ECONÓMICO-L1 §4](../docs/DISENO-ECONOMICO-L1.md).

Fases siguientes (L2 EVM, motor ioquake3, integración): [PLAN-UNIFICADO](../docs/PLAN-UNIFICADO.md).

---

## Seguridad

- **No expongas el RPC** a internet; usa autenticación por cookie o `rpcuser`/`rpcpassword`
  con `rpcallowip` restringido.
- Las claves privadas (génesis, spork, BLS de masternode) se custodian **fuera del repo**.
- Reporta vulnerabilidades según [SECURITY.md](SECURITY.md).

## Licencia

e4Coin Core se distribuye bajo licencia MIT — ver [COPYING](COPYING). Hereda la base de
Dash Core y Bitcoin Core, también MIT.
