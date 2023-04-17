// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "amm-core/test/__fixtures/BaseTest.sol";

import { ReservoirDeployer2 } from "src/ReservoirDeployer2.sol";
import { ReservoirRouter } from "src/ReservoirRouter.sol";

contract ReservoirDeployerTest is BaseTest {
    ReservoirDeployer2 private _deployer2 = new ReservoirDeployer2(
        address(1),
        address(2),
        address(3)
    );

    function setUp() public {

    }

    function testDeployRouter() external {
        // arrange


        // act
        _deployer2.deployRouter(type(ReservoirRouter).creationCode, address(1));

        // assert

    }
}
