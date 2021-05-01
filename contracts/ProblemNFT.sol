pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "hardhat/console.sol";

// import "./AllRegistry.sol"; this should be an interface later

/*
Contract for problems/content and staking/rewards, deployed by registered publisher from startproblem.sol

------
to do:
still need to add token transfers and reward in ERC20 (tbd if set to USDC or native token ETH/Matic/whatever it is). 
options on maximum user stake and minimum ETH stake.
debug all_content[0] indexing
*/
contract ProblemNFT is ERC721 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    IERC20 disk; //need to add approval or permit functions, transferFrom in stake functions
    bytes32 problemStatementHash; //used for identifying this problem
    uint256 public totalReward;

    mapping(address => uint256) public communities; //maps to total commitments to problems

    //affects what functions are allowed
    enum ProblemState {STAKING, WRITING, REWARDED}
    ProblemState currentState;

    //starting options to add in constructor
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
        address writer;
        bytes32 contentHash; // IPFS or arweave hash here
        uint256 contentReward;
        bool rewardClaimed;
    }

    mapping(address => address) public writerPublisher;
    mapping(address => uint256) public writerContent;
    mapping(uint256 => mapping(address => uint256)) public contentUserStake; //track user deposit per content, where first uint is the content id?

    Content[] public all_content;
    uint256 totalUserStaked; //tracks total stake per content

    constructor(bytes32 _problemStatementHash, address disk_implementation)
        public
        ERC721("Problem Set", "PS")
    {
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
                block.timestamp <= writingStart.add(EXPIRY),
                "writing period has ended"
            );
            _;
        }
        if (state == false) {
            require(
                block.timestamp >= writingStart.add(EXPIRY),
                "writing period has not ended"
            );
            _;
        }
    }

    /*
    staking state functions
    */

    //add some priced token as deposit to overall reward
    function stakeProblem(uint256 _amount)
        external
        payable
        checkState(ProblemState.STAKING)
    {
        totalReward = totalReward.add(_amount);
        communities[msg.sender] = communities[msg.sender].add(_amount); //this works if only communities can send
        //does payable handle the ETH sent or do I need to recieve it?
    }

    function endStaking() external checkState(ProblemState.STAKING) {
        // require(totalReward >= 10**20, "not enough rewards yet for writers");
        currentState = ProblemState.WRITING;
        writingStart = block.timestamp; //start writing counter
    }

    /*
    writing state functions
    */
    function newContent(
        address _writer,
        string calldata _name,
        bytes32 _contentHash
    ) external checkState(ProblemState.WRITING) returns (bool) {
        //add check that (block.timestamp <= writingStart + EXPIRY)
        require(
            communities[msg.sender] >= 0,
            "Not a staked community, can't publish"
        );
        require(
            writerPublisher[_writer] == address(0),
            "Has already published once"
        );
        //burn content token
        _safeMint(_writer, _tokenIds.current());

        writerPublisher[_writer] = msg.sender;
        all_content.push(Content(_name, _writer, _contentHash, 0, false));
        writerContent[_writer] = _tokenIds.current();

        emit NewContent(_tokenIds.current(), _name, _writer, msg.sender);
        _tokenIds.increment();

        return true;
    }

    function stakeContent(uint256 _amount, uint256 _contentId) public {
        require(
            communities[msg.sender] == 0,
            "Sender is a staked community, can't stake article"
        );
        require(
            writerContent[msg.sender] != _contentId,
            "Writer cannot stake their own article"
        );
        //add checkExpiry after testing

        //check that total user stake is not > 5000,
        contentUserStake[_contentId][msg.sender] = contentUserStake[_contentId][
            msg.sender
        ]
            .add(_amount);

        console.log(all_content[_contentId].contentReward);
        // all_content[0].contentReward = all_content[0].contentReward.add(
        //     _amount
        // ); //come back to debug this
        totalUserStaked = totalUserStaked.add(_amount);

        //this should be transferred to writer and community right away
        //need an event added here
    }

    /*
    reward state functions
    */
    // function rewardSplit()
    //     external
    //     checkState(ProblemState.WRITING)
    //     returns (bool)
    // {
    //     //add checkExpiry after testing
    //     for (uint256 i = 0; i < all_content.length; i++) {
    //         all_content[i].contentReward.div(totalUserStaked).mul(totalReward);
    //     }

    //     currentState = ProblemState.REWARDED;
    //     return true;
    // }

    // function claimWinnings()
    //     external
    //     checkState(ProblemState.REWARDED)
    //     returns (uint256 transferAmount)
    // {
    //     uint256 contentId = writerContent[msg.sender];
    //     require(
    //         all_content[contentId].rewardClaimed == false,
    //         "reward already claimed"
    //     );

    //     transferAmount = all_content[contentId].contentReward;
    //     all_content[contentId].rewardClaimed = true;

    //     //transfer from contract to msg.sender after checking their winning mapping.
    // }

    /* 
    view functions
    */
    function getContent() external view returns (Content[] memory content) {
        content = all_content;
    }

    //     function getContentCount() external view returns (uint256 count) {
    //         count = all_content.length;
    //     }
}
