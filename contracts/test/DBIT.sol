pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../interfaces/IDebondToken.sol";


contract DBIT is ERC20, IDebondToken, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("D/BIT TOKEN", "DBIT") {
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
    }


}
