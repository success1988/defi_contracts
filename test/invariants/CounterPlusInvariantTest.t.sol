// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/CounterPlus.sol";
import "./CounterPlusHandler.sol";

contract CounterInvariantTest is Test {
    CounterPlus public counter;
    CounterHandler public handler;
    
    function setUp() public {
        counter = new CounterPlus();
        handler = new CounterHandler(counter);
        
        // Target the handler, not the original contract
        targetContract(address(handler));
    }
    
    function invariant_count_consistency() public view {
        assert(counter.count() <= counter.maxCount());
    }
    
    function invariant_ghost_variables_match() public view {
        // Verify that our handler's expected state matches actual state
        assert(handler.expectedCount() == counter.count());
        assert(handler.expectedMaxCount() == counter.maxCount());
    }
}