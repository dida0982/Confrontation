# Roadmap: todas as fases do projeto

Este arquivo é o **mapa do desenvolvimento**. Ele mostra todas as fases, na ordem, e marca o que já foi feito.
Sempre que terminar uma fase, marque com `[x]` e vá para o arquivo da próxima.

> **Regra de ouro:** primeiro fazer o jogo **funcionar** com caixas e cores simples (o chamado *greybox*). Só depois deixar bonito. Jogos de tiro são 90% sensação de controle e de tiro; arte vem no final.

---

## Onde estamos agora

**Feito:** Fases 0 a 4 (planejamento, projeto criado, jogador, armas, dano e bonecos de treino)
**Agora:** testar a sala de treino e ajustar a sensação, seguindo [02-jogador-armas-e-dano.md](02-jogador-armas-e-dano.md)
**Próximo passo:** Fase 5, o mapa (greybox)

---

## Fases

### Fase 0: Planejamento ✅
- [x] Definir a ideia do jogo e as regras ([README.md](../README.md))
- [x] Escolher as ferramentas gratuitas
- [x] Criar este roadmap

### Fase 1: Instalação e projeto vazio ✅
- [x] Godot 4.7.2 baixado (está em `Downloads`)
- [x] Git instalado
- [x] Projeto do Godot criado na pasta `jogo/`
- [x] Repositório público no GitHub: https://github.com/dida0982/Confrontation

### Fase 2: Controle do jogador ✅
- [x] Câmera em primeira pessoa com o mouse
- [x] Correr (WASD), andar silencioso (Shift), agachar (Ctrl ou C), pular (Espaço)
- [x] Freada rápida ao soltar a tecla (para parar e atirar, como no Valorant)
- [x] Sala de treino com grade de 1 metro, caixas, parede e plataforma com rampa

### Fase 3: Armas e tiro ✅
- [x] Tiro instantâneo em linha reta (*hitscan*), **sem queda de bala**
- [x] As 3 armas: fuzil (1), pistola (2), sniper (3), com pente, recarga (R) e tempo de sacar
- [x] Recuo e imprecisão: aumenta correndo, pulando e atirando sem parar
- [x] Zoom da sniper (botão direito)
- [x] Marcas de bala nas paredes
- [x] Mira (crosshair) que abre conforme a imprecisão

### Fase 4: Vida, dano e morte ✅ (parte do jogador fica para a Fase 6)
- [x] Hitbox separada para **cabeça** e **corpo**
- [x] Cabeça = 1 tiro. Corpo = 4 tiros (pistola/fuzil). Sniper = 1 tiro em qualquer lugar
- [x] Bonecos de treino (parados e andando de lado), renascem em 2 segundos
- [x] Marcador de acerto (branco = corpo, amarelo = cabeça, vermelho = matou)
- [ ] Morte do jogador e modo espectador (fica para a Fase 6, junto com os rounds)

### Fase 5: Mapa (greybox) ⬅️ PRÓXIMA
- [ ] Desenhar o mapa no papel (vista de cima): base ataque, base defesa, mid, Bomb A, Bomb B
- [ ] Montar o mapa com blocos simples no Godot
- [ ] Pontos de nascimento das duas equipes e barreiras da fase de preparação
- [ ] Testar tempos de caminhada (cada rota deve demorar parecido)

### Fase 6: Regras da partida
- [ ] Morte do jogador e modo espectador
- [ ] Sistema de rounds (preparação → combate → fim), todos renascem com as 3 armas e munição cheia
- [ ] Bomba: plantar, timer, desarmar
- [ ] Condições de vitória do round
- [ ] Placar, troca de lado no round 12, vitória com 13

### Fase 7: Multiplayer 5v5
- [ ] Criar e entrar em partida (host / cliente) na rede local
- [ ] Sincronizar movimento e tiros dos jogadores
- [ ] Servidor confere os acertos (evita trapaça básica)
- [ ] Divisão de times e lobby simples
- [ ] Testar com amigos (rede local ou pela internet com ferramentas grátis)

### Fase 8: Interface (HUD e menus)
- [ ] Menu principal, configurações (sensibilidade, volume, resolução)
- [ ] Placar, timer do round, quem matou quem (*killfeed*)
- [ ] Mira personalizável

### Fase 9: Arte e som
- [ ] Modelo do personagem (Blender ou Mixamo) com animações
- [ ] Modelos das 3 armas
- [ ] Texturas e iluminação do mapa
- [ ] Sons: tiros, passos (importantíssimo num jogo tático), recarga, bomba

### Fase 10: Polimento e distribuição
- [ ] Otimização (FPS alto é obrigatório em jogo de tiro)
- [ ] Testes com jogadores e correção de bugs
- [ ] Exportar o jogo para Windows (executável .exe)
- [ ] Publicar grátis, se quiser (ex.: itch.io)

---

## Decisões tomadas

| Decisão | Resposta |
|---|---|
| Jogador escolhe ou compra arma? | **Não.** Todos nascem com fuzil, pistola e sniper |
| Pode pegar arma do chão? | Não |
| Dano da sniper | 1 tiro em qualquer parte do corpo mata |
| Dano de pistola e fuzil | Cabeça 1 tiro, corpo 4 tiros |
| Nome do jogo | **Confrontation** |

## Decisões pendentes

| Decisão | Proposta inicial | Até a fase |
|---|---|---|
| Duração do round e da bomba | Igual ao Valorant: 1:40 de round, 45 s de bomba, 30 s de preparação | Fase 6 |
