---
description: schematize-engineering — modo desenvolvimento contínuo: força um checklist exaustivo e NÃO deixa parar/falar com o usuário até o checklist estar 100% verificado (Stop hook que rejeita parada prematura). Anti "entreguei uma micro-função e disse que terminei".
argument-hint: "<objetivo> | resume | status | stop"
---

Modo **OVERDEV** (`references/overdev.md`): trabalho contínuo até o checklist fechar de
verdade. Usa o Stop hook `overdev-stop.sh`, que **rejeita a parada** enquanto houver item
aberto — o agente só fala com o usuário quando **tudo** estiver `- [x]` e o gate passar.

## Modo `<objetivo>` (iniciar)
1. **Gere o CHECKLIST exaustivo** do objetivo — **plan-first**. Um item por linha
   (`- [ ]`), pequeno e **verificável** (cada um com como provar: teste, comando, gate). Se
   o usuário já tem checklist, **incorpore inteiro, sem resumir**. Cubra: implementação,
   testes, edge cases, erro/loading/vazio, doc-comment + índice/MAPA (§39), DoD (§35),
   archive (§28), e o que o objetivo pedir. Um checklist magro é a causa do "terminei"
   precoce — seja exaustivo por contagem, não por resumo.
2. **Grave o estado** (control-plane em `.overdev/`, no root — gitignore):
   - `.overdev/CHECKLIST.md` — o checklist (o hook lê os `- [ ]`).
   - `.overdev/state` — `mode=active`, `max_iters=200` (ajuste se pedirem), `archive=<projeto>_archive/overdev`.
   - `.overdev/gate.sh` — verificação de máquina (chame `/eng-review` + testes + lint do projeto). `exit!=0` = não terminou, mesmo com caixas marcadas.
   - Espelhe o checklist em `<projeto>_archive/overdev/OBJETIVO.md` (registro durável §28).
   - Garanta que `.overdev/` está no `.gitignore`.
3. **Confirme o hook ativo:** se `Stop`→`overdev-stop.sh` não estiver no `settings.json`,
   avise o usuário e mostre o trecho de `assets/settings.claude.example.json` pra ligar
   (registrar é seguro: inerte sem overdev ativo). 
4. **Entre no laço** (`references/overdev.md` §2): próximo `- [ ]` → implementa → **verifica
   (roda o gate)** → marca `- [x]` → repete. ≥3 unidades independentes → **fan-out**
   (`/eng-orchestrate`). **Não pare, não anuncie "pronto", não entregue micro-função como
   se fosse o todo.**

## Como TERMINAR (as únicas saídas legítimas)
- **Concluído:** todos `- [x]` **e** `.overdev/gate.sh` passa → crie `.overdev/DONE`, ponha
  `mode=done` no state, e só então reporte ao usuário o resultado + evidência.
- **Bloqueio real:** segredo/credencial faltando, decisão irreversível/destrutiva,
  dependência externa, ambiguidade que muda o resultado → crie `.overdev/BLOCKED` com o
  motivo + a pergunta objetiva, e pare pra perguntar. (Não use isso pra fugir de trabalho.)
- **Budget/thrashing:** estourou `max_iters` ou vários ciclos sem progresso → `.overdev/BLOCKED`
  com post-mortem do que falta. Guardrail, não desistência.

## `resume`
Releia `.overdev/CHECKLIST.md` + `OBJETIVO.md`, retome do primeiro `- [ ]`. (Use após
crash/compactação; ideal com heartbeat `/loop` ou cron re-chamando `resume`.)

## `status`
Mostre a tabela do checklist (feitos/abertos), `iterations`, `max_iters`, últimas linhas de
`premature-stops.log`. Não altera nada.

## `stop`
Parada manual do usuário: ponha `mode=stopped` no `.overdev/state` (o hook volta a inerte).
Use só quando VOCÊ (usuário) mandar — o agente não se auto-libera por aqui.

> Regra de ouro: no overdev, o **checklist é o juiz**. O agente não decide que terminou —
> o gate decide. Marcar item sem prova é a mesma macaquice do "terminei" precoce (§6).
