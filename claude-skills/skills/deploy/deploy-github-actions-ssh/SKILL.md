---
name: deploy-github-actions-ssh
description: Publicar, configurar ou depurar o deploy de um projeto do Alessandro no padrão GitHub Actions + ssh para servidor próprio (build no runner, artefato por ssh, troca de release, migração protegida, conferência do .env e smoke test pela internet). Use SEMPRE que for "publicar", "subir", "deploy", "pôr no ar", "voltar versão", criar o workflow de deploy de um projeto novo, ou quando um deploy falhar ou "passar" e o site não responder.
---

# Deploy: GitHub Actions + ssh

Padrão usado em quase todos os projetos. A referência viva é o feebapp. Os modelos em
[modelos/](modelos/) são essa referência sem dados de projeto: copie, troque os marcadores `<...>` e
ajuste os caminhos.

```
Actions (workflow_dispatch: ambiente, escopo, forcar, confirmar)
  └─ runner Linux: checkout + chave ssh + bin/publicar.sh <amb> --sim
       ├─ backend mudou? → ssh: bin/deploy-backend.sh  (no servidor)
       │     pull --ff-only → dependências → CONFERIR AMBIENTE (--sem-banco) → assets
       │     → migração protegida (manutenção + dump + foto antes/depois) → caches → permissões
       │     → CONFERIR AMBIENTE completo
       │   → curl https://<host>/up pela internet (tem que ser 200)
       └─ front mudou?   → build no runner → artefato .tgz por scp → ssh: ativar-release.sh
             troca atômica do link `current` → reinicia o processo → saúde local → volta se falhar
```

## Regras do padrão

1. **Deploy só pelo Actions** (`Actions > Deploy > Run workflow`). O script local existe para
   depuração. O build com binário nativo (sharp, swc, extensões) feito no Mac quebra no servidor
   Linux, por isso o `publicar.sh` recusa rodar fora de Linux sem `DEPLOY_PERMITIR_MAC=1`.
2. **O commit precisa estar no GitHub** e a árvore precisa estar limpa. O servidor puxa de lá: commit
   só local vira um deploy de outra versão.
3. **Produção pede confirmação:** o input `confirmar` precisa ser `PUBLICAR`. Se o plano tiver
   "Required reviewers" no environment `prod`, use também.
4. **Um deploy por ambiente de cada vez:** `concurrency: deploy-<ambiente>`, sem cancelar o que está
   rodando.
5. **Só publica o que mudou:** o servidor guarda o último sha publicado por parte
   (`releases/<amb>/{web,backend}.sha`). O `--forcar` ignora essa comparação.
6. **Segredo nunca viaja no artefato nem no log.** O `.env` mora no servidor e é a fonte única por
   ambiente. O artefato é limpo de `.env*`. Scripts mostram nome de variável e host, nunca valor.
7. **O servidor não compila o front:** sem `npm install` e sem `next build` em produção.
8. **Falhar alto:** cada etapa sai com 1 e explica o que fazer. É melhor o site fora do ar em
   manutenção do que no ar com dado faltando.

## Segredos e environments (configuração única por repositório)

Em *Settings > Environments*, crie `stage` e `prod`. Cadastre em cada um, ou como segredo do
repositório:

| Segredo | Conteúdo |
|---|---|
| `DEPLOY_SSH_KEY` | chave privada ssh **exclusiva do CI** (`ssh-keygen -t ed25519 -C ci-<projeto>`); a pública vai no `authorized_keys` do servidor |
| `DEPLOY_KNOWN_HOSTS` | saída de `ssh-keyscan -t ed25519 <host>`, conferida contra `ssh-keygen -F <host>` da sua máquina |
| `DEPLOY_SSH` | destino `usuario@host` |

No runner, o workflow monta o `~/.ssh/config` com `Host deploy`, `IdentitiesOnly yes`,
`StrictHostKeyChecking yes` e `ConnectTimeout 15`. O `publicar.sh` usa `DEPLOY_SSH=deploy`.
**Nunca** use `StrictHostKeyChecking no`.

Os segredos são cadastrados pelo Alessandro (`gh secret set ... --env prod`). Não leia nem imprima o
valor deles.

## Conferência do ambiente (Regra 7 da `testes-de-regressao`)

A suíte prova o código. Ela não vê o `.env` do servidor. Variável faltando faz o config cair no valor
padrão, que costuma ser o de produção: homologação passa a falar com produção. Por isso:

1. **Contrato versionado:** `config/ambiente.php` ([modelo](modelos/laravel/config-ambiente.php)) lista:
   - as variáveis obrigatórias para todos os ambientes e as de cada ambiente;
   - as que precisam ficar vazias em produção (ex.: `MAIL_REDIRECT_TO`);
   - as URLs a conferir e os hosts de produção.
2. **Comando** `php artisan app:conferir-ambiente` ([modelo](modelos/laravel/ConferirAmbiente.php)).
   Ele lê o **arquivo** `.env` (não o `env()` do processo) e confere o valor **resolvido** do config:
   - fora de produção, nenhuma URL tem host de produção;
   - em produção, nenhuma tem `localhost`, `homo`, `stage` ou domínio de desenvolvimento.

   Mostra nome e host, nunca valor. Sai com 1 se algo falhar.
3. **Duas chamadas no `deploy-backend.sh`:** `--sem-banco` logo depois do pull e das dependências,
   **antes de migrar** (falhou, nada é migrado). Depois, a conferência completa no fim: banco conecta,
   não há migração pendente, pastas graváveis.
4. **Testes do incidente** ([modelo](modelos/laravel/ConferirAmbienteTest.php)) cobrem:
   - variável ausente, variável vazia, URL do ambiente errado nos dois sentidos;
   - a saída sem valor de segredo;
   - "toda obrigatória está no `.env.example`".
5. **Variável nova que muda entre homologação e produção** entra no contrato, no `.env.example` e no
   `.env` dos servidores **no mesmo commit/deploy**.

Projeto sem Laravel (Node, Python, estático): use [modelos/conferir-env.sh](modelos/conferir-env.sh).
Ele recebe a lista de obrigatórias em `deploy/env-obrigatorio.<ambiente>.txt` e roda no servidor
antes do restart. As mesmas regras valem: nome sim, valor nunca.

## Migração protegida (backend)

Quando não há migração pendente, nada acontece e o site não cai. Quando há:

1. **Recusa migração destrutiva** (`migrate --pretend` com DROP/TRUNCATE/DELETE) sem
   `--permitir-destrutiva`.
2. **Liga a manutenção.** O padrão é `php artisan down --retry=60`; se o projeto tiver uma flag
   própria, use-a. Guarde o estado anterior para não desligar o que já estava ligado.
3. **Faz o dump do banco**, testa com `gzip -t`, exige um tamanho mínimo e mantém só os 10 dumps
   mais recentes.
4. **Tira uma foto antes e depois:** linhas por tabela e colunas. Se sumiu linha, tabela ou coluna,
   **para com a manutenção ligada** e imprime o comando de restauração.
5. Só desliga a manutenção quando tudo bate.

Credenciais do banco são lidas do `.env` para `MYSQL_PWD`/`PGPASSWORD` e nunca são impressas.

## Front: release com troca atômica

- O runner faz o build (`next build` com `output: 'standalone'`, por exemplo). As variáveis
  `NEXT_PUBLIC_*` vêm do `web/.env` **do servidor**, lido por ssh para um `.env.production.local`
  temporário que é apagado em seguida.
- O artefato vai para `releases/<sha>/`. O `ativar-release.sh` (enviado por stdin, `bash -s`):
  - troca o link `current` com `ln -sfn` + `mv -T`;
  - reinicia o processo (PM2 com `node --env-file=<repo>/web/.env server.js`);
  - espera 30 s por resposta 2xx/3xx na porta local. Sem resposta, **volta para a release
    anterior**.
- Guarda as 5 releases mais recentes. Voltar versão = rodar o `ativar-release.sh` com o sha anterior.

## Smoke test pela internet

O deploy no servidor pode passar e o site não responder (proxy, PHP-FPM, certificado, DNS). Depois de
cada parte publicada:

```bash
COD="$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$URL_PUBLICA/up" || true)"
[[ "$COD" == 200 ]] || erro "publicado, mas $URL_PUBLICA/up respondeu $COD"
```

- Laravel 11+: `->withRouting(health: '/up')` no `bootstrap/app.php`.
- Next/Node: crie uma rota `/api/saude` que responde 200 sem depender de sessão.
- Para fluxos críticos, um e2e de produção agendado (Playwright, `workflow_dispatch` + `schedule`)
  pega o que o `/up` não vê.

## Configurar o padrão num projeto novo

1. Copie os modelos: `modelos/deploy.yml` para `.github/workflows/`; `publicar.sh`,
   `deploy-backend.sh` e `ativar-release.sh` para `bin/` (com `chmod +x`).
2. Troque os marcadores `<...>`: caminhos no servidor por ambiente, URL pública, nome do processo,
   porta.
3. Laravel: copie `ConferirAmbiente.php`, `config-ambiente.php` (como `config/ambiente.php`) e o
   teste. Preencha as obrigatórias e os hosts. Rode o teste. Confira se `/up` está ligado.
4. Gere a chave do CI, fixe o `known_hosts` e cadastre os três segredos nos environments.
5. No servidor: clone em `<repo_remoto>`, crie o `.env` de cada ambiente e rode
   `php artisan app:conferir-ambiente` à mão até passar.
6. Rode `bash -n bin/*.sh` e faça o primeiro deploy em `stage`, acompanhando. Só depois faça o de
   `prod`.
7. Registre o comando de deploy no `CLAUDE.md`/`AGENTS.md` do projeto e no checkpoint.

## Quando o deploy falha

| Sintoma | Causa provável | O que fazer |
|---|---|---|
| `Host key verification failed` | `DEPLOY_KNOWN_HOSTS` desatualizado (servidor reinstalado) | conferir a nova chave por outro canal antes de atualizar o segredo |
| `Permission denied (publickey)` | chave do CI fora do `authorized_keys` | adicionar a pública; conferir o usuário em `DEPLOY_SSH` |
| `git pull falhou` no servidor | alteração local no servidor ou `chmod` marcando arquivos | `git status` no servidor; `core.fileMode false`; nunca editar código no servidor |
| `o commit ... não está no GitHub` | faltou push | push e repetir |
| conferência do ambiente falhou | `.env` do servidor sem variável ou com URL errada | corrigir o `.env` **no servidor**; nada foi migrado |
| migração parou com site em manutenção | migração removeu dado | analisar a foto antes/depois; restaurar o dump se preciso; desligar a manutenção só depois |
| release não respondeu em 30 s | erro de runtime, variável do front, porta | o script já voltou para a anterior; ver os logs do processo |
| `/up` não é 200 | proxy, PHP-FPM, certificado | `curl -v` de fora; logs do nginx e do PHP-FPM |

## Relatório pós-deploy

Diga em poucas linhas:
- ambiente e sha publicado;
- quais partes mudaram (backend/front) e quais ficaram sem mudança;
- o resultado da conferência e do `/up`;
- onde ficou o dump, se houve migração.

Atualize o `Docs/ESTADO-DO-PROJETO.md` (skill `checkpoint-projeto`). Incidente de servidor vira
checagem no deploy (Regra 7 da `testes-de-regressao`), não só nota.

## Anti-padrões

- Rodar `npm install`/build em produção.
- `StrictHostKeyChecking no`.
- Imprimir segredo, ou copiar `.env` no artefato ou no log.
- Deploy de commit que não está no GitHub; editar código direto no servidor.
- `env('URL_X', 'https://producao...')`: valor padrão de produção esconde a variável faltando.
- Pular o `/up` porque "só mudou CSS".
- Desligar a manutenção antes de conferir a migração.
- Alterar script de deploy sem `bash -n` e sem acompanhar o primeiro deploy depois da mudança.
