// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumner} from "./Interactions.s.sol";

contract DeployRaffle is Script {
  function run() public {
    deployContract();
  }

  function deployContract() public returns (Raffle, HelperConfig) {
    HelperConfig helperConfig = new HelperConfig();
    // local -> deploy mocks, get local config
    // sepolia -> get sepolia config
    HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

    if (config.subscriptionId == 0) {
      // Create subscription
      CreateSubscription createSubscription = new CreateSubscription();
      (config.subscriptionId, config.vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator);

      // Fund subscription
      FundSubscription fundSubscription = new FundSubscription();
      fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link);
    }

    vm.startBroadcast();
    Raffle raffle = new Raffle(
      config.entranceFee,
      config.interval,
      config.vrfCoordinator,
      config.gasLane,
      config.subscriptionId,
      config.callbackGasLimit
    );
    vm.stopBroadcast();
   
    AddConsumner addConsumner = new AddConsumner();
    // Don't need to broadcast...
    addConsumner.addConsumner(address(raffle), config.vrfCoordinator, config.subscriptionId);

    return (raffle, helperConfig);
  }
}