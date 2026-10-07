# Passo 01: Instalação das ferramentas

**Objetivo desta etapa:** deixar o computador pronto e criar o projeto vazio do Godot.
**Tempo estimado:** 30 a 60 minutos.

Por enquanto só precisa de **3 programas**: Godot, Git e (opcional agora) Blender. O resto instala quando chegar na fase de arte.

---

## 1. Instalar o Godot 4

1. Acesse https://godotengine.org/download/windows/
2. Baixe a versão **Godot Engine** padrão (a mais recente 4.x estável). **Não** precisa da versão ".NET / C#", vamos usar GDScript.
3. O Godot não tem instalador: ele vem num `.zip`. Extraia, por exemplo, em `C:\Godot\`.
4. Abra o arquivo `Godot_v4.x-stable_win64.exe`.
   - Dica: clique com o botão direito no `.exe` → "Mostrar mais opções" → "Enviar para" → "Área de trabalho (criar atalho)".

## 2. Instalar o Git

1. Acesse https://git-scm.com/download/win e baixe o instalador.
2. Instale clicando em "Next" em tudo (as opções padrão estão boas).
3. Para conferir, abra o PowerShell e digite:
   ```
   git --version
   ```
   Deve aparecer algo como `git version 2.x.x`.
4. Configure seu nome e e-mail (só precisa fazer uma vez):
   ```
   git config --global user.name "Seu Nome"
   git config --global user.email "seu@email.com"
   ```

## 3. Criar uma conta no GitHub (opcional, mas recomendado)

1. Acesse https://github.com/ e crie uma conta grátis.
2. Serve como **backup na nuvem** do projeto. Se o computador estragar, o jogo não se perde.

## 4. Instalar o Blender (pode deixar para depois)

1. Acesse https://www.blender.org/download/ e instale.
2. Só vamos usar de verdade na Fase 9 (arte). Na fase do mapa vamos montar tudo com blocos dentro do próprio Godot.

---

## 5. Abrir o projeto no Godot

> ✅ **Já feito:** o projeto foi criado na pasta `jogo/`. Você só precisa abrir.

1. Abra o Godot (`Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`).
   - Dica: mova a pasta do Godot para `C:\Godot\` e crie um atalho na Área de Trabalho.
2. No **Gerenciador de Projetos**, clique em **"Importar"**.
3. Escolha o arquivo `C:\Users\dida0\jogo de fps\jogo\project.godot`.
4. Clique em **"Importar e Editar"**.
5. Aperte **F5** para jogar.

## 6. Git e GitHub

> ✅ **Já feito:** o repositório público está em https://github.com/dida0982/Confrontation.

Para outra pessoa (ou outro computador) baixar o projeto:

```
git clone https://github.com/dida0982/Confrontation.git
```

O padrão de commits está no [CONTRIBUTING.md](../CONTRIBUTING.md).

---

## ✅ Checklist desta etapa

- [x] Godot baixado
- [x] `git --version` funciona no PowerShell
- [x] Projeto criado dentro de `jogo de fps\jogo`
- [ ] Projeto importado no Godot e rodando com F5
- [x] Repositório publicado no GitHub

**Próximo passo:** [02-jogador-armas-e-dano.md](02-jogador-armas-e-dano.md)
