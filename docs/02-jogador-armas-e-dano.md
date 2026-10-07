# Passo 02: Jogador, armas e dano (sala de treino)

**O que foi feito:** as fases 2, 3 e 4 do [roadmap](00-roadmap.md). Já existe uma **sala de treino** onde você anda, atira com as 3 armas e mata bonecos de treino.

---

## 1. Como jogar

1. Abra o projeto no Godot (veja a seção 5 do [passo 01](01-instalacao-das-ferramentas.md)).
2. Aperte **F5** (ou o botão ▶ no canto de cima à direita).

### Controles

| Tecla | Ação |
|---|---|
| W A S D | Andar |
| Shift (segurar) | Correr mais rápido |
| Ctrl ou C (segurar) | Agachar |
| Espaço | Pular |
| Botão esquerdo | Atirar |
| Botão direito | Zoom da sniper |
| R | Recarregar |
| 1 / 2 / 3 ou rodinha do mouse | Fuzil / Pistola / Sniper |
| Esc | Menu (continuar, mira e sensibilidade, sair) |
| F11 | Tela cheia |

### O que testar

- **Pistola (2):** dê 4 tiros no corpo de um boneco. Ele morre no 4º (a vida em cima dele cai 100 → 75 → 50 → 25 → 0).
- **Qualquer arma na cabeça:** 1 tiro mata. O boneco pisca **amarelo**.
- **Sniper (3):** com zoom (botão direito), 1 tiro em qualquer lugar mata. **Sem zoom ela erra muito**, igual no Valorant.
- **Fuzil (1):** segure o botão. Não tem recuo: a mira fica parada enquanto você atira. As balas nunca acabam, só precisa recarregar o pente.
- **Marcador de acerto (o "X" na mira):** branco = corpo, amarelo = cabeça, vermelho = matou.

---

## 2. Como o projeto está organizado

```
jogo/
├── project.godot                 ← configuração do projeto
├── scenes/
│   ├── sala_de_treino.tscn       ← sala de treino
│   ├── player.tscn               ← o jogador
│   └── training_dummy.tscn       ← boneco de treino
├── scripts/
│   ├── autoload/controles.gd     ← teclas do jogo
│   ├── player/player.gd          ← movimento e câmera
│   ├── weapons/weapon_manager.gd ← tiro, troca de arma, recarga, zoom
│   ├── weapons/weapon_data.gd    ← lista de "números" que toda arma tem
│   ├── components/health.gd      ← vida (serve para jogador e boneco)
│   ├── components/hitbox.gd      ← cabeça ou corpo
│   ├── props/training_dummy.gd   ← boneco de treino
│   └── ui/hud.gd                 ← mira, vida, munição, luneta
├── weapons/
│   ├── fuzil.tres                ← números do fuzil
│   ├── pistola.tres              ← números da pistola
│   └── sniper.tres               ← números da sniper
└── materials/grade.gdshader      ← material com grade de 1 metro
```

### Como o tiro funciona (resumo)

1. Quando você atira, sai um **raio invisível** do centro da câmera, em linha reta. Ele acerta na hora (*hitscan*), por isso **a bala não cai**.
2. O raio ganha um desvio aleatório bem pequeno (a **imprecisão** da arma). Ela é a mesma parado ou em movimento. Só a sniper sem zoom erra muito.
3. Se o raio bate numa **hitbox**, o jogo olha se é cabeça (`is_head`) ou corpo e tira a vida:
   - `head_damage` = 100 em todas as armas.
   - `body_damage` = 25 na pistola e no fuzil e 100 na sniper.
4. Se bate numa parede, aparece uma marca de bala.

### Camadas de colisão

| Camada | Nome | Para que serve |
|---|---|---|
| 1 | mundo | Chão, paredes, caixas. Bloqueia movimento **e** tiro |
| 2 | jogadores | Corpo físico dos jogadores. Bloqueia movimento, **não** bloqueia tiro |
| 3 | hitbox | Cabeça e corpo. Só o tiro enxerga |

---

## 3. Como ajustar as coisas (sem programar)

### Mudar os números de uma arma
1. No Godot, no painel **Sistema de Arquivos** (canto de baixo à esquerda), abra a pasta `weapons`.
2. Dê dois cliques em `fuzil.tres`, `pistola.tres` ou `sniper.tres`.
3. No **Inspetor** (direita), mude o que quiser: cadência (`Fire Interval`), pente, recarga, dano, imprecisão...
4. Aperte F5 para testar.

### Mudar velocidade do jogador
1. Abra `scenes/player.tscn`.
2. Clique no nó **Player**.
3. No Inspetor: `Run Speed`, `Walk Speed`, `Jump Velocity`, `Mouse Sensitivity`...

### Mudar a sala de treino ou colocar mais bonecos
1. Abra `scenes/sala_de_treino.tscn`.
2. Para mover uma caixa: clique nela em `Map` e arraste as setas coloridas.
3. Para criar mais bonecos: clique com o botão direito num boneco dentro de `Dummies` → **Duplicar** (Ctrl+D). No Inspetor, `Strafe Distance` maior que 0 faz ele andar de um lado para o outro.

---

## 4. Repositório no GitHub

O projeto está em **https://github.com/dida0982/Confrontation** (público).

- Todo o progresso já está commitado e enviado.
- Os commits seguem o padrão do [CONTRIBUTING.md](../CONTRIBUTING.md), para que outras pessoas consigam entender o histórico.
- Para ver o histórico: `git log --oneline` no PowerShell, dentro da pasta do projeto, ou a aba **Commits** no site do GitHub.
- Se você mudar algo no Godot (por exemplo, os números de uma arma) e quiser salvar:

```
cd "C:\Users\dida0\jogo de fps"
git add .
git commit -m "balance(armas): descreve aqui o que mudou"
git push
```

---

## ✅ Checklist desta etapa

- [ ] O jogo abre com F5
- [ ] Consegui matar boneco com 4 tiros no corpo (pistola/fuzil) e 1 na cabeça
- [ ] Sniper com zoom mata com 1 tiro no corpo
- [ ] A sensação de andar e mirar está boa (se não, ajuste os números da seção 3)
- [x] Projeto publicado no GitHub

## ➡️ Próximo passo

Depois desta etapa entraram o mata-mata em equipe, a munição infinita, a corrida no Shift e a remoção do recuo. Continue em [03-mata-mata-em-equipe.md](03-mata-mata-em-equipe.md).
