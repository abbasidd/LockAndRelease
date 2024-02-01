// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


interface non_standard_IERC20 {
    function transferFrom(
          address from,
          address to,
          uint amount
      ) external ;

    function transfer(
          address to,
          uint amount
      ) external ;
  }
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

    // Event declarations
    event DepositEvent(address indexed user, uint256 amount, uint256 timestamp);
    event WithdrawalEvent(address indexed user, uint256 amount, uint256 fee, uint256 netAmount, uint256 timestamp);

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

    // Function to set the fee percentage, only accessible by the admin
    function setFeePercentage(uint256 _feePercentage) external onlyAdmin {
        require(_feePercentage <= 100, "Fee percentage must be less than or equal to 100");
        feePercentage = _feePercentage;
    }

    // Deposit function for Ether
    function deposit() external payable returns (bool) {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        // Creating a new Deposit struct with deposit details
        Deposit memory newDeposit = Deposit(msg.value, block.timestamp);
        // Adding the deposit to the user's deposit history
        userDeposits[msg.sender].push(newDeposit);

        // Emitting DepositEvent
        emit DepositEvent(msg.sender, msg.value, block.timestamp);

        return true;
    }

    // Withdrawal function for Ether
    function withdraw(uint256 _amount) external returns (bool) {
        require(_amount > 0, "Withdrawal amount must be greater than 0");

        // Calculating fee and net amount
        uint256 fee = (_amount * feePercentage) / 100;
        uint256 netAmount = _amount - fee;

        // Transferring net amount to the user
        require(payable(msg.sender).send(netAmount), "ETH transfer failed");
        // Transferring fee to the admin
        require(payable(admin).send(fee), "Fee transfer to admin failed");

        // Creating a new Withdrawal struct with withdrawal details
        Withdrawal memory newWithdrawal = Withdrawal(_amount, fee, netAmount, block.timestamp);
        // Adding the withdrawal to the user's withdrawal history
        userWithdrawals[msg.sender].push(newWithdrawal);

        // Emitting WithdrawalEvent
        emit WithdrawalEvent(msg.sender, _amount, fee, netAmount, block.timestamp);

        return true;
    }

    // Deposit function for ERC-20 tokens
    function depositERC20(address _tokenAddress, uint256 _amount) external returns (bool) {
        require(_amount > 0, "Deposit amount must be greater than 0");

        // Transferring ERC-20 tokens from the user to the contract
        non_standard_IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);

        // Creating a new Deposit struct with deposit details
        Deposit memory newDeposit = Deposit(_amount, block.timestamp);
        // Adding the deposit to the user's deposit history
        userDeposits[msg.sender].push(newDeposit);

        // Emitting DepositEvent
        emit DepositEvent(msg.sender, _amount, block.timestamp);

        return true;
    }

    // Withdrawal function for ERC-20 tokens
    function withdrawERC20(address _tokenAddress, uint256 _amount) external returns (bool) {
        require(_amount > 0, "Withdrawal amount must be greater than 0");

        // Creating an ERC-20 token instance
        non_standard_IERC20 token = non_standard_IERC20(_tokenAddress);
        // Calculating fee and net amount
        uint256 fee = (_amount * feePercentage) / 100;
        uint256 netAmount = _amount - fee;

        // Transferring net amount in ERC-20 tokens to the user
        token.transfer(msg.sender, netAmount);
        // Transferring fee in ERC-20 tokens to the admin
        token.transfer(admin, fee);

        // Creating a new Withdrawal struct with withdrawal details
        Withdrawal memory newWithdrawal = Withdrawal(_amount, fee, netAmount, block.timestamp);
        // Adding the withdrawal to the user's withdrawal history
        userWithdrawals[msg.sender].push(newWithdrawal);

        // Emitting WithdrawalEvent
        emit WithdrawalEvent(msg.sender, _amount, fee, netAmount, block.timestamp);

        return true;
    }

    // Function to get the count of deposits for a specific user
    function getUserDepositCount(address user) external view returns (uint256) {
        return userDeposits[user].length;
    }

    // Function to get the count of withdrawals for a specific user
    function getUserWithdrawalCount(address user) external view returns (uint256) {
        return userWithdrawals[user].length;
    }
}
