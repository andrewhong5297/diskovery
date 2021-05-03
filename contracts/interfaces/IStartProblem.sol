pragma solidity >=0.6.0;

interface IStartProblem {
    function createProblem(
        bytes32 _hash,
        uint256 _minimumReward,
        uint256 _expiry,
        string memory _text
    ) external returns (address);

    function getExpiryBounds() external view returns (uint256, uint256);

    function getMinRewards() external view returns (uint256);
}
