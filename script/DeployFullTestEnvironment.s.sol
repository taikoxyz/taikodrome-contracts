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

contract DeployFullTestEnvironment is Script {
    // Core contract addresses
    address constant ROUTER = 0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1;
    address constant POOL_FACTORY = 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318;
    address constant WETH = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    address constant AERO = 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== Deploying Full Test Environment ===");
        console.log("Deployer:", deployer);
        console.log("");
        
        // Deploy Mock Tokens
        console.log("=== Deploying Mock Tokens ===");
        MockERC20Mintable usdc = new MockERC20Mintable("USD Coin", "USDC", 6);
        MockERC20Mintable dai = new MockERC20Mintable("Dai Stablecoin", "DAI", 18);
        MockERC20Mintable wbtc = new MockERC20Mintable("Wrapped Bitcoin", "WBTC", 8);
        MockERC20Mintable link = new MockERC20Mintable("Chainlink", "LINK", 18);
        
        console.log("USDC:", address(usdc));
        console.log("DAI:", address(dai));
        console.log("WBTC:", address(wbtc));
        console.log("LINK:", address(link));
        
        // Mint tokens to deployer
        console.log("");
        console.log("=== Minting Tokens ===");
        uint256 usdcAmount = 10_000_000 * 10**6;  // 10M USDC
        uint256 daiAmount = 10_000_000 * 10**18;  // 10M DAI
        uint256 wbtcAmount = 1000 * 10**8;        // 1000 WBTC
        uint256 linkAmount = 1_000_000 * 10**18;  // 1M LINK
        
        usdc.mint(deployer, usdcAmount);
        dai.mint(deployer, daiAmount);
        wbtc.mint(deployer, wbtcAmount);
        link.mint(deployer, linkAmount);
        
        // Also mint some AERO tokens to deployer (assuming minter permissions)
        // Note: This might fail if the deployer doesn't have minting permissions
        try MockERC20Mintable(AERO).mint(deployer, 10_000_000 * 10**18) {
            console.log("Minted 10M AERO to deployer");
        } catch {
            console.log("Could not mint AERO (no permissions)");
        }
        
        console.log("Token balances minted successfully");
        
        // Create pools
        console.log("");
        console.log("=== Creating Liquidity Pools ===");
        IPoolFactory poolFactory = IPoolFactory(POOL_FACTORY);
        IRouter router = IRouter(ROUTER);
        
        // Create various pool types
        address wethUsdcPool = poolFactory.createPool(WETH, address(usdc), false);
        console.log("WETH/USDC Volatile Pool:", wethUsdcPool);
        
        address usdcDaiPool = poolFactory.createPool(address(usdc), address(dai), true);
        console.log("USDC/DAI Stable Pool:", usdcDaiPool);
        
        address wethDaiPool = poolFactory.createPool(WETH, address(dai), false);
        console.log("WETH/DAI Volatile Pool:", wethDaiPool);
        
        address wethWbtcPool = poolFactory.createPool(WETH, address(wbtc), false);
        console.log("WETH/WBTC Volatile Pool:", wethWbtcPool);
        
        address wethAeroPool = poolFactory.createPool(WETH, AERO, false);
        console.log("WETH/AERO Volatile Pool:", wethAeroPool);
        
        address linkUsdcPool = poolFactory.createPool(address(link), address(usdc), false);
        console.log("LINK/USDC Volatile Pool:", linkUsdcPool);
        
        // Approve all tokens for router
        console.log("");
        console.log("=== Approving Tokens for Router ===");
        IERC20(WETH).approve(ROUTER, type(uint256).max);
        IERC20(address(usdc)).approve(ROUTER, type(uint256).max);
        IERC20(address(dai)).approve(ROUTER, type(uint256).max);
        IERC20(address(wbtc)).approve(ROUTER, type(uint256).max);
        IERC20(address(link)).approve(ROUTER, type(uint256).max);
        IERC20(AERO).approve(ROUTER, type(uint256).max);
        console.log("All tokens approved");
        
        // Add initial liquidity to pools
        console.log("");
        console.log("=== Adding Initial Liquidity ===");
        
        // 1. WETH/USDC - Major trading pair
        addLiquidity(router, WETH, address(usdc), false, 100 ether, 300000 * 10**6);
        console.log("Added 100 WETH + 300k USDC");
        
        // 2. USDC/DAI - Stable pair
        addLiquidity(router, address(usdc), address(dai), true, 500000 * 10**6, 500000 * 10**18);
        console.log("Added 500k USDC + 500k DAI");
        
        // 3. WETH/DAI
        addLiquidity(router, WETH, address(dai), false, 50 ether, 150000 * 10**18);
        console.log("Added 50 WETH + 150k DAI");
        
        // 4. WETH/WBTC
        addLiquidity(router, WETH, address(wbtc), false, 200 ether, 10 * 10**8);
        console.log("Added 200 WETH + 10 WBTC");
        
        // 5. WETH/AERO (if we have AERO)
        uint256 aeroBalance = IERC20(AERO).balanceOf(deployer);
        if (aeroBalance > 0) {
            addLiquidity(router, WETH, AERO, false, 50 ether, min(aeroBalance, 500000 * 10**18));
            console.log("Added WETH/AERO liquidity");
        }
        
        // 6. LINK/USDC
        addLiquidity(router, address(link), address(usdc), false, 10000 * 10**18, 150000 * 10**6);
        console.log("Added 10k LINK + 150k USDC");
        
        // Log final pool states
        console.log("");
        console.log("=== Final Pool States ===");
        logPoolInfo("WETH/USDC", wethUsdcPool);
        logPoolInfo("USDC/DAI", usdcDaiPool);
        logPoolInfo("WETH/DAI", wethDaiPool);
        logPoolInfo("WETH/WBTC", wethWbtcPool);
        logPoolInfo("WETH/AERO", wethAeroPool);
        logPoolInfo("LINK/USDC", linkUsdcPool);
        
        // Save deployment info
        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("Test tokens deployed and pools created successfully!");
        console.log("");
        console.log("Token Addresses:");
        console.log("  USDC:", address(usdc));
        console.log("  DAI:", address(dai));
        console.log("  WBTC:", address(wbtc));
        console.log("  LINK:", address(link));
        console.log("");
        console.log("Add these to your frontend configuration!");
        
        vm.stopBroadcast();
    }
    
    function addLiquidity(
        IRouter router,
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountA,
        uint256 amountB
    ) internal {
        router.addLiquidity(
            tokenA,
            tokenB,
            stable,
            amountA,
            amountB,
            0, // No min amounts for initial liquidity
            0,
            msg.sender,
            block.timestamp + 3600
        );
    }
    
    function logPoolInfo(string memory name, address poolAddress) internal view {
        IPool pool = IPool(poolAddress);
        (uint256 reserve0, uint256 reserve1,) = pool.getReserves();
        uint256 totalSupply = IERC20(poolAddress).totalSupply();
        address token0 = pool.token0();
        address token1 = pool.token1();
        
        console.log(string.concat(name, ":"));
        console.log("  Pool:", poolAddress);
        console.log("  LP Supply:", totalSupply);
        console.log("  Reserve0:", reserve0);
        console.log("  Reserve1:", reserve1);
    }
    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}