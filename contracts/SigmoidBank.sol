pragma solidity ^0.8.9;
// SPDX-License-Identifier: apache 2.0

/// @title sigmoid bank v1
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/address.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Interfaces/IERC3475.sol";
// for the interface with DBIT and vote tokens (after staking the  bond tokens).
import "./Interfaces/ISigmoidTokens.sol";

import "./Interfaces/IAPM.sol";

import "./libraries/CDP.sol";
// handling the function of the pair contract

import "github.com/Debond-Protocol/Math-Operations/blob/main/PRBMathUD59x18.sol";
import "github.com/Debond-Protocol/Math-Operations/blob/main/PRBMath.sol";


contract SigmoidBank is Ownable {


    using PRBMathSD59x18 for uint256;
    using Address for address;

    // for the core contracts
    address public DBIT_contract;
    address public apm_address;

    //determines the version of contract
    uint256 public _phase;

    //ERC20 token address (DBIT).
    address DBIT_address;

    // external adapters for trade pairs and finding the price
    IDebondRouter adapter;
    IAPM pool;
    ISigmoidTokens dbitToken;

    bool contract_status;
    // events
    event BondCreated(uint256 classId, uint256 proposalId, string name);
    event BondRedeemed(address issuer, uint256 timestamp, uint256 amountOfDBITIssued);

    // stores the pairing  of the given bond and whitelisted stablecoins (ex dbgt-* and dbit-* pairs)
    // used for tracking the minting of the corresponding pairs of bonds in the router contract.

    struct TokenPairList {
        address[] tokenAddress;
        uint256 numberOfTokens;
    }
    //mapping for the  specified bond class  with the pairs corresponding to the bond
    // by standard 0: DBIT

    // 1: DBGT
    mapping(uint256 => TokenPairList) public tokenPairLists;
    mapping(uint => mapping(address => bool)) isWhitelisted;

    // mapping between classId => Bondparameters.
    // tcond interest is set based on the given ClassId
    mapping(uint256 => BondParameters) _bondInterest;

    struct BondParameters {
        uint256 interest_rate;
    }


    /*
@param bondToken_contract : address array corresponding the addresses  
*/
    constructor(
        address[] memory bondToken_contract,
        address[] memory _tokenList,
        address apm_address,
        address dbitToken
    ) public Ownable() {
        DBIT_contract = bondToken_contract[0];
        governance_contract = governance_address;
        // WhiteListing
        for (uint j = 0; j < bondToken_contract.length; j++) {
            for (uint i = 0; i < _tokenList.length; i++) {
                // adding token  from tokenlist
                tokenPairLists[j].tokenAddress[i] = _tokenList[i];
                tokenPairLists[j].numberOfTokens = ListToken(_tokenList[i], j);
            }
        
        }
        //   interface contracts for pair creation and operations with bond
        apm = IAPM(debondRouterAddress);
        pair = IPairContract(debondPairAddress);

        contract_status = true;
        setBondContract(DBIT_contract);
        setGovernanceContract(governance_contract);
    }

    function setGovernanceContract(address _governanceContract) public override OnlyGov returns (bool) {
        governance_contract = _governanceContract;
        return (true);
    }

    function isActive() public view returns (bool) {
        return contract_status;
    }

    modifier OnlyOwner() {
        require(msg.sender == owner(), "access denied");
        _;
    }

    // getter functions
    /* token listed : _BondIndex is the index of whitelisted tokens currently for the given bond type.
choice : these are the nomenclature of  type of bond (0 for DBIT for 1 and DBGT)
*/

    // TODO:   we dont have to address
    function isTokenListed(address _address, uint256 _bondIndex) public view returns (bool listed) {
        address[] memory addresses = fetchAllTokenListed(_bondIndex);
        for (uint256 i = 0; i < tokenPairLists[_bondIndex].numberOfTokens; i++) {
            if (addresses[i] == _address) listed = true;
        }
    }

    function fetchAllTokenListed(uint256 _bondIndex) public view returns (address[] memory) {
        return tokenPairLists[_bondIndex].tokenAddress;
    }

    /* token listed : _BondIndex is the index of whitelisted tokens currently for the given bond type. */

    function ListToken(address _token, uint256 bondIndex) public OnlyGov returns (uint256 _coinIndex) {
        //  Check  whether  given token is ERC20 compliant
        require(Address.isContract(_token), "cant-be-EOA");

        // then verifying whether the address is already not listed .
        address[] memory listedTokens = fetchAllTokenListed(bondIndex);

        for (uint256 i = 0; i < listedTokens.length; i++) {
            if (listedTokens[i] == _token) _coinIndex = uint256(i);
            return _coinIndex;
        }
        tokenPairLists[bondIndex].tokenAddress.push(_token);

        // since 0 index
        _coinIndex = tokenPairLists[bondIndex].numberOfTokens;
        tokenPairLists[bondIndex].numberOfTokens = SafeMath.add(tokenPairLists[bondIndex].numberOfTokens, 1);

        return _coinIndex;
    }

    function setPhase(uint256 _Newphase) public OnlyGov returns (bool) {
        require(_Newphase == _phase + 1);
        _phase = _Newphase;
        return (true);
    }

    // define the  interest rate for the given class , proposalId
    function setBondInterest(
        uint256 classId,
        uint256 proposalId,
        uint256 _interest_rate
    ) public OnlyGov {
        _bondInterest[classId][proposalId].interest_rate = _interest_rate;
    }

    function transferOwnershipBank(address newOwner) public virtual OnlyGov {
        _transferOwnership(newOwner);
    }

    // setting the  parameters  on contracts
    function setBondContract(address bond_address) public OnlyOwner returns (bool) {
        DBIT_contract = bond_address;
        return (true);
    }

    function setTokenContract(address contract_address) public OnlyOwner returns (bool) {
            DBIT_Address = contract_address;
        return (true);
    }

    function setNewApmAddress(address new_apm_address) public OnlyGov returns (bool) {
        apm_address = new_apm_address;
    }

    // does the swapping  during the redeeming phase (excpet for ethereum)
  
  
    function redeemBond(
        address _from,
        uint256 _classId,
        uint256 _nonceId,
        uint256 _amount,
        address tokenBond,
        address listToken,
        uint256 deadline
    ) public inTime(deadline) {
        require(isActive());
        /* redemption process:  */
        require(isTokenListed(listToken, _classId) == true, "SigmoidBank/Token_not_whitelisted");
       
        IDebondBond(bond_contract).redeem(_from, _classId, _nonceId, _amount);
        // then removing the  liquidity corresponding to the pair via the method from router
        uint256 LiqPair = removeLiquidity(DBIT_address, _amount, _from, 10)[0];
        //now   removing the liquidity of the bond tokens from the bond structure also.

        // then trying to remove the liquidity from the pool from ERC3475 contract.
        require(IERC3475(DBGT_contract).redeem(_from, _classId, _nonceId, LiqPair), "bonds are not redeemable for now");

        // TODO: this is to discurse the interest and the final face value.

        
        IERC20(listToken).safeTransferOf(LiqPair, router_address, _from);

        emit BondRedeemed(_from, block.timestamp, LiqPair);
    }



    function _addLiquidityForOneSide(
        uint256 _bondIndex,
        address _token,
        address _amountToken,
        uint256 _amountDBIT
    ) internal view returns (uint256 amountToken, uint256 amountDBIT) {
        require(isTokenListed(_token, _bondIndex), "TKN_NOT_LISTED");

        uint256 erc20DBIT = pair.amountOfDebondToMint(_amountDBIT);

        (amountToken, amountDBIT) = (_amountToken, erc20DBIT);
    }

        function CreationOfNonce(
        uint256 timestamp_init,
        uint256 classId,
        uint256 intervals
    ) public override onlyBond returns (uint256) {
        // finding the elapsed days since the creation of the contract.
        uint256 timeElapsed = SafeMath.sub(block.timestamp - timestamp_init) / SafeMath.div(3600 * 24);
        uint256 nonce = SafeMath.mod(timeElapsed / intervals);
        return (nonce);
    }


    function buyBond(
        uint256 _BondIndex,
        address _token,
        uint256 _amountToken,
        uint256 _amountDBIT,
        uint256 _classIdDBIT,
        uint256 _classIdToken,
        address _to,
        uint256 deadline
    ) external inTime(deadline) returns (uint256 amountToken, uint256 amountDBIT) {
        require(_to != address(0), "ERR_ZERO_ADDRESS");
        // condition for checking whether bonds is approved by the bank

        (amountToken, amountDBIT) = _addLiquidityForOneSide(_BondIndex, _token, _amountToken, _amountDBIT);

        // update the ratio factor
        _updateRatioFactor(_token, DBIT_address, amountToken, amountDBIT);

        // update the price
        _updatePrice(_token, DBIT_address);

        
        uint256 timestamp_tokens = block.timestamp;

       
        // and finally issuance of the bonds corresponding to the amount of  whitelisted collateral  to be transfered.
        IDebondBond(DBIT_contract).issue(
            _to,
            _classIdDBIT,
            CreationOfNonce(timestamp_tokens, _classIdDBIT, 9999),
            amountDBIT
        );
        IDebondBond(DBIT_contract).issue(
            _to,
            _classIdToken,
            CreationOfNonce(timestamp_tokens, _classIdToken, 9999),
            amountToken
        );


    // now minting the  tokens and calling the transfer function from the bank contract : 

        ISigmoidTokens()

    ISigmoidTokens()


     ISigmoidTokens(_token).transferFrom(msg.sender, address(this), amountToken);

        // and now issuing the bonds  across the  corresponding classes . also generating the nonces from the experimental  mod function
        // for now taking an demo condition for intervals being for the whole year , but there can be an specific value

        ISigmoidTokens(DBIT_address).transferFrom()



        return (amountToken, amountDBIT);


        
    }

     function _updateRatioFactor(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) internal returns (uint256 ratio01, uint256 ratio10) {
        uint256[2] memory _ratio01 = ratio[token0][token1]; // gas savings
        uint256[2] memory _ratio10 = ratio[token1][token0]; // gas savings
        uint256 _reserve0 = reserve[token0][1];
        uint256 _reserve1 = reserve[token1][1];

        reserve[token0][0] = _reserve0;
        reserve[token1][0] = _reserve1;

        uint256 numerator0 = (_ratio01[0].mul(_reserve0)).add(amount1.mul(1 ether));
        uint256 numerator1 = (_ratio10[0].mul(_reserve1)).add(amount1.mul(1 ether));

        ratio[token0][token1][1] = numerator0.div(_reserve0.add(amount0));
        ratio[token1][token0][1] = numerator1.div(_reserve1.add(amount1));

        reserve[token0][1] = _reserve0.add(amount0);
        reserve[token1][1] = _reserve1.add(amount1);

        return (ratio[token0][token1][1], ratio[token1][token0][1]);
    }

    function _updatePrice(address token0, address token1) internal returns (uint256 price0, uint256 price1) {
        uint256[2] memory _ratio01 = ratio[token0][token1]; // gas savings
        uint256[2] memory _ratio10 = ratio[token1][token0]; // gas savings
        uint256 _previousReserve0 = reserve[token0][0];
        uint256 _previousReserve1 = reserve[token1][0];
        uint256 _reserve0 = reserve[token0][1];
        uint256 _reserve1 = reserve[token1][1];

        uint256 denominator0 = (_ratio01[0].div(1 ether)).mul(_previousReserve0).add(
            reserve[token0][1].sub(reserve[token0][0])
        );
        uint256 denominator1 = (_ratio10[0].div(1 ether)).mul(_previousReserve1).add(
            reserve[token1][1].sub(reserve[token1][0])
        );

        price0 = _ratio10[1].mul(_reserve0).div(denominator0);
        price1 = _ratio01[1].mul(_reserve1).div(denominator1);
    }


}