---
name: testes-de-regressao
description: Todo bug corrigido vira um teste automatizado que falha antes da correção e passa depois, toda regra de negócio vira um teste, e bug de deploy/servidor (.env, URL de ambiente errado, migração) vira checagem que para o deploy. Use SEMPRE que for corrigir um bug, quando o usuário reclamar que o projeto "anda em círculos", "o mesmo erro voltou", "quebra uma coisa ao consertar outra", ao criar regra de negócio nova, e ao configurar um projeto novo (regras de teste, CI, arquivo de regras do agente).
---

# Testes de regressão — bug corrigido não volta

Ideia: sem teste, cada correção é um passo para frente e outro para trás. Com teste, o bug só
aparece uma vez. O manual de regras do sistema vira código que roda sozinho.

## Regra 1 — todo bug vira teste (ordem obrigatória)

1. **Reproduzir** o bug com os dados de entrada e o estado reais (copiar do incidente: ids, payload, log).
2. **Escrever o teste e vê-lo falhar** pelo motivo certo. Teste que nasce verde não prova nada.
3. **Corrigir** o código.
4. **Ver o teste passar** e rodar a suíte inteira.
5. **Nomear pelo incidente**: `test_<comportamento>_regressao_<data ou bug N>` e citar o bug em uma
   linha de docstring. Quem ler sabe por que o teste existe e não o apaga.
6. Registrar no arquivo de bugs do projeto: `Teste:` com o caminho do teste. Bug FEITO sem teste não está feito.

Correção sem teste só é aceita com justificativa escrita (ex.: infraestrutura sem como simular),
e vira item de checklist manual.

## Regra 2 — toda regra de negócio vira teste

Regra nova ou alterada ("se acontece A com B, o resultado é C") entra com um teste por caso
importante: caminho feliz, bordas e o caso que deve ser **recusado**. A tabela de regras do
sistema deve poder ser lida nos nomes dos testes.

## Regra 3 — três camadas

| Camada | O que cobre | Quando |
|---|---|---|
| Unitário | uma função, entradas e saída conhecidas | sempre, é o grosso |
| Contrato/integração | dois módulos juntos com banco e dublê de serviço externo (ex.: publisher + uploader falso + Postgres) | quando o bug nasceu na **fronteira** entre peças |
| Ponta a ponta | o fluxo real, navegador ou pipeline completo | poucos, só nos caminhos que dão dinheiro ou risco |

Bug de fronteira (dado certo num módulo, errado no outro) não é pego por teste unitário. Se o
incidente cruzou módulos, o teste de regressão tem que cruzar também.

## Regra 4 — falha silenciosa vira falha alta

Um padrão repetido em incidentes: o sistema "avisa e segue" e o erro passa em silêncio (token
não conferido, `except` que engole, fallback que esconde). Ao corrigir, trocar por bloqueio
explícito e testar que **bloqueia**. "Não consegui verificar" não é "está certo".

## Regra 5 — rodar sempre, bloquear merge

- Suíte roda no CI em todo push e a `master` só recebe verde.
- Local: um comando único (`make test`), documentado.
- Teste que falha por ambiente (dependência faltando) é consertado ou marcado `skip` com motivo;
  suíte vermelha tolerada ensina todo mundo a ignorar o vermelho.

## Regra 6 — ao configurar projeto novo

Copiar para o arquivo de regras do agente (CLAUDE.md / AGENTS.md):

> Toda correção de bug nasce de um teste que falha antes e passa depois (skill `testes-de-regressao`).
> Toda regra de negócio nova entra com testes. Não declarar "corrigido" sem rodar a suíte.

E criar: pasta de testes, comando `make test`, job de CI, seção `Teste:` no arquivo de bugs.

## Regra 7 — bug de deploy e de servidor também vira checagem automática

A suíte prova o **código**. Ela não vê o **servidor**: `.env` sem uma variável, URL de um ambiente
apontando para o outro, migração que não rodou, pasta sem permissão, deploy que "passou" e o site não
responde. Esses incidentes atravessam CI verde. Bug desse tipo não fecha com nota no checkpoint: vira
checagem que **roda no deploy e para o deploy**.

1. **Contrato do `.env`** — arquivo versionado com as variáveis obrigatórias por ambiente
   (ex.: `config/ambiente.php`). Teste no CI: toda obrigatória existe no `.env.example`.
   Variável nova que muda entre homologação e produção entra no contrato no mesmo commit.
2. **Padrão que esconde erro é proibido** — `env('URL_X', 'https://producao...')` faz o ambiente sem a
   variável falar com produção. A checagem confere o valor **resolvido** do config, não só o arquivo:
   fora de produção nenhuma URL tem host de produção; em produção nenhuma tem `localhost`, `homo`,
   `stage` ou domínio de dev. Desvio de e-mail (`MAIL_REDIRECT_TO`) obrigatório em homologação e
   proibido em produção.
3. **Comando de conferência no servidor** (ex.: `php artisan <app>:conferir-ambiente`), chamado pelo
   script de deploy **depois do pull e antes de migrar**; falhou = sai com 1 e nada é migrado. No fim
   do deploy roda de novo com banco, migrações pendentes e pastas graváveis.
4. **Smoke de fora** — o script que publica (Actions ou local) faz `curl` no endpoint de saúde pela
   internet (`/up`) e falha se não vier 200.
5. **Saída sem segredo** — a conferência mostra nome de variável e host, nunca valor.
6. **Teste do incidente** — o comando de conferência tem testes com o `.env` do incidente
   (variável ausente, vazia, URL do ambiente errado) que falham sem a regra.

Script de deploy alterado → `bash -n` antes do commit, e o primeiro deploy depois disso é acompanhado.

## Checklist de fechamento de bug

- [ ] Teste reproduz o incidente e falhou antes da correção
- [ ] Mesmo teste passa depois
- [ ] Suíte inteira verde
- [ ] O teste cobre a camada onde o bug nasceu (unidade ou fronteira)
- [ ] Bug registrado com o caminho do teste
- [ ] Houve falha silenciosa no caminho? Virou bloqueio testado
- [ ] O bug nasceu no servidor/deploy (`.env`, URL, migração, permissão)? Virou checagem no deploy (Regra 7)

## Anti-padrões

- Teste escrito depois da correção, só para "passar" — não prova que pegaria o bug.
- Mock que devolve exatamente o que o código quer ouvir; o teste vira tautologia.
- Um teste gigante que cobre tudo e ninguém sabe o que quebrou.
- Apagar ou afrouxar teste vermelho para a suíte passar. Vermelho é informação.
