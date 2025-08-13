// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPoolFactory} from "../contracts/interfaces/factories/IPoolFactory.sol";
import {IRouter} from "../contracts/interfaces/IRouter.sol";
import {IPool} from "../contracts/interfaces/IPool.sol";

contract DeployTestPools is Script {
    // Contract addresses from deployment
    address constant ROUTER = 0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1;
    address constant POOL_FACTORY = 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318;
    address constant WETH = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    address constant AERO = 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853;
    
    // Test token addresses will be set during deployment
    address USDC;
    address DAI;
    address WBTC;
    address LINK;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        IPoolFactory poolFactory = IPoolFactory(POOL_FACTORY);
        IRouter router = IRouter(ROUTER);
        
        console.log("=== Creating Test Pools ===");
        console.log("Deployer:", deployer);
        console.log("");
        
        // Create pools with different characteristics
        // 1. WETH/USDC - Volatile pool (most common trading pair)
        address wethUsdcPool = poolFactory.createPool(WETH, USDC, false);
        console.log("WETH/USDC Volatile Pool:", wethUsdcPool);
        
        // 2. USDC/DAI - Stable pool (stablecoin pair)
        address usdcDaiPool = poolFactory.createPool(USDC, DAI, true);
        console.log("USDC/DAI Stable Pool:", usdcDaiPool);
        
        // 3. WETH/DAI - Volatile pool
        address wethDaiPool = poolFactory.createPool(WETH, DAI, false);
        console.log("WETH/DAI Volatile Pool:", wethDaiPool);
        
        // 4. WETH/WBTC - Volatile pool (correlated assets)
        address wethWbtcPool = poolFactory.createPool(WETH, WBTC, false);
        console.log("WETH/WBTC Volatile Pool:", wethWbtcPool);
        
        // 5. WETH/AERO - Volatile pool (native token pair)
        address wethAeroPool = poolFactory.createPool(WETH, AERO, false);
        console.log("WETH/AERO Volatile Pool:", wethAeroPool);
        
        // 6. LINK/USDC - Volatile pool
        address linkUsdcPool = poolFactory.createPool(LINK, USDC, false);
        console.log("LINK/USDC Volatile Pool:", linkUsdcPool);
        
        console.log("");
        console.log("=== Adding Initial Liquidity ===");
        
        // Add liquidity to pools
        // Note: Need to approve tokens first
        
        // 1. Add liquidity to WETH/USDC pool
        uint256 wethAmount = 10 ether;
        uint256 usdcAmount = 30000 * 10**6; // $30k worth at $3000/ETH
        
        IERC20(WETH).approve(ROUTER, type(uint256).max);
        IERC20(USDC).approve(ROUTER, type(uint256).max);
        
        router.addLiquidity(
            WETH,
            USDC,
            false, // volatile
            wethAmount,
            usdcAmount,
            0, // min amounts for initial liquidity
            0,
            deployer,
            block.timestamp + 3600
        );
        console.log("Added liquidity to WETH/USDC pool");
        
        // 2. Add liquidity to USDC/DAI stable pool
        uint256 stableAmount = 100000 * 10**6; // 100k USDC
        uint256 daiAmount = 100000 * 10**18; // 100k DAI
        
        IERC20(DAI).approve(ROUTER, type(uint256).max);
        
        router.addLiquidity(
            USDC,
            DAI,
            true, // stable
            stableAmount,
            daiAmount,
            0,
            0,
            deployer,
            block.timestamp + 3600
        );
        console.log("Added liquidity to USDC/DAI pool");
        
        // 3. Add liquidity to WETH/DAI pool
        uint256 wethAmount2 = 5 ether;
        uint256 daiAmount2 = 15000 * 10**18; // $15k worth
        
        router.addLiquidity(
            WETH,
            DAI,
            false,
            wethAmount2,
            daiAmount2,
            0,
            0,
            deployer,
            block.timestamp + 3600
        );
        console.log("Added liquidity to WETH/DAI pool");
        
        // 4. Add liquidity to WETH/WBTC pool
        uint256 wethAmount3 = 20 ether;
        uint256 wbtcAmount = 1 * 10**8; // 1 WBTC
        
        IERC20(WBTC).approve(ROUTER, type(uint256).max);
        
        router.addLiquidity(
            WETH,
            WBTC,
            false,
            wethAmount3,
            wbtcAmount,
            0,
            0,
            deployer,
            block.timestamp + 3600
        );
        console.log("Added liquidity to WETH/WBTC pool");
        
        // 5. Add liquidity to WETH/AERO pool
        uint256 wethAmount4 = 5 ether;
        uint256 aeroAmount = 50000 * 10**18; // 50k AERO
        
        IERC20(AERO).approve(ROUTER, type(uint256).max);
        
        router.addLiquidity(
            WETH,
            AERO,
            false,
            wethAmount4,
            aeroAmount,
            0,
            0,
            deployer,
            block.timestamp + 3600
        );
        console.log("Added liquidity to WETH/AERO pool");
        
        // 6. Add liquidity to LINK/USDC pool
        uint256 linkAmount = 1000 * 10**18; // 1000 LINK
        uint256 usdcAmount2 = 15000 * 10**6; // $15k worth at $15/LINK
        
        IERC20(LINK).approve(ROUTER, type(uint256).max);
        
        router.addLiquidity(
            LINK,
            USDC,
            false,
            linkAmount,
            usdcAmount2,
            0,
            0,
            deployer,
            block.timestamp + 3600
        );
        console.log("Added liquidity to LINK/USDC pool");
        
        console.log("");
        console.log("=== Pool Information ===");
        
        // Log pool information
        logPoolInfo("WETH/USDC", wethUsdcPool);
        logPoolInfo("USDC/DAI", usdcDaiPool);
        logPoolInfo("WETH/DAI", wethDaiPool);
        logPoolInfo("WETH/WBTC", wethWbtcPool);
        logPoolInfo("WETH/AERO", wethAeroPool);
        logPoolInfo("LINK/USDC", linkUsdcPool);
        
        vm.stopBroadcast();
    }
    
    function logPoolInfo(string memory name, address poolAddress) internal view {
        IPool pool = IPool(poolAddress);
        (uint256 reserve0, uint256 reserve1,) = pool.getReserves();
        uint256 totalSupply = IERC20(poolAddress).totalSupply();
        
        console.log("");
        console.log(name, "Pool Info:");
        console.log("  Address:", poolAddress);
        console.log("  Total Supply:", totalSupply);
        console.log("  Reserve0:", reserve0);
        console.log("  Reserve1:", reserve1);
    }
}