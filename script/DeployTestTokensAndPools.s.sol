// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPoolFactory} from "../contracts/interfaces/factories/IPoolFactory.sol";
import {IRouter} from "../contracts/interfaces/IRouter.sol";
import {IPool} from "../contracts/interfaces/IPool.sol";

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

contract DeployTestTokensAndPools is Script {
    // Core contract addresses
    address constant ROUTER = 0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1;
    address constant POOL_FACTORY = 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318;
    address constant WETH = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    address constant AERO = 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853;

    function run() external {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== Deploying Test Tokens ===");
        console.log("Deployer:", deployer);
        
        // Deploy Mock Tokens
        MockERC20Mintable usdc = new MockERC20Mintable("USD Coin", "USDC", 6);
        MockERC20Mintable dai = new MockERC20Mintable("Dai Stablecoin", "DAI", 18);
        MockERC20Mintable wbtc = new MockERC20Mintable("Wrapped Bitcoin", "WBTC", 8);
        MockERC20Mintable link = new MockERC20Mintable("Chainlink", "LINK", 18);
        
        console.log("USDC:", address(usdc));
        console.log("DAI:", address(dai));
        console.log("WBTC:", address(wbtc));
        console.log("LINK:", address(link));
        
        // Mint tokens
        usdc.mint(deployer, 10_000_000 * 10**6);
        dai.mint(deployer, 10_000_000 * 10**18);
        wbtc.mint(deployer, 1000 * 10**8);
        link.mint(deployer, 1_000_000 * 10**18);
        
        // Create pools
        IPoolFactory poolFactory = IPoolFactory(POOL_FACTORY);
        
        console.log("");
        console.log("=== Creating Pools ===");
        
        address wethUsdcPool = poolFactory.createPool(WETH, address(usdc), false);
        console.log("WETH/USDC Pool:", wethUsdcPool);
        
        address usdcDaiPool = poolFactory.createPool(address(usdc), address(dai), true);
        console.log("USDC/DAI Pool:", usdcDaiPool);
        
        address wethDaiPool = poolFactory.createPool(WETH, address(dai), false);
        console.log("WETH/DAI Pool:", wethDaiPool);
        
        address wethWbtcPool = poolFactory.createPool(WETH, address(wbtc), false);
        console.log("WETH/WBTC Pool:", wethWbtcPool);
        
        // Approve router
        IERC20(WETH).approve(ROUTER, type(uint256).max);
        IERC20(address(usdc)).approve(ROUTER, type(uint256).max);
        IERC20(address(dai)).approve(ROUTER, type(uint256).max);
        IERC20(address(wbtc)).approve(ROUTER, type(uint256).max);
        
        // Add liquidity
        IRouter router = IRouter(ROUTER);
        
        console.log("");
        console.log("=== Adding Liquidity ===");
        
        // Add liquidity to WETH/USDC
        router.addLiquidity(
            WETH, address(usdc), false,
            10 ether, 30000 * 10**6,
            0, 0, deployer, block.timestamp + 3600
        );
        console.log("Added liquidity to WETH/USDC");
        
        // Add liquidity to USDC/DAI
        router.addLiquidity(
            address(usdc), address(dai), true,
            100000 * 10**6, 100000 * 10**18,
            0, 0, deployer, block.timestamp + 3600
        );
        console.log("Added liquidity to USDC/DAI");
        
        // Add liquidity to WETH/DAI
        router.addLiquidity(
            WETH, address(dai), false,
            5 ether, 15000 * 10**18,
            0, 0, deployer, block.timestamp + 3600
        );
        console.log("Added liquidity to WETH/DAI");
        
        // Add liquidity to WETH/WBTC
        router.addLiquidity(
            WETH, address(wbtc), false,
            20 ether, 1 * 10**8,
            0, 0, deployer, block.timestamp + 3600
        );
        console.log("Added liquidity to WETH/WBTC");
        
        console.log("");
        console.log("=== Deployment Complete ===");
        console.log("Update frontend/src/lib/config/testTokens.ts with:");
        console.log("USDC:", address(usdc));
        console.log("DAI:", address(dai));
        console.log("WBTC:", address(wbtc));
        console.log("LINK:", address(link));
        
        vm.stopBroadcast();
    }
}