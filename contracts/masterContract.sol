pragma solidity >=0.7.0 <0.9.0;

contract Matching_Pennies {
    struct GameDetail {
        address player_1;
        address player_2;
        bytes32 hash;
        int8 penny;
        address winner;
        int8 status;
        uint256 revealTimeLimit;
    }
    mapping(uint256 => GameDetail) private _gameDetail;
    address private _owner;
    uint256 private _gameNo;
    uint256 private _timeLimit;
    uint256 private _bet;
    uint256 private _reward;
    int8 private _openStatus;
    int8 private _waitingStatus;
    int8 private _revealedStatus;
    int8 private _closedStatus;
    int8 private _penalizedStatus;

    modifier placeBet() {
        require(msg.value == _bet, "Amount should be equal to 1 Ether");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "You are not the owner of this contract");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _gameNo = 1;
        _timeLimit = 1 days;
        _bet = 1 ether;
        _reward = _bet * 2;
        _openStatus = 1;
        _waitingStatus = 2;
        _revealedStatus = 3;
        _penalizedStatus = 4;
        _closedStatus = 0;
    }

    function setTimeLimit(uint256 t) public onlyOwner {
        _timeLimit = t * 1 seconds;
    }

    function newGame(bytes32 commitPenny)
        public
        payable
        placeBet
        returns (uint256)
    {
        require(commitPenny != "", "Hash should not be empty");
        require(commitPenny.length == 32, "The input is not a correct hash");
        _gameDetail[_gameNo].hash = commitPenny;
        _gameDetail[_gameNo].player_1 = msg.sender;
        _gameDetail[_gameNo].status = _openStatus;
        _gameDetail[_gameNo].penny = -1;
        
        uint256 newGameNo = _gameNo + 1;
        assert(newGameNo > _gameNo);
        _gameNo = newGameNo;

        return _gameNo;
    }

    function hashPenny(int8 penny, string memory secret)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(penny, secret));
    }

    function playGame(uint256 gameNo, int8 penny)
        public
        payable
        placeBet
        returns (bool)
    {
        require(_gameNo >= gameNo, "The game has not yet started");
        require(penny == 1 || penny == 0, "Penny must be either 0 or 1");
        require(
            _gameDetail[gameNo].status == _openStatus,
            "The game is not available anymore"
        );

        _gameDetail[gameNo].status = _waitingStatus;
        _gameDetail[gameNo].player_2 = msg.sender;
        _gameDetail[gameNo].penny = penny;
        
        uint256 revealTimeLimit = block.timestamp + _timeLimit;
        assert(revealTimeLimit > block.timestamp);
        _gameDetail[gameNo].revealTimeLimit = revealTimeLimit;

        return true;
    }

    function revealPenny(
        uint256 gameNo,
        int8 penny,
        string memory secret
    ) public returns (address) {
        require(
            msg.sender == _gameDetail[gameNo].player_1,
            "You are not authorized to reveal the hash of this game"
        );
        require(
            _gameDetail[gameNo].status == _waitingStatus,
            "This game is no longer require revealing"
        );
        require(penny == 1 || penny == 0, "Penny must be either 0 or 1");
        require(
            _gameDetail[gameNo].hash ==
                keccak256(abi.encodePacked(penny, secret)),
            "Your inputs are not correct"
        );

        _gameDetail[gameNo].winner = _gameDetail[gameNo].player_2;

        if (penny == _gameDetail[gameNo].penny) {
            _gameDetail[gameNo].winner = _gameDetail[gameNo].player_1;
        }

        _gameDetail[gameNo].status = _revealedStatus;

        return _gameDetail[gameNo].winner;
    }

    function cancelGame(uint256 gameNo) public returns (bool) {
        require(
            _gameDetail[gameNo].status == _openStatus,
            "The game cannot be cancelled"
        );
        require(
            msg.sender == _gameDetail[gameNo].player_1,
            "You are not authorized to cancel the game"
        );

        _gameDetail[gameNo].status = _closedStatus;
        (bool success, ) = payable(msg.sender).call{value: _bet}("");
        require(success, "Transaction failed");

        return success;
    }

    function withdrawRewards(uint256 gameNo) public returns (bool) {
        require(
            msg.sender == _gameDetail[gameNo].winner,
            "You are not the winner of this game"
        );
        require(
            _gameDetail[gameNo].status == _revealedStatus,
            "You have already withdrawn the rewards"
        );

        _gameDetail[gameNo].status = _closedStatus;
        (bool success, ) = payable(msg.sender).call{value: _reward}("");
        require(success, "Transaction failed");

        return success;
    }

    function penalizedWithdraw(uint256 gameNo) public returns (bool) {
        require(
            _gameDetail[gameNo].revealTimeLimit <= block.timestamp,
            "Not yet reach time limit"
        );
        require(
            _gameDetail[gameNo].status == _waitingStatus &&
                _gameDetail[gameNo].player_2 == msg.sender,
            "You are not authorized to use this function"
        );

        _gameDetail[gameNo].status = _penalizedStatus;
        (bool success, ) = payable(msg.sender).call{value: _reward}("");
        require(success, "Transaction failed");

        return success;
    }

    function checkGameDetail(uint256 gameNo)
        public
        view
        returns (
            address,
            address,
            address,
            int8,
            int8,
            uint256
        )
    {
        return (
            _gameDetail[gameNo].player_1,
            _gameDetail[gameNo].player_2,
            _gameDetail[gameNo].winner,
            _gameDetail[gameNo].status,
            _gameDetail[gameNo].penny,
            _gameDetail[gameNo].revealTimeLimit
        );
    }

    function checkGameNo() public view returns (uint256) {
        return _gameNo - 1;
    }
    
    function checkTimeLimit() public view returns (uint256) {
        return _timeLimit;
    }
}
