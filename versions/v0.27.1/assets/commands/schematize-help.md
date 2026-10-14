---
description: Índice ÚNICO de todos os comandos schematize instalados (as 37 skills da casa) — o que cada um faz, agrupado por skill
---

Mostre o **índice completo** dos comandos schematize — todas as skills num lugar só. É o "help dos helps".

## 1. Descubra o que está instalado (lista VIVA)

A lista de skills muda com o tempo: **não confie em contagem fixa** — gere-a agora a partir do disco.

- Skills instaladas: `ls ~/.claude/skills` (global) e `.claude/skills` (projeto); cada `schematize-<slug>/` é uma skill.
- Comandos (projeto tem prioridade sobre global): `.claude/commands/*.md` e `~/.claude/commands/*.md`.

Cada skill tem um **prefixo de comando** que NÃO se deriva do nome (C# é `schematize-csharp` mas os comandos são `/cs-*`; a overdev-context usa `/overdev-context-*`). Use o catálogo da seção 3 para mapear; para um prefixo desconhecido, leia o 1º arquivo `<prefixo>-*.md` e a `description:` do frontmatter (fonte da verdade do que o comando faz). Comando que existe no projeto **e** no global: use o do projeto e marque `(local)`.

```
for f in ~/.claude/commands/*.md .claude/commands/*.md; do
  [ -e "$f" ] || continue
  desc=$(awk 'f==1&&/^description:/{sub(/^description:[[:space:]]*/,"");print;exit}/^---/{f++}' "$f")
  printf "/%s\t%s\n" "$(basename "$f" .md)" "$desc"
done
```

## 2. Apresente agrupado

Uma tabela por **grupo** (seção 3), só com as skills **instaladas**; colunas: **comando** · **o que faz** (1 linha da `description:`). Encurte prefixos redundantes (`schematize-xxx — `). Skill do catálogo que não está instalada entra na legenda final como não instalada.

Padrões comuns a quase todas (explique 1 vez, no topo): `/<prefixo>-help` lista os comandos da skill · `/<prefixo>-load` carrega TODO o corpo normativo · `/<prefixo>-claude` instala/mescla o `CLAUDE.md` sempre-on · `/<prefixo>-index` (re)gera índice/MAPA no archive · `/<prefixo>-review` gate da DoD/anti-padrões no diff · `/<prefixo>-cc` / `/<prefixo>-handoff` context compact / handoff no archive. Depois liste **só os comandos próprios** de cada skill, com destaque (ex.: `/eng-overdev`, `/eng-orchestrate`, `/eng-scan`, `/qa-plan`, `/pentest-gate`, `/archive-todos`, `/scaffold-new`).

## 3. Catálogo das 37 skills (slug · prefixo de comando · domínio)

Marque cada uma como instalada ou não comparando com `ls ~/.claude/skills`.

**Base e processo**
- `schematize-engineering` · `/eng-*` — base comum agnóstica (arquitetura/DDD, segurança, dados, observabilidade, DoD/archive, orquestração, overdev, scan, plan, refactor).
- `schematize-scaffold` · `/scaffold-*` — projeto novo: o piso do dia 0 na ordem certa.
- `schematize-overdev-context` · `/overdev-context-*` — Fase 0 do overdev: decisões, grafo, plano e checklist.
- `schematize-archive` · `/archive-*` — archive como criticidade 0; gera afazeres do overdev a partir do histórico.
- `schematize-audit` · `/audit-*` — prova que todo checklist foi sanado (órfãos RED).
- `schematize-qa` · `/qa-*` — Q.A.: pirâmide de testes, "verde de verdade", plan-first.
- `schematize-pentest` · `/pentest-*` — segurança ofensiva defensiva/red-team autorizado.
- `schematize-docs` · `/docs-*` — ADR, runbook, OpenAPI, índice/MAPA.
- `schematize-models` · `/models-*` — orquestra Codex, Gemini e Cursor como subagents; imagem sempre fora do Claude (pergunta qual usar); saída externa não confiável.

**Linguagens do rol de backend (por fit + ADR, sem hierarquia)**
- `schematize-go` · `/go-*` · `schematize-rust` · `/rust-*` · `schematize-elixir` · `/elixir-*` · `schematize-csharp` · **`/cs-*`** · `schematize-zig` · `/zig-*` · `schematize-ruby` · `/ruby-*`. Escolha e desempate: `schematize-engineering → references/linguagens.md`.

**Sancionadas fora do rol de backend** (`linguagens.md` §2.2)
- `schematize-c` · `/c-*` e `schematize-cpp` · `/cpp-*` — manutenção defensiva (componente novo nasce em Rust/Zig, por ADR).
- `schematize-swift` · `/swift-*`, `schematize-kotlin` · `/kotlin-*`, `schematize-dart` · `/dart-*` — clientes mobile, sob a `schematize-mobile`.
- `schematize-shell` · `/shell-*` e `schematize-python` · `/python-*` — ferramenta (script, dados/ML, automação).
- `schematize-node` · `/node-*` — manutenção de legado Node/TS (sem backend novo; PHP migra quando tocado).

**Domínio**
- `schematize-web` · `/web-*` — frontend (Next.js/Astro). `schematize-design` · `/design-*` — direção visual, wireframe antes do código, anti-AI-slop. `schematize-mobile` · `/mobile-*` — apps iOS/Android/cross. `schematize-desktop` · `/desktop-*` — software local/nativo.
- `schematize-data` · `/data-*` — engenharia de dados. `schematize-database` · `/database-*` — modelagem relacional. `schematize-ai` · `/ai-*` — software com LLM.
- `schematize-infra` · `/infra-*` — infra/DevOps/SRE. `schematize-docker` · `/docker-*` — Dockerfile/OCI, compose, SBOM, cosign, hardening. `schematize-terraform` · `/tf-*` — IaC com OpenTofu/Terraform (state, módulos, plan/apply gated). `schematize-observability` · `/obs-*` — OpenTelemetry, SLO, alertas, dashboards como código.
- `schematize-seo` · `/seo-*` — SEO (estratégia e técnico). `schematize-seo-writing` · `/seow-*` — redação SEO em 4 passos com checador. `schematize-institutional` · `/institutional-*` — site institucional.

Skill faltando? Instale: `git clone https://github.com/schematizeme/skill-<slug>.git && ./skill-<slug>/install.sh` (ou `install.sh ~` pra global). Detalhe de qualquer comando: abra o `.md` dele em `.claude/commands/` ou rode o `/<prefixo>-load`. Catálogo web: `skills.schematize.me`.
