pragma solidity >=0.6.0;

interface IStartProblem {
    function createProblem(bytes32 _hash, uint256 _minimumReward) external;
}
