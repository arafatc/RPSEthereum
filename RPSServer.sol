// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

contract RPSGame {
    // GameState - INITIATED after inital game setup, RESPONDED after responder adds hash choice, WIN or DRAW after final scoring
    enum RPSGameState {INITIATED, RESPONDED, WIN, DRAW}
    
    // PlayerState - PENDING until they add hashed choice, PLAYED after adding hash choice, CHOICE_STORED once raw choice and random string are stored
    enum PlayerState {PENDING, PLAYED, CHOICE_STORED}
    
    // 0 before choices are stored, 1 for Rock, 2 for Paper, 3 for Scissors. Strings are stored only to generate comment with choice names
    string[4] choiceMap = ['None', 'Rock', 'Paper', 'Scissor'];
    
    struct RPSGameData {
        address initiator; // Address of the initiator
        PlayerState initiator_state; // State of the initiator
        bytes32 initiator_hash; // Hashed choice of the initiator
        uint8 initiator_choice; // Raw number of initiator's choice - 1 for Rock, 2 for Paper, 3 for Scissors
        string initiator_random_str; // Random string chosen by the initiator
        
	    address responder; // Address of the responder
        PlayerState responder_state; // State of the responder
        bytes32 responder_hash; // Hashed choice of the responder
        uint8 responder_choice; // Raw number of responder's choice - 1 for Rock, 2 for Paper, 3 for Scissors
        string responder_random_str; // Random string chosen by the responder
                
        RPSGameState state; // Game State
        address winner; // Address of winner after completion. addresss(0) in case of draw
        string comment; // Comment specifying what happened in the game after completion
    }
    
    RPSGameData _gameData;
    
    // Initiator sets up the game and stores its hashed choice in the creation itself. Game and player states are adjusted accordingly
    constructor(address _initiator, address _responder, bytes32 _initiator_hash) {
        _gameData = RPSGameData({
                                    initiator: _initiator,
                                    initiator_state: PlayerState.PLAYED,
                                    initiator_hash: _initiator_hash, 
                                    initiator_choice: 0,
                                    initiator_random_str: '',
                                    responder: _responder, 
                                    responder_state: PlayerState.PENDING,
                                    responder_hash: 0, 
                                    responder_choice: 0,
                                    responder_random_str: '',
                                    state: RPSGameState.INITIATED,
                                    winner: address(0),
                                    comment: ''
                            });
    }
    
    // Responder stores their hashed choice. Game and player states are adjusted accordingly.
    function addResponse(bytes32 _responder_hash) public {
        _gameData.responder_hash = _responder_hash;
        _gameData.state = RPSGameState.RESPONDED;
        _gameData.responder_state = PlayerState.PLAYED;
    }
    
    // Initiator adds raw choice number and random string. If responder has already done the same, the game should process the completion execution
    function addInitiatorChoice(uint8 _choice, string memory _randomStr) public returns (bool) {
        require(_gameData.state == RPSGameState.RESPONDED, "incorrect game state");
        _gameData.initiator_choice = _choice;
        _gameData.initiator_random_str = _randomStr;
        _gameData.initiator_state = PlayerState.CHOICE_STORED;
        if (_gameData.responder_state == PlayerState.CHOICE_STORED) {
            __validateAndExecute();
        }
        return true;
    }

    // Responder adds raw choice number and random string. If initiator has already done the same, the game should process the completion execution
    function addResponderChoice(uint8 _choice, string memory _randomStr) public returns (bool) {
        require(_gameData.state == RPSGameState.RESPONDED, "incorrect game state");
        _gameData.responder_choice = _choice;
        _gameData.responder_random_str = _randomStr;
        _gameData.responder_state = PlayerState.CHOICE_STORED;
        if (_gameData.initiator_state == PlayerState.CHOICE_STORED) {
            __validateAndExecute();
        }
        return true;
    }
    
    // Core game logic to check raw choices against stored hashes, and then the actual choice comparison
    // Can be split into multiple functions internally
    function __validateAndExecute() private {
        bytes32 initiatorCalcHash = sha256(abi.encodePacked(choiceMap[_gameData.initiator_choice], '-', _gameData.initiator_random_str));
        bytes32 responderCalcHash = sha256(abi.encodePacked(choiceMap[_gameData.responder_choice], '-', _gameData.responder_random_str));
        bool initiatorAttempt = false;
        bool responderAttempt = false;
        
        if (initiatorCalcHash == _gameData.initiator_hash) {
            initiatorAttempt = true;
        }
        
        if (responderCalcHash == _gameData.responder_hash) {
            responderAttempt = true;
        }
    // Add logic to complete the game first based on attempt validation states, and then based on 
    // actual game logic if both attempts are validation
    // Comments can be set appropriately like 'Initator attempt invalid', or 'Scissor beats Paper', etc.
    
        if(initiatorAttempt == false && responderAttempt == false) {
        // DRAW if both are invalid, Changes the game state to RPSGameState.DRAW
        // Winner address should be address(0) in case of DRAW
            setGamestatus(3, address(0), 'Both attempts are invalid' );
        }

        else if(initiatorAttempt == false && responderAttempt == true) {
        // WIN if one is invalid, Changes the game state to RPSGameState.WIN 
        // Winner address should be address(A or B)
            setGamestatus(2, _gameData.responder, 'Initator attempt invalid' );
        }

        else if(initiatorAttempt == true && responderAttempt == false) {
        //WIN if one is invalid, Changes the game state to RPSGameState.WIN
        // Winner address should be address(A or B)
            setGamestatus(2, _gameData.initiator, 'Responder attempt invalid' );  
        }

        else {
        // Compare choices based on game logic and assign DRAW or WIN accordingly
        // 1 Rock 2 Paper 3 Scissor - 2 beats 1, 3 beats 2, 1 beats 3
            uint8 initiator_choice = _gameData.initiator_choice;
            uint8 responder_choice = _gameData.responder_choice;
            
            if( initiator_choice == responder_choice){
                setGamestatus(3, address(0), 'Both choices are same' );
            }
            else if( initiator_choice * responder_choice == 2){
                if(initiator_choice ==1) {
                    setGamestatus(2, _gameData.responder, 'Paper beats Rock' );
                }
                else {
                    setGamestatus(2, _gameData.initiator, 'Paper beats Rock' );
                }
            }
            else if( initiator_choice * responder_choice == 3){
                if(initiator_choice ==1) {
                   setGamestatus(2, _gameData.initiator, 'Rock beats Scissor' ); 
                }
                else {
                    setGamestatus(2, _gameData.responder, 'Rock beats Scissor');
                }
            } 
            else {
                if(initiator_choice ==2) {
                    setGamestatus(2, _gameData.responder, 'Scissor beats Paper' );
                }
                else {
                    setGamestatus(2, _gameData.initiator, 'Scissor beats Paper' );
                }
            }
        }
    }

    // Helper function to set the state of the game, winner address and comment based on valid/ invalid player moves
    function setGamestatus(uint8 _gameState, address _player, string memory _comment) internal returns (bool success) {
        if(_gameState == 2) {
            _gameData.state = RPSGameState.WIN;
        } 
        if(_gameState == 3) {
            _gameData.state = RPSGameState.DRAW;
        }
        _gameData.winner = _player;
        _gameData.comment = _comment;
        return true;
    }

    // Returns the address of the winner, GameState (2 for WIN, 3 for DRAW), and the comment
    function getResult() public view returns (address, RPSGameState, string memory) {
        //{INITIATED, RESPONDED, WIN, DRAW}
        require(_gameData.state == RPSGameState.WIN || _gameData.state == RPSGameState.DRAW, "incorrect game state");
        return (_gameData.winner, _gameData.state, _gameData.comment);
    } 
}

contract RPSServer {
    // Mapping for each game instance with the first address being the initiator and internal key aaddress being the responder
    mapping(address => mapping(address => RPSGame)) _gameList;
    
    // Modifier to check inititator address
    modifier check_initiator(address _initiator) {
        require(_initiator != address(0) && _initiator != msg.sender, "initiator address incorrect");
        _;
    }

    // Modifier to check responder address
    modifier check_responder(address _responder) {
        require(_responder != address(0) && _responder != msg.sender, "responder address incorrect");
        _;
    }

    // Modifier to check choices
    modifier check_choice(uint8 _choice) {
        require(_choice >= 1 && _choice <= 3, "choice must be 1, 2 or 3");
        _;
    }

    // Initiator sets up the game and stores its hashed choice in the creation itself. New game created and appropriate function called    
    function initiateGame(address _responder, bytes32 _initiator_hash) public check_responder(_responder) {
        RPSGame game = new RPSGame(msg.sender, _responder, _initiator_hash);
        _gameList[msg.sender][_responder] = game;
    }

    // Responder stores their hashed choice. Appropriate RPSGame function called   
    function respond(address _initiator, bytes32 _responder_hash) public check_initiator(_initiator) {
        RPSGame game = _gameList[_initiator][msg.sender];
        game.addResponse(_responder_hash);
    }

    // Initiator adds raw choice number and random string. Appropriate RPSGame function called  
    function addInitiatorChoice(address _responder, uint8 _choice, string memory _randomStr) public check_responder(_responder) check_choice(_choice) returns (bool) {
        RPSGame game = _gameList[msg.sender][_responder];
        return game.addInitiatorChoice(_choice, _randomStr);
    }

    // Responder adds raw choice number and random string. Appropriate RPSGame function called
    function addResponderChoice(address _initiator, uint8 _choice, string memory _randomStr) public check_initiator(_initiator) check_choice(_choice) returns (bool) {        
        RPSGame game = _gameList[_initiator][msg.sender];
        return game.addResponderChoice(_choice, _randomStr);
    }
    
    // Result details request by the initiator
    function getInitiatorResult(address _responder) public check_responder(_responder) view returns (address, RPSGame.RPSGameState, string memory) {
        RPSGame game = _gameList[msg.sender][_responder];
        return game.getResult();
    }

    // Result details request by the responder
    function getResponderResult(address _initiator) public check_initiator(_initiator) view returns (address, RPSGame.RPSGameState, string memory) {
        RPSGame game = _gameList[_initiator][msg.sender];
        return game.getResult();
    }
}