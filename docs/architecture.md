[architecture.md](https://github.com/user-attachments/files/25888628/architecture.md)
# YouthChain System Architecture

**Youth For Change TT** | youthforchangett.com | Trinidad & Tobago 🇹🇹

---

## Overview

YouthChain is a blockchain-based tokenized learning reward system built on top of the Youth For Change TT platform. It issues on-chain tokens to young people aged 14–25 when they complete verified learning milestones, creating a transparent, tamper-proof record of educational achievement.

---

## System Layers

```
┌─────────────────────────────────────────────────────┐
│                 YOUTH FACING LAYER                  │
│         WordPress / BuddyBoss Platform              │
│   Quiz → BuddyBoss Auth → Results → Token Display   │
└─────────────────────┬───────────────────────────────┘
                      │ HTTP POST (quiz results)
┌─────────────────────▼───────────────────────────────┐
│                OFF-CHAIN DATA LAYER                 │
│              Google Sheets + Apps Script            │
│   Raw Data │ M&E Summary │ Duplicate Prevention     │
│   Personal data stored here ONLY — never on-chain  │
└─────────────────────┬───────────────────────────────┘
                      │ Anonymous ID + Hash only
┌─────────────────────▼───────────────────────────────┐
│                BLOCKCHAIN LAYER                     │
│           Polygon Network (Layer 2)                 │
│   MilestoneVerifier.sol → ChangeToken.sol (CHG)     │
│   Public, immutable, tamper-proof impact records    │
└─────────────────────────────────────────────────────┘
```

---

## Privacy Architecture

YouthChain is designed with child safety as the primary constraint.

### What Goes On-Chain (Public)
| Data | Format | Purpose |
|------|--------|---------|
| Anonymous Student ID | Random string e.g. YFC-A3K9XZ2 | Links record without identity |
| Achievement Hash | Keccak256 hash | Tamper-proof proof of completion |
| Timestamp | Block timestamp | Independently verifiable |
| Score | Integer (0-5) | Learning outcome metric |
| Tokens Earned | CHG amount | Reward record |

### What Stays Off-Chain (Private — Google Sheets only)
| Data | Storage | Access |
|------|---------|--------|
| Full name | Google Sheets | Admin only |
| Email address | Google Sheets | Admin only |
| School / institution | Google Sheets | Admin only |
| WordPress User ID | Google Sheets | Admin only |

---

## Smart Contracts

### ChangeToken.sol (ERC-20)
- **Token:** Change Token (CHG)
- **Max Supply:** 1,000,000,000 CHG
- **Reward Rate:** 0.2 CHG per correct answer
- **Network:** Polygon
- **Standard:** ERC-20 (OpenZeppelin)

### MilestoneVerifier.sol
- Records verified learning milestones on-chain
- Prevents duplicate submissions per anonymous ID
- Triggers token issuance via ChangeToken contract
- Emits public events for impact dashboard

---

## Quiz Flow

```
1. Youth logs into WordPress/BuddyBoss
2. BuddyBoss profile data auto-fills quiz (name, email, school)
3. Youth completes multiple choice and true/false questions
4. On submit:
   a. Score calculated client-side
   b. Result POSTed to Google Apps Script webhook
   c. Google Sheets records result with Anonymous ID
   d. M&E Summary auto-updates
   e. Anonymous ID returned and displayed to youth
5. Tokens displayed immediately (blockchain write queued)
6. On-chain: MilestoneVerifier records hash + issues CHG tokens
```

---

## Duplicate Prevention

Two layers of duplicate prevention:

1. **Off-chain:** Google Apps Script checks WordPress User ID before accepting submission
2. **On-chain:** MilestoneVerifier maps anonymous student ID hash — reverts if already completed

---

## Token Economy

| Action | CHG Earned |
|--------|-----------|
| 1 correct answer | 0.2 CHG |
| 2 correct answers | 0.4 CHG |
| 3 correct answers | 0.6 CHG |
| 4 correct answers | 0.8 CHG |
| 5 correct answers (perfect) | 1.0 CHG |

### Redemption
Tokens are redeemable for:
- Partner gift cards
- Local business discounts
- Digital rewards

---

## M&E Indicators

YouthChain tracks the following indicators for stakeholder reporting:

| Indicator | SDG Target | Data Source |
|-----------|-----------|-------------|
| Total youth completing assessments | SDG 4.4 | Google Sheets |
| Average score per module | SDG 4.6 | Google Sheets |
| School / institution breakdown | SDG 4.5 | Google Sheets |
| Total tokens issued | Area 2 impact | Blockchain |
| Unique wallet addresses | Reach metric | Blockchain |
| On-chain milestone count | Verifiable impact | Blockchain |

---

## Network

| Property | Value |
|----------|-------|
| Network | Polygon |
| Type | Public, Layer 2 |
| Token Standard | ERC-20 |
| Testnet | Polygon Amoy |
| Gas Strategy | Meta-transaction relay (zero cost to users) |

---

## Deployment Status

| Component | Status |
|-----------|--------|
| WordPress Quiz | ✅ Live — youthforchangett.com |
| BuddyBoss Integration | ✅ Live |
| Google Sheets Webhook | ✅ Live |
| M&E Dashboard | ✅ Live |
| Smart Contracts | 🔄 Pre-development — testnet pending |
| Mainnet Deployment | ⏳ Post-audit — pending UNICEF funding |

---

## Open Source

All code in this repository is published under the MIT Licence.
Free to use, modify and deploy by any youth development organisation globally.

Apply for Digital Public Good status: digitalpublicgoods.net

---

*Built in Trinidad and Tobago 🇹🇹 for Caribbean youth and the Global South.*
