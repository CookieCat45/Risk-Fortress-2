#pragma semicolon 1
#pragma newdecls required

// General -------------------------------------------------------------------------------------------------------------------------------------
#define MAXTF2PLAYERS 36
#define MAX_EDICTS 2048
#define MAX_COOKIE_LENGTH 100
#define MAX_MAP_SIZE 32768.0
#define MAX_DAMAGE 32767.0 // Maximum possible single-instance damage in TF2
#define WAIT_TIME_DEFAULT 120 // Waiting For Players time
#define TF_CLASSES 9+1 // because arrays
#define DMG_MELEE DMG_BLAST_SURFACE
#define WORLD_CENTER "rf2_world_center" // An info_target used to determine where the "center" of the world is, according to the map designer
#define INVALID_ENT INVALID_ENT_REFERENCE
#define MAX_PATH_FOLLOWERS 60

// Configs -------------------------------------------------------------------------------------------------------------------------------------
#define ConfigPath "configs/rf2"
#define ItemConfig "items.cfg"
#define SurvivorConfig "survivors.cfg"
#define WeaponConfig "weapons.cfg"
#define MapConfig "maps.cfg"


// Models/Sprites -------------------------------------------------------------------------------------------------------------------------------------
#define MODEL_ERROR "models/error.mdl"
#define MODEL_INVISIBLE "models/empty.mdl"
#define MODEL_CASH_BOMB "models/props_c17/cashregister01a.mdl"
#define MODEL_MERASMUS "models/bots/merasmus/merasmus.mdl"
#define MODEL_MEDISHIELD "models/props_mvm/mvm_player_shield2.mdl"

#define MAT_DEBUGEMPTY "debug/debugempty.vmt"
#define MAT_BEAM "materials/sprites/laser.vmt"

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
#define SND_CASH "mvm/mvm_bought_upgrade.wav"
#define SND_NOPE "vo/engineer_no01.mp3"
#define SND_MERASMUS_APPEAR "misc/halloween/merasmus_appear.wav"
#define SND_MERASMUS_DISAPPEAR "misc/halloween/merasmus_disappear.wav"
#define SND_MERASMUS_DANCE1 "vo/halloween_merasmus/sf12_wheel_dance03.mp3"
#define SND_MERASMUS_DANCE2 "vo/halloween_merasmus/sf12_wheel_dance04.mp3"
#define SND_MERASMUS_DANCE3 "vo/halloween_merasmus/sf12_wheel_dance05.mp3"
#define SND_BOSS_SPAWN "mvm/mvm_tank_start.wav"
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
#define SND_TELEPORTER_BLU "mvm/mvm_tele_deliver.wav"
#define SND_ARTIFACT_ROLL "ui/buttonclick.wav"
#define SND_ARTIFACT_SELECT "items/spawn_item.wav"
#define SND_DOOMSDAY_EXPLODE "misc/doomsday_missile_explosion.wav"
#define SND_ACHIEVEMENT "misc/achievement_earned.wav"
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

// Players ---------------------------------------------------------------------------------------------------------------------------------------
#define PLAYER_MINS {-24.0, -24.0, 0.0}
#define PLAYER_MAXS {24.0, 24.0, 82.0}


// TFBots -------------------------------------------------------------------------------------------------------------------------------------
enum
{
	TFBotDifficulty_Easy,
	TFBotDifficulty_Normal,
	TFBotDifficulty_Hard,
	TFBotDifficulty_Expert,
};

#define TFBOTFLAG_AGGRESSIVE (1 << 0) // Bot should always act aggressive (relentlessly chase target)
#define TFBOTFLAG_ROCKETJUMP (1 << 1) // Bot should rocket jump
#define TFBOTFLAG_STRAFING (1 << 2) // Bot is currently strafing
#define TFBOTFLAG_HOLDFIRE (1 << 3) // Hold fire until fully reloaded
#define TFBOTFLAG_SPAMJUMP (1 << 4) // Constantly jump around

// Enemies/Bosses -------------------------------------------------------------------------------------------------------------------------------------
#define MAX_ENEMIES 32
#define MAX_WEARABLES 6
#define BOSS_BASE_BACKSTAB_DAMAGE 750.0

enum
{
	StabDamageType_Raw,
	StabDamageType_Percentage,
};

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


// Weapons -------------------------------------------------------------------------------------------------------------------------------------
#define MAX_WEAPONS 256
#define TF_WEAPON_SLOTS 10
#define MAX_ATTRIBUTES 16
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
	TFAmmoType_Jarate,
	TFAmmoType_MadMilk,
	//TFAmmoType_Grenades3,	- Unused
};


// Items -------------------------------------------------------------------------------------------------------------------------------------
#define MAX_ITEMS 90
#define MAX_ITEM_MODIFIERS 12

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


// Objects -------------------------------------------------------------------------------------------------------------------------------------
#define MAX_TELEPORTERS 16
#define MAX_ALTARS 8
#define TELEPORTER_RADIUS 1500.0


// Stages -------------------------------------------------------------------------------------------------------------------------------------
#define MAX_STAGE_MAPS 16
#define MAX_STAGES 32


// Other -----------------------------------------------------------------------------------------------------------------------------------------
#define OFF_THE_MAP 		{-16384.0, -16384.0, -16384.0}
#define FFADE_IN			0x0001		// Just here so we don't pass 0 into the function
#define FFADE_OUT			0x0002		// Fade out (not in)
#define FFADE_MODULATE		0x0004		// Modulate (don't blend)
#define FFADE_STAYOUT		0x0008		// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE			0x0010		// Purges all other fades, replacing them with this one
#define SCREENFADE_FRACBITS	9

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
	
	LAST_SHARED_COLLISION_GROUP
};

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

#define SF_NORESPAWN (1 << 30)
