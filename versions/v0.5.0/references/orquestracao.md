# Orquestração & paralelização — tempo do usuário acima de tokens

> Piso de **execução**: quando uma tarefa se divide em partes independentes, o padrão da casa é **decompor em mini-tasks e paralelizar com múltiplos subagents**, não fazer serial. O gargalo que otimizamos é o **relógio do usuário (wall-clock)**, não o orçamento de tokens. Preferimos gastar mais tokens e entregar em minutos a economizar tokens e levar horas. O que é vetado é o oposto: gastar 10× o tempo resolvendo serialmente algo que paralelizava.

## 1. Princípio (o trade-off explícito)

- **Tempo > tokens.** Se há um caminho que custa 5× mais tokens mas entrega em 15 min paralelizando, e outro que economiza tokens mas leva 2 h, **escolha o rápido**. Tokens são baratos; o tempo do usuário não.
- **Isso não é licença pra desperdício.** Paralelizar tem custo fixo (cada agent começa **frio** e re-deriva contexto; depois há o passo de juntar/integrar). Paralelizar trabalho **acoplado** ou **pequeno demais** só adiciona overhead e *gasta* o tempo do usuário. Juízo, não reflexo.

## 2. Regra de decisão (fan-out vs inline)

- **≥ 3 unidades independentes e não-triviais → fan-out** (um subagent por unidade, disparados **em paralelo numa só mensagem**).
- **< 3 unidades, ou trabalho acoplado/sequencial → inline** (faça você mesmo; abrir agents aqui perde).

**"Independente"** = as unidades **não compartilham alvo de escrita** e **não têm ordem obrigatória** entre si. Arquivos distintos, repos distintos, idiomas distintos, tópicos de pesquisa distintos: independentes. Um único arquivo coeso com dependências internas, ou um pipeline `build → deploy`: acoplado.

## 3. Largura do fan-out

- **Default otimizado: 8 subagents por onda.** Cobre a maioria dos casos (8 idiomas, N arquivos, N repos) numa tacada.
- **Teto global: 25** para tarefas extremamente grandes. Acima de 8 unidades, dispare em **ondas de 8** até 25; acima de 25, agrupe unidades por afinidade até caber.
- Cada subtask deve ser **chunky** o bastante pra amortizar o cold-start — se uma "unidade" é um único `Edit`, agrupe várias num só agent.

## 4. Playbook (como decompor bem)

1. **Design/decomposição primeiro (plan-first).** Se o desenho não está fechado, **decida a arquitetura/contrato antes** de abrir agents — senão eles divergem e a integração custa mais do que economizou. Fixe: interfaces, nomes, formato de saída, critério de "pronto".
2. **Particione por independência** (§2). Liste as unidades; confirme que não colidem.
3. **Brief autossuficiente por agent.** O subagent **não vê a conversa** — mande contexto necessário, caminhos absolutos, o contrato a seguir, e o critério de pronto. Um brief pobre gera retrabalho (o pior desperdício de tempo).
4. **Isole escritas.** Se agents tocam o mesmo repo: `isolation: "worktree"` (cada um numa cópia git isolada) **ou** particione por diretório/arquivo com fronteiras que não se cruzam. Nunca deixe dois agents escrevendo o mesmo arquivo.
5. **Orquestrador faz o gather.** Você (o principal) junta os resultados, **integra e verifica uma vez** (build/test/publish). Paralelize também a **verificação** quando ela se divide (curls independentes, suites por serviço).
6. **Continue, não recrie.** Pra iterar num agent que já tem o contexto, use continuação (SendMessage) em vez de abrir outro frio.

## 5. Padrões de fan-out comuns

| Situação | Decomposição |
|---|---|
| N arquivos/módulos independentes a criar/editar | 1 agent por arquivo (ou grupo coeso) |
| Mesma mudança em N repos/serviços | 1 agent por repo (worktree se for o mesmo) |
| Traduzir/portar pra N idiomas/plataformas | 1 agent por idioma/alvo |
| Pesquisar M tópicos/perguntas | 1 agent (Explore) por tópico |
| Suite de testes por serviço/domínio | 1 agent por suite; gather do relatório |
| Auditoria/review de N áreas | 1 agent por área; consolida achados |

## 6. Onde NÃO paralelizar (seja honesto)

- Um **arquivo único coeso** com dependências internas.
- **Desenho ainda indefinido** (agents divergem — faça §4.1 antes).
- **Ordem dura** (`build → deploy`, migração antes de código que a usa).
- Quando o **custo de merge/coordenação > tempo economizado** (2 unidades pequenas).

## 7. Permanência — o MD é o backup, à prova de crash (MUST)

Eventos de subagent são efêmeros: chat corrompe, a plataforma trava, uma onda morre no meio. **O estado nunca vive só nos eventos.** A verdade do fan-out mora num **MD de checkpoint** no archive, escrito **antes** de qualquer agent rodar e atualizado a cada onda — assim, se tudo cair, você **retoma lendo o MD**, sem refazer o que já ficou pronto.

1. **Antes de disparar a onda 1**, grave o plano+checkpoint em **`<projeto>_archive/orchestration/<YYYY-MM-DD-HH-MM-SS>-<tarefa>.md`**: o contrato, a lista de unidades e uma **tabela de status** (`PENDENTE / EM ANDAMENTO / FEITO / FALHOU`) por unidade, com o caminho do resultado de cada uma.
2. **Cada subagent grava o próprio resultado** num `.md` no archive (não só retorna pelo evento) — `…/orchestration/<tarefa>/<unidade>.md` com o que fez, arquivos tocados e o pronto/erro. Resultado que só existe no evento **não existe**.
3. **A cada onda que fecha**, o orquestrador **atualiza a tabela de status** no MD de checkpoint. O MD é sempre o retrato atual.
4. **Retomada:** se a sessão cai, o próximo passo é **ler o checkpoint** e disparar só as unidades `PENDENTE/FALHOU` — nunca recomeçar do zero. Sem retry infinito; unidade que falha 2× vira gate humano.

> Isto é o mesmo princípio do handoff (§34.1) e do archive (§28): **MD como memória durável**. Se a resposta a "e se travar agora?" não for "abro o MD e continuo", o fan-out está sem rede.

## 8. Integração com o resto da casa

- **Plan-first, sempre.** Como o Q.A. (`references/testes-execucao.md` §22.9), a orquestração **planeja a decomposição, mostra o fan-out e o custo, e pede aprovação** antes de disparar as ondas — passo destrutivo só com gate, sem retry infinito, retoma do checkpoint (§7) até concluir. Comando: `/eng-orchestrate`.
- **Archive.** Plano, checkpoint e resultado consolidado entram no archive (§28) — em `<projeto>_archive/orchestration/`, nunca no root — como qualquer entrega.
- **Contexto.** Ondas longas seguem a gestão de contexto (`references/contexto-claude-code.md`): handoff antes de compactar.

> Regra de bolso: **se dá pra dividir sem colidir, divida e paralelize.** O usuário paga o relógio, não o token. Mas paralelizar exige o mesmo rigor de sempre — contrato fixado, escrita isolada, **checkpoint em MD**, verificação única. Fan-out sem plano (ou sem checkpoint durável) é desperdício rápido, não entrega rápida.
