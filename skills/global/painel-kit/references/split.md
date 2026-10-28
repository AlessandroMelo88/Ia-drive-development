# Variante `split`

Laravel 13 como **API** (Sanctum) + **Next.js (App Router)** no front, em pastas/repos
separados. Mesmos componentes shadcn do padrão, instalados no front Next.

> **Esta variante ainda NÃO foi executada ponta a ponta.** O que foi executado de verdade é a
> variante `inertia` (`inertia.md`). Os passos abaixo vêm da doc oficial; pontos não
> confirmados estão marcados com **INCERTO**. As lições que valem nas duas variantes (o
> `APP_URL` malformado, o `packageManager` para o shadcn CLI, os blocos que sobrescrevem
> arquivo, a `CREATEDB` na role) já foram incorporadas.

Estrutura:

```
meuprojeto/
├── api/     # Laravel 13 (API only)
└── web/     # Next.js App Router (painel)
```

Se forem repos separados, use dois diretórios irmãos com o mesmo nome de projeto e um
`README.md` em cada, apontando um para o outro.

## Parte A — Backend (`api/`)

### A1. Criar o projeto

```bash
laravel new api --no-authentication --phpunit --database=pgsql --no-node --no-interaction
```

- `--no-authentication` porque o scaffolding de auth dos starter kits é acoplado ao front
  (Inertia/Livewire); aqui o front é Next e a auth é feita por Sanctum + rotas próprias.
- `--no-node` porque o backend não tem front.
- `--no-interaction` evita todos os prompts.
- `--database=pgsql` é valor aceito (confirmado na execução da variante `inertia`).
- Não passe `--git` se `api/` vive dentro de um repositório maior.

**Logo depois de criar, confira o `APP_URL`.** Na variante `inertia` o instalador gravou
`http://localhost:8000:8000` (porta duplicada) e isso faz **todo** comando artisan morrer com
`Invalid URI: Host is malformed.` Com `--no-node` o erro não aparece no build, mas o `.env`
pode vir errado do mesmo jeito:

```bash
cd api
grep '^APP_URL' .env      # esquema + host + UMA porta, igual à do serve
php artisan config:clear
php artisan about         # se roda, o .env está válido
```

### A2. Banco e `.env`

Crie role + database próprios (seção "Banco" do `SKILL.md` — a role precisa de `CREATEDB`,
senão `php artisan test` não consegue criar o banco de teste) e configure:

```ini
APP_URL=http://localhost:8001

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=meuprojeto
DB_USERNAME=meuprojeto
DB_PASSWORD=senha-forte-aqui

# SPA em outra porta do mesmo host
FRONTEND_URL=http://localhost:3002
SANCTUM_STATEFUL_DOMAINS=localhost:3002
SESSION_DOMAIN=localhost
SESSION_DRIVER=database

PAINEL_ADMIN_NAME="Alessandro Melo"
PAINEL_ADMIN_EMAIL=admin@exemplo.com
PAINEL_ADMIN_PASSWORD=senha-forte-aqui
```

> INCERTO: a doc atual do Sanctum descreve a opção de configuração como `stateful` em
> `config/sanctum.php` e cita os helpers `Sanctum::currentApplicationUrlWithPort()` e
> `Sanctum::currentRequestHost()`, sem nomear a variável de ambiente. Historicamente o
> `config/sanctum.php` publicado lê `SANCTUM_STATEFUL_DOMAINS`. **Confira o
> `config/sanctum.php` gerado no seu projeto** e use o nome de env que estiver lá; se o
> arquivo não usar env, edite o array `stateful` direto.

### A3. Instalar Sanctum (API)

Comando oficial (verificado na doc do Sanctum):

```bash
php artisan install:api
```

Isso instala o Sanctum, publica a migration de tokens e cria `routes/api.php`.

### A4. Middleware stateful

Em `bootstrap/app.php`:

```php
->withMiddleware(function (Middleware $middleware): void {
    $middleware->statefulApi();
})
```

Isso permite que o SPA autentique por cookie de sessão, mantendo tokens para terceiros.

### A5. CORS com credenciais

O `config/cors.php` **não é publicado por padrão** no Laravel 11+. Publique:

```bash
php artisan config:publish cors
```

E ajuste:

```php
'paths' => ['api/*', 'login', 'logout', 'sanctum/csrf-cookie'],
'allowed_origins' => [env('FRONTEND_URL', 'http://localhost:3002')],
'supports_credentials' => true,
```

`supports_credentials => true` é obrigatório (envia `Access-Control-Allow-Credentials`).

Em produção com subdomínios, prefixe o domínio da sessão com ponto em `config/session.php`:

```php
'domain' => '.meudominio.com',
```

SPA e API **precisam compartilhar o mesmo domínio de topo** (podem estar em subdomínios
diferentes). Em local, `localhost:3002` + `localhost:8001` funciona.

### A6. Rotas de auth e API

A doc do Sanctum diz que a rota `/login` pode ser implementada manualmente ou via Fortify
(headless). Para painel de usuário único, o manual é suficiente. Em `routes/web.php`
(precisa da sessão, portanto middleware `web`):

```php
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

Route::post('/login', function (Request $request) {
    $credentials = $request->validate([
        'email' => ['required', 'email'],
        'password' => ['required'],
    ]);

    if (! Auth::attempt($credentials, $request->boolean('remember'))) {
        return response()->json(['message' => 'Credenciais inválidas.'], 422);
    }

    $request->session()->regenerate();

    return response()->json($request->user());
});

Route::post('/logout', function (Request $request) {
    Auth::guard('web')->logout();
    $request->session()->invalidate();
    $request->session()->regenerateToken();

    return response()->noContent();
})->middleware('auth:sanctum');
```

Rotas protegidas em `routes/api.php`:

```php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', fn (Request $request) => $request->user());
    // ... resto da API do painel
});
```

Adicione o trait `Laravel\Sanctum\HasApiTokens` em `App\Models\User` se for emitir tokens
para clientes que não sejam o SPA (mobile, integrações). Para o SPA, **não** use tokens —
a doc é explícita: "You should not use API tokens to authenticate your own first-party SPA".

### A7. Auth de usuário único

Crie o `AdminUserSeeder` lendo `PAINEL_ADMIN_*` do `.env` (código completo no `SKILL.md`),
registre em `DatabaseSeeder` e rode:

```bash
php artisan migrate --seed
php artisan serve --port=8001
```

Não crie rota de registro público.

## Parte B — Frontend (`web/`)

### B1. Criar o projeto Next

```bash
npx create-next-app@latest web
```

Aceite os defaults recomendados: **TypeScript**, **App Router**, **Tailwind CSS** e o alias
de import `@/*` — a doc do shadcn diz que os defaults já configuram exatamente isso.

Confirme no `tsconfig.json`:

```json
{ "compilerOptions": { "paths": { "@/*": ["./*"] } } }
```

(se o projeto usar `src/`, o alias aponta para `./src/*`).

### B2. Fixar o gerenciador de pacotes e inicializar shadcn/ui

Aqui o `init` **é** necessário (ao contrário da variante `inertia`, onde o starter kit já
vem com `components.json` — nunca rode `init` lá).

Antes do primeiro `npx shadcn`, fixe o gerenciador no `package.json` do `web/`:

```json
"packageManager": "npm@10.9.2"
```

Sem isso o CLI do shadcn pode detectar pnpm e morrer com
`Cannot find module '.../corepack/v1/pnpm/<versão>/bin/pnpm.cjs'` (shim quebrado do corepack —
não é versão do shadcn; ver `componentes.md` §0).

```bash
cd web
npx shadcn@latest init
```

O CLI faz perguntas de configuração e gera o `components.json`. Componentes vão para
`components/ui/` (ou `src/components/ui/` se você escolheu `src/`) e são importados como
`@/components/ui/<nome>`.

### B3. Instalar o kit de componentes

Componentes simples num `add` só — a lista canônica está em `componentes.md` §8:

```bash
npx shadcn@latest add button card badge separator skeleton avatar form input textarea \
  select checkbox label calendar popover command dialog sheet alert-dialog alert tooltip \
  dropdown-menu sonner table tabs chart progress

npm install @tanstack/react-table    # confira a major: no ecossistema atual é v9, não v8
```

Os **blocos**, um por vez e sem sobrescrever nada:

```bash
yes n | npx shadcn@latest add login-02 --yes
yes n | npx shadcn@latest add sidebar-07 --yes
```

Depois de cada bloco, rode as limpezas de import de `componentes.md` §2 — o `sidebar-07`
importa `cn` do pacote npm errado (`from 'cn'` em vez de `@/lib/utils`) e inventa caminhos
absolutos. Os `grep` têm de sair vazios.

### B4. Encaixar os blocos no App Router

`login-02` gera uma `page.tsx` do bloco + `components/login-form.tsx`. **O `login-form.tsx`
como veio não serve**: ele usa `<a href>` e botões de OAuth, sem nenhuma chamada à API.
Aproveite só o layout de duas colunas e reescreva o miolo do formulário. Padrão:

```
app/(auth)/login/page.tsx        <- layout de duas colunas do login-02 + <LoginForm />
components/login-form.tsx        <- formulário real: chama login() do cliente HTTP (B5),
                                    mostra erro de validação da API, tem "lembrar de mim"
```

Apague os botões de OAuth e qualquer `<a href>` de navegação interna (use `<Link>` do Next).

`sidebar-07` gera `app-sidebar.tsx`, `nav-main.tsx`, `nav-projects.tsx`, `nav-user.tsx`,
`team-switcher.tsx` + uma `page.tsx` de exemplo. Padrão:

```
app/(painel)/layout.tsx          <- <SidebarProvider> + <AppSidebar /> + <SidebarInset>
app/(painel)/dashboard/page.tsx  <- conteúdo
components/app-sidebar.tsx       <- do bloco sidebar-07
```

Copie o `<SidebarProvider>` / `<SidebarInset>` / header com `<SidebarTrigger />` da
`page.tsx` gerada pelo bloco para o `layout.tsx` do grupo `(painel)`, e apague a page de
exemplo. Mantenha `<Sidebar collapsible="icon">`. Em painel de usuário único, **apague
`nav-projects.tsx` e `team-switcher.tsx`** e ponha logo + nome do projeto fixos no header da
sidebar.

Item ativo: compare com `usePathname()` do Next (equivalente ao `usePage().url` da variante
`inertia`): ativo quando `path === href` ou `path` começa com `href` + `/`, tratando `/` como
caso exato. Enquanto uma rota do painel não existir, aponte para a URL literal e **não** use
`prefetch` no `<Link>`, senão o Next dispara requisição e você ganha 404 por item.

Monte o `<Toaster />` do `sonner` uma vez em `app/layout.tsx`.

### B5. Cliente HTTP e fluxo de login (Sanctum SPA)

`.env.local` do Next:

```ini
NEXT_PUBLIC_API_URL=http://localhost:8001
```

Fluxo obrigatório, na ordem (conforme a doc do Sanctum):

1. `GET {API}/sanctum/csrf-cookie` — inicializa o CSRF, o Laravel devolve o cookie `XSRF-TOKEN`.
2. `POST {API}/login` com as credenciais.
3. Requisições seguintes autenticam pelo cookie de sessão.

Requisitos de cada request: `credentials: 'include'` (equivalente a
`axios.defaults.withCredentials = true`), header `Accept: application/json`, e o header
`X-XSRF-TOKEN` com o valor do cookie `XSRF-TOKEN` **URL-decodificado**.

O Axios faz isso sozinho com `withCredentials` + `withXSRFToken`:

```ts
import axios from 'axios';

export const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  withCredentials: true,
  withXSRFToken: true,
  headers: { Accept: 'application/json' },
});

export async function login(email: string, password: string) {
  await api.get('/sanctum/csrf-cookie');
  return api.post('/login', { email, password });
}
```

Se usar `fetch` em vez de Axios, você mesmo precisa ler o cookie `XSRF-TOKEN`,
`decodeURIComponent` nele e mandar em `X-XSRF-TOKEN` — a doc avisa isso explicitamente.

Sessão expirada volta 401/419: redirecione para `/login`.

**Importante**: por ser auth por cookie, o login e as chamadas autenticadas precisam sair do
**navegador** (Client Components / route handlers que repassem os cookies). Chamada direta de
Server Component não carrega os cookies do usuário automaticamente.

> INCERTO: a doc do Sanctum não prescreve um padrão para App Router / Server Components.
> O caminho seguro e verificável é fazer as chamadas autenticadas do lado cliente, e proteger
> as rotas do painel com um guard que consulta `GET /api/user`.

### B6. Porta do Next

Fixe a porta no `package.json` (3001 é do site pessoal — não use):

```json
"scripts": { "dev": "next dev -p 3002", "start": "next start -p 3002" }
```

Ela precisa bater com `FRONTEND_URL`, `SANCTUM_STATEFUL_DOMAINS` e `allowed_origins` do
backend.

## Verificação da variante split

```bash
# backend
cd api
php artisan route:list | grep -E 'login|logout|sanctum|user'
php artisan migrate:status
cat config/sanctum.php | grep -A5 stateful
grep -n "supports_credentials" config/cors.php
grep -n "statefulApi" bootstrap/app.php

# frontend
cd ../web
ls components/ui
ls components | grep -E 'app-sidebar|nav-main|nav-user|login-form'
npm ls @tanstack/react-table
grep -rn "from 'cn'" .    --include='*.tsx' --exclude-dir=node_modules   # vazio
npx tsc --noEmit
npm run build
```

Rotas por módulo no backend: use o mesmo padrão da variante `inertia`
(`routes/painel/<modulo>.php` incluídos por um `foreach` em `routes/api.php`), com a mesma
regra de propriedade de arquivos da seção "Como paralelizar o trabalho" do `SKILL.md`.

Teste manual do fluxo de auth:

```bash
curl -i -c cookies.txt http://localhost:8001/sanctum/csrf-cookie
# deve retornar 204 e Set-Cookie: XSRF-TOKEN=...
```

Depois, no navegador em `http://localhost:3002/login`, logue com as credenciais do `.env` do
backend e confirme que `GET /api/user` retorna o usuário (sem 401 e sem erro de CORS no
console).
