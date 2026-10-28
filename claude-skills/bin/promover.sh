#!/usr/bin/env bash
# =============================================================================
# Traz para o repo central uma skill que hoje vive num projeto ou num perfil.
#
# Uso: bin/promover.sh <pasta-da-skill> <categoria>
#   ex.: bin/promover.sh ~/develop/x/.claude/skills/minha-skill global
#        bin/promover.sh ~/develop/x/.claude/skills/minha-skill stack/web
#
# Só COPIA para skills/<categoria>/<nome>/. A origem fica intacta. Depois:
#   1. revise/generalize o SKILL.md (sem dado de cliente);
#   2. commite aqui;
#   3. global → bin/instalar-perfis.sh (a cópia antiga do perfil vai para o backup);
#      outra categoria → acrescente ao projetos/<projeto>.yml e rode bin/instalar.sh <projeto>
#      (antes, mova a pasta local do projeto para fora, senão o instalar.sh acusa conflito).
# =============================================================================
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_comum.sh"

[[ $# -eq 2 ]] || { sed -n '2,15p' "$0"; exit 1; }
origem="$(cd "$1" && pwd)"; cat_="$2"; nome="$(basename "$origem")"
[[ -f "$origem/SKILL.md" ]] || erro "$origem não tem SKILL.md"
existente="$(skill_por_nome "$nome")"
[[ -z "$existente" ]] || erro "já existe uma skill com esse nome no repo: ${existente#$REPO/} (nome precisa ser único)"
destino="$REPO/skills/$cat_/$nome"
mkdir -p "$(dirname "$destino")"
rsync -a --exclude .DS_Store --exclude node_modules "$origem/" "$destino/"
ok "Copiada para skills/$cat_/$nome. Origem intacta. Próximos passos no cabeçalho deste script."
