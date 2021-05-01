pragma solidity >=0.6.0;
//fill this out after checking with Suhana, since content will probably be submitted here as a proposal. same as problem.

//combine comp governance + daohaus here?
//we do need execute for buy orders, do we want weighted votes? can time weighted be enough?
//could there be some way of bridging the DAO's tokens in a one time mint?
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PubDAO is AccessControl {
    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER"); //votes on content only
    bytes32 public constant LEADER_ROLE = keccak256("LEADER"); //votes on content and transactions (purchase of registration, problem, and content tokens)
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR"); //votes on content and calls final publication to NFT

    //DAO needs to have voting proposals
    //DAO needs to be able to execute functions
    //DAO needs to have treasury management of ETH and of disk tokens
    //DAO can set their minimum disk tokens for submissions, to with minimum of 200 disk and maximum of 2000 disk (max two weeks wait)

    ////to ask suhana
    //what roles do we need, and who has power.
    //what states do we need
    //what criteria do we need

    struct Proposal {
        // Unique id for looking up a proposal
        uint256 id;
        // Creator of the proposal
        address proposer;
        // The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
        // the ordered list of target addresses for calls to be made
        address[] targets;
        // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        // The ordered list of function signatures to be called
        string[] signatures;
        // The ordered list of calldata to be passed to each call
        bytes[] calldatas;
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
        // Flag marking whether the proposal has been executed
        bool executed;
        // Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;
        // Whether or not the voter supports the proposal
        bool support;
        // The number of votes the voter had, which were cast
        uint96 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }
}
