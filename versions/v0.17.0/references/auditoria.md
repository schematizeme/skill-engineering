# Auditoria de histórico — todo checklist criado foi mesmo sanado?

> A casa gera **muitos checklists** — overdev, Q.A., handoffs de contexto, planos, ADRs,
> TASKs. A pergunta que este reference responde: **algum deles ficou com item aberto,
> pergunta parkeada sem resposta, ou "concluído" que nunca foi de verdade?** É a revisão de
> histórico que fecha o loop de `scan → plan → refactor → overdev`: prova que o que foi
> prometido foi **entregue e verificado**, não só marcado.

## 1. O que se audita (as fontes)

Enumere **todos** os artefatos com checklist/promessa no projeto — do archive e do histórico
git. Conte-os (é o alvo de cobertura; artefato de fora = auditoria incompleta):

- **Overdev:** `.schematize/overdev/CHECKLIST.md` (run ativo; `.overdev/CHECKLIST.md` legado
  ainda aceito), `<projeto>_archive/overdev/OBJETIVO.md`,
  `<projeto>_archive/overdev/premature-stops.log`, `./PERGUNTAS-OVERDEV.txt`,
  `.schematize/overdev/DECISOES.md` / `PLAN.md`.
- **Q.A.:** `<projeto>_archive/qa/*.md` (planos plan-first).
- **Contexto/handoff:** `<projeto>_archive/context/*-checklist.md` (FEITO vs EM ABERTO).
- **Plano:** `<projeto>_archive/plan/*.md` (do `/eng-plan`).
- **ADR:** `assets/ADR.md` e ADRs em `<projeto>_archive/` marcados `proposed` que nunca
  viraram `accepted`/`rejected`.
- **Qualquer MD** no archive/histórico com linhas `- [ ]` / `- [~]` ou seções "TODO/EM ABERTO".

## 2. O que se verifica por item

Para cada artefato, classifique cada linha e cruze com a realidade:

| Estado | Significado | Suspeita a investigar |
|---|---|---|
| `- [x]` feito | fechado | **fechou de verdade?** (§3 — checkbox sem prova é suspeito) |
| `- [ ]` aberto | **nunca fechado** | é **órfão RED**: o run/plano encerrou deixando isto? foi retomado depois? |
| `- [~]` on-hold | pergunta parkeada | a pergunta em `PERGUNTAS-OVERDEV.txt` foi **respondida** em algum lugar? o item foi então fechado? |

Cruzamentos que pegam o buraco:
- **Overdev "concluído" com `- [ ]` aberto:** só é legítimo se fechou por budget/thrashing (§4.1) — e aí os itens travados **têm** que reaparecer num run/plano posterior. Sumiram? é dívida esquecida.
- **`premature-stops.log` com itens que faltavam:** aqueles itens foram **eventualmente feitos**? (grep no código/testes/archive).
- **Pergunta parkeada sem resposta:** `PERGUNTAS-OVERDEV.txt` com pergunta que ninguém respondeu = decisão pendente virou permanente por esquecimento.
- **ADR `proposed` órfão:** decisão que nunca foi ratificada nem descartada — está valendo? por acidente?
- **Handoff "EM ABERTO" nunca retomado:** o próximo run continuou de onde parou?

## 3. "Fechou de verdade" — prova, não fé (a guarda no vermelho)

Um `- [x]` sem evidência é **suspeito**, não fato (a mesma disciplina do red-first e do
"suspeito ≠ achado"). Faça **spot-check** dos itens marcados feitos que tocam caminho
crítico: existe o teste/commit/arquivo que prova? o gate correspondente passa hoje? Item
marcado feito cujo código sumiu ou cujo teste não existe **volta a aberto** no relatório.

## 4. Saída — o veredito e o conserto

Grava em `<projeto>_archive/audit/<data>.md`:
- **Cobertura:** `A` artefatos auditados / `A` existentes (tem que bater); total de itens por estado.
- **Órfãos RED** (o que importa): lista de `- [ ]` nunca fechados, `- [~]` sem resposta,
  perguntas parkeadas pendentes, ADRs `proposed` órfãos, itens marcados-feito que **não se
  provam** — cada um com origem (artefato + data) e o que falta.
- **Checklist de saneamento:** os órfãos viram um **novo checklist** (candidato a
  `/eng-overdev`) pra fechar de vez — reabrir + resolver + verificar + reteste.
- **Veredito de gate:** **histórico são** só quando **zero órfãos RED**. Qualquer aberto/hold/
  parkeado sem desfecho = **não fecha** — é dívida rastreável, não "já era".

## 5. Quando rodar

- **Fim de marco/entrega**, antes de dizer "pronto" no macro (não só na task).
- **Início de retomada** de um projeto parado (o que ficou pra trás?).
- **Periódico** (cron/agendado) em projeto ativo — o overdev fecha a sessão viva; o audit
  cobre o "ficou um rastro no histórico".
- Depois de um `/eng-scan` grande, pra garantir que os achados **viraram** itens fechados.

> Regra de bolso: **checklist criado é dívida até ser sanado.** O overdev garante que a
> sessão não para com item aberto; a auditoria garante que **nenhum item aberto ficou órfão
> no histórico** — e que "feito" quer dizer feito, com prova.
