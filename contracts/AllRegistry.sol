//stores all users and roles, and if they have claimed this week yet or not.
pragma solidity ^0.6.0;

contract AllRegistry {
    mapping(address => bool) public pubRegistry;

    //checks address then bool then last claim time, if now() - last claim time > 40000 then they can claim tokens again.
    mapping(address => mapping(bool => uint256)) public claimTracking;

    function registerPub() public returns (bool sucess) {
        pubRegistry[msg.sender] = true;
        return true;
    }

    //pubclaim tokens for content or problems

    //userclaim tokens to stake
}
