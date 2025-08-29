// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.24;

import {Pool} from "@ccip/contracts/src/v0.8/ccip/libraries/Pool.sol";
import {TokenPool} from "@ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {IRebaseToken} from "src/interfaces/IRebaseToken.sol";

contract RebaseTokenPool is TokenPool {
    constructor(IERC20 _token, address[] memory _allowlist, address _rmnProxy, address _router)
        TokenPool(_token, _allowlist, _rmnProxy, _router)
    {}

    /// @notice Burns the tokens on the source chain
    function lockOrBurn(Pool.LockOrBurnInV1 calldata lockOrBurnIn)
        external
        virtual
        override
        returns (Pool.LockOrBurnOutV1 memory lockOrBurnOut)
    {
        _validateLockOrBurn(lockOrBurnIn);
        // Burn the tokens on the source chain. This returns their userAccumulatedInterest before the tokens were burned
        // In case all tokens were burned, we do not want to send 0 tokens cross-chain
        uint256 userInterestRate = IRebaseToken(address(i_token)).getUserInterestRate(lockOrBurnIn.originalSender);
        IRebaseToken(address(i_token)).burn(address(this), lockOrBurnIn.amount);
        // Note, here address(this) was instead of receiver!
        // This is because an approval will be made to the token pool, which will then send the tokens (not the sender!)

        // Encode a function call to pass the caller's info to the destination pool and update it
        lockOrBurnOut = Pool.LockOrBurnOutV1({
            destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector),
            destPoolData: abi.encode(userInterestRate)
        });
    }

    /// @notice Mints the tokens on the source chain
    function releaseOrMint(Pool.ReleaseOrMintInV1 calldata releaseOrMintIn)
        external
        returns (Pool.ReleaseOrMintOutV1 memory)
    {
        _validateReleaseOrMint(releaseOrMintIn);
        uint256 userInterestRate = abi.decode(releaseOrMintIn.sourcePoolData, (uint256));
        // Mint rebasing tokens to the receiver on the destination chain
        // This will also mint any interest that has accrued since the last time the user's balance was updated
        IRebaseToken(address(i_token)).mint(releaseOrMintIn.receiver, releaseOrMintIn.amount, userInterestRate);

        return Pool.ReleaseOrMintOutV1({destinationAmount: releaseOrMintIn.amount});
    }
}
