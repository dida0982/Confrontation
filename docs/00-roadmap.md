# Roadmap: todas as fases do projeto

Este arquivo é o **mapa do desenvolvimento**. Ele mostra todas as fases, na ordem, e marca o que já foi feito.
Sempre que terminar uma fase, marque com `[x]` e vá para o arquivo da próxima.

> **Regra de ouro:** primeiro fazer o jogo **funcionar** com caixas e cores simples (o chamado *greybox*). Só depois deixar bonito. Jogos de tiro são 90% sensação de controle e de tiro; arte vem no final.

---

## Onde estamos agora

**Feito:** Fases 0 a 6 (projeto, jogador, armas, dano, mata-mata em equipe e o primeiro mapa, o **Porto**), mais deslize, menu da mira, placar no Tab e minimapa
**Agora:** testar o minimapa seguindo [06-minimapa.md](06-minimapa.md)
**Próximo passo:** Fase 7, multiplayer 5v5

---

## Fases

### Fase 0: Planejamento ✅

- [x] Definir a ideia do jogo e as regras ([README.md](../README.md))
- [x] Escolher as ferramentas gratuitas
- [x] Criar este roadmap

### Fase 1: Instalação e projeto ✅

- [x] Godot 4.7.2 e Git instalados
- [x] Projeto do Godot criado na pasta `jogo/`
- [x] Repositório público no GitHub: <https://github.com/dida0982/Confrontation>

### Fase 2: Controle do jogador ✅

- [x] Câmera em primeira pessoa com o mouse
- [x] Andar (WASD), correr mais rápido (Shift), agachar (Ctrl ou C), pular (Espaço)
- [x] Freada rápida ao soltar a tecla (para parar e atirar, como no Valorant)
- [x] **Deslize** com Ctrl em alta velocidade (correndo ou depois de pular correndo)
- [x] Sala de treino com grade de 1 metro, caixas, parede e plataforma com rampa

### Fase 3: Armas e tiro ✅

- [x] Tiro instantâneo em linha reta (*hitscan*), **sem queda de bala**
- [x] As 3 armas: fuzil (1), pistola (2), sniper (3), com pente, recarga (R) e tempo de sacar
- [x] **Sem recuo** e **sem perda de precisão** andando, correndo, pulando ou deslizando
- [x] **Munição infinita** (pente e recarga normais)
- [x] Zoom da sniper (botão direito)
- [x] Marcas de bala nas paredes

### Fase 4: Vida e dano ✅

- [x] Hitbox separada para **cabeça** e **corpo**
- [x] Cabeça = 1 tiro. Corpo = 4 tiros (pistola/fuzil). Sniper = 1 tiro em qualquer lugar
- [x] Bonecos de treino (parados e andando de lado)
- [x] Marcador de acerto (branco = corpo, amarelo = cabeça, vermelho = matou)

### Fase 5: Regras do mata-mata em equipe ✅

- [x] Times Azul e Vermelho, sem fogo amigo
- [x] Morte do jogador e renascimento em 3 s no ponto do time mais longe dos inimigos
- [x] Proteção de nascimento (2 s ou até atirar)
- [x] Placar, 100 abates para vencer, tempo de 9:30, empate
- [x] Feed de abates, tela de morte e tela de vitória/derrota (Enter reinicia)
- Arquivo: [03-mata-mata-em-equipe.md](03-mata-mata-em-equipe.md)

### Fase 6: Mapa (greybox) ✅

- [x] Pesquisa de como a Riot desenha os mapas do Valorant
- [x] Mapa **Porto**: base Azul ao sul, base Vermelha ao norte, três rotas e o meio
- [x] Bomb A e Bomb B prontos para o modo futuro
- [x] Pontos de nascimento nas bases e nomes das áreas no chão
- [x] Tempos de caminhada parecidos para os dois times até o meio
- Arquivo: [05-mapa-porto.md](05-mapa-porto.md)
- [ ] (Depois) Mais mapas

### Fase 7: Multiplayer 5v5 ⬅️ PRÓXIMA

- [ ] Criar e entrar em partida (host / cliente) na rede local
- [ ] Sincronizar movimento, tiros, mortes e placar
- [ ] Servidor confere os acertos (evita trapaça básica)
- [ ] Lobby simples: escolher nome e entrar num time (até 5 por time)
- [ ] Testar com amigos pela internet (servidor dedicado ou ferramentas grátis)

### Fase 8: Chat de voz por proximidade

- [ ] Capturar o microfone (`AudioEffectCapture`) com botão de falar (push-to-talk) ou voz aberta
- [ ] Comprimir a voz com codec **Opus** (addon gratuito) para enviar pela rede
- [ ] Tocar a voz num `AudioStreamPlayer3D` preso ao boneco de quem fala: o volume cai com a distância
- [ ] Definir até onde a voz alcança e se paredes abafam o som
- [ ] Opções: volume da voz, silenciar um jogador, escolher o microfone

### Fase 9: Interface (menus)

- [x] Menu no Esc: continuar, mira e sair
- [x] Sensibilidade (mesma escala do Valorant) e tipo de mira (ponto ou cruz), salvos no computador
- [x] Placar de abates e mortes segurando Tab
- [x] Minimapa no canto (estilo Valorant); quem atira aparece para os inimigos por 3 s ([06-minimapa.md](06-minimapa.md))
- [ ] Menu principal (tela inicial), criar/entrar em partida
- [ ] Mais configurações: volume, resolução, microfone, cor e tamanho da mira

### Fase 10: Arte e som

- [ ] Modelo do personagem (Blender ou Mixamo) com animações, cores dos times
- [ ] Modelos das 3 armas
- [ ] Texturas e iluminação do mapa
- [ ] Sons: tiros, passos (importantíssimo num jogo tático), recarga

### Fase 11: Polimento e distribuição

- [ ] Otimização (FPS alto é obrigatório em jogo de tiro)
- [ ] Testes com jogadores e correção de bugs
- [ ] Exportar o jogo para Windows (executável .exe)
- [ ] Publicar grátis, se quiser (ex.: itch.io)

### Futuro: modo plantar a bomba

- [ ] Rounds sem renascimento (morreu, vira espectador até o próximo round)
- [ ] Fase de preparação com barreiras
- [ ] Bomba: plantar, timer, desarmar
- [ ] Troca de lado no round 12, vitória com 13

---

## Decisões tomadas

| Decisão | Resposta |
|---|---|
| Nome do jogo | **Confrontation** |
| Modo de jogo atual | Mata-mata em equipe (plantar bomba fica para o futuro) |
| Mapas | Originais, com a mesma estrutura dos mapas do Valorant (não copiamos mapas da Riot) |
| Jogador escolhe ou compra arma? | **Não.** Todos nascem com fuzil, pistola e sniper |
| Pode pegar arma do chão? | Não |
| Dano da sniper | 1 tiro em qualquer parte do corpo mata |
| Dano de pistola e fuzil | Cabeça 1 tiro, corpo 4 tiros |
| Recuo das armas | Não tem |
| Munição | Infinita (pente e recarga normais) |
| Shift | Corre mais rápido |
| Ctrl correndo | Desliza |
| Precisão em movimento | Igual a parado (andar/correr/pular não desvia o tiro) |
| Tipos de mira | Ponto e cruz |
| Esc | Abre o menu (o jogo não pausa) |
| Tab | Mostra o placar de abates |
| Minimapa | No canto superior esquerdo; quem atira aparece para os inimigos por alguns segundos |
| Multiplayer | 5 contra 5 online |
| Comunicação | Chat de voz por proximidade |

## Decisões pendentes

| Decisão | Proposta inicial | Até a fase |
|---|---|---|
| Voz: botão para falar ou microfone sempre aberto? | Botão (ex.: V), com opção de voz aberta | Fase 8 |
| Alcance da voz | Uns 25 metros, abafada atrás de paredes | Fase 8 |
| Inimigos ouvem sua voz? | Sim (proximidade vale para todos), o que dá estratégia | Fase 8 |
| Onde roda o servidor | Um jogador hospeda; servidor dedicado depois | Fase 7 |
