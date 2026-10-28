---
name: validacao-visual
description: Use when a ticket, PR or change in any web project needs visual validation in the locally running app (tela, clique, redirect, texto na página, layout desktop/mobile, "testar visualmente", "printar a tela", "ver se aparece", validar aceite no navegador) with minimal tokens.
---

# Validação visual

Roteiro JSON → Chromium headless → um print JPEG por passo + `report.md` com PASS/FAIL. Você lê só o report (texto curto); abre print apenas de passo FAIL ou quando o aceite é de layout. Serve para qualquer projeto web (Laravel, Next.js, Django…).

## Fluxo

1. App no ar? `curl -s -o /dev/null -w "%{http_code}" <baseUrl>`. Fora do ar: peça ao usuário para subir (`! composer run dev`, `! pnpm dev`…). Não suba Docker por conta própria.
2. Traduza cada aceite do ticket em um passo observável. Salve em `.validacao-visual/<ticket>.json` na raiz do projeto.
3. Garanta `.validacao-visual/` em `.git/info/exclude` (local, nunca versiona).
4. Rode da raiz do projeto: `node ~/.claude/skills/validacao-visual/capture.mjs .validacao-visual/<ticket>.json` (`--audio` grava `resumo.wav` falado; `--headed` mostra a janela).
5. FAIL ou aceite visual: Read no `.jpg` do passo (junte vários com `magick a.jpg b.jpg +append` para um Read só).
6. Reporte PASS/FAIL por aceite + pasta dos prints.

## Roteiro

```json
{
  "name": "sis-344",
  "baseUrl": "http://localhost:8000",
  "loginPath": "/login",
  "dismiss": [{ "role": "button", "name": "Recusar" }],
  "accounts": { "gratis": { "email": "conta-seed@exemplo.test" } },
  "steps": [
    { "name": "guest vai pro login", "goto": "/painel/x", "expectUrl": "/login" },
    { "name": "gratis vê aviso", "as": "gratis", "goto": "/painel/x", "expectText": "recurso Pro" },
    { "name": "capa mobile", "goto": "/perfil/8", "viewport": "mobile", "expectSelector": "img.capa" }
  ]
}
```

| Campo | Faz |
|---|---|
| `goto` | navega (path relativo a `baseUrl`) |
| `click` / `check` | CSS ou `{role,name}` / `{text}` / `{label}` |
| `fill` | `{ "#campo": "valor" }` |
| `as` | conta de `accounts`; contexto logado próprio |
| `viewport` | `desktop` (1366×800) ou `mobile` (390×844) |
| `expectUrl` `expectStatus` `expectText` `expectNoText` `expectSelector` `expectAttr` | viram PASS/FAIL |
| `fullPage` | print da página inteira |
| raiz `loginPath`; conta `loginPath` `emailField` `passwordField` | formulário de login (default `/login`, campos email/password) |
| raiz `dismiss` | clicados após cada `goto` se visíveis (cookies etc.) |
| raiz `ageGate` | `"AAAA-MM-DD"`; passa gate de idade com selects Dia/Mês/Ano |

**Senha:** padrão de teste local `q1w2e3r4` (embutida no script). Conta com outra senha: `passwordEnv` com o nome da variável do `.env` (nunca impressa). Só contas de seed/teste, nunca de pessoa real.

## Notas por projeto

- **PeekingMe (Kelnab):** `baseUrl` `http://localhost:8000`; painel `loginPath` `/painel/entrar`; site pede `"ageGate": "1990-01-15"` e `dismiss` Recusar (cookies). Criadora Grátis seed: `tomb.raider@seed.kelnab.test`.

## Erros comuns

- Print de tudo "para ver": gasta token. Checagem textual primeiro.
- Print coberto por modal: falta `ageGate` ou botão em `dismiss`.
- `login falhou`: conta sem a senha padrão, MFA ou throttle — espere 1 min ou troque a conta.
- Chrome real do usuário (claude-in-chrome) só quando o fluxo exige a sessão dele (OAuth externo); custa bem mais.
- `Playwright não encontrado`: `npm --prefix ~/.claude/skills/validacao-visual i`.
