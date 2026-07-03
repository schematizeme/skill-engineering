# Changelog — schematize-engineering

Formato: [Keep a Changelog]; versionamento: SemVer.

## [0.1.0] — 2026-07-03
Primeira release — a **base comum de engenharia** da casa, agnóstica de linguagem, extraída do corpo normativo compartilhado entre `schematize-go`/`rust`/`web`/`node`.

### Adicionado
- Corpo normativo language-agnostic: arquitetura/DDD, estrutura de repositórios + `<projeto>_ops` + contenção no workspace, **padrões de código** (≤300 linhas, doc-comment com fluxo de dado, **MAPA+grafo+índice exaustivo por contagem**), segurança (segredo server-side, SQL parametrizado, authz), dados/eventos + independência de runtime, cadeia de suprimentos, observabilidade (LGTM+), operação/entrega/DoD/**archive** e anti-padrões (§37).
- Comandos `/eng-help`, `/eng-load`, `/eng-claude`, `/eng-index`, `/eng-review`, `/eng-qa`, `/eng-cc`, `/eng-handoff`; `CLAUDE.md` sempre-on.
- Referência ao **mapa de endpoints** (`schematize-pentest`) na superfície de entrada do índice.

> As skills de linguagem (`schematize-go`/`rust`/`web`/`node`) especializam esta base; use esta quando o projeto não é de uma linguagem específica.
