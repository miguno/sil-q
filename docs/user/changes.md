______________________________________________________________________

## title: Latest Changes

## Release Overview

| Sil-Q Version | Release Date |
| ------------- | ------------ |
| 1.5.1-beta1   | unreleased   |
| 1.5.0         | 2022-01-03   |
| 1.4.2         | 2019-05-05   |
| 1.4.1         | 2018-12-18   |
| 1.4.0         | 2018-06-27   |
| 1.3.0 (Sil)   | 2016-01-04   |
| 1.0.0 (Sil)   | 2012-01-03   |

## Sil-Q 1.5.1-beta1 (unreleased)

### Highlights

- macOS version supports Retina displays (thanks backwardsEric)
- Many bug fixes

### Breaking changes

- TODO (none thus far)

### Gameplay

- TODO (none thus far)

### All Details

Added:

- macOS: Support retina display
  ([#96](https://github.com/sil-quirk/sil-q/pull/96))

Changed:

- Updates to tiles and manual
  ([8c9cd7c](https://github.com/sil-quirk/sil-q/commit/8c9cd7c))

Fixed:

- fix: prevent signed integer overflow in update_mon()
  ([#131](https://github.com/sil-quirk/sil-q/pull/131))
- fix: docs for lightning chance for cross-shaped rooms
  ([#129](https://github.com/sil-quirk/sil-q/pull/129))
- fix: out-of-bounds access when searching disarmed chests
  ([#128](https://github.com/sil-quirk/sil-q/pull/128))
- fix: show "Mortal wound" if a player's cuts are >= 100
  ([#126](https://github.com/sil-quirk/sil-q/pull/126))
- fix: out-of-bounds access in get_move_wander()
  ([#125](https://github.com/sil-quirk/sil-q/pull/125))
- macOS: cap window sizes so do not exceed z-term's limits
  ([#123](https://github.com/sil-quirk/sil-q/pull/123))
- MicroChasm's tiles: correct two potion flavor assignments
  ([#119](https://github.com/sil-quirk/sil-q/pull/119))
- Call make_patches_of_sunlight() after placing player
  ([#114](https://github.com/sil-quirk/sil-q/pull/114))
- Fix for riposte not being added to monster lore
  ([beb980b](https://github.com/sil-quirk/sil-q/commit/beb980b))
- Fix for skeletons and chests not being searchable in dark corridors
  ([e81113f](https://github.com/sil-quirk/sil-q/commit/e81113fe4c906480d21bb97b275ac818e2a09796))
- macOS: only allow changing the graphics mode while waiting for a game command
  or while on the splash screen
  ([#103](https://github.com/sil-quirk/sil-q/pull/103))
- In smithing add flag or ability menus for artefacts, don't add invalid option
  if valid option is highlighted and a letter is pressed for an invalid option
  ([#102](https://github.com/sil-quirk/sil-q/pull/102))
- Fix typos in the tutorial notes
  ([#101](https://github.com/sil-quirk/sil-q/pull/101))
- Update the tiles for macOS to match the current 16x16.bmp
  ([#99](https://github.com/sil-quirk/sil-q/pull/99))
- Mac: only allow saving from the menu bar when the core game is waiting for a
  player command ([#99](https://github.com/sil-quirk/sil-q/pull/98))

## Sil-Q 1.5.0 (2022-01-03)

### Highlights

- Mac support greatly improved thanks to backwardsEric

- Tiles are now supported on Linux, Windows and Mac

  - This uses a new tileset designed by MicroChasm

- New manual by MicroChasm

### Gameplay

- Ability changes

  - Melee
    - Smite now shows main attack in red to make it clear it is active
  - Archery
    - Puncture buffed from 3 to 5
    - Crippling Shot buffed
  - Evasion
    - Blocking changed, buffed
  - Stealth
    - Cruel Blow buffed
  - Perception
    - Forewarned replaced with Outwit (Scatha feedback)
    - Master Hunter buffed - bonus doubled
  - Will
    - Tree rearranged, Curse Breaking at bottom
    - Hardiness and Critical Resistance removed
    - Oath and Formidable added
    - Inner Light buffed - bonus doubled
  - Song
    - Song of Whetting removed
    - Song of Slaying added
      - This is mechanically different to the old Song of Slaying
    - Song of Mastery buffed, wider range of outcomes
    - Song of Staying Will bonus halved

- Smithing changes

  - Smithing items removed
  - Curses removed from artifact creation
  - Smithing costs reduced to compensate
  - Guaranteed forges now at the first entrance to or below: 100', 300', 500'

- New egos and new effects

  - Resist Bleeding - as it says
    - Medic - increases health gained from healing items
    - Avoid Traps - avoids traps (but not webs, roosts or pits)
    - Cumbersome - the weapon does not get critical hits
    - Many new egos
    - Egos now conform better to weapon types e.g. curved swords have Angband
      rather than elven egos
    - Horn of Force can remove a certain crown
    - Staff of Earthquakes replaced by Staff of Dismay

- Objects tweaked

  - Handaxes now 4d2 instead of 5d1

- Lights

  - Mallorn torches added
  - Feanorian lamps buffed
  - Items on the floor no longer shed light by themselves
    - this is to avoid the behaviour where experienced players carried many
      lamps to debuff light sensitive foes

- New enemies

  - Attercops, spectres, wraiths
  - Unmourned removed
  - Human and elven thralls added as well as orcish thrallmasters
  - Human and elven thralls may request player character aid
  - Several enemies can now rally their escort, boosting morale

- Depth clock tweaked

  - Slightly more aggressive in the endgame
  - Responds to player - laggards get more time, divers a little less

- Score mechanism updated

  - Extra column in score between turn count and sils
  - 1 point for 5K start
  - 2 points for following iron man rules (formally or not)
  - 3 points for playing Naugrim or Sindar
  - 5 points for playing Edain

### Documentation

- New manual by MicroChasm
- Tutorial updated for Sil-Q abilities

### Bug fixes

- Many, many bugfixes

## Older releases

For changes of older releases, please read the detailed
[Change Log](https://github.com/sil-quirk/sil-q/blob/master/lib/docs/CHANGELOG.md).
