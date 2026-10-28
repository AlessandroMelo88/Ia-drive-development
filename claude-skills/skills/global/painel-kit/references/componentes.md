# Componentes canônicos do painel

Lista fechada. Todo painel termina com **todos** estes presentes, na variante `inertia` e na
`split`. Se o projeto precisar de algo fora da lista, instale à parte — mas não remova nada
daqui.

Nomes verificados no registry do shadcn (`https://ui.shadcn.com/r/styles/new-york-v4/<nome>.json`
responde 200) em setembro de 2026, e o `add` foi executado de verdade no painel.

## 0. Antes de rodar qualquer `npx shadcn` — duas armadilhas reais

### (a) Fixe o gerenciador de pacotes

`npx shadcn@latest add ...` morre antes de instalar nada com:

```
Cannot find module '.../corepack/v1/pnpm/12.3.4/bin/pnpm.cjs'
```

O CLI detecta o gerenciador do projeto, acha pnpm (o starter kit deixa um
`pnpm-workspace.yaml` na raiz) e cai num shim quebrado do corepack. **Não é versão do
shadcn** — testado com 4.20.0, mesmo erro.

Correção que funcionou — no `package.json` do projeto, antes do primeiro `add`:

```json
"packageManager": "npm@10.9.2"
```

Depois `npm install`. Não troque por `pnpm@...`, não rode `pnpm install` neste projeto.

### (b) O CLI sobrescreve arquivos e pergunta interativamente

Os blocos (`login-02`, `sidebar-07`) geram arquivos com nomes que **já existem** no starter
kit e o CLI pergunta arquivo por arquivo se pode sobrescrever. Aceitar destrói componentes
já ligados ao Inertia/Fortify.

Padrão obrigatório para bloco:

```bash
yes n | npx shadcn@latest add <bloco> --yes
```

`--yes` pula a confirmação inicial; `yes n |` responde **não** a cada conflito — e os
arquivos **novos** ainda são criados. Rode um bloco por vez, para ler o output.

## 1. O que já vem no starter kit (variante `inertia`)

**Não rode `shadcn init`.** O starter kit React do Laravel 13 já traz `components.json`
(aliases prontos, `style: new-york`, `baseColor: neutral`, `tailwind.config` vazio porque
Tailwind 4 configura por CSS) e **~26 componentes** em `resources/js/components/ui/`.

Sempre comece olhando o que existe:

```bash
ls resources/js/components/ui
```

Instale só o delta entre esse `ls` e a lista canônica abaixo. `@tanstack/react-table` (v9),
`recharts` (v3), `react-hook-form`, `zod`, `cmdk`, `input-otp`, `sonner`, `date-fns` e
`react-day-picker` também **já vêm** no `package.json` — confira com `npm ls <pacote>` antes
de instalar.

Além dos `ui/*`, o kit traz componentes de aplicação prontos que **não** se devem substituir
por blocos: `app-sidebar`, `nav-main`, `nav-user`, `user-menu-content`, `app-logo`,
`appearance-tabs` (dark mode), `input-error`, `password-input`, `text-link`,
`manage-two-factor`, `manage-passkeys`, `passkey-verify`, `breadcrumbs`.

## 2. Blocos obrigatórios (identidade do painel)

```bash
yes n | npx shadcn@latest add login-02 --yes
yes n | npx shadcn@latest add sidebar-07 --yes
```

- `login-02` — "A two column login page with a cover image". Dependências: `button`,
  `input`, `label`, `field`. Gera `pages/login.tsx` + `components/login-form.tsx`.
  **O que ele gera não serve como está** (usa `<a href>` e OAuth, sem Fortify): aproveite só
  o layout de duas colunas. Procedimento em `inertia.md` §8.
- `sidebar-07` — "A sidebar that collapses to icons". Dependências: `sidebar`, `breadcrumb`,
  `separator`, `collapsible`, `dropdown-menu`, `avatar`. Gera `app-sidebar.tsx`,
  `nav-main.tsx`, `nav-projects.tsx`, `nav-user.tsx`, `team-switcher.tsx` e um `use-mobile`
  — **duplicando** quatro coisas que o starter kit já tem. Consolide em uma sidebar só:
  `inertia.md` §9.

### Limpeza obrigatória depois de cada bloco

```bash
# imports de `cn` vindos do pacote npm errado — o sidebar-07 trouxe 13 arquivos assim
grep -rln "from 'cn'" resources/js       # corrigir para: import { cn } from '@/lib/utils';

# caminhos absolutos inventados pelo bloco
grep -rn "@/resources/js/" resources/js  # @/resources/js/routes -> @/routes, /types -> @/types

# a dependência inútil que entrou no package.json
npm ls cn
```

Os dois `grep` têm de sair vazios antes de você considerar o bloco aplicado.
`npm run types:check` é o juiz final.

## 3. Base de UI

```bash
npx shadcn@latest add button card badge separator skeleton avatar
```

## 4. Formulários e entradas

```bash
npx shadcn@latest add form input textarea select checkbox label calendar popover command
```

`form` depende de `react-hook-form` + `zod`. `calendar` depende de `react-day-picker`.
`command` depende de `cmdk` (command palette e combobox junto com `popover`). Todos já
costumam vir no starter kit.

## 5. Overlays e feedback

```bash
npx shadcn@latest add dialog sheet alert-dialog alert tooltip dropdown-menu sonner
```

`sonner` é o toast padrão (substituiu o antigo `toast`). Monte `<Toaster />` uma única vez
no layout raiz do painel.

## 6. Dados

```bash
npx shadcn@latest add table tabs chart progress
```

`chart` é a camada shadcn sobre Recharts (v3 no starter kit).

## 7. data-table — padrão, não componente

**`data-table` NÃO é instalável.** Não existe no registry
(`/r/styles/new-york-v4/data-table.json` retorna 404): a documentação do shadcn fornece um
**guia** para construir a tabela sobre o **TanStack Table**.

```bash
npm ls @tanstack/react-table    # no starter kit veio v9 — só instale se faltar
```

Os componentes shadcn que a tabela usa: `table` (§6) + `button`, `dropdown-menu`, `input`,
`select`, `checkbox` conforme os recursos (sort, filtro, paginação, seleção de linha,
colunas visíveis).

Padrão do projeto: **um** `components/data-table.tsx` genérico (`useReactTable` +
`getCoreRowModel` + paginação + `columns` por prop), reutilizado em todas as listagens, com
um `columns.tsx` por recurso.

> Atenção: a major instalada é **`@tanstack/react-table` v9**, não v8. Se copiar exemplo da
> internet, confira a API contra `npm ls @tanstack/react-table` e a doc da v9.

## 8. Lista canônica (para verificar)

```
alert  alert-dialog  avatar  badge  breadcrumb  button  calendar  card  chart  checkbox
collapsible  command  dialog  dropdown-menu  field  form  input  input-otp  label  popover
progress  scroll-area  select  separator  sheet  sidebar  skeleton  sonner  spinner  switch
table  tabs  textarea  toggle  toggle-group  tooltip
```

## 9. Verificação

```bash
# ajuste o caminho conforme a variante:
#   inertia -> resources/js/components/ui
#   split   -> components/ui  (ou src/components/ui)
DIR=resources/js/components/ui

for c in alert alert-dialog avatar badge breadcrumb button calendar card chart checkbox \
         collapsible command dialog dropdown-menu field form input input-otp label popover \
         progress scroll-area select separator sheet sidebar skeleton sonner spinner switch \
         table tabs textarea toggle toggle-group tooltip; do
  test -f "$DIR/$c.tsx" || echo "FALTA: $c"
done

npm ls @tanstack/react-table
grep -rn "from 'cn'" resources/js        # vazio
grep -rn "@/resources/js/" resources/js  # vazio
npm run types:check
```

Blocos aplicados, não apenas instalados:

- `login-02` → `layouts/auth/auth-split-layout.tsx` em duas colunas
  (`grid min-h-svh lg:grid-cols-2`), `login-form.tsx` com `<Form>` do Inertia, e **sem**
  `pages/login.tsx` genérica sobrando.
- `sidebar-07` → **um** `app-sidebar.tsx` com `collapsible="icon"`, sem `nav-projects.tsx`
  nem `team-switcher.tsx` (painel de usuário único), item ativo por `usePage().url`.
