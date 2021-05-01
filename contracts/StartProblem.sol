//allows new problemNFTs to be created.
pragma solidity >=0.6.0;

import "./ProblemNFT.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

// import "./AllRegistry.sol"; add interface later

contract StartProblem {
    using SafeMath for uint256;

    address disk;
    // AllRegistry reg;

    // ProblemNFT[] public problems; //not sure if this is better to have, or if we just save space without this array and get function.
    mapping(bytes32 => address) public deployedProblem;
    mapping(bytes32 => address[]) public problemCommunities;

    event NewProblem(bytes32 problemHash, address creator);

    event NewStake(bytes32 problemHash, address community, uint256 amount);

    event NewProblemDeployed(bytes32 problemHash, address deployedAddress);

    struct Problem {
        bytes32 problemHash;
        uint256 totalReward;
        bool deployed;
    }

    mapping(bytes32 => Problem) newProblems;

    constructor(address _disk, address _reg) {
        disk = _disk;
        // reg = AllRegistry(_reg);
    }

    /*
    pre_deploy functions
    */
    function createProblem(bytes32 _hash) external {
        require(
            newProblems[_hash].problemHash == 0,
            "problem has been created already"
        );
        //require this to be community
        //burn a problem token
        newProblems[_hash] = Problem(_hash, 0, false);
        emit NewProblem(_hash, msg.sender);
    }

    //add some priced token as deposit to overall reward
    function stakeProblem(bytes32 _hash, uint256 _amount) external payable {
        require(
            newProblems[_hash].problemHash != 0,
            "problem has not been created yet"
        );
        require(
            deployedProblem[_hash] == address(0),
            "problem already deployed, go stake on the contract"
        );

        //require msg.sender to be community

        newProblems[_hash].totalReward = newProblems[_hash].totalReward.add(
            _amount
        );
        problemCommunities[_hash].push(msg.sender);
        emit NewStake(_hash, msg.sender, _amount);

        //check if minimum stake was met, if so then deployNewProblem.
        if (newProblems[_hash].totalReward >= 2000) {
            deployNewProblem(_hash);
        }
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
                newProblems[_hash].totalReward,
                problemCommunities[_hash]
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
