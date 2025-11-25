// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import "./BaseScript.s.sol";
import {Counter} from "../src/Counter.sol";

contract CounterScript is BaseScript {
    Counter public counter;

    function run() public broadcaster {
        counter = new Counter();
        console.log("Counter deployed on %s", address(counter));

        saveContract("Counter", address(counter));
        // https://sepolia.etherscan.io/address/0xc976280d6fa3c6df2061c01bb5aa5f69ebc2725a
        counter.setNumber(99);
        counter.increment();
    }
}
