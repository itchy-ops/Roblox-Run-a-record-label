# Run a Record Label

A playable Roblox management prototype based on the supplied design conversation. Start with $5,000 and a battered studio, discover solo artists and bands, negotiate contracts, build careers, and decide when to sell.

## Open and play

The generated place is [**build/RecordLabel.rbxlx**](build/RecordLabel.rbxlx). Download it and open it with Roblox Studio, then press **Play**. No third-party assets or plugins are required to play the built place.

Your phone opens automatically. Use **P** or the Phone button to hide it while walking around town. Visit Open Mic, Park Stage, and Music Cafe discovery booths, or search the Feed. Repair your studio, scout an artist, and submit a contract offer. Roster contains recording, album, touring, promotion, and AI buyout actions. Inbox shows career and negotiation messages. Market shows other online players' contracts and lets owners approve buyouts.

## Build and validate in the cloud

```sh
cd /workspace/Roblox-Run-a-record-label
bash tools/install.sh
```

Setup installs locked Node development dependencies, downloads Rojo 7.6.1 with TLS and a pinned SHA-256 from the official GitHub release, runs tests, and builds the place. Python 3 and Node/npm are required. No Roblox account credentials belong in these scripts.

After editing:

```sh
npm test
npm run build
```

For local desktop development, install the official Rojo Studio plugin and run `.tools/rojo serve default.project.json`, or rebuild and reopen the place. Each cloud task is already isolated: use this checkout; do not create another Git worktree.

## Gameplay implemented

- A small walkable town, one studio, three discovery locations, and a responsive phone interface.
- Unique server-generated solo artists and bands, genre and popularity meters, mostly hidden potential, estimated skill, partial motivation, and consistency revealed after career experience.
- Paid scouting and three upgrades that narrow stable potential estimates without revealing exact stats through repeated requests.
- Email/DM-style contract offers with bonus, royalties, duration, prepaid promotion, artist-specific acceptance thresholds, patience, and a two-minute refusal cooldown.
- Server-calculated earnings applied each second and rerolled each minute. Studio quality, popularity, skill, promotion, releases, tours, genre trends, and random success/failure affect earnings. Expenses can exceed income.
- Single and album campaigns, touring, promotion, studio repair, expanded capacity, and fluctuating genre demand.
- AI buyout offers for popular artists. Owners can accept or decline; offers never take artists without consent.
- Online player buyout offers with seller approval, affordability and capacity checks, expiration, and preserved royalties and contract end times.
- Saved cash, upgrades, discovery, artist careers, messages, and remaining contracts. Session leases prevent simultaneous profile use; unavailable live saves stop play instead of overwriting progress with defaults.
- A durable trade journal and profile escrows recover interrupted player transfers. Reserved cash and artists settle once or return on abort.

## Saving and multiplayer testing

Publish a **separate test place** in Studio and enable **Game Settings → Security → Enable Studio Access to API Services** to test actual DataStores. Do not connect Studio tests to a production experience's live player data. Without API access, Studio clearly labels an unsaved practice session. Published servers refuse failed profile loads.

In Studio's **Test** tools, start a server with two players. Sign an artist on one label, open Market on the other, submit an offer, and approve it in the seller's Inbox. Saved and practice labels cannot trade with each other.

Contracts use real timestamps and expire while offline. Offline earnings are not awarded. Income rates resume at the next server career refresh. Save interval is 45 seconds; a hard crash can lose ordinary progress since the last successful save. Trade reservations and decisions are saved before assets settle. An interrupted transaction may require waiting up to three minutes for its journal deadline and profile lease before rejoining.

## Validation and remaining work

Automated checks exercise the actual economy, server request handlers, profile store, trade journal, and settlement code against a small Roblox service model. They cover negotiation, hidden stats, funds, authorization, studio requirements, releases, AI offers, player transfers, duplicate settlement, expiration, interrupted transfers, and save failures. These tests do **not** simulate Roblox rendering, physics, real DataStore throttling, or Studio networking.

See [the Studio smoke-test checklist](tests/STUDIO_CHECKLIST.md) for the remaining engine checks. Linux cloud tooling cannot run Roblox Studio, so those checks have not been executed here.

This is a first playable prototype, not a finished commercial game. The town and studio use simple generated geometry; artist profiles represent performers without animated NPC rigs, recorded music, custom character art, or a real external social network. Releases and tours are management campaigns rather than minigames. Artists are unique to each label's discovery pool until traded. Expired artists become available for their current label to renegotiate; a shared cross-server free-agent auction is not implemented. Marketplace listings cover players in the same server. Balancing, art/audio, accessibility/device testing, and production load testing remain before release.
