# bookMakerDAO_bearbuilders

Instrucciones

NOTA: Solo funciona en Goerli ya que el oraculo de EnetScore de Chainlink es para esa red.
Copiar y pegar los 3 contratos con exactamente los mismos nombres en Remix.

Deployar contrato del token ERC20 llamado dai.sol
Deployar contrato Superbetcontract (este herada el Enetscoreconsumer.sol

Utilizar este faucet para hacerse de eth y link https://faucets.chain.link/goerli

Enviar link al contrato Superbetcontract

Llamar a la funcion requestschedule para obtener el fixture de determinada fecha, pasar como parametro:
  specId: 0x6431313062356334623833643432646361323065343130616335333763643934
  payment: 100000000000000000 (0.1 LINK)
  market: 0
  leagueId:
    47: English Premier League
    53: France Ligue `
    54: Germany Bundesliga
    55: Italy Serie A
    87: Spain LaLiga
    42: UEFA Champion's League
  date: en formato epoch unix , usar https://www.epochconverter.com/ gmt 0hs

Llamar a la funcion getGameCreate pasando como parameto el requestId que se obtiene del log (se puede scacar de events en etherscan)
  los idx 0,1,2,... nos daran el nombre del equipo, gameId y hora exacta de cada partido de ese dia
 
Llamar a la funcion createBet para crear una instancia de apuesta , es decir que se pueda apostar a un partido. Se debe pasar el requestId e idx del partido que se quiera crear la apuesta. Ademas se deben setear las cuotas iniciales para home, tied y away.}

Creada la apuesta un usuario puede apostar haciendo uso de la funcion setBet.

Previo al inicio del partido se debe cerrar las apuestas llamando a closeBet.

Finalizado el partido se debe llamar a la funcion requestSchedule nuevamente, pero la segunda!!(ojo) pasar mismos parametros cambiando market: 1 y entre corchetes el gameID [xxxx]

Llamando a getGameCreate con el requestId correspondiente generado por el evento se puede verificar el resultado del partido.

Ahora se puede llamar a resolveWinner para verificar quien gano.

Calculado el ganador, quienes hayan ganado puede llamar a claimRewards y cobrase su apuesta. (Tiene que haber suficientes tokens en el contrato para poder pagarlo)




