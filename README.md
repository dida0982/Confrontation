# Confrontation

Um jogo de tiro em primeira pessoa, **multiplayer 5 contra 5**, inspirado no estilo de jogo do Valorant, mas **sem poderes, sem classes de personagem e sem granadas**. Só mira, posicionamento e trabalho em equipe, com **chat de voz por proximidade**.

Todo o projeto é feito **somente com softwares gratuitos**.

---

## 1. A ideia do jogo

- Multiplayer online: duas equipes de **5 jogadores**, time **Azul** e time **Vermelho**.
- Todos os personagens são iguais: mesmo modelo, mesma vida, mesma velocidade. Não existem agentes nem habilidades.
- Todo jogador nasce com as mesmas 3 armas. Não tem granada, fumaça, flash nem nenhum outro utilitário.
- **Chat de voz por proximidade:** você ouve a voz dos outros jogadores saindo do boneco deles. Quanto mais perto, mais alto; longe, ninguém ouve.
- Modo atual: **mata-mata em equipe** (detalhes abaixo). O modo de plantar a bomba fica para o futuro.

## 2. Regras de combate

| Regra | Valor |
|---|---|
| Vida do jogador | 100 |
| Tiro na **cabeça** (qualquer arma) | **mata com 1 tiro** (100 de dano) |
| Pistola ou fuzil em **qualquer outra parte do corpo** (peito, braço, perna...) | 25 de dano, **morre com 4 tiros** |
| **Sniper** em **qualquer parte do corpo** | **mata com 1 tiro** (100 de dano) |
| Queda da bala (gravidade) | **Não existe**: a bala vai reto até onde você mirou |
| Tempo de viagem da bala | **Não existe**: o acerto é instantâneo (técnica chamada *hitscan*) |
| Escudo / colete | Não existe |
| Recuo (*recoil*) | **Não existe**: a mira não sobe nem abre ao atirar sem parar |
| Precisão em movimento | **Igual a parado**: andar, correr, pular ou deslizar não desvia o tiro |
| Munição | **Infinita**: o pente tem tamanho normal e precisa recarregar, mas as balas nunca acabam |
| Fogo amigo | Não existe: tiro em aliado não causa dano |

## 3. Armas

Só existem 3 armas. **Ninguém escolhe nem compra arma**: todo jogador já nasce com as 3 e troca entre elas com as teclas 1, 2 e 3. Não dá para pegar arma do chão.

| Tecla | Arma | Como funciona |
|---|---|---|
| 1 | **Fuzil** | Automático (segura o botão para atirar), pente de 25. |
| 2 | **Pistola** | Semiautomática (um tiro por clique), pente de 12, boa precisão. |
| 3 | **Sniper** | Um tiro a cada 1,5 s, pente de 5, mira com zoom no botão direito. Só é precisa com zoom. |

## Movimento

Jogo de tiro **dinâmico**: correr com **Shift**, pular e **deslizar** (Ctrl em velocidade alta, como no Fortnite e no Call of Duty). Pular no meio do deslize mantém o embalo.

## 4. Formato da partida: mata-mata em equipe

No estilo do mata-mata em equipe do Valorant:

- Cada abate de um inimigo vale **1 ponto** para o time.
- **Vence o time que chegar a 100 abates** primeiro, ou o que tiver mais abates quando o tempo de **9:30** acabar (pode dar empate).
- Quem morre **renasce em 3 segundos** num ponto de nascimento do seu time, longe dos inimigos, com vida e pentes cheios.
- Ao renascer, o jogador tem **2 segundos de proteção** (não leva dano). Atirar cancela a proteção.

### No futuro: modo plantar a bomba

Depois, vamos fazer o modo competitivo do Valorant: o Ataque planta a bomba no **Bomb A** ou **Bomb B** e a Defesa tenta impedir ou desarmar. Rounds sem renascimento, troca de lado após 12 rounds e vitória com 13.

## 5. O mapa

- Mapas no estilo dos mapas do Valorant: três rotas e um **meio (mid)**, com uma base para cada time e os locais de bomba (A e B) do modo futuro.
- **Primeiro mapa: Porto** ([planta e detalhes](docs/05-mapa-porto.md)).
- **Minimapa** no canto, como no Valorant: aliados sempre aparecem; **inimigos só aparecem por alguns segundos depois de atirar** ([detalhes](docs/06-minimapa.md)).
- **Importante:** o mapa precisa ser **original**, feito por nós. Copiar exatamente um mapa do Valorant (geometria, texturas, nomes, modelos) é proibido por direitos autorais da Riot Games e poderia fazer o jogo ser derrubado se for publicado. A gente vai usar o **mesmo tipo de estrutura** (três rotas, dois bombs, mid), que é uma ideia de design de jogo e não pertence a ninguém, mas com desenho próprio.
- Pelo mesmo motivo, não vamos usar nomes, logos, sons ou modelos do Valorant.

## 6. Ferramentas (todas gratuitas)

| Para quê | Software | Observação |
|---|---|---|
| Motor do jogo | **[Godot Engine 4](https://godotengine.org/)** | Grátis e código aberto (licença MIT). Sem royalties, sem assinatura, sem conta. |
| Linguagem | **GDScript** | Linguagem do próprio Godot, parecida com Python, fácil para aprender. |
| Modelos 3D (personagem, armas, mapa) | **[Blender](https://www.blender.org/)** | Grátis e código aberto. |
| Texturas e imagens | **[Krita](https://krita.org/)** ou **[GIMP](https://www.gimp.org/)** | Grátis e código aberto. |
| Sons | **[Audacity](https://www.audacityteam.org/)** | Editar sons de tiro, passos etc. |
| Editor de código | **[VS Code](https://code.visualstudio.com/)** | Opcional; o Godot já tem editor de código embutido. |
| Controle de versão | **[Git](https://git-scm.com/)** + **[GitHub](https://github.com/)** (conta grátis) | Guarda o histórico do projeto e serve de backup. |
| Recursos prontos grátis | [Kenney.nl](https://kenney.nl/), [Poly Haven](https://polyhaven.com/), [Freesound](https://freesound.org/), [Mixamo](https://www.mixamo.com/) | Modelos, texturas, sons e animações. Sempre conferir a licença de cada item. |
| Multiplayer | Rede embutida do Godot (**ENet**) | Grátis. Para testar, roda tudo no próprio computador ou na rede de casa. |
| Chat de voz | Captura de microfone do Godot (`AudioEffectCapture`) + addon gratuito com codec **Opus** | A voz toca num `AudioStreamPlayer3D` preso no boneco, então o volume cai com a distância. |

**Por que Godot e não Unreal ou Unity?** O Godot é 100% gratuito para sempre, sem taxa nenhuma mesmo se o jogo der dinheiro, é leve (roda em computador simples) e é mais fácil para começar. Unreal cobra royalties depois de certo faturamento e Unity tem regras de licença que já mudaram várias vezes.

## 7. Estrutura de pastas

```
jogo de fps/
├── README.md        ← este arquivo (visão geral do projeto)
├── docs/            ← passo a passo do desenvolvimento
│   ├── 00-roadmap.md                       ← todas as fases e o que já foi feito
│   ├── 01-instalacao-das-ferramentas.md
│   ├── 02-jogador-armas-e-dano.md
│   ├── 03-mata-mata-em-equipe.md
│   ├── 04-deslize-menu-e-placar.md
│   ├── 05-mapa-porto.md
│   ├── 06-minimapa.md                      ← o que foi feito por último
│   └── img/                                ← planta e fotos dos mapas
└── jogo/            ← projeto do Godot (abra o arquivo project.godot)
    ├── scenes/      ← cenas (mapas/, sala de treino, jogador, boneco de treino)
    ├── scripts/     ← código (GDScript); scripts/match/ tem as regras da partida
    ├── weapons/     ← números de cada arma (fuzil, pistola, sniper)
    └── materials/   ← materiais (grade de 1 metro do greybox)
```

## 8. Como continuar

1. Abra [docs/00-roadmap.md](docs/00-roadmap.md) para ver todas as fases e em qual estamos.
2. Siga o arquivo do próximo passo indicado lá.
3. A cada fase concluída, um novo arquivo é criado em `docs/` com o passo a passo do que foi feito e do que vem depois.

Quer ajudar no projeto? Leia o [CONTRIBUTING.md](CONTRIBUTING.md) (fluxo de trabalho e padrão de commits).
