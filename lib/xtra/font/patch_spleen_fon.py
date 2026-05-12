#!/usr/bin/env python3
"""
Patch the resolution metadata in the Spleen .fon files.

Vanilla Spleen registers spleen-5x8/6x12/12x24/32x64.fon as 120 DPI raster
fonts ("8514 res"). On the standard 96 DPI Windows desktop, the GDI font
mapper penalizes that resolution mismatch heavily enough that a CreateFont()
call asking for "Spleen" at the matching pixel height substitutes a smaller
default font, which renders only in the top-left of each (correctly-sized)
character cell. The 8x16 and 16x32 variants ship as 96 DPI and work as-is.

This script rewrites dfVertRes / dfHorizRes from 120 to 96, and recomputes
dfPoints from the pixel height so the registration stays internally
consistent (points = pixHeight * 72 / 96). It updates both the RT_FONT FNT
header and the matching RT_FONTDIR DIRENTRY so font enumeration and font
mapping agree.

This script is idempotent: files already at 96 DPI are not modified.

Run from anywhere:
    python3 lib/xtra/font/patch_spleen_fon.py
"""

import struct
import sys
from pathlib import Path

TARGET_DPI = 96
SOURCE_DPI = 120

NE_OFFSET_AT = 0x3C
NE_RESOURCE_TABLE_OFFSET_AT = 0x24
RT_FONTDIR = 0x8007
RT_FONT = 0x8008

# Field offsets within a (v2.0 or v3.0) FNT header. The same layout is used for
# the DIRENTRY records inside FONTDIR.
FNT_DFPOINTS = 68
FNT_DFVERTRES = 70
FNT_DFHORIZRES = 72
FNT_DFPIXHEIGHT = 88

# Within FONTDIR, each DIRENTRY is preceded by a 2-byte ordinal number.
FONTDIR_NUMFONTS_SIZE = 2
FONTDIR_ORDINAL_SIZE = 2


def u16(buf, off):
    return struct.unpack_from("<H", buf, off)[0]


def write_u16(buf, off, value):
    struct.pack_into("<H", buf, off, value)


def find_resource(data, type_id):
    """Yield (offset, length) for every resource of the given type."""
    ne_off = struct.unpack_from("<I", data, NE_OFFSET_AT)[0]
    res_table = ne_off + u16(data, ne_off + NE_RESOURCE_TABLE_OFFSET_AT)
    align_shift = u16(data, res_table)
    cur = res_table + 2
    while True:
        rt_type = u16(data, cur)
        if rt_type == 0:
            return
        count = u16(data, cur + 2)
        cur += 8
        for _ in range(count):
            offset = u16(data, cur) << align_shift
            length = u16(data, cur + 2) << align_shift
            if rt_type == type_id:
                yield (offset, length)
            cur += 12


def patch_fnt(buf, fnt_offset, points_new):
    """Update dfPoints, dfVertRes, dfHorizRes in an FNT header in-place."""
    write_u16(buf, fnt_offset + FNT_DFPOINTS, points_new)
    write_u16(buf, fnt_offset + FNT_DFVERTRES, TARGET_DPI)
    write_u16(buf, fnt_offset + FNT_DFHORIZRES, TARGET_DPI)


def patch_fontdir(buf, fontdir_offset, points_new):
    """Update every DIRENTRY inside a FONTDIR resource."""
    num_fonts = u16(buf, fontdir_offset)
    cursor = fontdir_offset + FONTDIR_NUMFONTS_SIZE
    for _ in range(num_fonts):
        direntry = cursor + FONTDIR_ORDINAL_SIZE
        write_u16(buf, direntry + FNT_DFPOINTS, points_new)
        write_u16(buf, direntry + FNT_DFVERTRES, TARGET_DPI)
        write_u16(buf, direntry + FNT_DFHORIZRES, TARGET_DPI)
        # Step over this entry. The DIRENTRY is the FNT header layout up to
        # dfBitsOffset+dfReserved; v2.0 = 117 bytes, v3.0 = 148 bytes.
        version = u16(buf, direntry)
        entry_size = 117 if version == 0x0200 else 148
        cursor = direntry + entry_size


def patch_file(path):
    data = bytearray(path.read_bytes())

    fnts = list(find_resource(data, RT_FONT))
    if not fnts:
        return f"{path.name}: no FNT resource — skipped"

    # Inspect the first FNT to decide whether this file needs patching.
    fnt_off, _ = fnts[0]
    vert = u16(data, fnt_off + FNT_DFVERTRES)
    horiz = u16(data, fnt_off + FNT_DFHORIZRES)
    pix_height = u16(data, fnt_off + FNT_DFPIXHEIGHT)

    if vert == TARGET_DPI and horiz == TARGET_DPI:
        return f"{path.name}: already {TARGET_DPI} DPI — skipped"
    if vert != SOURCE_DPI or horiz != SOURCE_DPI:
        return f"{path.name}: unexpected DPI {horiz}x{vert} — skipped"

    # Equivalent point size at the target DPI for the same pixel height.
    points_new = round(pix_height * 72 / TARGET_DPI)

    for fnt_off, _ in fnts:
        patch_fnt(data, fnt_off, points_new)
    for fd_off, _ in find_resource(data, RT_FONTDIR):
        patch_fontdir(data, fd_off, points_new)

    path.write_bytes(bytes(data))
    return (f"{path.name}: {pix_height}px {SOURCE_DPI}DPI -> "
            f"{TARGET_DPI}DPI, points {points_new}")


def main():
    font_dir = Path(__file__).resolve().parent
    targets = sorted(font_dir.glob("spleen-*.fon"))
    if not targets:
        print(f"No spleen-*.fon files found in {font_dir}", file=sys.stderr)
        return 1
    for path in targets:
        print(patch_file(path))
    return 0


if __name__ == "__main__":
    sys.exit(main())
