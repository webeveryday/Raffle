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

// This is NATSPEC
// @notice for anybody reading this code base
// @dev for notes to developer
/**
 * @title A sample Raffle Contract
 * @author webeveryday
 * @notice This contract is for creating a sample raffle
 * @dev It implements Chainlink VRFv2 and Chainlink Automation
 */
contract Raffe {
  /** Errors */
  // Give prefix of the contract name and then two underscores before the error for best practices
  error Raffe__SendMoreToEnterRaffle();

  // constant is the cheapest gas
  // immutable is cheap gas
  // i_ prefix for immutable variable
  uint256 private immutable i_entranceFee;

  // Interval between lottery rounds
  // @dev The duration of the lottery in seconds
  uint256 private immutable i_interval;

  uint256 private s_lastTimeStamp;

  // Keep track of all players
  // Dynamic Array
  // It payable because one of the participants registered in this array will be paid the ETH prize
  address payable[] private s_players;

  /** Events */
  event RaffleEntered(address indexed player);

  constructor(uint256 entranceFee, uint256 interval) {
    i_entranceFee = entranceFee;
    i_interval = interval;
    s_lastTimeStamp = block.timestamp;
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
  }

  /** Getter Function */
  function getEntranceFee() external view returns (uint256) {
    return i_entranceFee;
  }
}