#!/usr/bin/env bash
# =============================================================================
# <PROJETO> — Deploy do backend Laravel (roda NO SERVIDOR, chamado pelo publicar.sh)
# Uso: ./bin/deploy-backend.sh [--permitir-destrutiva]
#   Migração pendente => manutenção + dump + foto antes/depois (passo 4/6).
#
# Modelo da skill deploy-github-actions-ssh. Banco: MySQL/MariaDB (DB_CONNECTION=mysql|mariadb)
# ou PostgreSQL (pgsql). Troque os valores marcados com <...>.
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[AVISO]${NC} $1"; }
error()   { echo -e "${RED}[ERRO]${NC} $1"; exit 1; }
step()    { echo ""; echo -e "${BLUE}━━━ $1 ━━━${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$REPO_ROOT/<backend>"          # "." se o Laravel está na raiz do repo
ARTISAN_CONFERIR="app:conferir-ambiente"
BK_DIR="${BACKUP_DIR:-<caminho-de-backups>/deploy}"
DONO_WEB="${DONO_WEB:-www-data}"

# ── 0. Código: git pull ───────────────────────────────────────────────────────
# `fileMode false`: o chmod do passo de permissões marcaria arquivos como modificados e travaria o
# pull. Depois do pull o script se reexecuta, porque o pull pode ter trocado este mesmo arquivo.
if [[ "${DEPLOY_JA_ATUALIZADO:-}" != "1" ]]; then
  git -C "$REPO_ROOT" config core.fileMode false
  info "git pull --ff-only (branch $(git -C "$REPO_ROOT" branch --show-current))"
  git -C "$REPO_ROOT" pull --ff-only || error "git pull falhou (alteração local no servidor ou histórico divergente). Resolva antes de repetir."
  success "Código em $(git -C "$REPO_ROOT" log --oneline -1)"
  DEPLOY_JA_ATUALIZADO=1 exec "$0" "$@"
fi

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" && { nvm use 20 >/dev/null 2>&1 || true; }

# ── 1. Estrutura ──────────────────────────────────────────────────────────────
step "1/6 Validando arquivos do Laravel"
[[ -f "$BACKEND_DIR/artisan" ]] || error "artisan não encontrado em $BACKEND_DIR"
[[ -f "$BACKEND_DIR/.env" ]] || error "$BACKEND_DIR/.env não existe. Crie-o antes do deploy."
cd "$BACKEND_DIR"

# ── 2. Dependências + conferência do .env (antes de migrar) ───────────────────
step "2/6 Composer e conferência do .env"
composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev
php artisan "$ARTISAN_CONFERIR" --sem-banco || error "O .env deste servidor não passou na conferência (acima). Nada foi migrado. Corrija o .env e repita."

# ── 3. Assets (Vite) — remova se o backend não tem front próprio ──────────────
step "3/6 Assets (Vite)"
if [[ -f package.json ]]; then npm ci --prefer-offline --no-audit --no-fund && npm run build; fi

# ── 4. Migrações pendentes, com rede de proteção ──────────────────────────────
# a) recusa migração destrutiva sem --permitir-destrutiva; b) manutenção; c) dump conferido;
# d) foto antes; e) migra, foto depois, compara. Falha = site FICA em manutenção, de propósito.
step "4/6 Migrações pendentes"
PERMITIR_DESTRUTIVA=0
[[ "${1:-}" == "--permitir-destrutiva" ]] && PERMITIR_DESTRUTIVA=1

PENDENTES="$(php artisan migrate:status --pending --no-ansi 2>/dev/null | grep -c 'Pending' || true)"
if [[ "${PENDENTES:-0}" -eq 0 ]]; then
  success "Nenhuma migração pendente."
else
  info "$PENDENTES migração(ões) pendente(s)."

  # Credenciais vindas do .env, nunca impressas.
  env_get() { grep -E "^$1=" .env | tail -1 | cut -d= -f2- | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//"; }
  CONN="$(env_get DB_CONNECTION)"; DB_HOST_="$(env_get DB_HOST)"; DB_PORT_="$(env_get DB_PORT)"
  DB_NAME_="$(env_get DB_DATABASE)"; DB_USER_="$(env_get DB_USERNAME)"; SENHA="$(env_get DB_PASSWORD)"
  [[ -n "$DB_NAME_" && -n "$DB_USER_" ]] || error "DB_DATABASE/DB_USERNAME ausentes no .env."
  case "$CONN" in
    pgsql)
      export PGPASSWORD="$SENHA"
      PG=(-h "${DB_HOST_:-127.0.0.1}" -p "${DB_PORT_:-5432}" -U "$DB_USER_" -d "$DB_NAME_")
      sql()  { psql "${PG[@]}" -At -c "$1"; }
      dump() { pg_dump "${PG[@]}" --no-owner; }
      TABELAS="select table_name from information_schema.tables where table_schema='public' and table_type='BASE TABLE' order by 1"
      COLUNAS="select table_name||chr(9)||column_name from information_schema.columns where table_schema='public' order by 1"
      RESTAURAR="gunzip -c <dump> | psql -U <usuario> $DB_NAME_" ;;
    *)
      export MYSQL_PWD="$SENHA"
      MY=(-h "${DB_HOST_:-127.0.0.1}" -P "${DB_PORT_:-3306}" -u "$DB_USER_")
      sql()  { mysql "${MY[@]}" -N -e "$1" "$DB_NAME_"; }
      dump() { mysqldump "${MY[@]}" --single-transaction --no-tablespaces --routines --triggers "$DB_NAME_"; }
      TABELAS="select table_name from information_schema.tables where table_schema='$DB_NAME_' and table_type='BASE TABLE' order by 1"
      COLUNAS="select table_name, column_name from information_schema.columns where table_schema='$DB_NAME_' order by 1,2"
      RESTAURAR="gunzip -c <dump> | mysql -u<usuario> -p $DB_NAME_" ;;
  esac

  # a) Migração que apaga dado não roda sozinha.
  SQL_PREVIA="$(php artisan migrate --pretend --no-ansi 2>&1 || true)"
  if echo "$SQL_PREVIA" | grep -Eiq '(drop[[:space:]]+(table|column|database|index)|truncate|delete[[:space:]]+from|alter[[:space:]]+table.*drop[[:space:]])'; then
    echo "$SQL_PREVIA" | grep -Ei 'drop|truncate|delete' || true
    [[ "$PERMITIR_DESTRUTIVA" -eq 1 ]] || error "Migração DESTRUTIVA. Nada foi alterado. Revise e rode: ./bin/deploy-backend.sh --permitir-destrutiva"
    warn "--permitir-destrutiva informado: seguindo, com dump e conferência."
  fi

  # b) Manutenção. Projeto com flag própria de manutenção: troque estas duas funções.
  JA_EM_MANUTENCAO=0; [[ -f storage/framework/down ]] && JA_EM_MANUTENCAO=1
  ligar_manutencao()    { php artisan down --retry=60 >/dev/null; }
  desligar_manutencao() { php artisan up >/dev/null; }
  [[ "$JA_EM_MANUTENCAO" -eq 1 ]] || { ligar_manutencao; success "Manutenção LIGADA."; }

  # c) Dump + verificação.
  TS="$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BK_DIR" || error "Não consegui criar $BK_DIR."
  DUMP="$BK_DIR/${DB_NAME_}-pre-migracao-$TS.sql.gz"
  dump | gzip > "$DUMP"
  gzip -t "$DUMP" || error "Dump corrompido: $DUMP. Manutenção mantida."
  [[ "$(stat -c%s "$DUMP" 2>/dev/null || stat -f%z "$DUMP")" -gt 10240 ]] || error "Dump pequeno demais: $DUMP. Manutenção mantida."
  success "Backup: $DUMP"
  ls -1t "$BK_DIR"/"${DB_NAME_}"-pre-migracao-*.sql.gz 2>/dev/null | tail -n +11 | xargs -r rm -f

  # d) Foto do banco: linhas por tabela + colunas.
  foto() {
    : > "$1.linhas"
    while IFS= read -r t; do printf '%s\t%s\n' "$t" "$(sql "select count(*) from \"$t\"" 2>/dev/null || sql "select count(*) from \`$t\`")" >> "$1.linhas"; done < <(sql "$TABELAS")
    sql "$COLUNAS" > "$1.colunas"
  }
  ANTES="$BK_DIR/foto-antes-$TS"; DEPOIS="$BK_DIR/foto-depois-$TS"
  foto "$ANTES"

  falha_com_manutencao() {
    warn "SITE MANTIDO EM MANUTENÇÃO. Backup: $DUMP"
    warn "Restaurar: ${RESTAURAR/<dump>/$DUMP}"
    warn "Depois de resolver: php artisan up"
    exit 1
  }

  # e) Migração e conferência.
  php artisan migrate --force || { warn "A migração falhou."; falha_com_manutencao; }
  foto "$DEPOIS"
  PERDAS=""
  while IFS=$'\t' read -r t antes; do
    depois="$(awk -F'\t' -v t="$t" '$1==t {print $2}' "$DEPOIS.linhas")"
    if [[ -z "$depois" ]]; then PERDAS+=$'\n'"  tabela removida: $t ($antes linhas)"
    elif [[ "$depois" -lt "$antes" ]]; then PERDAS+=$'\n'"  linhas a menos em $t: $antes -> $depois"; fi
  done < "$ANTES.linhas"
  COL="$(comm -23 <(sort "$ANTES.colunas") <(sort "$DEPOIS.colunas") | awk -F'\t' '{print "  coluna removida: "$1"."$2}')"
  [[ -n "$COL" ]] && PERDAS+=$'\n'"$COL"
  [[ -z "$PERDAS" ]] || { warn "A MIGRAÇÃO REMOVEU DADO:$PERDAS"; falha_com_manutencao; }
  success "Migrações aplicadas e conferidas: nenhuma linha, tabela ou coluna perdida."

  [[ "$JA_EM_MANUTENCAO" -eq 1 ]] || { desligar_manutencao; success "Manutenção DESLIGADA."; }
  unset MYSQL_PWD PGPASSWORD
fi

# ── 5. Caches ─────────────────────────────────────────────────────────────────
step "5/6 Caches do Laravel"
[[ -L public/storage ]] || php artisan storage:link
php artisan optimize:clear

# ── 6. Permissões ─────────────────────────────────────────────────────────────
step "6/6 Permissões"
chown -R "$DONO_WEB:$DONO_WEB" storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

info "Conferência final (banco, migrações, pastas)"
php artisan "$ARTISAN_CONFERIR" || error "Código publicado, mas a conferência final falhou (acima). Verifique antes de liberar."
success "Deploy do backend concluído."
