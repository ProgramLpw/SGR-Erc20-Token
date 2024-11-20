// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MyBeautifulToken is ERC20, Pausable, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;

    // Define roles for access control
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private constant INITIAL_SUPPLY = 1400000000 * (10 ** 18); // 1.4 billion tokens with 18 decimals
    uint256 private _burnFee = 1; // 1% burn fee
    uint256 private constant MAX_FEE = 1000; // Maximum fee is 10%

    event TokensBurned(address indexed from, uint256 amount);
    event BurnFeeUpdated(uint256 oldFee, uint256 newFee);
    event TokensMinted(address to, uint256 amount);
    event ContractPaused(address account);
    event ContractUnpaused(address account);

    /**
     * @dev Constructor that gives the msg.sender all the initial roles, and mints tokens
     * @param name_ Name of the token
     * @param symbol_ Symbol of the token
     */
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        // Grant the contract deployer the default admin role: it will be able to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

        // Mint initial supply to the contract deployer
        _mint(msg.sender, INITIAL_SUPPLY);
        emit TokensMinted(msg.sender, INITIAL_SUPPLY);
    }

    /**
     * @dev Mints new tokens to the specified address. Only callable by MINTER_ROLE
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) public whenNotPaused nonReentrant {
        require(hasRole(MINTER_ROLE, msg.sender), "Only minter can mint");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @dev Burns tokens from the sender. 
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) public nonReentrant {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /**
     * @dev Transfers tokens in batch to multiple recipients
     * @param recipients Array of addresses to receive tokens
     * @param amounts Array of token amounts to transfer
     */
    function batchTransfer(address[] memory recipients, uint256[] memory amounts) public whenNotPaused nonReentrant {
        require(recipients.length == amounts.length, "Recipients and amounts length mismatch");
        for (uint i = 0; i < recipients.length; i++) {
            _transfer(msg.sender, recipients[i], amounts[i]);
        }
    }

    /**
     * @dev Sets the burn fee. Only callable by the DEFAULT_ADMIN_ROLE
     * @param burnFee The new burn fee percentage multiplied by 1000 (i.e., 1% = 10)
     */
    function setBurnFee(uint256 burnFee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin can set burn fee");
        require(burnFee <= MAX_FEE, "Burn fee cannot exceed 10%");
        emit BurnFeeUpdated(_burnFee, burnFee);
        _burnFee = burnFee;
    }

    /**
     * @dev Pauses all token transfers. Only callable by the PAUSER_ROLE
     */
    function pause() public {
        require(hasRole(PAUSER_ROLE, msg.sender), "Only pauser can pause");
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses all token transfers. Only callable by the PAUSER_ROLE
     */
    function unpause() public {
        require(hasRole(PAUSER_ROLE, msg.sender), "Only pauser can unpause");
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Override the transfer function to apply the burn fee
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override whenNotPaused {
        uint256 burnAmount = amount.mul(_burnFee).div(1000);
        super._transfer(sender, address(0), burnAmount); // Burn fee
        super._transfer(sender, recipient, amount.sub(burnAmount)); // Actual transfer amount
    }

    /**
     * @dev Returns the current burn fee
     */
    function burnFee() public view returns (uint256) {
        return _burnFee;
    }
}

// SafeMath: 使用SafeMath库来防止算术溢出。
// ReentrancyGuard: 防止重入攻击。
// Pausable: 增加了可暂停的功能，允许合约在紧急情况下暂停所有交易。
// 事件: 添加了更多的合约事件，帮助监控合约行为。
// 构造函数检查: 虽然这里没有直接使用require，但确保初始供应量是固定值的。
// 燃烧费用: 通过燃烧费用降低代币的供应量，减少通货膨胀。
// 视图函数: 增加了一个视图函数burnFee()，以便用户可以查看当前的燃烧费用。

// 限制单次铸造的数量。
// 实施更多的权限控制。
// 添加更细粒度的访问控制，如角色管理。
// 使用更复杂的逻辑来管理燃烧费用和铸造行为。
// 进行代码审计以发现潜在的漏洞。