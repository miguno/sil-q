## Tile Mapping System

### Overview

Game entities (objects, monsters, terrain, etc.) are defined in two separate
locations:

1. **Definition files** (`lib/edit/*.txt`) - Define entity properties and names
2. **Preference files** (`lib/pref/*.prf`) - Assign graphical tiles to entities

The **numeric ID** in each file links them together.

### File Mapping

| Entity Type | Definition File        | Pref Line Format       | Array               |
| ----------- | ---------------------- | ---------------------- | ------------------- |
| Objects     | `lib/edit/object.txt`  | `K:<id>:<attr>/<char>` | `k_info`            |
| Monsters    | `lib/edit/monster.txt` | `R:<id>:<attr>/<char>` | `r_info`            |
| Terrain     | `lib/edit/terrain.txt` | `F:<id>:<attr>/<char>` | `f_info`            |
| Flavors     | `lib/edit/flavor.txt`  | `L:<id>:<attr>/<char>` | `flavor_info`       |
| Special     | (hardcoded)            | `S:<id>:<attr>/<char>` | `misc_to_attr/char` |

### Example

From `lib/edit/object.txt`, note the `N:374` at the beginning of the block:

    N:374:& Small jewelled chest~
    G:~:v1
    I:7:3:0
    W:19:0:750:250
    P:0:0d0:0:0d0
    A:19/8
    F:IGNORE_ALL

From `lib/pref/graf-new.prf`, note the `K:374` at the beginning of the line:

    # & Small jewelled chest~
    K:374:0x81/0x84

Both reference ID `374`. The definition file sets the name and properties,
whereas the pref file assigns the tile coordinates `0x81/0x84`.

### Name Formatting Tokens

Object names in `object.txt` use special tokens:

- `&` — Replaced with appropriate article ("a", "an", "the", or count)
- `~` — Marks pluralization point (adds "s" or "es" when count > 1)
- `#` — Replaced with flavor text (e.g., "Amethyst" for rings)

Example: `& Small jewelled chest~` becomes:

- "a Small jewelled chest" (count=1)
- "3 Small jewelled chests" (count=3)

### Source Code

- Definition parsing: `src/init1.c` (`parse_k_info`, `parse_r_info`, etc.)
- Pref file parsing: function `process_pref_file_command` in `src/files.c`
- Name formatting: function `object_desc()` in `src/object1.c`
