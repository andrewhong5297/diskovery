pragma solidity >=0.6.0;

//this requires a new DAO structure, so we can check if it is a dao or not (i.e. DAO(address))
//maybe writers have to submit a certain number of tokens to get published? minimum 200, and your "conviction" is multiplied by multiple of 200 you push behind your article.
//so balance between writers and community split depends on where we want the power...

//fill this out after checking with Suhana, since content will probably be submitted here as a proposal. same as problem.

//combine comp governance + daohaus here?
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PubDAO is AccessControl {
    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER"); //votes on content only
    bytes32 public constant LEADER_ROLE = keccak256("LEADER"); //votes on content and transactions (purchase of registration, problem, and content tokens)
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR"); //votes on content and calls final publication to NFT

    //DAO needs to have voting proposals
    //DAO needs to be able to execute functions
    //DAO needs to have treasury management of ETH and of
}
