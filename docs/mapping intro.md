# Risk Fortress 2 Mapper's Introduction

Creating maps for Risk Fortress is a very simple process at its core. The most that is needed for a basic functional map is a navigation mesh 
and some Teleporter spawn points. However, Risk Fortress provides a vast set of different entities and functionality to use to create more advanced maps
that are able to utilize their own form of logic, such as custom objectives, secret areas that reward players with loot, and more. This is all provided
by the `rf2.fgd` file, which exposes the functionality of many of the custom entities that the plugin utilizes to the Hammer Editor, to be placed inside of your map.
<br/><br/> 

Before we get started, let's go through a quick tutorial on how to install custom .fgd files inside of Hammer. I'll be using 
[Hammer++](https://ficool2.github.io/HammerPlusPlus-Website/) specifically in this guide,
which I highly recommend using over the stock Hammer Editor if you aren't already.
<br/><br/>

### Adding the custom FGD file to Hammer
1. Download `rf2.fgd` from the Releases page in this repository.
2. Go to your Team Fortress 2 installation folder. Place `rf2.fgd` inside of the `Team Fortress 2/bin/` directory.
3. Start up Hammer. Go to **Tools -> Options**.
4. Next to the **Game Data files** list, click **Add**. Find and open `rf2.fgd` in the prompt, in the directory that you placed it in.
5. Restart Hammer. The next time you open Hammer you should see some new entities in the entity list, prefixed with `rf2_`.
<br/><br/>

## Mapping Basics in Hammer
With that out of the way, it's time to go over the basics of how to get a Risk Fortress map up and running. There's not too much to cover here, as making a Risk Fortress map inside of Hammer alone is very simple. At the bottom of the page, there's also some important knowledge and tips that you should be aware of, as well as links to the other guides that cover the other aspects of the Risk Fortress mapping process in more depth.
<br/><br/>

### Creating a Functional Map: Objectives
For a Risk Fortress map to work, there needs to be an objective for RED Team to complete, after which the map will end. There are multiple ways to implement this:
- Placing Teleporter spawn points around the map using the `rf2_teleporter_spawn` entity
- Placing Tank spawn points using the `rf2_tank_spawner` entity, to be used in Tank Destruction mode
- Creating a custom objective using the `rf2_gamerules` entity (this is more advanced and will be covered in the entity guide)
<br/>

Placing `rf2_teleporter_spawn` entities is simple enough - just place them and you're done. `rf2_tank_spawner` works the same way, although comes with some custom keyvalues to change attributes on the Tanks that are spawned by it, such as health and speed. These are covered in the entity guide, as it is outside the scope of this guide. Note that the inputs to spawn Tanks defined in the `rf2_tank_spawner` entity are not required for Tank Destruction mode to work, only placing the entity is required. Said entity is also not mutually exclusive to Tank Destruction mode - it can be used in any type of map.
<br/><br/>

### Creating a Functional Map: Nav Mesh
Risk Fortress uses the [Nav Mesh](https://developer.valvesoftware.com/wiki/Nav_Mesh) (or navigation mesh) for quite a few different things, but more importantly, it is used for **spawning objects and enemies on the map**. Obviously, generating a nav mesh should only be done when the map itself is in a finished or at least playable state. However, there is certain data contained in the nav mesh that the plugin will use, or in other words, [Nav Mesh Attributes](https://developer.valvesoftware.com/wiki/Nav_Mesh_Editing#Area_Attributes). Risk Fortress utilizes the following:
<br/><br/>
**Base Attributes (nav_mark_attribute)**<br/>
- `NO_HOSTAGES`: Used to prevent objects and enemies from spawning in this nav area.

**TF Attributes (tf_mark)**
- `NO_SPAWNING`: Same as NO_HOSTAGES, prevents spawning
- `SENTRY_SPOT`: Used to specify **Engineer bot build locations**. When marking these areas, make sure there's lots of space for the Engineer bot to build. The Engineer will stand on the center of the area and build each type of building around it. This attribute will be required if you want your map to have Engineer bots.
<br/><br/>

### Nav Mesh: World Center Entity
To assist the plugin in using the nav mesh as a means of spawning objects and enemies, it is highly recommended that you use an `rf2_world_center` entity to define a center point from which to spawn them. This entity should always be placed in the very center of the playing area in your map, and only one should exist.
<br/><br/>

### Nav Mesh: Fixing Up Nav Meshes
Often after generating a nav mesh using the `nav_generate` command, it may generate nav mesh in undesired areas, such as outside of the map's boundaries. After generating the nav mesh, you should enter [Nav Mesh Editing Mode](https://developer.valvesoftware.com/wiki/Nav_Mesh_Editing) and check for undesired results that you may want to fix up. Otherwise, you may end up with objects and enemies spawning outside of the map's boundaries!<br/>
A tip to prevent this from happening in the first place is to use `tools/toolsclip` brushes for clipping instead of `tools/toolsplayerclip`. The nav generator will generate through player clips, but not through regular clip brushes. So, if you block off-limits areas in your map using regular clip brushes instead of player clips, the nav generator will likely not generate anything in those areas, which can save you a lot of tedious nav mesh editing!
<br/><br/>

### Gargoyle Altar Spawn Points
`rf2_altar_spawn` is another spawn point entity that is used to define spawn points for Gargoyle Altars and works similarly to `rf2_teleporter_spawn`. Gargoyle Altars serve as entrances to the special Underworld shop map where players can buy and trade for items in peace. They are meant to be placed in hidden or hard to reach locations. Ideally, every map should have altar spawn points, though it is not a requirement.
<br/><br/>

### Important Knowledge/Tips
- `func_respawnroom` and `func_regenerate` entities should not be used, and will be removed by the plugin when the map is running. Risk Fortress by nature does not utilize respawn rooms. If you need `func_respawnroomvisualizer`, use `func_forcefield` instead.
- Despite the above, `info_player_teamspawn` entities should still be placed in your map for both teams. BLU Team (robots) will spawn randomly around the map but `info_player_teamspawn` entities are still required for them to spawn. RED Team (survivors) will always spawn at `info_player_teamspawn` entities.
- Health and ammo kits shouldn't be placed either, as players have infinite reserve ammo and regenerate health automatically.
- Make sure that doorways or tight passages in your map are spacious enough for giant robots to fit through.
- For map layouts in general, maps that are very spacious and open are ideal, as this will give lots of room for objects/enemies to spawn, as well as more room for players to kite around enemies. Cramped maps, maps with low ceilings, maps that are too small, or otherwise non-spacious maps should be avoided.
<br/><br/>

## Other Guides
