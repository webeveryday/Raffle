// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {
  Raffle public raffle;
  HelperConfig public helperConfig;

  uint256 entranceFee;
  uint256 interval;
  address vrfCoordinator;
  bytes32 gasLane;
  uint256 subscriptionId;
  uint32 callbackGasLimit;

  // Create an address based on the string
  address public PLAYER = makeAddr("player");
  // Amount of ETH to send
  uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

  function setUp() external {
    DeployRaffle deployer = new DeployRaffle();
    (raffe, helperConfig) = deployer.deployContract();

    HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
    entranceFee = config.entranceFee;
    interval = config.interval;
    vrfCoordinator = config.vrfCoordinator;
    gasLane = config.gasLane;
    callbackGasLimit = config.callbackGasLimit;
    subscriptionId = config.subscriptionId;
  }

  function testRaffleInitializesInOpenState() public view {
    assert(raffle.getRaffleState() == Raffe.RaffleState.OPEN);
  }
}