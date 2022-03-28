pragma solidity 0.8.13;


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

import "./IERC3475.sol";




interface IDebondBond is IERC3475 {

    enum InterestRateType { FixedRate, FloatingRate }

    function createNonce(uint256 classId, uint256 nonceId, uint256 maturityTime, uint256 liqT) external;

    function createClass(uint256 classId, string memory symbol, InterestRateType interestRateType, address tokenAddress, uint256 periodTimestamp) external;

    function classExists(uint256 classId) external returns (bool);

    function nonceExists(uint256 classId, uint256 nonceId) external returns (bool);

    function isActive() external returns (bool);


}

