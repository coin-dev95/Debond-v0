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

contract APM is IAPM {
    using SafeMath for uint256;

	// token reserve L(tA)
	mapping(address => uint256[2]) internal reserve;

    /**
    * @dev update revserve of a token pair when adding or removing liquidity
    * @param _token0 address of the first token
    * @param _token1 address of the second token
    * @param _amount0 amount of first tokens to add
    * @param _amount1 amount of second tokens to add
    * @dev @Edoumou
    */
    function updateReserves(address _token0, address _token1, uint256 _amount0, uint256 _amount1) external {
		uint256 _reserve0 = reserve[_token0][1];
		uint256 _reserve1 = reserve[_token1][1];

		(reserve[_token0][0], reserve[_token1][0]) = (_reserve0, _reserve1);
		(reserve[_token0][1], reserve[_token1][1]) = (_amount0, _amount1);
	}

    /**
    * @dev get revserve of a token pair
    * @param _token0 address of the first token
    * @param _token1 address of the second token
    * @dev @Edoumou
    */
    function getReserves(address _token0, address _token1) external view returns(uint256 reserve0, uint256 reserve1) {
        (reserve0, reserve1) = (reserve[_token0][1], reserve[_token1][1]);
    }

    /**
    * @dev get previous revserve of a token pair
    * @param _token0 address of the first token
    * @param _token1 address of the second token
    * @dev @Edoumou
    */
    function getPreviousReserves(address _token0, address _token1) external view returns(uint256 reserve0, uint256 reserve1) {
        (reserve0, reserve1) = (reserve[_token0][0], reserve[_token1][0]);
    }

    function getRatio(address token0, address token1) external returns(uint256 previousRatio, uint256 ratio) {

    }

    function getPrice(address _token0, address _token1) external returns(uint256 price) {

    }
    
}
