// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MyToken
 * @dev 这个代币合约增加了铸造功能，只有合约所有者可以使用
 */
contract MyToken is ERC20, Ownable {
    constructor() ERC20("My Token", "MYT") Ownable(msg.sender) {
        _mint(msg.sender, 1400000000 * (10 ** decimals()));
    }

    /**
     * @dev 铸造新的代币给指定地址
     * @param to 要接收代币的地址
     * @param amount 要铸造的代币数量（未计算小数位）
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount * (10 ** decimals()));
    }
}
