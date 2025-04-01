# Risk Fortress 2 Mapping: Map Configs
Risk Fortress does not use a map cycle file. Instead, it uses configuration files in SourceMod's config directory
to define the maps that will be used in the game, as well as for configuring what kinds of robots will appear in said maps.<br/>
Map configuration files are located in directories inside of `addons/sourcemod/configs/rf2/maps/`, while configuration files
for robots that appear in maps are normally located in `addons/sourcemod/configs/rf2/enemies/`.<br><br>
Each stage has its own individual folder, e.g. `rf2/maps/stage1/`, `rf2/maps/stage2/`, and so on, with some special ones such as `rf2/maps/underworld/`. Each of the .cfg files in these individual folders have a filename that matches the name of the map they are associated with, e.g. `rf2_sawmill_r1.cfg`. If there are multiple map configs in a given stage folder, one will be chosen at random when transitioning to that stage.<br>
### This is what a map configuration file normally looks like
```
"map"
{
    "enemy_pack       "enemies/sawmill/sawmill_enemies"
    "boss_pack"       "enemies/sawmill/sawmill_bosses"
    "enemy_pack_loop" "enemies/sawmill/sawmill_enemies_loop"
    "boss_pack_loop"  "enemies/sawmill/sawmill_bosses_loop"

    "theme"                     "rf2/music/bgm1.mp3"
    "theme_duration"            "180"
    "boss_theme"                "rf2/music/boss_bgm1.mp3"
    "boss_theme_duration"       "135"

    "theme_alt"                 "rf2/music/bgm1alt.mp3"
    "theme_alt_duration"        "171"
    "boss_theme_alt"            "rf2/music/boss_bgm1alt.mp3"
    "boss_theme_alt_duration"   "206"

    "grace_period_time"         "30.0"
}

```

# Map Settings

- `enemy_pack`: The enemy pack to use for this map. **Don't include the .cfg file extension**.<br/>

- `boss_pack`: The boss pack to use for this map. Bosses (normally giants) will appear during the Teleporter event or may spawn randomly when the enemy level reaches a certain point.<br/>

- `enemy_pack_loop`: Same as `enemy_pack`, but is used in place of it if the run has looped at least once.<br/>

- `boss_pack_loop`: Same as `boss_pack`, but is used in place of it if the run has looped at least once.<br/>

- `grace_period_time`: How long the grace period at the beginning of the map will last. Defaults to 30 seconds. -1 for no grace period.<br/>

- `theme`: Music track to play during the course of the map. The duration of the track needs to be specified in `theme_duration`, in seconds.<br/>

- `boss_theme`: Music track to play during the Teleporter event or when the tanks arrive in Tank Destruction mode. The duration of the track needs to be specified in `boss_theme_duration`, in seconds.<br/>

- `theme_alt`/`boss_theme_alt`/`theme_alt_duration`/`boss_theme_alt_duration`: Same as above, but used in place of the normal music tracks if the game has looped at least once.<br/>

- `tank_destruction`: Enables Tank Destruction mode. The map needs to have `rf2_tank_spawner` entities placed for this to work.

- `max_spawn_wave_time`: The maximum amount of time in seconds between robot spawn waves. If unspecified, the spawn timer will behave as normal.

- `boss_spawn_chance_bonus`: Can increase the chance for bosses to randomly spawn. Starting at enemy level 20, there will be a 1 in 250 chance for a boss to spawn in place of a regular robot, which increases by 1 every 4 levels onwards, but this key can be used to add to this chance value.

- `disable_eureka_teleport`: Disables the Eureka Effect's teleport ability.

- `disable_item_dropping`: Prevent players from dropping their items.

- `start_money_multiplier`: Multiplier for the amount of money that players begin the map with.


# Risk Fortress 2 Mapping: Robot Configs
Maps normally have two configuration files for robot types: one for the common robot types, and another for the boss robots, who are usually giants.


```
"enemies"
{
	"example_heavy"
	{
		"name"			"Example Heavy"
		"class"			"heavy"
		"health"		"300"
		"speed"			"280"
		"weight"		"25"

		"xp_award"		"30"
		"cash_award"	"15"

		"tf_bot_difficulty"	"1"
		
		"weapon1"
		{
			"classname"		"tf_weapon_minigun"
			"index"			"15"               
			"attributes"
			{
				"damage bonus" "1.2"
				"fire rate bonus" "0.8"
			}
		}

                "weapon2"
		{
			"classname"		"tf_weapon_fists"
			"index"			"5"
			"attributes"		
			{
				"fire rate bonus" "0.5"
			}
		}
		
		"wearable1"
		{
			"index"		"246"
		}

	}
}
```


### General Keyvalues
- `name`: The bot's name. Self explanatory.

- `class`: The bot's class, e.g. `scout`, `soldier`, `pyro`

- `health`: The bot's base max health. Scales with level.

- `speed`: The bot's movement speed in hammer units per second.

- `group`: The bot's spawning group. This can be changed by the map on the fly, and if the map does so, only bots from this group will spawn. Defaults to none.

- `model`: Custom model to use if set, e.g. `models/player/heavy.mdl`. Defaults to the robot model for the class if unspecified

- `model_scale`: The bot's model scale. Defaults to 1.75 for bosses.

- `xp_award`: The bot's base XP drop. Scales with level.

- `money_award`: The bot's base money drop. Scales with level.

- `weight`: Value that determines how often a bot will spawn in comparison to others. Defaults to 50.

- `active_limit`: How many of this bot type that can be active on the map at once. Defaults to 0 (no limit).

- `spawn_limit`: How many times this bot is allowed to spawn during the course of the map. Defaults to 0 (no limit).

- `spawn_cooldown`: The time in seconds that must pass before this bot is allowed to spawn again. Defaults to 0.


### TFBot Behavior Keyvalues
- `tf_bot_difficulty`: The bot's skill level. 0 = Easy, 1 = Normal, 2 = Hard, 3 = Expert. Defaults to Normal.
Note that higher difficulty settings can override this unless `tf_bot_difficulty_no_override` is set to 1.

- `tf_bot_difficulty_no_override`: If 1, prevents higher difficulty settings from overriding the bot's skill level. Defaults to 0.

- `tf_bot_constant_jump`: If 1, forces the bot to constantly jump.

- `tf_bot_aggressive`: If 1, forces the bot to aggressively chase down its target. Bots wielding melee weapons will utilize this behavior automatically. Defaults to 0.

- `tf_bot_rocketjump`: If 1 on a Soldier bot, allows it to rocket jump. Defaults to 0.

- `tf_bot_hold_fire_until_reload`: If 1, the bot will not fire its weapon until the clip is fully loaded. Defaults to 0.

- `tf_bot_always_attack`: If 1, forces the bot to constantly fire its weapon. Defaults to 0.

- `tf_bot_melee_distance`: If a bot's target gets this close to it in hammer units, the bot will switch to its melee weapon. Defaults to 0.

- `tf_bot_uber_on_sight`: If 1, forces a Medic bot to use it's UberCharge the moment it spots an enemy. Defaults to 0.

- `tf_bot_behavior_flags`: TFBot attributes (the ones you can set in MvM popfiles such as AlwaysCrit). This is a bitflag. You probably don't want to touch this - most of them don't work outside of MvM anyways.

- `suicide_bomber`: This one is a section. Causes the bot to behave like a Sentry Buster, except that it goes after players instead of buildings. Here is an example usage:
```
"suicide_bomber"
{
	"name"      "Player Buster"
	"class"     "demoman"
	"health"    "600"
	"speed"     "360"
	"model"     "models/bots/demo/bot_sentry_buster.mdl"
	"weight"    "50"
	"voice_pitch" "125"
	
	"tf_bot_difficulty" "3"
	
	"suicide_bomber"
	{
		"damage"        600		// Damage of the explosion (default 600)
		"range"         300		// Range of the explosion (default 300)
		"friendly_fire" 1		// Should the explosion deal friendly fire damage (default 1)
		"delay"         2.0		// Delay in seconds before the explosion happens (default 2.0)
		
		"use_buster_sounds"     1	// Should the bot play sentry buster sound effects (default 1)
		"use_damage_falloff"    1	// Should the explosion have damage falloff (default 1)
	}
	
	"weapon1"
	{
		"classname"     "tf_weapon_grenadelauncher"
		"index"         "19"
		"attributes"
		{
			"no_attack" 1
			"special taunt" 1 // disables thriller taunt
		}
	}
}
```

### Miscellaneous Keyvalues
- `scripts`: A section that specifies VScript files to be run on the bot when it spawns. The bot will be the `self` variable in the script.
```
"scripts"
{
	"1" "my_script_file.nut"
	"2" "my_other_script_file.nut"
}
```

- `tags`: A section that specifies a list of tags to give to the bot. Useful for scripts.
```
"tags"
{
	"1" "first_tag"
	"2"	"second_tag"
}
```

- `full_rage`: Forces the bot to spawn with a full rage meter, for weapons such as banners. Defaults to 0.

- `no_bleeding`: Prevents the bot from generating blood particles when it takes damage. Defaults to 1.

- `glow`: Forces the bot to have an outline. Defaults to 0.

- `no_crits`: Prevents this bot from dealing any kind of crit or mini-crit damage. Defaults to 0.

- `eye_glow`: Enables the eye glow effect for robots. Defaults to 1.

- `engine_idle_sound`: Plays the engine idle sound for boss robots. Defaults to 1 for bosses.


### Weapons Section Keyvalues
For a list of weapon classnames and item definition indexes, see this page: https://wiki.alliedmods.net/Team_fortress_2_item_definition_indexes

For a list of weapon attributes, see this page: https://wiki.teamfortress.com/wiki/List_of_item_attributes

- `classname`: The weapon's entity classname.

- `index`: The weapon's item definition index. This will define the weapon's appearance and default stats.

- `attributes`: Attributes section. See the above example.

- `strip_attributes`: If 1, strips all of the default stats on the weapon. The default stats are based on the weapon's item definition index.

- `visible`: If 0, causes the weapon's model to be invisible.

- `active_weapon`: If 1, this will be the bot's active weapon when it spawns.

- `empty_clip`: If 1, this weapon's clip will be empty when the bot spawns.


There is also a wearables section for giving wearable items to the bot. For the most part, it is the same as the weapons section.
```
"wearable1"
{
	// The classname of the item defaults to tf_wearable
	
	"index"				"359" 	// Item def index (Samur-Eye)
	"visible"			"1"		// Is the wearable item visible, default 1
	"strip_attributes"	"0"		// Strip all base item stats from the wearable, default 0
}
"wearable2"
{
	// Demoman shields are wearables and need to be defined like this
	"classname"			"tf_wearable_demoshield"
	"index"				"406" 	// Splendid Screen
	
	// Wearables can also have attributes
	"attributes"
	{
		"charge recharge rate increased" 1.5
	}
}
```
