#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf2items>
#include <cbasenpc>
#tryinclude <morecolors>

#pragma semicolon 1
#pragma newdecls required

// General -------------------------------------------------------------------------------------------------------------------------------------
#define MAXTF2PLAYERS 36
#define MAX_EDICTS 2048
#define MAX_TF_CONDITIONS 133
#define TF_CLASSES 9+1
#define WAIT_TIME 100 // Waiting For Players time

#define WORLD_CENTER "rf2_world_center" // An info_target used to determine where the "center" of the world is, according to the map designer
#define MAX_CONFIG_NAME_LENGTH 64
#define MAX_ATTRIBUTE_STRING_LENGTH 512

// Configs -------------------------------------------------------------------------------------------------------------------------------------
#define ConfigPath "configs/rf2"
#define ItemConfig "items.cfg"
#define SurvivorConfig "survivors.cfg"
#define WeaponConfig "weapons.cfg"
#define MapConfig "maps.cfg"

// Models/Sprites -------------------------------------------------------------------------------------------------------------------------------------
#define ERROR "models/error.mdl"
#define MODEL_INVISIBLE "models/empty.mdl"
#define MODEL_TELEPORTER "models/rf2_models/objects/teleporter.mdl"
#define MODEL_TELEPORTER_RADIUS "models/rf2_models/objects/teleporter_radius.mdl"
#define MODEL_CRATE "models/rf2_models/objects/crate.mdl"
#define MODEL_CRATE_STRANGE "models/props_hydro/water_barrel.mdl"
#define MODEL_CRATE_HAUNTED "models/player/items/crafting/halloween2015_case.mdl"
#define MODEL_KEY_HAUNTED "models/crafting/halloween2015_gargoyle_key.mdl"

#define MODEL_MEDISHIELD "models/props_mvm/mvm_player_shield2.mdl"

#define MODEL_BADASS_TANK "models/rf2_models/tank/badass_tank.mdl"

#define DEBUGEMPTY "debug/debugempty.vmt"
#define SPRITE_BEAM "materials/sprites/laser.vmt"

// Sounds -------------------------------------------------------------------------------------------------------------------------------------
#define SOUND_ITEM_PICKUP "ui/item_default_pickup.wav"
#define SOUND_GAME_OVER "music/mvm_lost_wave.wav"
#define SOUND_LASTMAN "mvm/mvm_warning.wav"
#define SOUND_MONEY_PICKUP "mvm/mvm_money_pickup.wav"

#define SOUND_DROP_DEFAULT "ui/itemcrate_smash_rare.wav"
#define SOUND_DROP_HAUNTED "misc/halloween/spell_skeleton_horde_cast.wav"
#define SOUND_DROP_UNUSUAL "ui/itemcrate_smash_ultrarare_fireworks.wav"
#define NOPE "vo/engineer_no01.mp3"

#define SOUND_PARTY1 "misc/happy_birthday_tf_04.wav"
#define SOUND_PARTY2 "misc/happy_birthday_tf_11.wav"
#define SOUND_PARTY3 "misc/happy_birthday_tf_13.wav"
#define SOUND_PARTY4 "misc/happy_birthday_tf_14.wav"
#define SOUND_PARTY5 "misc/happy_birthday_tf_15.wav"

#define SOUND_BOSS_SPAWN "mvm/mvm_tank_start.wav"
#define SOUND_SENTRYBUSTER_BOOM "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define SOUND_ENEMY_STUN "mvm/mvm_robo_stun.wav"

#define SOUND_BELL "misc/halloween/strongman_bell_01.wav"
#define SOUND_SHIELD "weapons/medi_shield_deploy.wav"
#define SOUND_LUCKYSHOT_FIRE "weapons/sentry_rocket.wav"
#define SOUND_LASER "rf2/sfx/laser.mp3"
#define SOUND_MEDISHIELD "weapons/medi_shield_deploy.wav"

#define SOUND_SPELL_FIREBALL "misc/halloween/spell_fireball_cast.wav"
#define SOUND_SPELL_LIGHTNING "misc/halloween/spell_lightning_ball_cast.wav"
#define SOUND_SPELL_METEOR "misc/halloween/spell_meteor_cast.wav"
#define SOUND_SPELL_BATS "misc/halloween/spell_bat_cast.wav"
#define SOUND_SPELL_OVERHEAL "misc/halloween/spell_overheal.wav"
#define SOUND_SPELL_JUMP "misc/halloween/spell_blast_jump.wav"
#define SOUND_SPELL_STEALTH "misc/halloween/spell_stealth.wav"
#define SOUND_SPELL_TELEPORT "misc/halloween/spell_teleport.wav"

// Particles -------------------------------------------------------------------------------------------------------------------------------------
#define PARTICLE_NORMAL_CRATE_OPEN "mvm_loot_explosion"
#define PARTICLE_HAUNTED_CRATE_OPEN "ghost_appearation"
#define PARTICLE_UNUSUAL_CRATE_OPEN "mvm_pow_gold_seq"

// Players ---------------------------------------------------------------------------------------------------------------------------------------
#define PLAYER_MINS {-24.0, -24.0, 0.0}
#define PLAYER_MAXS {24.0, 24.0, 82.0}

// "mod see enemy health", "maxammo primary increased", "maxammo secondary increased", "metal regen"
#define BASE_PLAYER_ATTRIBUTES "269 = 1 ; 76 = 10.0 ; 78 = 10.0 ; 113 = 25"

// "mod see enemy health", "maxammo primary increased", "maxammo secondary increased", 
// "damage force reduction", "airblast vulnerability multiplier", "increased jump height", "cancel falling damage"
#define BASE_BOSS_ATTRIBUTES "269 = 1 ; 76 = 10.0 ; 78 = 10.0 ; 252 = 0.2 ; 329 = 0.2 ; 326 = 1.35 ; 275 = 1"

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

// TFBots -------------------------------------------------------------------------------------------------------------------------------------
enum
{
	TFBotDifficulty_Easy,
	TFBotDifficulty_Normal,
	TFBotDifficulty_Hard,
	TFBotDifficulty_Expert,
};

// Enemies -------------------------------------------------------------------------------------------------------------------------------------
#define MAX_ENEMIES 128
#define MAX_ENEMY_WEARABLES 6

// Bosses -------------------------------------------------------------------------------------------------------------------------------------
#define MAX_BOSSES 32
#define BOSS_BASE_BACKSTAB_DAMAGE 750.0
#define MAX_BOSS_WEARABLES 6

enum
{
	StabDamageType_Raw,
	StabDamageType_Percentage,
};

// Weapons -------------------------------------------------------------------------------------------------------------------------------------
#define MAX_WEAPONS 256
#define MAX_ATTRIBUTES 20

// Weapon slots, according to TF source code
#define TF_WEAPON_SLOTS 10
enum
{
	WeaponSlot_Primary,
	WeaponSlot_Secondary,
	WeaponSlot_Melee,
	WeaponSlot_Utility, // Used for the PASS Time JACK
	WeaponSlot_Builder,
	WeaponSlot_PDA,
	WeaponSlot_PDA2,
	WeaponSlot_Action = 9, // Action item, e.g. Spellbook Magazine or Grappling Hook (The rest of the slots are for wearables and taunts)
	
	WeaponSlot_DisguiseKit = WeaponSlot_PDA,
	WeaponSlot_InvisWatch = WeaponSlot_PDA2,
};

// Ammo types, according to TF source code
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

// Objects
#define MAX_TELEPORTERS 16
#define MAX_ALTARS 8
#define BASE_OBJECT_COUNT 12
#define CRATE_BASE_COST 50.0

// Stages -------------------------------------------------------------------------------------------------------------------------------------
#define MAX_STAGE_MAPS 16
#define MAX_STAGES 32

// Other -----------------------------------------------------------------------------------------------------------------------------------------
#define EF_ITEM_BLINK 0x100

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
	COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player, for
										// TF2, this filters out other players and CBaseObjects
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

#include <rf2>

#define PLUGIN_VERSION "0.1a"
public Plugin myinfo =
{
	name		=	"Risk Fortress 2",
	author		=	"CookieCat",
	description	=	"Endless roguelike TF2 gamemode inspired by hit indie game Risk of Rain 2.",
	version		=	PLUGIN_VERSION,
	url			=	"",
};

// General
bool g_bPluginEnabled;
bool g_bLateLoad;
bool g_bGameStarted;
bool g_bWaitingForPlayers;
bool g_bRoundActive;
bool g_bGracePeriod;
bool g_bGameOver;
bool g_bStageCleared;
bool g_bMapChanging;
bool g_bConVarsModified;
bool g_bPluginReloading;

bool g_bSeedSet;
int g_iSeed;

int g_iMapFog = -1;
int g_iWorldCenterEntity = -1;

// Difficulty
float g_flSecondsPassed;
int g_iMinutesPassed;

float g_flSubDifficultyIncrement = 50.0;
float g_flDifficultyCoeff;
int g_iDifficultyLevel = DIFFICULTY_IRON;
int g_iSubDifficulty = SubDifficulty_Easy;

int g_iStagesCompleted;
int g_iLoopCount;
int g_iEnemyLevel = 1;
int g_iRespawnWavesCompleted;

// HUD
Handle g_hMainHudSync;
int g_iMainHudR = 100;
int g_iMainHudG = 255;
int g_iMainHudB = 100;
char g_szHudDifficulty[128] = "Difficulty: Easy";
char g_szObjectiveHud[MAXTF2PLAYERS][64];

// g_iStagesCompleted+1, g_iMinutesPassed, hudSeconds, g_iEnemyLevel, g_iPlayerLevel[i], g_flPlayerXP[i], 
// g_flPlayerNextLevelXP[i], g_flPlayerCash[i], g_szHudDifficulty, strangeItemName, strangeItemCooldown, g_szObjectiveHud[i]
char g_szSurvivorHudText[1024] = "\n\n\nStage %i | %02d:%02d\nEnemy Level: %i | Your Level: %i\n%.0f/%.0f XP | Cash: $%.0f\n%s\nStrange Item: %s [%.1f]\n%s";

// g_iStagesCompleted+1, g_iMinutesPassed, hudSeconds, g_iEnemyLevel, g_szHudDifficulty
char g_szHudText[512] = "\n\n\nStage %i | %02d:%02d\nEnemy Level: %i\n%s";

// Players
bool g_bPlayerInGame[MAXTF2PLAYERS];

int g_iPlayerLevel[MAXTF2PLAYERS] = {1, ...};
float g_flPlayerXP[MAXTF2PLAYERS];
float g_flPlayerNextLevelXP[MAXTF2PLAYERS] = {150.0, ...};
float g_flPlayerCash[MAXTF2PLAYERS];
int g_iPlayerHauntedKeys[MAXTF2PLAYERS] = {999, ...};

int g_iPlayerStatWearable[MAXTF2PLAYERS] = {-1, ...}; // Wearable entity used to store specific attributes on player

int g_iPlayerBaseHealth[MAXTF2PLAYERS] = {1, ...};
int g_iPlayerCalculatedMaxHealth[MAXTF2PLAYERS] = {1, ...};
float g_flPlayerMaxSpeed[MAXTF2PLAYERS] = { 300.0, ... };
float g_flPlayerCalculatedMaxSpeed[MAXTF2PLAYERS] = {300.0, ...};
float g_flHealthRegenTime[MAXTF2PLAYERS];
bool g_bPlayerInCondition[MAXTF2PLAYERS][MAX_TF_CONDITIONS];

int g_iPlayerSurvivorIndex[MAXTF2PLAYERS] = {-1, ...};
int g_iItemsTaken[MAX_SURVIVORS];
int g_iItemLimit[MAX_SURVIVORS];
int g_iItemDropper[MAX_EDICTS] = {-1, ...};
int g_iItemOwner[MAX_EDICTS] = {-1, ...};
int g_iEntityItemDamageProc[MAX_EDICTS] = {-1, ...};
int g_iItemDamageProc[MAXTF2PLAYERS] = {-1, ...};
bool g_bDroppedItem[MAX_EDICTS];
bool g_bViewingItemMenu[MAXTF2PLAYERS];
float g_flPlayerStrangeItemCooldown[MAXTF2PLAYERS];

int g_iPlayerEnemyType[MAXTF2PLAYERS] = {-1, ...};
int g_iPlayerBossType[MAXTF2PLAYERS] = {-1, ...};
bool g_bIsTeleporterBoss[MAXTF2PLAYERS];
bool g_bGiantFootstepCooldown[MAXTF2PLAYERS];
float g_flGiantFootstepInterval[MAXTF2PLAYERS] = {0.5, ...};

int g_iDamageBuffStacks[MAXTF2PLAYERS];
bool g_bStunnable[MAXTF2PLAYERS] = { true, ... };
bool g_bAttackWasMiniCrit[MAXTF2PLAYERS];

int g_iVoiceType[MAXTF2PLAYERS];
bool g_bVoiceNoPainSounds[MAXTF2PLAYERS];
int g_iVoicePitch[MAXTF2PLAYERS] = {SNDPITCH_NORMAL, ...};
int g_iFootstepType[MAXTF2PLAYERS] = {FootstepType_Normal, ...};

float g_flAFKTime[MAXTF2PLAYERS];
bool g_bIsAFK[MAXTF2PLAYERS];

bool g_bNoDamageOwner[MAX_EDICTS];
float g_flDangeresqueDamageBonus[MAXTF2PLAYERS];

// Tank Destruction
bool g_bTankBossMode;
int g_iTankModelIndex;
int g_iTanksKilledObjective;
int g_iTankKillRequirement;
int g_iTanksSpawned;
float g_flTankGracePeriodTime;

// Variables for tracking stats for post-game results
int g_iTotalEnemiesKilled;
int g_iTotalBossesKilled;
int g_iTotalItemsFound;

// Timers
Handle g_hPlayerTimer = null;
Handle g_hHudTimer = null;
Handle g_hDifficultyTimer = null;

// SDK
Handle g_hSDKEquipWearable;
Handle g_hSDKGetMaxClip1;

// Forwards
Handle f_TeleEventStart;
Handle f_GracePeriodStart;
Handle f_GracePeriodEnded;

// ConVars
ConVar g_cvAlwaysSkipWait;
ConVar g_cvNoMapChange;
ConVar g_cvShowDifficultyCoeff;
ConVar g_cvDontEndGame;
ConVar g_cvEnableAFKManager;
ConVar g_cvAFKManagerKickTime;
ConVar g_cvAFKLimit;
ConVar g_cvAFKKickAdmins;
ConVar g_cvAFKMinHumans;
ConVar g_cvBotsCanBeSurvivor;
ConVar g_cvSubDifficultyIncrement;
ConVar g_cvDifficultyScaleMultiplier;
ConVar g_cvShowObjectSpawns;
ConVar g_cvMaxObjects;
ConVar g_cvForceSeed;
ConVar g_cvShowSeedInConsole;
ConVar g_cvCashBurnTime;
ConVar g_cvSurvivorHealthScale;
ConVar g_cvSurvivorDamageScale;
ConVar g_cvSurvivorBaseXpRequirement;
ConVar g_cvSurvivorXpRequirementScale;
ConVar g_cvEnemyHealthScale;
ConVar g_cvEnemyDamageScale;
ConVar g_cvEnemyMinSpawnDistance;
ConVar g_cvEnemyMaxSpawnDistance;
ConVar g_cvEnemyMaxSpawnWaveCount;
ConVar g_cvEnemyMinSpawnWaveTime;
ConVar g_cvBossStabDamageType;
ConVar g_cvBossStabDamagePercent;
ConVar g_cvBossStabDamageAmount;
ConVar g_cvTeleporterRadiusMultiplier;
ConVar g_cvObjectSpreadDistance;
ConVar g_cvItemShareEnabled;
ConVar g_cvTankBaseHealth;
ConVar g_cvTankHealthScale;
ConVar g_cvTankBaseSpeed;

// Cookies
Handle g_coMusicEnabled;
Handle g_coBecomeSurvivor;
Handle g_coBecomeBoss;
Handle g_coAutomaticItemMenu;
Handle g_coSurvivorPoints;

bool g_bMusicEnabled[MAXTF2PLAYERS] = {true, ...};
bool g_bBecomeSurvivor[MAXTF2PLAYERS] = {true, ...};
bool g_bBecomeBoss[MAXTF2PLAYERS] = {true, ...};
bool g_bAutomaticItemMenu[MAXTF2PLAYERS] = {true, ...};
int g_iSurvivorPoints[MAXTF2PLAYERS];

// TFBots
PathFollower g_TFBotPathFollower[MAXTF2PLAYERS];
bool g_bTFBotForceSwim[MAXTF2PLAYERS];
bool g_bTFBotForceReload[MAXTF2PLAYERS];
bool g_bTFBotForceCrouch[MAXTF2PLAYERS];
bool g_bTFBotAggressive[MAXTF2PLAYERS];
float g_flTFBotMinReloadTime[MAXTF2PLAYERS];

// Includes
#include "rf2/items.sp"
#include "rf2/survivors.sp"
#include "rf2/objects.sp"
#include "rf2/cookies.sp"
#include "rf2/bosses.sp"
#include "rf2/enemies.sp"
#include "rf2/stages.sp"
#include "rf2/weapons.sp"
#include "rf2/functions.sp"
#include "rf2/functions_clients.sp"
#include "rf2/natives_forwards.sp"
#include "rf2/commands_convars.sp"
#include "rf2/npc/tf_bot.sp"
#include "rf2/npc/npc_tank_boss.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		FormatEx(error, err_max, "This plugin was developed for Team Fortress 2 only");
		return APLRes_Failure;
	}
	
	LoadNatives();
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadGameData();
	LoadForwards();
	LoadCommandsAndCvars();
	BakeCookies();
	
	LoadTranslations("common.phrases");
	
	g_hMainHudSync = CreateHudSynchronizer();
	AddNormalSoundHook(PlayerSoundHook);
}

public void OnPluginEnd()
{
	if (g_bPluginEnabled)
		StopMusicTrackAll();
}

void LoadGameData()
{
	GameData gamedata = LoadGameConfigFile("rf2");
	if (!gamedata)
		SetFailState("[SDK] Failed to locate gamedata file \"rf2.txt\"");
	
	// CBasePlayer::EquipWearable ---------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	
	g_hSDKEquipWearable = EndPrepSDKCall();
	if(!g_hSDKEquipWearable)
		SetFailState("[SDK] Failed to create call for CBasePlayer::EquipWearable"); // We need this pretty badly, so SetFailState.
	
	// CTFWeaponBase::GetMaxClip1 ---------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFWeaponBase::GetMaxClip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	g_hSDKGetMaxClip1 = EndPrepSDKCall();
	if (!g_hSDKGetMaxClip1)
		LogError("[SDK] Failed to create call for CTFWeaponBase::GetMaxClip1");
	
	delete gamedata;
}

public void OnMapStart()
{
	if (g_bPluginReloading)
	{
		// Prevents OnMapStart() from firing twice when reloading. Doesn't really matter but I just find it annoying.
		CreateTimer(0.1, Timer_ReloadPlugin, _, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	
	g_bMapChanging = false;
	
	char mapName[256];
	char buffer[8];
	GetCurrentMap(mapName, sizeof(mapName));
	SplitString(mapName, "_", buffer, sizeof(buffer));
	
	if (strcmp(buffer, "rf2", false) == 0)
	{
		g_bPluginEnabled = true;
		if (GameRules_GetProp("m_bInWaitingForPlayers"))
			g_bWaitingForPlayers = true;
		
		if (!TheNavMesh.IsLoaded())
		{
			SetFailState("[NAV] The NavMesh for map \"%s\" does not exist!", mapName);
		}
		
		LoadAssets();
		AutoExecConfig(true, "rf2");
		
		// These are ConVars we're OK with being set by server.cfg, but we'll set our personal defaults.
		// If configs wish to change these, they will be overridden by them.
		SetConVarInt(FindConVar("sv_alltalk"), 1);
		SetConVarInt(FindConVar("tf_use_fixed_weaponspreads"), 1);
		SetConVarInt(FindConVar("tf_avoidteammates_pushaway"), 0);
		
		// Round events
		HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Pre);
		HookEvent("teamplay_round_win", Event_RoundEnd, EventHookMode_Post);
		
		// Player events
		HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
		HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
		HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
		
		// Command listeners
		AddCommandListener(OnCallForMedic, "voicemenu");
		AddCommandListener(OnChangeClass, "joinclass");
		AddCommandListener(OnChangeTeam, "autoteam");
		AddCommandListener(OnChangeTeam, "jointeam");
		AddCommandListener(OnChangeTeam, "spectate");
		AddCommandListener(OnSuicide, "kill");
		AddCommandListener(OnSuicide, "explode");
		AddCommandListener(OnChangeSpec, "spec_next");
		AddCommandListener(OnChangeSpec, "spec_prev");
		
		LoadMapSettings(mapName);
		LoadItems();
		LoadWeapons();
		LoadSurvivorStats();
		g_iMaxStages = GetMaxStages();
		g_iMapFog = FindEntityByClassname(-1, "env_fog_controller");
		
		if (!g_bSeedSet)
		{
			int forcedSeed;
			if ((forcedSeed = GetConVarInt(g_cvForceSeed)) > -1)
			{
				g_iSeed = forcedSeed;
				SetConVarInt(g_cvForceSeed, -1);
			}
			else
			{
				g_iSeed = GetRandomInt(0, 2147483647);
			}
			
			if (GetConVarBool(g_cvShowSeedInConsole))
			{
				PrintToConsoleAll("[RF2] Seed for this game: %i", g_iSeed);
			}
			
			g_bSeedSet = true;
		}
		
		CreateTimer(1.0, Timer_AFKManager, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(60.0, Timer_PluginMessage, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		if (g_bLateLoad)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientConnected(i))
				{
					OnClientCookiesCached(i);
				}
				
				if (IsClientInGame(i))
				{
					OnClientPutInServer(i);
				}
			}
		}
	}
	else
	{
		g_bPluginEnabled = false;
		PrintToServer("The current map (%s) isn't an RF2-compatible map. RF2 will be disabled.", mapName);
	}
}

void LoadAssets()
{
	// Models
	PrecacheModel(ERROR);
	PrecacheModel(MODEL_INVISIBLE);
	PrecacheModel(MODEL_TELEPORTER);
	PrecacheModel(MODEL_TELEPORTER_RADIUS);
	PrecacheModel(MODEL_CRATE);
	PrecacheModel(MODEL_CRATE_STRANGE);
	PrecacheModel(MODEL_KEY_HAUNTED);
	PrecacheModel(MODEL_CRATE_HAUNTED);
	
	g_iTankModelIndex = PrecacheModel(MODEL_BADASS_TANK);
	AddModelToDownloadsTable(MODEL_BADASS_TANK);
	AddModelToDownloadsTable(MODEL_TELEPORTER);
	AddModelToDownloadsTable(MODEL_TELEPORTER_RADIUS);
	
	// Sounds
	PrecacheSound(SOUND_ITEM_PICKUP);
	PrecacheSound(SOUND_GAME_OVER);
	PrecacheSound(SOUND_LASTMAN);
	PrecacheSound(SOUND_MONEY_PICKUP);
	
	PrecacheSound(SOUND_DROP_DEFAULT);
	PrecacheSound(SOUND_DROP_HAUNTED);
	PrecacheSound(SOUND_DROP_UNUSUAL);
	PrecacheSound(NOPE);
	
	PrecacheSound(SOUND_BOSS_SPAWN);
	PrecacheSound(SOUND_SENTRYBUSTER_BOOM);
	PrecacheSound(SOUND_ENEMY_STUN);
	
	PrecacheSound(SOUND_BELL);
	PrecacheSound(SOUND_SHIELD);
	PrecacheSound(SOUND_LUCKYSHOT_FIRE);
	PrecacheSound(SOUND_LASER);
	
	PrecacheSound(SOUND_SPELL_FIREBALL);
	PrecacheSound(SOUND_SPELL_TELEPORT);
	PrecacheSound(SOUND_SPELL_BATS);
	PrecacheSound(SOUND_SPELL_LIGHTNING);
	PrecacheSound(SOUND_SPELL_METEOR);
	PrecacheSound(SOUND_SPELL_OVERHEAL);
	PrecacheSound(SOUND_SPELL_JUMP);
	PrecacheSound(SOUND_SPELL_STEALTH);
	g_iBeamModel = PrecacheModel(SPRITE_BEAM);
	
	AddSoundToDownloadsTable(SOUND_LASER);
}

public Action Timer_ReloadPlugin(Handle timer)
{
	InsertServerCommand("sm plugins reload rf2");
	return Plugin_Continue;
}

public void OnConfigsExecuted()
{
	if (g_bPluginEnabled)
	{
		ConVar SpeedLimit = FindConVar("sm_tf2_maxspeed");
		if (SpeedLimit)
		{
			LogMessage("Speed Limit: %.0f. Change by setting sm_tf2_maxspeed in server.cfg", GetConVarFloat(SpeedLimit));
		}
		else
		{
			LogMessage("TF2 Move Speed Unlocker plugin not found. It is not required, but is recommended to install.");
		}
		
		// Why is this a dev-only convar? :/
		ConVar WaitTime = FindConVar("mp_waitingforplayers_time");
		SetConVarFlags(WaitTime, GetConVarFlags(WaitTime) & ~FCVAR_DEVELOPMENTONLY);
		SetConVarInt(WaitTime, WAIT_TIME);
		
		// Here are ConVars we don't want changed by configs.
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
		SetConVarInt(FindConVar("mp_forcecamera"), 0);
		SetConVarInt(FindConVar("mp_maxrounds"), 9999);
		SetConVarInt(FindConVar("mp_forceautoteam"), 1);
		SetConVarFloat(FindConVar("mp_respawnwavetime"), 99999.0);
		SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), 0);
		SetConVarInt(FindConVar("tf_weapon_criticals"), 0);
		SetConVarInt(FindConVar("tf_forced_holiday"), 2);
		
		// TFBots
		SetConVarInt(FindConVar("tf_bot_defense_must_defend_time"), -1);
		SetConVarInt(FindConVar("tf_bot_offense_must_push_time"), -1);
		SetConVarInt(FindConVar("tf_bot_taunt_victim_chance"), 0);
		SetConVarString(FindConVar("tf_bot_quota_mode"), "fill");
		SetConVarInt(FindConVar("tf_bot_quota"), GetMaxHumanPlayers()-1);
		SetConVarInt(FindConVar("tf_bot_join_after_player"), 1);
		
		ConVar botConsiderClass = FindConVar("tf_bot_reevaluate_class_in_spawnroom");
		SetConVarFlags(botConsiderClass, GetConVarFlags(botConsiderClass) & ~FCVAR_CHEAT);
		SetConVarInt(botConsiderClass, 0);
		
		char team[8];
		switch (TEAM_ENEMY)
		{
			case view_as<int>(TFTeam_Blue):	team = "blue";
			case view_as<int>(TFTeam_Red):	team = "red";
		}
		SetConVarString(FindConVar("mp_humans_must_join_team"), team);
		
		g_flSubDifficultyIncrement = GetConVarFloat(g_cvSubDifficultyIncrement);
		g_bConVarsModified = true;
	}
}

public void OnMapEnd()
{
	// Reset our ConVars if we've changed them
	if (g_bConVarsModified)
	{
		ConVar WaitTime = FindConVar("mp_waitingforplayers_time");
		SetConVarFlags(WaitTime, GetConVarFlags(WaitTime) & ~FCVAR_DEVELOPMENTONLY);
		ResetConVar(WaitTime);
		
		ResetConVar(FindConVar("sv_alltalk"));
		ResetConVar(FindConVar("tf_use_fixed_weaponspreads"));
		ResetConVar(FindConVar("tf_avoidteammates_pushaway"));
		
		ResetConVar(FindConVar("mp_teams_unbalance_limit"));
		ResetConVar(FindConVar("mp_forcecamera"));
		ResetConVar(FindConVar("mp_maxrounds"));
		ResetConVar(FindConVar("mp_forceautoteam"));
		ResetConVar(FindConVar("mp_respawnwavetime"));
		ResetConVar(FindConVar("tf_dropped_weapon_lifetime"));
		ResetConVar(FindConVar("tf_weapon_criticals"));
		
		ResetConVar(FindConVar("tf_bot_defense_must_defend_time"));
		ResetConVar(FindConVar("tf_bot_offense_must_push_time"));
		ResetConVar(FindConVar("tf_bot_taunt_victim_chance"));
		ResetConVar(FindConVar("tf_bot_quota_mode"));
		ResetConVar(FindConVar("tf_bot_quota"));
		ResetConVar(FindConVar("tf_bot_join_after_player"));
		
		ConVar botConsiderClass = FindConVar("tf_bot_reevaluate_class_in_spawnroom");
		SetConVarFlags(botConsiderClass, GetConVarFlags(botConsiderClass) & ~FCVAR_CHEAT);
		ResetConVar(botConsiderClass);
		
		ResetConVar(FindConVar("mp_humans_must_join_team"));
		
		g_bConVarsModified = false;
	}
	
	g_bMapChanging = true;
	
	if (g_bPluginEnabled)
	{
		if (g_bGameOver)
		{
			ReloadPlugin(false);
			return;
		}
		else if (g_bStageCleared)
		{
			g_iStagesCompleted++;
		}
		
		CleanUp();
	}
}

void CleanUp()
{
	UnhookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Pre);
	UnhookEvent("teamplay_round_win", Event_RoundEnd, EventHookMode_Post);
	
	UnhookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	UnhookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	
	RemoveCommandListener(OnCallForMedic, "voicemenu");
	RemoveCommandListener(OnChangeClass, "joinclass");
	RemoveCommandListener(OnChangeTeam, "jointeam");
	RemoveCommandListener(OnChangeTeam, "autoteam");
	RemoveCommandListener(OnChangeTeam, "spectate");
	RemoveCommandListener(OnSuicide, "kill");
	RemoveCommandListener(OnSuicide, "explode");
	RemoveCommandListener(OnChangeSpec, "spec_next");
	RemoveCommandListener(OnChangeSpec, "spec_prev");
	
	g_bRoundActive = false;
	g_bGracePeriod = false;
	g_bStageCleared = false;
	g_bWaitingForPlayers = false;
	
	g_hPlayerTimer = null;
	g_hHudTimer = null;
	g_hDifficultyTimer = null;
	g_iRespawnWavesCompleted = 0;
	
	g_iEnemyCount = 0;
	g_iBossAmount = 0;
	g_iItemCount = 0;
	
	g_szPackName = "";
	
	g_iTeleporter = -1;
	g_iTeleporterActivator = -1;
	g_bTeleporterEventCompleted = false;
	
	g_iMapFog = -1;
	g_iWorldCenterEntity = -1;
	
	g_bTankBossMode = false;
	g_iTanksKilledObjective = 0;
	g_iTankKillRequirement = 0;
	g_iTanksSpawned = 0;
	
	StopMusicTrackAll();
	
	for (int i = 1; i < MAXTF2PLAYERS; i++)
	{
		if (IsPlayerSurvivor(i))
		{
			SaveSurvivorInventory(i, g_iPlayerSurvivorIndex[i]);
		}
		
		RefreshClient(i);
		ResetAFKTime(i);
		
		if (g_TFBotPathFollower[i])
		{
			g_TFBotPathFollower[i].Destroy();
			g_TFBotPathFollower[i] = view_as<PathFollower>(Address_Null);
		}
	}
}

public void OnClientPutInServer(int client)
{
	g_bPlayerInGame[client] = true;
	if (g_bPluginEnabled)
	{
		SDKHook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamageAlive);
		SDKHook(client, SDKHook_WeaponSwitch, Hook_WeaponSwitch);
	}
}

public void OnClientDisconnect(int client)
{
	if (!g_bPluginEnabled)
		return;
	
	SaveClientCookies(client);
	StopMusicTrack(client); // To reset the timer

	if (!g_bWaitingForPlayers && !g_bGameOver && g_bGameStarted && !g_bMapChanging && !IsFakeClient(client))
	{
		int count;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (i == client || !IsClientConnected(i) || IsFakeClient(i))
				continue;
			
			count++;
		}
		
		if (count == 0) // Everybody left. Time to start over!
		{
			PrintToServer("[RF2] All human players have disconnected from the server. Restarting the game...");
			ReloadPlugin(true);
			return;
		}
	}
	
	// We need to deal with survivors who disconnect during the grace period.
	if (g_bGracePeriod && IsPlayerSurvivor(client))
	{
		SaveSurvivorInventory(client, g_iPlayerSurvivorIndex[client]);
		
		// Find the best candidate to replace this guy with.
		bool allowBots = GetConVarBool(g_cvBotsCanBeSurvivor);
		int points[MAXTF2PLAYERS];
		int playerPoints[MAXTF2PLAYERS];
		bool valid[MAXTF2PLAYERS];
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (i == client || !g_bPlayerInGame[i] || IsPlayerSurvivor(i))
				continue;
			
			// If we are allowing bots, they lose points in favor of players.
			if (IsFakeClient(i))
			{
				if (!allowBots)
					continue;
					
				points[i] -= 2500;
			}
			
			if (IsPlayerAFK(i))
				points[i] -= 99999;
				
			if (!g_bBecomeSurvivor[i])
				points[i] -= 9999;
			
			// Dead players and non-bosses have higher priority.
			if (!IsPlayerAlive(i))
				points[i] += 5000;
			else if (GetClientTeam(i) == TEAM_ENEMY && GetBossType(i) < 0)
				points[i] += 500;
			
			points[i] += GetRandomInt(1, 150);
			playerPoints[i] = points[i];		
			valid[i] = true;
		}
		
		SortIntegers(points, sizeof(points), Sort_Descending);
		int highestPoints = points[0];
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!valid[i])
				continue;
			
			// We've found our winner
			if (playerPoints[i] == highestPoints)
			{
				// Lucky you - your points won't be getting reset.
				CreateSurvivor(i, g_iPlayerSurvivorIndex[client], false);
				
				float pos[3];
				float angles[3];
				GetClientAbsOrigin(client, pos);
				GetClientEyeAngles(client, angles);
				TeleportEntity(i, pos, angles, NULL_VECTOR);
				
				RF2_PrintToChat(i, "You've been chosen as a Survivor because %N disconnected. Enjoy!", client);
				break;
			}
		}
	}
	
	// If the map is changing, we don't want to refresh our client yet so we can save Survivor inventories.
	// All clients are temporarily disconnected from the server on map change.
	if (!g_bMapChanging)
		RefreshClient(client);
}

public void OnClientDisconnect_Post(int client)
{
	g_bPlayerInGame[client] = false;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnabled || g_bWaitingForPlayers)
		return Plugin_Continue;
	
	if (!SetSurvivors())
	{
		PrintToServer("[RF2] No Survivors were spawned! Restarting the game...");
		ReloadPlugin(true);
		return Plugin_Continue;
	}
	
	if (!g_bGameStarted)
	{
		CreateTimer(2.0, Timer_DifficultyVote, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	g_bGameStarted = true;
	CreateTimer(0.5, Timer_KillAllEnemies, _, TIMER_FLAG_NO_MAPCHANGE);
	
	if (g_bTankBossMode)
	{
		TankDestructionMode_BeginGracePeriod();
	}
	
	SpawnObjects();
	
	if (g_hPlayerTimer != null)
		delete g_hPlayerTimer;
	if (g_hHudTimer != null)
		delete g_hHudTimer;
	if (g_hDifficultyTimer != null)
		delete g_hDifficultyTimer;
	
	g_hPlayerTimer = CreateTimer(0.1, Timer_PlayerTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	g_hHudTimer = CreateTimer(0.1, Timer_PlayerHud, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	g_hDifficultyTimer = CreateTimer(1.0, Timer_Difficulty, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	StopMusicTrackAll();
	
	CreateTimer(0.1, Timer_PlayMusicDelay, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(g_flGracePeriodTime, Timer_EndGracePeriod, _, TIMER_FLAG_NO_MAPCHANGE);
	
	g_bRoundActive = true;
	g_bGracePeriod = true;
	Call_StartForward(f_GracePeriodStart);
	Call_Finish();
	
	CreateTimer(3.0, Timer_DeleteFuncRespawnroom, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action Timer_DifficultyVote(Handle timer)
{
	if (!IsVoteInProgress())
	{
		StartDifficultyVote();
	}
	else // Try again in a bit
	{
		CreateTimer(5.0, Timer_DifficultyVote, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

void StartDifficultyVote()
{
	Handle menu = CreateMenu(Menu_DifficultyVote);
	SetMenuTitle(menu, "Vote for the game's difficulty level!");
	AddMenuItem(menu, "0", "Scrap");
	AddMenuItem(menu, "1", "Iron");
	AddMenuItem(menu, "2", "Steel");
	VoteMenuToAll(menu, 30);
}

public int Menu_DifficultyVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_VoteEnd:
		{
			char info[8];
			GetMenuItem(menu, param1, info, sizeof(info));
			g_iDifficultyLevel = StringToInt(info);
			
			char difficultyName[64];
			GetDifficultyName(g_iDifficultyLevel, difficultyName, sizeof(difficultyName));
			RF2_PrintToChatAll("The difficulty has been set to %s{default}.", difficultyName);
		}
		case MenuAction_VoteCancel:
		{
			if (!g_bPluginReloading) // Causes an error when the plugin is reloading for some reason. I dunno why.
			{
				g_iDifficultyLevel = GetRandomInt(DIFFICULTY_SCRAP, DIFFICULTY_STEEL);
				char difficultyName[64];
				GetDifficultyName(g_iDifficultyLevel, difficultyName, sizeof(difficultyName));
				RF2_PrintToChatAll("The difficulty has been set to %s{default}.", difficultyName);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public Action Timer_DeleteFuncRespawnroom(Handle timer)
{
	// Bots will not follow players into respawn rooms, engineers can't build in them, and players can respawn themselves in them. Many reasons for this.
	// The timer is to allow TF2 to compute incursion distances between the spawnrooms for bots before they're deleted. 3 seconds seems to be enough time.
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "func_respawnroom")) != -1)
	{
		RemoveEntity(entity);
	}
	
	return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnabled || GetConVarInt(g_cvNoMapChange) != 0)
		return Plugin_Continue;
		
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_bPlayerInGame[i] && !IsPlayerSurvivor(i) && !IsFakeClient(i))
		{
			g_iSurvivorPoints[i] += 10;
			RF2_PrintToChat(i, "You gained {lime}10 {default}Survivor Points from this round.");
		}
	}
	
	int winningTeam = event.GetInt("team");
	if (winningTeam == TEAM_SURVIVOR)
	{
		int nextStage = GetCurrentStage();
		if (nextStage >= g_iMaxStages-1)
		{
			g_iLoopCount++;
			nextStage = 0;
		}
		else
		{
			nextStage++;
		}
		
		g_bStageCleared = true;
		CreateTimer(14.0, Timer_SetNextStage, nextStage, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (winningTeam == TEAM_ENEMY)
	{
		g_bGameOver = true;
		CreateTimer(14.0, Timer_GameOver, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	g_bRoundActive = false;
	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnabled || !g_bRoundActive)
		return Plugin_Continue;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = GetClientTeam(client);
	
	// Bots should never join red team outside of waiting for players.
	if (IsFakeClient(client))
	{
		TFBot_Spawn(client);
		
		if (team == TEAM_SURVIVOR && !GetConVarBool(g_cvBotsCanBeSurvivor))
		{
			SilentKillPlayer(client);
			ChangeClientTeam(client, TEAM_ENEMY);
		}
	}

	// Enemies should never spawn during the grace period, if it somehow happens.
	if (g_bGracePeriod && team == TEAM_ENEMY)
	{
		TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
		SDKHooks_TakeDamage(client, 0, 0, 9999999.0, DMG_PREVENT_PHYSICS_FORCE);
		ForcePlayerSuicide(client);
	}
	
	if (team == TEAM_SURVIVOR)
	{
		if (!IsPlayerSurvivor(client))
		{
			SilentKillPlayer(client);
			ChangeClientTeam(client, TEAM_ENEMY);
		}
		else if (g_bAutomaticItemMenu[client])
		{
			ShowItemMenu(client);
		}
	}
	
	CreateAttributeWearable(client);
	RequestFrame(RF_CalculateStats, client);
	TF2_AddCondition(client, TFCond_UberchargedHidden, 0.2);
	return Plugin_Continue;
}

void CreateAttributeWearable(int client)
{
	// Only create our wearable if it doesn't exist already
	if (g_iPlayerStatWearable[client] == -1 || !IsValidEntity(g_iPlayerStatWearable[client]))
	{
		const int wearableIndex = 5000;
		char attributes[MAX_ATTRIBUTE_STRING_LENGTH];
		
		if (GetBossType(client) >= 0)
		{
			attributes = BASE_BOSS_ATTRIBUTES;
		}
		else
		{
			attributes = BASE_PLAYER_ATTRIBUTES;
		}
		
		g_iPlayerStatWearable[client] = CreateWearable(client, "tf_wearable", wearableIndex, attributes, false, TF2Quality_Valve, 69);
	}
}

public void RF_CalculateStats(int client)
{
	if (!g_bPlayerInGame[client])
		return;
	
	CalculatePlayerMaxHealth(client, false, true);
	CalculatePlayerMaxSpeed(client);

	return;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnabled || g_bWaitingForPlayers || !g_bRoundActive)
		return Plugin_Continue;
		
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victimTeam = GetClientTeam(victim);
	
	Action action = Plugin_Continue;
	
	if (victimTeam == TEAM_ENEMY)
	{
		if (!g_bGracePeriod)
		{
			float origin[3];
			GetClientAbsOrigin(victim, origin);
			
			float cashAmount;
			int size;
			
			if (GetEnemyType(victim) != -1)
			{
				g_iTotalEnemiesKilled++;
				cashAmount = g_flEnemyCashAward[g_iPlayerEnemyType[victim]];
			}
			else if (GetBossType(victim) >= 0)
			{
				cashAmount = g_flBossCashAward[g_iPlayerBossType[victim]];
				g_iTotalBossesKilled++;
				size = 3;
				
				EmitSoundToAll(SOUND_SENTRYBUSTER_BOOM, victim);
				EmitSoundToAll(SOUND_SENTRYBUSTER_BOOM, victim);
				EmitSoundToAll(SOUND_SENTRYBUSTER_BOOM, victim);
				EmitSoundToAll(SOUND_SENTRYBUSTER_BOOM, victim);
				
				TE_SetupParticle("fireSmokeExplosion", origin);
				RequestFrame(RF_DeleteRagdoll, victim);
			}
			
			if (attacker > 0 && PlayerHasItem(attacker, Item_BanditsBoots))
			{
				cashAmount *= 1.0 + CalculateItemModifier(attacker, Item_BanditsBoots);
			}
			
			SpawnCashDrop(cashAmount, origin, size);
		}
		else // If the grace period is active, die silently.
		{
			RequestFrame(RF_DeleteRagdoll, victim);
			action = Plugin_Stop;
		}
		
		if (attacker > 0)
		{
			if (victimTeam == TEAM_ENEMY && IsPlayerSurvivor(attacker))
			{
				float xp;
				
				if (GetEnemyType(victim) >= 0)
					xp = g_flEnemyXPAward[g_iPlayerEnemyType[victim]];
				else if (GetBossType(victim) >= 0)
					xp = g_flBossXPAward[g_iPlayerBossType[victim]];
				
				for (int i = 1; i <= MaxClients; i++)
				{
					if (!g_bPlayerInGame[i])
						continue;
						
					if (IsPlayerSurvivor(i))
						UpdatePlayerXP(i, xp);
				}
			}
		}
	}
	else if (victimTeam == TEAM_SURVIVOR)
	{
		if (!g_bGracePeriod)
		{
			SaveSurvivorInventory(victim, GetSurvivorIndex(victim));
			PrintDeathMessage(victim);
			
			int fog = CreateEntityByName("env_fog_controller");
			DispatchKeyValue(fog, "spawnflags", "1");
			DispatchKeyValue(fog, "fogenabled", "1");
			DispatchKeyValue(fog, "fogstart", "50.0");
			DispatchKeyValue(fog, "fogend", "100.0");
			DispatchKeyValue(fog, "fogmaxdensity", "0.9");
			DispatchKeyValue(fog, "fogcolor", "255 0 0");
			
			DispatchSpawn(fog);				
			AcceptEntityInput(fog, "TurnOn");				
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!g_bPlayerInGame[i])
					continue;
				
				SetEntPropEnt(i, Prop_Data, "m_hCtrl", fog);
			}
			
			CreateTimer(0.1, Timer_KillFog, EntIndexToEntRef(fog), TIMER_FLAG_NO_MAPCHANGE);
			
			// Change the victim's team on a timer to avoid some strange behavior.
			CreateTimer(0.3, Timer_ChangeTeamOnDeath, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
			
			int alive = 0;
			int lastMan;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!g_bPlayerInGame[i] || i == victim)
					continue;
					
				if (IsPlayerAlive(i) && IsPlayerSurvivor(i))
				{
					alive++;
					lastMan = i;
				}
			}
			
			if (alive == 0 && GetConVarInt(g_cvDontEndGame) == 0) // Game over, man!
			{
				GameOver();
			}
			else if (alive == 1)
			{
				PrintHintText(lastMan, "You're the last one. Good luck...");
				EmitSoundToClient(lastMan, SOUND_LASTMAN);
				
				if (GetRandomInt(1, 3) == 1)
				{
					SetVariantString("randomnum:100");
					AcceptEntityInput(lastMan, "AddContext");
					
					SetVariantString("IsMvMDefender:1");
					AcceptEntityInput(lastMan, "AddContext");
					
					SetVariantString("TLK_MVM_LAST_MAN_STANDING");
					AcceptEntityInput(lastMan, "SpeakResponseConcept");
					AcceptEntityInput(lastMan, "ClearContext");
				}
			}
		}
		else
		{
			// Respawning players right inside of player_death causes strange behaviour as well.
			CreateTimer(0.1, Timer_RespawnSurvivor, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	RefreshClient(victim);
	return action;
}

public Action Timer_KillFog(Handle timer, int fog)
{
	if (EntRefToEntIndex(fog) == INVALID_ENT_REFERENCE)
		return Plugin_Continue;
	
	AcceptEntityInput(fog, "TurnOff");
	RemoveEntity(fog);
	
	if (IsValidEntity(g_iMapFog))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!g_bPlayerInGame[i])
				continue;
				
			SetEntPropEnt(i, Prop_Data, "m_hCtrl", g_iMapFog);
		}
	}
	
	return Plugin_Continue;
}

public void RF_DeleteRagdoll(int client)
{
	if (g_bPlayerInGame[client])
	{
		char classname[16];
		int entCount = GetEntityCount();
		for (int i = MaxClients+1; i <= entCount; i++)
		{
			if (!IsValidEntity(i))
				continue;

			GetEntityClassname(i, classname, sizeof(classname));
			if (strcmp(classname, "tf_ragdoll") == 0)
			{
				if (GetEntProp(i, Prop_Send, "m_iPlayerIndex") == client)
				{
					RemoveEntity(i);
					break;
				}
			}
		}
	}
}

public void RF_ResetPlayerName(DataPack pack)
{
	pack.Reset();
	
	int client = GetClientOfUserId(pack.ReadCell());
	if (client == 0)
	{
		delete pack;
		return;
	}
		
	char name[MAX_NAME_LENGTH];
	pack.ReadString(name, sizeof(name));
	delete pack;
	
	SetClientName(client, name);
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	g_bAttackWasMiniCrit[attacker] = event.GetBool("minicrit");
	return Plugin_Continue;
}

public Action Timer_KillAllEnemies(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!g_bPlayerInGame[i] || IsPlayerSurvivor(i))
			continue;
		
		SDKHooks_TakeDamage(i, 0, 0, 9999999.0, DMG_PREVENT_PHYSICS_FORCE);
		ForcePlayerSuicide(i);
	}
	
	return Plugin_Continue;
}

public Action Timer_RespawnSurvivor(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || !IsPlayerSurvivor(client))
	{
		return Plugin_Continue;
	}
	
	CreateSurvivor(client, GetSurvivorIndex(client));
	return Plugin_Continue;
}

public Action Timer_ChangeTeamOnDeath(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
		
	ChangeClientTeam(client, TEAM_ENEMY);
	return Plugin_Continue;
}

public Action Timer_EndGracePeriod(Handle timer)
{
	if (!g_bGracePeriod) // grace period was probably ended early by /rf2_skipgrace (which still calls this timer function)
		return Plugin_Continue;
	
	g_bGracePeriod = false;
	
	CreateTimer(5.0, Timer_RespawnWave, _, TIMER_FLAG_NO_MAPCHANGE);
	
	Call_StartForward(f_GracePeriodEnded);
	Call_Finish();
	
	RF2_PrintToChatAll("Grace period has ended. Death on RED will result in joining BLU.");
	return Plugin_Continue;
}

int g_iEnemySpawnType[MAXTF2PLAYERS] = {-1, ...};
int g_iBossSpawnType[MAXTF2PLAYERS] = {-1, ...};
public Action Timer_RespawnWave(Handle timer)
{
	if (!g_bPluginEnabled || !g_bRoundActive || g_bTeleporterEventCompleted)
		return Plugin_Continue;
	
	// Start the timer again first so any errors that may or may not happen don't abort our entire spawning system.
	float duration = (25.0 - 1.5 * (g_iSurvivorCount - 1)) - (float(g_iEnemyLevel-1) * 0.5);
	if (g_bTeleporterEvent)
	{
		float multiplier = (0.8 - (0.02 * g_iSurvivorCount-1));
		duration *= multiplier;
		
		// The longer the stage goes on, the faster the enemies spawn, but this is clamped based on the difficulty.
		float reduction = float(g_iRespawnWavesCompleted) * 0.5;
		float maxReduction = 5.0 + (float(g_iSubDifficulty) * 1.0);
		if (reduction > maxReduction)
			reduction = maxReduction;
		
		duration -= reduction;
	}
	
	float minSpawnWaveTime = GetConVarFloat(g_cvEnemyMinSpawnWaveTime);
	if (duration < minSpawnWaveTime)
		duration = minSpawnWaveTime;
	
	CreateTimer(duration, Timer_RespawnWave, _, TIMER_FLAG_NO_MAPCHANGE);
	
	int maxCount = GetRandomInt(1, 3) + g_iSurvivorCount-1 + g_iSubDifficulty;
	int absoluteMaxCount = GetConVarInt(g_cvEnemyMaxSpawnWaveCount);
	if (maxCount > absoluteMaxCount)
		maxCount = absoluteMaxCount;
	
	Handle respawnArray = CreateArray(1, MAXTF2PLAYERS);
	static int spawnPoints[MAXTF2PLAYERS];
	int count;
	bool finished, ignorePoints, chosen[MAXTF2PLAYERS], pointsGiven[MAXTF2PLAYERS];
	
	// grab our next players for the spawn
	for (int i = 1; i <= MaxClients; i++)
	{
		if (chosen[i] || !g_bPlayerInGame[i] || GetClientTeam(i) != TEAM_ENEMY || IsPlayerAlive(i))
			continue;
		
		if (ignorePoints && count < maxCount || !finished && spawnPoints[i] >= 0)
		{
			SetArrayCell(respawnArray, count, i);
			count++;
			SwapArrayItems(respawnArray, GetRandomInt(0, count-1), GetRandomInt(0, count-1));
			
			spawnPoints[i]--;
			chosen[i] = true;
		}
		else if (!pointsGiven[i])
		{
			if (!IsFakeClient(i))
				spawnPoints[i] += 3;
			else
				spawnPoints[i]++;
				
			pointsGiven[i] = true;
		}
		
		if (spawnPoints[i] > 0 && IsFakeClient(i))
			spawnPoints[i] = 0; // bots have less spawn priority than players this way, but they will still spawn
		
		if (count >= maxCount)
		{
			finished = true; // if we're finished, we're just setting everyone's points for next time around
		}
		else
		{
			ignorePoints = true; // not enough spawns, ignore the points system
			i = 1;
		}
	}

	ResizeArray(respawnArray, count);
	int client;
	float time = 0.1;
	for (int i = 0; i < count; i++)
	{
		client = GetArrayCell(respawnArray, i);
		
		if (g_iSubDifficulty >= SubDifficulty_VeryHard && GetRandomFloat(g_flDifficultyCoeff/100.0, 100.0) > 99.0 || g_flDifficultyCoeff/100.0 > 99.0)
		{
			g_iBossSpawnType[client] = GetRandomBoss();
		}
		else
		{
			g_iEnemySpawnType[client] = GetRandomEnemy();
		}
		
		// Don't spawn everyone on the same frame to reduce lag.
		CreateTimer(time, Timer_SpawnEnemy, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		time += 0.1;
	}
	
	delete respawnArray;
	g_iRespawnWavesCompleted++;
	
	return Plugin_Continue;
}

public Action Timer_SpawnEnemy(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
	
	if (g_iEnemySpawnType[client] > -1)
	{
		SpawnEnemy(client, g_iEnemySpawnType[client]);
	}
	else if (g_iBossSpawnType[client] > -1)
	{
		SpawnBoss(client, g_iBossSpawnType[client]);
	}
	
	g_iEnemySpawnType[client] = -1;
	g_iBossSpawnType[client] = -1;
	
	return Plugin_Continue;
}

public Action Timer_SetNextStage(Handle timer, int stage)
{
	g_iCurrentStage = stage;
	
	// rf2_setnextmap
	if (g_bForceNextMapCommand)
	{
		char reason[64];
		FormatEx(reason, sizeof(reason), "%s forced the next map", g_szMapForcer);
		
		ForceChangeLevel(g_szForcedMap, reason);
		g_bForceNextMapCommand = false;
	}
	else
	{
		SetNextStage(stage);
	}
	
	return Plugin_Continue;
}

public Action Timer_GameOver(Handle timer)
{
	ReloadPlugin(true);
	return Plugin_Continue;
}

public Action Timer_PlayerHud(Handle timer)
{
	if (!g_bPluginEnabled)
	{
		g_hHudTimer = null;
		return Plugin_Stop;
	}
	
	static bool scoreCalculated;
	static int score;
	static char rank[8];
	
	int hudSeconds;
	char strangeItemName[64];
	
	SetHudTextParams(-1.0, -1.3, 0.15, g_iMainHudR, g_iMainHudG, g_iMainHudB, 255);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!g_bPlayerInGame[i] || IsFakeClient(i))
			continue;
		
		if (g_bGameOver)
		{
			// Calculate our score and rank.
			if (!scoreCalculated)
			{
				score += g_iTotalEnemiesKilled * 5;
				score += g_iTotalBossesKilled * 300;
				score += g_iTotalItemsFound * 50;
				score += g_iStagesCompleted * 1000;
				
				if (score >= 60000)
					rank = "S";
				else if (score >= 37500)
					rank = "A";
				else if (score >= 25000)
					rank = "B";
				else if (score >= 13500)
					rank = "C";
				else if (score >= 9000)
					rank = "D";
				else if (score >= 3500)
					rank = "E";
				else
					rank = "F";
					
				scoreCalculated = true;
			}
			
			SetHudTextParams(-1.0, -1.3, 0.15, 255, 100, 100, 255);
			ShowSyncHudText(i, g_hMainHudSync, 
			"\n\n\n\nGAME OVER\n\nEnemies slain: %i\nBosses slain: %i\nStages completed: %i\nItems found: %i\n\nTOTAL SCORE: %i\nRANK: %s", 
			g_iTotalEnemiesKilled, g_iTotalBossesKilled, g_iStagesCompleted, g_iTotalItemsFound, score, rank);
			return Plugin_Continue;
		}
		
		hudSeconds = RoundFloat((g_flSecondsPassed) - (g_iMinutesPassed * 60.0));
		
		if (g_bTankBossMode)
		{
			if (g_flTankGracePeriodTime > 0.0)
			{
				FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "Tank arriving in: %.0f...", g_flTankGracePeriodTime);
			}
			else
			{
				FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "Tanks Destroyed: %i/%i", g_iTanksKilledObjective, g_iTankKillRequirement);
			}
		}
		
		if (IsPlayerSurvivor(i))
		{
			if (g_iPlayerStrangeItem[i] > Item_Null)
			{
				GetItemName(g_iPlayerStrangeItem[i], strangeItemName, sizeof(strangeItemName));
				if (g_flPlayerStrangeItemCooldown[i] <= 0.0)
				{
					Format(strangeItemName, sizeof(strangeItemName), "%s (READY! RELOAD (R) TO USE)", strangeItemName);
				}
				else
				{
					Format(strangeItemName, sizeof(strangeItemName), "%s (on cooldown)", strangeItemName);
				}
			}
			else
			{
				strangeItemName = "None";
			}
			
			ShowSyncHudText(i, g_hMainHudSync, g_szSurvivorHudText, g_iStagesCompleted+1, g_iMinutesPassed, 
			hudSeconds, g_iEnemyLevel, g_iPlayerLevel[i], g_flPlayerXP[i], g_flPlayerNextLevelXP[i], g_flPlayerCash[i],
			g_szHudDifficulty, strangeItemName, g_flPlayerStrangeItemCooldown[i], g_szObjectiveHud[i]);
		}
		else
		{
			ShowSyncHudText(i, g_hMainHudSync, g_szHudText, g_iStagesCompleted+1, g_iMinutesPassed, hudSeconds, 
			g_iEnemyLevel, g_szHudDifficulty);
		}
	}
	return Plugin_Continue;
}

public Action Timer_Difficulty(Handle timer)
{
	if (!g_bPluginEnabled)
	{
		g_hDifficultyTimer = null;
		return Plugin_Stop;
	}
	
	if (g_bGameOver)
		return Plugin_Continue;
	
	g_flSecondsPassed += 1.0;
	if (g_flSecondsPassed >= 60.0 * (g_iMinutesPassed+1))
		g_iMinutesPassed++;

	float timeFactor = g_flSecondsPassed / 10.0;
	float playerFactor = ((g_iSurvivorCount-1) * 0.12) + 1.0;
	if (playerFactor < 1.0)
		playerFactor = 1.0;
	
	// this scales a bit too hard in higher survivor counts
	float value = 1.12 - (0.01 * float(g_iSurvivorCount-1));
	if (value < 1.02)
		value = 1.02;
		
	float stageFactor = Pow(value, float(g_iStagesCompleted));
	
	float difficultyFactor = GetDifficultyFactor(g_iDifficultyLevel);
	float oldDifficultyCoeff = g_flDifficultyCoeff;
	g_flDifficultyCoeff = (timeFactor * stageFactor * playerFactor) * difficultyFactor;
	g_flDifficultyCoeff *= GetConVarFloat(g_cvDifficultyScaleMultiplier);
	if (g_flDifficultyCoeff < oldDifficultyCoeff)
		g_flDifficultyCoeff = oldDifficultyCoeff;
	
	if (GetConVarInt(g_cvShowDifficultyCoeff) != 0)
		PrintCenterTextAll("g_flDifficultyCoeff = %f", g_flDifficultyCoeff);

	int currentLevel = g_iEnemyLevel;
	g_iEnemyLevel = RoundToFloor(1.0 + g_flDifficultyCoeff / (g_flSubDifficultyIncrement / 4.0));
	
	// do not go down
	if (g_iEnemyLevel < currentLevel)
		g_iEnemyLevel = currentLevel;
	
	if (g_iEnemyLevel < 1)
		g_iEnemyLevel = 1;
	
	if (g_iEnemyLevel > currentLevel) // enemy level just increased
	{
		RF2_PrintToChatAll("Enemy Level: {red}%i -> %i", currentLevel, g_iEnemyLevel);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!g_bPlayerInGame[i] || !IsPlayerAlive(i))
				continue;
			
			if (GetClientTeam(i) == TEAM_ENEMY)
				CalculatePlayerMaxHealth(i);
		}
	}
	
	// increment the sub difficulty depending on difficulty value
	float subTime = g_flDifficultyCoeff / g_flSubDifficultyIncrement;
	if (subTime >= g_iSubDifficulty+1)
	{	
		g_iSubDifficulty++;
		SetHudDifficulty(g_iSubDifficulty);
		
		static float lastBellTime;
		if (g_iSubDifficulty <= SubDifficulty_Normal || lastBellTime+10.0 > GetGameTime())
		{
			EmitSoundToAll(SOUND_BELL);
			lastBellTime = GetGameTime();
		}
	}
	
	return Plugin_Continue;
}

public Action Timer_PlayerTimer(Handle timer)
{
	if (!g_bPluginEnabled || !g_bRoundActive)
	{
		g_hPlayerTimer = null;
		return Plugin_Stop;
	}
	
	int maxHealth;
	int health;
	int healAmount;
	int weapon;
	int ammoType;
	bool canRegen;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!g_bPlayerInGame[i])
			continue;
		
		// All players have infinite reserve ammo
		for (int wep = WeaponSlot_Primary; wep <= WeaponSlot_Secondary; wep++)
		{
			weapon = GetPlayerWeaponSlot(i, wep);
			if (weapon > -1)
			{
				ammoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
				if (ammoType > TFAmmoType_None && ammoType < TFAmmoType_Metal)
				{
					GivePlayerAmmo(i, 999999, ammoType, true);
				}
			}
		}
		
		// Health Regen
		canRegen = (IsPlayerSurvivor(i) || PlayerHasItem(i, Item_Archimedes) || PlayerHasItem(i, Item_ClassCrown));
		if (canRegen)
		{
			g_flHealthRegenTime[i] -= 0.1;
			if (g_flHealthRegenTime[i] <= 0.0 && !TF2_IsPlayerInConditionEx(i, TFCond_Overhealed))
			{
				g_flHealthRegenTime[i] = 0.0;
				health = GetClientHealth(i);
				maxHealth = g_iPlayerCalculatedMaxHealth[i];
				
				if (health < maxHealth)
				{
					healAmount = RoundToFloor((float(maxHealth) * 0.0025));
					
					if (PlayerHasItem(i, Item_Archimedes))
					{
						healAmount = RoundToFloor(float(healAmount) * (1.0 + CalculateItemModifier(i, Item_Archimedes)));
					}
					
					if (PlayerHasItem(i, Item_ClassCrown))
					{
						healAmount = RoundToFloor(float(healAmount) * (1.0 + CalculateItemModifier(i, Item_ClassCrown)));
					}
					
					if (IsPlayerSurvivor(i))
					{
						if (g_iDifficultyLevel == DIFFICULTY_TITANIUM)
							healAmount = RoundToFloor(float(healAmount) * 0.75);
						else if (g_iDifficultyLevel == DIFFICULTY_AUSTRALIUM)
							healAmount = RoundToFloor(float(healAmount) * 0.5);
					}
					
					if (healAmount < 1)
						healAmount = 1;
					
					SetEntityHealth(i, health+healAmount);
					if (GetClientHealth(i) > maxHealth)
					{
						SetEntityHealth(i, maxHealth);
					}
				}
			}
			
			canRegen = false;
		}
	}

	return Plugin_Continue;
}

public Action Timer_PluginMessage(Handle timer)
{
	if (!g_bPluginEnabled)
		return Plugin_Continue;
		
	static int message;
	const int maxMessages = 3;
	
	switch (message)
	{
		case 0: RF2_PrintToChatAll("Type {lightblue}/rf2_settings{default} to change your in-game preferences at any time.");
		case 1: RF2_PrintToChatAll("Need to AFK? No problem! Type {lightblue}/rf2_afk{default} into chat to enter AFK Mode. Only up to 2 players may use this at a time, however.");
		case 2: RF2_PrintToChatAll("{lightblue}Risk Fortress 2{default} version {pink}%s{default} created by {indianred}CookieCat", PLUGIN_VERSION);
		case 3: RF2_PrintToChatAll("Don't want to be a Survivor or want to save up queue points? Toggle it off in {lightblue}/rf2_settings{default}.");
	}
	
	message++;
	if (message > maxMessages)
		message = 0;
		
	return Plugin_Continue;
}

public Action Timer_DeleteEntity(Handle timer, int entity)
{
	entity = EntRefToEntIndex(entity);
	if (entity != INVALID_ENT_REFERENCE)
		RemoveEntity(entity);
		
	return Plugin_Continue;
}

public Action Timer_AFKManager(Handle timer)
{
	if (!g_bPluginEnabled || GetConVarBool(g_cvEnableAFKManager) == false)
		return Plugin_Continue;
	
	int kickPriority[MAXTF2PLAYERS];
	int highestKickPriority = -1;
	int afkCount;
	int humanCount;
	
	int afkLimit = GetConVarInt(g_cvAFKLimit);
	int minHumans = GetConVarInt(g_cvAFKMinHumans);
	float afkKickTime = GetConVarFloat(g_cvAFKManagerKickTime);
	bool kickAdmins = GetConVarBool(g_cvAFKKickAdmins);
	
	// first we need to count our AFKs to see if anyone needs kicking
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!g_bPlayerInGame[i] || IsFakeClient(i))
			continue;
		
		humanCount++;
		
		if (IsPlayerAFK(i))
		{
			kickPriority[i] += RoundToFloor(g_flAFKTime[i]); // kick whoever has been AFK the longest first
			if (kickPriority[i] > highestKickPriority || highestKickPriority < 0)
			{
				highestKickPriority = kickPriority[i];
			}
			
			afkCount++;
		}
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!g_bPlayerInGame[i] || IsFakeClient(i))
			continue;
		
		g_flAFKTime[i] += 1.0;
		if (g_flAFKTime[i] >= afkKickTime * 0.5)
		{
			if (afkCount >= afkLimit && humanCount >= minHumans)
			{
				if (kickAdmins || GetUserAdmin(i) == INVALID_ADMIN_ID)
				{
					PrintCenterText(i, "You have been detected as AFK. Press any button or you will be kicked shortly.");
				}
			}
			
			if (!IsPlayerAlive(i) && GetClientTeam(i) > 0)
			{
				ChangeClientTeam(i, 0);
			}
			
			g_bIsAFK[i] = true;
		}
		
		if (afkCount >= afkLimit && g_flAFKTime[i] >= afkKickTime && kickPriority[i] >= highestKickPriority && humanCount >= minHumans)
		{
			if (kickAdmins || GetUserAdmin(i) == INVALID_ADMIN_ID)
			{
				KickClient(i, "Kicked for being AFK.");
				g_flAFKTime[i] = 0.0;
				g_bIsAFK[i] = false;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action OnCallForMedic(int client, const char[] command, int args)
{
	if (!g_bPluginEnabled)
		return Plugin_Continue;
	
	if (IsPlayerSurvivor(client) && IsPlayerAlive(client))
	{
		char arg1[8], arg2[8];
		int num1, num2;
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		num1 = StringToInt(arg1);
		num2 = StringToInt(arg2);
		
		if (num1 != 0 || num2 != 0) // voicemenu 0 0 only
			return Plugin_Continue;
			
		if (GetClientButtons(client) & IN_SCORE)
		{
			ShowItemMenu(client); // shortcut
			return Plugin_Handled;
		}
		
		if (PickupItem(client))
			return Plugin_Handled;
		else if (ObjectInteract(client))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnChangeClass(int client, const char[] command, int args)
{
	if (!g_bPluginEnabled || g_bWaitingForPlayers)
		return Plugin_Continue;
		
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	TFClassType desiredClass = TF2_GetClass(arg1);
	if (g_bRoundActive && !g_bGracePeriod || GetClientTeam(client) == TEAM_ENEMY)
	{
		RF2_PrintToChat(client, "You can't change your class at this time!");
		
		if (desiredClass != TFClass_Unknown)
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", view_as<int>(desiredClass));
		}
		
		return Plugin_Handled;
	}
	else if (IsPlayerSurvivor(client))
	{
		float pos[3];
		GetClientAbsOrigin(client, pos);
		
		SilentKillPlayer(client);
		ChangeClientTeam(client, TEAM_SURVIVOR);
		
		TF2_SetPlayerClass(client, desiredClass); // so stats update properly
		CreateSurvivor(client, GetSurvivorIndex(client));

		// Teleport the player back to their last position in grace period
		DataPack pack;
		CreateDataTimer(0.3, Timer_SuicideTeleport, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(GetClientUserId(client));
		pack.WriteFloat(pos[0]);
		pack.WriteFloat(pos[1]);
		pack.WriteFloat(pos[2]);
	}
	return Plugin_Continue;
}

public Action OnChangeTeam(int client, const char[] command, int args)
{
	if (!g_bPluginEnabled)
		return Plugin_Continue;
	
	int team = GetClientTeam(client);
	
	if (team == TEAM_ENEMY || team == TEAM_SURVIVOR)
	{
		RF2_PrintToChat(client, "You can't change your team!");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnChangeSpec(int client, const char[] command, int args)
{
	ResetAFKTime(client);
	return Plugin_Continue;
}

public Action OnSuicide(int client, const char[] command, int args)
{
	if (!g_bPluginEnabled || !g_bRoundActive)
		return Plugin_Continue;

	if (g_bGracePeriod && IsPlayerSurvivor(client))
	{
		// Teleport the player back to their last position in grace period
		float pos[3];
		GetClientAbsOrigin(client, pos);
		
		DataPack pack;
		CreateDataTimer(0.1, Timer_SuicideTeleport, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(GetClientUserId(client));
		pack.WriteFloat(pos[0]);
		pack.WriteFloat(pos[1]);
		pack.WriteFloat(pos[2]);
	}
	else
	{
		RF2_PrintToChat(client, "You are NOT allowed to suicide!");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Timer_SuicideTeleport(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if (client == 0)
		return Plugin_Continue;
	
	if (!g_bPlayerInGame[client] || !IsPlayerAlive(client))
		return Plugin_Continue;
		
	float pos[3];
	pos[0] = pack.ReadFloat();
	pos[1] = pack.ReadFloat();
	pos[2] = pack.ReadFloat();
	
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Continue;
}

public void OnGameFrame()
{
	if (!g_bPluginEnabled || !g_bRoundActive)
		return;
	
	float speed;
	int weapon;
	int health;
	float healthPercentage;
	static char classname[128];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!g_bPlayerInGame[i] || !IsPlayerAlive(i))
			continue;
		
		if (IsFakeClient(i))
			TFBot_Think(i);
		
		// Calculate speed
		speed = g_flPlayerCalculatedMaxSpeed[i];
		if (GetBossType(i) >= 0 && g_flPlayerCalculatedMaxSpeed[i] < 230.0)
		{
			// crouch at normal speed if we're a boss and are slower than a normal Heavy
			if (GetEntProp(i, Prop_Send, "m_bDucked"))
			{
				speed *= 3.0;
			}
		}
		
		// Note that some of these are purposefully hardcoded to match up with TF2's speed values.
		if (TF2_IsPlayerInConditionEx(i, TFCond_Charging))
		{
			speed = 720.0 + g_flPlayerCalculatedMaxSpeed[i] - g_flPlayerMaxSpeed[i];
		}
		else if (TF2_IsPlayerInConditionEx(i, TFCond_Slowed))
		{
			switch (TF2_GetPlayerClass(i))
			{
				case TFClass_Heavy:
				{
					speed *= 0.47 * TF2Attrib_HookValueFloat(1.0, "mult_player_aiming_movespeed", i);
				}
				case TFClass_Sniper:
				{
					weapon = GetPlayerWeaponSlot(i, WeaponSlot_Primary);
					if (weapon != INVALID_ENT_REFERENCE)
					{
						GetEntityClassname(weapon, classname, sizeof(classname));
						if (strcmp(classname, "tf_weapon_compound_bow") == 0)
						{
							speed *= 0.53;
						}
						else
						{
							speed *= 0.27;
						}
					}
				}
			}
		}
		
		// I know this is different depending on the class, but I don't really care.
		if (TF2_IsPlayerInConditionEx(i, TFCond_SpeedBuffAlly))
			speed *= 1.25;
			
		if (TF2_IsPlayerInConditionEx(i, TFCond_RuneHaste))
			speed *= 1.3;
		else if (TF2_IsPlayerInConditionEx(i, TFCond_RuneAgility))
			speed *= 1.5;
			
		weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
		if (weapon != INVALID_ENT_REFERENCE && TF2Attrib_GetByDefIndex(weapon, 235)) // "mod shovel speed boost" (Escape Plan)
		{
			health = GetClientHealth(i);
			healthPercentage = float(health) / float(g_iPlayerCalculatedMaxHealth[i]);
			if (healthPercentage < 0.4)
				healthPercentage = 0.4;
				
			speed *= 1.0 + (1.0-healthPercentage);
		}
		
		SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", speed);
	}
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	g_bPlayerInCondition[client][condition] = true;
	if (condition == TFCond_Disguised && !g_bDisguising)
	{
		UpdatePlayerDisguise(client);
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	g_bPlayerInCondition[client][condition] = false;
	if (condition == TFCond_Disguised)
	{
		ClearPlayerDisguise(client);
	}
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if (!g_bPluginEnabled || g_bWaitingForPlayers)
		return Plugin_Continue;
	
	DataPack pack = CreateDataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(weapon);
	RequestFrame(RF_NextPrimaryAttack, pack);
	
	float proc = GetWeaponProcCoefficient(weapon);
	if (RollAttackCrit(client, proc))
	{
		result = true;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void RF_NextPrimaryAttack(DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if (client == 0)
	{
		delete pack;
		return;
	}
	
	int weapon = pack.ReadCell();
	delete pack;
	float gameTime = GetGameTime();
	float multiplier = 1.0 / (1.0 + CalculateItemModifier(client, Item_MaimLicense));
	float time = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
	time -= gameTime;
	time *= multiplier;
	
	// Melee weapons have a swing speed cap.
	if (time < 0.3 && GetPlayerWeaponSlot(client, WeaponSlot_Melee) == weapon)
	{
		time = 0.3;
	}
	
	ChopFloat(time, 4);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", gameTime+time);
}

public void TF2_OnWaitingForPlayersStart()
{
	if (!g_bPluginEnabled)
		return;
	
	DespawnObjects();
	if (GetConVarBool(g_cvAlwaysSkipWait))
	{
		InsertServerCommand("mp_restartgame_immediate 1");
	}
	
	g_bWaitingForPlayers = true;
	PrintToServer("[RF2] Waiting For Players sequence started.");
}

public void TF2_OnWaitingForPlayersEnd()
{
	if (!g_bPluginEnabled)
		return;
	
	g_bWaitingForPlayers = false;
	PrintToServer("[RF2] Waiting For Players sequence ended.");
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!g_bPluginEnabled)
		return;
		
	if (IsValidEdict(entity))
	{
		g_iItemDropper[entity] = -1;
		g_iItemOwner[entity] = -1;
		g_iEntityItemDamageProc[entity] = -1;
		g_bDroppedItem[entity] = false;
		g_bNoDamageOwner[entity] = false;
	}
	
	if (StrContains(classname, "item_currencypack") != -1)
	{
		SDKHook(entity, SDKHook_StartTouch, Hook_CashTouch);
		SDKHook(entity, SDKHook_Touch, Hook_CashTouch);
	}
	else if (strcmp(classname, "tf_projectile_rocket") == 0 || 
	strcmp(classname, "tf_projectile_flare") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, Hook_ProjectileSpawnPost);
	}
	else if (strcmp(classname, "func_regenerate") == 0 || strcmp(classname, "tf_ammo_pack") == 0 ||
	StrContains(classname, "item_") != -1 || StrContains(classname, "tf_logic_") != -1 || strcmp(classname, "teleport_vortex") == 0)
	{
		RemoveEntity(entity);
	}
	else if (StrContains(classname, "obj_") != -1)
	{
		SDKHook(entity, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamageAlive);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (!g_bPluginEnabled || !IsValidEdict(entity))
		return;
		
	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (strcmp(classname, "tf_wearable") == 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!g_bPlayerInGame[i])
				continue;
				
			if (g_iPlayerStatWearable[i] == entity)
			{
				g_iPlayerStatWearable[i] = -1;
				break;
			}
		}
	}
}

public void Hook_ProjectileSpawnPost(int entity)
{
	int launcher;
	if ((launcher = GetEntPropEnt(entity, Prop_Send, "m_hLauncher")) > 0 && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") <= MaxClients)
	{
		char buffer[PLATFORM_MAX_PATH];
		TF2Attrib_HookValueString("none", "custom_projectile_model", launcher, buffer, sizeof(buffer));
		if (strcmp(buffer, "none") != 0)
		{
			SetEntityModel(entity, buffer);
		}
	}
}

public Action Hook_OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!g_bPluginEnabled || g_bWaitingForPlayers)
		return Plugin_Continue;
	
	static char attackerClassname[64];
	GetEntityClassname(attacker, attackerClassname, sizeof(attackerClassname));
	
	if (!IsValidClient(attacker))
		return Plugin_Continue;
	
	bool victimIsBuilding = HasEntProp(victim, Prop_Send, "m_iObjectType");
	if (!IsValidClient(victim) && !victimIsBuilding)
		return Plugin_Continue;
		
	if (g_bNoDamageOwner[inflictor] && victim == GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity"))
	{
		return Plugin_Handled;
	}
	
	float survivorDamageIncrease = GetConVarFloat(g_cvSurvivorDamageScale);
	float enemyDamageIncrease = GetConVarFloat(g_cvEnemyDamageScale);
	
	bool invuln = IsInvuln(victim);
	
	//bool inflictorIsSentry = HasEntProp(inflictor, Prop_Send, "m_iObjectType");
	
	// Proc coefficient calculation. Like Risk of Rain 2, this is a value that affects
	// the rate at which certain items proc (such as Lucky Shot).
	// Important for things like miniguns and flamethrowers that send tons of damage events.
	float proc = 1.0;
	if (IsValidEntity(weapon))
	{
		proc *= GetWeaponProcCoefficient(weapon);
	}
	
	static char inflictorClassname[64];
	GetEntityClassname(inflictor, inflictorClassname, sizeof(inflictorClassname));
	if (strcmp(inflictorClassname, "entity_medigun_shield") == 0)
	{
		proc *= 0.02; // This thing does damage every damn tick.
	}
	
	if (g_iItemDamageProc[attacker] > 0)
	{
		proc *= GetItemProcCoefficient(g_iItemDamageProc[attacker]);
		g_iItemDamageProc[attacker] = -1;
	}
	
	if (g_iEntityItemDamageProc[inflictor] > 0)
	{
		// shouldn't need to set back to -1
		proc *= GetItemProcCoefficient(g_iEntityItemDamageProc[attacker]);
	}
	
	if (attacker == victim && GetBossType(victim) >= 0)
	{
		// bosses don't do damage to themselves
		damage = 0.0;
		return Plugin_Changed;
	}
	
	bool changed;
	//int attackerTeam = GetEntProp(attacker, Prop_Data, "m_iTeamNum");
	int victimTeam = GetEntProp(victim, Prop_Data, "m_iTeamNum");
	
	// backstabs do set damage against bosses, obviously
	if (damagecustom == TF_CUSTOM_BACKSTAB && GetBossType(victim) >= 0)
	{
		int damageType = GetConVarInt(g_cvBossStabDamageType);
		if (damageType == StabDamageType_Raw)
		{
			damage = GetConVarFloat(g_cvBossStabDamageAmount);
		}
		else if (damageType == StabDamageType_Percentage)
		{
			damage = float(g_iPlayerCalculatedMaxHealth[victim]) * GetConVarFloat(g_cvBossStabDamagePercent);
		}
		
		changed = true;
	}
	
	if (IsPlayerSurvivor(attacker))
	{
		damage *= 1.0 + (float(g_iPlayerLevel[attacker]-1) * survivorDamageIncrease);
		changed = true;
	}
	else
	{
		damage *= 1.0 + (float(g_iEnemyLevel-1) * enemyDamageIncrease);
		changed = true;
	}
	
	if (!victimIsBuilding)
	{
		if (!(damagetype & DMG_CRIT) || g_bAttackWasMiniCrit[attacker])
		{
			if (RollAttackCrit(attacker, proc))
			{
				damagetype &= ~DMG_CRIT; // minicrits use this same flag :/
				damagetype |= DMG_CRIT;	 // removing it and setting it makes it a full crit
				changed = true;
			}
		}
	}
	g_bAttackWasMiniCrit[attacker] = false;
	
	if (PlayerHasItem(attacker, Item_PointAndShoot))
	{
		if (g_iDamageBuffStacks[attacker] > 0)
		{
			damage *= 1.0 + (0.08 * float(g_iDamageBuffStacks[attacker]));
			changed = true;
		}
		
		int maxStacks = RoundToFloor(CalculateItemModifier(attacker, Item_PointAndShoot));
		if (g_iDamageBuffStacks[attacker] < maxStacks)
		{
			g_iDamageBuffStacks[attacker]++;
			float duration = damage / 
			((IsPlayerSurvivor(attacker) ? 
			float(g_iPlayerLevel[attacker]) * survivorDamageIncrease : float(g_iEnemyLevel) * enemyDamageIncrease) * 100.0) * proc;
			
			if (duration > 5.0)
				duration = 5.0;
				
			if (duration < 0.5)
				duration = 0.5;			
			
			CreateTimer(duration, Timer_DecayDamageBuff, attacker, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	if (PlayerHasItem(attacker, Item_ClassCrown))
	{
		damage *= 1.0 + CalculateItemModifier(attacker, Item_ClassCrown);
		changed = true;
	}
	
	if (PlayerHasItem(attacker, Item_Dangeresque))
	{
		damage *= 1.0 + g_flDangeresqueDamageBonus[attacker];
		changed = true;
	}
	
	/**
	* !!!Below this line is post damage calculation. Do not add any damage-modifying calculations below this line!!!
	*
	*/
	
	if (victimTeam == TEAM_SURVIVOR && !victimIsBuilding)
	{
		int maxHealth = g_iPlayerCalculatedMaxHealth[victim];
		float seconds = 5.0 * (damage / float(maxHealth));
		if (seconds > 5.0)
			seconds = 5.0;
		else if (seconds < 0.5)
			seconds = 0.5;
			
		g_flHealthRegenTime[victim] += seconds;
		if (g_flHealthRegenTime[victim] > 5.0)
			g_flHealthRegenTime[victim] = 5.0;
	}
	
	if (PlayerHasItem(attacker, Item_LuckyShot) && g_iEntityItemDamageProc[inflictor] != Item_LuckyShot)
	{
		float random = 100.0 - (100.0 / (CalculateItemModifier(attacker, Item_LuckyShot) + 1.0));
		random *= proc;
		if (GetRandomFloat(0.0, 100.0) <= random)
		{
			int rocket = CreateEntityByName("tf_projectile_sentryrocket");
			SetEntProp(rocket, Prop_Data, "m_iTeamNum", GetClientTeam(attacker));
			SetEntityOwner(rocket, attacker);
			SetEntDataFloat(rocket, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 50.0, true); // hidden, bleh (sets damage)
			g_bNoDamageOwner[rocket] = true;
			
			g_iItemDamageProc[attacker] = Item_LuckyShot;
			g_iEntityItemDamageProc[rocket] = Item_LuckyShot;
			
			const float rocketSpeed = 1200.0;
			float angles[3];
			float velocity[3];
			float pos[3];
			float enemyPos[3];
			GetClientAbsOrigin(attacker, pos);
			GetClientAbsOrigin(victim, enemyPos);
			pos[2] += 30.0;
			enemyPos[2] += 30.0;
			
			GetVectorAnglesTwoPoints(pos, enemyPos, angles);
			GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(velocity, velocity);
			ScaleVector(velocity, rocketSpeed);
			TeleportEntity(rocket, pos, angles, velocity);
			DispatchSpawn(rocket);
			
			EmitSoundToAll(SOUND_LUCKYSHOT_FIRE, attacker);
		}
	}
	
	if (PlayerHasItem(victim, Item_PocketMedic) && !invuln)
	{
		RequestFrame(RF_CheckHealthForPocketMedic, victim);
	}
	
	if (PlayerHasItem(victim, Item_BoomBoxers) && !invuln)
	{
		float chance = 10.0 * proc;
		if (GetRandomFloat(0.0, 100.0) <= chance)
		{
			DoRadiusDamage(victim, g_flItemModifier[Item_BoomBoxers] * float(g_iPlayerItem[victim][Item_BoomBoxers]), DMG_BLAST, 200.0, 0.3, true);
		}
	}
	
	if (changed)
		return Plugin_Changed;

	return Plugin_Continue;
}

public void Hook_WeaponSwitch(int client, int weapon)
{
	RequestFrame(RF_RecalculateSpeed, client);
}

public void RF_RecalculateSpeed(int client)
{
	if (!g_bPlayerInGame[client])
		return;
	
	CalculatePlayerMaxSpeed(client); // Need to account for stuff like Powerjack with "provide on active".
}

public void RF_CheckHealthForPocketMedic(int client)
{
	if (!g_bPlayerInGame[client] || !IsPlayerAlive(client))
		return;
		
	if (float(GetClientHealth(client)) < float(g_iPlayerCalculatedMaxHealth[client]) * g_flItemModifier[Item_PocketMedic])
	{
		EmitSoundToAll(SOUND_SHIELD, client);
		TF2_AddCondition(client, TFCond_UberchargedCanteen, 5.0);
		PrintHintText(client, "Pocket Medic activated!");
		GiveItem(client, Item_PocketMedic, -1);
	}
}

public Action Timer_DecayDamageBuff(Handle timer, int client)
{
	if (g_iDamageBuffStacks[client] > 0)
	{
		g_iDamageBuffStacks[client]--;
	}
	
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype)
{
	if (g_bPluginEnabled)
	{
		Action action = Plugin_Continue;
		if (IsFakeClient(client))
		{
			action = TFBot_OnPlayerRunCmd(client, buttons, impulse, vel, angles, weapon, subtype);
		}
		else
		{
			if (buttons)
			{
				ResetAFKTime(client);
			}
		}
		
		static bool reloadPressed[MAXTF2PLAYERS];
		if (buttons & IN_RELOAD)
		{
			if (!reloadPressed[client])
			{
				if (g_iPlayerStrangeItem[client] > Item_Null)
				{
					ActivateStrangeItem(client);
				}
			}
			
			reloadPressed[client] = true;
		}
		else
		{
			reloadPressed[client] = false;
		}
		
		if (g_iFootstepType[client] == FootstepType_GiantRobot && !g_bGiantFootstepCooldown[client])
		{
			if (!TF2_IsPlayerInConditionEx(client, TFCond_Disguised))
			{
				if (buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT)
				{
					if (GetEntityFlags(client) & FL_ONGROUND)
					{
						float fwdVel[3];
						float sideVel[3];
						GetAngleVectors(angles, fwdVel, NULL_VECTOR, NULL_VECTOR);
						GetAngleVectors(angles, NULL_VECTOR, sideVel, NULL_VECTOR);
						NormalizeVector(fwdVel, fwdVel);
						NormalizeVector(sideVel, sideVel);
						NormalizeVector(vel, vel);
						
						float dotFwd = GetVectorDotProduct(fwdVel, vel);
						float dotSide = GetVectorDotProduct(sideVel, vel);
						
						if (dotFwd != 0.0 || dotSide != 0.0)
						{
							TFClassType class = TF2_GetPlayerClass(client);
							char sample[PLATFORM_MAX_PATH];
							
							// No unique footstep sounds for these classes
							if (class == TFClass_Sniper || class == TFClass_Engineer || class == TFClass_Spy)
							{
								FormatEx(sample, sizeof(sample), "mvm/giant_common/giant_common_step_0%i.wav", GetRandomInt(1, 8));
							}
							else
							{
								char classString[16];
								TF2_GetClassString(class, classString, sizeof(classString));
								
								// Some of the filenames don't have underscores before the number, yet others do. -.- (Soldier and Heavy)
								if (class == TFClass_Soldier || class == TFClass_Heavy)
									FormatEx(sample, sizeof(sample), "mvm/giant_%s/giant_%s_step0%i.wav", classString, classString, GetRandomInt(1, 4));
								else
									FormatEx(sample, sizeof(sample), "mvm/giant_%s/giant_%s_step_0%i.wav", classString, classString, GetRandomInt(1, 4));
							}
							
							if (class == TFClass_Spy)
							{
								if (TF2_IsPlayerInConditionEx(client, TFCond_Disguised) || TF2_IsPlayerInConditionEx(client, TFCond_Cloaked))
								{
									sample = "vo/null.wav";
								}
							}
							
							PrecacheSound(sample);
							EmitSoundToAll(sample, client);
							
							g_bGiantFootstepCooldown[client] = true;
							
							float duration = g_flGiantFootstepInterval[client];
							float multiplier = g_flPlayerCalculatedMaxSpeed[client] / g_flPlayerMaxSpeed[client];
							duration *= multiplier;
							
							CreateTimer(duration, Timer_GiantFootstep, client, TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
		}
		
		return action;
	}

	return Plugin_Continue;
}

public Action PlayerSoundHook(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& client, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	if (!g_bPluginEnabled || g_bWaitingForPlayers)
		return Plugin_Continue;
	
	if (client > 0 && client <= MaxClients && (GetClientTeam(client) == TEAM_ENEMY || TF2_IsPlayerInConditionEx(client, TFCond_Disguised)))
	{
		int voiceType = g_iVoiceType[client];
		int footstepType = g_iFootstepType[client];
		if (TF2_IsPlayerInConditionEx(client, TFCond_Disguised))
		{
			if (IsPlayerSurvivor(client))
			{
				voiceType = VoiceType_Robot;
				footstepType = FootstepType_Robot;
			}
			else
			{
				voiceType = VoiceType_Human;
				footstepType = FootstepType_Normal;
			}
		}
		
		if (StrContains(sample, "vo/") != -1)
		{
			if (voiceType == VoiceType_Silent || g_bVoiceNoPainSounds[client] && StrContains(sample, "_pain") != -1)
			{
				return Plugin_Stop;
			}
			
			pitch = g_iVoicePitch[client];
			
			if (voiceType == VoiceType_Robot)
			{
				TFClassType class = TF2_GetPlayerClass(client);
				bool noGiantLines; // Some classes don't have these.
				
				if (class == TFClass_Sniper || class == TFClass_Medic || class == TFClass_Engineer || class == TFClass_Spy)
				{
					noGiantLines = true;
				}
				
				char classString[16];
				char newString[32];
				TF2_GetClassString(class, classString, sizeof(classString), true);
				
				if (GetBossType(client) >= 0 && !noGiantLines)
				{
					ReplaceStringEx(sample, sizeof(sample), "vo/", "vo/mvm/mght/");
					FormatEx(newString, sizeof(newString), "%smvm_m_", classString);
				}
				else
				{
					ReplaceStringEx(sample, sizeof(sample), "vo/", "vo/mvm/norm/");
					FormatEx(newString, sizeof(newString), "%smvm_", classString);
				}
				
				ReplaceStringEx(sample, sizeof(sample), classString, newString);
				
				if (!FileExists(sample))
					return Plugin_Stop;
					
				PrecacheSound(sample);
			}

			return Plugin_Changed;
		}
		else if (StrContains(sample, "player/footsteps/") != -1)
		{
			// Giant Robots have a different way of playing their footstep sounds, this way doesn't work too well. See OnPlayerRunCmd().
			if (footstepType == FootstepType_Silent || footstepType == FootstepType_GiantRobot)
			{
				return Plugin_Stop;
			}
			else if (footstepType == FootstepType_Robot)
			{
				if (TF2_GetPlayerClass(client) == TFClass_Medic) // Robot Medics don't have legs. So this wouldn't make much sense.
					return Plugin_Stop;
				
				// For the love of god...
				if (TF2_IsPlayerInConditionEx(client, TFCond_Taunting))
				{
					return Plugin_Continue;
				}
				
				int random = GetRandomInt(1, 18);
				if (random > 9)
				{
					FormatEx(sample, sizeof(sample), "mvm/player/footsteps/robostep_%i.wav", random);
				}
				else
				{
					FormatEx(sample, sizeof(sample), "mvm/player/footsteps/robostep_0%i.wav", random);
				}
				
				if (!PrecacheSound(sample))
					return Plugin_Stop;
				
				// Only works this way for some reason
				EmitSoundToAll(sample, client, channel, level, flags, volume, pitch);
				return Plugin_Stop;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action Timer_GiantFootstep(Handle timer, int client)
{
	g_bGiantFootstepCooldown[client] = false;
	return Plugin_Continue;
}
