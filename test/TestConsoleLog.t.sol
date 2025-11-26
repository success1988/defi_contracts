// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Test.sol";

contract TestConsoleLog is Test {
    address user1 = address(0x2);
    address user2  = address(0x3);

    function setUp() public {

    }


    function test_MaxParams() public view{
        uint amount = 220;
        string memory userName = "zhangsan";
        bool activeFlag = true;
        address userAddr = address(user1);
        bytes4 sel = bytes4(keccak256("getCallData(address,uint256)"));

        console.log("This is a four-parameter log:[uint] %s, [string] %s, [bool] %s", amount, userName, activeFlag);
        console.logUint(amount);
        console.logBool(activeFlag);
        console.logString(userName);
        console.logAddress(userAddr);
        console.logBytes4(sel);
    }

}