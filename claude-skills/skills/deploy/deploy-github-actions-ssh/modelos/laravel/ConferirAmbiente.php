<?php

namespace App\Console\Commands;

use Dotenv\Dotenv;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Throwable;

/**
 * Confere o `.env` do servidor antes de o deploy migrar e liberar o código (bin/deploy-backend.sh).
 *
 * Pega o que nenhum teste pega, porque é do servidor e não do código: variável faltando faz o config
 * cair no padrão (muitas vezes a URL de produção), e homologação passa a falar com produção.
 * Regras em config/ambiente.php. A saída mostra nome de variável e host, nunca o valor.
 *
 * Modelo da skill deploy-github-actions-ssh: copiar para app/Console/Commands/.
 */
class ConferirAmbiente extends Command
{
    protected $signature = 'app:conferir-ambiente
        {--arquivo= : .env a conferir (padrão: o do backend)}
        {--sem-banco : Não testa banco, migrações nem pastas (antes de migrar ou em teste)}';

    protected $description = 'Confere o .env do servidor (variáveis obrigatórias e URLs do ambiente certo). Sai com 1 se algo falhar.';

    /** @var list<string> */
    private array $falhas = [];

    public function handle(): int
    {
        $caminho = (string) ($this->option('arquivo') ?: base_path('.env'));

        if (! is_file($caminho)) {
            $this->error("[FALHA] .env não encontrado em {$caminho}");

            return self::FAILURE;
        }

        // Lê o arquivo, não o env() do processo: o que importa é o que está gravado no servidor.
        $env = Dotenv::parse((string) file_get_contents($caminho));
        $ambiente = (string) ($env['APP_ENV'] ?? '');
        $producao = $ambiente === 'production';

        $this->line("Ambiente: {$ambiente}");

        $this->variaveis($env, $ambiente);
        $this->urls($producao);

        if (! $this->option('sem-banco')) {
            $this->bancoEPastas();
        }

        if ($this->falhas === []) {
            $this->info('[OK] Ambiente conferido.');

            return self::SUCCESS;
        }

        foreach ($this->falhas as $falha) {
            $this->error("[FALHA] {$falha}");
        }

        return self::FAILURE;
    }

    /** @param  array<string, string|null>  $env */
    private function variaveis(array $env, string $ambiente): void
    {
        $exigidas = [...config('ambiente.obrigatorias.todos', []), ...config("ambiente.obrigatorias.{$ambiente}", [])];

        foreach ($exigidas as $nome) {
            if (trim((string) ($env[$nome] ?? '')) === '') {
                $this->falhas[] = "{$nome} ausente ou vazia no .env";
            }
        }

        if ($ambiente === 'production') {
            foreach (config('ambiente.vazias_em_producao', []) as $nome) {
                if (trim((string) ($env[$nome] ?? '')) !== '') {
                    $this->falhas[] = "{$nome} preenchida em produção (precisa ficar vazia)";
                }
            }
        }
    }

    private function urls(bool $producao): void
    {
        $deProducao = config('ambiente.hosts_producao', []);
        $proibidos = config('ambiente.hosts_proibidos_em_producao', []);

        foreach (config('ambiente.urls', []) as $variavel => $chave) {
            $host = strtolower((string) parse_url((string) config($chave), PHP_URL_HOST));

            if ($host === '') {
                continue;
            }

            $errado = $producao
                ? in_array($host, $proibidos, true) || str_contains($host, 'homo') || str_contains($host, 'stage')
                : in_array($host, $deProducao, true);

            if ($errado) {
                $alvo = $producao ? 'fora de produção' : 'produção';
                $this->falhas[] = "{$variavel} aponta para {$alvo} ({$host})";
            }
        }
    }

    private function bancoEPastas(): void
    {
        try {
            DB::select('select 1');
        } catch (Throwable) {
            $this->falhas[] = 'banco não conecta';

            return;
        }

        Artisan::call('migrate:status', ['--pending' => true]);

        if (str_contains(Artisan::output(), 'Pending')) {
            $this->falhas[] = 'há migração pendente';
        }

        foreach (['app/private', 'framework/cache', 'logs'] as $pasta) {
            if (! is_writable(storage_path($pasta))) {
                $this->falhas[] = "storage/{$pasta} sem permissão de escrita";
            }
        }
    }
}
