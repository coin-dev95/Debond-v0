pragma solidity ^0.8.4;

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


import './Interfaces/IData.sol';
import "./Interfaces/IERC20.sol";


contract DebondData is IData {


    struct Class {
        uint classId;
        uint period;
        address tokenAddress;
        string symbol;
        InterestRateType interestRateType; //fixed rate or flexible
    }

    mapping ( uint => Class) classIdToClass; // mapping from classId to class

    function updateClassIdToClass (uint classId, uint period, address tokenAddress, string memory symbol, InterestRateType interestRateType) public {
        Class storage class = classIdToClass[classId];
        class.classId = classId;
        class.period = period;
        class.tokenAddress = tokenAddress;
        class.interestRateType = interestRateType;
    }

    mapping (address => mapping ( address => bool ) ) public tokenAllowed; //private or??

    //tokens whitlistées

    // mapping class nounce?




    constructor(
        address _dbit,
        address _testToken
    ) {

        updateClassIdToClass(1, 1, _dbit, "DBIT", InterestRateType.FixedRate);
        updateClassIdToClass(2, 1, _testToken, "TEST", InterestRateType.FixedRate);

        tokenAllowed[_dbit][_testToken] = true;
        tokenAllowed[_testToken][_dbit] = true;

    }


    function updateTokenAllowed (
        address tokenA,
        address tokenB,
        bool allowed
    ) external override { //verify why override needed
        tokenAllowed[tokenA][tokenB] = allowed;
    }

    function isPairAllowed (
        address tokenA,
        address tokenB) external view returns (bool) {
        return tokenAllowed[tokenA][tokenB];
    }

    function classIdToInfos(
        uint classId
    ) external view returns(uint period, address tokenAddress, InterestRateType interestRateType) {
        Class storage class = classIdToClass[classId];
        period = class.period;
        tokenAddress = class.tokenAddress;
        interestRateType = class.interestRateType;
        return (period, tokenAddress, interestRateType);
    }





}
