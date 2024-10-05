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
contract Raffe is VRFConsumerBaseV2Plus{
  /** Errors */
  // Give prefix of the contract name and then two underscores before the error for best practices
  error Raffe__SendMoreToEnterRaffle();

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

  // Keep track of all players
  // Dynamic Array
  // It payable because one of the participants registered in this array will be paid the ETH prize
  address payable[] private s_players;

  /** Events */
  event RaffleEntered(address indexed player);

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

    // Set the value to VRFConsumerBaseV2Plus state variable
    //s_vrfCoordinator.requestRandomWords();
  }
  
  function enterRaffle() external payable {
    // EX 1 - Require Statement
    // This cost a lot of gas to have this as a string
    // require(msg.value >= i_entranceFee, "Not enough ETH sent!");

    // EX 2 - Custom Error
    if (msg.value >= i_entranceFee) {
      revert Raffe__SendMoreToEnterRaffle();
    }

    // EX 3 - Custom Error
    // This feature is only available if you compile your Solidity with IR, it takes a lot of time to compile
    // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());

    s_players.push(payable(msg.sender));

    // Use event when we update something in storage
    // 1. Makes migration easier
    // 2. Makes front end "indexing" easier
    emit RaffleEntered(msg.sender);
    
  }

  // 1. Get a random number
  // 2. Use random number to pick a player
  // 3. Be automatically called
  function pickWinner() external {
    // Check to see if enough time has passed

    // 1000 - 900 = 100, 50
    if ((block.timestamp - s_lastTimeStamp) > i_interval) {
      revert();
    }

    // Get our random number 2.5
    // 1. Request RNG
    // 2. Get RNG
    // Call to the chainlink coordinator to the chainlink node
    VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
      keyHash: i_keyHash,       // The price you are willing to pay
      subId: i_subscriptionId,    // Where to fund the oracle gas for working with chainlink VRF
      requestConfirmations: REQUEST_CONFIRMATIONS,    // How many blocks it should wait for the chainlink node to give us our random number
      callbackGasLimit: i_callbackGasLimit,     // The max amount of gas you willing to pay
      numWords: NUM_WORDS,
      // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
      extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
    });
    uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
  }

  function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override{}

  /** Getter Function */
  function getEntranceFee() external view returns (uint256) {
    return i_entranceFee;
  }
}