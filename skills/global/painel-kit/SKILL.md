---
name: painel-kit
description: Use when iniciando um projeto novo que tem painel administrativo (bootstrap de painel, "cria o painel", "novo projeto com admin", "quero um dashboard", escolher entre stack Laravel+Inertia ou Laravel API+Next.js) — padroniza o painel com os mesmos componentes shadcn/ui, o bloco de login login-02 e o bloco de sidebar sidebar-07, mais banco PostgreSQL local, portas e auth de usuário único por env.
---

# painel-kit

Todo painel administrativo do Alessandro nasce igual: mesmos componentes shadcn/ui, mesmo
visual de login (`login-02`), mesmo shell de sidebar (`sidebar-07`), banco PostgreSQL no
docker-compose local, usuário único com credenciais em `.env`.

Esta skill é o passo a passo executável. Não improvise componentes nem flags.

> **Status:** o fluxo `inertia` foi executado de verdade (painel de CRM em
> `~/develop/server/wordpress/alessandro/painel`, Laravel 13.31). Tudo marcado como
> "verificado em execução" abaixo saiu desse bootstrap real, incluindo os erros.
> O fluxo `split` ainda não foi executado ponta a ponta — ver avisos em `references/split.md`.

## 1. Decidir a variante

Pergunte (ou infira do contexto) e escolha **uma**:

| Sinal | Variante |
|---|---|
| Projeto interno, painel é o produto, um só deploy, quer velocidade | `inertia` |
| Já existe (ou vai existir) um front público em Next.js, ou o back vai servir app mobile / outros clientes, ou front e back têm deploys/repos separados | `split` |

- `inertia` → **Laravel 13 + Inertia 3 + React 19 + TypeScript + Vite (via `vite-plus`) +
  Tailwind 4 + shadcn/ui + Fortify**, **um repositório**.
  Passo a passo: `references/inertia.md`
- `split` → Laravel 13 como API (Sanctum) + Next.js (App Router) no front,
  **pastas/repos separados**.
  Passo a passo: `references/split.md`

Na dúvida, **`inertia`** é o padrão: menos peças, e o starter kit oficial já vem com
shadcn/ui configurado e ~26 componentes publicados.

Confirme a escolha com o usuário em uma linha antes de rodar qualquer comando.

## 2. Ordem de execução (sempre esta)

1. Decidir variante (passo 1).
2. Escolher e **registrar as portas** (seção "Portas").
3. Criar o banco e a role no PostgreSQL (seção "Banco").
4. Criar o projeto conforme `references/inertia.md` ou `references/split.md`.
5. **Consertar o `.env` antes de qualquer outra coisa** — o instalador termina com o build
   quebrado por causa do `APP_URL`. Ver "Primeiro passo pós-instalação".
6. Fixar `packageManager` no `package.json` (senão o shadcn CLI morre) e completar o kit de
   componentes — lista canônica em `references/componentes.md`.
7. Aplicar o visual dos blocos (`login-02` no layout de auth, `sidebar-07` na sidebar) —
   procedimento real em `references/inertia.md`.
8. Configurar auth de usuário único + seeder lendo `.env` (seção "Auth").
9. Criar a estrutura de rotas por módulo (seção "Rotas por módulo").
10. Rodar migrations + seeder, subir dev server, validar com o checklist final.

## 3. Primeiro passo pós-instalação: consertar o `APP_URL`

**Verificado em execução.** O `laravel new ... --react --npm` termina em erro: o build do
front falha no plugin `@laravel/vite-plugin-wayfinder`, porque o Vite chama
`php artisan wayfinder:generate` antes do `.env` estar válido.

A causa **não** é o Wayfinder. O instalador gravou um `APP_URL` malformado — na execução
real saiu `http://localhost:8000:8000` (porta duplicada). Com isso **todo** comando artisan
morre com:

```
Invalid URI: Host is malformed.
```

Conserto, na raiz do projeto novo, antes de tocar em mais nada:

```bash
# 1. olhe o valor gerado
grep '^APP_URL' .env

# 2. corrija para esquema + host + UMA porta, igual à porta do serve
#    (edite o .env; exemplo com a porta escolhida no passo "Portas")
APP_URL=http://localhost:8000

# 3. limpe a config e confirme o valor efetivo
php artisan config:clear
php artisan tinker --execute="echo config('app.url');"
```

Só depois disso rode `npm run build`. Regra permanente: **ao trocar a porta do `serve`,
troque o `APP_URL` junto e rode `config:clear`** — é a causa mais comum do erro voltar.

Diagnóstico rápido: se *qualquer* `php artisan` estiver estourando "Invalid URI", o
problema é `.env`/`APP_URL`, não o comando que você rodou.

## 4. Banco

Padrão: **PostgreSQL** do docker-compose local em `~/develop/server/wordpress`.

- container: `postgres`
- imagem: `postgres:17.2-alpine`
- porta exposta no host: `5432`
- superusuário do container: `kelnab` (é o `POSTGRES_USER` do compose — **não** existe role
  `postgres` garantida)
- database padrão do container: `kelnab` (não crie tabelas de projeto nele)

Regra: **cada projeto tem role e database próprios.**

Suba o container se preciso:

```bash
cd ~/develop/server/wordpress && docker compose up -d postgres
```

Crie role + database (comandos como foram executados; troque `meuprojeto` e a senha — a
senha vai para o `.env` do projeto, nunca para arquivo versionado):

```bash
docker exec postgres psql -U kelnab -d postgres -c \
  "CREATE ROLE meuprojeto WITH LOGIN PASSWORD 'senha-forte-aqui' CREATEDB;"
docker exec postgres psql -U kelnab -d postgres -c \
  "CREATE DATABASE meuprojeto OWNER meuprojeto;"
```

`CREATEDB` na role não é opcional: `php artisan test` cria um database de teste próprio e
falha sem essa permissão.

Confira dono e existência:

```bash
docker exec postgres psql -U kelnab -d postgres -tAc \
  "SELECT datname, pg_get_userbyid(datdba) FROM pg_database WHERE datname = 'meuprojeto';"
```

`.env` do Laravel:

```ini
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=meuprojeto
DB_USERNAME=meuprojeto
DB_PASSWORD=senha-forte-aqui
```

Atenção: o `.env.example` gerado pelo instalador traz `DB_DATABASE=<nome-do-app>` e
`DB_USERNAME=root`. Corrija na cópia — e deixe o `database/database.sqlite` criado pelo
instalador de lado (inofensivo, mas não é usado com `DB_CONNECTION=pgsql`).

## 5. Portas

O usuário roda vários projetos ao mesmo tempo. **Verifique antes de escolher** — na máquina
real a 8000 já estava ocupada por outro projeto no meio do bootstrap:

```bash
# quem está na porta que você quer
lsof -nP -iTCP:8000 -sTCP:LISTEN

# panorama geral
lsof -nP -iTCP -sTCP:LISTEN | awk '{print $1, $9}' | sort -u
```

Em uso conhecido (confira, não presuma):

| Porta | Uso |
|---|---|
| 3001 | Next.js do site pessoal (alessandromelo.com.br) |
| 8000 | painel Laravel (`php artisan serve` padrão) |
| 5173 | Vite dev server padrão |
| 5432 | PostgreSQL (docker) |
| 3306 | MySQL (docker) |
| 9000 / 9001 | MinIO (docker) |

Se precisar trocar:

- Laravel: `php artisan serve --port=8001` **e** `APP_URL=http://localhost:8001` no `.env`
  **e** `php artisan config:clear`. Os três, sempre.
- Vite: `npm run dev -- --port=5174`. Não precisa configurar nada no Laravel — o
  `laravel-vite-plugin` grava a URL do dev server em `public/hot`. Se o Vite morreu de
  forma abrupta e o arquivo ficou velho, `rm -f public/hot`.
- Next.js: `next dev -p 3002` (ou `npm run dev -- --port 3002`).

Registre a alocação no `README.md` do projeto novo, numa tabela `Porta | Serviço`, e
avise o usuário quais portas foram tomadas.

## 6. Auth

Padrão: **um único usuário administrador**. Sem registro público.

O starter kit React do Laravel 13 usa **Fortify**, já com 2FA e **passkeys** habilitados.
Não troque o backend de auth: as rotas (`GET/POST /login`, `POST /logout`, etc.) já existem.

### Desligar registro público (verificado em execução)

1. Comente a feature em `config/fortify.php`:

   ```php
   // Features::registration(),
   Features::resetPasswords(),
   Features::emailVerification(),
   ```

2. Apague o que o front tem de registro — o Wayfinder gera rotas em build time e
   referência a rota inexistente **quebra o build**:

   ```bash
   rm -f resources/js/pages/auth/register.tsx
   rm -rf resources/js/routes/register
   grep -rn "routes/register" resources/js
   ```

   O resto de `resources/js/routes/` é **gerado**: o Wayfinder regenera na próxima execução
   do Vite. Não edite esses arquivos à mão.

3. Confirme: `php artisan route:list | grep register` não retorna nada.

Opcional em painel single-user: comentar também `Features::resetPasswords()` e
`Features::emailVerification()` — e remover as referências correspondentes no front, pelo
mesmo motivo do Wayfinder. Se mantiver `resetPasswords()`, o `login-form.tsx` continua
podendo importar `request` de `@/routes/password`.

### Credenciais por env

Sempre por variável de ambiente, lidas por um seeder:

```ini
# .env  (nunca commitado)
PAINEL_ADMIN_NAME="Alessandro Melo"
PAINEL_ADMIN_EMAIL=admin@exemplo.com
PAINEL_ADMIN_PASSWORD=senha-forte-aqui
```

No `.env.example` (versionado) deixe apenas as chaves **vazias**:

```ini
PAINEL_ADMIN_NAME=
PAINEL_ADMIN_EMAIL=
PAINEL_ADMIN_PASSWORD=
```

`database/seeders/AdminUserSeeder.php`:

```php
<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        $email = config('painel.admin.email');
        $password = config('painel.admin.password');

        if (blank($email) || blank($password)) {
            throw new \RuntimeException(
                'AdminUserSeeder abortado: defina PAINEL_ADMIN_EMAIL e PAINEL_ADMIN_PASSWORD no .env.'
            );
        }

        User::updateOrCreate(
            ['email' => $email],
            [
                'name' => config('painel.admin.name', 'Admin'),
                'password' => Hash::make($password),
                'email_verified_at' => now(),
            ],
        );
    }
}
```

Leia via `config()` (com um `config/painel.php` mapeando os `env()`), não `env()` direto —
`env()` retorna `null` quando a config está em cache.

Registre em `DatabaseSeeder::run()`: `$this->call(AdminUserSeeder::class);` e rode:

```bash
php artisan migrate --seed
```

Regras duras:
- **Nunca** escrever senha em arquivo versionado (seeder, migration, README, docs, teste).
- **Nunca** senha hardcoded como fallback — sem env, o seeder **falha alto** em vez de
  criar credencial padrão.
- Confirme que `.env` está no `.gitignore` antes do primeiro commit.

## 7. Componentes

A lista canônica, o que já vem no starter kit e as duas armadilhas do CLI do shadcn
(corepack/pnpm e sobrescrita de arquivo) estão em `references/componentes.md`. Leia antes de
rodar qualquer `npx shadcn`.

Resumo do que mudou em relação à teoria:

- O starter kit **já vem com `components.json` e ~26 componentes** em
  `resources/js/components/ui/`. **Não rode `shadcn init`.**
- Antes do primeiro `npx shadcn@latest add`, fixe `"packageManager": "npm@10.9.2"` no
  `package.json` do projeto.
- Blocos (`login-02`, `sidebar-07`) **sobrescrevem** arquivos do starter kit e perguntam
  interativamente. Rode sempre `yes n | npx shadcn@latest add <bloco> --yes`.
- Os blocos são **referência visual**, não código para usar como veio. O procedimento de
  encaixe está em `references/inertia.md`.

## 8. Rotas por módulo

**Verificado em execução.** Um arquivo de rotas por módulo, incluídos por um `foreach` em
`routes/web.php`:

```
routes/
├── web.php
├── settings.php          # do starter kit
└── painel/
    ├── metrics.php
    ├── leads.php
    ├── clients.php
    └── ...
```

`routes/web.php`:

```php
Route::inertia('/', 'welcome')->name('home');

require __DIR__.'/settings.php';

foreach (['metrics', 'leads', 'clients', 'quotes', 'tools'] as $modulo) {
    require __DIR__."/painel/{$modulo}.php";
}
```

Cada arquivo de módulo agrupa o middleware:

```php
Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('leads', [LeadController::class, 'index'])->name('leads.index');
    // ...
});
```

Armadilha real: o starter kit registra um placeholder
`Route::inertia('dashboard', 'dashboard')->name('dashboard')` em `routes/web.php`. Quando o
módulo de dashboard entrar com o nome `dashboard`, **remova o placeholder** — duas rotas com
o mesmo nome fazem `php artisan route:cache` quebrar. Deixe um comentário no lugar dizendo
onde a rota foi morar.

Verifique sempre depois de mexer em rotas:

```bash
php artisan route:list | grep -E 'login|register|dashboard'
php artisan route:cache && php artisan route:clear
```

## 9. Como paralelizar o trabalho

**Verificado em execução** — o painel de CRM foi construído com agentes paralelos e o que
evitou retrabalho foi propriedade exclusiva de arquivos.

### Ordem obrigatória

1. **Um agente só de domínio, sozinho, antes de todos**: migrations, models, enums,
   factories e seeders. Nada de UI. Ele define os nomes de coluna, os enums de estágio/status
   e os métodos que centralizam mudança de estado (ex.: `Lead::moverPara()`,
   `Quote::recalcularTotal()`).
2. **Depois**, um agente por módulo, em paralelo.

Fatiar por módulo antes do domínio existir garante conflito de migration e model duplicado.

### Regra de propriedade de arquivos

Cada agente de módulo é dono **exclusivo** de:

- `routes/painel/<modulo>.php`
- `app/Http/Controllers/Painel/<Modulo>*Controller.php`
- `app/Http/Requests/<Modulo>/*`
- `resources/js/pages/<modulo>/*`

E é **proibido** de tocar em:

- `routes/web.php` (o orquestrador acrescenta o nome no `foreach`, uma vez)
- `app/Models/*`, `app/Enums/*`, `database/migrations/*` (donos: agente de domínio)
- `resources/js/components/ui/*` (kit compartilhado)
- `resources/js/components/app-sidebar.tsx`, `nav-main.tsx`, layouts (shell compartilhado)
- `config/*`, `.env`, `package.json`, `composer.json`

Se um agente de módulo precisar de coluna nova, campo em enum ou item na sidebar, ele
**reporta** ao orquestrador em vez de editar. O orquestrador aplica.

### Fechamento

Depois que os agentes de módulo terminam, o orquestrador roda uma passada única de
integração: `foreach` do `web.php`, itens da sidebar, `npx tsc --noEmit`, `npm run build`,
`vendor/bin/pint`, `php artisan test`.

## 10. Armadilhas de métrica

Duas lições que só apareceram com dados reais no painel. Se o painel tem funil ou tempo por
estágio, decida as duas **antes** de escrever as queries e escreva a decisão na doc.

### (a) Sem evento de nascimento, o funil não tem denominador

Se o model só grava evento de estágio na **transição** (`de` → `para`), um registro que
nasce no primeiro estágio não tem nenhum evento com `para = <primeiro estágio>`. Efeito:

- tempo médio no primeiro estágio sai `0.0` dias com `0` entradas — o tempo até o primeiro
  contato simplesmente não é medido;
- a taxa de conversão desde o topo usa a entrada no primeiro estágio como denominador →
  denominador zero → **todas as taxas saem `0.0`** e parecem bug de cálculo.

Escolha uma e implemente:

1. o `store` grava um evento inicial (`de = null`, `para = <primeiro estágio>`, em
   `created_at`) — recomendado, mantém uma só fonte de verdade; ou
2. as duas métricas leem `<tabela>.created_at` como entrada no primeiro estágio.

Não deixe as duas nem nenhuma. E proteja toda divisão: denominador zero devolve `0.0`
explícito, nunca `null` na tela nem divisão por zero.

### (b) `COALESCE(proximo_evento, now())` mede permanência em aberto

Tempo médio por estágio costuma ser calculado com janela:

```sql
LEAD(ocorreu_em) OVER (PARTITION BY lead_id ORDER BY ocorreu_em) AS proximo_em
-- duração = ocorreu_em .. COALESCE(proximo_em, now())
```

Isso tem duas semânticas possíveis e você precisa escolher:

- **Incluindo aberto** (`COALESCE(..., now())`): responde "quanto tempo se leva neste
  estágio, contando quem está travado lá agora". Um registro parado empurra a média para
  cima — em geral é o que se quer num painel comercial. Custo: **a média muda a cada
  consulta mesmo sem nenhum evento novo**, então não é comparável entre dois momentos e não
  serve para snapshot histórico.
- **Só transições fechadas** (descartar `proximo_em IS NULL`): média estável e reproduzível,
  mas cega para o gargalo atual — justamente os registros travados ficam de fora.

Regras que valem nas duas:

- a janela `LEAD()` roda sobre **todos** os eventos do registro; o recorte de período é
  aplicado depois, sobre a entrada no estágio. Filtrar antes corta a duração na borda.
- estágios finais ficam fora (deles não se sai).
- um registro que passou duas vezes pelo mesmo estágio conta duas entradas.
- estágio sem entrada aparece com `0.0` e `0`, para a tabela ter todas as linhas.

Escreva a escolha na doc de métricas, ao lado da query. Sem isso, alguém vai reportar a
média como bug.

## 11. Checklist final de verificação

Rode e confirme cada item antes de dizer que o painel está pronto.

**Ambiente e banco**

- [ ] `docker exec postgres psql -U kelnab -d postgres -tAc "SELECT datname, pg_get_userbyid(datdba) FROM pg_database WHERE datname='<projeto>'"` devolve `<projeto>|<role>`
- [ ] `php artisan tinker --execute="echo config('app.url');"` imprime esquema + host + **uma** porta, igual à do `serve`
- [ ] `php artisan about` roda sem `Invalid URI` (prova que o `.env` está válido)
- [ ] `php artisan migrate:status` — todas as migrations rodaram
- [ ] `php artisan db:seed --class=AdminUserSeeder` roda duas vezes seguidas sem duplicar usuário

**Segredos**

- [ ] `grep -rn "PAINEL_ADMIN_PASSWORD" --include='*.php' --include='*.ts' --include='*.tsx' .` só aparece em `config/painel.php` e no seeder, sem valor literal
- [ ] `git check-ignore -v .env` retorna match
- [ ] `grep -E '^PAINEL_ADMIN' .env.example` mostra as chaves **vazias**

**Componentes**

- [ ] `cat components.json` existe, `aliases.ui` = `@/components/ui`, `tailwind.css` = `resources/css/app.css`
- [ ] todos os componentes de `references/componentes.md` existem em `resources/js/components/ui/` (use o loop de verificação do arquivo)
- [ ] `grep -rn "from 'cn'" resources/js` **não retorna nada** (import errado que o bloco `sidebar-07` traz)
- [ ] `npm ls @tanstack/react-table` resolve
- [ ] `"packageManager"` está fixado no `package.json`

**Shell e login**

- [ ] existe **uma** sidebar (`app-sidebar.tsx`) com `collapsible="icon"`, e não sobrou cópia duplicada do bloco
- [ ] `resources/js/layouts/app-layout.tsx` aponta para o layout de sidebar; `auth-layout.tsx` aponta para `auth/auth-split-layout`
- [ ] `auth-split-layout.tsx` está em duas colunas (`grid min-h-svh lg:grid-cols-2`)
- [ ] `login-form.tsx` usa o `<Form>` do Inertia com `errors`, `status`, `remember` — **não** `<a href>` nem OAuth
- [ ] não existe `resources/js/pages/login.tsx` genérica sobrando (a página real é `pages/auth/login.tsx`)
- [ ] item ativo da sidebar acende na navegação (comparação por `usePage().url`)

**Rotas e auth**

- [ ] `php artisan route:list | grep register` não retorna nada, e `/register` dá 404
- [ ] `grep -rn "routes/register" resources/js` não retorna nada
- [ ] `php artisan route:cache` passa (prova que não há nome de rota duplicado), seguido de `php artisan route:clear`
- [ ] cada módulo tem seu `routes/painel/<x>.php` e o `foreach` do `web.php` lista todos

**Build e execução**

- [ ] `npm run build` passa
- [ ] `npm run types:check` (ou `npx tsc --noEmit`) passa
- [ ] `npm run check` (lint do front) passa
- [ ] `vendor/bin/pint --test` limpo e `composer run types:check` (PHPStan) limpo
- [ ] `php artisan test` passa
- [ ] `/login` abre e o login com as credenciais do `.env` entra no painel
- [ ] portas escolhidas estão numa tabela no `README.md` e não colidem com o que o `lsof` mostrou
- [ ] dark mode funciona (alternar no `appearance-tabs`)

## Notas de exatidão

- Fluxo `inertia` **executado de verdade** em setembro de 2026: `laravel new` gerou
  **Laravel 13.31**, Inertia 3, React 19, Tailwind 4, Vite dentro do pacote `vite-plus`
  (scripts npm chamam `vp`), auth por Fortify com 2FA e passkeys.
- Erros de instalação documentados aqui foram reproduzidos e resolvidos, não inferidos.
- `login-02` e `sidebar-07` existem no registry do shadcn — mas o que eles geram não serve
  como veio; ver `references/inertia.md`.
- Fluxo `split` **não** foi executado; pontos não confirmados estão marcados com
  **INCERTO** em `references/split.md`.
