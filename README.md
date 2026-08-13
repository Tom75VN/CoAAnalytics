# CoA Analytics

A unified performance analysis and character-advice addon for World of Warcraft: Ascension.

[Download the latest complete release](https://github.com/Tom75VN/CoAAnalytics/releases/latest/download/CoAAnalytics.zip)

The release archive includes both `CoAAnalytics` and the optional
`CoAAnalytics_DataProbe` collector.

## Features

- Battleground rankings for specializations and players
- Role-based scoring for dungeons and raids
- Live dungeon performance ratings
- Mythic 0 Keystone boss identification, required boss-order drawer, and English party sharing
- Mythic+ cache and Mythic Coin counters read from Edrim, plus the next weekly cap increase synced to Ascension's raid reset
- Pet, guardian, healing, threat, and utility tracking
- Per-death spell, aura, exact-threat, and aggro diagnostics for every role
- Class-aware talent, stat, equipment, tooltip, and loot recommendations
- Local character-only combat calibration, kept separate from group performance collection
- Optional community DataProbe, distributed as the load-on-demand `CoAAnalytics_DataProbe` addon
- One interface organized into Home, Performance, Advice, Loot, Combat, Collection, and Settings
- English and French interface

In a recognized Mythic 0 dungeon, the live performance widget shows the
Keystone boss. Its drawer lists verified CoA objectives and clearly labels
legacy routes that still need public CoA confirmation. The share button (or
`/coaa boss share`) always posts in English.

## Installation

1. [Download the repository as a ZIP](https://github.com/Tom75VN/CoAAnalytics/archive/refs/heads/main.zip).
2. Extract it and rename the folder to `CoAAnalytics`.
3. Move `CoAAnalytics` into `Interface/AddOns`.
4. Optionally move `CoAAnalytics_DataProbe` beside it to enable community data collection.
5. Restart the game.

Use `/coaa` to open the unified home page. Advisor commands are available
under `/coaa advisor`, and DataProbe opens with `/coaa collection`.
Use `/coaa reset` to print the next Mythic+ cache/coin cap increase.
The same status and the latest Edrim counters are shown at the top of the
Home page. Use `/coaa reset actualiser` to query the client timers again.

Player data and diagnostic logs remain local in the game's `WTF` folder.
