# OVERDEV — desenvolvimento contínuo até o checklist fechar (à prova de parada prematura)

Modo de trabalho **opt-in** (comando `/eng-overdev`) para quando o agente **para cedo
demais** — entrega uma micro-função e diz "tá tudo pronto" com o checklist cheio de item
aberto. O overdev **força um checklist exaustivo e só deixa o agente falar com o usuário
quando o checklist estiver EFETIVAMENTE 100%** (verificado, não auto-declarado).

Roda **só quando você chama** `/eng-overdev`. O hook é **inerte** sem um overdev ativo.

## 1. O contrato: checklist é o "terminou"
- Nada de "acho que tá bom". O único critério de fim é **todos os itens do checklist
  fechados (`- [x]`) e o gate de verificação passando**.
- **Plan-first:** o objetivo vira um **checklist exaustivo de itens verificáveis** — um
  por linha, cada um pequeno e com um jeito de provar (comando/teste/observação). Se o
  usuário já tem um checklist, ele é **incorporado inteiro** (nunca resumido/aparado).
- Grava em **`.overdev/CHECKLIST.md`** (control-plane que o hook lê) e espelha em
  **`<projeto>_archive/overdev/OBJETIVO.md`** (registro humano durável — §28).

## 2. O laço (sem parar)
Enquanto houver item aberto: pega o **próximo `- [ ]`** → implementa **de verdade** →
**verifica** (roda o teste/gate do item) → só então marca `- [x]` → repete. Do critério
mais barato ao mais caro. Unidades independentes (≥3) vão pra **fan-out de subagents**
(`references/orquestracao.md`) — paralelismo acelera, não autoriza fechar item sem prova.

## 3. Continuidade à prova de parada (o mecanismo)
- **Stop hook `overdev-stop.sh`** (o núcleo): quando o agente tenta encerrar o turno, o
  hook conta os `- [ ]` abertos e roda o `.overdev/gate.sh` (se houver). Sobrou item ou o
  gate falhou → **rejeita a parada** e devolve ao agente a lista do que falta. É o que
  impede o "terminei" precoce: encerrar o turno = falar com o usuário, e o hook **bloqueia
  isso** até o checklist fechar.
- **Registro da parada prematura (a "punição"):** toda tentativa de parar com item aberto
  é anexada a `<archive>/overdev/premature-stops.log` (timestamp, ciclo, itens que
  faltavam) e o agente é forçado a continuar.
- **Backstop opcional de crash:** um heartbeat (`/loop` ou cron) que re-invoca
  `/eng-overdev resume` sobrevive a travada/compactação — o Stop hook cobre a sessão viva;
  o cron cobre o "a Anthropic travou". Opcional, ligado a pedido.

## 4. Paradas LEGÍTIMAS (não é fraqueza — é o certo)
O overdev pune parada **preguiçosa**, não parada **correta**. Só são permitidas:
- **Concluído:** todos os itens `- [x]` **e** o gate passa → cria `.overdev/DONE`, reporta.
- **Bloqueio real que exige o usuário:** segredo/credencial faltando, decisão irreversível/
  destrutiva, dependência externa indisponível, ambiguidade que muda o resultado → cria
  `.overdev/BLOCKED` com o **motivo e a pergunta objetiva**, então para pra perguntar.
- **Teto de budget** (`max_iters`, default 200, configurável): guardrail anti-loop-infinito
  → para e reporta progresso + o que falta. Não é "desistir cedo", é não girar pra sempre.
- **Sem progresso mensurável (thrashing)** por vários ciclos → post-mortem curto, cria
  `.overdev/BLOCKED` explicando, muda de abordagem ou pede ajuda em vez de girar.

## 5. Guardrails inegociáveis (o overdev NÃO burla os pisos)
- "Sem parar" ≠ "sem verificar": **cada item fecha só com prova** (teste/gate), nunca por
  marcar `[x]` na fé. Marcar item não-verificado é a mesma macaquice do "terminei" precoce.
- Segurança, testes, archive e DoD **continuam valendo** — velocidade não desliga piso.
- O gate do projeto (`/eng-review`, testes, lint) entra no `.overdev/gate.sh` sempre que dá.

## 6. Estado (control-plane) e limpeza
`.overdev/` no root do projeto (trate como `.git` — **gitignore**): `state`, `CHECKLIST.md`,
`iterations`, `gate.sh`, e as sentinelas `DONE`/`BLOCKED`. Ao concluir (ou `/eng-overdev
stop`), o `mode` sai de `active` → o hook volta a ser inerte. O registro humano
(`OBJETIVO.md`, logs) fica no archive.

## 7. Ativação (uma vez, seguro)
O hook só age se registrado como `Stop` no `settings.json` (ver
`assets/settings.claude.example.json`) **e** se houver `.overdev/state` ativo. Registrar é
seguro: sem overdev ativo ele sai em microssegundos. Ligar/desligar um run é só
`/eng-overdev <objetivo>` e `/eng-overdev stop`.
