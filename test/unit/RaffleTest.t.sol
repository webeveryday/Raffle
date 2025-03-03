// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";

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
  address public PLAYER = makeAddr("Player");
  // Amount of ETH to send
  uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

  // Need to copy and paste events here to test
  event RaffleEntered(address indexed player);
  event WinnerPicked(address indexed winner);

  function setUp() external {
    DeployRaffle deployer = new DeployRaffle();
    (raffle, helperConfig) = deployer.deployContract();

    HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
    entranceFee = config.entranceFee;
    interval = config.interval;
    vrfCoordinator = config.vrfCoordinator;
    gasLane = config.gasLane;
    callbackGasLimit = config.callbackGasLimit;
    subscriptionId = config.subscriptionId;

    // Send ETH to player
    vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
  }

  function testRaffleInitializesInOpenState() public view {
    assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
  }


  // -- Enter Raffle -- //
  
  // Player enter the raffle without money
  function testRaffleRevertsWhenYouDontPayEnough() public {
    // Arrange
    vm.prank(PLAYER);
    // Act / Assert
    vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
    raffle.enterRaffle();
  }

  function testRaffleRecordsPlayersWhenTheyEnter() public {
    // Arrange
    vm.prank(PLAYER);
    // Act
    // Send money to Raffle first
    raffle.enterRaffle{value: entranceFee}();
    // Assert
    address playerRecorded = raffle.getPlayer(0);
    assert(playerRecorded == PLAYER);
  }

  function testEnterRaffleEmitsEvent() public {
    // Arrange
    vm.prank(PLAYER);
    // Act
    // first 4 parameters is for if we have `indexed` parameters in our event;
    vm.expectEmit(true, false, false, false, address(raffle));
    emit RaffleEntered(PLAYER);
    // Assert
    raffle.enterRaffle{value: entranceFee}();
  }

  function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
    // Arrange
    vm.prank(PLAYER);
    // Set up raffle
    raffle.enterRaffle{value: entranceFee}();
    // Set the `block.timestamp`
    vm.warp(block.timestamp + interval  + 1);
    // Set the `block.number`
    // Roll it by the current block plus 1
    // Add one new block
    vm.roll(block.number + 1);
    raffle.performUpkeep("");

    // Act
    vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
    vm.prank(PLAYER);     // Make sure we are player
    // Calling `enterRaffle` to check if it reverts as it should
    raffle.enterRaffle{value: entranceFee}();
  }

  /**
  * CHECK UPKEEP
  */

  function testCheckUpKeepReturnsFalseIfItHasNoBalance() public {
    // Arrange
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);

    // Act
    (bool upkeepNeeded,) = raffle.checkUpkeep("");

    // Assert
    assert(!upkeepNeeded);
  }

  function testCheckUpKeepReturnsFalseIfRaffleIsntOpen() public {
    // Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval  + 1);
    vm.roll(block.number + 1);
    raffle.performUpkeep("");

    // Act
    (bool upkeepNeeded,) = raffle.checkUpkeep("");

    // Assert
    assert(!upkeepNeeded);
  }

  /**
  * PERFORM UPKEEP
  */

  function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
    // Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval  + 1);
    vm.roll(block.number + 1);

    // Act / Assert
    raffle.performUpkeep("");
  }

  function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
    // Arrange
    uint256 currentBalance = 0;
    uint256 numPlayers = 0;
    Raffle.RaffleState rState = raffle.getRaffleState();

    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    currentBalance = currentBalance + entranceFee;
    numPlayers = 1;

    // Act / Assert
    vm.expectRevert(
      abi.encodeWithSelector(
        Raffle.Raffle__UpKeepNotNeeded.selector,
        currentBalance,
        numPlayers,
        rState
      )
    );

    raffle.performUpkeep("");
  }

  // Test for data from emitted events in our test
  function testPerformUpkeepUpkeepUpdatesRaffleAndEmitsRequestId() public {
    // Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval  + 1);
    vm.roll(block.number + 1);

    // Act
    // Keep track of event emit and put them into an array
    vm.recordLogs();
    raffle.performUpkeep("");
    Vm.Log[] memory entries = vm.getRecordedLogs();   // This a special log
    bytes32 requestId = entries[1].topics[1];

    // Assert
    Raffle.RaffleState raffleState = raffle.getRaffleState();
    assert(uint256(requestId) > 0);     // Check if the request ID is not empty
    assert(uint256(raffleState) == 1);
  }
}