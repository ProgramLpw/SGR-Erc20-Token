// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title MyToken
 * @dev 这个代币合约增加了安全性增强功能
 */
contract MyToken is ERC20, Ownable, Pausable, ReentrancyGuard {
    // 添加一个事件来通知代币的铸造
    event TokenMinted(address indexed to, uint256 amount);
    // 添加一个事件来通知代币的燃烧
    event TokenBurned(address indexed from, uint256 amount);

    constructor() ERC20("My Token", "MYT") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * (10 ** decimals()));
    }

    /**
     * @dev 铸造新的代币给指定地址，并触发事件
     * @param to 要接收代币的地址
     * @param amount 要铸造的代币数量（未计算小数位）
     */
    function mint(address to, uint256 amount) public onlyOwner whenNotPaused nonReentrant {
        uint256 mintAmount = amount * (10 ** decimals());
        _mint(to, mintAmount);
        emit TokenMinted(to, mintAmount);
    }

    /**
     * @dev 允许用户燃烧自己的代币，并触发事件
     * @param amount 要燃烧的代币数量（未计算小数位）
     */
    function burn(uint256 amount) public whenNotPaused nonReentrant {
        uint256 burnAmount = amount * (10 ** decimals());
        _burn(msg.sender, burnAmount);
        emit TokenBurned(msg.sender, burnAmount);
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

    /**
     * @dev 在转账前进行检查，确保合约没有被暂停
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual  whenNotPaused {
        _beforeTokenTransfer(from, to, amount);
    }
}
