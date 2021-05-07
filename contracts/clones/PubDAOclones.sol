pragma solidity >=0.6.0;
//make this a minimal proxy for practice, and because this needs to be avail.

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IERC20S.sol";
import "../interfaces/IRegistry.sol";
import "../interfaces/IProblemNFT.sol";
import "../interfaces/IStartProblem.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "hardhat/console.sol";

contract PubDAOclones is AccessControl {
    using SafeMath for uint256;

    string public pubName;
    bool init = false;

    //admin has master control on roles
    bytes32 public constant LEADER_ROLE = keccak256("LEADER"); //votes on content and transactions (purchase of registration, problem, and content tokens)
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR"); //votes on content and calls final publication to NFT
    bytes32 public constant ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");

    IERC20S usdc;
    IERC20S disk;
    // IERC20S reg;
    // IERC20S prob;
    // IERC20S cont;

    IRegistry registry;
    IStartProblem startProblem;

    uint256 quorum = 0;
    // uint256 MIN_CONTENT_STAKE = 2 * 10**20; //starts at 200 disk minimum

    mapping(bytes32 => Content) public proposedContent;
    mapping(bytes32 => Problem) public proposedProblem;

    struct Content {
        // Unique id for looking up a content
        bytes32 contentHash;
        // Name of content
        string contentName;
        // Writer behind content submitted
        address writer;
        // Stake behind the content submitted
        // uint256 diskStaked;
        // the address of the problemNFT
        address problemNFT;
        // The block at which problemNFT expires
        uint256 endBlock;
        // if rejected by editor
        bool rejected;
        // Flag marking whether the proposal has been published
        bool published;
    }

    struct Problem {
        bytes32 problemHash;
        uint256 minimumStake;
        string problemText;
        uint256 expiry;
        bool created;
        bool rejected;
        uint256 forVotes;
        uint256 againstVotes;
    }

    mapping(bytes32 => mapping(address => bool)) hasVotedProblem;

    function initialize(
        address _disk,
        address _usdc,
        // address _regToken,
        // address _probToken,
        // address _contToken,
        address _registry,
        address _startProblem,
        string memory _pubName,
        address _owner
    ) public {
        require(init == false);
        init = true;
        disk = IERC20S(_disk);
        usdc = IERC20S(_usdc);
        // reg = IERC20S(_regToken);
        // prob = IERC20S(_probToken);
        // cont = IERC20S(_contToken);
        registry = IRegistry(_registry);
        startProblem = IStartProblem(_startProblem);
        _setupRole(ADMIN_ROLE, _owner);
        _setRoleAdmin(LEADER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(EDITOR_ROLE, ADMIN_ROLE);
        pubName = _pubName;
    }

    function withdraw(address _to, uint256 _amount) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "not admin");
        usdc.transfer(_to, _amount);
    }

    // function setContentStake(uint256 _min) external {
    //     require(hasRole(ADMIN_ROLE, msg.sender), "not admin");
    //     MIN_CONTENT_STAKE = _min;
    // }

    /*
    role functions, all must be called by admin only. Admin can be a multisig acct.
    */
    function manageEditor(address _Editor, bool _state) external {
        if (_state == false) {
            revokeRole(EDITOR_ROLE, _Editor);
            quorum = quorum.sub(1);
        } else {
            grantRole(EDITOR_ROLE, _Editor);
            quorum = quorum.add(1);
        }
    }

    function manageLeader(address _Leader, bool _state) external {
        if (_state == false) {
            revokeRole(LEADER_ROLE, _Leader);
            quorum = quorum.sub(1);
        } else {
            grantRole(LEADER_ROLE, _Leader);
            quorum = quorum.add(1);
        }
    }

    function setQuorum(uint256 _quorum) external {
        require(hasRole(ADMIN_ROLE, msg.sender) == true, "not admin");
        require(_quorum > 0, "minimum quorum of 1");
        quorum = _quorum;
    }

    /*
    registry functions
    */
    // function claimTokens() external {
    //     require(hasRole(LEADER_ROLE, msg.sender) == true, "Not a leader");
    //     registry.claimWeeklyPub();
    // }

    // function buyTokens(uint256 _tokens, uint256 _tokenType) external {
    //     require(hasRole(ADMIN_ROLE, msg.sender) == true, "Not admin");

    //     disk.approve(
    //         address(registry),
    //         _tokens.mul(registry.checkMinimum(_tokenType))
    //     );
    //     registry.buyTokens(_tokens, _tokenType);
    // }

    function register() external {
        require(hasRole(ADMIN_ROLE, msg.sender) == true, "Not admin");
        // add in _daoName later
        // reg.approve(address(registry), 10**18);
        registry.registerPub();
    }

    /*
    startProblem functions
    */
    function suggestProblem(
        bytes32 _hash,
        uint256 _reward,
        string memory _text,
        uint256 _expiry
    ) external {
        require(
            hasRole(LEADER_ROLE, msg.sender) == true ||
                hasRole(EDITOR_ROLE, msg.sender) == true,
            "Not an editor or leader"
        );
        require(
            proposedProblem[_hash].problemHash == 0,
            "problem created already"
        );
        (uint256 minE, uint256 maxE) = startProblem.getExpiryBounds();
        require(_expiry <= maxE && _expiry >= minE);
        require(_reward >= startProblem.getMinRewards());

        proposedProblem[_hash] = Problem({
            problemHash: _hash,
            minimumStake: _reward,
            problemText: _text,
            expiry: _expiry,
            created: false,
            rejected: false,
            forVotes: 1,
            againstVotes: 0
        });
        hasVotedProblem[_hash][msg.sender] = true;
    }

    /// @notice function automatically submits problem or rejects based on quorum threshold.
    function voteProblem(bytes32 _hash, bool _support) external {
        require(proposedProblem[_hash].created == false, "already published");
        require(
            hasRole(LEADER_ROLE, msg.sender) == true ||
                hasRole(EDITOR_ROLE, msg.sender) == true,
            "Not an editor or leader"
        );
        require(hasVotedProblem[_hash][msg.sender] == false, "already voted");

        if (_support) {
            proposedProblem[_hash].forVotes = proposedProblem[_hash]
                .forVotes
                .add(1);
            if (proposedProblem[_hash].forVotes >= quorum) {
                submitProblem(_hash);
            }
        } else {
            proposedProblem[_hash].forVotes = proposedProblem[_hash]
                .againstVotes
                .add(1);
            if (proposedProblem[_hash].againstVotes >= quorum) {
                proposedProblem[_hash].rejected = true;
            }
        }
        hasVotedProblem[_hash][msg.sender] = true;
    }

    function submitProblem(bytes32 _hash) internal {
        Problem memory tempProblem = proposedProblem[_hash];
        // prob.approve(address(startProblem), 10**18); //problem token transfer
        usdc.approve(address(startProblem), tempProblem.minimumStake);
        startProblem.createProblem(
            tempProblem.problemHash,
            tempProblem.minimumStake,
            tempProblem.expiry,
            tempProblem.problemText
        );
        proposedProblem[_hash].created = true;
    }

    function stakeProblem(uint256 _amount, bytes32 _hash) external {
        require(hasRole(ADMIN_ROLE, msg.sender) == true, "Not an admin");
        Content memory tempContent = proposedContent[_hash];
        require(tempContent.published == true, "content not yet published");
        IProblemNFT problemNFT = IProblemNFT(tempContent.problemNFT);

        usdc.approve(address(problemNFT), _amount);
        problemNFT.addStake(_amount);
    }

    /*
    publishing functions
    */

    /// @notice content is submitted by writer. Publisher should know if they have already submitted content from this writer to a problem before (can be frontend notif)
    function submitContent(
        bytes32 _contentHash,
        string memory _contentName,
        address _problemNFT,
        // uint256 _stake,
        uint256 _expiry
    ) external {
        require(
            proposedContent[_contentHash].writer == address(0),
            "there is already content with this hash"
        );
        // require(_stake >= MIN_CONTENT_STAKE, "not enough stake");
        // disk.transferFrom(msg.sender, address(this), _stake);
        proposedContent[_contentHash] = Content(
            _contentHash,
            _contentName,
            msg.sender,
            // _stake,
            _problemNFT,
            _expiry,
            false,
            false
        );
    }

    /// @notice content accepted and published by editor.
    function publishContent(bytes32 _hash) external {
        require(hasRole(EDITOR_ROLE, msg.sender) == true, "Not an editor");
        Content memory tempContent = proposedContent[_hash];
        require(block.timestamp <= tempContent.endBlock, "too late");
        require(tempContent.published == false, "content already published");
        require(tempContent.rejected == false, "content already rejected");
        IProblemNFT problemNFT = IProblemNFT(tempContent.problemNFT);

        // cont.approve(address(problemNFT), 10**18);
        problemNFT.newContent(
            tempContent.writer,
            tempContent.contentName,
            tempContent.contentHash
        );
        proposedContent[_hash].published = true;
    }

    function rejectContent(bytes32 _hash) external {
        require(hasRole(EDITOR_ROLE, msg.sender) == true, "Not an editor");
        Content memory tempContent = proposedContent[_hash];
        require(tempContent.published == false, "content already published");
        require(tempContent.rejected == false, "content already rejected");
        proposedContent[_hash].rejected = true;
    }
}
