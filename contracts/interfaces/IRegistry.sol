pragma solidity >=0.6.0 <0.8.0;

interface IRegistry {
    function checkPubDAO(address _checker) external view returns (bool isDao);
}
