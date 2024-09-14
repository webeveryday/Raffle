// SPDX-License-Identifier: MIT

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
  // constant is the cheapest gas
  // immutable is cheap gas
  // i_ prefix for immutable variable
  uint256 private immutable i_entranceFee;

  constructor(uint256 entranceFee) {
    i_entranceFee = entranceFee;
  }
  
  function enterRaffle() public payable {}

  function pickWinner() public {}

  /** Getter Function */
  function getEntranceFee() external view returns (uint256) {
    return i_entranceFee;
  }
}