# Passo 09: Chat de voz por proximidade

**O que foi feito:** a Fase 8 do [roadmap](00-roadmap.md). Você fala no microfone e quem está **perto do seu boneco** ouve, inclusive os **inimigos**. Quanto mais longe, mais baixo. Atrás de parede, a voz fica abafada.

---

## 1. Como usar

| O quê | Como |
|---|---|
| **Falar** | Segure **V** |
| **Voz aberta** (sem apertar nada) | **Esc → Voz → Voz aberta** |
| Ver se está transmitindo | Aparece **"● Transmitindo sua voz"** acima da ajuda de controles |
| Ver quem está falando | O nome aparece na mesma área, e o boneco dele mostra **FALANDO** em cima da cabeça |

### Regras

| Regra | Valor |
|---|---|
| Alcance | **25 metros**. Mais longe que isso não se ouve nada |
| Volume | Cai com a distância (perto = alto, longe = baixo) |
| Paredes | Atrás de parede a voz fica **abafada** e mais baixa |
| Quem ouve | **Todos que estão perto**, aliados **e inimigos**. Cuidado com o que fala perto do inimigo! |
| Mortos | Não falam (mas continuam ouvindo) |

---

## 2. Configurações (Esc → Voz)

| Opção | O que faz |
|---|---|
| **Segurar V / Voz aberta** | Com "voz aberta" o jogo transmite sozinho quando você fala |
| **Volume das vozes dos outros** | De 0% a 200% |
| **Microfone** | Escolha qual microfone usar (ex.: o do headset) |
| **Teste do microfone** | Uma barra que mexe quando você fala. Se não mexer, o microfone está errado ou bloqueado |
| **Voz aberta: volume mínimo** | Abaixo desse volume o jogo não transmite (evita mandar barulho de fundo). Só aparece na voz aberta |

Tudo fica salvo no computador.

**Dica:** use **fone de ouvido**. Com caixa de som, o microfone pode pegar a voz dos outros e fazer eco.

### Se ninguém te ouve

1. Veja se a barra do **Teste do microfone** mexe quando você fala.
2. Se não mexer: troque o **Microfone** na lista.
3. Ainda não mexe? No Windows: **Configurações → Privacidade e segurança → Microfone** e deixe **"Permitir que aplicativos da área de trabalho acessem o microfone"** ligado.

---

## 3. Como funciona (para quem for programar)

Tudo é feito com o que já vem no Godot (sem addon, sem custo):

1. **Captura:** o microfone (`AudioStreamMicrophone`) toca num bus de áudio **mudo** chamado `Microfone`, que tem um efeito `AudioEffectCapture`. O script lê o som gravado desse efeito.
2. **Compressão:** o som vira **mono, 16 kHz**, e cada amostra é comprimida em **1 byte (μ-law)**, o mesmo jeito do telefone. São pacotes de **40 ms**, cerca de **16 KB/s** por pessoa falando.
3. **Rede:** o pacote vai para o **host**. O host repassa **só para quem está a até 30 m** de quem falou (25 m de alcance + folga), usando um canal separado da rede (canal 1, não confiável e ordenado: se um pacote se perder, não trava o resto).
4. **Reprodução:** quem recebe toca a voz no nó **Voz** (`AudioStreamPlayer3D`) do boneco de quem falou. O próprio Godot faz o volume cair com a distância. A cada 0,2 s o jogo confere se tem parede no meio e, se tiver, abafa o som.

| Arquivo | O que faz |
|---|---|
| `scripts/autoload/voz.gd` | Todo o chat de voz (captura, compressão, envio, reprodução, paredes) |
| `scenes/player.tscn` | Nós **Voz** (de onde sai a voz) e **FalandoLabel** (aviso em cima da cabeça) |
| `scripts/ui/pause_menu.gd` | Página **Voz** do menu |
| `scripts/autoload/configuracoes.gd` | Salva modo, volume, sensibilidade e microfone |

### Ajustes rápidos

| O que | Onde |
|---|---|
| Alcance da voz | `voz.gd` → `RANGE` e, em `player.tscn`, nó **Voz** → `Max Distance` (os dois iguais) |
| Quão rápido o volume cai | `player.tscn` → nó **Voz** → `Unit Size` (maior = alto até mais longe) |
| Quanto a parede abafa | `voz.gd` → `_update_occlusion()` |

### Limitações conhecidas

- A compressão μ-law é simples. A voz fica com qualidade de telefone e usa mais internet do que o Opus (usado em jogos grandes). Dá para trocar no futuro por um addon de Opus.
- Ainda não dá para **silenciar um jogador** específico.
- Não tem chat de voz **só do time** (rádio). Hoje é só proximidade.

---

## 4. Testes que foram feitos

- [x] Compressão μ-law: ida e volta com erro máximo de 1,5% (imperceptível para voz)
- [x] Duas cópias do jogo: o host ouve o cliente a 14 m e **não** ouve a 60 m
- [x] O cliente ouve o host
- [x] Quem está morto não transmite
- [x] O microfone real é encontrado e lido (testado com o headset HyperX deste computador)

O teste com duas pessoas conversando de verdade fica com você.

## ✅ Checklist para você

- [ ] Esc → Voz: a barra do teste do microfone mexe quando eu falo
- [ ] Com um amigo (ou 2 janelas): segurando V, ele me ouve; longe, não ouve
- [ ] Atrás de uma parede a voz fica abafada

## ➡️ Próximo passo

Pelo [roadmap](00-roadmap.md), as próximas fases são:
- **Fase 9, interface:** tela inicial mais bonita, configurações de vídeo e áudio, mira com cor e tamanho;
- **Fase 10, arte e som:** modelos de personagem e armas, texturas e **sons de tiro e passos**.

Para os amigos terem o chat de voz, é preciso **gerar e publicar a versão 0.2.0** (veja [08-gerar-e-publicar-o-jogo.md](08-gerar-e-publicar-o-jogo.md)).
