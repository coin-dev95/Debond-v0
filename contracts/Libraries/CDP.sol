pragma solidity ^0.8.0;

import "./Interfaces/ISigmoidTokens.sol";
import "./Interfaces/ISigmoidTokens.sol";
import "./PRBMathUD60x18.sol";
/**
functions for determining the price of 
*/ 
library CDP {
 using  PRBMathUD60x18 for uint256;

function BondExchangeRate(int256 dbitTotalSupply) public view returns (int256 amount_bond) {
        if (dbitTotalSupply < 1e5) {
            amount_bond = 1 ether;
        } else {
            int256 logTotalSupply = PRBMathSD59x18.ln(dbitTotalSupply * 1e13);
            amount_bond = PRBMathSD59x18.pow(1.05 * 1 ether, logTotalSupply);
        }
    } 


    function _amountOfDebondToMint(uint256 _dbitIn) internal pure returns (uint256 amountDBIT) {
        // todo: mock token contract.
        uint256 dbitMaxSupply = ISigmoidTokens(DBIT_contract).MaxSupply;
        uint256 dbitTotalSupply = ISigmoidTokens(DBIT_contract).totalSupply;

        require(_dbitIn > 0, "SigmoidBank/NULL_VALUE");
        require(dbitTotalSupply.add(_dbitIn) <= dbitMaxSupply, "insufficient value");
        // amount of of DBIT to mint
        amountDBIT = _dbitIn * _dbitUSDPrice();
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'DebondLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'DebondLibrary: ZERO_ADDRESS');
    }

    /*function getReserves(address tokenA, address tokenB) public view returns (uint112 reserveA, uint112 reserveB) {
        (address token0, address token1) = DebondLibrary.sortTokens(tokenA, tokenB);
        Pair pair = addressToPair[token0][token1];
        (uint reserve0, uint reserve1) = (pair.reserveTokenA, pair.reserveTokenB);
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

    }*/

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) { /// use uint?? int256???
        require(amountA > 0, 'DebondLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'DebondLibrary: INSUFFICIENT_LIQUIDITY');
        //amountB = amountA.mul(reserveB) / reserveA;
        amountB = PRBMathUD60x18.div( PRBMathUD60x18.mul(amountA,reserveB), reserveA);

    }



}
