# Game state

## Player state

- The player is hardcoded as entity `0` in the context of the `monster_race*`
  struct (`src/types.h:343-394`):

  ```c
  // `0` always refers to the player.
  monster_race* r_ptr = &r_info[0];
  ```

- The player's in-game state is primarily managed via `struct player_type`
  (`src/types.h:763`). Modifying the `player_type` struct can break savefiles!
