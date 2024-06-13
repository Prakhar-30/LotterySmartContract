// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.9;

contract Lottery {
    address public manager;
    address payable[] public participants;
    address payable public winner;

    event ParticipantEntered(address participant, uint amount);
    event WinnerSelected(address winner, uint winnerAmount, address manager, uint managerAmount);

    constructor() {
        manager = msg.sender;
    }
    
    receive() external payable {
        require(msg.value >= 0.00005 ether, "Minimum participation is 1 ether");
        require(msg.sender != manager, "Manager cannot participate");
        participants.push(payable(msg.sender));
        emit ParticipantEntered(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint) {
        require(msg.sender == manager, "Only the manager can check the balance");
        return address(this).balance;
    }
    
    function random() private view returns (uint) {
        // Improved randomness using multiple sources of entropy
        return uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, block.prevrandao, participants.length, address(this).balance)));
    }

    function selectWinner() public {
        require(msg.sender == manager, "Only the manager can select the winner");
        require(participants.length >= 3, "At least 3 participants are required");

        uint r = random();
        uint index = r % participants.length;
        winner = participants[index];

        uint totalBalance = getBalance();
        uint managerShare = totalBalance / 5; // 20% to the manager
        uint winnerShare = totalBalance - managerShare; // 80% to the winner

        winner.transfer(winnerShare);
        payable(manager).transfer(managerShare);
        
        emit WinnerSelected(winner, winnerShare, manager, managerShare);

        // Reset participants array for next round
        participants = new address payable[](0) ;
    }
}
