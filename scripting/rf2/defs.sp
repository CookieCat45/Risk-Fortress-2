#pragma semicolon 1
#pragma newdecls required
#define MAX_EDICTS 2048
#define PLAYER_MINS {-24.0, -24.0, 0.0}
#define PLAYER_MAXS {24.0, 24.0, 82.0}
#define MAX_COOKIE_LENGTH 100
#define TF_CLASSES 9+1 // because arrays
#define DMG_MELEE DMG_BLAST_SURFACE
#define INVALID_ENT INVALID_ENT_REFERENCE
#define SF_NORESPAWN (1 << 30)
#define MAX_PATH_FOLLOWERS 60
#define MAX_INVENTORIES 64
#define MAX_MAP_SIZE 32768.0
#define MAX_DAMAGE 32767.0 // Maximum possible single-instance damage in TF2
#define WAIT_TIME_DEFAULT 150 // Default Waiting For Players time
#define PING_COOLDOWN 1.2
#define OFF_THE_MAP 		{-16384.0, -16384.0, -16384.0}
#define FFADE_IN			0x0001		// Just here so we don't pass 0 into the function
#define FFADE_OUT			0x0002		// Fade out (not in)
#define FFADE_MODULATE		0x0004		// Modulate (don't blend)
#define FFADE_STAYOUT		0x0008		// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE			0x0010		// Purges all other fades, replacing them with this one
#define SCREENFADE_FRACBITS	9
#define	DifficultyFactor_Scrap 0.8
#define	DifficultyFactor_Iron 1.0
#define	DifficultyFactor_Steel 1.5
#define DifficultyFactor_Titanium 2.0

enum
{
	TF2Quality_Normal,
	TF2Quality_Genuine,
	TF2Quality_Unused1,
	TF2Quality_Vintage,
	TF2Quality_Unused2,
	TF2Quality_Unusual,
	TF2Quality_Unique,
	TF2Quality_Community,
	TF2Quality_Valve,
	TF2Quality_SelfMade,
	TF2Quality_Unused3,
	TF2Quality_Strange,
	TF2Quality_Unused4,
	TF2Quality_Haunted,
	TF2Quality_Collectors,
	TF2Quality_Decorated,
};

enum
{
	SOLID_NONE,
	SOLID_BSP,
	SOLID_BBOX,
	SOLID_OBB,
	SOLID_OBB_YAW,
	SOLID_TEST,
	SOLID_VPHYSICS,
};

enum
{
	COLLISION_GROUP_NONE  = 0,
	COLLISION_GROUP_DEBRIS,			// Collides with nothing but world and static stuff
	COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
	COLLISION_GROUP_INTERACTIVE_DEBRIS,	// Collides with everything except other interactive debris or debris
	COLLISION_GROUP_INTERACTIVE,	// Collides with everything except interactive debris or debris
	COLLISION_GROUP_PLAYER,
	COLLISION_GROUP_BREAKABLE_GLASS,
	COLLISION_GROUP_VEHICLE,
	COLLISION_GROUP_PLAYER_MOVEMENT,// For HL2, same as Collision_Group_Player, for TF2, this filters out other players and CBaseObjects
	COLLISION_GROUP_NPC,			// Generic NPC group
	COLLISION_GROUP_IN_VEHICLE,		// for any entity inside a vehicle
	COLLISION_GROUP_WEAPON,			// for any weapons that need collision detection
	COLLISION_GROUP_VEHICLE_CLIP,	// vehicle clip brush to restrict vehicle movement
	COLLISION_GROUP_PROJECTILE,		// Projectiles!
	COLLISION_GROUP_DOOR_BLOCKER,	// Blocks entities not permitted to get near moving doors
	COLLISION_GROUP_PASSABLE_DOOR,	// ** sarysa TF2 note: Must be scripted, not passable on physics prop (Doors that the player shouldn't collide with)
	COLLISION_GROUP_DISSOLVING,		// Things that are dissolving are in this group
	COLLISION_GROUP_PUSHAWAY,		// ** sarysa TF2 note: I could swear the collision detection is better for this than NONE. (Nonsolid on client and server, pushaway in player code)
	
	COLLISION_GROUP_NPC_ACTOR,		// Used so NPCs in scripts ignore the player.
	COLLISION_GROUP_NPC_SCRIPTED,	// USed for NPCs in scripts that should not collide with each other
	
	// TF2-specific collision groups
	TFCOLLISION_GROUP_SHIELD,
	TFCOLLISION_GROUP_OBJECT,
	TFCOLLISION_GROUP_OBJECT_SOLIDTOPLAYERMOVEMENT,
	TFCOLLISION_GROUP_COMBATOBJECT,
	TFCOLLISION_GROUP_ROCKETS,		// Solid to players, but not player movement. ensures touch calls are originating from rocket
	TFCOLLISION_GROUP_RESPAWNROOMS, // CookieCat note: Only collides with players
	TFCOLLISION_GROUP_TANK, 		// CookieCat note: Solid to everything except for players. Despite the name, it's only used by spell pumpkin bombs, not tanks.
	TFCOLLISION_GROUP_ROCKET_BUT_NOT_WITH_OTHER_ROCKETS, // CookieCat note: Used by most projectiles, same as TFCOLLISION_GROUP_ROCKETS but doesn't collide with itself or that group
};

// entity flags, CBaseEntity::m_iEFlags
#define EFL_KILLME						(1<<0)	// This entity is marked for death -- This allows the game to actually delete ents at a safe time
#define EFL_DORMANT						(1<<1)	// Entity is dormant, no updates to client
#define EFL_NOCLIP_ACTIVE				(1<<2)	// Lets us know when the noclip command is active.
#define EFL_SETTING_UP_BONES			(1<<3)	// Set while a model is setting up its bones.
#define EFL_KEEP_ON_RECREATE_ENTITIES 	(1<<4) // This is a special entity that should not be deleted when we restart entities only

#define EFL_HAS_PLAYER_CHILD			(1<<4)	// One of the child entities is a player.

#define EFL_DIRTY_SHADOWUPDATE			(1<<5)	// Client only- need shadow manager to update the shadow...
#define EFL_NOTIFY						(1<<6)	// Another entity is watching events on this entity (used by teleport)

// The default behavior in ShouldTransmit is to not send an entity if it doesn't
// have a model. Certain entities want to be sent anyway because all the drawing logic
// is in the client DLL. They can set this flag and the engine will transmit them even
// if they don't have a model.
#define EFL_FORCE_CHECK_TRANSMIT	(1<<7)
	
#define EFL_BOT_FROZEN				(1<<8)	// This is set on bots that are frozen.
#define EFL_SERVER_ONLY				(1<<9)	// Non-networked entity.
#define EFL_NO_AUTO_EDICT_ATTACH	(1<<10) // Don't attach the edict; we're doing it explicitly
	
// Some dirty bits with respect to abs computations
#define EFL_DIRTY_ABSTRANSFORM =				(1<<11)
#define EFL_DIRTY_ABSVELOCITY =					(1<<12)
#define EFL_DIRTY_ABSANGVELOCITY =				(1<<13)
//#define EFL_DIRTY_SURROUNDING_COLLISION_BOUNDS	(1<<14)
#define EFL_DIRTY_SPATIAL_PARTITION				(1<<15)
//	UNUSED										(1<<16)
#define EFL_IN_SKYBOX						(1<<17)	// This is set if the entity detects that it's in the skybox. This forces it to pass the "in PVS" for transmission.
#define EFL_USE_PARTITION_WHEN_NOT_SOLID 	(1<<18)	// Entities with this flag set show up in the partition even when not solid
#define EFL_TOUCHING_FLUID					(1<<19)	// Used to determine if an entity is floating
#define EFL_IS_BEING_LIFTED_BY_BARNACLE	 	(1<<20)
#define EFL_NO_ROTORWASH_PUSH				(1<<21)		// I shouldn't be pushed by the rotorwash
#define EFL_NO_THINK_FUNCTION				(1<<22)
#define EFL_NO_GAME_PHYSICS_SIMULATION 		(1<<23)
#define EFL_CHECK_UNTOUCH					(1<<24)
#define EFL_DONTBLOCKLOS					(1<<25)		// I shouldn't block NPC line-of-sight
#define EFL_DONTWALKON						(1<<26)		// NPC;s should not walk on this entity
#define EFL_NO_DISSOLVE						(1<<27)		// These guys shouldn't dissolve
#define EFL_NO_MEGAPHYSCANNON_RAGDOLL	 	(1<<28)	// Mega physcannon can't ragdoll these guys.
#define EFL_NO_WATER_VELOCITY_CHANGE  		(1<<29)	// Don't adjust this entity's velocity when transitioning into water
#define EFL_NO_PHYSCANNON_INTERACTION 		(1<<30)	// Physcannon can't pick these up or punt them
#define EFL_NO_DAMAGE_FORCES				(1<<31)	// Doesn't accept forces from physics damage

// m_nSolidType
#define SOLID_NONE 0 // no solid model
#define SOLID_BSP 1 // a BSP tree
#define SOLID_BBOX 2 // an AABB
#define SOLID_OBB 3 // an OBB (not implemented yet)
#define SOLID_OBB_YAW 4 // an OBB, constrained so that it can only yaw
#define SOLID_CUSTOM 5 // Always call into the entity for tests
#define SOLID_VPHYSICS 6 // solid vphysics object, get vcollide from the model and collide with that

// m_usSolidFlags
#define FSOLID_CUSTOMRAYTEST 0x0001 // Ignore solid type + always call into the entity for ray tests
#define FSOLID_CUSTOMBOXTEST 0x0002 // Ignore solid type + always call into the entity for swept box tests
#define FSOLID_NOT_SOLID 0x0004 // Are we currently not solid?
#define FSOLID_TRIGGER 0x0008 // This is something may be collideable but fires touch functions
							// even when it's not collideable (when the FSOLID_NOT_SOLID flag is set)
#define FSOLID_NOT_STANDABLE 0x0010 // You can't stand on this
#define FSOLID_VOLUME_CONTENTS 0x0020 // Contains volumetric contents (like water)
#define FSOLID_FORCE_WORLD_ALIGNED 0x0040 // Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
#define FSOLID_USE_TRIGGER_BOUNDS 0x0080 // Uses a special trigger bounds separate from the normal OBB
#define FSOLID_ROOT_PARENT_ALIGNED 0x0100 // Collisions are defined in root parent's local coordinate space
#define FSOLID_TRIGGER_TOUCH_DEBRIS 0x0200 // This trigger will touch debris objects

enum
{
	USE_OBB_COLLISION_BOUNDS = 0,
	USE_BEST_COLLISION_BOUNDS,		// Always use the best bounds (most expensive)
	USE_HITBOXES,
	USE_SPECIFIED_BOUNDS,
	USE_GAME_CODE,
	USE_ROTATION_EXPANDED_BOUNDS,
	USE_COLLISION_BOUNDS_NEVER_VPHYSICS,
	
	SURROUNDING_TYPE_BIT_COUNT = 3
};

enum // ParticleAttachment_t
{
	PATTACH_INVALID = -1,			// Not in original, indicates invalid initial value
	PATTACH_ABSORIGIN = 0,			// Create at absorigin, but don't follow
	PATTACH_ABSORIGIN_FOLLOW,		// Create at absorigin, and update to follow the entity
	PATTACH_CUSTOMORIGIN,			// Create at a custom origin, but don't follow
	PATTACH_POINT,					// Create on attachment point, but don't follow
	PATTACH_POINT_FOLLOW,			// Create on attachment point, and update to follow the entity
	PATTACH_WORLDORIGIN,			// Used for control points that don't attach to an entity
	PATTACH_ROOTBONE_FOLLOW,		// Create at the root bone of the entity, and update to follow
};

enum // Move collide types
{
	MOVECOLLIDE_DEFAULT,
	MOVECOLLIDE_FLY_BOUNCE, // Entity bounces, reflects, based on elasticity of surface and object - applies friction (adjust velocity) (Used by item_currencypack)
	MOVECOLLIDE_FLY_CUSTOM, // ENTITY:Touch will modify the velocity however it likes
	MOVECOLLIDE_FLY_SLIDE // Entity slides along surfaces (no bounce) - applies friciton (adjusts velocity)
};


// Configs --------------------------------------------------------------------------------------------------------------------------------------------
#define ConfigPath "configs/rf2"
#define ItemConfig "items.cfg"
#define SurvivorConfig "survivors.cfg"
#define WeaponConfig "weapons.cfg"


// Models/Sprites -------------------------------------------------------------------------------------------------------------------------------------
#define MODEL_ERROR "models/error.mdl"
#define MODEL_INVISIBLE "models/empty.mdl"
#define MODEL_CASH_BOMB "models/props_c17/cashregister01a.mdl"
#define MODEL_MERASMUS "models/bots/merasmus/merasmus.mdl"
#define MODEL_MEDISHIELD "models/props_mvm/mvm_player_shield2.mdl"

#define MAT_DEBUGEMPTY "debug/debugempty.vmt"
#define MAT_BEAM "materials/sprites/laser.vmt"

#define MODEL_BOT_SCOUT "models/rf2/bots/bot_scout.mdl"
#define MODEL_BOT_SOLDIER "models/rf2/bots/bot_soldier.mdl"
#define MODEL_BOT_PYRO "models/rf2/bots/bot_pyro.mdl"
#define MODEL_BOT_DEMO "models/rf2/bots/bot_demo_fix1.mdl"
#define MODEL_BOT_HEAVY "models/rf2/bots/bot_heavy.mdl"
#define MODEL_BOT_ENGINEER "models/rf2/bots/bot_engineer.mdl"
#define MODEL_BOT_MEDIC "models/rf2/bots/bot_medic.mdl"
#define MODEL_BOT_SNIPER "models/rf2/bots/bot_sniper.mdl"
#define MODEL_BOT_SPY "models/rf2/bots/bot_spy.mdl"
#define MODEL_GIANT_SCOUT "models/rf2/boss_bots/bot_scout_boss.mdl"
#define MODEL_GIANT_SOLDIER "models/rf2/boss_bots/bot_soldier_boss.mdl"
#define MODEL_GIANT_PYRO "models/rf2/boss_bots/bot_pyro_boss.mdl"
#define MODEL_GIANT_DEMO "models/rf2/boss_bots/bot_demo_boss_fix1.mdl"
#define MODEL_GIANT_HEAVY "models/rf2/boss_bots/bot_heavy_boss.mdl"

// Sounds -------------------------------------------------------------------------------------------------------------------------------------
#define SND_ITEM_PICKUP "ui/item_default_pickup.wav"
#define SND_GAME_OVER "music/mvm_lost_wave.wav"
#define SND_EVIL_LAUGH "rf2/sfx/evil_laugh.wav"
#define SND_LASTMAN "mvm/mvm_warning.wav"
#define SND_MONEY_PICKUP "mvm/mvm_money_pickup.wav"
#define SND_USE_WORKBENCH "ui/item_metal_scrap_pickup.wav"
#define SND_USE_SCRAPPER "ui/item_metal_scrap_drop.wav"
#define SND_DROP_DEFAULT "ui/itemcrate_smash_rare.wav"
#define SND_DROP_HAUNTED "misc/halloween/spell_skeleton_horde_cast.wav"
#define SND_DROP_UNUSUAL "ui/itemcrate_smash_ultrarare_fireworks.wav"
#define SND_ENTER_HELL "misc/halloween/gotohell.wav"
#define SND_CASH "mvm/mvm_bought_upgrade.wav"
#define SND_NOPE "vo/engineer_no01.mp3"
#define SND_MERASMUS_APPEAR "misc/halloween/merasmus_appear.wav"
#define SND_MERASMUS_DISAPPEAR "misc/halloween/merasmus_disappear.wav"
#define SND_MERASMUS_DANCE1 "vo/halloween_merasmus/sf12_wheel_dance03.mp3"
#define SND_MERASMUS_DANCE2 "vo/halloween_merasmus/sf12_wheel_dance04.mp3"
#define SND_MERASMUS_DANCE3 "vo/halloween_merasmus/sf12_wheel_dance05.mp3"
#define SND_BOSS_SPAWN "mvm/mvm_tank_start.wav"
#define SND_BOSS_DEATH "rf2/sfx/boss_death.wav"
#define SND_MEDSHIELD_DEPLOY "weapons/medi_shield_deploy.wav"
#define SND_SENTRYBUSTER_BOOM "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define SND_ENEMY_STUN "mvm/mvm_robo_stun.wav"
#define SND_TELEPORTER_CHARGED "mvm/mvm_bought_in.wav"
#define SND_TANK_SPEED_UP "misc/cp_harbor_red_whistle.wav"
#define SND_BELL "misc/halloween/strongman_bell_01.wav"
#define SND_SHIELD "weapons/medi_shield_deploy.wav"
#define SND_LAW_FIRE "weapons/sentry_rocket.wav"
#define SND_LASER "rf2/sfx/laser.mp3"
#define SND_MEDISHIELD "weapons/medi_shield_deploy.wav"
#define SND_THUNDER "ambient/halloween/thunder_08.wav"
#define SND_WEAPON_CRIT "rf2/sfx/crit_clean.mp3"
#define SND_BLEED_EXPLOSION "physics/body/body_medium_impact_soft6.wav"
#define SND_SAPPER_PLANT "weapons/sapper_plant.wav"
#define SND_SAPPER_DRAIN "weapons/sapper_timer.wav"
#define SND_SPELL_FIREBALL "misc/halloween/spell_fireball_cast.wav"
#define SND_SPELL_LIGHTNING "misc/halloween/spell_lightning_ball_cast.wav"
#define SND_SPELL_METEOR "misc/halloween/spell_meteor_cast.wav"
#define SND_SPELL_BATS "misc/halloween/spell_bat_cast.wav"
#define SND_SPELL_OVERHEAL "misc/halloween/spell_overheal.wav"
#define SND_SPELL_JUMP "misc/halloween/spell_blast_jump.wav"
#define SND_SPELL_STEALTH "misc/halloween/spell_stealth.wav"
#define SND_SPELL_TELEPORT "misc/halloween/spell_teleport.wav"
#define SND_RUNE_AGILITY "items/powerup_pickup_agility.wav"
#define SND_RUNE_HASTE "items/powerup_pickup_haste.wav"
#define SND_RUNE_KNOCKOUT "items/powerup_pickup_knockout.wav"
#define SND_RUNE_PRECISION "items/powerup_pickup_precision.wav"
#define SND_RUNE_WARLOCK "items/powerup_pickup_reflect.wav"
#define SND_RUNE_REGEN "items/powerup_pickup_regeneration.wav"
#define SND_RUNE_RESIST "items/powerup_pickup_resistance.wav"
#define SND_RUNE_STRENGTH "items/powerup_pickup_strength.wav"
#define SND_RUNE_VAMPIRE "items/powerup_pickup_vampire.wav"
#define SND_RUNE_KING "items/powerup_pickup_king.wav"
#define SND_THROW "weapons/cleaver_throw.wav"
#define SND_TELEPORTER_BLU_START "mvm/mvm_tele_activate.wav"
#define SND_TELEPORTER_BLU "mvm/mvm_tele_deliver.wav"
#define SND_ARTIFACT_ROLL "ui/buttonclick.wav"
#define SND_ARTIFACT_SELECT "items/spawn_item.wav"
#define SND_DOOMSDAY_EXPLODE "misc/doomsday_missile_explosion.wav"
#define SND_ACHIEVEMENT "misc/achievement_earned.wav"
#define SND_DRAGONBORN "rf2/sfx/fus_ro_dah.wav"
#define SND_DRAGONBORN2 "misc/halloween/spell_mirv_explode_secondary.wav"
#define SND_AUTOFIRE_TOGGLE "buttons/button3.wav"
#define SND_AUTOFIRE_SHOOT "weapons/smg1/smg1_fire1.wav"
#define SND_STUN "player/pl_impact_stun.wav"
#define SND_PARACHUTE "items/para_open.wav"
#define SND_1UP "rf2/sfx/1up.wav"
#define SND_HINT "ui/hint.wav"
#define SND_LONGWAVE_USE "ui/cyoa_node_activate.wav"
#define SND_REVIVE "misc/halloween/spell_skeleton_horde_rise.wav"
#define NULL "misc/null.wav"

// Game sounds
#define GSND_CRIT "TFPlayer.CritHit"
#define GSND_MINICRIT "TFPlayer.CritHitMini"
#define GSND_SNIPER_STOCK "Weapon_SniperRifle.Single"
#define GSND_HEATMAKER "Weapon_ProSniperRifle.Single"
#define GSND_CLASSIC "Weapon_ClassicSniperRifle.Single"
#define GSND_SYDNEY "Weapon_SydneySleeper.Single"
#define GSND_BAZAAR "Weapon_Bazaar_Bargain.Single"
#define GSND_MACHINA "Weapon_SniperRailgun.Single"
#define GSND_SHOOTINGSTAR "Weapon_ShootingStar.Single"
#define GSND_AWP "Weapon_AWP.Single"
#define GSND_MVM_POWERUP "MVM.PlayerUsedPowerup"

// TFBots -------------------------------------------------------------------------------------------------------------------------------------
enum
{
	TFBotSkill_Easy,
	TFBotSkill_Normal,
	TFBotSkill_Hard,
	TFBotSkill_Expert,
};

#define TFBOTFLAG_AGGRESSIVE (1 << 0) // Bot should always act aggressive (relentlessly chase target)
#define TFBOTFLAG_ROCKETJUMP (1 << 1) // Bot should rocket jump
#define TFBOTFLAG_STRAFING (1 << 2) // Bot is currently strafing
#define TFBOTFLAG_HOLDFIRE (1 << 3) // Hold fire until fully reloaded
#define TFBOTFLAG_SPAMJUMP (1 << 4) // constantly jump
#define TFBOTFLAG_ALWAYSATTACK (1 << 5) // Always hold IN_ATTACK
#define TFBOTFLAG_SUICIDEBOMBER (1 << 6) // Behave like a Sentry Buster, but go after players instead of sentries


// Weapons -------------------------------------------------------------------------------------------------------------------------------------
#define MAX_STRING_ATTRIBUTES 8
#define TF_WEAPON_SLOTS 10
#define MAX_ATTRIBUTES 20
#define MAX_STATIC_ATTRIBUTES 16
#define MAX_ATTRIBUTE_STRING_LENGTH 512
#define TFObjectMode_Disposable TFObjectMode_Exit

enum
{
	WeaponSlot_Primary,
	WeaponSlot_Secondary,
	WeaponSlot_Melee,
	WeaponSlot_PDA,
	WeaponSlot_PDA2,
	WeaponSlot_Builder,
	WeaponSlot_Action = 9, // Action item, e.g. Spellbook Magazine or Grappling Hook (The rest of the slots are for wearables and taunts)
	
	WeaponSlot_DisguiseKit = WeaponSlot_PDA,
	WeaponSlot_InvisWatch = WeaponSlot_PDA2,
};

enum
{
	TFAmmoType_None = -1,
	TFAmmoType_Primary = 1,
	TFAmmoType_Secondary,
	TFAmmoType_Metal,
	TFAmmoType_Jarate, // aka Grenades1, also used for Sandman/Wrap Assassin and lunchbox items
	TFAmmoType_MadMilk, // aka Grenades2, also used for Cleaver
	TFAmmoType_Grenades3,
};


// Other
enum
{
	VoiceType_Robot,
	VoiceType_Human,
	VoiceType_Silent,
};

enum
{
	FootstepType_Robot,
	FootstepType_GiantRobot,
	FootstepType_Normal,
	FootstepType_Silent,
};