pragma solidity ^0.8.0;

import "./IERC20.sol";

contract IDebondToken is IERC20 {
    function mint(address to, uint amount) external;
}
