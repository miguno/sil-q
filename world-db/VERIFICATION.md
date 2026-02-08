# Phase 1 Verification Report

This document records the verification of Phase 1 findings for accuracy and
comprehensiveness.

## Summary

| Check                 | Status      | Notes                                        |
| --------------------- | ----------- | -------------------------------------------- |
| Quest system active   | ✅ Verified | `thrall_quest` used in 6 files, saved/loaded |
| Entity counts valid   | ✅ Verified | All counts within limits.txt bounds          |
| TilePicker comparison | ✅ Verified | Parsing logic matches, gaps identified       |
| Flag usage active     | ✅ Verified | RF1*RAND*\* used in code and data            |
| Git history review    | ✅ Verified | No major feature removals found              |

______________________________________________________________________

## 1. Quest System Verification

**Status:** Active (not legacy code)

**Evidence:**

- `thrall_quest` variable persisted in save files (`save.c:952`, `load.c:961`)
- Initialized at character birth (`birth.c:551`)
- Used in dungeon generation (`generate.c:2756-2762`)
- Multiple states: `QUEST_NOT_STARTED`, `QUEST_GIVER_PRESENT`,
  `QUEST_REWARD_MAP`, `QUEST_COMPLETE`
- Git history confirms active development: "Alert human and elven slaves may now
  ask the player for things" (commit 19c4f82)
- Renamed from "slaves" to "thralls" (commit 4fade51)

**Recommendation:** Update CODE_ANALYSIS.md to remove "to confirm" note.

______________________________________________________________________

## 2. Entity Count Verification

**limits.txt vs Actual Counts:**

| Entity Type     | Limit           | Actual Count | Status          |
| --------------- | --------------- | ------------ | --------------- |
| Features (M:F)  | 86              | 84           | ✅ Within limit |
| Objects (M:K)   | 600             | 196          | ✅ Within limit |
| Monsters (M:R)  | 656             | 152          | ✅ Within limit |
| Artifacts (M:A) | 20+180+1+50=251 | 122          | ✅ Within limit |
| Specials (M:E)  | 145             | 73           | ✅ Within limit |
| Races (M:P)     | 4               | 4            | ✅ Exact match  |
| Houses (M:C)    | 11              | 11           | ✅ Exact match  |
| Abilities (M:B) | 240             | 84           | ✅ Within limit |
| Flavors (M:L)   | 310             | 108          | ✅ Within limit |

**Note:** Limits are "maximum + 1" per file header comment.

______________________________________________________________________

## 3. TilePicker.html Comparison

### Verified Matching

| Component          | TilePicker                      | My Documentation | Match |
| ------------------ | ------------------------------- | ---------------- | ----- |
| Entity type codes  | K, R, F, L                      | K, R, F, L       | ✅    |
| object.txt format  | `N:id:name`, `I:tval:sval:pval` | Same             | ✅    |
| monster.txt format | `N:id:name`                     | Same             | ✅    |
| terrain.txt format | `N:id:name`                     | Same             | ✅    |
| flavor.txt format  | `N:id:tval:sval`, `D:name`      | Same             | ✅    |
| PRF line format    | `[LSFKR]:id:0xYY/0xXX`          | Same             | ✅    |

### Gaps Identified

1. **S: entries in PRF files (Special graphics)**

   - TilePicker parses these for digits, arrows, breath effects, spells
   - Not documented in DATA_FILES.md
   - Format: `S:0xID:0xYY/0xXX` with preceding `##` comment as name
   - **Action:** Add section to DATA_FILES.md

2. **Player tile equipment states**

   - TilePicker defines 16 equipment states per race
   - My docs mention 4×16 tiles but don't list the states
   - States: Unarmed, Small sword, Curved sword, Big sword, Spear, Small axe,
     Big axe, Quarterstaff, Shield+weapon, Shield+big axe, Shield+small axe,
     Dual swords, Sword+axe, Axe+sword, Dual axes, Bow
   - **Action:** Add detailed list to WORLD_MODEL.md

3. **xtra-new.prf conditional syntax**

   - Player tiles use `?:[EQU $CLASS ...][EQU $RACE ...]` conditionals
   - Not documented in DATA_FILES.md
   - **Action:** Document PRF conditional syntax

______________________________________________________________________

## 4. Flag Usage Verification

### RF1 Flags (Monster)

| Flag        | In Code                            | In Data        | Status |
| ----------- | ---------------------------------- | -------------- | ------ |
| RF1_RAND_25 | ✅ melee2.c, monster1.c, randart.c | ✅ 3+ monsters | Active |
| RF1_RAND_50 | ✅ melee2.c, monster1.c, randart.c | ✅ 6+ monsters | Active |

### TR Flags (Item)

Spot-checked TR1_STR, TR2_RES_FIRE - both actively parsed and applied.

______________________________________________________________________

## 5. Git History Review

**Period:** 2020-01-01 to present

**Findings:**

- No major game features removed
- Active development with balance changes
- Build system cleanup (removing old platform support)
- "Slaves" renamed to "thralls" (terminology change)
- Several new abilities and items added
- Song of Whetting → Song of Slaying rename

**Deprecated/Removed:**

- Old build targets (Amiga, typewriter, old Mac)
- Some unused randart code
- Nothing affecting game data structures

______________________________________________________________________

## 6. Additional Findings

### Active but Undocumented

1. **Morgoth state system** - Confirmed in code, documented in CODE_ANALYSIS.md
2. **Truce system** - Confirmed in code, documented in CODE_ANALYSIS.md
3. **Silmaril mechanics** - Confirmed in code, documented in CODE_ANALYSIS.md

### Terminology Changes

- "Slaves" → "Thralls" (commit 4fade51)
- "Song of Whetting" → "Song of Slaying" (commit c847c9b)
- "of Grace" → limited to mithril helms/lesser jewels (commit 1da0125)

______________________________________________________________________

## 7. Action Items

### Documentation Updates Needed

1. **DATA_FILES.md:**

   - Add S: line format for special graphics in PRF files
   - Add PRF conditional syntax documentation
   - Add explicit counts for each entity type

2. **WORLD_MODEL.md:**

   - Add complete list of 16 player equipment states
   - Add tile coordinate calculation formula

3. **CODE_ANALYSIS.md:**

   - Remove "to confirm" note from Quest System section
   - Add git commit references for verification

### Counts Completed

All entity counts verified - all within limits.txt bounds.

______________________________________________________________________

## Conclusion

Phase 1 findings are **substantially accurate**. The main gaps are:

1. **Minor omissions** in PRF file documentation (S: entries, conditionals)
2. **Missing detail** on player tile equipment states

No **incorrect** information was found. The quest system concern was validated -
it is actively used and maintained. All entity counts verified against
limits.txt.
