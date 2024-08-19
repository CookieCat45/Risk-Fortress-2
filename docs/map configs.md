# Risk Fortress 2 Mapping: Map Configs
Risk Fortress does not use a map cycle file. Instead, it uses configuration files in SourceMod's config directory
to define the maps that will be used in the game, as well as for configuring what kinds
of enemies and bosses will appear in said maps.<br/>
The map configuration file is located in `addons/sourcemod/configs/rf2/maps.cfg`, while configuration files
for enemies and bosses that appear in maps are normally located in `addons/sourcemod/configs/rf2/enemies/`.
Let's go over a brief example of how the map configuration file works:
<br/><br/>

```
"stages"
{
	"stage1"
	{
		"map1"
		{
			"name"					"rf2_sawmill"
			
			"enemy_pack"			"enemies/sawmill/sawmill_enemies"
			"boss_pack"				"enemies/sawmill/sawmill_bosses"
			"enemy_pack_loop"		"enemies/sawmill/sawmill_enemies_loop"
			"boss_pack_loop"		"enemies/sawmill/sawmill_bosses_loop"
			
			"theme"						"rf2/music/bgm1.mp3"
			"theme_duration"			"180"
			"boss_theme"				"rf2/music/boss_bgm1.mp3"
			"boss_theme_duration"		"135"
			
			"theme_alt"					"rf2/music/bgm1alt.mp3"
			"theme_alt_duration"		"171"
			"boss_theme_alt"			"rf2/music/boss_bgm1alt.mp3"
			"boss_theme_alt_duration"	"206"
			
			"grace_period_time"		"30.0"
		}
	}

	"stage2"
	{
		"map1"
		{
			"name"					"rf2_isolation"
			
			"enemy_pack"			"enemies/isolation/isolation_enemies"
			"boss_pack"				"enemies/isolation/isolation_bosses"
			"enemy_pack_loop"		"enemies/isolation/isolation_enemies_loop"
			"boss_pack_loop"		"enemies/isolation/isolation_bosses_loop"
			
			"theme"					"rf2/music/bgm2.mp3"
			"theme_duration"		"300"
			"boss_theme"			"rf2/music/boss_bgm2.mp3"
			"boss_theme_duration"	"184"
			
			"grace_period_time"		"30.0"
		}
		"map2"
		{
			"name"					"rf2_tropics"

			"enemy_pack"			"enemies/tropics/tropics_enemies"
			"boss_pack"				"enemies/tropics/tropics_bosses"
			"enemy_pack_loop"		"enemies/tropics/tropics_enemies_loop"
			"boss_pack_loop"		"enemies/tropics/tropics_bosses_loop"
			
			"theme"						"rf2/music/bgm6.mp3"
			"theme_duration"			"164"
			"boss_theme"				"rf2/music/boss_bgm6.mp3"
			"boss_theme_duration"		"134"
			
			"theme_alt"					"rf2/music/bgm6alt.mp3"
			"theme_alt_duration"		"267"
			"boss_theme_alt"			"rf2/music/boss_bgm6alt.mp3"
			"boss_theme_alt_duration"	"188.5"
			
			"grace_period_time"		"30.0"
		}
	}

  "special"
	{
		"underworld"
		{
			"name"					"rf2_hellscape_r1"
			"grace_period_time"		"-1.0"
		}
		"final"
		{
			"name"					"rf2_robotfactory"
			
			"enemy_pack"			"enemies/robotfactory/robotfactory_enemies"
			"boss_pack"				"enemies/robotfactory/robotfactory_bosses"
		}
	}
}
```
<br/>
As you can see, maps are grouped into categories called "stages". Each stage can define multiple different maps,
one of which will be chosen at random when the game transitions to the stage.
Whenever the last stage in the sequence is reached, it will loop back to Stage 1.<br/>

The `special` section is reserved for maps that can only be reached when specific conditions are met, such as Hellscape.
Entries in this section need to be implemented in the plugin to work. Currently, there is only `underworld` and `final`.
<br/><br/>

# Map Settings
Maps have a few settings that you can tweak in their own sections:<br/>

- `name`: The file name of the map, without the extension. You don't have to use the full name of the map, using only part of it works too.<br/>

- `enemy_pack`: The enemy pack to use for this map. We'll get into how to create and use these shortly. **Don't include the .cfg file extension**.<br/>

- `boss_pack`: The boss pack to use for this map. Bosses will appear during the Teleporter event or may spawn randomly when the difficulty reaches a certain point.<br/>

- `enemy_pack_loop`: Same as `enemy_pack`, but is used in place of it if the game has looped at least once.<br/>

- `boss_pack_loop`: Same as `boss_pack`, but is used in place of it if the game has looped at least once.<br/>

- `grace_period_time`: How long the grace period at the beginning of the map will last. Defaults to 30 seconds. -1 for no grace period.<br/>

- `theme`: Music track to play during the course of the map. The duration of the track needs to be specified in `theme_duration`, in seconds.<br/>

- `boss_theme`: Music track to play during the Teleporter event or when the tanks arrive in Tank Destruction mode. The duration of the track needs to be specified in `boss_theme_duration`, in seconds.<br/>

- `theme_alt`/`boss_theme_alt`/`theme_alt_duration`/`boss_theme_alt_duration`: Same as above, but used in place of the normal music tracks if the game has looped at least once.<br/>

- `tank_destruction`: Special keyvalue. 1 to enable Tank Destruction mode. The map needs to have `rf2_tank_spawner` entities placed for this to work.
