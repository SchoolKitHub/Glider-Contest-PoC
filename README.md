# Glider Contest PoC

This submission demonstrates an access-control initialization vulnerability using a local fork, following the Glider Contest PoC guidelines.

## Overview

We reproduce two takeover vectors detected by our Glider query:
- Unguarded admin setup: `setDefaultAdmin(address)` callable by anyone before a one-time flag is set.
- First-call initializer exposure: `init()` / `initialize(...)` / VaultLib-style `init(address,address,string)` callable post-deploy.

The PoC runs on a local fork only and prints clear logs that confirm the vulnerable behavior.

## Environment

- Tooling: Foundry (forge/cast)
- RPC endpoint: configurable via `RPC_URL` (prefilled with Sepolia for this demo)
- Fork block: exact block via `BLOCK_NUMBER`
- Safety: never touches live chains directly; all interactions occur on a fork

## Files

- `foundry.toml` — Foundry config
- `.env.example` — environment template (`RPC_URL`, `BLOCK_NUMBER`, `TARGET_ADDRESS`, `ATTACKER`, optional `FUND_NAME`)
- `test/PoC_SetDefaultAdmin.t.sol` — RBAC takeover PoC
- `test/PoC_InitializerFirstCall.t.sol` — Generic initializer PoC (+ VaultLib signature)
- `test/PoC_VaultLibInit.t.sol` — Focused VaultLib initializer PoC
- `script/Run*.s.sol` — Optional one-shot scripts for each path
- `EXPECTED_OUTPUT.txt` — Sample output from a successful run

## Implementation

- The tests set up a fork at `BLOCK_NUMBER` and impersonate `ATTACKER`.
- The admin PoC calls `setDefaultAdmin(attacker)` and then attempts `grantRole(DEFAULT_ADMIN_ROLE, attacker)` to show privileges.
- The initializer PoCs try common signatures and verify that a second call fails (single-use lock semantics), confirming first-call capture.

### What the logs show
- The exact call attempted
- Whether it succeeded
- Post-condition checks (e.g., second-call failure or role grant success)

## Run Instructions

1) Install dependencies (once):
```bash
forge install foundry-rs/forge-std --no-commit
```

2) Set environment:
```bash
cp .env.example .env
# Edit .env: set RPC_URL, BLOCK_NUMBER, TARGET_ADDRESS, (optional) ATTACKER, FUND_NAME
```

3) Run one of the tests:
```bash
# setDefaultAdmin takeover
forge test -vv --match-test test_SetDefaultAdmin_Takeover --fork-url $RPC_URL --fork-block-number $BLOCK_NUMBER

# Generic initializer sweep (includes VaultLib init(address,address,string))
forge test -vv --match-test test_Initializer_FirstCall_Takeover --fork-url $RPC_URL --fork-block-number $BLOCK_NUMBER

# Focused VaultLib init PoC
forge test -vv --match-test test_VaultLib_Init_Takeover --fork-url $RPC_URL --fork-block-number $BLOCK_NUMBER
```

4) Optional scripts (single call per run):
```bash
forge script script/RunSetDefaultAdminPoC.s.sol:RunSetDefaultAdminPoC --rpc-url $RPC_URL --broadcast --slow --sig "run()"
forge script script/RunInitializerPoC.s.sol:RunInitializerPoC --rpc-url $RPC_URL --broadcast --slow --sig "run()"
forge script script/RunVaultLibInitPoC.s.sol:RunVaultLibInitPoC --rpc-url $RPC_URL --broadcast --slow --sig "run()"
```

## Expected Output

See `EXPECTED_OUTPUT.txt`. Example excerpt from a successful `setDefaultAdmin` run:

```
Running 1 test for test/PoC_SetDefaultAdmin.t.sol:PoC_SetDefaultAdmin
[PASS] test_SetDefaultAdmin_Takeover() (gas: 17847)
Logs:
  Called setDefaultAdmin(attacker)
    success: true
  Attempted grantRole(DEFAULT_ADMIN_ROLE, attacker) success: true
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 7.4s
```

## Safety Statement

- Runs exclusively on a local fork of a specified chain.
- No keys, secrets, or live transactions are used.
- The PoC is readied for reproducibility and isolation per the contest rules.

## Optional Impact Context

If run against high-value targets (as filtered by Glider query), an attacker gaining admin via these functions could:
- Seize DEFAULT_ADMIN_ROLE and escalate privileges, potentially draining tokens via privileged calls.
- Lock operators out by resetting roles, pausing systems, or changing upgrade paths.

## Remediation

- Initialize admin/owner at deployment (constructor) or guard initialization paths.
- Use `initializer`/`reinitializer` and ensure implementations are locked by running a dummy initializer.
- Ensure admin-setup functions are restricted (e.g., `onlyOwner`) or constructor-only.
