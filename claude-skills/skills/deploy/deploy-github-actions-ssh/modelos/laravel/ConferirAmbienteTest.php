<?php

use Illuminate\Support\Facades\Artisan;

/*
 | tests/Feature/ConferirAmbienteTest.php (Pest) — modelo da skill deploy-github-actions-ssh.
 | Cada incidente de servidor (.env sem variável, URL do ambiente errado) ganha um teste aqui com o
 | `.env` do incidente, que falha sem a regra. Troque os valores marcados com <...> e acrescente as
 | variáveis do projeto em envCompleto() e aplicarNoConfig().
 */

function envDeTeste(array $variaveis): string
{
    $arquivo = tempnam(sys_get_temp_dir(), 'app-env-');
    file_put_contents($arquivo, collect($variaveis)->map(fn ($v, $k) => "{$k}={$v}")->implode("\n"));

    return $arquivo;
}

function envCompleto(string $ambiente, array $trocas = []): array
{
    $homo = $ambiente !== 'production';

    return array_merge([
        'APP_ENV' => $ambiente,
        'APP_KEY' => 'base64:x',
        'APP_URL' => $homo ? 'https://homo.<dominio-prod>' : 'https://<dominio-prod>',
        'DB_DATABASE' => 'app',
        'MAIL_HOST' => 'smtp.example.org',
        'MAIL_REDIRECT_TO' => $homo ? 'equipe@example.org' : '',
    ], $trocas);
}

/** Faz o config refletir o arquivo, como o servidor faria ao ler o `.env` (com os mesmos padrões). */
function aplicarNoConfig(array $env): void
{
    config()->set('app.url', $env['APP_URL'] ?? 'http://localhost');
}

function conferir(array $env): array
{
    aplicarNoConfig($env);
    $codigo = Artisan::call('app:conferir-ambiente', ['--arquivo' => envDeTeste($env), '--sem-banco' => true]);

    return [$codigo, Artisan::output()];
}

test('homologação e produção completas passam', function (string $ambiente) {
    [$codigo, $saida] = conferir(envCompleto($ambiente));

    expect($codigo)->toBe(0)->and($saida)->not->toContain('FALHA');
})->with(['staging', 'production']);

test('variável obrigatória ausente para o deploy', function () {
    $env = envCompleto('staging');
    unset($env['MAIL_HOST']);

    [$codigo, $saida] = conferir($env);

    expect($codigo)->toBe(1)->and($saida)->toContain('MAIL_HOST');
});

test('variável presente mas vazia conta como faltando', function () {
    [$codigo, $saida] = conferir(envCompleto('production', ['APP_KEY' => '']));

    expect($codigo)->toBe(1)->and($saida)->toContain('APP_KEY');
});

test('homologação apontando para produção falha', function () {
    [$codigo, $saida] = conferir(envCompleto('staging', ['APP_URL' => 'https://<dominio-prod>']));

    expect($codigo)->toBe(1)->and($saida)->toContain('APP_URL');
});

test('produção apontando para homologação ou localhost falha', function (string $url) {
    [$codigo] = conferir(envCompleto('production', ['APP_URL' => $url]));

    expect($codigo)->toBe(1);
})->with(['https://homo.<dominio-prod>', 'http://localhost']);

test('produção com MAIL_REDIRECT_TO desviaria todo e-mail: falha', function () {
    [$codigo, $saida] = conferir(envCompleto('production', ['MAIL_REDIRECT_TO' => 'alguem@example.org']));

    expect($codigo)->toBe(1)->and($saida)->toContain('MAIL_REDIRECT_TO');
});

test('a saída nunca mostra o valor de uma variável', function () {
    [, $saida] = conferir(envCompleto('production', ['APP_KEY' => '', 'MAIL_REDIRECT_TO' => 'segredo-xyz@example.org']));

    expect($saida)->not->toContain('segredo-xyz');
});

test('toda variável obrigatória está no .env.example', function () {
    $exemplo = Dotenv\Dotenv::parse((string) file_get_contents(base_path('.env.example')));
    $exigidas = collect(config('ambiente.obrigatorias'))->flatten()->unique();

    expect($exigidas->reject(fn (string $nome) => array_key_exists($nome, $exemplo))->values()->all())->toBe([]);
});
