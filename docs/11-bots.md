# Passo 11: Bots (NPCs inteligentes) e o modo 5x5 contra bots

**O que foi feito:** a Fase 11 do [roadmap](00-roadmap.md). Agora dá para jogar **sozinho num 5 contra 5**: você fica no time Azul com **4 bots aliados** contra **5 bots inimigos**. Na sala online, o host também pode **completar os times com bots** quando faltar gente.

---

## 1. Como jogar contra bots

1. No menu, clique em **Jogar contra bots (5x5)**.
2. Escolha a dificuldade: **Fácil**, **Normal** ou **Difícil** (o jogo lembra a última escolhida).
3. Clique em **Começar**.

**Online com bots:** depois de **Criar partida**, ligue **Completar os times com bots** na sala e escolha a dificuldade. Ao começar, cada time recebe bots até ficar com 5. Exemplo: com 3 amigos no Azul e 1 no Vermelho, entram 2 bots no Azul e 4 no Vermelho.

Os bots aparecem com o nome **"Bot ..."** (Bot Tatu, Bot Falcão...) no placar do Tab, no feed de abates e no minimapa, como qualquer jogador.

### Diferença entre as dificuldades

| | Fácil | Normal | Difícil |
|---|---|---|---|
| Tempo para reagir (ver → atirar) | 0,65 s | 0,4 s | 0,25 s |
| Erro da mira (no começo → depois de mirar) | 1 m → 0,32 m | 0,65 m → 0,17 m | 0,4 m → 0,07 m |
| Chance de mirar na cabeça | 8% | 25% | 50% |
| Faz strafe (anda de lado atirando) | às vezes | quase sempre | sempre |
| Procura cobertura para recarregar | pouco | bastante | quase sempre |
| Flanqueia por outra rota | raramente | às vezes | bastante |
| Alcance da visão | 50 m | 70 m | 90 m |

Num teste de 90 segundos só com bots, no Fácil **5%** dos abates foram na cabeça e no Difícil **60%**.

---

## 2. Como os bots funcionam

### O mesmo boneco dos jogadores
O bot **é o mesmo `Player`** que você controla. A única diferença é quem "aperta as teclas": em vez do teclado e do mouse, um **cérebro** (`BotController`) escreve os comandos:

- `input_move` (WASD), `input_sprint` (Shift), `input_crouch` (Ctrl), `input_jump` (Espaço);
- gira o boneco e a câmera para mirar;
- chama `pull_trigger()`, `equip()`, `start_reload()` e `set_scoped()` nas armas.

Por isso o bot usa **as mesmas armas, o mesmo dano, as mesmas animações, sons e rede**. O tiro dele também é um raio que sai da câmera: se a mira estiver errada, ele erra de verdade.

### Navegação
Quando a partida abre, o host monta uma **malha de navegação** (`NavigationRegion3D`, recurso grátis do Godot) a partir das caixas e paredes do mapa. Cada bot usa um `NavigationAgent3D` para achar o caminho, desviar das caixas e contornar os prédios. Se ficar preso, ele pula e desvia para o lado.

Como a malha é montada sozinha, **um mapa novo funciona sem passo extra**. Para os bots andarem por rotas que fazem sentido, o mapa tem o nó **`PontosBot`**:

```
PontosBot
├── A      ← pontos (Marker3D) da base Azul até a base Vermelha pela rota A
├── Meio
└── B
```

Os pontos ficam na ordem **da base Azul para a Vermelha**; o time Vermelho percorre ao contrário. Num mapa sem `PontosBot`, os bots andam por pontos sorteados da malha.

### O que o bot sabe (sem trapacear)
O bot só sabe o que uma pessoa saberia:

- **Vê** inimigos dentro do campo de visão (100° a 120°) e **sem parede no meio** (um raio invisível do olho dele até a cabeça ou o peito do inimigo). Bem perto (3 m) ele percebe mesmo de costas.
- **Ouve tiros** até 60 m e **passos de quem está correndo** até 18 m. Quem anda agachado não faz barulho.
- Vê no **minimapa** quem atirou, como os jogadores.
- Recebe os **avisos dos aliados** ("vi um inimigo ali").

### Comportamentos (máquina de estados)

| Estado | O que o bot faz |
|---|---|
| **Patrulhar** | Anda pela rota dele (A, Meio ou B). Em cada ponto, para um pouco e olha as quinas por onde o inimigo pode vir. No fim da rota, troca de rota e volta. |
| **Combater** | Espera o tempo de reação, mira com erro que diminui com o tempo (como uma pessoa ajustando a mira), atira em rajadas curtas, faz strafe, às vezes agacha e escolhe a arma pela distância: sniper de longe (só quem "gosta" de sniper), fuzil no meio, pistola se o fuzil ficar sem bala com o inimigo perto. |
| **Cobertura** | Recarregando, ou com 2 inimigos à vista e pouca vida: corre para trás de uma parede, agacha, recarrega e volta para a briga. |
| **Investigar** | Vai até onde ouviu um tiro, viu alguém ou um aliado avisou, já mirando para lá. Chegando, olha em volta e volta a patrulhar. |
| **Seguir** | De vez em quando, um bot do seu time acompanha você por um tempo, olhando para o lado que você não está olhando. |

**Trabalho em equipe:** o "técnico" (`BotDirector`) divide os bots entre as rotas, para não irem todos juntos. Quando um bot vê um inimigo, até **2 aliados** por perto vão ajudar. Às vezes, ao trocar de rota, o bot **flanqueia**: escolhe uma rota diferente daquela onde o time viu inimigos.

### Rede
Os bots rodam **só no host**. O host calcula o movimento e os tiros deles e confere os acertos direto (sem passar pela internet). Para os outros computadores, o bot é um jogador normal: a posição chega pelo mesmo `MultiplayerSynchronizer` dos jogadores.

---

## 3. Onde fica cada coisa

| Arquivo | O que tem |
|---|---|
| `scripts/bots/bot_controller.gd` | O cérebro de cada bot: visão, audição, estados, mira e tiro. A tabela **`PROFILES`** tem todos os números das dificuldades. |
| `scripts/bots/bot_director.gd` | Malha de navegação, rotas, divisão nas rotas, avisos do time e quem acompanha o jogador. |
| `scripts/match/team_deathmatch.gd` | Cria os bots no começo da partida e confere os tiros deles. |
| `scripts/autoload/rede.gd` | `play_vs_bots()`, `set_bots()`, `bots_needed()` e os nomes dos bots (`BOT_NAMES`). |
| `scripts/player/player.gd` | `is_bot`, os comandos `input_*` e `is_simulated_here()`. |
| `scenes/mapas/porto.tscn` | O nó `PontosBot` com as rotas A, Meio e B. |

**Quer deixar os bots mais fáceis ou mais difíceis?** Mude os números em `PROFILES`, no começo de `bot_controller.gd`. Por exemplo, aumentar `reaction` deixa o bot mais lento para atirar, e diminuir `head_chance` faz ele mirar menos na cabeça.

---

## 4. Como testar

1. **Sozinho:** Jogar contra bots → Normal → Começar. Observe no minimapa os aliados se dividindo entre A, Meio e B.
2. **Ouvir:** fique parado numa quina e veja se o inimigo aparece já mirando depois de você atirar (ele ouviu o tiro).
3. **Cobertura:** acerte um bot até ele precisar recarregar; ele deve correr para trás de uma parede.
4. **Online:** crie a partida, ligue os bots na sala e entre com uma segunda cópia do jogo (`127.0.0.1`). As duas cópias devem ver os mesmos bots se mexendo.

Também existe um teste automático que roda uma partida só de bots sem abrir janela; veja a Fase 12 em [12-polimento-e-testes.md](12-polimento-e-testes.md).

---

## 5. Ideias para depois

- Bots entrarem no lugar de quem sai no meio da partida online.
- Bots falando por "rádio" (mensagens rápidas tipo "inimigo no B").
- Usar os bots no futuro modo plantar a bomba (atacar um bomb, defender, desarmar).

## ➡️ Próximo passo: Fase 12, polimento e testes

Veja [12-polimento-e-testes.md](12-polimento-e-testes.md).
