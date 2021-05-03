//allows new problemNFTs to be created.
pragma solidity >=0.6.0;

import "./ProblemNFT.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IERC20S.sol";
import "./interfaces/IRegistry.sol";

contract StartProblem {
    using SafeMath for uint256;

    address admin;

    IERC20S usdc;
    // IERC20S prob;
    // address cont;
    address disk;
    uint256 MINIMUM_REWARD = 4000;
    uint256 MIN_EXPIRY = 40320; //a week
    uint256 MAX_EXPIRY = 161280; //a month
    uint256 MAX_STAKE = 3 * 10**21; //3000 max tokens
    IRegistry reg;

    mapping(bytes32 => address) public deployedProblem;

    event NewProblemDeployed(
        bytes32 problemHash,
        address deployedAddress,
        address deployer,
        string problemText,
        uint256 minimumReward
    );

    constructor(
        address _disk,
        address _reg,
        address _usdc // address _prob, // address _cont
    ) {
        usdc = IERC20S(_usdc);
        // prob = IERC20S(_prob);
        reg = IRegistry(_reg);
        disk = _disk;
        // cont = _cont;
        admin = msg.sender;
    }

    function setOptions(
        uint256 _minR,
        uint256 _maxE,
        uint256 _minE,
        uint256 _maxS
    ) external {
        require(msg.sender == admin);
        MINIMUM_REWARD = _minR;
        MIN_EXPIRY = _minE;
        MAX_EXPIRY = _maxE;
        MAX_STAKE = _maxS;
    }

    /*
    pre_deploy functions
    */
    function createProblem(
        bytes32 _hash,
        uint256 _minimumReward,
        uint256 _expiry,
        string memory _text
    ) external returns (address) {
        require(deployedProblem[_hash] == address(0));
        require(_minimumReward >= MINIMUM_REWARD);
        require(_expiry <= MAX_EXPIRY && _expiry >= MIN_EXPIRY);
        require(reg.checkPubDAO(msg.sender) == true);

        // require(prob.transferFrom(msg.sender, address(this), 10**18), "prob");
        require(
            usdc.transferFrom(msg.sender, address(this), _minimumReward),
            "usdc"
        );

        //add CREATE2 in here later
        ProblemNFT newProblem =
            new ProblemNFT(
                _hash,
                disk,
                address(usdc),
                _minimumReward,
                msg.sender,
                // _text,
                address(reg),
                // cont,
                MAX_STAKE,
                _expiry
            );
        deployedProblem[_hash] = address(newProblem);
        usdc.transfer(address(newProblem), _minimumReward);

        emit NewProblemDeployed(
            _hash,
            address(newProblem),
            msg.sender,
            _text,
            _minimumReward
        );
        return address(newProblem);
    }

    /**
    @notice Get the address of the project by problemhash
    @return problemAddress address of the deployed problem
    @param _hash problemhash created in frontend (probably just sha256 of string + address + date?)
    */
    function getProblem(bytes32 _hash)
        external
        view
        returns (address problemAddress)
    {
        return deployedProblem[_hash];
    }

    function getExpiryBounds() external view returns (uint256, uint256) {
        return (MIN_EXPIRY, MAX_EXPIRY);
    }

    function getMinRewards() external view returns (uint256) {
        return MINIMUM_REWARD;
    }
}
