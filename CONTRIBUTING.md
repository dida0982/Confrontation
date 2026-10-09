# Como contribuir com o Confrontation

Obrigado por ajudar! Este guia explica como o projeto é organizado e como escrever commits para que toda a equipe entenda o histórico.

## Antes de começar

1. Leia o [README.md](README.md) (ideia e regras do jogo).
2. Veja em [docs/00-roadmap.md](docs/00-roadmap.md) em qual fase estamos.
3. Leia o arquivo `docs/` da fase atual: ele explica o que já existe e qual é o próximo passo.
4. Use o **Godot 4.7** (versão padrão, não a .NET). Abra o arquivo `jogo/project.godot`.

## Fluxo de trabalho

- A branch principal é `main`. Ela deve sempre abrir e rodar sem erros (F5 no Godot).
- Para tarefas maiores, crie uma branch: `feat/nome-curto`, `fix/nome-curto` ou `docs/nome-curto`.
- Faça commits pequenos, cada um com **uma única mudança lógica**.
- Ao terminar uma fase ou tarefa, atualize o roadmap e o arquivo `docs/` correspondente.
- **Antes de commitar, rode os testes automáticos** (levam cerca de 1 minuto, sem abrir janela):
  ```
  Godot_v4.7.2-stable_win64_console.exe --headless --path jogo -s res://testes/rodar_testes.gd
  ```
  Tem que aparecer `TUDO CERTO`. Mudou uma regra do jogo? Atualize ou crie o teste em `jogo/testes/testes.gd`.

## Padrão de commits

Usamos o padrão [Conventional Commits](https://www.conventionalcommits.org/pt-br/), escrito em **português**.

```
<tipo>(<escopo>): <resumo no imperativo, minúsculo, sem ponto final>

<corpo opcional: o QUE mudou e POR QUE, quebrando linha em ~72 caracteres>
```

### Tipos

| Tipo | Quando usar |
|---|---|
| `feat` | Nova funcionalidade no jogo |
| `fix` | Correção de bug |
| `refactor` | Mudança no código que não altera o comportamento |
| `perf` | Melhoria de desempenho |
| `balance` | Ajuste de números de jogo (dano, velocidade, cadência...) |
| `art` | Modelos, texturas, materiais, iluminação |
| `audio` | Sons e música |
| `docs` | Documentação (README, docs/, comentários) |
| `test` | Testes |
| `chore` | Configuração, ferramentas, arquivos do repositório |

### Escopos usados no projeto

`jogador`, `armas`, `combate`, `mapa`, `partida`, `rede`, `voz`, `hud`, `menu`, `treino`, `projeto`

### Exemplos

```
feat(armas): adiciona zoom da sniper no botão direito
fix(jogador): impede levantar quando há teto acima da cabeça
balance(armas): reduz recuo do fuzil de 0.6 para 0.5 graus por tiro
docs(roadmap): marca fase 5 como concluída
```

### Regras rápidas

- Resumo com no máximo ~72 caracteres.
- Verbo no presente: "adiciona", "corrige", "remove", "ajusta" (não "adicionado" ou "adicionei").
- Explique o **porquê** no corpo quando não for óbvio.
- Não misture assuntos: ajuste de arma e mudança de mapa vão em commits separados.

## Recursos (modelos, texturas, sons, fontes)

- Use só recursos **gratuitos** com licença que permita usar no jogo (de preferência **CC0**).
- **Nunca** use arquivos tirados de outros jogos (ex.: modelos ou mapas do Valorant).
- Todo recurso novo entra no [CREDITOS.md](CREDITOS.md) com autor, licença e link. Se a licença exigir crédito (CC-BY), coloque também na tela de créditos (`scripts/ui/main_menu.gd`).

## Estilo de código (GDScript)

- Siga o [guia de estilo oficial do GDScript](https://docs.godotengine.org/pt-br/4.x/tutorials/scripting/gdscript/gdscript_styleguide.html).
- Identificadores (variáveis, funções, nós) em inglês. Comentários e textos de interface em português.
- Use tipos estáticos (`var speed: float`, `:=`) sempre que possível.
- Números de gameplay devem ser `@export` para poderem ser ajustados no Inspetor.
