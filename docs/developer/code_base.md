# Sil-Q Codebase

This document describes the systems of Sil-Q that are implemented in the C
source code (`src/`), with a focus on behavior that is **hardcoded**, i.e., not
configurable via the game data files.

Related documents (each topic is documented in one place only):

- [data_files.md](data_files.md): the format of all game data files
    (`lib/edit/*.txt`, `lib/pref/*.prf`). Go there for "what does field X of
    file Y mean".
- [rendering.md](rendering.md): how entities are drawn on screen (ASCII and
    tiles, the tileset, overlays, rage visual effects).
- [visibility.md](visibility.md): line of sight, the view algorithm, and the
    `distance()` function.
- [world_model.md](world_model.md): an entity-relationship summary of the game
    world for a possible database of game entities.
- [developer_mode.md](developer_mode.md): debug commands for testing.
- [game_design.md](game_design.md): design intent and history.

Source references use function names (e.g., `min_depth()` in `src/cmd2.c`)
instead of line numbers, because line numbers change often.

## Top-down view

- **UI.** The game has a graphical view (tiles or ASCII, switchable during play)
    and a terminal mode (GCU, ASCII only). There are separate front ends for
    Windows (`main-win.c`), macOS (`main-cocoa.m`), and X11 (`main-x11.c`), plus
    GCU (`main-gcu.c`) for terminal mode on macOS and Linux. Changes to graphics
    must be made in each front end. A unified stack (e.g., SDL) would make this
    simpler.
- **Data vs. code.** Data files define most entities (monsters, items, terrain,
    abilities, vaults). Much behavior is still hardcoded in C. This document
    lists the most important cases.
- **UI language.** English only. Some strings are hardcoded in C, and parts of
    the UI layout depend on the exact length of English words (e.g., the status
    bar).

## Loading game data

### Edit files (`lib/edit/*.txt`)

`init_info()` in `src/init2.c` loads each edit file. It first tries a cached
binary file `lib/data/<name>.raw`. If the `.raw` file is missing or older than
the `.txt` file (`CHECK_MODIFICATION_TIME`), it parses the `.txt` file with the
matching `parse_*_info()` function in `src/init1.c` (e.g., `parse_r_info()` for
`monster.txt`, `parse_k_info()` for `object.txt`) and writes a new `.raw` file.

The parsed data is stored in global arrays such as `r_info` (monster races),
`k_info` (object kinds), `a_info` (artefacts), `e_info` (specials), `f_info`
(terrain), `b_info` (abilities), `p_info` (races), `c_info` (houses), and
`flavor_info`.

### Pref files (`lib/pref/*.prf`)

`process_pref_file()` in `src/files.c` loads pref files. Pref files can include
other pref files (`%:file.prf`) and can have conditions (`?:[EQU $GRAF tiles]`).
The load order is:

1. `pref.prf` at startup (`src/init2.c`).
2. `graf.prf` if graphics are on, else `font.prf` (`reset_visuals()` in
    `src/object1.c`). `graf.prf` includes the per-platform file (e.g.,
    `graf-x11.prf`), which includes `graf-tiles.prf` if `ANGBAND_GRAF` is
    `"tiles"`. `graf-tiles.prf` includes `flvr-tiles.prf`.
3. `user.prf`, `user.scb`, and `races.prf` when a game starts (`src/dungeon.c`).
    `races.prf` includes `noldor.prf` etc., but these files do not exist, so it
    has no effect.

`ANGBAND_GRAF` (`src/variable.c`) is `"old"` by default. The front ends set it
to `"tiles"` (tiles graphics) or `"pseudo"` (GCU).

## Player

### Player state

The player's state is `struct player_type` (`src/types.h`), accessed via
`p_ptr`. Changing this struct can break savefiles.

The player uses entries 0–3 of the monster race array `r_info`, one per race:
`r_info[p_ptr->prace]`. These are the `N:0`–`N:3` records in `monster.txt`.

### Stats

Source: `calc_bonuses()`, `calc_hitpoints()`, `calc_voice()` and
`strength_modified_ds()` in `src/xtra1.c`.

| Stat         | Effect                                                                                          |
| ------------ | ----------------------------------------------------------------------------------------------- |
| Strength     | Adds to the damage _sides_ of melee and archery. The bonus is capped by the weapon weight (lb). |
| Dexterity    | +1 per point to Melee, Archery, Evasion, Stealth.                                               |
| Constitution | Max HP = 20 × 1.2^CON (compounding; ÷1.2 per negative point).                                   |
| Grace        | +1 per point to Perception, Will, Smithing, Song. Max voice = 20 × 1.2^GRA (compounding).       |

There are no character levels. Players spend experience on skills and abilities
instead.

### Skills

Source: `S_*` constants in `src/defines.h`, `calc_bonuses()` in `src/xtra1.c`.

| Index | Constant | Skill      | Stat bonus from |
| ----- | -------- | ---------- | --------------- |
| 0     | `S_MEL`  | Melee      | DEX             |
| 1     | `S_ARC`  | Archery    | DEX             |
| 2     | `S_EVN`  | Evasion    | DEX             |
| 3     | `S_STL`  | Stealth    | DEX             |
| 4     | `S_PER`  | Perception | GRA             |
| 5     | `S_WIL`  | Will       | GRA             |
| 6     | `S_SMT`  | Smithing   | GRA             |
| 7     | `S_SNG`  | Song       | GRA             |

The final skill is
`skill_use[s] = skill_base[s] + skill_stat_mod[s] + skill_equip_mod[s] + skill_misc_mod[s]`.
`skill_misc_mod` includes race/house affinities and penalties (see below).

Constants: `BASE_SKILL_MAX` = 100, `ABILITIES_MAX` = 20 (per skill).

**Skill point cost** (`skill_cost()` in `src/birth.c`): the nth point of a skill
costs 100 × n experience.

**Affinities and penalties** (`affinity_level()` in `src/xtra1.c`): each
`*_AFFINITY` flag on the race or house gives +1 to the skill and makes its
abilities 500 XP cheaper. Each `*_PENALTY` flag gives −1 and makes abilities 500
XP more expensive. Race and house flags stack (race + house affinity is shown as
"mastery").

### Abilities

Arrays in `player_type`:

| Array                  | Meaning                                              |
| ---------------------- | ---------------------------------------------------- |
| `innate_ability[S][A]` | The player has learned the ability                   |
| `active_ability[S][A]` | The ability is in use (the player can turn some off) |
| `have_ability[S][A]`   | Learned or granted by items                          |

`prereqs()` in `src/cmd4.c` checks prerequisites. All prerequisites of an
ability are OR conditions. The Quick Study ability (`PER_QUICK_STUDY`) removes
the prerequisite check.

### Speed and energy

Source: `extract_energy[]` in `src/tables.c`, `calc_bonuses()` in `src/xtra1.c`.

Each game turn, a creature gains energy based on its speed:

| Speed | Energy/turn |
| ----- | ----------- |
| 1     | 5           |
| 2     | 10          |
| 3     | 15          |
| 4     | 20          |
| 5     | 25          |
| 6     | 30          |
| 7     | 35          |

**Player speed** is hardcoded to 2 and then modified: +1 for each `SPEED` item
flag, haste, or sprinting; −1 for each `SLOWNESS` flag, slow, being over the
weight limit, or stealth mode. The result is clamped to 1–3.

**Monster speed** comes from the `I:` line of `monster.txt` and is not clamped.

### Experience

Source: `adjusted_mon_exp()` in `src/xtra2.c`, `dungeon()` in `src/dungeon.c`,
`object_aware()` in `src/object2.c`.

All XP amounts are hardcoded. Start XP is `PY_START_EXP` (5000), or
`PY_FIXED_EXP` (50000) with the "fixed experience" birth option.

| Source                        | XP                                                                     |
| ----------------------------- | ---------------------------------------------------------------------- |
| Seeing a monster race         | Unique: `depth × 10`. Other: `depth × 10 / (sights + 1)`               |
| Killing a monster             | Unique: `depth × 10`. Other: `depth × 10 / (kills + 1)`. `PEACEFUL`: 0 |
| Reaching a new max depth      | `depth × 50` for each new level (not for level 1)                      |
| Identifying a new object kind | 100                                                                    |

`depth` is the monster's `W:` depth in `monster.txt`. That is the only way to
change a monster's XP. The player tracks XP by source in `kill_exp`,
`encounter_exp`, `descent_exp` and `ident_exp`; `exp` is the total and `new_exp`
the unspent part.

### Hunger and food

Source: `process_player()` in `src/dungeon.c`, `prt_hunger()` and
`calc_bonuses()` in `src/xtra1.c`.

| Food value       | Status (color)     | Effect                             |
| ---------------- | ------------------ | ---------------------------------- |
| < 1 (`STARVE`)   | Starving (red)     | 1 damage per turn, no regeneration |
| < 1000 (`WEAK`)  | Weak (orange)      | STR −1                             |
| < 2000 (`ALERT`) | Hungry (yellow)    |                                    |
| < 5000 (`FULL`)  | (blank)            |                                    |
| < 8000 (`MAX`)   | Full (light green) |                                    |
| ≥ 8000           | Full (green)       | Digestion ×50                      |

The player digests 1 food per turn, modified by `p_ptr->hunger`:

- `hunger < 0`: digestion happens only with a chance of 1 in 3^|hunger|.
- `hunger > 0`: digestion is multiplied by 3^hunger.

`hunger` goes down by 1 for each `SLOW_DIGEST` item and for the Indomitable
ability. It goes up by 1 for each `HUNGER` item and for regeneration.

### Status effects

Player status effects are counters in `p_ptr` that count down each turn:
`poisoned`, `cut`, `blind`, `confused`, `afraid`, `image` (hallucination),
`stun`, `slow`, `entranced`, `rage`. The `set_*()` functions in `src/xtra2.c`
change them.

Poison and cuts do `(counter + 4) / 5` damage per turn (`process_player()` in
`src/dungeon.c`). Poison damage from an attack is added to the counter
(`pois_dam_mixed()` in `src/spells1.c`); it does not do direct damage.

## Combat

### Rolls

Sil-Q uses opposed rolls (see [game_design.md](game_design.md#combat)):

- **Hit:** `hit_roll()` in `src/cmd1.c`: attack score + 1d20 vs. evasion + 1d20.
- **Damage:** damage dice vs. a protection roll. Only the net damage counts.

### Critical hits

Source: `crit_bonus()` in `src/cmd1.c`.

Extra damage dice = `(hit_result × 10 + 4) / (70 + weapon_weight)`, where
`weapon_weight` is in 0.1 lb.

| Modifier                                                    | Effect            |
| ----------------------------------------------------------- | ----------------- |
| Finesse (`MEL_FINESSE`)                                     | 70 → 50           |
| Subtlety (`MEL_CONTROL`), one-handed weapon, empty off hand | another −20       |
| Power (`MEL_POWER`)                                         | +10               |
| Monster `RES_CRIT`                                          | Bonus dice halved |
| Monster `NO_CRIT`                                           | No bonus dice     |
| Weapon `CUMBERSOME`                                         | No bonus dice     |

### Other bonuses

| Function                  | Source        | Effect                                                      |
| ------------------------- | ------------- | ----------------------------------------------------------- |
| `axe_bonus()`             | `src/xtra1.c` | +1 per `AXE_PROFICIENCY` (race, house) with an `AXE` weapon |
| `polearm_bonus()`         | `src/xtra1.c` | +2 with Polearm Mastery and a `POLEARM` weapon              |
| `hand_and_a_half_bonus()` | `src/xtra1.c` | Bonus for `HAND_AND_A_HALF` weapons used two-handed         |
| `bane_bonus()`            | `src/cmd4.c`  | Bane ability vs. the chosen monster type                    |
| `elf_bane_bonus()`        | `src/cmd4.c`  | Monster bonus vs. elf players (`ELFBANE` monsters)          |
| `spider_bane_bonus()`     | `src/cmd4.c`  | Bonus vs. spiders                                           |

Two-weapon fighting uses `p_ptr->offhand_mel_mod`. Knock back is `knock_back()`
in `src/cmd1.c`; `p_ptr->knocked_back` records that the player was knocked back
last turn.

### Monster blows

Each monster has up to 4 blows (`monster_blow blow[MONSTER_BLOW_MAX]` in
`monster_race`, `src/types.h`) with `method` (`RBM_*`), `effect` (`RBE_*`),
`att`, `dd` and `ds`. `make_attack_normal()` in `src/melee1.c` implements the
effects. All effects first do (net) damage, except where noted:

| Effect                                                     | Additional effect                                                       |
| ---------------------------------------------------------- | ----------------------------------------------------------------------- |
| `HURT`                                                     | None                                                                    |
| `WOUND`                                                    | Chance to cut                                                           |
| `BATTER`                                                   | Chance to stun                                                          |
| `SHATTER`                                                  | Chance to stun; earthquake                                              |
| `FIRE`, `COLD`, `ACID`, `ELEC`, `DARK`                     | Elemental damage. Fire, cold and dark get +1 damage die if not resisted |
| `POISON`                                                   | Damage goes to the poison counter (+1 die if not resisted)              |
| `BLIND`, `CONFUSE`, `TERRIFY`, `ENTRANCE`, `HALLU`, `SLOW` | Status effect                                                           |
| `DISEASE`                                                  | `disease()`                                                             |
| `LOSE_STR`, `_DEX`, `_CON`, `_GRA`, `_STR_CON`, `_ALL`     | Stat drain                                                              |
| `UN_BONUS`                                                 | Disenchants equipment                                                   |
| `UN_POWER`                                                 | Drains charges                                                          |
| `LOSE_MANA`                                                | Drains voice                                                            |
| `EAT_ITEM`, `EAT_FOOD`, `HUNGER`                           | Steals items or food, or reduces food                                   |
| `DISARM`                                                   | Disarms the player's weapon                                             |

## Monsters

### Special monsters

`R_IDX_*` constants in `src/defines.h` identify monsters with hardcoded
behavior. Examples:

| Constant                                             | ID     | Behavior                                  |
| ---------------------------------------------------- | ------ | ----------------------------------------- |
| `R_IDX_MORGOTH`                                      | 251    | Progressive difficulty, truce (see below) |
| `R_IDX_MORGOTH_NO_CROWN`                             | 252    | Morgoth after he loses his crown          |
| `R_IDX_CARCHAROTH`                                   | 253    | Placed by vaults (`C`); special lore text |
| `R_IDX_HUMAN_THRALL`, `R_IDX_ELF_THRALL`             | 13, 14 | Thrall quest                              |
| `R_IDX_ORC_THRALLMASTER`                             | 15     | Guards thralls                            |
| `R_IDX_ALERT_HUMAN_THRALL`, `R_IDX_ALERT_ELF_THRALL` | 16, 17 | Thralls that give a quest                 |

Most other `R_IDX_*` constants (e.g., Gothmog, Glaurung, Barrow-wight) exist
because vault layouts place them by letter (`build_vault()` in
`src/generate.c`). See the `vault.txt` section in
[data_files.md](data_files.md).

### Monster skills

`monster_skill()` in `src/monster2.c` returns Stealth, Perception and Will from
the `A:` line. Monsters have no Melee, Archery, Evasion, Smithing or Song score;
they use the `B:` and `P:` lines instead. Stunned monsters get −2.

### Alertness

Source: `ALERTNESS_*` in `src/defines.h`, `place_monster_one()` in
`src/monster2.c`, `monster_perception()` and `process_monster()` in
`src/melee2.c`.

| Alertness | State  |
| --------- | ------ |
| < −10     | Asleep |
| −10 … −1  | Unwary |
| ≥ 0       | Alert  |

The range is −20 (`ALERTNESS_MIN`) to 20 (`ALERTNESS_MAX`).

**Initial alertness** = `0 − 1d(sleepiness)` (sleepiness from the `A:` line; 0
means always alert). Group members copy the leader. During the escape
(`on_the_run`), many monsters start more alert.

**Perception check** (each time the player makes noise):

```
m_perception = monster_skill(S_PER) − noise_distance
             + combat noise bonus (+2 if the player attacked, +2 if attacked)
             − bane_bonus + elf_bane_bonus
             + 5 during the escape
             − alertness (if already alert)
             + 10 × aggravation (if awake and not MINDLESS)
             + open squares next to the player + combat bonus
               (only with line of sight; halved by Disguise)
result = (m_perception + 1d10) − (player stealth + 1d10)
if result > 0: alertness += result
```

`SHORT_SIGHTED` monsters only notice the player within distance 2.

**Losing track:** an alert, non-fleeing monster that can sleep (sleepiness > 0)
and has no line of sight makes a Perception check (+25, or +15 if the player has
Vanish) vs. Stealth + noise distance. If it fails, alertness drops by the
margin, but not below −10.

### Morale and stance

Source: `calc_morale()` and `calc_stance()` in `src/melee2.c`.

Morale is calculated at runtime only. Data files cannot set it.

```
morale = 60
       + (monster depth − current depth) × 10   (or +20 during the escape)
       + player conditions: hallucinating/blind +20, confused/slowed/afraid +40,
         entranced +80 (else stun +20/+40/+80),
         player wounded +20/+40/+80 (not with Formidable)
       − monster stunned 20, + monster hasted 40
       − monster wounded 20/40/80 (−20 more if already fleeing and ≤75% HP)
       + morale_from_friends()
       − 10 × (light − 3) for HURT_LITE monsters if the player's square light ≥ 4
       − 20 per carried object (non-uniques)
       − Majesty, − Bane × 10, + Elf-Bane × 10
       + tmp_morale (e.g., rally)
```

In the throne room, morale is at least 20.

| Morale | Default stance |
| ------ | -------------- |
| > 200  | Aggressive     |
| > 0    | Confident      |
| ≤ 0    | Fleeing        |

Overrides: `MINDLESS` is always aggressive. `TROLL`, aggravation, and angered
monsters turn confident into aggressive. `NO_FEAR` turns fleeing into confident.
Song of Challenge can make confident monsters aggressive. Unwary or sleeping
monsters are always confident.

### Random movement

`RAND_25` and `RAND_50` add up: 25%, 50%, or 75% with both.

### Morgoth

Source: `anger_morgoth()` and `break_truce()` in `src/xtra2.c`.

Morgoth's stats change with `p_ptr->morgoth_state`:

| State | Trigger                 | Changes                              |
| ----- | ----------------------- | ------------------------------------ |
| 0     | Initial                 | evn 20, att 20, wil 25, per 10       |
| 1     | Loses crown             | evn 22, light 0, per 15              |
| 2     | Hurt or Silmaril stolen | att 30, dd 7, wil 30, per 20, evn 25 |
| 3     | Badly hurt              | pd 7, wil 35, per 25                 |
| 4     | Desperate               | evn 30, att 40, dd 8, wil 40, per 30 |

**Truce.** On arrival at the throne room, `p_ptr->truce` is set. Alert monsters
in line of sight do not attack until `break_truce()` is called. Attacks,
stealing a Silmaril, using items, and similar actions call it.

## Items

### Consumable effects

Data files define names, weights and costs of consumables. Their effects are
hardcoded by sval in `src/use-obj.c` (`eat_food()`, `quaff_potion()`,
`use_staff()`, `play_instrument()`). The `SV_*` constants are in
`src/defines.h`.

**Herbs and food** (`TV_FOOD`). After the effect, every food item also adds its
pval to the food counter.

| sval | Name         | Effect                                | pval |
| ---- | ------------ | ------------------------------------- | ---- |
| 0    | Rage         | Cures fear, rage +10d4                | 250  |
| 1    | Sustenance   | Food +2000                            | 0    |
| 2    | Terror       | Fear +10d4 and haste +5d4             | 250  |
| 3    | Healing      | Heals 50 (+ Medic bonus), halves cuts | 250  |
| 4    | Restoration  | Restores all stats                    | 250  |
| 5    | Emptiness    | Food −1000                            | 0    |
| 6    | Visions      | Cures blindness, hallucination +80d4  | 250  |
| 7    | Entrancement | Entranced 10d4                        | 250  |
| 8    | Weakness     | Drains STR                            | 250  |
| 9    | Sickness     | Drains CON                            | 250  |
| 35   | Dark Bread   | None                                  | 1500 |
| 36   | Dried Meat   | None                                  | 2000 |
| 37   | Lembas       | Restores GRA                          | 3000 |

**Horns** (`TV_HORN`). pval is not used. The power uses the player's Will. Using
a horn costs voice (halved by Channeling) and makes noise.

| sval | Name     | Effect                                                                                          |
| ---- | -------- | ----------------------------------------------------------------------------------------------- |
| 0    | Terror   | `GF_FEAR` in a 90° arc                                                                          |
| 1    | Thunder  | `GF_SOUND` (stun) in a 90° arc                                                                  |
| 2    | Force    | 3-wide arc, up to 3 squares: Will+10 vs. CON×2; knocks back (closer = further), stuns, energy 0 |
| 3    | Blasting | `GF_KILL_WALL` in an arc. Up: rocks fall on the player. Down: the player can fall a level       |
| 4    | Warning  | Very loud noise that alerts monsters                                                            |

### Channeling

The pval of a staff stores _half_ charges. A normal use costs 2
(`CHANNELING_CHARGE_MULTIPLIER`); with the Channeling ability a use costs 1, so
the staff has double the uses (`do_cmd_activate_staff()` in `src/cmd6.c`). The
charge display in `src/object1.c` divides by 2 if the player does not have
Channeling. Channeling also halves the voice cost of horns.

### Light sources

Light radius is hardcoded (`src/defines.h`), not in data files:

| Constant              | Radius | Item            |
| --------------------- | ------ | --------------- |
| `RADIUS_TORCH`        | 1      | Wooden Torch    |
| `RADIUS_LESSER_JEWEL` | 1      | Lesser Jewel    |
| `RADIUS_LANTERN`      | 2      | Brass Lantern   |
| `RADIUS_MALLORN`      | 3      | Mallorn Torch   |
| `RADIUS_ARTEFACT`     | 3      | Light artefacts |
| `RADIUS_FEANORIAN`    | 4      | Feanorian Lamp  |
| `RADIUS_SILMARIL`     | 7      | Silmaril        |

Lights with a `timeout` burn fuel each turn (`process_world()` in
`src/dungeon.c`).

### Smithing

Source: `src/cmd4.c`.

- `att_max()`, `ds_max()`, `evn_max()`, `ps_max()`, `pval_max()`, `wgt_max()`
    and the matching `*_min()` / `*_valid()` functions set hardcoded limits per
    item type (e.g., rings of accuracy, arrows, armour types).
- `object_difficulty()` calculates the smithing difficulty.
- `forge_bonus()` gives +0 / +3 / +7 for a normal / enchanted / unique forge.
- Mithril is a separate resource (`use_mithril()`, `melt_mithril_item()`).

### Forges

Source: `place_forge()` in `src/object2.c`. For the feature IDs, see
`terrain.txt` in [data_files.md](data_files.md).

- Uses: 3 or 4 (`2 + 1d2`). Levels 1–2 always get a normal forge with 3 uses.
- Type: roll 1d1000 once per level of depth (twice per level in a greater vault)
    and keep the best roll. 1000 gives the unique forge Orodruth (3 uses, only
    once per game). 990–999 gives an enchanted forge. Else normal.
- Each use replaces the feature with the next lower ID.

### Staff of Treasures

`SV_STAFF_TREASURES` has hardcoded behavior in `src/use-obj.c`, `src/object2.c`,
and `src/spells2.c`.

## Dungeon

### Depth

Depth is in levels of 50 ft. `MORGOTH_DEPTH` = 20 (1000 ft) is the throne room.
Depth 0 is the Gates of Angband.

### Stairs

Source: `do_cmd_go_up()` and `do_cmd_go_down()` in `src/cmd2.c`.

| Feature ID | Constant          | Effect |
| ---------- | ----------------- | ------ |
| 80         | `FEAT_LESS`       | Up 1   |
| 81         | `FEAT_MORE`       | Down 1 |
| 82         | `FEAT_LESS_SHAFT` | Up 2   |
| 83         | `FEAT_MORE_SHAFT` | Down 2 |

Going up:

- Without a Silmaril, the player cannot leave the throne room.
- Ironman and the Oath of Iron block going up without a Silmaril.
- If the new depth is less than `min_depth()`, the player arrives at
    `min_depth()` instead ("You enter a maze of up staircases, but cannot find
    your way"). Trapped stairs can drop the player one level.
- Leaving the throne room with a Silmaril starts the escape
    (`p_ptr->on_the_run`).

Going down:

- The player cannot go down from the Gates.
- During the escape, the player cannot go back to the throne room.

### Minimum depth

Source: `min_depth()` in `src/cmd2.c`, `process_player()` in `src/dungeon.c`.

The minimum depth stops the player from staying on shallow levels.

```
min_depth = min_depth_counter / 100000 + 1   (clamped to 1..MORGOTH_DEPTH)
            = MORGOTH_DEPTH in the throne room
            = 0 during the escape
```

Each player turn adds `max(0, 85 − playerturn / 850 + 3 × (depth − min_depth))`
to `min_depth_counter`. Time and being deeper than the minimum both push it up.

### Victory

The player wins by walking off the edge of the map (`do_cmd_escape()` in
`src/files.c`, called from `move_player()` in `src/cmd1.c`). This is only
possible at the Gates.

### Traps

Source: `hit_trap()` in `src/cmd1.c`. All trap effects are hardcoded; there is
no trap data in the data files.

| Constant                | Effect                                                           |
| ----------------------- | ---------------------------------------------------------------- |
| `FEAT_TRAP_FALSE_FLOOR` | Fall to the next level, falling damage                           |
| `FEAT_TRAP_PIT`         | 2d4 damage                                                       |
| `FEAT_TRAP_SPIKED_PIT`  | 2d4 damage, then 4d5 spikes vs. protection; cuts                 |
| `FEAT_TRAP_DART`        | If it hits (1d15 vs. protection): 1 damage, STR drain            |
| `FEAT_TRAP_GAS_CONF`    | Confusion +4d4                                                   |
| `FEAT_TRAP_GAS_MEMORY`  | Forget the map (saving throw)                                    |
| `FEAT_TRAP_ALARM`       | Very loud noise                                                  |
| `FEAT_TRAP_FLASH`       | Blindness +5d4                                                   |
| `FEAT_TRAP_CALTROPS`    | Perception check; else 1d4 damage and slow +4d4                  |
| `FEAT_TRAP_ROOST`       | Summons up to 2 birds/bats; the trap disappears                  |
| `FEAT_TRAP_WEB`         | Summons a spider                                                 |
| `FEAT_TRAP_DEADFALL`    | Pushes the player to a free square; if none, 6d8 damage and stun |
| `FEAT_TRAP_ACID`        | 4d4 acid damage                                                  |

### Terrain behavior

`terrain.txt` defines only name, symbol, color and mimic. All other terrain
behavior is hardcoded by feature ID ranges (`FEAT_*` and `FEAT_*_HEAD`/`_TAIL`
in `src/defines.h`) and macros such as `cave_floor_bold()`, `cave_trap_bold()`,
`cave_wall_bold()`. Per-square state is in `cave_info` (`CAVE_*` flags, e.g.,
`CAVE_WALL`, `CAVE_GLOW`, `CAVE_MARK`).

Examples: `FEAT_CHASM` (2), `FEAT_GLYPH` (3), `FEAT_WARDED`/`2`/`3` (6–8, warded
doors), `FEAT_SUNLIGHT` (9), `FEAT_RUBBLE` (0x31).

### Thrall quest

Source: `reward_player_for_quest()` and the `quest_*[]` arrays in `src/cmd1.c`,
vault letters `z`/`Z` in `build_vault()` in `src/generate.c`.

Vaults can place thralls and an orc thrallmaster. If the quest has not started,
one thrall is an alert thrall. The quest index is
`r_idx − R_IDX_ALERT_HUMAN_THRALL`: the human thrall asks for a light, the elf
thrall asks for food. `p_ptr->thrall_quest` tracks the state.

Reward: if the elf thrall's quest is done and the player has less than half HP,
the elf heals the player. Else, by 1d3: a herb of Rage, a herb of Terror, or
information about nearby passages (`QUEST_REWARD_MAP`).

### Silmarils and Morgoth's crown

Source: `prise_silmaril()` and `shatter_weapon()` in `src/cmd3.c`,
`silmarils_possessed()` in `src/files.c`.

The crown is 4 artefacts, one per number of Silmarils:

| Artefact ID | Constant        | Silmarils |
| ----------- | --------------- | --------- |
| 178         | `ART_MORGOTH_3` | 3         |
| 177         | `ART_MORGOTH_2` | 2         |
| 176         | `ART_MORGOTH_1` | 1         |
| 175         | `ART_MORGOTH_0` | 0         |

To free a Silmaril, the player stands on the crown and uses `k`. This is a melee
attack against the crown: the hit roll must succeed, and the damage must exceed
the crown's protection of 10d4 (`pd = 10` in `prise_silmaril()`; reduced by
sharpness). On success, `o_ptr->name1` is decremented and a Silmaril
(`SV_LIGHT_SILMARIL`) goes into the inventory.

| Silmaril | Noise | Consequence                                                                                     |
| -------- | ----- | ----------------------------------------------------------------------------------------------- |
| 1st      | 5     | None                                                                                            |
| 2nd      | 10    | 50%: the weapon shatters and the Silmaril stays. Else Morgoth gets angry (state 2).             |
| 3rd      | 15    | The weapon shatters and the Silmaril stays. If a weapon already shattered: the player is cursed |

`p_ptr->crown_shatter` records that a weapon already shattered. After that, the
2nd Silmaril never shatters a weapon.

The number of Silmarils carried also changes monster generation during the
escape (`src/generate.c`, `src/dungeon.c`) and the score.

### Damage and effect types (`GF_*`)

Source: `GF_*` in `src/defines.h`, `project_m()` and `project_p()` in
`src/spells1.c`.

| Value | Constant        | Value | Constant       |
| ----- | --------------- | ----- | -------------- |
| 1     | `GF_HURT`       | 14    | `GF_SLOW`      |
| 2     | `GF_ARROW`      | 15    | `GF_SPEED`     |
| 3     | `GF_BOULDER`    | 16    | `GF_CONFUSION` |
| 4     | `GF_ACID`       | 17    | `GF_SLEEP`     |
| 5     | `GF_ELEC`       | 18    | `GF_FEAR`      |
| 6     | `GF_FIRE`       | 19    | `GF_HEAL`      |
| 7     | `GF_COLD`       | 20    | `GF_KILL_WALL` |
| 8     | `GF_POIS`       | 21    | `GF_KILL_DOOR` |
| 9     | `GF_DARK`       | 22    | `GF_KILL_TRAP` |
| 10    | `GF_DARK_WEAK`  | 23    | `GF_LOCK_DOOR` |
| 11    | `GF_LIGHT`      | 24    | `GF_AWAY_ALL`  |
| 12    | `GF_SOUND`      | 25    | `GF_IDENTIFY`  |
| 13    | `GF_EARTHQUAKE` | 26    | `GF_WEB`       |

Resistances:

| Element   | Player               | Monster                         |
| --------- | -------------------- | ------------------------------- |
| `GF_FIRE` | `RES_FIRE` item flag | `RES_FIRE`                      |
| `GF_COLD` | `RES_COLD`           | `RES_COLD`                      |
| `GF_ELEC` | `RES_ELEC`           | `RES_ELEC`                      |
| `GF_POIS` | `RES_POIS`           | `RES_POIS`                      |
| `GF_DARK` | `resist_dark()`      | `BRTH_DARK` or `UNDEAD`         |
| `GF_FEAR` | `RES_FEAR`           | Will check; `NO_FEAR` adds +100 |

The monster flags `RES_NETHR`, `RES_WATER`, `RES_PLAS`, `RES_NEXUS` and
`RES_DISEN` are parsed, but no monster uses them and no code checks them.

### Scoring

Source: `score_points()` in `src/files.c`.

The score is a number that sorts runs. From least to most important: fewer
turns, race challenge (Sindar/Naugrim +3, Edain +5), no fixed experience (+1),
the Oath of Iron kept (+2), Silmarils, depth (max depth without a Silmaril,
closeness to the surface with one), and killing Morgoth.

## Graphics and visibility

See [rendering.md](rendering.md) and [visibility.md](visibility.md).

## Key source files

| File (in `src/`) | Primary content                                                     |
| ---------------- | ------------------------------------------------------------------- |
| `birth.c`        | Character creation, skill point costs                               |
| `cave.c`         | Visibility/LOS, `map_info()` (rendering), `distance()`              |
| `cmd1.c`         | Combat, criticals, traps, knock back, thrall quest, escape          |
| `cmd2.c`         | Stairs, `min_depth()`                                               |
| `cmd3.c`         | Silmaril removal, crown                                             |
| `cmd4.c`         | Abilities, smithing, bane bonuses, forge bonus                      |
| `cmd6.c`         | Using staffs and other items                                        |
| `defines.h`      | Most constants (`TV_*`, `SV_*`, `FEAT_*`, `R_IDX_*`, `GF_*`, flags) |
| `dungeon.c`      | Main loop, hunger, regeneration, descent XP, min depth counter      |
| `files.c`        | Pref file parser, scoring, `silmarils_possessed()`                  |
| `generate.c`     | Level and vault generation, special monster placement               |
| `init1.c`        | Edit file parsers (`parse_*_info()`)                                |
| `init2.c`        | Loading edit files (`init_info()`)                                  |
| `melee1.c`       | Monster blows (`RBE_*`)                                             |
| `melee2.c`       | Monster AI, perception, morale, stance                              |
| `monster2.c`     | Monster creation, health, `monster_skill()`                         |
| `object2.c`      | Object generation, forge placement, identification XP               |
| `spells1.c`      | `GF_*` effects on monsters and the player                           |
| `tables.c`       | `extract_energy[]`                                                  |
| `types.h`        | Structs (`player_type`, `monster_race`, `object_type`)              |
| `use-obj.c`      | Effects of herbs, potions, staves, horns                            |
| `wizard2.c`      | Debug commands                                                      |
| `xtra1.c`        | Player bonuses, stats, skills, speed                                |
| `xtra2.c`        | Status effects, experience, Morgoth, truce                          |
