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

    function updaReserveAfterAddingLiquidity(
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1
    ) external;

    function updaReserveAfterRemovingLiquidity(
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1
    ) external;

    function updateRatioAfterAddingLiquidity(
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1
    ) external;

    function updateRatioAfterRemovingLiquidity(
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1
    ) external;

    function getReserves(
        address _token
    ) external view returns(uint256 _reserve);

    function getRatios(
        address _token0,
        address _token1
    ) external view returns(uint256 _ratio01, uint256 _ratio10);

    function getPrices(
        address _token0,
        address _token1
    ) external view returns(uint256 _price01, uint256 _price10);
}
