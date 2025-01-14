# Proveably Random Raffle Contracts

## About

This code is to create a proveably random smart contract lottery.

## What we want it to do?

1. Users should be able to enter the raffle by paying for a ticket. The ticket fees are going to be the prize the winner receives.
2. The lottery should automatically and programmatically draw a winner after a certain period.
3. Chainlink VRF should generate a provably random number.

4. Chainlink Automation should trigger the lottery draw regularly.

## Notes
- Update foundry.toml to have read permissions on the broadcast folder. FS permissions means to give foundry read access to broadcast and reports folders
```toml
fs_permissions = [
    { access = "read", path = "./broadcast" },
    { access = "read", path = "./reports" },
]
```
- The previous version of foundry DevOps had FFI equals true. It give foundry shell access to whatever it wanted to 
ex - `ffi = true`