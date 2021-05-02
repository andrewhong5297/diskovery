pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "hardhat/console.sol";

// import "./AllRegistry.sol"; this should be an interface later

/*
Contract for problems/content and staking/rewards, deployed by registered community from startproblem.sol

------
to do:
after DAO and Registry, come back and add token transfers/burns and reward in ERC20 (just use USDC for now). 
add constructor options on maximum user stake and expiry
*/
contract ProblemNFT is ERC721 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    IERC20 disk;
    bytes32 problemStatementHash; //used for identifying this problem
    uint256 public totalReward;
    mapping(address => bool) public communities; //maps to total commitments to problems

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
        address community;
        bytes32 contentHash; // IPFS or arweave hash here
        uint256 contentReward;
        bool rewardClaimed;
    }

    mapping(address => uint256) public writerContent;
    mapping(uint256 => mapping(address => uint256)) public contentUserStake; //track user deposit per content, where first uint is the content id?

    Content[] public all_content;

    //staking related
    uint256 totalUserStaked;
    bool rewardsCalculated = false;

    constructor(
        bytes32 _problemStatementHash,
        address disk_implementation,
        uint256 _totalReward,
        address[] memory _communities
    ) public ERC721("Problem Set", "PS") {
        problemStatementHash = _problemStatementHash;
        disk = IERC20(disk_implementation);
        EXPIRY = 100000; //this should be passed in constructor later with checks
        writingStart = block.timestamp; //should there be a delay before the start?
        totalReward = _totalReward;
        for (uint256 i = 0; i < _communities.length; i++) {
            communities[_communities[i]] = true;
        }
    }

    //modifiers
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

    //function that allows anyone to add to totalReward anytime before expiry
    function addStake(uint256 _amount) external {
        //transferFrom and check balance before calling this
        //check if msg.sender is part of pubdaos mapping
        communities[msg.sender] = true;
        totalReward = totalReward.add(_amount); //or msg.value if we make this payable
    }

    /*
    writing state functions
    */
    function newContent(
        address _writer,
        string calldata _name,
        bytes32 _contentHash
    ) external returns (bool) {
        //add check that (block.timestamp <= writingStart + EXPIRY)
        require(communities[msg.sender] == true, "Community did not stake");
        require(
            writerContent[_writer] == 0,
            "Writer has already published once"
        );

        //recieve/burn content token
        _tokenIds.increment();
        _safeMint(_writer, _tokenIds.current());

        all_content.push(
            Content(_name, _writer, msg.sender, _contentHash, 0, false)
        );
        writerContent[_writer] = _tokenIds.current();

        emit NewContent(_tokenIds.current(), _name, _writer, msg.sender);
        return true;
    }

    function stakeContent(uint256 _amount, uint256 _contentId) public {
        require(
            all_content[_contentId.sub(1)].community != msg.sender,
            "community cannot stake their own article"
        );
        require(_contentId > 0, "contentId starts from 1");
        require(
            writerContent[msg.sender] != _contentId,
            "Writer cannot stake their own article"
        );
        //add checkExpiry after testing

        //add check that total user stake is not > 5000,
        contentUserStake[_contentId][msg.sender] = contentUserStake[_contentId][
            msg.sender
        ]
            .add(_amount);

        all_content[_contentId.sub(1)].contentReward = all_content[
            _contentId.sub(1)
        ]
            .contentReward
            .add(_amount); //come back to debug this
        totalUserStaked = totalUserStaked.add(_amount);

        //this should be transferred to writer and community right away
        //need an event added here
    }

    /*
    reward state functions
    */

    ///@notice normalizes content stakes, then allocates totalReward.
    function rewardSplit() external {
        //add checkExpiry after testing
        require(rewardsCalculated == false, "rewards already calculated");
        for (uint256 i = 0; i < all_content.length; i++) {
            all_content[i].contentReward = mulDiv(
                all_content[i].contentReward,
                totalReward,
                totalUserStaked
            );
        }
        rewardsCalculated = true;
    }

    function claimWinnings() external returns (uint256 transferAmount) {
        //add expiryCheck after testing
        require(
            rewardsCalculated == true,
            "rewards need to be calculated first"
        );
        uint256 contentId = writerContent[msg.sender];
        require(
            all_content[contentId].rewardClaimed == false,
            "reward already claimed"
        );

        transferAmount = all_content[contentId.sub(1)].contentReward;
        all_content[contentId.sub(1)].rewardClaimed = true;

        console.log("sent to writer: ", transferAmount);
        //need claim event here
        //transfer from contract to msg.sender after checking their winning mapping.
    }

    /* 
    view functions
    */
    function getContent() external view returns (Content[] memory content) {
        content = all_content;
    }

    function getContentCount() external view returns (uint256 count) {
        count = all_content.length;
    }

    function fullMul(uint256 x, uint256 y)
        public
        pure
        returns (uint256 l, uint256 h)
    {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        require(h < z);
        uint256 mm = mulmod(x, y, z);
        if (mm > l) h -= 1;
        l -= mm;
        uint256 pow2 = z & -z;
        z /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        return l * r;
    }
}
