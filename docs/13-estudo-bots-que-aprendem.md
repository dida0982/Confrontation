# Estudo: bots que aprendem com o seu jeito de jogar

**Pedido:** bots com inteligência e movimentos parecidos com os de uma pessoa, que **aprendem enquanto você joga contra eles**, copiam suas movimentações e táticas e **não fazem sempre a mesma coisa**.

**Resumo da recomendação:** dá para fazer, e de graça. Mas o caminho que funciona primeiro **não é uma rede neural gigante**. É gravar como você joga e transformar isso num **perfil** e numa **biblioteca de movimentos** que os bots usam. Esse tipo de aprendizado já funciona depois de poucas partidas, roda dentro do jogo em GDScript (sem Python e sem a versão .NET do Godot) e deixa cada bot diferente. A rede neural de verdade fica como um passo opcional, depois, usando os dados já gravados.

---

## 1. As três formas de "machine learning" para bots

| Forma | Como funciona | Fica parecido com humano? | Quanto custa |
|---|---|---|---|
| **A. Aprendizado por reforço** (*reinforcement learning*) | Os bots jogam milhões de partidas entre si e ganham "pontos" por matar e sobreviver. Vão melhorando sozinhos | **Não muito.** Ficam bons, mas com jeito de robô: giram 180° na hora, andam de forma estranha, exploram falhas do mapa | Muito tempo de treino (horas a dias de computador), Python, e para rodar no jogo precisa da versão **.NET** do Godot |
| **B. Imitação pura** (*behavior cloning*): uma rede neural copia teclado e mouse | Grava você jogando e treina uma rede para apertar as mesmas teclas nas mesmas situações | **Sim, quando funciona.** Mas precisa de **muitas horas** de gravação. Com pouco dado, o bot fica "bêbado": treme, anda em círculo, trava em parede | Python + treino fora do jogo. Aprender "enquanto você joga" fica difícil |
| **C. Híbrido (recomendado)**: o "esqueleto" atual (andar pela malha, ver, atirar) continua, mas **as escolhas e o estilo vêm do que você faz** | Grava sua partida, calcula seus hábitos (rotas, reação, strafe, onde segura ângulo...) e guarda trechos reais dos seus movimentos. Os bots sorteiam a partir disso | **Sim**, porque os movimentos e decisões são literalmente seus, com variação | Roda no jogo, em GDScript, e começa a funcionar depois de 1 ou 2 partidas |

Um exemplo conhecido do caminho C é o **Drivatar** da série Forza: a corrida copia o estilo de pilotagem dos jogadores para criar pilotos controlados pelo computador.

**Sobre o Godot RL Agents** (biblioteca grátis para a forma A): ele treina em Python e exporta o modelo em ONNX, mas para **rodar o modelo dentro do jogo** é preciso o Godot **.NET** (C#). O Confrontation usa o Godot normal com GDScript. Dá para mudar, mas é uma troca grande só por isso.

---

## 2. O plano recomendado (em etapas)

### Etapa 1: gravador de partidas
Enquanto **você** joga (contra bots ou online), o jogo grava 20 vezes por segundo, num arquivo no seu computador (`user://gravacoes/`):

- onde você está, para onde olha, velocidade, se está agachado, pulando ou deslizando;
- teclas de movimento, tiro, troca de arma, recarga;
- o que você vê: inimigos à vista, distância, vida, se tem parede perto;
- eventos: viu inimigo, atirou, acertou, matou, morreu, de onde veio o tiro.

Uma partida de 10 minutos dá algo como 1 a 2 MB. Fica **só no seu computador**; nada é enviado para a internet.

### Etapa 2: "perfil do jogador" (o bot aprende seus hábitos)
Depois de cada partida, o jogo resume a gravação num **perfil**. Exemplos do que ele aprende:

| Hábito | O que o bot passa a fazer |
|---|---|
| Por qual rota você costuma ir em cada momento da partida | Os bots do seu time escolhem rotas parecidas; os inimigos esperam você lá |
| Onde você para e segura ângulo (mapa de calor) | Bots seguram ângulo nesses mesmos lugares, mirando para onde você mirava |
| Seu tempo de reação e quão rápido você "puxa" a mira | O tempo de reação e a velocidade de mira dos bots seguem os seus (com variação) |
| Quanto tempo você fica indo para cada lado no strafe, se agacha atirando, se pula na quina | O ritmo do strafe dos bots copia o seu |
| Arma por distância (quando você usa sniper, quando saca a pistola) | Bots escolhem arma do mesmo jeito |
| Quando você recua, quando você avança depois de um abate | Bots recuam e avançam em situações parecidas |

Cada número vira uma **faixa com sorteio** (não um valor fixo), então os bots variam o tempo todo. O perfil continua aprendendo a cada partida: as partidas novas pesam mais que as antigas.

### Etapa 3: biblioteca de movimentos (o bot se move como você)
Durante os combates, o jogo guarda **trechos de 1 a 3 segundos** dos seus comandos de movimento (o "ADAD", agachar, pular, deslizar, peek de quina), junto com a situação: distância do inimigo, se tinha cobertura, vida, arma.

Na hora da luta, o bot procura na biblioteca um trecho de uma **situação parecida** e "toca" esse trecho, ajustado para o lugar onde ele está (sem andar para dentro de parede). Assim os movimentos ficam com o seu ritmo, irregulares como os de uma pessoa, e cada luta é diferente. Isso é parecido com a técnica de *motion matching* usada em animação de jogos grandes.

### Etapa 4: contra-tática (os inimigos se adaptam a você)
Os bots **inimigos** usam o mesmo perfil para te **enfrentar**:

- se você sempre entra pelo B, eles começam a esperar no B, ou flanqueiam pelo A enquanto você está lá;
- se você sempre dá peek no mesmo canto, eles pré-miram ali;
- dentro da mesma partida também: se você matou 3 vezes no mesmo lugar, eles evitam esse lugar ou vão em grupo.

Para não ficar injusto, isso respeita a dificuldade (no Fácil eles adaptam pouco) e os bots continuam só sabendo o que veriam ou ouviriam.

### Etapa 5: personalidades
Cada bot mistura o seu perfil com uma **personalidade sorteada**: agressivo (entra primeiro), *lurker* (anda sozinho pelos flancos), sniper (segura linhas longas), suporte (anda junto com o time). Assim nem todos os bots são cópias de você.

### Etapa 6 (opcional, depois): rede neural de verdade
Com várias horas de gravações das etapas anteriores, dá para treinar uma **rede neural pequena** (Python + PyTorch, grátis) que decide **o que fazer** a cada momento (avançar, segurar, recuar, rotacionar, flanquear), copiando suas decisões.

- O treino roda fora do jogo, em minutos, num computador comum.
- A rede é pequena (umas poucas camadas). Os números dela viram um arquivo e o jogo faz a conta em GDScript, sem precisar do Godot .NET.
- Ela **substitui só a parte das decisões**; andar pela malha, ver e atirar continuam com o código atual, que já é seguro.

---

## 3. Riscos e cuidados

| Risco | Como evitar |
|---|---|
| Bot copiando você fica previsível **para você** | Misturar com personalidades, sorteio e com o seu "eu antigo" (partidas anteriores) |
| Aprender hábitos ruins (ex.: você ficou parado no menu) | Ignorar trechos com menu aberto, morto ou parado sem inimigo |
| Bot "roubar" (aprender a mirar através da parede) | Os bots continuam usando a visão atual: só sabem o que veriam ou ouviriam |
| Pouco dado no começo | Até ter dados suficientes, usar os perfis atuais (Fácil/Normal/Difícil) e ir misturando aos poucos |
| Desempenho | Procurar trechos e decidir 10 vezes por segundo, como hoje; a biblioteca fica na memória (poucos MB) |

---

## 4. Quanto trabalho é

Estimativa aproximada, em sessões de trabalho como as feitas até aqui:

| Etapa | Tamanho | Resultado que você percebe |
|---|---|---|
| 1. Gravador | pequena | (nada visível ainda; começa a juntar dados) |
| 2. Perfil do jogador | média | Bots com reação, mira, strafe e rotas parecidos com os seus, variando a cada luta |
| 3. Biblioteca de movimentos | média a grande | Movimento de combate muito mais humano |
| 4. Contra-tática | média | Inimigos que "te conhecem" e mudam de plano |
| 5. Personalidades | pequena | Cada bot com um jeito |
| 6. Rede neural | grande (opcional) | Decisões ainda mais parecidas com as suas |

**Sugestão:** fazer as etapas 1 e 2 juntas como **Fase 13**. Já dá para sentir a diferença depois de duas ou três partidas suas. Depois decidir se vale seguir para a 3 e a 4.

Também dá para incluir no menu um botão **"Bot espelho"**: um bot que joga com o seu perfil, para você enfrentar a si mesmo.

---

## 5. Decisões para você tomar

1. **Começamos pelas etapas 1 e 2 (gravador + perfil)?** É o que recomendo.
2. Os bots devem aprender **só com você** ou também com os amigos nas partidas online? (Cada um grava só no próprio computador; dá para juntar os arquivos depois, se todos quiserem.)
3. Quer o modo **"Bot espelho"** no menu?

Fonte sobre o Godot RL Agents e o Godot .NET: [godot-rl no PyPI](https://pypi.org/project/godot-rl).
