// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "contracts/PriceConverter.sol";

// Custom Errors (Best Practice for gas efficiency and clearer error messages)
error NotOwner();
error NotBuyer();
error InvalidState(Escrow.Status currentStatus, Escrow.Status expectedStatus);
error InsufficientDeposit(uint256 sentAmount, uint256 requiredAmount);
error BuyerAlreadySet();
error TransferFailed();
error UnauthorizedCaller(); // For dispute, etc.

contract Escrow {
    using PriceConverter for uint256;

    // State Variables (organized and optimized)
    // Immutable for fixed addresses initialized in constructor (gas efficient)
    address public immutable i_owner;
    // Constant for fixed values (most gas efficient)
    uint256 public constant DEPOSIT_AMOUNT_USD = 5e18; // Renamed for clarity: 5e18 means $5 if using 18 decimals for USD

    // Public for easy readability, but `buyer` is dynamically set
    address public buyer;
    Status public currentStatus; // Renamed for clarity, `status` is a common keyword

    // Enum for states (ordered logically)
    enum Status {
        Created,   // 0: Asset defined, ready for deposit
        Deposited, // 1: Buyer deposited funds
        Delivered, // 2: Seller confirmed delivery
        Refunded,  // 3: Funds returned to buyer
        Disputed   // 4: Dispute initiated, needs external resolution
    }

    // Asset Details (struct and array are fine, consider if only one asset per escrow)
    struct AssetDetail {
        string name;
        string description;
        uint256 price; // Price of the asset, potentially in local currency or original units
    }
    AssetDetail[] public assets; // Use a single asset if it's one-to-one escrow

    // No longer needed as part of the core challenge, or specific to an advanced multi-asset scenario
    // mapping(string => uint256) public nameToAmountFunded;

    // Events (Renamed for clarity and consistency)
    event AssetDetailsSet(string name, string description, uint256 price);
    event FundsDeposited(address indexed buyerAddress, uint256 depositedValueUSD); // Emitting USD value for clarity
    event DeliveryConfirmed();
    event FundsRefunded(uint256 amount);
    event DisputeInitiated(address indexed initiator);
    event FundsWithdrawn(uint256 amount);

    // Modifiers (using custom errors)
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    modifier onlyBuyer() {
        if (msg.sender != buyer) revert NotBuyer();
        _;
    }

    // Constructor (sets immutable owner and initial status)
    constructor() {
        i_owner = msg.sender;
        currentStatus = Status.Created; // Initialize status here
    }

    /**
     * @notice Allows the owner to define the asset being escrowed.
     * @param _name The name of the asset.
     * @param _description A description of the asset.
     * @param _price The price of the asset (e.g., in USD cents, or units).
     */
    function createAsset(string calldata _name, string calldata _description, uint256 _price) external onlyOwner {
        // Only allow asset creation if in Created state (initial)
        // or Refunded state (allowing re-use of contract for a new asset after a refund)
        // Adjust this logic based on whether you want a single-use or multi-use escrow contract
        if (currentStatus != Status.Created && currentStatus != Status.Refunded) {
             revert InvalidState(currentStatus, Status.Created); // Or specific error for "Asset already defined"
        }

        // Clear existing assets if re-creating, assuming single asset per escrow
        if (assets.length > 0) {
            delete assets; // Clear existing assets if allowing re-creation
        }

        assets.push(AssetDetail(_name, _description, _price));
        emit AssetDetailsSet(_name, _description, _price);

        // If you want to allow re-creating after refund, ensure status becomes Created again.
        // currentStatus = Status.Created; // Uncomment if you allow re-creating after Refunded
    }

    /**
     * @notice Allows the buyer to deposit funds into the escrow.
     * @dev The first person to call this becomes the buyer.
     * Requires the contract to be in 'Created' state and the deposit amount to meet the minimum.
     */
    function deposit() public payable {
        if (currentStatus != Status.Created) revert InvalidState(currentStatus, Status.Created);
        if (buyer != address(0)) revert BuyerAlreadySet(); // Ensures only one buyer can deposit

        uint256 depositedUSD = msg.value.getConversionRate();
        if (depositedUSD < DEPOSIT_AMOUNT_USD) revert InsufficientDeposit(depositedUSD, DEPOSIT_AMOUNT_USD);

        buyer = msg.sender;
        currentStatus = Status.Deposited;

        emit FundsDeposited(msg.sender, depositedUSD);
    }

    /**
     * @notice Allows the seller (owner) to confirm delivery of the asset.
     * @dev Transitions the contract to 'Delivered' state.
     */
    function confirmDelivery() external onlyOwner {
        if (currentStatus != Status.Deposited) revert InvalidState(currentStatus, Status.Deposited);
        currentStatus = Status.Delivered;
        emit DeliveryConfirmed();
    }

    /**
     * @notice Allows the buyer to get a refund if delivery hasn't been confirmed.
     * @dev Funds are transferred back to the buyer, and the contract transitions to 'Refunded'.
     * @dev Add a time-lock condition here for a real-world scenario (e.g., if not confirmed within X time).
     */
    function refund() external onlyBuyer {
        if (currentStatus != Status.Deposited) revert InvalidState(currentStatus, Status.Deposited);

        // Optional: Add a time-lock here for a real-world scenario
        // require(block.timestamp > deliveryConfirmationDeadline, "Refund not yet available");

        uint256 amountToRefund = address(this).balance; // Refund entire contract balance
        currentStatus = Status.Refunded; // Set status before external call (re-entrancy guard)
        emit FundsRefunded(amountToRefund);

        (bool success, ) = payable(buyer).call{value: amountToRefund}("");
        if (!success) revert TransferFailed();
    }

    /**
     * @notice Allows either buyer or owner to initiate a dispute.
     * @dev Moves the contract to 'Disputed' state, requiring external resolution.
     */
    function dispute() external {
        if (msg.sender != buyer && msg.sender != i_owner) revert UnauthorizedCaller();
        if (currentStatus != Status.Deposited && currentStatus != Status.Delivered) {
            revert InvalidState(currentStatus, Status.Deposited); // Or another specific error
        }
        currentStatus = Status.Disputed;
        emit DisputeInitiated(msg.sender);
    }

    /**
     * @notice Allows the owner to withdraw funds after delivery is confirmed.
     * @dev Transfers the entire contract balance to the owner.
     */
    function withdraw() external onlyOwner {
        if (currentStatus != Status.Delivered) revert InvalidState(currentStatus, Status.Delivered);

        uint256 amountToWithdraw = address(this).balance;
        // Optionally, reset nameToAmountFunded if it serves a specific purpose in a multi-asset scenario
        // For a simple single-asset escrow, this part might be removed or adapted.
        // for (uint256 i = 0; i < assets.length; i++) {
        //     nameToAmountFunded[assets[i].name] = 0;
        // }
        currentStatus = Status.Created; // Or 'Completed' if you want a terminal state

        emit FundsWithdrawn(amountToWithdraw);
        (bool success, ) = payable(i_owner).call{value: amountToWithdraw}("");
        if (!success) revert TransferFailed();
    }

    // Fallback and Receive functions to handle direct Ether transfers
    fallback() external payable {
        deposit(); // Redirects incoming Ether to the deposit logic
    }

    receive() external payable {
        deposit(); // Redirects incoming Ether to the deposit logic
    }
}
