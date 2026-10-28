#!/usr/bin/env bash
# =============================================================================
# Conferência do .env para projeto SEM Laravel (Node, Python, estático). Roda NO SERVIDOR antes do
# restart. Mostra nome de variável e host, nunca valor. Sai com 1 se algo falhar.
#
# Uso: bin/conferir-env.sh <stage|prod> [caminho/.env]
# Contrato (versionado no projeto):
#   deploy/env-obrigatorio.todos.txt      uma variável por linha (# comenta)
#   deploy/env-obrigatorio.<amb>.txt      obrigatórias só daquele ambiente
#   deploy/env-vazio.prod.txt             precisam ficar VAZIAS em produção (ex.: MAIL_REDIRECT_TO)
#   deploy/hosts-producao.txt             hosts de produção (proibidos fora de prod)
# Em prod, nenhuma variável *_URL pode ter localhost, 127.0.0.1, "homo", "stage" ou ".develop".
#
# Modelo da skill deploy-github-actions-ssh.
# =============================================================================
set -euo pipefail
AMB="${1:?stage|prod}"; ENV="${2:-.env}"
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$RAIZ/deploy"
FALHAS=0
falha() { echo "[FALHA] $1"; FALHAS=$((FALHAS + 1)); }
lista() { [[ -f "$1" ]] && grep -vE '^\s*(#|$)' "$1" || true; }
valor() { grep -E "^$1=" "$ENV" | tail -1 | cut -d= -f2- | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//"; }

[[ -f "$ENV" ]] || { echo "[FALHA] $ENV não encontrado"; exit 1; }
echo "Ambiente: $AMB ($ENV)"

for n in $(lista "$D/env-obrigatorio.todos.txt") $(lista "$D/env-obrigatorio.$AMB.txt"); do
  [[ -n "$(valor "$n" | tr -d '[:space:]')" ]] || falha "$n ausente ou vazia"
done

if [[ "$AMB" == prod ]]; then
  for n in $(lista "$D/env-vazio.prod.txt"); do
    [[ -z "$(valor "$n" | tr -d '[:space:]')" ]] || falha "$n preenchida em produção (precisa ficar vazia)"
  done
fi

while IFS= read -r linha; do
  nome="${linha%%=*}"
  host="$(valor "$nome" | sed -E 's|^[a-z]+://||; s|[/:].*$||' | tr 'A-Z' 'a-z')"
  [[ -z "$host" ]] && continue
  if [[ "$AMB" == prod ]]; then
    [[ "$host" =~ (localhost|127\.0\.0\.1|homo|stage|\.develop$) ]] && falha "$nome aponta para fora de produção ($host)"
  else
    lista "$D/hosts-producao.txt" | grep -qxF "$host" && falha "$nome aponta para produção ($host)"
  fi
done < <(grep -E '^[A-Z0-9_]*URL[A-Z0-9_]*=' "$ENV" || true)

[[ "$FALHAS" -eq 0 ]] && { echo "[OK] Ambiente conferido."; exit 0; }
exit 1
