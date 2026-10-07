# Passo 04: Deslize, menu da mira e placar no Tab

**O que foi feito nesta etapa:**

1. **Precisão em movimento:** andar, correr, pular ou deslizar **não desvia mais o tiro**. A precisão é a mesma de quando você está parado.
2. **Menu no Esc** com ajuste de **sensibilidade** e **tipo de mira** (ponto ou cruz).
3. **Deslize** (*slide*) com Ctrl quando estiver rápido, como no Fortnite e no Call of Duty.
4. **Placar de abates** segurando **Tab**.

---

## 1. Controles atualizados

| Tecla | Ação |
|---|---|
| W A S D | Andar |
| Shift (segurar) | Correr mais rápido |
| Ctrl ou C | Agachar. **Correndo, desliza** |
| Espaço | Pular (pular no meio do deslize mantém o embalo) |
| Botão esquerdo / direito | Atirar / zoom da sniper |
| R | Recarregar |
| 1 / 2 / 3 | Fuzil / Pistola / Sniper |
| **Esc** | **Menu** |
| **Tab (segurar)** | **Placar de abates** |
| F11 | Tela cheia |
| F8 | Morrer (só para teste) |

---

## 2. Deslize

**Como fazer:**
- Corra com **Shift** e aperte **Ctrl** (segurando). O boneco abaixa e desliza.
- Ou corra, **pule** e aperte **Ctrl no ar**: quando cair no chão, ele desliza.
- **Pule durante o deslize** para sair voando com o embalo.

**Como funciona:**

| Regra | Valor |
|---|---|
| Velocidade mínima para deslizar | 6 m/s (correndo com Shift passa disso; andando normal, não) |
| Embalo extra ao começar | +2 m/s (máximo 10 m/s) |
| Perda de velocidade | 7 m/s por segundo (o deslize dura uns 0,8 s) |
| Termina quando | fica abaixo de 3 m/s, solta o Ctrl ou sai do chão |
| Espera entre deslizes | 0,6 s |
| Câmera | Inclina 5° durante o deslize |

Ao terminar com o Ctrl ainda apertado, o boneco continua agachado. Se bater numa parede, o deslize perde velocidade e acompanha a parede.

**Para ajustar:** abra `scenes/player.tscn`, clique no nó **Player** e mude o grupo **Deslize** no Inspetor.

---

## 3. Menu (Esc)

- **Esc** abre o menu. **O jogo não pausa**, porque vai ser online, igual ao Valorant. Enquanto o menu está aberto, o seu boneco para de andar e de atirar.
- **Continuar:** fecha o menu.
- **Mira:**
  - **Sensibilidade:** arraste a barra ou digite o número. Usa a **mesma escala do Valorant**, então você pode colocar a mesma sensibilidade que usa lá. O padrão é 2,0.
  - **Tipo de mira:** **Ponto** ou **Cruz**, com prévia logo abaixo.
  - **Voltar** (ou Esc) volta para a página principal.
- **Sair do jogo:** fecha o jogo.

As escolhas ficam **salvas no computador**. Quando abrir o jogo de novo, continuam iguais. O arquivo fica em `%APPDATA%\Godot\app_userdata\Confrontation\configuracoes.cfg`.

---

## 4. Placar (Tab)

Segure **Tab** para ver:
- o total de abates de cada time;
- cada jogador com **Abates** e **Mortes**, do melhor para o pior;
- a **sua linha em amarelo**.

Na sala de treino aparecem você (Azul) e os 6 bonecos (Vermelho). No multiplayer vão ser os 5 jogadores de cada lado.

---

## 5. Arquivos novos e alterados

| Arquivo | O que faz |
|---|---|
| `scripts/autoload/configuracoes.gd` | Guarda e salva a sensibilidade e o tipo de mira (acessível em qualquer script como `Configuracoes`) |
| `scripts/ui/pause_menu.gd` | O menu do Esc |
| `scripts/ui/crosshair.gd` | Desenha a mira (ponto ou cruz). Usado pelo HUD e pela prévia do menu |
| `scripts/ui/scoreboard.gd` | Placar do Tab |
| `scripts/match/team_deathmatch.gd` | Agora também conta abates e mortes de cada jogador |
| `scripts/player/player.gd` | Deslize; sensibilidade vem do menu |

---

## ✅ Checklist desta etapa

- [ ] Correndo e pulando, o tiro vai no mesmo lugar que parado
- [ ] Correndo + Ctrl = desliza; andando normal + Ctrl = só agacha
- [ ] Correr + pular + Ctrl no ar = desliza ao cair
- [ ] Esc abre o menu; consigo mudar a sensibilidade e a mira; ao reabrir o jogo, continua salvo
- [ ] Tab mostra o placar com abates e mortes

## ➡️ Próximo passo: Fase 6, o mapa

Desenhe o mapa no papel (base de cada time, três rotas, meio e espaço para Bomb A e B) e peça: *"vamos fazer a fase 6, o mapa"*. Vai ser criado o arquivo `docs/05-mapa-greybox.md`.
