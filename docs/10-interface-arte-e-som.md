# Passo 10: Interface, arte e som

**O que foi feito:** as Fases 9 e 10 do [roadmap](00-roadmap.md).

- **Fase 9, interface:** tela inicial nova, tema visual próprio e configurações de mira, vídeo, áudio e voz.
- **Fase 10, arte e som:** personagem e armas em 3D, texturas no mapa, sons de tiro, passos, recarga e acerto.

Tudo com recursos **gratuitos**. A lista completa de autores e licenças está em [CREDITOS.md](../CREDITOS.md).

---

## 1. Fase 9: interface

### Tela inicial
- O mapa **Porto em 3D ao fundo**, com a câmera girando devagar.
- Título, subtítulo e botões à esquerda, no estilo do Valorant. O botão principal fica em vermelho.
- Novos botões **Configurações** e **Créditos**. A versão aparece no rodapé.

### Tema visual
- Fonte **Rajdhani** (Google Fonts, licença livre OFL), parecida com a do Valorant.
- Fundo azul-escuro. Botões ficam vermelhos ao passar o mouse. Barras, abas e campos seguem o mesmo estilo.
- O tema fica em `scripts/ui/game_theme.gd`. Mudando as cores lá, muda o jogo todo.

### Configurações (menu principal → Configurações, ou Esc → Configurações)

| Aba | Opções |
|---|---|
| **Mira** | Sensibilidade, tipo (ponto ou cruz), **cor** (verde, branco, amarelo, ciano, rosa, vermelho), **tamanho**, **espessura**, **espaço no meio**, **contorno preto**, com prévia |
| **Vídeo** | Janela / tela cheia / tela cheia exclusiva, tamanho da janela, VSync, limite de FPS, qualidade da imagem 3D (50 a 100%), sombras (desligadas, baixas, altas), mostrar FPS |
| **Áudio** | Volume geral, efeitos (tiros, passos) e vozes dos outros |
| **Voz** | Segurar V ou voz aberta, microfone, teste do microfone, volume mínimo da voz aberta |

Tudo fica salvo no computador. **Dica para computador fraco:** desligue as sombras e baixe a qualidade da imagem 3D para 70%.

**Para programar:** cada opção é uma variável em `scripts/autoload/configuracoes.gd`, listada em `SAVED` (como ela é salva no arquivo). Para mudar uma opção, use `Configuracoes.set_option("nome", valor)`. As telas ficam em `scripts/ui/settings_panel.gd`.

---

## 2. Fase 10: arte e som

### Personagem
- Os outros jogadores e os bonecos de treino agora são um **soldado SWAT animado** (Quaternius, CC0):
  - parado com a arma apontada;
  - correndo para frente, para trás e para os lados (a animação acompanha a direção);
  - caindo quando morre.
- **Contorno na cor do time** (azul ou vermelho), como o contorno dos inimigos no Valorant.
- Segura na mão a arma que está usando (fuzil, pistola ou sniper).
- Os bonecos de treino **piscam o contorno** ao levar tiro: branco no corpo, amarelo na cabeça.

### Armas
- Modelos 3D de verdade em primeira pessoa: **fuzil estilo AK**, **pistola** e **sniper com luneta**.
- **Mãos segurando a arma:** braços com manga do uniforme e luva. A mão direita fica no cabo e a esquerda na frente da arma (na pistola, as duas no cabo).
- **Animação de recarga** nas três armas: a arma inclina, a mão esquerda tira o pente, pega um novo e encaixa. Os sons acompanham.
- **Animação de troca de arma:** a arma nova sobe de baixo da tela.
- **Balanço ao andar** e **tranco ao atirar**.
- **Clarão no cano** a cada tiro, o seu e o dos outros.

### Mapa
- O Porto ganhou **texturas** (Poly Haven, CC0): chão de **concreto**, paredes de **reboco bege** e coberturas de **madeira**.
- Os bombs e as bases continuam com cor própria, agora por cima da textura.
- A sala de treino continua com a grade de 1 metro, que é boa para medir.

### Sons

| Som | Quando |
|---|---|
| **Tiro** de cada arma (gravações reais) | Ao atirar. Os outros ouvem **em 3D**, vindo da arma de quem atirou, até uns 150 m |
| **Passos** no concreto | A cada 2 m andando ou correndo. **Mais alto correndo com Shift. Agachado ou deslizando não faz barulho** (como andar no Valorant) |
| **Recarga** | No começo e no fim da recarga |
| **Troca de arma** | Ao trocar (1, 2, 3) |
| **Acerto** | Quando o seu tiro acerta. Na **cabeça** toca um "ding" |

O volume dos efeitos fica em **Configurações → Áudio**.

---

## 3. Onde fica cada coisa

| Pasta/arquivo | O que tem |
|---|---|
| `jogo/modelos/` | Personagem e armas (.glb) |
| `jogo/scenes/armas/` | Cada arma no tamanho e direção certos, com o marcador "Cano" |
| `jogo/scenes/personagem.tscn` + `scripts/player/character_model.gd` | Corpo 3D animado, contorno do time, arma na mão |
| `jogo/texturas/` | Texturas do mapa |
| `jogo/sons/` | Sons |
| `jogo/fontes/` | Fonte Rajdhani e a licença dela |
| `scripts/weapons/muzzle_flash.gd` | Clarão do tiro |
| `scripts/ui/game_theme.gd` | Tema visual |
| `scripts/ui/settings_panel.gd` | Telas de configuração |
| `CREDITOS.md` | Autores e licenças. **Ao adicionar qualquer recurso novo, coloque aqui** |

### Ajustes rápidos

| O que | Onde |
|---|---|
| Posição da arma na tela | `scenes/player.tscn` → `Head/Camera3D/WeaponManager` (e cada arma dentro dele) |
| Onde as mãos seguram cada arma | `scenes/armas/*.tscn` → marcadores `MaoDireita`, `MaoEsquerda` e `Pente` |
| Cor e forma dos braços, cotovelos | `scripts/weapons/first_person_arms.gd` |
| Curva das animações de recarga, troca e balanço | `scripts/weapons/weapon_manager.gd` → `_animate()` |
| Volume do tiro da sua arma | `weapon_manager.gd` → `SHOT_VOLUME_DB` (os tiros dos outros: nó `SomTiro` em `player.tscn`) |
| Posição da arma na mão do personagem | `scenes/personagem.tscn` → `Weapon Rotation Degrees` e `Weapon Offset` |
| Espessura do contorno do time | `character_model.gd` → `OUTLINE_SIZE` |
| Distância entre passos | `player.gd` → `STEP_DISTANCE` |
| Quão longe se ouve um tiro | `scenes/player.tscn` → nó `SomTiro` → `Max Distance` |
| Repetição das texturas | `scenes/mapas/porto.tscn` → materiais → `UV1 → Scale` |

### Licenças (resumo)

Quase tudo é **CC0** (domínio público). A exceção são os **sons de tiro**, que são **CC-BY 3.0** (Vincent Sevedge): podem ser usados de graça, inclusive para vender o jogo, **desde que o autor apareça nos créditos**. Por isso o menu tem a tela **Créditos**.

---

## 4. Testes que foram feitos

- [x] Tela inicial, configurações (todas as abas) e créditos: fotos tiradas em 1280x720
- [x] Mapa com texturas, inimigo SWAT com contorno vermelho, fuzil, pistola e sniper em primeira pessoa: fotos tiradas de dentro do jogo
- [x] Bonecos de treino com o SWAT, inclusive o que anda de lado (animação de corrida lateral)
- [x] Duas cópias do jogo: o host **ouve o tiro do cliente em 3D**, vê a arma certa na mão dele (pistola) e morre com 4 tiros. O placar fica igual nos dois
- [x] As configurações que você já tinha salvo (sensibilidade, mira, nome) continuam valendo

**Ouvir os sons de verdade** e conferir se os volumes estão bons fica com você.

## ✅ Checklist para você

- [ ] A tela inicial abre com o mapa girando ao fundo
- [ ] Configurações → Mira: mudar cor e tamanho muda a mira no jogo
- [ ] Configurações → Vídeo: tela cheia e sombras funcionam
- [ ] Os sons de tiro, passos e acerto estão com volume bom
- [ ] Com 2 janelas: o outro jogador aparece como soldado com contorno, anima ao correr e o tiro dele soa vindo dele

## ➡️ Próximos passos

- **Publicar a versão 0.2.0** para os amigos, com voz, interface nova e arte nova. Veja [08-gerar-e-publicar-o-jogo.md](08-gerar-e-publicar-o-jogo.md).
- **Fase 11, bots:** um modo 5x5 em que o seu time e o outro são bots inteligentes (veja o plano no [roadmap](00-roadmap.md)).
- **Fase 12, polimento:** otimização, correção de bugs e testes com mais jogadores.
- **Ideias para depois:** mais mapas, o modo de plantar a bomba, animação de recarga, sons diferentes para cada tipo de chão.
