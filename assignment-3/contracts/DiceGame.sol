// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract DiceGame {
    struct Player {
        address addr;
        bool turn;
        uint256[] rolls;
    }

    struct Winner {
        string winnerIs;
        address addr;
    }

    mapping(uint256 => Player) public player;

    address public _owner;
    uint256 games;
    uint256 maxRounds;
    Winner public winner;

    constructor(address _addr1, address _addr2, uint256 _maxRounds){
        require(_addr1 != _addr2, "Can't play against yourself");
        maxRounds = _maxRounds;
        _owner = msg.sender;
        player[0].addr = _addr1;
        player[0].turn = true;
        player[1].addr = _addr2;
    }

    function reset(address _addr1, address _addr2) public {
        require(msg.sender == _owner, "Only owner allowed to reset");
        require(_addr1 != _addr2, "Can't play against yourself");    
        uint256[] memory emptyArr;
        player[0] = Player(_addr1, true, emptyArr);
        player[1] = Player(_addr2, false, emptyArr);
    }

    function rollTheDice() public {
        require(games / 2 != maxRounds, "Game over");
        require(player[0].addr == msg.sender || player[1].addr == msg.sender, "Not allowed!");
        if (player[0].addr == msg.sender) {
            require(player[0].turn == true, "It's Player2's turn");
            uint256 diceNr = pseudoRNDiceRoll();
            player[0].rolls.push(diceNr);
            player[0].turn = false;
            player[1].turn = true;
        }
        if (player[1].addr == msg.sender) {
            require(player[1].turn == true, "It's Player1's turn");
            uint256 diceNr = pseudoRNDiceRoll();
            player[1].rolls.push(diceNr);
            player[1].turn = false;
            player[0].turn = true;
        }
        games++;
        if (games / 2 == maxRounds){
            whoWon();
        }
    }

    function pseudoRNDiceRoll() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % 6 +1; 
    }

    function getRolls(uint256 _id) public view returns(uint256[] memory) {
        return player[_id].rolls;
    }

    function sumOfArray(uint256[] memory _arr) internal pure returns (uint256) {
        uint256 rollsSum;
        for (uint i = 0; i < _arr.length; i++){
            rollsSum += _arr[i];
        }
        return rollsSum;
    }
    
    function whoWon() internal {
        uint256 p1;
        uint256 p2;
        p1 = sumOfArray(player[0].rolls);
        p2 = sumOfArray(player[1].rolls);
        if (p1 == p2){ 
            winner = Winner("Tie", 0x0000000000000000000000000000000000000000);
        }
        if (p1 > p2){ 
            winner = Winner("Player 1", player[0].addr);
        }
        if (p2 > p1){ 
            winner = Winner("Player 2", player[1].addr);
        }
    }
}