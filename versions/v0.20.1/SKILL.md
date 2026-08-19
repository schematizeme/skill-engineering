---
name: schematize-engineering
metadata:
  version: 0.20.1
description: Padrões normativos de engenharia da casa — a BASE comum, agnóstica de linguagem, que se repete em toda a stack. Backend em ROL SANCIONADO escolhido por fit + ADR (Go, Rust, Elixir, C#, Zig, Ruby — cada uma com skill irmã; Node-backend/PHP em saída); o piso (segurança, testes, IAM, ops, archive, DoD) é o mesmo em toda linguagem (arquitetura/DDD, MAPA+grafo+endpoints, segurança, dados/eventos, cadeia de suprimentos, observabilidade, operação/DoD/archive, orquestração/paralelização com subagents, anti-padrões, gestão de contexto) E as disciplinas de fluxo (scan de problemas, planejamento extensivo, refactor disciplinado, auditoria de histórico, overdev contínuo). Use SEMPRE que for projetar, gerar, revisar ou refatorar qualquer software, decidir arquitetura, escolher stack, modelar eventos/banco, configurar observabilidade, planejar execução paralela/multiagente, VARRER a base atrás de problemas, PLANEJAR pesado antes de construir, REFATORAR sem quebrar comportamento, AUDITAR se os checklists criados foram sanados, ou produzir ADR/runbook/archive — mesmo sem citar "padrão". Contém pisos inegociáveis (segredo nunca no cliente, sem SQL concatenado, auth server-side, índice/MAPA exaustivo, archive obrigatório, tempo do usuário acima de tokens, refactor preserva comportamento com rede de testes, UX de massa — prever o usuário leigo, software que se adapta e nunca culpa o usuário) que vetam atalhos inseguros e execução serial ineficiente. Detalhe por linguagem nas skills irmãs: schematize-go/rust (backend), schematize-web (frontend), schematize-node (legado). Pentest é a schematize-pentest.
---

# Padrões de Engenharia da Casa (base comum)

Conjunto normativo que rege como software é projetado, construído, testado e operado aqui. Esta é a **base comum, agnóstica de linguagem** — o que se repete em toda a stack. As skills irmãs **especializam** esta base por contexto: `schematize-go`/`schematize-rust` (backend), `schematize-web` (frontend), `schematize-node` (legado Node), `schematize-pentest` (teste de segurança). Use esta quando o projeto não é de uma linguagem específica, ou quando quer só os princípios da casa; use a irmã de linguagem quando há stack definida.

**Versão:** skill `schematize-engineering` v0.20.1. Changelog em `CHANGELOG.md`.

## Comandos (Claude Code)

Digite `/eng-help` pra ver todos. Em resumo:

| Comando | O que faz |
|---|---|
| `/schematize-help` | **índice único de TODAS as skills** (go/rust/web/node/eng/pentest): o que cada comando faz |
| `/eng-help` | lista todos os comandos do schematize-engineering |
| `/eng-cc` | context compact: gera context.md + checklist.md no archive e roda `/compact` |
| `/eng-handoff` | gera o handoff (context.md + checklist.md) **sem** compactar — pra fim de sessão |
| `/eng-review` | roda o gate da DoD/§37 no diff (arquivo >750 bloqueia / >300 úteis flag, função sem doc, índice, macaquices) |
| `/eng-scan` | **varredura ampla** de problemas na base inteira (correção, anti-padrões, pisos, duplicação/morto, testes, concorrência, dados, supply chain, dívida, deriva de índice) — exaustiva, com fan-out; cada achado com `arquivo:linha`+severidade+conserto |
| `/eng-plan` | **planejamento extensivo** plan-first: entender→escopo→spikes→decompor no grafo→risco/rollback→ADR→paralelização→fases; gera o plano no archive, deriva o checklist e **pede aprovação** |
| `/eng-refactor` | **refactor disciplinado**: muda a forma sem mudar o comportamento, rede de testes ANTES (red-first), passos pequenos reversíveis, escopo-diff; gate exige mesma suíte verde + contrato idêntico |
| `/eng-audit` | **auditoria de histórico**: enumera todos os checklists (overdev/QA/handoff/plano/ADR/perguntas) e verifica se foram **sanados** — acha órfãos RED e trava se sobrar item aberto/sem prova |
| `/eng-index` | (re)gera o índice de microfunções (§39) a partir dos doc-comments |
| `/eng-orchestrate` | decompõe a tarefa em mini-tasks independentes e paraleliza com subagents (plan-first) — otimiza tempo sobre tokens |
| `/eng-overdev` | modo contínuo: força um checklist exaustivo e **não deixa parar** (Stop hook rejeita) até tudo `- [x]` e o gate passar — anti "entreguei micro-função e disse que terminei" |
| `/eng-ops` | audita/scaffolda o `<projeto>_ops` (interface única): fluxo de ambientes, instalação paralela (`nproc`), independência |
| `/eng-iam` | força/audita/scaffolda o IAM (identidade≠email, ≥2 fatores, ReBAC multi-tenant, sessão longa/logout irreversível) como app separado em `auth.<domain>`, ou porta um auth legado |

Os comandos ficam em `assets/commands/` e são instalados em `.claude/commands/`.

## Como usar esta skill

1. Identifique o domínio da tarefa e **leia o(s) reference(s) relevante(s)** antes de produzir código ou decisão. Não trabalhe de memória — os detalhes (versões, limites, convenções) estão nos arquivos.
2. **Sempre** aplique os pisos inegociáveis abaixo, independente do reference carregado.
3. Ao terminar, valide contra a Definition of Done (`references/entrega.md`, §35) e **gere o archive** (§28, `references/operacao.md`).

Mapa de references — leia o que casa com a tarefa:

| Tarefa | Reference |
|---|---|
| **Limites de código (arquivo ≤750: ~500 úteis + ~250 comentário; flag >300 úteis), uma função/arquivo, comentários, MAPA** | `references/padroes-codigo.md` |
| **Escolha de linguagem — rol sancionado (Go/Rust/Elixir/C#/Zig/Ruby) + guia de fit por problema; Node-backend/PHP em saída; o piso é o mesmo em todas** | `references/linguagens.md` |
| Arquitetura, camadas, DDD, repositórios, anti-monólito, shared libs, CQRS | `references/arquitetura.md` |
| Eventos/mensageria, banco, cache, APIs, resiliência, jobs | `references/dados-eventos.md` |
| Segurança, auth, JWT, multi-tenancy, LGPD, **frontend/segredos** | `references/seguranca.md` |
| **Cadeia de suprimentos: lockfile, SBOM, scan que trava, imagem mínima/pinada/assinada, SLSA, segredo no build** | `references/cadeia-suprimentos.md` |
| **Testes / Q.A. — MOVIDO pra skill dedicada `schematize-qa`** (pirâmide, "verde de verdade", a11y/visual, contrato/dados, flaky, cobertura, plan-first). A engineering mantém só o piso "a DoD exige testes verdes" — o COMO é lá | `references/testes.md` (ponteiro) → skill `schematize-qa` |
| Observabilidade, healthchecks, performance, FinOps | `references/observabilidade.md` |
| Config, deploy/K8s, git/PR, ownership, runbooks/incidentes, ADR, **archive** (§20–28) | `references/operacao.md` |
| **Ops (control plane): fluxo dev→local→github→hml→prd (nada direto no servidor), ops como interface única (100%, autônomo), instalação paralela=`nproc`, independência=invariante** | `references/ops.md` |
| **IAM (identidade+autorização): auth como app separada (`auth.<domain>`), ID≠email, ≥2 fatores/passkey/Resend/Twilio, ReBAC multi-tenant, sessão longa/logout irreversível, migração de legado** | `references/iam.md` |
| Templates, feature flags, IA assistida, DoD, evolução, índice de funcionalidades (§29+) | `references/entrega.md` |
| Filosofia, aplicação universal e a lista completa de anti-padrões vetados | `references/anti-padroes.md` |
| **Orquestração & paralelização: decompor em mini-tasks e paralelizar com subagents (tempo > tokens), fan-out 8/teto 25, isolamento, gather** | `references/orquestracao.md` |
| **OVERDEV — desenvolvimento contínuo até o checklist fechar (Stop hook rejeita parada prematura; só termina 100% verificado)** | `references/overdev.md` |
| **SCAN de problemas — varredura ampla da base (todas as classes: correção, §37, §6, duplicação/morto, testes, concorrência, dados, supply chain, dívida, deriva de índice), exaustiva + fan-out, achado com arquivo:linha+conserto** | `references/scan.md` |
| **PLANEJAMENTO extensivo — plan-first: entender→escopo→spikes→decompor no grafo→risco→ADR→paralelizar→fases; plano no archive, deriva checklist, pede aprovação** | `references/planejamento.md` |
| **REFACTOR disciplinado — muda a forma sem mudar o comportamento; rede de testes ANTES (red-first), passos pequenos, escopo-diff, catálogo seguro, gate de contrato idêntico** | `references/refactor.md` |
| **AUDITORIA de histórico — todo checklist criado foi sanado? enumera overdev/QA/handoff/plano/ADR/perguntas, acha órfãos RED, gera saneamento, trava se sobrar** | `references/auditoria.md` |
| Gestão de contexto em sessões longas no Claude Code (handoff, hooks) | `references/contexto-claude-code.md` |

## Pisos inegociáveis (VETADO — sem ADR de exceção)

Estes nunca são violados, nem "pra funcionar", nem "pra ir mais rápido". A lista completa com veto + caminho certo está em `references/anti-padroes.md` (§37). Os que mais aparecem em código gerado às pressas:

- **Segredo nunca no cliente.** Nada de API key, secret de JWT, senha de banco, service-role key ou token em bundle do browser, nem em `NEXT_PUBLIC_*`/`VITE_*`. Segredo só server-side (BFF/route handler/secret manager). Detalhe em `references/seguranca.md`.
- **SQL sempre parametrizado.** Concatenar string em query é injeção esperando acontecer.
- **Auth e autorização server-side.** `tenant_id`/role/`user_id` vêm do token verificado, nunca do body/header do cliente. Validação no front é UX, não controle.
- **JWT validado por inteiro** (assinatura, exp, aud, iss, alg em allowlist). Senha em bcrypt cost ≥ 12 ou argon2id. Token/id de sessão por CSPRNG, nunca `Math.random()`.
- **Erro nunca engolido** (`catch {}`, `except: pass`, `_ = err`); sem `any`/`@ts-ignore`/`unwrap()` pra calar o compilador.
- **Teste nunca silenciado** pra passar CI (`.skip`, comentar assert, baixar threshold de cobertura). Conserta o código, não o teste.
- **Sem monólito que mistura bounded contexts**, sem monólito distribuído, sem shared lib `commons` de domínio. Detalhe em `references/arquitetura.md`.
- **Archive SEMPRE gerado.** Toda entrega que produz código/decisão/mudança de estado gera o `.md` de archive (§28) — é parte da entrega, não extra. Pular é violação direta. Templates em `assets/`.
- **Migration reversível** (com `down`, testada com rollback). Container não-root, read-only. Dependência nova com nome/licença/versão verificados (typosquatting é real).
- **Pisos de código (`references/padroes-codigo.md`):** arquivos **≤ 750 linhas** (teto duro: ~250 de comentário + ~500 de código útil; acima → quebrar por coesão), **flag em > 300 linhas de código útil** (não bloqueia, mas sempre sinaliza — indício de função extensa/falta de abstração, revê depois; observabilidade ~400), **uma função/unidade lógica por arquivo**, **toda função com doc-comment** (motivo, comportamento esperado, entradas, saídas, efeitos), **`MAPA.md` da aplicação** atualizado no mesmo PR — em **`<projeto>/<projeto>_archive/index/`, nunca no root** — e **índice de microfunções** regenerado (`/eng-index`). **Todo MD gerado (MAPA/índice/plano/relatório/handoff) mora no archive**, root limpo (§28). Detalhe em `references/padroes-codigo.md` (§4) e `references/operacao.md` (§28, §39).
- **Backend novo em linguagem do ROL SANCIONADO, escolhida por fit + ADR.** O rol é **Go, Rust, Elixir, C#, Zig, Ruby** (cada uma com skill irmã); a escolha por serviço sai de um **guia de fit** e vira **ADR** (§27) — não por gosto. **Frontend é Node** (Next.js principal; Astro) — só frontend. **Fora do rol e em saída:** **Node como serviço backend** e **PHP** **não recebem serviço novo** (legado migra por funcionalidade do módulo quando tocado; ~30% afetado → extrai, ~50% extraído → migra o resto). O piso de engenharia é **o mesmo** em toda linguagem — ela muda o "como", não o "o quê". Guia de fit + rol em `references/linguagens.md`; detalhe de saída em `references/arquitetura.md` (§3).
- **Tempo do usuário acima de tokens.** Tarefa que se divide em **≥3 unidades independentes** e não-triviais é **decomposta e paralelizada com subagents** (fan-out de 8 por onda, teto 25) — não executada serial. Não é licença pra desperdício: trabalho acoplado/pequeno é inline; fan-out é plan-first, com contrato fixado, escrita isolada e verificação única. Detalhe em `references/orquestracao.md`.
- **Fluxo de ambientes e ops (`references/ops.md`).** Toda mudança segue **dev local → teste local → GitHub → hml → prd**; **VETADO editar código direto no servidor** (hml/prd é imutável por edição manual, recebe só artefato do git). **100%** das operações no servidor (install/update/correção/config/migrate/rollback) passam pela **ferramenta do `<projeto>_ops`** — nunca à mão; o ops é **autônomo** (o usuário provisiona o servidor do zero sem a IA). **Instalação sempre paralela** = `nproc`; **falha no paralelo = serviços não independentes → corrigir a independência é prioridade máxima** (não serializar pra mascarar).
- **Deploy destrutivo por seed + isolamento por usuário (`references/ops.md` §2–§3).** O ops provisiona em **`/<app>/`** clonando os repos dentro; **`/<app>/.env` é o seeder global** (fonte única de config). **Todo redeploy é destrutivo na aplicação** — apaga a anterior e recria um clone zerado só com o seed (idempotente/sem drift), **preservando os dados** (migration reversível; `ops reset` de dados só em dev/hml). **Cada serviço roda como user Linux próprio em systemd unit hardened** (blast radius mínimo). Tudo automatizado pelo ops.
- **IAM por desenho (`references/iam.md`).** Todo projeto começa com identidade+autorização robustas, e o **auth é app SEPARADA** (`auth.<domain>`, serviço+front próprios, isolados; nunca monolith; apps delegam por OIDC/PKCE). **ID interno imutável — email/telefone nunca é ID** (múltiplos emails; SSO com recuperação local). **≥2 fatores sempre** (passkey no núcleo, TOTP/push, email OTP Resend always-on, Twilio; senha por padrão mas opcional); invariante de troca de fator; **recuperação ≥ login**. **Multi-tenant RBAC/ABAC granular via ReBAC** (deny-default, PDP/PEP, server-side, token fino). **Multi-dispositivo, sessão 7d/90d, logout irreversível.** **Migrar auth legado = prioridade 0.** Scaffold/auditoria por **`/eng-iam`**; testes cross-tenant/priv-esc na `schematize-pentest`.
- **UX de massa — prever o usuário leigo ("prever macacos").** Software pro público **não pode quebrar nem CULPAR o usuário** por como ele invocou/usou. Todo caminho que um usuário ingênuo pode tomar — rodar como **root/su/sudo**, **PATH mínimo**, **sem toolchain**, clicar em ordem "errada", **fechar no meio**, **dir com nome inesperado** — é PREVISTO e tratado com graça: o software **se adapta/conserta sozinho**, NÃO avisa "você fez errado". Edge case que um leigo atinge = **BUG do software, não erro do usuário** (produto de massa: usuário insatisfeito = menos receita). Concreto: **(a)** nunca exija que o usuário saiba de internals (rustup, PATH, sudo, root, git); **(b)** detecte e faça o certo **automaticamente** (rodou como root? descubra o usuário real e instale **pra ele**, nunca em `/root`); **(c)** precisa de privilégio? **eleve sozinho** (sudo só onde precisa); **(d)** falta dependência/toolchain? **instale/configure**; **(e)** mensagem de erro é **acionável e sem culpa** ("faço X pra você" > "você fez errado"). Vale pra **TODO** software user-facing da casa (instaladores, CLIs, GUIs, onboarding). Anti-padrão espelho na §37 (item 48).

> Regra de bolso: se a justificativa começa com "só pra funcionar", "depois eu arrumo" ou "é mais rápido assim" e o resultado mexe em segredo, auth, dado ou registro — é um anti-padrão vetado. Pare e faça certo.

## Testes / Q.A. — MOVIDO pra skill dedicada `schematize-qa`

A disciplina de teste/Q.A. da casa **saiu desta skill** e virou a skill dedicada **`schematize-qa`**
(pirâmide unit→componente→integração→e2e, "verde de verdade" no smoke, a11y/regressão visual,
contrato/dados, flaky, cobertura útil, plan-first `/qa-plan`/`/qa-run`, gates de CI). Detalhe em
`references/testes.md` (ponteiro) e na própria `schematize-qa`.

A engineering mantém **só o piso mínimo**, delegando o COMO pra lá:

- **A Definition of Done exige testes verdes** (§35, `references/entrega.md`): unit + integração passam,
  cobertura nos mínimos, caminhos críticos com teste explícito, smoke que prova conteúdo, `simulated`
  com rota 100% acessível. *Como* fazer cada um é a `schematize-qa`.
- **Teste nunca silenciado pra passar CI** (§37): `.skip`, comentar assert ou baixar threshold é VETADO.
- **Refactor exige rede de testes ANTES** (red-first, `references/refactor.md`).

> **Segurança ofensiva** (pentest de rejeição rota-por-rota, injeção/coerção, IDOR/BOLA, cross-tenant,
> hardening, red-team) é a **`schematize-pentest`** — não é Q.A. **Auditoria de histórico** (checklists
> sanados?) é a **`schematize-audit`**.

## Andaime pronto (scripts e templates)

Não escreva do zero o que já está bundlado:

- **Andaime de TESTE movido** → skill **`schematize-qa`** (`scripts/`): `lib.sh` (helpers), `test-skeleton.sh` (esqueleto de `tests/<mode>/<name>.sh`), `smoke-selfcheck.sh` (meta-teste anti "verde mentiroso"), `simulated/run.py` (engine rotas × personas × injections). Não estão mais aqui — use os da `schematize-qa`.
- `scripts/hooks/context-monitor.mjs` + `scripts/hooks/precompact-backup.mjs` — gestão de contexto no Claude Code: detectam o limite de handoff (default 250k) e fazem backup automático em `<projeto>/<projeto>_archive` antes da compactação. Ver `references/contexto-claude-code.md` e `assets/settings.claude.example.json`.
- `assets/ADR.md`, `assets/TASK.md`, `assets/CHAT_ARCHIVE.md`, `assets/PR_TEMPLATE.md`, `assets/RUNBOOK.md` — templates. ADR/TASK/CHAT_ARCHIVE cumprem §27/§28.
- `assets/GRAFO_GLOBAL.md` + `assets/INDEX_GLOBAL.md` + `assets/INDEX_FUNCTIONS.md` + `scripts/build-index.mjs` — grafo de funcionalidades (§39), **grafo GLOBAL de dois níveis**: o global (serviços como nós com funções principais, contratos como arestas ASCII `A -> B`) é mantido à mão; o detalhado por-serviço (funções como nós) é **gerado** dos doc-comments (§6) pelo `build-index.mjs`, que sai 1 se achar função sem contexto (trava CI). **Local operacional vivo:** `.schematize/grafos/` (o que o app desenha); **espelho durável:** `<projeto>/<projeto>_archive/index/`.
- `assets/CLAUDE.md` — arquivo "sempre on" pra colocar na **raiz do repositório**: garante que estes padrões fiquem pinados no contexto de toda tarefa, não só quando a skill dispara. Copie e ajuste `<project>`.
- `assets/commands/eng-cc.md` — comando `/eng-cc` (context compact) pro Claude Code: gera `context.md` + `checklist.md` em `<projeto>/<projeto>_archive` e compacta. Copie para `.claude/commands/eng-cc.md`. Ver `references/contexto-claude-code.md`.

## Aplicação sempre-on

Esta skill é puxada quando a tarefa casa com a descrição. Para garantir que os padrões valham em **toda** interação do repo (e não só nas que disparam a skill), copie `assets/CLAUDE.md` para a raiz do projeto. Os dois mecanismos se complementam: o `CLAUDE.md` pina o resumo e aponta pra cá; a skill entrega o detalhe e o andaime.
