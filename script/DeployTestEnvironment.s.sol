// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20Mintable is ERC20 {
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract DeployTestEnvironment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Mock Tokens with mint function
        MockERC20Mintable usdc = new MockERC20Mintable("USD Coin", "USDC", 6);
        MockERC20Mintable dai = new MockERC20Mintable("Dai Stablecoin", "DAI", 18);
        MockERC20Mintable wbtc = new MockERC20Mintable("Wrapped Bitcoin", "WBTC", 8);
        MockERC20Mintable link = new MockERC20Mintable("Chainlink", "LINK", 18);
        
        // Mint tokens to deployer
        uint256 usdcAmount = 1_000_000 * 10**6;  // 1M USDC
        uint256 daiAmount = 1_000_000 * 10**18;  // 1M DAI
        uint256 wbtcAmount = 100 * 10**8;        // 100 WBTC
        uint256 linkAmount = 100_000 * 10**18;   // 100k LINK
        
        usdc.mint(deployer, usdcAmount);
        dai.mint(deployer, daiAmount);
        wbtc.mint(deployer, wbtcAmount);
        link.mint(deployer, linkAmount);
        
        // Log deployed addresses
        console.log("=== Mock Tokens Deployed ===");
        console.log("USDC:", address(usdc));
        console.log("DAI:", address(dai));
        console.log("WBTC:", address(wbtc));
        console.log("LINK:", address(link));
        console.log("");
        console.log("=== Token Balances ===");
        console.log("USDC balance:", usdc.balanceOf(deployer) / 10**6, "USDC");
        console.log("DAI balance:", dai.balanceOf(deployer) / 10**18, "DAI");
        console.log("WBTC balance:", wbtc.balanceOf(deployer) / 10**8, "WBTC");
        console.log("LINK balance:", link.balanceOf(deployer) / 10**18, "LINK");
        
        vm.stopBroadcast();
    }
}