// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auction {
    // State variables
    address public owner;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    address public highestBidder;
    uint256 public highestBindingBid;

    mapping(address => uint256) public bids;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyBeforeEnd() {
        require(block.timestamp < endTimestamp, "Auction has already ended");
        _;
    }

    modifier onlyAfterEnd() {
        require(block.timestamp >= endTimestamp, "Auction has not ended yet");
        _;
    }

    // Additional state variables
    uint256 public previousHighestBid;
    uint256 public numberOfBids;
    uint256 public increment;

    // Constructor
    constructor(uint256 minutesDuration) {
        owner = msg.sender;
        startTimestamp = block.timestamp;
        endTimestamp = startTimestamp + (minutesDuration * 1 minutes);
    }

    // Bid function
    function placeBid() external payable onlyBeforeEnd {
        require(msg.sender != owner, "Owner cannot bid.");
        require(msg.value > 0, "Bid amount must be greater than 0");
        require(msg.value >= highestBindingBid, "Bidding amount should be greater than previous bid");
        if (msg.value >= highestBindingBid || highestBindingBid == 0) {
            // Update highestBid and highestBidder
            previousHighestBid = highestBindingBid;
            highestBindingBid = msg.value;
            highestBidder = msg.sender;

            // Update bids mapping for the bidder
            bids[msg.sender] = msg.value;

            // Increment the number of bids
            numberOfBids++;
        }
    }

    // Finalize auction function
   function finalizeAuction() external onlyOwner onlyAfterEnd {
    require(highestBidder != address(0), "No bidders");


    // Calculate the maximum allowed increment
    uint256 maxIncrement = ((highestBindingBid - previousHighestBid) / 2);

    // Set the highestBindingBid with the random increment
   
    highestBindingBid = previousHighestBid + maxIncrement;

    // Transfer the highestBindingBid to the owner
    payable(owner).transfer(highestBindingBid);
}

    // Withdraw funds function
    function withdraw() external onlyAfterEnd {
        uint256 amount = bids[msg.sender];
        require(amount > 0, "No funds to withdraw");
        bids[msg.sender] = 0;

        if (msg.sender == highestBidder) {
            // Deduct the highestBindingBid from the withdrawal amount for the highest bidder
            amount = amount - highestBindingBid;
            require(amount >= 0, "Withdrawal amount cannot be negative");
        }

        // Transfer funds to the bidder
        payable(msg.sender).transfer(amount);
    }

    // Cancel auction function
    function cancelAuction() public onlyOwner onlyBeforeEnd {
        // End the auction prematurely
        endTimestamp = block.timestamp;
        
        // Reset auction state
        highestBidder = address(0);
        highestBindingBid = 0;
    }
}