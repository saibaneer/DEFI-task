// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title DEFI Staking Contract
 * @dev Allows users to stake DEFI tokens and earn rewards over time.
 */
contract DEFIStaking {
    using SafeERC20 for IERC20;

    IERC20 public defiToken;

    struct Position {
        uint256 amount;
        uint256 updatedRewardTime;
        uint256 rewardDebt;
    }

    mapping(address => Position) public positions;

    uint256 public constant REWARDS_PER_SECOND = uint256(1e18) / 86400; // Reward rate per second for 1000 staked DEFI

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardUpdated(address indexed user, uint256 reward);

    constructor(IERC20 _defiToken) {
        defiToken = _defiToken;
    }

    /**
     * @dev Allows a user to stake DEFI tokens.
     * @param _amount The amount of DEFI tokens to stake.
     */
    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        updateRewards(msg.sender);

        positions[msg.sender].amount += _amount;
        positions[msg.sender].updatedRewardTime = block.timestamp;
        defiToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount);
    }

    /**
     * @dev Withdraws the staked tokens and any earned rewards for the sender.
     */
    function withdraw() external {
        updateRewards(msg.sender);

        Position storage userStake = positions[msg.sender];
        require(userStake.amount > 0, "No stake found");

        uint256 amountToTransfer = userStake.amount + userStake.rewardDebt;
        userStake.amount = 0;
        userStake.rewardDebt = 0;

        // Ensure the contract has enough tokens to transfer
        uint256 contractBalance = defiToken.balanceOf(address(this));
        require(amountToTransfer <= contractBalance, "Insufficient balance in contract");


        defiToken.safeTransfer(msg.sender, amountToTransfer);

        emit Withdrawn(msg.sender, amountToTransfer);
    }

    /**
     * @dev Internal function to update the reward for a user.
     * @param _user The address of the user.
     */
    function updateRewards(address _user) internal {
        Position storage userStake = positions[_user];
        if (userStake.amount > 0) {
            uint256 reward = getReward(_user);
            userStake.rewardDebt += reward;
            userStake.updatedRewardTime = block.timestamp;

            emit RewardUpdated(_user, reward);
        }
    }

    /**
     * @dev Gets the total rewards for a user, including both accumulated and pending rewards.
     * @param _user The address of the user to get rewards for.
     * @return The total rewards of the user.
     */
    function getReward(address _user) public view returns (uint256) {
        Position memory userStake = positions[_user];
        if (userStake.amount == 0) return 0;
        uint256 secondsStaked = block.timestamp - userStake.updatedRewardTime;
        uint256 reward = (secondsStaked * REWARDS_PER_SECOND * userStake.amount) / 1000e18;
        return userStake.rewardDebt + reward;
    }

    /**
     * @dev Gets the staked balance of a user.
     * @param _user The address of the user.
     * @return The staked balance of the user.
     */
    function getUserBalance(address _user) public view returns (uint256) {
        return positions[_user].amount;
    }
}
