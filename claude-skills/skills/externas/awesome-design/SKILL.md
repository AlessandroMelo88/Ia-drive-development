---
name: awesome-design
description: Biblioteca local de 84 DESIGN.md extraídos de design systems de marcas conhecidas (Airbnb, Apple, Stripe, Linear, Notion, Vercel etc.), do repositório VoltAgent/awesome-design-md. Use ao escolher direção visual, criar ou refazer design system, landing ou painel, quando o usuário pedir "no estilo de X", ou para buscar referência de paleta, tipografia, espaçamento e componentes.
---

# Awesome Design (DESIGN.md de referência)

Cada pasta em `design-md/<marca>/DESIGN.md` descreve um design system real: paleta, tipografia,
espaçamento, raio, componentes e tom. Fonte: https://github.com/VoltAgent/awesome-design-md (MIT).

## Como usar

1. Liste as opções: `ls ${CLAUDE_SKILL_DIR}/design-md`.
2. Escolha 2–3 referências coerentes com o produto (ex.: hospitalidade → airbnb; painel denso → linear, vercel).
3. Leia o `DESIGN.md` escolhido e extraia o **sistema** (escala de tipo, ritmo de espaçamento, regras de cor),
   não a marca. Nunca copie logo, nome, imagem ou texto da marca de referência.
4. Traduza para os tokens do projeto (ex.: `Docs/design-tokens.css`) e registre de qual referência veio cada decisão.
