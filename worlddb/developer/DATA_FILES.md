## Game Data Files

This document describes the game data files of Sil-Q.

### Common file format conventions

All data files share a common structure:

- Lines starting with `#` are comments
- Each file begins with a version stamp: `V:1.5.1`
- Entity entries start with an `N:` line (containing serial number and name)
- Field lines use single-letter prefixes followed by `:` and colon-separated
  values
- Multiple values on a line are separated by `:`
- Flags are separated by `|`
- Description lines (`D:`) can span multiple lines

### Overview of current edit files (`lib/edit/*.txt`)

| File           | Entity Type       | In Scope | Notes                                          |
| -------------- | ----------------- | -------- | ---------------------------------------------- |
| `ability.txt`  | Player abilities  | Yes      | Skills like Power, Finesse, etc.               |
| `artefact.txt` | Unique artifacts  | Yes      | Glamdring, Ringil, etc.                        |
| `flavor.txt`   | Item flavors      | Yes      | Visual descriptions (Amethyst ring, Oak staff) |
| `history.txt`  | Character history | No       | Background generation                          |
| `house.txt`    | Player houses     | Yes      | House of Feanor, etc.                          |
| `limits.txt`   | Game limits       | No       | Max monsters, objects, etc.                    |
| `monster.txt`  | Monster types     | Yes      | All monster definitions                        |
| `names.txt`    | Random names      | No       | Name generation                                |
| `object.txt`   | Base items        | Yes      | Weapons, armor, consumables                    |
| `race.txt`     | Player races      | Yes      | Noldor, Sindar, Naugrim, Edain                 |
| `special.txt`  | Item suffixes     | Yes      | "of Gondolin", "of Free Action"                |
| `terrain.txt`  | Terrain features  | Yes      | Floors, walls, doors, traps                    |
| `vault.txt`    | Vault layouts     | No       | Dungeon layout templates (e.g., throne room)   |

### monster.txt - Monster Definitions

Defines all monster types in the game.

#### Format

```
N: monster/player ID : monster/player name
W: depth : rarity
G: ASCII character : attribute (color code) of ASCII character
I: speed : XdY (health dice) : light radius
A: sleepiness : perception : stealth : will
P: [evasion bonus, protection dice]
B: attack method : attack effect : (attack bonus, damage dice)
S: SPELL_PCT_X | POW_Y
S: spell type | spell type | ...
F: flag | flag | ...
D: description
```

#### Field Details

| Field | Description                                                              |
| ----- | ------------------------------------------------------------------------ |
| `N`   | Unique ID and name. Entries 0-3 are reserved for the player (4 races).   |
| `W`   | Depth found at; rarity (1 in N chance)                                   |
| `G`   | ASCII character (e.g., `V`) and its attribute (color code)               |
| `I`   | Speed, health dice (XdY), light radius (negative = darkness)             |
| `A`   | Sleepiness, perception, stealth, will (see Alertness section below)      |
| `P`   | Defense: `[evasion, Xd4 protection]`                                     |
| `B`   | Attack: method, effect, `(bonus, XdY damage)`. Up to 4 attacks.          |
| `S`   | Spells: first line is frequency/power, subsequent lines list spell types |
| `F`   | Monster flags (see below)                                                |
| `D`   | Description text (multiple lines allowed)                                |

#### Speed Values

Speed determines how much energy a creature gains per game turn:

| Speed | Name      | Energy/Turn | Count | Example Monsters                      |
| ----- | --------- | ----------- | ----- | ------------------------------------- |
| 1     | Slow      | 5           | 7     | Mewlips, some plants                  |
| 2     | Normal    | 10          | 84    | Most monsters (default)               |
| 3     | Fast      | 15          | 23    | Wolf, Orc scout                       |
| 4     | Very Fast | 20          | 10    | Carcharoth, Thuringwethil, Shadow bat |

**Data vs Code:** The code (`tables.c:115-124`) supports speeds 1-7, but
`monster.txt` only uses speeds **1-4**. The game manual correctly states there
are 4 speed levels.

**Fastest Monsters (Speed 4):** Carcharoth, Thuringwethil, Grotesque, Darting
horror, Shadow bat, Twisted bat, Hummerhorn, Grimhawk, Gorcrow, Crebain.

**Note:** Player speed is **hardcoded** to 2 (Normal) in `src/xtra1.c:2235`,
clamped to range 1-3. Player speed is NOT configurable in data files - only
modified by equipment (`TR2_SPEED` flag) or status effects.

#### Health Dice

Monster health is specified as dice notation (XdY) in the `I:` line.

**Example:** `I:3:6d4:0` means speed 3, health 6d4, light 0.

**Health Calculation** (Source: `monster2.c:2553-2558`):

| Monster Type | Calculation                        | Example (6d4) |
| ------------ | ---------------------------------- | ------------- |
| UNIQUE       | Average: `hdice × (1 + hside) / 2` | 6 × 2.5 = 15  |
| Non-unique   | Rolled: `damroll(hdice, hside)`    | 6-24 (random) |

Non-unique monsters have **variable health** each time they spawn. A Wolf (6d4)
might have 8 HP one encounter and 20 HP the next.

#### Alertness and Sleepiness (A: Line)

The first field of the `A:` line controls how likely a monster is to start
asleep or unwary.

**Format:** `A: sleepiness : perception : stealth : will`

**Sleepiness Value:**

- Determines initial alertness when monster spawns
- Formula: `initial_alertness = 0 - dieroll(sleepiness)`
- Higher value = more likely to start asleep/unwary
- Value of 0 = monster always starts alert (never sleeps)

**Examples:**

| Monster     | Sleepiness | Initial Alertness | Typical State  |
| ----------- | ---------- | ----------------- | -------------- |
| Wolf        | 20         | -19 to -1         | Usually asleep |
| Orc warrior | 10         | -9 to -1          | Usually unwary |
| Morgoth     | 0          | 0                 | Always alert   |

**Alertness Thresholds** (from `defines.h`):

| Constant           | Value | Monster State                |
| ------------------ | ----- | ---------------------------- |
| `ALERTNESS_ALERT`  | 0     | Alert (aware of player)      |
| `ALERTNESS_UNWARY` | -10   | Unwary (awake but not alert) |
| Below -10          | < -10 | Asleep                       |

See CODE_ANALYSIS.md Section 30 for the full alertness/perception mechanics.

#### Monster Flags (from `defines.h`)

**RF1 Flags** - Basic properties:

- `UNIQUE`, `QUESTOR`, `MALE`, `FEMALE`
- `FORCE_DEPTH`, `SPECIAL_GEN`
- `FRIEND`, `FRIENDS`, `ESCORT`, `ESCORTS`
- `RAND_25`, `RAND_50` - Random movement
- `DROP_33`, `DROP_100`, `DROP_1D2` ... `DROP_4D2` - Item drops
- `DROP_GOOD`, `DROP_GREAT`, `DROP_CHEST`, `DROP_CHOSEN`
- `NEVER_BLOW`, `NEVER_MOVE`, `HIDDEN_MOVE`
- `NO_CRIT`, `RES_CRIT`

**RF2 Flags** - Abilities and behaviors:

- `MINDLESS`, `SMART`, `TERRITORIAL`, `SHORT_SIGHTED`
- `INVISIBLE`, `GLOW`, `MULTIPLY`, `REGENERATE`
- `FLYING`, `PASS_DOOR`, `UNLOCK_DOOR`, `OPEN_DOOR`, `BASH_DOOR`
- `PASS_WALL`, `KILL_WALL`, `TUNNEL_WALL`
- `KILL_BODY`, `TAKE_ITEM`, `KILL_ITEM`
- Combat abilities: `CHARGE`, `KNOCK_BACK`, `CRIPPLING`, `OPPORTUNIST`,
  `ZONE_OF_CONTROL`, `CRUEL_BLOW`, `EXCHANGE_PLACES`, `RIPOSTE`, `FLANKING`,
  `ELFBANE`

**RF3 Flags** - Monster types and resistances:

- Types: `ORC`, `TROLL`, `SERPENT`, `DRAGON`, `RAUKO`, `UNDEAD`, `SPIDER`,
  `WOLF`, `MAN`, `ELF`
- `HURT_LITE`, `STONE`, `HURT_FIRE`, `HURT_COLD`
- `RES_ELEC`, `RES_FIRE`, `RES_COLD`, `RES_POIS`, `RES_NETHR`, `RES_WATER`,
  `RES_PLAS`, `RES_NEXUS`, `RES_DISEN`
- `NO_SLOW`, `NO_FEAR`, `NO_STUN`, `NO_CONF`, `NO_SLEEP`

**RF4 Flags** - Spells and special attacks:

- `ARROW1`, `ARROW2`, `BOULDER`
- `BRTH_FIRE`, `BRTH_COLD`, `BRTH_POIS`, `BRTH_DARK`
- `EARTHQUAKE`, `SHRIEK`, `SCREECH`, `DARKNESS`, `FORGET`
- `SCARE`, `CONF`, `HOLD`, `SLOW`
- Songs: `SNG_BINDING`, `SNG_PIERCING`, `SNG_OATHS`
- `HATCH_SPIDER`, `DIM`, `THROW_WEB`, `RALLY`

#### Attack Methods (`RBM_*`)

| Code         | Method          |
| ------------ | --------------- |
| `RBM_HIT`    | Generic hit     |
| `RBM_TOUCH`  | Touch attack    |
| `RBM_CLAW`   | Claw attack     |
| `RBM_BITE`   | Bite attack     |
| `RBM_STING`  | Sting attack    |
| `RBM_PECK`   | Peck attack     |
| `RBM_WHIP`   | Whip attack     |
| `RBM_CRUSH`  | Crushing attack |
| `RBM_ENGULF` | Engulf attack   |
| `RBM_CRAWL`  | Crawl attack    |
| `RBM_THORN`  | Thorn attack    |
| `RBM_SPORE`  | Spore attack    |

#### Attack Effects (`RBE_*`)

| Code                                                                                  | Effect                 |
| ------------------------------------------------------------------------------------- | ---------------------- |
| `RBE_HURT`                                                                            | Normal damage          |
| `RBE_WOUND`                                                                           | Causes bleeding        |
| `RBE_BATTER`                                                                          | Battering damage       |
| `RBE_SHATTER`                                                                         | Shattering damage      |
| `RBE_POISON`, `RBE_ACID`, `RBE_ELEC`, `RBE_FIRE`, `RBE_COLD`                          | Elemental              |
| `RBE_BLIND`, `RBE_CONFUSE`, `RBE_TERRIFY`, `RBE_ENTRANCE`, `RBE_HALLU`, `RBE_DISEASE` | Status                 |
| `RBE_SLOW`, `RBE_DARK`, `RBE_HUNGER`                                                  | Debuffs                |
| `RBE_LOSE_STR`, `RBE_LOSE_DEX`, `RBE_LOSE_CON`, `RBE_LOSE_GRA`, `RBE_LOSE_ALL`        | Stat drain             |
| `RBE_UN_BONUS`, `RBE_UN_POWER`, `RBE_LOSE_MANA`                                       | Equipment/mana effects |
| `RBE_EAT_ITEM`, `RBE_EAT_FOOD`, `RBE_DISARM`                                          | Item effects           |

______________________________________________________________________

### object.txt - Base Item Definitions

Defines all base item types (weapons, armor, consumables, etc.).

#### Format

```
N: object ID : object name (with formatting tokens like `&`, `~`)
G: symbol : color
I: tval : sval : pval
W: depth : rarity : weight : cost
P: plus to-hit : damage dice : plus to-evasion : protection dice
A: depth/rarity : depth/rarity : ...
F: flag | flag | ...
D: description
```

#### Field details

| Field | Description                                                                |
| ----- | -------------------------------------------------------------------------- |
| `N`   | ID and name. `&` for article placement, `~` for pluralization.             |
| `G`   | Symbol and color. `d` = use flavor color.                                  |
| `I`   | tval (type), sval (subtype), pval (power value)                            |
| `W`   | Depth, rarity (unused), weight (0.1 lb units), cost                        |
| `P`   | Combat stats: `attack_bonus : XdY damage : evasion_bonus : XdY protection` |
| `A`   | Allocation pairs (depth/rarity) for generation                             |
| `F`   | Item flags (see below)                                                     |
| `D`   | Description                                                                |

#### tval (type values) from `src/defines.h`

| tval | Constant        | Category         |
| ---- | --------------- | ---------------- |
| 19   | `TV_BOW`        | Bows             |
| 20   | `TV_DIGGING`    | Shovels/Mattocks |
| 21   | `TV_HAFTED`     | Hafted weapons   |
| 22   | `TV_POLEARM`    | Polearms         |
| 23   | `TV_SWORD`      | Swords           |
| 30   | `TV_BOOTS`      | Boots            |
| 31   | `TV_GLOVES`     | Gloves           |
| 32   | `TV_HELM`       | Helms            |
| 34   | `TV_SHIELD`     | Shields          |
| 35   | `TV_CLOAK`      | Cloaks           |
| 36   | `TV_SOFT_ARMOR` | Soft armor       |
| 37   | `TV_MAIL`       | Mail armor       |
| 39   | `TV_LIGHT`      | Light sources    |
| 40   | `TV_AMULET`     | Amulets          |
| 45   | `TV_RING`       | Rings            |
| 55   | `TV_STAFF`      | Staves           |
| 66   | `TV_HORN`       | Horns            |
| 75   | `TV_POTION`     | Potions          |
| 80   | `TV_FOOD`       | Food (herbs)     |
| 81   | `TV_FLASK`      | Flasks           |
| 90   | `TV_ARROW`      | Arrows           |
| 91   | `TV_CHEST`      | Chests           |
| 100  | `TV_METAL`      | Metal pieces     |
| 101  | `TV_USELESS`    | Useless items    |

#### Food Items (`TV_FOOD`) - Special Handling

Food items use a **hybrid system**: special herbs have hardcoded effects, then
ALL food adds pval to hunger.

**Special Herbs** (sval 0-9) - Hardcoded in `use-obj.c`:

| sval | Name               | Hardcoded Effect            | pval |
| ---- | ------------------ | --------------------------- | ---- |
| 0    | Rage               | +20 turns haste, +10 damage | 250  |
| 1    | Sustenance         | +2000 food                  | 0    |
| 2    | Terror             | Fear + speed                | 250  |
| 3    | Healing            | Heal 50+ HP                 | 250  |
| 4    | Restoration        | Restore stats               | 250  |
| 5    | Emptiness (Hunger) | -1000 food                  | 0    |
| 6    | Visions            | Hallucination               | 250  |
| 7    | Entrancement       | Entranced                   | 250  |
| 8    | Weakness           | STR drain                   | 250  |
| 9    | Sickness           | Poison                      | 250  |

**Generic Food** (sval 32+) - Uses pval directly:

| sval | Name               | pval     | Food Gained |
| ---- | ------------------ | -------- | ----------- |
| 35   | Bread              | (varies) | +pval       |
| 36   | Meat               | (varies) | +pval       |
| 37   | Fragment of Lembas | 3000     | +3000       |

**Formula**: `total_food = hardcoded_effect + pval`

Most herbs have pval ~250 for minor nourishment on top of their special effect.

#### Horns (`TV_HORN`) - Hardcoded Effects

Horns (tval 66) are usable items that produce sound-based effects. **All effects
are hardcoded** in `use-obj.c:670-920`; pval is NOT used.

| sval | Name     | Hardcoded Effect                             |
| ---- | -------- | -------------------------------------------- |
| 0    | Terror   | Fear effect in 90° arc (GF_FEAR)             |
| 1    | Thunder  | Stun effect in 90° arc (GF_SOUND, 10 damage) |
| 2    | Force    | Knockback 1-3 squares + stun                 |
| 3    | Blasting | Destroys stone walls (GF_KILL_WALL)          |
| 4    | Warning  | Alerts all nearby monsters                   |

Horn power scales with the player's **Will skill**. See CODE_ANALYSIS.md Section
27 for details.

#### Item Flags (`TR1_*`, `TR2_*`, `TR3_*`)

**TR1 Flags** - Stats and slays:

- Stats: `STR`, `DEX`, `CON`, `GRA`, `NEG_STR`, `NEG_DEX`, `NEG_CON`, `NEG_GRA`
- Skills: `MEL`, `ARC`, `STL`, `PER`, `WIL`, `SMT`, `SNG`
- Slays: `SLAY_ORC`, `SLAY_TROLL`, `SLAY_WOLF`, `SLAY_SPIDER`, `SLAY_UNDEAD`,
  `SLAY_RAUKO`, `SLAY_DRAGON`, `SLAY_MAN_OR_ELF`
- Brands: `BRAND_COLD`, `BRAND_FIRE`, `BRAND_ELEC`, `BRAND_POIS`
- Special: `DAMAGE_SIDES`, `TUNNEL`, `SHARPNESS`, `SHARPNESS2`, `VAMPIRIC`

**TR2 Flags** - Resistances and abilities:

- Sustains: `SUST_STR`, `SUST_DEX`, `SUST_CON`, `SUST_GRA`
- Resistances: `RES_COLD`, `RES_FIRE`, `RES_ELEC`, `RES_POIS`, `RES_BLEED`,
  `RES_FEAR`, `RES_BLIND`, `RES_CONFU`, `RES_STUN`, `RES_HALLU`
- Abilities: `SLOW_DIGEST`, `LIGHT`, `REGEN`, `SEE_INVIS`, `FREE_ACT`, `SPEED`,
  `RADIANCE`
- Curses: `FEAR`, `HUNGER`, `DARKNESS`, `SLOWNESS`, `DANGER`, `AGGRAVATE`,
  `HAUNTED`, `TRAITOR`
- Vulnerabilities: `VUL_COLD`, `VUL_FIRE`, `VUL_POIS`

**TR3 Flags** - Miscellaneous:

- `DAMAGED`, `CHEAT_DEATH`, `STAND_FAST`, `ACCURATE`, `CUMBERSOME`,
  `AVOID_TRAPS`, `MEDIC`
- `NO_SMITHING`, `MITHRIL`, `AXE`, `POLEARM`
- `IGNORE_ACID`, `IGNORE_ELEC`, `IGNORE_FIRE`, `IGNORE_COLD`
- `THROWING`, `ENCHANTABLE`, `ACTIVATE`, `INSTA_ART`, `EASY_KNOW`,
  `MORE_SPECIAL`
- `HAND_AND_A_HALF`, `TWO_HANDED`
- `LIGHT_CURSE`, `HEAVY_CURSE`, `PERMA_CURSE`

#### Flag Effects Reference

**Hunger Flags** (see CODE_ANALYSIS.md Section 25):

| Flag          | Effect                              | Stacks |
| ------------- | ----------------------------------- | ------ |
| `SLOW_DIGEST` | Reduces hunger rate (hunger -= 1)   | Yes    |
| `HUNGER`      | Increases hunger rate (hunger += 1) | Yes    |

At hunger = -1, digestion happens ~1/3 as often. At hunger = +1, food is
consumed 3× faster.

**Speed Flag:**

| Flag    | Effect                                    |
| ------- | ----------------------------------------- |
| `SPEED` | Player speed += 1 (more actions per turn) |

**Resistance Flags** (TR2*RES*\*):

| Flag        | Protects Against         |
| ----------- | ------------------------ |
| `RES_FIRE`  | Fire damage (GF_FIRE)    |
| `RES_COLD`  | Cold damage (GF_COLD)    |
| `RES_ELEC`  | Electricity (GF_ELEC)    |
| `RES_POIS`  | Poison damage and status |
| `RES_BLEED` | Bleeding/wound effects   |
| `RES_FEAR`  | Fear status effects      |
| `RES_BLIND` | Blindness                |
| `RES_CONFU` | Confusion                |
| `RES_STUN`  | Stunning                 |
| `RES_HALLU` | Hallucination            |

**Vulnerability Flags** (TR2*VUL*\*):

| Flag       | Effect                    |
| ---------- | ------------------------- |
| `VUL_FIRE` | Extra fire damage taken   |
| `VUL_COLD` | Extra cold damage taken   |
| `VUL_POIS` | Extra poison damage taken |

______________________________________________________________________

### artefact.txt - Unique Artifact Definitions

Defines unique artifacts (Glamdring, Ringil, etc.). Uses same format as
`object.txt` but always has `INSTA_ART` flag.

#### Additional Fields

Same as `object.txt`, but artifacts typically have:

- Specific base item via tval/sval
- Pre-set bonuses and abilities
- Unique names and descriptions

______________________________________________________________________

### special.txt - Item Suffixes

Defines special item suffixes that can be applied to base items (e.g., "of
Gondolin", "of Free Action").

#### Format

```
N: suffix ID : suffix name
T: tval : min_sval : max_sval
X: extra type : extra value
W: depth : rarity : weight modifier : cost modifier
C: attack : damage : evasion : protection
F: flag | flag | ...
```

#### Field Details

| Field | Description                                                     |
| ----- | --------------------------------------------------------------- |
| `N`   | ID and suffix name (e.g., "of Gondolin")                        |
| `T`   | Applicable item types: tval, sval range                         |
| `X`   | Extra random ability type and max value                         |
| `W`   | Generation depth, rarity, weight/cost modifiers                 |
| `C`   | Combat modifiers: attack, damage dice, evasion, protection dice |
| `F`   | Flags granted by this suffix                                    |

______________________________________________________________________

### terrain.txt - Terrain Features

Defines all terrain types (floors, walls, doors, traps, etc.).

#### Format

```
N: unique ID : terrain name
G: symbol : color
M: mimic feature number
F: flag | flag | ...
D: description
```

#### Field Details

| Field | Description                              |
| ----- | ---------------------------------------- |
| `N`   | ID and name                              |
| `G`   | Symbol and color                         |
| `M`   | Mimic another feature (for hidden traps) |
| `F`   | Terrain flags (see below)                |
| `D`   | Description                              |

#### Terrain Flags

- Movement: `PASSABLE`, `FLOOR`, `WALL`, `PERMANENT`, `BRIDGE`
- Vision: `LOS`, `PROJECT`, `GLOW` (interact with
  `CAVE_VIEW`/`CAVE_SEEN`/`CAVE_MARK` runtime flags; see CODEBASE.md Section 32)
- Special: `DOOR`, `TRAP`, `STAIRS`, `SHAFT`, `CHASM`
- Effects: `FIERY`, `WATERY`, `ICY`, `ICKY`

#### Forges (Terrain Features with State)

Forges are terrain features that encode their **remaining uses** in the feature
ID itself. Each use count is a separate feature entry.

**Forge Types:**

| Type      | Name               | Smithing Bonus | Feature ID Range  |
| --------- | ------------------ | -------------- | ----------------- |
| Normal    | "forge"            | +0             | 0x40-0x45 (64-69) |
| Enchanted | "enchanted forge"  | +3             | 0x46-0x4B (70-75) |
| Unique    | "forge 'Orodruth'" | +7             | 0x4C-0x4F (76-79) |

**Feature ID Encoding:**

```
FEAT_FORGE_NORMAL_HEAD (0x40) + uses = Normal forge with N uses
FEAT_FORGE_GOOD_HEAD (0x46) + uses = Enchanted forge with N uses
FEAT_FORGE_UNIQUE_HEAD (0x4C) + uses = Orodruth with N uses
```

**Example entries from terrain.txt:**

```
N:64:forge (exhausted)           # Normal, 0 uses left
N:65:forge (1 use remaining)     # Normal, 1 use
N:66:forge (2 uses remaining)    # Normal, 2 uses
...
N:71:enchanted forge (1 use remaining)   # Enchanted, 1 use
...
N:77:forge 'Orodruth' (1 use remaining)  # Unique, 1 use
```

**Note:** The number of uses is NOT configurable in data files. Uses are
determined at dungeon generation time (see CODE_ANALYSIS.md). When a forge is
used, the game replaces the feature with the next lower ID.

______________________________________________________________________

### race.txt - Player Races

Defines the four playable races.

#### Format

```
N: race ID : race name
S: str : dex : con : gra
I: history : age_base : age_max
H: height : height_mod
W: weight : weight_mod
C: color_indices (e.g., 1|2|3)
F: flag | flag | ...
E: tval : sval : min : max
D: description
```

#### Field Details

| Field | Description                                          |
| ----- | ---------------------------------------------------- |
| `N`   | ID (0-3) and name                                    |
| `S`   | Stat modifiers: Str, Dex, Con, Gra                   |
| `I`   | History table start, base age, max age               |
| `H`   | Base height, height modifier                         |
| `W`   | Base weight, weight modifier                         |
| `C`   | Color indices for tile display (pipe-separated)      |
| `F`   | Race flags (skill affinities/penalties)              |
| `E`   | Starting equipment: tval, sval, min count, max count |
| `D`   | Description                                          |

#### Player Stats

Sil-Q uses four primary statistics that affect all characters. Stats are
modified by race and house selections.

| Stat         | Code    | Effects                                                  |
| ------------ | ------- | -------------------------------------------------------- |
| Strength     | `A_STR` | Melee damage bonus, carrying capacity, bow damage        |
| Dexterity    | `A_DEX` | Melee accuracy, Evasion skill bonus, Stealth skill bonus |
| Constitution | `A_CON` | Hit points per level, resistance to physical effects     |
| Grace        | `A_GRA` | Will skill bonus, Song skill bonus, Smithing skill bonus |

**Stat-to-Skill Bonuses** (Source: `xtra1.c:2794-2815`):

| Skill      | Primary Stat | Bonus Formula    |
| ---------- | ------------ | ---------------- |
| Melee      | DEX          | +1 per DEX point |
| Archery    | DEX          | +1 per DEX point |
| Evasion    | DEX          | +1 per DEX point |
| Stealth    | DEX          | +1 per DEX point |
| Perception | GRA          | +1 per GRA point |
| Will       | GRA          | +1 per GRA point |
| Smithing   | GRA          | +1 per GRA point |
| Song       | GRA          | +1 per GRA point |

**Strength Damage Bonus** (Source: `xtra1.c:1851-1869`):

- Melee: +1 damage per 2 STR points (rounded down)
- Archery: +1 damage per 4 STR points (varies by bow type)

**Constitution HP Bonus** (Source: `xtra1.c:2226-2233`):

- Base HP per level from race/house
- +1 HP per level per CON point above 0
- -1 HP per level per CON point below 0

#### Player Races

| ID  | Name    | Stat Mods   | Flags                                      |
| --- | ------- | ----------- | ------------------------------------------ |
| 0   | Noldor  | 0/+1/+2/+2  | BOW_PROFICIENCY, SNG_AFFINITY              |
| 1   | Sindar  | -1/+1/+2/+1 | BOW_PROFICIENCY, SNG_AFFINITY              |
| 2   | Naugrim | 0/-1/+3/+1  | AXE_PROFICIENCY, ARC_PENALTY, SMT_AFFINITY |
| 3   | Edain   | 0/0/0/0     | (none)                                     |

#### Race/House Flags (RHF\_\*)

- Proficiencies: `BOW_PROFICIENCY`, `AXE_PROFICIENCY`
- Affinities (+1 bonus, free ability): `MEL_AFFINITY`, `ARC_AFFINITY`,
  `EVN_AFFINITY`, `STL_AFFINITY`, `PER_AFFINITY`, `WIL_AFFINITY`,
  `SMT_AFFINITY`, `SNG_AFFINITY`
- Penalties (-1 penalty, +500 ability cost): `MEL_PENALTY`, `ARC_PENALTY`,
  `EVN_PENALTY`, `STL_PENALTY`, `PER_PENALTY`, `WIL_PENALTY`, `SMT_PENALTY`,
  `SNG_PENALTY`

______________________________________________________________________

### house.txt - Player Houses

Defines houses within each race, providing additional bonuses.

#### Format

```
N: house ID : house name
A: alternate house name
B: short house name
S: str : dex : con : gra
F: flag
D: description
```

#### Field Details

| Field | Description                             |
| ----- | --------------------------------------- |
| `N`   | ID and full name                        |
| `A`   | Alternate form (e.g., "Feanor's House") |
| `B`   | Short name for display                  |
| `S`   | Stat bonuses                            |
| `F`   | House flags (affinities)                |
| `D`   | Description                             |

#### Houses by Race

**Noldor Houses:**

- Feanor (SMT_AFFINITY, +1 Dex)
- Fingolfin (WIL_AFFINITY, +1 Con)
- Finarfin (PER_AFFINITY, +1 Gra)

**Sindar Houses:**

- Doriath (SNG_AFFINITY, +1 Gra)
- Falas (ARC_AFFINITY, +1 Dex)

**Naugrim Houses:**

- Nogrod (SMT_AFFINITY, +1 Dex)
- Belegost (WIL_AFFINITY, +1 Str)

**Edain Houses:**

- Beor (EVN_AFFINITY, +1 Gra)
- Haleth (STL_AFFINITY, +1 Dex)
- Hador (MEL_AFFINITY, +1 Str)

______________________________________________________________________

### ability.txt - Player Abilities

Defines all learnable player abilities/skills.

#### Format

```
N: ability number : ability name
I: skill number : ability value : level requirement
P: prerequisite_skill/prerequisite_ability : ...
T: tval : min_sval : max_sval
D: description
```

#### Field Details

| Field | Description                                            |
| ----- | ------------------------------------------------------ |
| `N`   | ID and name                                            |
| `I`   | Skill tree (0-7), position in tree, level requirement  |
| `P`   | Prerequisites as skill/ability pairs (colon-separated) |
| `T`   | Smithable onto items with matching tval/sval           |
| `D`   | Description                                            |

#### Skill Trees

| Skill # | Name       | Ability Range | Ultimate (stat bonus) |
| ------- | ---------- | ------------- | --------------------- |
| 0       | Melee      | 0-13          | Strength (level 20)   |
| 1       | Archery    | 20-28         | Dexterity (level 10)  |
| 2       | Evasion    | 40-50         | Dexterity (level 20)  |
| 3       | Stealth    | 60-66         | Dexterity (level 11)  |
| 4       | Perception | 80-89         | Grace (level 10)      |
| 5       | Will       | 100-110       | Constitution (lvl 12) |
| 6       | Smithing   | 120-127       | Grace (level 10)      |
| 7       | Song       | 140-153       | Grace (level 12)      |

#### Prerequisite Format (P: line)

Prerequisites use the format `skill_number/ability_value`. Multiple
prerequisites are colon-separated.

**Logic:** Multiple prerequisites on one P: line are **OR** conditions. Multiple
P: lines would be **AND** (but this pattern is not used).

**Examples:**

```
P:0/0:0/1          # Requires Melee ability 0 (Power) OR ability 1 (Finesse)
P:0/3:0/5          # Requires Polearm Mastery OR Follow-Through
P:0/7:3/4          # Requires Subtlety (Melee) OR Opportunist (Stealth)
```

**Cross-skill prerequisites:** Abilities can require abilities from other skill
trees:

- `Two Weapon Fighting` (Melee) requires `Parry` (Evasion skill #2)
- `Rapid Attack` (Melee) requires `Opportunist` (Stealth skill #3)

#### Smithable Item Types (T: line)

The T: line specifies which item types this ability can be smithed onto.

**Format:** `T:tval:min_sval:max_sval`

| tval | Item Type    | Notes                          |
| ---- | ------------ | ------------------------------ |
| 19   | Bows         |                                |
| 20   | Diggers      | Shovels, mattocks              |
| 21   | Hafted       | Hammers, quarterstaves         |
| 22   | Polearms     | Spears, glaives                |
| 23   | Swords       |                                |
| 30   | Boots        |                                |
| 31   | Gloves       | sval 1:1 = leather gloves only |
| 32   | Helm         |                                |
| 34   | Shields      |                                |
| 35   | Cloak        |                                |
| 36   | Soft Armour  | sval 2:2 = Robe only           |
| 37   | Mail         |                                |
| 39   | Light Source |                                |
| 40   | Amulet       |                                |
| 45   | Ring         |                                |

**Special sval restrictions:**

- `T:31:1:1` - Only leather gloves (Archery abilities)
- `T:36:2:2` - Only robes (Majesty ability)
- `T:21:8:8` - Only war hammers (Smithing abilities)
- `T:23:25:25` - Only greatswords (Impale)
- `T:22:0:4` - Polearms sval 0-4 only

#### Example: Complete Melee Skill Tree

| ID  | Ability             | Level  | Prerequisites          | Description                                   |
| --- | ------------------- | ------ | ---------------------- | --------------------------------------------- |
| 0   | Power               | 1      | -                      | +1 damage sides, harder crits                 |
| 1   | Finesse             | 2      | -                      | Crit threshold 7→5                            |
| 2   | Knock Back          | 3      | -                      | Push enemies back                             |
| 3   | Polearm Mastery     | 4      | -                      | +2 attack with polearms, set to receive       |
| 4   | Charge              | 5      | -                      | +3 STR/DEX when attacking after moving        |
| 5   | Follow-Through      | 6      | Power OR Finesse       | Continue attack on kill                       |
| 6   | Impale              | 7      | Power OR Polearm       | Strike through enemies                        |
| 7   | Subtlety            | 8      | Finesse                | -2 crit threshold (one-handed, free hand)     |
| 8   | Whirlwind Attack    | 9      | Polearm + Follow       | Free attacks on all adjacent enemies          |
| 9   | Zone of Control     | 10     | Finesse + Polearm      | Free attack when enemies move between squares |
| 10  | Smite               | 11     | Knock Back + Charge    | Max damage on first two-handed attack         |
| 11  | Two Weapon Fighting | 12     | Finesse + Parry        | Off-hand attack at -3 STR/DEX                 |
| 12  | Rapid Attack        | 13     | Subtlety + Opportunist | Extra attack at -3 STR/DEX                    |
| 13  | **Strength**        | **20** | -                      | **+1 Strength (ultimate)**                    |

______________________________________________________________________

### flavor.txt - Item Flavors

Defines visual "flavors" for items that need identification (rings, amulets,
potions, staves, horns, herbs).

#### Format

```
N: index : tval : sval (optional)
G: symbol : color
D: flavor name
```

#### Field Details

| Field | Description                           |
| ----- | ------------------------------------- |
| `N`   | ID, tval, and optional fixed sval     |
| `G`   | Display character and color           |
| `D`   | Flavor name (e.g., "Amethyst", "Oak") |

#### Flavor Categories

- **Rings** (tval 45): Amethyst, Beryl, Bloodstone, Emerald, etc.
- **Amulets** (tval 40): Amber, Coral, Ivory, Crystal, etc.
- **Staves** (tval 55): Aspen, Birch, Ebony, Oak, etc.
- **Horns** (tval 66): Silver, Brazen, Ivory, etc.
- **Herbs** (tval 80): Black, Yellow, Pale Green, etc.
- **Flasks** (tval 81): Bright Red, Golden, Sky Blue, etc.
- **Potions** (tval 75): Clear, Murky Brown, Crimson, etc.

Some flavors are "fixed" to specific items (with sval specified), like:

- Ring of Barahir → Serpentine
- Pearl 'Nimphelos' → Pearl (for amulets)

______________________________________________________________________

### Color Codes

Used in `G:` lines throughout data files:

| Code | Color               |
| ---- | ------------------- |
| `d`  | Black (or flavored) |
| `w`  | White               |
| `s`  | Gray                |
| `o`  | Orange              |
| `r`  | Red                 |
| `g`  | Green               |
| `b`  | Blue                |
| `u`  | Brown               |
| `D`  | Dark Gray           |
| `W`  | Light Gray          |
| `v`  | Violet              |
| `y`  | Yellow              |
| `R`  | Light Red           |
| `G`  | Light Green         |
| `B`  | Light Blue          |
| `U`  | Light Brown         |

Suffix `1` indicates a brighter/alternate shade (e.g., `r1` = bright red).

______________________________________________________________________

### Pref Files - Tile Assignments

**Location:** `lib/pref/*.prf`

PRF files map entities to tile coordinates in the tileset image.

#### Key Files

| File           | Content                                                           |
| -------------- | ----------------------------------------------------------------- |
| `graf-new.prf` | Monsters, objects, terrain, player tiles, special graphics        |
| `flvr-new.prf` | Flavor tiles (ring colors, staff types, etc.)                     |
| `xtra-new.prf` | Legacy file - NOT used by MicroChasm tiles (out-of-bounds coords) |

#### Tileset Dimensions (MicroChasm tiles)

| Property           | Value                                           |
| ------------------ | ----------------------------------------------- |
| Tileset file       | `lib/xtra/graf/16x16.bmp` (or `.png` for macOS) |
| Tile size          | 16×16 pixels                                    |
| Tileset dimensions | 512×256 pixels                                  |
| Rows               | 16 (coordinates 0x80-0x8F)                      |
| Columns            | 32 (coordinates 0x80-0x9F)                      |
| Total tiles        | 512                                             |

**Note:** The 512 tile limit is specific to MicroChasm's tileset, not a game
limitation. Larger tilesets could use coordinates up to 0xFF.

#### Line Formats

**Entity mappings:**

```
R:id:0xYY/0xXX    # Monster (id 0-3 are player races)
K:id:0xYY/0xXX    # Object (kind)
F:id:0xYY/0xXX    # Feature (terrain)
L:id:0xYY/0xXX    # Flavor
```

**Special graphics (S:):**

```
## Comment describing the graphic
S:0xID:0xYY/0xXX
```

S: entries use hex IDs and map special graphics like:

- Digits (0x00-0x09)
- Arrows in various directions (0x3F, 0x4F, 0x5F, 0x6F, 0x7F)
- Boulder graphics (0x32, 0x42, 0x52, 0x62, 0x72)
- Breath weapons (0x31, 0x34, 0x35, 0x38)
- Spell effects (0x50, 0x51)

#### Coordinate Format

```
0xYY/0xXX
  │    │
  │    └── Column = 0xXX - 0x80 (0-31 for MicroChasm)
  └─────── Row = 0xYY - 0x80 (0-15 for MicroChasm)
```

**Pixel position:** `x = (0xXX - 0x80) * 16`, `y = (0xYY - 0x80) * 16`

#### Player Tiles by Race

Player tiles (R:0 through R:3) are assigned by **race only**, not race+house:

| R:id | Race    | Tile        | Row | Column Range             |
| ---- | ------- | ----------- | --- | ------------------------ |
| R:0  | Noldor  | `0x8D/0x80` | 13  | 0-15 (equipment states)  |
| R:1  | Sindar  | `0x8D/0x90` | 13  | 16-31 (equipment states) |
| R:2  | Naugrim | `0x8E/0x80` | 14  | 0-15 (equipment states)  |
| R:3  | Edain   | `0x8E/0x90` | 14  | 16-31 (equipment states) |

**House has no effect on player tile.** Each race has 16 tile variants for
different equipment states (see WORLD_MODEL.md for the 16 states).

#### Example Entity Tiles

| Entity           | Type    | ASCII       | Tile Coordinates  |
| ---------------- | ------- | ----------- | ----------------- |
| Wolf             | Monster | `C` (umber) | `R:11:0x88/0x91`  |
| Morgoth          | Monster | `V` (dark)  | `R:251:0x8A/0x92` |
| Player (Noldor)  | Race 0  | `@` (white) | `R:0:0x8D/0x80`   |
| Player (Naugrim) | Race 2  | `@` (white) | `R:2:0x8E/0x80`   |

______________________________________________________________________

### Entity Counts

Current counts from data files vs limits.txt:

| Entity    | File         | Count | Limit |
| --------- | ------------ | ----- | ----- |
| Monsters  | monster.txt  | 152   | 656   |
| Objects   | object.txt   | 196   | 600   |
| Artifacts | artefact.txt | 122   | 251   |
| Specials  | special.txt  | 73    | 145   |
| Features  | terrain.txt  | 84    | 86    |
| Abilities | ability.txt  | 84    | 240   |
| Flavors   | flavor.txt   | 108   | 310   |
| Races     | race.txt     | 4     | 4     |
| Houses    | house.txt    | 11    | 11    |
