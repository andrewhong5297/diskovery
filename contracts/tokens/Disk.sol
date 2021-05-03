pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Disk is ERC20 {
    address registry;
    address admin;

    constructor() ERC20("Disk", "DK") {
        admin = msg.sender;
        _mint(msg.sender, 10**23); //at least 100,000
    }

    function setRegistry(address _registry) external {
        registry = _registry;
    }

    function mint(address _claimer, uint256 _amount) external {
        require(msg.sender == registry, "only registry can mint");
        _mint(_claimer, _amount);
    }

    function burn(uint256 _amount) external {
        require(msg.sender == registry, "only registry can burn");
        _burn(msg.sender, _amount);
    }
}
