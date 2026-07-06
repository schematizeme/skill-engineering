# Changelog — schematize-engineering

Formato: [Keep a Changelog]; versionamento: SemVer.

## [0.5.0] — 2026-07-05
Control plane `<projeto>_ops`: fluxo de ambientes, ops como interface única, instalação paralela, independência invariante.

### Adicionado
- **`references/ops.md`**: (1) **fluxo de promoção fixo** `dev local → teste local → GitHub → hml → prd`, **nada direto no servidor** — editar código em hml/prd é VETADO (servidor imutável por edição manual; drift detection, filesystem read-only, break-glass auditado); (2) **ops é a interface única** — 100% de install/update/correção/config passa por comando do `<projeto>_ops`, que é autônomo/idempotente/completo (usuário provisiona o servidor do zero sem a IA); (3) **instalação sempre paralela** = `nproc`; (4) **independência é invariante** — falha no paralelo = serviços não independentes → corrigir é prioridade máxima; ops expõe a colisão, nunca serializa pra mascarar.
- **Comando `/eng-ops`** (plan-first): audita/scaffolda o ops, verifica fluxo de ambientes, paralelização e independência.
- Pisos **14 e 15** no `CLAUDE.md` sempre-on; pisos no SKILL.md; anti-padrões **35–38** (editar no servidor, pular pra hml/prd, operar fora do ops, instalar serial, serializar pra mascarar dependência); `operacao.md` §21 estendido; `/eng-load` carrega `ops.md`.

## [0.4.0] — 2026-07-05
Índice único de comandos entre skills.

### Adicionado
- **Comando `/schematize-help`**: o "help dos helps" — varre os comandos instalados (projeto + global) de **todas** as skills da casa (go/rust/web/node/eng/pentest), lê a `description:` de cada um e apresenta um índice agrupado por skill, com legenda do catálogo e como instalar skills faltantes. `/eng-help` passa a apontar pra ele.

## [0.3.0] — 2026-07-05
Permanência (MD como backup à prova de crash) e **todo MD gerado no archive, root limpo**.

### Adicionado
- **§28.0 (`references/operacao.md`): layout canônico do archive** — todo `.md` gerado (MAPA, índices, planos, relatórios, handoffs, checkpoints) mora em `<projeto>_archive/<área>/`, **NUNCA no root**. Subpastas: `index/`, `context/`, `orchestration/`, `pentest/`, `chat/`, `task/`. Root fica limpo (só código, config e MDs de projeto à mão).
- **Permanência da orquestração (`references/orquestracao.md` §7):** o MD de checkpoint é gravado **antes** de disparar a onda 1, com tabela de status por unidade; cada subagent grava o próprio resultado no archive; retomada por leitura do checkpoint (não recomeça do zero). Comando `/eng-orchestrate` atualizado.

### Corrigido
- **MAPA/índice saíam no root.** Agora `MAPA.md`, `INDEX_GLOBAL.md`, `INDEX_FUNCTIONS.md` vão para **`<projeto>_archive/index/`** (`padroes-codigo.md` §4, `assets/MAPA.md`, `/eng-index`, `build-index.mjs` (uso), `CLAUDE.md`, `SKILL.md`).

## [0.2.0] — 2026-07-04
Orquestração & paralelização como piso — **tempo do usuário acima de tokens**.

### Adicionado
- **`references/orquestracao.md`**: quando a tarefa se divide em ≥3 unidades independentes, decompor em mini-tasks e **paralelizar com subagents** em vez de serial; fan-out de **8 por onda** (teto global **25**); regra fan-out-vs-inline; independência (sem alvo de escrita compartilhado, sem ordem obrigatória); brief autossuficiente (agent começa frio); isolamento de escrita (worktree/partição); gather + verificação única pelo orquestrador; onde **não** paralelizar; plan-first.
- **Comando `/eng-orchestrate`**: planeja a decomposição/fan-out, fixa o contrato, mostra o plano e pede aprovação antes de disparar as ondas.
- Piso 13 no `CLAUDE.md` sempre-on e piso correspondente no SKILL.md; `/eng-load` e `/eng-help` atualizados.

## [0.1.0] — 2026-07-03
Primeira release — a **base comum de engenharia** da casa, agnóstica de linguagem, extraída do corpo normativo compartilhado entre `schematize-go`/`rust`/`web`/`node`.

### Adicionado
- Corpo normativo language-agnostic: arquitetura/DDD, estrutura de repositórios + `<projeto>_ops` + contenção no workspace, **padrões de código** (≤300 linhas, doc-comment com fluxo de dado, **MAPA+grafo+índice exaustivo por contagem**), segurança (segredo server-side, SQL parametrizado, authz), dados/eventos + independência de runtime, cadeia de suprimentos, observabilidade (LGTM+), operação/entrega/DoD/**archive** e anti-padrões (§37).
- Comandos `/eng-help`, `/eng-load`, `/eng-claude`, `/eng-index`, `/eng-review`, `/eng-qa`, `/eng-cc`, `/eng-handoff`; `CLAUDE.md` sempre-on.
- Referência ao **mapa de endpoints** (`schematize-pentest`) na superfície de entrada do índice.

> As skills de linguagem (`schematize-go`/`rust`/`web`/`node`) especializam esta base; use esta quando o projeto não é de uma linguagem específica.
