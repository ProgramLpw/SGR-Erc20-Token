// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title MyToken
 * @dev 这个代币合约现在可以被暂停
 */
contract MyToken is ERC20, Ownable, Pausable {
    constructor() ERC20("My Token", "MYT") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * (10 ** decimals()));
    }

    /**
     * @dev 铸造新的代币给指定地址
     * @param to 要接收代币的地址
     * @param amount 要铸造的代币数量（未计算小数位）
     */
    function mint(address to, uint256 amount) public onlyOwner whenNotPaused {
        _mint(to, amount * (10 ** decimals()));
    }

    /**
     * @dev 允许用户燃烧自己的代币
     * @param amount 要燃烧的代币数量（未计算小数位）
     */
    function burn(uint256 amount) public whenNotPaused {
        _burn(msg.sender, amount * (10 ** decimals()));
    }

    /**
     * @dev 暂停合约，阻止代币的转账
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev 恢复合约，恢复代币的转账
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}
