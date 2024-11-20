// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MyToken
 * @dev 这是一个简单的ERC20代币合约实现
 */
contract MyToken is ERC20 {
    constructor() ERC20("My Token", "MYT") {
        // 在构造函数中初始化代币名称和符号，并为合约创建者铸造100万个代币
        _mint(msg.sender, 1400000000 * (10 ** decimals()));
    }
}
