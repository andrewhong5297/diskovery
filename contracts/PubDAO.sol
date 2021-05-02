pragma solidity >=0.6.0;
//make this a minimal proxy for practice, and because this needs to be avail.

import "@openzeppelin/contracts/access/AccessControl.sol";

contract PubDAO is AccessControl {
    //admin has master control on roles
    bytes32 public constant LEADER_ROLE = keccak256("LEADER"); //votes on content and transactions (purchase of registration, problem, and content tokens)
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR"); //votes on content and calls final publication to NFT

    //EDITOR is the only one
    //DAO needs to have treasury management of ERC20 and of disk token functions.
    //DAO can set their minimum disk tokens for submissions, to with minimum of 200 disk and maximum of 2000 disk (max two weeks wait)
    //what criteria do we need for content
    //how do we setup a problem statement here?

    struct Content {
        // Unique id for looking up a content
        uint256 id;
        // Writer behind content submitted
        address writer;
        // Stake behind the content submitted
        uint256 diskStaked;
        // the address of the problemNFT
        address problemNFT;
        // The block at which voting begins: holders must delegate their votes prior to this block
        uint256 startBlock;
        // The block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;
        // Current number of votes in favor of this proposal
        uint256 forVotes;
        // Current number of votes in opposition to this proposal
        uint256 againstVotes;
        // Flag marking whether the proposal has been canceled
        bool canceled;
        // Flag marking whether the proposal has been published
        bool published;
    }

    /// @notice Possible states that submitted content may be in
    enum ProposalState {Active, Defeated, Succeeded, Expired, Published}

    //functions for recieving disk tokens, and registering a publication
    //functions for managing members/roles

    //function publish
    //function claim tokens
    //function spend tokens
    //function createProblem
}
