// SPDX-License-Identifier: UNLINCENSED

/**
 * @title DEFIStaking
 * @dev A contract for staking DEFI tokens and earning rewards.
 */
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract DEFIStaking {
    event Staked(address indexed user, uint256 amount);
    event Withdrew(address indexed user, uint256 amount);


    using SafeERC20 for IERC20;
    IERC20 public immutable defiToken;
    uint256 public constant REWARD_PER_DAY = 1 ether; // Assuming DEFI has 18 decimals
    uint256 public constant STAKE_MULTIPLIER = 1000 ether; // 1000 DEFI tokens

    struct Position {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastRewardBlockNumber;
        uint256 rewardMultiplier;
        uint256 lastStakedTime;
    }

    mapping(address => Position) public positions;

    /**
     * @dev Constructor function
     * @param _defiToken The address of the DEFI token contract
     */
    constructor(address _defiToken) {
        defiToken = IERC20(_defiToken);
    }

    /**
     * @dev Stake DEFI tokens
     * @param _amount The amount of DEFI tokens to stake
     */
    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");

        // Update rewards before changing the stake amount
        updateRewards(msg.sender);
        positions[msg.sender].amount += _amount;
        updateRewardMultiplier(msg.sender);
        positions[msg.sender].lastRewardBlockNumber = block.number;
        defiToken.safeTransferFrom(msg.sender, address(this), _amount); //change to safe transfer

        emit Staked(msg.sender, _amount);
    }

    /**
     * @dev Withdraw staked DEFI tokens and rewards
     */
    function withdraw() external {
        Position storage userStake = positions[msg.sender];
        require(userStake.amount > 0, "No stake found");

        updateRewards(msg.sender);

        uint256 amountToTransfer = userStake.amount + userStake.rewardDebt;
        // Ensure the contract has enough tokens to transfer
        uint256 contractBalance = defiToken.balanceOf(address(this));
        require(amountToTransfer <= contractBalance, "Insufficient balance in contract");

        delete positions[msg.sender];
        defiToken.safeTransfer(msg.sender, amountToTransfer);
        emit Withdrew(msg.sender, amountToTransfer);
    }

    /**
     * @dev Get the accumulated reward for a user
     * @param _user The address of the user
     * @return The accumulated reward for the user
     */
    function getReward(address _user) public view returns (uint256) {
        Position storage userStake = positions[_user];
        uint256 accumulatedReward = (block.timestamp - userStake.lastStakedTime) * REWARD_PER_DAY / 86400;
        if (userStake.rewardMultiplier > 0) {
            return (userStake.amount / STAKE_MULTIPLIER) * accumulatedReward  + userStake.rewardDebt;
        } else {
            return accumulatedReward  + userStake.rewardDebt;
        }
        
    }

    /**
     * @dev Update the rewards for a user
     * @param _user The address of the user
     */
    function updateRewards(address _user) private {
        Position storage userStake = positions[_user];
        userStake.rewardDebt = getReward(_user);
        userStake.lastRewardBlockNumber = block.number;
        userStake.lastStakedTime = block.timestamp;
        updateRewardMultiplier(_user);
    }

    /**
     * @dev Update the reward multiplier for a user
     * @param _user The address of the user
     */
    function updateRewardMultiplier(address _user) private {
        Position storage userStake = positions[_user];
        if (userStake.amount >= STAKE_MULTIPLIER) {
            uint multiplier = userStake.amount / STAKE_MULTIPLIER;
            userStake.rewardMultiplier = multiplier;
        } else {
            userStake.rewardMultiplier = 0;
        }
    }

    function getUserBalance(address _user) public view returns (uint256) {
        return positions[_user].amount;
    }
}
