// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MilestoneVerifier
 * @dev Records verified learning milestones on-chain for the
 *      YouthChain system on Youth For Change TT platform.
 *
 * Privacy Model:
 * - NO personal data stored on-chain
 * - Only anonymous student ID, achievement hash and timestamp recorded
 * - Personal data (name, email, school) stays off-chain in Google Sheets
 *
 * What gets recorded:
 * 1. Anonymous student ID (randomly generated, not linked to identity)
 * 2. Keccak256 hash of the assessment record (tamper-proof proof of completion)
 * 3. Block timestamp (immutable, independently verifiable)
 * 4. Score (number of correct answers)
 * 5. Tokens earned
 *
 * This creates verifiable evidence of learning outcomes while keeping
 * children's data 100% off-chain — meeting UNICEF child safety standards.
 *
 * Network: Polygon Amoy Testnet (pre-deployment)
 *          Polygon Mainnet (post-audit deployment)
 */

interface IChangeToken {
    function rewardMilestone(
        address recipient,
        uint256 correctAnswers,
        bytes32 achievementHash
    ) external;
}

contract MilestoneVerifier is Ownable {

    // Reference to the ChangeToken contract
    IChangeToken public changeToken;

    // Mapping to prevent duplicate submissions per anonymous ID
    mapping(bytes32 => bool) public completedMilestones;

    // Total milestones verified on-chain
    uint256 public totalMilestonesVerified;

    // Total tokens issued
    uint256 public totalTokensIssued;

    // Authorised backend addresses (your server/webhook)
    mapping(address => bool) public authorisedBackends;

    // On-chain milestone record
    struct MilestoneRecord {
        bytes32 anonymousStudentId;
        bytes32 achievementHash;
        uint256 score;
        uint256 tokensEarned;
        uint256 timestamp;
        bool verified;
    }

    // Records indexed by achievement hash
    mapping(bytes32 => MilestoneRecord) public milestoneRecords;

    // Events — these are the public, auditable proof of impact
    event MilestoneVerified(
        bytes32 indexed anonymousStudentId,
        bytes32 indexed achievementHash,
        uint256 score,
        uint256 tokensEarned,
        uint256 timestamp
    );

    event BackendAuthorised(address indexed backend);
    event BackendRevoked(address indexed backend);

    // Errors
    error AlreadyCompleted();
    error NotAuthorisedBackend();
    error ZeroAddress();

    constructor(address _changeToken) Ownable(msg.sender) {
        changeToken = IChangeToken(_changeToken);
    }

    /**
     * @dev Authorise a backend address to submit verifications
     */
    function authoriseBackend(address backend) external onlyOwner {
        if (backend == address(0)) revert ZeroAddress();
        authorisedBackends[backend] = true;
        emit BackendAuthorised(backend);
    }

    /**
     * @dev Revoke backend authorisation
     */
    function revokeBackend(address backend) external onlyOwner {
        authorisedBackends[backend] = false;
        emit BackendRevoked(backend);
    }

    /**
     * @dev Verify a completed milestone and issue tokens
     *
     * @param anonymousStudentId  Keccak256 hash of the anonymous student ID
     * @param achievementHash     Keccak256 hash of (studentId + quizId + score + timestamp)
     * @param score               Number of correct answers
     * @param recipientWallet     Student's wallet address to receive tokens
     *
     * Called by authorised backend after Google Sheets records the result.
     * No personal data passed — only hashes and scores.
     */
    function verifyMilestone(
        bytes32 anonymousStudentId,
        bytes32 achievementHash,
        uint256 score,
        address recipientWallet
    ) external {
        if (!authorisedBackends[msg.sender] && msg.sender != owner())
            revert NotAuthorisedBackend();

        // Prevent duplicate completions
        if (completedMilestones[anonymousStudentId])
            revert AlreadyCompleted();

        // Mark as completed
        completedMilestones[anonymousStudentId] = true;

        // Calculate tokens: 0.2 CHG per correct answer
        uint256 tokensEarned = score * 2 * 10 ** 17;

        // Store immutable record on-chain
        milestoneRecords[achievementHash] = MilestoneRecord({
            anonymousStudentId: anonymousStudentId,
            achievementHash:    achievementHash,
            score:              score,
            tokensEarned:       tokensEarned,
            timestamp:          block.timestamp,
            verified:           true
        });

        // Update global counters
        totalMilestonesVerified++;
        totalTokensIssued += tokensEarned;

        // Issue tokens to student wallet
        if (recipientWallet != address(0)) {
            changeToken.rewardMilestone(
                recipientWallet,
                score,
                achievementHash
            );
        }

        // Emit public, auditable event
        emit MilestoneVerified(
            anonymousStudentId,
            achievementHash,
            score,
            tokensEarned,
            block.timestamp
        );
    }

    /**
     * @dev Check if an anonymous student ID has already completed a milestone
     */
    function hasCompleted(bytes32 anonymousStudentId)
        external view returns (bool)
    {
        return completedMilestones[anonymousStudentId];
    }

    /**
     * @dev Get a milestone record by achievement hash
     */
    function getMilestone(bytes32 achievementHash)
        external view returns (MilestoneRecord memory)
    {
        return milestoneRecords[achievementHash];
    }

    /**
     * @dev Update the ChangeToken contract address
     */
    function setChangeToken(address _changeToken) external onlyOwner {
        changeToken = IChangeToken(_changeToken);
    }
}
