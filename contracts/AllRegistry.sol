pragma solidity >=0.6.0;

import "./PubDAO.sol";

//stores all users and roles, and if they have claimed this week yet or not.
//this requires a new DAO structure, so we can check if it is a dao or not (i.e. DAO(address))

contract AllRegistry {
    mapping(address => bool) public pubRegistry;

    //checks address then bool then last claim time, if now() - last claim time > 40000 then they can claim tokens again.
    //maybe this should just be set weekly instead for consistency...
    mapping(address => mapping(bool => uint256)) public claimTracking;

    function registerPub() public returns (bool sucess) {
        //maybe you should be able to have a PubDAO before registry, so you can pool enough funds to buy a registration token.
        //burn registration token, which is airdropped to those who funded MIRROR post at the start

        /*
        at the start of each month you get a problem token and five content tokens? 
        Maybe there is a use for ERC1155 here... to have registration tokens, problem tokens, and content tokens. 
        This limit and price can then be set by governance in terms of USDC.

        I wish I could let them recieve disk tokens, but then I would have to somehow limit transfer of disk to them... 
        so their balance would be stored in this registry instead. 
        This way they can burn maybe 10000 disk tokens for one problem token, 1000 for a content token, and 100000 for a registration token. 
        */

        pubRegistry[msg.sender] = true;
        return true;
    }

    //pubclaim for registration tokens, problem tokens, and content tokens.

    //userclaim tokens to stake
}
