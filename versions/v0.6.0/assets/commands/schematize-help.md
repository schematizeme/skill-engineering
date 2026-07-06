---
description: Índice ÚNICO de todos os comandos schematize instalados (go/rust/web/node/eng/pentest) — o que cada um faz, agrupado por skill
---

Mostre o **índice completo** dos comandos schematize — todas as skills num lugar só. É o "help dos helps".

## 1. Descubra o que está instalado

Varra os comandos instalados (projeto tem prioridade sobre global):
- Projeto: `.claude/commands/*.md`
- Global: `~/.claude/commands/*.md`

Considere os que começam com os prefixos das skills da casa: `eng-`, `go-`, `rust-`, `web-`, `node-`, `pentest-`, `schematize-`. Para cada arquivo, leia a **1ª linha `description:`** do frontmatter (é a fonte da verdade do que o comando faz). Se um comando existir no projeto **e** no global, use o do projeto e marque `(local)`.

Dica de extração (ajuste o caminho):
```
for f in ~/.claude/commands/{eng,go,rust,web,node,pentest,schematize}-*.md; do
  [ -e "$f" ] || continue
  desc=$(awk 'f==1&&/^description:/{sub(/^description:[[:space:]]*/,"");print;exit}/^---/{f++}' "$f")
  printf "/%s\t%s\n" "$(basename "$f" .md)" "$desc"
done
```

## 2. Apresente agrupado por skill

Uma tabela por skill **instalada**, na ordem: `schematize-engineering` (base), `-go`, `-rust`, `-web`, `-node`, `-pentest`. Colunas: **comando** · **o que faz** (1 linha, tirada da `description:`). Encurte prefixos redundantes (`schematize-xxx — `). Cabeçalho de cada grupo com o nome da skill + 1 linha do domínio dela.

Padrões comuns a quase todas (explique 1 vez, no topo, pra não repetir 6×):
- `/<slug>-help` — comandos daquela skill · `/<slug>-load` — carrega TODO o corpo normativo · `/<slug>-claude` — instala/mescla o `CLAUDE.md` sempre-on · `/<slug>-index` — (re)gera índice/MAPA no `<projeto>_archive/index/` · `/<slug>-qa` — Q.A. plan-first · `/<slug>-review` — gate da DoD/anti-padrões no diff · `/<slug>-cc` / `/<slug>-handoff` — context compact / handoff no archive.
- Depois liste **só os comandos próprios** de cada skill (os que fogem do padrão), com destaque: ex. `/eng-orchestrate`, `/node-audit`, `/node-migrate-status`, `/pentest-plan`, `/pentest-endpoints`, `/pentest-authz`, `/pentest-threat-model`, `/pentest-report`.

## 3. Legenda das skills (o que existe, instalado ou não)

Feche com o catálogo das 6 skills e quando usar cada uma, marcando ✅ instalada / ⬚ não instalada (compare com `~/.claude/skills/`):
- **schematize-engineering** — base comum agnóstica de linguagem (arquitetura/DDD, MAPA+grafo+endpoints, segurança, dados, observabilidade, DoD/archive, orquestração). As de linguagem a especializam.
- **schematize-go** — backend Go/Rust. **schematize-rust** — backend Rust principal/Go auxiliar. **schematize-web** — frontend Next.js/Astro. **schematize-node** — manutenção de legado Node/TS (sem backend novo). **schematize-pentest** — teste de segurança (AppSec defensivo + red-team autorizado).

Skill faltando? Instale: `git clone https://github.com/schematizeme/skill-<slug>.git && ./skill-<slug>/install.sh` (ou `install.sh ~` pra global). Detalhe de qualquer comando: abra o `.md` dele em `.claude/commands/` ou rode o `/<slug>-load` da skill. Catálogo web: `skills.schematize.me`.
