// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    // 构造函数，初始化代币的名称和符号
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }

    // 可实现的功能列表：

    // 1. **铸造新代币** - 仅由合约所有者执行
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // 2. **销毁代币** - 用户或合约所有者可以销毁自己的代币
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    // 3. **批量转账** - 允许一次性发送代币到多个地址
    function batchTransfer(address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length == amounts.length, "Recipients and amounts length mismatch");
        for (uint i = 0; i < recipients.length; i++) {
            transfer(recipients[i], amounts[i]);
        }
    }

    // 4. **暂停和恢复合约** - 由合约所有者控制，以应对紧急情况
    bool private _paused;

    function pause() public onlyOwner {
        _paused = true;
    }

    function unpause() public onlyOwner {
        _paused = false;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!_paused, "Token transfer is paused");
        super._beforeTokenTransfer(from, to, amount);
    }

    // 5. **设置燃烧费** - 每次转账收取一定比例的代币作为费用
    uint256 private _burnFee = 1; // 1% 燃烧费
    uint256 private constant MAX_FEE = 1000; // 最大费用为 10%

    function setBurnFee(uint256 burnFee) public onlyOwner {
        require(burnFee <= MAX_FEE, "Burn fee cannot exceed 10%");
        _burnFee = burnFee;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        uint256 burnAmount = amount * _burnFee / 1000;
        super._transfer(sender, address(0), burnAmount); // 燃烧费
        super._transfer(sender, recipient, amount - burnAmount); // 实际转账金额
    }

    // 6. **查看代币持有量** - 标准的 ERC20 balanceOf 功能
    function balanceOf(address account) public view virtual override returns (uint256) {
        return super.balanceOf(account);
    }

    // 7. **允许转账代币** - 标准的 ERC20 approve 功能
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        return super.approve(spender, amount);
    }

    // 8. **转账代币** - 标准的 ERC20 transfer 功能
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        return super.transfer(recipient, amount);
    }

    // 9. **代理转账代币** - 标准的 ERC20 transferFrom 功能
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }
}

// 1.铸造新代币 - 合约所有者可以增加代币供应。
// 2.销毁代币 - 用户或合约所有者可以销毁代币，减少流通中的供应量。
// 3.批量转账 - 一次性将代币发送到多个地址。
// 4.暂停和恢复 - 在紧急情况下，合约所有者可以暂停或恢复代币的转账。
// 5.设置燃烧费 - 每次转账时收取一定比例的代币作为燃烧费，以减少代币供应量。
// 6.查看代币持有量 - 查看某个地址的代币余额。
// 7.允许转账代币 - 用户授权他人从自己的账户中转出代币。
// 8.转账代币 - 基本的转账功能。
// 9.代理转账代币 - 允许通过授权来转移代币。
