// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FeeSplittingContract {
    address public admin;
    uint256 public feePercentage; // Fee percentage to be deducted

    struct Deposit {
        uint256 amount;
        uint256 timestamp;
    }

    struct Withdrawal {
        uint256 amount;
        uint256 fee;
        uint256 netAmount;
        uint256 timestamp;
    }

    mapping(address => Deposit[]) public userDeposits;
    mapping(address => Withdrawal[]) public userWithdrawals;

    constructor(address _admin, uint256 _feePercentage) {
        admin = _admin;
        feePercentage = _feePercentage;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    function setFeePercentage(uint256 _feePercentage) external onlyAdmin {
        require(_feePercentage <= 100, "Fee percentage must be less than or equal to 100");
        feePercentage = _feePercentage;
    }

    function deposit() external payable returns (bool) {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        Deposit memory newDeposit = Deposit(msg.value, block.timestamp);
        userDeposits[msg.sender].push(newDeposit);

        return true;
    }

    function withdraw(uint256 _amount) external returns (bool) {
        require(_amount > 0, "Withdrawal amount must be greater than 0");

        uint256 fee = (_amount * feePercentage) / 100;
        uint256 netAmount = _amount - fee;

        require(payable(msg.sender).send(netAmount), "ETH transfer failed");
        require(payable(admin).send(fee), "Fee transfer to admin failed");

        Withdrawal memory newWithdrawal = Withdrawal(_amount, fee, netAmount, block.timestamp);
        userWithdrawals[msg.sender].push(newWithdrawal);

        return true;
    }

    function depositERC20(address _tokenAddress, uint256 _amount) external returns (bool) {
        require(_amount > 0, "Deposit amount must be greater than 0");

        IERC20 token = IERC20(_tokenAddress);
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        Deposit memory newDeposit = Deposit(_amount, block.timestamp);
        userDeposits[msg.sender].push(newDeposit);

        return true;
    }

    function withdrawERC20(address _tokenAddress, uint256 _amount) external returns (bool) {
        require(_amount > 0, "Withdrawal amount must be greater than 0");

        IERC20 token = IERC20(_tokenAddress);
        uint256 fee = (_amount * feePercentage) / 100;
        uint256 netAmount = _amount - fee;

        require(token.transfer(msg.sender, netAmount), "Token transfer failed");
        require(token.transfer(admin, fee), "Fee transfer to admin failed");

        Withdrawal memory newWithdrawal = Withdrawal(_amount, fee, netAmount, block.timestamp);
        userWithdrawals[msg.sender].push(newWithdrawal);

        return true;
    }

    function getUserDepositCount(address user) external view returns (uint256) {
        return userDeposits[user].length;
    }

    function getUserWithdrawalCount(address user) external view returns (uint256) {
        return userWithdrawals[user].length;
    }
}
