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

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAPM.sol";
import "./libraries/SafeMath.sol";


contract APM is IAPM {
    using SafeMath for uint256;

    mapping(address => uint256) internal reserve;
    mapping(address => mapping(address => uint256)) internal ratio;
    mapping(address => mapping(address => uint256)) internal price;

    /**
    * @dev update revserve of tokens after adding liquidity
    * @param _token address of the token
    * @param _amount amount of the tokens to add
    */
    function updaReserveAfterAddingLiquidity(address _token, uint256 _amount) external {
        require(_token != address(0), "Not valid token address");
        require(_amount > 0, "Debond: No liquidity sent");

        uint256 _reserve = reserve[_token];
		reserve[_token] = _reserve + _amount;
	}

    /**
    * @dev update revserve of tokens after removing liquidity
    * @param _token address of the token
    * @param _amount amount of the tokens to add
    */
    function updaReserveAfterRemovingLiquidity(address _token, uint256 _amount) external {
        require(_token != address(0), "Notr valid token address");
        require(_amount > 0, "Debond: No liquidity sent");

        uint256 _reserve0 = reserve[_token];
		reserve[_token] = _reserve0 - _amount;
	}

    /**
    * @dev update rations of a token pair
    * @param _token0 address of the first token
    * @param _token1 address of the second token
    * @param _amount0 amount of first tokens to add
    * @param _amount1 amount of second tokens to add
    */
    function updateRatioAfterAddingLiquidity(address _token0, address _token1, uint256 _amount0, uint256 _amount1) external {
        require(_token0 != address(0) && _token1 != address(0), "Notr valid token address");
        require(_amount0 > 0 && _amount1 > 0, "Debond: No liquidity sent");

        (uint256 _ratio0, uint256 _ratio1) = (ratio[_token0][_token1], ratio[_token1][_token0]);

		(ratio[_token0][_token1], ratio[_token1][_token0]) = (_ratio0 + _amount0 , _ratio1 + _amount1);
	}

    /**
    * @dev update rations of a token pair after removing liquidity
    * @param _token0 address of the first token
    * @param _token1 address of the second token
    * @param _amount0 amount of first tokens to add
    * @param _amount1 amount of second tokens to add
    */
    function updateRatioAfterRemovingLiquidity(address _token0, address _token1, uint256 _amount0, uint256 _amount1) external {
        require(_token0 != address(0) && _token1 != address(0), "Notr valid token address");
        require(_amount0 > 0 && _amount1 > 0, "Debond: No liquidity sent");

        (uint256 _ratio0, uint256 _ratio1) = (ratio[_token0][_token1], ratio[_token1][_token0]);

		(ratio[_token0][_token1], ratio[_token1][_token0]) = (_ratio0 - _amount0 , _ratio1 - _amount1);
	}

    /**
    * @dev get revserve of a token pair
    * @param _token address of the first token
    * @param _reserve the total liquidity of _token in the APM
    */
    function getReserve(address _token) external view returns(uint256 _reserve) {
        _reserve = reserve[_token];
    }

    /**
    * @dev get ratios of a token pair
    * @param _token0 address of the first token
    * @param _token1 address of the second token
    * @param _ratio01 ratio of token0: The amount of tokens _token0 in the pool (token0, token1)
    * @param _ratio10 ratio of token1: The amount of tokens _token1 in the pool (token0, token1)
    */
    function getRatios(address _token0, address _token1) external view returns(uint256 _ratio01, uint256 _ratio10) {
		return (ratio[_token0][_token1], ratio[_token1][_token0]);
	}

     /**
    * @dev get prices of a token pair
    * @param _token0 address of the first token
    * @param _token1 address of the second token
    * @param _price01 price: ratio[_token1] / ratio[_token0]
    * @param _price10 price: ratio[_token0] / ratio[_token1]
    */
    function getPrices(address _token0, address _token1) external view returns(uint256 _price01, uint256 _price10) {
		return (
            (ratio[_token1][_token0] / ratio[_token0][_token1]) * 1 ether,
            (ratio[_token0][_token1] / ratio[_token1][_token0]) * 1 ether
        );
	} 
}

