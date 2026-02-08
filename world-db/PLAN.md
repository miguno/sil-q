# Sil-Q World Database

## Overview

A comprehensive database containing information about all entities in the Sil-Q
game: monsters, objects/items, terrain features, skills, abilities, player
races, houses, and more.

## Purpose

- Facilitate understanding of game entities and their relationships
- Enable searching entities by name and viewing their properties (including
  visual representation in ASCII and tile modes)
- Support filtered queries such as:
  - "Show all monsters with the RAND_25 flag"
  - "Show all monsters with the same tile assignment (e.g., hex 0x8D/0x8B)"
  - "Show all objects with 'amulet' in their name"
  - "Show all monsters that spawn at 500ft depth or deeper"
- **Not** for use within the actual game - this is a separate developer/player
  reference tool

## Target Audience

1. Developers (primary)
2. Players (secondary, via potential static website)

## Technical Decisions

- **Database**: SQLite
- **Schema philosophy**: Human-readable (e.g., boolean column named `RAND_25`
  rather than bitmasks)
- **Parsing tool**: Typed Python 3.14, using [uv](https://docs.astral.sh/uv/)
  for package management
- **Versioning**: Database will track the git commit of sil-q from which data
  was extracted

## Entities to Include

- Monsters (individual types and monster "groups" via tval/sval)
- Objects/Items (base items)
- Artefacts (unique items like "Glamdring" from `lib/edit/artefact.txt`)
- Special item suffixes (dynamically generated items via `lib/edit/special.txt`)
- Terrain features (doors, etc.)
- Player races (from `lib/edit/race.txt`)
- Player houses (from `lib/edit/house.txt`)
- Skills and abilities (usable by players, monsters, and possibly other entities
  like traps)

## Data Sources

Data is spread across multiple locations:

| Location          | Content                                                         |
| ----------------- | --------------------------------------------------------------- |
| `lib/edit/*.txt`  | Primary game data files                                         |
| `lib/pref/*.prf`  | Tile assignments (focus on `graf-new.prf` and `flvr-new` files) |
| `src/*.c`         | Hardcoded behavior extending the data files                     |
| `src/defines.h`   | tval/sval definitions, flag definitions                         |
| `TilePicker.html` | Prior art for parsing game data files (JavaScript)              |

## Out of Scope

The following files are excluded unless their data directly relates to other
`lib/edit/*.txt` data:

- `lib/edit/vault.txt`
- `lib/edit/history.txt`
- `lib/edit/limits.txt`
- `lib/edit/names.txt`

## Complications to Address

1. **Scattered data**: Monster/object data spread across txt files, C code, and
   headers
2. **tval/sval semantics**: Need to confirm how these distinguish individual
   types vs. groups
3. **Obsolete code/data**: Codebase contains unused legacy data that must be
   identified and excluded
4. **Dynamic items**: Items with suffixes combined at runtime (modeled in
   `special.txt`)
5. **Artefacts**: Unique items not yet parsed by TilePicker.html

## Approach

### Phase 1: World Model Documentation

Build a comprehensive overview of all code and data files that define the game's
"world" in terms of entities and properties. Document in Markdown files within
this directory.

### Phase 2: Database Schema Design

Design SQLite schema based on Phase 1 findings. Schema should:

- Favor human-readability
- Model discovered relationships between entities
- Track source git commit

### Phase 3: Parsing/Import Tool

Create typed Python tool that:

- Parses C code, game data files, headers
- Populates the database from scratch (empty → repopulate approach)
- Runs occasionally when game data changes, not part of game loop

### Phase 4: Test Suite

Verify database accuracy against source data.

## File Structure

```
world-db/
├── PLAN.md                  # This file - project specification
├── docs/
    ├── DATA_FILES.md        # Analysis of lib/edit/*.txt formats
    ├── CODE_ANALYSIS.md     # Analysis of hardcoded behavior in src/*.c
    └── WORLD_MODEL.md       # Comprehensive entity/relationship model
└── (future: Python tool, SQLite DB, tests)
```
