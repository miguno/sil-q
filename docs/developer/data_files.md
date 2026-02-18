# Game Data Files

This document is the reference for the **format** of the game data files:

- **Edit files** (`lib/edit/*.txt`): define entities such as monsters, items,
    terrain, abilities and vaults.
- **Pref files** (`lib/pref/*.prf`): assign graphical tiles (and other visual
    settings) to entities.

It describes what each line and field means. It does not describe game mechanics
that are hardcoded in C; those are in [code_base.md](code_base.md). How the
engine draws tiles is in [rendering.md](rendering.md).

Each edit file also starts with a comment block that explains its format. If
this document and a file header disagree, the parser in `src/init1.c`
(`parse_*_info()`) is the source of truth.

## Common conventions (edit files)

- Lines starting with `#` are comments.
- Each file has a version stamp line: `V:1.5.1`.
- A record starts with an `N:` line (serial number and name). Serial numbers
    must increase.
- A line is a letter, `:`, and then values separated by `:`.
- Flags are separated by `|`. A record can have many `F:` lines.
- `D:` (description) lines can repeat. Each line is appended, so a line needs a
    leading or trailing space to separate words.
- Some numeric lines (e.g., `T:`, `E:`) have a trailing `# comment`.
- Abilities are referenced as `skill/ability` (e.g., `B:4/2` = skill 4, ability
    2; see `ability.txt`).

At startup the game converts each `.txt` file into a binary cache
`lib/data/<name>.raw` (see [code_base.md](code_base.md#edit-files-libedittxt)).

### Overview

| File           | Entities                 | Records | Limit (`limits.txt`) |
| -------------- | ------------------------ | ------- | -------------------- |
| `ability.txt`  | Player abilities         | 84      | 240 (`M:B`)          |
| `artefact.txt` | Artefacts                | 122     | 251 (`M:A`, total)   |
| `flavor.txt`   | Item flavors             | 108     | 310 (`M:L`)          |
| `history.txt`  | Character background     |         | 165 (`M:H`)          |
| `house.txt`    | Player houses            | 11      | 11 (`M:C`)           |
| `limits.txt`   | Array sizes              |         |                      |
| `monster.txt`  | Monsters and player      | 153     | 656 (`M:R`)          |
| `names.txt`    | Words for random names   |         |                      |
| `object.txt`   | Object kinds             | 196     | 600 (`M:K`)          |
| `race.txt`     | Player races             | 4       | 4 (`M:P`)            |
| `special.txt`  | Special items ("of ...") | 73      | 145 (`M:E`)          |
| `terrain.txt`  | Terrain features         | 84      | 86 (`M:F`)           |
| `vault.txt`    | Room and vault layouts   |         | 500 (`M:V`)          |

The limits are the maximum + 1. Changing them can break savefiles.

## Colors

`G:` lines use one color letter, optionally with a numeric suffix for extended
colors (e.g., `b1`, `v1`):

| Code | Color     | Code | Color       | Code | Color      | Code | Color       |
| ---- | --------- | ---- | ----------- | ---- | ---------- | ---- | ----------- |
| `d`  | Black     | `w`  | White       | `s`  | Gray       | `o`  | Orange      |
| `r`  | Red       | `g`  | Green       | `b`  | Blue       | `u`  | Brown       |
| `D`  | Dark Gray | `W`  | Light Gray  | `v`  | Violet     | `y`  | Yellow      |
| `R`  | Light Red | `G`  | Light Green | `B`  | Light Blue | `U`  | Light Brown |

In `object.txt`, `d` means "use the flavor's color".

## monster.txt

Defines all monster races. Records `N:0`–`N:3` are the player, one per race
(`<player>`).

```
N: serial number : monster name
W: depth : rarity
G: symbol : color
I: speed : health dice : light radius
A: sleepiness : perception : stealth : will
P: [evasion, protection dice]
B: method : effect : (attack bonus, damage dice)
S: SPELL_PCT_X | POW_Y
S: spell type | spell type | ...
F: flag | flag | ...
D: description
```

| Line | Meaning                                                                                                                       |
| ---- | ----------------------------------------------------------------------------------------------------------------------------- |
| `W`  | Native depth (must not be 0) and rarity (1 in N).                                                                             |
| `I`  | Speed (1–4 in use; see [code_base.md](code_base.md#speed-and-energy)), health dice `XdY`, light radius (negative = darkness). |
| `A`  | Max sleepiness, Perception, Stealth, Will. Sleepiness 0 = always starts alert.                                                |
| `P`  | Evasion and protection dice, e.g., `[+20,5d4]`.                                                                               |
| `B`  | Up to 4 blows. Effect and damage are optional; damage can be `(+N)` without dice.                                             |
| `S`  | First line: casting chance in % (`SPELL_PCT_X`, not 0) and power (`POW_Y`). Then spell types (`RF4_*`).                       |

Example:

```
N:251:Morgoth, Lord of Darkness
W:25:1
G:V:D
I:2:160d4:7
A:10:10:0:25
P:[+20,5d4]
B:HIT:SHATTER:(+20,6d10)
F:UNIQUE | QUESTOR | MALE
```

Speed in use (number of records): 1 (7), 2 (84), 3 (23), 4 (10).

Health: uniques always get the average (`hdice × (1 + hside) / 2`); others roll
the dice when created (`place_monster_one()` in `src/monster2.c`).

### Monster flags

Flag names are the constants in `src/defines.h` without the prefix.

- **`RF1_*`**: `UNIQUE`, `QUESTOR`, `MALE`, `FEMALE`, `PEACEFUL`, `CHAR_CLEAR`,
    `ATTR_CLEAR`, `ATTR_MULTI`, `FORCE_DEPTH`, `SPECIAL_GEN`, `FRIEND`,
    `FRIENDS`, `ESCORT`, `ESCORTS`, `UNIQUE_FRIEND`, `NEVER_BLOW`, `NEVER_MOVE`,
    `HIDDEN_MOVE`, `RAND_25`, `RAND_50`, `NO_CRIT`, `RES_CRIT`, `DROP_33`,
    `DROP_100`, `DROP_1D2` … `DROP_4D2`, `DROP_GOOD`, `DROP_GREAT`,
    `DROP_CHEST`, `DROP_CHOSEN`, `DROP_UP_TO_10` … `DROP_UP_TO_20`.
- **`RF2_*`**: `MINDLESS`, `SMART`, `TERRITORIAL`, `SHORT_SIGHTED`, `INVISIBLE`,
    `GLOW`, `CRUEL_BLOW`, `EXCHANGE_PLACES`, `MULTIPLY`, `REGENERATE`,
    `RIPOSTE`, `FLANKING`, `CLOUD_SURROUND`, `FLYING`, `PASS_DOOR`,
    `UNLOCK_DOOR`, `OPEN_DOOR`, `BASH_DOOR`, `PASS_WALL`, `KILL_WALL`,
    `TUNNEL_WALL`, `KILL_BODY`, `TAKE_ITEM`, `KILL_ITEM`, `LOW_MANA_RUN`,
    `CHARGE`, `ELFBANE`, `KNOCK_BACK`, `CRIPPLING`, `OPPORTUNIST`,
    `ZONE_OF_CONTROL`.
- **`RF3_*`**: types `ORC`, `TROLL`, `SERPENT`, `DRAGON`, `RAUKO`, `UNDEAD`,
    `SPIDER`, `WOLF`, `MAN`, `ELF`; `HURT_LITE`, `STONE`, `HURT_FIRE`,
    `HURT_COLD`; `RES_ELEC`, `RES_FIRE`, `RES_COLD`, `RES_POIS`; `NO_SLOW`,
    `NO_FEAR`, `NO_STUN`, `NO_CONF`, `NO_SLEEP`. (`RES_NETHR`, `RES_WATER`,
    `RES_PLAS`, `RES_NEXUS`, `RES_DISEN` are parsed but have no effect.)
- **`RF4_*`** (spells, used on `S:` lines): `ARROW1`, `ARROW2`, `BOULDER`,
    `BRTH_FIRE`, `BRTH_COLD`, `BRTH_POIS`, `BRTH_DARK`, `EARTHQUAKE`, `SHRIEK`,
    `SCREECH`, `DARKNESS`, `FORGET`, `SCARE`, `CONF`, `HOLD`, `SLOW`,
    `HATCH_SPIDER`, `DIM`, `SNG_BINDING`, `SNG_PIERCING`, `SNG_OATHS`,
    `THROW_WEB`, `RALLY`.

### Blow methods and effects

Methods (`RBM_*`): `HIT`, `TOUCH`, `CLAW`, `BITE`, `STING`, `PECK`, `WHIP`,
`CRUSH`, `ENGULF`, `CRAWL`, `THORN`, `SPORE`.

Effects (`RBE_*`): `HURT`, `WOUND`, `BATTER`, `SHATTER`, `UN_BONUS`, `UN_POWER`,
`LOSE_MANA`, `SLOW`, `EAT_ITEM`, `EAT_FOOD`, `DARK`, `HUNGER`, `POISON`, `ACID`,
`ELEC`, `FIRE`, `COLD`, `BLIND`, `CONFUSE`, `TERRIFY`, `ENTRANCE`, `HALLU`,
`DISEASE`, `LOSE_STR`, `LOSE_DEX`, `LOSE_CON`, `LOSE_GRA`, `LOSE_STR_CON`,
`LOSE_ALL`, `DISARM`.

What each effect does is in [code_base.md](code_base.md#monster-blows).

## object.txt

Defines object kinds (base items).

```
N: serial number : & object name~
G: symbol : color
I: tval : sval : pval
W: depth : rarity : weight : cost
P: attack bonus : damage dice : evasion bonus : protection dice
A: depth/rarity : depth/rarity : ...
B: skill/ability
F: flag | flag | ...
D: description
```

| Line | Meaning                                                                         |
| ---- | ------------------------------------------------------------------------------- |
| `N`  | Name tokens: `&` = article or count ("a", "an", "3"); `~` = plural ending.      |
| `G`  | Color `d` = use the flavor color.                                               |
| `I`  | Type, subtype, and a fixed pval (variable pvals are hardcoded).                 |
| `W`  | Depth (the object's level), rarity (not used; see `A`), weight in 0.1 lb, cost. |
| `P`  | Combat values. Light sources have a 5th value (always 0).                       |
| `A`  | Allocation: one or more `depth/rarity` pairs used for generation.               |
| `B`  | An ability that the item grants.                                                |

Example: `& Small jewelled chest~` is shown as "a Small jewelled chest" or "3
Small jewelled chests". Names are built by `object_desc()` in `src/object1.c`.

### tval (item type)

From `TV_*` in `src/defines.h`:

| tval | Constant      | Items                 | tval | Constant        | Items                    |
| ---- | ------------- | --------------------- | ---- | --------------- | ------------------------ |
| 2    | `TV_NOTE`     | Tutorial notes        | 35   | `TV_CLOAK`      | Cloaks                   |
| 3    | `TV_SKELETON` | Skeletons             | 36   | `TV_SOFT_ARMOR` | Soft armour              |
| 4    | `TV_METAL`    | Piece of mithril      | 37   | `TV_MAIL`       | Mail                     |
| 7    | `TV_CHEST`    | Chests                | 39   | `TV_LIGHT`      | Light sources            |
| 17   | `TV_ARROW`    | Arrows                | 40   | `TV_AMULET`     | Amulets                  |
| 19   | `TV_BOW`      | Bows                  | 45   | `TV_RING`       | Rings                    |
| 20   | `TV_DIGGING`  | Shovels, mattocks     | 55   | `TV_STAFF`      | Staves                   |
| 21   | `TV_HAFTED`   | Blunt weapons         | 66   | `TV_HORN`       | Horns                    |
| 22   | `TV_POLEARM`  | Spears, axes, glaives | 75   | `TV_POTION`     | Potions                  |
| 23   | `TV_SWORD`    | Swords                | 77   | `TV_FLASK`      | Flasks of oil            |
| 30   | `TV_BOOTS`    | Boots                 | 80   | `TV_FOOD`       | Herbs and food           |
| 31   | `TV_GLOVES`   | Gloves                | 81   | `TV_EASTER`     | Easter herb flavors only |
| 32   | `TV_HELM`     | Helms                 |      |                 |                          |
| 33   | `TV_CROWN`    | Crowns                |      |                 |                          |
| 34   | `TV_SHIELD`   | Shields               |      |                 |                          |

Herbs are `TV_FOOD` svals 0–9; bread, meat and lembas are svals 35–37. The
effects of herbs, potions, staves and horns are hardcoded by sval (see
[code_base.md](code_base.md#consumable-effects)). Food adds its pval to the food
counter.

### Item flags

Flag names are the constants in `src/defines.h` without the prefix.

- **`TR1_*`**: stats `STR`, `DEX`, `CON`, `GRA`, `NEG_STR` … `NEG_GRA`; skills
    `MEL`, `ARC`, `STL`, `PER`, `WIL`, `SMT`, `SNG`; slays `SLAY_ORC`,
    `SLAY_TROLL`, `SLAY_WOLF`, `SLAY_SPIDER`, `SLAY_UNDEAD`, `SLAY_RAUKO`,
    `SLAY_DRAGON`, `SLAY_MAN_OR_ELF`; brands `BRAND_COLD`, `BRAND_FIRE`,
    `BRAND_ELEC`, `BRAND_POIS`; `DAMAGE_SIDES`, `TUNNEL`, `SHARPNESS`,
    `SHARPNESS2`, `VAMPIRIC`.
- **`TR2_*`**: sustains `SUST_STR` … `SUST_GRA`; resistances `RES_COLD`,
    `RES_FIRE`, `RES_ELEC`, `RES_POIS`, `RES_BLEED`, `RES_FEAR`, `RES_BLIND`,
    `RES_CONFU`, `RES_STUN`, `RES_HALLU`; `RADIANCE`, `SLOW_DIGEST`, `LIGHT`,
    `REGEN`, `SEE_INVIS`, `FREE_ACT`, `SPEED`; curses `TRAITOR`, `FEAR`,
    `HUNGER`, `DARKNESS`, `SLOWNESS`, `DANGER`, `AGGRAVATE`, `HAUNTED`;
    vulnerabilities `VUL_COLD`, `VUL_FIRE`, `VUL_POIS`.
- **`TR3_*`**: `DAMAGED`, `CHEAT_DEATH`, `STAND_FAST`, `ACCURATE`, `CUMBERSOME`,
    `AVOID_TRAPS`, `MEDIC`, `NO_SMITHING`, `MITHRIL`, `AXE`, `POLEARM`,
    `IGNORE_ACID`, `IGNORE_ELEC`, `IGNORE_FIRE`, `IGNORE_COLD`, `IGNORE_ALL`,
    `THROWING`, `ENCHANTABLE`, `ACTIVATE`, `INSTA_ART`, `EASY_KNOW`,
    `MORE_SPECIAL`, `HAND_AND_A_HALF`, `TWO_HANDED`, `LIGHT_CURSE`,
    `HEAVY_CURSE`, `PERMA_CURSE`.

## artefact.txt

Defines the fixed artefacts.

```
N: serial number : name
G: symbol : color          (optional override)
I: tval : sval : pval
B: skill/ability : skill/ability : ...
W: depth : rarity : weight : cost
P: attack bonus : damage dice : evasion bonus : protection dice
F: flag | flag | ...
D: description
```

The `I:` line selects the base object kind. The artefact ID (`N:`) is used by
the debug command `C` (see [developer_mode.md](developer_mode.md)). Removing an
artefact or changing its base type breaks savefiles.

Morgoth's crown is 4 artefacts (175–178), one for each number of Silmarils. See
[code_base.md](code_base.md#silmarils-and-morgoths-crown).

## special.txt

Defines special items ("of Gondolin", "of Free Action", ...) that can be applied
to base items.

```
N: serial number : name
C: max att : dice : sides : max evn : prot dice : prot sides : pval
W: depth : rarity : max depth : cost
T: tval : min sval : max sval
B: skill/ability
F: flag | flag | ...
```

| Line | Meaning                                                         |
| ---- | --------------------------------------------------------------- |
| `C`  | Creation bonuses (maximum values). Cursed specials negate them. |
| `W`  | Depth, rarity, deepest depth for generation, and cost.          |
| `T`  | Base items it can apply to. Up to 4 `T:` lines.                 |
| `B`  | An ability that the special grants.                             |

Example:

```
N:1:of Protection
W:0:2:0:1000
C:0:0:0:0:0:1:0
T:34:0:99
T:30:2:99
```

## terrain.txt

Defines terrain features. Only name, symbol, color and mimic come from the file:

```
N: serial number : name
G: symbol : color
M: feature to mimic
```

There are no `F:` or `D:` lines. All terrain behavior (walls, doors, traps,
stairs, etc.) is hardcoded by feature ID (`FEAT_*` in `src/defines.h`). See
[code_base.md](code_base.md#terrain-behavior).

Important feature ID ranges:

| IDs       | Constants                       | Features                       |
| --------- | ------------------------------- | ------------------------------ |
| 0x10–0x1C | `FEAT_TRAP_HEAD` … `_TAIL`      | Traps                          |
| 0x40–0x45 | `FEAT_FORGE_NORMAL_*`           | Forge, 0–5 uses left           |
| 0x46–0x4B | `FEAT_FORGE_GOOD_*`             | Enchanted forge, 0–5 uses left |
| 0x4C–0x4F | `FEAT_FORGE_UNIQUE_*`           | Orodruth, 0–3 uses left        |
| 0x50–0x53 | `FEAT_LESS` … `FEAT_MORE_SHAFT` | Stairs and shafts              |

Forges encode their remaining uses in the ID: `*_HEAD + uses`. For example,
`N:65` is "forge (1 use remaining)". Generation is in
[code_base.md](code_base.md#forges).

## race.txt

Defines the 4 player races.

```
N: race number : name
S: str : dex : con : gra
I: history : base age : max age
H: base height : height modifier
W: base weight : weight modifier
C: house | house | ...
F: flag | flag | ...
E: tval : sval : min : max
D: description
```

| Line | Meaning                                                       |
| ---- | ------------------------------------------------------------- |
| `I`  | First `history.txt` chart for the background, and age values. |
| `C`  | The houses (IDs from `house.txt`) that this race can choose.  |
| `E`  | Starting equipment: object tval, sval, and a count range.     |

| ID  | Race    | Stats (S/D/C/G) | Flags                                      | Houses (`C:`) |
| --- | ------- | --------------- | ------------------------------------------ | ------------- |
| 0   | Noldor  | 0/+1/+2/+2      | BOW_PROFICIENCY, SNG_AFFINITY              | 1, 2, 3       |
| 1   | Sindar  | −1/+1/+2/+1     | BOW_PROFICIENCY, SNG_AFFINITY              | 4, 10         |
| 2   | Naugrim | 0/−1/+3/+1      | AXE_PROFICIENCY, ARC_PENALTY, SMT_AFFINITY | 5, 6          |
| 3   | Edain   | 0/0/0/0         | (none)                                     | 7, 8, 9       |

### Race and house flags (`RHF_*`)

- Proficiencies: `BOW_PROFICIENCY`, `AXE_PROFICIENCY`.
- Affinities: `MEL_AFFINITY`, `ARC_AFFINITY`, `EVN_AFFINITY`, `STL_AFFINITY`,
    `PER_AFFINITY`, `WIL_AFFINITY`, `SMT_AFFINITY`, `SNG_AFFINITY`.
- Penalties: `MEL_PENALTY` … `SNG_PENALTY` (same skills).

The effect of affinities and penalties is in
[code_base.md](code_base.md#skills).

## house.txt

Defines player houses.

```
N: house number : name
A: alternate name          (as in "<name> of <alternate name>")
B: short name
F: flag
S: str : dex : con : gra
D: description
```

| ID  | House              | Race    | Flag         | Stat   |
| --- | ------------------ | ------- | ------------ | ------ |
| 0   | Houseless          | —       | —            | —      |
| 1   | House of Feanor    | Noldor  | SMT_AFFINITY | +1 Dex |
| 2   | House of Fingolfin | Noldor  | WIL_AFFINITY | +1 Con |
| 3   | House of Finarfin  | Noldor  | PER_AFFINITY | +1 Gra |
| 4   | Of Doriath         | Sindar  | SNG_AFFINITY | +1 Gra |
| 5   | House of Nogrod    | Naugrim | SMT_AFFINITY | +1 Dex |
| 6   | House of Belegost  | Naugrim | WIL_AFFINITY | +1 Str |
| 7   | House of Beor      | Edain   | EVN_AFFINITY | +1 Gra |
| 8   | House of Haleth    | Edain   | STL_AFFINITY | +1 Dex |
| 9   | House of Hador     | Edain   | MEL_AFFINITY | +1 Str |
| 10  | Falathrim          | Sindar  | ARC_AFFINITY | +1 Dex |

## ability.txt

Defines all abilities.

```
N: ability number : name
I: skill number : ability number in skill : level requirement
P: skill/ability : skill/ability : ...
T: tval : min sval : max sval
D: description
```

| Line | Meaning                                                                         |
| ---- | ------------------------------------------------------------------------------- |
| `I`  | Skill (0–7, see below), index within the skill, and the level requirement.      |
| `P`  | Prerequisites. One `P:` line per ability. The player needs **any one** of them. |
| `T`  | Item types that can get this ability by smithing. Many `T:` lines allowed.      |

| Skill | Name       | Abilities | Last ability (stat +1, level) |
| ----- | ---------- | --------- | ----------------------------- |
| 0     | Melee      | 0–13      | Strength (20)                 |
| 1     | Archery    | 20–28     | Dexterity (10)                |
| 2     | Evasion    | 40–50     | Dexterity (20)                |
| 3     | Stealth    | 60–66     | Dexterity (11)                |
| 4     | Perception | 80–89     | Grace (10)                    |
| 5     | Will       | 100–110   | Constitution (12)             |
| 6     | Smithing   | 120–127   | Grace (10)                    |
| 7     | Song       | 140–153   | Grace (12)                    |

Example, the Melee tree:

| `N:` | Ability             | Level | Prerequisites (any one)         |
| ---- | ------------------- | ----- | ------------------------------- |
| 0    | Power               | 1     | —                               |
| 1    | Finesse             | 2     | —                               |
| 2    | Knock Back          | 3     | —                               |
| 3    | Polearm Mastery     | 4     | —                               |
| 4    | Charge              | 5     | —                               |
| 5    | Follow-Through      | 6     | Power, Finesse                  |
| 6    | Impale              | 7     | Power, Polearm Mastery          |
| 7    | Subtlety            | 8     | Finesse                         |
| 8    | Whirlwind Attack    | 9     | Polearm Mastery, Follow-Through |
| 9    | Zone of Control     | 10    | Finesse, Polearm Mastery        |
| 10   | Smite               | 11    | Knock Back, Charge              |
| 11   | Two Weapon Fighting | 12    | Finesse, Parry (Evasion)        |
| 12   | Rapid Attack        | 13    | Subtlety, Opportunist (Stealth) |
| 13   | Strength            | 20    | —                               |

`T:` lines with a single sval restrict smithing to one item. Examples:
`T:31:1:1` (archery abilities, leather gloves), `T:30:1:1` (Disguise, Vanish:
one kind of boots), `T:36:2:2` (Majesty, robe), `T:21:8:8` (smithing abilities,
war hammer), `T:23:25:25` (Impale, greatsword).

## flavor.txt

Defines the unidentified looks ("flavors") of rings, amulets, staves, horns,
potions and herbs.

```
N: serial number : tval [: sval]
G: symbol : color
D: flavor name
```

- Without an sval, the flavor is one of the random flavors for that tval.
- With an sval, the item always has this flavor ("fixed" flavor).

Flavor tvals in use: 40 (amulets), 45 (rings), 55 (staves), 66 (horns), 75
(potions), 80 (herbs). Records with tval 81 are "Easter egg" herb flavors: at
Easter, herbs use the flavor 20 records later (`flavor_init()` in
`src/object1.c`).

Example of a random flavor (Antidote, `I:75:8:100`): every flavor record with
tval 75 and no sval can be its flavor.

```
N:198:75
G:!:b1
D:Brilliant Blue
```

Example of a fixed flavor (Orcish Liquor, `I:75:2:100`):

```
N:195:75:2
G:!:u
D:Murky Brown
```

## vault.txt

Defines interesting rooms and vaults.

```
N: serial number : name
X: room type : depth : rarity
F: flag | flag | ...
D: layout line
```

Room types: 6 interesting room, 7 lesser vault, 8 greater vault, 9 Morgoth's
vault, 10 Gates of Angband. Flags: `TEST`, `NO_ROTATION`, `TRAPS`, `WEBS`,
`LIGHT`, `SURFACE`.

`D:` lines are the map. Whitespace matters. The file header lists all symbols.
Some symbols place specific monsters (e.g., `C` Carcharoth, `V` Morgoth, `z`
thrall, `Z` orc thrallmaster); `build_vault()` in `src/generate.c` implements
them.

## history.txt, names.txt, limits.txt

- `history.txt`: `N: chart : entry : probability : house` + `D:` text. The
    race's `I:` line gives the first chart.
- `names.txt`: `N:word`, one word per record, for random names.
- `limits.txt`: `M:<code>:<value>` array sizes. `M:A` has 4 values (special,
    normal, random, self-made artefacts). See the file header for all codes.

## Pref files (`lib/pref/*.prf`)

Pref files assign tiles and other visuals. The tiles graphics mapping is in
`graf-tiles.prf`; flavor tiles are in `flvr-tiles.prf` (included from
`graf-tiles.prf`). `lib/xtra/graf/TilePicker.html` helps to find tiles.

Control lines:

- `%:file.prf` includes another pref file.
- `?:[EQU $GRAF tiles]` … `?:1` makes lines conditional (`$SYS`, `$GRAF`,
    `$RACE`, ...).

Tile lines (`0xYY/0xXX` = attr/char = row/column):

```
R:id:0xYY/0xXX         # Monster or player race (IDs 0-3 = player races)
R:id:rage:0xYY/0xXX    # Monster tile while the player is raging (optional)
K:id:0xYY/0xXX         # Object kind
F:id:0xYY/0xXX         # Terrain feature
L:id:0xYY/0xXX         # Flavor
S:0xID:0xYY/0xXX       # Special graphic (icons, digits, arrows, spells, ...)
```

The `id` is the `N:` number from the matching edit file. Example: object `N:374`
(`& Small jewelled chest~`) has the tile line `K:374:0x81/0x84`.

An `R:<id>:rage:...` line needs a normal `R:<id>:...` line too. It only sets the
tile that is shown during rage (see
[rendering.md](rendering.md#rage-specific-alternative-tiles)).

### Tile coordinates

```
0xYY/0xXX
  │    └── column = 0xXX − 0x80 (0–31 in the MicroChasm tileset)
  └─────── row    = 0xYY − 0x80 (0–16 in the MicroChasm tileset)
```

Pixel position: `x = column × 16`, `y = row × 16`. The tileset is 512×272 pixels
(32 × 17 tiles of 16×16).

Examples:

| Entity          | ASCII | Tile line             |
| --------------- | ----- | --------------------- |
| Player (Noldor) | `@`   | `R:0:0x8D/0x80`       |
| Wolf            | `C`   | `R:11:0x88/0x91`      |
| Wolf (rage)     |       | `R:11:rage:0x90/0x85` |
| Morgoth         | `V`   | `R:251:0x8A/0x92`     |
| Frost breath    |       | `S:0x31:0x8B/0x8D`    |

Player tiles: each race has 16 tiles in a row, starting at the `R:0`–`R:3` tile.
The house does not change the tile. Which of the 16 is shown is hardcoded (see
[rendering.md](rendering.md#player-tiles)).
