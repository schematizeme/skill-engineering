# OVERDEV — desenvolvimento contínuo até o checklist fechar (à prova de parada prematura)

Modo de trabalho **opt-in** (comando `/eng-overdev`) para quando o agente **para cedo
demais** — entrega uma micro-função e diz "tá tudo pronto" com o checklist cheio de item
aberto. O overdev **força um checklist exaustivo e só deixa o agente falar com o usuário
quando o checklist estiver EFETIVAMENTE 100%** (verificado, não auto-declarado).

Roda **só quando você chama** `/eng-overdev`. O hook é **inerte** sem um overdev ativo.

## 0. Fase 0 — Fundação (ANTES do laço): decisões → grafo → plano pesado

**Antes de tickar qualquer item**, o overdev **funda o trabalho**. Pular isto é a causa nº 1
de plano raso, retrabalho e "reabrir o que já foi combinado". A Fase 0 é **obrigatória** e é
a **primeira coisa** que o run faz — o laço (§2) só começa quando ela fecha (§0.4).

**0.1 Colher o que já foi debatido e ACORDADO no contexto atual.** Varra a conversa/sessão
inteira e extraia as **decisões acordadas** (as fechadas, não as abandonadas): o que foi
combinado, por quê, qual alternativa foi descartada, restrições e defaults aceitos. Grava em
**`.schematize/overdev/DECISOES.md`** (+ espelho no `<projeto>/_archive/overdev/`) em formato **ADR-lite**:
`Decisão · Motivo · Alternativa descartada · Origem (onde no contexto)`. Vira **input do plano**
e **trava o que já foi fechado** (não se re-debate). O que ficou **em aberto/ambíguo** → não
inventa: vira candidato a `- [~]` on-hold (parkeia, §4), não segura a fundação.

**0.2 Carregar o GRAFO do index (se existir).** Rode/leia `/eng-index` (§39): o **MAPA** e os
grafos de serviço/chamadas em `<projeto>/_archive/index/` (`INDEX_GLOBAL.md`, `INDEX_FUNCTIONS.md`,
`MAPA.md` — adjacência `A -> B`). O plano se **ancora no grafo real**: cada item aponta o(s)
**nó(s)** que toca (função/serviço/`arquivo:linha`) e as **arestas** afetadas (quem chama / é
chamado). Sem index ainda? **gerá-lo é o 1º item do checklist**; ou registre a ausência e
planeje pela enumeração de rotas/funções. O grafo é o que liga o plano ao código de verdade —
**e é o que o painel/tela de grafos consome** (§8).

**0.3 Planejamento PESADO (plan-first de verdade, não uma lista rasa).** Só depois de 0.1+0.2,
produza o **PLANO** em **`.schematize/overdev/PLAN.md`** (+ archive):
- **Objetivo e escopo** (o que entra / o que **NÃO** entra), ancorado nas decisões (0.1).
- **Decomposição** em fases e itens **verificáveis**, cada item com: nó(s) do grafo que toca,
  **prova** (teste/comando/gate), **dependências** (o que vem antes), risco/reversibilidade.
- **Ordem** (topológica pelas dependências) e **paralelismo**: ≥3 unidades independentes →
  fan-out (`/eng-orchestrate`).
- **Mapa decisão→item** (rastreável: cada decisão de 0.1 vira ≥1 item; cada item aponta a
  decisão que o justifica) e **cobertura do grafo** (nós tocados vs nós que deveriam ser).
- **Riscos** e **pontos de parada legítima** (§4.1); o que é irreversível.
- **Definition of Done** do objetivo (§35) + **archive** (§28).
O PLANO **gera o CHECKLIST** (§1): o checklist é a **projeção executável do plano**, exaustivo
por contagem — não uma lista solta.

**0.4 Gate da Fase 0.** Só entra no laço (§2) quando: `DECISOES.md` colhido, **grafo carregado**
(ou ausência registrada + item de gerá-lo), **`PLAN.md` pesado** escrito, e `CHECKLIST.md`
**derivado do plano**. Começar a tickar sem a fundação é a macaquice que a Fase 0 existe para
matar — "planejamento pesado antes de começar".

## 1. O contrato: checklist é o "terminou"
- Nada de "acho que tá bom". O único critério de fim é **todos os itens do checklist
  fechados (`- [x]`) e o gate de verificação passando**.
- **Plan-first:** o objetivo vira um **checklist exaustivo de itens verificáveis** — um
  por linha, cada um pequeno e com um jeito de provar (comando/teste/observação). Se o
  usuário já tem um checklist, ele é **incorporado inteiro** (nunca resumido/aparado).
- Grava em **`.schematize/overdev/CHECKLIST.md`** (control-plane que o hook lê) e espelha em
  **`<projeto>/_archive/overdev/OBJETIVO.md`** (registro humano durável — §28).

## 2. O laço (sem parar) — começa DEPOIS da Fase 0
Fechada a fundação (§0), tickeia **item a item**. Enquanto houver item aberto: pega o
**próximo `- [ ]`** → implementa **de verdade** →
**verifica** (roda o teste/gate do item) → só então marca `- [x]` → repete. Do critério
mais barato ao mais caro. Unidades independentes (≥3) vão pra **fan-out de subagents**
(`references/orquestracao.md`) — paralelismo acelera, não autoriza fechar item sem prova.

## 3. Continuidade à prova de parada (o mecanismo)
- **Stop hook `overdev-stop.sh`** (o núcleo): quando o agente tenta encerrar o turno, o
  hook conta os `- [ ]` abertos e roda o `.schematize/overdev/gate.sh` (se houver). Sobrou item ou o
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
- O gate do projeto (`/eng-review`, testes, lint) entra no `.schematize/overdev/gate.sh` sempre que dá.

## 6. Estados do checklist e control-plane
- **Itens:** `- [ ]` aberto (tem que fazer) · `- [x]` feito (verificado) · `- [~]` on-hold
  (pergunta parkeada, **não bloqueia** o fim do run).
- **Layout operacional** `.schematize/overdev/` no root do projeto (trate como `.git` —
  **gitignore**): `state.json`, `CHECKLIST.md`, `iterations`, `gate.sh`. O marcador canônico
  do projeto é a pasta **`.schematize/`** (contém `overdev/` e `grafos/`, §39); o antigo
  **`.overdev/` fica como LEGADO** — o motor Rust lê ambos e **auto-migra** para
  `.schematize/overdev/` no `overdev start`. `./PERGUNTAS-OVERDEV.txt` fica na **base** do
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

## 8. Contexto da aplicação + painel auxiliar e tela de grafos (fora do CLI/VSCode)
O `schematize` **guarda o contexto da aplicação** e o expõe num **painel auxiliar fora do
CLI/VSCode** — para o humano acompanhar o run enquanto o agente trabalha:
- **Fonte de dados (o control-plane da Fase 0):** `.schematize/overdev/DECISOES.md`,
  `.schematize/overdev/PLAN.md`, `.schematize/overdev/CHECKLIST.md`, `./PERGUNTAS-OVERDEV.txt`
  e o **grafo vivo** (`.schematize/grafos/`, §39). O painel **lê** esses arquivos — não é
  fonte da verdade, é vista.
- **Painel HTML no browser** (`schematize panel` — em construção): decisões, plano, progresso do
  checklist (feitos/abertos/on-hold), perguntas parkeadas e a **tela de grafos** interativa
  (force-directed **estilo Obsidian**), com cada nó **linkado ao `arquivo:linha`** do index.
- **Integração Obsidian** (`schematize graph obsidian` — em construção): exporta o index como
  **vault Obsidian** (markdown + `[[wikilinks]]`), navegável no graph view do Obsidian.
- **Regra:** o painel é **auxiliar e read-mostly** — o juiz do "terminou" continua sendo o
  checklist + gate (§6), não a tela. A tela ajuda a **ver**; o hook é quem **decide**.

> Fluxo completo do overdev: **Fase 0** (decisões → grafo → plano pesado → checklist) → **laço**
> (tick item a item, com prova) → **fim legítimo** (checklist fechado + gate), tudo visível no
> painel e ancorado no grafo do index.
