<?php

/*
 | config/ambiente.php — o que `app:conferir-ambiente` exige do `.env` de cada servidor. Roda no deploy
 | (bin/deploy-backend.sh) antes de migrar. Variável nova que muda de valor entre homologação e produção
 | entra aqui no mesmo commit, senão o servidor que não a tiver cai no padrão do config, que costuma ser
 | o valor de produção.
 |
 | Modelo da skill deploy-github-actions-ssh. Troque os valores marcados com <...>.
 */

return [

    'obrigatorias' => [
        'todos' => [
            'APP_KEY',
            'APP_URL',
            'DB_DATABASE',
            'MAIL_HOST',
            // '<APP>_URL_SITE', '<APP>_URL_PAINEL', tokens de integração...
        ],
        // Homologação desvia todo e-mail para a equipe: sem isso, cliente real recebe e-mail de teste.
        'staging' => ['MAIL_REDIRECT_TO'],
        'production' => [],
    ],

    // Em produção estas precisam estar vazias.
    'vazias_em_producao' => ['MAIL_REDIRECT_TO'],

    // Variável => chave do config. Confere o valor JÁ RESOLVIDO (inclui o padrão do config).
    'urls' => [
        'APP_URL' => 'app.url',
        // '<APP>_URL_SITE' => '<app>.url_site',
    ],

    // Fora de produção nenhuma URL pode ter estes hosts.
    'hosts_producao' => [
        '<dominio-prod>',
        'www.<dominio-prod>',
    ],

    // Em produção nenhuma URL pode ter estes hosts nem conter "homo" ou "stage".
    'hosts_proibidos_em_producao' => ['localhost', '127.0.0.1', '<dominio-de-dev-local>'],

];
