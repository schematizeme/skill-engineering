---
description: schematize-engineering — decompõe a tarefa em mini-tasks independentes e paraleliza com subagents (plan-first); otimiza tempo de relógio sobre tokens
argument-hint: "[a tarefa a paralelizar]"
---

Planeje a execução **paralela** da tarefa (`references/orquestracao.md`). Padrão da casa: **tempo do usuário acima de tokens** — se dá pra dividir sem colidir, divide e paraleliza. **Nada dispara antes da aprovação.**

Tarefa: **${ARGUMENTS:-(descreva a tarefa)}**

## 1. Decida se paraleliza

- Liste as **unidades de trabalho**. Marque quais são **independentes** (sem alvo de escrita compartilhado, sem ordem obrigatória entre si).
- **Regra:** ≥3 unidades independentes e não-triviais → **fan-out**. Menos, ou acoplado/sequencial → **inline** (e diga por quê, honestamente — não paralelize por paralelizar).

## 2. Fixe o contrato ANTES (plan-first)

Se o desenho não está fechado, decida agora: interfaces/nomes, formato de saída, convenções, e o **critério de "pronto"** por unidade. Agents divergem sem contrato.

## 3. Monte o plano de fan-out (MD)

- **Ondas de até 8** subagents (teto global 25; acima de 8, ondas sequenciais de 8).
- Por agent: **brief autossuficiente** (contexto + caminhos absolutos + contrato + critério de pronto — ele começa frio, não vê esta conversa).
- **Isolamento de escrita:** se tocam o mesmo repo, `isolation: "worktree"` ou partição por diretório/arquivo sem cruzar.
- Marque passos **destrutivos/arriscados** com **gate humano**.
- Defina o passo de **gather**: como você (orquestrador) junta, integra e **verifica uma vez** (build/test/publish), paralelizando a verificação quando dá.

## 4. Peça aprovação

Mostre o plano (unidades × agents, ondas, custo aproximado, gate). **Só após "ok"** dispare a onda 1; retome de checkpoint até concluir (sem retry infinito). Achado crítico pausa e reporta.

## 5. Consolide

Junte os resultados, rode a verificação única, e **grave o archive** (§28) com a decomposição e o resultado. Confirme ao usuário: unidades feitas, ondas, verde da verificação.
