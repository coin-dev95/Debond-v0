pragma solidity ^0.8.9;
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
import "./Interfaces/ISigmoidToken.sol";
import "@openzeppelin/contracts/utils/access/Ownable.sol"

/** currently implementing the DBIT token contract. */
contract SigmoidToken is AirdropToken, ISigmoidToken , OnlyOwner {
    uint256 private _maximumSupply;
    uint256 private _totalSupply;
    uint256 private _total_allocated;

    address private _bank_contract;

    bool private _contract_is_active;

    mapping(address => uint) private _locked;

    /**
     * @dev Sets the values for addresses
     */
    constructor(address bank_contract, string memory name, string memory symbol ,uint256 maximumSupply, uint256 totalSupply)  {
        _bank_contract = bank_contract;
        _contract_is_active = true;
        _total_allocated = 0;
        _maximumSupply = maximumSupply;
        _totalSupply = totalSupply;
        
    }

    modifier onlyIfActive() {
        require(_contract_is_active, "SigmoidAirdropToken: Contract is not active");
        _;
    }


    modifier onlyBank() {
        require(msg.sender == owner() || msg.sender == _bank_contract, "SigmoidAirdropToken: Not an owner or bank caller");
        _;
    }


    function setActiveState(bool newState) external onlyGovernance  returns(bool) {
        _contract_is_active = newState;
        return true;
    }

    function isActive() external view returns (bool) {
        return _contract_is_active;
    }
 
  

    function setBankContract(address bank_addres)
        public
        override
        onlyOwner
        returns (bool)
    {
        _bank_contract = bank_addres;
        return (true);
    }



    function setAllocatedSupply(uint256 total_allocated_supply)
        public
        onlyBank
        returns (bool)
    {
        _total_allocated = total_allocated_supply;
        return (true);
    }

    //read only functions
    function maximumSupply() public override view returns (uint256) {
        return (_maximumSupply);
    }

    function allocatedSupply() public override view returns (uint256) {
        return (_total_allocated);
    }


    //mint function can only be called from bank contract or governance contract, when the redemption of bonds or the claiming of allocation
    function mint(address _to, uint256 _amount) public onlyBank onlyIfActive returns (bool) {
        _mint(_to, _amount);
        return (true);
    }

    //mint allcation function can only be called from bank contract  allocation and airdrop do not count in total supply
    function mintAllocation(address _to, uint256 _amount)
        external
        override
        onlyBank onlyIfActive
        returns (bool)
    { 
         _mintAllocation(_to, _amount);

        return (true);
    }

    function _mintAllocation(address account, uint256 amount) private {
        _total_allocated += amount;
        _mint(account, amount);
    }
 

    //bank transfer can only be called by bank contract or exchange contract, bank transfer don't need the approval of the sender.
    function bankTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) public override onlyBank onlyIfActive returns (bool) { 
        require(_from != address(0), "SigmoidAirdropToken: transfer from the zero address");
        require(_to != address(0), "SigmoidAirdropToken: transfer to the zero address");
        _transfer(_from, _to, _amount);
        return (true);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from == address(0x0) || balanceOf(from) >= amount + _locked[from],
         "SigmoidAirdropToken: cannot transfer locked amount");
    }

   
}