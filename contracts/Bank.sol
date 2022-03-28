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



import './APM.sol';
import './DebondData.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAPM.sol";
import "./interfaces/IData.sol";
import "./interfaces/IDebondBond.sol";
import "./interfaces/IDebondToken.sol";
import "./libraries/CDP.sol";


contract Bank {

    using CDP for uint256;

    IAPM apm;
    IData debondData;
    IDebondBond bond;
    enum PurchaseMethod {Buying, Staking}
    uint public constant BASE_TIMESTAMP = 1646089200; // 2022-03-01 00:00
    uint public constant DIFF_TIME_NEW_NONCE = 24 * 3600; // every 24h we crate a new nonce.
    uint public constant RATE = 5; // every 24h we crate a new nonce.

    constructor(address apmAddress, address dataAddress, address bondAddress) {
        apm = IAPM(apmAddress);
        debondData = IData(dataAddress);
        bond = IDebondBond(bondAddress);
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    // **** BUY BONDS ****

    function buyBond(
        uint _purchaseTokenClassId, // token added
        uint _debondTokenClassId, // token to mint
        uint _purchaseTokenAmount,
        uint _debondTokenMinAmount,
        PurchaseMethod purchaseMethod
    ) external {

        uint purchaseTokenClassId = _purchaseTokenClassId;
        uint debondTokenClassId = _debondTokenClassId;
        uint purchaseTokenAmount = _purchaseTokenAmount;
        uint debondTokenMinAmount = _debondTokenMinAmount;
        uint nowTimestamp = block.timestamp;
        (,,address purchaseTokenAddress,) = debondData.getClassFromId(purchaseTokenClassId);
        (,,address debondTokenAddress,) = debondData.getClassFromId(debondTokenClassId);


        require(debondData.isPairAllowed(purchaseTokenAddress, debondTokenAddress));

        uint amountBToMint = calculateDebondTokenToMint(
//            purchaseTokenAddress,
//            debondTokenAddress,
            purchaseTokenAmount
        );

        require(debondTokenMinAmount <= amountBToMint, "Not enough debond token in minting calculation");


        IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
        //see uniswap : transferhelper,ierc202
        IDebondToken(debondTokenAddress).mint(address(apm), amountBToMint);
        // be aware that tokenB is a DebondToken, maybe add it to the class model


        if (purchaseMethod == PurchaseMethod.Staking) {
            bond.issue(msg.sender, purchaseTokenClassId, manageAndGetNonceId(purchaseTokenClassId, nowTimestamp), purchaseTokenAmount);
            bond.issue(msg.sender, debondTokenClassId, manageAndGetNonceId(debondTokenClassId, nowTimestamp), amountBToMint * RATE / 100);
            //we define interest at 5% for the period
        }
        else
            if (purchaseMethod == PurchaseMethod.Buying) {
                (uint reserveA, uint reserveB) = apm.getReserves(purchaseTokenAddress, debondTokenAddress);
                uint amount = CDP.quote(purchaseTokenAmount, reserveA, reserveB);
                bond.issue(msg.sender, debondTokenClassId, manageAndGetNonceId(purchaseTokenClassId, nowTimestamp), amount + amount * RATE / 100); // here the interest calculation is hardcoded
            }


//        apm.updateRatioFactor(debondTokenAddress, purchaseTokenAddress, amountBToMint, purchaseTokenAmount);


    }


    // TODO External to the Bank maybe
    function calculateDebondTokenToMint(
//        address purchaseTokenAddress, // token added
//        address debondTokenAddress, //token minted
        uint purchaseTokenAmount
    ) internal pure returns (uint amountB) {

        uint amountBOptimal = amountOfDBITToMint(purchaseTokenAmount);
        //change this later
        amountB = amountBOptimal;

    }


    function amountOfDBITToMint(uint256 amountA) public pure returns (uint256 amountToMint) {
        return amountA;
    }

    function manageAndGetNonceId(uint classId, uint timestampToCheck) private returns (uint) {
        (uint lastNonceId, uint createdAt) = debondData.getLastNonceCreated(classId);
        if ((timestampToCheck - createdAt) >= DIFF_TIME_NEW_NONCE) {
            return createNewNonce(classId, lastNonceId, timestampToCheck);
        }

        uint tDay = (timestampToCheck - BASE_TIMESTAMP) % DIFF_TIME_NEW_NONCE;
        if ((tDay + (timestampToCheck - createdAt)) >= DIFF_TIME_NEW_NONCE) {
            return createNewNonce(classId, lastNonceId, timestampToCheck);
        }

        return lastNonceId;
    }

    function createNewNonce(uint classId, uint lastNonceId, uint creationTimestamp) private returns (uint _newNonceId) {
        _newNonceId = lastNonceId++;
        debondData.updateLastNonce(classId, _newNonceId, creationTimestamp);
        (,,, uint period) = debondData.getClassFromId(classId);
        bond.createNonce(classId, _newNonceId, creationTimestamp + period, 500);
        //here 500 is liquidity info hard coded for now
        return _newNonceId;
    }

}
