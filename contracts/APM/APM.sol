pragma solidity 0.8.13;

// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <info@SGM.finance>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

import "../Interfaces/IAPM.sol";
import "../Libraries/SafeMath.sol";

contract APM {
    using SafeMath for uint256;

    mapping(address => uint256[2]) internal reserve;

    /**
    * @dev update revserve of a token pair when adding or removing liquidity
    * @param token0 address of the first token
    * @param token1 address of the second token
    */
    function updateReserve(address token0, address token1, uint256 amount0, uint256 amount1) external {
		uint256 _reserve0 = reserve[token0][1];
		uint256 _reserve1 = reserve[token1][1];

		(reserve[token0][0], reserve[token1][0]) = (_reserve0, _reserve1);
		(reserve[token0][1], reserve[token1][1]) = (_reserve0.add(amount0), _reserve1.add(amount1));
	}
}