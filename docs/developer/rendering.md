# Tile Rendering System

This document describes how Sil-Q renders entities (player, monsters, objects,
features) using either ASCII characters or graphical tiles.

## Display fields: `d_attr`/`d_char` vs. `x_attr`/`x_char`

Every renderable entity type (player, monsters, objects, features, flavors) has
four display fields defined in `src/types.h`:

```c
byte d_attr;   /* Default attribute (from data files) */
char d_char;   /* Default character (from data files) */
byte x_attr;   /* Desired attribute (what should be displayed in the next rendering run) */
char x_char;   /* Desired character (what should be displayed in the next rendering run) */
```

- **`d_attr`/`d_char`**: The defaults loaded from data files (e.g., a line with
    `G:V:D` in `lib/edit/monster.txt` sets `d_char` to `'V'` and `d_attr` to the
    color code for dark). These are also used for non-visual purposes in some
    cases.
- **`x_attr`/`x_char`**: The desired/requested values to be displayed in the
    next rendering run. Initialized as copies of `d_attr`/`d_char`, then may be
    overridden by pref files (`lib/pref/*.prf`) or changed at runtime by game
    logic.

## ASCII graphics vs. tiles graphics mode

The game supports three graphics modes, defined in `src/defines.h`:

```c
#define GRAPHICS_NONE        0   /* ASCII */
#define GRAPHICS_MICROCHASM  1   /* Graphical tiles */
#define GRAPHICS_PSEUDO      2   /* Pseudo-graphics (ASCII-based) */
```

`graphics_are_ascii()` (in `src/cmd1.c`) returns true for `GRAPHICS_NONE` and
`GRAPHICS_PSEUDO`.

In **ASCII mode**, `x_attr` is a terminal color and `x_char` is a printable
ASCII character (e.g., `'V'` for Morgoth).

In **tiles mode**, `x_attr` and `x_char` are repurposed as tile coordinates into
the tileset image (`lib/xtra/graf/16x16_microchasm.png`), with bit 7 (`0x80`)
set as a flag that indicates "tiles mode". The prf file
`lib/pref/graf-tiles.prf` sets these values, such as:

```
R:251:0x8A/0x92
```

This sets `x_attr = 0x8A` and `x_char = 0x92` for monster index 251 (Morgoth).

## Bit layout of `x_attr` and `x_char` in graphical mode

Each byte encodes three pieces of information:

```
┌─────┬──────┬───────────────────────────────────────────────────────────────┐
│ Bit │ Mask │                         Meaning                               │
├─────┼──────┼───────────────────────────────────────────────────────────────┤
│ 7   │ 0x80 │ Graphics flag — "this is a tile, not ASCII"                   │
├─────┼──────┼───────────────────────────────────────────────────────────────┤
│ 6   │ 0x40 │ Runtime overlay flag — alert (on x_char) or glow (on x_attr)  │
├─────┼──────┼───────────────────────────────────────────────────────────────┤
│ 5-0 │ 0x3F │ Actual tile row (from x_attr) or column (x_char), values 0–63 │
└─────┴──────┴───────────────────────────────────────────────────────────────┘
```

The rendering backends extract the tile coordinates with `& 0x3F`:

```c
// From `Term_pict_x11()` in `main-x11.c`:
x1 = (c & 0x3F) * td->fnt->twid; // column in tileset
y1 = (a & 0x3F) * td->fnt->hgt;  // row in tileset
```

The `0x80` graphics flag is checked in `map_info()` of `cave.c` to decide
whether to render a tile or an ASCII character:

```c
// True if game runs in tiles graphics mode.
if ((da & 0x80) && (dc & 0x80))
{
    a = da;
    c = dc;
}
```

### Example: Morgoth (`R:251:0x8A/0x92`)

| Field    | Hex value | Graphics flag (`& 0x80`) | Overlay flag (`& 0x40`) | Tile coordinate (`& 0x3F`) |
| -------- | --------- | ------------------------ | ----------------------- | -------------------------- |
| `x_attr` | `0x8A`    | `0x80` (set)             | `0x00` (clear)          | `0x0A` = row 10            |
| `x_char` | `0x92`    | `0x80` (set)             | `0x00` (clear)          | `0x12` = column 18         |

## Overlay icons: alert and glow

Two overlay effects are composited on top of base tiles at render time. Both use
bit 6 (`0x40`) as a flag, but on different bytes.

### Alert overlay

- **Flag**: `GRAPHICS_ALERT_MASK` (`0x40`) on `x_char`.
- **When set**: In `map_info()` (`src/cave.c`), when a monster's
    `alertness >= ALERTNESS_ALERT` in graphical mode:
    ```c
    c += GRAPHICS_ALERT_MASK;
    ```
- **Icon tile**: `ICON_ALERT` (`0x0B`), mapped in the pref file as
    `S:0x0B:0x8C/0x8B`.

### Glow overlay

- **Flag**: `GRAPHICS_GLOW_MASK` (`0x40`) on `x_attr`.
- **When set**: In the `object_attr` macro (`src/defines.h`), when
    `weapon_glows()` returns true:
    ```c
    (k_info[(T)->k_idx].x_attr) | GRAPHICS_GLOW_MASK
    ```
- **Icon tile**: `ICON_GLOW` (`0x0C`), mapped in the prf file as
    `S:0x0C:0x8C/0x8E`.

### How compositing works

The rendering backends (e.g., `composite_image()` in `src/main-x11.c`) strip the
overlay flags with `& 0x3F` to recover the base tile coordinates, then composite
pixel-by-pixel in this priority order:

1. Alert icon (if alert flag is set)
2. Foreground tile (the player/monster/item/object)
3. Glow icon (if glow flag is set)
4. Background terrain tile

A "blank" pixel color acts as transparency — if a higher-priority layer has a
blank pixel, the next layer shows through.

## Rage visual effects

While the player character is raging (`p_ptr->rage > 0`), we use a visual effect
to give the dungeon a hostile, "red" look. The visual effect is more
sophisticated in tiles graphics than in ASCII graphics.

### Rage visual effects in tiles graphics

In tiles graphics, the entire dungeon including monsters, items, floors, walls,
etc. turns red.

Additionally, monsters change their shape/form while rage is active. The in-game
reason is that the player character literally "sees red" and, due to the rage,
can no longer clearly distinguish between different sub-types of the same
monster. For example, an Orc Warrior and an Orc Archer will look the same to a
raging player. This effect includes unique monsters with the exception of
Morgoth.

#### Rage tint shader for tiles

The rage "shader" is a pre-tinted copy of the original tileset that the renderer
switches to while raging. Note that it is not a runtime per-pixel effect.

- **Build time**: at tileset load, the platform backend reads the tileset twice:
    once as-is, and once through `tint_rgb_for_rage()`, which converts each
    pixel to luma and rescales to
    `(luma * RAGE_TINT_RED_COEFF, luma * RAGE_TINT_GREEN_COEFF, luma * RAGE_TINT_BLUE_COEFF)`.
    The "blank"/transparent color is discovered at load time from pixel (0,0)
    of the tileset (Sil-Q convention for BMP transparency) and passed in to
    `tint_rgb_for_rage()` as `blank_r/blank_g/blank_b`. Pixels matching it are
    left unchanged, so compositing-time transparency still works regardless of
    which RGB the tileset chose for it.
- **Render time**: `Term_pict_x11()` / `Term_pict_win()` /
    `Term_xtra_cocoa_fresh()` select the pre-tinted image when `p_ptr->rage` is
    active and fall back to the normal image otherwise. The `(attr, char)`
    values produced by `map_info()` are unchanged.

Relevant constants (`src/defines.h`):

```c
#define RAGE_TINT_RED_COEFF   1.0
#define RAGE_TINT_GREEN_COEFF 0.3
#define RAGE_TINT_BLUE_COEFF  0.3
```

Per-platform pre-tinted image:

| Backend | Source-of-truth | Tinted variant                                                |
| ------- | --------------- | ------------------------------------------------------------- |
| X11     | `td->tiles`     | `td->tiles_rage`, built in `init_x11()` via `ReadBMPRage`     |
| Windows | `infGraph`      | `infGraph_rage`, built in `init_graphics()` via `ReadDIBRage` |
| macOS   | `pict_image`    | `pict_image_rage`, built by `create_rage_tinted_image()`      |

Because the model `(attr, char)` does not change when rage starts or ends,
`Term_queue_char()`'s dedupe against `Term->scr` would otherwise eat the redraw.
`set_rage()` in `src/xtra2.c` calls `redraw_all_terms()` to force a full repaint
when the rage state changes.

#### Rage-specific alternative tiles

In addition to tinting, individual monsters can declare a rage-specific
alternative tile that is shown in place of their normal tile while the player is
raging. The shader still tints the alternative.

- **Storage**: two extra fields on `monster_race` (in `src/types.h`):
    ```c
    byte rage_x_attr; /* 0 = no override, use the normal tile */
    char rage_x_char;
    ```
- **Pref-file syntax** in `lib/pref/graf-tiles.prf`:
    ```
    R:<id>:rage:<attr>/<char>
    ```
    parsed by `process_pref_file_command()` in `src/files.c`. Lines without a rage
    entry keep their normal tile. Each `R:<id>:rage:...` line must have a
    corresponding regular `R:<id>:...` line, because the rage form only
    overrides the tile, it does not register the monster.
- **Selection**: `map_info()` in `src/cave.c` substitutes
    `(rage_x_attr, rage_x_char)` for `(x_attr, x_char)` when raging in tiles
    mode.
- Defaults are reset by `reset_visuals()` in `src/object1.c` to `0/0` (no
    override).

### Rage visual effect in ASCII graphics

In ASCII mode, the rage tint shader is skipped. Instead, `map_info()` recolors
visible monsters to `TERM_RED` while raging. There is no equivalent of the
alternative-tile mechanism for ASCII.

## Preference (prf) files

Tile assignments are defined in prf files under `lib/pref/`. The main graphical
tileset mappings are in `lib/pref/graf-tiles.prf`.

The prf file parser in `src/files.c` handles these line formats:

| Prefix     | Entity type                                           | Example               |
| ---------- | ----------------------------------------------------- | --------------------- |
| `R`        | Player or Monster race                                | `R:251:0x8A/0x92`     |
| `R` (rage) | Optional rage-specific alternative tile for a monster | `R:11:rage:0x90/0x85` |
| `K`        | Object kind                                           | `K:131:0x8C/0x90`     |
| `F`        | Feature (floor, wall, etc)                            | `F:16:0x8A/0x9C`      |
| `S`        | Special/miscellaneous icon                            | `S:0x0B:0x8C/0x8B`    |

`S:` entries populate the `misc_to_attr[]`/`misc_to_char[]` arrays (defined in
`src/variable.c`), used for overlay icons and other special graphics like damage
number display.

## The rendering pipeline

### Step 1: `map_info()` (src/cave.c)

The central function `map_info()` determines the attr/char pair for each grid
cell. It outputs two pairs:

- **Foreground tile** (`*ap`/`*cp`): the player, a monster, an object, or a
    feature.
- **Background tile** (`*tap`/`*tcp`): the terrain tile underneath.

The game entity to be displayed in the foreground is selected by priority:

1. Visible monster (`m_idx > 0`): reads `r_ptr->x_attr`/`x_char`.
2. Player (`m_idx < 0`): reads `x_attr`/`x_char` for the player's race, offset
    by `player_tile_offset()`.
3. Visible object: uses the `object_attr`/`object_char` macros from `defines.h`.
4. Feature (floor, wall, etc.): reads `f_ptr->x_attr`/`x_char`.

In graphical mode, `map_info()` also applies the alert overlay flag
(`c += GRAPHICS_ALERT_MASK`) to the foreground char if a monster is alert, and
the glow flag is applied in the `object_attr` macro for glowing weapons.

### Step 2: `Term_pict_*()` (platform-specific backends)

The attr/char pairs from `map_info()` are passed to a platform-specific
rendering function. Each backend receives arrays of `n` cells to draw in one
call:

| Backend | Function            | Compositing approach                 |
| ------- | ------------------- | ------------------------------------ |
| X11     | `Term_pict_x11()`   | `composite_image()` — pixel-by-pixel |
| Windows | `Term_pict_win()`   | `TransparentBlt()` API calls         |
| macOS   | `Term_pict_cocoa()` | Core Graphics compositing            |
| GCU     | (none)              | ASCII only, no tile support          |

Each function receives four arrays of length `n`:

- `ap`/`cp`: foreground attr/char (the entity tile).
- `tap`/`tcp`: background attr/char (the terrain tile).

For each cell, the backend:

1. Extracts the foreground tile coordinates: `x1 = (c & 0x3F) * tile_width`,
    `y1 = (a & 0x3F) * tile_height`.
2. Extracts the terrain tile coordinates: `x3 = (tc & 0x3F) * tile_width`,
    `y3 = (ta & 0x3F) * tile_height`.
3. Checks the overlay flags: `alert = (c & 0x40)`, `glow = (a & 0x40)`.
4. Looks up the overlay icon pixel offsets from
    `misc_to_attr[]`/`misc_to_char[]`.
5. Composites the layers in order (bottom to top): terrain, glow icon,
    foreground tile, alert icon. A "blank" pixel color acts as transparency
    between layers.

## The tileset image

The tileset is `lib/xtra/graf/16x16.bmp` (BMP format) and the identical
`lib/xtra/graf/16x16_microchasm.png` (PNG format). The tileset dimensions are
512x272 pixels. Each tile is 16x16 pixels, giving a grid of 32 columns x 17
rows. Tile coordinates from the `x_attr`/`x_char` (row/column) fields index into
this grid.

## Key source files

| File                                 | Role                                                                                        |
| ------------------------------------ | ------------------------------------------------------------------------------------------- |
| `lib/pref/flvr-tiles.prf`            | Graphical tile assignments for flavored objects                                             |
| `lib/pref/graf-tiles.prf`            | Graphical tile assignments                                                                  |
| `lib/xtra/graf/16x16.bmp`            | The tileset image in BMP format (for Windows and X11)                                       |
| `lib/xtra/graf/16x16_microchasm.png` | The tileset image in PNG format (for macOS Cocoa)                                           |
| `src/cave.c`                         | `map_info()` — determines attr/char (and tiles) per grid cell                               |
| `src/cmd1.c`                         | `graphics_are_ascii()`                                                                      |
| `src/defines.h`                      | `GRAPHICS_ALERT_MASK`, `GRAPHICS_GLOW_MASK`, `ICON_ALERT`, `ICON_GLOW`, `RAGE_TINT_*_COEFF` |
| `src/files.c`                        | Pref file parser (R:/K:/F:/S: lines) for `lib/pref/*.prf`                                   |
| `src/main-cocoa.m`                   | macOS tile rendering and compositing; `create_rage_tinted_image()`                          |
| `src/main-win.c`                     | Windows tile rendering and compositing; `infGraph_rage`                                     |
| `src/main-x11.c`                     | X11 tile rendering and compositing; `td->tiles_rage`                                        |
| `src/maid-x11.c`                     | `ReadBMPNormal()` / `ReadBMPRage()` and the X11 `tint_rgb_for_rage()`                       |
| `src/readdib.c`                      | `ReadDIBNormal()` / `ReadDIBRage()` and the Windows `tint_rgb_for_rage()`                   |
| `src/types.h`                        | `d_attr`/`d_char`/`x_attr`/`x_char` plus `rage_x_attr`/`rage_x_char` on `monster_race`      |
| `src/variable.c`                     | `misc_to_attr[]`/`misc_to_char[]` arrays                                                    |
| `src/xtra2.c`                        | `set_rage()` triggers a full repaint so the shader's tileset switch is visible              |
