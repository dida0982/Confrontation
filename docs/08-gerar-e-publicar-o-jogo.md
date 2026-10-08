# Passo 08: Gerar o jogo (.exe) e publicar para os amigos

**O que foi feito:** o jogo virou um programa normal do Windows, o `Confrontation.exe`, e o primeiro download está publicado no GitHub.

🔗 **Link para mandar aos amigos:** <https://github.com/dida0982/Confrontation/releases/latest>

---

## 1. Como os amigos entram na partida

1. **Baixar o jogo** pelo link acima: o arquivo `Confrontation-v0.1.0-windows.zip`, em **Assets**.
2. **Extrair** o `.zip` e abrir o `Confrontation.exe`. Não precisa instalar o Godot nem mais nada.
   - Se aparecer **"O Windows protegeu o computador"**, clique em **Mais informações → Executar assim mesmo**. Esse aviso aparece porque o jogo não tem uma assinatura digital (que é paga). Não é vírus.
3. **Ficar na mesma rede que o host:**
   - mesma casa/Wi-Fi: nada a fazer;
   - pela internet: todos instalam o **[Radmin VPN](https://www.radmin-vpn.com/)** (grátis) e entram na rede que o host criou nele.
4. O host clica em **Criar partida** e manda o **IP** dele (o da sala, ou o do Radmin, que começa com `26.`).
5. Os amigos clicam em **Entrar em partida**, digitam o IP e esperam na sala.
6. O host clica em **Começar partida**.

O passo a passo também vai dentro do `.zip`, no arquivo **LEIA-ME.txt** (o original fica em [distribuicao/LEIA-ME.txt](../distribuicao/LEIA-ME.txt)).

> **Todos precisam da mesma versão do jogo.** Quando sair uma versão nova, todo mundo baixa de novo.

---

## 2. Como gerar uma versão nova (para quem desenvolve)

### Uma vez só: instalar os "modelos de exportação"

O Godot precisa dos **modelos de exportação** (*export templates*) para montar o `.exe`. Eles são grátis:

1. No Godot: **Editor → Gerenciar modelos de exportação...**
2. Clique em **Baixar e instalar**.

(Neste computador eles já foram instalados, só a parte do Windows, em `%APPDATA%\Godot\export_templates\4.7.2.stable\`.)

### Gerar o .exe

**Pelo Godot (mais fácil):**
1. **Projeto → Exportar...**
2. Escolha o preset **Windows** (já está configurado no arquivo `jogo/export_presets.cfg`).
3. Clique em **Exportar projeto**, desmarque **Exportar com depuração** e salve em `builds/Confrontation/Confrontation.exe`.

**Pela linha de comando:**
```
cd "C:\Users\dida0\jogo de fps\jogo"
Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Windows" ../builds/Confrontation/Confrontation.exe
```

O resultado é **um único arquivo** `Confrontation.exe` (uns 105 MB) com tudo dentro. A pasta `builds/` **não vai para o Git**, porque é arquivo gerado e grande.

### Publicar no GitHub

1. Suba o número da versão em `jogo/project.godot` (`config/version`, ex.: `0.2.0`) e faça o commit.
2. Gere o `.exe` (acima).
3. Copie o [distribuicao/LEIA-ME.txt](../distribuicao/LEIA-ME.txt) para `builds/Confrontation/` (atualize a versão no texto).
4. Compacte a pasta `builds/Confrontation` em `Confrontation-vX.Y.Z-windows.zip`.
5. No GitHub: **Releases → Draft a new release**, crie a tag `vX.Y.Z`, escreva o que mudou e anexe o `.zip`.
   - Ou pelo terminal: `gh release create vX.Y.Z builds/Confrontation-vX.Y.Z-windows.zip --title "Confrontation X.Y.Z" --notes "o que mudou"`

### Números de versão

Usamos **MAIOR.MENOR.CORREÇÃO** (ex.: `0.1.0`):
- **CORREÇÃO** (`0.1.0 → 0.1.1`): só correção de bugs;
- **MENOR** (`0.1.0 → 0.2.0`): coisa nova (ex.: chat de voz);
- **MAIOR** (`0.x → 1.0.0`): quando o jogo estiver "pronto" para o público.

Enquanto for `0.x`, o jogo está em desenvolvimento.

---

## 3. Próximos passos possíveis para convidar amigos

| Melhoria | O que muda | Custo |
|---|---|---|
| **Código de sala** (ex.: `ABC123`) | Não precisa de Radmin VPN nem de IP | Precisa de um pequeno servidor na internet (existem opções grátis com limite) |
| **Atualização automática** | O jogo avisa quando sai versão nova | Grátis (consulta o GitHub Releases) |
| **Publicar no itch.io** | Página bonita do jogo, download fácil | Grátis |

## ➡️ Próximo passo: Fase 8, chat de voz por proximidade

Continua o plano: veja o [roadmap](00-roadmap.md). Vai ser criado o arquivo `docs/09-chat-de-voz.md`.
