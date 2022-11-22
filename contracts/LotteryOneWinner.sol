// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

error Lottery__NotOwner();
error Lottery__NotEnoughPlayers();
error Lottery__TransferFailed();

contract LotteryOneWinner is ReentrancyGuard, VRFConsumerBaseV2 {
    /* Lottery Variables */
    address payable[] private participants;
    address immutable i_owner;
    address private s_winner;
    uint256 private lotteryStake;
    uint256 private lotteryId;
    enum LotteryState {
        OPEN,
        CLOSED
    }

    /* Chainlink VRF Variables */
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Structs

    struct Lottery {
        address author;
        LotteryState status;
        uint256 reward;
        address payable[] participants;
    }

    /* Mappings */
    mapping(uint256 => Lottery) idToLottery;

    /* Events */
    event RequestedRaffleWinner(uint256 indexed requestId);
    event AddressesAdded(
        uint256 indexed lotteryId,
        address payable[] addresses
    );
    event WinnerPicked(address indexed recentWinner);

    /* Constructor */
    constructor(
        uint64 _subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) payable VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed) {
        i_owner = msg.sender;
        i_vrfCoordinator = VRFCoordinatorV2Interface(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        );
        subscriptionId = _subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        lotteryStake = msg.value;
        lotteryId = 0;
    }

    /* Modifiers */

    modifier onlyOwner() {
        require(msg.sender == i_owner);
        _;
    }

    /* Main Functions */

    function openLottery(address _author) public payable onlyOwner {
        lotteryId += 1;
        idToLottery[lotteryId].author = _author;
        idToLottery[lotteryId].status = LotteryState.OPEN;
        idToLottery[lotteryId].reward = msg.value;
    }

    function addLotteryParticipants(
        uint256 _lotteryId,
        address payable[] memory _addresses
    ) public onlyOwner {
        idToLottery[_lotteryId].participants = _addresses;
        emit AddressesAdded(_lotteryId, _addresses);
    }

    function requestRandomWords() external {
        if (participants.length <= 0) {
            revert Lottery__NotEnoughPlayers();
        }
        if (msg.sender != i_owner) {
            revert Lottery__NotOwner();
        }
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256, /* _requestId */
        uint256[] memory _randomWords
    ) internal override nonReentrant {
        uint256 indexOfWinner = _randomWords[0] % participants.length;
        address payable recentWinner = participants[indexOfWinner];
        s_winner = recentWinner;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /* Getter Functions */

    function getRecentWinner() public view returns (address) {
        return s_winner;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getNumberOfPlayers(uint256 _lotteryId)
        public
        view
        returns (uint256)
    {
        return idToLottery[_lotteryId].participants.length;
    }

    function getParticipants(uint256 _lotteryId)
        public
        view
        returns (address payable[] memory)
    {
        return idToLottery[_lotteryId].participants;
    }

    function getLotteryStake() public view returns (uint256) {
        return lotteryStake;
    }

    function getSubscriptionId() public view returns (uint256) {
        return subscriptionId;
    }
}
