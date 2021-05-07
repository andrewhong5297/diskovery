pragma solidity >=0.6.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./PubDAOclones.sol";

contract PubDAOfactory {
    address immutable tokenImplementation;

    address disk;
    address usdc;
    // address regToken,
    // address probToken,
    // address contToken,
    address registry;
    address startProblem;

    mapping(string => address) projectSearch;

    constructor(
        address _disk,
        address _usdc,
        // address _regToken,
        // address _probToken,
        // address _contToken,
        address _registry,
        address _startProblem
    ) public {
        tokenImplementation = address(new PubDAOclones());
        disk = _disk;
        usdc = _usdc;
        // regToken = _regToken;
        // probToken = _probToken;
        // contToken = _contToken;
        registry = _registry;
        startProblem = _startProblem;
    }

    function createDao(string memory _daoName) external returns (address) {
        address clone = Clones.clone(tokenImplementation);
        PubDAOclones(clone).initialize(
            disk,
            usdc,
            // regToken,
            // probToken,
            // contToken,
            registry,
            startProblem,
            _daoName,
            msg.sender
        );
        projectSearch[_daoName] = clone;
        return clone;
    }

    function getDao(string memory _daoName) external view returns (address) {
        return projectSearch[_daoName];
    }
}
