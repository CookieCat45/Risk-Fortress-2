# Risk Fortress 2 Mapping: Map Configs
Risk Fortress does not use a map cycle file. Instead, it uses configuration files in SourceMod's config directory
to define the maps that will be used in the game, as well as for configuring what kinds of robots will appear in said maps.<br/>
Map configuration files are located in directories inside of `addons/sourcemod/configs/rf2/maps/`, while configuration files
for robots that appear in maps are normally located in `addons/sourcemod/configs/rf2/enemies/`.<br><br>
Each stage has its own individual folder, e.g. `rf2/maps/stage1/`, `rf2/maps/stage2/`, and so on, with some special ones such as `rf2/maps/underworld/`. Each of the .cfg files in these individual folders have a filename that matches the name of the map they are associated with, e.g. `rf2_sawmill_r1.cfg`. If there are multiple map configs in a given stage folder, one will be chosen at random when transitioning to that stage.<br>
Let's go over a brief example of how the map configuration file works:

# Map Settings
Maps have a few settings that you can tweak in their own sections:<br/>

- `enemy_pack`: The enemy pack to use for this map. We'll get into how to create and use these shortly. **Don't include the .cfg file extension**.<br/>

- `boss_pack`: The boss pack to use for this map. Bosses will appear during the Teleporter event or may spawn randomly when the difficulty reaches a certain point.<br/>

- `enemy_pack_loop`: Same as `enemy_pack`, but is used in place of it if the game has looped at least once.<br/>

- `boss_pack_loop`: Same as `boss_pack`, but is used in place of it if the game has looped at least once.<br/>

- `grace_period_time`: How long the grace period at the beginning of the map will last. Defaults to 30 seconds. -1 for no grace period.<br/>

- `theme`: Music track to play during the course of the map. The duration of the track needs to be specified in `theme_duration`, in seconds.<br/>

- `boss_theme`: Music track to play during the Teleporter event or when the tanks arrive in Tank Destruction mode. The duration of the track needs to be specified in `boss_theme_duration`, in seconds.<br/>

- `theme_alt`/`boss_theme_alt`/`theme_alt_duration`/`boss_theme_alt_duration`: Same as above, but used in place of the normal music tracks if the game has looped at least once.<br/>

- `tank_destruction`: 1 to enable Tank Destruction mode. The map needs to have `rf2_tank_spawner` entities placed for this to work.

- `max_spawn_wave_time`: The maximum amount of time in seconds between robot spawn waves. If unspecified, the spawn timer will behave as normal.

- `boss_spawn_chance_bonus`: Can increase the chance for bosses to randomly spawn. Starting at enemy level 20, there will be a 1 in 250 chance for a boss to spawn in place of a regular robot, which increases by 1 every 4 levels onwards, but this keyvalue can be used to add to this chance value.

- `disable_eureka_teleport`: Disables the Eureka Effect's teleport ability.

- `disable_item_dropping`: Prevent players from dropping their items.

- `start_money_multiplier`: Multiplier for the amount of money that players begin the map with.
