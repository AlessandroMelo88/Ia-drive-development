---
name: padroes-projeto
description: Padrão de documentação e arquitetura para qualquer projeto do Alessandro — ADR para decisões caras (Docs/adr/), spec por feature antes do código (Docs/specs/) e regras de arquitetura por stack (Laravel, Next.js, Python/Django). Use ao planejar feature nova, ao tomar ou mudar decisão de arquitetura, ao iniciar projeto, ou quando o usuário perguntar "precisa de spec?", "registra essa decisão", "como documentar isso", "qual o padrão".
---

# Padrões de projeto

Três camadas de documento, cada uma com um papel:

| Camada | Arquivo | Responde | Quando escrever |
|---|---|---|---|
| Estado | `Docs/ESTADO-DO-PROJETO.md` | Onde estamos e para onde vamos | Skill `checkpoint-projeto` |
| Decisão | `Docs/adr/NNNN-nome.md` | **Por que** foi feito assim | Quando uma escolha é cara de desfazer ou de redescobrir |
| Feature | `Docs/specs/NNN-nome.md` | **O que** a feature faz e como saber que ficou pronta | Antes de escrever código de uma feature nova |

Modelos nesta pasta: `modelos/adr.md` e `modelos/spec.md`.

## ADR (Architecture Decision Record)

- Um arquivo por decisão, numerado (`0001-...`), com índice em `Docs/adr/README.md`.
- Status: `Proposta` → `Aceita`. Mudou de ideia? **Novo ADR** que substitui o antigo; o antigo ganha `Substituída por ADR-XXXX`. Nunca apagar.
- Vale ADR: escolha de stack, onde um dado mora, integração externa, regra de negócio que parece estranha, algo que já custou retrabalho.
- Não vale ADR: nome de variável, biblioteca trivial, ajuste de layout.

## Spec por feature

1. Copiar `modelos/spec.md` para `Docs/specs/NNN-nome.md`.
2. Preencher objetivo, **fora de escopo**, regras numeradas (R1, R2…) e contrato (rotas, payloads, tabelas).
3. Mostrar ao usuário antes do código se a feature for maior que um dia.
4. Cada regra R vira pelo menos um teste. A spec só vai para `Entregue` com os critérios de pronto marcados.
5. Contrato de API detalhado pode morar na documentação do módulo; a spec aponta para ele.

Ciclo maior (várias fases, execução com agentes): as skills `superpowers:brainstorming` → `superpowers:writing-plans`, ou o fluxo `gsd:*`, fazem o mesmo papel com mais cerimônia. Use a spec simples quando bastar.

## Regras de arquitetura por stack

Antes de qualquer código de framework, a skill `docs-first` (documentação da versão exata).

### Laravel (+ Inertia/React)
- Nomes de domínio em português (models, enums, métodos de regra: `moverPara`, `recalcularTotal`).
- Transição de estado por **um único método** no model, que grava histórico. Nunca `update(['status' => ...])` solto.
- Rotas por módulo em `routes/<area>/*.php`; controller fino, regra em model ou `app/Services`.
- API pública: validação por FormRequest, limite de requisições, CORS restrito, segredo só no `.env`.
- Teste de feature para cada regra da spec; `vendor/bin/pint` limpo.
- UI de painel: skill `painel-kit` (shadcn, `login-02`, `sidebar-07`).

### Next.js
- App Router + TypeScript. Site de marketing: `output: "export"` (sem Node em produção).
- Dados tipados em `lib/*.ts`; texto de página não fica espalhado em componente.
- UI: componentes shadcn como base, **editados** para o design do projeto; tokens no `@theme` do Tailwind v4.
- SEO por página (`metadata`, JSON-LD, `sitemap.ts`, `robots.ts`).
- Verificar com `tsc --noEmit`, lint e `build` antes de dizer que terminou.

### Python / Django
- Ambiente isolado (`.venv`), dependências fixadas, `pytest`.
- Django: um app por domínio, regra em model ou service, não em view; migrations revisadas antes de rodar.
- Integração com IA ou API externa: fallback definido e falha que nunca derruba o processo principal.

### Sempre
- Nada de número, cliente ou depoimento inventado em conteúdo.
- Segredo nunca em código nem em documento; dizer onde ele está guardado.
- Mudança de comportamento atualiza a documentação na mesma rodada (skill `documentacao-viva`).

> Estas regras são o ponto de partida. Quando o usuário corrigir um padrão, atualizar este arquivo.
