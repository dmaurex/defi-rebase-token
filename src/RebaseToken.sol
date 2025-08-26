// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RebaseToken
 * @author dmaurex
 * @notice This is a cross-chain rebase token that incentivizes users to deposit into a vault and gain interest in rewards
 * @notice The interest rate in the smart contract can only decrease
 * @notice Each user will have their own interest rate that is the global interest rate at the time of depositing
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
    error RebaseToken__InterestRateCanOnlyDecrease(uint256 oldInterestRate, uint256 newInterestRate);

    uint256 private constant PRECISION = 1e18;
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");
    uint256 private s_interestRate = (5 * PRECISION) / 1e8;
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    event InterestRateSet(uint256 newInterestRate);

    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender) {}

    /////////////////////
    // External functions
    /////////////////////

    /**
     * @notice Grant a user the role to mint and burn
     * @param _account The user that is granted the role
     */
    function grantMintAndBurnRole(address _account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _account);
    }

    /**
     * @notice Sets the global interest rate for the rebase token
     * @param _newInterestRate The new interest rate to set
     * @dev The interest rate can only decrease
     */
    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        if (_newInterestRate >= s_interestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease(s_interestRate, _newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /**
     * @notice Get the principal balance of a user.
     * @notice It is the number of tokens a user has without any interest that has accrued since the last interaction with the protocol.
     * @param _user The user to get the principal balance for
     * @return The principal balance of the user
     */
    function principalBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @notice Mint the user tokens when they deposit into the vault
     * @param _to The user to mint the tokens to
     * @param _amount The amount of tokens to mint
     */
    function mint(address _to, uint256 _amount, uint256 _userInterestRate) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = _userInterestRate;
        _mint(_to, _amount);
    }

    /**
     * @notice Burn the user tokens when they withdraw from the vault
     * @param _from The user to burn the tokens from
     * @param _amount The amount of tokens to burn
     */
    function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        if (_amount == type(uint256).max) {
            // standard practice to account for dust
            _amount = balanceOf(_from);
        }
        _mintAccruedInterest(_from); // update on interaction
        _burn(_from, _amount);
    }

    ///////////////////
    // Public functions
    ///////////////////

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
     * @notice Transfer tokens from sender to to another user
     * @param _to The user to transfer tokens to
     * @param _amount The amount of tokens to transfer
     * @return True if the transfer was successful
     * @dev Recipient receives the sender's interest rate if he owned no tokens previously
     */
    function transfer(address _to, uint256 _amount) public override returns (bool) {
        // Update both's balance since transfer counts as protocol interaction
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_to);

        if (_amount == type(uint256).max) {
            // standard practice to account for dust
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_to) == 0) {
            // Inherit interest rate from the sender when recipient had no tokens previously
            // TODO: alternatively use the global interest rate
            s_userInterestRate[_to] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_to, _amount);
    }

    /**
     * @notice Transfer tokens from one user to another
     * @param _from The user to transfer the tokens from
     * @param _to  The user to transfer the tokens to
     * @param _amount The amount of tokens to transfer
     * @return True if the transfer was successful
     * @dev Recipient receives the sender's interest rate if he owned no tokens previously
     */
    function transferFrom(address _from, address _to, uint256 _amount) public override returns (bool) {
        // Update both's balance since transfer counts as protocol interaction
        _mintAccruedInterest(_from);
        _mintAccruedInterest(_to);

        if (_amount == type(uint256).max) {
            // standard practice to account for dust
            _amount = balanceOf(_from);
        }
        if (balanceOf(_to) == 0) {
            // Inherit interest rate from the sender when recipient had no tokens previously
            // TODO: alternatively use the global interest rate
            s_userInterestRate[_to] = s_userInterestRate[_from];
        }
        return super.transferFrom(_from, _to, _amount);
    }

    /////////////////////////////////
    // Internal and private functions
    /////////////////////////////////

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

    //////////////////////////
    // External view functions
    //////////////////////////

    /**
     * @notice Get the interest rate currently set for the contract.
     * @notice Any future depositors will receive this interest rate.
     * @return The interest rate for the contract
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    /**
     * @notice Returns the personal interest rate for a user
     * @param _user The address of the user
     * @return The interest rate for the user
     */
    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}
