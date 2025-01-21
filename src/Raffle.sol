// SPDX-License-Identifier: MIT

// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract
// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions
// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions

// external & public view & pure functions

pragma solidity ^0.8.18;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

// This is NATSPEC
// @notice for anybody reading this code base
// @dev for notes to developer
/**
 * @title A sample Raffle Contract
 * @author webeveryday
 * @notice This contract is for creating a sample raffle
 * @dev It implements Chainlink VRFv2 and Chainlink Automation
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Errors
     */
    // Give prefix of the contract name and then two underscores before the error for best practices
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpKeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    /**
     * Type Declarations
     */

    // Enum is a type declaration
    // Enums can be used to create custom types with a finite set of constant values
    enum RaffleState {
        // Each one of these states can be converted to integer
        OPEN, // 0
        CALCULATING // 1

    }

    /**
     * State Variables
     */

    // Cap locks for naming constant variables
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // constant is the cheapest gas
    // immutable is cheap gas
    // i_ prefix for immutable variable
    uint256 private immutable i_entranceFee;

    // Interval between lottery rounds
    // @dev The duration of the lottery in seconds
    uint256 private immutable i_interval;

    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;

    // Keep track of all players
    // Dynamic Array
    // It payable because one of the participants registered in this array will be paid the ETH prize
    address payable[] private s_players;

    RaffleState private s_raffleState;

    /**
     * Events
     */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_raffleState = RaffleState.OPEN; // Same as RaffleState[0]

        // Set the value to VRFConsumerBaseV2Plus state variable
        //s_vrfCoordinator.requestRandomWords();
    }

    function enterRaffle() external payable {
        // EX 1 - Require Statement
        // This cost a lot of gas to have this as a string
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!");

        // EX 2 - Custom Error
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        // EX 3 - Custom Error
        // This feature is only available if you compile your Solidity with IR, it takes a lot of time to compile
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));

        // Use event when we update something in storage
        // 1. Makes migration easier
        // 2. Makes front end "indexing" easier
        emit RaffleEntered(msg.sender);
    }

    // upkeepNeeded is true or false ex: Is it time to pick the winner?
    // performData is information about what to do with upkeep
    // When should the winner be picked?
    /**
     * @dev This is the function that Chainlink nodes will call to see if the lottery is ready to have a winner picked.
     * The following should be true in order for upkeepNeeded to be true:
     * 1. The time interval has passed between raffle runs
     * 2. The lottery is open
     * 3. The contract has ETH (has players)
     * 4. Implicitly, your subscription has LINK
     * @param - ignored
     * @return upkeepNeeded - true if it's time to restart the lottery
     * @return - ignored
    */
    function checkUpkeep(bytes memory /* checkData */)
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        // Return True if all is true
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;

        // "" for returning null
        return (upkeepNeeded, "");
    }

    // 1. Get a random number
    // 2. Use random number to pick a player
    // 3. Be automatically called
    function performUpkeep(bytes calldata /* performData */) external {
        // Check to see if enough time has passed
        // 1000 - 900 = 100, 50
        // if ((block.timestamp - s_lastTimeStamp) > i_interval) {
        //     revert();
        // }
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            // You can add parameters to the custom error for more information about the error
            revert Raffle__UpKeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;

        // Get our random number 2.5
        // 1. Request RNG
        // 2. Get RNG
        // Call to the chainlink coordinator to the chainlink node
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash, // The price you are willing to pay
            subId: i_subscriptionId, // Where to fund the oracle gas for working with chainlink VRF
            requestConfirmations: REQUEST_CONFIRMATIONS, // How many blocks it should wait for the chainlink node to give us our random number
            callbackGasLimit: i_callbackGasLimit, // The max amount of gas you willing to pay
            numWords: NUM_WORDS,
            // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    // CEI: Checks, Effects, Interactions Patten (Methodology)
    // To defend against re-entrancy attacks

    // This function is called when Chainlink node give us the random number
    // It get called from rawFulfilRandomWords in VRFConsumerBaseV2Plus
    // Add keyword 'override' because of inheriting VRFConsumerBaseV2Plus in the abstract contract, it was marked as virtual, which mean it is meant to be overidden (update or implemented in our contract)
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // Checks */
        // -> require(), conditionals
        // Start with the checks on the top for gas efficient

        // Effects (Internal Contract State) */
        
        // Pick the winner
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        // Reset Lottery
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);       // Reset to a brand new blank array
        s_lastTimeStamp = block.timestamp;

        emit WinnerPicked(s_recentWinner);

        // Interactions (External Contract Interactions) */

        // Pay the winner
        (bool success,) = recentWinner.call{value: address(this).balance}("");

        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Getter Function
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }
}
