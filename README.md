# Confrontation

Um jogo de tiro em primeira pessoa, tático, **5 contra 5**, inspirado no estilo de jogo do Valorant, mas **sem poderes, sem classes de personagem e sem granadas**. Só mira, posicionamento e trabalho em equipe.

Todo o projeto é feito **somente com softwares gratuitos**.

---

## 1. A ideia do jogo

- Duas equipes de 5 jogadores: **Ataque** e **Defesa**.
- Todos os personagens são iguais: mesmo modelo, mesma vida, mesma velocidade. Não existem agentes nem habilidades.
- Cada jogador nasce com uma arma na mão e joga o round só com ela. Não tem granada, fumaça, flash nem nenhum outro utilitário.
- A partida é dividida em rounds, como no Valorant (detalhes abaixo).

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

## 3. Armas

Só existem 3 armas. **Ninguém escolhe nem compra arma**: todo jogador já nasce com as 3 e troca entre elas com as teclas 1, 2 e 3. Não dá para pegar arma do chão.

| Tecla | Arma | Como funciona |
|---|---|---|
| 1 | **Fuzil** | Automático (segura o botão para atirar), pente de 25, tem recuo (*recoil*) quando atira muito seguido. |
| 2 | **Pistola** | Semiautomática (um tiro por clique), pente de 12, boa precisão. |
| 3 | **Sniper** | Um tiro a cada 1,5 s, pente de 5, mira com zoom no botão direito. Só é precisa com zoom e parada. |

## 4. Formato da partida (igual ao Valorant)

- **Objetivo do Ataque:** plantar a bomba (no Valorant chama "Spike") em um dos dois locais (**Bomb A** ou **Bomb B**) e proteger até explodir, **ou** eliminar todos os defensores.
- **Objetivo da Defesa:** impedir a plantação, desarmar a bomba, **ou** eliminar todos os atacantes.
- Cada round tem: fase de preparação (barreiras fechadas) → fase de combate → fim do round.
- Quem morre fica de espectador até o próximo round (não renasce no meio do round).
- **Troca de lado** depois de 12 rounds.
- **Vence quem chegar a 13 rounds** primeiro.

## 5. O mapa

- Um mapa no estilo dos mapas do Valorant: **dois locais de bomba (A e B)**, um **meio (mid)**, base de ataque e base de defesa com barreiras no início do round.
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

**Por que Godot e não Unreal ou Unity?** O Godot é 100% gratuito para sempre, sem taxa nenhuma mesmo se o jogo der dinheiro, é leve (roda em computador simples) e é mais fácil para começar. Unreal cobra royalties depois de certo faturamento e Unity tem regras de licença que já mudaram várias vezes.

## 7. Estrutura de pastas

```
jogo de fps/
├── README.md        ← este arquivo (visão geral do projeto)
├── docs/            ← passo a passo do desenvolvimento
│   ├── 00-roadmap.md                       ← todas as fases e o que já foi feito
│   ├── 01-instalacao-das-ferramentas.md
│   └── 02-jogador-armas-e-dano.md          ← o que foi feito por último
└── jogo/            ← projeto do Godot (abra o arquivo project.godot)
    ├── scenes/      ← cenas (sala de treino, jogador, boneco de treino)
    ├── scripts/     ← código (GDScript)
    ├── weapons/     ← números de cada arma (fuzil, pistola, sniper)
    └── materials/   ← materiais (grade de 1 metro do greybox)
```

## 8. Como continuar

1. Abra [docs/00-roadmap.md](docs/00-roadmap.md) para ver todas as fases e em qual estamos.
2. Siga o arquivo do próximo passo indicado lá.
3. A cada fase concluída, um novo arquivo é criado em `docs/` com o passo a passo do que foi feito e do que vem depois.

Quer ajudar no projeto? Leia o [CONTRIBUTING.md](CONTRIBUTING.md) (fluxo de trabalho e padrão de commits).
