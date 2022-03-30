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


import './interfaces/IData.sol';
import './libraries/CDP.sol';

contract DebondData is IData {

    uint public constant SIX_M_PERIOD = 60; // 1 min period for tests

    struct Class {
        uint id;
        bool exists;
        string symbol;
        InterestRateType interestRateType;
        address tokenAddress;
        uint periodTimestamp;
        uint lastNonceIdCreated;
        uint lastNonceIdCreatedTimestamp;
    }

    mapping(uint => Class) classes; // mapping from classId to class

    mapping(address => mapping( address => bool)) public tokenAllowed;

    // data to be exclusively for the front end (for now)
    mapping(uint => uint[]) purchasableClasses;
    uint[] debondClasses;

    constructor(
        address DBIT,
        address USDC,
        address USDT,
        address DAI
//        address governance
    ) {

        addClass(0, "DBIT", InterestRateType.FixedRate, DBIT, SIX_M_PERIOD);
        addClass(1, "USDC", InterestRateType.FixedRate, USDC, SIX_M_PERIOD);
        addClass(2, "USDT", InterestRateType.FixedRate, USDT, SIX_M_PERIOD);
        addClass(3, "DAI", InterestRateType.FixedRate, DAI, SIX_M_PERIOD);

<<<<<<< HEAD
        (address token1, address token2) = CDP.sortTokens(DBIT,USDC);
        tokenAllowed[token1][token2] = true;

        (token1, token2) = CDP.sortTokens(DBIT,USDT);
        tokenAllowed[token1][token2] = true;

        (token1, token2) = CDP.sortTokens(DBIT,DAI);
        tokenAllowed[token1][token2] = true;
        
=======
        purchasableClasses[0].push(1);
        purchasableClasses[0].push(2);
        purchasableClasses[0].push(3);

        (address token1, address token2) = sortTokens(DBIT,USDC);
        tokenAllowed[token1][token2] = true;

        (token1, token2) = sortTokens(DBIT,USDT);
        tokenAllowed[token1][token2] = true;

        (token1, token2) = sortTokens(DBIT,DAI);
        tokenAllowed[token1][token2] = true;
>>>>>>> d6bc324818a83c3b72438573eb19e5bd6a659e33

    }

    /**
     * @notice this method should only be called by the governance contract TODO Only Governance
     */
    function addClass(uint classId, string memory symbol, InterestRateType interestRateType, address tokenAddress, uint periodTimestamp) public override {
        Class storage class = classes[classId];
        require(!class.exists, "DebondData: cannot add an existing classId");
        class.id = classId;
        class.exists = true;
        class.symbol = symbol;
        class.interestRateType = interestRateType;
        class.tokenAddress = tokenAddress;
        class.periodTimestamp = periodTimestamp;

        // should maybe add an event
    }

    // TODO Only Governance
    function updateTokenAllowed (
        address tokenA,
        address tokenB,
        bool allowed
    ) external override {
        tokenAllowed[tokenA][tokenB] = allowed;
        tokenAllowed[tokenB][tokenA] = allowed;
    }

    function isPairAllowed (
        address _tokenA,
        address _tokenB) public view returns (bool) {
        (address tokenA, address tokenB) = sortTokens(_tokenA, _tokenB);
        return tokenAllowed[tokenA][tokenB];
    }

    function getClassFromId(
        uint classId
    ) external view returns(string memory symbol, InterestRateType interestRateType, address tokenAddress, uint periodTimestamp) {
        Class storage class = classes[classId];
        symbol = class.symbol;
        periodTimestamp = class.periodTimestamp;
        tokenAddress = class.tokenAddress;
        interestRateType = class.interestRateType;
        return (symbol, interestRateType, tokenAddress, periodTimestamp);
    }

    // TODO Only Bank
    function getLastNonceCreated(uint classId) external view returns(uint nonceId, uint createdAt) {
        Class storage class = classes[classId];
        require(class.exists, "Debond Data: class id given not found");
        nonceId = class.lastNonceIdCreated;
        createdAt = class.lastNonceIdCreatedTimestamp;
        return (nonceId, createdAt);
    }

    // TODO Only Bank
    function updateLastNonce(uint classId, uint nonceId, uint createdAt) external {
        Class storage class = classes[classId];
        require(class.exists, "Debond Data: class id given not found");
        class.lastNonceIdCreated = nonceId;
        class.lastNonceIdCreatedTimestamp = createdAt;
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'DebondLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'DebondLibrary: ZERO_ADDRESS');
    }





}
