# Developer Mode (a.k.a. Wizard Mode, Debug Mode)

Developer mode is useful for development and testing. It is also called "Wizard
mode", and the special commands available in developer mode are also called
"debug commands" or "cheats".

## Source Code

The main entry point is function `do_cmd_debug()` in `src/wizard2.c`.

## How to enable developer mode

Type `Ctrl-a` in the game and answer with `Gondolin` in the password prompt. Now
you are in debug mode, and each `Ctrl-a` lets you input a debug command.

## Debug commands

### Using arguments with debug commands

A number of the commands take an argument (e.g., a count, an ID, or a range). To
supply an argument, type `R` for repeat, enter the value, then type `Ctrl-a`
followed by the debug command.

Example: You want to create the artefact `Ocrist`.

Orcrist has this record in `lib/edit/artefact.txt`, which sets its artefact ID
to 64 via `N:64:...`:

```
N:64:'Orcrist'
I:23:17:2
W:10:20:30:40000
P:2:2d5:2:0d0
F:SLAY_ORC | SLAY_TROLL | PERCEPTION
D:This gleaming blade, mate to Glamdring, is called simply
D: "Biter" by orcs who came to know its power all too well.
```

To create the `Orcrist`, you need to type:

```
R 64 Ctrl-a C
```

> Note: Artefacts are only generated once per game. `Ctrl-a T` (tile test) will
> generate all artefacts (and monsters, items, etc.) at once.

### Debug command reference

#### Help

| Key | Command           | Description                                                     |
| --- | ----------------- | --------------------------------------------------------------- |
| `?` | Help              | Opens the help screen                                           |
| `"` | Generate Spoilers | Creates spoiler files (only if `ALLOW_SPOILERS` is compiled in) |

#### Player character

| Key | Command             | Description                                                                                  |
| --- | ------------------- | -------------------------------------------------------------------------------------------- |
| `a` | Cure all            | Heals all wounds, cures all maladies, and restores stats                                     |
| `e` | Edit character      | Modify character stats (set stats to 20 to become nearly unkillable for testing)             |
| `k` | Self-knowledge      | Display detailed information about your character's abilities and resistances                |
| `x` | Increase experience | Gain experience points. With argument: gain that amount. Without argument: double current XP |

#### Navigation & detection

| Key | Command            | Description                                             |
| --- | ------------------ | ------------------------------------------------------- |
| `b` | Teleport to target | Teleport directly to a targeted location                |
| `d` | Detect all         | Detects all doors, traps, monsters, objects, and stairs |
| `j` | Jump               | Go to a specific dungeon level                          |
| `m` | Map reveal         | Reveals the entire map of the current dungeon level     |
| `p` | Phase door         | Short-range teleport (10 squares)                       |
| `t` | Teleport           | Long-range teleport (100 squares)                       |
| `w` | Wizard light       | Permanently illuminates the entire level                |

#### Object creation and manipulation

| Key | Command           | Description                                                                        |
| --- | ----------------- | ---------------------------------------------------------------------------------- |
| `c` | Create object     | Create any object by kind. Argument = number of objects to create (default: 1)     |
| `C` | Create artefact   | Create a specific artefact. Argument = artefact ID from `lib/edit/artefact.txt`    |
| `g` | Good objects      | Generate good-quality objects at your location. Argument = count (default: 1)      |
| `v` | Very good objects | Generate excellent-quality objects at your location. Argument = count (default: 1) |
| `T` | Tile test         | Clears the level and generates all items, monsters (alive!), and artefacts         |
| `i` | Identify          | Identify an item in your inventory                                                 |
| `o` | Object play       | Interactively examine and modify object properties                                 |

Artifacts are only generated once in the current run (i.e., for the lifetime of
the current character).

#### Monsters

| Key | Command          | Description                                                              |
| --- | ---------------- | ------------------------------------------------------------------------ |
| `n` | Summon named     | Summon a specific monster by ID. Argument = monster ID                   |
| `s` | Summon random    | Summon random monsters. Argument = count (default: 1)                    |
| `u` | Unhide monsters  | Reveal all hidden/invisible monsters. Argument = range (default: 255)    |
| `z` | Zap (banishment) | Destroy all monsters in range. Argument = range (default: line of sight) |

#### Tiles artwork

| Key | Command   | Description                                                                |
| --- | --------- | -------------------------------------------------------------------------- |
| `T` | Tile test | Clears the level and generates all items, monsters (alive!), and artefacts |

Artifacts are only generated once in the current run (i.e., for the lifetime of
the current character).

#### Dungeon and level

| Key | Command       | Description                                             |
| --- | ------------- | ------------------------------------------------------- |
| `l` | Wizard look   | Examine dungeon squares with detailed debug information |
| `q` | Query dungeon | Query dungeon feature flags at a location               |
| `f` | Forget        | Forget all items, map knowledge, and monster memory     |

#### Debug options

| Key | Command       | Description                                                                                            |
| --- | ------------- | ------------------------------------------------------------------------------------------------------ |
| `O` | Debug Options | Opens the debug options menu with settings for visualizing noise, scent, and other internal game state |

### Commonly used workflows

### Test a new artefact

1. Find the artefact ID in `lib/edit/artefact.txt`.
2. Type `R <artefact_id> Ctrl-a C` to create it.
3. Use `Ctrl-a i` to identify it if needed.

#### Explore a level safely

1. `Ctrl-a e` to edit character (set stats to 20).
2. `Ctrl-a d` to detect everything.
3. `Ctrl-a m` to reveal the map.
4. `Ctrl-a a` to heal whenever needed.

#### Test monster behavior

1. `Ctrl-a j` to jump to desired level.
2. `R <monster_id> Ctrl-a n` to summon a specific monster.
3. `Ctrl-a z` to clear monsters when done.

#### Test the tiles artwork

4. `Ctrl-a T` to generate all items, monsters, and artefacts on a cleared level.
   Be careful, because the monsters are alive and will attack you!
