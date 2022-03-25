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

    // ratio factors r_{tA (tB)} of a pair
	mapping(address => mapping(address => uint256[2])) internal ratio;
	// price P(tA, tB) in a pair
	mapping(address => mapping(address => uint256)) internal price;
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

    function getRatios(address token0, address token1) external view returns(uint256 previousRatio, uint256 currentRatio) {
		return (ratio[token0][token1][0], ratio[token0][token1][1]);
	}

    function getPrices(address token0, address token1) external view returns(uint256) {
		return price[token0][token1];
	}

    function updateRatioFactor( 
		address token0,
		address token1,
		uint256 amount0,
		uint256 amount1
	) public returns(uint256 ratio01, uint256 ratio10) {
		uint256[2] memory _ratio01 = ratio[token0][token1];  // gas savings
		uint256[2] memory _ratio10 = ratio[token1][token0]; // gas savings
		uint256 _reserve0 = reserve[token0][1];
		uint256 _reserve1 = reserve[token1][1];

		reserve[token0][0] = _reserve0;
		reserve[token1][0] = _reserve1;

		uint256 numerator0 = ((_ratio01[0].mul0(_reserve0)) / (1 ether)).add(amount0);
		uint256 numerator1 = ((_ratio10[0].mul0(_reserve1)) / (1 ether)).add(amount1);

		ratio[token0][token1][1] = numerator0.div(( (_reserve0.add(amount0)) / (1 ether)));
		ratio[token1][token0][1] = numerator1.div(( (_reserve1.add(amount1)) / (1 ether)));

		reserve[token0][1] = _reserve0.add(amount0);
		reserve[token1][1] = _reserve1.add(amount1);

		return (ratio[token0][token1][1], ratio[token1][token0][1]);
	}

    function updatePrice(address token0, address token1) public returns(uint256 price0, uint256 price1) {
		uint256[2] memory _ratio01 = ratio[token0][token1];  // gas savings
		uint256[2] memory _ratio10 = ratio[token1][token0]; // gas savings
		uint256 _reserve0 = reserve[token0][1];
		uint256 _reserve1 = reserve[token1][1];

		uint256 denominator0 = _ratio01[0].mul0(reserve[token0][1]).div(1 ether);
		uint256 denominator1 = _ratio10[0].mul0(reserve[token1][1]).div(1 ether);

		price[token0][token1] = _ratio10[1].mul0(_reserve0).div(denominator0);
		price[token1][token0] = _ratio01[1].mul0(_reserve1).div(denominator1);

		return (price[token0][token1], price[token1][token0]);
	}


    
}