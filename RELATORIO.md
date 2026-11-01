# Secret Agent Man â€” RelatÃ³rio de desenvolvimento

Jogo arcade para **PICO-8** feito a partir de [conceitos.md](conceitos.md) e da imagem `tilesets concepts.jfif`.

- Cartucho: [secretagentman.p8](secretagentman.p8) (abre no PICO-8: `load secretagentman.p8` â†’ `run`)
- VersÃ£o web: [web/index.html](web/index.html) (exportada pelo prÃ³prio PICO-8; abre no navegador)
- Fontes editÃ¡veis: pasta [fontes/](fontes/) â€” o cartucho Ã© **gerado** a partir dela por `python tools/build.py`

![tÃ­tulo](docs/screenshots/title.png) ![aÃ§Ã£o](docs/screenshots/enemies.png) ![luz apagada](docs/screenshots/dark.png)

---

## 1. O que foi implementado

### Tela inicial
- TÃ­tulo "SECRET AGENT / MAN" em fonte larga.
- Abertura no estilo *gun barrel*: bolinhas brancas atravessam a tela, a Ãºltima vira o cano da arma (cÃ­rculo com raias girando), o agente entra andando, vira de frente apontando o revÃ³lver para o jogador â€” **quebrando a quarta parede** â€” e dispara (clarÃ£o + som).
- "PUSH BUTTON TO START" piscando; ao apertar, a mensagem pisca rÃ¡pido por 1 s e o jogo comeÃ§a.
- Mostra o hi-score salvo (persistente via `cartdata`).

### Jogo
| Elemento | Como ficou |
|---|---|
| **PrÃ©dio** | Telhado + 12 andares (256 px de largura Ã— 416 px de altura), scroll horizontal e vertical com cÃ¢mera suave. HUD fixo no topo. |
| **Entrada** | SequÃªncia especial do concept: o agente desce de **paraquedas** (canopy com a bandeira britÃ¢nica) atÃ© o telhado. |
| **Elevadores** | 4 poÃ§os com faixas de andares diferentes (1â€“5, 3â€“8, 5â€“10, 8â€“12), obrigando a combinar elevadores e escadas. Fora do controle do jogador, a cabine anda sozinha entre andares aleatÃ³rios. **Dentro** dela o jogador controla com â¬†ï¸/â¬‡ï¸ (para em cada andar, continua se o botÃ£o estiver segurado). DÃ¡ para **subir no teto** da cabine quando ele estÃ¡ nivelado com o andar. Placas acima de cada porta de elevador mostram o nÃºmero do andar e acendem em vermelho quando a cabine estÃ¡ ali. |
| **Queda no poÃ§o** | Entrar no poÃ§o sem a cabine faz cair; queda de mais de ~1 andar (40 px) **mata**. |
| **Esmagamento** | Quem estÃ¡ no teto da cabine Ã© esmagado ao chegar no topo do poÃ§o; quem estÃ¡ no fundo do poÃ§o (andar mais baixo) Ã© esmagado pela cabine descendo. |
| **Escadas rolantes** | 7 escadas ligando pares de andares (inclusive telhado â†’ 12Âº). â¬‡ï¸ no topo desce, â¬†ï¸ na base sobe. |
| **Portas vermelhas** | 6 portas com os planos. â¬†ï¸ em frente: a porta abre, o agente entra, a porta fecha (nunca se vÃª a sala), abre de novo e ele sai com os planos. A porta passa a ser azul como as outras. |
| **Inimigos** | Agentes de chapÃ©u e capote pretos saem das portas azuis perto do jogador. Seguem **as mesmas regras de movimento** (cÃ³digo compartilhado `act()`): usam elevadores (por dentro e pelo teto), escadas rolantes, caem nos poÃ§os e sÃ£o esmagados. A maioria evita poÃ§o aberto, mas ~15% sÃ£o "descuidados". Atiram quando estÃ£o no mesmo andar e a uma distÃ¢ncia de atÃ© 100 px (40 px no escuro). |
| **Tiros e abaixar** | Os tiros dos inimigos saem na altura do peito; **abaixado** (â¬‡ï¸), o jogador fica com 12 px de altura e os tiros passam por cima. Os inimigos nÃ£o se abaixam. |
| **Lustres** | Dois por andar. O tiro normal passa por baixo; **pulando e atirando**, o tiro acerta o lustre, que quebra e **apaga a luz do andar**. |
| **EscuridÃ£o** | Andar sem luz Ã© desenhado com uma paleta escura (cenÃ¡rio **e** sprites, por remapeamento de cores na memÃ³ria de vÃ­deo). Se o jogador estÃ¡ num andar escuro, a tela inteira fica escura; ao chegar num andar iluminado, volta ao normal. |
| **HUD** | Placar, hi-score, Ã­cone de pasta com planos coletados (x/6) e vidas como cabeÃ§as do agente. |
| **Fim da fase** | Com todos os planos: "ALL PLANS! ESCAPE VIA LOBBY!". No tÃ©rreo, a saÃ­da Ã  direita (antes bloqueada) libera; o agente sai para a rua, entra na **caranga verde** e vai embora acelerando. "MISSION COMPLETE!" + bÃ´nus de 1000 Ã— nÃ­vel. |
| **ProgressÃ£o** | Cada missÃ£o seguinte aumenta a velocidade, o nÃºmero mÃ¡ximo e a cadÃªncia de tiro dos inimigos. 3 vidas; game over volta para a tela inicial. |

**Controles:** â¬…ï¸âž¡ï¸ andar Â· â¬‡ï¸ abaixar / descer escada / descer elevador Â· â¬†ï¸ entrar na porta vermelha / subir escada / subir elevador Â· **Z (ðŸ…¾ï¸)** atirar Â· **X (âŽ)** pular. No menu de pausa (Enter) hÃ¡ a opÃ§Ã£o "music on/off".

**PontuaÃ§Ã£o:** inimigo baleado 100 Â· inimigo esmagado/caÃ­do 300 Â· planos 500 Â· lustre 50 Â· bÃ´nus de missÃ£o 1000 Ã— nÃ­vel.

### MÃºsica e sons
- **Tema original** no estilo surf/espionagem dos anos 60: baixo em ostinato de blues em Mi (com a 5Âª diminuta, tÃ­pico do gÃªnero), bateria surf (bumbo, caixa, chimbal) e guitarra solo em onda *pulse* com vibrato, alÃ©m de um trecho de *tremolo picking* de surf. Estrutura: intro â†’ tema â†’ break de tremolo â†’ IV grau â†’ tema â†’ turnaround com virada de caixa, em loop. Usa 3 canais; o 4Âº fica livre para os efeitos. A composiÃ§Ã£o Ã© original (nÃ£o copia as melodias de Secret Agent Man, Peter Gunn nem do tema de Bond).
- 14 efeitos: tiro do jogador/inimigo, inimigo abatido, morte, coleta de planos, vidro do lustre, "ding" do elevador, pulo, start, esmagamento, motor do carro, jingle de missÃ£o, porta e game over.

### Arte (adaptaÃ§Ã£o do concept para o PICO-8)
- Personagens em sprites **16Ã—24** (2Ã—3 tiles), grandes como pedia o concept, aproveitando o scroll. Estilo flat, poucas cores: smoking preto com camisa branca e gravata-borboleta, cabelo castanho; inimigos com chapÃ©u de aba e faixa cinza, Ã³culos escuros, capote com cinto.
- Quadros do agente: parado, 2 de caminhada, tiro, abaixado, tiro abaixado, pulo, tiro no pulo, morto e **de frente apontando** (usado em 2Ã— na abertura). Inimigos: parado, 2 de caminhada, tiro e morto.
- Ãcone de vida, pasta dos planos, canopy do paraquedas e carro (32Ã—16).
- O prÃ©dio (paredes azuis, lajes cinza, portas azuis/vermelhas com batente, poÃ§os, cabines lilÃ¡s, lustres, escadas rolantes, telhado com antena, casa de mÃ¡quinas e casinha da escada, rua com calÃ§ada e skyline) Ã© **desenhado por cÃ³digo** em vez de tiles do mapa. Assim sobra a sprite sheet inteira para os personagens e o prÃ©dio pode ser mais largo/alto do que caberia no mapa.
- A versÃ£o "escura" dos tiles e sprites vem de uma tabela de cores (`dm`) aplicada Ã s linhas da tela dos andares apagados, o que dispensa uma segunda cÃ³pia dos sprites.

---

## 2. Estrutura dos arquivos

```
secretagentman.p8          cartucho final (gerado)
web/index.html, index.js   versÃ£o jogÃ¡vel no navegador (gerada pelo PICO-8)
fontes/
  lua/game.lua             todo o cÃ³digo do jogo (~4.900 de 8.192 tokens)
  sprites/player.txt       sprites do agente (pixel art em ASCII)
  sprites/enemy.txt        sprites dos inimigos
  sprites/items.txt        vida, pasta, paraquedas, carro
  sprites/spritesheet.png  prÃ©via da sprite sheet (gerada a cada build)
  audio/audio.py           efeitos sonoros e mÃºsica (notas em texto)
  label.txt                imagem do label do cartucho
tools/build.py             monta o .p8 a partir de fontes/
docs/screenshots/          capturas
```

**Fluxo de ediÃ§Ã£o:** editar `fontes/...` â†’ `python tools/build.py` â†’ abrir `secretagentman.p8` no PICO-8. Para refazer a versÃ£o web: `pico8 -x secretagentman.p8 -export web/index.html`.

Nos `.txt` de sprites, cada bloco comeÃ§a com `@ x y nome` (posiÃ§Ã£o na sheet 128Ã—128); `.` Ã© transparente e `0`â€“`f` sÃ£o as cores do PICO-8. AtenÃ§Ã£o: se vocÃª editar sprites **dentro** do editor do PICO-8 e salvar, as mudanÃ§as ficam sÃ³ no `.p8` e serÃ£o sobrescritas no prÃ³ximo build. Edite pelos `.txt` ou copie as mudanÃ§as de volta.

## 3. Como foi testado
- ExecuÃ§Ã£o *headless* do PICO-8 (`pico8 -x`) com um script que simula o controle: tela inicial, paraquedas, escada rolante, elevador, inimigos, quebra de lustre, porta vermelha, fuga de carro e 3.000 frames de entradas aleatÃ³rias. Rodou **sem erros**, e as capturas da tela (em `docs/screenshots/`) foram conferidas visualmente.
- Bugs encontrados e corrigidos nesse processo: corpo flutuando quando o personagem morria dentro do elevador em movimento, skyline alto demais, texto de ajuda cortado e inimigos chegando ao telhado no exato momento do pouso (foi adicionado um tempo de carÃªncia).
- **Ainda nÃ£o testado:** jogar de verdade com teclado/controle. O equilÃ­brio de dificuldade (velocidade dos inimigos, cadÃªncia dos tiros, frequÃªncia de surgimento) precisa ser ajustado jogando.

---

## 4. ImplementaÃ§Ãµes e alteraÃ§Ãµes futuras

### Prioridade alta (jogabilidade)
1. **Balanceamento jogando de verdade:** cadÃªncia de tiro, velocidade dos inimigos e `spt` (intervalo de surgimento). Hoje os valores sÃ£o estimativas.
2. **Invencibilidade breve ao renascer** (piscando por ~2 s) e renascer longe de inimigos.
3. **IA dos inimigos usando o elevador de propÃ³sito** para perseguir o jogador entre andares (hoje eles sÃ³ usam quando passam por um, e as escadas sÃ³ quando estÃ£o indo na direÃ§Ã£o do jogador).
4. **Inimigos que tambÃ©m se abaixam ou atiram baixo** em nÃ­veis mais altos, para o jogador nÃ£o ficar seguro sÃ³ abaixando (o concept diz que os inimigos nÃ£o se abaixam; avaliar).
5. **Chute/ataque corpo a corpo** e pulo sobre inimigos, como alternativa ao tiro.
6. Tiros dos inimigos acertando lustres (apagÃµes "acidentais").

### ConteÃºdo
7. **VÃ¡rios prÃ©dios/layouts** por fase (hoje o layout Ã© fixo, sÃ³ a dificuldade muda). DÃ¡ para gerar o layout a partir de uma tabela por fase ou proceduralmente (o cÃ³digo jÃ¡ lÃª as listas `shafts`, `escs` e `doors`).
8. **Itens extras do concept:** relÃ³gio, colar, cartÃ£o de acesso, maleta, extintor e vasos de planta como decoraÃ§Ã£o ou bÃ´nus de pontos; arma extra com mais muniÃ§Ã£o.
9. **Placas de andar estilo concept** (28/27/26) em vez de 12â€¦1, com prÃ©dios mais altos.
10. **Janelas com vista da cidade** e mÃ³veis (mesa, cofre, planta), como no tileset do concept, desenhados ao fundo.
11. Vida extra a cada 10.000 pontos.
12. Tela de ranking (top 5) usando mais slots do `cartdata`.

### Arte e animaÃ§Ã£o
13. AnimaÃ§Ã£o de **queda** (braÃ§os para cima) e de **esmagamento** prÃ³pria; inimigo caindo de costas com o chapÃ©u voando.
14. AnimaÃ§Ã£o do agente **entrando no carro** e porta do carro abrindo; fumaÃ§a do escapamento.
15. Portas do elevador abrindo/fechando (hoje a cabine Ã© aberta).
16. Brilho/cone de luz sob os lustres e cacos de vidro caindo ao quebrar.
17. PartÃ­culas de faÃ­sca no impacto das balas e cartucho ejetado.
18. IlustraÃ§Ã£o mais detalhada na abertura (efeito de sangue escorrendo/vinheta vermelha) e transiÃ§Ã£o para o paraquedas.

### Som
19. Uma segunda mÃºsica para o andar escuro (tensa, sÃ³ baixo e chimbal) e um jingle curto de "mission complete" com a mÃºsica completa.
20. Passos e som de escada rolante; som do motor do elevador em loop baixo.

### TÃ©cnico
21. Otimizar `darken()` (hoje faz `peek/poke` byte a byte; dÃ¡ para usar `memcpy` com uma tela prÃ©-escurecida ou `pal()` por regiÃ£o com `clip()`).
22. Suporte a 60 fps (`_update60`) ajustando velocidades.
23. Rodar o teste automatizado (`tools/test_harness.lua` + `tools/dump2png.py`, usados no desenvolvimento) num CI, com um script Ãºnico que cole o harness no cartucho e gere as capturas.
24. Publicar a versÃ£o web via GitHub Pages (a pasta `web/` jÃ¡ estÃ¡ pronta).
