# Changelog — schematize-engineering

Formato: [Keep a Changelog]; versionamento: SemVer.

## [0.11.0] — 2026-08-15
Lições de um incidente real de auth/onboarding — **alcançabilidade de estado** e **guarda provada no vermelho**.

### Adicionado
- **Alcançabilidade / anti-deadlock de bootstrap** (`references/iam.md` §4 + checklist; anti-padrão #47 em `references/anti-padroes.md`): toda exigência obrigatória (enrolar 2º fator, verificar) tem que ter **rampa self-service alcançável a partir do estado zero** — o fallback always-on (Email OTP) dá a sessão de baixo AAL para enrolar o fator forte; a saída **nunca** exige o que falta (link para página que pede sessão a quem não tem) nem terceiriza o que é do dono (admin enrolar o autenticador alheio); **prova por estado** (nenhum estado de conta sem transição de saída). Origem: N contas presas sem TOTP porque a única porta pedia o que elas não tinham.
- **Guarda provada no vermelho + test discovery** (`references/testes.md` §22; anti-padrão #20a): todo teste/guarda tem que ser **visto FALHAR** quando o invariante quebra (red-first) — verde que nunca reprovou o caso ruim (a asserção casa com o vizinho/array/regex errado) não guarda; o runner tem que **COLETAR** o teste (globs de `include` cobrem `.test.tsx`/`_test.go`), suíte que rodou 0 testes novos é falso-verde.

## [0.10.0] — 2026-07-11
Overdev pelo CLI `schematize` (Rust) — parkear pergunta em vez de travar; on-hold; veto a AskUserQuestion.

### Alterado
- **Motor do overdev agora é o binário `schematize` (Rust, repo `schematizeme/schematize-cli`)**, não mais o `.sh` (que fica só como fallback Stop-only). `schematize overdev enable` registra **dois** hooks: **Stop** (`overdev check` — não para até o checklist fechar; item on-hold não bloqueia) e **PreToolUse** matcher `AskUserQuestion` (`overdev guard` — **veta o pool bloqueante de perguntas**).
- **Regra central nova:** em overdev, **VETADO parar pra perguntar**. Topou dúvida → **parkeia** (`schematize overdev park "<item>" "<pergunta>"`: registra em `./PERGUNTAS-OVERDEV.txt` na base do projeto **e** marca o item como `- [~]` on-hold) e **segue**. On-hold não bloqueia o fim do run; as perguntas ficam pro usuário ler quando voltar. Preferir default razoável documentado a perguntar.
- **Terceiro estado de checklist `- [~]` (on-hold)** além de `- [ ]`/`- [x]`. Corrige a causa do bug reportado ("na instalação não constava os .sh / overdev não funcionava"): o `install.sh` copiava o hook mas não o ativava no settings — agora `schematize overdev enable` faz o wiring de forma robusta.
- `references/overdev.md` §4/§6/§7 e `/eng-overdev` reescritos pro modelo CLI + parkear.

## [0.9.1] — 2026-07-11
Fix no hook do OVERDEV.

### Corrigido
- `assets/hooks/overdev-stop.sh`: contagem de itens abertos quebrava quando o checklist estava 100% fechado (`grep -c` imprime 0 e sai 1 → `|| echo 0` gerava `"0\n0"` e erro de sintaxe, impedindo a parada legítima). Agora conta certo e libera a parada com o checklist completo (e ainda bloqueia se o `gate.sh` falhar). Coberto por smoke-test dos 4 cenários (inerte / item aberto / tudo fechado / gate falho).

## [0.9.0] — 2026-07-11
Modo OVERDEV — desenvolvimento contínuo até o checklist fechar (anti-parada-prematura).

### Adicionado
- **`references/overdev.md` + comando `/eng-overdev` + hook `assets/hooks/overdev-stop.sh`:** modo opt-in que resolve o agente que **para cedo demais** ("entreguei uma micro-função e disse que terminei"). Força um **checklist exaustivo e verificável** (`.overdev/CHECKLIST.md`, espelhado em `<projeto>_archive/overdev/OBJETIVO.md`) e um **Stop hook que REJEITA a parada** enquanto houver `- [ ]` aberto ou o `.overdev/gate.sh` falhar — o agente só fala com o usuário quando tudo está `- [x]` e verificado. Tentativa de parar prematura é registrada em `premature-stops.log` (a "punição") e o agente é forçado a continuar. **Paradas legítimas:** concluído (cria `.overdev/DONE`), bloqueio real que exige o usuário (`.overdev/BLOCKED` com motivo+pergunta), teto de budget (`max_iters`, default 200, guardrail anti-loop) ou thrashing. **Opt-in e inerte** fora de um run (o hook sai em microssegundos sem `.overdev/state` ativo); ativação por registro `Stop` no `settings.json` (`assets/settings.claude.example.json` atualizado). Não burla pisos: item só fecha com prova. Escopo: schematize-engineering.
- `SKILL.md` (comando + reference), `/eng-help`, `/eng-load` atualizados.

## [0.8.0] — 2026-07-11
IAM por desenho — identidade + autorização robustas, auth como app separada.

### Adicionado
- **`references/iam.md`** — piso de IAM da casa: **auth é app SEPARADA** (`auth.<domain>`, serviço + front próprios, isolados; nunca monolith; apps delegam por OIDC/OAuth2.1 + PKCE). **ID interno imutável — email/telefone nunca é ID** (N emails por usuário, incentivado; SSO com recuperação local forçada; nudge de email secundário com detecção de provedor + tooltip). **≥2 fatores sempre** (AAL/NIST 800-63B): **passkey/WebAuthn no núcleo**, TOTP/push, **email OTP Resend always-on inclusive HML**, **Twilio** p/ telefone (providers plugáveis); senha por padrão (argon2id+HIBP) mas opcional no seletor; invariante de troca "fator Y≠X no maior AAL"; **recuperação ≥ força do login**. **Multi-tenant RBAC/ABAC granular via ReBAC** (OpenFGA/SpiceDB): deny-default, PDP/PEP, enforcement server-side, token fino, decisão auditada. **Multi-dispositivo** + view de remover; **sessão 7d/90d** (fim do "15 min e é chutado"); **logout irreversível**. **Migração de auth legado = prioridade 0** (strangler-fig). Rotina agressiva de testes cross-tenant/priv-esc (schematize-pentest).
- **Comando `/eng-iam`** (plan-first): força/audita/scaffolda o IAM num projeto (bootstrap) ou porta um auth legado (migrate).
- **Piso 17** no `CLAUDE.md`; bullet + linha na tabela de references do `SKILL.md`; anti-padrões **43–46** (auth monolith; email como ID / 1 fator; authz hand-rolled/no cliente; logout que só apaga cookie); `/eng-load` carrega `iam.md`; `/eng-help` lista `/eng-iam`.

## [0.7.0] — 2026-07-11
Limite de arquivo em camadas — teto de 750 (≤500 úteis + ~250 comentário) + flag em >300 úteis.

### Alterado
- **`references/padroes-codigo.md` §1/§2:** o limite rígido de **300 linhas/arquivo** vira regra **em camadas**. **Teto DURO: 750 linhas** (das quais **~250 reservadas a comentário/doc** e **até ~500 de código útil**) — acima bloqueia. **FLAG (não bloqueia, mas SEMPRE sinaliza) em > 300 linhas de código útil:** indício de que a função está **muito extensa** / **precisa de mais abstração** — registra como dívida e **revê quando as prioridades forem resolvidas**. **Observabilidade tem folga natural (~400 úteis).** Função com >300 úteis dispara o mesmo flag; "uma função por arquivo" mantida.
- **`scripts/check-diff.sh`:** o gate de tamanho passa a contar **código útil** (exclui comentário/branco): `total > 750` **bloqueia**, `útil > 500` **bloqueia**, `útil > 300` (ou `> 400` em arquivo de observabilidade) **flagueia** (`warn`, não trava).
- Propagado no piso do `CLAUDE.md`, `SKILL.md`, `references/entrega.md` (DoD), `references/arquitetura.md` (§6) e comandos `/eng-load` `/eng-help` `/eng-review`.

## [0.6.0] — 2026-07-06
Deploy destrutivo por seed + isolamento por usuário (control plane `<projeto>_ops`).

### Adicionado
- **`references/ops.md` §2 — layout, seed e redeploy destrutivo:** o ops provisiona em **`/<app>/`** clonando os repos dentro (`/<app>/<app>_<ctx>`); **`/<app>/.env` é o seeder global** (fonte única de config). **Todo redeploy é destrutivo na aplicação** — apaga a anterior e recria um clone zerado só com o seed (idempotente, sem drift). **"Destrutivo" é a app, nunca os dados:** banco/volumes preservados (migration reversível); `ops reset` de dados gated a dev/hml, nunca prd.
- **`references/ops.md` §3 — isolamento por usuário:** um **user Linux dedicado + systemd unit hardened por serviço** (`NoNewPrivileges`/`ProtectSystem`/`PrivateTmp`/…); blast radius mínimo (comprometer um serviço não alcança os outros nem o host). Tudo automatizado pelo ops.
- Piso **16** no `CLAUDE.md`; bullet no SKILL.md; anti-padrões **39–42** (patch in-place/redeploy fora do seed; config fora do seed/repos fora de `/<app>/`; apagar dados no destrutivo; serviços sem isolamento de user). `/eng-ops` audita layout/seed/isolamento.

### Corrigido
- `ops.md` §7: referência de comando normalizada para `/<slug>-ops` (era `/eng-ops` fixo, que ficava incorreto nas cópias das skills de linguagem).

## [0.5.0] — 2026-07-05
Control plane `<projeto>_ops`: fluxo de ambientes, ops como interface única, instalação paralela, independência invariante.

### Adicionado
- **`references/ops.md`**: (1) **fluxo de promoção fixo** `dev local → teste local → GitHub → hml → prd`, **nada direto no servidor** — editar código em hml/prd é VETADO (servidor imutável por edição manual; drift detection, filesystem read-only, break-glass auditado); (2) **ops é a interface única** — 100% de install/update/correção/config passa por comando do `<projeto>_ops`, que é autônomo/idempotente/completo (usuário provisiona o servidor do zero sem a IA); (3) **instalação sempre paralela** = `nproc`; (4) **independência é invariante** — falha no paralelo = serviços não independentes → corrigir é prioridade máxima; ops expõe a colisão, nunca serializa pra mascarar.
- **Comando `/eng-ops`** (plan-first): audita/scaffolda o ops, verifica fluxo de ambientes, paralelização e independência.
- Pisos **14 e 15** no `CLAUDE.md` sempre-on; pisos no SKILL.md; anti-padrões **35–38** (editar no servidor, pular pra hml/prd, operar fora do ops, instalar serial, serializar pra mascarar dependência); `operacao.md` §21 estendido; `/eng-load` carrega `ops.md`.

## [0.4.0] — 2026-07-05
Índice único de comandos entre skills.

### Adicionado
- **Comando `/schematize-help`**: o "help dos helps" — varre os comandos instalados (projeto + global) de **todas** as skills da casa (go/rust/web/node/eng/pentest), lê a `description:` de cada um e apresenta um índice agrupado por skill, com legenda do catálogo e como instalar skills faltantes. `/eng-help` passa a apontar pra ele.

## [0.3.0] — 2026-07-05
Permanência (MD como backup à prova de crash) e **todo MD gerado no archive, root limpo**.

### Adicionado
- **§28.0 (`references/operacao.md`): layout canônico do archive** — todo `.md` gerado (MAPA, índices, planos, relatórios, handoffs, checkpoints) mora em `<projeto>_archive/<área>/`, **NUNCA no root**. Subpastas: `index/`, `context/`, `orchestration/`, `pentest/`, `chat/`, `task/`. Root fica limpo (só código, config e MDs de projeto à mão).
- **Permanência da orquestração (`references/orquestracao.md` §7):** o MD de checkpoint é gravado **antes** de disparar a onda 1, com tabela de status por unidade; cada subagent grava o próprio resultado no archive; retomada por leitura do checkpoint (não recomeça do zero). Comando `/eng-orchestrate` atualizado.

### Corrigido
- **MAPA/índice saíam no root.** Agora `MAPA.md`, `INDEX_GLOBAL.md`, `INDEX_FUNCTIONS.md` vão para **`<projeto>_archive/index/`** (`padroes-codigo.md` §4, `assets/MAPA.md`, `/eng-index`, `build-index.mjs` (uso), `CLAUDE.md`, `SKILL.md`).

## [0.2.0] — 2026-07-04
Orquestração & paralelização como piso — **tempo do usuário acima de tokens**.

### Adicionado
- **`references/orquestracao.md`**: quando a tarefa se divide em ≥3 unidades independentes, decompor em mini-tasks e **paralelizar com subagents** em vez de serial; fan-out de **8 por onda** (teto global **25**); regra fan-out-vs-inline; independência (sem alvo de escrita compartilhado, sem ordem obrigatória); brief autossuficiente (agent começa frio); isolamento de escrita (worktree/partição); gather + verificação única pelo orquestrador; onde **não** paralelizar; plan-first.
- **Comando `/eng-orchestrate`**: planeja a decomposição/fan-out, fixa o contrato, mostra o plano e pede aprovação antes de disparar as ondas.
- Piso 13 no `CLAUDE.md` sempre-on e piso correspondente no SKILL.md; `/eng-load` e `/eng-help` atualizados.

## [0.1.0] — 2026-07-03
Primeira release — a **base comum de engenharia** da casa, agnóstica de linguagem, extraída do corpo normativo compartilhado entre `schematize-go`/`rust`/`web`/`node`.

### Adicionado
- Corpo normativo language-agnostic: arquitetura/DDD, estrutura de repositórios + `<projeto>_ops` + contenção no workspace, **padrões de código** (≤300 linhas, doc-comment com fluxo de dado, **MAPA+grafo+índice exaustivo por contagem**), segurança (segredo server-side, SQL parametrizado, authz), dados/eventos + independência de runtime, cadeia de suprimentos, observabilidade (LGTM+), operação/entrega/DoD/**archive** e anti-padrões (§37).
- Comandos `/eng-help`, `/eng-load`, `/eng-claude`, `/eng-index`, `/eng-review`, `/eng-qa`, `/eng-cc`, `/eng-handoff`; `CLAUDE.md` sempre-on.
- Referência ao **mapa de endpoints** (`schematize-pentest`) na superfície de entrada do índice.

> As skills de linguagem (`schematize-go`/`rust`/`web`/`node`) especializam esta base; use esta quando o projeto não é de uma linguagem específica.
