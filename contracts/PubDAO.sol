pragma solidity >=0.6.0;
//make this a minimal proxy for practice, and because this needs to be avail.

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IERC20S.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/IProblemNFT.sol";
import "./interfaces/IStartProblem.sol";

contract PubDAO is AccessControl {
    //admin has master control on roles
    bytes32 public constant LEADER_ROLE = keccak256("LEADER"); //votes on content and transactions (purchase of registration, problem, and content tokens)
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR"); //votes on content and calls final publication to NFT

    IERC20S usdc;
    IERC20S disk;
    IERC20S reg;
    IERC20S prob;
    IERC20S cont;

    IRegistry registry;
    IStartProblem startProblem;

    //assign leader - grantRole(LEADER_ROLE) - done, need to make this a voting process later
    //asign editor - grantRole(EDITOR_ROLE) - done, need to make this a voting process later
    //add voting processes, this will be a pain since it probably requires it's own expiry/quorum process.

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
        uint256 diskStaked;
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
    }

    constructor(
        address _disk,
        address _usdc,
        address _regToken,
        address _probToken,
        address _contToken,
        address _registry,
        address _startProblem
    ) public {
        disk = IERC20S(_disk);
        usdc = IERC20S(_usdc);
        reg = IERC20S(_regToken);
        prob = IERC20S(_probToken);
        cont = IERC20S(_contToken);
        registry = IRegistry(_registry);
        startProblem = IStartProblem(_startProblem);
    }

    function claimTokens() external {
        require(hasRole(LEADER_ROLE, msg.sender) == true, "Not a leader");
        registry.claimWeeklyPub();
    }

    function buyTokens(uint256 _tokens, uint256 _tokenType) external {
        require(hasRole(LEADER_ROLE, msg.sender) == true, "Not a leader");

        disk.approve(address(registry), _tokens);
        registry.buyTokens(_tokens, _tokenType);
    }

    function register() external {
        require(hasRole(LEADER_ROLE, msg.sender) == true, "Not a leader");

        reg.approve(address(registry), 10**18);
        registry.registerPub();
    }

    function createProblem(
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
        proposedProblem[_hash] = Problem(_hash, _reward, _text, _expiry);
    }

    function submitProblem(bytes32 _hash) external {
        require(hasRole(LEADER_ROLE, msg.sender) == true, "Not an editor");
        Problem memory tempProblem = proposedProblem[_hash];
        usdc.approve(address(startProblem), tempProblem.minimumStake);
        startProblem.createProblem(
            tempProblem.problemHash,
            tempProblem.minimumStake,
            tempProblem.expiry,
            tempProblem.problemText
        );
    }

    function stakeProblem(uint256 _amount, bytes32 _hash) external {
        require(hasRole(LEADER_ROLE, msg.sender) == true, "Not a leader");
        Content memory tempContent = proposedContent[_hash];
        require(tempContent.published == true, "content not yet published");
        IProblemNFT problemNFT = IProblemNFT(tempContent.problemNFT);

        usdc.approve(address(problemNFT), _amount);
        problemNFT.addStake(_amount);
    }

    function submitContent(
        bytes32 _hash,
        string memory _contentName,
        address _problemNFT,
        uint256 _stake,
        uint256 _expiry
    ) external {
        require(
            proposedContent[_hash].writer == address(0),
            "there is already content with this hash"
        );
        proposedContent[_hash] = Content(
            _hash,
            _contentName,
            msg.sender,
            _stake,
            _problemNFT,
            _expiry,
            false,
            false
        );
    }

    function publishContent(bytes32 _hash) external {
        require(hasRole(EDITOR_ROLE, msg.sender) == true, "Not an editor");
        Content memory tempContent = proposedContent[_hash];
        require(tempContent.published == false, "content already published");
        require(tempContent.rejected == false, "content already rejected");
        IProblemNFT problemNFT = IProblemNFT(tempContent.problemNFT);

        cont.approve(address(problemNFT), 10**18);
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
