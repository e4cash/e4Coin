# Despliegue de e4Coin Core

Artefactos para correr nodos e4Coin (semilla y masternode) en las plataformas del
proyecto: unraid, servidor físico y dos clústeres Kubernetes.

## Contenido

| Archivo | Uso |
|---|---|
| `Dockerfile` | Imagen del nodo (build multi-stage desde fuente, con ZMQ) |
| `docker-entrypoint.sh` | Arranque; baja privilegios a usuario `e4coin`, arregla permisos del volumen |
| `docker-compose.yml` | unraid / servidor físico |
| `e4coin.conf.example` | Config de referencia (RPC, ZMQ, índices, masternode) |
| `k8s/e4coin-seed.yaml` | StatefulSet de nodos semilla para los clústeres K8s |

## Construir la imagen

```bash
# Desde la raíz del repo e4coin-core
docker build -f deploy/Dockerfile -t ghcr.io/ab4cus/e4coin-core:latest .
```

La CI (`.github/workflows/e4coin-release.yml`) también la construye y publica en GHCR
en cada tag `v*`.

## unraid / servidor físico

```bash
docker compose -f deploy/docker-compose.yml up -d
docker compose -f deploy/docker-compose.yml logs -f
```

En unraid, apuntar el volumen a un share del array (ver comentario en el compose) y
abrir el puerto **7834/tcp** en el router para que el nodo actúe como semilla.

## Kubernetes (los 2 clústeres)

```bash
# Ajustar storageClassName y la IP del LoadBalancer primero
kubectl apply -f deploy/k8s/e4coin-seed.yaml
kubectl -n e4coin get pods,svc
```

- **StatefulSet** (no Deployment): cada nodo tiene identidad de red y disco estables.
- El `Service` headless `e4coin-p2p` da DNS por pod; `e4coin-p2p-public` (LoadBalancer)
  expone el P2P al exterior para el rol de semilla.
- `e4coin-rpc` expone RPC+ZMQ **solo dentro del clúster** — lo consumirá el Oracle/bridge
  de la L2 (Fase 4).

## Puertos

| Puerto | Rol |
|---|---|
| 7834 | P2P mainnet (abrir al exterior en semillas) |
| 7832 | RPC mainnet (mantener interno) |
| 17834 / 17832 | P2P / RPC testnet |
| 28332/3/4 | ZMQ: rawtx / rawblock / InstantSend locks |

## Masternode (federación)

Un nodo se convierte en masternode registrando el colateral de **1000 E4C** y una clave
BLS. Pasar la clave por `E4COIN_EXTRA_ARGS=-masternodeblsprivkey=...` (compose) o por un
`Secret` montado en K8s. El procedimiento completo de la ceremonia de claves de los 25
masternodes de la federación se documentará en el runbook de operaciones.
