pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IERC20S.sol";
import "./interfaces/IRegistry.sol";

/*
Contract for problems/content and staking/rewards, deployed by registered community from startproblem.sol
*/
contract ProblemNFT is ERC721 {
    using SafeMath for uint256;
    uint256 _tokenId = 0;

    IRegistry reg; //add into constructor later
    IERC20S disk;
    IERC20S usdc;
    IERC20S cont;
    bytes32 problemStatementHash; //used for identifying this problem
    uint256 public totalReward;
    string public problemText;
    mapping(address => uint256) public communities; //maps to total commitments to problems

    //starting options to add in constructor
    uint256 MAX_STAKE;
    uint256 EXPIRY;

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

    event NewContent(
        uint256 contentId,
        string articleName,
        address writer,
        address communitySponsor
    );

    event NewStake(address communitySponsor, uint256 amount);

    event NewContentStake(address user, uint256 amount, uint256 tokenId);

    event RewardClaimed(address writer, uint256 amount);

    constructor(
        bytes32 _problemStatementHash,
        address _disk,
        address _usdc,
        uint256 _totalReward,
        address _community,
        string memory _problemText,
        address _reg,
        address _cont,
        uint256 _maxS,
        uint256 _expiry
    ) public ERC721("Problem Set", "PS") {
        problemStatementHash = _problemStatementHash;
        disk = IERC20S(_disk);
        usdc = IERC20S(_usdc);
        cont = IERC20S(_cont);
        EXPIRY = block.timestamp + _expiry;
        totalReward = _totalReward;
        communities[_community] = _totalReward; //can change this to _totalReward instead of boolean
        problemText = _problemText;
        reg = IRegistry(_reg);
        MAX_STAKE = _maxS;
    }

    //modifiers
    modifier checkExpiry(bool state) {
        if (state) {
            require(block.timestamp <= EXPIRY, "writing period has ended");
            _;
        }
        if (state == false) {
            require(block.timestamp >= EXPIRY, "writing period has not ended");
            _;
        }
    }

    //function that allows anyone to add to totalReward anytime before expiry
    function addStake(uint256 _amount) external {
        require(reg.checkPubDAO(msg.sender) == true);
        usdc.transferFrom(msg.sender, address(this), _amount);
        communities[msg.sender] = communities[msg.sender].add(_amount);
        totalReward = totalReward.add(_amount); //or msg.value if we make this payable

        emit NewStake(msg.sender, _amount);
    }

    /*
    writing state functions
    */
    function newContent(
        address _writer,
        string calldata _name,
        bytes32 _contentHash
    ) external returns (bool) {
        //add checkExpiry(true)
        require(communities[msg.sender] >= 0);
        require(writerContent[_writer] == 0);

        cont.transferFrom(msg.sender, address(this), 10**18);
        _tokenId = _tokenId.add(1);
        _safeMint(_writer, _tokenId);

        all_content.push(
            Content(_name, _writer, msg.sender, _contentHash, 0, false)
        );
        writerContent[_writer] = _tokenId;

        emit NewContent(_tokenId, _name, _writer, msg.sender);
        return true;
    }

    function stakeContent(uint256 _amount, uint256 _contentId) public {
        require(all_content[_contentId.sub(1)].community != msg.sender);
        require(_contentId > 0);
        require(writerContent[msg.sender] != _contentId);
        //add checkExpiry(true)

        disk.transferFrom(msg.sender, address(this), _amount);

        require(
            contentUserStake[_contentId][msg.sender].add(_amount) <= MAX_STAKE
        );
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

        //transfer to writer and community
        uint256 writerAmount = mulDiv(_amount, 7, 10);
        disk.transfer(all_content[_contentId.sub(1)].writer, writerAmount);
        disk.transfer(
            all_content[_contentId.sub(1)].community,
            _amount.sub(writerAmount)
        );

        emit NewContentStake(msg.sender, _amount, _contentId);
    }

    /*
    reward state functions
    */

    ///@notice normalizes content stakes, then allocates totalReward.
    function rewardSplit() external {
        //add checkExpiry(false)
        require(rewardsCalculated == false, "calc");
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
        require(rewardsCalculated == true, "need calc");
        uint256 contentId = writerContent[msg.sender];
        require(
            all_content[contentId].rewardClaimed == false,
            "reward claimed"
        );

        transferAmount = all_content[contentId.sub(1)].contentReward;
        usdc.transfer(msg.sender, transferAmount);
        all_content[contentId.sub(1)].rewardClaimed = true;

        emit RewardClaimed(msg.sender, transferAmount);
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
