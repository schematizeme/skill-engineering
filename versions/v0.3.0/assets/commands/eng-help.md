---
description: schematize-engineering — lista todos os comandos disponíveis e o que cada um faz
---

Mostre ao usuário a lista de comandos do conjunto **schematize-engineering**, em formato
de tabela legível, exatamente com este conteúdo (ajuste se houver comandos novos
instalados em `.claude/commands/`):

| Comando | O que faz |
|---|---|
| `/eng-help` | Lista todos os comandos do schematize-engineering (este). |
| `/eng-load` | **Carrega à força TODO o corpo normativo** (DDD/arquitetura, clean code, segurança, dados, testes, operação) no contexto e passa a aplicá-lo no projeto como regra inegociável. |
| `/eng-claude` | Cria ou **atualiza (sobrescreve)** o `CLAUDE.md` da raiz com a versão atual da skill (backup se houver customização local). |
| `/eng-cc` | Context compact: gera `context.md` + `checklist.md` em `<projeto>_archive/context/` e roda `/compact`. |
| `/eng-handoff` | Gera o handoff (`context.md` + `checklist.md`) **sem** compactar — ideal pra fim de sessão ou troca de tarefa. |
| `/eng-qa` | Fluxo de Q.A. plan-first (§22.9): planeja tudo, gera MD de passo a passo, pede aprovação, e roda faseado/assistido ou de uma vez. |
| `/eng-review` | Roda o gate da Definition of Done e dos anti-padrões (§35, §37): arquivos >300 linhas, função sem doc-comment, índice desatualizado, macaquices de segurança. |
| `/eng-index` | (Re)gera o índice de microfunções (§39) a partir dos doc-comments das funções. |
| `/eng-orchestrate` | Decompõe a tarefa em mini-tasks independentes e paraleliza com subagents (plan-first): otimiza tempo de relógio sobre tokens; fan-out de 8/onda, teto 25. |

Depois da tabela, diga em uma linha que o detalhe normativo está na skill
`schematize-engineering` (referências em `references/`) e que o site é `skills.schematize.me/go`.
