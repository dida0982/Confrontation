# Passo 03: Mata-mata em equipe

**O que foi feito:** a Fase 5 do [roadmap](00-roadmap.md), mais quatro mudanças de regra pedidas:

1. **Sem recuo:** a mira não sobe nem abre ao atirar sem parar.
2. **Shift corre mais rápido** (antes era andar devagar).
3. **Munição infinita:** o pente e a recarga continuam normais, mas as balas nunca acabam.
4. **Modo mata-mata em equipe** no lugar de plantar a bomba (que fica para o futuro).

---

## 1. Regras do mata-mata em equipe

| Regra | Valor | Onde mudar |
|---|---|---|
| Times | Azul x Vermelho, até 5 por time (quando tiver multiplayer) | `scripts/match/team.gd` |
| Pontos | 1 por abate de inimigo | |
| Vitória | 100 abates **ou** mais abates quando o tempo acabar | `Kills To Win` |
| Tempo de partida | 9:30 (570 segundos) | `Time Limit` |
| Empate | Sim, se o tempo acabar com o placar igual | |
| Renascer | 3 segundos depois de morrer | `Respawn Delay` |
| Proteção de nascimento | 2 segundos sem levar dano (acaba se você atirar) | `Spawn Protection` |
| Onde renasce | No ponto do seu time **mais longe** dos inimigos vivos | nós `Spawns/Azul` e `Spawns/Vermelho` |
| Fogo amigo | Não existe | |
| Ao renascer | Vida 100, todos os pentes cheios, volta para o fuzil | |

Os valores com nome na coluna "Onde mudar" ficam no nó **TeamDeathmatch** da cena do mapa (`scenes/mapas/porto.tscn`) ou da sala de treino (`scenes/sala_de_treino.tscn`). Clique nele e mude no Inspetor.

## 2. Como testar

Aperte **F5**. Na sala de treino, você é do time **Azul** e os bonecos são do time **Vermelho**.

- **Placar no topo:** Azul (esquerda), tempo, Vermelho (direita). Cada boneco que você mata vale 1 ponto para o Azul.
- **Feed de abates** (canto superior direito): "Você matou Boneco (cabeça)", com as cores dos times.
- **F8 (só para teste):** mata você na hora. Aparece a tela vermelha "VOCÊ MORREU – Renascendo em 3.0". Você renasce num ponto do fundo da sala com o aviso "PROTEÇÃO DE NASCIMENTO".
- **Fim da partida:** para testar rápido, mude `Kills To Win` para 5 no nó TeamDeathmatch. Ao chegar em 5 aparece **VITÓRIA** e o placar. **Enter** começa de novo.
- **Munição:** atire o pente inteiro. Ele recarrega sozinho e o contador mostra `25 / ∞`.
- **Shift:** segure andando para frente. Você fica bem mais rápido.

## 3. Como o código está organizado

| Arquivo | O que faz |
|---|---|
| `scripts/match/team.gd` | Lista dos times (Azul, Vermelho) com nome e cor |
| `scripts/match/team_deathmatch.gd` | Regras da partida: placar, tempo, renascimento, fim de jogo |
| `scripts/components/health.gd` | Vida, time, proteção de nascimento; avisa **quem matou** |
| `scripts/player/player.gd` | Morrer (câmera desce, armas somem) e renascer |
| `scripts/ui/hud.gd` | Placar, tempo, feed de abates, tela de morte e de fim |

### Como um abate é contado

1. O tiro acerta uma hitbox e chama `take_damage(dano, cabeça, atirador)`.
2. Se a vida chega a 0, o `Health` emite o sinal `died(quem_matou, foi_na_cabeça)`.
3. O `TeamDeathmatch` ouve esse sinal de todos que estão no grupo **"combatants"**. Se quem matou é do outro time, soma 1 ponto.
4. Ele emite `kill_registered`, que o HUD usa para escrever no feed.
5. Se quem morreu sabe renascer (tem a função `respawn`), entra na fila para renascer em 3 s.

Isso já está pronto para o multiplayer: cada jogador novo só precisa estar no grupo "combatants", ter um `Health` com o time certo e a função `respawn`.

---

## ✅ Checklist desta etapa

- [ ] O placar sobe quando mato um boneco
- [ ] O feed de abates aparece
- [ ] F8 → tela de morte → renasço em 3 s com proteção
- [ ] Partida termina em VITÓRIA ao chegar no limite de abates, e Enter reinicia
- [ ] Armas sem recuo e com munição infinita
- [ ] Shift corre mais rápido

## ➡️ Próximo passo

Depois desta etapa entraram o deslize, o menu da mira e o placar no Tab: veja [04-deslize-menu-e-placar.md](04-deslize-menu-e-placar.md).

### Fase 6, o mapa

O mapa do mata-mata precisa de:
- uma **base para cada time** (com vários pontos de nascimento),
- **três rotas** ligando as bases e um **meio (mid)**,
- espaço reservado para **Bomb A** e **Bomb B**, para usar no modo futuro.

Desenhe no papel, visto de cima, só com quadrados e setas, e peça: *"vamos fazer a fase 6, o mapa"*. Pode descrever ou mandar foto do desenho. Vai ser criado o arquivo `docs/05-mapa-greybox.md`.

Depois do mapa vem o **multiplayer 5v5** (Fase 7) e o **chat de voz por proximidade** (Fase 8).
