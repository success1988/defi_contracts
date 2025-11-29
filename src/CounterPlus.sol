// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CounterPlus {
    uint256 public count;
    uint256 public maxCount;
    
    function increment() public {
        count++;
        if (count > maxCount) {
            maxCount = count;
        }
    }
    
    function decrement() public {
        require(count > 0, "Count must be positive");
        count--;
    }
    
    function reset() public {
        count = 0;
    }
}