// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title SGR Token Contract
 * @dev 实现一个可暂停、可限制供应量的 ERC20 代币
 */
contract SGR is ERC20, Ownable, Pausable {
    bool public mintingFinished;
    uint256 public constant MAX_SUPPLY = 1000000000 * (10 ** 18); // 10亿代币上限

    uint256 public mintingAllowance;  // 添加铸币配额
    uint256 public constant MINTING_PERIOD = 30 days;  // 铸币周期
    uint256 public lastMintingTime;    // 上次铸币时间

    // 添加黑名单映射
    mapping(address => bool) public blacklist;
    
    // 添加黑名单事件
    event BlacklistUpdated(address indexed account, bool isBlacklisted);
    
    event MintingFinished();
    event MintingAllowanceUpdated(uint256 newAllowance);
    event TokensMinted(address indexed to, uint256 amount);

    // 添加锁定期映射
    mapping(address => uint256) public lockedUntil;
    
    // 添加锁定事件
    event TokensLocked(address indexed account, uint256 unlockTime);
    
    // 铸币者角色映射
    mapping(address => bool) public minters;
    
    event MinterUpdated(address indexed account, bool isMinter);
    
    event TokensBurned(address indexed from, uint256 amount);
    
    /**
     * @dev 构造函数
     * @param initialSupply 初始代币供应量（未计算小数位）
     * 初始化代币名称为 "Sino Great Revival"，符号为 "SGR"
     * 检查初始供应量是否超过最大供应量限制
     */
    constructor(uint256 initialSupply) 
        ERC20("Sino Great Revival", "SGR") 
        Ownable(msg.sender)
    {
        require(initialSupply * (10 ** decimals()) <= MAX_SUPPLY, "Initial supply exceeds max supply");
        _mint(msg.sender, initialSupply * (10 ** decimals()));
        mintingFinished = false; // 初始化时允许铸造
    }

    /**
     * @dev 铸造新代币
     * @param amount 要铸造的代币数量
     * 要求：
     * - 调用者必须是合约所有者
     * - 合约不能处于暂停状态
     * - 铸造功能没有被永久关闭
     * - 铸造后的总供应量不能超过最大供应量
     */
    function mint(uint256 amount) public whenNotPaused {
        require(owner() == msg.sender || minters[msg.sender], "Not authorized");
        require(!mintingFinished, "Minting has finished");
        require(totalSupply() + amount <= MAX_SUPPLY, "Would exceed max supply");
        require(block.timestamp >= lastMintingTime + MINTING_PERIOD, "Minting period not elapsed");
        require(amount <= mintingAllowance, "Exceeds minting allowance");
        
        _mint(msg.sender, amount);
        lastMintingTime = block.timestamp;
        mintingAllowance = mintingAllowance - amount;
        emit TokensMinted(msg.sender, amount);
    }

    /**
     * @dev 永久结束代币铸造功能
     * 要求：
     * - 调用者必须是合约所有者
     * - 铸造功能尚未结束
     * 触发 MintingFinished 事件
     */
    function finishMinting() public onlyOwner {
        require(!mintingFinished, "Minting is already finished");
        mintingFinished = true;
        emit MintingFinished();
    }

    /**
     * @dev 销毁代币
     * @param amount 要销毁的代币数量
     * 允许任何代币持有者销毁自己的代币
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /**
     * @dev 暂停合约
     * 要求：
     * - 调用者必须是合约所有者
     * 暂停后将阻止代币的铸造操作
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev 解除合约暂停状态
     * 要求：
     * - 调用者必须是合约所有者
     * 解除暂停后将恢复代币的铸造操作
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev 设置新的铸币配额
     * @param newAllowance 新的铸币配额
     */
    function setMintingAllowance(uint256 newAllowance) public onlyOwner {
        require(!mintingFinished, "Minting has finished");
        require(newAllowance <= MAX_SUPPLY - totalSupply(), "Allowance too high");
        mintingAllowance = newAllowance;
        emit MintingAllowanceUpdated(newAllowance);
    }

    /**
     * @dev 代币转账前的检查
     * 检查：
     * 1. 合约是否处于暂停状态
     * 2. 发送方和接收方是否在黑名单中
     * 3. 发送方的代币是否在锁定期内
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override whenNotPaused {
        require(!blacklist[from] && !blacklist[to], "Blacklisted address");
        // 排除铸造和销毁操作的锁定检查
        if(from != address(0) && to != address(0)) {
            require(block.timestamp >= lockedUntil[from], "Tokens are locked");
        }
        super._beforeTokenTransfer(from, to, amount);
    }
    
    // 添加黑名单管理函数
    function updateBlacklist(address account, bool isBlacklisted) external onlyOwner {
        blacklist[account] = isBlacklisted;
        emit BlacklistUpdated(account, isBlacklisted);
    }

    /**
     * @dev 批量转账函数
     * @param recipients 接收者地址数组
     * @param amounts 对应的转账金额数组
     * @return 转账是否成功
     * 
     * 要求：
     * - 接收者数组和金额数组长度相同
     * - 数组不能为空
     * - 发送者余额足够支付所有转账
     * 
     * 安全考虑：
     * - 使用 unchecked 来优化 gas
     * - 检查总金额避免溢出
     */
    function batchTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external returns (bool) {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(recipients.length > 0, "Empty arrays");
        
        uint256 totalAmount;
        unchecked {
            for(uint256 i = 0; i < amounts.length; i++) {
                totalAmount += amounts[i];
                require(totalAmount >= amounts[i], "Amount overflow");
            }
        }
        
        require(balanceOf(msg.sender) >= totalAmount, "Insufficient balance");
        
        for(uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient");
            _transfer(msg.sender, recipients[i], amounts[i]);
        }
        
        return true;
    }

    /**
     * @dev 代币锁定功能
     * @param account 要锁定的账户地址
     * @param lockDuration 锁定时长（以秒为单位）
     * 
     * 要求：
     * - 只能由合约所有者调用
     * - 锁定时间不能超过最大值
     */
    function lockTokens(address account, uint256 lockDuration) external onlyOwner {
        require(account != address(0), "Invalid address");
        require(lockDuration <= 365 days, "Lock duration too long"); // 限制最长锁定期为1年
        uint256 unlockTime = block.timestamp + lockDuration;
        require(unlockTime >= block.timestamp, "Lock time overflow");
        
        lockedUntil[account] = unlockTime;
        emit TokensLocked(account, unlockTime);
    }

    /**
     * @dev 紧急提款功能
     * 允许合约所有者提取意外发送到合约的ETH
     * 
     * 安全考虑：
     * - 检查提款金额
     * - 使用 call 而不是 transfer
     * - 检查调用结果
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
    }

    /**
     * @dev 代币回收功能
     * @param from 要回收代币的地址
     * @param amount 回收的代币数量
     * 
     * 要求：
     * - 只能由合约所有者调用
     * - 目标地址必须有足够的余额
     */
    function recoverTokens(address from, uint256 amount) external onlyOwner {
        require(from != address(0), "Invalid address");
        require(from != owner(), "Cannot recover from owner");
        require(balanceOf(from) >= amount, "Insufficient balance");
        
        _transfer(from, owner(), amount);
    }

    /**
     * @dev 设置铸币权限
     * @param account 要设置权限的地址
     * @param status 是否授予铸币权限
     * 
     * 要求：
     * - 只能由合约所有者调用
     * - 不能给零地址设置权限
     */
    function setMinter(address account, bool status) external onlyOwner {
        require(account != address(0), "Invalid address");
        require(minters[account] != status, "Status not changed");
        
        minters[account] = status;
        emit MinterUpdated(account, status);
    }

    /**
     * @dev 查询地址是否被锁定
     * @param account 要查询的地址
     * @return 如果当前时间小于解锁时间则返回true
     */
    function isLocked(address account) external view returns (bool) {
        return block.timestamp < lockedUntil[account];
    }

    /**
     * @dev 查询地址的解锁时间
     * @param account 要查询的地址
     * @return 返回解锁时间戳
     */
    function getUnlockTime(address account) external view returns (uint256) {
        return lockedUntil[account];
    }
} 