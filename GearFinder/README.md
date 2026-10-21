# Gear Finder

Gear Finder ranks up to five recorded gear choices per slot for your current character level, with three shown by default. It targets WoW Forever beta 1.60.1, interface 16001.

## Start

1. Restart WoW after installation and enable Gear Finder at character selection.
2. Log in and type `/gear`.
3. Choose your role from the first dropdown.
4. Click Scan.

Each slot shows its equipped item and up to three or five alternatives, with the highest score first. Click an alternative for its source, requirements, stats and base-score difference. Hover it for the game's live tooltip and equipment comparison. Empty results mean the database has no matching choice under your filters.

The add-on detects class, level, faction and profession skills. It saves the role, filters and custom weights separately for each character. New characters start with the first profile for their class. Choose the role that matches how you play. The add-on does not infer your spec from talents.

## Controls

- Top 3 per slot is the default. Choose Top 5 per slot in the upper-right dropdown to expand the results, or switch back to three. The choice saves per character and rescans the results. Slots with fewer eligible items show only those matches.
- The role dropdown has 29 profiles across all nine classes, including separate druid cat and bear profiles and a shaman tank profile.
- Level defaults to your current character level. Use the minus and plus buttons, or type a whole number from 1 to 60 and press Enter. Each change rescans the results. Click Current to resume following your character's level. Current * means that automatic mode is active. A login or `/reload` also restores current-level mode.
- The weapons dropdown selects the profile's preferred weapon setup, all usable weapon types, two-handed weapons, dual wielding, or a weapon and shield. Class and level restrictions still apply.
- The armor dropdown defaults to All usable armor. Choose Cloth only, Leather only, Mail only or Plate only to filter body armor. Cloaks, jewelry, weapons, shields and held items keep their normal results. Class and level restrictions still apply, so choosing an unusable type leaves body armor results empty. The selection saves per character and each change rescans.
- Dungeons, Quests and Crafting select the source types to consider.
- Your character's faction appears in the heading. Use faction farming preferences is enabled by default to preserve earlier settings. Uncheck it to stop hiding Ragefire Chasm routes for Alliance and Ruins of Lordaeron routes for Horde, including their recorded quest rewards. Actual quest faction and class requirements still apply. The choice saves per character. These are configured preferences, not entrance restrictions. An item can still appear through another eligible source.
- Include Classic sources is enabled by default. Clear it to exclude Classic dungeon drops and quest sources or requirements that rely on Classic data.
- Include uncertain requirements is disabled by default. Enable it to include records with missing source requirements or additional restrictions that the add-on cannot verify. Check the detail panel and live tooltip before farming.
- Include commissions of tradable crafts is enabled by default. Clear it to restrict crafting routes to your recorded profession skills. Bind-on-pickup crafts require your own profession and a known recipe unless uncertain requirements are enabled. The filter always checks recorded profession requirements for wearing an item, including Engineering goggles.
- Edit stat weights changes the selected profile's scoring. Each weight is the score added by one point of that stat. Reset restores the bundled estimates for that profile.
- Item page and Quest page select a URL in the copy box. Press Ctrl+C and paste it into your browser. These buttons do not open a browser from the game. Quest page uses the first matching quest route shown in the detail panel.
- Select an item and click Link to party, or Shift-click an item row, to insert its item link into party chat. Press Enter to send. You must be in a group. An instance-only group uses instance chat. If item data is still loading, hover the item and try again. Existing party text stays in the draft. Finish or clear a draft in another channel before using this button.
- Coverage explains what the database includes.
- Item lookup opens the standalone item-source window. The normal WoW Inspect window also has a Find sources button.

Open your professions once so the add-on can observe learned recipes. It does not learn recipes from someone else's linked or guild profession window. Having sufficient profession skill does not prove that you have a recipe, its specialization or its materials. The detail panel labels recipes that have not been confirmed as learned.

Drag the window to move it. Escape closes it. `/gear scan` opens the window and rescans. `/gear resetpos` centers it. `/gearfinder` is an alias for `/gear`.

When your level, faction, equipment, quest completion or profession skills change, the window asks you to Scan again.

Choosing a different level changes equipment level requirements, dungeon and quest level filters, and level-based armor and weapon access. Your equipped gear, profession skills, learned recipes and quest completion remain those of your actual character. The title marks results for a different level as planning results.

## Inspect players and look up items

Inspect a player through WoW's normal Inspect window. Click Find sources beside that window, then click an equipped item. A small panel beside Inspect shows its recorded sources. Keep clicking other equipped items to compare their sources. Click the button again or close the panel to leave source lookup mode. Closing Inspect, changing its player or switching away from the equipment tab also ends the mode. Normal Shift-click links and Ctrl-click dressing-room actions remain available.

The panel's Link to party button prepares an item-link draft. Press Enter to send. Copy item page selects a research URL that you can copy with Ctrl+C. The add-on uses the gear data already loaded by WoW's Inspect window and makes no additional inspection request for these clicks.

The source panel leaves space for the Inspect window's side tabs. It uses the left side when there is more room there and scales down to fit smaller screens. Scroll the details with the mouse wheel. The action buttons and URL field stay below the scroll area.

The standalone Item lookup window remains available for item IDs, pasted links and your own gear. Its Inspect target button and `/gear inspect` command also remain available. Click My gear there to browse your equipment.

To look up a chat link, type `/gear item ` in the chat box, including the trailing space. Shift-click the item link, then press Enter. This runs the lookup command locally. You can also enter an item ID or paste an item link into the lookup field, or drag an inventory item into that field. `/gear item 5191` is an example.

Select an item and click Link to party to prepare a chat draft. Shift-clicking a row does the same. Press Enter to send. The link keeps the inspected item's recorded variant when the game supplies a full hyperlink. Item page copies a research URL. First quest page copies a URL for the first recorded quest route. Other quest IDs appear in the source details.

This window shows all recorded routes, including routes hidden by your ranking filters. It checks requirements against your actual current level, faction and progress, even if the ranking window has a preview level. Your faction farming preferences still appear as exclusions. The window shows possible sources, not proof of how another player obtained the item. Missing records say that no acquisition source is recorded. New Forever dungeon drops, vendors, raids, PvP and general world drops remain outside the bundled source coverage.

Inspection needs a nearby player who can be inspected. It waits for the matching server response, cancels if the target changes, and times out after eight seconds. Requests have a three-second cooldown. If another player's native Inspect window is open, close it before requesting a different player here. Empty or unavailable equipment slots have no item data to look up.

## What the ranking means

The first result is the best base-stat score among the eligible records for that slot and profile. The weights are editable leveling estimates, not theorycrafted best-in-slot lists or simulation results. Some specs share a role template. Caster profiles also weight their main damage schools. Hunter profiles prioritize ranged weapon damage. Feral profiles do not score weapon DPS.

Scores omit procs, on-use effects, set bonuses, enchants, random suffix bonuses, stat caps, talent interactions and enemy-specific effects. The details show recorded effects without assigning them a score. Read the live tooltips when these affect your choice. The bundled snapshot supplies ranking stats even before WoW loads a live item tooltip.

Each slot ranks independently. Both ring slots and both trinket slots can show the same options. This is a list of alternatives, not a proposed complete set. Check Unique and Unique-Equipped restrictions before selecting a pair. Two-handed weapons replace both hands, so a score against the main hand alone is not a full weapon-set comparison. Equipped-item score differences also use the bundled base item, without its enchants or random suffix.

## Database coverage

The October 3, 2026 snapshot matches build 1.60.1.70205. It includes 8,406 gear records. Of these, 2,941 have a recorded dungeon, quest or crafting source. There are 336 items with dungeon sources, 1,302 with quest sources and 1,317 with crafting sources. Some items have more than one source type.

Dungeon drops come from Classic 1.12 records and may differ in Forever. New Forever dungeon drops are not included. Some new Forever quest and crafting rewards are included. Records without an acquisition source, hidden or Season of Discovery records, shirts and tabards do not appear as farming suggestions. Raids, PvP, vendors and general world drops are outside the source filters.

The dungeon filter uses the published recommended minimum level, not a promise that you can solo the dungeon or meet every entrance requirement. It keeps lower-level dungeons available. Quest rewards use the quest's minimum level, faction, recorded class and race restrictions, and completion state. Known higher-level prerequisites also block a route. Other prerequisites remain a check for the player. Quest chains and Classic requirements can change in Forever. A recipe or item in client data does not establish that its source is available in the current beta.

Scan searches this bundled database. It does not research the web, download patches, or refresh source records. A database update requires rebuilding and reinstalling the add-on. AtlasLoot is not required. The AtlasLoot Forever 1.1.7 release notes also mark new dungeon loot as still to be added.

## Install or update

Copy the `GearFinder` folder into the Forever client's `Interface\AddOns` folder. The resulting path should end in `Interface\AddOns\GearFinder\GearFinder.toc`. Restart WoW after adding a new add-on folder.

Use the manual installation above for your chosen client, including `_forever_`. This repository does not include the older beta-only installer. `tools/build_gear.py --refresh` rebuilds the snapshot from public source data. The import may need updating if those sources change their format.

## Validation

The test suite checks Lua 5.1 syntax, snapshot integrity, ranking order, all 29 profiles, armor filters, class and level restrictions, faction farming preferences, quest faction and race requirements, completed quest exclusion, profession requirements, per-profile weights, level previews and UI interactions. Chat tests check item links, draft preservation, group channels and uncached items. Run `node tools/test_gear.cjs` from the project folder. It uses the project's existing Fengari and luaparse dependencies.

Inspection tests check matching server responses, target changes, timeouts, request throttling, missing item records, delayed item data and preservation of inspected item links. This version has not been tested inside WoW. Mock API tests cannot verify the live layout, tooltip behavior or every Forever API change. Enable error reporting with `/console scriptErrors 1` if the add-on fails, then copy the first error. Disable it with `/console scriptErrors 0` afterward.

See SOURCES.md for data provenance and licensing.
