#!/usr/bin/env bash
# overdev-stop.sh — Stop hook do modo OVERDEV (schematize-engineering, /eng-overdev).
#
# O quê: quando o agente tenta PARAR, checa o CHECKLIST do overdev. Se ainda houver
#        QUALQUER item aberto ("- [ ]") — ou o gate de verificação falhar — REJEITA a
#        parada e força a continuação, registrando a tentativa (a "punição"). Assim o
#        agente só fala com o usuário quando o checklist estiver EFETIVAMENTE 100%.
# Onde:  hook `Stop` no settings.json (ver settings.claude.example.json). É INERTE
#        quando não há overdev ativo — seguro registrar global; só engata quando você
#        roda /eng-overdev (que cria .overdev/state mode=active).
#
# Contrato Claude Code (Stop hook): lê JSON no stdin; pra BLOQUEAR imprime
#   {"decision":"block","reason":"..."} e sai 0; pra PERMITIR sai 0 sem decisão.
#
# Estado (control-plane no root do projeto — trate como .git; gitignore):
#   .overdev/state        KEY=VALUE: mode=active, max_iters=N, archive=<path>
#   .overdev/CHECKLIST.md  checklist com "- [ ]" (aberto) / "- [x]" (feito)
#   .overdev/iterations   contador de tentativas de parada
#   .overdev/gate.sh      (opcional) verificação máquina; exit!=0 => NÃO terminou
#   .overdev/DONE         escrito quando tudo verde → permite parar
#   .overdev/BLOCKED      bloqueio real que exige o usuário → permite parar (avisando)

set -uo pipefail
cat >/dev/null 2>&1 || true   # consome o stdin (JSON do harness)

SD=".overdev"; STATE="$SD/state"; CL="$SD/CHECKLIST.md"
[[ -f "$STATE" ]] || exit 0                                   # inerte: sem overdev
mode="$(grep -E '^mode=' "$STATE" | head -1 | cut -d= -f2- || true)"
[[ "$mode" == "active" ]] || exit 0

archive="$(grep -E '^archive=' "$STATE" | head -1 | cut -d= -f2-)"; [[ -n "${archive:-}" ]] || archive="$SD"
mkdir -p "$archive" 2>/dev/null || true
max="$(grep -E '^max_iters=' "$STATE" | head -1 | cut -d= -f2-)"; [[ "${max:-}" =~ ^[0-9]+$ ]] || max="${OVERDEV_MAX_ITERS:-200}"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo '?')"

emit_block() { local r="${1//\\/\\\\}"; r="${r//\"/\\\"}"; r="${r//$'\n'/\\n}"; printf '{"decision":"block","reason":"%s"}\n' "$r"; exit 0; }
allow()      { echo "[$ts] $1" >> "$archive/overdev.log" 2>/dev/null || true; exit 0; }

[[ -f "$SD/DONE" ]]    && allow "DONE — checklist 100%, parada permitida."
[[ -f "$SD/BLOCKED" ]] && allow "BLOCKED — $(head -1 "$SD/BLOCKED" 2>/dev/null)"

# Budget (guardrail anti-loop-infinito; alto e configurável — não é 'desistir').
it="$(cat "$SD/iterations" 2>/dev/null || echo 0)"; [[ "$it" =~ ^[0-9]+$ ]] || it=0
it=$((it+1)); echo "$it" > "$SD/iterations" 2>/dev/null || true
if (( it > max )); then
  echo "budget de $max ciclos atingido em $ts — pare e reporte o progresso e o que falta." > "$SD/BLOCKED"
  allow "BUDGET ($max) atingido após $it ciclos."
fi

# Verificação: itens abertos no checklist + gate de máquina (se houver).
open=0; [[ -f "$CL" ]] && open="$(grep -cE '^[[:space:]]*- \[ \]' "$CL" 2>/dev/null || echo 0)"
gate_ok=1; gate_msg=""
if [[ -x "$SD/gate.sh" ]]; then
  if ! out="$(bash "$SD/gate.sh" 2>&1)"; then gate_ok=0; gate_msg=" | gate.sh FALHOU: $(echo "$out" | tail -1)"; fi
fi

if [[ ! -f "$CL" ]]; then
  emit_block "OVERDEV ativo mas sem $CL. Gere o CHECKLIST exaustivo do objetivo primeiro (um item verificável por linha, '- [ ]'), grave em $CL e em $archive/OBJETIVO.md, e comece."
fi

if (( open == 0 )) && (( gate_ok == 1 )); then
  allow "checklist 100% e gate verde — o agente pode declarar concluído (crie .overdev/DONE)."
fi

# Ainda há trabalho → REJEITA a parada (a 'punição') e re-injeta o que falta.
echo "[$ts] PARADA PREMATURA rejeitada (ciclo $it/$max): $open item(ns) aberto(s)$gate_msg" >> "$archive/premature-stops.log" 2>/dev/null || true
pend="$(grep -nE '^[[:space:]]*- \[ \]' "$CL" 2>/dev/null | head -n 8 | sed 's/"/\x27/g' || true)"
emit_block "MODO OVERDEV — NÃO PARE E NÃO DIGA QUE TERMINOU. Faltam $open item(ns) do checklist$gate_msg (ciclo $it/$max). \
NÃO fale com o usuário ainda. Abra $CL, pegue o PRÓXIMO item aberto, implemente de verdade, VERIFIQUE (rode o gate/teste), e só então marque '- [x]'. Itens abertos agora:\n$pend\n\
Só é permitido parar quando: (a) TODOS os itens '- [x]' e o gate passa → crie .overdev/DONE; ou (b) bloqueio real que exige o usuário (segredo/credencial faltando, decisão irreversível, dependência externa, ambiguidade que muda o resultado) → crie .overdev/BLOCKED com o motivo e a pergunta. Nada de 'acho que tá bom' nem entregar micro-função como se fosse o todo. Continue agora."
