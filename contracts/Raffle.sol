// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";

error Lottery__NotOwner();
error Lottery__NotEnoughPlayers();
error Lottery__TransferFailed();
error Lottery__LotteryClosed();
error Lottery__RewardEqualToZero();
error Lottery__NotEnoughWinners();
error Lottery__NumOfPlayersNotEqualToNumOfRewards();
error Lottery__WinnerAlreadyPicked();
error Lottery__LotteryAlreadyExists();
error Lottery__NotEnoughFundsSent();
error Lottery__LotteryDoesNotExist();
error Lottery__RewardProportionsError();
error Lottery__RewardAmountSplitError();
error Lottery__RandomNumberAlreadyPicked();
error Lottery__RandomNumberNotPicked();

/// @title Lottery that automatically picks winners and pays them in the native token
/// @author VAIOT team
/// @notice This contract supports multiple lotteries running at once
/// @dev Functions should be called in the order: openLottery -> addLotteryParticipants -> pickRandomNumberForLottery
/// -> payOutWinners (open the lottery, add participants, pick random number for the lottery and pay the winners)
/// The function emergencyCashback is for paying back the author of the giveaway in case the lottery gets stuck
/// (for example because there were not enough players).

contract Raffle is VRFConsumerBaseV2 {
    /* Lottery Variables */
    address immutable i_owner;

    uint256 private lotteryId;
    enum LotteryState {
        CLOSED,
        OPEN
    }
    enum LotteryType {
        SPLIT,
        PERCENTAGE
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
        LotteryType lotteryType;
        uint256 reward;
        uint256 numOfWinners;
        uint256[] rewardProportions; // this is used when a % lottery is picked
        uint256[] finalRewards;
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

    /// @notice Open the lottery with the type SPLIT
    /// @param _author - author of the giveaway
    /// @param _numOfWinners - number of winners of the lottery
    /// @param _rewardAmounts - how many tokens go to which winner in WEI. For example 0.1 tokens is 0.1*10^18

    function openLotterySplit(
        address payable _author,
        uint256 _numOfWinners,
        uint256[] memory _rewardAmounts
    ) public payable onlyOwner {
        if (_rewardAmounts.length != _numOfWinners) {
            revert Lottery__NumOfPlayersNotEqualToNumOfRewards();
        }
        if (msg.value <= 0) {
            revert Lottery__NotEnoughFundsSent();
        }

        // Calculating how much the winners get exactly in MATIC and pushing the information into the mapping

        uint256 totalAmount = 0;

        // Get the total amount of MATIC the winners should get (in WEI)

        for (uint i = 0; i < _rewardAmounts.length; i++) {
            totalAmount = totalAmount + _rewardAmounts[i];
        }

        if (idToLottery[lotteryId].exists == true) {
            revert Lottery__LotteryAlreadyExists();
        }

        lotteryId += 1;

        // Setting basic information about the lottery

        idToLottery[lotteryId].exists = true;
        idToLottery[lotteryId].lotteryType = LotteryType.SPLIT;
        idToLottery[lotteryId].author = _author;
        idToLottery[lotteryId].status = LotteryState.OPEN;
        idToLottery[lotteryId].reward = totalAmount;
        idToLottery[lotteryId].numOfWinners = _numOfWinners;
        idToLottery[lotteryId].finalRewards = _rewardAmounts;
    }

    /// @notice Open the lottery with the type PERCENTAGE
    /// @param _author - author of the giveaway
    /// @param _numOfWinners - number of winners of the lottery
    /// @param _totalReward - total amount of MATIC given out in wei
    /// @param _finalRewards - exact amount of tokens each winner should get in WEI
    /// @param _rewardProportions - what % of the reward goes to what winner. Example:
    /// if there are 5 participants and everyone gets equal rewards the input would be [20,20,20,20,20]
    /// Keep in mind the proportions have to sum up to 100 and the length of the array has to match
    /// the number of winners

    function openLotteryPercentage(
        address payable _author,
        uint256 _numOfWinners,
        uint256 _totalReward,
        uint256[] memory _finalRewards,
        uint256[] memory _rewardProportions
    ) public payable onlyOwner {
        if (_rewardProportions.length != _numOfWinners) {
            revert Lottery__NumOfPlayersNotEqualToNumOfRewards();
        }
        if (msg.value <= 0) {
            revert Lottery__NotEnoughFundsSent();
        }

        uint256 rewardProportionsSum;

        for (uint i = 0; i < _rewardProportions.length; i++) {
            rewardProportionsSum = rewardProportionsSum + _rewardProportions[i];
        }

        if (rewardProportionsSum != 100) {
            revert Lottery__RewardProportionsError();
        }

        if (idToLottery[lotteryId].exists == true) {
            revert Lottery__LotteryAlreadyExists();
        }

        lotteryId += 1;

        // Setting basic information about the lottery

        idToLottery[lotteryId].exists = true;
        idToLottery[lotteryId].author = _author;
        idToLottery[lotteryId].lotteryType = LotteryType.PERCENTAGE;
        idToLottery[lotteryId].status = LotteryState.OPEN;
        idToLottery[lotteryId].reward = _totalReward;
        idToLottery[lotteryId].numOfWinners = _numOfWinners;
        idToLottery[lotteryId].rewardProportions = _rewardProportions;
        idToLottery[lotteryId].finalRewards = _finalRewards;
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
        if (idToLottery[_lotteryId].reward <= 0) {
            revert Lottery__RewardEqualToZero();
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

    /// @notice Function that pays the winners of the lottery
    /// @notice Call it only when openLottery and addParticipants have been previously called
    /// @param _lotteryId - id of the lottery

    function payoutWinners(uint256 _lotteryId) public onlyOwner {
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
        // Loop over the array of winners and payout their winnings
        for (uint i = 0; i < idToLottery[_lotteryId].winners.length; i++) {
            (bool success, ) = idToLottery[_lotteryId].winners[i].call{
                value: idToLottery[_lotteryId].finalRewards[i]
            }("");
            if (!success) {
                revert Lottery__TransferFailed();
            }
        }
    }

    /// @notice Function that is only called when an emergency cashback is required (for example funds are stuck)
    /// Keep in mind that the money gets returned to the author of the giveaway
    /// @param _lotteryId - id of the lottery

    function emergencyCashback(uint256 _lotteryId) public onlyOwner {
        address payable author = idToLottery[_lotteryId].author;
        uint256 amount = idToLottery[_lotteryId].reward;
        idToLottery[_lotteryId].status = LotteryState.CLOSED;
        (bool success, ) = author.call{value: amount}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
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

    function getLotteryPrize(uint256 _lotteryId) public view returns (uint256) {
        return idToLottery[_lotteryId].reward;
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

    function getLotteryType(
        uint256 _lotteryId
    ) public view returns (LotteryType) {
        return idToLottery[_lotteryId].lotteryType;
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

    function getRewardProportions(
        uint256 _lotteryId
    ) public view returns (uint256[] memory) {
        return idToLottery[_lotteryId].rewardProportions;
    }

    function getFinalRewards(
        uint256 _lotteryId
    ) public view returns (uint256[] memory) {
        return idToLottery[_lotteryId].finalRewards;
    }

    function checkIfLotteryExists(
        uint256 _lotteryId
    ) public view returns (bool) {
        return idToLottery[_lotteryId].exists;
    }
}
