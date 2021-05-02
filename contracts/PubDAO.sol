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

    IERC20S disk;
    IERC20S reg;
    IERC20S prob;
    IERC20S cont;

    IRegistry registry;
    IStartProblem startProblem;

    //assign leader - grantRole(LEADER_ROLE) - done, need to make this a voting process later
    //asign editor - grantRole(EDITOR_ROLE) - done, need to make this a voting process later
    //leader executes registry and claim below - done
    //manage some token (USDC) used for staking problem
    //Editor create problem - done
    //Leaders submit problem - done
    //Leaders stake problem - done
    //User submits content - done
    //Editor reviews and publishes to problem - done

    //add voting minimums/processes

    mapping(bytes32 => Content) public proposedContent;

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
    }

    constructor(
        address _disk,
        address _regToken,
        address _probToken,
        address _contToken,
        address _registry,
        address _startProblem
    ) public {
        disk = IERC20S(_disk);
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

        //approve transfer
        registry.buyTokens(_tokens, _tokenType);
    }

    function register() external {
        require(hasRole(LEADER_ROLE, msg.sender) == true, "Not a leader");

        reg.approve(address(registry), 10**18);
        registry.registerPub();
    }

    function createProblem() external {
        require(
            hasRole(LEADER_ROLE, msg.sender) == true ||
                hasRole(EDITOR_ROLE, msg.sender) == true,
            "Not an editor or leader"
        );

        //add problem struct and tracking
    }

    function submitProblem() external {
        require(hasRole(LEADER_ROLE, msg.sender) == true, "Not an editor");
        //approve transfer

        //similar to content flow
    }

    function stakeProblem(uint256 _amount, bytes32 _hash) external {
        require(hasRole(LEADER_ROLE, msg.sender) == true, "Not a leader");
        Content memory tempContent = proposedContent[_hash];
        require(tempContent.published == true, "content not yet published");
        IProblemNFT problemNFT = IProblemNFT(tempContent.problemNFT);

        //approve transfer
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

        //transfer and approve functions
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
