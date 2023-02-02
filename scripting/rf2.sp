#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#include <tf2_stocks>
#include <dhooks>

// external dependencies
#include <cbasenpc>
#include <cbasenpc/tf/nav>
#include <tf2attributes>
#include <tf2items>
#include <tf_ontakedamage>
#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.1b"
public Plugin myinfo =
{
	name		=	"Risk Fortress 2",
	author		=	"CookieCat",
	description	=	"TF2 endless roguelike adventure gamemode inspired by hit indie game Risk of Rain 2.",
	version		=	PLUGIN_VERSION,
	url			=	"",
};


// General -------------------------------------------------------------------------------------------------------------------------------------
#define MAXTF2PLAYERS 36
#define MAX_EDICTS 2048
#define MAX_MAP_SIZE 32768.0
#define WAIT_TIME_DEFAULT 100 // Waiting For Players time
#define TF_CLASSES 9+1 // because arrays
#define MAX_TF_CONDITIONS 150

// this is the actual unique damage flag that TF2 uses for melee weapons
#define DMG_MELEE DMG_BLAST_SURFACE

#define WORLD_CENTER "rf2_world_center" // An info_target used to determine where the "center" of the world is, according to the map designer
#define MAX_CONFIG_NAME_LENGTH 64
#define MAX_ATTRIBUTE_STRING_LENGTH 512
#define MAX_DESC_LENGTH 256


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
#define MAT_SPRITE_BEAM "materials/sprites/laser.vmt"


// Sounds -------------------------------------------------------------------------------------------------------------------------------------
#define SOUND_ITEM_PICKUP "ui/item_default_pickup.wav"
#define SOUND_GAME_OVER "music/mvm_lost_wave.wav"
#define SOUND_EVIL_LAUGH "rf2/sfx/evil_laugh.wav"
#define SOUND_LASTMAN "mvm/mvm_warning.wav"
#define SOUND_MONEY_PICKUP "mvm/mvm_money_pickup.wav"
#define SOUND_USE_WORKBENCH "ui/item_metal_scrap_pickup.wav"
#define SOUND_USE_SCRAPPER "ui/item_metal_scrap_drop.wav"
#define SOUND_DROP_DEFAULT "ui/itemcrate_smash_rare.wav"
#define SOUND_DROP_HAUNTED "misc/halloween/spell_skeleton_horde_cast.wav"
#define SOUND_DROP_UNUSUAL "ui/itemcrate_smash_ultrarare_fireworks.wav"
#define SOUND_CASH "mvm/mvm_bought_upgrade.wav"
#define SOUND_NOPE "vo/engineer_no01.mp3"
#define SOUND_MERASMUS_APPEAR "misc/halloween/merasmus_appear.wav"
#define SOUND_MERASMUS_DISAPPEAR "misc/halloween/merasmus_disappear.wav"
#define SOUND_MERASMUS_DANCE1 "vo/halloween_merasmus/sf12_wheel_dance03.mp3"
#define SOUND_MERASMUS_DANCE2 "vo/halloween_merasmus/sf12_wheel_dance04.mp3"
#define SOUND_MERASMUS_DANCE3 "vo/halloween_merasmus/sf12_wheel_dance05.mp3"
#define SOUND_BOSS_SPAWN "mvm/mvm_tank_start.wav"
#define SOUND_SENTRYBUSTER_BOOM "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
#define SOUND_ENEMY_STUN "mvm/mvm_robo_stun.wav"
#define SOUND_TELEPORTER_CHARGED "mvm/mvm_bought_in.wav"
#define SOUND_TANK_SPEED_UP "misc/cp_harbor_red_whistle.wav"
#define SOUND_BELL "misc/halloween/strongman_bell_01.wav"
#define SOUND_SHIELD "weapons/medi_shield_deploy.wav"
#define SOUND_LAW_FIRE "weapons/sentry_rocket.wav"
#define SOUND_LASER "rf2/sfx/laser.mp3"
#define SOUND_MEDISHIELD "weapons/medi_shield_deploy.wav"
#define SOUND_THUNDER "ambient/halloween/thunder_08.wav"
#define SOUND_WEAPON_CRIT "rf2/sfx/crit_clean.mp3"
#define SOUND_BLEED_EXPLOSION "physics/body/body_medium_impact_soft6.wav"
#define SOUND_DEMO_BEAM "rf2/sfx/sword_beam.wav"
#define SOUND_SPELL_FIREBALL "misc/halloween/spell_fireball_cast.wav"
#define SOUND_SPELL_LIGHTNING "misc/halloween/spell_lightning_ball_cast.wav"
#define SOUND_SPELL_METEOR "misc/halloween/spell_meteor_cast.wav"
#define SOUND_SPELL_BATS "misc/halloween/spell_bat_cast.wav"
#define SOUND_SPELL_OVERHEAL "misc/halloween/spell_overheal.wav"
#define SOUND_SPELL_JUMP "misc/halloween/spell_blast_jump.wav"
#define SOUND_SPELL_STEALTH "misc/halloween/spell_stealth.wav"
#define SOUND_SPELL_TELEPORT "misc/halloween/spell_teleport.wav"

// Script sounds
#define SCSOUND_CRIT "TFPlayer.CritHit"
#define SCSOUND_MINICRIT "TFPlayer.CritHitMini"


// Particles -------------------------------------------------------------------------------------------------------------------------------------
#define PARTICLE_NORMAL_CRATE_OPEN "mvm_loot_explosion"
#define PARTICLE_HAUNTED_CRATE_OPEN "ghost_appearation"
#define PARTICLE_UNUSUAL_CRATE_OPEN "mvm_pow_gold_seq"


// Players ---------------------------------------------------------------------------------------------------------------------------------------
#define PLAYER_MINS {-24.0, -24.0, 0.0}
#define PLAYER_MAXS {24.0, 24.0, 82.0}

// "mod see enemy health"
#define BASE_PLAYER_ATTRIBUTES "269 = 1"


// TFBots -------------------------------------------------------------------------------------------------------------------------------------
enum
{
	TFBotDifficulty_Easy,
	TFBotDifficulty_Normal,
	TFBotDifficulty_Hard,
	TFBotDifficulty_Expert,
};


// Enemies/Bosses -------------------------------------------------------------------------------------------------------------------------------------
#define MAX_ENEMIES 128
#define MAX_WEARABLES 6
#define MAX_BOSSES 32
#define BOSS_BASE_BACKSTAB_DAMAGE 750.0

// "mod see enemy health", "damage force reduction", "airblast vulnerability multiplier", "increased jump height", "cancel falling damage"
#define BASE_BOSS_ATTRIBUTES "269 = 1 ; 252 = 0.2 ; 329 = 0.2 ; 326 = 1.35 ; 275 = 1"

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
#define MAX_ATTRIBUTES 16
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
#define MAX_ITEMS 64
#define MAX_ITEM_MODIFIERS 8

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
#define EF_ITEM_BLINK 0x100
#define OFF_THE_MAP {-16384.0, -16384.0, -16384.0}

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

// Doesn't block player movement, but still allowed to be hit by player weapons
#define COLLISION_GROUP_CRATE COLLISION_GROUP_PROJECTILE

enum // ParticleAttachment_t
{
    PATTACH_INVALID = -1,            // Not in original, indicates invalid initial value
    PATTACH_ABSORIGIN = 0,            // Create at absorigin, but don't follow
    PATTACH_ABSORIGIN_FOLLOW,        // Create at absorigin, and update to follow the entity
    PATTACH_CUSTOMORIGIN,            // Create at a custom origin, but don't follow
    PATTACH_POINT,                    // Create on attachment point, but don't follow
    PATTACH_POINT_FOLLOW,            // Create on attachment point, and update to follow the entity
    PATTACH_WORLDORIGIN,            // Used for control points that don't attach to an entity
    PATTACH_ROOTBONE_FOLLOW,        // Create at the root bone of the entity, and update to follow
};

enum // gamerules_roundstate_t
{
    // initialize the game, create teams
    GR_STATE_INIT = 0,

    //Before players have joined the game. Periodically checks to see if enough players are ready
    //to start a game. Also reverts to this when there are no active players
    GR_STATE_PREGAME,

    //The game is about to start, wait a bit and spawn everyone
    GR_STATE_STARTGAME,

    //All players are respawned, frozen in place
    GR_STATE_PREROUND,

    //Round is on, playing normally
    GR_STATE_RND_RUNNING,

    //Someone has won the round
    GR_STATE_TEAM_WIN,

    //Noone has won, manually restart the game, reset scores
    GR_STATE_RESTART,

    //Noone has won, restart the game
    GR_STATE_STALEMATE,

    //Game is over, showing the scoreboard etc
    GR_STATE_GAME_OVER,

    //Game is in a bonus state, transitioned to after a round ends
    GR_STATE_BONUS,

    //Game is awaiting the next wave/round of a multi round experience
    GR_STATE_BETWEEN_RNDS,

    GR_NUM_ROUND_STATES
};

#include <rf2>

// General
bool g_bPluginEnabled;
bool g_bLateLoad;
bool g_bGameInitialized;
bool g_bWaitingForPlayers;
bool g_bRoundActive;
bool g_bGracePeriod;
bool g_bGameOver;
bool g_bMapChanging;
bool g_bConVarsModified;
bool g_bPluginReloading;
bool g_bTankBossMode;

int g_iTotalEnemiesKilled;
int g_iTotalBossesKilled;
int g_iTotalTanksKilled;
int g_iTotalItemsFound;
int g_iTanksKilledObjective;
int g_iTankKillRequirement;
int g_iTanksSpawned;
int g_iMapFog = -1;
int g_iWorldCenterEntity = -1;

// Difficulty
float g_flSecondsPassed;
float g_flDifficultyCoeff;

int g_iMinutesPassed;
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
// g_flPlayerNextLevelXP[i], g_flPlayerCash[i], g_iPlayerHauntedKeys[i], g_szHudDifficulty, strangeItemInfo, g_szObjectiveHud[i]
char g_szSurvivorHudText[2048] = "\n\nStage %i | %02d:%02d\nEnemy Level: %i | Your Level: %i\n%.0f/%.0f XP | Cash: $%.0f | Haunted Keys: %i\n%s\n%s\n%s";

// g_iStagesCompleted+1, g_iMinutesPassed, hudSeconds, g_iEnemyLevel, g_szHudDifficulty, strangeItemInfo
char g_szEnemyHudText[1024] = "\n\nStage %i | %02d:%02d\nEnemy Level: %i\n%s\n%s";

// Players
bool g_bPlayerInGame[MAXTF2PLAYERS]; // Check IsClientInGameEx() instead of checking IsClientInGame().
bool g_bPlayerInCondition[MAXTF2PLAYERS][MAX_TF_CONDITIONS]; // Check TF2_IsPlayerInConditionEx() over TF2_IsPlayerInCondition().
bool g_bPlayerFakeClient[MAXTF2PLAYERS]; // Check IsFakeClientEx() instead of checking IsFakeClient().
bool g_bPlayerViewingItemMenu[MAXTF2PLAYERS];
bool g_bPlayerIsTeleporterBoss[MAXTF2PLAYERS];
bool g_bPlayerVoiceNoPainSounds[MAXTF2PLAYERS];
bool g_bPlayerStunnable[MAXTF2PLAYERS] = { true, ... };
bool g_bPlayerIsAFK[MAXTF2PLAYERS];
bool g_bPlayerExtraSentryHint[MAXTF2PLAYERS];

float g_flPlayerXP[MAXTF2PLAYERS];
float g_flPlayerNextLevelXP[MAXTF2PLAYERS] = {100.0, ...};
float g_flPlayerCash[MAXTF2PLAYERS];
float g_flPlayerMaxSpeed[MAXTF2PLAYERS] = {300.0, ...};
float g_flPlayerCalculatedMaxSpeed[MAXTF2PLAYERS] = {300.0, ...};
float g_flPlayerHealthRegenTime[MAXTF2PLAYERS];
float g_flPlayerNextMetalRegen[MAXTF2PLAYERS];
float g_flPlayerEquipmentItemCooldown[MAXTF2PLAYERS];
float g_flPlayerGiantFootstepInterval[MAXTF2PLAYERS] = {0.5, ...};
float g_flPlayerAFKTime[MAXTF2PLAYERS];

int g_iPlayerLevel[MAXTF2PLAYERS] = {1, ...};
int g_iPlayerHauntedKeys[MAXTF2PLAYERS];
int g_iPlayerStatWearable[MAXTF2PLAYERS] = {-1, ...}; // Wearable entity used to store specific attributes on player
int g_iPlayerBaseHealth[MAXTF2PLAYERS] = {1, ...};
int g_iPlayerCalculatedMaxHealth[MAXTF2PLAYERS] = {1, ...};
int g_iPlayerSurvivorIndex[MAXTF2PLAYERS] = {-1, ...};
int g_iPlayerEquipmentItemCharges[MAXTF2PLAYERS] = {1, ...};
int g_iPlayerEnemyType[MAXTF2PLAYERS] = {-1, ...};
int g_iPlayerBossType[MAXTF2PLAYERS] = {-1, ...};
int g_iPlayerVoiceType[MAXTF2PLAYERS];
int g_iPlayerVoicePitch[MAXTF2PLAYERS] = {SNDPITCH_NORMAL, ...};
int g_iPlayerFootstepType[MAXTF2PLAYERS] = {FootstepType_Normal, ...};
int g_iPlayerFireRateStacks[MAXTF2PLAYERS];
int g_iPlayerAirDashCounter[MAXTF2PLAYERS];
int g_iPlayerLastAttackedTank[MAXTF2PLAYERS] = {-1, ...};
int g_iItemsTaken[MAX_SURVIVORS];
int g_iItemLimit[MAX_SURVIVORS];

char g_szPlayerOriginalName[MAXTF2PLAYERS][MAX_NAME_LENGTH];
ArrayList g_hPlayerExtraSentryList[MAXTF2PLAYERS];
ArrayList g_hCachedPlayerSounds;
ArrayList g_hInvalidPlayerSounds;

// Entities
int g_iItemDamageProc[MAX_EDICTS];
int g_iCashBombSize[MAX_EDICTS];

bool g_bDontDamageOwner[MAX_EDICTS];
bool g_bPyromancerFireball[MAX_EDICTS];
bool g_bCashBomb[MAX_EDICTS];
bool g_bFiredWhileRocketJumping[MAX_EDICTS];
bool g_bDontRemoveWearable[MAX_EDICTS];
bool g_bItemWearable[MAX_EDICTS];

float g_flProjectileForcedDamage[MAX_EDICTS];
float g_flSentryNextLaserTime[MAX_EDICTS];
float g_flCashBombAmount[MAX_EDICTS];
float g_flCashValue[MAX_EDICTS];

// Timers
Handle g_hPlayerTimer;
Handle g_hHudTimer;
Handle g_hDifficultyTimer;

// Gamedata handles
Handle g_hSDKEquipWearable;
Handle g_hSDKGetMaxClip1;
Handle g_hSDKDoQuickBuild;
Handle g_hSDKComputeIncursion;
DHookSetup g_hSDKCanBuild;
DHookSetup g_hSDKComputeIncursionHook;
DHookSetup g_hSDKDoSwingTrace;
DHookSetup g_hSDKSentryAttack;
DynamicHook g_hSDKTakeHealthHook;
DynamicHook g_hSDKStartUpgrading;

// Forwards
Handle g_fwTeleEventStart;
Handle g_fwTeleEventEnd;
Handle g_fwGracePeriodStart;
Handle g_fwGracePeriodEnded;

// ConVars
ConVar g_cvAlwaysSkipWait;
ConVar g_cvDebugNoMapChange;
ConVar g_cvDebugShowDifficultyCoeff;
ConVar g_cvDebugDontEndGame;
ConVar g_cvEnableAFKManager;
ConVar g_cvAFKManagerKickTime;
ConVar g_cvAFKLimit;
ConVar g_cvAFKKickAdmins;
ConVar g_cvAFKMinHumans;
ConVar g_cvBotsCanBeSurvivor;
ConVar g_cvBotWanderRecomputeDist;
ConVar g_cvBotWanderTime;
ConVar g_cvBotWanderMaxDist;
ConVar g_cvBotWanderMinDist;
ConVar g_cvSubDifficultyIncrement;
ConVar g_cvDifficultyScaleMultiplier;
ConVar g_cvDebugShowObjectSpawns;
ConVar g_cvMaxObjects;
ConVar g_cvCashBurnTime;
ConVar g_cvSurvivorHealthScale;
ConVar g_cvSurvivorDamageScale;
ConVar g_cvSurvivorBaseXpRequirement;
ConVar g_cvSurvivorXpRequirementScale;
ConVar g_cvEnemyHealthScale;
ConVar g_cvEnemyDamageScale;
ConVar g_cvEnemyXPDropScale;
ConVar g_cvEnemyCashDropScale;
ConVar g_cvEnemyMinSpawnDistance;
ConVar g_cvEnemyMaxSpawnDistance;
ConVar g_cvEnemyMaxSpawnWaveCount;
ConVar g_cvEnemyMinSpawnWaveTime;
ConVar g_cvEnemyBaseSpawnWaveTime;
ConVar g_cvBossStabDamageType;
ConVar g_cvBossStabDamagePercent;
ConVar g_cvBossStabDamageAmount;
ConVar g_cvTeleporterRadiusMultiplier;
ConVar g_cvObjectSpreadDistance;
ConVar g_cvObjectBaseCost;
ConVar g_cvObjectBaseCount;
ConVar g_cvObjectSpecialChance;
ConVar g_cvItemShareEnabled;
ConVar g_cvTankBaseHealth;
ConVar g_cvTankHealthScale;
ConVar g_cvTankBaseSpeed;
ConVar g_cvTankSpeedBoost;
ConVar g_cvTankBoostHealth;
ConVar g_cvTankBoostDifficulty;
ConVar g_cvSurvivorQuickBuild;
ConVar g_cvEnemyQuickBuild;
ConVar g_cvMeleeCritChanceBonus;
ConVar g_cvEngiMetalRegenInterval;
ConVar g_cvEngiMetalRegenAmount;
ConVar g_cvHauntedKeyDropChanceMax;

// Cookies
Cookie g_coMusicEnabled;
Cookie g_coBecomeSurvivor;
Cookie g_coBecomeBoss;
Cookie g_coAutomaticItemMenu;
Cookie g_coSurvivorPoints;

bool g_bPlayerMusicEnabled[MAXTF2PLAYERS] = {true, ...};
bool g_bPlayerBecomeSurvivor[MAXTF2PLAYERS] = {true, ...};
bool g_bPlayerBecomeBoss[MAXTF2PLAYERS] = {true, ...};
bool g_bPlayerAutomaticItemMenu[MAXTF2PLAYERS] = {true, ...};
int g_iPlayerSurvivorPoints[MAXTF2PLAYERS];

// TFBots
TFBot g_TFBot[MAXTF2PLAYERS];

#define TFBOTFLAG_AGGRESSIVE (1 << 0)
#define TFBOTFLAG_ROCKETJUMP (1 << 1)
#define TFBOTFLAG_STRAFING (1 << 2)

// Other
bool g_bThrillerActive;
int g_iThrillerRepeatCount;
ArrayList g_hParticleEffectTable;

#include "rf2/items.sp"
#include "rf2/survivors.sp"
#include "rf2/entityfactory.sp"
#include "rf2/objects.sp"
#include "rf2/cookies.sp"
#include "rf2/bosses.sp"
#include "rf2/enemies.sp"
#include "rf2/stages.sp"
#include "rf2/weapons.sp"
#include "rf2/functions/general.sp"
#include "rf2/functions/clients.sp"
#include "rf2/functions/entities.sp"
#include "rf2/functions/buildings.sp"
#include "rf2/natives_forwards.sp"
#include "rf2/commands_convars.sp"
#include "rf2/npc/nav.sp"
#include "rf2/npc/tf_bot.sp"
#include "rf2/npc/npc_tank_boss.sp"
#include "rf2/npc/npc_sentry_buster.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		strcopy(error, err_max, "This plugin was developed for use with Team Fortress 2 only");
		return APLRes_Failure;
	}
	
	g_bLateLoad = late;
	LoadNatives();
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadGameData();
	LoadForwards();
	LoadCommandsAndCvars();
	BakeCookies();
	LoadTranslations("common.phrases");
}

public void OnPluginEnd()
{
	if (RF2_IsEnabled())
		StopMusicTrackAll();
	
	for (int i = 0; i < MAXTF2PLAYERS; i++)
	{
		if (g_TFBot[i].Follower)
		{
			g_TFBot[i].Follower.Destroy();
		}
		
		if (RF2_IsEnabled() && IsValidClient(i))
		{
			ChangeClientTeam(i, TEAM_ENEMY);
			SetClientName(i, g_szPlayerOriginalName[i]);
		}
	}
	
	if (!g_bPluginReloading)
	{
		LogError("Unexpected unload detected! Please use the rf2_reload or rf2_fullreload commands to reload the plugin properly!");
	}
}

void LoadGameData()
{
	GameData gamedata = LoadGameConfigFile("rf2");
	if (!gamedata)
	{
		SetFailState("[SDK] Failed to locate gamedata file \"rf2.txt\"");
	}
	
	// CBasePlayer::EquipWearable --------------------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKEquipWearable = EndPrepSDKCall();
	if(!g_hSDKEquipWearable)
	{
		SetFailState("[SDK] Failed to create call for CBasePlayer::EquipWearable"); // We need this pretty badly
	}
	
	// CTFWeaponBase::GetMaxClip1 --------------------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFWeaponBase::GetMaxClip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMaxClip1 = EndPrepSDKCall();
	if (!g_hSDKGetMaxClip1)
	{
		LogError("[SDK] Failed to create call for CTFWeaponBase::GetMaxClip1");
	}
	
	// CBaseObject::DoQuickBuild ---------------------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseObject::DoQuickBuild");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	g_hSDKDoQuickBuild = EndPrepSDKCall();
	if (!g_hSDKDoQuickBuild)
	{
		LogError("[SDK] Failed to create call for CBaseObject::DoQuickBuild");
	}
	
	// CBaseEntity::TakeHealth -----------------------------------------------------------------------------
	int offset = GameConfGetOffset(gamedata, "CBaseEntity::TakeHealth");
	
	g_hSDKTakeHealthHook = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, DHook_TakeHealth);
	if (!g_hSDKTakeHealthHook)
	{
		LogError("[DHooks] Failed to create virtual hook for CBaseEntity::TakeHealth");
	}
	else
	{
		DHookAddParam(g_hSDKTakeHealthHook, HookParamType_Float);
		DHookAddParam(g_hSDKTakeHealthHook, HookParamType_Int);
	}
	
	// CTFPlayer::CanBuild --------------------------------------------------------------------------------
	g_hSDKCanBuild = DHookCreateFromConf(gamedata, "CTFPlayer::CanBuild");
	if (!g_hSDKCanBuild || !DHookEnableDetour(g_hSDKCanBuild, true, DHook_CanBuild))
	{
		LogError("[DHooks] Failed to create detour for CTFPlayer::CanBuild");
	}

	// CBaseObject::StartUpgrading -------------------------------------------------------------------------
	offset = GameConfGetOffset(gamedata, "CBaseObject::StartUpgrading");
	g_hSDKStartUpgrading = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	if (!g_hSDKStartUpgrading)
	{
		LogError("[DHooks] Failed to create virtual hook for CBaseObject::StartUpgrading");
	}
	
	// CTFNavMesh::ComputeIncursionDistances ---------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFNavMesh::ComputeIncursionDistances");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKComputeIncursion = EndPrepSDKCall();
	if (!g_hSDKComputeIncursion)
	{
		LogError("[SDK] Failed to create call for CTFNavMesh::ComputeIncursionDistances");
	}
	
	g_hSDKComputeIncursionHook = DHookCreateFromConf(gamedata, "CTFNavMesh::ComputeIncursionDistances");
	if (!g_hSDKComputeIncursionHook || !DHookEnableDetour(g_hSDKComputeIncursionHook, false, DHook_ComputeIncursionDistances))
	{
		LogError("[DHooks] Failed to create detour for CTFNavMesh::ComputeIncursionDistances");
	}
	
	// CTFWeaponBaseMelee::DoSwingTraceInternal ------------------------------------------------------------
	g_hSDKDoSwingTrace = DHookCreateFromConf(gamedata, "CTFWeaponBaseMelee::DoSwingTraceInternal");
	if (!g_hSDKDoSwingTrace || !DHookEnableDetour(g_hSDKDoSwingTrace, false, DHook_DoSwingTrace) || !DHookEnableDetour(g_hSDKDoSwingTrace, true, DHook_DoSwingTracePost))
	{
		LogError("[DHooks] Failed to create detour for CTFWeaponBaseMelee::DoSwingTraceInternal");
	}
	
	// CObjectSentrygun::Attack ----------------------------------------------------------------------------
	g_hSDKSentryAttack = DHookCreateFromConf(gamedata, "CObjectSentrygun::Attack");
	if (!g_hSDKSentryAttack || !DHookEnableDetour(g_hSDKSentryAttack, true, DHook_SentryGunAttack))
	{
		LogError("[DHooks] Failed to create detour for CObjectSentrygun::Attack");
	}
	
	delete gamedata;
}

public void OnMapStart()
{
	// This was a reload map change
	if (g_bPluginReloading)
	{
		InsertServerCommand("sm plugins reload rf2");
		return;
	}
	
	g_bMapChanging = false;
	float engineTime = GetEngineTime();
	char mapName[256], buffer[8];

	GetCurrentMap(mapName, sizeof(mapName));
	SplitString(mapName, "_", buffer, sizeof(buffer));
	
	if (strcmp2(buffer, "rf2", false))
	{
		g_bPluginEnabled = true;
		g_bWaitingForPlayers = bool(GameRules_GetProp("m_bInWaitingForPlayers"));
		
		if (g_bLateLoad)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientConnected(i))
				{
					OnClientConnected(i);
					OnClientCookiesCached(i);
				}
				
				if (IsClientInGame(i))
				{
					OnClientPutInServer(i);
				}
			}
		}
		
		if (GetMaxHumanPlayers() < 32)
		{
			LogMessage("This server has only %i maxplayers. 32 maxplayers is recommended for Risk Fortress 2.", GetMaxHumanPlayers());
		}
		
		if (!TheNavMesh.IsLoaded())
		{
			SetFailState("[NAV] The NavMesh for map \"%s\" does not exist", mapName);
		}
		
		LoadAssets();
		
		static bool entsInstalled;
		if (!entsInstalled)
		{
			InstallEntities();
			entsInstalled = true;
		}
		
		if (!g_bLateLoad)
		{
			AutoExecConfig(true, "RiskFortress2");
		}
		
		// These are ConVars we're OK with being set by server.cfg, but we'll set our personal defaults.
		// If configs wish to change these, they will be overridden by them later.
		FindConVar("sv_alltalk").SetBool(true);
		FindConVar("tf_use_fixed_weaponspreads").SetBool(true);
		FindConVar("tf_avoidteammates_pushaway").SetBool(false);
		
		// Why is this a development only ConVar Valve?
		ConVar waitTime = FindConVar("mp_waitingforplayers_time");
		waitTime.Flags &= ~FCVAR_DEVELOPMENTONLY;
		waitTime.SetInt(WAIT_TIME_DEFAULT);
		
		// Round events
		HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_Pre);
		HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Post);
		
		// Player events
		HookEvent("post_inventory_application", OnPostInventoryApplication, EventHookMode_Post);
		HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
		HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Post);
		HookEvent("player_chargedeployed", OnPlayerChargeDeployed, EventHookMode_Post);
		HookEvent("player_dropobject", OnPlayerDropObject, EventHookMode_Post);
		HookEvent("player_builtobject", OnPlayerBuiltObject, EventHookMode_Post);
		HookEvent("player_team", OnChangeTeamMessage, EventHookMode_Pre);
		
		// Command listeners
		AddCommandListener(OnVoiceCommand, "voicemenu");
		AddCommandListener(OnChangeClass, "joinclass");
		AddCommandListener(OnChangeTeam, "autoteam");
		AddCommandListener(OnChangeTeam, "jointeam");
		AddCommandListener(OnChangeTeam, "spectate");
		AddCommandListener(OnSuicide, "kill");
		AddCommandListener(OnSuicide, "explode");
		AddCommandListener(OnChangeSpec, "spec_next");
		AddCommandListener(OnChangeSpec, "spec_prev");
		AddCommandListener(OnBuildCommand, "build");
		
		// Entity output hooks
		HookEntityOutput("tank_boss", "OnKilled", Output_OnTankKilled);
		
		// UserMessage hooks
		HookUserMessage(GetUserMessageId("SayText2"), UserMessageHook_SayText2, true);
		
		// NormalSound hooks
		AddNormalSoundHook(PlayerSoundHook);
		
		// TE hooks
		AddTempEntHook("TFBlood", TEHook_TFBlood);
		
		// Everything else
		g_hMainHudSync = CreateHudSynchronizer();
		g_hCachedPlayerSounds = CreateArray(PLATFORM_MAX_PATH);
		g_hInvalidPlayerSounds = CreateArray(PLATFORM_MAX_PATH);
		g_hParticleEffectTable = CreateArray(128);
		
		SentryBuster_OnMapStart();
		
		g_iMaxStages = FindMaxStages();
		LoadMapSettings(mapName);
		LoadItems();
		LoadWeapons();
		LoadSurvivorStats();
		
		SDK_ComputeIncursionDistances();
		
		CreateTimer(1.0, Timer_AFKManager, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(60.0, Timer_PluginMessage, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		if (g_bLateLoad)
		{
			DespawnObjects();
		}
		
		// Find map spawned objects
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "*")) != -1)
		{
			if (entity <= MaxClients)
				continue;
			
			if (IsObject(entity))
			{
				SetEntProp(entity, Prop_Data, "m_bMapPlaced", true);
			}
		}
		
		g_iMapFog = FindEntityByClassname(-1, "env_fog_controller");
		if (IsValidEntity(g_iMapFog))
		{
			g_iMapFog = EntIndexToEntRef(g_iMapFog);
		}
	}
	else
	{
		g_bPluginEnabled = false;
		LogMessage("The current map (%s) isn't an RF2-compatible map. RF2 will be disabled. Prefix your map's name with \"rf2_\" if this is in error.", mapName);
	}
	
	LogMessage("Time taken to load: %f seconds", GetEngineTime()-engineTime);
}

public void OnConfigsExecuted()
{
	if (RF2_IsEnabled() && !g_bPluginReloading)
	{
		if (!FindConVar("sm_tf2_maxspeed"))
		{
			LogMessage("TF2 Move Speed Unlocker plugin not found. It is not required, but is recommended to install.");
		}
		
		// Here are ConVars that we don't want changed by configs
		FindConVar("mp_teams_unbalance_limit").SetInt(0);
		FindConVar("mp_forcecamera").SetBool(false);
		FindConVar("mp_maxrounds").SetInt(9999);
		FindConVar("mp_forceautoteam").SetBool(true);
		FindConVar("tf_dropped_weapon_lifetime").SetInt(0);
		FindConVar("tf_weapon_criticals").SetBool(false);
		FindConVar("tf_forced_holiday").SetInt(2);
		FindConVar("tf_player_movement_restart_freeze").SetBool(false);
		
		// TFBots
		FindConVar("tf_bot_defense_must_defend_time").SetInt(-1);
		FindConVar("tf_bot_offense_must_push_time").SetInt(-1);
		FindConVar("tf_bot_taunt_victim_chance").SetInt(0);
		FindConVar("tf_bot_quota_mode").SetString("fill");
		FindConVar("tf_bot_quota").SetInt(GetMaxHumanPlayers()-1);
		FindConVar("tf_bot_join_after_player").SetBool(true);
		
		ConVar botConsiderClass = FindConVar("tf_bot_reevaluate_class_in_spawnroom");
		botConsiderClass.Flags = botConsiderClass.Flags & ~FCVAR_CHEAT;
		botConsiderClass.SetBool(false);
		
		char team[8];
		switch (TEAM_ENEMY)
		{
			case view_as<int>(TFTeam_Blue):	team = "blue";
			case view_as<int>(TFTeam_Red):	team = "red";
		}
		
		FindConVar("mp_humans_must_join_team").SetString(team);
		
		g_bConVarsModified = true;
	}
}

public void OnMapEnd()
{
	// Reset our ConVars if we've changed them
	if (g_bConVarsModified)
		ResetConVars();
		
	g_bMapChanging = true;

	if (RF2_IsEnabled())
	{
		if (g_bGameOver)
		{
			ReloadPlugin(false);
			return;
		}
		else
		{
			g_iStagesCompleted++;
		}
		
		CleanUp();
	}
}

void CleanUp()
{
	UnhookEvent("teamplay_round_start", OnRoundStart, EventHookMode_Pre);
	UnhookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Post);
	UnhookEvent("post_inventory_application", OnPostInventoryApplication, EventHookMode_Post);
	UnhookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	UnhookEvent("player_hurt", OnPlayerHurt, EventHookMode_Post);
	UnhookEvent("player_chargedeployed", OnPlayerChargeDeployed, EventHookMode_Post);
	UnhookEvent("player_dropobject", OnPlayerDropObject, EventHookMode_Post);
	UnhookEvent("player_builtobject", OnPlayerBuiltObject, EventHookMode_Post);
	UnhookEvent("player_team", OnChangeTeamMessage, EventHookMode_Pre);
	
	RemoveCommandListener(OnVoiceCommand, "voicemenu");
	RemoveCommandListener(OnChangeClass, "joinclass");
	RemoveCommandListener(OnChangeTeam, "jointeam");
	RemoveCommandListener(OnChangeTeam, "autoteam");
	RemoveCommandListener(OnChangeTeam, "spectate");
	RemoveCommandListener(OnSuicide, "kill");
	RemoveCommandListener(OnSuicide, "explode");
	RemoveCommandListener(OnChangeSpec, "spec_next");
	RemoveCommandListener(OnChangeSpec, "spec_prev");
	RemoveCommandListener(OnBuildCommand, "build");
	
	UnhookEntityOutput("tank_boss", "OnKilled", Output_OnTankKilled);
	
	UnhookUserMessage(GetUserMessageId("SayText2"), UserMessageHook_SayText2, true);
	
	RemoveNormalSoundHook(PlayerSoundHook);
	
	RemoveTempEntHook("TFBlood", TEHook_TFBlood);
	
	g_bRoundActive = false;
	g_bGracePeriod = false;
	g_bWaitingForPlayers = false;
	g_hPlayerTimer = null;
	g_hHudTimer = null;
	g_hDifficultyTimer = null;
	g_iRF2GameRulesEntRef = -1;
	g_iRespawnWavesCompleted = 0;
	g_iSentryKillCounter = 0;
	g_szEnemyPackName = "";
	g_szBossPackName = "";
	g_iTeleporterEntRef = -1;
	g_iMapFog = -1;
	g_iWorldCenterEntity = -1;
	g_bTankBossMode = false;
	g_iTanksKilledObjective = 0;
	g_iTankKillRequirement = 0;
	g_iTanksSpawned = 0;
	g_bThrillerActive = false;
	g_iThrillerRepeatCount = 0;
	
	delete g_hMainHudSync;
	delete g_hCachedPlayerSounds;
	delete g_hInvalidPlayerSounds;
	delete g_hParticleEffectTable;
	
	StopMusicTrackAll();
	
	for (int i = 1; i < MAXTF2PLAYERS; i++)
	{
		RefreshClient(i);
		ResetAFKTime(i);
	}
}

void LoadAssets()
{
	PrecacheFactoryAssets();
	
	// Models
	PrecacheModel(MODEL_ERROR);
	PrecacheModel(MODEL_INVISIBLE);
	PrecacheModel(MODEL_CASH_BOMB);
	PrecacheModel(MODEL_MERASMUS);
	g_iBeamModel = PrecacheModel(MAT_SPRITE_BEAM);
	
	// Sounds
	PrecacheSound(SOUND_ITEM_PICKUP);
	PrecacheSound(SOUND_GAME_OVER);
	PrecacheSound(SOUND_EVIL_LAUGH);
	PrecacheSound(SOUND_LASTMAN);
	PrecacheSound(SOUND_MONEY_PICKUP);
	PrecacheSound(SOUND_USE_WORKBENCH);
	PrecacheSound(SOUND_USE_SCRAPPER);
	PrecacheSound(SOUND_DROP_DEFAULT);
	PrecacheSound(SOUND_DROP_HAUNTED);
	PrecacheSound(SOUND_DROP_UNUSUAL);
	PrecacheSound(SOUND_CASH);
	PrecacheSound(SOUND_NOPE);
	PrecacheSound(SOUND_MERASMUS_APPEAR);
	PrecacheSound(SOUND_MERASMUS_DISAPPEAR);
	PrecacheSound(SOUND_MERASMUS_DANCE1);
	PrecacheSound(SOUND_MERASMUS_DANCE2);
	PrecacheSound(SOUND_MERASMUS_DANCE3);
	PrecacheSound(SOUND_BOSS_SPAWN);
	PrecacheSound(SOUND_SENTRYBUSTER_BOOM);
	PrecacheSound(SOUND_ENEMY_STUN);
	PrecacheSound(SOUND_TELEPORTER_CHARGED);
	PrecacheSound(SOUND_TANK_SPEED_UP);
	PrecacheSound(SOUND_BELL);
	PrecacheSound(SOUND_SHIELD);
	PrecacheSound(SOUND_LAW_FIRE);
	PrecacheSound(SOUND_LASER);
	PrecacheSound(SOUND_THUNDER);
	PrecacheSound(SOUND_WEAPON_CRIT);
	PrecacheSound(SOUND_BLEED_EXPLOSION);
	PrecacheSound(SOUND_DEMO_BEAM);
	PrecacheSound(SOUND_SPELL_FIREBALL);
	PrecacheSound(SOUND_SPELL_TELEPORT);
	PrecacheSound(SOUND_SPELL_BATS);
	PrecacheSound(SOUND_SPELL_LIGHTNING);
	PrecacheSound(SOUND_SPELL_METEOR);
	PrecacheSound(SOUND_SPELL_OVERHEAL);
	PrecacheSound(SOUND_SPELL_JUMP);
	PrecacheSound(SOUND_SPELL_STEALTH);
	
	PrecacheScriptSound(SCSOUND_CRIT);
	PrecacheScriptSound(SCSOUND_MINICRIT);
	
	AddSoundToDownloadsTable(SOUND_LASER);
	AddSoundToDownloadsTable(SOUND_WEAPON_CRIT);
}

void ResetConVars()
{
	ResetConVar(FindConVar("sv_alltalk"));
	ResetConVar(FindConVar("tf_use_fixed_weaponspreads"));
	ResetConVar(FindConVar("tf_avoidteammates_pushaway"));
	ResetConVar(FindConVar("mp_waitingforplayers_time"));
	
	ResetConVar(FindConVar("mp_teams_unbalance_limit"));
	ResetConVar(FindConVar("mp_forcecamera"));
	ResetConVar(FindConVar("mp_maxrounds"));
	ResetConVar(FindConVar("mp_forceautoteam"));
	ResetConVar(FindConVar("tf_dropped_weapon_lifetime"));
	ResetConVar(FindConVar("tf_weapon_criticals"));
	ResetConVar(FindConVar("tf_forced_holiday"));
	ResetConVar(FindConVar("tf_player_movement_restart_freeze"));

	ResetConVar(FindConVar("tf_bot_defense_must_defend_time"));
	ResetConVar(FindConVar("tf_bot_offense_must_push_time"));
	ResetConVar(FindConVar("tf_bot_taunt_victim_chance"));
	ResetConVar(FindConVar("tf_bot_quota_mode"));
	ResetConVar(FindConVar("tf_bot_quota"));
	ResetConVar(FindConVar("tf_bot_join_after_player"));
	ResetConVar(FindConVar("tf_bot_reevaluate_class_in_spawnroom"));
}

public void OnClientConnected(int client)
{
	g_bPlayerFakeClient[client] = IsFakeClient(client);
}

public void OnClientPutInServer(int client)
{
	g_bPlayerInGame[client] = true;
	GetClientName(client, g_szPlayerOriginalName[client], sizeof(g_szPlayerOriginalName[]));
	
	if (IsFakeClientEx(client))
	{
		g_TFBot[client] = new TFBot(client);
		g_TFBot[client].Follower = PathFollower(_, Path_FilterIgnoreObjects, Path_FilterOnlyActors);
	}
	
	if (RF2_IsEnabled())
	{
		if (!IsFakeClientEx(client) && g_bRoundActive)
		{
			PlayMusicTrack(client);
		}
		
		SDKHook(client, SDKHook_PreThink, Hook_PreThink);
		SDKHook(client, SDKHook_WeaponSwitch, Hook_WeaponSwitch);
		
		if (g_hSDKTakeHealthHook)
		{
			DHookEntity(g_hSDKTakeHealthHook, false, client);
		}
		
		g_hPlayerExtraSentryList[client] = CreateArray();
	}
}

public void OnClientDisconnect(int client)
{
	if (!RF2_IsEnabled())
		return;
	
	StopMusicTrack(client);
	
	if (!IsFakeClientEx(client))
	{
		SaveClientCookies(client);
	}
	
	if (!g_bWaitingForPlayers && !g_bGameOver && g_bGameInitialized && !g_bMapChanging && !IsFakeClientEx(client) && !IsStageCleared())
	{
		int humanCount = GetTotalHumans(false)-1; // minus ourselves
		
		if (humanCount == 0 && !g_bPluginReloading) // Everybody left. Time to start over!
		{
			PrintToServer("[RF2] All human players have disconnected from the server. Restarting the game...");
			ReloadPlugin(true);
			return;
		}
	}
	
	if (IsPlayerSurvivor(client))
	{
		SaveSurvivorInventory(client, RF2_GetSurvivorIndex(client));
		
		// We need to deal with survivors who disconnect during the grace period.
		if (g_bGracePeriod)
		{
			ReshuffleSurvivor(client, -1);
		}
	}
}

public void OnClientDisconnect_Post(int client)
{
	g_bPlayerInGame[client] = false;
	g_bPlayerFakeClient[client] = false;
	g_flLoopMusicAt[client] = -1.0;
	
	if (g_hPlayerExtraSentryList[client])
		delete g_hPlayerExtraSentryList[client];
	
	if (g_TFBot[client].Follower)
	{
		g_TFBot[client].Follower.Destroy();
		g_TFBot[client].Follower = view_as<PathFollower>(0);
	}
	
	g_TFBot[client] = null;
	RefreshClient(client);
}

void ReshuffleSurvivor(int client, int teamChange=TEAM_ENEMY)
{
	if (IsClientInGameEx(client) && teamChange >= 0)
	{
		ChangeClientTeam(client, teamChange);
	}
	
	bool allowBots = g_cvBotsCanBeSurvivor.BoolValue;
	int points[MAXTF2PLAYERS];
	int playerPoints[MAXTF2PLAYERS];
	bool valid[MAXTF2PLAYERS];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client || !IsClientInGameEx(i) || IsPlayerSurvivor(i))
			continue;
		
		// If we are allowing bots, they lose points in favor of players.
		if (IsFakeClientEx(i))
		{
			if (!allowBots)
				continue;
				
			points[i] -= 2500;
		}
		
		if (IsPlayerAFK(i))
			points[i] -= 99999;
			
		if (!g_bPlayerBecomeSurvivor[i])
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
			MakeSurvivor(i, RF2_GetSurvivorIndex(client), false);
			
			float pos[3];
			float angles[3];
			GetClientAbsOrigin(client, pos);
			GetClientEyeAngles(client, angles);
			TeleportEntity(i, pos, angles, NULL_VECTOR);
			
			if (IsClientInGameEx(client))
			{
				RF2_PrintToChat(i, "You've been chosen as a Survivor because %N disconnected or went AFK. Enjoy!", client);
			}
			
			break;
		}
	}
}

public Action OnRoundStart(Event event, const char[] eventName, bool dontBroadcast)
{
	if (!RF2_IsEnabled() || g_bWaitingForPlayers)
		return Plugin_Continue;
	
	g_bRoundActive = true;
	g_bGracePeriod = true;
	if (!CreateSurvivors())
	{
		g_bRoundActive = false;
		g_bGracePeriod = false;
		PrintToServer("[RF2] No Survivors were spawned! Restarting the game...");
		ReloadPlugin(true);
		return Plugin_Continue;
	}
	
	if (!g_bGameInitialized)
	{
		CreateTimer(2.0, Timer_DifficultyVote, _, TIMER_FLAG_NO_MAPCHANGE);
		g_bGameInitialized = true;
	}
	
	CreateTimer(0.5, Timer_KillEnemyTeam, _, TIMER_FLAG_NO_MAPCHANGE);
	
	int gamerules = FindEntityByClassname(-1, "tf_gamerules");
	if (gamerules == -1)
	{
		gamerules = CreateEntityByName("tf_gamerules");
	}
	
	SetVariantInt(9999);
	AcceptEntityInput(gamerules, "SetRedTeamRespawnWaveTime");
	SetVariantInt(9999);
	AcceptEntityInput(gamerules, "SetBlueTeamRespawnWaveTime");
	
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
	CreateTimer(0.25, Timer_PlayMusicDelay, _, TIMER_FLAG_NO_MAPCHANGE);
	
	// Begin grace period
	int timer = CreateEntityByName("team_round_timer");
	DispatchSpawn(timer);
	SetEntProp(timer, Prop_Send, "m_nState", 0); // setup state
	SetVariantFloat(g_flGracePeriodTime);
	AcceptEntityInput(timer, "SetSetupTime");
	SetVariantInt(1);
	AcceptEntityInput(timer, "ShowInHUD");
	AcceptEntityInput(timer, "Resume");
	HookSingleEntityOutput(timer, "OnSetupFinished", Output_GraceTimerFinished, true);
	
	if (g_bTankBossMode)
	{
		RF2_PrintToChatAll("Tanks will arrive in %.0f seconds.", g_flGracePeriodTime);
	}
	
	Call_StartForward(g_fwGracePeriodStart);
	Call_Finish();
	
	GameRules_SetProp("m_nGameType", -1);
	
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
	Menu menu = CreateMenu(Menu_DifficultyVote);
	menu.SetTitle("Vote for the game's difficulty level!");
	menu.AddItem("0", "Scrap");
	menu.AddItem("1", "Iron");
	menu.AddItem("2", "Steel");
	
	if (GetRandomInt(1, 20) == 1)
	{
		menu.AddItem("3", "Titanium");
	}
	
	menu.DisplayVoteToAll(30);
}

public int Menu_DifficultyVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_VoteEnd:
		{
			char info[8];
			menu.GetItem(param1, info, sizeof(info));
			g_iDifficultyLevel = StringToInt(info);
			
			char difficultyName[64];
			GetDifficultyName(g_iDifficultyLevel, difficultyName, sizeof(difficultyName));
			
			if (g_iDifficultyLevel != DIFFICULTY_TITANIUM)
			{
				RF2_PrintToChatAll("The difficulty has been set to %s{default}.", difficultyName);
			}
			else
			{
				EmitSoundToAll(SOUND_EVIL_LAUGH);
				RF2_PrintToChatAll("The difficulty has been set to %s{default}! {red}Prepare to die...", difficultyName);
			}
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

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!RF2_IsEnabled() || g_cvDebugNoMapChange.BoolValue)
		return Plugin_Continue;
		
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGameEx(i) && !IsPlayerSurvivor(i) && !IsFakeClientEx(i))
		{
			g_iPlayerSurvivorPoints[i] += 10;
			RF2_PrintToChat(i, "You gained {lime}10 {default}Survivor Points from this round.");
		}
	}
	
	int winningTeam = event.GetInt("team");
	if (winningTeam == TEAM_SURVIVOR)
	{
		int nextStage = RF2_GetCurrentStage();
		if (nextStage >= RF2_GetMaxStages()-1)
		{
			g_iLoopCount++;
			nextStage = 0;
		}
		else
		{
			nextStage++;
		}
		
		CreateTimer(14.0, Timer_SetNextStage, nextStage, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (winningTeam == TEAM_ENEMY)
	{
		g_bGameOver = true;
		CreateTimer(14.0, Timer_GameOver, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

public Action OnPostInventoryApplication(Event event, const char[] eventName, bool dontBroadcast)
{
	if (!RF2_IsEnabled() || !g_bRoundActive)
		return Plugin_Continue;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = GetClientTeam(client);
	
	// If we're an enemy and spawn during the grace period, or don't have a type, die
	if (team == TEAM_ENEMY)
	{
		if (g_bGracePeriod || GetEnemyType(client) < 0 && GetBossType(client) < 0)
		{
			SilentlyKillPlayer(client);
			return Plugin_Continue;
		}
	}
	
	if (team == TEAM_SURVIVOR)
	{
		// Gatekeeping
		if (!IsPlayerSurvivor(client) || IsFakeClientEx(client) && !g_cvBotsCanBeSurvivor.BoolValue)
		{
			SilentlyKillPlayer(client);
			ChangeClientTeam(client, TEAM_ENEMY);
		}
		else if (g_bPlayerAutomaticItemMenu[client])
		{
			ShowItemMenu(client);
		}
	}
	else if (team == TEAM_ENEMY) // Remove loadout wearables for enemies
	{
		// TODO: Do something about voodoo-cursed (zombie) cosmetics causing player skin issues.
		TF2_RemoveLoadoutWearables(client);
		
		char name[MAX_NAME_LENGTH];
		if (GetEnemyType(client) > -1)
		{
			strcopy(name, sizeof(name), g_szEnemyName[GetEnemyType(client)]);
		}
		else if (GetBossType(client) > -1)
		{
			strcopy(name, sizeof(name), g_szBossName[GetBossType(client)]);
		}
		
		if (name[0])
		{
			if (IsFakeClientEx(client))
			{
				SetClientName(client, name);
			}
			else
			{
				Format(name, sizeof(name), "%s (%s)", name, g_szPlayerOriginalName[client]);
				SetClientName(client, name);
			}
		}
	}
	
	if (IsFakeClientEx(client))
	{
        if (g_TFBot[client].Follower.IsValid())
        {
            g_TFBot[client].Follower.Invalidate();
        }
	}
	
	// Initialize our stats (health, speed, kb resist) the next frame to ensure it's correct
	RequestFrame(RF_InitStats, client);
	
	TF2_AddCondition(client, TFCond_UberchargedHidden, 0.2);
	if (g_bThrillerActive)
	{
		TF2_AddCondition(client, TFCond_HalloweenThriller);
	}
	
	return Plugin_Continue;
}

public void RF_InitStats(int client)
{
	if (IsClientInGameEx(client) && IsPlayerAlive(client))
	{
		CalculatePlayerMaxHealth(client, false, true);
		CalculatePlayerMaxSpeed(client);
		CalculatePlayerKnockbackResist(client);
	}
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!RF2_IsEnabled() || g_bWaitingForPlayers || !g_bRoundActive)
		return Plugin_Continue;
		
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int inflictor = event.GetInt("inflictor_entindex");
	int assister = GetClientOfUserId(event.GetInt("assister"));
	int damageType = event.GetInt("damagebits");
	int damageCustom = event.GetInt("customkill");
	int critType = event.GetInt("crit_type");
	
	// No dominations
	int deathFlags = event.GetInt("death_flags");
	deathFlags &= ~(TF_DEATHFLAG_KILLERDOMINATION | TF_DEATHFLAG_ASSISTERDOMINATION | 
	TF_DEATHFLAG_KILLERREVENGE | TF_DEATHFLAG_ASSISTERREVENGE);
	event.SetInt("death_flags", deathFlags);
	
	int victimTeam = GetClientTeam(victim);
	Action action = Plugin_Continue;
	
	if (attacker > 0)
	{
		DoItemDeathEffects(attacker, victim, damageType, damageCustom, critType);
	}
	
	if (victimTeam == TEAM_ENEMY)
	{
		if (!g_bGracePeriod)
		{
			float pos[3];
			GetClientAbsOrigin(victim, pos);
			
			float cashAmount;
			int size;
			
			if (GetEnemyType(victim) >= 0)
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
				
				TE_TFParticle("fireSmokeExplosion", pos);
				RequestFrame(RF_DeleteRagdoll, victim);
			}
			
			cashAmount *= 1.0 + (float(RF2_GetEnemyLevel()-1) * g_cvEnemyCashDropScale.FloatValue);
			if (attacker > 0 && PlayerHasItem(attacker, Item_BanditsBoots))
			{
				cashAmount *= 1.0 + CalcItemMod(attacker, Item_BanditsBoots, 0);
			}
			
			SpawnCashDrop(cashAmount, pos, size);
			
			// For now, enemies have a chance to drop Haunted Keys, may implement a different way of obtaining them later
			int max = g_cvHauntedKeyDropChanceMax.IntValue;
			if (max > 0 && RandChanceIntEx(attacker, 1, max, 1))
			{
				RF2_PrintToChatAll("{yellow}%N{default} dropped a {haunted}Haunted Key!", victim);
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsPlayerSurvivor(i))
						g_iPlayerHauntedKeys[i]++;
				}
			}
		}
		else // If the grace period is active, die silently
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
				{
					xp = g_flEnemyXPAward[g_iPlayerEnemyType[victim]];
				}
				else if (GetBossType(victim) >= 0)
				{
					xp = g_flBossXPAward[g_iPlayerBossType[victim]];
				}
				
				if (xp > 0.0)
				{
					xp *= 1.0 + (float(RF2_GetEnemyLevel()-1) * g_cvEnemyXPDropScale.FloatValue);
					
					UpdatePlayerXP(attacker, xp);
					
					// Only share xp for boss kills, assisters, or a medic healing us.
					int medigun;
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGameEx(i) || attacker == i || !IsPlayerSurvivor(i))
							continue;
							
						if (GetBossType(victim) >= 0 || i == assister 
						|| TF2_GetPlayerClass(i) == TFClass_Medic && (medigun = GetPlayerWeaponSlot(i, WeaponSlot_Secondary)) > -1 && GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget") == attacker)
						{
							UpdatePlayerXP(i, xp);
						}
					}
				}
				
				if (inflictor > MaxClients && g_cvBusterSpawnKillThreshold.IntValue > 0 && IsBuilding(inflictor) && !IsSentryBusterActive())
				{
					g_iSentryKillCounter++;
					if (g_iSentryKillCounter >= g_cvBusterSpawnKillThreshold.IntValue + RF2_GetEnemyLevel()-1 * g_cvBusterSpawnKillRatio.IntValue)
					{
						g_iSentryKillCounter = 0;
						DoSentryBusterWave();
					}
				}
				
				int total;
				for (int i = 1; i <= MaxClients; i++)
				{
					if (!IsClientInGameEx(i) || !IsPlayerSurvivor(i))
						continue;
						
					if (PlayerHasItem(i, Item_PillarOfHats))
					{
						total++;
					}
				}
				
				if (total > 0)
				{
					float scrapChance = CalcItemMod(0, Item_PillarOfHats, 0, total);
					float recChance = CalcItemMod(0, Item_PillarOfHats, 1, total);
					float refChance = CalcItemMod(0, Item_PillarOfHats, 2, total);
					float totalChance = scrapChance + recChance + refChance;
					float result;
					
					if (RandChanceFloatEx(attacker, 0.0, 1.0, totalChance, result))
					{
						int item;
						if (result <= refChance)
						{
							item = Item_RefinedMetal;
						}
						else if (result <= recChance)
						{
							item = Item_ReclaimedMetal;
						}
						else
						{
							item = Item_ScrapMetal;
						}
						
						float pos[3];
						GetClientAbsOrigin(victim, pos);
						pos[2] += 30.0;
						SpawnItem(item, pos, attacker);
					}
				}
				
				if (PlayerHasItem(attacker, Item_Dangeresque))
				{
					if (RandChanceFloatEx(attacker, 0.0, 1.0, GetItemMod(Item_Dangeresque, 3)))
					{
						int bomb = CreateEntityByName("tf_projectile_pipe");
						float pos[3];
						GetClientAbsOrigin(victim, pos);
						pos[2] += 30.0;
						TeleportEntity(bomb, pos);
						
						float damage = GetItemMod(Item_Dangeresque, 0) + CalcItemMod(attacker, Item_Dangeresque, 1, -1);
						SetEntPropFloat(bomb, Prop_Send, "m_flDamage", damage);
						float radius = GetItemMod(Item_Dangeresque, 4) + CalcItemMod(attacker, Item_Dangeresque, 5, -1);
						SetEntPropFloat(bomb, Prop_Send, "m_DmgRadius", radius);
						
						SetEntityOwner(bomb, attacker);
						SetEntProp(bomb, Prop_Data, "m_iTeamNum", GetClientTeam(attacker));
						
						g_bCashBomb[bomb] = true;
						if (GetEnemyType(victim) != -1)
						{
							g_flCashBombAmount[bomb] = g_flEnemyCashAward[g_iPlayerEnemyType[victim]];
							g_iCashBombSize[bomb] = 2;
						}
						else if (GetBossType(victim) >= 0)
						{
							g_flCashBombAmount[bomb] = g_flBossCashAward[g_iPlayerBossType[victim]];
							g_iCashBombSize[bomb] = 3;
						}
						
						g_flCashBombAmount[bomb] *= 1.0 + (float(GetPlayerLevel(victim)-1) * g_cvEnemyCashDropScale.FloatValue);
						
						if (PlayerHasItem(attacker, Item_BanditsBoots))
						{
							g_flCashBombAmount[bomb] *= 1.0 + CalcItemMod(attacker, Item_BanditsBoots, 0);
						}
						
						SDKHook(bomb, SDKHook_StartTouch, Hook_DisableTouch);
						SDKHook(bomb, SDKHook_Touch, Hook_DisableTouch);
						
						g_bDontDamageOwner[bomb] = true;
						SetEntItemDamageProc(bomb, Item_Dangeresque);
						
						DispatchSpawn(bomb);
						ActivateEntity(bomb);
						SetEntityModel(bomb, MODEL_CASH_BOMB);
						
						TE_TFParticle("mvm_cash_embers_red", pos, bomb, PATTACH_ABSORIGIN_FOLLOW);
					}
				}
			}
		}
	}
	else if (IsPlayerSurvivor(victim))
	{
		if (!g_bGracePeriod)
		{
			SaveSurvivorInventory(victim, RF2_GetSurvivorIndex(victim));
			PrintDeathMessage(victim);
			
			int fog = CreateEntityByName("env_fog_controller");
			DispatchKeyValue(fog, "spawnflags", "1");
			DispatchKeyValueInt(fog, "fogenabled", 1);
			DispatchKeyValueFloat(fog, "fogstart", 50.0);
			DispatchKeyValueFloat(fog, "fogend", 100.0);
			DispatchKeyValueFloat(fog, "fogmaxdensity", 0.9);
			DispatchKeyValue(fog, "fogcolor", "255 0 0");
			
			DispatchSpawn(fog);				
			AcceptEntityInput(fog, "TurnOn");				
			
			const float time = 0.1;
			int oldFog[MAXTF2PLAYERS] = {-1, ...};
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGameEx(i))
					continue;
				
				oldFog[i] = GetEntPropEnt(i, Prop_Data, "m_hCtrl");
				SetEntPropEnt(i, Prop_Data, "m_hCtrl", fog);
				
				DataPack pack;
				CreateDataTimer(time, Timer_RestorePlayerFog, pack, TIMER_FLAG_NO_MAPCHANGE);
				pack.WriteCell(GetClientUserId(i));
				pack.WriteCell(EntIndexToEntRef(oldFog[i]));
			}
			
			CreateTimer(time, Timer_KillFog, EntIndexToEntRef(fog), TIMER_FLAG_NO_MAPCHANGE);
			
			// Change the victim's team on a timer to avoid some strange behavior.
			CreateTimer(0.3, Timer_ChangeTeamOnDeath, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
			
			int alive = 0;
			int lastMan;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGameEx(i) || i == victim)
					continue;
					
				if (IsPlayerAlive(i) && IsPlayerSurvivor(i))
				{
					alive++;
					lastMan = i;
				}
			}
			
			if (alive == 0 && !g_cvDebugDontEndGame.BoolValue) // Game over, man!
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
			// Respawning players right inside of player_death causes strange behaviour.
			CreateTimer(0.1, Timer_RespawnSurvivor, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	if (TF2_GetPlayerClass(victim) == TFClass_Engineer)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "*")) != -1)
		{
			if (entity <= MaxClients || !IsBuilding(entity) || GetEntPropEnt(entity, Prop_Send, "m_hBuilder") != victim)
				continue;
				
			if (TF2_GetObjectType(entity) == TFObject_Sentry || GetEntProp(entity, Prop_Data, "m_iTeamNum") == TEAM_SURVIVOR)
			{
				SetVariantInt(10);
				AcceptEntityInput(entity, "SetHealth");
				SDKHooks_TakeDamage(entity, attacker, attacker, 99999.0, DMG_PREVENT_PHYSICS_FORCE);
			}
			else
			{
				AcceptEntityInput(entity, "SetBuilder", -1);
			}
		}
	}

	if (victimTeam == TEAM_ENEMY)
	{
		SetClientName(victim, g_szPlayerOriginalName[victim]);
	}
	
	RefreshClient(victim);
	return action;
}

public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	float damage = float(event.GetInt("damageamount"));
	int damageCustom = event.GetInt("custom");
	
	if (attacker > 0 && PlayerHasItem(attacker, ItemSniper_HolyHunter) && CanUseCollectorItem(attacker, ItemSniper_HolyHunter))
	{
		if (damageCustom == TF_CUSTOM_HEADSHOT || damageCustom == TF_CUSTOM_HEADSHOT_DECAPITATION)
		{
			float pos[3];
			GetClientAbsOrigin(victim, pos);
			pos[2] += 30.0;
			
			float radiusDamage = damage * GetItemMod(ItemSniper_HolyHunter, 0);
			radiusDamage *= 1.0 + CalcItemMod(attacker, ItemSniper_HolyHunter, 1, -1);
			float radius = GetItemMod(ItemSniper_HolyHunter, 2);
			radius *= 1.0 + CalcItemMod(attacker, ItemSniper_HolyHunter, 3, -1);
			
			DoRadiusDamage(attacker, ItemSniper_HolyHunter, pos, radiusDamage, DMG_BLAST, radius, GetPlayerWeaponSlot(attacker, WeaponSlot_Primary), _, true);
		}
	}
	
	return Plugin_Continue;
}

public Action Timer_RespawnSurvivor(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || !IsPlayerSurvivor(client))
	{
		return Plugin_Continue;
	}
	
	MakeSurvivor(client, RF2_GetSurvivorIndex(client), false, false);
	return Plugin_Continue;
}

public Action Timer_ChangeTeamOnDeath(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
		
	ChangeClientTeam(client, TEAM_ENEMY);
	return Plugin_Continue;
}

public Action Timer_KillFog(Handle timer, int fog)
{
	if (EntRefToEntIndex(fog) == INVALID_ENT_REFERENCE)
		return Plugin_Continue;
	
	AcceptEntityInput(fog, "TurnOff");
	RemoveEntity(fog);
	
	int mapFog = EntRefToEntIndex(g_iMapFog);
	if (mapFog != INVALID_ENT_REFERENCE)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGameEx(i))
				continue;
				
			SetEntPropEnt(i, Prop_Data, "m_hCtrl", mapFog);
		}
	}
	
	return Plugin_Continue;
}

public Action Timer_RestorePlayerFog(Handle timer, DataPack pack)
{
	pack.Reset();
	
	int client = GetClientOfUserId(pack.ReadCell());
	if (client == 0)
		return Plugin_Continue;
		
	int fog = EntRefToEntIndex(pack.ReadCell());
	if (fog != INVALID_ENT_REFERENCE)
	{
		SetEntPropEnt(client, Prop_Data, "m_hCtrl", fog);
	}
	
	return Plugin_Continue;
}

public void RF_DeleteRagdoll(int client)
{
	if (!IsClientInGameEx(client))
		return;

	char classname[16];
	int entity = -1;
	
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		if (entity <= MaxClients)
			continue;
		
		GetEntityClassname(entity, classname, sizeof(classname));
		if (strcmp2(classname, "tf_ragdoll") && GetEntPropEnt(entity, Prop_Send, "m_hPlayer") == client)
		{
			RemoveEntity(entity);
			break;
		}
	}	
}

public Action OnPlayerChargeDeployed(Event event, const char[] name, bool dontBroadcast)
{
	int medic = GetClientOfUserId(event.GetInt("userid"));
	if (PlayerHasItem(medic, ItemMedic_WeatherMaster))
	{
		int team = GetClientTeam(medic);
		float eyePos[3], enemyPos[3], beamPos[3];
		GetClientEyePosition(medic, eyePos);
		
		float damage = CalcItemMod(medic, ItemMedic_WeatherMaster, 0) + CalcItemMod(medic, ItemMedic_WeatherMaster, 2);
		float range = sq(CalcItemMod(medic, ItemMedic_WeatherMaster, 1) + CalcItemMod(medic, ItemMedic_WeatherMaster, 3, -1));
		
		Handle trace;
		int hitCount;
		
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "*")) != -1)
		{
			if (entity < 1)
				continue;
			
			if (!IsValidClient(entity) && !IsBuilding(entity) && !IsNPC(entity) || entity == medic)
				continue;
				
			if (GetEntProp(entity, Prop_Data, "m_iTeamNum") == team)
				continue;
				
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", enemyPos);
			enemyPos[2] += 30.0;
			
			if (GetVectorDistance(eyePos, enemyPos, true) <= range)
			{
				trace = TR_TraceRayFilterEx(eyePos, enemyPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceFilter_WallsOnly);
				if (!TR_DidHit(trace))
				{
					SetEntItemDamageProc(medic, ItemMedic_WeatherMaster);
					SDKHooks_TakeDamage(entity, medic, medic, damage, DMG_SHOCK, _, _, _, false);
					
					CopyVectors(enemyPos, beamPos);
					beamPos[2]+=1500.0;
					enemyPos[2] -= 30.0;
					TE_SetupBeamPoints(beamPos, enemyPos, g_iBeamModel, 0, 0, 0, 0.5, 8.0, 8.0, 0, 10.0, {255, 255, 255, 200}, 20);
					TE_SendToAll();
					
					hitCount++;
				}
				
				delete trace;
			}
		}
			
		
		if (hitCount > 0)
		{
			EmitSoundToAll(SOUND_THUNDER, medic);
			
			int shake = CreateEntityByName("env_shake");
			DispatchKeyValue(shake, "spawnflags", "4");
			DispatchKeyValueFloat(shake, "radius", range*3.0);
			DispatchKeyValueFloat(shake, "amplitude", 10.0);
			DispatchKeyValueFloat(shake, "duration", 8.0);
			DispatchKeyValueFloat(shake, "frequency", 5.0*hitCount);
			
			TeleportEntity(shake, eyePos);
			DispatchSpawn(shake);
			CreateTimer(8.0, Timer_DeleteEntity, EntIndexToEntRef(shake), TIMER_FLAG_NO_MAPCHANGE);
			
			Handle msg;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGameEx(i))
					continue;
					
				msg = StartMessageOne("Fade", i);
				BfWriteShort(msg, 100);
				BfWriteShort(msg, 0);
				BfWriteShort(msg, (0x0002));
				BfWriteByte(msg, 255);
				BfWriteByte(msg, 255);
				BfWriteByte(msg, 255);
				BfWriteByte(msg, 255);
				
				EndMessage();
			}
			
			if (hitCount >= 5)
			{
				AcceptEntityInput(medic, "ClearContext");
				SetVariantString("TLK_PLAYER_SPELL_PICKUP_RARE");
				AcceptEntityInput(medic, "SpeakResponseConcept");
			}
		}
	}
	
	return Plugin_Continue;
}

public Action OnPlayerDropObject(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int building = event.GetInt("index");
	
	if (CanTeamQuickBuild(GetClientTeam(client)))
	{
		if (TF2_GetObjectType(building) == TFObject_Dispenser) // must be delayed by a frame or else the screen will break
		{
			RequestFrame(RF_DispenserQuickBuild, building);
		}
		else
		{
			SDK_DoQuickBuild(building);
		}
	}
	
	return Plugin_Continue;
}

public void RF_DispenserQuickBuild(int building)
{
	SDK_DoQuickBuild(building);
}

public Action OnPlayerBuiltObject(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int building = event.GetInt("index");
	bool carryDeploy = bool(GetEntProp(building, Prop_Send, "m_bCarryDeploy"));
	
	// For some reason, extra sentries built (by detouring CTFPlayer::CanBuild) always have this netprop set,
	// so we'll use it to detect extra sentries built with the Head of Defense.
	if (GetEntProp(building, Prop_Send, "m_bDisposableBuilding"))
	{
		SetEntProp(building, Prop_Send, "m_bDisposableBuilding", false);
		SetEntProp(building, Prop_Send, "m_bMiniBuilding", true);
		
		g_hPlayerExtraSentryList[client].Push(building);
		
		if (!carryDeploy)
		{
			// Need to set health. m_bDisposableBuilding being set also messes with the building health.
			int maxHealth = GetEntProp(building, Prop_Send, "m_iMaxHealth");
			maxHealth = RoundToFloor(float(maxHealth) * TF2Attrib_HookValueFloat(1.0, "mult_engy_building_health", client));
			SetEntProp(building, Prop_Send, "m_iMaxHealth", maxHealth);
			SetVariantInt(maxHealth);
			AcceptEntityInput(building, "SetHealth");
		}
	}
	
	if (!carryDeploy && GameRules_GetProp("m_bInSetup"))
	{
		SDK_DoQuickBuild(building, true);
	}
	
	return Plugin_Continue;
}

public Action OnChangeTeamMessage(Event event, const char[] name, bool dontBroadcast)
{
	// no team change messages
	event.BroadcastDisabled = true;
	return Plugin_Continue;
}

public Action Timer_KillEnemyTeam(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i) || IsPlayerSurvivor(i))
			continue;
		
		SDKHooks_TakeDamage(i, 0, 0, 9999999.0, DMG_PREVENT_PHYSICS_FORCE);
		ForcePlayerSuicide(i);
	}
	
	return Plugin_Continue;
}

public Action Output_GraceTimerFinished(const char[] output, int caller, int activator, float delay)
{
	if (!g_bGracePeriod) // grace period was probably ended early by /rf2_skipgrace (which still calls this timer function)
		return Plugin_Continue;
	
	EndGracePeriod();
	RemoveEntity(caller);
	return Plugin_Continue;
}

void EndGracePeriod()
{
	g_bGracePeriod = false;
	int entity = MaxClients+1;
	
	// Must do this or else bots will misbehave, thinking it's still setup time. They won't attack players and will randomly taunt.
	while ((entity = FindEntityByClassname(entity, "team_round_timer")) != -1)
	{
		if (GetEntProp(entity, Prop_Send, "m_nState") == 0)
		{
			UnhookSingleEntityOutput(entity, "team_round_timer", Output_GraceTimerFinished);
			SetVariantFloat(1.0);
			AcceptEntityInput(entity, "SetSetupTime");
			CreateTimer(2.0, Timer_DeleteEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	// Begin our enemy spawning
	CreateTimer(5.0, Timer_EnemySpawnWave, _, TIMER_FLAG_NO_MAPCHANGE);
	
	Call_StartForward(g_fwGracePeriodEnded);
	Call_Finish();
	
	if (!g_bTankBossMode)
	{
		RF2_PrintToChatAll("Grace period has ended. Death on RED will result in joining BLU.");
	}
	else
	{
		BeginTankDestructionMode();
	}
}

public Action UserMessageHook_SayText2(UserMsg msg, BfRead bf, const int[] clients, int numClients, bool reliable, bool init) 
{
	char message[128];
	bf.ReadString(message, sizeof(message));
	bf.ReadString(message, sizeof(message));
	
	if (StrContains(message, "Name_Change") != -1) // Hide name change messages, they really get spammy
		return Plugin_Handled;
	
	return Plugin_Continue;
}

int g_iEnemySpawnType[MAXTF2PLAYERS] = {-1, ...};
int g_iBossSpawnType[MAXTF2PLAYERS] = {-1, ...};
public Action Timer_EnemySpawnWave(Handle timer)
{
	if (!RF2_IsEnabled() || !g_bRoundActive || IsStageCleared())
		return Plugin_Continue;
	
	int survivorCount = RF2_GetSurvivorCount();
	float duration = g_cvEnemyBaseSpawnWaveTime.FloatValue - ((1.5 * float(survivorCount-1)) - (float(RF2_GetEnemyLevel()-1) * 0.2));
	
	float reduction = 0.25 * float(g_iRespawnWavesCompleted);
	float subIncrement = g_flDifficultyCoeff/g_cvSubDifficultyIncrement.FloatValue;
	if (reduction > subIncrement)
		reduction = subIncrement;
	
	duration -= reduction;
	
	if (GetTeleporterEventState() == TELE_EVENT_ACTIVE)
		duration *= 0.65;
	
	float minSpawnWaveTime = g_cvEnemyMinSpawnWaveTime.FloatValue;
	
	if (duration < minSpawnWaveTime)
		duration = minSpawnWaveTime;
	
	CreateTimer(duration, Timer_EnemySpawnWave, _, TIMER_FLAG_NO_MAPCHANGE);
	
	int increment = g_iSubDifficulty/2;
	int maxCount = GetRandomInt(2+increment, 3+increment) + (survivorCount/2);
	int absoluteMaxCount = g_cvEnemyMaxSpawnWaveCount.IntValue;
	
	if (maxCount > absoluteMaxCount)
		maxCount = absoluteMaxCount;
		
	if (maxCount < 1)
		maxCount = 1;
	
	ArrayList respawnArray = CreateArray(1, MAXTF2PLAYERS);
	static int spawnPoints[MAXTF2PLAYERS];
	int count;
	bool finished, ignorePoints, chosen[MAXTF2PLAYERS], pointsGiven[MAXTF2PLAYERS];
	
	// grab our next players for the spawn
	for (int i = 1; i <= MaxClients; i++)
	{
		if (chosen[i] || !IsClientInGameEx(i) || GetClientTeam(i) != TEAM_ENEMY)
			continue;
		
		if (IsPlayerAlive(i))
		{
			if (!ignorePoints && !IsFakeClientEx(i))
			{
				spawnPoints[i] += 3;
			}
			
			continue;
		}
		
		if (ignorePoints && count < maxCount || !finished && spawnPoints[i] >= 0)
		{
			respawnArray.Set(count, i);
			count++;
			respawnArray.SwapAt(GetRandomInt(0, count-1), GetRandomInt(0, count-1));
			spawnPoints[i]--;
			chosen[i] = true;
		}
		else if (!pointsGiven[i])
		{
			if (!IsFakeClientEx(i)) // Humans get more spawn points than bots
			{
				spawnPoints[i] += 6;
			}
			else
			{
				spawnPoints[i]++;
			}
				
			pointsGiven[i] = true;
		}
		
		// bots have less spawn priority than players this way, but they will still spawn
		if (spawnPoints[i] > 0 && IsFakeClientEx(i))
			spawnPoints[i] = 0;
		
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

	respawnArray.Resize(count);
	int client;
	float time = 0.1;
	float min;
	const float max = 100.0;
	
	for (int i = 0; i < count; i++)
	{
		client = respawnArray.Get(i);
		
		min = subIncrement < max ? subIncrement : max;
		if (g_iSubDifficulty >= SubDifficulty_Impossible && RandChanceFloat(min, max, min))
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
		FormatEx(reason, sizeof(reason), "%s forced the next map", g_szMapForcerName);
		
		g_bMapChanging = true;
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
	if (!RF2_IsEnabled())
	{
		g_hHudTimer = null;
		return Plugin_Stop;
	}
	
	int hudSeconds, strangeItem;
	static char strangeItemInfo[128];
	
	SetHudTextParams(-1.0, -1.3, 0.15, g_iMainHudR, g_iMainHudG, g_iMainHudB, 255);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i) || IsFakeClientEx(i))
			continue;
		
		if (g_bGameOver)
		{
			static bool scoreCalculated;
			static int score;
			static char rank[8];
			
			// Calculate our score and rank.
			if (!scoreCalculated)
			{
				score += g_iTotalEnemiesKilled * 10;
				score += g_iTotalBossesKilled * 250;
				score += g_iTotalTanksKilled * 500;
				score += g_iTotalItemsFound * 50;
				score += g_iStagesCompleted * 1500;
				
				if (score >= 100000)
					rank = "S";
				else if (score >= 50000)
					rank = "A";
				else if (score >= 30000)
					rank = "B";
				else if (score >= 13500)
					rank = "C";
				else if (score >= 8000)
					rank = "D";
				else if (score >= 3500)
					rank = "E";
				else
					rank = "F";
					
				scoreCalculated = true;
			}
			
			SetHudTextParams(-1.0, -1.3, 0.15, 255, 100, 100, 255);
			ShowSyncHudText(i, g_hMainHudSync, 
			"\n\n\n\nGAME OVER\n\nEnemies slain: %i\nBosses slain: %i\nStages completed: %i\nItems found: %i\n\nTOTAL SCORE: %i points\nRANK: %s", 
			g_iTotalEnemiesKilled, g_iTotalBossesKilled, g_iStagesCompleted, g_iTotalItemsFound, score, rank);
			return Plugin_Continue;
		}
		
		hudSeconds = RoundFloat((g_flSecondsPassed) - (float(g_iMinutesPassed) * 60.0));
		strangeItem = GetPlayerEquipmentItem(i);
		
		if (strangeItem > Item_Null)
		{
			GetItemName(strangeItem, strangeItemInfo, sizeof(strangeItemInfo));
			
			if (g_iPlayerEquipmentItemCharges[i] > 0)
			{
				if (g_flPlayerEquipmentItemCooldown[i] > 0.0) // multi-stack recharge?
				{
					Format(strangeItemInfo, sizeof(strangeItemInfo), "Strange Item: %s[%i] READY! RELOAD KEY (R) TO USE! [%.1f]", 
					strangeItemInfo, g_iPlayerEquipmentItemCharges[i], g_flPlayerEquipmentItemCooldown[i]);
				}
				else
				{
					Format(strangeItemInfo, sizeof(strangeItemInfo), "Strange Item: %s[%i] READY! RELOAD KEY (R) TO USE!", 
					strangeItemInfo, g_iPlayerEquipmentItemCharges[i]);
				}
			}
			else
			{
				Format(strangeItemInfo, sizeof(strangeItemInfo), "Strange Item: %s[0] [%.1f]", 
				strangeItemInfo, g_flPlayerEquipmentItemCooldown[i]);
			}
		}
		else
		{
			strangeItemInfo = "";
		}
		
		if (IsPlayerSurvivor(i))
		{
			if (g_bTankBossMode && !g_bGracePeriod)
			{
				if (IsValidEntity(g_iPlayerLastAttackedTank[i]))
				{
					int health = GetEntProp(g_iPlayerLastAttackedTank[i], Prop_Data, "m_iHealth");
					int maxHealth = GetEntProp(g_iPlayerLastAttackedTank[i], Prop_Data, "m_iMaxHealth");
					
					FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "Tanks Destroyed: %i/%i\nTank Health: %i/%i", 
					g_iTanksKilledObjective, g_iTankKillRequirement, health, maxHealth);
				}
				else
				{
					g_iPlayerLastAttackedTank[i] = -1;
					FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "Tanks Destroyed: %i/%i", 
					g_iTanksKilledObjective, g_iTankKillRequirement);
				}
			}
			
			ShowSyncHudText(i, g_hMainHudSync, g_szSurvivorHudText, g_iStagesCompleted+1, g_iMinutesPassed, 
			hudSeconds, g_iEnemyLevel, g_iPlayerLevel[i], g_flPlayerXP[i], g_flPlayerNextLevelXP[i], g_flPlayerCash[i], g_iPlayerHauntedKeys[i],
			g_szHudDifficulty, strangeItemInfo, g_szObjectiveHud[i]);
		}
		else
		{
			ShowSyncHudText(i, g_hMainHudSync, g_szEnemyHudText, g_iStagesCompleted+1, g_iMinutesPassed, hudSeconds, 
			g_iEnemyLevel, g_szHudDifficulty, strangeItemInfo);
		}
	}
	return Plugin_Continue;
}

public Action Timer_Difficulty(Handle timer)
{
	if (!RF2_IsEnabled())
	{
		g_hDifficultyTimer = null;
		return Plugin_Stop;
	}
	
	if (g_bGameOver)
		return Plugin_Continue;
	
	g_flSecondsPassed += 1.0;
	if (g_flSecondsPassed >= 60.0 * (float(g_iMinutesPassed+1)))
		g_iMinutesPassed++;

	float timeFactor = g_flSecondsPassed / 10.0;
	float playerFactor = (float(RF2_GetSurvivorCount()-1) * 0.12) + 1.0;
	if (playerFactor < 1.0)
		playerFactor = 1.0;
	
	// this scales a bit too hard in higher survivor counts
	float value = 1.12 - (0.01 * float(RF2_GetSurvivorCount()-1));
	if (value < 1.02)
		value = 1.02;
		
	float stageFactor = Pow(value, float(g_iStagesCompleted));
	
	float difficultyFactor = GetDifficultyFactor(RF2_GetDifficulty());
	float oldDifficultyCoeff = g_flDifficultyCoeff;
	g_flDifficultyCoeff = (timeFactor * stageFactor * playerFactor) * difficultyFactor;
	g_flDifficultyCoeff *= g_cvDifficultyScaleMultiplier.FloatValue;
	if (g_flDifficultyCoeff < oldDifficultyCoeff)
		g_flDifficultyCoeff = oldDifficultyCoeff;
	
	if (g_cvDebugShowDifficultyCoeff.BoolValue)
		PrintCenterTextAll("g_flDifficultyCoeff = %f", g_flDifficultyCoeff);

	int currentLevel = RF2_GetEnemyLevel();
	g_iEnemyLevel = RoundToFloor(1.0 + g_flDifficultyCoeff / (g_cvSubDifficultyIncrement.FloatValue / 4.0));
	
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
			if (!IsClientInGameEx(i) || !IsPlayerAlive(i))
				continue;
			
			CalculatePlayerMaxHealth(i);
			
			if (GetBossType(i) <= -1)
			{
				CalculatePlayerKnockbackResist(i);
			}
		}
	}
	
	// increment the sub difficulty depending on difficulty value
	float subTime = g_flDifficultyCoeff / g_cvSubDifficultyIncrement.FloatValue;
	if (subTime >= g_iSubDifficulty+1)
	{	
		g_iSubDifficulty++;
		SetHudDifficulty(g_iSubDifficulty);
		
		static float lastBellTime;
		if (g_iSubDifficulty <= SubDifficulty_Normal || lastBellTime+10.0 > GetTickedTime())
		{
			EmitSoundToAll(SOUND_BELL);
			lastBellTime = GetTickedTime();
		}
	}
	
	return Plugin_Continue;
}

public Action Timer_PlayerTimer(Handle timer)
{
	if (!RF2_IsEnabled() || !g_bRoundActive)
	{
		g_hPlayerTimer = null;
		return Plugin_Stop;
	}
	
	int maxHealth, health, healAmount, weapon, ammoType;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i) || !IsPlayerAlive(i))
			continue;
		
		// All players have infinite reserve ammo
		weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
		if (weapon > -1)
		{
			ammoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
			
			if (ammoType > TFAmmoType_None && ammoType < TFAmmoType_Metal)
			{
				GivePlayerAmmo(i, 999999, ammoType, true);
			}
		}
		
		// Health Regen
		if (CanPlayerRegen(i))
		{
			g_flPlayerHealthRegenTime[i] -= 0.1;
			if (g_flPlayerHealthRegenTime[i] <= 0.0 && !TF2_IsPlayerInConditionEx(i, TFCond_Overhealed))
			{
				g_flPlayerHealthRegenTime[i] = 0.0;
				health = GetClientHealth(i);
				maxHealth = RF2_GetCalculatedMaxHealth(i);
				
				if (health < maxHealth)
				{
					healAmount = RoundToFloor(float(maxHealth) * 0.0025);
					
					if (PlayerHasItem(i, Item_Archimedes))
						healAmount = RoundToFloor(float(healAmount) * (1.0 + CalcItemMod(i, Item_Archimedes, 0)));
					
					if (PlayerHasItem(i, Item_ClassCrown))
						healAmount = RoundToFloor(float(healAmount) * (1.0 + CalcItemMod(i, Item_ClassCrown, 1)));
					
					if (IsPlayerSurvivor(i))
					{
						if (RF2_GetDifficulty() == DIFFICULTY_TITANIUM)
						{
							healAmount = RoundToFloor(float(healAmount) * 0.75);
						}
						else if (RF2_GetDifficulty() == DIFFICULTY_SCRAP)
						{
							healAmount = RoundToFloor(float(healAmount) * 1.5);
						}
					}
					
					if (healAmount < 1)
						healAmount = 1;
					
					HealPlayer(i, healAmount, false);
				}
			}
		}
		
		if (PlayerHasItem(i, Item_HorrificHeadsplitter) && !TF2_IsPlayerInConditionEx(i, TFCond_Bleeding))
		{
			TF2_MakeBleed(i, i, 60.0);
		}
	}

	return Plugin_Continue;
}

public Action Timer_PluginMessage(Handle timer)
{
	if (!RF2_IsEnabled())
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
	if (!RF2_IsEnabled() || IsSingleplayer() || !g_cvEnableAFKManager.BoolValue)
		return Plugin_Continue;
	
	int kickPriority[MAXTF2PLAYERS];
	int highestKickPriority = -1;
	int afkCount;
	int humanCount = GetTotalHumans();
	
	int afkLimit = g_cvAFKLimit.IntValue;
	int minHumans = g_cvAFKMinHumans.IntValue;
	float afkKickTime = g_cvAFKManagerKickTime.FloatValue;
	bool kickAdmins = g_cvAFKKickAdmins.BoolValue;
	
	// first we need to count our AFKs to see if anyone needs kicking
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i) || IsFakeClientEx(i))
			continue;
		
		if (IsPlayerAFK(i))
		{
			kickPriority[i] += RoundToFloor(g_flPlayerAFKTime[i]); // kick whoever has been AFK the longest first
			if (kickPriority[i] > highestKickPriority || highestKickPriority < 0)
			{
				highestKickPriority = kickPriority[i];
			}
			
			afkCount++;
		}
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i) || IsFakeClientEx(i))
			continue;
		
		g_flPlayerAFKTime[i] += 1.0;
		if (g_flPlayerAFKTime[i] >= afkKickTime * 0.5)
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
			else if (IsPlayerSurvivor(i) && g_bGracePeriod)
			{
				ReshuffleSurvivor(i, 0);
			}
			
			if (!g_bPlayerIsAFK[i])
			{
				g_bPlayerIsAFK[i] = true;
				OnPlayerEnterAFK(i);
			}
		}
		
		if (afkCount >= afkLimit && g_flPlayerAFKTime[i] >= afkKickTime && kickPriority[i] >= highestKickPriority && humanCount >= minHumans)
		{
			if (kickAdmins || GetUserAdmin(i) == INVALID_ADMIN_ID)
			{
				KickClient(i, "Kicked for being AFK");
				g_flPlayerAFKTime[i] = 0.0;
				g_bPlayerIsAFK[i] = false;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action OnVoiceCommand(int client, const char[] command, int args)
{
	if (!RF2_IsEnabled() || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	char arg1[8], arg2[8];
	int num1, num2;
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	num1 = StringToInt(arg1);
	num2 = StringToInt(arg2);
	
	if (IsPlayerSurvivor(client))
	{
		if (num1 == 0 && num2 == 0) // Medic!
		{
			if (GetClientButtons(client) & IN_SCORE)
			{
				ShowItemMenu(client); // shortcut
				return Plugin_Handled;
			}
			
			if (PickupItem(client) || ObjectInteract(client))
				return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action OnChangeClass(int client, const char[] command, int args)
{
	if (!RF2_IsEnabled() || !g_bRoundActive)
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
		
		SilentlyKillPlayer(client);
		TF2_SetPlayerClass(client, desiredClass); // so stats update properly
		MakeSurvivor(client, RF2_GetSurvivorIndex(client), false, false);
		
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
	if (!RF2_IsEnabled())
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

public Action OnBuildCommand(int client, const char[] command, int args)
{
	if (GetClientTeam(client) == TEAM_ENEMY)
	{
		char arg1[8];
		GetCmdArg(1, arg1, sizeof(arg1));
		
		if (StringToInt(arg1) == 1)
		{
			char arg2[8];
			GetCmdArg(2, arg2, sizeof(arg2));
			
			if (args == 1 || StringToInt(arg2) == 0)
			{
				EmitSoundToClient(client, SOUND_NOPE);
				PrintCenterText(client, "You can't build a Teleporter entrance. You only need to build an exit!");
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action OnSuicide(int client, const char[] command, int args)
{
	if (!RF2_IsEnabled() || !g_bRoundActive)
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
	int client;
	if ((client = GetClientOfUserId(pack.ReadCell())) == 0)
		return Plugin_Continue;
	
	if (!IsClientInGameEx(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
		
	float pos[3];
	pos[0] = pack.ReadFloat();
	pos[1] = pack.ReadFloat();
	pos[2] = pack.ReadFloat();
	
	TeleportEntity(client, pos);
	return Plugin_Continue;
}

public void Hook_PreThink(int client)
{
	if (!g_bRoundActive)
		return;
	
	float engineTime = GetEngineTime();
	
	if (!IsFakeClientEx(client) && !IsStageCleared() && g_flLoopMusicAt[client] >= 0.0 && engineTime >= g_flLoopMusicAt[client])
	{
		if (GetTeleporterEntity() != INVALID_ENT_REFERENCE && GetTeleporterEventState() != TELE_EVENT_PREPARING)
		{
			StopMusicTrack(client);
			PlayMusicTrack(client);
		}
	}
	
	if (!IsPlayerAlive(client))
		return;
	
	if (IsFakeClientEx(client))
	{
		TFBot_Think(g_TFBot[client]);
	}
	
	TFClassType class = TF2_GetPlayerClass(client);
	if (class == TFClass_Engineer)
	{
		float tickedTime = GetTickedTime();
		if (tickedTime >= g_flPlayerNextMetalRegen[client])
		{
			GivePlayerAmmo(client, g_cvEngiMetalRegenAmount.IntValue, TFAmmoType_Metal, true);
			float time = g_bGracePeriod ? 0.2 : g_cvEngiMetalRegenInterval.FloatValue;
			g_flPlayerNextMetalRegen[client] = tickedTime + time;
		}
	}
	else if (class == TFClass_Scout)
	{
		if (GetEntityFlags(client) & FL_ONGROUND)
		{
			g_iPlayerAirDashCounter[client] = 0;
		}
		else if (GetEntProp(client, Prop_Send, "m_iAirDash") > 0)
		{
			g_iPlayerAirDashCounter[client]++;
			OnPlayerAirDash(client, g_iPlayerAirDashCounter[client]);
		}
	}
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (condition == TFCond_Dazed)
	{
		int stunFlags = GetEntProp(client, Prop_Send, "m_iStunFlags");
		if (!RF2_CanBeStunned(client))
		{
			if (stunFlags & TF_STUNFLAGS_SMALLBONK || stunFlags & TF_STUNFLAGS_GHOSTSCARE || stunFlags & TF_STUNFLAGS_BIGBONK)
			{
				TF2_RemoveCondition(client, TFCond_Dazed);
				return;
			}
		}
	}
	
	g_bPlayerInCondition[client][condition] = true;
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	g_bPlayerInCondition[client][condition] = false;
	
	if (condition == TFCond_Buffed && PlayerHasItem(client, Item_MisfortuneFedora))
	{
		TF2_AddCondition(client, TFCond_Buffed);
	}
}

int g_iLastFiredWeapon[MAXTF2PLAYERS] = {-1, ...};
float g_flWeaponFireTime[MAXTF2PLAYERS];
public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponName, bool &result)
{
	if (!RF2_IsEnabled() || g_bWaitingForPlayers)
		return Plugin_Continue;
	
	bool changed;
	bool melee = GetPlayerWeaponSlot(client, WeaponSlot_Melee) == weapon;
	
	// Set m_flNextPrimaryAttack on the next frame to modify attack speed
	// Any of TF2's own firing speed modifications such as attributes will still go through
	g_iLastFiredWeapon[client] = EntIndexToEntRef(weapon);
	g_flWeaponFireTime[client] = GetGameTime(); // This is to (possibly) prevent a desync issue, see RF_NextPrimaryAttack
	RequestFrame(RF_NextPrimaryAttack, GetClientUserId(client));
	
	// Use our own crit logic
	if (!result && !strcmp2(weaponName, "tf_weapon_flamethrower"))
	{
		float proc = GetWeaponProcCoefficient(weapon);
		if (RollAttackCrit(client, proc, melee ? DMG_MELEE : DMG_GENERIC))
		{
			result = true;
			changed = true;
			
			StopSound(client, SNDCHAN_AUTO, SOUND_WEAPON_CRIT);
			EmitSoundToAll(SOUND_WEAPON_CRIT, client);
		}
	}
	
	if (melee)
	{
		if (PlayerHasItem(client, ItemPyro_PyromancerMask) && CanUseCollectorItem(client, ItemPyro_PyromancerMask)
		&& GetClientHealth(client) / RF2_GetCalculatedMaxHealth(client) >= GetItemMod(ItemPyro_PyromancerMask, 5))
		{
			float speed = GetItemMod(ItemPyro_PyromancerMask, 2) + CalcItemMod(client, ItemPyro_PyromancerMask, 3, -1);
			
			if (speed > GetItemMod(ItemPyro_PyromancerMask, 4))
				speed = GetItemMod(ItemPyro_PyromancerMask, 4);
			
			float eyePos[3], eyeAng[3];
			GetClientEyePosition(client, eyePos);
			GetClientEyeAngles(client, eyeAng);
			
			// Damage needs to be set in the damage hook.
			int fireball = ShootProjectile(client, "tf_projectile_spellfireball", eyePos, eyeAng, speed);
			g_bPyromancerFireball[fireball] = true;
			EmitSoundToAll(SOUND_SPELL_FIREBALL, client, _, _, _, 0.45);
		}
		
		if (PlayerHasItem(client, ItemDemo_ConjurersCowl) && CanUseCollectorItem(client, ItemDemo_ConjurersCowl)
		&& GetClientHealth(client) / RF2_GetCalculatedMaxHealth(client) >= GetItemMod(ItemDemo_ConjurersCowl, 5))
		{
			float eyePos[3], eyeAng[3];
			GetClientEyePosition(client, eyePos);
			GetClientEyeAngles(client, eyeAng);
			
			float speed = GetItemMod(ItemDemo_ConjurersCowl, 2) + CalcItemMod(client, ItemDemo_ConjurersCowl, 3, -1);
			if (speed > GetItemMod(ItemDemo_ConjurersCowl, 4))
				speed = GetItemMod(ItemDemo_ConjurersCowl, 4);
			
			float damage = GetItemMod(ItemDemo_ConjurersCowl, 0) + CalcItemMod(client, ItemDemo_ConjurersCowl, 1, -1);
			int beam = ShootProjectile(client, "tf_projectile_arrow", eyePos, eyeAng, speed, damage);
			SetEntityMoveType(beam, MOVETYPE_FLY);
			SetEntProp(beam, Prop_Send, "m_iProjectileType", 18); // prevent headshots (TF_PROJECTILE_BUILDING_REPAIR_BOLT)
			
			if (result)
			{
				SetEntProp(beam, Prop_Send, "m_bCritical", true);
			}
			
			SetEntityModel(beam, MODEL_INVISIBLE);
			
			char particleName[64];
			if (TF2_GetClientTeam(client) == TFTeam_Red)
				particleName = "drg_cow_rockettrail_fire";
			else
				particleName = "drg_cow_rockettrail_fire_blue";
			
			int particle = CreateEntityByName("info_particle_system");
			DispatchKeyValue(particle, "effect_name", particleName);
			TeleportEntity(particle, eyePos);
			DispatchSpawn(particle);
			
			ActivateEntity(particle);
			AcceptEntityInput(particle, "Start");
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", beam);
			
			EmitSoundToAll(SOUND_DEMO_BEAM, client);
		}
	}
	
	return changed ? Plugin_Changed : Plugin_Continue;
}

public void RF_NextPrimaryAttack(int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return;
	
	int weapon = EntRefToEntIndex(g_iLastFiredWeapon[client]);
	if (weapon == INVALID_ENT_REFERENCE)
		return;
	
	float gameTime = g_flWeaponFireTime[client];
	float time = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
	
	time -= gameTime;
	time *= GetPlayerFireRateMod(client);
	
	// Melee weapons have a swing speed cap
	if (time < 0.3 && GetPlayerWeaponSlot(client, WeaponSlot_Melee) == weapon)
	{
		time = 0.3;
	}
	
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", gameTime+time);
}

public Action Hook_ForceProjectileDamage(int entity, int other)
{
	if (!(other > 0 && other <= MaxClients) && !IsNPC(other) && !IsBuilding(other))
	{
		return Plugin_Handled;
	}
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (!IsValidEntity(owner))
	{
		owner = 0;
	}
	
	float damage = g_flProjectileForcedDamage[entity];
	int damageFlags = DMG_SONIC;
	if (HasEntProp(entity, Prop_Send, "m_bCritical") && GetEntProp(entity, Prop_Send, "m_bCritical"))
	{
		damageFlags |= DMG_CRIT;
	}
	
	SDKHooks_TakeDamage(other, entity, owner, damage, damageFlags, _, _, _, false);
	return Plugin_Handled;
}

public void TF2_OnWaitingForPlayersStart()
{
	if (!RF2_IsEnabled())
		return;
	
	// Hide any map spawned objects
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		if (entity <= MaxClients)
			continue;
		
		if (IsObject(entity) && GetEntProp(entity, Prop_Data, "m_bMapPlaced"))
		{
			AcceptEntityInput(entity, "TurnOff");
		}
	}
	
	if (g_cvAlwaysSkipWait.BoolValue)
	{
		InsertServerCommand("mp_restartgame_immediate 1");
	}
	
	g_bWaitingForPlayers = true;
	PrintToServer("[RF2] Waiting For Players sequence started.");
}

public void TF2_OnWaitingForPlayersEnd()
{
	if (!RF2_IsEnabled())
		return;
	
	g_bWaitingForPlayers = false;
	PrintToServer("[RF2] Waiting For Players sequence ended.");
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!RF2_IsEnabled() || entity < 0 || entity >= MAX_EDICTS)
		return;
	
	g_iItemDamageProc[entity] = Item_Null;
	
	g_bDontDamageOwner[entity] = false;
	g_bDontRemoveWearable[entity] = false;
	g_bItemWearable[entity] = false;
	g_bCashBomb[entity] = false;
	g_bPyromancerFireball[entity] = false;
	g_bFiredWhileRocketJumping[entity] = false;
	
	if (strcmp2(classname, "tf_projectile_rocket") || strcmp2(classname, "tf_projectile_flare") || strcmp2(classname, "tf_projectile_arrow"))
	{
		SDKHook(entity, SDKHook_SpawnPost, Hook_ProjectileSpawnPost);
	}
	else if (StrContains(classname, "item_") == 0)
	{
		if (StrContains(classname, "item_currencypack") == 0)
		{
			SDKHook(entity, SDKHook_SpawnPost, Hook_CashSpawnPost);
			SDKHook(entity, SDKHook_StartTouch, Hook_CashTouch);
			SDKHook(entity, SDKHook_Touch, Hook_CashTouch);
		}
		else if (StrContains(classname, "item_healthkit") == 0) // Sandvich?
		{
			SDKHook(entity, SDKHook_SpawnPost, Hook_HealthKitSpawnPost);
		}
		else
		{
			RemoveEntity(entity);
		}
	}
	else if (!g_bMapChanging && strcmp2(classname, "prop_dynamic"))
	{
		// temp fix for maps not updated to use new entities yet
		SDKHook(entity, SDKHook_SpawnPost, Hook_TempTeleporterFix);
	}
	else if (IsEntityBlacklisted(classname))
	{
		RemoveEntity(entity);
	}
	else if (IsBuilding(entity))
	{
		if (g_hSDKStartUpgrading)
		{
			DHookEntity(g_hSDKStartUpgrading, false, entity, _, DHook_StartUpgrading);
			DHookEntity(g_hSDKStartUpgrading, true, entity, _, DHook_StartUpgradingPost);
		}
	}
	else if (IsNPC(entity))
	{
		SDKHook(entity, SDKHook_OnTakeDamageAlive, Hook_NPCOnTakeDamageAlive);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (!RF2_IsEnabled() || entity < 0 || entity >= MAX_EDICTS)
		return;
		
	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	
	if (classname[0] == 't' && strcmp2(classname, "tf_wearable"))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGameEx(i))
				continue;
				
			if (g_iPlayerStatWearable[i] == entity)
			{
				g_iPlayerStatWearable[i] = -1;
				break;
			}
		}
	}
	else if (classname[0] == 'o' && StrContains(classname, "obj_") != -1)
	{
		if (TF2_GetObjectType(entity) == TFObject_Sentry)
		{
			int index;
			int builder = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
			
			if (builder > 0 && (index = g_hPlayerExtraSentryList[builder].FindValue(entity)) != -1)
			{
				g_hPlayerExtraSentryList[builder].Erase(index);
			}
		}
	}
	else if (g_bCashBomb[entity])
	{
		float pos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
		SpawnCashDrop(g_flCashBombAmount[entity], pos, g_iCashBombSize[entity]);
		
		EmitAmbientSound(SOUND_CASH, pos);
		TE_TFParticle("env_grinder_oilspray_cash", pos);
		TE_TFParticle("mvm_cash_explosion", pos);
	}
}

bool IsEntityBlacklisted(const char[] classname)
{
	return (strcmp2(classname, "func_regenerate") || strcmp2(classname, "tf_ammo_pack") || strcmp2(classname, "halloween_souls_pack") || strcmp2(classname, "teleport_vortex"));
}

public void Hook_ProjectileSpawnPost(int entity)
{
	int launcher = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if (launcher > 0 && IsValidClient(owner))
	{
		char buffer[PLATFORM_MAX_PATH];
		TF2Attrib_HookValueString("", "custom_projectile_model", launcher, buffer, sizeof(buffer));
		
		if (buffer[0])
		{
			SetEntityModel(entity, buffer);
		}
		
		GetEntityClassname(entity, buffer, sizeof(buffer));
		if (strcmp2(buffer, "tf_projectile_rocket"))
		{
			if (PlayerHasItem(owner, ItemSoldier_Compatriot) && CanUseCollectorItem(owner, ItemSoldier_Compatriot) && TF2_IsPlayerInConditionEx(owner, TFCond_BlastJumping))
			{
				g_bFiredWhileRocketJumping[entity] = true;
			}
		}
		else if (strcmp2(buffer, "tf_projectile_arrow"))
		{
			int type = GetEntProp(entity, Prop_Send, "m_iProjectileType");
			if (type == 8 || type == 19) // TF_PROJECTILE_ARROW or TF_PROJECTILE_FESTIVE_ARROW
			{
				if (TF2Attrib_HookValueInt(0, "set_weapon_mode", launcher) >= 1) // no headshots
				{
					SetEntProp(entity, Prop_Send, "m_iProjectileType", 18); // TF_PROJECTILE_BUILDING_REPAIR_BOLT
				}
			}
		}
	}
}

public void Hook_HealthKitSpawnPost(int entity)
{
	// make sure we don't accidentally delete thrown lunchbox items
	if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") <= 0)
	{
		RemoveEntity(entity);
	}
	else
	{
		SDKHook(entity, SDKHook_StartTouch, Hook_HealthKitTouch);
		SDKHook(entity, SDKHook_Touch, Hook_HealthKitTouch);
	}
}

public Action Hook_HealthKitTouch(int entity, int other)
{
	if (other > 0 && other <= MaxClients && GetClientTeam(other) == TEAM_ENEMY)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void Hook_CashSpawnPost(int entity)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (owner > 0)
	{
		char classname[16];
		GetEntityClassname(owner, classname, sizeof(classname));
		
		// remove cash drops spawned by tank_boss and base_boss
		if (strcmp2(classname, "tank_boss") || strcmp2(classname, "base_boss"))
		{
			RemoveEntity(entity);
		}
	}
}

public Action Hook_CashTouch(int entity, int other)
{
	if (IsValidClient(other))
	{
		if (!IsPlayerSurvivor(other))
			return Plugin_Handled;
		
		PickupCash(other, entity);
	}
	
	return Plugin_Continue;
}

public void Hook_TempTeleporterFix(int entity)
{
	char name[32];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
	
	if (strcmp2(name, "rf2_object_teleporter"))
	{
		float pos[3], angles[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
		GetEntPropVector(entity, Prop_Send, "m_angRotation", angles);
		
		int spawnPoint = CreateEntityByName("rf2_teleporter_spawn");
		TeleportEntity(spawnPoint, pos, angles);
		DispatchSpawn(spawnPoint);
		
		RemoveEntity(entity);
	}
}

// TF2_OnTakeDamage is not called for NPCs
public Action Hook_NPCOnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, 
float damageForce[3], float damagePosition[3], int damageCustom)
{
	CritType critType = CritType_None;
	return TF2_OnTakeDamage(victim, attacker, inflictor, damage, damageType, weapon, damageForce, damagePosition, damageCustom, critType);
}

float g_flPlayerVelocity[MAXTF2PLAYERS][3];
float g_flDamageProc;

// Do not modify/access crit type variable here, see TF2_OnTakeDamageModifyRules()
public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, 
float damageForce[3], float damagePosition[3], int damageCustom, CritType &critType)
{
	if (!RF2_IsEnabled() || !g_bRoundActive)
		return Plugin_Continue;
	
	bool attackerIsClient = IsValidClient(attacker);
	bool inflictorIsBuilding = IsBuilding(inflictor);
	bool attackerIsNpc = IsNPC(attacker);
	if (!attackerIsClient && !inflictorIsBuilding && !attackerIsNpc)
	{
		return Plugin_Continue;
	}
	
	bool victimIsClient = IsValidClient(victim);
	bool victimIsBuilding = IsBuilding(victim);
	bool victimIsNpc = IsNPC(victim);
	if (!victimIsClient && !victimIsBuilding && !victimIsNpc)
	{
		return Plugin_Continue;
	}

	if (g_bDontDamageOwner[inflictor] && victim == GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity"))
	{
		return Plugin_Handled;
	}
	
	float originalDamage = damage;
	CritType originalCritType = critType;
	
	bool ignoreResist;
	if (!ignoreResist && attackerIsClient && weapon > -1)
	{
		int initial;
		if (TF2Attrib_HookValueInt(initial, "mod_pierce_resists_absorbs", weapon) > 0)
		{
			ignoreResist = true;
		}
	}
	
	static char inflictorClassname[64];
	GetEntityClassname(inflictor, inflictorClassname, sizeof(inflictorClassname));
	
	bool selfDamage = (attacker == victim || inflictor == victim);
	bool rangedDamage = (damageType & DMG_BULLET || damageType & DMG_BLAST || damageType & DMG_IGNITE || damageType & DMG_SONIC);
	bool invuln;
	
	if (victimIsClient)
	{
		invuln = IsInvuln(victim);
	}
	else if (victimIsNpc)
	{
		static char classname[128];
		GetEntityClassname(victim, classname, sizeof(classname));
		
		if (inflictorIsBuilding)
		{
			if (strcmp2(classname, "rf2_npc_sentry_buster"))
			{
				damage *= 0.25;
				
				if (damage < 1.0)
					damage = 1.0;
			}
		}
		else if (attackerIsClient && IsPlayerSurvivor(attacker) && g_iPlayerLastAttackedTank[attacker] != victim && strcmp2(classname, "tank_boss"))
		{
			g_iPlayerLastAttackedTank[attacker] = victim;
		}
	}
	
	// Proc coefficient calculation. Like Risk of Rain 2, this is a value that affects
	// the rate at which certain items proc (such as Law).
	// Important for things like miniguns and flamethrowers that send tons of damage events.
	float proc = 1.0;
	
	if (attackerIsClient)
	{
		if (weapon > 0)
		{
			proc *= GetWeaponProcCoefficient(weapon);
		}
		
		if (strcmp2(inflictorClassname, "tf_projectile_rocket") || strcmp2(inflictorClassname, "tf_projectile_energy_ball") || strcmp2(inflictorClassname, "tf_projectile_sentryrocket"))
		{
			int enemy = GetEntDataEnt2(inflictor, FindSendPropInfo("CTFProjectile_Rocket", "m_hLauncher") + 16); // m_hEnemy
			if (enemy != victim) // enemy == victim means direct damage was dealt, otherwise this is splash
			{
				proc *= 0.5;
			}
		}
		else if (strcmp2(inflictorClassname, "tf_projectile_pipe"))
		{
			float directDamage = GetEntDataFloat(inflictor, FindSendPropInfo("CTFGrenadePipebombProjectile", "m_bDefensiveBomb") - 4);
			if (originalDamage < directDamage) // non direct hit
			{
				proc *= 0.5;
			}
		}
		else if (strcmp2(inflictorClassname, "tf_projectile_pipe_remote"))
		{
			proc *= 0.5;
		}
		
		switch (damageCustom)
		{
			case TF_CUSTOM_SPELL_FIREBALL:
			{
				proc *= 0.5;
				
				if (victimIsClient)
				{
					// Seems to remove most of the knockback. There's still an upwards push, but that's fine.
					GetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", g_flPlayerVelocity[victim]);
					RequestFrame(RF_RemoveFireballKnockback, victim);
				}
				
				/*
				// We can't set fireball damage normally. Need to do it here.
				if (g_bPyromancerFireball[inflictor])
				{
					damage = GetItemMod(ItemPyro_PyromancerMask, 0) + CalcItemMod(attacker, ItemPyro_PyromancerMask, 1, -1);
				}
				
				// Fireballs nearly always do two instances of damage (unless the AOE just barely touches you). So we halve the damage.
				damage *= 0.5;
				*/
			}
			
			case TF_CUSTOM_BURNING, TF_CUSTOM_BLEEDING:
			{
				proc *= 0.75;
			}
		}
		
		if (IsPlayerSurvivor(attacker))
		{
			damage *= 1.0 + (float(GetPlayerLevel(attacker)-1) * g_cvSurvivorDamageScale.FloatValue);
		}
		else
		{
			damage *= GetEnemyDamageMult();
		}
		
		if (strcmp2(inflictorClassname, "entity_medigun_shield"))
		{
			proc *= 0.02; // This thing does damage every damn tick
		}
		
		if (g_bFiredWhileRocketJumping[inflictor] && PlayerHasItem(attacker, ItemSoldier_Compatriot) && CanUseCollectorItem(attacker, ItemSoldier_Compatriot))
		{
			damage *= 1.0 + CalcItemMod(attacker, ItemSoldier_Compatriot, 0);
		}
		
		int procItem = GetEntItemDamageProc(attacker);
		if (procItem > Item_Null) // client
		{
			proc *= GetItemProcCoefficient(procItem);
			SetEntItemDamageProc(attacker, Item_Null);
		}
		
		if (GetEntItemDamageProc(inflictor) != procItem)
		{
			proc *= GetItemProcCoefficient(GetEntItemDamageProc(inflictor));
		}
		
		if (inflictorIsBuilding)
		{
			if (victimIsClient && PlayerHasItem(attacker, ItemEngi_HeadOfDefense) && CanUseCollectorItem(attacker, ItemEngi_HeadOfDefense))
			{
				if (GetEntProp(inflictor, Prop_Send, "m_bMiniBuilding"))
				{
					TF2_AddCondition(victim, TFCond_MarkedForDeathSilent, GetItemMod(ItemEngi_HeadOfDefense, 1), attacker);
				}
			}
			
			if (PlayerHasItem(attacker, ItemEngi_BrainiacHairpiece) && CanUseCollectorItem(attacker, ItemEngi_BrainiacHairpiece))
			{
				if (g_flSentryNextLaserTime[inflictor] <= GetTickedTime())
				{
					float pos[3], victimPos[3], angles[3];
					GetEntPropVector(inflictor, Prop_Data, "m_vecAbsOrigin", pos);
					GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", victimPos);
					pos[2] += 40.0;
					victimPos[2] += 40.0;
					GetVectorAnglesTwoPoints(pos, victimPos, angles);
					
					int colors[4];
					colors[3] = 255;
					if (TF2_GetClientTeam(attacker) == TFTeam_Red)
					{
						colors[0] = 255;
						colors[1] = 100;
						colors[2] = 100;
					}
					else
					{
						colors[0] = 100;
						colors[1] = 100;
						colors[2] = 255;
					}
					
					float laserDamage, size;
					laserDamage = GetItemMod(ItemEngi_BrainiacHairpiece, 2);
					size = GetItemMod(ItemEngi_BrainiacHairpiece, 3);
					
					FireLaser(attacker, ItemEngi_BrainiacHairpiece, pos, angles, true, _, 
					laserDamage, DMG_SONIC|DMG_PREVENT_PHYSICS_FORCE, size, colors);
					
					float time = GetItemMod(ItemEngi_BrainiacHairpiece, 0);
					time *= CalcItemMod_HyperbolicInverted(attacker, ItemEngi_BrainiacHairpiece, 1, -1);
					g_flSentryNextLaserTime[inflictor] = GetTickedTime()+time;
				}
			}
		}
		
		if (!victimIsBuilding && !victimIsNpc)
		{
			if (selfDamage && GetBossType(victim) >= 0 && !g_bBossAllowSelfDamage[GetBossType(victim)] &&
			(!PlayerHasItem(victim, Item_HorrificHeadsplitter) && damageCustom != TF_CUSTOM_BLEEDING))
			{
				// bosses normally don't do damage to themselves
				damage = 0.0;
				return Plugin_Changed;
			}
			
			// backstabs do set damage against survivors and bosses
			if (damageCustom == TF_CUSTOM_BACKSTAB)
			{
				if (GetBossType(victim) >= 0)
				{
					int stabType = g_cvBossStabDamageType.IntValue;
					if (stabType == StabDamageType_Raw)
					{
						damage = g_cvBossStabDamageAmount.FloatValue;
					}
					else if (stabType == StabDamageType_Percentage)
					{
						damage = float(RF2_GetCalculatedMaxHealth(victim)) * g_cvBossStabDamagePercent.FloatValue;
					}
					
					damage *= 1.0 + CalcItemMod(attacker, ItemSpy_NohMercy, 0);
				}
				else if (IsPlayerSurvivor(victim))
				{
					damage = float(RF2_GetCalculatedMaxHealth(victim)) * 0.35;
				}
			}
		}
		
		// Horrific Headsplitter
		if (victimIsClient && PlayerHasItem(victim, Item_HorrificHeadsplitter) && damageCustom == TF_CUSTOM_BLEEDING)
		{
			if (!g_bGracePeriod)
			{
				int level = GetPlayerLevel(victim);
				damage *= 1.0 + CalcItemMod(victim, Item_HorrificHeadsplitter, 1) * (1.0 + (float(level-1) * GetItemMod(Item_HorrificHeadsplitter, 0)));
			}
			else
			{
				damage = 0.0; // don't damage us during grace period, as we'll have nothing to kill
				RequestFrame(RF_ClearViewPunch, victim);
				return Plugin_Handled;
			}
			
			RequestFrame(RF_ClearViewPunch, victim);
		}
		
		if (!selfDamage && !invuln) // General damage modifications will be done here
		{
			if (PlayerHasItem(attacker, Item_PointAndShoot))
			{
				int maxStacks = RoundToFloor(CalcItemMod(attacker, Item_PointAndShoot, 0));
				if (g_iPlayerFireRateStacks[attacker] < maxStacks)
				{
					g_iPlayerFireRateStacks[attacker]++;
					
					float duration = GetItemMod(Item_PointAndShoot, 2) * proc;
					if (duration < 0.25)
						duration = 0.25;
					
					CreateTimer(duration, Timer_DecayFireRateBuff, attacker, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			
			// Misfortune Fedora and Class Crown increase overall damage
			if (PlayerHasItem(attacker, Item_ClassCrown))
			{
				damage *= 1.0 + CalcItemMod(attacker, Item_ClassCrown, 2);
			}
			
			if (PlayerHasItem(attacker, Item_MisfortuneFedora))
			{
				damage *= 1.0 + CalcItemMod(attacker, Item_MisfortuneFedora, 1);
			}
			
			if (damageType & DMG_MELEE)
			{
				// Eye Catcher and Saxton Hat increase melee damage
				if (PlayerHasItem(attacker, Item_EyeCatcher))
				{
					damage *= 1.0 + CalcItemMod(attacker, Item_EyeCatcher, 0);
				}
				
				if (PlayerHasItem(attacker, Item_SaxtonHat))
				{
					damage *= 1.0 + CalcItemMod(attacker, Item_SaxtonHat, 0);
				}
			}
			else if (rangedDamage)
			{
				if (PlayerHasItem(attacker, Item_Goalkeeper))
				{
					// Ranged damage penalty
					damage *= CalcItemMod_HyperbolicInverted(attacker, Item_Goalkeeper, 2);
				}
			}
			
			if (PlayerHasItem(attacker, ItemSpy_CounterfeitBillycock) && CanUseCollectorItem(attacker, ItemSpy_CounterfeitBillycock))
			{
				if (TF2_IsPlayerInConditionEx(attacker, TFCond_Disguised) || TF2_IsPlayerInConditionEx(attacker, TFCond_DisguiseRemoved))
				{
					damage *= 1.0 + CalcItemMod(attacker, ItemSpy_CounterfeitBillycock, 0);
				}
			}
		}
	}
	else if (attackerIsNpc)
	{
		if (strcmp2(inflictorClassname, "headless_hatman")) // this guy does 80% of victim HP, that is a big nono
		{
			damage = 350.0 * GetEnemyDamageMult();
		}
		else if (strcmp2(inflictorClassname, "eyeball_boss"))
		{
			damage *= GetEnemyDamageMult();
		}
	}
	
	// Now for our resistances
	if (victimIsClient && !ignoreResist)
	{
		if (rangedDamage && PlayerHasItem(victim, Item_DarkHelm))
		{
			damage *= CalcItemMod_HyperbolicInverted(victim, Item_DarkHelm, 0);
		}
		
		if (PlayerHasItem(victim, ItemSpy_CounterfeitBillycock) && CanUseCollectorItem(victim, ItemSpy_CounterfeitBillycock))
		{
			// If we're disguised and uncloaked, this item gives us resist
			if (TF2_IsPlayerInConditionEx(victim, TFCond_Disguised) && !TF2_IsPlayerInConditionEx(victim, TFCond_Cloaked))
			{
				damage *= CalcItemMod_HyperbolicInverted(victim, ItemSpy_CounterfeitBillycock, 1);
			}
		}
	}

	/**
	 *
	 *
	 * !!!Below this line is post damage calculation!!!
	 * !!!DO NOT add any damage-modifying calculations below this line!!!
	 *
	 *
	 */
	
	if (victimIsClient)
	{
		if (CanPlayerRegen(victim))
		{
			const float regenTimeMin  = 0.5;
			const float regenTimeMax  = 5.0;
			
			float seconds = 5.0 * (damage / float(RF2_GetCalculatedMaxHealth(victim)));
			if (seconds > regenTimeMax)
			{
				seconds = regenTimeMax;
			}
			else if (seconds < regenTimeMin)
			{
				seconds = regenTimeMin;
			}
			
			g_flPlayerHealthRegenTime[victim] += seconds;
			if (g_flPlayerHealthRegenTime[victim] > regenTimeMax)
				g_flPlayerHealthRegenTime[victim] = regenTimeMax;
		}
		
		if (!invuln)
		{
			if (PlayerHasItem(victim, Item_PocketMedic))
			{
				// check after the damage is dealt
				RequestFrame(RF_CheckHealthForPocketMedic, victim);
			}
		}
	}
	
	if (attackerIsClient)
	{
		if (!selfDamage && !invuln)
		{
			if (PlayerHasItem(attacker, Item_Law) && GetEntItemDamageProc(inflictor) != Item_Law)
			{
				float random = GetItemMod(Item_Law, 0);
				random *= proc;
				
				if (RandChanceFloatEx(attacker, 0.0, 1.0, random))
				{
					int rocket = CreateEntityByName("tf_projectile_sentryrocket");
					SetEntProp(rocket, Prop_Data, "m_iTeamNum", GetClientTeam(attacker));
					SetEntityOwner(rocket, attacker);
					int offset = FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected")+4; // m_flDamage
					SetEntDataFloat(rocket, offset, GetItemMod(Item_Law, 1) + CalcItemMod(attacker, Item_Law, 2), true); 
					g_bDontDamageOwner[rocket] = true;
					
					SetEntItemDamageProc(attacker, Item_Law);
					SetEntItemDamageProc(rocket, Item_Law);
					
					const float rocketSpeed = 1200.0;
					float angles[3];
					float velocity[3];
					float pos[3];
					float enemyPos[3];
					GetClientAbsOrigin(attacker, pos);
					GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", enemyPos);
					pos[2] += 30.0;
					enemyPos[2] += 30.0;
					
					GetVectorAnglesTwoPoints(pos, enemyPos, angles);
					GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
					NormalizeVector(velocity, velocity);
					ScaleVector(velocity, rocketSpeed);
					TeleportEntity(rocket, pos, angles, velocity);
					DispatchSpawn(rocket);
					
					EmitSoundToAll(SOUND_LAW_FIRE, attacker, _, _, _, 0.6);
				}
			}
			
			if (PlayerHasItem(attacker, Item_HorrificHeadsplitter))
			{
				int healAmount = RoundToFloor(damage * CalcItemMod_Hyperbolic(attacker, Item_HorrificHeadsplitter, 0));
				
				if (healAmount < 1)
					healAmount = 1;
				
				HealPlayer(attacker, healAmount, false);
			}
		}
	}
	
	if (victimIsClient && damage <= 0.0)
	{
		RequestFrame(RF_ClearViewPunch, victim);
	}
	
	g_flDamageProc = proc; // carry over to TF2_OnTakeDamageModifyRules()
	if (damage != originalDamage || critType != originalCritType)
		return Plugin_Changed;

	return Plugin_Continue;
}

public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, 
float damageForce[3], float damagePosition[3], int damageCustom, CritType &critType)
{
	if (!RF2_IsEnabled() || !g_bRoundActive)
		return Plugin_Continue;
	
	CritType originalCritType = critType;
	float proc = g_flDamageProc;
	
	if (IsValidClient(attacker))
	{
		// Check for full crits for any damage that isn't against a building.
		// Don't do this for bullet or melee weapons - we already do that in TF2_CalcIsAttackCritical().
		if (!IsBuilding(victim) && critType != CritType_Crit && !(damageType & DMG_MELEE) && !(damageType & DMG_BULLET) && !(damageType & DMG_BUCKSHOT)
		|| critType == CritType_MiniCrit && !PlayerHasItem(attacker, Item_Executioner))
		{
			static char classname[64];
			GetEntityClassname(inflictor, classname, sizeof(classname));
			bool projCrit = StrContains(classname, "tf_proj") != -1 && HasEntProp(inflictor, Prop_Send, "m_bCritical");
			
			if (!projCrit && RollAttackCrit(attacker, proc))
			{
				critType = CritType_Crit;
			}
		}
		
		// Executioner converts minicrits to full crits
		if (PlayerHasItem(attacker, Item_Executioner) && critType == CritType_MiniCrit)
		{
			critType = CritType_Crit;
		}
		
		if (critType != CritType_None)
		{
			switch (critType)
			{
				case CritType_Crit:
				{
					// Cryptic Keepsake converts crit chance to crit damage, other than its own crit chance
					if (PlayerHasItem(attacker, Item_CrypticKeepsake))
					{
						if (PlayerHasItem(attacker, Item_TombReaders))
						{
							damage *= 1.0 + CalcItemMod(attacker, Item_TombReaders, 0);
						}
						
						if (PlayerHasItem(attacker, Item_SaxtonHat) && damageType & DMG_MELEE && damageCustom != TF_CUSTOM_BACKSTAB)
						{
							damage *= 1.0 + CalcItemMod(attacker, Item_SaxtonHat, 1);
						}
						
						if (PlayerHasItem(attacker, Item_BruiserBandana))
						{
							damage *= 1.0 + GetItemMod(Item_BruiserBandana, 1);
						}
					}
					
					// Executioner has a chance to cause bleeding on crit damage
					if (IsValidClient(victim) && PlayerHasItem(attacker, Item_Executioner))
					{
						float random = CalcItemMod_Hyperbolic(attacker, Item_Executioner, 0);
						random *= proc;
						if (RandChanceFloatEx(attacker, 0.0, 1.0, random))
						{
							TF2_MakeBleed(victim, attacker, GetItemMod(Item_Executioner, 1));
						}
					}
				}
			}
			
			
			// Bruiser's Bandana increases any damage that is a crit or mini-crit
			if (PlayerHasItem(attacker, Item_BruiserBandana))
			{
				damage *= 1.0 + CalcItemMod(attacker, Item_BruiserBandana, 0);
			}
		}
	}
	
	if (originalCritType != critType)
	{
		// An issue will occur when changing the crit type here where it plays the wrong effect or no effect at all,
		// but this should correct the damage values. We can only create the correct effect manually; the incorrect one cannot be removed at this point.
		switch (originalCritType)
		{
			case CritType_None:
			{
				damageType |= DMG_CRIT;
				
				if (critType == CritType_Crit)
				{
					TE_TFParticle("crit_text", damagePosition, victim);
					EmitGameSoundToClient(attacker, SCSOUND_CRIT);
					damage *= 3.0;
				}
				else
				{
					TE_TFParticle("minicrit_text", damagePosition, victim);
					EmitGameSoundToClient(attacker, SCSOUND_MINICRIT);
					damage *= 1.35;
				}
			}
			
			case CritType_MiniCrit:
			{
				if (critType == CritType_Crit)
				{
					TE_TFParticle("crit_text", damagePosition, victim);
					EmitGameSoundToClient(attacker, SCSOUND_CRIT);
					damage *= 0.741;
					damage *= 3.0;
				}
				else
				{
					damage *= 0.741;
				}
			}
			
			case CritType_Crit:
			{
				if (critType == CritType_MiniCrit)
				{
					TE_TFParticle("minicrit_text", damagePosition, victim);
					EmitGameSoundToClient(attacker, SCSOUND_MINICRIT);
					damage /= 3.0;
					damage *= 1.35;
				}
				else
				{
					damage /= 3.0;
				}
			}
		}
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public void RF_RemoveFireballKnockback(int client)
{
	TeleportEntity(client, _, _, g_flPlayerVelocity[client]);
}

public void Hook_WeaponSwitch(int client, int weapon)
{
	if (IsFakeClientEx(client))
	{
		g_TFBot[client].RemoveButtonFlag(IN_RELOAD);
	}
	else if (!g_bPlayerExtraSentryHint[client] && PlayerHasItem(client, ItemEngi_HeadOfDefense) && CanUseCollectorItem(client, ItemEngi_HeadOfDefense))
	{
		char classname[64];
		GetEntityClassname(weapon, classname, sizeof(classname));
		if (strcmp2(classname, "tf_weapon_pda_engineer_build")) // PDA won't allow us to build extra sentries using it
		{
			PrintHintText(client, "Press ATTACK3 (Middle Mouse Button) to build extra sentries. TAB + ATTACK3 to detonate them.");
			g_bPlayerExtraSentryHint[client] = true;
		}
	}
}

public Action Hook_DisableTouch(int entity, int other)
{
	return Plugin_Handled;
}

public void RF_CheckHealthForPocketMedic(int client)
{
	if (!IsClientInGameEx(client) || !IsPlayerAlive(client))
		return;
	
	int health = GetClientHealth(client);
	int maxHealth = RF2_GetCalculatedMaxHealth(client);
	if (health < float(maxHealth) * GetItemMod(Item_PocketMedic, 0))
	{
		EmitSoundToAll(SOUND_SHIELD, client);
		TF2_AddCondition(client, TFCond_UberchargedCanteen, GetItemMod(Item_PocketMedic, 2));
		
		int heal = RoundToFloor(float(maxHealth) * GetItemMod(Item_PocketMedic, 1));
		HealPlayer(client, heal, false);
		
		PrintHintText(client, "Pocket Medic activated!");
		GiveItem(client, Item_PocketMedic, -1);
	}
}

public void RF_ClearViewPunch(int client)
{
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", {0.0, 0.0, 0.0});
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", {0.0, 0.0, 0.0});
}

public Action Timer_DecayFireRateBuff(Handle timer, int client)
{
	if (g_iPlayerFireRateStacks[client] > 0)
	{
		g_iPlayerFireRateStacks[client]--;
	}
	
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype)
{
	if (RF2_IsEnabled())
	{
		Action action = Plugin_Continue;
		
		if (IsFakeClientEx(client))
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
		if (!IsFakeClientEx(client) && buttons & IN_RELOAD)
		{
			if (!reloadPressed[client])
			{
				// Don't conflict with the Vaccinator or Eureka Effect. Player must be pressing IN_SCORE when holding these weapons.
				bool tabRequired;
				int initial;
				
				if (TF2_GetPlayerClass(client) == TFClass_Medic)
				{
					int medigun = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
					if (medigun > -1 && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == medigun)
					{
						initial = TF2Attrib_HookValueInt(0, "set_charge_type", medigun);
						
						if (initial == 3)
						{
							tabRequired = true;
						}
					}
				}
				else if (TF2_GetPlayerClass(client) == TFClass_Engineer)
				{
					int wrench = GetPlayerWeaponSlot(client, WeaponSlot_Melee);
					if (wrench > -1 && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == wrench)
					{
						initial = TF2Attrib_HookValueInt(0, "alt_fire_teleport_to_spawn", wrench);
						
						if (initial > 0)
						{
							tabRequired = true;
						}
					}
				}
				
				if ((!tabRequired || buttons & IN_SCORE) && GetPlayerEquipmentItem(client) > Item_Null)
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

		static bool attack3Pressed[MAXTF2PLAYERS];
		if (!IsFakeClientEx(client) && buttons & IN_ATTACK3)
		{
			if (!attack3Pressed[client])
			{
				if (TF2_GetPlayerClass(client) == TFClass_Engineer)
				{
					if (buttons & IN_SCORE)
					{
						if (g_hPlayerExtraSentryList[client].Length > 0)
						{
							int entity = g_hPlayerExtraSentryList[client].Get(0);
							if (IsValidEntity(entity))
							{
								SetVariantInt(GetEntProp(entity, Prop_Send, "m_iHealth")+9999);
								AcceptEntityInput(entity, "RemoveHealth");
							}
						}
					}
					else
					{
						FakeClientCommand(client, "build 2");
					}
				}
			}
			
			attack3Pressed[client] = true;
		}
		else
		{
			attack3Pressed[client] = false;
		}
		
		static float nextFootstepTime[MAXTF2PLAYERS];
		if (g_iPlayerFootstepType[client] == FootstepType_GiantRobot && GetTickedTime() >= nextFootstepTime[client] && !TF2_IsPlayerInConditionEx(client, TFCond_Disguised))
		{
			if ((buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT) && GetEntityFlags(client) & FL_ONGROUND)
			{
				float fwdVel[3], sideVel[3];
				GetAngleVectors(angles, fwdVel, NULL_VECTOR, NULL_VECTOR);
				GetAngleVectors(angles, NULL_VECTOR, sideVel, NULL_VECTOR);
				NormalizeVector(fwdVel, fwdVel);
				NormalizeVector(sideVel, sideVel);
				NormalizeVector(vel, vel);
				
				if (GetVectorDotProduct(fwdVel, vel) != 0.0 || GetVectorDotProduct(sideVel, vel) != 0.0)
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
						{
							FormatEx(sample, sizeof(sample), "mvm/giant_%s/giant_%s_step0%i.wav", classString, classString, GetRandomInt(1, 4));
						}
						else
						{
							FormatEx(sample, sizeof(sample), "mvm/giant_%s/giant_%s_step_0%i.wav", classString, classString, GetRandomInt(1, 4));
						}
					}
					
					if (class == TFClass_Spy)
					{
						if (TF2_IsPlayerInConditionEx(client, TFCond_Disguised) || TF2_IsPlayerInConditionEx(client, TFCond_Cloaked))
						{
							sample = "misc/null.wav";
						}
					}
					
					// avoid repeatedly calling PrecacheSound()
					bool valid = true;
					if (g_hInvalidPlayerSounds.FindString(sample) >= 0)
					{
						valid = false;
					}
					else if (g_hCachedPlayerSounds.FindString(sample) < 0)
					{
						if (PrecacheSound(sample))
						{
							g_hCachedPlayerSounds.PushString(sample);
						}
						else
						{
							g_hInvalidPlayerSounds.PushString(sample);
							valid = false;
						}
					}
					
					if (valid)
					{
						EmitSoundToAll(sample, client);
						float duration = g_flPlayerGiantFootstepInterval[client] * (RF2_GetCalculatedSpeed(client) / RF2_GetBaseSpeed(client));
						nextFootstepTime[client] = GetTickedTime() + duration;
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
	if (!RF2_IsEnabled() || g_bWaitingForPlayers)
		return Plugin_Continue;
	
	if (IsValidClient(client) && (GetClientTeam(client) == TEAM_ENEMY || TF2_IsPlayerInConditionEx(client, TFCond_Disguised)))
	{
		Action action = Plugin_Continue;
		int voiceType = g_iPlayerVoiceType[client];
		int footstepType = g_iPlayerFootstepType[client];
		
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
		
		TFClassType class;
		bool blacklist[MAXTF2PLAYERS];
		
		// If we're disguised, play the original sample to our teammates before doing anything.
		if (TF2_IsPlayerInConditionEx(client, TFCond_Disguised))
		{
			for (int i = 0; i < numClients; i++)
			{
				if (clients[i] == client || !IsValidClient(clients[i]))
					continue;
				
				if (GetClientTeam(clients[i]) == GetClientTeam(client))
				{
					EmitSoundToClient(clients[i], sample, client, channel, level, flags, volume, pitch);
					blacklist[clients[i]] = true;
				}
			}
			
			class = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
		}
		else
		{
			class = TF2_GetPlayerClass(client);
		}
		
		if (StrContains(sample, "vo/") != -1)
		{
			if (voiceType == VoiceType_Silent || g_bPlayerVoiceNoPainSounds[client] && StrContains(sample, "_pain") != -1)
			{
				return Plugin_Stop;
			}
			
			pitch = g_iPlayerVoicePitch[client];
			
			if (voiceType == VoiceType_Robot)
			{
				action = Plugin_Changed;
				
				bool noGiantLines = (class == TFClass_Sniper || class == TFClass_Medic || class == TFClass_Engineer || class == TFClass_Spy);
				char classString[16], newString[32];
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
				
				// avoid repeatedly calling PrecacheSound()
				if (g_hInvalidPlayerSounds.FindString(sample) >= 0)
				{
					return Plugin_Stop;
				}
				else if (g_hCachedPlayerSounds.FindString(sample) < 0)
				{
					if (PrecacheSound(sample))
					{
						g_hCachedPlayerSounds.PushString(sample);
					}
					else
					{
						g_hInvalidPlayerSounds.PushString(sample);
						return Plugin_Stop;
					}
				}
			}
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
				action = Plugin_Stop;
				
				if (TF2_GetPlayerClass(client) == TFClass_Medic) // Robot Medics don't have legs. So this wouldn't make much sense.
					return Plugin_Stop;
				
				// For the love of god...
				if (TF2_IsPlayerInConditionEx(client, TFCond_Taunting))
				{
					return Plugin_Continue;
				}
				else
				{
					int random = GetRandomInt(1, 18);
					if (random > 9)
					{
						FormatEx(sample, sizeof(sample), "mvm/player/footsteps/robostep_%i.wav", random);
					}
					else
					{
						FormatEx(sample, sizeof(sample), "mvm/player/footsteps/robostep_0%i.wav", random);
					}
					
					// avoid repeatedly calling PrecacheSound()
					if (g_hInvalidPlayerSounds.FindString(sample) >= 0)
					{
						return Plugin_Stop;
					}
					else if (g_hCachedPlayerSounds.FindString(sample) < 0)
					{
						if (PrecacheSound(sample))
						{
							g_hCachedPlayerSounds.PushString(sample);
						}
						else
						{
							g_hInvalidPlayerSounds.PushString(sample);
							return Plugin_Stop;
						}
					}
				}
				
				// Only works this way for some reason
				if (TF2_IsPlayerInConditionEx(client, TFCond_Disguised))
				{
					EmitSoundToClient(client, sample, client, channel, level, flags, volume, pitch);
					
					for (int i = 0; i < numClients; i++)
					{
						if (clients[i] != client && !blacklist[clients[i]])
						{
							EmitSoundToClient(clients[i], sample, client, channel, level, flags, volume, pitch);
						}
					}
				}
				else
				{
					EmitSoundToAll(sample, client, channel, level, flags, volume, pitch);
				}
			}
		}
		
		// If we're disguised, don't play the new sound to our teammates
		if (TF2_IsPlayerInConditionEx(client, TFCond_Disguised))
		{
			for (int i = 0; i < numClients; i++)
			{
				if (blacklist[clients[i]])
				{
					// Remove the client from the array.
					for (int j = i; j < numClients-1; j++)
					{
				    	clients[j] = clients[j+1];
					}
					
					numClients--;
					i--;
				}
			}
		}

		return action;
	}
	
	return Plugin_Continue;
}

static float g_flBloodPos[3];
public Action TEHook_TFBlood(const char[] te_name, const int[] clients, int numClients, float delay)
{
	int index = TE_ReadNum("entindex");
	
	if (IsValidClient(index))
	{
		int type = GetEnemyType(index);
		int bossType = GetBossType(index);
		if (type >= 0 && g_bEnemyNoBleeding[type] || bossType >= 0 && g_bBossNoBleeding[bossType])
		{
			g_flBloodPos[0] = TE_ReadFloat("m_vecOrigin[0]");
			g_flBloodPos[1] = TE_ReadFloat("m_vecOrigin[1]");
			g_flBloodPos[2] = TE_ReadFloat("m_vecOrigin[2]");
			RequestFrame(RF_SpawnMechBlood, index);
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

public void RF_SpawnMechBlood(int client)
{
	TE_TFParticle("lowV_blood_impact_red_01", g_flBloodPos);
}

public bool TraceFilter_WallsOnly(int entity, int mask)
{
	return false;
}

public bool TraceFilter_DontHitSelf(int self, int mask, int other)
{
	return !(self == other);
}
