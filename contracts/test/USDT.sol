pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";





contract USDT is ERC20, Ownable {


    constructor() ERC20("USDT Test", "USDT") {}

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }


}
