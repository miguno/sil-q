# Sil-Q World Model

This document presents an entity-relationship model for the Sil-Q game world,
based on information from data files (`lib/edit/*.txt`) and hardcoded behavior
(`src/*.c`).

## Entity Diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Monster   │     │    Item     │     │   Terrain   │
│             │     │             │     │             │
│ • id        │     │ • id        │     │ • id        │
│ • name      │     │ • name      │     │ • name      │
│ • symbol    │     │ • tval/sval │     │ • symbol    │
│ • flags     │     │ • flags     │     │ • flags     │
│ • attacks   │     │ • stats     │     │ • mimic     │
│ • spells    │     │             │     │             │
└──────┬──────┘     └──────┬──────┘     └─────────────┘
       │                   │
       │                   ├──────────────┬──────────────┐
       │                   │              │              │
       │            ┌──────┴──────┐ ┌─────┴─────┐ ┌──────┴──────┐
       │            │  Artefact   │ │  Special  │ │   Flavor    │
       │            │             │ │  (Suffix) │ │             │
       │            │ • base_item │ │ • name    │ │ • tval      │
       │            │ • abilities │ │ • flags   │ │ • color     │
       │            └─────────────┘ └───────────┘ └─────────────┘
       │
┌──────┴──────┐     ┌─────────────┐     ┌─────────────┐
│  MonsterType│     │   Ability   │     │    Skill    │
│             │     │             │     │             │
│ • ORC       │     │ • id        │     │ • id (0-7)  │
│ • TROLL     │     │ • name      │     │ • name      │
│ • DRAGON    │◄────│ • skill     │◄────│ • abilities │
│ • etc.      │     │ • prereqs   │     │             │
└─────────────┘     └─────────────┘     └─────────────┘

┌─────────────┐     ┌─────────────┐
│    Race     │────►│    House    │
│             │     │             │
│ • id (0-3)  │     │ • id        │
│ • name      │     │ • name      │
│ • stats     │     │ • stats     │
│ • flags     │     │ • affinity  │
│ • equipment │     │             │
└─────────────┘     └─────────────┘
```

---

## Core Entities

### 1. Monster

Represents all creature types in the game, including the player.

**Source:** `lib/edit/monster.txt`

| Attribute       | Type   | Description                 |
| --------------- | ------ | --------------------------- |
| id              | int    | Unique identifier (N: line) |
| name            | string | Monster name                |
| symbol          | char   | ASCII display character     |
| color           | string | Display color code          |
| depth           | int    | Native dungeon depth        |
| rarity          | int    | Generation rarity (1 in N)  |
| speed           | int    | Speed modifier              |
| health_dice     | string | Health as "XdY"             |
| mana            | int    | Mana pool                   |
| light_radius    | int    | Light emission radius       |
| sleepiness      | int    | Base sleep value            |
| perception      | int    | Perception score            |
| stealth         | int    | Stealth score               |
| will            | int    | Will score                  |
| evasion         | int    | Evasion bonus               |
| protection_dice | string | Protection as "XdY"         |
| description     | text   | Flavor text                 |

**Relationships:**

- Has many **MonsterAttack** (up to 4)
- Has many **MonsterSpell**
- Has many **MonsterFlag**
- Belongs to **MonsterType** categories (ORC, TROLL, DRAGON, etc.)

**Hardcoded Extensions:**

- `is_morgoth` - Has progressive difficulty system
- `is_quest_monster` - Part of thrall quest system
- `is_unique` - Can only exist once
- `special_placement_depth` - Override generation depth

---

### 2. MonsterAttack

Individual attack definitions for monsters.

| Attribute    | Type   | Description                      |
| ------------ | ------ | -------------------------------- |
| monster_id   | int    | Foreign key to Monster           |
| slot         | int    | Attack slot (0-3)                |
| method       | string | Attack method (`RBM_*` constant) |
| effect       | string | Attack effect (`RBE_*` constant) |
| attack_bonus | int    | To-hit modifier                  |
| damage_dice  | string | Damage as "XdY"                  |

**Attack Methods:** HIT, TOUCH, CLAW, BITE, STING, PECK, WHIP, CRUSH, ENGULF,
CRAWL, THORN, SPORE

**Attack Effects:** HURT, WOUND, BATTER, SHATTER, POISON, ACID, ELEC, FIRE,
COLD, BLIND, CONFUSE, TERRIFY, ENTRANCE, HALLU, DISEASE, SLOW, DARK, HUNGER,
LOSE_STR, LOSE_DEX, LOSE_CON, LOSE_GRA, LOSE_ALL, UN_BONUS, UN_POWER, LOSE_MANA,
EAT_ITEM, EAT_FOOD, DISARM

---

### 3. MonsterSpell

Spell/special ability definitions for monsters.

| Attribute  | Type   | Description            |
| ---------- | ------ | ---------------------- |
| monster_id | int    | Foreign key to Monster |
| spell_type | string | RF4\_\* constant       |
| frequency  | int    | Cast percentage        |
| power      | int    | Spell power/damage     |

**Spell Types:** ARROW1, ARROW2, BOULDER, BRTH_FIRE, BRTH_COLD, BRTH_POIS,
BRTH_DARK, EARTHQUAKE, SHRIEK, SCREECH, DARKNESS, FORGET, SCARE, CONF, HOLD,
SLOW, HATCH_SPIDER, DIM, SNG_BINDING, SNG_PIERCING, SNG_OATHS, THROW_WEB, RALLY

---

### 4. Item (Object Kind)

Base item types - weapons, armor, consumables, etc.

**Source:** `lib/edit/object.txt`

| Attribute       | Type   | Description                      |
| --------------- | ------ | -------------------------------- |
| id              | int    | Unique identifier                |
| name            | string | Item name (with & and ~ markers) |
| symbol          | char   | ASCII display character          |
| color           | string | Display color                    |
| tval            | int    | Type value (category)            |
| sval            | int    | Subtype value                    |
| pval            | int    | Power value                      |
| depth           | int    | Native depth                     |
| rarity          | int    | Generation rarity                |
| weight          | int    | Weight in 0.1 lb units           |
| cost            | int    | Base value                       |
| attack_bonus    | int    | To-hit modifier                  |
| damage_dice     | string | Damage as "XdY"                  |
| evasion_bonus   | int    | Evasion modifier                 |
| protection_dice | string | Protection as "XdY"              |
| description     | text   | Flavor text                      |

**Relationships:**

- Has many **ItemFlag**
- Has many **ItemAllocation** (depth/rarity pairs)
- May have **Flavor** (for unidentified items)
- May be base for **Artefact**
- May receive **Special** suffixes

**Hardcoded Extensions:**

- `is_silmaril` - Primary quest item
- `has_special_timeout` - Custom light drain
- `smithing_restrictions` - JSON of modification limits

---

### 5. Artefact

Unique items with fixed properties.

**Source:** `lib/edit/artefact.txt`

| Attribute       | Type   | Description                       |
| --------------- | ------ | --------------------------------- |
| id              | int    | Artifact index                    |
| name            | string | Artifact name (e.g., "Glamdring") |
| base_item_id    | int    | Foreign key to Item (tval/sval)   |
| attack_bonus    | int    | To-hit modifier                   |
| damage_dice     | string | Damage override                   |
| evasion_bonus   | int    | Evasion modifier                  |
| protection_dice | string | Protection override               |
| pval            | int    | Power value                       |
| description     | text   | Lore text                         |

**Relationships:**

- Belongs to **Item** (base type)
- Has many **ArtefactFlag**

---

### 6. Special (Item Suffix)

Magical suffixes that can be applied to base items.

**Source:** `lib/edit/special.txt`

| Attribute      | Type   | Description                       |
| -------------- | ------ | --------------------------------- |
| id             | int    | Suffix identifier                 |
| name           | string | Suffix name (e.g., "of Gondolin") |
| extra_type     | int    | Random bonus type                 |
| extra_value    | int    | Random bonus max                  |
| depth          | int    | Minimum generation depth          |
| rarity         | int    | Generation rarity                 |
| weight_mod     | int    | Weight modifier                   |
| cost_mod       | int    | Cost modifier                     |
| attack_mod     | int    | Attack bonus                      |
| damage_mod     | string | Damage modifier                   |
| evasion_mod    | int    | Evasion modifier                  |
| protection_mod | string | Protection modifier               |

**Relationships:**

- Has many **SpecialApplicable** (tval/sval ranges)
- Has many **SpecialFlag**

---

### 7. Flavor

Visual "flavors" for unidentified items.

**Source:** `lib/edit/flavor.txt`

| Attribute | Type   | Description                          |
| --------- | ------ | ------------------------------------ |
| id        | int    | Flavor identifier                    |
| tval      | int    | Applicable item type                 |
| sval      | int    | Fixed sval (optional, for artifacts) |
| symbol    | char   | Display character                    |
| color     | string | Display color                        |
| name      | string | Flavor name (e.g., "Amethyst")       |

**Flavor Categories:**

- Rings (tval 45): Gemstones, metals
- Amulets (tval 40): Materials, metals
- Staves (tval 55): Wood types
- Horns (tval 66): Materials
- Herbs (tval 80): Colors
- Flasks (tval 81): Colors
- Potions (tval 75): Colors, descriptions

---

### 8. Terrain

Dungeon terrain features.

**Source:** `lib/edit/terrain.txt`

| Attribute   | Type   | Description                         |
| ----------- | ------ | ----------------------------------- |
| id          | int    | Feature identifier (FEAT\_\*)       |
| name        | string | Feature name                        |
| symbol      | char   | ASCII display character             |
| color       | string | Display color                       |
| mimic_id    | int    | Feature to mimic (for hidden traps) |
| description | text   | Description                         |

**Relationships:**

- Has many **TerrainFlag**

**Key Features:**

- Floors, walls, permanent walls
- Doors (open, closed, locked, jammed)
- Stairs (up, down)
- Traps (various types)
- Chasms, rubble, water
- Wards (FEAT_WARDED, FEAT_WARDED2, FEAT_WARDED3)

---

### 9. Race

Player races.

**Source:** `lib/edit/race.txt`

| Attribute     | Type   | Description           |
| ------------- | ------ | --------------------- |
| id            | int    | Race identifier (0-3) |
| name          | string | Race name             |
| str_mod       | int    | Strength modifier     |
| dex_mod       | int    | Dexterity modifier    |
| con_mod       | int    | Constitution modifier |
| gra_mod       | int    | Grace modifier        |
| history_start | int    | History table start   |
| age_base      | int    | Base age              |
| age_max       | int    | Maximum age           |
| height        | int    | Base height           |
| height_mod    | int    | Height modifier       |
| weight        | int    | Base weight           |
| weight_mod    | int    | Weight modifier       |
| colors        | string | Tile color indices    |
| description   | text   | Race description      |

**Relationships:**

- Has many **RaceFlag**
- Has many **RaceEquipment** (starting items)
- Has many **House** (available houses)

**Races:**

| ID  | Name    | Stats       | Flags                                      |
| --- | ------- | ----------- | ------------------------------------------ |
| 0   | Noldor  | 0/+1/+2/+2  | BOW_PROFICIENCY, SNG_AFFINITY              |
| 1   | Sindar  | -1/+1/+2/+1 | BOW_PROFICIENCY, SNG_AFFINITY              |
| 2   | Naugrim | 0/-1/+3/+1  | AXE_PROFICIENCY, ARC_PENALTY, SMT_AFFINITY |
| 3   | Edain   | 0/0/0/0     | (none)                                     |

---

### 10. House

Player houses (sub-groups within races).

**Source:** `lib/edit/house.txt`

| Attribute   | Type   | Description        |
| ----------- | ------ | ------------------ |
| id          | int    | House identifier   |
| name        | string | Full house name    |
| alt_name    | string | Alternate form     |
| short_name  | string | Abbreviated name   |
| str_mod     | int    | Strength bonus     |
| dex_mod     | int    | Dexterity bonus    |
| con_mod     | int    | Constitution bonus |
| gra_mod     | int    | Grace bonus        |
| description | text   | House description  |

**Relationships:**

- Has **HouseFlag** (affinity)
- Belongs to **Race** (implicitly via availability)

**Houses:**

- **Noldor:** Feanor (SMT), Fingolfin (WIL), Finarfin (PER)
- **Sindar:** Doriath (SNG), Falas (ARC)
- **Naugrim:** Nogrod (SMT), Belegost (WIL)
- **Edain:** Beor (EVN), Haleth (STL), Hador (MEL)

---

### 11. Skill

The eight primary skill categories.

| Attribute | Type   | Description       |
| --------- | ------ | ----------------- |
| id        | int    | Skill index (0-7) |
| name      | string | Skill name        |
| stat      | string | Governing stat    |

**Skills:**

| ID  | Name       | Stat    |
| --- | ---------- | ------- |
| 0   | Melee      | Str/Dex |
| 1   | Archery    | Dex     |
| 2   | Evasion    | Dex     |
| 3   | Stealth    | Dex     |
| 4   | Perception | Gra     |
| 5   | Will       | Gra     |
| 6   | Smithing   | Gra     |
| 7   | Song       | Gra     |

---

### 12. Ability

Learnable player abilities within skill trees.

**Source:** `lib/edit/ability.txt`

| Attribute   | Type   | Description        |
| ----------- | ------ | ------------------ |
| id          | int    | Ability identifier |
| name        | string | Ability name       |
| skill_id    | int    | Skill tree (0-7)   |
| position    | int    | Position in tree   |
| level_req   | int    | Level requirement  |
| description | text   | Effect description |

**Relationships:**

- Belongs to **Skill**
- Has many **AbilityPrerequisite**
- Has many **AbilitySmithable** (tval/sval ranges)

**Hardcoded Effects:** Many abilities have effects implemented in C code,
including:

- MEL_FINESSE, MEL_POWER: Critical hit modifiers
- MEL_POLEARMS: +2 bonus with polearms
- WIL_CHANNELING: Staff charge efficiency
- Various combat triggers and passive effects

---

## Flag Entities

### MonsterFlag

| Category | Examples                                               |
| -------- | ------------------------------------------------------ |
| RF1      | UNIQUE, QUESTOR, MALE, FEMALE, RAND*25, DROP*\*        |
| RF2      | MINDLESS, SMART, FLYING, PASS_WALL, CHARGE, KNOCK_BACK |
| RF3      | ORC, TROLL, DRAGON, UNDEAD, RES\*\*, NO\*\*            |
| RF4      | Spells and abilities                                   |

### ItemFlag

| Category | Examples                                 |
| -------- | ---------------------------------------- |
| TR1      | Stats (STR, DEX), Slays, Brands          |
| TR2      | Sustains, Resistances, Abilities, Curses |
| TR3      | Misc (MITHRIL, TWO_HANDED, CURSED)       |

### TerrainFlag

PASSABLE, FLOOR, WALL, PERMANENT, LOS, PROJECT, DOOR, TRAP, etc.

### RaceHouseFlag (RHF\_\*)

BOW_PROFICIENCY, AXE_PROFICIENCY, \_\_AFFINITY, \_\_PENALTY

---

## Type Value (tval) Reference

| tval | Category   | sval Range |
| ---- | ---------- | ---------- |
| 19   | Bows       | 0-99       |
| 20   | Digging    | 0-99       |
| 21   | Hafted     | 0-99       |
| 22   | Polearms   | 0-99       |
| 23   | Swords     | 0-99       |
| 30   | Boots      | 0-99       |
| 31   | Gloves     | 0-99       |
| 32   | Helms      | 0-99       |
| 34   | Shields    | 0-99       |
| 35   | Cloaks     | 0-99       |
| 36   | Soft Armor | 0-99       |
| 37   | Mail       | 0-99       |
| 39   | Lights     | 0-99       |
| 40   | Amulets    | 0-99       |
| 45   | Rings      | 0-99       |
| 55   | Staves     | 0-99       |
| 66   | Horns      | 0-99       |
| 75   | Potions    | 0-99       |
| 80   | Food/Herbs | 0-99       |
| 81   | Flasks     | 0-99       |
| 90   | Arrows     | 0-99       |
| 91   | Chests     | 0-99       |
| 100  | Metal      | 0-99       |
| 101  | Useless    | 0-99       |

---

## Tile Mapping

**Source:** `lib/pref/graf-tiles.prf`, `lib/pref/flvr-tiles.prf`

Entities are mapped to tile coordinates in the format:

```
R:monster_id:0xYY:0xXX
K:item_id:0xYY:0xXX
F:feature_id:0xYY:0xXX
L:flavor_id:0xYY:0xXX
```

Where `0xYY = 0x80 + row` and `0xXX = 0x80 + column` in the tileset image.

**Player Tiles:** 4 races × 16 equipment states = 64 player tiles

| Race    | Base Tile |
| ------- | --------- |
| Noldor  | 0x8D/0x80 |
| Sindar  | 0x8D/0x90 |
| Naugrim | 0x8E/0x80 |
| Edain   | 0x8E/0x90 |

**Equipment States (offsets 0-15):**

| Offset | Equipment Configuration           |
| ------ | --------------------------------- |
| 0      | Unarmed/default                   |
| 1      | Small sword (dagger, short sword) |
| 2      | Curved sword                      |
| 3      | Big sword or shovel               |
| 4      | Spear                             |
| 5      | Small axe/war hammer/mattock      |
| 6      | Big axe                           |
| 7      | Quarterstaff                      |
| 8      | Shield + any weapon               |
| 9      | Shield + big axe                  |
| 10     | Shield + small axe                |
| 11     | Dual wielding swords              |
| 12     | Sword + axe offhand               |
| 13     | Axe + sword offhand               |
| 14     | Axe + axe dual wield              |
| 15     | Bow (archery > melee)             |

Player tile coordinate = base_tile + equipment_offset (in the column)

---

## Special Systems

### Quest System

Thrall rescue quests with hardcoded:

- Quest requirements
- Ability rewards
- Completion tracking

### Morgoth System

Progressive difficulty with 5 states:

- Stats change based on player actions
- Truce system for initial encounter
- Silmaril removal triggers

### Smithing System

Item modification with:

- Type-specific caps
- Difficulty calculations
- Material requirements

---

## Database Schema Implications

Based on this model, a DB schema should include the following tables.

Core Tables:

- `monsters` - Monster definitions
- `monster_attacks` - Attack details
- `monster_spells` - Spell capabilities
- `monster_flags` - Flag assignments
- `items` - Base item definitions
- `item_flags` - Flag assignments
- `item_allocations` - Depth/rarity pairs
- `artefacts` - Unique item definitions
- `specials` - Item suffix definitions
- `special_applicables` - tval/sval ranges
- `flavors` - Visual flavors
- `terrain` - Terrain features
- `terrain_flags` - Flag assignments
- `races` - Player races
- `race_equipment` - Starting items
- `houses` - Player houses
- `skills` - Skill categories
- `abilities` - Learnable abilities
- `ability_prerequisites` - Prerequisite chains
- `ability_smithables` - Items that can receive ability

Reference Tables:

- `tvals` - Type value definitions
- `flag_categories` - RF1, RF2, TR1, etc.
- `flags` - All flag definitions

Tile Tables:

- `monster_tiles` - Monster tile mappings
- `item_tiles` - Item tile mappings
- `feature_tiles` - Terrain tile mappings
- `flavor_tiles` - Flavor tile mappings
- `player_tiles` - Player race/equipment tiles

Metadata:

- `db_version` - Schema version
- `source_commit` - Git commit of source data
