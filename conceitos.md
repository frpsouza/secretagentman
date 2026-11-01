# Secret Agent Man



Jogo estilo arcade  em que um agente secreto invade um predio e se move por elevadores, entrando em salas com items para pegar e enfrentando outros agentes que cuidam do predio.

use as imagens tileset concepts para criar os sprites e tiles para o jogo. Faça as adaptações necessárias para ficar bem na resolucao e limitações do Pico-8.

O jogo faz scroll horizontal e vertical. Então, nao precisa fazer os sprites dos bonecos muito pequenos; prefira combinações para formar sprites grandes e use o scroll para contornar a baixa resolução de 128x128.

## Tela inicial

Título "Secret Agent Man".



Mostra o personagem apontando a arma "quebrando a quarta parede", ao estilo de "James Bond gun barrel intro" .

Abaixo, "Push button to start". Apertando o botão pisca brevemente a mensagem e inicia o jogo.

## Jogo

O jogador é um agente screto britânico, bem vestido de smoking, gravata borboleta e portando um revolver. 

Os agentes inimigos usam roupas pretas, chapeus e capotes.

Os sprites devem ter uma cara mais flat e minimalista, com destaque para os shapes, mas poucas cores. 

A missão do jogador é procurar os planos secretos que estão escondidos em várias salas do edifício.

A ação envolve descer o prédio pelos elevadores. O jogador pode entrar no elevador ou subir na parte de cima.

Também há escadas rolantes no prédio, que o jogador pode subir ou descer.

Se cair de uma certa altura do fosso do elevador, ele morre.
Também pode ser esmagado se ficar entre a plataforma superior do elevador e a laje de um andar.

O jogador pode entrar nas portas vermelhas, onde estão os planos a serem colhidos. Ele abre a porta e entra brevente na sala, fechando a porta. Mas nunca se ve a sala por dentro, apenas a porta abrindo e fechando. Quando apanhou um item de uma porta vermelha, ela fica da cor das demais portas. 


Os agentes inimigos saem das portas normais. Para eles, valem as mesmas regras de  movimento nos elevadores e escadas rolantes. Também podem morrer ao cair de altura do fosso do elevador ou serem esmagados. 


Os agentes inimigos atiram no jogador. O jogador pode se abaixar para se defender dos tiros, mas os inimigos nao. 


O jogador pode atirar nos inimigos.

Quando um lustre é atingido por um tiro, a luz do andar apaga. Adaptar os sprites para a versao escura. Quando chegar em um andar com luz, volta ao normal.


O HUD com score, hiscore e vidas (representadas por cabeças do jogador) ficam na parte de cima da tela.

Recolhendo todos os itens, deve aparecer uma mensagem indicando para o jogador sair do prédio.


Quando descer ao primeiro andar e descer do predio, o jogador pega sua caranga e vai embora.


Assim termina a fase.

Música

Fazer uma música estilo surf music anos 60 típica de séries e filmes de espionagem, como Secret Agent Man, Peter Gunn, James Bond Theme etc. Criar um tema instrumental para o pico8 que tenha essa "pegada".
