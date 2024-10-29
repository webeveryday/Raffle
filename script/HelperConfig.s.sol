// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

abstract contract CodeConstants {
  uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
}

contract HelperConfig is CodeConstants, Script {
  struct NetworkConfig {
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
  }

  NetworkConfig public localNetworkConfig;
  mapping(uint256 chainId => NetworkConfig) public networkConfigs;

  constructor() {
    networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
  }

  function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
    return NetworkConfig({
        entranceFee: 0.01 ether, // 1e16
        interval: 30, // 30 seconds
        vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
        gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
        callbackGasLimit: 500000, // 500,000 gas
        subscriptionId: 0
    });
  }
}