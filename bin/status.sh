#!/usr/bin/env bash
# =============================================================================
# Mostra, por perfil e por projeto, o estado de cada skill do repo:
#   ok          symlink para este repo
#   solta=      pasta real com o mesmo conteúdo do repo (cópia; não recebe as mudanças)
#   solta≠      pasta real DIVERGENTE do repo (alguém editou a cópia, ou o repo andou)
#   outro-link  symlink para outro lugar
#   falta       não existe
#   quebrado    symlink para o repo que não aponta para nada (skill movida/renomeada)
# E, no fim, se há mudança não commitada no repo (edição feita por dentro de um projeto).
#
# Uso: bin/status.sh [-v]     (-v lista também as skills ok)
# =============================================================================
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_comum.sh"
VERBOSO=0; [[ "${1:-}" == "-v" ]] && VERBOSO=1

estado() { # estado <destino> <alvo-no-repo>
  local d="$1" a="$2"
  if [[ -L "$d" ]]; then
    if [[ "$(readlink "$d")" == "$a" ]]; then [[ -e "$d" ]] && echo ok || echo quebrado
    else echo outro-link; fi
  elif [[ -e "$d" ]]; then
    if [[ -d "$a" ]]; then igual "$d" "$a" && echo "solta=" || echo "solta≠"
    else cmp -s "$d" "$a" && echo "solta=" || echo "solta≠"; fi
  else echo falta; fi
}

# resumo <rótulo> <linhas "estado nome">
resumo() {
  local rot="$1" linhas="$2" n_ok
  n_ok="$(grep -c '^ok ' <<< "$linhas" || true)"
  printf '  %-34s ok=%-3s' "$rot" "$n_ok"
  local outros; outros="$(grep -v '^ok ' <<< "$linhas" | grep -v '^$' | awk '{a[$1]=a[$1]" "$2} END{for(k in a) printf " | %s:%s", k, a[k]}')"
  printf '%s\n' "${outros:- | tudo ligado}"
  [[ "$VERBOSO" -eq 1 ]] && grep '^ok ' <<< "$linhas" | awk '{printf "      ok %s\n", $2}'
  return 0
}

echo "== Repo: $(curto "$REPO")"

echo ""
echo "== Perfis (skills globais: $(skills_globais | xargs -n1 basename | tr '\n' ' '))"
while IFS= read -r dest; do
  linhas=""
  while IFS= read -r s; do linhas+="$(estado "$dest/$(basename "$s")" "$s") $(basename "$s")"$'\n'; done < <(skills_globais)
  resumo "$(curto "$dest")" "$linhas"
  # Skills do repo que NÃO são globais mas aparecem soltas no perfil (sombreiam a do projeto).
  for s in "$REPO"/skills/*/*/ "$REPO"/skills/stack/*/*/; do
    s="${s%/}"; [[ -f "$s/SKILL.md" ]] || continue
    case "$s" in "$REPO"/skills/global/*) continue ;; esac
    n="$(basename "$s")"
    [[ -e "$dest/$n" || -L "$dest/$n" ]] && printf '      fora-do-global: %s (%s) — sombreia a versão ligada no projeto\n' "$n" "$(estado "$dest/$n" "$s")"
  done
  # Links para o repo que não apontam para skill existente.
  for l in "$dest"/*; do
    [[ -L "$l" ]] || continue
    case "$(readlink "$l")" in "$REPO"/*) [[ -e "$l" ]] || printf '      quebrado: %s\n' "$(basename "$l")" ;; esac
  done
done < <(destinos_skills)

echo ""
echo "== Regras globais (regras/CLAUDE-global.md)"
while IFS= read -r e; do
  x="$(expandir "$e")"
  if [[ ! -d "$(dirname "$x")" ]]; then printf '  %-34s (CLI não instalado)\n' "$(curto "$x")"; continue; fi
  printf '  %-34s %s\n' "$(curto "$x")" "$(estado "$x" "$REPO/regras/CLAUDE-global.md")"
done < <(yml_lista "$REPO/perfis.yml" regras_destinos)

echo ""
echo "== Projetos (manifesto projetos/*.yml; as globais vêm pelo perfil)"
for man in "$REPO"/projetos/*.yml; do
  nome="$(basename "$man" .yml)"
  caminho="$(expandir "$(yml_valor "$man" caminho)")"
  if [[ ! -d "$caminho" ]]; then printf '  %-34s pasta não encontrada (%s)\n' "$nome" "$caminho"; continue; fi
  linhas=""
  while IFS= read -r s; do
    [[ -n "$s" ]] || continue
    linhas+="$(estado "$caminho/.claude/skills/$(basename "$s")" "$REPO/skills/$s") $(basename "$s")"$'\n'
  done < <(yml_lista "$man" skills)
  locais=""
  while IFS= read -r l; do
    [[ -n "$l" ]] || continue
    if [[ -d "$caminho/.claude/skills/$l" && ! -L "$caminho/.claude/skills/$l" ]]; then locais+=" $l"; else locais+=" $l(FALTA)"; fi
  done < <(yml_lista "$man" locais)
  if [[ -z "$linhas" ]]; then printf '  %-34s só globais' "$nome"; else resumo "$nome" "$linhas" | tr -d '\n'; fi
  printf '%s\n' "${locais:+ | locais:$locais}"
done

echo ""
echo "== Mudanças não commitadas no repo"
pend="$(git -C "$REPO" status --porcelain 2>/dev/null)"
if [[ -z "$pend" ]]; then echo "  nenhuma"; else echo "$pend" | sed 's/^/  /'; echo "  -> commite no repo central (a edição feita num projeto cai aqui)."; fi
