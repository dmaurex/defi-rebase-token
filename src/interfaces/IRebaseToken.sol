// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.24;

interface IRebaseToken {
    function balanceOf(address _user) external view returns (uint256);
    function mint(address _to, uint256 _amount, uint256 _interestRate) external;
    function burn(address _from, uint256 _amount) external;
    function getInterestRate() external view returns (uint256);
    function getUserInterestRate(address _user) external view returns (uint256);
    function grantMintAndBurnRole(address _account) external;
}
