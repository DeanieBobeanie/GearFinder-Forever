First public beta for WoW Forever 1.60.1, interface 16001.

Rank recorded gear by level and role, and look up its dungeon, quest and crafting sources.

## Changes

- Added the saved Use faction farming preferences checkbox.
- Turn it off to include cross-faction dungeon farming routes. Actual quest faction and class restrictions still apply.
- Existing characters keep faction farming preferences enabled by default.

## Install

Download `GearFinder-1.6.3-beta.1.zip` under Assets. Close WoW, extract it and copy `GearFinder` into your client's `Interface/AddOns` folder. Restart WoW and enable it at character selection.

Type `/gear`, choose a role and click Scan. Keep your WTF folder when updating to retain settings. `SHA256SUMS.txt` contains the download checksum.

## Known limits

- The 3 October 2026 data snapshot omits new Forever dungeon drops.
- Rankings use estimated base-stat weights and omit procs, set bonuses and complete gear-set comparisons.
- Inspect integration still needs an in-game check.

## Checks

Automated checks passed. Current-level scans, level 25 planning and item source details were checked in WoW Forever on 21 October 2026. Disabling faction farming preferences changed the planning results from 390 to 395 items; enabling it restored 390.

![Gear Finder level planning and item source details in WoW Forever](https://raw.githubusercontent.com/DeanieBobeanie/GearFinder-Forever/v1.6.3-beta.1/media/in-game.jpg)

[Usage guide](https://github.com/DeanieBobeanie/GearFinder-Forever#quick-start) · [Report a bug](https://github.com/DeanieBobeanie/GearFinder-Forever/issues) · [Contribute](https://github.com/DeanieBobeanie/GearFinder-Forever/blob/main/CONTRIBUTING.md)
