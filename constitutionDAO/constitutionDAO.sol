// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title ThresholdIntentAuction
 * @dev This contract handles a threshold-based auction where users can contribute funds. If the threshold is met
 * before a deadline, an auction takes place. Contributors can request a refund if the auction fails or the threshold isn't met.
 */
contract ThresholdIntentAuction is ReentrancyGuard {
    using SafeMath for uint256;

    struct Contribution {
        uint256 amount;  // Amount contributed by an address
        bool refunded;   // Whether the contribution has been refunded
    }

    address private owner;        // Address of the contract owner
    uint256 private threshold;    // Contribution threshold to trigger the auction
    uint256 private totalRaised;  // Total amount raised from contributions
    uint256 private deadline;     // Deadline for reaching the threshold
    bool private thresholdMet;    // Whether the threshold has been met
    bool private auctionWon;      // Whether the auction has been won
    mapping(address => Contribution) private contributions;  // Mapping of contributor addresses to their contributions
    address[] private contributors;  // List of contributors

    /// @dev Emitted when a contribution is made.
    /// @param contributor The address of the contributor.
    /// @param amount The amount of the contribution.
    event ContributionMade(address indexed contributor, uint256 amount);

    /// @dev Emitted when the threshold is reached.
    /// @param totalAmount The total amount raised when the threshold is reached.
    event ThresholdReached(uint256 totalAmount);

    /// @dev Emitted when the auction is won.
    /// @param bidAmount The bid amount made by the contract owner.
    event AuctionWon(uint256 bidAmount);

    /// @dev Emitted when a refund is issued to a contributor.
    /// @param contributor The address of the contributor receiving the refund.
    /// @param amount The amount refunded.
    event RefundIssued(address indexed contributor, uint256 amount);

    /// @dev Ensures that only the contract owner can call the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    /// @dev Ensures that the current time is before the deadline.
    modifier beforeDeadline() {
        require(block.timestamp < deadline, "Deadline has passed");
        _;
    }

    /// @dev Ensures that the current time is after the deadline.
    modifier afterDeadline() {
        require(block.timestamp >= deadline, "Deadline has not yet passed");
        _;
    }

    /**
     * @notice Initializes the auction with a threshold and duration.
     * @param _threshold The minimum amount of contributions required for the auction to proceed.
     * @param _durationInDays The duration of the auction in days.
     */
    constructor(uint256 _threshold, uint256 _durationInDays) {
        owner = msg.sender;
        threshold = _threshold;
        deadline = block.timestamp + (_durationInDays * 1 days);
        thresholdMet = false;
        auctionWon = false;
    }

    /**
     * @notice Allows users to contribute funds to the auction before the deadline.
     * @dev Contribution amount must be greater than zero.
     */
    function contribute() external payable beforeDeadline nonReentrant {
        require(msg.value > 0, "Contribution must be greater than 0");
        
        if (contributions[msg.sender].amount == 0) {
            contributors.push(msg.sender);
        }
        
        contributions[msg.sender].amount = contributions[msg.sender].amount.add(msg.value);
        totalRaised = totalRaised.add(msg.value);

        emit ContributionMade(msg.sender, msg.value);

        if (totalRaised >= threshold && !thresholdMet) {
            thresholdMet = true;
            emit ThresholdReached(totalRaised);
        }
    }

    /**
     * @notice Allows the owner to place a bid after the deadline if the threshold is met.
     * @dev The bid amount must not exceed the total amount raised.
     * @param bidAmount The amount the owner bids in the auction.
     */
    function placeBid(uint256 bidAmount) external onlyOwner afterDeadline {
        require(thresholdMet, "Threshold not met");
        require(bidAmount <= totalRaised, "Bid amount exceeds total raised");
        
        // Simulating the auction win
        auctionWon = true;
        emit AuctionWon(bidAmount);
    }

    /**
     * @notice Allows the owner to withdraw the raised funds after a successful auction.
     * @dev Can only be called if the auction was won.
     */
    function withdraw() external onlyOwner afterDeadline {
        require(auctionWon, "Auction not won");
        uint256 amount = address(this).balance;
        payable(owner).transfer(amount);
    }

    /**
     * @notice Allows contributors to request a refund if the threshold wasn't met or the auction wasn't won.
     */
    function refund() external afterDeadline nonReentrant {
        require(!thresholdMet || !auctionWon, "Cannot refund after successful auction");
        Contribution storage contribution = contributions[msg.sender];
        require(contribution.amount > 0, "No contribution to refund");
        require(!contribution.refunded, "Already refunded");

        uint256 refundAmount = contribution.amount;
        contribution.refunded = true;
        contribution.amount = 0;

        payable(msg.sender).transfer(refundAmount);
        emit RefundIssued(msg.sender, refundAmount);
    }

    /**
     * @notice Returns the contribution amount for a specific contributor.
     * @param contributor The address of the contributor.
     * @return The contribution amount of the specified contributor.
     */
    function getContribution(address contributor) external view returns (uint256) {
        return contributions[contributor].amount;
    }

    /**
     * @notice Returns the total amount raised.
     * @return The total amount of funds raised.
     */
    function getTotalRaised() external view returns (uint256) {
        return totalRaised;
    }

    /**
     * @notice Returns whether the threshold has been met.
     * @return True if the threshold has been met, false otherwise.
     */
    function isThresholdMet() external view returns (bool) {
        return thresholdMet;
    }

    /**
     * @notice Returns the auction deadline timestamp.
     * @return The deadline timestamp.
     */
    function getDeadline() external view returns (uint256) {
        return deadline;
    }

    /**
     * @notice Returns whether the auction was won.
     * @return True if the auction was won, false otherwise.
     */
    function isAuctionWon() external view returns (bool) {
        return auctionWon;
    }
}
