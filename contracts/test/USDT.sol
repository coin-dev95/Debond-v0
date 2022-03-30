pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "./FakeERC20.sol";


contract USDT is FakeERC20 {


    constructor() ERC20("USDT Test", "USDT") {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }


}
