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
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IAPM.sol";
import "./interfaces/IData.sol";
import "./interfaces/IDebondBond.sol";
import "./interfaces/IDebondToken.sol";
import "./libraries/CDP.sol";


contract Bank {

    using CDP for uint256;
    using SafeERC20 for IERC20;

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
        (,,address purchaseTokenAddress,) = debondData.getClassFromId(purchaseTokenClassId);
        (,,address debondTokenAddress,) = debondData.getClassFromId(debondTokenClassId);


        require(debondData.isPairAllowed(purchaseTokenAddress, debondTokenAddress), "Pair not Allowed");

        uint amountBToMint = calculateDebondTokenToMint(
//            purchaseTokenAddress,
//            debondTokenAddress,
            purchaseTokenAmount
        );

//        require(debondTokenMinAmount <= amountBToMint, "Not enough debond token in minting calculation");


        IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
        //see uniswap : transferhelper,ierc202
        IDebondToken(debondTokenAddress).mint(address(apm), amountBToMint);
        // be aware that tokenB is a DebondToken, maybe add it to the class model


        if (purchaseMethod == PurchaseMethod.Staking) {
            issueBonds(msg.sender, purchaseTokenClassId, purchaseTokenAmount);
            (uint reserveA, uint reserveB) = (apm.getReserve(purchaseTokenAddress), apm.getReserve(debondTokenAddress));
            uint amount = CDP.quote(purchaseTokenAmount, reserveA, reserveB);
            issueBonds(msg.sender, debondTokenClassId, amount * RATE / 100);
            //msg.sender or to??
        }
        else
            if (purchaseMethod == PurchaseMethod.Buying) {
                (uint reserveA, uint reserveB) = (apm.getReserve(purchaseTokenAddress), apm.getReserve(debondTokenAddress));
                uint amount = CDP.quote(purchaseTokenAmount, reserveA, reserveB);
                issueBonds(msg.sender, debondTokenClassId, amount + amount * RATE / 100); // here the interest calculation is hardcoded
            }

            apm.updaReserveAfterAddingLiquidity(debondTokenAddress, amountBToMint);
            apm.updaReserveAfterAddingLiquidity(purchaseTokenAddress, purchaseTokenAmount);
            apm.updateRatioAfterAddingLiquidity(debondTokenAddress, purchaseTokenAddress, amountBToMint, purchaseTokenAmount);


    }

    // **** SELL BONDS ****

    function sellBonds(
        uint _TokenClassId,
        uint _TokenNonceId,
        uint amount
        //uint amountMin?
    ) external {
        IDebondBond(address(bond)).redeem(msg.sender, _TokenClassId,  _TokenNonceId, amount);
	    //require(redeemable) is already done in redeem function for liquidity, but still has to be done for time redemption

        (, IData.InterestRateType interestRateType ,address TokenAddress,) = debondData.getClassFromId(_TokenClassId);
        //require(reserves[TokenAddress]>amountIn);

        if(interestRateType == IData.InterestRateType.FixedRate) {
            IERC20(TokenAddress).transferFrom(address(apm), msg.sender, amount);


        }
        else if (interestRateType == IData.InterestRateType.FloatingRate){
            //to be implemented later
        }



	    
        //how do we know if we have to burn (or put in reserves) dbit or dbgt?


	    //APM.removeLiquidity(tokenAddress, amountIn);
//        apm.updaReserveAfterRemovingLiquidity(tokenAddress, amountIn);
        //emit

    }

    // **** Swaps ****







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

    function issueBonds(address to, uint256 classId, uint256 amount) private {
        manageNonceId(classId);
        (uint nonceId,) = debondData.getLastNonceCreated(classId);
        bond.issue(to, classId, nonceId, amount);
    }

    function manageNonceId(uint classId) private {
        uint timestampToCheck = block.timestamp;
        (uint lastNonceId, uint createdAt) = debondData.getLastNonceCreated(classId);
        if ((timestampToCheck - createdAt) >= DIFF_TIME_NEW_NONCE) {
            createNewNonce(classId, lastNonceId, timestampToCheck);
            return;
        }

        uint tDay = (timestampToCheck - BASE_TIMESTAMP) % DIFF_TIME_NEW_NONCE;
        if ((tDay + (timestampToCheck - createdAt)) >= DIFF_TIME_NEW_NONCE) {
            createNewNonce(classId, lastNonceId, timestampToCheck);
            return;
        }
    }

    function createNewNonce(uint classId, uint lastNonceId, uint creationTimestamp) private {
        uint _newNonceId = lastNonceId++;
        (,,, uint period) = debondData.getClassFromId(classId);
        bond.createNonce(classId, _newNonceId, creationTimestamp + period, 500);
        debondData.updateLastNonce(classId, _newNonceId, creationTimestamp);
        //here 500 is liquidity info hard coded for now
    }

}
