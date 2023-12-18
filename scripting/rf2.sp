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

#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#define REQUIRE_EXTENSIONS

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.1.6b"
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
#define DMG_MELEE DMG_BLAST_SURFACE
#define WORLD_CENTER "rf2_world_center" // An info_target used to determine where the "center" of the world is, according to the map designer


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
#define SND_DEMO_BEAM "rf2/sfx/sword_beam.wav"
#define SND_SAPPER_PLANT "weapons/sapper_plant.wav"
#define SND_SAPPER_DRAIN "weapons/sapper_timer.wav"
#define SND_SPELL_FIREBALL "misc/halloween/spell_fireball_cast.wav"
#define SND_SPELL_FIREBALL_IMPACT "misc/halloween/spell_fireball_impact.wav"
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
#define SND_BOMB_EXPLODE "weapons/loose_cannon_explode.wav"
#define NULL "misc/null.wav"

// Game sounds
#define GSND_CRIT "TFPlayer.CritHit"
#define GSND_MINICRIT "TFPlayer.CritHitMini"
#define GSND_CLEAVER_HIT "Cleaver.ImpactFlesh"


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


// Enemies/Bosses -------------------------------------------------------------------------------------------------------------------------------------
#define MAX_ENEMIES 128
#define MAX_WEARABLES 6
#define MAX_BOSSES 32
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
Handle g_hObjectiveHudSync;
int g_iMainHudR = 100;
int g_iMainHudG = 255;
int g_iMainHudB = 100;
char g_szHudDifficulty[128] = "Difficulty: Easy";
char g_szObjectiveHud[MAXTF2PLAYERS][64];

// g_iStagesCompleted+1, g_iMinutesPassed, hudSeconds, g_iEnemyLevel, g_iPlayerLevel[i], g_flPlayerXP[i], 
// g_flPlayerNextLevelXP[i], g_flPlayerCash[i], g_iPlayerHauntedKeys[i], g_szHudDifficulty, strangeItemInfo, miscText
char g_szSurvivorHudText[2048] = "\n\nStage %i | %02d:%02d\nEnemy Level: %i | Your Level: %i\n%.0f/%.0f XP | Cash: $%.0f | Haunted Keys: %i\n%s\n%s\n\n%s";

// g_iStagesCompleted+1, g_iMinutesPassed, hudSeconds, g_iEnemyLevel, g_szHudDifficulty, strangeItemInfo
char g_szEnemyHudText[1024] = "\n\nStage %i | %02d:%02d\nEnemy Level: %i\n%s\n%s";

// Players
bool g_bPlayerViewingItemMenu[MAXTF2PLAYERS];
bool g_bPlayerIsTeleporterBoss[MAXTF2PLAYERS];
bool g_bPlayerStunnable[MAXTF2PLAYERS] = { true, ... };
bool g_bPlayerIsAFK[MAXTF2PLAYERS];
bool g_bPlayerExtraSentryHint[MAXTF2PLAYERS];
bool g_bPlayerInSpawnQueue[MAXTF2PLAYERS];
bool g_bPlayerHasVampireSapper[MAXTF2PLAYERS];
bool g_bEquipmentCooldownActive[MAXTF2PLAYERS];

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
float g_flPlayerVampireSapperCooldown[MAXTF2PLAYERS];
float g_flPlayerVampireSapperDamage[MAXTF2PLAYERS];
float g_flPlayerVampireSapperDuration[MAXTF2PLAYERS];

int g_iPlayerLevel[MAXTF2PLAYERS] = {1, ...};
int g_iPlayerHauntedKeys[MAXTF2PLAYERS];
int g_iPlayerBaseHealth[MAXTF2PLAYERS] = {1, ...};
int g_iPlayerCalculatedMaxHealth[MAXTF2PLAYERS] = {1, ...};
int g_iPlayerSurvivorIndex[MAXTF2PLAYERS] = {-1, ...};
int g_iPlayerEquipmentItemCharges[MAXTF2PLAYERS] = {1, ...};
int g_iPlayerEnemyType[MAXTF2PLAYERS] = {-1, ...};
int g_iPlayerBossType[MAXTF2PLAYERS] = {-1, ...};
int g_iPlayerEnemySpawnType[MAXTF2PLAYERS] = {-1, ...};
int g_iPlayerBossSpawnType[MAXTF2PLAYERS] = {-1, ...};
int g_iPlayerVoiceType[MAXTF2PLAYERS];
int g_iPlayerVoicePitch[MAXTF2PLAYERS] = {SNDPITCH_NORMAL, ...};
int g_iPlayerFootstepType[MAXTF2PLAYERS] = {FootstepType_Normal, ...};
int g_iPlayerFireRateStacks[MAXTF2PLAYERS];
int g_iPlayerAirDashCounter[MAXTF2PLAYERS];
int g_iPlayerLastAttackedTank[MAXTF2PLAYERS] = {-1, ...};
int g_iPlayerKillfeedItem[MAXTF2PLAYERS];
int g_iItemsTaken[MAX_SURVIVORS];
int g_iItemLimit[MAX_SURVIVORS];
int g_iPlayerVampireSapperAttacker[MAXTF2PLAYERS] = {-1, ...};
int g_iPlayerLastScrapMenuItem[MAXTF2PLAYERS];
int g_iPlayerLastItemMenuItem[MAXTF2PLAYERS];
int g_iPlayerLastDropMenuItem[MAXTF2PLAYERS];

char g_szPlayerOriginalName[MAXTF2PLAYERS][MAX_NAME_LENGTH];
ArrayList g_hPlayerExtraSentryList[MAXTF2PLAYERS];
ArrayList g_hCachedPlayerSounds;
ArrayList g_hInvalidPlayerSounds;

// Entities
int g_iItemDamageProc[MAX_EDICTS];
int g_iCashBombSize[MAX_EDICTS];

bool g_bDontDamageOwner[MAX_EDICTS];
bool g_bCashBomb[MAX_EDICTS];
bool g_bFiredWhileRocketJumping[MAX_EDICTS];
bool g_bDontRemoveWearable[MAX_EDICTS];
bool g_bItemWearable[MAX_EDICTS];
bool g_bFakeFireball[MAX_EDICTS];

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
Handle g_hSDKUpdateSpeed;
Handle g_hSDKDoQuickBuild;
Handle g_hSDKGetMaxHealth;
Handle g_hSDKComputeIncursion;
Handle g_hSDKPlayGesture;
DHookSetup g_hSDKCanBuild;
DHookSetup g_hSDKDoSwingTrace;
DHookSetup g_hSDKSentryAttack;
//DHookSetup g_hSDKComputeIncursionVoid;
DHookSetup g_hSDKHandleRageGain;
DynamicHook g_hSDKTakeHealth;
DynamicHook g_hSDKStartUpgrading;
DynamicHook g_hSDKVPhysicsCollision;
//DynamicHook g_hSDKEffectBarRecharge;

// Forwards
Handle g_fwTeleEventStart;
Handle g_fwTeleEventEnd;
Handle g_fwGracePeriodStart;
Handle g_fwGracePeriodEnded;

// ConVars
//ConVar g_cvMaxHumanPlayers;
ConVar g_cvMaxSurvivors;
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
ConVar g_cvEnemyMinSpawnWaveCount;
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
Cookie g_coTutorialItemPickup;
Cookie g_coTutorialSurvivor;

bool g_bPlayerMusicEnabled[MAXTF2PLAYERS] = {true, ...};
bool g_bPlayerBecomeSurvivor[MAXTF2PLAYERS] = {true, ...};
bool g_bPlayerBecomeBoss[MAXTF2PLAYERS] = {true, ...};
bool g_bPlayerAutomaticItemMenu[MAXTF2PLAYERS] = {true, ...};
int g_iPlayerSurvivorPoints[MAXTF2PLAYERS];

// TFBots
TFBot g_TFBot[MAXTF2PLAYERS];

#define TFBOTFLAG_AGGRESSIVE (1 << 0) // Bot should always act aggressive (relentlessly chase target)
#define TFBOTFLAG_ROCKETJUMP (1 << 1) // Bot should rocket jump
#define TFBOTFLAG_STRAFING (1 << 2) // Bot is currently strafing 
#define TFBOTFLAG_HOLDFIRE (1 << 3) // Hold fire until fully reloaded

// Other
bool g_bThrillerActive;
int g_iThrillerRepeatCount;
ArrayList g_hParticleEffectTable;

#include "rf2/overrides.sp"
#include "rf2/items.sp"
#include "rf2/survivors.sp"
#include "rf2/entityfactory.sp"
#include "rf2/enemies.sp"
#include "rf2/stages.sp"
#include "rf2/objects.sp"
#include "rf2/cookies.sp"
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
	InstallEntities();
	LoadGameData();
	LoadForwards();
	LoadCommandsAndCvars();
	BakeCookies();
	LoadTranslations("common.phrases");
	LoadTranslations("rf2.phrases");
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
			if (!IsPlayerSpectator(i))
				ChangeClientTeam(i, TEAM_ENEMY);

			SetClientName(i, g_szPlayerOriginalName[i]);
		}
	}
}

void LoadGameData()
{
	GameData gamedata = LoadGameConfigFile("rf2");
	if (!gamedata)
	{
		SetFailState("[SDK] Failed to locate gamedata file \"rf2.txt\"");
	}
	
	int offset;
	
	// CBasePlayer::EquipWearable ------------------------------------------------------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKEquipWearable = EndPrepSDKCall();
	if(!g_hSDKEquipWearable)
	{
		LogError("[SDK] Failed to create call for CBasePlayer::EquipWearable");
	}
	
	// CTFPlayer::CanBuild -------------------------------------------------------------------------------------------------------------------
	g_hSDKCanBuild = DHookCreateFromConf(gamedata, "CTFPlayer::CanBuild");
	if (!g_hSDKCanBuild || !DHookEnableDetour(g_hSDKCanBuild, true, DHook_CanBuild))
	{
		LogError("[DHooks] Failed to create detour for CTFPlayer::CanBuild");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::TeamFortress_SetSpeed");
	g_hSDKUpdateSpeed = EndPrepSDKCall();
	if (!g_hSDKUpdateSpeed)
	{
		LogError("[SDK] Failed to create call for CTFPlayer::TeamFortress_SetSpeed");
	}
	
	// CTFPlayer::PlayGesture ----------------------------------------------------------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::PlayGesture");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKPlayGesture = EndPrepSDKCall();
	if (!g_hSDKPlayGesture)
	{
		LogError("Failed to create call for CTFPlayer::PlayGesture");
	}
	
	// CBaseEntity::TakeHealth ---------------------------------------------------------------------------------------------------------------
	offset = GameConfGetOffset(gamedata, "CBaseEntity::TakeHealth");
	g_hSDKTakeHealth = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, DHook_TakeHealth);
	if (g_hSDKTakeHealth)
	{
		DHookAddParam(g_hSDKTakeHealth, HookParamType_Float); // amount to heal
		DHookAddParam(g_hSDKTakeHealth, HookParamType_Int);   // "damagetype"? Doesn't seem to be used.
	}
	else
	{
		LogError("[DHooks] Failed to create virtual hook for CBaseEntity::TakeHealth");
	}

	// CPhysicsProp::VPhysicsCollision -------------------------------------------------------------------------------------------------------
	offset = GameConfGetOffset(gamedata, "CPhysicsProp::VPhysicsCollision");
	g_hSDKVPhysicsCollision = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	if (g_hSDKVPhysicsCollision)
	{
		DHookAddParam(g_hSDKVPhysicsCollision, HookParamType_Int); 			// index
		DHookAddParam(g_hSDKVPhysicsCollision, HookParamType_ObjectPtr); 	// gamevcollisionevent_t
	}
	else
	{
		LogError("[DHooks] Failed to create virtual hook for CPhysicsProp::VPhysicsCollision");
	}
	
	/*
	// CTFWeaponBase::InternalGetEffectBarRechargeTime ---------------------------------------------------------------------------------------
	offset = GameConfGetOffset(gamedata, "CTFWeaponBase::InternalGetEffectBarRechargeTime");
	g_hSDKEffectBarRecharge = DHookCreate(offset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, DHook_GetEffectBarRechargeTime);
	if (!g_hSDKEffectBarRecharge)
	{
		LogError("[DHooks] Failed to create virtual hook for CTFWeaponBase::InternalGetEffectBarRechargeTime");
	}
	*/
	
	// CTFWeaponBase::GetMaxClip1 ------------------------------------------------------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFWeaponBase::GetMaxClip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMaxClip1 = EndPrepSDKCall();
	if (!g_hSDKGetMaxClip1)
	{
		LogError("[SDK] Failed to create call for CTFWeaponBase::GetMaxClip1");
	}
	
	// CTFWeaponBaseMelee::DoSwingTraceInternal ----------------------------------------------------------------------------------------------
	g_hSDKDoSwingTrace = DHookCreateFromConf(gamedata, "CTFWeaponBaseMelee::DoSwingTraceInternal");
	if (!g_hSDKDoSwingTrace || !DHookEnableDetour(g_hSDKDoSwingTrace, false, DHook_DoSwingTrace) || !DHookEnableDetour(g_hSDKDoSwingTrace, true, DHook_DoSwingTracePost))
	{
		LogError("[DHooks] Failed to create detour for CTFWeaponBaseMelee::DoSwingTraceInternal");
	}
	
	// CBaseObject::DoQuickBuild -------------------------------------------------------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseObject::DoQuickBuild");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	g_hSDKDoQuickBuild = EndPrepSDKCall();
	if (!g_hSDKDoQuickBuild)
	{
		LogError("[SDK] Failed to create call for CBaseObject::DoQuickBuild");
	}
	
	// CBaseObject::StartUpgrading -----------------------------------------------------------------------------------------------------------
	offset = GameConfGetOffset(gamedata, "CBaseObject::StartUpgrading");
	g_hSDKStartUpgrading = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	if (!g_hSDKStartUpgrading)
	{
		LogError("[DHooks] Failed to create virtual hook for CBaseObject::StartUpgrading");
	}
	
	// CObjectSentrygun::Attack --------------------------------------------------------------------------------------------------------------
	g_hSDKSentryAttack = DHookCreateFromConf(gamedata, "CObjectSentrygun::Attack");
	if (!g_hSDKSentryAttack || !DHookEnableDetour(g_hSDKSentryAttack, true, DHook_SentryGunAttack))
	{
		LogError("[DHooks] Failed to create detour for CObjectSentrygun::Attack");
	}
	
	g_hSDKHandleRageGain = DHookCreateFromConf(gamedata, "HandleRageGain");
	if (!g_hSDKHandleRageGain || !DHookEnableDetour(g_hSDKHandleRageGain, false, DHook_HandleRageGain))
	{
		LogError("[DHooks] Failed to create detour for HandleRageGain");
	}
	
	// CTFNavMesh::ComputeIncursionDistances -------------------------------------------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFNavMesh::ComputeIncursionDistances");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // spawnArea
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // team
	g_hSDKComputeIncursion = EndPrepSDKCall();
	if (!g_hSDKComputeIncursion)
	{
		LogError("[SDK] Failed to create call for CTFNavMesh::ComputeIncursionDistances");
	}
	
	/*
	// CTFNavMesh::ComputeIncursionDistances(void) -------------------------------------------------------------------------------------------------
	g_hSDKComputeIncursionVoid = DHookCreateFromConf(gamedata, "CTFNavMesh::ComputeIncursionDistances_Void");
	if (!g_hSDKComputeIncursionVoid || !DHookEnableDetour(g_hSDKComputeIncursionVoid, true, DHook_ComputeIncursionVoid))
	{
		LogError("[DHooks] Failed to create detour for CTFNavMesh::ComputeIncursionDistances(void)");
	}
	*/
	
	delete gamedata;
	
	gamedata = LoadGameConfigFile("sdkhooks.games");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	g_hSDKGetMaxHealth = EndPrepSDKCall();
	if (!g_hSDKGetMaxHealth)
	{
		SetFailState("[SDK] Failed to create call for CBasePlayer::GetMaxHealth from SDKHooks gamedata");
	}
	
	delete gamedata;
}

public void OnMapStart()
{
	// Reset our ConVars if we've changed them
	if (g_bConVarsModified)
	{
		ResetConVars();
		g_bConVarsModified = false;
	}
	
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
		g_bWaitingForPlayers = asBool(GameRules_GetProp("m_bInWaitingForPlayers"));
		
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
		
		#if defined _SteamWorks_Included
		if (GetExtensionFileStatus("SteamWorks.ext") == 1)
		{
			char desc[64];
			FormatEx(desc, sizeof(desc), "Risk Fortress 2 - %s (Stage %d)", PLUGIN_VERSION, g_iStagesCompleted+1);
			SteamWorks_SetGameDescription(desc);
		}
		#endif
		
		LoadAssets();
		
		if (!g_bLateLoad)
		{
			AutoExecConfig(true, "RiskFortress2");
		}
		
		// These are ConVars we're OK with being set by server.cfg, but we'll set our personal defaults.
		// If configs wish to change these, they will be overridden by them later.
		FindConVar("sv_alltalk").SetBool(true);
		FindConVar("tf_use_fixed_weaponspreads").SetBool(true);
		FindConVar("tf_avoidteammates_pushaway").SetBool(false);
		FindConVar("tf_bot_pyro_shove_away_range").SetFloat(0.0);
		FindConVar("tf_bot_force_class").SetString("scout"); // prevent console spam
		
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
		
		HookEntityOutput("tank_boss", "OnKilled", Output_OnTankKilled);
		HookEntityOutput("rf2_tank_boss_badass", "OnKilled", Output_OnTankKilled);
		HookUserMessage(GetUserMessageId("SayText2"), UserMessageHook_SayText2, true);
		AddNormalSoundHook(PlayerSoundHook);
		AddTempEntHook("TFBlood", TEHook_TFBlood);

		g_hMainHudSync = CreateHudSynchronizer();
		g_hObjectiveHudSync = CreateHudSynchronizer();
		g_hCachedPlayerSounds = CreateArray(PLATFORM_MAX_PATH);
		g_hInvalidPlayerSounds = CreateArray(PLATFORM_MAX_PATH);
		g_hParticleEffectTable = CreateArray(128);
		
		SentryBuster_OnMapStart();
		BadassTank_OnMapStart();
		
		g_iMaxStages = FindMaxStages();
		LoadMapSettings(mapName);
		LoadItems();
		LoadWeapons();
		LoadSurvivorStats();
		
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
		//FindConVar("sv_visiblemaxplayers").SetInt(g_cvMaxHumanPlayers.IntValue);
		FindConVar("mp_teams_unbalance_limit").SetInt(0);
		FindConVar("mp_forcecamera").SetBool(false);
		FindConVar("mp_maxrounds").SetInt(1);
		FindConVar("mp_forceautoteam").SetBool(true);
		FindConVar("mp_respawnwavetime").SetFloat(99999.0);
		FindConVar("tf_dropped_weapon_lifetime").SetInt(0);
		FindConVar("tf_weapon_criticals").SetBool(false);
		FindConVar("tf_forced_holiday").SetInt(2);
		FindConVar("tf_player_movement_restart_freeze").SetBool(false);
		FindConVar("mp_bonusroundtime").SetInt(20);
		
		// no SourceTV
		FindConVar("tv_enable").SetBool(false);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientSourceTV(i))
			{
				KickClient(i, "GTFO");
				break;
			}
		}
		
		// For some reason, FindConVar() with sv_pure returns NULL
		// So we will use this as a workaround. Custom servers should have sv_pure 0 anyways.
		InsertServerCommand("sv_pure 0");
		
		// TFBots
		FindConVar("tf_bot_quota").SetInt(MaxClients-1);
		FindConVar("tf_bot_quota_mode").SetString("fill");
		FindConVar("tf_bot_defense_must_defend_time").SetInt(-1);
		FindConVar("tf_bot_offense_must_push_time").SetInt(-1);
		FindConVar("tf_bot_taunt_victim_chance").SetInt(0);
		FindConVar("tf_bot_join_after_player").SetBool(true);
		
		ConVar botConsiderClass = FindConVar("tf_bot_reevaluate_class_in_spawnroom");
		botConsiderClass.Flags = botConsiderClass.Flags & ~FCVAR_CHEAT;
		botConsiderClass.SetBool(false);
		
		char team[8];
		switch (TEAM_ENEMY)
		{
			case 3:	team = "blue";
			case 2:	team = "red";
		}
		
		FindConVar("mp_humans_must_join_team").SetString(team);
		g_bConVarsModified = true;
	}
}

public void OnMapEnd()
{	
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
	g_iWorldCenterEntity = -1;
	g_bTankBossMode = false;
	g_iTanksKilledObjective = 0;
	g_iTankKillRequirement = 0;
	g_iTanksSpawned = 0;
	g_bThrillerActive = false;
	g_iThrillerRepeatCount = 0;
	
	delete g_hMainHudSync;
	delete g_hObjectiveHudSync;
	delete g_hCachedPlayerSounds;
	delete g_hInvalidPlayerSounds;
	delete g_hParticleEffectTable;
	
	StopMusicTrackAll();
}

void LoadAssets()
{
	PrecacheFactoryAssets();
	
	// Models
	PrecacheModel(MODEL_ERROR, true);
	PrecacheModel(MODEL_INVISIBLE, true);
	PrecacheModel(MODEL_CASH_BOMB, true);
	PrecacheModel(MODEL_MERASMUS, true);
	g_iBeamModel = PrecacheModel(MAT_BEAM, true);
	
	// Sounds
	PrecacheSound(SND_ITEM_PICKUP, true);
	PrecacheSound(SND_GAME_OVER, true);
	PrecacheSound(SND_EVIL_LAUGH, true);
	PrecacheSound(SND_LASTMAN, true);
	PrecacheSound(SND_MONEY_PICKUP, true);
	PrecacheSound(SND_USE_WORKBENCH, true);
	PrecacheSound(SND_USE_SCRAPPER, true);
	PrecacheSound(SND_DROP_DEFAULT, true);
	PrecacheSound(SND_DROP_HAUNTED, true);
	PrecacheSound(SND_DROP_UNUSUAL, true);
	PrecacheSound(SND_CASH, true);
	PrecacheSound(SND_NOPE, true);
	PrecacheSound(SND_MERASMUS_APPEAR, true);
	PrecacheSound(SND_MERASMUS_DISAPPEAR, true);
	PrecacheSound(SND_MERASMUS_DANCE1, true);
	PrecacheSound(SND_MERASMUS_DANCE2, true);
	PrecacheSound(SND_MERASMUS_DANCE3, true);
	PrecacheSound(SND_BOSS_SPAWN, true);
	PrecacheSound(SND_SENTRYBUSTER_BOOM, true);
	PrecacheSound(SND_ENEMY_STUN, true);
	PrecacheSound(SND_TELEPORTER_CHARGED, true);
	PrecacheSound(SND_TANK_SPEED_UP, true);
	PrecacheSound(SND_BELL, true);
	PrecacheSound(SND_SHIELD, true);
	PrecacheSound(SND_LAW_FIRE, true);
	PrecacheSound(SND_LASER, true);
	PrecacheSound(SND_THUNDER, true);
	PrecacheSound(SND_WEAPON_CRIT, true);
	PrecacheSound(SND_BLEED_EXPLOSION, true);
	PrecacheSound(SND_DEMO_BEAM, true);
	PrecacheSound(SND_SAPPER_PLANT, true);
	PrecacheSound(SND_SAPPER_DRAIN, true);
	PrecacheSound(SND_SPELL_FIREBALL, true);
	PrecacheSound(SND_SPELL_FIREBALL_IMPACT, true);
	PrecacheSound(SND_SPELL_TELEPORT, true);
	PrecacheSound(SND_SPELL_BATS, true);
	PrecacheSound(SND_SPELL_LIGHTNING, true);
	PrecacheSound(SND_SPELL_METEOR, true);
	PrecacheSound(SND_SPELL_OVERHEAL, true);
	PrecacheSound(SND_SPELL_JUMP, true);
	PrecacheSound(SND_SPELL_STEALTH, true);
	PrecacheSound(SND_RUNE_AGILITY, true);
	PrecacheSound(SND_RUNE_HASTE, true);
	PrecacheSound(SND_RUNE_WARLOCK, true);
	PrecacheSound(SND_RUNE_PRECISION, true);
	PrecacheSound(SND_RUNE_REGEN, true);
	PrecacheSound(SND_RUNE_KNOCKOUT, true);
	PrecacheSound(SND_RUNE_RESIST, true);
	PrecacheSound(SND_RUNE_STRENGTH, true);
	PrecacheSound(SND_RUNE_VAMPIRE, true);
	PrecacheSound(SND_RUNE_KING, true);
	PrecacheSound(SND_THROW, true);
	PrecacheSound(SND_BOMB_EXPLODE, true);
	PrecacheSound("vo/halloween_boss/knight_attack01.mp3", true);
	PrecacheSound("vo/halloween_boss/knight_attack02.mp3", true);
	PrecacheSound("vo/halloween_boss/knight_attack03.mp3", true);
	PrecacheSound("vo/halloween_boss/knight_attack04.mp3", true);
	PrecacheScriptSound(GSND_CRIT);
	PrecacheScriptSound(GSND_MINICRIT);
	PrecacheScriptSound(GSND_CLEAVER_HIT);
	
	AddSoundToDownloadsTable(SND_LASER);
	AddSoundToDownloadsTable(SND_WEAPON_CRIT);
}

void ResetConVars()
{
	ResetConVar(FindConVar("sv_alltalk"));
	//ResetConVar(FindConVar("sv_visiblemaxplayers"));
	
	ResetConVar(FindConVar("mp_waitingforplayers_time"));
	ResetConVar(FindConVar("mp_teams_unbalance_limit"));
	ResetConVar(FindConVar("mp_forcecamera"));
	ResetConVar(FindConVar("mp_maxrounds"));
	ResetConVar(FindConVar("mp_forceautoteam"));
	ResetConVar(FindConVar("mp_respawnwavetime"));
	ResetConVar(FindConVar("mp_humans_must_join_team"));
	ResetConVar(FindConVar("mp_bonusroundtime"));
	ResetConVar(FindConVar("tv_enable"));
	
	ResetConVar(FindConVar("tf_use_fixed_weaponspreads"));
	ResetConVar(FindConVar("tf_avoidteammates_pushaway"));
	ResetConVar(FindConVar("tf_dropped_weapon_lifetime"));
	ResetConVar(FindConVar("tf_weapon_criticals"));
	ResetConVar(FindConVar("tf_forced_holiday"));
	ResetConVar(FindConVar("tf_player_movement_restart_freeze"));
	
	ResetConVar(FindConVar("tf_bot_defense_must_defend_time"));
	ResetConVar(FindConVar("tf_bot_offense_must_push_time"));
	ResetConVar(FindConVar("tf_bot_taunt_victim_chance"));
	ResetConVar(FindConVar("tf_bot_join_after_player"));
	ResetConVar(FindConVar("tf_bot_reevaluate_class_in_spawnroom"));
	ResetConVar(FindConVar("tf_bot_quota"));
	ResetConVar(FindConVar("tf_bot_quota_mode"));
	ResetConVar(FindConVar("tf_bot_pyro_shove_away_range"));
	ResetConVar(FindConVar("tf_bot_force_class"));
}

public void OnClientConnected(int client)
{
	/*
	if (RF2_IsEnabled())
	{
		if (!IsFakeClient(client))
		{
			if (GetTotalHumans(false) > g_cvMaxHumanPlayers.IntValue)
			{
				KickClient(client, "Only %i humans are allowed in this server", g_cvMaxHumanPlayers.IntValue);
			}
		}
	}
	*/
}

public void OnClientPutInServer(int client)
{
	RefreshClient(client);
	GetClientName(client, g_szPlayerOriginalName[client], sizeof(g_szPlayerOriginalName[]));
	
	if (RF2_IsEnabled() && !IsClientSourceTV(client) && !IsClientReplay(client))
	{
		if (IsFakeClient(client))
		{
			g_TFBot[client] = new TFBot(client);
			g_TFBot[client].Follower = PathFollower(_, Path_FilterIgnoreObjects, Path_FilterOnlyActors);
		}
		else if (g_bRoundActive)
		{
			PlayMusicTrack(client);
		}
		
		SDKHook(client, SDKHook_PreThink, Hook_PreThink);
		SDKHook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamageAlive);
		SDKHook(client, SDKHook_OnTakeDamageAlivePost, Hook_OnTakeDamageAlivePost);
		SDKHook(client, SDKHook_WeaponSwitchPost, Hook_WeaponSwitchPost);

		if (g_hSDKTakeHealth)
			DHookEntity(g_hSDKTakeHealth, false, client);
		
		g_hPlayerExtraSentryList[client] = CreateArray();
	}
}

public void OnClientDisconnect(int client)
{
	if (!RF2_IsEnabled())
		return;
	
	StopMusicTrack(client);
	
	if (!IsFakeClient(client))
	{
		SaveClientCookies(client);
	}
	
	if (!g_bWaitingForPlayers && !g_bGameOver && g_bGameInitialized && !g_bMapChanging && !IsFakeClient(client) && !IsStageCleared())
	{
		int humanCount = GetTotalHumans(false)-1; // minus ourselves
		
		if (humanCount == 0 && !g_bPluginReloading) // Everybody left. Time to start over!
		{
			PrintToServer("%T", "AllHumansDisconnected", LANG_SERVER);
			ReloadPlugin(true);
			return;
		}
	}
	
	if (IsPlayerSurvivor(client) && !g_bPluginReloading)
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
	ResetAFKTime(client, false);
}

void ReshuffleSurvivor(int client, int teamChange=TEAM_ENEMY)
{
	if (IsClientInGame(client) && teamChange >= 0)
	{
		ChangeClientTeam(client, teamChange);
	}
	
	bool allowBots = g_cvBotsCanBeSurvivor.BoolValue;
	int points[MAXTF2PLAYERS];
	int playerPoints[MAXTF2PLAYERS];
	bool valid[MAXTF2PLAYERS];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client || !IsClientInGame(i) || IsPlayerSurvivor(i))
			continue;
		
		// If we are allowing bots, they lose points in favor of players.
		if (IsFakeClient(i))
		{
			if (!allowBots)
				continue;
				
			points[i] -= 2500;
		}
		
		if (IsPlayerAFK(i))
			points[i] -= 999;
			
		if (!g_bPlayerBecomeSurvivor[i])
			points[i] -= 9999;
		
		// Dead players and non-bosses have higher priority.
		if (!IsPlayerAlive(i))
		{
			points[i] += 5000;
		}
		else if (IsEnemy(i) && !IsBoss(i))
		{
			points[i] += 500;
		}
		
		points[i] += GetRandomInt(1, 150);
		playerPoints[i] = points[i];		
		valid[i] = true;
	}
	
	SortIntegers(points, sizeof(points), Sort_Descending);
	int highestPoints = points[0];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!valid[i] || i == client)
			continue;
		
		// We've found our winner
		if (playerPoints[i] == highestPoints)
		{
			// Lucky you - your points won't be getting reset.
			MakeSurvivor(i, RF2_GetSurvivorIndex(client), false);
			
			float pos[3];
			float angles[3];
			GetEntPos(client, pos);
			GetClientEyeAngles(client, angles);
			TeleportEntity(i, pos, angles, NULL_VECTOR);
			
			if (IsClientInGame(client))
			{
				RF2_PrintToChat(i, "%t", "DisconnectChosenAsSurvivor", client);
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
		PrintToServer("%T", "NoSurvivorsSpawned", LANG_SERVER);
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
	
	/*
	CNavArea redArea = GetIncursionArea(TFTeam_Red);
	CNavArea blueArea = GetIncursionArea(TFTeam_Blue);
	
	if (redArea)
		SDK_ComputeIncursionDistances(redArea, TFTeam_Red);
	
	if (blueArea)
		SDK_ComputeIncursionDistances(blueArea, TFTeam_Blue);
	*/
	
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
		RF2_PrintToChatAll("%t", "TanksWillArrive", g_flGracePeriodTime);
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
				RF2_PrintToChatAll("%t", "DifficultySet", difficultyName);
			}
			else
			{
				EmitSoundToAll(SND_EVIL_LAUGH);
				RF2_PrintToChatAll("%t", "DifficultySetDeadly", difficultyName);
			}
		}
		case MenuAction_VoteCancel:
		{
			if (!g_bPluginReloading) // Causes an error when the plugin is reloading for some reason. I dunno why.
			{
				g_iDifficultyLevel = GetRandomInt(DIFFICULTY_SCRAP, DIFFICULTY_STEEL);
				char difficultyName[64];
				GetDifficultyName(g_iDifficultyLevel, difficultyName, sizeof(difficultyName));
				RF2_PrintToChatAll("%t", "DifficultySet", difficultyName);
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
		if (IsClientInGame(i) && !IsPlayerSurvivor(i) && !IsFakeClient(i))
		{
			g_iPlayerSurvivorPoints[i] += 10;
			RF2_PrintToChat(i, "%t", "GainedSurvivorPoints");
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
	if (!IsValidClient(client))
		return Plugin_Continue;

	int team = GetClientTeam(client);
	
	// If we're an enemy and spawn during the grace period, or somehow don't have a type, die
	if (team == TEAM_ENEMY)
	{
		if (g_bGracePeriod || !IsEnemy(client))
		{
			SilentlyKillPlayer(client);
			return Plugin_Continue;
		}
	}
	
	if (team == TEAM_SURVIVOR)
	{
		// Gatekeeping
		if (!IsPlayerSurvivor(client))
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
		
		if (IsFakeClient(client))
		{
			char name[MAX_NAME_LENGTH];
			if (IsEnemy(client))
			{
				Enemy(client).GetName(name, sizeof(name));
			}
			
			if (name[0])
			{
				SetClientName(client, name);
			}
		}
	}
	
	if (IsFakeClient(client))
	{
        if (g_TFBot[client].Follower.IsValid())
        {
            g_TFBot[client].Follower.Invalidate();
        }
	}
	
	TF2Attrib_SetByDefIndex(client, 269, 1.0); // "mod see enemy health"
	TF2Attrib_SetByDefIndex(client, 275, 1.0); // "cancel falling damage"
	
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
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		CalculatePlayerMaxHealth(client, false, true);
		CalculatePlayerMaxSpeed(client);
		CalculatePlayerMiscStats(client);
	}
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!RF2_IsEnabled() || g_bWaitingForPlayers || !g_bRoundActive)
		return Plugin_Continue;
	
	int deathFlags = event.GetInt("death_flags");
	if (deathFlags & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Continue;

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int inflictor = event.GetInt("inflictor_entindex");
	//int assister = GetClientOfUserId(event.GetInt("assister"));
	//int custom = event.GetInt("customkill");
	int weaponId = event.GetInt("weaponid");
	int damageType = event.GetInt("damagebits");
	CritType critType = view_as<CritType>(event.GetInt("crit_type"));
	
	// No dominations
	deathFlags &= ~(TF_DEATHFLAG_KILLERDOMINATION | TF_DEATHFLAG_ASSISTERDOMINATION | 
	TF_DEATHFLAG_KILLERREVENGE | TF_DEATHFLAG_ASSISTERREVENGE);
	event.SetInt("death_flags", deathFlags);
	
	int victimTeam = GetClientTeam(victim);
	Action action = Plugin_Continue;
	
	if (attacker > 0)
	{
		DoItemDeathEffects(attacker, victim, damageType, critType);
		
		// Kill icons
		int itemProc;
		
		if (inflictor > 0 && inflictor != attacker)
		{
			itemProc = GetEntItemDamageProc(inflictor);
		}
		else
		{
			itemProc = g_iPlayerKillfeedItem[attacker];
			
			// Reset next frame in case we have multiple kills at once
			RequestFrame(RF_ResetKillfeedItem, attacker);
		}
		
		switch (itemProc)
		{
			case ItemDemo_ConjurersCowl, ItemMedic_WeatherMaster: event.SetString("weapon", "spellbook_lightning");
			
			case Item_Dangeresque, Item_SaxtonHat, ItemSniper_HolyHunter, ItemStrange_CroneDome: event.SetString("weapon", "pumpkindeath");
			
			case ItemEngi_BrainiacHairpiece, ItemStrange_VirtualViewfinder: event.SetString("weapon", "merasmus_zap");
			
			case ItemStrange_LegendaryLid: event.SetString("weapon", "kunai");
		}
	}
	
	if (victimTeam == TEAM_ENEMY)
	{
		if (!g_bGracePeriod)
		{
			float pos[3];
			GetEntPos(victim, pos);
			
			float cashAmount;
			int size;
			
			if (IsEnemy(victim))
			{
				g_iTotalEnemiesKilled++;
				cashAmount = Enemy(victim).CashAward;
				
				if (IsBoss(victim))
				{
					g_iTotalBossesKilled++;
					size = 3;
					
					EmitSoundToAll(SND_SENTRYBUSTER_BOOM, victim);
					EmitSoundToAll(SND_SENTRYBUSTER_BOOM, victim);
					EmitSoundToAll(SND_SENTRYBUSTER_BOOM, victim);
					
					TE_TFParticle("fireSmokeExplosion", pos);
					RequestFrame(RF_DeleteRagdoll, victim);
				}
			}
			
			cashAmount *= 1.0 + (float(RF2_GetEnemyLevel()-1) * g_cvEnemyCashDropScale.FloatValue);
			if (attacker > 0 && PlayerHasItem(attacker, Item_BanditsBoots))
			{
				cashAmount *= 1.0 + CalcItemMod(attacker, Item_BanditsBoots, 0);
			}
			
			int cashEntity = SpawnCashDrop(cashAmount, pos, size);
			if (attacker > 0 && TF2_GetPlayerClass(attacker) == TFClass_Sniper)
			{
				if (weaponId == TF_WEAPON_SNIPERRIFLE 
				|| weaponId == TF_WEAPON_SNIPERRIFLE_DECAP 
				|| weaponId == TF_WEAPON_SNIPERRIFLE_CLASSIC)
				{
					PickupCash(attacker, cashEntity);
				}
			}
			
			// For now, enemies have a chance to drop Haunted Keys, may implement a different way of obtaining them later
			int max = g_cvHauntedKeyDropChanceMax.IntValue;
			if (max > 0 && RandChanceIntEx(attacker, 1, max, 1))
			{
				RF2_PrintToChatAll("%t", "HauntedKeyDrop", victim);
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
				if (IsEnemy(victim))
				{
					xp = Enemy(victim).XPAward;
				}
				
				if (xp > 0.0)
				{
					xp *= 1.0 + (float(RF2_GetEnemyLevel()-1) * g_cvEnemyXPDropScale.FloatValue);
					UpdatePlayerXP(attacker, xp);
					
					//int medigun;
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || attacker == i || !IsPlayerSurvivor(i))
							continue;
						
						UpdatePlayerXP(i, xp);
						/*
						if (IsBoss(victim) || i == assister 
						|| TF2_GetPlayerClass(i) == TFClass_Medic && (medigun = GetPlayerWeaponSlot(i, WeaponSlot_Secondary)) > -1 
						&& GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget") == attacker)
						{
							UpdatePlayerXP(i, xp);
						}
						else
						{
							UpdatePlayerXP(i, xp*0.6);
						}
						*/
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
					if (!IsClientInGame(i) || !IsPlayerSurvivor(i))
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
						GetEntPos(victim, pos);
						pos[2] += 30.0;
						SpawnItem(item, pos, attacker, 8.0);
					}
				}
				
				if (PlayerHasItem(attacker, Item_Dangeresque))
				{
					if (RandChanceFloatEx(attacker, 0.0, 1.0, GetItemMod(Item_Dangeresque, 3)))
					{
						int bomb = CreateEntityByName("tf_projectile_pipe");
						float pos[3];
						GetEntPos(victim, pos);
						pos[2] += 30.0;
						TeleportEntity(bomb, pos);
						
						float damage = GetItemMod(Item_Dangeresque, 0) + CalcItemMod(attacker, Item_Dangeresque, 1, -1);
						SetEntPropFloat(bomb, Prop_Send, "m_flDamage", damage);
						float radius = GetItemMod(Item_Dangeresque, 4) + CalcItemMod(attacker, Item_Dangeresque, 5, -1);
						SetEntPropFloat(bomb, Prop_Send, "m_DmgRadius", radius);
						
						SetEntityOwner(bomb, attacker);
						SetEntProp(bomb, Prop_Data, "m_iTeamNum", GetClientTeam(attacker));
						
						g_bCashBomb[bomb] = true;
						if (IsEnemy(victim))
						{
							g_flCashBombAmount[bomb] = Enemy(victim).CashAward;
							g_iCashBombSize[bomb] = 2;
						}

						g_flCashBombAmount[bomb] *= 1.0 + (float(GetPlayerLevel(victim)-1) * g_cvEnemyCashDropScale.FloatValue);
						
						if (PlayerHasItem(attacker, Item_BanditsBoots))
						{
							g_flCashBombAmount[bomb] *= 1.0 + CalcItemMod(attacker, Item_BanditsBoots, 0);
						}
						
						SDKHook(bomb, SDKHook_StartTouch, Hook_DisableTouch);
						SDKHook(bomb, SDKHook_Touch, Hook_DisableTouch);
						
						SetShouldDamageOwner(bomb, false);
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
			int oldFog;
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || IsFakeClient(i))
					continue;
				
				oldFog = GetEntPropEnt(i, Prop_Data, "m_hCtrl");
				SetEntPropEnt(i, Prop_Data, "m_hCtrl", fog);
				
				if (IsValidEntity(oldFog))
				{
					DataPack pack;
					CreateDataTimer(time, Timer_RestorePlayerFog, pack, TIMER_FLAG_NO_MAPCHANGE);
					pack.WriteCell(GetClientUserId(i));
					pack.WriteCell(EntIndexToEntRef(oldFog));
				}
			}
			
			CreateTimer(time, Timer_KillFog, EntIndexToEntRef(fog), TIMER_FLAG_NO_MAPCHANGE);
			
			// Change the victim's team on a timer to avoid some strange behavior.
			CreateTimer(0.3, Timer_ChangeTeamOnDeath, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
			
			int alive = 0;
			int lastMan;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || i == victim)
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
				PrintHintText(lastMan, "%t", "LastMan");
				EmitSoundToClient(lastMan, SND_LASTMAN);
				
				if (GetRandomInt(1, 3) == 1)
				{
					SpeakResponseConcept_MVM(lastMan, "TLK_MVM_LAST_MAN_STANDING");
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

public void RF_ResetKillfeedItem(int client)
{
	g_iPlayerKillfeedItem[client] = Item_Null;
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
			GetEntPos(victim, pos);
			pos[2] += 30.0;
			
			float radiusDamage = damage * GetItemMod(ItemSniper_HolyHunter, 0);
			radiusDamage *= 1.0 + CalcItemMod(attacker, ItemSniper_HolyHunter, 1, -1);
			float radius = GetItemMod(ItemSniper_HolyHunter, 2);
			radius *= 1.0 + CalcItemMod(attacker, ItemSniper_HolyHunter, 3, -1);
			DoRadiusDamage(attacker, attacker, ItemSniper_HolyHunter, pos, radiusDamage, DMG_BLAST, radius, GetPlayerWeaponSlot(attacker, WeaponSlot_Primary), _, true);
		}
	}
	
	return Plugin_Continue;
}

public Action Timer_RespawnSurvivor(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || !IsPlayerSurvivor(client))
		return Plugin_Continue;
	
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
	if (!IsClientInGame(client))
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
				
			GetEntPos(entity, enemyPos);
			enemyPos[2] += 30.0;
			
			if (GetVectorDistance(eyePos, enemyPos, true) <= range)
			{
				trace = TR_TraceRayFilterEx(eyePos, enemyPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceFilter_WallsOnly);
				if (!TR_DidHit(trace))
				{
					SetEntItemDamageProc(medic, ItemMedic_WeatherMaster);
					SDKHooks_TakeDamage(entity, medic, medic, damage, DMG_SHOCK);
					
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
			EmitSoundToAll(SND_THUNDER, medic);
			
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
				if (!IsClientInGame(i))
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
				SpeakResponseConcept(medic, "TLK_PLAYER_SPELL_PICKUP_RARE");
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
	bool carryDeploy = asBool(GetEntProp(building, Prop_Send, "m_bCarryDeploy"));
	
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
			maxHealth = imax(maxHealth, 1); // prevent 0, causes division by zero crash on client
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
		if (!IsClientInGame(i) || IsPlayerSurvivor(i))
			continue;
		
		SilentlyKillPlayer(i);
		
		if (IsFakeClient(i))
		{
			// hotfix
			TF2_SetPlayerClass(i, TFClass_Scout);
		}
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
		RF2_PrintToChatAll("%t", "GracePeriodEnded");
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
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

int g_iEnemySpawnPoints[MAXTF2PLAYERS];
public Action Timer_EnemySpawnWave(Handle timer)
{
	if (!RF2_IsEnabled() || !g_bRoundActive || IsStageCleared())
		return Plugin_Continue;
	
	int survivorCount = RF2_GetSurvivorCount();
	float duration = g_cvEnemyBaseSpawnWaveTime.FloatValue - 1.5 * float(survivorCount-1);
	duration -= float(RF2_GetEnemyLevel()-1) * 0.2;
	
	if (GetTeleporterEventState() == TELE_EVENT_ACTIVE)
		duration *= 0.8;
	
	CreateTimer(fmax(duration, g_cvEnemyMinSpawnWaveTime.FloatValue), Timer_EnemySpawnWave, _, TIMER_FLAG_NO_MAPCHANGE);
	
	int spawnCount = g_cvEnemyMinSpawnWaveCount.IntValue + ((survivorCount-1)/3) + RF2_GetSubDifficulty() / 3;
	spawnCount = imax(imin(spawnCount, g_cvEnemyMaxSpawnWaveCount.IntValue), g_cvEnemyMinSpawnWaveCount.IntValue);
	float subIncrement = RF2_GetDifficultyCoeff() / g_cvSubDifficultyIncrement.FloatValue;
	ArrayList respawnArray = CreateArray();
	
	// Reset everyone's points
	if (g_iRespawnWavesCompleted <= 0)
	{
		for (int i = 1; i < MAXTF2PLAYERS; i++)
			g_iEnemySpawnPoints[i] = 0;
	}
	
	// grab our next players for the spawn (bots don't get points)
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_bPlayerInSpawnQueue[i] || !IsClientInGame(i) || GetClientTeam(i) != TEAM_ENEMY)
			continue;
		
		// humans always spawn before bots, alive players get less points
		if (IsPlayerAlive(i))
		{
			if (!IsFakeClient(i))
			{
				g_iEnemySpawnPoints[i] += 5;
			}
			
			continue;
		}
		else if (!IsFakeClient(i))
		{
			g_iEnemySpawnPoints[i] += 10;
		}
		
		respawnArray.Push(i);
	}
	
	int client, spawns;
	float time = 0.1;
	float bossChance;
	const float max = 250.0;
	
	respawnArray.SortCustom(SortEnemySpawnArray);
	if (respawnArray.Length > spawnCount)
		respawnArray.Resize(spawnCount);
	
	for (int i = 0; i < respawnArray.Length; i++)
	{
		client = respawnArray.Get(i);
		bossChance = subIncrement < max ? subIncrement : max;
		if (RF2_GetSubDifficulty() >= SubDifficulty_Impossible && RandChanceFloat(0.0, max, bossChance))
		{
			g_iPlayerBossSpawnType[client] = GetRandomBoss();
		}
		else
		{
			g_iPlayerEnemySpawnType[client] = GetRandomEnemy();
		}
		
		// Don't spawn everyone on the same frame to reduce lag
		CreateTimer(time, Timer_SpawnEnemy, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		time += 0.1;
		g_bPlayerInSpawnQueue[client] = true;
		
		spawns++;
		if (spawns >= spawnCount)
			break;
	}
	
	delete respawnArray;
	g_iRespawnWavesCompleted++;
	return Plugin_Continue;
}

public int SortEnemySpawnArray(int index1, int index2, ArrayList array, Handle hndl)
{
	int client1 = array.Get(index1);
	int client2 = array.Get(index2);
	
	if (IsFakeClient(client1))
		return 1;
	
	if (IsFakeClient(client2))
		return -1;
	
	if (g_iEnemySpawnPoints[client1] == g_iEnemySpawnPoints[client2])
		return 0;
	
	return g_iEnemySpawnPoints[client1] < g_iEnemySpawnPoints[client2] ? 1 : -1;
}

public Action Timer_SpawnEnemy(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
	
	if (g_iPlayerEnemySpawnType[client] > -1)
	{
		SpawnEnemy(client, g_iPlayerEnemySpawnType[client]);
	}
	else if (g_iPlayerBossSpawnType[client] > -1)
	{
		SpawnBoss(client, g_iPlayerBossSpawnType[client]);
	}
	
	g_iPlayerEnemySpawnType[client] = -1;
	g_iPlayerBossSpawnType[client] = -1;
	
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
	static char miscText[128];
	
	SetHudTextParams(-1.0, -1.3, 0.15, g_iMainHudR, g_iMainHudG, g_iMainHudB, 255);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		if (g_bGameOver)
		{
			static bool scoreCalculated;
			static int score;
			static char rank[8];
			
			// Calculate our score and rank.
			if (!scoreCalculated)
			{
				score += g_iTotalEnemiesKilled * 25;
				score += g_iTotalBossesKilled * 250;
				score += g_iTotalTanksKilled * 500;
				score += g_iTotalItemsFound * 75;
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
				"\n\n\n\nGAME OVER\n\nEnemies slain: %i\nBosses slain: %i\nStages completed: %i\nItems found: %i\nTanks destroyed: %i\nTOTAL SCORE: %i points\nRANK: %s", 
				g_iTotalEnemiesKilled, g_iTotalBossesKilled, g_iStagesCompleted, g_iTotalItemsFound, g_iTotalTanksKilled, score, rank);

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
					Format(strangeItemInfo, sizeof(strangeItemInfo), "%s[%i] READY! RELOAD (R) [%.1f]", 
						strangeItemInfo, g_iPlayerEquipmentItemCharges[i], g_flPlayerEquipmentItemCooldown[i]);
				}
				else
				{
					Format(strangeItemInfo, sizeof(strangeItemInfo), "%s[%i] READY! RELOAD (R)", 
						strangeItemInfo, g_iPlayerEquipmentItemCharges[i]);
				}
			}
			else
			{
				Format(strangeItemInfo, sizeof(strangeItemInfo), "%s[0] [%.1f]", 
					strangeItemInfo, g_flPlayerEquipmentItemCooldown[i]);
			}
		}
		else
		{
			strangeItemInfo = "";
		}
		
		miscText = "";
		
		if (IsPlayerSurvivor(i))
		{
			if (g_bTankBossMode && !g_bGracePeriod)
			{
				if (IsValidEntity(g_iPlayerLastAttackedTank[i]))
				{
					static char classname[128], name[32];
					int maxHealth;
					int health = GetEntProp(g_iPlayerLastAttackedTank[i], Prop_Data, "m_iHealth");
					GetEntityClassname(g_iPlayerLastAttackedTank[i], classname, sizeof(classname));
					
					if (strcmp2(classname, "rf2_tank_boss_badass"))
					{
						name = "Badass Tank";
						maxHealth = GetEntProp(g_iPlayerLastAttackedTank[i], Prop_Data, "m_iActualMaxHealth");
					}
					else
					{
						name = "Tank";
						maxHealth = GetEntProp(g_iPlayerLastAttackedTank[i], Prop_Data, "m_iMaxHealth");
					}
					
					FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "Tanks Destroyed: %i/%i\n%s Health: %i/%i", 
						g_iTanksKilledObjective, g_iTankKillRequirement, name, health, maxHealth);
				}
				else
				{
					g_iPlayerLastAttackedTank[i] = -1;
					FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "Tanks Destroyed: %i/%i", 
						g_iTanksKilledObjective, g_iTankKillRequirement);
				}
			}
			
			if (g_flPlayerVampireSapperCooldown[i] > 0.0)
			{
				FormatEx(miscText, sizeof(miscText), "\nSapper Cooldown: %.1f", g_flPlayerVampireSapperCooldown[i]);
			}
			
			ShowSyncHudText(i, g_hMainHudSync, g_szSurvivorHudText, g_iStagesCompleted+1, g_iMinutesPassed, 
				hudSeconds, g_iEnemyLevel, g_iPlayerLevel[i], g_flPlayerXP[i], g_flPlayerNextLevelXP[i], 
				g_flPlayerCash[i], g_iPlayerHauntedKeys[i], g_szHudDifficulty, strangeItemInfo, miscText);
		}
		else
		{
			ShowSyncHudText(i, g_hMainHudSync, g_szEnemyHudText, g_iStagesCompleted+1, g_iMinutesPassed, hudSeconds, 
				g_iEnemyLevel, g_szHudDifficulty, strangeItemInfo);
		}
		
		if (g_szObjectiveHud[i][0])
		{
			if (GetPlayerEquipmentItem(i) != Item_Null)
			{
				SetHudTextParams(-1.0, -0.66, 0.15, g_iMainHudR, g_iMainHudG, g_iMainHudB, 255);
			}
			else
			{
				SetHudTextParams(-1.0, -0.7, 0.15, g_iMainHudR, g_iMainHudG, g_iMainHudB, 255);
			}
			
			ShowSyncHudText(i, g_hObjectiveHudSync, g_szObjectiveHud[i]);
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
	
	if (g_bGameOver || g_bGracePeriod)
		return Plugin_Continue;
	
	g_flSecondsPassed += 1.0;
	if (g_flSecondsPassed >= 60.0 * (float(g_iMinutesPassed+1)))
	{
		float seconds = g_flSecondsPassed - (float(g_iMinutesPassed) * 60.0);
		g_iMinutesPassed += RoundToFloor(seconds/60.0);
	}
	
	float timeFactor = g_flSecondsPassed / 10.0;
	float playerFactor = fmax(1.0 + float(RF2_GetSurvivorCount()-1) * 0.12, 1.0);
	float value = fmax(1.08 - (0.005 * float(RF2_GetSurvivorCount()-1)), 1.02);
	float stageFactor = Pow(value, float(g_iStagesCompleted));
	
	float difficultyFactor = GetDifficultyFactor(RF2_GetDifficulty());
	float oldDifficultyCoeff = g_flDifficultyCoeff;
	g_flDifficultyCoeff = (timeFactor * stageFactor * playerFactor) * difficultyFactor;
	g_flDifficultyCoeff *= g_cvDifficultyScaleMultiplier.FloatValue;
	g_flDifficultyCoeff = fmax(g_flDifficultyCoeff, oldDifficultyCoeff);
	
	if (g_cvDebugShowDifficultyCoeff.BoolValue)
	{
		PrintCenterTextAll("g_flDifficultyCoeff = %f", g_flDifficultyCoeff);
	}
	
	int currentLevel = RF2_GetEnemyLevel();
	g_iEnemyLevel = imax(RoundToFloor(1.0 + g_flDifficultyCoeff / (g_cvSubDifficultyIncrement.FloatValue / 4.0)), currentLevel);
	g_iEnemyLevel = imax(g_iEnemyLevel, 1);
	
	if (g_iEnemyLevel > currentLevel) // enemy level just increased
	{
		RF2_PrintToChatAll("%t", "EnemyLevelUp", currentLevel, g_iEnemyLevel);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
			
			CalculatePlayerMaxHealth(i);
			CalculatePlayerMiscStats(i);
		}
	}
	
	// increment the sub difficulty depending on difficulty value
	float subTime = g_flDifficultyCoeff / g_cvSubDifficultyIncrement.FloatValue;
	if (subTime >= g_iSubDifficulty+1)
	{
		g_iSubDifficulty++;
		SetHudDifficulty(g_iSubDifficulty);
		
		static float lastBellTime;
		if (GetTickedTime() > lastBellTime+10.0)
		{
			EmitSoundToAll(SND_BELL);
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
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
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
		
		// Make sure our max health is up to date (mainly for things like the GRU)
		maxHealth = SDK_GetPlayerMaxHealth(i);
		if (g_iPlayerCalculatedMaxHealth[i] != maxHealth)
		{
			g_iPlayerCalculatedMaxHealth[i] = maxHealth;
		}
		
		// Health Regen
		if (CanPlayerRegen(i))
		{
			g_flPlayerHealthRegenTime[i] -= 0.1;
			if (g_flPlayerHealthRegenTime[i] <= 0.0 && !TF2_IsPlayerInCondition(i, TFCond_Overhealed))
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
						if (RF2_GetDifficulty() == DIFFICULTY_STEEL)
						{
							g_flPlayerHealthRegenTime[i] += 0.2;
						}
						else if (RF2_GetDifficulty() == DIFFICULTY_TITANIUM)
						{
							g_flPlayerHealthRegenTime[i] += 0.4;
						}
						else if (RF2_GetDifficulty() == DIFFICULTY_SCRAP)
						{
							healAmount = RoundFloat(float(healAmount) * 1.5);
						}
					}
					
					if (healAmount < 1)
						healAmount = 1;
					
					HealPlayer(i, healAmount, false);
				}
			}
		}
		
		if (PlayerHasItem(i, Item_HorrificHeadsplitter) && !TF2_IsPlayerInCondition(i, TFCond_Bleeding))
		{
			TF2_MakeBleed(i, i, 60.0);
		}

		if (g_flPlayerVampireSapperCooldown[i] > 0.0)
		{
			g_flPlayerVampireSapperCooldown[i] -= 0.1;
		}

		// hotfix - start equipment cooldown if it stops for some reason?
		if (!g_bEquipmentCooldownActive[i] && g_flPlayerEquipmentItemCooldown[i] > 0.0)
		{
			g_bEquipmentCooldownActive[i] = true;
			CreateTimer(0.1, Timer_EquipmentCooldown, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	return Plugin_Continue;
}

public Action Timer_PluginMessage(Handle timer)
{
	if (!RF2_IsEnabled())
		return Plugin_Stop;
		
	static int message;
	const int maxMessages = 4;
	
	switch (message)
	{
		case 0: RF2_PrintToChatAll("%t", "TipSettings");
		case 1: RF2_PrintToChatAll("%t", "TipAFK", g_cvAFKLimit.IntValue);
		case 2: RF2_PrintToChatAll("%t", "TipCredits", PLUGIN_VERSION);
		case 3: RF2_PrintToChatAll("%t", "TipQueue");
		case 4: RF2_PrintToChatAll("%t", "TipMenu");
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
		if (!IsClientInGame(i) || IsFakeClient(i))
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
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		g_flPlayerAFKTime[i] += 1.0;
		if (g_flPlayerAFKTime[i] >= afkKickTime * 0.5)
		{
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
			else
			{
				PrintCenterText(i, "%t", "AFKDetected");
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
	
	int num1 = GetCmdArgInt(1);
	int num2 = GetCmdArgInt(2);
	
	if (IsPlayerSurvivor(client))
	{
		if (num1 == 0 && num2 == 0) // Medic!
		{
			if (GetClientButtons(client) & IN_SCORE)
			{
				ShowItemMenu(client); // shortcut
				return Plugin_Handled;
			}
			else
			{
				int target = GetClientAimTarget(client);
				if (IsValidClient(target) && IsPlayerSurvivor(target))
				{
					ShowItemMenu(client, target);
					return Plugin_Handled;
				}
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
		RF2_PrintToChat(client, "%t", "NoChangeClass");
		
		if (desiredClass != TFClass_Unknown)
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", view_as<int>(desiredClass));
		}
		
		return Plugin_Handled;
	}
	else if (IsPlayerSurvivor(client))
	{
		float pos[3];
		GetEntPos(client, pos);
		
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
	
	if (g_bRoundActive)
	{
		int team = GetClientTeam(client);
		if (team == TEAM_ENEMY || team == TEAM_SURVIVOR)
		{
			RF2_PrintToChat(client, "%t", "NoChangeTeam");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action OnChangeSpec(int client, const char[] command, int args)
{
	if (!IsSingleplayer(false))
		ResetAFKTime(client);

	return Plugin_Continue;
}

public Action OnBuildCommand(int client, const char[] command, int args)
{
	if (GetClientTeam(client) == TEAM_ENEMY && GetCmdArgInt(1) == view_as<int>(TFObject_Teleporter))
	{
		if (args == 1 || GetCmdArgInt(2) == view_as<int>(TFObjectMode_Entrance))
		{
			EmitSoundToClient(client, SND_NOPE);
			PrintCenterText(client, "%t", "OnlyBuildExit");
			return Plugin_Handled;
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
		GetEntPos(client, pos);
		
		DataPack pack;
		CreateDataTimer(0.3, Timer_SuicideTeleport, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(GetClientUserId(client));
		pack.WriteFloat(pos[0]);
		pack.WriteFloat(pos[1]);
		pack.WriteFloat(pos[2]);
	}
	else
	{
		RF2_PrintToChat(client, "%t", "NoSuicide");
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
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
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
	bool bot = IsFakeClient(client);
	
	if (!bot && !IsStageCleared() && g_flLoopMusicAt[client] > 0.0 && engineTime >= g_flLoopMusicAt[client])
	{
		if (GetTeleporterEntity() == INVALID_ENT_REFERENCE || GetTeleporterEventState() != TELE_EVENT_PREPARING)
		{
			StopMusicTrack(client);
			PlayMusicTrack(client);
		}
	}
	
	if (!IsPlayerAlive(client))
		return;
	
	if (bot)
	{
		TFBot_Think(g_TFBot[client]);
	}
	
	TFClassType class = TF2_GetPlayerClass(client);
	if (class == TFClass_Engineer)
	{
		float tickedTime = GetTickedTime();
		if (tickedTime >= g_flPlayerNextMetalRegen[client])
		{
			int metal = RoundToFloor(float(g_cvEngiMetalRegenAmount.IntValue) * (1.0 + float(GetPlayerLevel(client)) * 0.12));
			GivePlayerAmmo(client, metal, TFAmmoType_Metal, true);
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
			TF2_OnPlayerAirDash(client, g_iPlayerAirDashCounter[client]);
		}
	}
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	g_bPlayerInCondition[client][condition] = true;
	
	if (!RF2_IsEnabled())
		return;
	
	if (condition == TFCond_Dazed)
	{
		if (!RF2_CanBeStunned(client))
		{
			int stunFlags = GetEntProp(client, Prop_Send, "m_iStunFlags");
			if (stunFlags & TF_STUNFLAG_THIRDPERSON || stunFlags & TF_STUNFLAG_BONKSTUCK)
			{
				TF2_RemoveCondition(client, TFCond_Dazed);
				return;
			}
		}
	}
	else if (condition == TFCond_RuneVampire || condition == TFCond_RuneWarlock 
	|| condition == TFCond_RuneKnockout || condition == TFCond_KingRune)
	{
		// These runes modify max health
		CalculatePlayerMaxHealth(client);
	}
	else if (condition == TFCond_RuneHaste || condition == TFCond_RuneAgility || condition == TFCond_SpeedBuffAlly
	|| condition == TFCond_RegenBuffed || condition == TFCond_HalloweenSpeedBoost || condition == TFCond_Slowed || condition == TFCond_Dazed)
	{
		CalculatePlayerMaxSpeed(client);
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	g_bPlayerInCondition[client][condition] = false;
	
	if (!RF2_IsEnabled())
		return;
	
	if (condition == TFCond_Buffed && PlayerHasItem(client, Item_MisfortuneFedora))
	{
		TF2_AddCondition(client, TFCond_Buffed);
		return;
	}
	else if (condition == TFCond_RuneVampire || condition == TFCond_RuneWarlock 
	|| condition == TFCond_RuneKnockout || condition == TFCond_KingRune)
	{
		// These runes modify max health
		CalculatePlayerMaxHealth(client);
	}
	else if (condition == TFCond_RuneHaste || condition == TFCond_RuneAgility || condition == TFCond_SpeedBuffAlly
	|| condition == TFCond_RegenBuffed || condition == TFCond_HalloweenSpeedBoost || condition == TFCond_Slowed || condition == TFCond_Dazed)
	{
		CalculatePlayerMaxSpeed(client);
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
	g_flWeaponFireTime[client] = GetGameTime(); // This is to prevent a desync issue, see RF_NextPrimaryAttack
	RequestFrame(RF_NextPrimaryAttack, GetClientUserId(client));
	
	// Use our own crit logic
	// we already do flamethrowers in our damage hook
	if (!result)
	{
		if (PlayerHasItem(client, Item_Executioner) && IsPlayerMiniCritBuffed(client))
		{
			result = true;
			changed = true;
		}
		
		if (TF2Attrib_HookValueInt(1, "mult_crit_chance", weapon) != 0)
		{
			float proc = GetWeaponProcCoefficient(weapon);
			if (RollAttackCrit(client, proc, melee ? DMG_MELEE : DMG_GENERIC))
			{
				result = true;
				changed = true;
				
				StopSound(client, SNDCHAN_AUTO, SND_WEAPON_CRIT);
				EmitSoundToAll(SND_WEAPON_CRIT, client);
			}
		}
	}
	
	if (melee)
	{
		if (PlayerHasItem(client, ItemPyro_PyromancerMask) && CanUseCollectorItem(client, ItemPyro_PyromancerMask)
			&& GetClientHealth(client) / RF2_GetCalculatedMaxHealth(client) >= GetItemMod(ItemPyro_PyromancerMask, 5))
		{
			float speed = GetItemMod(ItemPyro_PyromancerMask, 2) + CalcItemMod(client, ItemPyro_PyromancerMask, 3, -1);
			if (speed > GetItemMod(ItemPyro_PyromancerMask, 4))
			{
				speed = GetItemMod(ItemPyro_PyromancerMask, 4);
			}
			
			float eyePos[3], eyeAng[3];
			GetClientEyePosition(client, eyePos);
			GetClientEyeAngles(client, eyeAng);
			
			float damage = GetItemMod(ItemPyro_PyromancerMask, 0) + CalcItemMod(client, ItemPyro_PyromancerMask, 1, -1);
			int fireball = ShootProjectile_Fireball(client, eyePos, eyeAng, speed, damage);
			SetShouldDamageOwner(fireball, false);
			SetEntItemDamageProc(fireball, ItemPyro_PyromancerMask);
		}
		
		if (PlayerHasItem(client, ItemDemo_ConjurersCowl) && CanUseCollectorItem(client, ItemDemo_ConjurersCowl)
			&& GetClientHealth(client) / RF2_GetCalculatedMaxHealth(client) >= GetItemMod(ItemDemo_ConjurersCowl, 5))
		{
			float eyePos[3], eyeAng[3];
			GetClientEyePosition(client, eyePos);
			GetClientEyeAngles(client, eyeAng);
			
			float speed = GetItemMod(ItemDemo_ConjurersCowl, 2) + CalcItemMod(client, ItemDemo_ConjurersCowl, 3, -1);
			if (speed > GetItemMod(ItemDemo_ConjurersCowl, 4))
			{
				speed = GetItemMod(ItemDemo_ConjurersCowl, 4);
			}
			
			float damage = GetItemMod(ItemDemo_ConjurersCowl, 0) + CalcItemMod(client, ItemDemo_ConjurersCowl, 1, -1);
			int beam = ShootProjectile(client, "tf_projectile_arrow", eyePos, eyeAng, speed, damage, -4.0);
			SetEntityMoveType(beam, MOVETYPE_FLYGRAVITY);
			SetEntProp(beam, Prop_Send, "m_iProjectileType", 18); // prevent headshots (TF_PROJECTILE_BUILDING_REPAIR_BOLT)
			SetEntItemDamageProc(beam, ItemDemo_ConjurersCowl);
			
			if (result)
			{
				SetEntProp(beam, Prop_Send, "m_bCritical", true);
			}
			
			SetEntityModel(beam, MODEL_INVISIBLE);
			
			char particleName[64];
			if (TF2_GetClientTeam(client) == TFTeam_Red)
			{
				particleName = "drg_cow_rockettrail_fire";
			}
			else
			{
				particleName = "drg_cow_rockettrail_fire_blue";
			}
			
			SpawnInfoParticle(particleName, eyePos, _, beam);
			EmitSoundToAll(SND_DEMO_BEAM, client);
		}
	}
	
	return changed ? Plugin_Changed : Plugin_Continue;
}

public void RF_NextPrimaryAttack(int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return;
	
	int weapon;
	if ((weapon = EntRefToEntIndex(g_iLastFiredWeapon[client])) == INVALID_ENT_REFERENCE)
		return;
	
	// Calculate based on the time the weapon was fired at since that was in the last frame.
	float gameTime = g_flWeaponFireTime[client];
	float time = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
	
	time -= gameTime;
	time *= GetPlayerFireRateMod(client, weapon);
	
	// Melee weapons have a swing speed cap
	if (time < 0.3 && GetPlayerWeaponSlot(client, WeaponSlot_Melee) == weapon)
	{
		time = 0.3;
	}
	
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", gameTime+time);
}

public Action Hook_ProjectileForceDamage(int entity, int other)
{
	bool remove;
	int itemProc = GetEntItemDamageProc(entity);
	if (itemProc == ItemDemo_ConjurersCowl)
	{
		remove = true;
	}
	
	if (!IsValidClient(other) && !IsNPC(other) && !IsBuilding(other))
	{
		if (remove)
		{
			RemoveEntity(entity);
		}
		
		return Plugin_Handled;
	}
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (!IsValidEntity(owner))
		owner = 0;
	
	float damage = g_flProjectileForcedDamage[entity];
	int damageFlags = DMG_SONIC;
	if (HasEntProp(entity, Prop_Send, "m_bCritical") && GetEntProp(entity, Prop_Send, "m_bCritical"))
	{
		damageFlags |= DMG_CRIT;
	}
	
	SDKHooks_TakeDamage(other, entity, owner, damage, damageFlags);
	
	if (remove)
	{
		RemoveEntity(entity);
	}
	
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
	PrintToServer("%T", "WaitingStart", LANG_SERVER);
}

public void TF2_OnWaitingForPlayersEnd()
{
	if (!RF2_IsEnabled())
		return;
	
	g_bWaitingForPlayers = false;
	PrintToServer("%T", "WaitingEnd", LANG_SERVER);
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
	g_bFiredWhileRocketJumping[entity] = false;
	g_bFakeFireball[entity] = false;
	
	if (strcmp2(classname, "tf_projectile_rocket") || strcmp2(classname, "tf_projectile_flare") || strcmp2(classname, "tf_projectile_arrow"))
	{
		SDKHook(entity, SDKHook_SpawnPost, Hook_ProjectileSpawnPost);
	}
	else if (classname[0] == 'i' && StrContains(classname, "item_") == 0)
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
		
		SDKHook(entity, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamageAlive);
		SDKHook(entity, SDKHook_OnTakeDamageAlivePost, Hook_OnTakeDamageAlivePost);
	}
	else if (IsNPC(entity))
	{
		SDKHook(entity, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamageAlive);
		SDKHook(entity, SDKHook_OnTakeDamageAlivePost, Hook_OnTakeDamageAlivePost);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (!RF2_IsEnabled() || entity < 0 || entity >= MAX_EDICTS)
		return;
		
	if (g_bCashBomb[entity])
	{
		float pos[3];
		GetEntPos(entity, pos);
		SpawnCashDrop(g_flCashBombAmount[entity], pos, g_iCashBombSize[entity]);
		
		EmitAmbientSound(SND_CASH, pos);
		TE_TFParticle("env_grinder_oilspray_cash", pos);
		TE_TFParticle("mvm_cash_explosion", pos);
	}
	else if (g_bFakeFireball[entity])
	{
		float pos[3];
		GetEntPos(entity, pos);
		EmitAmbientSound(SND_SPELL_FIREBALL_IMPACT, pos);
		switch (view_as<TFTeam>(GetEntProp(entity, Prop_Data, "m_iTeamNum")))
		{
			case TFTeam_Red: 	TE_TFParticle("spell_fireball_tendril_parent_red", pos);
			default: 			TE_TFParticle("spell_fireball_tendril_parent_blue", pos);
		}
	}
	else if (IsBuilding(entity) && TF2_GetObjectType(entity) == TFObject_Sentry)
	{
		int index;
		int builder = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
		
		if (builder > 0 && (index = g_hPlayerExtraSentryList[builder].FindValue(entity)) != -1)
		{
			g_hPlayerExtraSentryList[builder].Erase(index);
		}
	}
}

bool IsEntityBlacklisted(const char[] classname)
{
	return (strcmp2(classname, "func_regenerate") || strcmp2(classname, "tf_ammo_pack") 
	|| strcmp2(classname, "halloween_souls_pack") || strcmp2(classname, "teleport_vortex")
	|| strcmp2(classname, "func_respawnroom"));
}

public void Hook_ProjectileSpawnPost(int entity)
{
	RequestFrame(RF_ProjectileSpawnPost, EntIndexToEntRef(entity)); // just in case
}

public void RF_ProjectileSpawnPost(int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE)
		return;
	
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
			if (PlayerHasItem(owner, ItemSoldier_Compatriot) && CanUseCollectorItem(owner, ItemSoldier_Compatriot) && TF2_IsPlayerInCondition(owner, TFCond_BlastJumping))
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
	if (IsValidClient(other) && GetClientTeam(other) == TEAM_ENEMY)
		return Plugin_Handled;

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
		if (StrContains(classname, "tank_boss") != -1 || strcmp2(classname, "base_boss"))
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

float g_flDamageProc;

public Action Hook_OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, 
float damageForce[3], float damagePosition[3], int damageCustom)
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
	
	if (!ShouldDamageOwner(inflictor) && victim == GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity"))
	{
		return Plugin_Handled;
	}
	
	float originalDamage = damage;
	bool ignoreResist;
	if (!ignoreResist && attackerIsClient && weapon > -1)
	{
		int initial;
		if (weapon > 0 && TF2Attrib_HookValueInt(initial, "mod_pierce_resists_absorbs", weapon) > 0)
		{
			ignoreResist = true;
		}
	}
	
	if (g_bFakeFireball[inflictor])
	{
		damageCustom = TF_CUSTOM_SPELL_FIREBALL;
		if (IsValidClient(victim))
		{
			TF2_IgnitePlayer(victim, attacker, 10.0);
		}
	}
	
	if (victimIsClient && IsSingleplayer(false) && IsPlayerSurvivor(victim) && TF2_GetPlayerClass(victim) != TFClass_Heavy)	
	{
		damage *= 0.8;
	}
	
	static char inflictorClassname[64];
	GetEntityClassname(inflictor, inflictorClassname, sizeof(inflictorClassname));
	
	bool selfDamage = (attacker == victim || inflictor == victim);
	bool rangedDamage = (damageType & DMG_BULLET || damageType & DMG_BLAST || damageType & DMG_IGNITE || damageType & DMG_SONIC);
	bool invuln = victimIsClient && TF2_IsInvuln(victim);
	
	if (victimIsClient)
	{
		// because there's no fall damage, red team takes increased self blast damage
		if (selfDamage && rangedDamage && IsPlayerSurvivor(victim))
		{
			damage *= 2.0;
		}
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
				damage = fmax(damage, 1.0);
			}
		}
		else if (attackerIsClient && IsPlayerSurvivor(attacker) && g_iPlayerLastAttackedTank[attacker] != victim 
		&& StrContains(classname, "tank_boss") != -1)
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
		
		if (inflictorIsBuilding)
		{
			proc *= 0.5;
		}
		else if (strcmp2(inflictorClassname, "tf_projectile_rocket") || strcmp2(inflictorClassname, "tf_projectile_energy_ball") || strcmp2(inflictorClassname, "tf_projectile_sentryrocket"))
		{
			int offset = FindSendPropInfo("CTFProjectile_Rocket", "m_hLauncher") + 16;
			int enemy = GetEntDataEnt2(inflictor, offset); // m_hEnemy
			if (enemy != victim) // enemy == victim means direct damage was dealt, otherwise this is splash
			{
				proc *= 0.5;
			}
		}
		else if (strcmp2(inflictorClassname, "tf_projectile_pipe"))
		{
			int offset = FindSendPropInfo("CTFGrenadePipebombProjectile", "m_bDefensiveBomb") - 4;
			float directDamage = GetEntDataFloat(inflictor, offset);
			if (originalDamage < directDamage) // non direct hit
			{
				proc *= 0.5;
			}
		}
		else if (strcmp2(inflictorClassname, "tf_projectile_pipe_remote"))
		{
			proc *= 0.5;
		}
		else if (strcmp2(inflictorClassname, "entity_medigun_shield"))
		{
			proc *= 0.02; // This thing does damage every damn tick
		}
		
		switch (damageCustom)
		{
			case TF_CUSTOM_SPELL_FIREBALL: proc *= 0.5;
			case TF_CUSTOM_BURNING, TF_CUSTOM_BLEEDING: proc *= 0.75;
		}
		
		damage *= GetPlayerDamageMult(attacker);
		
		if (g_bFiredWhileRocketJumping[inflictor] && PlayerHasItem(attacker, ItemSoldier_Compatriot) && CanUseCollectorItem(attacker, ItemSoldier_Compatriot))
		{
			damage *= 1.0 + CalcItemMod(attacker, ItemSoldier_Compatriot, 0);
		}
		
		int procItem = GetEntItemDamageProc(attacker);
		if (procItem > Item_Null)
		{
			proc *= GetItemProcCoefficient(procItem);
			SetEntItemDamageProc(attacker, Item_Null);
		}
		
		if (GetEntItemDamageProc(inflictor) != Item_Null)
		{
			proc *= GetItemProcCoefficient(GetEntItemDamageProc(inflictor));
		}
		
		if (inflictorIsBuilding)
		{
			/*
			if (victimIsClient && PlayerHasItem(attacker, ItemEngi_HeadOfDefense) && CanUseCollectorItem(attacker, ItemEngi_HeadOfDefense))
			{
				if (GetEntProp(inflictor, Prop_Send, "m_bMiniBuilding"))
				{
					TF2_AddCondition(victim, TFCond_MarkedForDeathSilent, GetItemMod(ItemEngi_HeadOfDefense, 1), attacker);
				}
			}
			*/
			
			if (PlayerHasItem(attacker, ItemEngi_BrainiacHairpiece) && CanUseCollectorItem(attacker, ItemEngi_BrainiacHairpiece))
			{
				if (g_flSentryNextLaserTime[inflictor] <= GetTickedTime()
					&& g_hPlayerExtraSentryList[attacker].FindValue(inflictor) == -1)
				{
					float pos[3], victimPos[3], angles[3];
					GetEntPos(inflictor, pos);
					GetEntPos(victim, victimPos);
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
					
					float laserDamage = GetItemMod(ItemEngi_BrainiacHairpiece, 2);
					float size = GetItemMod(ItemEngi_BrainiacHairpiece, 3);
					
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
			if (selfDamage && IsBoss(victim) && !Enemy(victim).AllowSelfDamage &&
			(!PlayerHasItem(victim, Item_HorrificHeadsplitter) && damageCustom != TF_CUSTOM_BLEEDING))
			{
				// bosses normally don't do damage to themselves
				damage = 0.0;
				return Plugin_Changed;
			}
			
			// backstabs do set damage against survivors and bosses
			if (damageCustom == TF_CUSTOM_BACKSTAB)
			{
				if (IsBoss(victim))
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
				damage *= 1.0 + CalcItemMod(victim, Item_HorrificHeadsplitter, 1) * (1.0 + (float(GetPlayerLevel(victim)-1) * GetItemMod(Item_HorrificHeadsplitter, 0)));
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
					{
						duration = 0.25;
					}
					
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
				if (TF2_IsPlayerInCondition(attacker, TFCond_Disguised) || TF2_IsPlayerInCondition(attacker, TFCond_DisguiseRemoved))
				{
					damage *= 1.0 + CalcItemMod(attacker, ItemSpy_CounterfeitBillycock, 0);
				}
			}
		}
	}
	else if (attackerIsNpc)
	{
		if (strcmp2(inflictorClassname, "headless_hatman")) // this guy does 80% of victim HP by default, that is a big nono
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
			if (TF2_IsPlayerInCondition(victim, TFCond_Disguised) && !TF2_IsPlayerInCondition(victim, TFCond_Cloaked))
			{
				damage *= CalcItemMod_HyperbolicInverted(victim, ItemSpy_CounterfeitBillycock, 1);
			}
		}
	}
	
	g_flDamageProc = proc; // carry over to post hook and TF2_OnTakeDamageModifyRules()
	if (damage != originalDamage)
	{
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public void Hook_OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damageType, int weapon, 
float damageForce[3], float damagePosition[3], int damageCustom)
{
	bool attackerIsClient = IsValidClient(attacker);
	bool victimIsClient = IsValidClient(victim);
	bool invuln = victimIsClient && TF2_IsInvuln(victim);
	bool selfDamage = victim == attacker;
	float proc = g_flDamageProc;
	
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
			{
				g_flPlayerHealthRegenTime[victim] = regenTimeMax;
			}
		}
		
		if (!invuln)
		{
			if (PlayerHasItem(victim, Item_PocketMedic))
			{
				// check after the damage is dealt
				RequestFrame(RF_CheckHealthForPocketMedic, victim);
			}
		}
		
		if (damage <= 0.0)
		{
			RequestFrame(RF_ClearViewPunch, victim);
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
					const float rocketSpeed = 1200.0;
					float angles[3], pos[3], enemyPos[3];
					GetEntPos(attacker, pos);
					GetEntPos(victim, enemyPos);
					pos[2] += 30.0;
					enemyPos[2] += 30.0;
					GetVectorAnglesTwoPoints(pos, enemyPos, angles);
					
					float dmg = GetItemMod(Item_Law, 1) + CalcItemMod(attacker, Item_Law, 2);
					int rocket = ShootProjectile(attacker, "tf_projectile_sentryrocket", pos, angles, rocketSpeed, dmg);
					
					SetShouldDamageOwner(rocket, false);
					SetEntItemDamageProc(rocket, Item_Law);
					EmitSoundToAll(SND_LAW_FIRE, attacker, _, _, _, 0.6);
				}
			}
			
			if (PlayerHasItem(attacker, Item_HorrificHeadsplitter))
			{
				int healAmount = imax(RoundToFloor(damage * CalcItemMod_Hyperbolic(attacker, Item_HorrificHeadsplitter, 0)), 1);
				HealPlayer(attacker, healAmount, false);
			}
		}
	}
}

public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, 
float damageForce[3], float damagePosition[3], int damageCustom, CritType &critType)
{
	if (!RF2_IsEnabled() || !g_bRoundActive)
		return Plugin_Continue;
	
	CritType originalCritType = critType;
	float proc = g_flDamageProc;
	
	if (IsValidClient(attacker) && attacker != victim)
	{
		static char classname[64];
		GetEntityClassname(inflictor, classname, sizeof(classname));	
		bool projectile = StrContains(classname, "tf_proj") != -1 && HasEntProp(inflictor, Prop_Send, "m_bCritical");
		
		// Check for full crits for any damage that isn't against a building and isn't from a weapon.
		if (weapon < 0 && !IsBuilding(victim))
		{
			if (critType != CritType_Crit || critType == CritType_MiniCrit && !PlayerHasItem(attacker, Item_Executioner))
			{
				if (!projectile && RollAttackCrit(attacker, proc))
				{
					critType = CritType_Crit;
				}
			}
		}
		
		if (weapon > 0)
		{
			if (critType == CritType_Crit)
			{
				// Crit weapons nerf (Phlog, Backburner, Frontier Justice, Diamondback)
				if (TF2Attrib_HookValueInt(0, "burn_damage_earns_rage", weapon)
					|| TF2Attrib_HookValueInt(0, "set_flamethrower_back_crit", weapon)
					|| TF2Attrib_HookValueInt(0, "sentry_killed_revenge", weapon)
					|| TF2Attrib_HookValueInt(0, "sapper_kills_collect_crits", weapon))
				{
					critType = CritType_MiniCrit;
				}
			}
		}
		
		int itemProc = GetEntItemDamageProc(inflictor);
		if (itemProc == ItemStrange_HandsomeDevil && critType == CritType_MiniCrit)
		{
			critType = CritType_Crit;
		}
		
		// Executioner converts minicrits to full crits
		if (!projectile && PlayerHasItem(attacker, Item_Executioner) && critType == CritType_MiniCrit)
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
	
	// Changing the crit type here will not change the damage, so we have to modify the damage ourselves.
	// An issue will also occur when changing the crit type here where it plays the wrong effect or no effect at all.
	// We can only fake a missing crit effect; an incorrect crit effect (such as minicrit -> crit spawning the minicrit effect) cannot be fixed.
	if (originalCritType != critType)
	{
		switch (originalCritType)
		{
			case CritType_None:
			{
				damageType |= DMG_CRIT;
				
				if (critType == CritType_Crit)
				{
					TE_TFParticle("crit_text", damagePosition, victim);
					EmitGameSoundToClient(attacker, GSND_CRIT);
					damage *= 3.0;
				}
				else // Mini crit
				{
					TE_TFParticle("minicrit_text", damagePosition, victim);
					EmitGameSoundToClient(attacker, GSND_MINICRIT);
					damage *= 1.35;
				}
			}
			
			case CritType_MiniCrit:
			{
				if (critType == CritType_Crit)
				{
					TE_TFParticle("crit_text", damagePosition, victim);
					EmitGameSoundToClient(attacker, GSND_CRIT);
					damage *= 0.741;
					damage *= 3.0;
				}
				else // Non crit
				{
					damage *= 0.741;
				}
			}
			
			case CritType_Crit:
			{
				if (critType == CritType_MiniCrit)
				{
					TE_TFParticle("minicrit_text", damagePosition, victim);
					EmitGameSoundToClient(attacker, GSND_MINICRIT);
					damage /= 3.0;
					damage *= 1.35;
				}
				else // Non crit
				{
					damage /= 3.0;
				}
			}
		}
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public void Hook_WeaponSwitchPost(int client, int weapon)
{
	if (IsFakeClient(client))
	{
		g_TFBot[client].RemoveButtonFlag(IN_RELOAD);
	}
	else if (!g_bPlayerExtraSentryHint[client] && PlayerHasItem(client, ItemEngi_HeadOfDefense) && CanUseCollectorItem(client, ItemEngi_HeadOfDefense))
	{
		char classname[64];
		GetEntityClassname(weapon, classname, sizeof(classname));
		if (strcmp2(classname, "tf_weapon_pda_engineer_build")) // PDA won't allow us to build extra sentries using it
		{
			PrintHintText(client, "%t", "ExtraSentryHint");
			g_bPlayerExtraSentryHint[client] = true;
		}
	}
	
	CalculatePlayerMaxSpeed(client);
}

public Action Hook_DisableTouch(int entity, int other)
{
	return Plugin_Handled;
}

public void RF_CheckHealthForPocketMedic(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	int health = GetClientHealth(client);
	int maxHealth = RF2_GetCalculatedMaxHealth(client);
	if (health < float(maxHealth) * GetItemMod(Item_PocketMedic, 0))
	{
		EmitSoundToAll(SND_SHIELD, client);
		TF2_AddCondition(client, TFCond_UberchargedCanteen, GetItemMod(Item_PocketMedic, 2));
		
		int heal = RoundToFloor(float(maxHealth) * GetItemMod(Item_PocketMedic, 1));
		HealPlayer(client, heal, false);
		
		PrintHintText(client, "%t", "PocketMedic");
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

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3])
{
	if (!RF2_IsEnabled() || g_bWaitingForPlayers || !IsPlayerAlive(client))
		return Plugin_Continue;
		
	Action action = Plugin_Continue;
	bool bot = IsFakeClient(client);
	
	if (bot)
	{
		action = TFBot_OnPlayerRunCmd(client, buttons, impulse);
	}
	else
	{
		if (buttons && !IsSingleplayer(false))
		{
			ResetAFKTime(client);
		}
	}
	
	if (!bot && buttons & IN_ATTACK)
	{
		if (IsPlayerSurvivor(client) && g_flPlayerVampireSapperCooldown[client] <= 0.0 && TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			if (!TF2_IsPlayerInCondition(client, TFCond_Cloaked) && GetGameTime() >= GetEntPropFloat(client, Prop_Send, "m_flInvisChangeCompleteTime"))
			{
				int sapper = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
				
				if (sapper > 0 && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == sapper)
				{
					const float range = 350.0;
					float eyePos[3], endPos[3], eyeAng[3], vel[3];
					GetClientEyePosition(client, eyePos);
					GetClientEyeAngles(client, eyeAng);
					GetAngleVectors(eyeAng, vel, NULL_VECTOR, NULL_VECTOR);
					NormalizeVector(vel, vel);
					
					endPos[0] = eyePos[0] + vel[0] * range;
					endPos[1] = eyePos[1] + vel[1] * range;
					endPos[2] = eyePos[2] + vel[2] * range;
					
					TR_TraceRayFilter(eyePos, endPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter_EnemyTeam, client);
					int enemy = TR_GetEntityIndex();
					if (IsValidClient(enemy) && !g_bPlayerHasVampireSapper[enemy])
					{
						ApplyVampireSapper(enemy, client);
						g_flPlayerVampireSapperCooldown[client] = 30.0;
					}
				}
			}
		}
	}
	
	static bool reloadPressed[MAXTF2PLAYERS];
	if (!bot && buttons & IN_RELOAD)
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
	if (!bot && buttons & IN_ATTACK3)
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
	if (g_iPlayerFootstepType[client] == FootstepType_GiantRobot && GetTickedTime() >= nextFootstepTime[client] && !TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		if ((buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT) && GetEntityFlags(client) & FL_ONGROUND)
		{
			float fwdVel[3], sideVel[3], vel[3];
			GetAngleVectors(angles, fwdVel, NULL_VECTOR, NULL_VECTOR);
			GetAngleVectors(angles, NULL_VECTOR, sideVel, NULL_VECTOR);
			NormalizeVector(fwdVel, fwdVel);
			NormalizeVector(sideVel, sideVel);
			NormalizeVector(vel, vel);
			
			if (GetVectorDotProduct(fwdVel, vel) != 0.0 || GetVectorDotProduct(sideVel, vel) != 0.0)
			{
				TFClassType class = TF2_GetPlayerClass(client);
				static char sample[PLATFORM_MAX_PATH];
				
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
					if (TF2_IsPlayerInCondition(client, TFCond_Disguised) || TF2_IsPlayerInCondition(client, TFCond_Cloaked))
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

public Action PlayerSoundHook(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& client, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	if (!RF2_IsEnabled() || g_bWaitingForPlayers || !IsValidClient(client))
		return Plugin_Continue;
	
	if (GetClientTeam(client) == TEAM_ENEMY || TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		Action action = Plugin_Continue;
		int voiceType = g_iPlayerVoiceType[client];
		int footstepType = g_iPlayerFootstepType[client];
		
		if (TF2_IsPlayerInCondition(client, TFCond_Disguised))
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
		if (TF2_IsPlayerInCondition(client, TFCond_Disguised))
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
			if (voiceType == VoiceType_Silent)
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
				
				if (IsBoss(client) && !noGiantLines)
				{
					ReplaceStringEx(sample, sizeof(sample), "vo/", "vo/mvm/mght/");
					FormatEx(newString, sizeof(newString), "%smvm_m_", classString);
				}
				else
				{
					ReplaceStringEx(sample, sizeof(sample), "vo/", "vo/mvm/norm/", _, _, false);
					FormatEx(newString, sizeof(newString), "%smvm_", classString);
				}
				
				ReplaceStringEx(sample, sizeof(sample), classString, newString, _, _, false);
				
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
				if (TF2_IsPlayerInCondition(client, TFCond_Taunting))
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
				if (TF2_IsPlayerInCondition(client, TFCond_Disguised))
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
		if (TF2_IsPlayerInCondition(client, TFCond_Disguised))
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
	int client = TE_ReadNum("entindex");
	
	if (IsValidClient(client) && Enemy(client) != NULL_ENEMY) 
	{
		if (Enemy(client).NoBleeding)
		{
			g_flBloodPos[0] = TE_ReadFloat("m_vecOrigin[0]");
			g_flBloodPos[1] = TE_ReadFloat("m_vecOrigin[1]");
			g_flBloodPos[2] = TE_ReadFloat("m_vecOrigin[2]");
			RequestFrame(RF_SpawnMechBlood, client);
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