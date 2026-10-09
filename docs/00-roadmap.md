# Roadmap: todas as fases do projeto

Este arquivo é o **mapa do desenvolvimento**. Ele mostra todas as fases, na ordem, e marca o que já foi feito.
Sempre que terminar uma fase, marque com `[x]` e vá para o arquivo da próxima.

> **Regra de ouro:** primeiro fazer o jogo **funcionar** com caixas e cores simples (o chamado *greybox*). Só depois deixar bonito. Jogos de tiro são 90% sensação de controle e de tiro; arte vem no final.

---

## Onde estamos agora

**Feito:** Fases 0 a 11 (jogo completo em rede, com voz, arte e som, e **bots inteligentes** no modo 5x5 contra bots). Versão **0.2.0** publicada. Fase 12 quase toda feita: desempenho medido, bugs corrigidos e testes automáticos
**Agora:** jogar contra os bots e com amigos e anotar o que melhorar ([11-bots.md](11-bots.md), [12-polimento-e-testes.md](12-polimento-e-testes.md))
**Próximo passo:** decidir o estudo de bots que aprendem com o seu jeito de jogar ([13-estudo-bots-que-aprendem.md](13-estudo-bots-que-aprendem.md))

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

### Fase 7: Multiplayer 5v5 ✅

- [x] Menu principal: nome, criar partida (host), entrar pelo IP, treinar sozinho
- [x] Sala (lobby) com os times Azul e Vermelho, até 5 por time, troca de time
- [x] Movimento, tiros, mortes, placar, renascimento e minimapa sincronizados
- [x] Servidor (host) confere os acertos: cadência, alcance, linha de visão, alvo vivo e inimigo
- [x] Host pode voltar todos para a sala e começar outra partida
- [x] Testado com 2 cópias do jogo no mesmo computador
- Arquivo: [07-multiplayer.md](07-multiplayer.md)
- [ ] (Depois) Testar com amigos pela internet (Radmin VPN, ZeroTier ou Tailscale)
- [ ] (Depois) Entrar no meio da partida, servidor dedicado, compensação de atraso

### Fase 8: Chat de voz por proximidade ✅

- [x] Captura do microfone (`AudioEffectCapture`), segurando V ou com voz aberta
- [x] Compressão μ-law (grátis, sem addon) e envio pela rede, só para quem está perto
- [x] Voz num `AudioStreamPlayer3D` no boneco: alcance de 25 m, volume cai com a distância
- [x] Parede abafa a voz; inimigos perto também ouvem; mortos não falam
- [x] Menu: modo, volume das vozes, microfone, teste do microfone, sensibilidade da voz aberta
- [x] Aviso de quem está falando (HUD e em cima do boneco)
- Arquivo: [09-chat-de-voz.md](09-chat-de-voz.md)
- [ ] (Depois) Silenciar um jogador, rádio só do time, codec Opus

### Fase 9: Interface ✅

- [x] Menu no Esc: continuar, configurações e sair
- [x] Placar de abates e mortes segurando Tab; minimapa
- [x] Tela inicial com o mapa em 3D ao fundo e tema visual próprio (fonte Rajdhani)
- [x] Configurações em abas: mira (cor, tamanho, espessura, espaço, contorno), vídeo (modo de tela, resolução, VSync, FPS, qualidade, sombras), áudio e voz
- [x] Tela de créditos
- Arquivo: [10-interface-arte-e-som.md](10-interface-arte-e-som.md)

### Fase 10: Arte e som ✅

- [x] Personagem SWAT animado (Quaternius, CC0) com contorno na cor do time
- [x] Modelos das 3 armas (em primeira pessoa e na mão dos outros) e clarão no cano
- [x] Texturas no mapa Porto (Poly Haven, CC0)
- [x] Sons de tiro (3D para os outros), passos, recarga, troca de arma e acerto
- [ ] (Depois) Animação de recarga, sons por tipo de chão, efeitos de impacto (faíscas, poeira)

### Fase 11: Bots (NPCs inteligentes) ✅

**Objetivo:** um modo **5x5 com bots**. Você joga com 4 bots no seu time contra 5 bots no outro, e eles se mexem e lutam de um jeito parecido com jogadores de verdade. Também dá para completar uma partida online com bots quando faltar gente.

**Como vai funcionar:**
- [x] **Navegação:** o mapa ganha uma malha de navegação (`NavigationRegion3D`, recurso grátis do Godot). Cada bot usa um `NavigationAgent3D` para achar caminhos, desviar de caixas e paredes e subir rampas
- [x] **O mesmo boneco dos jogadores:** o bot é o mesmo `Player`, só que controlado por um "cérebro" (`BotController`) em vez de teclado e mouse. Assim usa as mesmas armas, regras de dano, animações, sons e rede
- [x] **Visão de verdade:** o bot só "vê" quem está no campo de visão dele e sem parede no meio (raio de visão). Ouve tiros e passos por perto e aparece no minimapa ao atirar, como os jogadores
- [x] **Comportamentos (máquina de estados):**
  - **Patrulhar:** escolhe uma rota (A, Meio ou B) e anda até pontos importantes do mapa, olhando para as quinas
  - **Combater:** ao ver um inimigo, mira com tempo de reação e erro de mira (como um humano), atira em rajadas curtas, faz **strafe** (anda de um lado para o outro atirando, como no Valorant), agacha às vezes e escolhe a arma certa pela distância (sniper de longe, fuzil no meio, pistola ao ficar sem bala)
  - **Procurar cobertura:** com inimigo perto demais ou recarregando, vai para trás de uma caixa ou parede
  - **Investigar:** vai até onde ouviu um tiro ou viu alguém no minimapa
  - **Flanquear:** às vezes vai por outra rota para pegar o inimigo pelas costas
- [x] **Trabalho em equipe:** os bots se dividem entre as rotas (não vão todos juntos), avisam os aliados onde viram inimigos e seguem o jogador do time de vez em quando
- [x] **Dificuldade (Fácil, Normal, Difícil):** muda o tempo de reação, a precisão da mira, o quanto miram na cabeça e o quanto usam strafe e cobertura
- [x] **Menu:** botão "Jogar contra bots (5x5)" com a escolha de dificuldade; na sala online, o host pode completar os times com bots
- [x] **Rede:** os bots rodam só no host (servidor); para os outros computadores eles aparecem como jogadores normais
- [x] **Bots com nome** e no placar do Tab, no feed de abates e no minimapa
- Arquivo: [11-bots.md](11-bots.md)

### Fase 12: Polimento e distribuição ⬅️ AGORA

- [x] Otimização: medido ~500 FPS com 10 bonecos na tela; consulta de "levantar" reaproveitada
- [x] Correção de bugs (bots parados no começo, microfone preso ao sair, Ctrl com o menu aberto)
- [x] Testes automáticos sem janela (`jogo/testes/`): dano, tiro, proteção, rotas e partida com bots
- [x] Exportar o jogo para Windows (`Confrontation.exe`) e publicar no GitHub Releases ([08-gerar-e-publicar-o-jogo.md](08-gerar-e-publicar-o-jogo.md)); 0.2.0 publicada
- [ ] Testes com pessoas de verdade (amigos online e contra bots)
- [ ] Publicar a 0.3.0 com os bots
- [ ] Publicar grátis, se quiser (ex.: itch.io)
- Arquivo: [12-polimento-e-testes.md](12-polimento-e-testes.md)

### Fase 13 (proposta): bots que aprendem com o seu jeito de jogar

Estudo em [13-estudo-bots-que-aprendem.md](13-estudo-bots-que-aprendem.md). Recomendação: gravar suas partidas e transformar num perfil e numa biblioteca de movimentos que os bots usam (sem rede neural no começo).

- [ ] Gravador de partidas
- [ ] Perfil do jogador (rotas, reação, mira, strafe, armas)
- [ ] Biblioteca de movimentos de combate
- [ ] Contra-tática: inimigos que se adaptam a você
- [ ] Personalidades (agressivo, lurker, sniper, suporte)
- [ ] (Opcional) Rede neural de imitação

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
| Multiplayer | 5 contra 5 online; um jogador cria a partida (host) e os outros entram pelo IP |
| Comunicação | Chat de voz por proximidade |
| Como falar | Segurando V (padrão) ou voz aberta, escolhido no menu |
| Alcance da voz | 25 m, abafada atrás de paredes |
| Inimigos ouvem sua voz? | Sim, se estiverem perto |
| Bots | Mesmo boneco dos jogadores, rodam só no host; 3 dificuldades; completam os times até 5x5 |

## Decisões pendentes

- Fase 13: começar pelo gravador + perfil do jogador? Bots aprendem só com você ou também com os amigos? Ter o modo "Bot espelho"? (ver [13-estudo-bots-que-aprendem.md](13-estudo-bots-que-aprendem.md))
