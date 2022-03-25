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
import './libraries/DebondLibrary.sol';
import './Data.sol';
import './ERC3475.sol';
import '../Interfaces/IERC20.sol';
import './ERC20.sol';
import "../Interfaces/IAPM.sol";
import "../Interfaces/IData.sol";
import "../Interfaces/IDebondBond.sol";
import "../Interfaces/ISigmoidTokens.sol";
import "../Libraries/CDP.sol";


contract Bank  {  //is IBank  remove data here and do functions  , IAPM

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
        uint classIdA, // token added
        uint classIdB, // token to mint
        uint amountADesired,
        uint amountMinBond,
        address to, //maybe not necessary
    //uint deadline, //let a default value 20 min as pancakeswap
        PurchaseMethod purchaseMethod  //0 for stacking, 1 for buying

    //uint nounce,  verify format here : [ (time1, %1), (time 2, %2), etc...]
    // faire [uint] nounce (time) et [uint] interets et vérifier que les tailles sont égales
    //uint interest // should be a function
    ) public  /*override ensure(deadline)*/ returns (uint amountA, uint amountBToMint, address) {

        (uint periodA, address tokentoAdd, ) = data.classIdToInfos(classIdA);
        (uint periodB, address tokenToMint, ) = data.classIdToInfos(classIdB); // see if we need all the param, or only need in certain choice


        require(data.isPairAllowed(tokentoAdd, tokenToMint));

        amountBToMint = _calculateAmountToMint(tokentoAdd, tokenToMint, amountADesired);


        //approval?
        IERC20(tokentoAdd).transferFrom(msg.sender, address(apm), amountA);  //see uniswap : transferhelper,ierc202
        ISigmoidToken(tokenToMint).mint(address(apm), amountBToMint); // be aware that tokenB is a DebondToken, maybe add it to the class model

        //check tomorrow why it works while I don't have these tokens

        uint nonceA = getNonce(classIdA);
        uint nonceB = getNonce(classIdB);
        //later : look if nounce exist: if not, create new one


        if (purchaseMethod == PurchaseMethod.Staking) {
            bond.issue(to, classIdA, nonceA, amountA);
            bond.issue(to, classIdB, nonceB, amountA * 50000000000000000); //we define interest at 5% for the period
        }
        else
            if (purchaseMethod == PurchaseMethod.Buying) {
            (uint reserveA, uint reserveB) = apm.getReserves( tokentoAdd, tokenToMint);
            uint amount = CDP.quote(amountA, reserveA, reserveB);
            bond.issue(to, 1, nonceA, amount *(1 + (5 / 100)));
        }

        apm.addLiquidity(tokentoAdd, tokenToMint); // mint of the bond, we do not precise class as we provide pair address
        // interest should be calculated and not directly put in param, because everyone can call this function


        return (amountA, amountBToMint, tokentoAdd);


    }

    function balancebond (address account, uint256 classId, uint256 nonceId) public view returns (uint256) {
        return bond.balanceOf(account, classId, nonceId);
    }

    function testSend (address tokenA, uint amountA) public{
        IERC20(tokenA).transferFrom(msg.sender, address(apm), amountA);
    }


    function _calculateAmountToMint(
        address tokenA, // token added
        address tokenB, //token minted
        uint amountADesired
    //uint amountBMin  // a verifier, minbond
    ) public virtual returns (uint amountB) {


        //(uint reserveA, uint reserveB) = apm.getReserves( tokenA, tokenB);


        uint amountBOptimal = amountOfDBITToMint(amountADesired);  //change this later
        //should calculate how much debit should be minted,
        //maybe should be added in core contracts and not in debond router

        //require(amountBOptimal >= amountBMin, 'UniswapV2Router: formula of dbit minting changed too fast');
        amountB = amountBOptimal;

    }


    function amountOfDBITToMint(uint256 amountA) public pure returns(uint256 amountToMint) {
        /*
        uint256 dbitMaxSupply = 10000000;
        uint256 dbitTotalSupply = 1000000;
        //===

        require(amountA > 0, "Amount of DBIT");
        require(dbitTotalSupply.add(amountA) <= dbitMaxSupply, "Not enough DBIT remins to buy");

        // amount of of DBIT to mint
        uint amountDBIT = amountA ; */   //pseudo code here
        return amountA;
    }




    function getNonce(/*blocktimestamp, */ uint classid  /*, address tokenB check later if needed*/ ) public returns(uint)  {

        //if jour = i: nonce=i // pseudo code
        return classid+1;
    }


    /*function balancetoken (address account) public view returns(uint){
        IERC20()
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }*/



    /*
        // **** REMOVE LIQUIDITY ****

        //add step here : verify if the bond is reedemable.
        //when we redeem, we are not sure if we burn dbit or not
        function removeLiquidity(
            address tokenA, //we have the address of the bond, and we will then see how much of bonds you have
            //address tokenDbit,
            //uint liquidity,
            //uint amountA,
            uint amountAMin, // amount of bond we want to redeem (could be amount/2, or else...)
            //uint amountBMin,
            address to,
            uint deadline
            //should have a param to know if flexible rate or fix rate, so we now if there is priority to redeem.
        ) public virtual  ensure(deadline) returns (uint amountA, uint amountB) { //override
            address pair = DebondLibrary.pairFor(factory, BondA, tokenDbit);
            DebondPair(pair).transferFrom(msg.sender, pair, amountAMin); // send liquidity to pair
            (uint amount0, uint amount1) = IDebondPair(pair).burn(to , amountAMin);


            //amount0=token0, amount1 = tokendbit, interest
            (address token0,) = DebondLibrary.sortTokens(tokenA, tokenB);
            (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
            //require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');  We do not need that : bond can be lower than expected.
            //require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
        }

        // **** SWAP ****
        // requires the initial amount to have already been sent to the first pair
        function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
            for (uint i; i < path.length - 1; i++) {
                (address input, address output) = (path[i], path[i + 1]);
                (address token0,) = UniswapV2Library.sortTokens(input, output);
                uint amountOut = amounts[i + 1];
                (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
                address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
                IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                    amount0Out, amount1Out, to, new bytes(0)
                );
            }
        }



        // **** LIBRARY FUNCTIONS ****
        function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual  returns (uint amountB) { //override
            return UniswapV2Library.quote(amountA, reserveA, reserveB);
        }
    */

}
