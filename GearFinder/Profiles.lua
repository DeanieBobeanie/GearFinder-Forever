local _, G = ...
G.classIDs = { WARRIOR=1, PALADIN=2, HUNTER=3, ROGUE=4, PRIEST=5, SHAMAN=7, MAGE=8, WARLOCK=9, DRUID=11 }
G.slots = {
    {1,"Head"}, {2,"Neck"}, {3,"Shoulders"}, {15,"Back"}, {5,"Chest"}, {9,"Wrists"},
    {10,"Hands"}, {6,"Waist"}, {7,"Legs"}, {8,"Feet"}, {11,"Ring 1"}, {12,"Ring 2"},
    {13,"Trinket 1"}, {14,"Trinket 2"}, {16,"Main hand"}, {17,"Off hand"}, {18,"Ranged / relic"},
}
G.statNames = { [0]="Mana", [1]="Health", [3]="Agility", [4]="Strength", [5]="Intellect", [6]="Spirit", [7]="Stamina",
    [12]="Defense", [13]="Dodge rating", [14]="Parry rating", [15]="Block rating",
    [16]="Melee hit", [17]="Ranged hit", [18]="Spell hit", [19]="Melee crit", [20]="Ranged crit",
    [21]="Spell crit", [31]="Hit", [32]="Crit", [36]="Haste", [37]="Expertise", [38]="Attack power",
    [39]="Ranged attack power", [41]="Healing", [42]="Spell damage", [43]="Mana per 5 sec",
    [45]="Spell power", [48]="Block value", [50]="Bonus armor", [83]="Physical damage", [84]="Holy damage",
    [85]="Fire damage", [86]="Nature damage", [87]="Frost damage", [88]="Shadow damage", [89]="Arcane damage",
    armor="Armor", meleeDPS="Melee DPS", rangedDPS="Ranged DPS" }
-- These are editable heuristics for leveling. They are not simulation results.
local caster = { [5]=1, [6]=0.35, [7]=0.2, [45]=1.5, [42]=1.5, [18]=1.2, [21]=0.9, [31]=1.2, [32]=0.9, [43]=1, rangedDPS=0.75 }
local healer = { [5]=1, [6]=0.8, [7]=0.2, [41]=1.6, [45]=1.6, [43]=3, [21]=0.6, [32]=0.6, rangedDPS=0.4 }
local strength = { [4]=2, [3]=1.1, [7]=0.35, [38]=1, [16]=1.5, [19]=1.2, [31]=1.5, [32]=1.2, [37]=1.2, meleeDPS=7 }
local agility = { [3]=2, [4]=1, [7]=0.3, [38]=1, [16]=1.5, [19]=1.3, [31]=1.5, [32]=1.3, [37]=1.2, meleeDPS=7 }
local tank = { [7]=2, [4]=0.8, [3]=0.9, [38]=0.35, [12]=1.7, [13]=1.4, [14]=1.4, [15]=1.2, armor=0.035, meleeDPS=2 }
local hunter = { [3]=2, [7]=0.3, [5]=0.3, [38]=1, [39]=1, [17]=1.5, [20]=1.3, [31]=1.5, [32]=1.3, rangedDPS=7 }
local cat = { [3]=2, [4]=2, [7]=0.3, [38]=1, [16]=1.5, [19]=1.3, [31]=1.5, [32]=1.3 }
local bear = { [7]=2.5, [3]=1.2, [4]=0.9, [38]=0.4, [12]=1.5, [13]=1.5, armor=0.08 }
local function schools(values)
    local weights={}
    for key,value in pairs(caster) do weights[key]=value end
    for key,value in pairs(values) do weights[key]=value end
    return weights
end
G.profiles, G.profileOrder = {}, {}
local function add(class, label, weights, weapon)
    local id = class .. ":" .. label
    G.profiles[id] = {id=id, class=class, name=label, weights=weights, weapon=weapon or "any"}
    G.profileOrder[#G.profileOrder+1] = id
end
add("WARRIOR", "Arms", strength, "two")
add("WARRIOR", "Fury", strength, "dual")
add("WARRIOR", "Protection", tank, "shield")
add("PALADIN", "Retribution", strength, "two")
add("PALADIN", "Holy", healer)
add("PALADIN", "Protection", tank, "shield")
add("HUNTER", "Beast Mastery", hunter)
add("HUNTER", "Marksmanship", hunter)
add("HUNTER", "Survival", hunter)
add("ROGUE", "Combat", agility, "dual")
add("ROGUE", "Assassination", agility, "daggers")
add("ROGUE", "Subtlety", agility, "dual")
add("PRIEST", "Shadow", schools({[88]=1.5}))
add("PRIEST", "Discipline", healer)
add("PRIEST", "Holy", healer)
add("SHAMAN", "Enhancement", strength, "two")
add("SHAMAN", "Elemental", schools({[86]=1.5,[85]=0.35}))
add("SHAMAN", "Restoration", healer)
add("SHAMAN", "Tank", tank, "shield")
add("MAGE", "Frost", schools({[87]=1.5}))
add("MAGE", "Fire", schools({[85]=1.5}))
add("MAGE", "Arcane", schools({[89]=1.5}))
add("WARLOCK", "Affliction", schools({[88]=1.5}))
add("WARLOCK", "Demonology", schools({[88]=1.1,[85]=0.6}))
add("WARLOCK", "Destruction", schools({[85]=1.3,[88]=0.7}))
add("DRUID", "Feral cat", cat)
add("DRUID", "Feral bear", bear, "two")
add("DRUID", "Balance", schools({[86]=0.9,[89]=0.9}))
add("DRUID", "Restoration", healer)
G.weapons = {
    WARRIOR={0,1,2,3,4,5,6,7,8,10,13,15,16,18}, PALADIN={0,1,4,5,6,7,8},
    HUNTER={0,1,2,3,6,7,8,10,13,15,18}, ROGUE={0,2,3,4,7,13,15,16,18},
    PRIEST={4,10,15,19}, SHAMAN={0,1,4,5,10,13,15}, MAGE={7,10,15,19},
    WARLOCK={7,10,15,19}, DRUID={4,5,6,10,13,15},
}
G.professionIDs = {blacksmithing=164, leatherworking=165, tailoring=197, engineering=202, enchanting=333, alchemy=171}
G.professionSpells = {blacksmithing=2018, leatherworking=2108, tailoring=3908, engineering=4036, enchanting=7411, alchemy=2259}
