//SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // Before startBroadcast -> Not a "real" tx
        HelperConfig helpConfig = new HelperConfig();
        address ethUsdPriceFeed = helpConfig.activeNetworkConfig();

        // After startBoradcast -> Real tx
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
