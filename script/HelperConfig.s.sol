//SPDX-License-Identifier:MIT

//1.Deploy mocks when we are on a local anvil chain
//2.Keep track of contract address across different chains
//SEPOLIA ETH/USD
//Mainnet ETH/USD

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // If we are on a local anvil, we deploy mocks
    // Otherwise, grab the existing address from the live network
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        //price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        //price feed address
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: 0x5C00128d4d1c2F4f652C267d7bcdD7aC99C16E16
        });
        return ethConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // 有这个判断的话，就可以判断下，如果已经在 anvil 上部署了一个 MockV3Aggregator 合约，那就不需要重复部署了
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // price feed address

        // 1. Deploy the mocks
        // 2. Return the mock address

        // 在 anvil chain 发布 mock 合约，有 vm 关键字，定义函数 getAnvilEthConfig 就不能有 pure 关键字
        vm.startBroadcast();
        // 下面的8，是由于 eth 的decimal 为 8 位；2000e8这个是初始化
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}
