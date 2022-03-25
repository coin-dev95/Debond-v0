pragma solidity ^0.8.9;

import "./IERC20.sol";

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

interface ISigmoidToken is IERC20 {
    function isActive() external view returns (bool);

    function maximumSupply() external view returns (uint256);

    function allocatedSupply() external view returns (uint256);

    function setBankContract(address bank_address) external returns (bool);

    function mintAllocation(address _to, uint256 _amount)
        external
        returns (bool);
 
    function bankTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);


}
