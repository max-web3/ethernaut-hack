// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Deployer {
    function deploy() public returns (address addr) {
        bytes memory bytecode = hex"602a60005260206000f3";
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }
    }
}
