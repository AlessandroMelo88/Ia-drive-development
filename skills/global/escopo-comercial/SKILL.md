---
name: escopo-comercial
description: Classificar e registrar em Docs/comercial/escopo-e-extras.md toda mudança feita num projeto de cliente — o que era combinado, o que é adicional cobrável, o que é correção de defeito e o que é ferramental interno. Use SEMPRE que o cliente pedir algo novo, que uma regra de negócio mudar, que uma tela nascer ou que um defeito for corrigido; e ao terminar qualquer rodada de trabalho, antes de fechar o checkpoint. Não se aplica a projeto pessoal nem a branch marcada como pessoal.
---

# Escopo × adicionais

Projeto de cliente costuma ter preço ou escopo fechado. O que o cliente pediu depois do combinado é o
que o Alessandro vai renegociar, e **a memória disso não pode viver na conversa**. Ela vive em
`Docs/comercial/escopo-e-extras.md`.

## Antes de qualquer coisa

### 1. Regra local do projeto prevalece

Procure `.claude/skills/escopo-comercial/SKILL.md` **no projeto**, como pasta real e não como link
para o repo `claude-skills`. Existindo, leia e siga essa versão: ela traz os documentos do combinado,
as datas e as branches daquele cliente. O Claude Code mostra a skill pessoal no lugar da do projeto
quando os nomes coincidem, por isso a leitura precisa ser explícita. Também valem as regras do
`CLAUDE.md`, `CLAUDE.local.md` ou `AGENTS.md` do projeto.

### 2. O projeto é de cliente?

- **Existe `Docs/comercial/escopo-e-extras.md`:** é de cliente. Siga o procedimento.
- **Não existe:** pergunte uma única vez ao Alessandro se o projeto tem cliente com escopo
  combinado. Se sim, crie o documento a partir de [modelo.md](modelo.md), pedindo a ele quais são os
  documentos do combinado (orçamento, especificação) e as datas. Se não, registre no `CLAUDE.local.md`
  do projeto: "escopo-comercial: não se aplica (projeto pessoal)". Assim a pergunta não se repete.

### 3. Em que branch você está?

```bash
git branch --show-current
```

Se o projeto declarar branches pessoais (no `CLAUDE.local.md`, por exemplo um simulador ou um
experimento do Alessandro), **a regra não vale nelas: não escreva nada no documento comercial**.
Trabalho que nasce na branch do cliente e depois é levado para uma branch pessoal é registrado UMA
vez, quando foi feito. O merge não gera linha nova.

### 4. Fora do git

O documento e o `CLAUDE.local.md` ficam **fora do git** (`.gitignore`: `/Docs/comercial`,
`CLAUDE.local.md`). Confira o `.gitignore` ao criar o documento. Nunca commite nenhum dos dois. Nunca
cole o conteúdo do documento numa mensagem que vá para o cliente: é material interno da conversa
comercial.

## Quando usar

- O cliente pediu qualquer coisa (documento, áudio, print, WhatsApp).
- Uma regra de negócio mudou.
- Uma tela ou um campo nasceu.
- Um defeito foi corrigido.
- Uma rodada de trabalho terminou: registre **antes** de atualizar o checkpoint.

## O procedimento

1. **Leia o documento inteiro antes de escrever.** Ele já tem estrutura e vocabulário. Item novo
   entra na seção certa, não numa lista nova.
2. **Classifique** cada item em uma das quatro caixas (regras abaixo).
3. **Escreva na seção correspondente**, com a data e, quando houver, **as palavras do cliente entre
   aspas**. A citação é o que sustenta a cobrança.
4. **Atualize o cabeçalho** (`**Atualizado em:**`). Se o item muda o peso da conversa, atualize
   também o resumo.
5. Só então feche o checkpoint (`Docs/ESTADO-DO-PROJETO.md`, skill `checkpoint-projeto`).

## As quatro caixas

| Caixa | Seção | Como reconhecer |
|---|---|---|
| **Combinado** | §1 | Está nos documentos do combinado listados no topo do arquivo (orçamento, especificação). Se está lá, não é extra |
| **Adicional** | §2 | Pedido do cliente que não está em nenhum documento do combinado: tela nova, regra nova, campo novo, comportamento novo |
| **Correção** | §3 | Defeito nosso, ou ajuste para o combinado funcionar como prometido. **Não entra na conta** |
| **Interno** | §4 | Decisão do Alessandro, não pedido do cliente: ferramental, scripts, auditoria. **Não cobrar** |

### O teste que separa "adicional" de "correção"

Pergunte: **o combinado, do jeito que foi vendido, funcionaria sem isto?**

- Funcionaria, e o cliente quer diferente: **adicional**.
- Não funcionaria, ou funcionava errado: **correção**.

Exemplos:

- Um total contado duas vezes: o combinado não funcionava direito, então é **correção**.
- O cliente quer mudar a definição de um indicador que já funcionava como especificado: **adicional**.
- Um defeito que nós introduzimos ao atender um pedido dele é **correção**. O pedido que o originou
  continua sendo **adicional**.

### Retrabalho pedido pelo cliente é adicional, não defeito

Quando ele pede A, recebe A e depois pede B no lugar, **as duas entregas contam**. Registre a data das
duas e a mudança de ideia.

### Na dúvida, registre como adicional e marque a dúvida

É melhor ter um item a mais para o Alessandro decidir do que um item esquecido. Escreva a dúvida na
própria linha.

## O que NÃO fazer

- **Não apague itens** do documento. Item que virou irrelevante ganha uma nota, mas não sai da
  lista: o histórico é o valor dele.
- **Não invente valor em reais.** O documento diz o que foi feito e de que tamanho. Quanto cobrar é
  decisão do Alessandro.
- **Não suavize.** "43 itens em quatro documentos em cinco dias" é um fato. A leitura dele é do
  Alessandro.
- **Não mande nada disto ao cliente** sem o Alessandro pedir.
