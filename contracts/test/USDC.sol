pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "./FakeERC20.sol";





contract USDC is FakeERC20 {


    constructor() ERC20("USDC Test", "USDC") {}

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }


}
