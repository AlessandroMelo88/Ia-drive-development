---
name: code-mode
description: Padrão "Code Mode" (Cloudflare) aplicado no Claude Code — em vez de encadear muitas chamadas de ferramenta MCP turno a turno, escrever um script que faz a lógica toda (loops, paginação, filtros, chamadas encadeadas) e devolve só o resultado final. Use SEMPRE que uma tarefa com MCP ou API precisar de mais de 3 chamadas parecidas, paginação, cruzamento de dados entre chamadas, ou resultados grandes (listas, logs, issues, páginas, eventos); e ao usar servidores MCP que já oferecem `search`/`execute` (ex.: Cloudflare `https://mcp.cloudflare.com/mcp`).
---

# Code Mode — código no lugar de chamadas em série

Ideia (Cloudflare, "Code Mode"): cada chamada de ferramenta MCP devolve o resultado inteiro para
o contexto e custa um turno. Listar → filtrar → buscar detalhe → atualizar vira dezenas de
chamadas e milhares de tokens. Um script faz o mesmo de uma vez e só o resumo volta.

Fontes: https://github.com/cloudflare/mcp · https://developers.cloudflare.com/agents/api-reference/codemode/
Não existe skill oficial que transforme qualquer MCP em Code Mode; isto é o padrão aplicado
com as ferramentas que o Claude Code já tem.

## Ordem de decisão

1. **O servidor MCP já tem `search`/`execute`?** (Cloudflare API MCP, MCP Server Portals com
   `?codemode=search_and_execute`.) Use `search` para achar os endpoints e **uma** chamada
   `execute` com a lógica inteira. Não chame endpoint por endpoint.
2. **A mesma API é acessível por CLI ou HTTP com credencial que já existe na máquina**
   (`gh`, `gcloud`, `aws`, `wrangler`, `curl` com token do `.env`, SDK do projeto)? Escreva um
   script (Bash, Node ou Python) no scratchpad que faz paginação, filtro e junção, e imprime só o
   necessário (contagens, tabela curta, IDs). Rode uma vez.
3. **Só existe o MCP** (conector claude.ai, sem credencial local)? Então:
   - carregue o schema só da ferramenta necessária (`ToolSearch` com `select:<nome>`);
   - dispare as chamadas independentes **em paralelo, na mesma mensagem**;
   - peça o mínimo: filtros, `limit`, campos específicos, consultas agregadas (JQL, CQL,
     busca do Sentry/Notion) em vez de listar tudo e filtrar no contexto;
   - não releia o que já veio.

## Como escrever o script

- Arquivo no scratchpad da sessão, não no projeto. Saída curta; resultado grande vai para
  arquivo e é consultado com `jq`/`grep`.
- Somente leitura primeiro. Escrita (criar, atualizar, apagar, enviar) só com o pedido do
  usuário e mostrando antes o que será alterado.
- Credenciais vêm do ambiente/`.env` já existente; nunca imprimir token, senha ou cabeçalho
  `Authorization`; nunca colar segredo no código.
- Tratar paginação e limite de taxa (respeitar `Retry-After`); parar no primeiro erro de
  autenticação em vez de repetir.
- Usar só endpoints e campos confirmados na documentação oficial da API, na versão em uso.

## Quando NÃO usar

- Uma ou duas chamadas simples: chame a ferramenta direto.
- Quando o usuário quer ver o resultado bruto de cada passo.
- Ações irreversíveis em lote sem confirmação explícita.

## Exemplo

Pedido: "quais issues do Sentry dos últimos 7 dias afetam o checkout, agrupadas por release?"

- Em série: buscar issues → abrir cada uma → ler eventos → agrupar (dezenas de chamadas).
- Code Mode: se houver `SENTRY_AUTH_TOKEN`, um script chama a API de issues com
  `query=checkout&statsPeriod=7d`, pagina, agrupa por release e imprime uma tabela de 10 linhas.
  Sem token, uma única busca do MCP do Sentry com o filtro completo, e só o resumo na resposta.
