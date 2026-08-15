# IAM — Identidade e Autorização da casa (piso inegociável)

Piso normativo de **identidade, autenticação e autorização**, válido para toda skill
da casa. **Todo projeto começa com um IAM robusto por desenho** — segurança é
inegociável. Este arquivo é o modelo agnóstico de linguagem; as skills de linguagem
especializam (backend go/rust, cliente web, migração de legado node, testes pentest).

Princípios-âncora: **separar identidade de autorização**; **nunca menos de 2 fatores**;
**recuperação tão forte quanto o login**; **deny-by-default**; **enforcement sempre no
servidor**. O buraco clássico é ter 2FA no login e um reset por 1 email que passa por
cima — aqui isso é vetado.

## 1. Topologia — auth é uma APLICAÇÃO SEPARADA

- **A autenticação é um serviço próprio, com link próprio e front próprio**, servido em
  **`auth.<domain>`**. **VETADO** apensar o auth ao escopo principal como monolith.
- **Microserviço de auth** (`<projeto>_auth_<lang>`) + **front de auth** próprio
  (`<projeto>_authfront`), com **repo, deploy, user Linux e systemd/container isolados**
  por conta própria (casa com o isolamento por app do `ops.md`). Comprometer o app
  principal **não** compromete o IdP.
- **O app principal (e todo cliente) delega ao auth por OIDC/OAuth2.1 + PKCE:** redireciona
  pra `auth.<domain>`, recebe tokens de volta. O serviço de auth é o **IdP da casa**
  (padrão self-hosted, consumido por N apps).
- **Segredos e chave de assinatura de token vivem SÓ no serviço de auth**; consumidores
  validam por **JWKS público**, nunca guardam a chave privada.

## 2. Modelo de identidade

- **ID interno imutável e opaco** (ULID/UUIDv7) é o `sub`. **Email e telefone NUNCA são
  ID** — são *identificadores* ligados ao usuário, cada um com estado de verificação.
- **Identificadores 1..N por usuário** (emails, telefones, identidades SSO, passkeys, apps,
  chaves FIDO2). **Ter mais de um email é incentivado** (resiliência a brick de provedor).
- **Identificador só vale verificado** — não loga nem recupera sem verificação.
- **SSO nunca é ponto único de falha:** cadastro via SSO **força ≥1 fator de recuperação
  local** (email de recuperação + códigos de backup), pra provedor banido ≠ conta perdida.
- **Account-linking explícito:** SSO chegando com email já verificado em outra conta →
  linkar vs. bloquear **com confirmação** (anti-takeover). Nunca linkar por email não
  verificado.
- **Nudge de email secundário (anti-brick):** com só 1 email, a UI **sugere adicionar um
  secundário**. **Detecta o provedor** do atual (gmail / hotmail-outlook / yahoo /
  próprio-corporativo) e **recomenda que o secundário seja preferencialmente de OUTRO
  provedor**. Ao lado, um **"i" com tooltip no hover**: *"Um segundo email, de preferência
  em outro provedor, garante que você não perca o acesso caso perca acesso a este email."*
  Sugestão, não obrigação.

## 3. Fatores e níveis de garantia (AAL — NIST 800-63B)

Classificar a **força** de cada fator permite "email sempre disponível" sem abrir mão de
segurança: operação sensível exige fator forte; email/SMS servem de fallback.

| Tier | Fatores | Uso |
|---|---|---|
| **Alto (phishing-resistant)** | **Passkey/WebAuthn (núcleo)**, chave FIDO2, push aprovado no app | Ops sensíveis: trocar fator, admin, cross-tenant, billing, recuperação |
| **Médio** | TOTP (app autenticador), senha + posse | Login + 2º fator |
| **Baixo (fallback)** | **Email OTP (Resend)**, **SMS/voz (Twilio)** | Sempre disponível; **não** autoriza ação sensível sozinho |

- **Email OTP (Resend) ligado por padrão, inclusive em HML** — só o operador desliga.
- **Twilio por padrão** para verificação de telefone e 2FA por SMS/voz.
- **Provedores plugáveis:** `EmailProvider` (Resend default), `SmsProvider` (Twilio
  default), `PushProvider` — trocáveis por config, sem tocar no core.
- **Senha por padrão, opcional por escolha:** o usuário **cria senha no cadastro** (padrão
  cultural; **argon2id** + verificação contra base de vazadas/HIBP), mas o **seletor de
  modos de autenticação permite marcá-la como opcional** e viver de passkey/OTP/app.
- **Passkey/WebAuthn é núcleo** (não roadmap): já é "2 fatores num" (dispositivo +
  biometria), phishing-resistant.
- **Nunca menos de 2 fatores:** após o bootstrap, **acesso pleno/sensível fica bloqueado
  até enrolar um 2º fator forte**.

## 4. Fluxos

**Onboarding:** cita um email → **verifica** → **escolhe o 1º meio de autenticação** (senha
por padrão, ou passkey/app) → passa → **escolhe o 2º meio** (fator forte) → passa →
**acesso ao sistema**. O 2º fator é obrigatório antes do acesso pleno.

**Login:** (1) sem app de 2FA ativo → **OTP por email** (mesmo sem nada habilitado); (2)
com app → **pergunta app ou email**; (3) com vários fatores (passkey/telefone/app) →
**lista todos e o usuário escolhe** qual usar. App = push-approval ou TOTP.

**Gestão de fator — invariante único:**
> **Para mutar o fator X, apresente um fator Y ≠ X, no maior AAL disponível.**
- Desativar/trocar **app** → verifica por **email** (ou outro ≠ app).
- Trocar/adicionar **email complementar** → exige o **app**.
- Add/remover **chave ou telefone** → mesmo princípio, **lista qual usar**.
- Toda mudança **notifica todos os canais verificados**; remover o **último fator forte** =
  **ação com atraso cancelável** (janela pra abortar se for ataque).

**Recuperação:** múltiplos caminhos independentes (vários emails, códigos de backup
offline, telefone). **Força ≥ login** (2 fatores ou processo com atraso + revisão),
rate-limit agressivo, tudo auditado. **Reset nunca é bypass de 1 fator.**

**Alcançabilidade — toda exigência tem rampa (sem deadlock de bootstrap):**
> Toda condição obrigatória (enrolar o 2º fator, verificar email, aprovar acesso) só é
> legítima se existe um **caminho self-service, alcançável a partir do estado zero**, até
> satisfazê-la. Gate que exige o que o usuário ainda **não tem** e não oferece como obtê-lo
> **trava a conta** — o clássico "não entra sem 2FA / não cadastra 2FA sem entrar".
- **O fallback always-on É a rampa:** quem não tem 2º fator ainda **entra por Email OTP**
  (sessão de baixo AAL) o suficiente para **enrolar** o fator forte — é para isso que o Email
  OTP é always-on (§3). Nunca "cadastre o app, mas para cadastrar você já precisa do app".
- **A saída nunca exige o que falta nem terceiriza o que é do dono:** mandar quem está sem
  sessão para uma **página que exige sessão** não é saída; "peça a quem administra sua org"
  para algo que **só o dono faz** (enrolar o próprio autenticador) não é saída.
- **Prova por estado:** para **cada** estado de conta (0 fatores, só email, fator forte
  perdido, SSO sem local, convidado) existe uma **transição de saída**. Estado sem saída =
  **bug de bootstrap** (a política pode estar certa; falta o degrau até ela). Teste de
  reachability na schematize-pentest (`iam-testing.md`).

## 5. Multi-tenant + RBAC/ABAC — motor ReBAC (estilo Zanzibar)

- **Identidade global, autorização por tenant:** um usuário (1 identidade) pertence a **N
  tenants** via **membership**, com papéis **diferentes por tenant**.
- **Motor de relação (ReBAC), ex. OpenFGA/SpiceDB** — hand-rolar authz é onde vazam
  privilégios. Autorização em **tuplas** `(objeto, relação, usuário/userset)`:
  - `tenant:acme#member@user:01H…`
  - `role:acme/finance-approver#assignee@user:01H…`
  - `invoice:987#parent@tenant:acme` (recurso parenteado ao tenant)
  - permissão computada por *relation rewrite* (member do tenant **E** assignee de papel
    que concede a permissão).
- **RBAC granular:** permissão = **`recurso:ação`** (`invoice:approve`, `user:invite`);
  papéis-padrão (owner/admin/member/viewer) **+ papéis 100% customizados e granulares por
  tenant** (viram relations/usersets). Deve ser possível criar cargos extremamente
  granulares e atribuí-los.
- **ABAC por cima:** condições sobre atributos (usuário/recurso/contexto — hora, IP, risco)
  via **conditional/contextual tuples** (ex.: aprova invoice < 10k do próprio setor).
- **PDP/PEP separados:** PDP = Check API do motor; **PEP = middleware** em cada serviço.
  **Deny-by-default**, enforcement **server-side**, **todo endpoint mapeia 1 permissão**.
- **Token fino:** carrega `sub`/tenant/sessão/AAL — **sem** a lista de permissões (evita
  authz stale em token longo); decisão consultada/cacheada com TTL curto.
- **Toda decisão de authz é logada** (quem / o quê / allow-deny / política) — auditoria +
  rotina de testes.

## 6. Sessão, multi-dispositivo e logout

- **Multi-dispositivo de 1ª classe:** N sessões simultâneas por usuário, cada uma atada a
  um **dispositivo** (fingerprint + rótulo amigável "Chrome no Windows", IP/geo, último
  uso). Nenhuma sessão derruba a outra.
- **View de dispositivos/sessões:** lista os ativos e **permite remover um** (revoga a
  sessão daquele device), além de **"sair de todos"**.
- **Sessão longa por padrão (fim do "15 min e é chutado"):** o access token continua curto
  (ex.: 15 min) **mas com refresh silencioso** — para o usuário, a sessão **persiste 7 dias
  por padrão**. No login, **pergunta se o dispositivo é confiável**; se sim, **90 dias**.
  Ops sensíveis ainda pedem **step-up fresco** em AAL alto — sessão longa não enfraquece.
- **Refresh rotativo com detecção de reuso** (reusou → revoga a **família** inteira).
- **Botão "Sair" bem visível → kill IRREVERSÍVEL da sessão:** não basta apagar o cookie —
  **revoga o refresh token (e a família), apaga o registro de sessão server-side, joga o
  `jti` na denylist até expirar e desassocia o push token do device**. Depois do logout,
  aquela sessão é irrecuperável: nem replay, nem refresh, nem "voltar o cookie" reativa.
- Cookies **`HttpOnly` + `Secure` + `SameSite`**; token nunca em `localStorage`.

## 7. Migração de auth legado — PRIORIDADE 0

Existe auth no padrão antigo → **portar pra este IAM é prioridade máxima** (segurança
inegociável; pode gastar o que precisar). Estratégia **strangler-fig** (casa com
schematize-node): dual-run, **re-hash preguiçoso** no login (→ argon2id), mapeia registros
legados → modelo novo (dedupe de emails, cunha IDs internos), **força enrolamento de 2º
fator no 1º login pós-migração**, **revoga sessões legadas** e **nunca confia na authz
legada** (re-deriva). O auth migrado nasce já como **app separado** (§1).

## 8. Rotina agressiva de testes (detalhe na schematize-pentest)

Suíte adversarial **contínua** (CI + agendada, fixtures multi-tenant, saída
machine-readable, **gate que trava** em qualquer vazamento):
- **Cross-tenant (BOLA/IDOR):** token do tenant B → IDs do tenant A = 403/404; fuzz de IDs.
- **Priv-esc (BFLA):** papel baixo → ação de papel alto (horizontal e vertical).
- **Matriz persona × endpoint** exaustiva.
- **Abuso de fluxo:** bypass de 2FA, reset pulando 2FA, brute-force/rate-limit de OTP,
  replay de token, reuso de refresh, JWT `alg=none`/kid, session fixation, adulteração de
  asserção SSO, IDOR na gestão de identificadores, bypass de step-up, mass-assignment de
  papel, **logout que não invalidou de verdade** (sessão recuperável).

## 9. Transversais (sempre)
- **Anti-automação / risk engine:** rate-limit + backoff exponencial em OTP; device
  fingerprint e sinais de risco (IP/geovelocidade) disparam step-up.
- **Audit log imutável** de toda decisão authn/authz e mudança de credencial — alimenta a
  forense e os testes (liga com a observabilidade LGTM+ da casa).
- **Padrões:** OIDC/OAuth2.1 + PKCE; WebAuthn/FIDO2; AALs NIST 800-63B; SCIM (roadmap
  enterprise); FAPI2 se fintech.

## Roadmap de fases
- **F0** Núcleo de identidade (ID imutável, N identificadores, verificação, Resend/Twilio
  plugáveis, email OTP always-on) — já como **app separado** em `auth.<domain>`.
- **F1** 2FA + fluxos (TOTP/push, **passkey**, escolha de método, invariante de troca,
  enrolamento forçado do 2º fator, risk engine).
- **F2** Multi-tenant + **ReBAC** (membership, papéis granulares, PDP/PEP, deny-default,
  token fino, audit).
- **F3** Recuperação resiliente (múltiplos caminhos, força ≥ login, SSO com recuperação
  local, atraso cancelável, nudge de email secundário).
- **F4** App de 1ª classe + multi-dispositivo (OIDC/PKCE nativo, push-approval, view de
  remover dispositivos, sessão 7d/90d confiável, logout irreversível).
- **F5** Migração de legado (prioridade 0 quando aplicável).
- **F6** Rotina agressiva de testes (cross-tenant, priv-esc, abuso de fluxo — CI + agendada).
- **Roadmap+** chave FIDO2 dedicada, SCIM, FAPI2, trusted contacts.

## Checklist (entra na Definition of Done quando o projeto tem auth)
- [ ] Auth é **app separada** (`auth.<domain>`, serviço + front próprios, isolados) — não monolith.
- [ ] **ID interno imutável**; email/telefone não são ID; múltiplos emails suportados.
- [ ] **≥ 2 fatores** sempre; passkey no núcleo; email OTP (Resend) always-on; Twilio p/ telefone.
- [ ] Invariante de troca de fator (Y≠X, maior AAL); recuperação ≥ login; SSO com recuperação local.
- [ ] **Toda exigência (enrolar fator, verificar) tem rampa self-service a partir do estado zero** — nenhum estado de conta sem transição de saída (sem deadlock de bootstrap; a saída não exige o que falta nem terceiriza o que é do dono).
- [ ] **Multi-tenant + RBAC/ABAC** (ReBAC), deny-default, PDP/PEP, enforcement server-side, token fino.
- [ ] Multi-dispositivo + view de remover; **sessão 7d/90d**; **logout irreversível** (não só cookie).
- [ ] Audit log de authn/authz; risk engine/rate-limit; migração de legado tratada como prioridade 0.
- [ ] Rotina agressiva de testes cross-tenant/priv-esc no CI (schematize-pentest).
