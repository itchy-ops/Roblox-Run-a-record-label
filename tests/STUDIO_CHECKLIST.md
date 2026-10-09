# Roblox Studio acceptance checks

These are manual engine checks; they have not been run by the Linux test harness.

1. Download and open `build/RecordLabel.rbxl` with File → Open from File and confirm the Town model, buildings, and spawn are visible before Play. Then Play. Confirm the town, spawn, discovery booths, and Phone render. Walk to all locations. Check Output for errors and the “RecordLabel Map fix 3: 32 anchored map parts ready” startup message. Confirm the character stands on the purple Town Spawn, not in a void.
2. Confirm initial cash is $5,000 and Studio is level 0. Hide/show the phone with P and the button. Check a narrow mobile emulator and scroll through a contract form.
3. Search Feed, inspect a solo artist and a band, and discover artists at a town booth. Potential and exact skill/consistency must remain hidden initially.
4. Upgrade scouting, pay for a report, and verify the range narrows. Repeated reports must not reveal the exact potential.
5. Send four very low offers. Confirm patience drops, refusal lasts two minutes, and no cash is charged for rejection. Check invalid, unaffordable, and out-of-range terms.
6. Sign a funded deal. Confirm bonus plus promotion are deducted once, the royalty and duration are correct, and capacity prevents excess contracts.
7. Try recording with the broken studio, then repair it and record a single. Launch an album after the single finishes, a tour, and promotion. Verify costs and overlapping campaign restrictions.
8. Observe at least three minute refreshes. Cash should change each second, explanations should update, genre demand should fluctuate, and weak/high-expense artists can lose money.
9. Grow an artist beyond popularity 50. Wait for an AI offer, decline one, then accept another. Verify payment, ownership removal, and no replay.
10. Start a two-player local server. Submit a player buyout, decline it, then accept a new one. Verify only the seller can accept, terms survive transfer, and cash/ownership move once. Check expired offers and insufficient buyer funds/capacity.
11. In a separate published test experience with Studio API access enabled, repeat a trade, leave, and rejoin both accounts. Confirm ownership, cash, upgrades, and contracts persist. Check that the practice warning disappears only with successful profile persistence.
12. Confirm a contract expires after its timestamp, stops earning, and can be negotiated again. Check no offline earnings are granted.
13. For release testing, use controlled DataStore fault injection in a test experience at reservation, journal commit, and final save boundaries. After lease expiry, rejoin both players and confirm exactly one owner and conserved transfer cash. The mocked fault-injection suite is not a substitute for this live test.
