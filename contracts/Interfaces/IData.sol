pragma solidity >=0.8.4;

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

interface IData {

    enum InterestRateType {FixedRate, FloatingRate}

    function updateTokenAllowed(
        address tokenA,
        address tokenB,
        bool allowed
    ) external;

    function updateClassIdToClass(uint classId, uint period, address tokenAddress, string memory symbol, InterestRateType interestRateType) external;

    function isPairAllowed(
        address tokenA,
        address tokenB) external view returns (bool);

    function classIdToInfos(
        uint classId
    ) external view returns(uint period, address tokenAddress, InterestRateType interestRateType);
}
