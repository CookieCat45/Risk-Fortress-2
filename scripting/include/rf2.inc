#if defined _RF2_included
 #endinput
#endif
#define _RF2_included

#define MAXTF2PLAYERS 36
#define TF_CLASSES 10 // one extra because array limits
#define SPEED_LIMIT 1000
#define WAIT_TIME 80 // Waiting For Players time

// Configs
#define ConfigPath "configs/rf2"
#define ItemConfig "items.cfg"
#define SurvivorConfig "survivors.cfg"
#define WeaponConfig "weapons.cfg"
#define RobotConfig "robots.cfg"
#define PackConfig "packs.cfg"
#define MapConfig "maps.cfg"
#define BossConfig "bosses.cfg"

// Models
#define ERROR "models/error.mdl"
#define MODEL_INVISIBLE "models/empty.mdl"
#define MODEL_TELEPORTER "models/rf2_models/objects/teleporter.mdl"
#define MODEL_TELEPORTER_RADIUS "models/rf2_models/objects/teleporter_radius.mdl"
#define MODEL_CRATE "models/props_urban/urban_crate002.mdl"

// Sounds
#define SOUND_ITEM_PICKUP "ui/item_default_pickup.wav"
#define SOUND_GAME_OVER "music/mvm_lost_wave.wav"
#define SOUND_MONEY_PICKUP "mvm/mvm_money_pickup.wav"

#define SOUND_DROP_DEFAULT "ui/itemcrate_smash_rare.wav"
#define SOUND_DROP_UNUSUAL "ui/itemcrate_smash_ultrarare_fireworks.wav"
#define NOPE "vo/engineer_no01.mp3"

#define SOUND_PARTY1 "misc/happy_birthday_tf_04.wav"
#define SOUND_PARTY2 "misc/happy_birthday_tf_11.wav"
#define SOUND_PARTY3 "misc/happy_birthday_tf_13.wav"
#define SOUND_PARTY4 "misc/happy_birthday_tf_14.wav"
#define SOUND_PARTY5 "misc/happy_birthday_tf_15.wav"

#define SOUND_BOSS_SPAWN "mvm/mvm_tank_start.wav"
#define SOUND_SENTRYBUSTER_BOOM "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define SOUND_ROBOT_STUN "mvm/mvm_robo_stun.wav"

#define SOUND_BELL "misc/halloween/strongman_bell_01.wav"

// Particles
#define PARTICLE_NORMAL_CRATE_OPEN "mvm_loot_explosion"
#define PARTICLE_UNUSUAL_CRATE_OPEN "mvm_pow_gold_seq"

#define PARTICLE_CONFETTI "bday_confetti"

// General
#define MAX_CONFIG_NAME_LENGTH 64
#define TF_WEAPON_SLOTS 6
#define MAX_WEAPON_INDEXES 256
#define MAX_ATTRIBUTE_STRING_LENGTH 512

// Objects
#define MAX_OBJECTS 150
#define MAX_TELEPORTERS 16
#define MAX_ALTARS 8
#define BASE_OBJECT_COUNT 10

#define OBJECT_TELEPORTER "rf2_object_teleporter"
#define TELEPORTER_RADIUS 1500.0

#define OBJECT_ALTAR "rf2_object_altar"

#define OBJECT_CRATE "rf2_object_crate"
#define OBJECT_CRATE_LARGE "rf2_object_crate_large"
#define OBJECT_CRATE_STRANGE "rf2_object_crate_strange"
#define CRATE_BASE_COST 50.0
#define CRATE_LARGE_BASE_COST 150.0
#define CRATE_STRANGE_BASE_COST 75.0

enum RF2ObjectState
{
	Obj_None,
	Obj_Active,
	Obj_Used,
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

// Players
#define PLAYER_MINS {-24.0, -24.0, 0.0}
#define PLAYER_MAXS {24.0, 24.0, 82.0}
#define TEAM_SURVIVOR view_as<int>(TFTeam_Red)
#define TEAM_ROBOT view_as<int>(TFTeam_Blue)
#define MAX_SURVIVORS 6

#define LEVEL_HEALTH_INCREASE 0.15
#define LEVEL_DAMAGE_INCREASE 0.1

#define BASE_XP_REQUIREMENT 150.0
#define XP_REQUIREMENT_SCALE 1.5

// "mod see enemy health", "maxammo primary increased", "maxammo secondary increased", "metal regen"
#define BASE_PLAYER_ATTRIBUTES "269 = 1 ; 76 = 10.0 ; 78 = 10.0 ; 113 = 25"
#define ATTRIBUTE_WEARABLE_INDEX 5000 // Scrap Metal

// Robots
#define MAX_ROBOT_TYPES 128
#define MIN_SPAWN_DIST 450.0
#define MAX_SPAWN_DIST 1100.0
#define MIN_RESPAWN_WAVE_TIME 6.0
#define MAX_SPAWN_WAVE_COUNT 8
#define MAX_ROBOT_WEARABLES 6

// Stages
#define MAX_STAGE_MAPS 32
#define MAX_STAGES 32

// Bosses
#define MAX_BOSS_TYPES 32
#define BOSS_BASE_BACKSTAB_DAMAGE 400.0
#define MAX_BOSS_WEARABLES 8

// Items
#define MAX_ITEMS 32
enum RF2ItemType
{
	Item_Null = 0,
	Item_TombReaders = 1,
	Item_FedFedora = 2,
	Item_PrideScarf = 3,
	Item_EyeCatcher = 4,
	Item_MaimLicense = 5,
	Item_RobinWalkers = 6,
	Item_RoundedRifleman = 7,
	Item_PartyHat = 8,
	Item_Executioner = 9,
	Equipment_Stahlhelm = 10,
	Item_Archimedes = 11,
	Item_MaxValid,
};

enum RF2ItemQuality
{
	Quality_None = -1,
	Quality_Normal,
	Quality_Genuine,
	Quality_Unusual,
	Quality_Haunted,
	Quality_Collectors,
	Quality_Strange,
};

// Difficulty
#define	DifficultyFactor_Drizzle 0.7
#define	DifficultyFactor_Rainstorm 1.0
#define	DifficultyFactor_Monsoon 1.5
#define DifficultyFactor_Diluvian 2.0

enum
{
	DIFFICULTY_DRIZZLE,
	DIFFICULTY_RAINSTORM,
	DIFFICULTY_MONSOON,
	DIFFICULTY_DILUVIAN,
};

enum
{
	TFBotDifficulty_Easy,
	TFBotDifficulty_Normal,
	TFBotDifficulty_Hard,
	TFBotDifficulty_Expert,
};

// Sub-difficulties (difficulty that increases with time)
enum
{
	SubDifficulty_Easy,
	SubDifficulty_Normal,
	SubDifficulty_Hard,
	SubDifficulty_VeryHard,
	SubDifficulty_Insane,
	SubDifficulty_Impossible,
	SubDifficulty_ISeeYou,
	SubDifficulty_ComingForYou,
	SubDifficulty_Hahaha,
};

enum
{
	WeaponSlot_Primary,
	WeaponSlot_Secondary,
	WeaponSlot_Melee,
	WeaponSlot_PDA,
	WeaponSlot_PDA2,
	WeaponSlot_Builder,
	
	WeaponSlot_DisguiseKit = WeaponSlot_PDA,
	WeaponSlot_InvisWatch = WeaponSlot_PDA2,
};

/*
 * Is RF2 enabled?
 * @return		True if RF2 is enabled, false otherwise.
 */
native bool RF2_IsRF2Enabled();

/*
 * Checks whether a player is stun immune or not.
 * @param client	Player index.
 * @return			True if player can be stunned, false otherwise.
 */
native bool RF2_CanBeStunned(int client);

/*
 * Checks whether or not a player is a boss.
 * @param client			Player index.
 * @param teleporterBoss	Also check if the player is a teleporter boss (bosses that must be killed to complete the Teleporter event).
 * @return					True if player is a boss, false otherwise.
 */
native bool RF2_IsPlayerBoss(int client, bool teleporterBoss = false);

/*
 * Checks whether or not the Teleporter Event is currently active.
 * @return		True if the Teleporter Event is active, false otherwise.
 */
native bool RF2_IsTeleporterEvent();

/*
 * Get the player's current Survivor index.
 *
 * @param client	Player index,
 * @return			Player's Survivor index. -1 if the player is not a Survivor. 
 */
native int RF2_GetSurvivorIndex(int client);

/*
 * Get the amount of an item that a player has.
 *
 * @param client		Player index.
 * @param itemIdx		Item index.
 * @return			Amount of the item, or -1 if item index is invalid.
 */
native int RF2_GetPlayerItemAmount(int client, RF2ItemType itemIdx);

/*
 * Returns the number of Survivors that were present at the beginning of the stage (meaning killed AND disconnected Survivors still count!).
 * @return			Number of Survivors.
 */
native int RF2_GetSurvivorCount();

/*
 * Gets the Survivor queue points of a player.
 * @param client	Player index.
 * @return			Survivor queue points of player.
 */
native int RF2_GetSurvivorPoints(int client);

/*
 * Sets the Survivor queue points of a player.
 * @param client	Player index.
 * @param points	New points value.
 * @noreturn
 */
native void RF2_SetSurvivorPoints(int client, int points);

/*
 * Gets the current difficulty coefficient value.
 * @return			Difficulty coefficient.
 */
native float RF2_GetDifficultyCoeff();

/*
 * Gets the current sub difficulty value (Easy, Normal, ...)
 * @return			Sub difficulty value.
 */
native int RF2_GetSubDifficulty();

/*
 * Gets the initial difficulty value (Drizzle, Rainstorm, ...)
 * @return			Initial difficulty value.
 */
native int RF2_GetInitialDifficulty();

/*
 * Gets the base max health stat of a player.
 * @param client	Player index.
 * @return			Player base max health stat.
 */
native int RF2_GetBaseMaxHealth(int client);

/*
 * Gets the calculated max health stat of a player.
 * @param client	Player index.
 * @return			Player max health stat.
 */
native int RF2_GetCalculatedMaxHealth(int client);

/*
 * Gets the base speed stat of a player.
 *
 * @param class		Class index.
 * @return			Class base speed.
 */
native float RF2_GetBaseSpeed(int client);

/*
 * Gets the fully calculated speed stat of a player.
 * @param client	Player index.
 * @return			Player speed stat.
 */
native float RF2_GetCalculatedSpeed(int client);

/*
 * Gets the maximum number of stages (the number of stages before a loop occurs).
 * @return			Maximum stage number.
 */
native int RF2_GetMaxStages();

/*
 * Gets the current stage number of a run.
 * @return			Stage number.
 */
native int RF2_GetCurrentStage();

/*
 * Gets the current Teleporter entity.
 * @return			Teleporter entity.
 */
native int RF2_GetTeleporterEntity();

// Prints a message to a client with the [RF2] tag. Uses the same parameters and supports color tags.
stock void RF2_PrintToChat(int client, const char[] message, any ...)
{
	char buffer[PLATFORM_MAX_PATH];
	VFormat(buffer, sizeof(buffer), message, 3);
	CPrintToChat(client, "{lightseagreen}[RF2] {default}%s", buffer);
}

// Prints a message to all clients with the [RF2] tag. Uses the same parameters and supports color tags.
stock void RF2_PrintToChatAll(const char[] message, any ...)
{
	char buffer[PLATFORM_MAX_PATH];
	VFormat(buffer, sizeof(buffer), message, 2);
	CPrintToChatAll("{lightseagreen}[RF2] {default}%s", buffer);
}

// Replies to a command with the [RF2] tag. Uses the same parameters and supports color tags.
stock void RF2_ReplyToCommand(int client, const char[] message, any ...)
{
	char buffer[PLATFORM_MAX_PATH];
	VFormat(buffer, sizeof(buffer), message, 3);
	CReplyToCommand(client, "{lightseagreen}[RF2] {default}%s", buffer);
}

/*
 * Called when the Teleporter event is started.
 * @param client	Client responsible for starting the event.
 * @return			Plugin_Handled to block the event from starting.
 */
forward Action RF2_OnTeleporterEventStart(int client);

/*
 * Called when the round's grace period has ended.
 * @noreturn
 */
forward Action RF2_OnGracePeriodEnd();

#if !defined REQUIRE_PLUGIN
public void __pl_RF2_SetNTVOptional()
{
	MarkNativeAsOptional("RF2_IsRF2Enabled");
	MarkNativeAsOptional("RF2_CanBeStunned");
	MarkNativeAsOptional("RF2_IsPlayerBoss");
	MarkNativeAsOptional("RF2_GetPlayerItemAmount");
	MarkNativeAsOptional("RF2_IsTeleporterEvent");
	
	MarkNativeAsOptional("RF2_GetSurvivorCount");
	MarkNativeAsOptional("RF2_GetSurvivorPoints");
	MarkNativeAsOptional("RF2_SetSurvivorPoints");
	
	MarkNativeAsOptional("RF2_GetDifficultyCoeff");
	MarkNativeAsOptional("RF2_GetSubDifficulty");
	
	MarkNativeAsOptional("RF2_GetBaseMaxHealth");
	MarkNativeAsOptional("RF2_GetCalculatedMaxHealth");
	MarkNativeAsOptional("RF2_GetBaseSpeed");
	MarkNativeAsOptional("RF2_GetCalculatedSpeed");
	
	MarkNativeAsOptional("RF2_GetMaxStages");
	MarkNativeAsOptional("RF2_GetCurrentStage");
}
#endif
