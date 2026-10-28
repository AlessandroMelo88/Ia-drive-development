---
name: documentacao-viva
description: Manter a documentação do projeto viva a cada mudança de comportamento — atualizar o que existe, criar o que falta, e escrever a parte do usuário final em linguagem não técnica com tabela, diagrama ou mapa mental. Use SEMPRE que alterar regra de negócio, cálculo, tela, rota, configuração, integração externa ou fluxo de operação; e ao terminar qualquer tarefa que mude o que o sistema faz.
---

# Documentação viva

Código que muda sem documentação que muda vira armadilha. A regra é simples:

> **Se o comportamento do sistema mudou, a documentação muda no mesmo commit.**

Não em outro commit, não "depois", não num TODO. No mesmo.

## Quando isto vale

Vale sempre que a mudança for percebida por alguém de fora do arquivo editado:

- regra de negócio, fórmula, corte, limite, arredondamento
- coluna, enum, constraint, migration
- tela, campo, filtro, rótulo, estado vazio
- rota, permissão, comando de console, agendamento
- variável de configuração, chave de `.env`, interruptor na interface
- integração externa: endpoint, cota, custo, autenticação
- procedimento de operação: deploy, backup, restauração

Não vale para refatoração pura, formatação e renomeação interna que ninguém de
fora enxerga.

## As duas camadas

Todo projeto tem dois públicos, e eles não leem o mesmo texto.

| | Camada técnica | Camada do usuário |
|---|---|---|
| Quem lê | quem vai mexer no código | quem usa o sistema e não programa |
| Onde mora | arquivos no repositório | dentro do próprio produto, ou PDF/página entregue |
| Responde | "como funciona e por quê" | "o que este número quer dizer e o que eu faço com ele" |
| Vocabulário | tabela, endpoint, enum, índice | tela, botão, aposta, lucro |

**As duas são obrigatórias.** Entregar só a técnica deixa o usuário perdido;
entregar só a do usuário deixa o próximo desenvolvedor adivinhando.

## Passo 1 — Achar o que já existe

Antes de escrever qualquer coisa, procure. Documentação duplicada é pior que
documentação faltando, porque as duas divergem e ninguém sabe qual vale.

```bash
ls -R docs/ Docs/ documentation/ .planning/ 2>/dev/null
find . -maxdepth 2 -iname "*.md" -not -path "./node_modules/*" -not -path "./vendor/*"
```

Leia o índice antes de criar arquivo novo. **Atualizar o arquivo certo vence
criar um arquivo novo**, sempre.

## Passo 2 — Atualizar, não empilhar

Ao mudar uma regra:

1. Encontre onde a regra antiga está escrita.
2. **Reescreva.** Não adicione um parágrafo "atualização:" embaixo — o leitor
   seguinte vai ler a versão errada primeiro.
3. Se a mudança veio de uma decisão, registre a decisão e o motivo, não só o
   resultado. "Passou a ser X" não ajuda ninguém; "passou a ser X porque Y"
   evita que alguém desfaça sem saber.
4. Se a regra veio do cliente ou do usuário, **cite as palavras dele entre
   aspas, com a data.** É a prova de que a regra não foi inventada.

## Passo 3 — A camada do usuário precisa de figura

Texto corrido não ensina fluxo. Escolha a forma pelo que precisa explicar:

| Precisa explicar | Use |
|---|---|
| Uma sequência de passos no tempo | fluxograma ou linha do tempo |
| Uma decisão com ramos ("se X então Y") | árvore de decisão |
| Como as partes se encaixam | mapa mental com o conceito no centro |
| Comparação de casos, valores e limites | tabela |
| O que cada número da tela quer dizer | a própria tela anotada, campo a campo |
| Uma conta | a fórmula com um exemplo numérico real preenchido |

Regras da figura:

- **Um exemplo numérico concreto vale mais que a fórmula.** Mostre os dois:
  a fórmula e, logo abaixo, ela resolvida com números que o usuário reconhece.
- **Nomeie as coisas como a tela nomeia.** Se o botão diz "Excluir tudo", a
  documentação diz "Excluir tudo" — nunca "a ação de limpeza em massa".
- **Nada de jargão sem tradução.** A primeira vez que um termo do negócio
  aparece, defina em uma linha.
- Diagrama entra como Mermaid (` ```mermaid `) num arquivo markdown, ou como
  SVG inline quando for uma página do próprio produto. Ambos são texto,
  versionam em git e sobrevivem a cópia e cola.

## Passo 4 — Checagem antes de fechar

- [ ] Toda regra que mudou está reescrita, e a versão antiga não sobrou em
      lugar nenhum
- [ ] O índice da documentação lista os arquivos que existem hoje
- [ ] O usuário final consegue responder "o que este número significa?" sem
      abrir o código
- [ ] Existe pelo menos uma figura ou tabela por conceito com mais de dois
      passos
- [ ] Toda conta aparece resolvida com um exemplo numérico
- [ ] A data da última revisão está atualizada
- [ ] Documentação e código foram no mesmo commit

## O que NÃO fazer

- Não documente o óbvio do código ("este método retorna o nome"). Documente a
  **decisão** e a **regra**, que é o que o código não conta.
- Não deixe número mágico sem origem. Se o corte é 1,70, escreva de onde saiu.
- Não escreva "TODO: documentar". Ou documenta, ou não mudou.
- Não copie a mesma explicação em dois arquivos. Aponte para o dono do assunto.
