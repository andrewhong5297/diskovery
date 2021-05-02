//allows new problemNFTs to be created.
pragma solidity >=0.6.0;

import "./ProblemNFT.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IERC20S.sol";
import "./interfaces/IRegistry.sol";

//add registry, stake tokens, and burn tokens

contract StartProblem {
    using SafeMath for uint256;

    IERC20S usdc;
    address disk;
    uint256 MINIMUM_REWARD = 4000;
    IRegistry reg;

    // ProblemNFT[] public problems; //not sure if this is better to have, or if we just save space without this array and get function.
    mapping(bytes32 => address) public deployedProblem;

    event NewProblem(bytes32 problemHash, address creator);
    event NewProblemDeployed(bytes32 problemHash, address deployedAddress);

    //add more structure to problem statements? either here or in the DAO
    struct Problem {
        bytes32 problemHash;
        uint256 minimumReward;
        string problemText;
        address communityProposer;
    }

    mapping(bytes32 => Problem) newProblems;

    constructor(
        address _disk,
        address _reg,
        address _usdc
    ) {
        usdc = IERC20S(_usdc);
        disk = _disk;
        reg = IRegistry(_reg);
    }

    /*
    pre_deploy functions
    */
    function createProblem(
        bytes32 _hash,
        uint256 _minimumReward,
        string memory _text
    ) external {
        require(
            newProblems[_hash].problemHash == 0,
            "problem has been created already"
        );
        require(
            _minimumReward >= MINIMUM_REWARD,
            "must set a higher minimum reward"
        );
        //require this to be community
        //recieve/burn a problem token

        //transfer staked tokens (USDC) require transfer to be true
        newProblems[_hash] = Problem(_hash, _minimumReward, _text, msg.sender);
        deployNewProblem(_hash);
        emit NewProblem(_hash, msg.sender);
    }

    /*
    this function should be called by any pub in the registry
    */
    function deployNewProblem(bytes32 _hash) internal returns (address) {
        //add CREATE2 in here later
        ProblemNFT newProblem =
            new ProblemNFT(
                _hash,
                disk,
                newProblems[_hash].minimumReward,
                newProblems[_hash].communityProposer,
                newProblems[_hash].problemText
            );
        deployedProblem[_hash] = address(newProblem);
        // problems.push(newProblem);

        //transfer ETH or whatever from this contract to address(newProblem);

        emit NewProblemDeployed(_hash, address(newProblem));
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
        require(
            deployedProblem[_hash] != address(0),
            "problem not deployed yet"
        );
        return deployedProblem[_hash];
    }
}
