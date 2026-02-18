# Sil-Q World Model

This document is an entity-relationship model of the Sil-Q game world. Its
purpose is to prepare a possible database of game entities, for example for a
website where players can browse and query items, monsters, and so on.

It summarizes information from the other developer documents. They are the
reference; this document only collects the facts that a database needs:

- Data file formats: [data_files.md](data_files.md)
- Hardcoded behavior: [code_base.md](code_base.md)
- Tiles: [rendering.md](rendering.md)

## Entity diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Monster   │     │ Object kind │     │   Terrain   │
│ • id        │     │ • id        │     │ • id        │
│ • name      │     │ • name      │     │ • name      │
│ • symbol    │     │ • tval/sval │     │ • symbol    │
│ • flags     │     │ • flags     │     │ • mimic     │
│ • blows     │     │ • abilities │     └─────────────┘
│ • spells    │     │ • stats     │
└─────────────┘     └──────┬──────┘
                           │ tval/sval
          ┌────────────────┼────────────────┐
   ┌──────┴──────┐  ┌──────┴──────┐  ┌──────┴──────┐
   │  Artefact   │  │   Special   │  │   Flavor    │
   │ • base item │  │ • name      │  │ • tval      │
   │ • abilities │  │ • tval/sval │  │ • sval?     │
   │ • flags     │  │   ranges    │  │ • color     │
   └─────────────┘  │ • abilities │  └─────────────┘
                    └─────────────┘

┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    Race     │────►│    House    │     │    Skill    │
│ • id (0-3)  │     │ • id        │     │ • id (0-7)  │
│ • stats     │     │ • stats     │     └──────┬──────┘
│ • flags     │     │ • flag      │            │
│ • equipment │     └─────────────┘     ┌──────┴──────┐
└─────────────┘                         │   Ability   │
                                        │ • prereqs   │
   Object kinds, artefacts and          │ • smithable │
   specials can grant abilities.        │   tval/sval │
                                        └─────────────┘
```

## Core entities

### Monster

All monster races. Records 0–3 are the player (one per race).

Source: `lib/edit/monster.txt`

| Attribute       | Type   | Source line | Description                 |
| --------------- | ------ | ----------- | --------------------------- |
| id              | int    | `N`         | Unique identifier           |
| name            | string | `N`         | Monster name                |
| depth           | int    | `W`         | Native depth (also sets XP) |
| rarity          | int    | `W`         | 1 in N                      |
| symbol          | char   | `G`         | ASCII character             |
| color           | string | `G`         | Color code                  |
| speed           | int    | `I`         | 1–4                         |
| health_dice     | string | `I`         | `XdY`                       |
| light_radius    | int    | `I`         | Negative = darkness         |
| sleepiness      | int    | `A`         | Max initial sleep           |
| perception      | int    | `A`         |                             |
| stealth         | int    | `A`         |                             |
| will            | int    | `A`         |                             |
| evasion         | int    | `P`         |                             |
| protection_dice | string | `P`         | `XdY`                       |
| spell_pct       | int    | `S`         | Chance to cast per turn (%) |
| spell_power     | int    | `S`         |                             |
| description     | text   | `D`         |                             |

Relationships:

- Has 0–4 **MonsterBlow**.
- Has many **MonsterSpell** (spell types).
- Has many **MonsterFlag**. Type flags (`ORC`, `TROLL`, `DRAGON`, ...) give the
    monster type.

Hardcoded extensions (not in the data file):

- `is_player`: IDs 0–3.
- `is_morgoth`: progressive difficulty and truce.
- `is_quest_monster`: thralls and the orc thrallmaster.
- `vault_letter`: monsters that vaults place by letter (e.g., Carcharoth `C`,
    Gothmog `R`).

### MonsterBlow

| Attribute    | Type   | Description        |
| ------------ | ------ | ------------------ |
| monster_id   | int    | Foreign key        |
| slot         | int    | 0–3                |
| method       | string | `RBM_*`            |
| effect       | string | `RBE_*` (optional) |
| attack_bonus | int    |                    |
| damage_dice  | string | `XdY` (optional)   |

Methods: HIT, TOUCH, CLAW, BITE, STING, PECK, WHIP, CRUSH, ENGULF, CRAWL, THORN,
SPORE.

Effects: HURT, WOUND, BATTER, SHATTER, UN_BONUS, UN_POWER, LOSE_MANA, SLOW,
EAT_ITEM, EAT_FOOD, DARK, HUNGER, POISON, ACID, ELEC, FIRE, COLD, BLIND,
CONFUSE, TERRIFY, ENTRANCE, HALLU, DISEASE, LOSE_STR, LOSE_DEX, LOSE_CON,
LOSE_GRA, LOSE_STR_CON, LOSE_ALL, DISARM.

### MonsterSpell

| Attribute  | Type   | Description |
| ---------- | ------ | ----------- |
| monster_id | int    | Foreign key |
| spell_type | string | `RF4_*`     |

Spell types: ARROW1, ARROW2, BOULDER, BRTH_FIRE, BRTH_COLD, BRTH_POIS,
BRTH_DARK, EARTHQUAKE, SHRIEK, SCREECH, DARKNESS, FORGET, SCARE, CONF, HOLD,
SLOW, HATCH_SPIDER, DIM, SNG_BINDING, SNG_PIERCING, SNG_OATHS, THROW_WEB, RALLY.

### Object kind (item)

Base item types: weapons, armour, consumables, etc.

Source: `lib/edit/object.txt`

| Attribute       | Type   | Source line | Description             |
| --------------- | ------ | ----------- | ----------------------- |
| id              | int    | `N`         |                         |
| name            | string | `N`         | With `&` and `~` tokens |
| symbol          | char   | `G`         |                         |
| color           | string | `G`         | `d` = flavor color      |
| tval            | int    | `I`         | Type                    |
| sval            | int    | `I`         | Subtype                 |
| pval            | int    | `I`         |                         |
| depth           | int    | `W`         |                         |
| weight          | int    | `W`         | 0.1 lb                  |
| cost            | int    | `W`         |                         |
| attack_bonus    | int    | `P`         |                         |
| damage_dice     | string | `P`         | `XdY`                   |
| evasion_bonus   | int    | `P`         |                         |
| protection_dice | string | `P`         | `XdY`                   |
| description     | text   | `D`         |                         |

Relationships:

- Has many **ItemFlag**.
- Has many **ItemAllocation** (`A:` depth/rarity pairs).
- Has many **Ability** grants (`B:` lines).
- Has a **Flavor** if it is a ring, amulet, staff, horn, potion or herb.
- Can be the base of an **Artefact** or a **Special** item.

Hardcoded extensions:

- Effects of herbs, potions, staves and horns (by sval).
- Light radius of light sources.
- Smithing limits per item type.

### Artefact

Source: `lib/edit/artefact.txt`

| Attribute       | Type   | Source line | Description         |
| --------------- | ------ | ----------- | ------------------- |
| id              | int    | `N`         |                     |
| name            | string | `N`         | E.g., "'Glamdring'" |
| symbol, color   |        | `G`         | Optional override   |
| tval, sval      | int    | `I`         | Base object kind    |
| pval            | int    | `I`         |                     |
| depth, rarity   | int    | `W`         |                     |
| weight, cost    | int    | `W`         |                     |
| attack_bonus    | int    | `P`         |                     |
| damage_dice     | string | `P`         |                     |
| evasion_bonus   | int    | `P`         |                     |
| protection_dice | string | `P`         |                     |
| description     | text   | `D`         |                     |

Relationships: belongs to an **Object kind** (tval/sval); has many **ItemFlag**
and **Ability** grants.

### Special (item suffix)

"of Gondolin", "of Free Action", etc.

Source: `lib/edit/special.txt`

| Attribute        | Type   | Source line | Description            |
| ---------------- | ------ | ----------- | ---------------------- |
| id               | int    | `N`         |                        |
| name             | string | `N`         |                        |
| max_attack       | int    | `C`         |                        |
| damage_dice      | int    | `C`         | Extra damage dice      |
| damage_sides     | int    | `C`         | Extra damage sides     |
| max_evasion      | int    | `C`         |                        |
| protection_dice  | int    | `C`         | Extra protection dice  |
| protection_sides | int    | `C`         | Extra protection sides |
| pval             | int    | `C`         | Max pval               |
| depth            | int    | `W`         |                        |
| rarity           | int    | `W`         |                        |
| max_depth        | int    | `W`         |                        |
| cost             | int    | `W`         |                        |

Relationships: has 1–4 **SpecialApplicable** (`T:` tval and sval range); has
many **ItemFlag** and **Ability** grants.

### Flavor

Unidentified looks of items.

Source: `lib/edit/flavor.txt`

| Attribute | Type   | Description            |
| --------- | ------ | ---------------------- |
| id        | int    |                        |
| tval      | int    |                        |
| sval      | int    | Only for fixed flavors |
| symbol    | char   |                        |
| color     | string |                        |
| name      | string | E.g., "Amethyst"       |

Flavor tvals: amulets (40), rings (45), staves (55), horns (66), potions (75),
herbs (80), and Easter herb flavors (81). The game assigns random flavors per
game, so a database can only show the list of possible flavors.

### Terrain

Source: `lib/edit/terrain.txt`

| Attribute | Type   | Description                         |
| --------- | ------ | ----------------------------------- |
| id        | int    | `FEAT_*` value                      |
| name      | string |                                     |
| symbol    | char   |                                     |
| color     | string |                                     |
| mimic_id  | int    | Feature to look like (hidden traps) |

The data file has no flags and no descriptions. All terrain behavior is
hardcoded by feature ID: floors, walls, doors, traps, stairs and shafts, forges
(uses encoded in the ID), chasm, rubble, sunlight, glyph, warded doors.

### Race

Source: `lib/edit/race.txt`

| Attribute           | Type   | Description               |
| ------------------- | ------ | ------------------------- |
| id                  | int    | 0–3                       |
| name                | string |                           |
| str/dex/con/gra_mod | int    | Stat modifiers            |
| history_start       | int    | First `history.txt` chart |
| age_base, age_max   | int    |                           |
| height, height_mod  | int    |                           |
| weight, weight_mod  | int    |                           |
| description         | text   |                           |

Relationships: has many **RaceFlag**, **RaceEquipment** (starting items: tval,
sval, min, max), and **House** (`C:` line).

| ID  | Name    | Stats (S/D/C/G) | Flags                                      |
| --- | ------- | --------------- | ------------------------------------------ |
| 0   | Noldor  | 0/+1/+2/+2      | BOW_PROFICIENCY, SNG_AFFINITY              |
| 1   | Sindar  | −1/+1/+2/+1     | BOW_PROFICIENCY, SNG_AFFINITY              |
| 2   | Naugrim | 0/−1/+3/+1      | AXE_PROFICIENCY, ARC_PENALTY, SMT_AFFINITY |
| 3   | Edain   | 0/0/0/0         | (none)                                     |

### House

Source: `lib/edit/house.txt`

| Attribute           | Type   | Description |
| ------------------- | ------ | ----------- |
| id                  | int    |             |
| name                | string |             |
| alt_name            | string |             |
| short_name          | string |             |
| str/dex/con/gra_mod | int    |             |
| description         | text   |             |

Relationships: has one **HouseFlag** (affinity); belongs to a **Race** via the
race's `C:` line. House 0 is "Houseless".

- **Noldor:** Feanor (SMT), Fingolfin (WIL), Finarfin (PER)
- **Sindar:** Doriath (SNG), Falathrim (ARC)
- **Naugrim:** Nogrod (SMT), Belegost (WIL)
- **Edain:** Beor (EVN), Haleth (STL), Hador (MEL)

### Skill

Hardcoded (`S_*` in `src/defines.h`).

| ID  | Name       | Stat bonus from |
| --- | ---------- | --------------- |
| 0   | Melee      | Dex             |
| 1   | Archery    | Dex             |
| 2   | Evasion    | Dex             |
| 3   | Stealth    | Dex             |
| 4   | Perception | Gra             |
| 5   | Will       | Gra             |
| 6   | Smithing   | Gra             |
| 7   | Song       | Gra             |

### Ability

Source: `lib/edit/ability.txt`

| Attribute   | Type   | Description            |
| ----------- | ------ | ---------------------- |
| id          | int    | `N:` number            |
| name        | string |                        |
| skill_id    | int    | 0–7                    |
| index       | int    | Index within the skill |
| level_req   | int    | Level requirement      |
| description | text   |                        |

Relationships: belongs to a **Skill**; has many **AbilityPrerequisite** (any one
is enough); has many **AbilitySmithable** (tval and sval range).

Many abilities have effects that are implemented only in C.

## Flags

| Entity     | Flag sets                                                                                                                                     |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Monster    | `RF1_*`, `RF2_*`, `RF3_*` (`RF4_*` are spells)                                                                                                |
| Item       | `TR1_*` (stats, skills, slays, brands), `TR2_*` (sustains, resistances, curses), `TR3_*` (misc, e.g., `MITHRIL`, `TWO_HANDED`, `LIGHT_CURSE`) |
| Race/House | `RHF_*` (proficiencies, affinities, penalties)                                                                                                |

The full lists are in [data_files.md](data_files.md).

## tval reference

| tval | Category       | tval | Category              |
| ---- | -------------- | ---- | --------------------- |
| 2    | Tutorial notes | 35   | Cloaks                |
| 3    | Skeletons      | 36   | Soft armour           |
| 4    | Mithril        | 37   | Mail                  |
| 7    | Chests         | 39   | Lights                |
| 17   | Arrows         | 40   | Amulets               |
| 19   | Bows           | 45   | Rings                 |
| 20   | Digging        | 55   | Staves                |
| 21   | Hafted         | 66   | Horns                 |
| 22   | Polearms       | 75   | Potions               |
| 23   | Swords         | 77   | Flasks                |
| 30   | Boots          | 80   | Herbs, food           |
| 31   | Gloves         | 81   | (Easter flavors only) |
| 32   | Helms          |      |                       |
| 33   | Crowns         |      |                       |
| 34   | Shields        |      |                       |

## Tile mapping

Source: `lib/pref/graf-tiles.prf`, `lib/pref/flvr-tiles.prf`

```
R:monster_id:0xYY/0xXX
K:object_id:0xYY/0xXX
F:feature_id:0xYY/0xXX
L:flavor_id:0xYY/0xXX
S:0xID:0xYY/0xXX
```

`0xYY = 0x80 + row` and `0xXX = 0x80 + column` in the 16×16 tileset
(`lib/xtra/graf/16x16_microchasm.png`). Some monsters also have a rage tile
(`R:id:rage:0xYY/0xXX`).

**Player tiles:** 4 races × 16 equipment states. The race's base tile is offset
0; the equipment state is added to the column.

| Race    | Base tile   |
| ------- | ----------- |
| Noldor  | `0x8D/0x80` |
| Sindar  | `0x8D/0x90` |
| Naugrim | `0x8E/0x80` |
| Edain   | `0x8E/0x90` |

The 16 equipment states are listed in [rendering.md](rendering.md#player-tiles).

## Special systems (hardcoded)

- **Thrall quest:** an alert human thrall asks for a light, an alert elf thrall
    for food. Reward: a herb of Rage or Terror, or map information; the elf
    thrall heals a badly hurt player instead.
- **Morgoth:** 5 difficulty states, a truce at arrival, and a crown with 0–3
    Silmarils (4 artefacts).
- **Smithing:** limits per item type, difficulty, forge bonus, mithril.

Details: [code_base.md](code_base.md).

## Database schema implications

A database based on this model could have these tables.

Core tables:

- `monsters`, `monster_blows`, `monster_spells`, `monster_flags`
- `items` (object kinds), `item_flags`, `item_allocations`, `item_abilities`
- `artefacts`, `artefact_flags`, `artefact_abilities`
- `specials`, `special_applicables`, `special_flags`, `special_abilities`
- `flavors`
- `terrain`
- `races`, `race_flags`, `race_equipment`, `race_houses`
- `houses`
- `skills`, `abilities`, `ability_prerequisites`, `ability_smithables`

Reference tables:

- `tvals`, `flag_categories`, `flags`

Tile tables:

- `monster_tiles`, `item_tiles`, `feature_tiles`, `flavor_tiles`, `player_tiles`

Metadata:

- `db_version`, `source_commit` (Git commit of the source data)
