pragma solidity >=0.6.0;

import "./PubDAO.sol";
import "./interfaces/IERC20S.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

////stores all users and roles, and if they have claimed this week yet or not.
//should people be allowed to buy disk tokens at a base USDC price of 1 cent? meaning each 1000 tokens is 10 dollars...
//need to add setter functions for governance of base prices and claims
contract AllRegistry {
    using SafeMath for uint256;

    IERC20S disk; //disk token
    IERC20S reg; //registration token
    IERC20S prob; //problem token
    IERC20S cont; //content token

    //base prices
    uint256 REG_TOKEN_MINIMUM = 5 * 10**5; //500,000
    uint256 PROB_TOKEN_MINIMUM = 5 * 10**4; //50,000
    uint256 CONT_TOKEN_MINIMUM = 5 * 10**3; //5,000

    //base claims
    uint256 C_USER_TOKEN = 10**21;
    uint256 C_PUB_TOKEN = 10**22;
    uint256 C_PROB_TOKEN = 10**18;
    uint256 C_CONT_TOKEN = 10**19;

    //everyone claims once a week
    uint256 public startTime;
    uint256 public nextTime;
    mapping(address => uint256) public userClaimTracking;
    mapping(address => uint256) public pubClaimTracking;

    //pubDAOs that have been registered already
    mapping(address => bool) public pubRegistry;

    constructor(
        address _disk,
        address _regToken,
        address _probToken,
        address _contToken
    ) public {
        disk = IERC20S(_disk);
        reg = IERC20S(_regToken);
        prob = IERC20S(_probToken);
        cont = IERC20S(_contToken);
        startTime = block.timestamp;
        nextTime = startTime.add(40320);
    }

    function registerPub() public returns (bool sucess) {
        require(pubRegistry[msg.sender] == false, "you're already registered!");
        reg.transferFrom(msg.sender, address(this), 10**18); //transfer one token
        reg.burn(10**18);
        pubRegistry[msg.sender] = true;
        return true;
    }

    function checkPubDAO(address _checker) external view returns (bool isDao) {
        if (pubRegistry[_checker] == true) {
            isDao = true;
        } else {
            isDao = false;
        }
    }

    function buyTokens(uint256 _tokens, uint256 _tokenType) external {
        require(pubRegistry[msg.sender] == true, "only pubDAO can claim here");
        uint256 multiplier = 0;
        IERC20S token = IERC20S(address(0));
        if (_tokenType == 0) {
            //register token
            multiplier = REG_TOKEN_MINIMUM;
            token = reg;
        } else if (_tokenType == 1) {
            //problem token
            multiplier = PROB_TOKEN_MINIMUM;
            token = prob;
        } else if (_tokenType == 2) {
            //content token
            multiplier = CONT_TOKEN_MINIMUM;
            token = cont;
        } else {
            revert("invalid token type");
        }
        disk.transferFrom(msg.sender, address(this), _tokens.mul(multiplier));
        disk.burn(_tokens.mul(multiplier));
        token.mint(msg.sender, _tokens);
    }

    function claimWeeklyPub() external {
        require(pubRegistry[msg.sender] == true, "only pubDAO can claim here");
        if (block.timestamp > nextTime) {
            startTime = nextTime;
            nextTime = startTime.add(40320);
        }
        require(
            pubClaimTracking[msg.sender] <= startTime,
            "pub has already claimed this week"
        );
        prob.mint(msg.sender, C_PROB_TOKEN);
        cont.mint(msg.sender, C_CONT_TOKEN);
        disk.mint(msg.sender, C_PUB_TOKEN);
        pubClaimTracking[msg.sender] = block.timestamp;
    }

    function claimWeeklyUser() external {
        require(pubRegistry[msg.sender] == false, "pubDAO can't claim here");
        if (block.timestamp > nextTime) {
            startTime = nextTime;
            nextTime = startTime.add(40320);
        }
        require(
            userClaimTracking[msg.sender] <= startTime,
            "user has already claimed this week"
        );
        disk.mint(msg.sender, C_USER_TOKEN);
        userClaimTracking[msg.sender] = block.timestamp;
    }
}
