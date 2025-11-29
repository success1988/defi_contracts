// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/CounterPlus.sol";

contract CounterHandler is Test {
    CounterPlus public counter;
    
    // Ghost variables for state tracking
    uint256 public expectedCount;
    uint256 public expectedMaxCount;
    
    constructor(CounterPlus _counter) {
        counter = _counter;
    }
    
    function increment() public {
        uint256 prevCount = counter.count();
        counter.increment();
        
        // Update expected state
        expectedCount = prevCount + 1;
        if (expectedCount > expectedMaxCount) {
            expectedMaxCount = expectedCount;
        }
    }
    
    function decrement() public {
        // Only decrement if count > 0
        if (counter.count() == 0) return;
        
        uint256 prevCount = counter.count();
        counter.decrement();
        
        // Update expected state
        expectedCount = prevCount - 1;
    }
    
    function reset() public {
        counter.reset();
        expectedCount = 0;
    }
}