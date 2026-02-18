# Visibility and Line of Sight

This document describes how Sil-Q decides which squares the player can see. The
code is in `src/cave.c`. For other systems, see [code_base.md](code_base.md).

In this document, "grid" and "square" mean the same thing: one map cell with
coordinates `(y, x)`. `+y` is down (south) and `+x` is right (east).

## Visibility flags

Each square has flags in `cave_info[y][x]` (`CAVE_*` in `src/defines.h`). Three
of them control visibility:

| Flag        | Meaning                               | Lifetime   | Set by          |
| ----------- | ------------------------------------- | ---------- | --------------- |
| `CAVE_VIEW` | In line of sight of the player        | Per update | `update_view()` |
| `CAVE_SEEN` | In line of sight _and_ lit            | Per update | `update_view()` |
| `CAVE_MARK` | Remembered by the player (on the map) | Persistent | `note_spot()`   |

`note_spot()` sets `CAVE_MARK` only for squares that are `CAVE_SEEN`:

- "Interesting" squares (walls, doors, stairs, traps, etc.) are always
    remembered.
- Floor-like squares are remembered only if they are permanently lit
    (`CAVE_GLOW`). Dark corridor floors are visible only while `CAVE_SEEN`.

Objects use a separate flag: `o_ptr->marked`, set in `note_spot()`.

## Distance

`distance()` approximates Euclidean distance without a square root:

```c
ay = abs(y1 - y2);
ax = abs(x1 - x2);
return (ay > ax) ? (ay + (ax >> 1)) : (ax + (ay >> 1));
```

That is `max(dy, dx) + min(dy, dx) / 2`. The area within a fixed distance is an
octagon, not a circle.

| dy  | dx  | Euclidean | `distance()` |
| --- | --- | --------- | ------------ |
| 0   | 10  | 10.0      | 10           |
| 3   | 4   | 5.0       | 5            |
| 7   | 7   | 9.9       | 10           |
| 10  | 10  | 14.1      | 15           |

`MAX_SIGHT` (20) is the maximum view distance; `MAX_RANGE` (20) is the maximum
range of spells etc. Both are in `src/defines.h`.

## The view algorithm

`update_view()` computes `CAVE_VIEW` and `CAVE_SEEN`. It uses data that
`vinfo_init()` calculates once at startup.

### Octants

The view is split into 8 octants of 45°. The algorithm stores data for one
octant only (east to southeast, where `x >= y`) and maps it to the other 7 by
symmetry. `vinfo_init()` does this with 8 transforms:

```c
vinfo[e].grid[0] = GRID(+y, +x);  // octant 0: E  to SE
vinfo[e].grid[1] = GRID(+x, +y);  // octant 1: SE to S
vinfo[e].grid[2] = GRID(+x, -y);  // octant 2: S  to SW
vinfo[e].grid[3] = GRID(+y, -x);  // octant 3: SW to W
vinfo[e].grid[4] = GRID(-y, -x);  // octant 4: W  to NW
vinfo[e].grid[5] = GRID(-x, -y);  // octant 5: NW to N
vinfo[e].grid[6] = GRID(-x, +y);  // octant 6: N  to NE
vinfo[e].grid[7] = GRID(-y, +x);  // octant 7: NE to E
```

```
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

Squares on an axis or a diagonal belong to two octants and can get `CAVE_VIEW`
from either one.

### Grids and slopes

| Constant           | Value | Meaning                                     |
| ------------------ | ----- | ------------------------------------------- |
| `VINFO_MAX_GRIDS`  | 161   | Squares in one octant within `MAX_SIGHT`    |
| `VINFO_MAX_SLOPES` | 126   | Distinct line-of-sight slopes in one octant |

- **Grids (161).** All `(y, x)` with `0 <= y <= x <= 20` and
    `distance(0, 0, y, x) <= 20`. Without the distance limit there would be 231.
    The full view has 1149 unique squares, because octants share their boundary
    squares.
- **Slopes (126).** For each of the 161 grids, `vinfo_init()` calculates the
    slope from the player's center to each of the 4 corners of the grid (scaled
    by `SCALE` = 100000). It keeps each distinct slope in `(0, SCALE]`. 126
    remain. Slope 0 (value 2439, about 1.4°) is next to the axis; slope 125
    (value 100000) is the 45° diagonal. The same numbering is used in all
    octants.

Both numbers were found empirically. The comment on `vinfo_init()` says: set the
constants too high, run the function, and use the error messages to get the
correct values.

Each `vinfo[]` entry stores, for one grid of the base octant:

- `grid[8]`: the grid offset in each octant;
- `bits_0` … `bits_3`: a 126-bit mask (4 × 32 bits) of the slopes that pass
    through the grid;
- `next_0`, `next_1`: the next grids for the outward scan;
- `y`, `x`, `d`: coordinates and distance.

### Wall blocking

For each octant, `update_view()` scans outward from the player, starting with
all 126 slopes valid. A grid is in view if at least one of its slopes is still
valid:

```c
if ((bits0 & (p->bits_0)) || (bits1 & (p->bits_1))
 || (bits2 & (p->bits_2)) || (bits3 & (p->bits_3)))
```

When the scan finds a wall, it removes the wall's slopes from the valid set:

```c
bits0 &= ~(p->bits_0);
bits1 &= ~(p->bits_1);
bits2 &= ~(p->bits_2);
bits3 &= ~(p->bits_3);
```

Grids behind the wall whose slopes are all removed do not get `CAVE_VIEW`.
