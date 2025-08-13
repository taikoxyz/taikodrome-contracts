// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "../test/utils/MockWETH.sol";

contract DeployWETH is Script {
    function run() public returns (address) {
        uint256 deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");
        
        vm.startBroadcast(deployPrivateKey);
        
        MockWETH weth = new MockWETH();
        
        vm.stopBroadcast();
        
        console.log("WETH deployed at:", address(weth));
        return address(weth);
    }
}