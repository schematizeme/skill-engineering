# IAM — Identidade e Autorização da casa (piso inegociável)

Piso normativo de **identidade, autenticação e autorização**, válido para toda skill
da casa. **Todo projeto começa com um IAM robusto por desenho** — segurança é
inegociável. Este arquivo é o modelo agnóstico de linguagem; as skills de linguagem
especializam (backend go/rust, cliente web, migração de legado node, testes pentest).

Princípios-âncora: **separar identidade de autorização**; **nunca menos de 2 fatores**
(senha + Email OTP **já conta** como 2FA baseline — fator forte é incentivado e just-in-time,
**nunca muro pré-login**); **força adaptável ao risco** (2FA→3FA + negação deceptiva sob
suspeita); **recuperação tão forte quanto o login**; **deny-by-default**; **enforcement sempre
no servidor**. O buraco clássico é ter 2FA no login e um reset por 1 email que passa por
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
| **Alto (phishing-resistant)** | **Passkey/WebAuthn (núcleo)**, chave FIDO2, push aprovado no app | Ops sensíveis: trocar fator, admin, cross-tenant, billing, recuperação; 3º fator sob risco |
| **Médio** | TOTP (app autenticador), senha + posse | Reforço do 2º fator (incentivado) |
| **Baixo (fallback)** | **Email OTP (Resend)**, **SMS/voz (Twilio)** | **É o 2º fator baseline da conta** (senha+OTP = 2FA); sempre disponível; **não** autoriza ação sensível sozinho (aí exige step-up forte) |

- **Email OTP (Resend) ligado por padrão, inclusive em HML** — só o operador desliga.
- **Twilio por padrão** para verificação de telefone e 2FA por SMS/voz.
- **Provedores plugáveis:** `EmailProvider` (Resend default), `SmsProvider` (Twilio
  default), `PushProvider` — trocáveis por config, sem tocar no core.
- **Senha por padrão, opcional por escolha:** o usuário **cria senha no cadastro** (padrão
  cultural; **argon2id** + verificação contra base de vazadas/HIBP), mas o **seletor de
  modos de autenticação permite marcá-la como opcional** e viver de passkey/OTP/app.
- **Passkey/WebAuthn é núcleo** (não roadmap): já é "2 fatores num" (dispositivo +
  biometria), phishing-resistant.
- **2FA por desenho desde o cadastro — senha + Email OTP JÁ é 2FA (fraco, porém válido):**
  a conta **nasce com dois fatores obrigatórios** — algo que **sabe** (senha) + algo que
  **acessa** (código no email verificado, always-on §3). Isso **já é uma conta segura** para
  acesso baseline; o sistema **trata como 2FA de verdade**, não como "sem 2º fator". O erro
  comum — tratar quem tem senha+OTP como se não tivesse 2FA e **barrar o login** até enrolar
  um fator forte — cria o **círculo infinito** (não entra sem forte / não enrola forte sem
  entrar) e é **VETADO**.
- **Fator forte é INCENTIVADO, nunca muro pré-login:** app OTP / passkey / chave são
  **sugeridos** (nudge — para não perder acesso e ganhar força), **exigidos just-in-time** só
  para **operação sensível** (step-up ao AAL alto) e **escalados sob risco** (§9) — jamais
  como bloqueio antes de entrar. Enrolar um fator forte usa o Email OTP como verificação
  (invariante Y≠X, §4): sem deadlock.
- **A força continua importando (AAL), mas degrada o sensível — não bloqueia o acesso:** sem
  fator forte enrolado, o baseline funciona pleno; o que exige AAL alto (billing, trocar
  fator, admin, cross-tenant) **pede o fator forte na hora** (step-up), e é aí — e só aí —
  que o usuário enrola um, se ainda não tem.

## 4. Fluxos

**Onboarding:** cita um email → **verifica** → **cria senha** (ou já escolhe passkey/app) →
**pronto: já está com 2FA (senha + Email OTP) e acesso baseline pleno**. Só **depois** — já
dentro do sistema — a UI **sugere** (não obriga) **reforçar**: adicionar um **2º email de
backup** (nudge, §2) e **enrolar um fator forte** (app/passkey) para não perder acesso e
liberar ops sensíveis sem atrito. **Nunca se barra o acesso por não ter fator forte** — ele
é pedido *just-in-time* na 1ª ação sensível (step-up) ou quando o risco sobe (§9).

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
> A causa-raiz do círculo infinito é de **desenho**: contar senha+Email OTP como "sem 2FA" e
> pôr um muro de fator forte antes do login. Corrigido isso (§3), **não há gate pré-login para
> travar**. A regra de alcançabilidade fica como **rede de segurança** para qualquer outra
> exigência obrigatória: só é legítima se existe um **caminho self-service alcançável a partir
> do estado zero** até satisfazê-la.
- **A exigência degrada, não bloqueia:** o que falta (fator forte, email de backup, aprovação)
  limita **o que aquilo destrava** (ops sensíveis), nunca o **acesso baseline**. O fator forte
  é pedido *just-in-time* e enrolado ali, verificado pelo Email OTP always-on (Y≠X, §3/§4).
- **A saída nunca exige o que falta nem terceiriza o que é do dono:** mandar quem está sem
  sessão para uma **página que exige sessão** não é saída; "peça a quem administra sua org"
  para algo que **só o dono faz** (enrolar o próprio autenticador) não é saída.
- **Prova por estado:** para **cada** estado de conta (só senha+email, fator forte perdido,
  SSO sem local, convidado) existe **acesso baseline + transição de saída** para o que estiver
  degradado. Estado que **bloqueia o login** por falta de fator forte = **bug de bootstrap**.
  Teste de reachability na schematize-pentest (`iam-testing.md`).

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
legados → modelo novo (dedupe de emails, cunha IDs internos), **ativa o Email OTP always-on
como 2º fator baseline** (a conta migrada já entra em 2FA sem muro) e **incentiva enrolar um
fator forte** (step-up para sensível), **revoga sessões legadas** e **nunca confia na authz
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

## 9. Autenticação adaptativa por risco (robusta) + transversais

O 2FA baseline (§3) segura o comum; **o risk engine é o que faz a conta ser difícil de
tomar sem chatear o usuário legítimo**. A resposta ao login **varia com o risco calculado**,
nunca é fixa.

- **Log de sessões e tentativas (fonte do sinal):** cada tentativa e cada sessão registram
  **IP, ASN/reputação, device fingerprint, geo, user-agent, horário, resultado e score de
  risco**. Fica na **view de dispositivos/sessões** (§6) para o usuário ver/revogar, e em
  **audit log imutável** para forense e testes. É o insumo do score e da detecção.
- **Score de risco por tentativa** a partir de sinais combinados: **IP suspeito/novo** (Tor,
  proxy, ASN de abuso, reputação ruim), **device novo**, **geovelocidade impossível**,
  **velocity/força-bruta**, discrepância de horário, e **hit de honeypot** (abaixo). Baixo =
  fluxo normal; elevado/alto = escala.
- **Escalonamento por risco — pede MAIS fatores (2FA → 3FA):** sob risco, exige um **fator a
  mais na ordem de força** — **senha → código por email → app OTP/chave**. Acertar senha+email
  não basta num contexto suspeito: sobe para o 3º fator (forte). É o mesmo motor do step-up de
   op sensível (§3), agora disparado pelo **contexto**, não só pela **ação**.
- **Negação deceptiva / tarpit (o "falso negativo" sob risco):** em contexto **suspeito**,
  mesmo com **senha correta** o sistema pode responder **genérico "credenciais inválidas"** —
  **uma vez** — enquanto **computa server-side que a credencial estava certa** e marca que a
  **próxima** tentativa correta **passa** (já exigindo os fatores escalados). O usuário legítimo
  apenas **re-tenta e entra**; o atacante automatizado **gasta rodadas e não sabe** se acertou.
  Regras que fazem isso ser seguro, não um lockout:
  - **Resposta e tempo IDÊNTICOS** ao erro real de senha (sem oráculo: nada distingue a negação
    deceptiva de um erro verdadeiro — cruza a regra anti-enumeração de §4/pentest).
  - **Estado "próxima passa" curto e escopado** (TTL curto, atado a conta+IP+device); expira
    sozinho. **Nunca** vira bloqueio permanente do legítimo.
  - **Ainda exige os fatores escalados** (3FA) na tentativa que passa — a deceção **soma-se** ao
    step-up, não o substitui. Tudo **logado** com o score que disparou.
- **Honeypot:** contas/campos/rotas **isca** (usuário-armadilha, campo oculto que humano não
  preenche, endpoint que ninguém legítimo chama). **Qualquer interação = sinal forte de
  hostil** → score alto, tarpit/deceção, alerta. Nunca serve tráfego real.
- **Anti-automação sempre:** rate-limit + **backoff exponencial** e **lockout progressivo por
  conta+IP** em senha/OTP/reset; OTP curto, single-use, `jti` na denylist. O burst nunca
  derruba o serviço; ele **barra o abuso**.
- **Notifica o usuário:** login novo/suspeito, novo device, mudança de credencial → aviso em
  **todos os canais verificados**, com ação de "não fui eu" (revoga sessão + força reforço).

### Transversais (sempre)
- **Audit log imutável** de toda decisão authn/authz e mudança de credencial — forense +
  testes (liga com a observabilidade LGTM+ da casa).
- **Padrões:** OIDC/OAuth2.1 + PKCE; WebAuthn/FIDO2; AALs NIST 800-63B; SCIM (roadmap
  enterprise); FAPI2 se fintech.

## Roadmap de fases
- **F0** Núcleo de identidade (ID imutável, N identificadores, verificação, Resend/Twilio
  plugáveis, email OTP always-on) — já como **app separado** em `auth.<domain>`.
- **F1** 2FA baseline por desenho (senha + Email OTP, sem muro pré-login) + fluxos (TOTP/
  push, **passkey**, escolha de método, invariante de troca, **nudge** de fator forte,
  step-up just-in-time, **risk engine adaptativo**: score, escalonamento a 3FA, negação
  deceptiva/tarpit, honeypot).
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
- [ ] **2FA baseline por desenho** (senha + Email OTP = 2FA desde o cadastro); passkey no núcleo; email OTP (Resend) always-on; Twilio p/ telefone.
- [ ] **Fator forte é incentivado (nudge) + just-in-time (step-up), NUNCA muro pré-login** — não se barra o acesso baseline por falta de fator forte (mata o círculo infinito).
- [ ] Invariante de troca de fator (Y≠X, maior AAL); recuperação ≥ login; SSO com recuperação local.
- [ ] **Alcançabilidade:** exigência **degrada** o sensível, não bloqueia o baseline — nenhum estado de conta sem acesso baseline + saída self-service (sem deadlock de bootstrap).
- [ ] **Risk engine adaptativo:** log de sessões/tentativas + score (IP/device/geo/velocity/honeypot); escalonamento a **3FA** sob risco; **negação deceptiva/tarpit** (falso negativo com "próxima passa", resposta idêntica ao erro real); notifica login suspeito.
- [ ] **Multi-tenant + RBAC/ABAC** (ReBAC), deny-default, PDP/PEP, enforcement server-side, token fino.
- [ ] Multi-dispositivo + view de remover; **sessão 7d/90d**; **logout irreversível** (não só cookie).
- [ ] Audit log de authn/authz; rate-limit/lockout progressivo; migração de legado tratada como prioridade 0.
- [ ] Rotina agressiva de testes cross-tenant/priv-esc no CI (schematize-pentest).
