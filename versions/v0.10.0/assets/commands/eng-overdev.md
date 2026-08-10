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
2. **Ative o run** com o CLI (motor Rust — ver `references/overdev.md` §7):
   - `schematize overdev start "<objetivo>" [--max N]` — cria `.overdev/` (`state.json`
     `mode=active`, `iterations`), um `CHECKLIST.md` template e o `.gitignore`.
   - Escreva o **CHECKLIST exaustivo** do passo 1 em `.overdev/CHECKLIST.md`; espelhe em
     `<projeto>_archive/overdev/OBJETIVO.md` (registro durável §28).
   - Crie `.overdev/gate.sh` — verificação de máquina (`/eng-review` + testes + lint).
     `exit!=0` = não terminou, mesmo com caixas marcadas.
   - Sem o binário instalado? use o fallback `assets/hooks/overdev-stop.sh` (Stop-only) e a
     `assets/settings.claude.example.json` — mas o binário é o recomendado (faz o veto de
     pergunta também). Instale: `schematize install`/bootstrap do `schematize-cli`.
3. **Confirme os hooks:** `schematize overdev enable` registra Stop + PreToolUse no
   `settings.json` (uma vez; inerte sem run). `schematize overdev status` mostra o estado.
4. **Entre no laço** (`references/overdev.md` §2): próximo `- [ ]` → implementa → **verifica
   (roda o gate)** → marca `- [x]` → repete. ≥3 unidades independentes → **fan-out**
   (`/eng-orchestrate`). **Não pare, não anuncie "pronto", não entregue micro-função como
   se fosse o todo.**

## NÃO trave pra perguntar (regra central)
**VETADO usar `AskUserQuestion` (pool bloqueante) em overdev** — o hook `guard` bloqueia.
Topou dúvida? **parkeia e segue**: `schematize overdev park "<item>" "<pergunta>"` (registra
em `./PERGUNTAS-OVERDEV.txt` na base do projeto **e** marca o item como `- [~]` on-hold), e
continua os outros. Prefira **assumir um default razoável e documentá-lo** a perguntar,
quando o erro for reversível.

## Como TERMINAR (as únicas saídas legítimas)
- **Concluído:** nenhum `- [ ]` aberto (tudo `- [x]` ou `- [~]`) **e** `.overdev/gate.sh`
  passa → `schematize overdev stop` e reporte ao usuário: resultado + evidência + **itens
  on-hold e as perguntas de `PERGUNTAS-OVERDEV.txt`**.
- **Budget/thrashing:** estourou `--max` ou vários ciclos sem progresso → parkeia os itens
  travados, `schematize overdev stop`, post-mortem do que falta. Guardrail, não desistência.

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
