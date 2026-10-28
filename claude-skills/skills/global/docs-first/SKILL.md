---
name: docs-first
description: Consultar a documentação oficial da versão exata do framework antes de escrever código, e resolver o problema com o recurso nativo da plataforma em vez de lógica própria. Use ao implementar qualquer coisa em Laravel, Next.js, React, Django, Tailwind, Eloquent, ou qualquer framework/biblioteca — especialmente autenticação, autorização, validação, filas, cache, upload, queries e rotas.
---

# Documentação primeiro, plataforma sempre

Duas regras. Valem para todo framework e toda linguagem.

1. **Antes de escrever, leia a documentação oficial da versão que o projeto usa.** Não a que você lembra.
2. **Resolva com o recurso nativo da plataforma.** Lógica própria só quando o framework comprovadamente não oferece o recurso.

Motivo: o recurso nativo já foi auditado, já trata os casos de borda, já é seguro por padrão e já é rápido. Código artesanal equivalente carrega bugs que o framework resolveu anos atrás — e ninguém vai auditá-lo.

## Passo 1 — Descobrir a versão exata

Nunca assuma. Leia do projeto:

| Ecossistema | Onde |
|---|---|
| PHP / Laravel | `composer.json` + `composer.lock` (`laravel/framework`) |
| Node / Next / React | `package.json` + lockfile |
| Python / Django | `pyproject.toml`, `requirements.txt`, `poetry.lock`, `uv.lock` |
| Ruby / Rails | `Gemfile.lock` |
| Go | `go.mod` |

Diferença de major muda a API inteira: Laravel 10 × 11 × 12 mudaram bootstrap, middleware e estrutura de arquivos; Next 13 × 14 × 15 × 16 mudaram cache, `params` assíncronos e Server Actions; Tailwind 3 × 4 trocaram `tailwind.config.js` por `@theme` no CSS. Responder com a memória da versão errada produz código que não roda.

## Passo 2 — Consultar a documentação oficial daquela versão

Ordem de preferência:

1. **MCP de documentação**, se disponível na sessão (`context7` e similares). Peça a versão explicitamente.
2. **Site oficial**, na URL da versão: `laravel.com/docs/12.x/...`, `nextjs.org/docs`, `docs.djangoproject.com/en/5.1/`, `tailwindcss.com/docs`.
3. **Código do próprio `vendor/` ou `node_modules/`** — é a fonte definitiva do que está instalado. Assinatura de método e propriedade não mentem.
4. **Convenção já existente no projeto** — se o repositório já resolveu um problema parecido, siga o padrão dele.

Blog post, StackOverflow e tutorial são último recurso, e sempre com a data conferida.

## Passo 3 — Procurar o recurso nativo antes de inventar

Antes de escrever qualquer lógica, pergunte: **o framework já faz isso?** Quase sempre faz.

### Laravel

| Não escreva à mão | Use |
|---|---|
| Hash/verificação de senha, tokens de sessão | `Hash`, `Auth`, **Sanctum** ou Passport |
| Checagem de dono do recurso espalhada em `if` | **Policies** + `authorize()` / `can` |
| Validação manual de `$_POST` | **FormRequest** (`rules()`, `prepareForValidation()`) |
| Montagem de SQL por concatenação | **Eloquent** / query builder (parametrizado por construção) |
| `SELECT *` devolvido cru para o cliente | **API Resource** com lista branca de campos |
| Fila artesanal em Redis com `lPop` | **Queues** + `Job` + `failed_jobs` + `retry_after` |
| Cron chamando script solto | **Scheduler** (`routes/console.php`), com `withoutOverlapping()` |
| `move_uploaded_file` e caminho montado à mão | **Storage** (`Storage::disk()->putFile()`) |
| Rate limit próprio | `RateLimiter` / middleware `throttle` |
| Chave de API lida de constante no código | `config/services.php` + `.env` — e `env()` **só** dentro de `config/` |
| Transação implícita | `DB::transaction()` |
| N+1 | `with()` / `load()`, e `Model::preventLazyLoading()` em dev |

### Next.js / React

| Não escreva à mão | Use |
|---|---|
| `useEffect` + `fetch` para dado inicial | Server Component com `fetch` (cache e dedup nativos) |
| Estado global para dado de servidor | Server Component, ou `cache()` / Server Action |
| Chave de API no cliente | Route Handler / Server Action — segredo nunca em `NEXT_PUBLIC_*` |
| `<img>` cru | `next/image` |
| `<link>` de Google Fonts | `next/font` (elimina CLS e a requisição externa) |
| Detecção de mobile por `window.innerWidth` | Media query CSS — JS causa flash de hidratação |
| Redirect manual por `useEffect` | `redirect()` do `next/navigation`, ou middleware |
| Toggle de tema próprio | `next-themes` |

### Django

`ModelForm` e `Form` no lugar de validação manual; `ORM` com `select_related`/`prefetch_related`; `django.contrib.auth` com permissões; `messages`; `cache_page`; `signals` com moderação; **nunca** `raw()` com string interpolada.

## Passo 4 — Antes de entregar

- [ ] A versão que consultei é a que está no lockfile.
- [ ] Não reimplementei nada que o framework já oferece.
- [ ] Nenhum segredo em código ou em variável exposta ao cliente.
- [ ] Query parametrizada; nenhuma concatenação de entrada do usuário.
- [ ] Autorização checada no servidor, não escondendo botão no cliente.
- [ ] Resposta ao cliente é lista branca de campos, não o registro inteiro.
- [ ] Segui o padrão que o projeto já usa.

## Quando o framework realmente não cobre

Aí sim, código próprio — com três obrigações: comentário dizendo **por que** o recurso nativo não serviu, isolamento numa camada única (Service, Action, util), e teste ou verificação manual descrita.

## O que não fazer

- Inventar nome de método ou opção de configuração "que deve existir". Se não confirmou na documentação ou no `vendor/`, não escreva.
- Copiar padrão de outra major version.
- Trocar segurança por conveniência ("depois eu protejo"). Depois não chega.
- Instalar biblioteca nova para algo que o framework já faz.
