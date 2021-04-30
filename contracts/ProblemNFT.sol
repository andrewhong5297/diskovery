pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/*
Contract for problems/content and staking/rewards, this should come from ProblemFactory which stores and registers all users of certain roles.sol

Dai needs to be adapted to Disk, where users can claim 1000 Disk a week. 
need to add state/date management and reward splits.
*/
contract ProblemNFT is ERC721 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    IERC20 disk; //need to add approval or permit functions, transferFrom in stake functions
    bytes32 problemStatementHash; //used for identifying
    uint256 public totalReward;

    mapping(address => uint256) public communities; //maps to total commitments
    address[] users;
    address admin;

    //affects what functions are allowed
    enum ProblemState {STAKING, WRITING, REWARDED}
    ProblemState currentState;

    //starting options to add in constructor
    uint256 TOTAL_WINNERS = 10; //top 10
    uint256 MIN_EXPIRY = 80640; //two weeks
    uint256 MAX_EXPIRY = 80640 * 2; //a month

    uint256 EXPIRY;
    uint256 writingStart;

    Counters.Counter private _tokenIds;

    //content related events/variables
    event NewContent(
        uint256 contentId,
        string articleName,
        address writer,
        address communitySponsor
    );

    struct Content {
        string name;
        bytes32 contentHash; // do we really need content hash?
    }

    mapping(uint256 => mapping(address => address))
        public contentWriterPublisher;

    mapping(uint256 => mapping(address => uint256)) public contentUserStake; //track user deposit per content, where first uint is the content id?

    Content[] public all_content;

    constructor(bytes32 _problemStatementHash, address disk_implementation)
        public
        ERC721("Problem Set", "PS")
    {
        admin = msg.sender;
        currentState = ProblemState.STAKING;
        problemStatementHash = _problemStatementHash;
        disk = IERC20(disk_implementation);
        EXPIRY = 50000; //this should be passed in constructor later
    }

    //modifiers
    modifier checkState(ProblemState state) {
        if (state == ProblemState.STAKING) {
            require(
                currentState == ProblemState.STAKING,
                "Staking period has already ended"
            );
            _;
        }

        if (state == ProblemState.WRITING) {
            if (currentState == ProblemState.STAKING) {
                revert("Writing period has not started");
            } else if (currentState == ProblemState.REWARDED) {
                revert(
                    "Writing period has already ended and rewards distributed"
                );
            } else {
                _;
            }
        }

        if (state == ProblemState.REWARDED) {
            require(
                currentState == ProblemState.REWARDED,
                "Writing period has not yet ended"
            );
            _;
        }
    }

    modifier checkExpiry(bool state) {
        if (state) {
            require(
                block.timestamp <= writingStart + EXPIRY,
                "writing period has ended"
            );
            _;
        }
        if (state == false) {
            require(
                block.timestamp >= writingStart + EXPIRY,
                "writing period has not ended"
            );
            _;
        }
    }

    //staking state functions
    function stakeProblem(uint256 _amount)
        external
        checkState(ProblemState.STAKING)
    {
        //should somehow track all communities, users, and writers in another smart contract.
        //add deposit to overall reward pie
        totalReward += _amount;
        communities[msg.sender] += _amount;
    }

    function endStaking() external checkState(ProblemState.STAKING) {
        // require(totalReward >= 10**20, "not enough rewards yet for writers");
        currentState = ProblemState.WRITING;
        writingStart = block.timestamp; //start writing counter
    }

    //writing state functions
    function newContent(
        address _writer,
        string calldata _name,
        bytes32 _contentHash
    ) external checkState(ProblemState.WRITING) returns (bool) {
        require(
            communities[msg.sender] >= 0,
            "Not a staked community, can't publish"
        );
        //add check that (block.timestamp <= writingStart + EXPIRY)

        all_content.push(Content(_name, _contentHash));
        _tokenIds.increment();
        uint256 contentId = _tokenIds.current();
        _safeMint(_writer, contentId); //important for tokenomics

        contentWriterPublisher[contentId][_writer] = msg.sender;

        emit NewContent(contentId, _name, _writer, msg.sender);
        return true;
    }

    function stakeContent(uint256 _amount, uint256 _contentId) public {
        require(
            communities[msg.sender] == 0,
            "Sender is a staked community, can't stake article"
        );
        require(
            contentWriterPublisher[_contentId][msg.sender] == address(0),
            "Writer cannot stake their own article"
        );
        //add check that (block.timestamp <= writingStart + EXPIRY)

        contentUserStake[_contentId][msg.sender] += _amount;
        //should this be transferred to writer or community right away?
    }

    //reward state functions
    function rewardSplit()
        external
        checkState(ProblemState.WRITING)
        returns (bool)
    {
        //add check that (block.timestamp >= writingStart + EXPIRY), i.e. writing time has expired

        //split total deposit by ranking of tokenId => contentUserStake, can just call transfer here
        //calculate_rewards
        //for reward in calculate_reards: disk.transfer(address, reward)

        currentState = ProblemState.REWARDED;
        return true;
    }
}
