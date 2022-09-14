//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./dai.sol";
import "./enetScoreConsumer.sol";

contract superBetContract is EnetscoresConsumer{
    address public owner;
    address tokenAddress;

    enum betOption {
        home,
        away,
        tied
    }
    struct betStruct {
        betOption option;
        uint256 amount;
        uint odd;
    }

    struct matchStruct {
        uint homeOdd;
        uint tiedOdd;
        uint awayOdd;
        bool betOpen;
        uint homeTotalBets;
        uint tiedTotalBets;
        uint awayTotalBets;
        betOption winner;
        mapping (address => betStruct) userBets;
        bool winnerResolved;
    }
    mapping(uint32 => matchStruct ) public matchs;

    GameResolve public mockedGameResolveMatch;
    GameCreate public mockedGameCreateMatch;

    uint public temporalRewardPublic;


    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress =_tokenAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'only owner');
        _;
    }

    function withdrawDAI(uint amount) public onlyOwner{
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }
    
    event betCreation(uint32 _gameId);
    function createBet(bytes32 _requestId, uint256 _idx, uint _homeOdd, uint _tiedOdd,  uint _awayOdd) 
        public onlyOwner{
            GameCreate memory matchData;
       //    matchData = mockedGameCreateMatch;
             matchData = getGameCreate(_requestId, _idx);
            //Obtengo el GameId para el partido especifico
            uint32 gameId = matchData.gameId;
            //Seteo los premios
            matchs[gameId].homeOdd = _homeOdd;
            matchs[gameId].tiedOdd = _tiedOdd;
            matchs[gameId].awayOdd = _awayOdd;
            matchs[gameId].betOpen = true;
            emit betCreation(gameId);

    }

    event userBet(address indexed _from, uint32 _gameId, uint _amount, betOption _choice);
    function setBet(uint32 _gameId, uint _amount, betOption _choice ) public {
        if(_choice == betOption.home){
        matchs[_gameId].userBets[msg.sender].odd = matchs[_gameId].homeOdd;
        matchs[_gameId].homeTotalBets += _amount;
        }
        if(_choice == betOption.away){
        matchs[_gameId].userBets[msg.sender].odd = matchs[_gameId].awayOdd;
        matchs[_gameId].awayTotalBets += _amount;
        }
        if(_choice == betOption.tied){
        matchs[_gameId].userBets[msg.sender].odd = matchs[_gameId].tiedOdd;
        matchs[_gameId].tiedTotalBets += _amount;
        }
        matchs[_gameId].userBets[msg.sender].option = _choice;
        matchs[_gameId].userBets[msg.sender].amount += _amount;
        depositDAI(_amount);
        emit userBet(msg.sender, _gameId, _amount, _choice);

    }


    function closeBet(uint32 _gameId) public onlyOwner {
            matchs[_gameId].betOpen = false;
    }

//Previo a esta funcion llamar getGameResolve. El request id debe ser del gameCreate para validar que el gameId sea el mismo
    function resolveWinner(bytes32 _requestIdGameCreate, bytes32 _requestIdGameResolve, uint256 _idx) public onlyOwner {
        //Obtengo el GameId para el partido especifico
        GameResolve memory matchData;
        matchData = getGameResolve(_requestIdGameResolve, _idx);
        //matchData = mockedGameResolveMatch;
        uint32 gameId = matchData.gameId;
        // Verifica que el gameId sea el mismo para gameResolve y game Create
        GameCreate memory _matchData;
        //_matchData = mockedGameCreateMatch;
        _matchData = getGameCreate(_requestIdGameCreate, _idx);
        uint32 _gameId = _matchData.gameId;
        require(gameId == _gameId, "gameIds not matchs");
        // Verifica que este cerrada la apuesta
        require (matchs[gameId].betOpen == false, "bet not closed yet");
        // Verifica que el partido haya terminado
        require (keccak256(abi.encodePacked("finished")) == keccak256(abi.encodePacked(matchData.status)));
        // Setea el ganador en base a resultados
        if(matchData.homeScore>matchData.awayScore) {
            matchs[gameId].winner = betOption.home;
        } 
        if(matchData.homeScore<matchData.awayScore) {
            matchs[gameId].winner = betOption.away;
        }
        if(matchData.homeScore == matchData.awayScore) {
            matchs[gameId].winner = betOption.tied;
        }
        matchs[gameId].winnerResolved = true;
    }

    event RewardClaim(address indexed _from, uint amount);
    function claimRewards(uint32 _gameId) public {
        require (matchs[_gameId].winnerResolved == true, "Winner not resolved");
        require (matchs[_gameId].winner == matchs[_gameId].userBets[msg.sender].option, "No rewards");
        //Calculo del reward
        uint amount = matchs[_gameId].userBets[msg.sender].amount * matchs[_gameId].userBets[msg.sender].odd / 10**18;     
        require(amount<=IERC20(tokenAddress).balanceOf(address(this)), "Not enought balance in treasury");
        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit RewardClaim(msg.sender, amount);
    }

   function depositDAI(uint amount) public {
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    function mockWinner(uint32 _gameId, betOption _winner) public onlyOwner{
        matchs[_gameId].winner = _winner;
        matchs[_gameId].winnerResolved = true;
    }

    function mockGetGameCreate(uint32 _gameId) public onlyOwner{
        GameCreate memory matchData;
        matchData.gameId = _gameId;
        mockedGameCreateMatch = matchData;
    }

    function mockGetGameResolve(uint32 _gameId, uint8 _homeScore, uint8 _awayScore, string memory _status ) public onlyOwner{
        GameResolve memory matchData;
        matchData.gameId = _gameId;
        matchData.homeScore = _homeScore;
        matchData.awayScore = _awayScore;
        matchData.status = _status;
        mockedGameResolveMatch = matchData;
    }

    function getUserBet(uint32 _gameId) public view returns (betStruct memory) {

        betStruct memory _userBet;
        _userBet.option = matchs[_gameId].userBets[msg.sender].option;
        _userBet.amount = matchs[_gameId].userBets[msg.sender].amount;
        _userBet.odd = matchs[_gameId].userBets[msg.sender].odd;

        return _userBet;
    }

    function calculateReward(uint32 _gameId) public returns(uint){
        uint amount = matchs[_gameId].userBets[msg.sender].amount * matchs[_gameId].userBets[msg.sender].odd / 10**18;     
        temporalRewardPublic = amount;
        return amount;
    }

}
