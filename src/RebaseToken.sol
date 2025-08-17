// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title RebaseToken
 * @author dmaurex
 * @notice This is a cross-chain rebase token that incentivizes users to deposit into a vault and gain interest in rewards
 * @notice The interest rate in the smart contract can only decrease
 * @notice Each user will have their own interest rate that is the global interest rate at the time of depositing
 */
contract RebaseToken is ERC20 {
    error RebaseToken__InterestRateCanOnlyDecrease(uint256 oldInterestRate, uint256 newInterestRate);

    uint256 private constant PRECISION = 1e18;
    uint256 private s_interestRate = 5e10;
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    event InterestRateSet(uint256 newInterestRate);

    constructor() ERC20("Rebase Token", "RBT") {}

    /**
     * @notice Sets the global interest rate for the rebase token
     * @param _newInterestRate The new interest rate to set
     * @dev The interest rate can only decrease
     */
    function setInterestRate(uint256 _newInterestRate) external {
        if (_newInterestRate < s_interestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease(s_interestRate, _newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /**
     * @notice Mint the user tokens when they deposit into the vault
     * @param _to The user to mint the tokens to
     * @param _amount The amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    /**
     * @notice Calculate the balance for the user including the interest that has accumulated since the last update
     * @param _user The user to calculate the balance for
     * @return The balance of the user including the interest that has accumulated
     * @dev Returned is the principal balance + some interest that has accrued
     */
    function balanceOf(address _user) public view override returns (uint256) {
        // Multiply the principle balance by a term that reflects the interest
        // that has accumulated in the time since the balance was last updated
        return (super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user)) / PRECISION;
    }

    /**
     * @notice Calculate the interest that has accumulated since the last update
     * @param _user The user to calculate the interest accumulated for
     * @return The interest that has accumulated since the last update
     */
    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user) internal view returns (uint256) {
        // Interest grows linear with time
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        uint256 linearInterest = (PRECISION + (s_userInterestRate[_user] * timeElapsed));
        return linearInterest;
    }

    /**
     * @notice Mint the accrued interest to the user since the last time they interacted with the protocol (e.g., mint, burn, transfer)
     * @param _user The user to mint the accrued interest to
     */
    function _mintAccruedInterest(address _user) internal {
        uint256 previousPrincipalBalance = super.balanceOf(_user); // since last interaction
        uint256 currentBalance = balanceOf(_user);
        uint256 balanceIncrease = currentBalance - previousPrincipalBalance;
        // Set the users last updated timestamp
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
        _mint(_user, balanceIncrease);
    }
}
