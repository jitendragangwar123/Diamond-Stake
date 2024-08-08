// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title ReDiscreteStaking Contract
 * @author Jitendra Kumar
 * @dev A contract for staking Ether and earning rewards based on staking duration.
 */
contract ReDiscreteStaking is ReentrancyGuardUpgradeable {
    address public owner;
    uint256 public currentPositionId;

    struct Position {
        uint256 positionId;
        address walletAddress;
        uint256 createdDate;
        uint256 unlockDate;
        uint256 percentInterest;
        uint256 weiStaked;
        uint256 weiInterest;
        bool open;
    }

    mapping(uint256 => Position) public positions;
    mapping(address => uint256[]) public positionIdByAddress;
    mapping(uint256 => uint256) public tiers;
    uint256[] public lockPeriods;

    event Staked(uint256 positionId, address indexed user, uint256 amount, uint256 unlockDate);
    event PositionClosed(uint256 positionId, address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
        currentPositionId = 0;

        tiers[0] = 700;
        tiers[30] = 800;
        tiers[60] = 900;
        tiers[90] = 1200;

        lockPeriods.push(0);
        lockPeriods.push(30);
        lockPeriods.push(60);
        lockPeriods.push(90);
    }

    function stakeEther(uint256 numDays) external payable {
        require(tiers[numDays] > 0, "Tier not found for the given number of days");

        uint256 interest = calculateInterest(tiers[numDays], msg.value);
        positions[currentPositionId] = Position(
            currentPositionId,
            msg.sender,
            block.timestamp,
            block.timestamp + (numDays * 1 days),
            tiers[numDays],
            msg.value,
            interest,
            true
        );

        positionIdByAddress[msg.sender].push(currentPositionId);
        emit Staked(currentPositionId, msg.sender, msg.value, block.timestamp + (numDays * 1 days));
        currentPositionId += 1;
    }

    function calculateInterest(uint256 basePoints, uint256 weiAmount) private pure returns (uint256) {
        require(basePoints > 0, "Base points must be greater than zero");
        require(weiAmount > 0, "Wei amount must be greater than zero");
        return (basePoints * weiAmount) / 10000;
    }

    function getLockPeriods() external view returns (uint256[] memory) {
        return lockPeriods;
    }

    function getInterestRate(uint256 numDays) external view returns (uint256) {
        return tiers[numDays];
    }

    function getPositionById(uint256 positionId) external view returns (Position memory) {
        return positions[positionId];
    }

    function getPositionIdsForAddress(address walletAddress) external view returns (uint256[] memory) {
        return positionIdByAddress[walletAddress];
    }

    function closePosition(uint256 positionId) external nonReentrant {
        Position storage position = positions[positionId];

        require(position.walletAddress == msg.sender, "Only position creator may close position");
        require(position.open == true, "Position is already closed");
        require(block.timestamp >= position.unlockDate, "Position is still locked");

        position.open = false;
        uint256 amount = position.weiStaked + position.weiInterest;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed!");

        emit PositionClosed(positionId, msg.sender, amount);
    }
}
