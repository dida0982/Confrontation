# Passo 12: Polimento, correção de bugs e testes

**O que foi feito:** a Fase 12 do [roadmap](00-roadmap.md): medir o desempenho, corrigir bugs e criar **testes automáticos** que conferem as regras do jogo sozinhos.

---

## 1. Desempenho medido

Partida contra bots (10 bonecos na tela), janela 1280x720, sem VSync, neste computador:

| Medida | Resultado |
|---|---|
| FPS médio | **~500** |
| Pior quadro em 6 s | 11 ms |
| Chamadas de desenho (*draw calls*) | ~480 por quadro |
| Objetos na tela | ~950 |

O jogo está bem leve. Os bots custam pouco porque "olham" só 10 vezes por segundo (e não a cada quadro) e usam poucos raios de visão.

**Otimização feita:** o teste "dá para levantar?" (quando o jogador está agachado) criava uma forma nova **128 vezes por segundo**. Com bots agachando, isso se multiplicava. Agora ele reaproveita a mesma consulta.

**Dica para computador fraco** (continua valendo): em Configurações → Vídeo, desligue as sombras e baixe a qualidade da imagem 3D para 70%.

---

## 2. Bugs corrigidos

| Bug | Correção |
|---|---|
| Bots ficavam parados nos primeiros instantes da partida: o jogo achava que a malha de navegação estava pronta antes de ela entrar no mapa | Os bots só começam quando o mapa de navegação já responde com um ponto da malha |
| Ao fechar o jogo, o microfone do chat de voz ficava preso na memória (aviso "ObjectDB instances were leaked") | O microfone é desligado ao sair |
| Abrir o menu (Esc) segurando Ctrl fazia o jogador levantar | O agachar continua valendo com o menu aberto |
| Um teste descartável com um caminho fixo de um computador estava no Git | Saiu do Git; a pasta `jogo/tests_tmp/` agora é ignorada |

---

## 3. Testes automáticos

Ficam em `jogo/testes/`. Rodam **sem abrir janela**, em cerca de **1 minuto**:

```
cd "C:\Users\dida0\jogo de fps"
Godot_v4.7.2-stable_win64_console.exe --headless --path jogo -s res://testes/rodar_testes.gd
```

Resultado esperado:

```
OK      nomes
OK      bots_por_time
OK      dano
OK      tiro_de_verdade
OK      protecao_de_nascimento
OK      rotas_dos_bots
OK      partida_com_bots
OK      fim_de_partida

TUDO CERTO  (0 falha(s), 60.0 s)
```

| Teste | O que confere |
|---|---|
| `nomes` | Nome vazio vira "Jogador", nome comprido é cortado, colchetes saem (eles quebrariam o feed de abates) |
| `bots_por_time` | Quantos bots entram para completar 5 contra 5 |
| `dano` | Corpo: 3 tiros deixam 25 de vida e o 4º mata. Cabeça mata. O abate conta ponto para o time |
| `tiro_de_verdade` | Atira de verdade (raio saindo da câmera) num boneco de treino: fuzil no peito tira 25, na cabeça mata; o boneco renasce; sniper no corpo mata |
| `protecao_de_nascimento` | Com proteção não leva dano; sem proteção leva |
| `rotas_dos_bots` | Todos os pontos das rotas A, Meio e B e todos os pontos de nascimento ficam em chão onde dá para andar |
| `partida_com_bots` | 45 s de partida só com bots: os 9 bots andam, lutam (5+ abates), **nenhum fica parado mais de 6 s fora de combate** e o placar bate com os abates |
| `fim_de_partida` | Com limite de 3 abates, a partida acaba, o vencedor tem 3 e ninguém se mexe depois |

Para rodar só alguns, coloque os nomes depois de `--`:
```
... -s res://testes/rodar_testes.gd -- dano tiro_de_verdade
```

O programa sai com o **número de falhas** (0 = tudo certo). Os testes **não vão para o `.exe`** (filtro `testes/*` em `export_presets.cfg`).

**Regra para a equipe** (está no [CONTRIBUTING.md](../CONTRIBUTING.md)): rode os testes antes de commitar. Mudou uma regra do jogo (ex.: dano)? Atualize o teste em `jogo/testes/testes.gd`.

> Por que dois arquivos? Um script rodado com `-s` é compilado **antes** dos autoloads (`Rede`, `Configuracoes`...). Então `rodar_testes.gd` só carrega o `testes.gd` depois que eles já existem.

---

## 4. O que ainda falta na Fase 12

- [ ] **Testes com pessoas de verdade:** jogar com amigos (online e contra bots) e anotar bugs e sensação de jogo
- [ ] Publicar a próxima versão com os bots (0.3.0) seguindo [08-gerar-e-publicar-o-jogo.md](08-gerar-e-publicar-o-jogo.md)
- [ ] (Opcional) Página no itch.io

## ➡️ Próximo passo

Estudo de bots que aprendem com o seu jeito de jogar: [13-estudo-bots-que-aprendem.md](13-estudo-bots-que-aprendem.md).
