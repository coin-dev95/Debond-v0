pragma solidity ^0.8.0;



import "../Interfaces/ISigmoidTokens.sol";
import "./SafeMath.sol";
/**
functions for determining the amount of DBIT to be mint and pricing 
*/ 
library CDP {
 using SafeMath for uint256;

  function BondExchangeRate(uint256 dbitTotalSupply) public view returns (uint256 amount_bond) {
        if (dbitTotalSupply < 1e5) {
            amount_bond = 1 ether;
        } else {
            uint256 logTotalSupply = SafeMath.ln(dbitTotalSupply * 1e13);
            amount_bond = SafeMath.pow(1.05 * 1 ether, logTotalSupply);
        }
    } 

    function _amountOfDebondToMint(uint256 _dbitIn) internal view returns (uint256 amountDBIT) {
        // todo: mock token contract.
        uint256 dbitMaxSupply = 10000;
        uint256 dbitTotalSupply = 1000000;

        require(_dbitIn > 0, "SigmoidBank/NULL_VALUE");
        require(dbitTotalSupply.add(_dbitIn) <= dbitMaxSupply, "insufficient value");
        // amount of of DBIT to mint
        amountDBIT = _dbitIn * 10;
    }
    
//    function _dbitUSDPrice() internal  returns(uint256) {
//        return 100;
//    }
    
    
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'DebondLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'DebondLibrary: ZERO_ADDRESS');
    }
    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) { /// use uint?? int256???
        require(amountA > 0, 'DebondLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'DebondLibrary: INSUFFICIENT_LIQUIDITY');
        //amountB = amountA.mul(reserveB) / reserveA;
        amountB = SafeMath.div(amountA * reserveB, reserveA);

    }

}

