pragma solidity ^0.8.0;

import "github.com/Debond-Protocol/Math-Operations/blob/main/PRBMathUD59x18.sol";
import "./Interfaces/ISigmoidTokens.sol";
/** 
functions for determining the price of 
*/ 
library CDP {
 using  PRBMathSD59x18 for uint256;

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



}