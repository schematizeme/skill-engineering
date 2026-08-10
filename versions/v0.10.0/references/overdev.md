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

## 4. NÃO trave pra perguntar — parkeia e segue (regra central)
A ideia do overdev é **por pra rodar e sair** (comer/dormir/viver). Então, **VETADO parar
pra perguntar com pool bloqueante (`AskUserQuestion`) enquanto em overdev** — o hook
`PreToolUse` (`schematize overdev guard`) **bloqueia** essa chamada. Muita pergunta que
parece "inegociável" pra IA é **inútil** pro humano e só trava o desenvolvimento.

Ao topar uma dúvida (mesmo que pareça bloqueante):
1. **Escreva a pergunta em `./PERGUNTAS-OVERDEV.txt`** (na **base do projeto**) — o usuário
   responde quando voltar.
2. **Marque aquele item como `- [~]` (on-hold)** — `schematize overdev park "<item>"
   "<pergunta>"` faz os dois (registra + marca).
3. **SIGA para os outros itens.** On-hold **não** bloqueia o fim do run.

Assuma um **default razoável e documente-o** em vez de perguntar, sempre que o custo de
errar for reversível. Só parkeia o que for de fato irreversível/ambíguo demais.

## 4.1. Paradas LEGÍTIMAS
- **Concluído:** nenhum `- [ ]` aberto (tudo `- [x]` ou `- [~]`) **e** o gate passa → o
  agente pode encerrar e reportar (o que ficou on-hold + as perguntas do txt).
- **Teto de budget** (`--max`, default 200): guardrail anti-loop → encerra e reporta o que
  falta. Não é "desistir cedo", é não girar pra sempre.
- **Sem progresso mensurável (thrashing)** por vários ciclos → post-mortem curto, parkeia os
  itens travados e encerra. Nunca gira à toa.

> O que **não** é parada legítima: dizer "terminei" com item `- [ ]` aberto, ou abrir um
> pool de pergunta. O primeiro o Stop hook rejeita; o segundo o guard veta.

## 5. Guardrails inegociáveis (o overdev NÃO burla os pisos)
- "Sem parar" ≠ "sem verificar": **cada item fecha só com prova** (teste/gate), nunca por
  marcar `[x]` na fé. Marcar item não-verificado é a mesma macaquice do "terminei" precoce.
- Segurança, testes, archive e DoD **continuam valendo** — velocidade não desliga piso.
- O gate do projeto (`/eng-review`, testes, lint) entra no `.overdev/gate.sh` sempre que dá.

## 6. Estados do checklist e control-plane
- **Itens:** `- [ ]` aberto (tem que fazer) · `- [x]` feito (verificado) · `- [~]` on-hold
  (pergunta parkeada, **não bloqueia** o fim do run).
- `.overdev/` no root do projeto (trate como `.git` — **gitignore**): `state.json`,
  `CHECKLIST.md`, `iterations`, `gate.sh`. `./PERGUNTAS-OVERDEV.txt` fica na **base** do
  projeto (é pro usuário ler). Ao encerrar (`schematize overdev stop`), `mode` sai de
  `active` → hooks voltam a ser inertes.

## 7. Motor: o CLI `schematize` (Rust) — não mais `.sh`
O overdev roda pelo binário **`schematize`** (repo `schematizeme/schematize-cli`), que
instala/versiona as skills **e** hospeda o motor:
- `schematize overdev enable` — registra **dois** hooks no `settings.json`: **Stop**
  (`overdev check` — não para até fechar; on-hold não conta) e **PreToolUse** matcher
  `AskUserQuestion` (`overdev guard` — veta o pool de pergunta). Uma vez; **inerte** sem run.
- `schematize overdev start "<objetivo>"` · `status` · `park "<item>" "<pergunta>"` ·
  `hold "<item>"` · `stop`.
- Instalar o CLI: `curl -fsSL .../schematize-cli/releases/latest/download/install.sh | bash`;
  depois `schematize install --all`.

> O hook shell legado (`assets/hooks/overdev-stop.sh`) fica só como **fallback Stop-only**
> onde o binário não está instalado — ele não veta `AskUserQuestion` (só o CLI faz os dois).
> O comando `/eng-overdev` prioriza o binário.
