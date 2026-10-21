# Classic world data: attribution and licence

The files in this folder (`/data/classicdb/`) are derived from **cMaNGOS classic-db**, a content database for
World of Warcraft Classic (patch 1.12) kept by the CMaNGOS project:

- Source: https://github.com/cmangos/classic-db
- Commit: [`ec4f596146be6467ea93c57397858e329e2db852`](https://github.com/cmangos/classic-db/tree/ec4f596146be6467ea93c57397858e329e2db852) (2026-09-22)
- Files read: `Full_DB/ClassicDB_1_12_1_z2815.sql.gz`, 357 files of `Updates/` and 30 of `Updates/Instances/`,
  applied in the order of its `InstallFullDB.sh`
- Licence: GNU General Public License version 3 (GPL-3.0). The full text is in [LICENSE.md](LICENSE.md), copied
  unchanged from the source. World of Warcraft content and materials are trademarks and copyrights of Blizzard
  Entertainment; see the source's [COPYRIGHT.md](COPYRIGHT.md), also copied unchanged.
- Authors: the contributors of cMaNGOS classic-db, as its commit history records them; its authorship file is copied
  unchanged as [AUTHORS.txt](AUTHORS.txt).

## What we changed

Forever Codex (https://forever-codex.com), a fan site not affiliated with Blizzard or with CMaNGOS, converted the
SQL tables `creature_template`, `creature`, `gameobject_template`, `gameobject`, the loot tables (`creature_`,
`gameobject_`, `reference_`, `item_`, `pickpocketing_`, `skinning_` and `fishing_loot_template`), `npc_vendor`,
`npc_trainer` (and their templates), `quest_template` and the quest relation tables, `item_template`, `conditions`,
`instance_encounters`, `areatrigger_teleport`, `playercreateinfo` and the spawn and event tables into compact JSON:

- loot rows are turned into chances per kill, open or catch (groups, references and quest drops resolved);
- positions are converted to our zone maps and world map, using the World of Warcraft: Forever client's map data;
- names come from the Forever client where it has them (English and Spanish);
- lines that the Forever client contradicts or already gives (items it does not have or retired, vendor lines its own
  vendor list has, quests its quest data covers) are left out, and instances Forever reworked are marked;
- quests are kept only when the Forever client lists them, with who gives and takes them, their chains, objectives and
  rewards (`quests.json`); the site's build also derives each instance's quests and access (keys, attunements), each
  zone's rares, elites and quest hubs, where each race starts, and the Classic stats of the items the Forever client
  withholds, from the same tables.

9,163 statements were applied to the kept tables; 0 could not be applied.

These files are a modified version of that database (converted from the commit of 2026-09-22, against the
Forever client build 1.60.1.70205) and are licensed under the same licence, GPL-3.0: you may copy, change and share them
under its terms. They are plain JSON, the form we work on them in; the unmodified database is the repository above at
the commit above. They come WITHOUT ANY WARRANTY (sections 15 and 16 of the licence). This is Classic data: it may
differ in World of Warcraft: Forever. The site shows it with a "Classic" tag whose help says it may differ in Forever,
and credits it at https://forever-codex.com/sources/#src-cmangos.

Other data files of the site carry parts of this data too (for example the Classic source lines of the item database
in `/data/items/` and the world map's service layer); those parts are licensed GPL-3.0 as well, and the files name
this source in a `cdb` or `src` header field.
