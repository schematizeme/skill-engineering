<!--
FONTE ÚNICA — cauda comum do bullet "IAM por desenho" (o lead específico da linguagem fica fora do bloco).
Herdada pelas skills derivadas da schematize-engineering via `tools/sync-herdados.mjs`.
Editar = editar AQUI + `node tools/sync-herdados.mjs`; o CI roda --check.
Variantes: invariantes ({{cmd}}).
Não escreva aqui o marcador "herdado" literal: este arquivo é a fonte, não um consumidor.
-->

<!-- variante:invariantes -->
**ID interno imutável (ULID/UUIDv7) — email/telefone nunca é ID** (N emails por usuário; SSO com recuperação local). **≥2 fatores sempre**: passkey/WebAuthn no núcleo, TOTP/push, email OTP always-on, Twilio para telefone; senha argon2id+HIBP por padrão, mas opcional; invariante de troca de fator (Y≠X no maior AAL); **recuperação ≥ login**. Senha + Email OTP já é **2FA baseline**: o PEP libera o baseline e exige AAL alto **só por rota sensível** (step-up just-in-time), nunca barra o login. **Multi-tenant RBAC/ABAC granular via ReBAC** (OpenFGA/SpiceDB; deny-default, PDP=Check API, PEP no servidor, token fino). **Multi-dispositivo, sessão 7d/90d, logout irreversível** (revoga refresh+família, `jti` na denylist, não só cookie). **Migrar auth legado = prioridade 0.** Scaffold/auditoria por **`/{{cmd}}-iam`**; testes cross-tenant/priv-esc na `schematize-pentest`.
<!-- /variante -->

