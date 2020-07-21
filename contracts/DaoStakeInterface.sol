pragma solidity ^0.6.0;

interface DaoStakeContract {
    function stakeALT(uint256 _altQuantity, uint256 _days)
        external
        returns (uint256 rewardAmount);

    function baseInterestRate() external view
        returns (uint256);
}
