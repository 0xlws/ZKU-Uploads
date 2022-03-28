// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract CardGame {

    enum Value { Ace, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King}
    enum Suit { Clubs, Diamonds, Hearts, Spades }

    struct Card {
        Suit suit;
        Value value;
    }

    struct Player {
        address uAddr;
        bool turn;
        bytes32[] hashedCards;
    }

    mapping(uint256 => Player) public player;
    mapping(bytes32 => bool) public isDrawn;

    Card private playersCard;
    Card[] private player1sCards;
    Card[] private player2sCards;

    // make players cards values visible 
    string[] public p1CardValues;
    string[] public p2CardValues;

    bytes32[] private _drawnCards;
    uint256 initialNumber;
    address public _owner;
    uint256 players = 0;
    uint256 maxPlayers = 2;
    bool private player1Turn = true;

    // initialize 2 player game, set contract deployer to owner
    constructor(address _addr1, address _addr2){
        require(_addr1 != _addr2, "Can't play against yourself");
        _owner = msg.sender;
        player[0].uAddr = _addr1;
        player[0].turn = true;
        player[1].uAddr = _addr2;
    }

    // owner can reset the game to init state
    function reset(address _addr1, address _addr2) public {
        require(msg.sender == _owner, "Only owner allowed to reset");
        require(_addr1 != _addr2, "Can't play against yourself");    
        bytes32[] memory emptyArr;
        player[0] = Player(_addr1, true, emptyArr);
        player[1] = Player(_addr2, false, emptyArr);
        _drawnCards = emptyArr;
    }

    // players can get a card with this function
    // user provides a secret number to make the hash more effective
    // checks are in place to make the game turn based
    function drawCard(uint256 _secret) public {
        require(player[0].uAddr == msg.sender || player[1].uAddr == msg.sender, "Not allowed!");
        if (player[0].uAddr == msg.sender) {
            require(player[0].turn == true, "It's Player2's turn");
            uint256 _suit;
            uint256 _value;
            (_suit, _value) = pseudoRandom(_secret);
            player1sCards.push(Card(Suit(_suit), Value(_value)));
            p1CardValues.push(getSuit(_value));
            player[0].hashedCards.push(hashCard(Suit(_suit), _secret,Value(_value)));
            player[0].turn = false;
            player[1].turn = true;
        }
        if (player[1].uAddr == msg.sender) {
            require(player[1].turn == true, "It's Player1's turn");
            uint256 _suit;
            uint256 _value;
            (_suit, _value) = pseudoRandom(_secret);
            player2sCards.push(Card(Suit(_suit), Value(_value)));
            p2CardValues.push(getSuit(_value));
            player[1].hashedCards.push(hashCard(Suit(_suit), _secret, Value(_value)));
            player[1].turn = false;
            player[0].turn = true;
        }
    }

    
    // function drawCardWithInput(uint256 _suit, uint256 _value, uint256 _secret) public {
    //     require(_suit <= 3, "Suit outside of range 0-3");
    //     require(_value <= 12, "Value outide of range 0-12" );
    //     require(player[0].uAddr == msg.sender || player[1].uAddr == msg.sender, "Not allowed!");
    //     if (player[0].uAddr == msg.sender) {
    //         require(player[0].turn == true, "It's Player2's turn");
    //         (_suit, _value) = pseudoRandomInput(_suit, _value, _secret);
    //         player[0].hashedCards.push(hashCard(Suit(_suit), _secret, Value(_value)));
    //         player[0].turn = false;
    //         player[1].turn = true;
    //     }
    //     if (player[1].uAddr == msg.sender) {
    //         require(player[1].turn == true, "It's Player1's turn");
    //         (_suit, _value) = pseudoRandomInput(_suit, _value, _secret);
    //         player[1].hashedCards.push(hashCard(Suit(_suit), _secret, Value(_value)));
    //         player[1].turn = false;
    //         player[0].turn = true;
    //     }
    // }

    function roundsPlayed() public view returns(uint256){
        return _drawnCards.length;
    }

    // get string representation of card values
    function getSuit(uint256 _val) internal pure returns(string memory){
        if (_val == 0) return "Ace"; 
        if (_val == 1) return "Two"; 
        if (_val == 2) return "Three"; 
        if (_val == 3) return "Four"; 
        if (_val == 4) return "Five"; 
        if (_val == 5) return "Six"; 
        if (_val == 6) return "Seven"; 
        if (_val == 7) return "Eight"; 
        if (_val == 8) return "Nine"; 
        if (_val == 9) return "Ten"; 
        if (_val == 10) return "Jack"; 
        if (_val == 11) return "Queen"; 
        if (_val == 12) return "King"; 
        return "";
    }

    // get random numbers for suit and value of card with user input
    function pseudoRandomInput(uint256 _suit, uint256 _value, uint256 _secret) internal returns(uint256, uint256){
        uint256 nr1 = uint256(keccak256(abi.encodePacked(initialNumber++, block.timestamp, _secret))) % _suit;
        uint256 nr2 = uint256(keccak256(abi.encodePacked(initialNumber++, block.timestamp, _secret))) % _value;
        bytes32 hashedCard = keccak256(abi.encodePacked(nr1, nr2));
        require(drawn(hashedCard), "Card already drawn, please try again.");
        _drawnCards.push(hashedCard);
        isDrawn[hashedCard] = true;
        return (nr1, nr2);
    }

    // get random numbers for suit and value of card with default values
    function pseudoRandom(uint256 _secret) internal returns(uint256, uint256){
        uint256 nr1 = uint256(keccak256(abi.encodePacked(initialNumber++, block.timestamp, _secret))) % 4;
        uint256 nr2 = uint256(keccak256(abi.encodePacked(initialNumber++, block.timestamp, _secret))) % 13;
        bytes32 hashedCard = keccak256(abi.encodePacked(nr1, nr2));
        require(drawn(hashedCard), "Card already drawn, please try again.");
        _drawnCards.push(hashedCard);
        isDrawn[hashedCard] = true;
        return (nr1, nr2);
    }

    // check if card is drawn
    function drawn(bytes32 a) private view returns (bool) {
        return !isDrawn[a];
    }

    // hash suit and value of card with secret inbetween to prevent hash collision
    function hashCard(Suit _suit, uint256 _secret,Value _value) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_suit, _secret, _value));
    }
}