---
name: checkpoint-projeto
description: Manter o checkpoint do projeto em Docs/ESTADO-DO-PROJETO.md — o que está em produção, o que já foi feito, o que está em aberto e PARA ONDE se quer ir — e usá-lo para ler cada pedido novo. Use no INÍCIO de toda sessão (overview na primeira resposta), quando o usuário trouxer pedidos novos de cliente, perguntar "onde paramos", "o que já fizemos", "retomar", e ao TERMINAR qualquer rodada de trabalho (atualizar o checkpoint). Use também para criar o checkpoint num projeto que ainda não tem.
---

# Checkpoint do projeto

Uma conversa nova não lembra da anterior. O que não está escrito no
repositório se perde, e a próxima sessão refaz decisões, repete erros ou
promete ao cliente o que já foi descartado.

> **Todo projeto tem um arquivo só que diz onde estamos e para onde vamos:
> `Docs/ESTADO-DO-PROJETO.md`. Ele é lido no começo e atualizado no fim.**

O caminho é fixo em todos os projetos — o hook de início de sessão procura
exatamente esse arquivo.

## Os três momentos

### 1. Abertura — na primeira resposta da sessão

Antes de responder ao primeiro pedido:

1. Ler `Docs/ESTADO-DO-PROJETO.md` inteiro.
2. Conferir se o arquivo ainda diz a verdade: `git log --oneline -5` e
   `git status --short`. Se houver commit mais novo que o "em produção" do
   arquivo, ou trabalho não commitado, dizer.
3. Abrir a resposta com o **overview** — curto, antes do resto:

   ```
   Onde estamos: <fase atual e o que está em produção, 1–2 linhas>
   Em aberto que toca este pedido: <só os itens da §Em aberto relacionados>
   Como o pedido se encaixa: <liga o pedido a "Para onde vamos"; se
     contradiz uma decisão registrada ou desvia do objetivo, dizer aqui>
   ```

4. Depois, atender o pedido normalmente.

Proporcional ao pedido: pergunta rápida pede overview de 2–3 linhas, não
um relatório. Se o pedido não tem nada a ver com o estado (ex.: "explica
esse erro de TypeScript"), uma linha basta. O overview serve para
**concatenar o pedido com a direção do projeto**, não para atrasar a
resposta.

Se o pedido contradiz algo da seção "Decisões que custaram caro", apontar
antes de executar — com o porquê registrado. Não refazer em silêncio.

### 2. Durante — pedidos novos do cliente

Quando chegar um lote de pedidos (prints, áudios, documento):

- Registrar a rodada em `Docs/fases/NN-nome.md` **antes** de mexer em
  código, com as palavras do cliente.
- Para cada item, dizer em que parte de "Para onde vamos" ele se encaixa.
  Pedido que não se encaixa em nada não é proibido — mas é sinal de que a
  direção mudou, e a seção 0 precisa ser revista com o usuário.

### 3. Fechamento — ao terminar uma rodada

No mesmo commit do trabalho, ou no seguinte:

- Atualizar a data e o commit "em produção" no topo.
- Acrescentar a linha no **Registro de checkpoints** (mais recente em cima):
  data, rodada, onde parou, próximo passo combinado.
- Mover para "Em aberto" o que ficou pendente; tirar o que foi resolvido.
- Nova decisão cara de descobrir → seção de Decisões, com o porquê.
- Nova armadilha operacional → seção de Armadilhas.
- **Não reescrever "Para onde vamos" sozinho.** Propor a mudança ao usuário.

## Criar o checkpoint num projeto que não tem

1. Levantar: `git log --reverse --format='%h %ad %s' --date=short`,
   `README`, `CLAUDE.md`, pastas de documentação, configuração de deploy.
2. Copiar `modelo.md` (nesta pasta) para `Docs/ESTADO-DO-PROJETO.md` e
   preencher o que for **verificável**. O que vier de memória ou dedução
   leva "(não confirmado)".
3. A seção "Para onde vamos" nasce como rascunho marcado para o usuário
   confirmar — é a intenção dele, não uma dedução do código.
4. Pôr no topo do `CLAUDE.md` do projeto:
   `**Antes de qualquer coisa, leia \`Docs/ESTADO-DO-PROJETO.md\`.**`
5. Commitar.

## Regras do arquivo

- **Resume e aponta.** O detalhe mora nos arquivos citados; o checkpoint
  diz onde. Passou de ~250 linhas, está duplicando documentação.
- **Datas absolutas** (18/09/2026), nunca "ontem" ou "semana passada".
- **Sem segredos**: nada de token, senha, chave. Dizer onde o segredo está
  guardado, não o valor.
- **Afirmação verificada ou marcada.** Número que veio de sessão antiga e
  não foi reconferido leva a marca.
- **Em aberto é lista honesta**: se não está resolvido, está lá — inclusive
  o que foi tentado e falhou.

## Relação com outras skills

- `documentacao-viva` mantém a especificação (`Docs/logic/`) — o COMO.
  Esta mantém o estado e a direção — o ONDE e o PARA ONDE.
- O arquivo de fase (`Docs/fases/`) guarda o pedido do cliente em detalhe;
  o checkpoint só aponta para ele.
