#!/usr/bin/env bash
# =============================================================================
# <PROJETO> — Ativa uma release do front (roda NO SERVIDOR, enviado por stdin pelo publicar.sh)
# Uso: bash -s -- <stage|prod> <sha>      (ou <stage|prod> <sha_anterior> para voltar)
#
# A release já foi extraída em $BASE/releases/<sha> (build pronto, sem node_modules para instalar).
# Aqui só: troca o link `current`, (re)inicia o processo PM2 e confere a saúde. Se a nova versão
# não responder, volta o link para a anterior. Guarda as últimas 5 releases.
#
# Modelo da skill deploy-github-actions-ssh. Troque os valores marcados com <...>.
# =============================================================================
set -euo pipefail

AMB="${1:?stage|prod}"; SHA="${2:?sha}"
case "$AMB" in
  prod)  PM2_NAME="<app>-prod";  PORT="<3000>"; REPO="<caminho-do-repo-prod-no-servidor>" ;;
  stage) PM2_NAME="<app>-stage"; PORT="<3001>"; REPO="<caminho-do-repo-stage-no-servidor>" ;;
  *) echo "ambiente invalido: $AMB"; exit 1 ;;
esac
BASE="<caminho-das-releases-no-servidor>/$AMB"
ENV_FILE="$REPO/web/.env"        # fonte de verdade das variáveis do front (não vai no artefato)
NOVA="$BASE/releases/$SHA"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" && nvm use 20 >/dev/null 2>&1 || true
NODE_BIN="$(command -v node)"

[[ -f "$NOVA/server.js" ]] || { echo "[ERRO] release $SHA nao encontrada em $NOVA"; exit 1; }
[[ -f "$ENV_FILE" ]] || { echo "[ERRO] $ENV_FILE nao existe"; exit 1; }

ANTERIOR=""
[[ -L "$BASE/current" ]] && ANTERIOR="$(readlink "$BASE/current")"

cat > "$BASE/ecosystem.config.cjs" <<ECO
module.exports = { apps: [{
  name: "$PM2_NAME",
  script: "server.js",
  cwd: "$BASE/current",
  interpreter: "$NODE_BIN",
  node_args: "--env-file=$ENV_FILE",
  env: { NODE_ENV: "production", PORT: "$PORT", HOSTNAME: "0.0.0.0" },
}] };
ECO

# Troca atômica: o link nunca fica apontando para o vazio.
ln -sfn "$NOVA" "$BASE/current.novo" && mv -T "$BASE/current.novo" "$BASE/current"

iniciar() { pm2 startOrRestart "$BASE/ecosystem.config.cjs" --update-env >/dev/null; }

saudavel() {
  for _ in $(seq 1 30); do
    codigo="$(curl -s -o /dev/null -w '%{http_code}' -m 5 "http://127.0.0.1:$PORT/" || true)"
    [[ "$codigo" =~ ^[23] ]] && return 0
    sleep 1
  done
  return 1
}

iniciar
if saudavel; then
  pm2 save >/dev/null
  echo "$SHA" > "$BASE/web.sha"
  echo "[OK] $AMB no ar: release $SHA (porta $PORT)"
else
  echo "[ERRO] release $SHA nao respondeu em 30 s."
  if [[ -n "$ANTERIOR" ]]; then
    ln -sfn "$ANTERIOR" "$BASE/current.novo" && mv -T "$BASE/current.novo" "$BASE/current"
    iniciar
    saudavel && echo "[AVISO] voltei para $(basename "$ANTERIOR")" || echo "[ERRO] a anterior tambem nao respondeu: veja pm2 logs $PM2_NAME"
  fi
  exit 1
fi

# Mantém as 5 releases mais recentes (a ativa nunca é apagada).
cd "$BASE/releases" && ls -1t | tail -n +6 | while read -r antiga; do
  [[ "$BASE/releases/$antiga" == "$(readlink "$BASE/current")" ]] || rm -rf "$BASE/releases/$antiga"
done
