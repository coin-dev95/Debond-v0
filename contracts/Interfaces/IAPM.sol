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

interface IAPM {
    function addLiquidity(
		address _baseToken,
		address _token,
		uint256 _amountBaseToken,
		uint256 _amountToken,
		uint256 _classBaseToken,
		uint256 _classIdToken,
		uint256 _nonecBaseToken,
		uint256 _nonceToken,
		address _to,
		uint deadline
	) external;

    function removeLiquidity(
		address _baseToken,
		address _token,
		uint256 _amountBaseToken,
		uint256 _amountToken,
		uint256 _classBaseToken,
		uint256 _classIdToken,
		uint256 _nonecBaseToken,
		uint256 _nonceToken,
		address _to,
		uint deadline
	) external;

    function getRatio( 
		address token0,
		address token1
	) external returns(uint256 previousRatio, uint256 ratio);

    function getPrice( 
		address token0,
		address token1
	) external returns(uint256 price);

    function updateReserves(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) external;

    function getReserves(
        address token0,
        address token1
    ) external view returns(uint256 reserve0, uint256 reserve1);

    function getPreviousReserves(
        address token0,
        address token1
    ) external view returns(uint256 reserve0, uint256 reserve1);
}