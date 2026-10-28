#!/usr/bin/env node
// Validação visual barata: roda um roteiro JSON num Chromium headless, salva um print
// por passo e escreve um report.md curto com PASS/FAIL. O agente lê só o report;
// abre um print apenas quando um passo falha ou quando precisa julgar layout.
//
// Uso: node capture.mjs <roteiro.json> [--audio] [--headed]
// Rodar a partir da raiz do projeto (usa o playwright do node_modules dele).

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';

const args = process.argv.slice(2);
const scenarioPath = args.find((a) => !a.startsWith('--'));
const withAudio = args.includes('--audio');
const headed = args.includes('--headed');

if (!scenarioPath) {
    console.error('uso: node capture.mjs <roteiro.json> [--audio] [--headed]');
    process.exit(2);
}

const cwd = process.cwd();
const require = createRequire(path.join(cwd, 'package.json'));
// prefere o Playwright do projeto; projeto sem Playwright usa o da própria skill
const skillRequire = createRequire(import.meta.url);
let chromium;
for (const load of [() => require('@playwright/test'), () => require('playwright'), () => skillRequire('playwright')]) {
    try {
        ({ chromium } = load());
        break;
    } catch {
        // tenta o próximo
    }
}
if (!chromium) {
    console.error('Playwright não encontrado. Rode: npm --prefix ~/.claude/skills/validacao-visual i');
    process.exit(2);
}

const scenario = JSON.parse(fs.readFileSync(scenarioPath, 'utf8'));
const baseUrl = (scenario.baseUrl ?? 'http://localhost:8000').replace(/\/$/, '');
const stamp = new Date().toISOString().slice(0, 16).replace(/[:T]/g, '-');
const outDir = path.join(cwd, '.validacao-visual', `${scenario.name ?? 'roteiro'}-${stamp}`);
fs.mkdirSync(outDir, { recursive: true });

// segredo vem do .env do projeto e nunca é impresso
function envValue(key) {
    if (process.env[key]) return process.env[key];
    const envFile = path.join(cwd, '.env');
    if (!fs.existsSync(envFile)) return undefined;
    const line = fs
        .readFileSync(envFile, 'utf8')
        .split('\n')
        .find((l) => l.startsWith(`${key}=`));
    return line?.slice(key.length + 1).replace(/^["']|["']$/g, '');
}

const DEFAULT_TEST_PASSWORD = 'q1w2e3r4';

const VIEWPORTS = {
    desktop: { width: 1366, height: 800 },
    mobile: { width: 390, height: 844, isMobile: true, hasTouch: true },
};

// sem browser do playwright em cache, usa o Google Chrome instalado
const browser = await chromium
    .launch({ headless: !headed })
    .catch(() => chromium.launch({ headless: !headed, channel: 'chrome' }));
const contexts = new Map();
const consoleErrors = [];

async function contextFor(accountKey, viewportKey) {
    const key = `${accountKey ?? 'anon'}|${viewportKey}`;
    if (contexts.has(key)) return contexts.get(key);

    const vp = VIEWPORTS[viewportKey] ?? VIEWPORTS.desktop;
    const context = await browser.newContext({
        viewport: { width: vp.width, height: vp.height },
        isMobile: vp.isMobile ?? false,
        hasTouch: vp.hasTouch ?? false,
        locale: 'pt-BR',
    });
    const page = await context.newPage();
    page.on('console', (msg) => {
        if (msg.type() === 'error') consoleErrors.push(`[${accountKey ?? 'anon'}] ${msg.text().slice(0, 200)}`);
    });
    page.on('pageerror', (err) => consoleErrors.push(`[${accountKey ?? 'anon'}] ${String(err).slice(0, 200)}`));

    const account = accountKey ? scenario.accounts?.[accountKey] : null;
    if (account) {
        // senha padrão de teste local do Alessandro; conta pode sobrescrever via passwordEnv
        const password = (account.passwordEnv && envValue(account.passwordEnv)) || DEFAULT_TEST_PASSWORD;
        await page.goto(baseUrl + (account.loginPath ?? scenario.loginPath ?? '/login'), { waitUntil: 'networkidle' });
        await page.locator(account.emailField ?? 'input[type="email"], #email, input[name="email"]').first().fill(account.email);
        await page.locator(account.passwordField ?? 'input[type="password"]').first().fill(password);
        await Promise.all([
            page.waitForLoadState('networkidle').catch(() => {}),
            page.locator('button[type="submit"]').first().click(),
        ]);
        const loginPath = account.loginPath ?? scenario.loginPath ?? '/login';
        await page.waitForURL((url) => url.pathname !== loginPath, { timeout: 10_000 }).catch(() => {});
        if (new URL(page.url()).pathname === loginPath) {
            throw new Error(`login falhou para a conta "${accountKey}" (${account.email})`);
        }
    }

    const entry = { context, page };
    contexts.set(key, entry);
    return entry;
}

// gate ECA 18+ do site: passa pelo fluxo real (boas-vindas → privacidade → data).
// Só roda se o modal aparecer; depois a sessão lembra e o custo é uma checagem rápida.
async function passAgeGate(page) {
    const [year, month, day] = String(scenario.ageGate).split('-');
    const first = page.getByRole('button', { name: 'Continuar', exact: true }).first();
    const dia = page.getByLabel('Dia', { exact: true }).first();
    const appeared = await Promise.race([
        first.waitFor({ state: 'visible', timeout: 2500 }).then(() => true),
        dia.waitFor({ state: 'visible', timeout: 2500 }).then(() => true),
    ]).catch(() => false);
    if (!appeared) return;
    for (const name of ['Continuar', 'Entendi, continuar']) {
        const btn = page.getByRole('button', { name, exact: true }).first();
        if (await btn.isVisible().catch(() => false)) await btn.click({ timeout: 5000 });
    }
    await dia.waitFor({ state: 'visible', timeout: 4000 });
    await dia.selectOption(String(Number(day)));
    await page.getByLabel('Mês', { exact: true }).first().selectOption(String(Number(month)));
    await page.getByLabel('Ano', { exact: true }).first().selectOption(year);
    await page.getByRole('button', { name: 'Confirmar e entrar' }).first().click({ timeout: 5000 });
    await dia.waitFor({ state: 'hidden', timeout: 5000 }).catch(() => {});
    await page.waitForLoadState('networkidle').catch(() => {});
}

// substring respeitando maiúsculas: getByText sem exact ignora caixa ("NaN" casaria com "Financeiro")
function textPattern(text) {
    return new RegExp(text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
}

function locate(page, target) {
    if (typeof target === 'string') return page.locator(target).first();
    if (target.role) return page.getByRole(target.role, { name: target.name, exact: target.exact ?? false }).first();
    if (target.text) return page.getByText(target.text, { exact: target.exact ?? false }).first();
    if (target.label) return page.getByLabel(target.label).first();
    throw new Error(`alvo inválido: ${JSON.stringify(target)}`);
}

const results = [];
let index = 0;

for (const step of scenario.steps) {
    index += 1;
    const label = `${String(index).padStart(2, '0')}-${(step.name ?? 'passo').replace(/[^\w-]+/g, '-').slice(0, 40)}`;
    const checks = [];
    let status = null;

    try {
        const { page } = await contextFor(step.as ?? scenario.defaultAs, step.viewport ?? scenario.viewport ?? 'desktop');

        if (step.goto) {
            const response = await page.goto(baseUrl + step.goto, { waitUntil: 'networkidle' });
            status = response?.status() ?? null;
            // fecha modais conhecidos (boas-vindas, idade, cookies) antes das checagens
            for (const target of [].concat(scenario.dismiss ?? [])) {
                const el = locate(page, target);
                if (await el.isVisible({ timeout: 1500 }).catch(() => false)) {
                    await el.click({ timeout: 5000 }).catch(() => {});
                    await page.waitForTimeout(300);
                }
            }
            if (scenario.ageGate) await passAgeGate(page);
        }
        if (step.click) {
            await locate(page, step.click).click();
            await page.waitForLoadState('networkidle').catch(() => {});
        }
        if (step.fill) {
            for (const [selector, value] of Object.entries(step.fill)) await page.locator(selector).first().fill(String(value));
        }
        if (step.check) await locate(page, step.check).check();

        const finalPath = new URL(page.url()).pathname;
        if (step.expectUrl) checks.push([`url contém ${step.expectUrl}`, finalPath.includes(step.expectUrl), finalPath]);
        if (step.expectStatus) checks.push([`status ${step.expectStatus}`, status === step.expectStatus, String(status)]);
        for (const text of [].concat(step.expectText ?? [])) {
            const visible = await page.getByText(textPattern(text)).first().isVisible().catch(() => false);
            checks.push([`texto "${text}"`, visible, visible ? 'visível' : 'ausente']);
        }
        for (const text of [].concat(step.expectNoText ?? [])) {
            const visible = await page.getByText(textPattern(text)).first().isVisible().catch(() => false);
            checks.push([`sem texto "${text}"`, !visible, visible ? 'presente' : 'ausente']);
        }
        for (const selector of [].concat(step.expectSelector ?? [])) {
            const visible = await page.locator(selector).first().isVisible().catch(() => false);
            checks.push([`elemento ${selector}`, visible, visible ? 'visível' : 'ausente']);
        }
        if (step.expectAttr) {
            const { selector, attr, contains } = step.expectAttr;
            const value = await page.locator(selector).first().getAttribute(attr).catch(() => null);
            checks.push([`${selector}[${attr}] contém ${contains}`, (value ?? '').includes(contains), value ?? 'null']);
        }

        await page.screenshot({ path: path.join(outDir, `${label}.jpg`), type: 'jpeg', quality: 60, fullPage: step.fullPage ?? false });
        results.push({ label, name: step.name, finalPath, status, checks, error: null });
    } catch (err) {
        results.push({ label, name: step.name, finalPath: null, status, checks, error: String(err.message ?? err).split('\n')[0] });
    }
}

await browser.close();

const failed = results.filter((r) => r.error || r.checks.some(([, ok]) => !ok));
const lines = [
    `# ${scenario.name ?? 'roteiro'} — ${failed.length === 0 ? 'PASS' : `FAIL (${failed.length}/${results.length})`}`,
    `base: ${baseUrl} · prints: ${outDir}`,
    '',
];
for (const r of results) {
    const ok = !r.error && r.checks.every(([, pass]) => pass);
    lines.push(`- ${ok ? 'PASS' : 'FAIL'} ${r.label} — ${r.name ?? ''} → ${r.finalPath ?? '?'}${r.status ? ` (${r.status})` : ''}`);
    if (r.error) lines.push(`  - erro: ${r.error}`);
    for (const [what, pass, got] of r.checks) if (!pass) lines.push(`  - ${what}: obtido ${got}`);
}
if (consoleErrors.length) {
    lines.push('', `console errors (${consoleErrors.length}, até 5):`, ...consoleErrors.slice(0, 5).map((e) => `- ${e}`));
}
const report = lines.join('\n');
fs.writeFileSync(path.join(outDir, 'report.md'), `${report}\n`);
console.log(report);

// resumo falado opcional (macOS `say`), para ouvir sem abrir nada
if (withAudio) {
    const spoken = `${scenario.name ?? 'Roteiro'}: ${results.length - failed.length} de ${results.length} passos aprovados.` +
        (failed.length ? ` Falharam: ${failed.map((r) => r.name).join(', ')}.` : ' Tudo certo.');
    try {
        execFileSync('say', ['-v', 'Luciana', '-o', path.join(outDir, 'resumo.wav'), '--data-format=LEI16@22050', spoken]);
        console.log(`áudio: ${path.join(outDir, 'resumo.wav')}`);
    } catch {
        console.log('áudio: `say` indisponível, resumo só em texto');
    }
}

process.exit(failed.length ? 1 : 0);
