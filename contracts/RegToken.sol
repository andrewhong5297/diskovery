pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RegToken is ERC20 {
    constructor() ERC20("RegToken", "RT") {}

    function mint(uint256 _amount, address _claimer) external {
        //require registry contract
        _mint(_claimer, _amount);
    }

    function burn(uint256 _amount, address _claimer) external {
        //require registry contract
        _burn(_claimer, _amount);
    }
}
