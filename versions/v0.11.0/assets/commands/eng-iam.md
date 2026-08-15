---
description: schematize-engineering — força/audita/scaffolda o IAM da casa (identidade≠email, ≥2 fatores, ReBAC multi-tenant, sessão longa/logout irreversível) como app separado em auth.<domain>, ou atualiza um auth existente
argument-hint: "[bootstrap | audit | migrate]"
---

Governe identidade e autorização pelo padrão IAM da casa (`references/iam.md`). Plan-first:
**audita, mostra o plano, pede aprovação, então executa.** Use este comando para **forçar
só a parte de IAM** num projeto (novo ou existente) ou **atualizar/portar um auth legado**.

## 0. Modo
- `audit` — varre o projeto e reporta o gap contra o piso IAM (checklist §iam).
- `bootstrap` — scaffolda o IAM do zero como **app separada**.
- `migrate` — porta um auth legado pro IAM (**prioridade 0**, strangler-fig).

## 1. Topologia primeiro (inegociável)
Confirme/scaffolde que o auth é **aplicação SEPARADA** (`references/iam.md` §1):
- Serviço próprio `<projeto>_auth_<lang>` + front próprio `<projeto>_authfront`, servidos em
  **`auth.<domain>`** — **VETADO** monolith apensado ao escopo principal.
- Repo/deploy/**user Linux + systemd isolados** por conta própria (casa com `ops.md` §3).
- App principal e clientes **delegam por OIDC/OAuth2.1 + PKCE**; chave de assinatura só no
  auth, consumidores validam por **JWKS público**.

## 2. Identidade
- **ID interno imutável** (ULID/UUIDv7); **email/telefone nunca são ID**; **N emails** por
  usuário (incentivado). Identificador só vale **verificado**.
- **SSO com recuperação local forçada**; account-linking explícito (anti-takeover).
- **Nudge de email secundário:** detecta provedor e recomenda outro provedor + tooltip "i".

## 3. Fatores (≥2 sempre)
- **Passkey/WebAuthn no núcleo**; TOTP/push; **email OTP (Resend) always-on inclusive HML**
  (só operador desliga); **Twilio** p/ telefone; providers **plugáveis**.
- **Senha por padrão** (argon2id + HIBP), **opcional no seletor de modos**.
- **2º fator forte obrigatório** antes do acesso pleno (bootstrap por email não basta).
- Invariante de troca: **mutar fator X exige fator Y≠X no maior AAL**; notificar canais;
  remover último fator forte = **atraso cancelável**. Recuperação **≥ força do login**.

## 4. Autorização (multi-tenant, ReBAC)
- **Identidade global, papéis por tenant** (membership). Motor **ReBAC (OpenFGA/SpiceDB)**,
  tuplas `(objeto, relação, usuário)`; **RBAC granular** (`recurso:ação`, papéis
  customizados) + **ABAC** (conditional tuples). **PDP/PEP separados, deny-default,
  enforcement server-side, token fino, decisão auditada.**

## 5. Sessão / logout
- **Multi-dispositivo** + **view de remover dispositivos** + "sair de todos".
- **Sessão 7 dias por padrão; pergunta se confiável → 90 dias** (access token curto com
  refresh silencioso — nada de "15 min e é chutado"). Step-up fresco em ops sensível.
- **Botão Sair visível → kill IRREVERSÍVEL:** revoga refresh + família, apaga sessão
  server-side, `jti` na denylist, desassocia push token. Nada recria a sessão.

## 6. Testes (dispare o gate do pentest)
Rode/priorize a rotina agressiva (`schematize-pentest`): **cross-tenant (BOLA/IDOR),
priv-esc (BFLA), abuso de fluxo (bypass 2FA/reset/step-up, replay, refresh reuse, logout
que não invalidou)** — gate que trava em vazamento. Ver `/pentest-authz`.

## 7. Migração de legado (modo `migrate`, prioridade 0)
Strangler-fig: dual-run, **re-hash preguiçoso** (→argon2id) no login, mapeia registros →
modelo novo (dedupe emails, cunha IDs), **força 2º fator no 1º login**, **revoga sessões
legadas**, **re-deriva authz** (nunca confia na antiga). O auth migrado nasce app separado.

## 8. Saída
Grave o plano/relatório em `<projeto>_archive/` (§28): topologia (app separado?), gaps do
checklist IAM (`references/iam.md`), plano por fase (F0–F6) e — se `migrate` — o mapa
legado→novo e a ordem de corte. Confirme: auth é app à parte? identidade≠email? ≥2 fatores?
ReBAC multi-tenant deny-default? sessão longa + logout irreversível? testes cross-tenant no CI?
