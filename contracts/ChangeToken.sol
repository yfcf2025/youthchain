// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ChangeToken
 * @dev ERC-20 token for the YouthChain learning rewards system
 * @notice Issued to youth on the Youth For Change TT platform
 *         when they complete verified learning milestones.
 *
 * Token Economics:
 * - Symbol: CHG
 * - Decimals: 18 (standard ERC-20)
 * - Max Supply: 1,000,000,000 CHG (1 billion)
 * - Reward Rate: 0.2 CHG per correct quiz answer
 *
 * Privacy Model:
 * - No personal data stored on-chain
 * - Tokens issued to anonymous wallet addresses only
 * - Personal data remains off-chain in secured Google Sheets
 *
 * Network: Polygon (MATIC) - Layer 2, low fees, mobile-friendly
 */

contract ChangeToken is ERC20, Ownable {

    // Maximum total supply: 1 billion CHG
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;

    // Reward per correct answer: 0.2 CHG
    uint256 public constant REWARD_PER_ANSWER = 2 * 10 ** 17;

    // Authorised minters (MilestoneVerifier contract)
    mapping(address => bool) public authorisedMinters;

    // Events
    event MilestoneRewarded(
        address indexed recipient,
        uint256 amount,
        bytes32 achievementHash,
        uint256 timestamp
    );

    event MinterAuthorised(address indexed minter);
    event MinterRevoked(address indexed minter);

    // Errors
    error MaxSupplyExceeded();
    error NotAuthorisedMinter();
    error ZeroAddress();

    constructor() ERC20("Change Token", "CHG") Ownable(msg.sender) {}

    /**
     * @dev Authorise an address to mint tokens (e.g. MilestoneVerifier)
     */
    function authoriseMinter(address minter) external onlyOwner {
        if (minter == address(0)) revert ZeroAddress();
        authorisedMinters[minter] = true;
        emit MinterAuthorised(minter);
    }

    /**
     * @dev Revoke minting authorisation
     */
    function revokeMinter(address minter) external onlyOwner {
        authorisedMinters[minter] = false;
        emit MinterRevoked(minter);
    }

    /**
     * @dev Mint tokens as reward for completing a learning milestone
     * @param recipient     Anonymous wallet address of the youth
     * @param correctAnswers Number of correct answers in the quiz
     * @param achievementHash Keccak256 hash of the achievement record
     */
    function rewardMilestone(
        address recipient,
        uint256 correctAnswers,
        bytes32 achievementHash
    ) external {
        if (!authorisedMinters[msg.sender] && msg.sender != owner())
            revert NotAuthorisedMinter();
        if (recipient == address(0)) revert ZeroAddress();

        uint256 amount = correctAnswers * REWARD_PER_ANSWER;

        if (totalSupply() + amount > MAX_SUPPLY)
            revert MaxSupplyExceeded();

        _mint(recipient, amount);

        emit MilestoneRewarded(
            recipient,
            amount,
            achievementHash,
            block.timestamp
        );
    }

    /**
     * @dev Owner can mint directly for airdrops and testing
     */
    function mint(address to, uint256 amount) external onlyOwner {
        if (totalSupply() + amount > MAX_SUPPLY)
            revert MaxSupplyExceeded();
        _mint(to, amount);
    }
}
