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

import './interfaces/IAPM.sol';
import './interfaces/IERC20.sol';
import "../Interfaces/IAPM.sol";
import "../Libraries/CDP.sol";


contract APM2 is IAPM { //is IAPM

    using CDP for uint256;

    uint public constant MINIMUM_LIQUIDITY = 10**3; //To avoid cases of division by zero,
    // there is a minimum number of liquidity tokens that always exist (but are owned by account zero)
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    // This is the ABI selector for the ERC-20 transfer function.
    //It is used to transfer ERC-20 tokens in the two token accounts.


    /*address public token0;
    address public token1;
    address public DBITAddress;
    // here : do a list of addresses of all the tokens in the pair (n-uplet) */ // this is in data.sol now

    struct Pair {
        address tokenA;
        address tokenB;
        uint112 reserveTokenA;
        uint112 reserveTokenB;
        uint112 ratio; //to use later
        uint kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event //public?
    }

    mapping( address => mapping( address => Pair) ) addressesToPair;  //less gas here

    mapping( address => uint256) totalBalances;

    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves
    //The timestamp for the last block in which an exchange occurred, used to track exchange rates across time.


    uint private unlocked = 1; //security details (see reentrancy abuse)

    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves(address tokenA, address tokenB) public view returns (uint112 reserveA, uint112 reserveB) {
        (address token0, address token1) = DebondLibrary.sortTokens(tokenA, tokenB);
        Pair storage pair = addressesToPair[token0][token1];
        (uint112 reserve0, uint112 reserve1) = (pair.reserveTokenA, pair.reserveTokenB);
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
        //To avoid having to import an interface for the token function, we "manually" create the call using one of the ABI functions.
    }

    //event addLiq(address indexed sender, uint amount0, uint amount1);
    //event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);



    function _update(uint balanceA, uint balanceB, address tokenA, address tokenB) private {
        //require(balanceA <= uint256(-1) && balanceB <= uint256(-1), 'UniswapV2: OVERFLOW'); check this !!!

        (address token0, address token1) = CDP.sortTokens(tokenA, tokenB);
        Pair storage pair = addressesToPair[token0][token1]; //storage?
        (pair.reserveTokenA, pair.reserveTokenB) = tokenA == token0 ? (uint112(balanceA), uint112(balanceB)) : (uint112(balanceB), uint112(balanceA));
        totalBalances[tokenA] = totalBalances[tokenA] + balanceA;
        totalBalances[tokenB] = totalBalances[tokenB] + balanceB;   //check this





        //emit Sync(pair.reserveTokenA, pair.reserveTokenB);
    }



    /*function rate(uint amount, uint interest ) public pure returns(uint result){
        uint swaping = amount * interest; //needs the correct mul function
        result = reserveDbit/(reserveTokenA+swaping); // needs correct div function. Check reserveTokenA, if it can be renamed.
    }*/

    // this low-level function should be called from a contract which performs important safety checks
    function addLiquidity(
    //address to    verify we do not need this
        address tokenA,
        address tokenB
    //uint choice,
    //uint nounce,
    //uint interest
    )
    external lock  { //returns (uint liquidity)
        // rate : how much interest you earn in fixed term 0 coupon.
        (uint112 _reserve0, uint112 _reserve1) = getReserves(tokenA, tokenB);

        (uint reserve0Total, uint reserve1Total) = (totalBalances[tokenA], totalBalances[tokenB]);

        uint balance0Total = IERC20(tokenA).balanceOf(address(this));
        uint balance1Total = IERC20(tokenB).balanceOf(address(this));


        uint amount0 = balance0Total - reserve0Total; //verify math
        uint amount1 = balance1Total - reserve1Total;



        //uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        /*if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount0)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else if {
            liquidity = amount0.mul(_totalSupply) / _reserve0;
        }   // take care later
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');  */

        // mint is not here but in bank

        _update(_reserve0 + amount0, _reserve1 + amount1, tokenA, tokenB);
        //emit Mint(msg.sender, amount0, amount1);
    }




    /*

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to, uint amount) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, ) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        //address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        //uint balance1 = IERC20(_token1).balanceOf(address(this));
        //uint liquidity = balanceOf[address(this)]; amount replaces this

        bool feeOn = _mintFee(_reserve0, _reserve1);
        //uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        //amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        //amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        //require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        //[address] bonds = IERC3475().getBonds(msg.sender) ;
        if(bond.amount<balance0){
            redeem(address(this),bond.class, bond.nounce , amount); // maybe put _nounce=bond.nounce to save gas
            _safeTransfer(_token0, to, amount);

        }
        else {
            redeem(address(this),bond.class, bond.nounce , bond.amount-balance0); // maybe put _nounce=bond.nounce to save gas
            _safeTransfer(_token0, to, bond.amount-balance0);

        }

        //what to do with dbit? burn? on burn exactement ce qu'on a mint en nb de token

        balance0 = IERC20(_token0).balanceOf(address(this));


        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    */
}
