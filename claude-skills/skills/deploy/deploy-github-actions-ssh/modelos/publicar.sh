#!/usr/bin/env bash
# =============================================================================
# <PROJETO> — Publicar (roda no GitHub Actions; o servidor não compila o front)
# Uso: ./bin/publicar.sh <stage|prod> [--forcar] [--so-web|--so-backend] [--sim]
#
#  - Só publica o que mudou desde a última publicação daquele ambiente (web/ e backend/ separados;
#    o último sha publicado fica em <BASE>/{web,backend}.sha no servidor). --forcar ignora.
#  - Backend: bin/deploy-backend.sh NO SERVIDOR (pull, dependências, conferência do .env, migração
#    protegida), depois curl em <URL>/up pela internet.
#  - Front: build aqui, envia o artefato, ativa com troca de link + checagem de saúde (ativar-release.sh).
#  - Variáveis do front vêm do web/.env do próprio servidor: fonte única por ambiente.
#
# Modelo da skill deploy-github-actions-ssh. Troque os valores marcados com <...>.
# =============================================================================
set -euo pipefail

AMB="${1:-}"; shift || true
FORCAR=0; SO=""; SIM=0
for a in "$@"; do case "$a" in
  --forcar) FORCAR=1 ;; --so-web) SO=web ;; --so-backend) SO=backend ;; --sim) SIM=1 ;;
  *) echo "opcao desconhecida: $a"; exit 1 ;; esac; done
[[ "$AMB" =~ ^(stage|prod)$ ]] || { echo "Uso: $0 <stage|prod> [--forcar] [--so-web|--so-backend] [--sim]"; exit 1; }

# ── Configuração do projeto ───────────────────────────────────────────────────
SSH_ALVO="${DEPLOY_SSH:-<alias-ssh-local>}"
case "$AMB" in
  prod)  REPO_REMOTO="<caminho-do-repo-prod-no-servidor>";  URL_PUBLICA="<https://dominio-prod>" ;;
  stage) REPO_REMOTO="<caminho-do-repo-stage-no-servidor>"; URL_PUBLICA="<https://dominio-stage>" ;;
esac
BASE="<caminho-das-releases-no-servidor>/$AMB"
# ──────────────────────────────────────────────────────────────────────────────

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHA="$(git -C "$RAIZ" rev-parse --short=10 HEAD)"
# O artefato leva binários nativos (sharp, swc): construído no Mac quebraria no servidor Linux.
if [[ "$(uname -s)" != Linux && "${DEPLOY_PERMITIR_MAC:-}" != 1 ]]; then
  echo "[ERRO] build do front só em Linux (binários nativos). Rode pelo GitHub Actions: Actions > Deploy > Run workflow."; exit 1
fi
sshr() { ssh -o BatchMode=yes "$SSH_ALVO" "$@"; }

info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
ok()   { echo -e "\033[0;32m[OK]\033[0m $1"; }
erro() { echo -e "\033[0;31m[ERRO]\033[0m $1"; exit 1; }

[[ -z "$(git -C "$RAIZ" status --porcelain -- web backend bin)" ]] || erro "há alteração não commitada em web/, backend/ ou bin/. Commite antes."
git -C "$RAIZ" fetch -q origin
git -C "$RAIZ" branch -r --contains HEAD | grep -q origin/ || erro "o commit $SHA não está no GitHub. Faça push antes (o servidor puxa de lá)."

mudou() { # $1 = web|backend ; compara com o último sha publicado
  local ult; ult="$(sshr "cat $BASE/$1.sha 2>/dev/null" || true)"
  [[ "$FORCAR" == 1 || -z "$ult" ]] && return 0
  git -C "$RAIZ" cat-file -e "$ult^{commit}" 2>/dev/null || return 0
  ! git -C "$RAIZ" diff --quiet "$ult" HEAD -- "$1"
}

saude_publica() { # visto de fora, pela internet: o deploy pode passar e o site não responder
  local cod; cod="$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$URL_PUBLICA/up" || true)"
  [[ "$cod" == 200 ]] || erro "publicado, mas $URL_PUBLICA/up respondeu $cod. Verifique o servidor."
  ok "$URL_PUBLICA/up respondeu 200"
}

info "Ambiente: $AMB | commit: $SHA | servidor: $SSH_ALVO"
if [[ "$AMB" == prod && "$SIM" != 1 ]]; then
  read -r -p "Publicar em PRODUCAO? [s/N]: " c; [[ "$c" =~ ^[sS]$ ]] || { info "Cancelado."; exit 0; }
fi
sshr "mkdir -p $BASE/releases $BASE/uploads"

# ── Backend ───────────────────────────────────────────────────────────────────
if [[ "$SO" != web ]]; then
  if mudou backend; then
    info "Backend mudou: deploy-backend.sh no servidor"
    sshr "cd $REPO_REMOTO && ./bin/deploy-backend.sh"
    sshr "echo $SHA > $BASE/backend.sha"
    ok "Backend publicado ($SHA)"
    saude_publica
  else
    ok "Backend sem mudança desde a última publicação: nada a fazer"
  fi
fi

# ── Front ─────────────────────────────────────────────────────────────────────
if [[ "$SO" != backend ]]; then
  if mudou web; then
    WEB="$RAIZ/web"
    ENVTMP="$WEB/.env.production.local"
    trap 'rm -f "$ENVTMP"' EXIT
    info "Variáveis do front: $REPO_REMOTO/web/.env (do servidor)"
    sshr "cat $REPO_REMOTO/web/.env" > "$ENVTMP"
    [[ -s "$ENVTMP" ]] || erro "web/.env do servidor vazio ou ilegível"

    info "npm ci + next build (aqui, não no servidor)"
    ( cd "$WEB" && npm ci --no-audit --no-fund && rm -rf .next && npx next build )
    rm -f "$ENVTMP"

    PKG="$(mktemp -d)"
    cp -R "$WEB/.next/standalone/." "$PKG/"
    mkdir -p "$PKG/.next" && cp -R "$WEB/.next/static" "$PKG/.next/static"
    [[ -d "$WEB/public" ]] && cp -R "$WEB/public" "$PKG/public"
    find "$PKG" -maxdepth 1 -name '.env*' -delete   # segredo/variável nunca viaja no artefato
    COPYFILE_DISABLE=1 tar -czf "$PKG.tgz" -C "$PKG" .
    info "Artefato: $(du -h "$PKG.tgz" | cut -f1)"

    scp -q -o BatchMode=yes "$PKG.tgz" "$SSH_ALVO:$BASE/uploads/$SHA.tgz"
    sshr "rm -rf $BASE/releases/$SHA && mkdir -p $BASE/releases/$SHA && tar --no-same-owner -xzf $BASE/uploads/$SHA.tgz -C $BASE/releases/$SHA && rm -f $BASE/uploads/$SHA.tgz"
    rm -rf "$PKG" "$PKG.tgz"

    sshr "bash -s -- $AMB $SHA" < "$RAIZ/bin/ativar-release.sh"
    ok "Front publicado ($SHA)"
  else
    ok "Front sem mudança desde a última publicação: nada a fazer"
  fi
fi
ok "Concluído."
