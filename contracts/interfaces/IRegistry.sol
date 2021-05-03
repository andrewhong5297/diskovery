pragma solidity >=0.6.0;

interface IRegistry {
    function checkPubDAO(address _checker) external view returns (bool isDao);

    function registerPub() external returns (bool sucess);

    function buyTokens(uint256 _tokens, uint256 _tokenType) external;

    function claimWeeklyPub() external;
}
