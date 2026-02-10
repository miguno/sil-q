# Sil-Q C Code Analysis

This document identifies hardcoded behavior in `src/*.c` files that extends or
modifies the data defined in `lib/edit/*.txt` files.

## Overview

While most entity definitions live in data files, significant game behavior is
hardcoded in C. This analysis identifies these behaviors for inclusion in the
world database schema and documentation.

______________________________________________________________________

## 1. Monster Index Constants

Special monsters with hardcoded behavior identified by `R_IDX_*` constants in
`defines.h`:

| Constant                   | ID  | Monster            | Special Behavior                                        |
| -------------------------- | --- | ------------------ | ------------------------------------------------------- |
| `R_IDX_MORGOTH`            | 251 | Morgoth            | Progressive difficulty, truce system, victory condition |
| `R_IDX_CARCHAROTH`         | 253 | Carcharoth         | Special placement logic                                 |
| `R_IDX_HUMAN_THRALL`       | 13  | Human Thrall       | Quest system                                            |
| `R_IDX_ELF_THRALL`         | 14  | Elf Thrall         | Quest system                                            |
| `R_IDX_ORC_THRALLMASTER`   | 15  | Orc Thrallmaster   | Quest target                                            |
| `R_IDX_ALERT_HUMAN_THRALL` | 16  | Alert Human Thrall | Quest completion                                        |
| `R_IDX_ALERT_ELF_THRALL`   | 17  | Alert Elf Thrall   | Quest completion                                        |
| `R_IDX_BARROW_WIGHT`       | 112 | Barrow-wight       | Special placement                                       |
| `R_IDX_YOUNG_COLD_DRAKE`   | 164 | Young Cold Drake   | Level-specific placement                                |
| `R_IDX_YOUNG_FIRE_DRAKE`   | 181 | Young Fire Drake   | Level-specific placement                                |

### Morgoth's Progressive Difficulty System

Source: `xtra2.c` - `anger_morgoth()` function

Morgoth's stats change based on `p_ptr->morgoth_state`:

| State | Trigger                  | Changes                              |
| ----- | ------------------------ | ------------------------------------ |
| 0     | Initial                  | evn=20, att=20, wil=25, per=10       |
| 1     | Crown lost               | evn=22, light=0, per=15              |
| 2     | Hurt or Silmarils stolen | att=30, dd=7, wil=30, per=20, evn=25 |
| 3     | Badly hurt               | pd=7, wil=35, per=25                 |
| 4     | Desperate                | evn=30, att=40, dd=8, wil=40, per=30 |

### Truce System

Source: `melee2.c`, `xtra2.c`

- `break_truce()` - Ends peaceful Morgoth encounter
- Morgoth won't move or attack during truce
- Truce broken by: attacking, stealing Silmarils, aggressive actions
- Affects `p_ptr->truce` flag

______________________________________________________________________

## 2. Quest System (Thralls)

Source: `cmd1.c:22-32`

Hardcoded quest arrays for thrall rescue missions:

```c
static const char* quest_text[] = {...};
static const int quest_skill[] = {...};  // Skill requirements
static const int quest_ability[] = {...};  // Ability rewards
```

Quest mechanics:

- Quest indexed by `(r_idx - R_IDX_ALERT_HUMAN_THRALL)`
- `p_ptr->thrall_quest` tracks completion state
- `reward_player_for_quest()` grants hardcoded abilities

______________________________________________________________________

## 3. Silmaril System

### Item Constants

| Constant                | sval | Item                                |
| ----------------------- | ---- | ----------------------------------- |
| `SV_LIGHT_SILMARIL`     | 9    | The Silmarils (primary quest items) |
| `SV_LIGHT_FEANORIAN`    | 8    | Feanorian Lamp                      |
| `SV_LIGHT_LESSER_JEWEL` | 2    | Lesser Jewel                        |

### Hardcoded Behavior

Source: Multiple files

| File (in `src/`)  | Function/Location       | Behavior                                         |
| ----------------- | ----------------------- | ------------------------------------------------ |
| `files.c:4035`    | `silmarils_possessed()` | Counts Silmarils in inventory                    |
| `cmd2.c:150`      | Escape check            | Cannot flee with Silmarils from throne room      |
| `cmd3.c:965-1025` | Messages                | Different text for 1st, 2nd, 3rd Silmaril        |
| `cmd3.c`          | `prise_silmaril()`      | Hardcoded DC checks for removal                  |
| `generate.c:3754` | Dungeon danger          | Silmaril count affects monster generation        |
| `cmd3.c:1138`     | Crown state             | Crown appearance changes based on Silmaril count |

______________________________________________________________________

## 4. Smithing System

Source: `cmd4.c:2040-2850`

### Attack Bonus Caps

| Item Type        | Non-Artifact Max | Artifact Max | Ego Max |
| ---------------- | ---------------- | ------------ | ------- |
| Arrows           | +3               | +8           | +0      |
| Melee weapons    | +1 + ego         | +4           | varies  |
| Armor            | +0 to +1         | varies       | varies  |
| Ring of Accuracy | +4               | -            | +1      |

### Special Item Rules

- **Evasion Ring** (`SV_RING_EVASION`): Special modification limits
- **Protection Ring** (`SV_RING_PROTECTION`): Special modification limits
- **Cloaks, Robes, Corslets**: Distinct armor type rules
- **Gloves/Boots/Helm/Crown**: Separate modification caps

### Difficulty Calculation

- Base difficulty from item properties
- +1 difficulty per pval increment
- Special handling for enchantments

______________________________________________________________________

## 5. Combat System

### Damage Calculation Chain

Source: `xtra1.c`, `cmd1.c`

```
Total Damage = base_sides + str_mod + equipment_bonus
  where str_mod is capped by weapon weight for bows
```

### Skill Bonus Functions

| Function              | Source        | Effect                        |
| --------------------- | ------------- | ----------------------------- |
| `axe_bonus()`         | `xtra1.c:180` | +1 for racial axe proficiency |
| `polearm_bonus()`     | `xtra1.c`     | +2 for MEL_POLEARMS ability   |
| `total_ads()`         | `xtra1.c`     | Archery damage calculation    |
| `elf_bane_bonus()`    | `cmd4.c`      | Bonus vs elves                |
| `bane_bonus()`        | `cmd4.c`      | General monster-type bonuses  |
| `spider_bane_bonus()` | `cmd4.c`      | Spider-specific bonus         |

### Critical Hit Modifiers

Source: `cmd1.c:995-1084`

| Ability/Flag     | Effect                           |
| ---------------- | -------------------------------- |
| `MEL_FINESSE`    | Lowers crit threshold            |
| `MEL_POWER`      | Adds damage but raises threshold |
| `TR3_CUMBERSOME` | Prevents criticals               |
| `RF1_RES_CRIT`   | Doubles threshold requirement    |
| `RF1_NO_CRIT`    | Immune to criticals              |

### Monster Attack Structure

```c
monster_blow blow[MONSTER_BLOW_MAX];  // Up to 4 attacks
struct {
    byte method;   // RBM_* constant
    byte effect;   // RBE_* constant
    byte att;      // Attack bonus
    byte dd, ds;   // Damage dice
}
```

Special cases:

- `RBM_SPORE`: Always hits, no criticals

______________________________________________________________________

## 6. Two-Weapon Combat

Source: `xtra1.c`, `cmd1.c`

| Variable/Function    | Purpose                     |
| -------------------- | --------------------------- |
| `two_handed_melee()` | Checks weapon configuration |
| `offhand_mel_mod`    | Two-weapon penalty modifier |
| `MEL_TWO_WEAPON`     | Enables second attack       |
| `MEL_RAPID_ATTACK`   | Modifies dual-wield bonus   |

Attack calculation: `cmd1.c:4088-4154`

______________________________________________________________________

## 7. Ability System

### Ability Types

| Array                           | Description               |
| ------------------------------- | ------------------------- |
| `p_ptr->innate_ability[S_*][*]` | Personal/racial abilities |
| `p_ptr->have_ability[S_*][*]`   | Combined with equipment   |

### Skill System

| Variable            | Purpose                 |
| ------------------- | ----------------------- |
| `skill_base[]`      | Base skill level        |
| `skill_use[]`       | Final effective skill   |
| `skill_equip_mod[]` | Equipment modifications |

Affected by pval items via TR1_MEL, TR1_ARC, etc.

______________________________________________________________________

## 8. Channeling System

Source: `object2.c`, `cmd6.c`, `use-obj.c`

| Constant                       | Value | Purpose                 |
| ------------------------------ | ----- | ----------------------- |
| `CHANNELING_CHARGE_MULTIPLIER` | 2     | Staff charge efficiency |

`WIL_CHANNELING` ability:

- Halves staff charge consumption
- Special charge display (`object2.c:4475, 4629`)
- Usage logic (`use-obj.c:537-557`)

______________________________________________________________________

## 9. Terrain Interactions

### Warded Features

| Feature        | Constant | Behavior                    |
| -------------- | -------- | --------------------------- |
| `FEAT_WARDED`  | -        | Basic ward                  |
| `FEAT_WARDED2` | -        | Stronger ward               |
| `FEAT_WARDED3` | -        | Strongest ward              |
| `FEAT_GLYPH`   | -        | Special monster interaction |

### Movement Features

| Feature         | Effect                           |
| --------------- | -------------------------------- |
| `FEAT_CHASM`    | Monster movement restrictions    |
| `FEAT_SUNLIGHT` | Affects light-sensitive monsters |
| `FEAT_RUBBLE`   | Movement cost changes            |

Door difficulty calculations: `melee2.c:838-898`

______________________________________________________________________

## 10. Depth-Based Rules

### MORGOTH_DEPTH (Level 100)

Special behaviors triggered at this depth:

| Behavior             | Source           | Description              |
| -------------------- | ---------------- | ------------------------ |
| Monster generation   | `generate.c`     | Special level caps       |
| Object drops         | `object2.c:3541` | Depth adjustment formula |
| Escape restrictions  | `cmd2.c:150`     | Need Silmarils to leave  |
| Truce message        | `dungeon.c:2665` | Initial encounter text   |
| Ability restrictions | Various          | Some abilities disabled  |

### Unique Monster Placement

Source: `generate.c:2700-2915`

Hardcoded level ranges for uniques:

- Carcharoth, Barrow-wight: Specific depth
- Dragons: Level-appropriate placement
- Gothmog, Glaurung, Gorthaur, Ungoliant: Levels 6-9
- Aldor: Unique placement logic

______________________________________________________________________

## 11. Monster AI

### Perception System

Source: `melee2.c:5969`

Detection difficulty calculation with modifiers for:

- Distance, light levels
- Player stealth vs monster perception
- Special abilities

### Morale System

Source: `melee2.c:5576-5630`

Affected by:

- Bane bonuses
- Elf bane
- `RF3_TROLL` regeneration
- `RF3_NO_FEAR` immunity

______________________________________________________________________

## 12. Knockback System

Source: `cmd1.c:3750-3858`

| Variable/Function     | Purpose                              |
| --------------------- | ------------------------------------ |
| `p_ptr->knocked_back` | Persistence flag                     |
| `knock_back()`        | Distance calculation                 |
| Evasion penalty       | -5 when knocked out (`xtra1.c:2923`) |

______________________________________________________________________

## 13. Special Items

### Staff of Treasures

- sval: `SV_STAFF_TREASURES`
- Source: `object2.c:1981`, `spells2.c:1682`
- Effect: Hardcoded chest generation

### Ring of Accuracy

- sval: `SV_RING_ACCURACY`
- Smithing caps: +4 max, +1 min
- Source: `cmd4.c:2047, 2120, 2164`

### Light Sources

Special timeout handling for:

- `SV_LIGHT_FEANORIAN`
- `SV_LIGHT_LESSER_JEWEL`
- Active light drain: `dungeon.c:65-69`

______________________________________________________________________

## 14. Scoring System

Source: `files.c:3512-3516`

Factors in scoring calculation:

- `p_ptr->prace` (race)
- Silmaril count
- Dungeon depth reached
- Difficulty settings

______________________________________________________________________

## 15. Hardcoded Constants

### Light Radius Values

Source: `defines.h:1172-1178`

| Constant              | Value | Item           |
| --------------------- | ----- | -------------- |
| `RADIUS_TORCH`        | 1     | Wooden Torch   |
| `RADIUS_LESSER_JEWEL` | 1     | Lesser Jewel   |
| `RADIUS_LANTERN`      | 2     | Brass Lantern  |
| `RADIUS_MALLORN`      | 3     | Mallorn Torch  |
| `RADIUS_FEANORIAN`    | 4     | Feanorian Lamp |
| `RADIUS_SILMARIL`     | 7     | Silmaril       |

**Note:** Light radius values are NOT in data files - they are hardcoded
constants.

### Speed and Energy System

Source: `tables.c:115-124`, `xtra1.c:2235`, `dungeon.c:2822-2835`

The energy system determines turn order. Each game tick, creatures gain energy
based on speed:

```c
const byte extract_energy[8] = {
    /* 0: impossible */ 5,
    /* 1: Slow */       5,
    /* 2: Normal */     10,
    /* 3: Fast */       15,
    /* 4: V Fast */     20,
    /* 5: X Fast */     25,
    /* 6: I Fast */     30,
    /* 7: A Fast */     35,
};
```

**Player speed:**

- Default: 2 (Normal) - hardcoded in `xtra1.c:2235`
- Range: **1 to 3 only** - clamped in `xtra1.c:2701-2704`
- Cannot be configured in data files (race.txt, etc.)
- Modified by `TR2_SPEED` equipment flag (+1) or slow effects (-1)

**Monster speed:**

- Configured in `monster.txt` via `I:` line (first field)
- Range: 1 to 7+ (no upper clamp)
- Modified at runtime by haste/slow effects

**Database Implication:** Player base speed is not an entity property - it's a
global constant. Monster speed IS a property from data files.

### Trap Damage Values

Source: `cmd1.c:3050-3350`

| Trap Type       | FEAT Constant          | Damage/Effect              |
| --------------- | ---------------------- | -------------------------- |
| False floor     | `FEAT_TRAP_FALSE`      | Fall damage based on depth |
| Pit             | `FEAT_TRAP_PIT`        | 1d4 damage                 |
| Spiked pit      | `FEAT_TRAP_SPIKED`     | 1d4 + 2d6 spikes           |
| Dart            | `FEAT_TRAP_DART`       | 1d15 damage + STR drain    |
| Gas (confusion) | `FEAT_TRAP_GAS_CONF`   | Confusion effect           |
| Gas (memory)    | `FEAT_TRAP_GAS_MEMORY` | Memory loss effect         |
| Flash           | `FEAT_TRAP_FLASH`      | Blindness + hallucination  |
| Caltrops        | `FEAT_TRAP_CALTROPS`   | 1d4 damage + slow          |
| Roost           | `FEAT_TRAP_ROOST`      | Summons bats/birds         |
| Web             | `FEAT_TRAP_WEB`        | Entraps player             |
| Deadfall        | `FEAT_TRAP_DEADFALL`   | 3d6 damage + stun          |
| Acid            | `FEAT_TRAP_ACID`       | 2d6 acid damage            |
| Bell            | `FEAT_TRAP_BELL`       | Alerts nearby monsters     |

**Note:** All trap effects are 100% hardcoded in C - no trap data exists in txt
files.

______________________________________________________________________

## 16. Monster Flag Behavior

### Random Movement Flags

Source: `melee2.c:5131-5143`

The `RF1_RAND_25` and `RF1_RAND_50` flags are **cumulative**:

```c
if (r_ptr->flags1 & (RF1_RAND_25))
{
    chance += 25;
}
if (r_ptr->flags1 & (RF1_RAND_50))
{
    chance += 50;
}
```

| Flag Combination   | Random Movement Chance |
| ------------------ | ---------------------- |
| Neither            | 0%                     |
| `RF1_RAND_25` only | 25%                    |
| `RF1_RAND_50` only | 50%                    |
| Both flags         | 75%                    |

### Critical Hit Resistance Flags

Source: `cmd1.c:1050-1070`

| Flag           | Effect                             |
| -------------- | ---------------------------------- |
| `RF1_RES_CRIT` | Doubles critical hit threshold     |
| `RF1_NO_CRIT`  | Complete immunity to critical hits |

______________________________________________________________________

## 17. Status Effects System

Source: `externs.h`, `spells1.c`, `xtra1.c`

Player status effects are stored as counters in `p_ptr`:

| Variable           | Effect        | Damage/Turn | Source                |
| ------------------ | ------------- | ----------- | --------------------- |
| `p_ptr->poisoned`  | Poison        | =counter    | `spells1.c:1325-1336` |
| `p_ptr->blind`     | Blindness     | -           | Vision disabled       |
| `p_ptr->confused`  | Confusion     | -           | Random movement       |
| `p_ptr->afraid`    | Fear          | -           | Cannot attack         |
| `p_ptr->image`     | Hallucination | -           | Visual distortion     |
| `p_ptr->stun`      | Stun          | -           | Skill penalties       |
| `p_ptr->cut`       | Bleeding      | varies      | HP loss over time     |
| `p_ptr->slow`      | Slowed        | -           | Movement penalty      |
| `p_ptr->entranced` | Entranced     | -           | Cannot act            |

### Poison Mechanics

Source: `spells1.c:1325-1336`

```c
void pois_dam_mixed(int dam)
{
    if (dam <= 0)
        return;
    set_poisoned(p_ptr->poisoned + dam);  // Accumulates!
    ident_resist(TR2_RES_POIS);
}
```

- Poison damage **equals** the poison counter value
- Counter **accumulates** with multiple poison sources
- Decrements each turn
- `TR2_RES_POIS` reduces incoming poison

______________________________________________________________________

## 18. Item Effects (Consumables)

Source: `use-obj.c`

All consumable item effects are 100% hardcoded by sval. The data files define
item names, weights, and costs, but **not** their effects.

### Herbs (TV_FOOD)

| sval | Herb Name            | Hardcoded Effect   |
| ---- | -------------------- | ------------------ |
| 0    | Herb of Rage         | +STR, berserk mode |
| 1    | Herb of Terror       | Fear effect        |
| 2    | Herb of Healing      | Restore HP         |
| 3    | Herb of Restoration  | Restore stats      |
| 4    | Herb of Sickness     | CON damage         |
| 5    | Herb of Entrancement | Entrance self      |
| ...  | ...                  | ...                |

### Potions (TV_POTION)

| sval | Potion Name       | Hardcoded Effect             |
| ---- | ----------------- | ---------------------------- |
| 0    | Miruvor           | Restore voice                |
| 1    | Orcish Liquor     | Confusion + healing          |
| 2    | Potion of Clarity | Cure confusion/hallucination |
| ...  | ...               | ...                          |

### Staves (TV_STAFF)

| sval | Staff Name        | Hardcoded Effect  |
| ---- | ----------------- | ----------------- |
| 0    | Staff of Light    | Light area        |
| 1    | Staff of Doorways | Detect/lock doors |
| 2    | Staff of Foes     | Detect monsters   |
| ...  | ...               | ...               |

**Database Implication:** Item effects must be documented separately from item
data files, or effect descriptions extracted from C code.

______________________________________________________________________

## 19. Attack Effects (Monster Blows)

Source: `melee1.c`, `spells1.c`

Monster attack effects (`RBE_*` constants) are defined in data files but their
**implementation** is hardcoded:

| Effect Constant | Implementation                        |
| --------------- | ------------------------------------- |
| `RBE_HURT`      | Direct HP damage                      |
| `RBE_POISON`    | Adds to poison counter                |
| `RBE_DISEASE`   | CON damage + poison                   |
| `RBE_DARK`      | Temporary blindness                   |
| `RBE_CONFUSE`   | Adds confusion                        |
| `RBE_TERRIFY`   | Fear effect                           |
| `RBE_PARALYZE`  | Entrance                              |
| `RBE_HALLU`     | Hallucination                         |
| `RBE_SLOW`      | Slow effect                           |
| `RBE_DRAIN_EXP` | Experience drain                      |
| `RBE_ENTRANCE`  | Entrance                              |
| `RBE_FIRE`      | Fire damage (reduced by RES_FIRE)     |
| `RBE_COLD`      | Cold damage (reduced by RES_COLD)     |
| `RBE_ACID`      | Acid damage + equipment damage        |
| `RBE_ELEC`      | Electric damage (reduced by RES_ELEC) |

______________________________________________________________________

## 20. Forge System

Source: `object2.c:4398-4455`, `cmd4.c:2813-2844`

### Forge Generation

Forges are placed during dungeon generation with randomized uses and type:

```c
// object2.c:place_forge()
uses = 2 + damroll(1, 2);  // 3-4 uses randomly

// Exception: early levels always get 3 uses
if (p_ptr->depth <= 2) {
    uses = 3;
    power = 0;  // No enchanted/unique forges
}
```

### Forge Type Selection

Type is determined by a "power" roll - roll d1000 once per dungeon level, keep
highest:

| Power Roll             | Forge Type        | Bonus | Max Uses |
| ---------------------- | ----------------- | ----- | -------- |
| < 990                  | Normal            | +0    | 5        |
| 990-999                | Enchanted         | +3    | 5        |
| 1000 (first time only) | Unique (Orodruth) | +7    | 3        |

### Forge Bonus Calculation

Source: `cmd4.c:2831-2844`

```c
static int forge_bonus(int y, int x) {
    if (feat <= FEAT_FORGE_NORMAL_TAIL) return 0;   // Normal
    if (feat <= FEAT_FORGE_GOOD_TAIL) return 3;     // Enchanted
    else return 7;                                   // Unique
}
```

### State Encoding

Uses are encoded in the feature ID. When a forge is used:

1. Current feature ID is decremented
2. When ID reaches `*_HEAD + 0`, forge is exhausted

**Not configurable in data files:** The uses and bonuses are hardcoded in C.

______________________________________________________________________

## 21. Morgoth's Crown and Silmaril System

Source: `cmd3.c:965-1183`, `artefact.txt:1580-1635`

### Crown Versions

The crown exists as **4 separate artefacts**, one for each Silmaril count:

| Artefact ID | Constant        | Silmarils | Notes                               |
| ----------- | --------------- | --------- | ----------------------------------- |
| 178         | `ART_MORGOTH_3` | 3         | Initial state when Morgoth drops it |
| 177         | `ART_MORGOTH_2` | 2         | After 1st Silmaril removed          |
| 176         | `ART_MORGOTH_1` | 1         | After 2nd Silmaril removed          |
| 175         | `ART_MORGOTH_0` | 0         | All Silmarils removed               |

When you remove a Silmaril, the crown's artefact ID is decremented
(`o_ptr->name1--`).

### Silmaril Removal Difficulty

Source: `cmd3.c:985, 1047-1074`

The removal is a **combat roll** against the crown. To do this, the player has
to stand over the crown and press `k`.

The crown has a protection of `10d4`. The player must first make a successful
hit with their attack, and then the attack's damage roll must also exceed the
crown's protection roll.

```c
int pd = 10;  // Crown's protection dice (HARDCODED)

// Player attack's hit roll
hit_result = hit_roll(attack_mod, 0, PLAYER, NULL, TRUE);
// Player attack's damage roll
dam = damroll(p_ptr->mdd + crit_bonus_dice, mds);

// Crown's protection roll
prt = damroll(pd, 4);  // 10d4, average 25

// Success if you deal net damage
net_dam = dam - prt;
if (net_dam > 0) { /* Silmaril freed */ }
```

**To adjust difficulty:** Edit `cmd3.c:985`:

- `int pd = 10;` - Lower = easier, Higher = harder
- pd=10 means 10d4 protection (10-40, average 25)

### Progressive Consequences

| Silmaril # | Noise | Special Consequence                       |
| ---------- | ----- | ----------------------------------------- |
| 1st (3→2)  | 5     | None                                      |
| 2nd (2→1)  | 10    | 50% weapon shatters (`shatter_weapon(2)`) |
| 3rd (1→0)  | 15    | Weapon always shatters, player cursed     |

The `p_ptr->crown_shatter` flag (from a special ability) bypasses weapon
shattering.

### Silmaril Item Creation

When freed, a Silmaril is created as an inventory item.

From `prise_silmaril()` in `cmd3.c`:

```c
// Make Silmaril
object_prep(o_ptr, lookup_kind(TV_LIGHT, SV_LIGHT_SILMARIL));
// Get it
slot = inven_carry(o_ptr, FALSE);
```

______________________________________________________________________

## 22. Graphics and Tileset System

### Tileset Selection

Source: `main-win.c:1264-1277`, `main-x11.c:2706-2724`, `main-cocoa.m:2874-2877`

The default tileset (MicroChasm's) is **hardcoded** in platform-specific files:

| Platform  | File (in `src/`)    | Tileset Path                         |
| --------- | ------------------- | ------------------------------------ |
| Windows   | `main-win.c:1269`   | `lib/xtra/graf/16X16.BMP`            |
| X11/Linux | `main-x11.c:2709`   | `lib/xtra/graf/16x16.bmp`            |
| macOS     | `main-cocoa.m:2877` | `lib/xtra/graf/16x16_microchasm.png` |

**Graphics mode constant:** `defines.h:3120`

```c
#define GRAPHICS_MICROCHASM 1
```

### Tile Coordinate System

Tile coordinates use a **0x80-based hex system**:

```
Coordinate format: 0xYY/0xXX
  YY = Row (0x80 = row 0, 0x81 = row 1, ...)
  XX = Column (0x80 = col 0, 0x81 = col 1, ...)
```

**Current MicroChasm tileset:**

- Dimensions: 512x256 pixels (16x16 pixel tiles)
- Rows: 16 (`0x80` to `0x8F`)
- Columns: 32 (`0x80` to `0x9F`)
- Total tiles: 512

**Maximum theoretical:**

- Rows: 256 (`0x80` to `0xFF`, minus reserved range)
- Columns: 256 (`0x80` to `0xFF`)
- Total: 65,536 tiles (with larger bitmap)

### Player Tiles

Player tiles are assigned **by race only**, not by race+house combination:

| Race ID | Race    | Tile Coordinates | Source             |
| ------- | ------- | ---------------- | ------------------ |
| 0       | Noldor  | `0x8D/0x80`      | `graf-new.prf:520` |
| 1       | Sindar  | `0x8D/0x90`      | `graf-new.prf:523` |
| 2       | Naugrim | `0x8E/0x80`      | `graf-new.prf:526` |
| 3       | Edain   | `0x8E/0x90`      | `graf-new.prf:529` |

Each race has 16 equipment state variants (columns 0x80-0x8F or 0x90-0x9F).

**House has no effect on player tile.** All members of a race use the same base
tile.

### PRF File Loading (`*.prf`)

Source: `object1.c:271-272`, `dungeon.c:2846-2863`

```c
// Graphics mode PRF
process_pref_file("graf.prf");  // Loads graf-new.prf for MicroChasm

// Race-specific PRF (ASCII colors)
process_pref_file("races.prf");  // Loads noldor.prf, sindar.prf, etc.
```

The `ANGBAND_GRAF` variable (`variable.c:594`) controls which PRF variant to
load:

- `"old"` → default (no graphics)
- `"new"` → MicroChasm tiles (graf-new.prf)

______________________________________________________________________

## 23. Min Depth System (Anti-Scumming)

Source: `cmd2.c:17-39`

The min_depth system prevents "stair scumming" (repeatedly using stairs to
regenerate levels for better loot/easier monsters).

### The min_depth() Function

```c
int min_depth(void)
{
    int min = 0;

    // After 1000ft, min depth increases based on deepest level reached
    if (p_ptr->max_depth > 20)
    {
        min = p_ptr->max_depth - 20;
    }

    // Each 1000 turns adds +1 to min depth (up to max_depth)
    min += p_ptr->turn / 1000;

    // Can never exceed deepest level reached
    if (min > p_ptr->max_depth) min = p_ptr->max_depth;

    return min;
}
```

### Mechanics

| Condition      | Min Depth Calculation              |
| -------------- | ---------------------------------- |
| Depth ≤ 1000ft | `turn / 1000` (time penalty only)  |
| Depth > 1000ft | `(max_depth - 20) + (turn / 1000)` |
| Cap            | Never exceeds `max_depth`          |

**Key Variables:**

- `p_ptr->depth` - Current dungeon depth (in 50ft units, so 20 = 1000ft)
- `p_ptr->max_depth` - Deepest level ever reached
- `p_ptr->turn` - Total game turns elapsed

### Effect on Stairs

When attempting to go upstairs, if `p_ptr->depth <= min_depth()`:

- The stairs are **blocked**
- Message: "These stairs are blocked."
- Player cannot ascend

This forces players to continue deeper rather than farming early levels
indefinitely.

______________________________________________________________________

## 24. Stair Mechanics

Source: `cmd2.c:105-230` (up stairs), `cmd2.c:233-330` (down stairs)

### Stair Types

From `lib/edit/terrain.txt`:

| Feature ID | Name           | Depth Change       |
| ---------- | -------------- | ------------------ |
| 6          | up staircase   | -1 level (-50ft)   |
| 7          | down staircase | +1 level (+50ft)   |
| 8          | up shaft       | -2 levels (-100ft) |
| 9          | down shaft     | +2 levels (+100ft) |

### Up Stair Logic (`do_cmd_go_up`)

1. **Check for stair feature** at player position
2. **Check min_depth restriction** (see Section 23)
3. **Special throne room check**: Cannot escape with Silmarils from depth 20
   (1000ft)
4. **Calculate new depth**:
   - Regular stairs: `new_depth = p_ptr->depth - 1`
   - Shaft: `new_depth = p_ptr->depth - 2`
5. **Victory check**: If `new_depth <= 0` and carrying Silmarils → GAME WON
6. **Generate new level** via `generate_cave()`

### Down Stair Logic (`do_cmd_go_down`)

1. **Check for stair feature** at player position
2. **Calculate new depth**:
   - Regular stairs: `new_depth = p_ptr->depth + 1`
   - Shaft: `new_depth = p_ptr->depth + 2`
3. **Update max_depth** if going deeper than before
4. **Generate new level** via `generate_cave()`

### Shaft Generation

Shafts are rarer than regular stairs. Generation probability is controlled in
`generate.c`.

### Special Cases

| Case                   | Behavior                                                                    |
| ---------------------- | --------------------------------------------------------------------------- |
| Depth 0 (Gates)        | No up stairs available                                                      |
| Depth 1                | Going up leads to Gates (depth 0)                                           |
| Throne room (depth 20) | Cannot go up with Silmarils (victory must be earned by escaping from Gates) |
| Max depth              | No down stairs generated beyond dungeon limit                               |

______________________________________________________________________

## 25. Hunger/Food System

Source: `defines.h:391-395`, `dungeon.c:2199-2266`, `xtra1.c:589-618`

### Food Thresholds

| Constant         | Value | Status Display   | Color       |
| ---------------- | ----- | ---------------- | ----------- |
| `PY_FOOD_STARVE` | 1     | (death imminent) | -           |
| `PY_FOOD_WEAK`   | 1000  | "Weak"           | Orange      |
| `PY_FOOD_ALERT`  | 2000  | "Hungry"         | Yellow      |
| `PY_FOOD_FULL`   | 5000  | (blank)          | Light green |
| `PY_FOOD_MAX`    | 8000  | "Full"           | Green       |

### Hunger Rate

The `p_ptr->hunger` variable controls digestion speed (`xtra1.c:2382-2407`):

| Hunger Value | Effect                          | Items                 |
| ------------ | ------------------------------- | --------------------- |
| -1 or lower  | Slower digestion (1/3^n chance) | SLOW_DIGEST equipment |
| 0            | Normal rate                     | Default               |
| +1 or higher | Faster digestion (×3^n)         | HUNGER equipment      |

**Digestion Formula** (`dungeon.c:2204-2225`):

```c
// Slow hunger (negative) - statistical reduction
if (p_ptr->hunger < 0) {
    if (!one_in_(int_exp(3, -(p_ptr->hunger))))
        return;  // Skip digestion this turn
}
// Fast hunger (positive) - multiplied
else if (p_ptr->hunger > 0) {
    food_loss *= int_exp(3, p_ptr->hunger);
}

set_food(p_ptr->food - food_loss);
```

### Starvation Effects

| Food Level    | Effect                       |
| ------------- | ---------------------------- |
| < WEAK (1000) | STR -1 (`xtra1.c:2655-2658`) |
| < STARVE (1)  | HP damage each turn          |

### Food Sources

**Consumables** (Source: `use-obj.c`):

| Item               | sval                     | Effect     |
| ------------------ | ------------------------ | ---------- |
| Herb of Sustenance | `SV_FOOD_SUSTENANCE` (1) | +2000 food |
| Herb of Hunger     | `SV_FOOD_HUNGER` (5)     | -1000 food |
| Other herbs        | varies                   | +pval food |
| Fragment of Lembas | varies                   | +pval food |

### Item Flags Affecting Hunger

| Flag              | Effect      | Example Items                                  |
| ----------------- | ----------- | ---------------------------------------------- |
| `TR2_SLOW_DIGEST` | hunger -= 1 | Amulet of Preservation, Cloak of the Traveller |
| `TR2_HUNGER`      | hunger += 1 | Ring "Bauglir's Vanguard", Vampiric weapons    |

Multiple items stack: wearing two SLOW_DIGEST items gives hunger = -2 (very slow
digestion).

______________________________________________________________________

## 26. Skill System

Source: `defines.h:630-654`, `monster2.c:1168-1210`

### Player Skills (8 total)

| Index | Constant | Skill      | Primary Stat |
| ----- | -------- | ---------- | ------------ |
| 0     | `S_MEL`  | Melee      | DEX          |
| 1     | `S_ARC`  | Archery    | DEX          |
| 2     | `S_EVN`  | Evasion    | DEX          |
| 3     | `S_STL`  | Stealth    | DEX          |
| 4     | `S_PER`  | Perception | GRA          |
| 5     | `S_WIL`  | Will       | GRA          |
| 6     | `S_SMT`  | Smithing   | GRA          |
| 7     | `S_SNG`  | Song       | GRA          |

Each skill can have up to 20 abilities (`ABILITIES_MAX`). Base skill maximum is
100 (`BASE_SKILL_MAX`).

### Monster Skills (3 of 8)

Monsters use a **subset** of the skill system. The `monster_skill()` function in
`monster2.c:1168-1210` maps monster stats to skills:

| Skill                | Monster Field | Source            |
| -------------------- | ------------- | ----------------- |
| `S_STL` (Stealth)    | `r_ptr->stl`  | `A:` line field 3 |
| `S_PER` (Perception) | `r_ptr->per`  | `A:` line field 2 |
| `S_WIL` (Will)       | `r_ptr->wil`  | `A:` line field 4 |

**Player-Only Skills** (not used by monsters):

- Melee (`S_MEL`) - monsters use attack bonus from B: line
- Archery (`S_ARC`) - monsters use spell/breath attacks
- Evasion (`S_EVN`) - monsters use evasion from P: line
- Smithing (`S_SMT`) - player crafting only
- Song (`S_SNG`) - player songs only (monsters have `SNG_*` flags)

> Player races may have `SNG_AFFINITY` (`lib/edit/race.txt`).

**Monster A: Line Format:**

```
A: sleepiness : perception : stealth : will
```

Example: `A:20:2:3:1` means Sleepiness 20, Perception 2, Stealth 3, Will 1.

______________________________________________________________________

## 27. Horn Effects

Source: `use-obj.c:670-920`

Horns are usable items with **entirely hardcoded effects**. The `pval` field is
not used.

### Horn Types and Effects

| sval | Name     | Effect                                                | Skill Check          |
| ---- | -------- | ----------------------------------------------------- | -------------------- |
| 0    | Terror   | `fire_arc(GF_FEAR, ...)` in 90° arc                   | Will vs. target Will |
| 1    | Thunder  | `fire_arc(GF_SOUND, 10, 4, ...)` stuns                | Will vs. target Will |
| 2    | Force    | Knockback 1-3 squares + stun                          | Will+10 vs CON×2     |
| 3    | Blasting | `fire_arc(GF_KILL_WALL, ...)` destroys walls          | Will-based           |
| 4    | Warning  | `monster_perception(TRUE, FALSE, -10)` alerts enemies | None                 |

### Horn of Force Details

The Horn of Force has complex knockback logic:

1. Affects monsters in a 3-wide arc, up to 3 squares away
2. Closer monsters are knocked back further
3. Monsters that can't be pushed are stunned more heavily
4. Sets monster energy to 0 (loses next turn)

### Noise Generation

All horns generate significant noise, alerting nearby monsters:

- Terror: -10 noise bonus
- Thunder: -20 noise bonus
- Others: Standard noise

______________________________________________________________________

## 28. Element/Effect System (`GF_*`)

Source: `defines.h:789-841`, `spells1.c`

The `GF_*` constants define damage types and effect types used by spells,
breaths, traps, and items.

### Damage Elements

| Constant     | Value | Element       | Used By                |
| ------------ | ----- | ------------- | ---------------------- |
| GF_HURT      | 1     | Physical      | Generic damage         |
| GF_ARROW     | 2     | Arrow         | Archery attacks        |
| GF_BOULDER   | 3     | Boulder       | Boulder traps          |
| GF_ACID      | 4     | Acid          | Rare attacks           |
| GF_ELEC      | 5     | Electricity   | Brands, traps          |
| GF_FIRE      | 6     | Fire          | Breaths, brands, traps |
| GF_COLD      | 7     | Cold          | Breaths, brands        |
| GF_POIS      | 8     | Poison        | Breaths, attacks       |
| GF_DARK      | 9     | Darkness      | Breaths, spells        |
| GF_DARK_WEAK | 10    | Weak darkness | Lesser dark effects    |
| GF_LIGHT     | 11    | Light         | Radiance ability       |
| GF_SOUND     | 12    | Sound         | Horn of Thunder        |

### Status Effects

| Constant     | Value | Effect    |
| ------------ | ----- | --------- |
| GF_SLOW      | 14    | Slowing   |
| GF_SPEED     | 15    | Haste     |
| GF_CONFUSION | 16    | Confusion |
| GF_SLEEP     | 17    | Sleep     |
| GF_FEAR      | 18    | Fear      |
| GF_HEAL      | 19    | Healing   |

### Terrain Effects

| Constant      | Value | Effect              |
| ------------- | ----- | ------------------- |
| GF_EARTHQUAKE | 13    | Terrain destruction |
| GF_KILL_WALL  | 20    | Destroys walls      |
| GF_KILL_DOOR  | 21    | Destroys doors      |
| GF_KILL_TRAP  | 22    | Disarms traps       |
| GF_LOCK_DOOR  | 23    | Locks doors         |
| GF_WEB        | 26    | Creates webs        |

### Resistance Mapping

| Element | Player Resistance | Monster Resistance |
| ------- | ----------------- | ------------------ |
| GF_FIRE | TR2_RES_FIRE      | RF3_RES_FIRE       |
| GF_COLD | TR2_RES_COLD      | RF3_RES_COLD       |
| GF_ELEC | TR2_RES_ELEC      | RF3_RES_ELEC       |
| GF_POIS | TR2_RES_POIS      | RF3_RES_POIS       |
| GF_DARK | -                 | RF3_RES_NETHR      |
| GF_FEAR | TR2_RES_FEAR      | RF3_NO_FEAR        |

______________________________________________________________________

## 29. Morale System

Source: `melee2.c:5398-5594`

Monster morale is **entirely calculated at runtime** based on combat conditions.
There is **no data file configuration** for base morale values.

### Morale Calculation (`calc_morale`)

```
Base morale = 60

Modifiers:
+ (monster_native_depth - current_depth) × 10
+ player condition bonuses (blind +20, confused +40, stunned +20-80, etc.)
- monster condition penalties (stunned -20, wounded -20 to -80)
+ morale_from_friends() (nearby allies)
- light penalty for light-averse monsters
- carried object penalty (thieves flee with loot)
- Majesty ability penalty
- Bane ability penalty
+ Elf-Bane ability bonus
+ tmp_morale (temporary modifiers from rallying, etc.)
```

### Morale → Stance Conversion (`calc_stance`)

| Morale | Default Stance |
| ------ | -------------- |
| > 200  | AGGRESSIVE     |
| > 0    | CONFIDENT      |
| ≤ 0    | FLEEING        |

### Monster Flags Affecting Stance

| Flag           | Effect                                     |
| -------------- | ------------------------------------------ |
| `RF2_MINDLESS` | Cannot flee; always AGGRESSIVE             |
| `RF3_TROLL`    | CONFIDENT → AGGRESSIVE                     |
| `RF3_NO_FEAR`  | Cannot flee naturally; FLEEING → CONFIDENT |

### Factors That Increase Monster Morale

- Monster is deeper than its native depth
- Player is injured, stunned, confused, afraid, or entranced
- Monster is hasted
- Nearby non-fleeing allies (e.g., when player is surrounded or overwhelmed)
- Elf-Bane ability (vs elf players)
- Endgame (`p_ptr->on_the_run`)

### Factors That Decrease Monster Morale

- Monster is shallower than its native depth
- Monster is injured or stunned
- Nearby fleeing allies
- Player has Majesty ability
- Player has Bane ability vs this monster type
- Light-averse monster facing bright light
- Monster is carrying stolen items

### Configuring Monster Behavior

You **cannot directly set** morale in data files. To make a monster:

- **More aggressive:** Add `RF2_MINDLESS` or `RF3_TROLL` flag
- **Fearless:** Add `RF3_NO_FEAR` flag
- **Braver at shallow depths:** Increase monster's `W:` depth value

______________________________________________________________________

## 30. Alertness System

Source: `defines.h:1969-1974`, `monster2.c:2508-2548`, `melee2.c:5969-6158`

The alertness system determines whether monsters are asleep, unwary, or alert to
the player's presence.

### Alertness Constants

| Constant                | Value | Meaning                                       |
| ----------------------- | ----- | --------------------------------------------- |
| `ALERTNESS_MIN`         | -20   | Minimum alertness (deeply asleep)             |
| `ALERTNESS_UNWARY`      | -10   | Threshold: below = asleep, at/above = unwary  |
| `ALERTNESS_ALERT`       | 0     | Threshold: at/above = alert (aware of player) |
| `ALERTNESS_QUITE_ALERT` | 5     | Moderately alert                              |
| `ALERTNESS_VERY_ALERT`  | 10    | Highly alert                                  |
| `ALERTNESS_MAX`         | 20    | Maximum alertness                             |

### Monster States

| Alertness Range | State  | Behavior                           |
| --------------- | ------ | ---------------------------------- |
| < -10           | Asleep | Cannot move or act; skips turns    |
| -10 to -1       | Unwary | Awake but not aware of player      |
| 0+              | Alert  | Aware of player; can pursue/attack |

### Initial Alertness Calculation

When a monster spawns (Source: `monster2.c:2508-2548`):

```c
if (r_ptr->sleep == 0)
    amount = 0;
else
    amount = dieroll(r_ptr->sleep);  // Roll 1d(sleep)

n_ptr->alertness = ALERTNESS_ALERT - amount;  // 0 - amount
```

**Special cases:**

- During player escape (`on_the_run`): monsters on Gates level or dangerous
  monsters start more alert.
- If monster has a "lead" (spawns with group): copies leader's alertness.

### Perception Check (Stealth vs Perception)

Each turn, monsters can detect the player (Source: `melee2.c:5969-6158`):

**Player's Stealth Roll:**

```
stealth_roll = player_stealth + dieroll(10) + modifiers
```

**Monster's Perception Roll:**

```
m_perception = monster_skill(S_PER)
             - noise_distance
             + combat_bonuses
             - bane_penalty
             + elf_bane_bonus
             + line_of_sight_bonus
             + aggravation_bonus

perception_roll = m_perception + dieroll(10)
```

**Result:**

```
result = perception_roll - stealth_roll
if (result > 0):
    alertness += result  // Monster becomes more alert
```

### Perception Modifiers

Bonuses to Monster Perception:

| Modifier      | Bonus         | Condition                          |
| ------------- | ------------- | ---------------------------------- |
| Combat noise  | +2            | Player attacked or was attacked    |
| Line of sight | +open_squares | Monster can see player             |
| Aggravation   | +10 per level | Player has aggravation curse       |
| Endgame       | +5            | Player is escaping (`on_the_run`)  |
| Elf-Bane      | +varies       | Monster has Elf-Bane vs elf player |

Penalties to Monster Perception:

| Modifier      | Penalty     | Condition                       |
| ------------- | ----------- | ------------------------------- |
| Distance      | -noise_dist | Further from noise source       |
| Already alert | -alertness  | Prevents over-alertness         |
| Bane ability  | -bonus      | Player has Bane vs this monster |
| Disguise      | ÷2          | Player has Disguise ability     |

### Losing Alertness

Alert monsters can lose track of the player (Source: `melee2.c:5866-5882`):

- Must be out of line of sight
- Must fail perception check by 25+ (15+ with Vanish ability)
- Alertness drops but not below `ALERTNESS_UNWARY`

### Related Flags

| Flag                | Effect                                   |
| ------------------- | ---------------------------------------- |
| `RF3_NO_SLEEP`      | Monster cannot be put to sleep by spells |
| `RF2_SHORT_SIGHTED` | Detection range limited to 2 squares     |

### Configuring Monster Alertness

In `monster.txt`, set the `A:` line sleepiness value:

| Sleepiness | Effect                      |
| ---------- | --------------------------- |
| 0          | Always alert (never sleeps) |
| 1-10       | Usually unwary              |
| 11-20      | Usually asleep              |
| 20+        | Deeply asleep               |

______________________________________________________________________

## 31. Experience System

Source: `defines.h:382-383`, `xtra2.c:2417-2455`, `monster2.c:1679-1683`,
`dungeon.c:2539-2541`, `object2.c:819-821`

All experience values are **hardcoded in C code**. There are no data file
configurations for XP amounts.

### Constants

| Constant       | Value | Description                      |
| -------------- | ----- | -------------------------------- |
| `PY_START_EXP` | 5000  | Starting experience              |
| `PY_FIXED_EXP` | 50000 | Fixed experience mode (optional) |

### Monster Experience Formula

Source: `xtra2.c:2417-2455` (`adjusted_mon_exp` function)

Base XP:

```c
mexp = r_ptr->level * 10   // Monster's W: line depth × 10
```

Encounter (Sight) XP:

| Monster Type | Formula                       | Notes               |
| ------------ | ----------------------------- | ------------------- |
| UNIQUE       | `level × 10`                  | Full XP             |
| Non-unique   | `(level × 10) / (sights + 1)` | Diminishing returns |

Kill XP:

| Monster Type | Formula                      | Notes                       |
| ------------ | ---------------------------- | --------------------------- |
| UNIQUE       | `level × 10`                 | Full XP                     |
| Non-unique   | `(level × 10) / (kills + 1)` | Diminishing returns         |
| PEACEFUL     | 0                            | No XP for peaceful monsters |

Example: Depth 5 monster (W:5:...) = base 50 XP

- 1st kill: 50/1 = 50 XP
- 2nd kill: 50/2 = 25 XP
- 3rd kill: 50/3 = 16 XP

### Descent Experience

Source: `dungeon.c:2539-2541`

```c
new_exp = depth * 50   // Only for NEW max depth
```

Only awarded when reaching a **new maximum depth** for the first time. Depth 1
(50ft) is skipped.

| Depth  | Level | XP   |
| ------ | ----- | ---- |
| 100ft  | 2     | 100  |
| 150ft  | 3     | 150  |
| 500ft  | 10    | 500  |
| 1000ft | 20    | 1000 |

### Identification Experience

Source: `object2.c:819-821`

```c
int new_exp = 100;   // Hardcoded flat value
```

**100 XP** per newly identified item kind (not per individual item).

### Experience Tracking Variables

Source: `types.h:786-787`

| Variable               | Purpose                   |
| ---------------------- | ------------------------- |
| `p_ptr->exp`           | Total experience          |
| `p_ptr->new_exp`       | Unspent experience        |
| `p_ptr->kill_exp`      | XP from kills             |
| `p_ptr->encounter_exp` | XP from sighting monsters |
| `p_ptr->descent_exp`   | XP from descending        |
| `p_ptr->ident_exp`     | XP from identification    |

### Skill Point Costs

Source: `birth.c:1699-1706`

```c
// The nth skill point costs (100*n) experience points
cost = (points + base) * (points + base + 1) / 2 * 100 - previous_cost
```

### Configuring Monster XP

The **only way to affect monster XP** is via the monster's depth in
`lib/edit/monster.txt`:

```
W: depth : rarity
```

Higher depth = more XP. A monster at `W:10:1` gives base `10 × 10 = 100` XP.

______________________________________________________________________

## 32. Visibility and Line-of-Sight System

Source: `cave.c`

The visibility system determines what the player can see. It uses an
octant-based line-of-sight (LOS) algorithm with precomputed slope data.

### Visibility Flags

Each dungeon square carries three visibility-related flags:

| Flag        | Meaning                          | Persistence | Set By                        |
| ----------- | -------------------------------- | ----------- | ----------------------------- |
| `CAVE_VIEW` | Line of sight exists from player | Per-turn    | `update_view()` LOS algorithm |
| `CAVE_SEEN` | Currently visible to player      | Per-turn    | Requires `CAVE_VIEW` + light  |
| `CAVE_MARK` | Memorized/mapped by player       | Persistent  | `note_spot()` on first sight  |

**Flag relationships:**

1. `CAVE_VIEW` = geometric line of sight exists (no walls blocking)
2. `CAVE_SEEN` = `CAVE_VIEW` + light source = player can see it right now
3. `CAVE_MARK` = square has been memorized (persistent across turns)

**Possible states:**

| `CAVE_VIEW` | `CAVE_SEEN` | `CAVE_MARK` | Meaning                          |
| ----------- | ----------- | ----------- | -------------------------------- |
| Yes         | No          | No          | In LOS but dark; invisible       |
| Yes         | Yes         | No          | Currently visible, not memorized |
| No          | No          | Yes         | Previously seen, now out of view |
| Yes         | Yes         | Yes         | Currently visible and memorized  |

**`CAVE_MARK` rules:**

- Set when the player first sees "interesting" terrain (doors, traps, stairs)
- For plain floors, only set if the floor has `CAVE_GLOW` (permanently lit)
- Dark corridor floors never get `CAVE_MARK` — only visible via `CAVE_SEEN`

> In addition to `CAVE_MARK`, the game uses a second way to mark objects (such
> as skeletons) as having been seen by the player. See the field `marked` of the
> `object_type` struct (often referred to as `o_ptr->marked` in the code).

### Distance Function

Source: `cave.c:27-37`

The `distance()` function uses an octagonal approximation of Euclidean distance
to avoid the precise, but expensive square root calculations of true Euclidean
distance `sqrt(dy² + dx²)`:

```c
int distance(int y1, int x1, int y2, int x2)
{
  int ay, ax;

  /* Find the absolute y/x distance components */
  ay = (y1 > y2) ? (y1 - y2) : (y2 - y1);
  ax = (x1 > x2) ? (x1 - x2) : (x2 - x1);

  /* Hack -- approximate the distance */
  return ((ay > ax) ? (ay + (ax >> 1)) : (ax + (ay >> 1)));
}
```

Here:

- The formula: `max(dy, dx) + min(dy, dx) / 2` is an approximation of Euclidean
  distance that avoids the precise, but expensive square root calculations of
  true Euclidean distance `sqrt(dy² + dx²)`.

The approximation (sometimes called "octagonal distance") creates an
octagon-shaped view area rather than a perfect circle. Used by `MAX_SIGHT` and
`MAX_VIEW` for range calculations.

| dy  | dx  | Euclidean | Approximation |
| --- | --- | --------- | ------------- |
| 0   | 10  | 10.0      | 10            |
| 7   | 7   | 9.9       | 10 (7 + 3)    |
| 3   | 4   | 5.0       | 5 (4 + 1)     |
| 10  | 10  | 14.1      | 15 (10 + 5)   |

### Octant-Based LOS Algorithm

The algorithm exploits 8-fold symmetry. It calculates visibility for one 45°
wedge (octant), then mirrors/rotates the results to cover the full 360° view.

```
Octant layout around player @:

    \  5  |  6  /
     \    |    /
   4  \   |   /  7
       \  |  /
---------[@]----------
       /  |  \
   3  /   |   \  0
     /    |    \
    /  2  |  1  \
```

The 8 octant transforms (from `vinfo_init()` in `cave.c`):

```
Octant 0 | GRID(+y, +x) | E  to SE (  0° to  45°)
Octant 1 | GRID(+x, +y) | SE to S  ( 45° to  90°)
Octant 2 | GRID(+x, -y) | S  to SW ( 90° to 135°)
Octant 3 | GRID(+y, -x) | SW to W  (135° to 180°)
Octant 4 | GRID(-y, -x) | W  to NW (180° to 225°)
Octant 5 | GRID(-x, -y) | NW to N  (225° to 270°)
Octant 6 | GRID(-x, +y) | N  to NE (270° to 315°)
Octant 7 | GRID(-y, +x) | NE to E  (315° to 360°)
```

Within each octant, squares are processed outward from the player: adjacent
squares first, then further squares following the LOS slopes. Each octant is
processed independently; a square on the boundary between octants (e.g., a
purely South square between octants 1 and 2) may receive `CAVE_VIEW` from either
octant.

### Grids (Squares) and Slopes: Overview

Within each octant, the algorithm tracks grids (squares) and slopes (LOS
angles):

| Constant           | Value | Meaning                                     |
| ------------------ | ----- | ------------------------------------------- |
| `MAX_SIGHT`        | 20    | Maximum view distance in grids              |
| `MAX_VIEW`         | 20    | Maximum range distance (spells etc.)        |
| `VINFO_MAX_GRIDS`  | 161   | Grid squares in one octant within MAX_SIGHT |
| `VINFO_MAX_SLOPES` | 126   | Unique LOS angles per octant                |

**Grid count (161):** Derived by iterating all `(y, x)` positions where `x >= y`
(octant constraint) and `distance(0, 0, y, x) <= 20` (within sight radius).
Without the distance check, the triangular region would have 231 grids; the
circular trim reduces this to 161. The value was determined empirically.

**Slope count (126):** For each of the 161 grids, slopes are calculated to all
four corners of the grid square. After filtering for valid range and removing
duplicates, 126 unique slopes remain. Slopes are stored as bitmasks across four
32-bit words:

```
bits_0: slopes   0-31  (32 slopes)
bits_1: slopes  32-63  (32 slopes)
bits_2: slopes  64-95  (32 slopes)
bits_3: slopes  96-125 (30 slopes)
```

**Slope numbering:** Within each octant, slope 0 is nearest the cardinal axis
(~1.4°) and slope 125 is at the diagonal (45°).

**Full view totals:**

- `8 octants × 161 grids = 1288`, but shared boundary grids reduce this to 1149
  unique grids for the full 360° view.
- The 126 slopes are reused for all 8 octants due to symmetry.

The `vinfo[]` array stores precomputed visibility data for each grid in one
octant, including which slopes pass through it, its distance from the player,
its coordinates, and links to child grids for queue processing.

### Grids (Squares) in Detail

#### What is a grid (square)?

In this context, a grid is simply a single square/tile on the dungeon map.

The codebase uses "grid" and "square" interchangeably:

- A grid has coordinates `(y, x)`.
- Each grid can contain: floor, wall, door, trap, stairs, etc.
- Each grid can have objects (items) and/or a monster on it.
- The player occupies one grid.

#### Grids in the view algorithm

`VINFO_MAX_GRIDS = 161` is the total number of grid squares within the player's
maximum sight range in one octant (cf. `MAX_SIGHT`, unit is `distance`; distance
is explained elsewhere in this document).

```
       MAX_SIGHT = 20
  <---------------------->

  . . . . . . . . . . . . .
  . . . . . . . . . . . . .    Each '.' is one grid.
  . . . . . . . . . . . . .
  . . . . . . . . . . . . .
  . . . . . @ . . . . . . .    @ = player's grid
  . . . . . . . . . . . . .
  . . . . . . . . . . . . .
  . . . . . . . . . . . . .
```

The `vinfo[]` array stores precomputed visibility data for each of these 161
grids (in one octant), including:

- Which slopes pass through it (`bits_0` through `bits_3`).
- Its distance from the player (`d`).
- Its coordinates (`y`, `x`).
- Links to child grids for queue processing (`next_0`, `next_1`).

#### Why 161 grids?

From src/cave.c:

```c
/*
 * Maximum number of grids in a single octant
 */
#define VINFO_MAX_GRIDS 161
```

The answer is in the code comments in src/cave.c at lines 2374-2378 and the
iteration logic at lines 2404-2410:

- Full Octagon (radius 20), Grids=1149
- Quadrant (south east), Grids=308, Slopes=251
- Octant (east then south), Grids=161, Slopes=126

The value 161 is derived empirically from this iteration:

```c
for (y = 0; y <= MAX_SIGHT; ++y)   // y from 0 to 20
{
  for (x = y; x <= MAX_SIGHT; ++x) // x from y to 20 (octant constraint)
  {
      if (distance(0, 0, y, x) > MAX_SIGHT)  // within circular range
          continue;

      num_grids++;  // count it
  }
}
```

The three constraints that determine 161:

1. `y` from 0 to 20 - vertical range of sight.
2. `x >= y` - the octant constraint (east-then-south means we only process grids
   where x-coordinate is at least as large as y-coordinate).
3. `distance() <= 20` - must be within circular sight radius.

Without the distance check, you'd get a triangular region with:

```
1 + 2 + 3 + ... 21 = 231 grids
```

But grids in the far corners (like `y=14`, `x=20`) exceed distance 20, so
they're excluded. This trimming reduces 231 down to 161.

The code comment at lines 2380-2383 even admits this is empirical: This function
assumes that `VINFO_MAX_GRIDS` and `VINFO_MAX_SLOPES` have the correct values,
which can be derived by setting them to a number which is too high, running this
function, and using the error messages to obtain the correct values.

So 161 wasn't calculated by a formula. It is/was empirically determined by
running the algorithm with a high value and using the error messages to find the
exact count.

### Slopes in Detail

#### What is a slope?

A slope represents a specific angle or line-of-sight ray from the player through
the dungeon.

```
Visual Representation

                  /  <- slope
                 /
                /
   ############/
   #.........#/
   #.........X     <- target grid
   #......../.
   #......./.#
   #....../..#
   #.....@...#     <- player
   #.........#
   ###########
```

Each slope is a ray from the player's center toward a specific angle. The
algorithm uses 126 different slopes per octant to determine which grids are
visible.

#### How Slopes Work

For each grid in an octant, the algorithm calculates which slopes pass through
it. This is stored as a bitmask:

```c
vinfo[e].bits_0 // slopes 0-31
vinfo[e].bits_1 // slopes 32-63
vinfo[e].bits_2 // slopes 64-95
vinfo[e].bits_3 // slopes 96-125
```

A grid is visible if any slope can reach it without being blocked by a wall.

#### Why 126 slopes?

It's empirically derived from the algorithm similar to the number of grids
(161). For each of the 161 grids, the code calculates slopes to all four corners
of that grid grid (lines 2426-2448 in src/cave.c), with `SCALE = 100000L`:

```c
/* Slope to the top right corner */
m = SCALE * (1000L * y - 500) / (1000L * x + 500);
/* Handle "legal" slopes */
vinfo_init_aux(hack, y, x, m);

/* Slope to top left corner */
m = SCALE * (1000L * y - 500) / (1000L * x - 500);
/* Handle "legal" slopes */
vinfo_init_aux(hack, y, x, m);

/* Slope to bottom right corner */
m = SCALE * (1000L * y + 500) / (1000L * x + 500);
/* Handle "legal" slopes */
vinfo_init_aux(hack, y, x, m);

/* Slope to bottom left corner */
m = SCALE * (1000L * y + 500) / (1000L * x - 500);
/* Handle "legal" slopes */
vinfo_init_aux(hack, y, x, m);
```

Each slope is only saved if it's unique and "legal" (between 0 and SCALE,
exclusive/inclusive). From `vinfo_init_aux()` at lines 2340-2361:

```c
/* Handle "legal" slopes */
if ((m > 0) && (m <= SCALE))
{
  /* Look for that slope */
  for (i = 0; i < hack->num_slopes; i++)
  {
      if (hack->slopes[i] == m)
          break;
  }

  /* New slope */
  if (i == hack->num_slopes)
  {
      hack->slopes[hack->num_slopes++] = m;
  }
}
```

So:

- 161 grids × 4 corners = 644 total slope calculations.
- But, after filtering for valid range and removing duplicates, only 126 unique
  slope values remain.
- The actual 126 slope values are listed in the comments at lines 2147-2272 in
  `src/cave.c` (slopes 0-125 with their numeric values).

#### Slope numbering

Slopes are numbered from the cardinal axis (E, S, W, N) toward the diagonal
within each octant - not strictly clockwise like quadrants are.

The 126 slopes are defined once for the base octant (where x >= y), and the same
numbering is reused for all 8 octants:

- Slope 0 = near the cardinal axis (shallowest angle, ~1.4°).
- Slope 125 = at the diagonal (45°).

So within each octant:

```
Octant 0 | E  to SE (  0° to  45°) | slope 0 near E,  slope 125 near SE  → clockwise
Octant 1 | SE to S  ( 45° to  90°) | slope 0 near S,  slope 125 near SE  → counter-clockwise
Octant 2 | S  to SW ( 90° to 135°) | slope 0 near S,  slope 125 near SW  → clockwise
Octant 3 | SW to W  (135° to 180°) | slope 0 near W,  slope 125 near SW  → counter-clockwise
Octant 4 | W  to NW (180° to 225°) | slope 0 near W,  slope 125 near NW  → clockwise
Octant 5 | NW to N  (225° to 270°) | slope 0 near N,  slope 125 near NW  → counter-clockwise
Octant 6 | N  to NE (270° to 315°) | slope 0 near N,  slope 125 near NE  → clockwise
Octant 7 | NE to E  (315° to 360°) | slope 0 near E,  slope 125 near NE  → counter-clockwise
```

Example for octant 7 (NE to E):

- Slope 0 has value 2439. This is the shallowest angle (~1.4°), i.e. closest to
  cardinal axis (East).
- Slope 10 is a low-numbered slope, so it's near the cardinal axis. In octant 7
  (NE to E), slope 10 is near the East cardinal axis, not the Northeast
  diagonal.
- Slope 125 has value 100000. This is the steepest angle (the Northeast diagonal
  at 45°) and the furthest away from the East cardinal axis.

```
┌───────┬────────┬───────────────────────────┬───────┐
│ Slope │  Value │ Approximate Angle         │ Grids │
├───────┼────────┼───────────────────────────┼───────┤
│     0 │   2439 │ ~ 1° (nearly horizontal)  │    21 │
├───────┼────────┼───────────────────────────┼───────┤
│    54 │  33333 │ ~18°                      │    18 │
├───────┼────────┼───────────────────────────┼───────┤
│    87 │  60000 │ ~31°                      │    23 │
├───────┼────────┼───────────────────────────┼───────┤
│   125 │ 100000 │  45° (diagonal)           │    13 │
└───────┴────────┴───────────────────────────┴───────┘
```

```
Visual Representation (for octant 7, East to Northeast)

                        Slope 125 (diagonal, 45°)
                      /
                    /
                  /
                /     Slope ~60-80 (steep)
              /
            /
          /       Slope ~30-50 (medium)
        /
      /
    /         Slope ~10-20 (shallow)
  /
/
@---------------- Slope 0 (nearly horizontal, ~1.4°)
   East axis
```

So in each octant:

- Low-numbered slopes (0-30) are near the "start" cardinal axis (e.g., East).
- High-numbered slopes (90-125) are moving further away from the start axis
  (e.g., Northeast).

#### Wall Blocking

When the view algorithm encounters a wall, it clears (removes) all slopes that
touch the wall from the valid set:

```c
if (info & (CAVE_WALL))
{
    bits0 &= ~(p->bits_0); // remove this wall's slopes from valid set
    bits0 &= ~(p->bits_0);
    bits1 &= ~(p->bits_1);
    bits2 &= ~(p->bits_2);
    bits3 &= ~(p->bits_3);
}
```

A grid is visible only if it has any remaining valid slopes:

```c
if ((bits0 & (p->bits_0)) || (bits1 & (p->bits_1))
 || (bits2 & (p->bits_2)) || (bits3 & (p->bits_3)))
```

If all slopes through a grid are blocked by walls, the grid is skipped entirely
and never receives `CAVE_VIEW`.

#### Slope Example

Consider a player looking East with a wall to the Northeast:

```
. . .
. . #    <- wall (Northeast) blocks slopes 10-40
. @ .    <- player, looks toward East
. . .
```

1. Initially all 126 slopes are valid.
2. When a wall is processed, it clears all slopes that pass through it. In the
   example, the Northeast wall is processed, intersecting with (say) slopes
   10-40.
3. Grids that only have slopes blocked by walls become invisible. Here, grids
   behind the wall that only use slopes 10-40 become invisible.
4. Grids with any remaining valid slopes are still visible (0-9 and 41-125).

### Octants in Detail

#### What is an octant?

An octant is one-eighth of the full 360° view around the player.

```
The full 360° view around the player @:

            N (270°)
            |
            |
   NW       |       NE
     \      |      /
       \    |    /
         \  |  /
W ---------[@]-------- E (0°)
         /  |  \
       /    |    \
     /      |      \
   SW       |       SE
            |
            |
            S (90°)
```

An octant is 1/8 of this circle = 45°:

```
Octant numbers:

    \  5  |  6  /
     \    |    /
   4  \   |   /  7
       \  |  /
---------[@]----------
       /  |  \
   3  /   |   \  0
     /    |    \
    /  2  |  1  \
```

The 8 octants are divided by:

- The 4 cardinal directions (N, E, S, W)
- The 4 diagonal directions (NE, SE, SW, NW)

#### Why Octants?

The view algorithm exploits symmetry.

The algorithm only calculates visibility for a single 45° wedge (e.g.,
East-to-Southeast, from 0° to 45°):

```
[@]---------- E (0°)
 |  \
 |   \  0
 |    \
 |  1  \
 |     SE (45°)
```

Within this single 45° wedge extending out to distance 20:

- 161 grids (grids that fit in this pie slice)
- 126 slopes (unique angles that rays can travel from the player through this
  slice)

To get the full 360° view, the algorithm processes the 161 grids once, then
mirrors/rotates the results 8 times:

```
Octant 0 | GRID(+y, +x) | E  to SE (  0° to  45°) → 161 grids
Octant 1 | GRID(+x, +y) | SE to S  ( 45° to  90°) → mirror of octant 0 at SE diagonal
Octant 2 | GRID(+x, -y) | S  to SW ( 90° to 135°) → mirror of octant 0
Octant 3 | GRID(+y, -x) | SW to W  (135° to 180°) → mirror of octant 0
Octant 4 | GRID(-y, -x) | W  to NW (180° to 225°) → mirror of octant 0
Octant 5 | GRID(-x, -y) | NW to N  (225° to 270°) → mirror of octant 0
Octant 6 | GRID(-x, +y) | N  to NE (270° to 315°) → mirror of octant 0
Octant 7 | GRID(-y, +x) | NE to E  (315° to 360°) → mirror of octant 0 at NE diagonal
```

- `8 octants × 161 grids = 1288`, but adjacent octants share their boundary
  grids (the axes and diagonals, 139 grids), so the actual total is `1149`
  unique grids for the full 360° view.
- The `126 slopes` are reused for all 8 octants since the angles are symmetric.
  A ray at 30° in one octant is the same geometry as a ray at 30° in any other
  octant.

Instead of calculating line-of-sight for all 360°, it does the following:

1. Calculates LOS for just one octant (e.g., the slice between East and
   Southeast for octant 0).
2. Applies 8 transformations to map those results to all other octants.

This is done at lines 2493-2500 of `vinfo_init()` of src/cave.c:

```c
//               vertical    horizontal
//   (- is up, + is down)    (- is left, + is right)
//                      |    |
//                      v    v
vinfo[e].grid[0] = GRID(+y, +x);  // octant 0: E  to SE
vinfo[e].grid[1] = GRID(+x, +y);  // octant 1: SE to S  (ex: mirror of octant 0 at SE diagonal)
vinfo[e].grid[2] = GRID(+x, -y);  // octant 2: S  to SW
vinfo[e].grid[3] = GRID(+y, -x);  // octant 3: SW to W
vinfo[e].grid[4] = GRID(-y, -x);  // octant 4: W  to NW
vinfo[e].grid[5] = GRID(-x, -y);  // octant 5: NW to N
vinfo[e].grid[6] = GRID(-x, +y);  // octant 6: N  to NE
vinfo[e].grid[7] = GRID(-y, +x);  // octant 7: NE to E  (ex: mirror of octant 0 at NE diagonal)
```

From src/cave.c:

```c
/*
 * Maximum number of grids in a single octant
 */
#define VINFO_MAX_GRIDS 161

/*
 * Maximum number of slopes in a single octant
 */
#define VINFO_MAX_SLOPES 126

/*
 * Mask of bits used in a single octant
 */
#define VINFO_BITS_3 0x3FFFFFFF
#define VINFO_BITS_2 0xFFFFFFFF
#define VINFO_BITS_1 0xFFFFFFFF
#define VINFO_BITS_0 0xFFFFFFFF
```

The docs of `vinfo_init()` in src/cave.c say:

```c
/*
 * Initialize the "vinfo" array
 *
 * Full Octagon (radius 20), Grids=1149
 *
 * Quadrant (south east), Grids=308, Slopes=251
 *
 * Octant (east then south), Grids=161, Slopes=126
 *
 * This function assumes that VINFO_MAX_GRIDS and VINFO_MAX_SLOPES
 * have the correct values, which can be derived by setting them to
 * a number which is too high, running this function, and using the
 * error messages to obtain the correct values.
 */
errr vinfo_init(void) {}
```

#### Processing Order of Octants

Within each octant, grids are processed outward from the player:

1. First the adjacent grids (`vinfo[1]` = cardinal, `vinfo[2]` = diagonal).
2. Then further grids, following the LOS slopes.

When a wall is encountered, it blocks certain LOS slopes, preventing grids
behind it from being seen.

______________________________________________________________________

## Key Source Files

| File (in `src/`) | Primary Content                                |
| ---------------- | ---------------------------------------------- |
| `cave.c`         | Visibility/LOS algorithm, distance function    |
| `xtra2.c`        | Morgoth progression, morale, experience system |
| `cmd1.c`         | Quest system, combat, knockback, trap effects  |
| `cmd2.c`         | Min depth system, stair mechanics, victory     |
| `cmd3.c`         | Silmaril removal mechanics, crown system       |
| `cmd4.c`         | Smithing, ability bonuses, bane, forge bonus   |
| `melee2.c`       | Monster AI, perception, morale system, stance  |
| `melee1.c`       | Monster attack effects (`RBE_*`)               |
| `object2.c`      | Silmarils, special items, forge placement      |
| `generate.c`     | Unique placement, thralls, depth rules         |
| `dungeon.c`      | Hunger/food, regeneration, descent XP          |
| `monster2.c`     | Monster spawning, health dice, encounter XP    |
| `birth.c`        | Character creation, skill point costs          |
| `xtra1.c`        | Skills, weapon bonuses, two-weapon, status     |
| `files.c`        | Silmaril counting, scoring, PRF loading        |
| `use-obj.c`      | Consumables, herbs, potions, horn effects      |
| `spells1.c`      | `GF_*` element effects, status mechanics       |
| `defines.h`      | Light radius, trap, forge, graphics constants  |
| `tables.c`       | Speed/energy system                            |
| `main-win.c`     | Windows tileset loading                        |
| `main-x11.c`     | X11 tileset loading                            |
| `main-cocoa.m`   | macOS tileset loading                          |
| `variable.c`     | ANGBAND_GRAF graphics mode variable            |

______________________________________________________________________

## Implications for Database Schema

The database should include:

01. **Monster special flags**: `is_morgoth`, `is_quest_monster`,
    `has_progressive_stats`
02. **Item special flags**: `is_silmaril`, `has_special_timeout`,
    `has_smithing_restrictions`
03. **Ability references**: Link abilities to their hardcoded effects
04. **Depth rules table**: Capture depth-specific behaviors
05. **Combat modifier tables**: Skill bonuses, proficiencies, bane effects
06. **Quest system tables**: Thrall quests, rewards, requirements
07. **Light source table**: Map items to their hardcoded light radius values
08. **Trap effects table**: Document all trap types and their hardcoded effects
09. **Status effects table**: Document player status variables and their
    mechanics
10. **Consumable effects table**: Map item sval to hardcoded effects from
    `use-obj.c`
11. **Attack effects table**: Document `RBE_*` constants and their
    implementations
12. **Flag behavior notes**: Document cumulative/non-cumulative flag mechanics
13. **Forge types table**: Document forge types, bonuses, and generation rules
14. **Crown/Silmaril state**: Track the 4 crown versions and removal mechanics
15. **Terrain state encoding**: Document features that encode state in their ID
16. **Stair types table**: Document stair/shaft features and their depth changes
17. **Player stat effects**: Document stat-to-skill bonuses and damage
    calculations
18. **Hunger system constants**: Food thresholds and hunger rate modifiers
19. **Monster health**: Note that non-uniques have variable HP (dice rolled at
    spawn)
20. **Skill system**: 8 player skills, 3 monster skills (subset)
21. **Food items**: Distinguish hardcoded herb effects vs pval-based food
22. **Horn effects**: Document hardcoded effects for each horn sval
23. **`GF_*` element table**: Map element constants to resistances and damage
    types
24. **Morale flags**: Document flags that affect monster stance (MINDLESS,
    TROLL, NO_FEAR)
25. **Alertness constants**: `ALERTNESS_*` thresholds and their meanings
26. **Monster sleepiness**: Link A: line sleepiness to initial alertness
    calculation
27. **Experience constants**: PY_START_EXP, monster XP formula (level x 10),
    diminishing returns for non-uniques
28. **XP category tracking**: encounter_exp, kill_exp, descent_exp, ident_exp as
    separate fields
29. **Visibility constants**: MAX_SIGHT, MAX_VIEW, VINFO_MAX_GRIDS,
    VINFO_MAX_SLOPES as global game parameters
30. **Visibility flags**: CAVE_VIEW, CAVE_SEEN, CAVE_MARK as runtime grid state
    (not entity properties, but document their semantics)
