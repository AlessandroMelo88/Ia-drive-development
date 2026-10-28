# Variante `inertia`

Laravel + Inertia + React + TypeScript + Vite + Tailwind 4 + shadcn/ui, **tudo em um
repositório**.

**Executado de verdade** em setembro de 2026. O que o `laravel new --react` gerou:

| Peça | Versão real |
|---|---|
| `laravel/framework` | **13.31** (`^13.17` no composer.json) |
| `inertiajs/inertia-laravel` + `@inertiajs/react` | **3.x** |
| React | 19 |
| TypeScript | 5.7 |
| Tailwind | 4 |
| Build | Vite 8 embalado no pacote **`vite-plus`** — os scripts npm chamam **`vp`**, não `vite` |
| Auth | **`laravel/fortify` ^1.37** com 2FA (`input-otp`) e **passkeys** (`@laravel/passkeys`) |
| Rotas no front | `laravel/wayfinder` + `@laravel/vite-plugin-wayfinder` (gera `resources/js/routes/`) |
| Extras | `laravel/chisel`, `laravel/pao`, `larastan`, `@tanstack/react-table` v9, `recharts` v3 |

Não escreva "Laravel 12" nem espere `"dev": "vite"` no `package.json`.

## 1. Pré-requisito: instalador do Laravel

```bash
composer global require laravel/installer
laravel --version
```

Requisitos que valeram na prática: PHP 8.4 (mínimo 8.3, com `pdo_pgsql`, `mbstring`,
`openssl`, `curl`, `intl`, `zip`), Composer 2.x, Node 20+, npm 10.9.2, Docker rodando.

## 2. Criar o projeto

Comando **exato** usado:

```bash
cd ~/develop/server/wordpress/<projeto>   # onde o painel vai morar
laravel new painel --react --database=pgsql --no-interaction --npm
```

`--no-interaction` evita todos os prompts (starter kit, testes, banco, git). Flags do
instalador que existem e são úteis:

| Flag | Efeito |
|---|---|
| `--react` | React Starter Kit (Inertia + React + TS + Tailwind + shadcn/ui + Fortify) |
| `--vue`, `--livewire` | outros starter kits (não usamos) |
| `--database=pgsql` | driver do banco — **confirmado, valor aceito** |
| `--npm` (ou `--pnpm` / `--bun` / `--yarn`) | instala e builda o front |
| `--no-node` | pula o front (usado na variante `split`, no backend) |
| `--no-interaction` | assume os defaults, sem prompt |
| `--pest` / `--phpunit` | framework de testes (o default veio PHPUnit 12) |
| `--git` | inicializa repositório git — **não use** se o painel vive dentro de um repo maior |
| `--workos`, `--teams`, `--no-authentication` | **não usar** (auth local, usuário único, queremos o login) |
| `--force` / `-f` | instala sobre diretório existente |

**O comando vai terminar em erro.** É esperado — ver passo 3.

## 3. Consertar o `.env` (o erro que o instalador deixa)

Sintoma no fim da instalação: o build do front falha em
`@laravel/vite-plugin-wayfinder`, porque o plugin roda `php artisan wayfinder:generate`.

Causa raiz: o instalador gravou `APP_URL=http://localhost:8000:8000` (porta duplicada), e
com `APP_URL` inválido **todo** comando artisan morre com `Invalid URI: Host is malformed.`
Não é bug do Wayfinder.

```bash
cd painel
grep '^APP_URL' .env      # confira o estrago
# edite o .env: APP_URL=http://localhost:8000  (esquema + host + UMA porta)
php artisan config:clear
php artisan tinker --execute="echo config('app.url');"
php artisan about          # se isto roda, o .env está válido
```

Enquanto o `APP_URL` estiver errado, nada mais funciona: nem `migrate`, nem
`route:list`, nem `npm run build`. Faça isto **primeiro**.

## 4. Banco e `.env`

Siga a seção "Banco" do `SKILL.md` (role com `CREATEDB` + database próprios no container
`postgres`, superusuário `kelnab`) e preencha:

```ini
APP_NAME="Painel <Projeto>"
APP_URL=http://localhost:8000

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=meuprojeto
DB_USERNAME=meuprojeto
DB_PASSWORD=senha-forte-aqui

PAINEL_ADMIN_NAME="Alessandro Melo"
PAINEL_ADMIN_EMAIL=admin@exemplo.com
PAINEL_ADMIN_PASSWORD=senha-forte-aqui
```

O `.env.example` gerado traz `DB_DATABASE=painel` e `DB_USERNAME=root` — corrija na cópia.
O `database/database.sqlite` criado pelo instalador não é usado; só garanta que
`DB_CONNECTION` não voltou para `sqlite`.

## 5. Fixar o gerenciador de pacotes (obrigatório antes do shadcn)

**Verificado em execução.** `npx shadcn@latest add ...` morre antes de instalar nada, com:

```
Cannot find module '.../corepack/v1/pnpm/12.3.4/bin/pnpm.cjs'
```

O CLI do shadcn detecta o gerenciador de pacotes do projeto, acha pnpm (o starter kit deixa
um `pnpm-workspace.yaml` na raiz) e cai num shim quebrado do corepack. **Não é versão do
shadcn** — testado com 4.20.0, mesmo erro.

Correção que funcionou: fixar o gerenciador no `package.json` do projeto.

```json
"packageManager": "npm@10.9.2"
```

Depois:

```bash
npm install
```

Não troque essa linha por `pnpm@...` e não instale dependências deste projeto com
`pnpm install`. O `pnpm-workspace.yaml` é resíduo do template.

O projeto também vem com `.npmrc` contendo `ignore-scripts=true`. Se faltar binário nativo
(esbuild, lightningcss, oxide do Tailwind), rode `npm rebuild <pacote>` para aquele pacote.

## 6. shadcn/ui — o kit já vem instalado

O starter kit React **já traz** `components.json` e ~26 componentes em
`resources/js/components/ui/`. **Não rode `shadcn init`** — só `add` do que falta.

`components.json` gerado (use como fonte da verdade, não escreva à mão):

```json
{
  "style": "new-york",
  "rsc": false,
  "tsx": true,
  "tailwind": { "config": "", "css": "resources/css/app.css", "baseColor": "neutral", "cssVariables": true },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  },
  "iconLibrary": "lucide"
}
```

Note que `tailwind.config` é **string vazia** — Tailwind 4 configura por CSS
(`resources/css/app.css`), não por arquivo JS.

Confira o que já existe antes de instalar nada:

```bash
ls resources/js/components/ui
```

A lista canônica, o comando de `add` e a verificação estão em `componentes.md`.

## 7. Instalar componentes e blocos sem estragar o starter kit

**Verificado em execução.** O CLI do shadcn sobrescreve arquivos existentes e pergunta
interativamente arquivo por arquivo. Num starter kit isso destrói componentes que já estão
ligados ao Inertia/Fortify.

Padrão para blocos:

```bash
yes n | npx shadcn@latest add login-02 --yes
yes n | npx shadcn@latest add sidebar-07 --yes
```

- `--yes` pula a confirmação inicial de instalação;
- `yes n |` responde **não** a cada pergunta de conflito, então nenhum arquivo existente é
  sobrescrito **e os arquivos novos ainda são criados**.

Componentes simples que faltam podem ir num `add` único (não colidem com nada):

```bash
npx shadcn@latest add <lista de componentes que faltam>
npm ls @tanstack/react-table   # já vem no starter kit (v9); só instale se faltar
```

### Consertar o que o bloco trouxe errado

Os blocos vêm com imports que não valem neste projeto. Rode isto depois de **cada** bloco:

```bash
# 1. imports de `cn` vindos do pacote npm errado (o sidebar-07 trouxe 13 arquivos assim)
grep -rln "from 'cn'" resources/js
# corrigir todos para:  import { cn } from '@/lib/utils';

# 2. caminhos absolutos errados gerados pelo bloco
grep -rn "@/resources/js/" resources/js
# @/resources/js/routes -> @/routes ; @/resources/js/types -> @/types

# 3. o pacote npm `cn` entrou no package.json como dependência inútil
npm ls cn
```

Depois de limpar, `npm run types:check` é o juiz.

## 8. Encaixar o `login-02` (o que realmente funciona)

**O bloco não serve como veio.** `login-02` gera `pages/login.tsx` +
`components/login-form.tsx` com `<a href>` de navegação cheia, botões de OAuth e nenhum
vínculo com Fortify. Usar isso como está perde validação, `status`, "lembrar de mim",
passkey e SPA.

Procedimento verificado:

1. **Aproveite só o layout de duas colunas.** Aplique o desenho do `login-02` em
   `resources/js/layouts/auth/auth-split-layout.tsx`: `grid min-h-svh lg:grid-cols-2`,
   formulário na coluna esquerda, cover na direita (no painel real o cover é um gradiente da
   marca, sem asset externo — evita imagem quebrada e peso de download).

2. **Aponte o layout de auth para ele:**

   ```ts
   // resources/js/layouts/auth-layout.tsx
   import AuthLayoutTemplate from '@/layouts/auth/auth-split-layout';
   ```

3. **Substitua o conteúdo do `components/login-form.tsx`** pelo formulário Inertia real do
   starter kit — mantendo tudo que o Fortify precisa:

   ```tsx
   import { Form } from '@inertiajs/react';
   import { store } from '@/routes/login';
   import { request } from '@/routes/password';
   // + InputError, PasswordInput, PasskeyVerify, Checkbox, Spinner, TextLink

   <Form {...store.form()} resetOnSuccess={['password']}>
     {({ processing, errors }) => ( /* email, senha, remember, submit */ )}
   </Form>
   ```

   Itens que **não** podem sair: `errors.email` / `errors.password` via `InputError`, a
   mensagem `status` do Fortify, o `Checkbox name="remember"`, o link de recuperação
   (`request()`) e o `<PasskeyVerify />`.

4. **Apague a página genérica do bloco:**

   ```bash
   rm -f resources/js/pages/login.tsx
   ```

   A página de login de verdade é `resources/js/pages/auth/login.tsx` (do starter kit); ela
   passa `status` e `canResetPassword` para o `LoginForm`.

5. Não troque o backend de auth. Fortify já expõe `GET/POST /login`, `POST /logout`, 2FA e
   passkeys.

Referência real: `resources/js/layouts/auth/auth-split-layout.tsx` e
`resources/js/components/login-form.tsx` do painel do Alessandro.

## 9. Encaixar o `sidebar-07` (consolidar, não empilhar)

**O bloco duplica o starter kit.** `sidebar-07` gera `app-sidebar.tsx`, `nav-main.tsx`,
`nav-user.tsx`, `nav-projects.tsx`, `team-switcher.tsx` e um `use-mobile` — sendo que
`app-sidebar.tsx`, `nav-main.tsx`, `nav-user.tsx` e o hook de mobile **já existem** no kit,
ligados ao Inertia. Além disso gera imports errados (`@/resources/js/routes`,
`@/resources/js/types`) e o `cn` do pacote npm errado.

Consolidação verificada — o resultado é **uma** sidebar:

1. Fique com **um** `resources/js/components/app-sidebar.tsx`, com o comportamento do bloco
   (`<Sidebar collapsible="icon">` + `<SidebarRail />`) e as peças do starter kit
   (`NavMain`, `NavUser`, `AppLogoIcon`). Apague qualquer cópia duplicada que o bloco tenha
   deixado com outro nome.

2. **Painel de usuário único: fora `nav-projects.tsx` e `team-switcher.tsx`.** O header da
   sidebar é fixo — logo + nome do projeto, num `SidebarMenuButton size="lg" asChild`
   envolvendo um `<Link>` para o dashboard.

3. **Item ativo por `usePage().url`**, não por helper de rota — funciona igual com helper do
   Wayfinder e com URL em string literal:

   ```tsx
   const currentPath = usePage().url.split('?')[0];
   // ativo se currentPath === path || currentPath.startsWith(`${path}/`)
   ```

   Trate `/` como caso exato, senão a home fica sempre ativa.

4. Confirme que o layout continua envolvendo tudo:
   `resources/js/layouts/app-layout.tsx` → `import AppLayoutTemplate from '@/layouts/app/app-sidebar-layout';`
   e que o `app-sidebar-layout.tsx` mantém `<SidebarProvider>` + `<AppSidebar />` +
   `<SidebarInset>`.

5. Rode as três limpezas de import do passo 7.

### Links de módulos que ainda não existem

**Verificado em execução — regra dura.** Enquanto o módulo não tem rota no backend:

- use **string literal de URL** no `href` (`'/leads'`), **nunca** helper do Wayfinder —
  o helper não existe ainda e o build quebra;
- **não** ponha `prefetch` nesses itens — o Inertia dispara a requisição na renderização da
  sidebar e você ganha um 404 por item;
- deixe um `// TODO: migrar para helper do Wayfinder quando o modulo X existir` na linha.

Quando o módulo entrar, troque por `import { index } from '@/routes/leads'` e aí sim pode
usar `prefetch`.

## 10. Auth de usuário único

Siga a seção "Auth" do `SKILL.md`:

- comente `Features::registration()` em `config/fortify.php`;
- `rm -f resources/js/pages/auth/register.tsx` e `rm -rf resources/js/routes/register/` —
  o Wayfinder regenera o resto de `resources/js/routes/` sozinho na próxima execução do Vite;
- `grep -rn "routes/register" resources/js` tem de sair vazio (rota inexistente **quebra o
  build**);
- crie `config/painel.php` + `AdminUserSeeder` lendo `PAINEL_ADMIN_*`;
- `php artisan migrate --seed`.

Opcional em single-user: comentar também `Features::resetPasswords()` e
`Features::emailVerification()`, removendo as referências no front pelo mesmo motivo. O 2FA
e as passkeys valem a pena manter — já vêm prontos e as telas existem em
`components/manage-two-factor.tsx` e `components/manage-passkeys.tsx`.

## 11. Rotas por módulo

Ver a seção "Rotas por módulo" do `SKILL.md`. O ponto que morde:

O starter kit registra `Route::inertia('dashboard', 'dashboard')->name('dashboard')` em
`routes/web.php`. Ao criar o módulo de dashboard (`routes/painel/metrics.php`) com o mesmo
nome de rota, **apague o placeholder** — nome duplicado faz `php artisan route:cache`
quebrar. No painel real ficou só um comentário no `web.php` apontando onde a rota mora.

## 12. Portas e dev server

```bash
# tudo junto (server + queue + pail + vite), definido no composer.json do starter kit
composer run dev     # chama `php artisan dev`; php artisan dev:list mostra os processos
```

Ou separado:

```bash
php artisan serve --port=8000
npm run dev
```

Regras:

- O Vite **precisa** estar rodando durante o desenvolvimento não só por HMR: é ele que
  executa o plugin do Wayfinder e regenera `resources/js/routes/` e `resources/js/actions/`.
  **Rota nova que não aparece no front é quase sempre Vite parado.**
- `composer run dev` usa a porta padrão 8000. Se estiver ocupada:
  `lsof -nP -iTCP:8000 -sTCP:LISTEN`, escolha outra, e ajuste `--port`, `APP_URL` e
  `php artisan config:clear` — os três.
- Vite em outra porta: `npm run dev -- --port=5174`. Nada a configurar no Laravel; o
  `laravel-vite-plugin` grava a URL em `public/hot`. Arquivo velho de Vite morto:
  `rm -f public/hot`.
- SSR: `config/inertia.php` vem com `ssr.enabled => true`, mas `php artisan dev` **não**
  sobe processo de SSR. Se aparecer erro de conexão em `127.0.0.1:13714`, ou suba
  (`npm run build:ssr && php artisan inertia:start-ssr`) ou desligue
  (`'enabled' => false` + `config:clear`).

Scripts npm do `vite-plus` (nome do binário é `vp`):

| Script | Comando |
|---|---|
| `npm run dev` | `vp dev` |
| `npm run build` | `vp build` |
| `npm run build:ssr` | `vp build && vp build --ssr` |
| `npm run check` / `check:fix` | `vp check` (lint do front) |
| `npm run types:check` | `tsc --noEmit` |

Do lado PHP: `composer run lint` (Pint), `composer run types:check` (PHPStan/larastan),
`composer run test` (lint + tipos + testes), `composer run ci:check` (tudo).

## 13. Verificação

```bash
php artisan about                       # .env válido
ls resources/js/components/ui
ls resources/js/components | grep -E 'app-sidebar|nav-main|nav-user|login-form'
grep -rn "from 'cn'" resources/js       # tem de sair vazio
grep -rn "@/resources/js/" resources/js # tem de sair vazio
npm run types:check
npm run build
php artisan route:list | grep -E 'login|register|dashboard'
php artisan route:cache && php artisan route:clear
php artisan test
```

`/register` deve ter desaparecido da lista de rotas. Depois complete com o checklist final
do `SKILL.md`.
