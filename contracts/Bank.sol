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



import './APM.sol';
import './DebondData.sol';
import './interfaces/IERC20.sol';
import "./interfaces/IAPM.sol";
import "./interfaces/IData.sol";
import "./interfaces/IDebondBond.sol";
import "./interfaces/ISigmoidTokens.sol";
import "./libraries/CDP.sol";


contract Bank  {

    using CDP for uint256;

    IAPM apm;
    IData data;
    IDebondBond bond;
    enum PurchaseMethod {Buying, Staking}

    constructor(address apmAddress, address dataAddress, address bondAddress) {
        apm  = IAPM(apmAddress);
        data = IData(dataAddress);
        bond = IDebondBond(bondAddress);
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    // **** BUY BONDS ****

    function buyBond(
        uint purchaseTokenClassId, // token added
        uint debondTokenClassId, // token to mint
        uint purchaseTokenAmount,
        uint debondTokenMinAmount,
        PurchaseMethod purchaseMethod  //0 for stacking, 1 for buying
    ) external {

        uint _purchaseTokenClassId = purchaseTokenClassId;
        uint _debondTokenClassId = debondTokenClassId;
        (,,address purchaseTokenAddress,) = data.getClassFromId()(_purchaseTokenClassId);
        (,,address debondTokenAddress,) = data.getClassFromId(_debondTokenClassId);


        require(data.isPairAllowed(purchaseTokenAddress, debondTokenAddress));

        amountBToMint = calculateDebondTokenToMint(purchaseTokenAddress, debondTokenAddress, purchaseTokenAmount);


        //approval?
        IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), amountA);  //see uniswap : transferhelper,ierc202
        ISigmoidToken(debondTokenAddress).mint(address(apm), amountBToMint); // be aware that tokenB is a DebondToken, maybe add it to the class model

        //check tomorrow why it works while I don't have these tokens
        {
            //later : look if nounce exist: if not, create new one


            if (purchaseMethod == PurchaseMethod.Staking) {
                bond.issue(msg.sender, _purchaseTokenClassId, getNonce(_purchaseTokenClassId), amountA);
                bond.issue(msg.sender, _debondTokenClassId, getNonce(_debondTokenClassId), amountA * 50000000000000000); //we define interest at 5% for the period
            }
            else
                if (purchaseMethod == PurchaseMethod.Buying) {
                    (uint reserveA, uint reserveB) = apm.getReserves( purchaseTokenAddress, debondTokenAddress);
                    uint amount = CDP.quote(amountA, reserveA, reserveB);
                    bond.issue(msg.sender, 1, getNonce(_purchaseTokenClassId), amount + amount * 5 / 100);
                }
        }


        apm.updateRatioFactor(debondTokenAddress, purchaseTokenAddress, amountBToMint, purchaseTokenAmount); // mint of the bond, we do not precise class as we provide pair address
        // interest should be calculated and not directly put in param, because everyone can call this function


    }


    // TODO External to the Bank maybe
    function calculateDebondTokenToMint(
        address purchaseTokenAddress, // token added
        address debondTokenAddress, //token minted
        uint purchaseTokenAmount
    ) internal returns (uint amountB) {

        uint amountBOptimal = amountOfDBITToMint(purchaseTokenAmount);  //change this later
        amountB = amountBOptimal;

    }


    function amountOfDBITToMint(uint256 amountA) public pure returns(uint256 amountToMint) {
        return amountA;
    }

}
