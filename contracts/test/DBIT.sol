pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/ISigmoidTokens.sol";


contract DBIT is ERC20, ISigmoidToken {

    address bankContractAddress;

    constructor() ERC20("D/BIT TOKEN", "DBIT") {

    }
}
