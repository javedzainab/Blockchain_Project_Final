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
  // Add a state variable to store addresses with the same value
// Add a state variable to store addresses with the same value
address[] private addressesWithSameValueArray;

// Update the placeBid function
function placeBid() external payable onlyBeforeEnd {
    require(msg.sender != owner, "Owner cannot bid.");
    require(msg.value > 0, "Bid amount must be greater than 0");

    if (msg.value >= highestBindingBid) {
        if (msg.value == highestBindingBid) {
            // Add the bidder's address to the array
            addressesWithSameValueArray.push(msg.sender);
        }

        // Update highestBid and highestBidder
        previousHighestBid = highestBindingBid;
        highestBindingBid = msg.value;
        highestBidder = msg.sender;
    }

    // Update bids mapping for the bidder
    bids[msg.sender] = msg.value;

    // Increment the number of bids
    numberOfBids++;
}

// Add a function to randomly select a winner among bidders with the same value
function getRandomBidderWithSameValue() internal view returns (address) {
    if (addressesWithSameValueArray.length > 0) {
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender))) % addressesWithSameValueArray.length;
        return addressesWithSameValueArray[randomIndex];
    }
    
    return address(0);
}
function finalizeAuction() external onlyOwner onlyAfterEnd {
    require(highestBidder != address(0), "No bidders");

    uint256 maxIncrement = ((highestBindingBid - previousHighestBid) / 2);

    highestBindingBid = previousHighestBid + maxIncrement;

    for (uint256 i = 0; i < addressesWithSameValueArray.length; i++) {
        payable(addressesWithSameValueArray[i]).transfer(bids[addressesWithSameValueArray[i]]);
    }

    payable(highestBidder).transfer(highestBindingBid);
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
