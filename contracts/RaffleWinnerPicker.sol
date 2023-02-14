// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "hardhat/console.sol";

error Lottery__NotOwner();
error Lottery__NotEnoughPlayers();
error Lottery__TransferFailed();
error Lottery__LotteryClosed();
error Lottery__RewardEqualToZero();
error Lottery__NotEnoughWinners();
error Lottery__WinnerAlreadyPicked();
error Lottery__LotteryAlreadyExists();
error Lottery__NotEnoughFundsSent();
error Lottery__LotteryDoesNotExist();
error Lottery__RandomNumberAlreadyPicked();
error Lottery__RandomNumberNotPicked();

/// @title Lottery that automatically picks the set amount of winners
/// @author VAIOT team
/// @notice This contract supports multiple lotteries running at once
/// @dev Functions should be called in the order: openLottery -> addLotteryParticipants -> pickRandomNumberForLottery
/// -> pickWinners (open the lottery, add participants, pick random number for the lottery and pick the winners)

contract RaffleWinnerPicker is VRFConsumerBaseV2 {
    /* Lottery Variables */

    address immutable i_owner;
    uint256 private lotteryId;
    enum LotteryState {
        CLOSED,
        OPEN
    }

    /* Chainlink VRF Variables */
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Structs

    struct Lottery {
        bool exists;
        address payable author;
        LotteryState status;
        uint256 numOfWinners;
        address payable[] participants;
        address payable[] winners;
    }

    /* Mappings */
    mapping(uint256 => Lottery) idToLottery;
    mapping(uint256 => uint256) idToRandomNumber;

    /* Events */
    event RequestedRaffleWinner(uint256 indexed requestId);
    event AddressesAdded(
        uint256 indexed lotteryId,
        address payable[] addresses
    );
    event RandomNumberPicked(uint256 indexed lotteryId, uint256 randomNumber);

    /* Constructor */
    constructor(
        uint64 _subscriptionId,
        bytes32 _gasLane,
        uint32 _callbackGasLimit
    ) payable VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed) {
        i_owner = msg.sender;
        i_vrfCoordinator = VRFCoordinatorV2Interface(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        );
        i_subscriptionId = _subscriptionId;
        i_gasLane = _gasLane;
        i_callbackGasLimit = _callbackGasLimit;
        lotteryId = 0;
    }

    /* Modifiers */

    modifier onlyOwner() {
        require(msg.sender == i_owner);
        _;
    }

    /* Main Functions */

    /// @notice Open the lottery
    /// @param _author - author of the giveaway
    /// @param _numOfWinners - number of winners of the lottery

    function openLottery(
        address payable _author,
        uint256 _numOfWinners
    ) public onlyOwner {
        lotteryId += 1;

        // Setting basic information about the lottery

        idToLottery[lotteryId].exists = true;
        idToLottery[lotteryId].author = _author;
        idToLottery[lotteryId].status = LotteryState.OPEN;
        idToLottery[lotteryId].numOfWinners = _numOfWinners;
    }

    /// @notice Function that adds participants of the lottery
    /// @param _lotteryId - id of the lottery (the first lottery has index 1)
    /// @param _addresses - array containing addresses of the lottery participants

    function addLotteryParticipants(
        uint256 _lotteryId,
        address payable[] memory _addresses
    ) public onlyOwner {
        if (idToLottery[_lotteryId].status != LotteryState.OPEN) {
            revert Lottery__LotteryClosed();
        }
        if (idToLottery[_lotteryId].exists != true) {
            revert Lottery__LotteryDoesNotExist();
        }
        for (uint i = 0; i < _addresses.length; i++) {
            idToLottery[_lotteryId].participants.push(_addresses[i]);
        }
        emit AddressesAdded(_lotteryId, _addresses);
    }

    /// @notice Call Chainlink VRF to get a random number
    /// @param _lotteryId - id of the lottery

    function pickRandomNumberForLottery(uint256 _lotteryId) external onlyOwner {
        if (idToLottery[_lotteryId].participants.length <= 0) {
            revert Lottery__NotEnoughPlayers();
        }
        if (idToLottery[_lotteryId].status != LotteryState.OPEN) {
            revert Lottery__LotteryClosed();
        }
        if (idToLottery[_lotteryId].numOfWinners <= 0) {
            revert Lottery__NotEnoughWinners();
        }
        if (idToLottery[_lotteryId].winners.length > 0) {
            revert Lottery__WinnerAlreadyPicked();
        }
        if (idToRandomNumber[_lotteryId] != 0) {
            revert Lottery__RandomNumberAlreadyPicked();
        }
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    /// @notice Function that the Chainlink node calls in order to supply us with a random number

    function fulfillRandomWords(
        uint256 /* _requestId */,
        uint256[] memory _randomWords
    ) internal override {
        idToRandomNumber[lotteryId] = _randomWords[0];
        emit RandomNumberPicked(lotteryId, _randomWords[0]);
    }

    /// @notice Function that picks the winners of the lottery
    /// @notice Call it only when openLottery and addParticipants have been previously called
    /// @param _lotteryId - id of the lottery

    function pickWinners(
        uint256 _lotteryId
    ) public onlyOwner returns (address payable[] memory) {
        if (idToRandomNumber[_lotteryId] == 0) {
            revert Lottery__RandomNumberNotPicked();
        }
        if (idToLottery[_lotteryId].exists != true) {
            revert Lottery__LotteryDoesNotExist();
        }
        if (idToLottery[_lotteryId].status != LotteryState.OPEN) {
            revert Lottery__LotteryClosed();
        }
        if (
            idToLottery[_lotteryId].numOfWinners >
            idToLottery[_lotteryId].participants.length
        ) {
            revert Lottery__NotEnoughPlayers();
        }
        idToLottery[_lotteryId].status = LotteryState.CLOSED;
        uint256 vrfNumber = idToRandomNumber[_lotteryId];

        // Creating a unique random number for every winner
        // 1. Create random number based on the array length
        // 2. Find the winner and push it to a new array
        // 3. Delete the previous winner and replace the last address with the deleted one
        // 4. Delete the last element of the array which is empty and repeat the process

        for (uint i = 0; i < idToLottery[_lotteryId].numOfWinners; i++) {
            uint256 randomIndex = uint256(
                keccak256(abi.encode(vrfNumber, block.timestamp, i))
            ) % idToLottery[_lotteryId].participants.length;
            address payable recentWinner = idToLottery[_lotteryId].participants[
                randomIndex
            ];
            idToLottery[_lotteryId].winners.push(recentWinner);
            delete idToLottery[_lotteryId].participants[randomIndex];
            idToLottery[_lotteryId].participants[randomIndex] = idToLottery[
                _lotteryId
            ].participants[idToLottery[_lotteryId].participants.length - 1];
            idToLottery[_lotteryId].participants.pop();
        }
        return idToLottery[_lotteryId].winners;
    }

    /* Getter Functions */

    function getWinnersOfLottery(
        uint256 _lotteryId
    ) public view returns (address payable[] memory) {
        return idToLottery[_lotteryId].winners;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getNumberOfPlayers(
        uint256 _lotteryId
    ) public view returns (uint256) {
        return idToLottery[_lotteryId].participants.length;
    }

    function getParticipants(
        uint256 _lotteryId
    ) public view returns (address payable[] memory) {
        return idToLottery[_lotteryId].participants;
    }

    function getSubscriptionId() public view returns (uint256) {
        return i_subscriptionId;
    }

    function getLotteryInfo(
        uint256 _lotteryId
    ) public view returns (Lottery memory) {
        return idToLottery[_lotteryId];
    }

    function getLotteryState(
        uint256 _lotteryId
    ) public view returns (LotteryState) {
        return idToLottery[_lotteryId].status;
    }

    function getRandomNumber(uint256 _lotteryId) public view returns (uint256) {
        return idToRandomNumber[_lotteryId];
    }

    function getLotteryId() public view returns (uint256) {
        return lotteryId;
    }

    function getNumberOfWinners(
        uint256 _lotteryId
    ) public view returns (uint256) {
        return idToLottery[_lotteryId].numOfWinners;
    }

    function getLotteryAuthor(
        uint256 _lotteryId
    ) public view returns (address payable) {
        return idToLottery[_lotteryId].author;
    }

    function checkIfLotteryExists(
        uint256 _lotteryId
    ) public view returns (bool) {
        return idToLottery[_lotteryId].exists;
    }
}
