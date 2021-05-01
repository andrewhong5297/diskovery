//allows new problemNFTs to be created.
pragma solidity >=0.6.0;

import "./ProblemNFT.sol";

// import "./AllRegistry.sol"; add interface later

contract StartProblem {
    //how to store problem queue (should there be a problem queue? does problem need to have a minimum stake before NFT is deployed? Should stake be in disk or USDC?
    address disk;
    // AllRegistry reg;

    mapping(bytes32 => address) public hashToProblem;
    // ProblemNFT[] public problems;

    event NewProblem(
        //remember you already set up theGraph for this
        bytes32 problemHash,
        address creator
    );

    constructor(address _disk, address _reg) {
        disk = _disk;
        // reg = AllRegistry(_reg);
    }

    /*
    this function should be called by any pub in the registry
    */
    function deployNewProblem(bytes32 _hash) external returns (address) {
        require(
            hashToProblem[_hash] == address(0),
            "This problem has been created already"
        );
        //require(reg.pubRegistry[msg.sender]==true,"not a publication, can't submit a problem");
        //burn a problem token, revert if this fails

        //add CREATE2 in here later
        ProblemNFT newProblem = new ProblemNFT(_hash, disk);
        hashToProblem[_hash] = address(newProblem);
        // problems.push(newProblem);

        emit NewProblem(_hash, msg.sender);

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
        return hashToProblem[_hash];
    }
}
