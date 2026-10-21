# Gear Finder

![Promotional artwork](media/banner.png)

AI-generated promotional artwork. The screenshot below shows the actual add-on in game.

Rank gear choices by level and role, and look up recorded dungeon, quest and crafting sources.

This is a beta for WoW Forever 1.60.1, interface 16001.

## Download and install

Download `GearFinder-1.6.3-beta.1.zip` from [Releases](https://github.com/DeanieBobeanie/GearFinder-Forever/releases).
Use that installable ZIP. GitHub's Source code archives contain the development repository.

Close WoW, extract the ZIP and copy `GearFinder` into your Forever client's
`Interface/AddOns` folder. For the current client this is usually
`World of Warcraft/_forever_/Interface/AddOns`. Select the actual client you use.
The resulting path must end in `GearFinder/GearFinder.toc`.
Restart WoW and enable the add-on at character selection.

Type `/gear`, choose a role and click Scan. Use Find sources beside the normal Inspect window to look up an equipped item.

Read the [complete controls and troubleshooting guide](GearFinder/README.md).

## Beta limits

The 3 October 2026 snapshot omits new Forever dungeon drops. Rankings use estimated base-stat weights and omit procs, set bonuses and complete gear-set comparisons. This beta adds a saved checkbox to disable faction farming preferences. It defaults to on to preserve previous behavior. Inspect integration still needs an in-game check.

Checked in WoW Forever on 21 October 2026. Scanning at the current level and planning level 25 works. Selecting an item shows its source details. Switching faction farming preferences off changes the planning results from 390 to 395 items, and switching it on restores 390. Inspect integration and broader gameplay still need testing.

The automated tests also pass outside WoW. Report the first Lua error and steps to reproduce it in an issue.

## In-game screenshot

![Actual in-game screenshot](media/in-game.jpg)

Level 25 planning on a level 6 Horde hunter, with a selected dungeon source.
Captured on 21 October 2026. Other installed add-ons are visible in the surrounding UI.

## Help develop it

Read [CONTRIBUTING.md](CONTRIBUTING.md) for setup and test commands.
Bug reports, gameplay checks, code improvements and documentation fixes are welcome.

## Credits and license

Maintained by DeanieBobeanie and contributors. Original code uses GPL-3.0-or-later. Preserve the bundled Classic DB notices. See GearFinder/SOURCES.md for data provenance and limits.
See [LICENSE](LICENSE). Independent add-on, with no Blizzard endorsement.
