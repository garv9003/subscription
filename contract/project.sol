// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionManager {
    address public owner;
    uint256 public subscriptionFee;
    uint256 public subscriptionDuration = 30 days;

    struct Subscriber {
        bool isActive;
        uint256 validUntil;
    }

    mapping(address => Subscriber) public subscribers;

    event Subscribed(address indexed user, uint256 validUntil);
    event SubscriptionRenewed(address indexed user, uint256 validUntil);
    event SubscriptionFeeUpdated(uint256 newFee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    modifier onlyActiveSubscriber() {
        require(subscribers[msg.sender].isActive && subscribers[msg.sender].validUntil > block.timestamp, "Subscription inactive or expired");
        _;
    }

    constructor(uint256 _fee) {
        owner = msg.sender;
        subscriptionFee = _fee;
    }

    function subscribe() external payable {
        require(msg.value == subscriptionFee, "Incorrect subscription fee");

        Subscriber storage user = subscribers[msg.sender];
        if (user.validUntil > block.timestamp) {
            user.validUntil += subscriptionDuration;
        } else {
            user.validUntil = block.timestamp + subscriptionDuration;
            user.isActive = true;
        }

        emit Subscribed(msg.sender, user.validUntil);
    }

    function renewSubscription() external payable onlyActiveSubscriber {
        require(msg.value == subscriptionFee, "Incorrect renewal fee");
        subscribers[msg.sender].validUntil += subscriptionDuration;

        emit SubscriptionRenewed(msg.sender, subscribers[msg.sender].validUntil);
    }

    function isSubscribed(address _user) external view returns (bool) {
        return subscribers[_user].isActive && subscribers[_user].validUntil > block.timestamp;
    }

    function updateSubscriptionFee(uint256 _newFee) external onlyOwner {
        subscriptionFee = _newFee;
        emit SubscriptionFeeUpdated(_newFee);
    }

    function withdrawFunds() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getSubscriptionStatus() external view returns (bool, uint256) {
        Subscriber memory user = subscribers[msg.sender];
        return (user.isActive, user.validUntil);
    }
}

