# Passo 07: Multiplayer 5 contra 5

**O que foi feito:** a Fase 7 do [roadmap](00-roadmap.md). Agora dá para **jogar com amigos**: um cria a partida e os outros entram pelo IP. São até **5 jogadores por time**.

---

## 1. Menu principal

O jogo agora abre num **menu**:

| Botão | O que faz |
|---|---|
| **Seu nome** | Nome que aparece no feed de abates e no placar (fica salvo) |
| **Criar partida** | Você vira o **host**: a partida roda no seu computador e você joga junto |
| **Entrar em partida** | Digite o **IP do host** e clique em Conectar |
| **Treinar sozinho no Porto** | Sem conexão, com os bonecos de treino |
| **Sala de treino** | A sala antiga, sozinho |

### A sala (lobby)

Depois de criar ou entrar, todos ficam na **sala**:
- aparecem os dois times, **Azul** e **Vermelho**, com o nome de cada um;
- quem entra vai para o time com menos gente; dá para trocar com **Entrar no Azul / Entrar no Vermelho** (se tiver vaga);
- o host vê os **IPs** que os amigos devem digitar;
- só o host tem o botão **Começar partida**.

### Durante a partida (Esc)

- **Sair da partida:** volta para o menu.
- **Voltar todos para a sala** (só o host): leva todo mundo de volta para a sala. Use para chamar mais gente, porque **não dá para entrar no meio de uma partida**.
- No fim da partida, o **host** aperta **Enter** para jogar de novo.

---

## 2. Como jogar com amigos

### Na mesma casa (mesma rede/Wi-Fi)

1. O host clica em **Criar partida**.
2. Na primeira vez, o **Firewall do Windows** pergunta se pode liberar o Godot/jogo. Clique em **Permitir** (marque "Redes privadas").
3. Os amigos clicam em **Entrar em partida** e digitam o IP que aparece na sala do host (algo como `192.168.0.15`).

### Pela internet (cada um na sua casa)

O jeito mais fácil e **grátis** é usar um programa de **rede virtual**. Ele faz os computadores acharem que estão na mesma casa:

| Programa | Grátis? | Como usar |
|---|---|---|
| **[Radmin VPN](https://www.radmin-vpn.com/)** | Sim | Todos instalam, o host cria uma "rede" com senha, os outros entram nela. Use o IP do Radmin do host (começa com `26.`) |
| **[ZeroTier](https://www.zerotier.com/)** | Sim (plano gratuito) | O host cria uma rede no site, os amigos entram com o ID da rede |
| **[Tailscale](https://tailscale.com/)** | Sim (uso pessoal) | Todos entram na mesma conta/rede; usa o IP `100.x.x.x` do host |

**Outra opção:** liberar a porta **7777 (UDP)** no roteador do host (*port forwarding*) e passar o IP público para os amigos. Funciona, mas cada roteador tem um jeito diferente de fazer isso.

### Testar sozinho com 2 janelas no mesmo computador

1. No Godot: menu **Depurar → Personalizar instâncias de execução...** (*Debug → Customize Run Instances*).
2. Marque **Habilitar várias instâncias** e coloque **2**.
3. Aperte **F5**: abrem 2 janelas do jogo.
4. Numa janela: **Criar partida**. Na outra: **Entrar em partida** com o IP `127.0.0.1`.
5. Na janela do host: **Começar partida**.

---

## 3. Como funciona (para quem for programar)

### Quem decide o quê

| Coisa | Quem decide |
|---|---|
| Movimento e câmera do seu boneco | **Você** (o seu computador manda a posição para os outros) |
| Se o tiro acertou na sua tela | **Você** (o tiro é instantâneo na tela de quem atira) |
| Se o acerto vale, dano, mortes, placar, renascimento, fim da partida | **Host (servidor)** |

### O servidor confere cada acerto (contra trapaça básica)

Quando o seu tiro acerta alguém na sua tela, o jogo **pede** para o host aplicar o dano. O host só aceita se:
1. você está vivo;
2. a arma não está "atirando mais rápido" do que a cadência dela;
3. o alvo é do outro time e está vivo;
4. o tiro saiu de perto de onde o host vê você (até 4 m de diferença, por causa do atraso da internet);
5. o alvo está dentro do alcance da arma;
6. não tem parede entre você e a cabeça ou o corpo do alvo.

### Arquivos

| Arquivo | O que faz |
|---|---|
| `scripts/autoload/rede.gd` | **Rede**: criar/entrar/sair, sala, times, carregar o mapa em todos |
| `scripts/match/team_deathmatch.gd` | A partida: cria os jogadores, confere acertos, envia os eventos (`_event_damage`, `_event_respawn`, `_event_shot`, `_event_end`...) |
| `scripts/player/player.gd` | `is_local()`: só o dono lê teclado/mouse; os outros seguem `net_position`, `net_yaw`, `net_crouching` |
| `scenes/player.tscn` | Nó **SyncMovimento** (copia as variáveis `net_*`) e **Corpo** (boneco colorido que os outros veem) |
| `scripts/ui/main_menu.gd` | Menu principal e sala |

Cada mapa precisa de um nó **Jogadores** e de um **SpawnerJogadores** (MultiplayerSpawner apontando para Jogadores), ligados ao **TeamDeathmatch**. O Porto e a sala de treino já têm.

**Dica:** abrir um mapa direto no editor (**F6**) continua funcionando: o jogo cria você sozinho para testar.

### Limitações conhecidas (para melhorar depois)

- **Não dá para entrar no meio da partida:** o host precisa voltar todos para a sala.
- **Se o host sair, a partida acaba** para todo mundo. No futuro dá para ter um servidor dedicado.
- **Sem compensação de atraso:** com internet muito lenta (ping alto), pode acontecer de você ver o acerto (marcador branco) e o host recusar.
- Os outros jogadores aparecem como **cápsulas coloridas**, sem modelo de arma nem animação (isso vem na fase de arte).
- Na troca de cena podem aparecer avisos `ERR_UNAUTHORIZED` no console do Godot. São pacotes de posição atrasados da partida anterior, que o Godot descarta. Não atrapalham.

---

## 4. Testes que foram feitos

Duas cópias do jogo rodando ao mesmo tempo (host + cliente pelo IP `127.0.0.1`):

- [x] Cliente entra na sala e troca para o time Vermelho
- [x] Host começa: os dois aparecem no Porto, os bonecos de treino saem
- [x] Host mata o cliente com tiro na cabeça: o cliente vê a própria morte e o feed "Host matou Cliente (cabeça)"
- [x] Cliente renasce com proteção e mata o host com 4 tiros de pistola no corpo
- [x] Placar e tabela iguais nos dois computadores (1 x 1)
- [x] Host volta todos para a sala e começa uma segunda partida com placar zerado
- [x] Treinar sozinho (Porto e sala de treino) continua funcionando

## ✅ Checklist para você

- [ ] Abrir 2 janelas (seção 2) e jogar uma contra a outra
- [ ] Jogar com um amigo na mesma rede
- [ ] Jogar com um amigo pela internet (Radmin VPN, ZeroTier ou Tailscale)

## ➡️ Próximo passo: Fase 8, chat de voz por proximidade

Com o multiplayer funcionando, dá para fazer a voz: o microfone de cada jogador toca no boneco dele, e quanto mais longe, mais baixo. Peça: *"vamos fazer a fase 8, o chat de voz"*. Vai ser criado o arquivo `docs/08-chat-de-voz.md`.
