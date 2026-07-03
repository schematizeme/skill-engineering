---
name: schematize-engineering
metadata:
  version: 0.1.0
description: Padrões normativos de engenharia da casa — a BASE comum, agnóstica de linguagem, que se repete em toda a stack (arquitetura/DDD, MAPA+grafo+endpoints, segurança, dados/eventos, cadeia de suprimentos, observabilidade, operação/DoD/archive, anti-padrões, gestão de contexto). Use SEMPRE que for projetar, gerar, revisar ou refatorar qualquer software, decidir arquitetura, escolher stack, modelar eventos/banco, configurar observabilidade, ou produzir ADR/runbook/archive — mesmo sem citar "padrão". Contém pisos inegociáveis (segredo nunca no cliente, sem SQL concatenado, auth server-side, índice/MAPA exaustivo, archive obrigatório) que vetam atalhos inseguros. Detalhe por linguagem nas skills irmãs: schematize-go/rust (backend), schematize-web (frontend), schematize-node (legado). Pentest é a schematize-pentest.
---

# Padrões de Engenharia da Casa (base comum)

Conjunto normativo que rege como software é projetado, construído, testado e operado aqui. Esta é a **base comum, agnóstica de linguagem** — o que se repete em toda a stack. As skills irmãs **especializam** esta base por contexto: `schematize-go`/`schematize-rust` (backend), `schematize-web` (frontend), `schematize-node` (legado Node), `schematize-pentest` (teste de segurança). Use esta quando o projeto não é de uma linguagem específica, ou quando quer só os princípios da casa; use a irmã de linguagem quando há stack definida.

**Versão:** skill `schematize-engineering` v0.1.0. Changelog em `CHANGELOG.md`.

## Comandos (Claude Code)

Digite `/eng-help` pra ver todos. Em resumo:

| Comando | O que faz |
|---|---|
| `/eng-help` | lista todos os comandos do schematize-engineering |
| `/eng-cc` | context compact: gera context.md + checklist.md no archive e roda `/compact` |
| `/eng-handoff` | gera o handoff (context.md + checklist.md) **sem** compactar — pra fim de sessão |
| `/eng-qa` | fluxo de Q.A. plan-first (§22.9): planeja, gera MD, pede aprovação, roda |
| `/eng-review` | roda o gate da DoD/§37 no diff (arquivos >300, função sem doc, índice, macaquices) |
| `/eng-index` | (re)gera o índice de microfunções (§39) a partir dos doc-comments |

Os comandos ficam em `assets/commands/` e são instalados em `.claude/commands/`.

## Como usar esta skill

1. Identifique o domínio da tarefa e **leia o(s) reference(s) relevante(s)** antes de produzir código ou decisão. Não trabalhe de memória — os detalhes (versões, limites, convenções) estão nos arquivos.
2. **Sempre** aplique os pisos inegociáveis abaixo, independente do reference carregado.
3. Ao terminar, valide contra a Definition of Done (`references/entrega.md`, §35) e **gere o archive** (§28, `references/operacao.md`).

Mapa de references — leia o que casa com a tarefa:

| Tarefa | Reference |
|---|---|
| **Limites de código (≤300 linhas), uma função/arquivo, comentários, MAPA** | `references/padroes-codigo.md` |
| Arquitetura, camadas, DDD, repositórios, anti-monólito, shared libs, linguagens, CQRS | `references/arquitetura.md` |
| Eventos/mensageria, banco, cache, APIs, resiliência, jobs | `references/dados-eventos.md` |
| Segurança, auth, JWT, multi-tenancy, LGPD, **frontend/segredos** | `references/seguranca.md` |
| **Cadeia de suprimentos: lockfile, SBOM, scan que trava, imagem mínima/pinada/assinada, SLSA, segredo no build** | `references/cadeia-suprimentos.md` |
| Testes — test kit, saída machine-readable, categorias de teste (§22.1–22.3) | `references/testes.md` |
| Testes — padrão de script, seeds, CI, pentest, Q.A. plan-first, Makefile (§22.4–23) | `references/testes-execucao.md` |
| Observabilidade, healthchecks, performance, FinOps | `references/observabilidade.md` |
| Config, deploy/K8s, git/PR, ownership, runbooks/incidentes, ADR, **archive** (§20–28) | `references/operacao.md` |
| Templates, feature flags, IA assistida, DoD, evolução, índice de funcionalidades (§29+) | `references/entrega.md` |
| Filosofia, aplicação universal e a lista completa de anti-padrões vetados | `references/anti-padroes.md` |
| Gestão de contexto em sessões longas no Claude Code (handoff, hooks) | `references/contexto-claude-code.md` |

## Pisos inegociáveis (VETADO — sem ADR de exceção)

Estes nunca são violados, nem "pra funcionar", nem "pra ir mais rápido". A lista completa com veto + caminho certo está em `references/anti-padroes.md` (§37). Os que mais aparecem em código gerado às pressas:

- **Segredo nunca no cliente.** Nada de API key, secret de JWT, senha de banco, service-role key ou token em bundle do browser, nem em `NEXT_PUBLIC_*`/`VITE_*`. Segredo só server-side (BFF/route handler/secret manager). Detalhe em `references/seguranca.md`.
- **SQL sempre parametrizado.** Concatenar string em query é injeção esperando acontecer.
- **Auth e autorização server-side.** `tenant_id`/role/`user_id` vêm do token verificado, nunca do body/header do cliente. Validação no front é UX, não controle.
- **JWT validado por inteiro** (assinatura, exp, aud, iss, alg em allowlist). Senha em bcrypt cost ≥ 12 ou argon2id. Token/id de sessão por CSPRNG, nunca `Math.random()`.
- **Erro nunca engolido** (`catch {}`, `except: pass`, `_ = err`); sem `any`/`@ts-ignore`/`unwrap()` pra calar o compilador.
- **Teste nunca silenciado** pra passar CI (`.skip`, comentar assert, baixar threshold de cobertura). Conserta o código, não o teste.
- **Sem monólito que mistura bounded contexts**, sem monólito distribuído, sem shared lib `commons` de domínio. Detalhe em `references/arquitetura.md`.
- **Archive SEMPRE gerado.** Toda entrega que produz código/decisão/mudança de estado gera o `.md` de archive (§28) — é parte da entrega, não extra. Pular é violação direta. Templates em `assets/`.
- **Migration reversível** (com `down`, testada com rollback). Container não-root, read-only. Dependência nova com nome/licença/versão verificados (typosquatting é real).
- **Pisos de código (`references/padroes-codigo.md`):** arquivos **≤ 300 linhas** (acima → quebrar por coesão), **uma função/unidade lógica por arquivo** (função > 300 linhas é quebrada), **toda função com doc-comment** (motivo, comportamento esperado, entradas, saídas, efeitos), **`MAPA.md` da aplicação** atualizado no mesmo PR, e **índice de microfunções** regenerado (`/eng-index`). Detalhe também em `references/arquitetura.md` (§6) e `references/operacao.md` (§39).
- **Backend novo só em Go ou Rust; Node backend é proibido.** Node legado não se mexe salvo solicitado; migração medida por funcionalidade do módulo (~30% afetado → extrai pra módulo Go/Rust à parte; ~50% extraído → migra o resto; ajuste pontual não porta). **PHP é proibido** e migra sumariamente. **Frontend Node é 100% permitido** (Next.js principal; Astro e outros) — só frontend. Detalhe em `references/arquitetura.md` (§3).

> Regra de bolso: se a justificativa começa com "só pra funcionar", "depois eu arrumo" ou "é mais rápido assim" e o resultado mexe em segredo, auth, dado ou registro — é um anti-padrão vetado. Pare e faça certo.

## Testes — o que conta como "verde de verdade"

Detalhe completo em `references/testes.md` (§22.1–22.3) e `references/testes-execucao.md` (§22.4–23). O essencial:

- **Smoke não pode ser teatro:** assertar shape do body (não só status 200), assertion negativa (sem stack trace/placeholder), e um **self-check que força uma falha conhecida** pra provar que o runner consegue reportar FAIL. Smoke que nunca falha está cego.
- **Unit agressivo:** caminho de erro obrigatório, casos hostis (tipo errado, unicode, null byte, boundary), property-based e mutation testing no domínio crítico. Cobertura de linha é piso, não meta.
- **Pentest prova rejeição, rota por rota, campo por campo:** nunca 500 por input hostil, nunca coerção silenciosa de tipo (varchar onde é int), nunca eco sem escape, nunca vazamento cross-tenant. Princípios em `references/testes-execucao.md` (§22.8).
- **`simulated` (teste emulado):** cruza rotas × personas × injections e prova que **100% das rotas** do inventário estão acessíveis pra quem deve e bloqueadas pra quem não deve. Rota fantasma/morta quebra o run.
- **Fluxo de Q.A. (plan-first, §22.9):** toda submissão de Q.A. **planeja tudo primeiro**, gera um MD detalhado de passo a passo, e **pede aprovação do usuário antes de executar**. Aprovado, oferece rodar **faseado e assistido** ou **de uma vez**; no "de uma vez", usa multiagentes e cron/watchdog que retoma de checkpoint até concluir (sem retry infinito, passo destrutivo só com gate). Nada de Q.A. roda às cegas.

## Andaime pronto (scripts e templates)

Não escreva do zero o que já está bundlado:

- `scripts/lib.sh` — helpers de teste (`test_pass`, `test_fail`, `test_skip`, `test_section`, `test_summary`, `http_call`, `assert_http_in`). Todo script de teste usa estes.
- `scripts/test-skeleton.sh` — esqueleto obrigatório de `tests/<mode>/<name>.sh`.
- `scripts/smoke-selfcheck.sh` — o meta-teste anti "verde mentiroso".
- `scripts/simulated/run.py` — scaffold do engine rotas × personas × injections.
- `scripts/hooks/context-monitor.mjs` + `scripts/hooks/precompact-backup.mjs` — gestão de contexto no Claude Code: detectam o limite de handoff (default 250k) e fazem backup automático em `<projeto>_archive` antes da compactação. Ver `references/contexto-claude-code.md` e `assets/settings.claude.example.json`.
- `assets/ADR.md`, `assets/TASK.md`, `assets/CHAT_ARCHIVE.md`, `assets/PR_TEMPLATE.md`, `assets/RUNBOOK.md` — templates. ADR/TASK/CHAT_ARCHIVE cumprem §27/§28.
- `assets/INDEX_GLOBAL.md` + `assets/INDEX_FUNCTIONS.md` + `scripts/build-index.mjs` — índice de funcionalidades (§39): o global (repos/pastas/comunicação) é mantido à mão; o de microfunções é **gerado** dos doc-comments (§6) pelo `build-index.mjs`, que sai 1 se achar função sem contexto (trava CI).
- `assets/CLAUDE.md` — arquivo "sempre on" pra colocar na **raiz do repositório**: garante que estes padrões fiquem pinados no contexto de toda tarefa, não só quando a skill dispara. Copie e ajuste `<project>`.
- `assets/commands/eng-cc.md` — comando `/eng-cc` (context compact) pro Claude Code: gera `context.md` + `checklist.md` em `<projeto>_archive` e compacta. Copie para `.claude/commands/eng-cc.md`. Ver `references/contexto-claude-code.md`.

## Aplicação sempre-on

Esta skill é puxada quando a tarefa casa com a descrição. Para garantir que os padrões valham em **toda** interação do repo (e não só nas que disparam a skill), copie `assets/CLAUDE.md` para a raiz do projeto. Os dois mecanismos se complementam: o `CLAUDE.md` pina o resumo e aponta pra cá; a skill entrega o detalhe e o andaime.
