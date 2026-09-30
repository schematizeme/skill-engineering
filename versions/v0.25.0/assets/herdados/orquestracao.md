<!--
FONTE ÚNICA da regra de orquestração ("Orquestrador não desenvolve; subagent barato executa"
+ "Sem frota ociosa") herdada pelas skills derivadas da schematize-engineering.

Mecanismo: cada skill derivada envolve o CORPO do item (depois do marcador de lista) num bloco
marcado com o comentário de abertura "herdado" (skill-base/id:variante) e o de fechamento
"/herdado". O sincronizador `tools/sync-herdados.mjs` reescreve o miolo de cada bloco com a
variante correspondente deste arquivo. Editar a regra = editar AQUI + rodar
`node tools/sync-herdados.mjs`; o CI roda com --check e reprova divergência.

Variantes (cada uma delimitada por variante:NOME ... /variante, conteúdo em UMA linha):
  longo  — item do CLAUDE.md das skills grandes (sem o número do item)
  curto  — item das skills pequenas / gates textuais
  bullet — bullet do SKILL.md

Não escreva aqui o marcador "herdado" literal: este arquivo é a fonte, não um consumidor.
-->

<!-- variante:longo -->
**Orquestrador não desenvolve; subagent barato executa.** O agent principal (o que fala com o humano, modelo padrão da sessão) **só planeja, decompõe, despacha, supervisiona e revisa** — não escreve código de entrega. Toda ação onerosa é quebrada em **micro-tasks/micro-funções** executáveis por agent barato (mesmo com <3 unidades: em série, por subagents, nunca inline no principal). Subagents rodam em **`sonnet` por padrão**; falhou → o **mesmo subagent corrige** (até 2 rodadas) → re-decompõe → só então **`opus`**, com o motivo registrado no checkpoint. O principal revisa toda entrega (diff + gate) e **só corrige com a própria mão se necessário** (trivial, 1–2 linhas). No overdev, **cada item do checklist é executado por subagent `sonnet`** e revisado pelo principal antes do `- [x]`; escalar para Opus não é pergunta, esgotou Opus → `park`. **Sem frota ociosa:** agent idle com pendência executável volta ao trabalho; pendência que depende de outro agent → mata e enfileira com gatilho de dependência; terminou → mata (§9.6). Detalhe em `schematize-engineering` → `references/orquestracao.md` §9.
<!-- /variante -->

<!-- variante:curto -->
**Orquestrador não desenvolve; subagent barato executa.** O agent principal só planeja, despacha e revisa; ação onerosa vira micro-tasks para subagents em `sonnet` (falhou → o mesmo subagent corrige, até 2 rodadas → re-decompõe → só então `opus`, com motivo). No overdev, cada item do checklist vai a um subagent e o principal revisa antes do `- [x]`. **Sem frota ociosa:** idle com pendência volta ao trabalho; dependente de outro agent → mata e enfileira com gatilho; terminou → mata (§9.6). Detalhe: `schematize-engineering` → `references/orquestracao.md` §9.
<!-- /variante -->

<!-- variante:bullet -->
**Orquestrador não desenvolve; subagent barato executa** (`schematize-engineering` → `references/orquestracao.md` §9). O principal só planeja/decompõe/despacha/supervisiona/revisa; ação onerosa vira micro-tasks; subagents em `sonnet` por padrão (falhou → mesmo subagent corrige, até 2 rodadas → re-decompõe → só então `opus`, com motivo registrado no checkpoint). No `overdev`, cada item do checklist é executado por subagent `sonnet` e revisado pelo principal (diff + gate) antes do `- [x]`. **Sem frota ociosa:** agent idle com pendência executável volta ao trabalho; pendência que depende de outro agent → mata e enfileira com gatilho de dependência; terminou → mata (§9.6).
<!-- /variante -->
