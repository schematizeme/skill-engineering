# Escolha de linguagem — rol sancionado + guia de fit (agnóstico)

> A casa **não tem "a linguagem única"**; tem **o rol sancionado** e um **guia de fit**. A
> engenharia (esta base) é **agnóstica**: os pisos — segurança, testes, archive, DoD, IAM,
> ops, observabilidade — são **os mesmos em toda linguagem**. A linguagem muda o **como**, não
> o **o quê**. Cada linguagem sancionada tem uma **skill irmã** que especializa esta base.

## 1. O rol sancionado

**Backend (serviço novo) — escolha uma, com ADR (§27) justificando o fit:**

| Linguagem | Skill | Sufixo de repo |
|---|---|---|
| **Go** | `schematize-go` | `_go` |
| **Rust** | `schematize-rust` | `_rs` |
| **Elixir** | `schematize-elixir` | `_ex` |
| **C#** (.NET) | `schematize-csharp` | `_cs` |
| **Zig** | `schematize-zig` | `_zig` |
| **Ruby** | `schematize-ruby` | `_rb` |

**Frontend:** **Node** (Next.js principal; Astro e outros consolidados) — governado por
`schematize-web`. É **só frontend** (o server-side do próprio front — route handlers/server
actions/BFF — faz parte do frontend).

## 2. Fora do rol (saída / legado — não reabrem)

- **Node como serviço backend** e **PHP** **não recebem serviço novo.** O que existe é
  **legado**: fica como está até ser tocado, e migra para uma linguagem do rol **por
  funcionalidade do módulo** (~30% afetado → extrai o módulo; ~50% extraído → migra o resto;
  ajuste pontual não porta). Detalhe da saída em `schematize-node` (Node) e migração sumária
  (PHP). O ganho marginal de tooling não reabre a porta.
- **Nova linguagem fora do rol** exige **ADR de exceção** aprovado — não se adota por gosto.

## 3. Guia de fit — quando usar cada (a decisão vira ADR)

Escolha por **encaixe com o problema**, não por preferência. O default pragmático é Go; o
default quando o custo de erro é alto é Rust; os demais entram quando o **fit** manda.

- **Go** — serviços de rede/API concorrentes, CLIs, tooling de infra/ops. Simplicidade,
  deploy de binário estático, concorrência por goroutines/canais. **Default pragmático.**
- **Rust** — correção e **segurança de memória** críticas, performance previsível (sem GC),
  sistemas, componentes sensíveis (auth, cripto, parsing de input hostil), WASM. **Default
  quando errar é caro.**
- **Elixir** — **realtime e alta concorrência** tolerante a falha (BEAM/OTP), sistemas
  distribuídos, messaging/streaming, presença/pub-sub, soft-realtime. Let-it-crash +
  supervisão.
- **C# (.NET)** — ecossistema **.NET/enterprise**, integração Microsoft, times .NET, cargas
  com ASP.NET Core/EF Core, desktop/Windows quando aplicável.
- **Zig** — **baixo nível e performance máxima** com controle explícito de memória, embedded,
  **interop com C**, artefatos pequenos, tooling de sistema. Sem GC, sem controle de fluxo
  oculto.
- **Ruby** — **prototipagem rápida**, scripts/automação, DX de produto (Rails) onde velocidade
  de iteração pesa mais que throughput; e **manutenção de legado Ruby**.

> Regra de fit: um serviço de auth/cripto pede Rust; um gateway realtime pede Elixir; um
> job de rede simples pede Go; um utilitário de sistema pede Zig; uma integração .NET pede
> C#; um script/protótipo pede Ruby. Se dois encaixam, escolha o **default pragmático** (Go)
> e registre o porquê no ADR.

## 4. O que NÃO muda com a linguagem (o piso é comum)

Independente da escolha, valem **integralmente** os pisos desta base (a linguagem só muda a
implementação):

- **Segurança:** segredo nunca no cliente, SQL/consulta sempre parametrizada, auth server-side,
  validação de input, sem erro engolido (`references/seguranca.md`, `anti-padroes.md`).
- **IAM por desenho** como app separada (`references/iam.md`).
- **Testes de verdade** + cobertura + pentest de rejeição (`references/testes.md`).
- **Arquitetura/DDD**, bounded contexts, anti-monólito (`references/arquitetura.md`).
- **Ops** (fluxo de ambientes, `<projeto>_ops`, deploy destrutivo por seed), **observabilidade**
  (OTel), **archive + DoD + índice/MAPA** (§28, §35, §39).
- **Clean code** (`references/padroes-codigo.md`) — os limites de arquivo/função valem para
  todas; o "código útil" e o estilo de comentário se adaptam à linguagem na skill irmã.

> A skill de linguagem **especializa** cada um desses para os idiomas, o build, os gerenciadores
> de pacote, o modelo de concorrência e o ecossistema da linguagem — mas **nunca afrouxa o
> piso**. Escolher a linguagem é decisão de ADR; cumprir o piso não é opcional em nenhuma.
