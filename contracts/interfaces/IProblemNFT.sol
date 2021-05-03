pragma solidity >=0.6.0;

interface IProblemNFT {
    function addStake(uint256 _amount) external;

    function newContent(
        address _writer,
        string calldata _name,
        bytes32 _contentHash
    ) external returns (bool);
}
