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
#tryinclude <handledebugger>

#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.6b"
public Plugin myinfo =
{
	name		=	"Risk Fortress 2",
	author		=	"CookieCat",
	description	=	"TF2 endless roguelike adventure gamemode inspired by hit indie game Risk of Rain 2.",
	version		=	PLUGIN_VERSION,
	url			=	"",
};

#include "rf2/defs.sp"
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
bool g_bGoombaAvailable;
bool g_bRoundEnding;
float g_flWaitRestartTime;
int g_iFileTime;
float g_flNextAutoReloadCheckTime;
float g_flAutoReloadTime;
bool g_bChangeDetected;
bool g_bHauntedKeyDrop;

int g_iTotalEnemiesKilled;
int g_iTotalBossesKilled;
int g_iTotalTanksKilled;
int g_iTotalItemsFound;
int g_iTanksKilledObjective;
int g_iTankKillRequirement;
int g_iTanksSpawned;
int g_iMetalItemsDropped;
int g_iWorldCenterEntity = INVALID_ENT;
int g_iTeleporterEntRef = INVALID_ENT;
int g_iRF2GameRulesEntRef = INVALID_ENT;

// Difficulty
float g_flSecondsPassed;
float g_flDifficultyCoeff;
float g_flRoundStartSeconds;
bool g_bTeleporterEventReminder;

int g_iMinutesPassed;
int g_iDifficultyLevel = DIFFICULTY_SCRAP;
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
char g_szObjectiveHud[MAXTF2PLAYERS][128];

// g_iStagesCompleted+1, g_iMinutesPassed, hudSeconds, g_iEnemyLevel, g_iPlayerLevel[i], g_flPlayerXP[i],
// g_flPlayerNextLevelXP[i], g_flPlayerCash[i], g_szHudDifficulty, strangeItemInfo, miscText
char g_szSurvivorHudText[2048] = "\n\nStage %i (%s) | %02d:%02d\nEnemy Level: %i | Your Level: %i\n%.0f/%.0f XP | Cash: $%.0f\n%s\n%s\n\n%s";

// g_iStagesCompleted+1, g_iMinutesPassed, hudSeconds, g_iEnemyLevel, g_szHudDifficulty, strangeItemInfo
char g_szEnemyHudText[1024] = "\n\nStage %i (%s) | %02d:%02d\nEnemy Level: %i\n%s\n%s";

// Players
bool g_bPlayerViewingItemMenu[MAXTF2PLAYERS];
bool g_bPlayerIsTeleporterBoss[MAXTF2PLAYERS];
bool g_bPlayerStunnable[MAXTF2PLAYERS] = { true, ... };
bool g_bPlayerIsAFK[MAXTF2PLAYERS];
bool g_bPlayerExtraSentryHint[MAXTF2PLAYERS];
bool g_bPlayerInSpawnQueue[MAXTF2PLAYERS];
bool g_bPlayerHasVampireSapper[MAXTF2PLAYERS];
bool g_bEquipmentCooldownActive[MAXTF2PLAYERS];
bool g_bItemPickupCooldown[MAXTF2PLAYERS];
bool g_bPlayerLawCooldown[MAXTF2PLAYERS];
bool g_bPlayerTookCollectorItem[MAXTF2PLAYERS];
bool g_bPlayerSpawnedByTeleporter[MAXTF2PLAYERS];
bool g_bExecutionerBleedCooldown[MAXTF2PLAYERS];
bool g_bPlayerHealBurstCooldown[MAXTF2PLAYERS];
bool g_bPlayerTimingOut[MAXTF2PLAYERS];
bool g_bMeleeMiss[MAXTF2PLAYERS];
bool g_bPlayerIsMinion[MAXTF2PLAYERS];

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
float g_flPlayerReloadBuffDuration[MAXTF2PLAYERS];
float g_flPlayerNextDemoSpellTime[MAXTF2PLAYERS];
float g_flPlayerNextFireSpellTime[MAXTF2PLAYERS];
float g_flPlayerRegenBuffTime[MAXTF2PLAYERS];

int g_iPlayerLevel[MAXTF2PLAYERS] = {1, ...};
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
int g_iItemsTaken[MAX_SURVIVORS];
int g_iItemLimit[MAX_SURVIVORS];
int g_iPlayerVampireSapperAttacker[MAXTF2PLAYERS] = {-1, ...};
int g_iPlayerLastScrapMenuItem[MAXTF2PLAYERS];
int g_iPlayerLastItemMenuItem[MAXTF2PLAYERS];
int g_iPlayerLastDropMenuItem[MAXTF2PLAYERS];
int g_iPlayerLastItemLogItem[MAXTF2PLAYERS];
int g_iPlayerUnusualsUnboxed[MAXTF2PLAYERS];

char g_szPlayerOriginalName[MAXTF2PLAYERS][MAX_NAME_LENGTH];
ArrayList g_hPlayerExtraSentryList[MAXTF2PLAYERS];
StringMap g_hCrashedPlayerSteamIDs;
Handle g_hCrashedPlayerTimers[MAX_SURVIVORS];

// Entities
PathFollower g_PathFollowers[MAX_PATH_FOLLOWERS];
int g_iEntityPathFollowerIndex[MAX_EDICTS] = {-1, ...};
int g_iItemDamageProc[MAX_EDICTS];
int g_iLastItemDamageProc[MAX_EDICTS];
int g_iEntLastHitItemProc[MAX_EDICTS]; // Mainly for use in OnPlayerDeath
int g_iCashBombSize[MAX_EDICTS];

bool g_bDisposableSentry[MAX_EDICTS];
bool g_bDontDamageOwner[MAX_EDICTS];
bool g_bCashBomb[MAX_EDICTS];
bool g_bFiredWhileRocketJumping[MAX_EDICTS];
bool g_bDontRemoveWearable[MAX_EDICTS];
bool g_bItemWearable[MAX_EDICTS];

float g_flBusterSpawnTime;
float g_flProjectileForcedDamage[MAX_EDICTS];
float g_flSentryNextLaserTime[MAX_EDICTS];
float g_flCashBombAmount[MAX_EDICTS];
float g_flCashValue[MAX_EDICTS];
float g_flTeleporterNextSpawnTime[MAX_EDICTS];

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
Handle g_hSDKPlayGesture;
Handle g_hSDKIntersects;
Handle g_hSDKWeaponSwitch;
Handle g_hSDKRealizeSpy;
Handle g_hSDKSetZombieType;
DynamicDetour g_hDetourDoSwingTrace;
DynamicDetour g_hDetourSentryAttack;
DynamicDetour g_hDetourHandleRageGain;
DynamicDetour g_hDetourSetReloadTimer;
DynamicHook g_hHookTakeHealth;
DynamicHook g_hHookStartUpgrading;
DynamicHook g_hHookVPhysicsCollision;
DynamicHook g_hHookShouldCollideWith;
DynamicHook g_hHookRiflePostFrame;

// Forwards
GlobalForward g_fwTeleEventStart;
GlobalForward g_fwTeleEventEnd;
GlobalForward g_fwGracePeriodStart;
GlobalForward g_fwGracePeriodEnded;
PrivateForward g_fwOnMapStart;

// ConVars
ConVar g_cvMaxHumanPlayers;
ConVar g_cvMaxSurvivors;
ConVar g_cvGameResetTime;
ConVar g_cvAlwaysSkipWait;
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
ConVar g_cvArtifactChance;
ConVar g_cvAllowHumansInBlue;
ConVar g_cvDebugNoMapChange;
ConVar g_cvDebugShowDifficultyCoeff;
ConVar g_cvDebugDontEndGame;
ConVar g_cvDebugShowObjectSpawns;
ConVar g_cvDebugUseAltMapSettings;
ConVar g_cvDebugDisableEnemySpawning;

// Cookies
Cookie g_coMusicEnabled;
Cookie g_coBecomeSurvivor;
Cookie g_coBecomeBoss;
Cookie g_coSurvivorPoints;
Cookie g_coTutorialItemPickup;
Cookie g_coTutorialSurvivor;
Cookie g_coStayInSpecOnJoin;
Cookie g_coSpecOnDeath;
Cookie g_coBecomeEnemy;
Cookie g_coItemsCollected[4];
Cookie g_coAchievementCookies[MAX_ACHIEVEMENTS];
Cookie g_coNewPlayer;
Cookie g_coDisableItemMessages;
Cookie g_coSwapStrangeButton;

// TFBots
TFBot g_TFBot[MAXTF2PLAYERS];
ArrayList g_hTFBotEngineerBuildings[MAXTF2PLAYERS];

// Other
//int g_iSpyDisguiseModels[10];
bool g_bThrillerActive;
int g_iThrillerRepeatCount;
ArrayList g_hActiveArtifacts;

#include "rf2/overrides.sp"
#include "rf2/items.sp"
#include "rf2/survivors.sp"
#include "rf2/entityfactory.sp"
#include "rf2/enemies.sp"
#include "rf2/stages.sp"

#include "rf2/customents/gamerules.sp"
#include "rf2/customents/item_ent.sp"
#include "rf2/customents/healthtext.sp"

#include "rf2/customents/objects/object_base.sp"
#include "rf2/customents/objects/object_teleporter.sp"
#include "rf2/customents/objects/object_crate.sp"
#include "rf2/customents/objects/object_workbench.sp"
#include "rf2/customents/objects/object_scrapper.sp"
#include "rf2/customents/objects/object_gravestone.sp"

#include "rf2/customents/projectiles/projectile_base.sp"
#include "rf2/customents/projectiles/projectile_shuriken.sp"
#include "rf2/customents/projectiles/projectile_bomb.sp"
#include "rf2/customents/projectiles/projectile_beam.sp"
#include "rf2/customents/projectiles/projectile_fireball.sp"
#include "rf2/customents/projectiles/projectile_kunai.sp"

#include "rf2/cookies.sp"
#include "rf2/weapons.sp"
#include "rf2/general_funcs.sp"
#include "rf2/clients.sp"
#include "rf2/entities.sp"
#include "rf2/buildings.sp"
#include "rf2/natives_forwards.sp"
#include "rf2/commands_convars.sp"
#include "rf2/artifacts.sp"
#include "rf2/achievements.sp"
#include "rf2/npc/nav.sp"
#include "rf2/npc/tf_bot.sp"
#include "rf2/npc/customhitbox.sp"
#include "rf2/npc/npc_base.sp"
#include "rf2/npc/actions/baseattack.sp"
#include "rf2/npc/npc_tank_boss.sp"
#include "rf2/npc/npc_sentry_buster.sp"
#include "rf2/npc/npc_raidboss_galleom.sp"
#include "rf2/npc/npc_companion_base.sp"

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
	InstallEnts();
	BakeCookies();
	LoadTranslations("common.phrases");
	LoadTranslations("rf2.phrases");
	LoadTranslations("rf2_artifacts.phrases");
	LoadTranslations("rf2_achievements.phrases");
	g_hActiveArtifacts = new ArrayList();
	g_hCrashedPlayerSteamIDs = new StringMap();
	g_iFileTime = GetPluginModifiedTime();
}

public void OnPluginEnd()
{
	if (RF2_IsEnabled())
		StopMusicTrackAll();
	
	for (int i = 0; i < MAXTF2PLAYERS; i++)
	{
		/*
		if (TFBot(i).Follower)
		{
			TFBot(i).Follower.Destroy();
			TFBot(i).Follower = view_as<PathFollower>(0);
		}
		*/
		
		if (RF2_IsEnabled() && IsValidClient(i))
		{
			if (!IsPlayerSpectator(i))
				ChangeClientTeam(i, TEAM_ENEMY);

			SetClientName(i, g_szPlayerOriginalName[i]);
		}
	}
	
	for (int i = 0; i < MAX_PATH_FOLLOWERS; i++)
	{
		if (g_PathFollowers[i])
		{
			g_PathFollowers[i].Destroy();
			g_PathFollowers[i] = view_as<PathFollower>(0);
		}
	}
}

void LoadGameData()
{
	GameData gamedata = new GameData("rf2");
	if (!gamedata)
	{
		SetFailState("[SDK] Failed to locate gamedata file \"rf2.txt\"");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKEquipWearable = EndPrepSDKCall();
	if(!g_hSDKEquipWearable)
	{
		LogError("[SDK] Failed to create call for CBasePlayer::EquipWearable");
	}
	
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::TeamFortress_SetSpeed");
	g_hSDKUpdateSpeed = EndPrepSDKCall();
	if (!g_hSDKUpdateSpeed)
	{
		LogError("[SDK] Failed to create call for CTFPlayer::TeamFortress_SetSpeed");
	}
	
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::PlayGesture");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKPlayGesture = EndPrepSDKCall();
	if (!g_hSDKPlayGesture)
	{
		LogError("Failed to create call for CTFPlayer::PlayGesture");
	}
	
	
	g_hHookTakeHealth = new DynamicHook(gamedata.GetOffset("CBaseEntity::TakeHealth"), HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity);
	if (g_hHookTakeHealth)
	{
		g_hHookTakeHealth.AddParam(HookParamType_Float); // amount to heal
		g_hHookTakeHealth.AddParam(HookParamType_Int);   // "damagetype"
	}
	else
	{
		LogError("[DHooks] Failed to create virtual hook for CBaseEntity::TakeHealth");
	}
	
	
	g_hHookVPhysicsCollision = new DynamicHook(gamedata.GetOffset("CPhysicsProp::VPhysicsCollision"), HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	if (g_hHookVPhysicsCollision)
	{
		g_hHookVPhysicsCollision.AddParam(HookParamType_Int); 			// index
		g_hHookVPhysicsCollision.AddParam(HookParamType_ObjectPtr); 	// gamevcollisionevent_t
	}
	else
	{
		LogError("[DHooks] Failed to create virtual hook for CPhysicsProp::VPhysicsCollision");
	}
	
	
	g_hHookShouldCollideWith = new DynamicHook(gamedata.GetOffset("ILocomotion::ShouldCollideWith"), HookType_Raw, ReturnType_Bool, ThisPointer_Address);
	if (g_hHookShouldCollideWith)
	{
		g_hHookShouldCollideWith.AddParam(HookParamType_CBaseEntity); // colliding entity
	}
	else
	{
		LogError("[DHooks] Failed to create virtual hook for ILocomotion::ShouldCollideWith");
	}
	

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseEntity::Intersects");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer); // pOther
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKIntersects = EndPrepSDKCall();
	if (!g_hSDKIntersects)
	{
		LogError("[SDK] Failed to create call for CBaseEntity::Intersects");
	}
	
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFWeaponBase::GetMaxClip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMaxClip1 = EndPrepSDKCall();
	if (!g_hSDKGetMaxClip1)
	{
		LogError("[SDK] Failed to create call for CTFWeaponBase::GetMaxClip1");
	}
	
	
	g_hDetourSetReloadTimer = DynamicDetour.FromConf(gamedata, "CTFWeaponBase::SetReloadTimer");
	if (!g_hDetourSetReloadTimer || !g_hDetourSetReloadTimer.Enable(Hook_Pre, Detour_SetReloadTimer))
	{
		LogError("[DHooks] Failed to create detour for CTFWeaponBase::SetReloadTimer");
	}
	
	
	g_hDetourDoSwingTrace = DynamicDetour.FromConf(gamedata, "CTFWeaponBaseMelee::DoSwingTraceInternal");
	if (!g_hDetourDoSwingTrace || !g_hDetourDoSwingTrace.Enable(Hook_Pre, Detour_DoSwingTrace) || !g_hDetourDoSwingTrace.Enable(Hook_Post, Detour_DoSwingTracePost))
	{
		LogError("[DHooks] Failed to create detour for CTFWeaponBaseMelee::DoSwingTraceInternal");
	}
	
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseObject::DoQuickBuild");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	g_hSDKDoQuickBuild = EndPrepSDKCall();
	if (!g_hSDKDoQuickBuild)
	{
		LogError("[SDK] Failed to create call for CBaseObject::DoQuickBuild");
	}
	
	
	g_hHookStartUpgrading = new DynamicHook(gamedata.GetOffset("CBaseObject::StartUpgrading"), HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	if (!g_hHookStartUpgrading)
	{
		LogError("[DHooks] Failed to create virtual hook for CBaseObject::StartUpgrading");
	}
	
	
	g_hDetourSentryAttack = DynamicDetour.FromConf(gamedata, "CObjectSentrygun::Attack");
	if (!g_hDetourSentryAttack || !g_hDetourSentryAttack.Enable(Hook_Post, DHook_SentryGunAttack))
	{
		LogError("[DHooks] Failed to create detour for CObjectSentrygun::Attack");
	}
	
	
	g_hDetourHandleRageGain = DynamicDetour.FromConf(gamedata, "HandleRageGain");
	if (!g_hDetourHandleRageGain || !g_hDetourHandleRageGain.Enable(Hook_Pre, DHook_HandleRageGain))
	{
		LogError("[DHooks] Failed to create detour for HandleRageGain");
	}
	
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFBot::RealizeSpy");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDKRealizeSpy = EndPrepSDKCall();
	if (!g_hSDKRealizeSpy)
	{
		LogError("[SDK] Failed to create call for CTFBot::RealizeSpy");
	}
	
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CZombie::SetSkeletonType");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKSetZombieType = EndPrepSDKCall();
	if (!g_hSDKSetZombieType)
	{
		LogError("[SDK] Failed to create call for CZombie::SetSkeletonType");
	}
	
	
	g_hHookRiflePostFrame = new DynamicHook(gamedata.GetOffset("CTFSniperRifle::ItemPostFrame"), HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	if (!g_hHookRiflePostFrame)
	{
		LogError("[DHooks] Failed to create virtual hook for CTFSniperRifle::ItemPostFrame");
	}

	
	delete gamedata;
	gamedata = new GameData("sdkhooks.games");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	g_hSDKGetMaxHealth = EndPrepSDKCall();
	if (!g_hSDKGetMaxHealth)
	{
		LogError("[SDK] Failed to create call for CBasePlayer::GetMaxHealth from SDKHooks gamedata");
	}
	
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "Weapon_Switch");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKWeaponSwitch = EndPrepSDKCall();
	if (!g_hSDKWeaponSwitch)
	{
		LogError("[SDK] Failed to create call for CBasePlayer::Weapon_Switch from SDKHooks gamedata");
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
		InsertServerCommand("sm plugins load_unlock; sm plugins reload rf2");
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
		
		for (int i = 0; i < MAX_PATH_FOLLOWERS; i++)
		{
			g_PathFollowers[i] = PathFollower(_, FilterIgnoreActors, FilterOnlyActors);
		}
		
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
					OnClientPostAdminCheck(i);
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
		
		UpdateGameDescription();
		LoadAssets();
		if (!g_bLateLoad)
		{
			//AutoExecConfig(true, "RiskFortress2");
		}
		
		ConVar maxSpeed = FindConVar("sm_tf2_maxspeed");
		if (maxSpeed)
		{
			maxSpeed.FloatValue = 900.0;
		}
		
		// These are ConVars we're OK with being set by server.cfg, but we'll set our personal defaults.
		// If configs wish to change these, they will be overridden by them later.
		FindConVar("sv_alltalk").SetBool(true);
		FindConVar("tf_use_fixed_weaponspreads").SetBool(true);
		FindConVar("tf_avoidteammates_pushaway").SetBool(false);
		FindConVar("tf_bot_pyro_shove_away_range").SetFloat(0.0);
		FindConVar("tf_bot_force_class").SetString("scout"); // prevent console spam
		FindConVar("sv_tags").Flags = 0;
		
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
		HookEvent("player_connect_client", OnPlayerConnect, EventHookMode_Pre);
		HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
		HookEvent("player_healonhit", OnPlayerHealOnHit, EventHookMode_Pre);
		
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
		
		g_iMaxStages = FindMaxStages();
		LoadMapSettings(mapName);
		LoadItems();
		LoadWeapons();
		LoadSurvivorStats();
		Call_StartForward(g_fwOnMapStart);
		Call_Finish();
		
		CreateTimer(1.0, Timer_AFKManager, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(60.0, Timer_PluginMessage, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		if (g_bLateLoad)
		{
			DespawnObjects();
		}
		
		if (g_bGameInitialized)
		{
			if (g_cvGameResetTime.FloatValue > 0.0)
			{
				// If the game has already started, restart if we wait too long for players
				g_flWaitRestartTime = GetTickedTime() + g_cvGameResetTime.FloatValue;
			}
		}
		
		if (!g_bChangeDetected)
			g_flNextAutoReloadCheckTime = GetTickedTime()+1.0;
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
		FindConVar("sv_quota_stringcmdspersecond").SetInt(5000); // So Engie bots don't get kicked
		FindConVar("mp_teams_unbalance_limit").SetInt(0);
		FindConVar("mp_forcecamera").SetBool(false);
		FindConVar("mp_maxrounds").SetInt(9999);
		FindConVar("mp_timelimit").SetInt(99999);
		FindConVar("mp_forceautoteam").SetBool(true);
		FindConVar("mp_respawnwavetime").SetFloat(99999.0);
		FindConVar("tf_dropped_weapon_lifetime").SetInt(0);
		FindConVar("mp_bonusroundtime").SetInt(15);
		FindConVar("tf_weapon_criticals").SetBool(false);
		FindConVar("tf_forced_holiday").SetInt(2);
		FindConVar("tf_player_movement_restart_freeze").SetBool(false);
		FindConVar("sm_vote_progress_hintbox").SetBool(true);
		
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
		FindConVar("tf_bot_quota").SetInt(MaxClients-g_cvMaxSurvivors.IntValue);
		FindConVar("tf_bot_quota_mode").SetString("fill");
		FindConVar("tf_bot_defense_must_defend_time").SetInt(-1);
		FindConVar("tf_bot_offense_must_push_time").SetInt(-1);
		FindConVar("tf_bot_taunt_victim_chance").SetInt(0);
		FindConVar("tf_bot_join_after_player").SetBool(true);
		FindConVar("tf_bot_auto_vacate").SetBool(true);
		
		ConVar botConsiderClass = FindConVar("tf_bot_reevaluate_class_in_spawnroom");
		botConsiderClass.Flags = botConsiderClass.Flags & ~FCVAR_CHEAT;
		botConsiderClass.SetBool(false);
		g_bConVarsModified = true;
	}
}

public void OnMapEnd()
{
	g_bMapChanging = true;

	if (RF2_IsEnabled())
	{
		if (!g_bGameOver)
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
	UnhookEvent("player_connect_client", OnPlayerConnect, EventHookMode_Pre);
	UnhookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
	UnhookEvent("player_healonhit", OnPlayerHealOnHit, EventHookMode_Pre);
	
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
	g_bRoundEnding = false;
	g_flNextAutoReloadCheckTime = 0.0;
	g_flAutoReloadTime = 0.0;
	g_hPlayerTimer = null;
	g_hHudTimer = null;
	g_hDifficultyTimer = null;
	g_iRF2GameRulesEntRef = INVALID_ENT;
	g_iRespawnWavesCompleted = 0;
	g_szEnemyPackName = "";
	g_szBossPackName = "";
	g_iTeleporterEntRef = INVALID_ENT;
	g_iWorldCenterEntity = INVALID_ENT;
	g_iRF2GameRulesEntRef = INVALID_ENT;
	g_bTankBossMode = false;
	g_iTanksKilledObjective = 0;
	g_iTankKillRequirement = 0;
	g_iTanksSpawned = 0;
	g_bThrillerActive = false;
	g_iThrillerRepeatCount = 0;
	g_iMetalItemsDropped = 0;
	g_flWaitRestartTime = 0.0;
	g_bTeleporterEventReminder = false;
	g_bHauntedKeyDrop = false;
	
	delete g_hMainHudSync;
	delete g_hObjectiveHudSync;
	g_hCrashedPlayerSteamIDs.Clear();
	SetAllInArray(g_hCrashedPlayerTimers, sizeof(g_hCrashedPlayerTimers), INVALID_HANDLE);
	StopMusicTrackAll();
	DisableAllArtifacts();
	
	// Just to be safe...
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "rf2_*")) != -1)
	{
		if (RF2_Object_Base(entity).IsValid())
		{
			delete RF2_Object_Base(entity).OnInteractForward;
		}
		else if (RF2_Projectile_Base(entity).IsValid())
		{
			delete RF2_Projectile_Base(entity).OnCollide;
		}
	}
	
	for (int i = 0; i < MAX_PATH_FOLLOWERS; i++)
	{
		if (g_PathFollowers[i])
		{
			g_PathFollowers[i].Destroy();
			g_PathFollowers[i] = view_as<PathFollower>(0);
		}
	}
}

void LoadAssets()
{
	// Models
	PrecacheModel2(MODEL_ERROR, true);
	PrecacheModel2(MODEL_INVISIBLE, true);
	PrecacheModel2(MODEL_CASH_BOMB, true);
	PrecacheModel2(MODEL_MERASMUS, true);
	g_iBeamModel = PrecacheModel2(MAT_BEAM, true);

	// Sounds
	PrecacheSound2(SND_ITEM_PICKUP, true);
	PrecacheSound2(SND_GAME_OVER, true);
	PrecacheSound2(SND_EVIL_LAUGH, true);
	PrecacheSound2(SND_LASTMAN, true);
	PrecacheSound2(SND_MONEY_PICKUP, true);
	PrecacheSound2(SND_USE_WORKBENCH, true);
	PrecacheSound2(SND_USE_SCRAPPER, true);
	PrecacheSound2(SND_DROP_DEFAULT, true);
	PrecacheSound2(SND_DROP_HAUNTED, true);
	PrecacheSound2(SND_DROP_UNUSUAL, true);
	PrecacheSound2(SND_CASH, true);
	PrecacheSound2(SND_NOPE, true);
	PrecacheSound2(SND_MERASMUS_APPEAR, true);
	PrecacheSound2(SND_MERASMUS_DISAPPEAR, true);
	PrecacheSound2(SND_MERASMUS_DANCE1, true);
	PrecacheSound2(SND_MERASMUS_DANCE2, true);
	PrecacheSound2(SND_MERASMUS_DANCE3, true);
	PrecacheSound2(SND_BOSS_SPAWN, true);
	PrecacheSound2(SND_SENTRYBUSTER_BOOM, true);
	PrecacheSound2(SND_ENEMY_STUN, true);
	PrecacheSound2(SND_TELEPORTER_CHARGED, true);
	PrecacheSound2(SND_TANK_SPEED_UP, true);
	PrecacheSound2(SND_BELL, true);
	PrecacheSound2(SND_SHIELD, true);
	PrecacheSound2(SND_LAW_FIRE, true);
	PrecacheSound2(SND_LASER, true);
	PrecacheSound2(SND_THUNDER, true);
	PrecacheSound2(SND_WEAPON_CRIT, true);
	PrecacheSound2(SND_BLEED_EXPLOSION, true);
	PrecacheSound2(SND_SAPPER_PLANT, true);
	PrecacheSound2(SND_SAPPER_DRAIN, true);
	PrecacheSound2(SND_SPELL_FIREBALL, true);
	PrecacheSound2(SND_SPELL_TELEPORT, true);
	PrecacheSound2(SND_SPELL_BATS, true);
	PrecacheSound2(SND_SPELL_LIGHTNING, true);
	PrecacheSound2(SND_SPELL_METEOR, true);
	PrecacheSound2(SND_SPELL_OVERHEAL, true);
	PrecacheSound2(SND_SPELL_JUMP, true);
	PrecacheSound2(SND_SPELL_STEALTH, true);
	PrecacheSound2(SND_RUNE_AGILITY, true);
	PrecacheSound2(SND_RUNE_HASTE, true);
	PrecacheSound2(SND_RUNE_WARLOCK, true);
	PrecacheSound2(SND_RUNE_PRECISION, true);
	PrecacheSound2(SND_RUNE_REGEN, true);
	PrecacheSound2(SND_RUNE_KNOCKOUT, true);
	PrecacheSound2(SND_RUNE_RESIST, true);
	PrecacheSound2(SND_RUNE_STRENGTH, true);
	PrecacheSound2(SND_RUNE_VAMPIRE, true);
	PrecacheSound2(SND_RUNE_KING, true);
	PrecacheSound2(SND_THROW, true);
	PrecacheSound2(SND_TELEPORTER_BLU, true);
	PrecacheSound2(SND_ARTIFACT_ROLL, true);
	PrecacheSound2(SND_ARTIFACT_SELECT, true);
	PrecacheSound2(SND_DOOMSDAY_EXPLODE, true);
	PrecacheSound2(SND_ACHIEVEMENT, true);
	PrecacheSound2("vo/halloween_boss/knight_attack01.mp3", true);
	PrecacheSound2("vo/halloween_boss/knight_attack02.mp3", true);
	PrecacheSound2("vo/halloween_boss/knight_attack03.mp3", true);
	PrecacheSound2("vo/halloween_boss/knight_attack04.mp3", true);
	PrecacheScriptSound(GSND_CRIT);
	PrecacheScriptSound(GSND_MINICRIT);
	AddSoundToDownloadsTable(SND_LASER);
	AddSoundToDownloadsTable(SND_WEAPON_CRIT);
	
	/*
	g_iSpyDisguiseModels[TFClass_Scout] = PrecacheModel2("models/rf2/bots/bot_scout.mdl", true);
	g_iSpyDisguiseModels[TFClass_Soldier] = PrecacheModel2("models/rf2/bots/bot_soldier.mdl", true);
	g_iSpyDisguiseModels[TFClass_Pyro] = PrecacheModel2("models/rf2/bots/bot_pyro.mdl", true);
	g_iSpyDisguiseModels[TFClass_DemoMan] = PrecacheModel2("models/rf2/bots/bot_demo.mdl", true);
	g_iSpyDisguiseModels[TFClass_Heavy] = PrecacheModel2("models/rf2/bots/bot_heavy.mdl", true);
	g_iSpyDisguiseModels[TFClass_Engineer] = PrecacheModel2("models/rf2/bots/bot_engineer.mdl", true);
	g_iSpyDisguiseModels[TFClass_Medic] = PrecacheModel2("models/rf2/bots/bot_medic.mdl", true);
	g_iSpyDisguiseModels[TFClass_Sniper] = PrecacheModel2("models/rf2/bots/bot_sniper.mdl", true);
	g_iSpyDisguiseModels[TFClass_Spy] = PrecacheModel2("models/rf2/bots/bot_spy.mdl", true);
	*/
}

void ResetConVars()
{
	ResetConVar(FindConVar("sv_alltalk"));
	ResetConVar(FindConVar("sv_quota_stringcmdspersecond"));
	ResetConVar(FindConVar("sm_vote_progress_hintbox"));
	ResetConVar(FindConVar("mp_waitingforplayers_time"));
	ResetConVar(FindConVar("mp_teams_unbalance_limit"));
	ResetConVar(FindConVar("mp_forcecamera"));
	ResetConVar(FindConVar("mp_maxrounds"));
	ResetConVar(FindConVar("mp_timelimit"));
	ResetConVar(FindConVar("mp_forceautoteam"));
	ResetConVar(FindConVar("mp_respawnwavetime"));
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
	ResetConVar(FindConVar("tf_allow_server_hibernation"));
	ResetConVar(FindConVar("tf_bot_join_after_player"));
}

public void OnAllPluginsLoaded()
{
	g_bGoombaAvailable = LibraryExists("goomba");
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	if (RF2_IsEnabled())
	{
		UpdateGameDescription();
		if (GetTotalHumans(false) >= g_cvMaxHumanPlayers.IntValue+1)
		{
			FormatEx(rejectmsg, maxlen, "Max human player limit of %i has been reached", g_cvMaxHumanPlayers.IntValue);
			return false;
		}
	}
	
	return true;
}

public void OnClientConnected(int client)
{
	if (RF2_IsEnabled() && !IsFakeClient(client))
	{
		FindConVar("tf_bot_auto_vacate").SetBool(!(GetTotalHumans(false)-1 >= g_cvMaxHumanPlayers.IntValue));
		UpdateGameDescription();
		UpdateBotQuota();
	}
}

public void OnClientPutInServer(int client)
{
	RefreshClient(client);
	GetClientName(client, g_szPlayerOriginalName[client], sizeof(g_szPlayerOriginalName[]));
	if (RF2_IsEnabled() && !IsClientSourceTV(client) && !IsClientReplay(client))
	{
		if (IsFakeClient(client))
		{
			//TFBot(client).Follower = PathFollower(_, FilterIgnoreActors, FilterOnlyActors);
			TFBot(client).FollowerIndex = GetFreePathFollowerIndex(client);
			SDKHook(client, SDKHook_WeaponCanSwitchTo, Hook_TFBotWeaponCanSwitch);
		}
		else if (g_bRoundActive)
		{
			PlayMusicTrack(client);
		}
		
		SDKHook(client, SDKHook_PreThink, Hook_PreThink);
		SDKHook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamageAlive);
		SDKHook(client, SDKHook_OnTakeDamageAlivePost, Hook_OnTakeDamageAlivePost);
		SDKHook(client, SDKHook_WeaponSwitchPost, Hook_WeaponSwitchPost);
		
		if (g_hHookTakeHealth)
		{
			DHookEntity(g_hHookTakeHealth, false, client, _, DHook_TakeHealth);
		}
		
		g_hPlayerExtraSentryList[client] = new ArrayList();
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (RF2_IsEnabled() && !IsFakeClient(client))
	{
		char auth[MAX_AUTHID_LENGTH];
		if (GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth)))
		{
			int survivorIndex;
			if (g_hCrashedPlayerSteamIDs.GetValue(auth, survivorIndex))
			{
				// This is a client rejoining who crashed/lost connection when they were a Survivor.
				RF2_PrintToChatAll("{yellow}%N {default}has returned, moving them back to RED team.", client);
				char class[128];
				FormatEx(class, sizeof(class), "%s_CLASS", auth);
				TFClassType myClass;
				g_hCrashedPlayerSteamIDs.GetValue(class, myClass);
				DataPack pack;
				CreateDataTimer(0.5, Timer_MakeSurvivor, pack, TIMER_FLAG_NO_MAPCHANGE);
				pack.WriteCell(GetClientUserId(client));
				pack.WriteCell(survivorIndex);
				pack.WriteCell(myClass);
				g_hCrashedPlayerSteamIDs.Remove(auth);
				g_hCrashedPlayerSteamIDs.Remove(class);
				if (g_hCrashedPlayerTimers[survivorIndex])
				{
					delete g_hCrashedPlayerTimers[survivorIndex];
				}
				
				FindConVar("tf_allow_server_hibernation").SetBool(true);
				FindConVar("tf_bot_join_after_player").SetBool(true);
			}
		}
	}
}

public Action Timer_MakeSurvivor(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if (client == 0)
		return Plugin_Continue;
	
	int index = pack.ReadCell();
	TF2_SetPlayerClass(client, view_as<TFClassType>(pack.ReadCell()));
	MakeSurvivor(client, index, false);
	PrintHintText(client, "To avoid crashes in the future, try turning off Multicore Rendering in advanced video options.");
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if (!RF2_IsEnabled())
		return;
	
	StopMusicTrack(client);
	if (g_bPlayerTimingOut[client] && IsPlayerSurvivor(client))
	{
		RF2_PrintToChatAll("{yellow}%N {red}crashed or lost connection on RED and has 5 minutes to reconnect!", client);
		PrintToServer("%N crashed or lost connection on RED and has 5 minutes to reconnect!", client);
		char authId[MAX_AUTHID_LENGTH], class[128];
		if (GetClientAuthId(client, AuthId_Steam2, authId, sizeof(authId)))
		{
			int index = RF2_GetSurvivorIndex(client);
			g_hCrashedPlayerSteamIDs.SetValue(authId, index);
			FormatEx(class, sizeof(class), "%s_CLASS", authId);
			g_hCrashedPlayerSteamIDs.SetValue(class, TF2_GetPlayerClass(client)); // Remember class
			SaveSurvivorInventory(client, index);
			DataPack pack;
			g_hCrashedPlayerTimers[index] = CreateDataTimer(300.0, Timer_PlayerReconnect, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteString(authId);
			if (IsSingleplayer(true))
			{
				FindConVar("tf_allow_server_hibernation").SetBool(false);
				FindConVar("tf_bot_join_after_player").SetBool(false);
			}
		}
	}
	else if (!IsFakeClient(client))
	{
		if (g_bRoundActive && !g_bGameOver && !g_bMapChanging)
		{
			CheckRedTeam(client);
		}
		
		if (IsPlayerSurvivor(client) && !g_bPluginReloading)
		{
			SaveSurvivorInventory(client, RF2_GetSurvivorIndex(client));
			// We need to deal with survivors who disconnect during the grace period
			if (g_bGracePeriod)
			{
				ReshuffleSurvivor(client, -1);
			}
		}
	}
	
	g_bPlayerTimingOut[client] = false;
}

public void OnClientDisconnect_Post(int client)
{
	g_flLoopMusicAt[client] = -1.0;
	if (g_hPlayerExtraSentryList[client])
	{
		delete g_hPlayerExtraSentryList[client];
		g_hPlayerExtraSentryList[client] = null;
	}
	
	if (TFBot(client).Follower)
	{
		TFBot(client).Follower.Invalidate();
		//TFBot(client).Follower.Destroy();
		//TFBot(client).Follower = view_as<PathFollower>(0);
	}
	
	TFBot(client).FollowerIndex = -1;
	RefreshClient(client);
	ResetAFKTime(client, false);
	FindConVar("tf_bot_auto_vacate").SetBool(!(GetTotalHumans(false) >= g_cvMaxHumanPlayers.IntValue));
	UpdateGameDescription();
	UpdateBotQuota();
}

public Action Timer_PlayerReconnect(Handle timer, DataPack pack)
{
	pack.Reset();
	char authId[MAX_AUTHID_LENGTH];
	pack.ReadString(authId, sizeof(authId));
	int index;
	g_hCrashedPlayerSteamIDs.GetValue(authId, index);
	g_hCrashedPlayerTimers[index] = null;
	char class[128];
	FormatEx(class, sizeof(class), "%s_CLASS", authId);
	g_hCrashedPlayerSteamIDs.Remove(authId);
	g_hCrashedPlayerSteamIDs.Remove(class);
	if (GetPlayersOnTeam(TEAM_SURVIVOR, true) == 0)
	{
		PrintToServer("[RF2] The game has ended because a timed-out client took too long to rejoin, and there are no players left on RED!");
		GameOver();
	}
	
	return Plugin_Continue;
}

void CheckRedTeam(int client)
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client || !IsClientInGame(i))
			continue;

		if (IsPlayerSurvivor(i))
			count++;
	}
	
	if (count <= 0 && !g_bRoundEnding) // Everybody on RED is gone, game over
	{
		RF2_PrintToChatAll("%t", "AllHumansDisconnected");
		GameOver();
	}
}

void ReshuffleSurvivor(int client, int teamChange=TEAM_ENEMY)
{
	int index = RF2_GetSurvivorIndex(client);
	RefreshClient(client, true);
	if (IsClientInGame(client) && teamChange >= 0)
	{
		ChangeClientTeam(client, teamChange);
	}
	
	bool allowBots = g_cvBotsCanBeSurvivor.BoolValue;
	int points[MAXTF2PLAYERS], playerPoints[MAXTF2PLAYERS];
	bool valid[MAXTF2PLAYERS];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client || !IsClientInGame(i) || IsPlayerSurvivor(i) || !GetCookieBool(i, g_coBecomeSurvivor) || GetClientTeam(i) <= 1)
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
		if (!valid[i] || i == client || !IsClientInGame(i) || IsFakeClient(i) && !allowBots)
			continue;
		
		// We've found our winner
		if (playerPoints[i] == highestPoints)
		{
			// Lucky you - your points won't be getting reset.
			MakeSurvivor(i, index, false);
			float pos[3], angles[3];
			GetEntPos(client, pos);
			GetClientEyeAngles(client, angles);
			TeleportEntity(i, pos, angles);
			RF2_PrintToChat(i, "%t", "DisconnectChosenAsSurvivor", client);
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
	g_bRoundEnding = false;
	if (!CreateSurvivors())
	{
		g_bRoundActive = false;
		g_bGracePeriod = false;
		PrintToServer("%T", "NoSurvivorsSpawned", LANG_SERVER);
		ReloadPlugin(asBool(g_iStagesCompleted > 0));
		return Plugin_Continue;
	}
	
	if (!g_bGameInitialized)
	{
		CreateTimer(2.0, Timer_DifficultyVote, _, TIMER_FLAG_NO_MAPCHANGE);
		g_bGameInitialized = true;
	}
	
	g_flRoundStartSeconds = g_flSecondsPassed;
	CreateTimer(0.5, Timer_KillEnemyTeam, _, TIMER_FLAG_NO_MAPCHANGE);
	
	int gamerules = FindEntityByClassname(-1, "tf_gamerules");
	if (gamerules == INVALID_ENT)
	{
		gamerules = CreateEntityByName("tf_gamerules");
	}
	
	SetVariantInt(9999);
	AcceptEntityInput(gamerules, "SetRedTeamRespawnWaveTime");
	SetVariantInt(9999);
	AcceptEntityInput(gamerules, "SetBlueTeamRespawnWaveTime");
	SpawnObjects();
	
	if (g_hPlayerTimer)
		delete g_hPlayerTimer;

	if (g_hHudTimer)
		delete g_hHudTimer;

	if (g_hDifficultyTimer)
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

	if (GetRandomInt(1, g_cvArtifactChance.IntValue) == 1)
	{
		//RollArtifacts();
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
	Menu menu = new Menu(Menu_DifficultyVote);
	menu.SetTitle("Vote for the game's difficulty level!");
	menu.AddItem("0", "Scrap (Easy)");
	menu.AddItem("1", "Iron (Normal)");
	menu.AddItem("2", "Steel (Hard)");
	
	if (GetRandomInt(1, 20) == 1)
	{
		menu.AddItem("3", "Titanium (Expert)");
	}

	int clients[MAXTF2PLAYERS] = {-1, ...};
	int clientCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsPlayerSpectator(i) || IsFakeClient(i))
			continue;

		clients[clientCount] = i;
		clientCount++;
	}

	menu.DisplayVote(clients, clientCount, 30);
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
			GetDifficultyName(g_iDifficultyLevel, difficultyName, sizeof(difficultyName), _, true);
			
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
			RF2_SetSurvivorPoints(i, RF2_GetSurvivorPoints(i)+10);
			RF2_PrintToChat(i, "%t", "GainedSurvivorPoints");
		}
	}
	
	g_bRoundEnding = true;
	int winningTeam = event.GetInt("team");
	if (winningTeam == TEAM_SURVIVOR)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerSurvivor(i))
				continue;
			
			UpdatePlayerXP(i, GetPlayerCash(i)/3.0);
			SetPlayerCash(i, 0.0);
		}
		
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
	}
	
	return Plugin_Continue;
}

public Action OnPostInventoryApplication(Event event, const char[] eventName, bool dontBroadcast)
{
	if (!RF2_IsEnabled())
		return Plugin_Continue;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client))
		return Plugin_Continue;
	
	if (g_bWaitingForPlayers)
	{
		CreateTimer(1.0, Timer_SkipWaitHint, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}
	
	if (!g_bRoundActive)
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
		if (!IsPlayerSurvivor(client) && !IsPlayerMinion(client))
		{
			SilentlyKillPlayer(client);
			ChangeClientTeam(client, TEAM_ENEMY);
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

	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		int entity = MaxClients+1;
		while ((entity = FindEntityByClassname(entity, "obj_*")) != INVALID_ENT)
		{
			if (GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client)
			{
				SetEntityHealth(entity, 1);
				RF_TakeDamage(entity, 0, 0, MAX_DAMAGE, DMG_PREVENT_PHYSICS_FORCE);
			}
		}
	}
	
	if (IsFakeClient(client))
	{
		if (TFBot(client).Follower.IsValid())
		{
			TFBot(client).Follower.Invalidate();
		}
	}
	
	g_bPlayerViewingItemMenu[client] = false;
	CancelClientMenu(client, true);
	ClientCommand(client, "slot10");
	TF2Attrib_SetByDefIndex(client, 269, 1.0); // "mod see enemy health"
	TF2Attrib_SetByDefIndex(client, 275, 1.0); // "cancel falling damage"

	// Initialize our stats (health, speed, kb resist) the next frame to ensure it's correct
	RequestFrame(RF_InitStats, client);

	// Calculate max speed on a timer again to fix a... weird issue with players spawning in and being REALLY slow.
	// I don't know why it happens, but this fixes it, so, cool I guess?
	CreateTimer(0.1, Timer_FixSpeedIssue, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

	TF2_AddCondition(client, TFCond_UberchargedHidden, 0.2);
	if (g_bThrillerActive)
	{
		TF2_AddCondition(client, TFCond_HalloweenThriller);
	}

	if (GetClientTeam(client) == TEAM_ENEMY && IsArtifactActive(BLUArtifact_Silence))
	{
		if (GetRandomInt(1, 5) == 1)
		{
			TF2_AddCondition(client, TFCond_StealthedUserBuffFade);
		}
	}

	return Plugin_Continue;
}

public Action Timer_SkipWaitHint(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return Plugin_Continue;
	
	PrintHintText(client, "If everyone is connected, you can skip Waiting For Players with the /rf2_skipwait command.");
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

public Action Timer_FixSpeedIssue(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)) || !IsPlayerAlive(client))
		return Plugin_Continue;

	CalculatePlayerMaxSpeed(client);
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!RF2_IsEnabled())
		return Plugin_Continue;
	
	int deathFlags = event.GetInt("death_flags");
	if (deathFlags & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Continue;
	
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (g_bWaitingForPlayers)
	{
		CreateTimer(0.1, Timer_RespawnPlayerPreRound, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}
	else if (!g_bRoundActive)
	{
		return Plugin_Continue;
	}
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	//int inflictor = event.GetInt("inflictor_entindex");
	int weaponIndex = event.GetInt("weapon_def_index");
	int weaponId = event.GetInt("weaponid");
	int damageType = event.GetInt("damagebits");
	//int customkill = event.GetInt("customkill");
	CritType critType = view_as<CritType>(event.GetInt("crit_type"));
	
	// No dominations
	deathFlags &= ~(TF_DEATHFLAG_KILLERDOMINATION | TF_DEATHFLAG_ASSISTERDOMINATION | TF_DEATHFLAG_KILLERREVENGE | TF_DEATHFLAG_ASSISTERREVENGE);
	event.SetInt("death_flags", deathFlags);
	int victimTeam = GetClientTeam(victim);
	Action action = Plugin_Continue;
	
	int itemProc = g_iEntLastHitItemProc[victim];
	if (attacker > 0)
	{
		DoItemKillEffects(attacker, victim, damageType, critType);
		switch (itemProc)
		{
			case ItemDemo_ConjurersCowl, ItemMedic_WeatherMaster: event.SetString("weapon", "spellbook_lightning");
			
			case Item_Dangeresque, Item_SaxtonHat, ItemSniper_HolyHunter, ItemStrange_CroneDome: event.SetString("weapon", "pumpkindeath");
			
			case ItemEngi_BrainiacHairpiece, ItemStrange_VirtualViewfinder, Item_RoBro: event.SetString("weapon", "merasmus_zap");
			
			case ItemStrange_LegendaryLid: event.SetString("weapon", "kunai");
		}
	}
	
	g_iEntLastHitItemProc[victim] = Item_Null;
	if (TF2_GetPlayerClass(victim) == TFClass_Engineer && IsPlayerSurvivor(victim))
	{
		int entity = MaxClients+1;
		while ((entity = FindEntityByClassname(entity, "obj_*")) != INVALID_ENT)
		{
			if (GetEntPropEnt(entity, Prop_Send, "m_hBuilder") != victim)
				continue;
			
			SetEntityHealth(entity, 1);
			RF_TakeDamage(entity, attacker, attacker, MAX_DAMAGE, DMG_PREVENT_PHYSICS_FORCE);
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
			
			pos[2] += 20.0;
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
			
			if (!g_bHauntedKeyDrop)
			{
				int max = g_cvHauntedKeyDropChanceMax.IntValue;
				if (max > 0 && RandChanceIntEx(attacker, 1, max, 1))
				{
					PrintHintTextToAll("%t", "HauntedKeyDrop", victim);
					g_bHauntedKeyDrop = true;
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsPlayerSurvivor(i))
						{
							GiveItem(i, Item_HauntedKey, 1, true);
						}
					}
				}
			}
			
			if (itemProc == ItemScout_LongFallBoots && IsBoss(victim))
			{
				TriggerAchievement(attacker, ACHIEVEMENT_GOOMBA);
			}
			
			if (weaponIndex == 416 && TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping) && IsBoss(victim))
			{
				TriggerAchievement(attacker, ACHIEVEMENT_MARKETGARDEN);
			}
		}
		else // If the grace period is active, die silently
		{
			RequestFrame(RF_DeleteRagdoll, victim);
			action = Plugin_Stop;
		}
		
		if (attacker > 0 && IsPlayerSurvivor(attacker))
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
				for (int i = 1; i <= MaxClients; i++)
				{
					if (!IsClientInGame(i) || attacker == i || !IsPlayerSurvivor(i))
						continue;

					UpdatePlayerXP(i, xp);
				}
			}
		}
	}
	else if (IsPlayerSurvivor(victim))
	{
		if (!g_bGracePeriod)
		{
			SaveSurvivorInventory(victim, RF2_GetSurvivorIndex(victim));
			PrintDeathMessage(victim, itemProc);
			
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
				
				if (IsValidEntity2(oldFog))
				{
					DataPack pack;
					CreateDataTimer(time, Timer_RestorePlayerFog, pack, TIMER_FLAG_NO_MAPCHANGE);
					pack.WriteCell(GetClientUserId(i));
					pack.WriteCell(EntIndexToEntRef(oldFog));
				}
			}
			
			CreateTimer(time, Timer_KillFog, EntIndexToEntRef(fog), TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(2.5, Timer_SurvivorDeath, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
			
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
			
			if (alive == 0 && !g_cvDebugDontEndGame.BoolValue && !g_bRoundEnding) // Game over, man!
			{
				GameOver();
			}
			else if (alive == 1)
			{
				PrintHintText(lastMan, "%t", "LastMan");
				EmitSoundToAll(SND_LASTMAN);
				SpeakResponseConcept_MVM(lastMan, "TLK_MVM_LAST_MAN_STANDING");
			}
			
			TriggerAchievement(victim, ACHIEVEMENT_DIE);
			TriggerAchievement(victim, ACHIEVEMENT_DIE100);
		}
		else
		{
			// Respawning players right inside of player_death causes strange behaviour.
			CreateTimer(0.1, Timer_RespawnSurvivor, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if (IsPlayerMinion(victim))
	{
		CreateTimer(5.0, Timer_MinionSpawn, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (victimTeam == TEAM_ENEMY && !IsFakeClient(victim))
	{
		SetClientName(victim, g_szPlayerOriginalName[victim]);
	}
	
	bool wasSurvivor = IsPlayerSurvivor(victim);
	RefreshClient(victim);
	if (wasSurvivor)
	{
		// Recalculate our item sharing for other players
		CalculateSurvivorItemShare();
	}
	
	return action;
}

public Action Timer_GameOver(Handle timer)
{
	if (g_iStagesCompleted == 0)
	{
		InsertServerCommand("mp_waitingforplayers_restart 1");
		CreateTimer(1.2, Timer_ReloadPluginNoMapChange, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		ReloadPlugin(true);
	}
	
	return Plugin_Continue;
}

public Action Timer_ReloadPluginNoMapChange(Handle timer)
{
	ReloadPlugin(false);
	return Plugin_Continue;
}

public Action Timer_RespawnPlayerPreRound(Handle timer, int client)
{
	if (!g_bWaitingForPlayers || (client = GetClientOfUserId(client)) <= 0)
		return Plugin_Continue;
	
	TF2_RespawnPlayer(client);
	return Plugin_Continue;
}

public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	float damage = float(event.GetInt("damageamount"));
	int damageCustom = event.GetInt("custom");
	
	if (damageCustom == TF_CUSTOM_HEADSHOT || damageCustom == TF_CUSTOM_HEADSHOT_DECAPITATION && attacker > 0)
	{
		if (PlayerHasItem(attacker, ItemSniper_HolyHunter) && CanUseCollectorItem(attacker, ItemSniper_HolyHunter))
		{
			float pos[3];
			GetEntPos(victim, pos);
			pos[2] += 30.0;
			float radiusDamage = damage * GetItemMod(ItemSniper_HolyHunter, 0);
			radiusDamage *= 1.0 + CalcItemMod(attacker, ItemSniper_HolyHunter, 1, -1);
			float radius = GetItemMod(ItemSniper_HolyHunter, 2);
			radius *= 1.0 + CalcItemMod(attacker, ItemSniper_HolyHunter, 3, -1);
			DoRadiusDamage(attacker, attacker, pos, ItemSniper_HolyHunter, radiusDamage, DMG_BLAST, radius);
			DoExplosionEffect(pos);
		}
		
		if (PlayerHasItem(attacker, ItemSniper_Bloodhound) && CanUseCollectorItem(attacker, ItemSniper_Bloodhound))
		{
			int stacks = GetItemModInt(ItemSniper_Bloodhound, 0) + CalcItemModInt(attacker, ItemSniper_Bloodhound, 1, -1);
			for (int i = 1; i <= stacks; i++)
			{
				TF2_MakeBleed(victim, attacker, GetItemMod(ItemSniper_Bloodhound, 2));
			}
			
			if (stacks >= 20)
			{
				TriggerAchievement(attacker, ACHIEVEMENT_BLOODHOUND);
			}
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

public Action Timer_SurvivorDeath(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
	
	if (GetCookieBool(client, g_coSpecOnDeath))
	{
		ChangeClientTeam(client, 1);
	}
	else
	{
		CreateTimer(0.0, Timer_MinionSpawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		PrintCenterText(client, "%t", "MinionSpawn");
	}
	
	return Plugin_Continue;
}

public Action Timer_MinionSpawn(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || IsPlayerAlive(client))
		return Plugin_Continue;
	
	SpawnMinion(client);
	return Plugin_Continue;
}

public Action Timer_KillFog(Handle timer, int fog)
{
	if (EntRefToEntIndex(fog) == INVALID_ENT)
		return Plugin_Continue;

	AcceptEntityInput(fog, "TurnOff");
	RemoveEntity2(fog);

	return Plugin_Continue;
}

public Action Timer_RestorePlayerFog(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());

	if (client == 0)
		return Plugin_Continue;

	int fog = EntRefToEntIndex(pack.ReadCell());
	if (fog != INVALID_ENT)
	{
		SetEntPropEnt(client, Prop_Data, "m_hCtrl", fog);
	}

	return Plugin_Continue;
}

public void RF_DeleteRagdoll(int client)
{
	if (!IsClientInGame(client))
		return;
	
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "tf_ragdoll")) != INVALID_ENT)
	{
		if (GetEntPropEnt(entity, Prop_Send, "m_hPlayer") == client)
		{
			RemoveEntity2(entity);
			break;
		}
	}
}

public Action OnPlayerChargeDeployed(Event event, const char[] name, bool dontBroadcast)
{
	int medic = GetClientOfUserId(event.GetInt("userid"));
	int medigun = GetPlayerWeaponSlot(medic, WeaponSlot_Secondary);
	bool vaccinator = (TF2Attrib_HookValueInt(0, "set_charge_type", medigun) == 3);
	if (PlayerHasItem(medic, ItemMedic_WeatherMaster))
	{
		int team = GetClientTeam(medic);
		float eyePos[3], enemyPos[3], beamPos[3];
		GetClientEyePosition(medic, eyePos);
		float damage = CalcItemMod(medic, ItemMedic_WeatherMaster, 0) + CalcItemMod(medic, ItemMedic_WeatherMaster, 2);
		float range = sq(CalcItemMod(medic, ItemMedic_WeatherMaster, 1) + CalcItemMod(medic, ItemMedic_WeatherMaster, 3, -1));
		
		if (vaccinator)
		{
			damage *= 0.25;
			range *= 0.75;
		}
		
		Handle trace;
		int hitCount, killCount;
		int entity = -1;
		
		while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT)
		{
			if (entity < 1 || entity == medic)
				continue;
			
			if (!IsCombatChar(entity) || IsValidClient(entity) && !IsPlayerAlive(entity))
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
					RF_TakeDamage(entity, medic, medic, damage, DMG_SHOCK|DMG_PREVENT_PHYSICS_FORCE, ItemMedic_WeatherMaster);
					if (GetEntProp(entity, Prop_Data, "m_iHealth") <= 0)
					{
						killCount++;
					}
					
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
			UTIL_ScreenShake(eyePos, 20.0, 5.0*hitCount, 8.0, range*3.0, SHAKE_START, true);
			
			if (!vaccinator)
			{
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
			}

			if (hitCount >= 5)
			{
				SpeakResponseConcept(medic, "TLK_PLAYER_SPELL_PICKUP_RARE");
			}
		}

		if (killCount >= 10)
		{
			TriggerAchievement(medic, ACHIEVEMENT_THUNDER);
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
		if (TF2_GetObjectType2(building) == TFObject_Dispenser) // must be delayed by a frame or else the screen will break
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
	if (!carryDeploy && (IsPlayerMinion(client) || GetPlayerBuildingCount(client, TFObject_Sentry, false) > 1))
	{
		SetEntPropFloat(building, Prop_Send, "m_flModelScale", 0.6);
		if (TF2_GetObjectType2(building) == TFObject_Sentry)
		{
			SetEntProp(building, Prop_Send, "m_iObjectMode", TFObjectMode_Disposable); // forces main sentry to always show in building HUD
			SetEntProp(building, Prop_Send, "m_bMiniBuilding", true);
			g_hPlayerExtraSentryList[client].Push(building);
			g_bDisposableSentry[building] = true;
		}
			
		if (GetPlayerBuildingCount(client, TFObject_Sentry) >= CalcItemModInt(client, ItemEngi_HeadOfDefense, 0) + 1)
		{
			SetSentryBuildState(client, false);
		}
		
		if (!carryDeploy)
		{
			// We need to set the health before the max health here so that the health increases properly when the sentry is building itself up
			int maxHealth = CalculateBuildingMaxHealth(client, building);
			SetVariantInt(RoundToCeil(float(maxHealth)*0.5));
			AcceptEntityInput(building, "AddHealth");
		}
	}
	else if (GetClientTeam(client) == TEAM_ENEMY && TF2_GetObjectType2(building) == TFObject_Teleporter)
	{
		if (g_flTeleporterNextSpawnTime[building] < 0.0)
			g_flTeleporterNextSpawnTime[building] = GetTickedTime()+(36.0/float(GetEntProp(building, Prop_Send, "m_iUpgradeLevel")));

		RequestFrame(RF_TeleporterThink, EntIndexToEntRef(building));
	}
	
	if (!carryDeploy && GameRules_GetProp("m_bInSetup"))
	{
		SDK_DoQuickBuild(building, true);
	}
	
	if (GetPlayerBuildingCount(client, TFObject_Sentry) >= 10)
	{
		TriggerAchievement(client, ACHIEVEMENT_SENTRIES);
	}
	
	return Plugin_Continue;
}

public void RF_TeleporterThink(int building)
{
	if ((building = EntRefToEntIndex(building)) == INVALID_ENT || GetEntProp(building, Prop_Send, "m_bCarried"))
		return;
	
	if (GetEntProp(building, Prop_Send, "m_bBuilding") || GetEntProp(building, Prop_Send, "m_bHasSapper"))
	{
		RequestFrame(RF_TeleporterThink, EntIndexToEntRef(building));
		return;
	}
	
	// can we spawn enemies?
	float tickedTime = GetTickedTime();
	if (tickedTime >= g_flTeleporterNextSpawnTime[building])
	{
		ArrayList enemies = new ArrayList();
		for (int i = 1; i <= MaxClients; i++)
		{
			if (g_bPlayerInSpawnQueue[i] || !IsClientInGame(i) || IsPlayerAlive(i) || GetClientTeam(i) != TEAM_ENEMY)
				continue;
			
			if (!IsFakeClient(i) && (!GetCookieBool(i, g_coBecomeEnemy) || !g_cvAllowHumansInBlue.BoolValue))
				continue;

			enemies.Push(i);
		}

		enemies.SortCustom(SortEnemySpawnArray);
		int spawns, client;
		float time;
		const int maxSpawns = 2;
		const float max = 250.0;
		float subIncrement = RF2_GetDifficultyCoeff() / g_cvSubDifficultyIncrement.FloatValue;
		float bossChance = subIncrement < max ? subIncrement : max;

		for (int i = 0; i < enemies.Length; i++)
		{
			client = enemies.Get(i);
			if (RF2_GetSubDifficulty() >= SubDifficulty_Impossible && RandChanceFloat(0.0, max, bossChance))
			{
				g_iPlayerBossSpawnType[client] = GetRandomBoss();
			}
			else
			{
				g_iPlayerEnemySpawnType[client] = GetRandomEnemy();
			}

			// Don't spawn everyone on the same frame to reduce lag
			DataPack pack;
			CreateDataTimer(time, Timer_SpawnEnemyTeleporter, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(GetClientUserId(client));
			pack.WriteCell(EntIndexToEntRef(building));
			time += 0.1;
			g_bPlayerInSpawnQueue[client] = true;

			spawns++;
			if (spawns >= maxSpawns)
				break;
		}

		if (spawns > 0)
		{
			EmitSoundToAll(SND_TELEPORTER_BLU, building, _, SNDLEVEL_TRAIN);
		}

		g_flTeleporterNextSpawnTime[building] = spawns > 0 ? tickedTime+(36.0/float(GetEntProp(building, Prop_Send, "m_iUpgradeLevel"))) : tickedTime+2.0;
		delete enemies;
	}

	// force spin animation for BLU teleporters (it's a bit choppy, but that's fine)
	SetEntPropFloat(building, Prop_Send, "m_flPlaybackRate", 1.0);
	SetEntProp(building, Prop_Send, "m_nBody", 1);
	RequestFrame(RF_TeleporterThink, EntIndexToEntRef(building));
}

public Action Timer_SpawnEnemyTeleporter(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;

	int teleporter = EntRefToEntIndex(pack.ReadCell());
	if (teleporter == INVALID_ENT)
	{
		g_iPlayerEnemySpawnType[client] = -1;
		g_iPlayerBossSpawnType[client] = -1;
		return Plugin_Continue;
	}

	float pos[3];
	GetEntPos(teleporter, pos);
	pos[2] += 25.0;

	g_bPlayerSpawnedByTeleporter[client] = true;
	if (g_iPlayerEnemySpawnType[client] > -1)
	{
		SpawnEnemy(client, g_iPlayerEnemySpawnType[client], pos, 0.0, 500.0);
	}
	else if (g_iPlayerBossSpawnType[client] > -1)
	{
		SpawnBoss(client, g_iPlayerBossSpawnType[client], pos, false, 0.0, 700.0);
	}

	return Plugin_Continue;
}

public Action OnChangeTeamMessage(Event event, const char[] name, bool dontBroadcast)
{
	// no team change messages
	event.BroadcastDisabled = true;
	return Plugin_Continue;
}

public Action OnPlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
	char auth[MAX_AUTHID_LENGTH];
	event.GetString("networkid", auth, sizeof(auth));
	if (strcmp2(auth, "BOT"))
		event.BroadcastDisabled = true;
	
	return Plugin_Continue;
}

public Action OnPlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && IsFakeClient(client))
		event.BroadcastDisabled = true;
	
	return Plugin_Continue;
}

public Action OnPlayerHealOnHit(Event event, const char[] name, bool dontBroadcast)
{
	if (event.GetBool("manual")) // manually called from HealPlayer()
		return Plugin_Continue;
	
	int client = event.GetInt("entindex");
	int amount = event.GetInt("amount");
	if (IsPlayerSurvivor(client) && IsArtifactActive(REDArtifact_Restoration))
	{
		amount = RoundToFloor(float(amount) * 2.0);
	}
	
	event.SetInt("amount", RoundToFloor(float(amount) * GetPlayerHealthMult(client)));
	return Plugin_Changed;
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
	RemoveEntity2(caller);
	return Plugin_Continue;
}

void EndGracePeriod()
{
	g_bGracePeriod = false;
	int entity = MaxClients+1;
	
	// Have to do this or else bots will misbehave, thinking it's still setup time. They won't attack players and will randomly taunt.
	while ((entity = FindEntityByClassname(entity, "team_round_timer")) != INVALID_ENT)
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
	g_flBusterSpawnTime = g_cvBusterSpawnInterval.FloatValue;
	CreateTimer(1.0, Timer_BusterSpawnWave, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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
	if (!RF2_IsEnabled() || !g_bRoundActive || IsStageCleared() || WaitingForPlayerRejoin(true))
		return Plugin_Continue;
	
	int survivorCount = RF2_GetSurvivorCount();
	float duration = g_cvEnemyBaseSpawnWaveTime.FloatValue - 2.0 * float(survivorCount-1);
	duration -= float(RF2_GetEnemyLevel()-1) * 0.2;
	
	if (GetCurrentTeleporter().IsValid() && GetCurrentTeleporter().EventState == TELE_EVENT_ACTIVE)
	{
		duration *= 0.8;
	}
	
	if (IsSingleplayer(false))
	{
		if (g_iStagesCompleted == 0)
			duration *= 1.25;
	}
	else
	{
		duration *= GetRandomFloat(0.8, 1.0-(float(survivorCount-1)*0.015));
	}
	
	duration = fmax(duration, g_cvEnemyMinSpawnWaveTime.FloatValue);
	if (IsArtifactActive(BLUArtifact_Swarm))
	{
		duration *= 0.6;
	}
	
	CreateTimer(duration, Timer_EnemySpawnWave, _, TIMER_FLAG_NO_MAPCHANGE);
	if (g_cvDebugDisableEnemySpawning.BoolValue)
		return Plugin_Continue;

	int spawnCount = g_cvEnemyMinSpawnWaveCount.IntValue + RF2_GetSubDifficulty() / 3;
	if (survivorCount >= 4)
	{
		spawnCount++;
	}
	
	if (survivorCount >= 7)
	{
		spawnCount++;
	}
	
	spawnCount = imax(imin(spawnCount, g_cvEnemyMaxSpawnWaveCount.IntValue), g_cvEnemyMinSpawnWaveCount.IntValue);
	float subIncrement = RF2_GetDifficultyCoeff() / g_cvSubDifficultyIncrement.FloatValue;
	ArrayList respawnArray = new ArrayList();
	
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
		
		if (!IsFakeClient(i) && (!GetCookieBool(i, g_coBecomeEnemy) || !g_cvAllowHumansInBlue.BoolValue))
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

public Action Timer_BusterSpawnWave(Handle timer)
{
	if (!g_bRoundActive || IsStageCleared())
		return Plugin_Stop;
	
	if (IsSentryBusterActive())
		return Plugin_Continue;
	
	bool sentryActive;
	int entity = MaxClients+1;
	int owner;
	while ((entity = FindEntityByClassname(entity, "obj_sentrygun")) != INVALID_ENT)
	{
		owner = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
		if (IsValidClient(owner) && IsPlayerSurvivor(owner))
		{
			// don't count disposable sentries because we don't care about them
			if (IsSentryDisposable(entity))
				continue;
			
			sentryActive = true;
			break;
		}
	}
	
	if (sentryActive)
	{
		g_flBusterSpawnTime -= 1.0;
		if (g_flBusterSpawnTime <= 0.0)
		{
			DoSentryBusterWave();
			g_flBusterSpawnTime = g_cvBusterSpawnInterval.FloatValue;
		}
	}
	else
	{
		g_flBusterSpawnTime = fmin(g_flBusterSpawnTime+8.0, g_cvBusterSpawnInterval.FloatValue);
	}

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
		char difficultyName[32];
		GetDifficultyName(RF2_GetDifficulty(), difficultyName, sizeof(difficultyName), false);
		if (IsPlayerSurvivor(i))
		{
			if (g_bTankBossMode && !g_bGracePeriod)
			{
				if (IsValidEntity2(g_iPlayerLastAttackedTank[i]))
				{
					static char classname[128], name[32];
					int maxHealth;
					int health = GetEntProp(g_iPlayerLastAttackedTank[i], Prop_Data, "m_iHealth");
					GetEntityClassname(g_iPlayerLastAttackedTank[i], classname, sizeof(classname));
					
					if (IsTankBadass(g_iPlayerLastAttackedTank[i]))
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
					g_iPlayerLastAttackedTank[i] = INVALID_ENT;
					FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "Tanks Destroyed: %i/%i",
						g_iTanksKilledObjective, g_iTankKillRequirement);
				}
			}
			
			TFClassType class = TF2_GetPlayerClass(i);
			if (class == TFClass_Spy && g_flPlayerVampireSapperCooldown[i] > 0.0)
			{
				FormatEx(miscText, sizeof(miscText), "\nSapper Cooldown: %.1f", g_flPlayerVampireSapperCooldown[i]);
			}
			else if (class == TFClass_Engineer && PlayerHasItem(i, ItemEngi_HeadOfDefense))
			{
				FormatEx(miscText, sizeof(miscText), 
					"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n																													Disposable Sentries: %i/%i", 
					g_hPlayerExtraSentryList[i].Length, CalcItemModInt(i, ItemEngi_HeadOfDefense, 0));
			}
			
			ShowSyncHudText(i, g_hMainHudSync, g_szSurvivorHudText, g_iStagesCompleted+1, difficultyName, g_iMinutesPassed,
				hudSeconds, g_iEnemyLevel, g_iPlayerLevel[i], g_flPlayerXP[i], g_flPlayerNextLevelXP[i],
				g_flPlayerCash[i], g_szHudDifficulty, strangeItemInfo, miscText);
		}
		else
		{
			ShowSyncHudText(i, g_hMainHudSync, g_szEnemyHudText, g_iStagesCompleted+1, difficultyName, g_iMinutesPassed, hudSeconds,
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
	
	if (g_bGameOver || g_bGracePeriod || WaitingForPlayerRejoin(true))
		return Plugin_Continue;
	
	float secondsToAdd = 1.0;
	if (IsArtifactActive(REDArtifact_Patience))
	{
		secondsToAdd *= 0.5;
	}

	if (IsArtifactActive(BLUArtifact_Haste))
	{
		secondsToAdd *= 2.0;
	}
	
	g_flSecondsPassed += secondsToAdd;
	if (g_flSecondsPassed >= 60.0 * (float(g_iMinutesPassed+1)))
	{
		float seconds = g_flSecondsPassed - (float(g_iMinutesPassed) * 60.0);
		g_iMinutesPassed += RoundToFloor(seconds/60.0);
	}
	
	float secondsSinceStart = g_flSecondsPassed - g_flRoundStartSeconds;
	if (secondsSinceStart >= 360.0 && !g_bTeleporterEventReminder && GetCurrentTeleporter().IsValid())
	{
		RF2_Object_Teleporter teleporter = GetCurrentTeleporter();
		if (teleporter.EventState == TELE_EVENT_INACTIVE)
		{
			teleporter.SetGlow(true);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerSurvivor(i))
				{
					PrintHintText(i, "Remember, as time passes, the strength of the enemy increases. Don't forget to activate the Teleporter!");
				}
			}
		}
		
		g_bTeleporterEventReminder = true;
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
	int sentry = INVALID_ENT;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		// All players have infinite reserve ammo
		weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
		if (weapon != INVALID_ENT)
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
			if (g_flPlayerRegenBuffTime[i] > 0.0)
				g_flPlayerRegenBuffTime[i] -= 0.1;

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
						healAmount += CalcItemModInt(i, Item_Archimedes, 0);
					
					if (PlayerHasItem(i, Item_ClassCrown))
						healAmount += CalcItemModInt(i, Item_ClassCrown, 1);
					
					if (g_flPlayerRegenBuffTime[i] > 0.0)
						healAmount += CalcItemModInt(i, Item_DapperTopper, 0);
					
					if (IsPlayerSurvivor(i))
					{
						if (RF2_GetDifficulty() == DIFFICULTY_STEEL)
						{
							g_flPlayerHealthRegenTime[i] += 0.2;
						}
						else if (RF2_GetDifficulty() == DIFFICULTY_TITANIUM)
						{
							g_flPlayerHealthRegenTime[i] += 0.3;
						}
						else if (RF2_GetDifficulty() == DIFFICULTY_SCRAP)
						{
							healAmount = RoundFloat(float(healAmount) * 1.5);
						}
					}
					
					healAmount = imax(healAmount, 1);
					HealPlayer(i, healAmount, false, _, false);
				}
			}
		}
		
		if (g_flPlayerVampireSapperCooldown[i] > 0.0)
		{
			g_flPlayerVampireSapperCooldown[i] -= 0.1;
		}
		
		// hotfix - start equipment cooldown if it stops for some reason?
		if (!g_bEquipmentCooldownActive[i])
		{
			if (g_flPlayerEquipmentItemCooldown[i] > 0.0)
			{
				g_bEquipmentCooldownActive[i] = true;
				CreateTimer(0.1, Timer_EquipmentCooldown, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else if (g_flPlayerEquipmentItemCooldown[i] <= 0.0)
		{
			g_bEquipmentCooldownActive[i] = false;
		}
		
		if (g_hPlayerExtraSentryList[i].Length > 0)
		{
			for (int a = 0; a < g_hPlayerExtraSentryList[i].Length; a++)
			{
				sentry = g_hPlayerExtraSentryList[i].Get(a);
				if (!IsValidEntity2(sentry))
				{
					g_hPlayerExtraSentryList[i].Erase(a);
					a--;
					continue;
				}
				
				if (IsSentryDisposable(sentry) && GetEntProp(sentry, Prop_Send, "m_iAmmoShells") <= 0 
					&& !GetEntProp(sentry, Prop_Send, "m_bCarried") && !GetEntProp(sentry, Prop_Send, "m_bBuilding"))
				{
					SetVariantInt(9999);
					AcceptEntityInput(sentry, "RemoveHealth");
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action Timer_PluginMessage(Handle timer)
{
	if (!RF2_IsEnabled())
		return Plugin_Stop;
	
	static int message;
	const int maxMessages = 6;
	
	switch (message)
	{
		case 0: RF2_PrintToChatAll("%t", "TipSettings");
		case 1: RF2_PrintToChatAll("%t", "TipItemLog");
		case 2: RF2_PrintToChatAll("%t", "TipCredits", PLUGIN_VERSION);
		case 3: RF2_PrintToChatAll("%t", "TipQueue");
		case 4: RF2_PrintToChatAll("%t", "TipMenu");
		case 5:	RF2_PrintToChatAll("%t", "TipDiscord");
		case 6: RF2_PrintToChatAll("%t", "TipAchievements");
	}
	
	message++;
	if (message > maxMessages)
		message = 0;

	return Plugin_Continue;
}

public Action Timer_DeleteEntity(Handle timer, int entity)
{
	entity = EntRefToEntIndex(entity);

	if (entity != INVALID_ENT)
		RemoveEntity2(entity);

	return Plugin_Continue;
}

public Action Timer_AFKManager(Handle timer)
{
	if (!RF2_IsEnabled() || IsSingleplayer())
		return Plugin_Continue;

	int kickPriority[MAXTF2PLAYERS];
	int highestKickPriority = -1;
	int afkCount;
	int humanCount = GetTotalHumans();
	int afkLimit = g_cvAFKLimit.IntValue;
	int minHumans = g_cvAFKMinHumans.IntValue;
	float afkKickTime = g_cvAFKManagerKickTime.FloatValue;
	bool kickAdmins = g_cvAFKKickAdmins.BoolValue;
	bool managerEnabled = g_cvEnableAFKManager.BoolValue;
	
	// first we need to count our AFKs to see if anyone needs kicking
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		if (IsPlayerAFK(i) && managerEnabled)
		{
			kickPriority[i] += RoundToFloor(g_flPlayerAFKTime[i]); // kick whoever has been AFK the longest first
			if (kickPriority[i] > highestKickPriority || highestKickPriority < 0)
			{
				highestKickPriority = kickPriority[i];
			}
			
			afkCount++;
		}
	}
	
	float time = g_bWaitingForPlayers ? afkKickTime * 0.35 : afkKickTime * 0.5;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		g_flPlayerAFKTime[i] += 1.0;
		if (g_flPlayerAFKTime[i] >= afkKickTime * time)
		{
			if (!IsPlayerAlive(i) && GetClientTeam(i) > 1)
			{
				ChangeClientTeam(i, 1);
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
			else if (managerEnabled)
			{
				PrintCenterText(i, "%t", "AFKDetected");
			}
		}
		
		if (managerEnabled && afkCount >= afkLimit && g_flPlayerAFKTime[i] >= afkKickTime && kickPriority[i] >= highestKickPriority && humanCount >= minHumans)
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
	if (!RF2_IsEnabled() || !IsClientInGame(client))
		return Plugin_Continue;
	
	int num1 = GetCmdArgInt(1);
	int num2 = GetCmdArgInt(2);
	if (num1 == 0 && num2 == 0)
	{
		return OnCallForMedic(client);
	}

	return Plugin_Continue;
}

Action OnCallForMedic(int client)
{
	if (!IsPlayerAlive(client))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (i == client || !IsClientInGame(i) || !IsPlayerSurvivor(i))
				continue;
			
			if (GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") == i)
			{
				ShowItemMenu(client, i);
				break;
			}
		}
		
		return Plugin_Continue;
	}
	
	if (IsPlayerSurvivor(client))
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
		
		if (PickupItem(client))
			return Plugin_Handled;
		
		float eyePos[3], eyeAng[3], endPos[3], direction[3];
		GetClientEyePosition(client, eyePos);
		GetClientEyeAngles(client, eyeAng);
		GetAngleVectors(eyeAng, direction, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(direction, direction);
		const float range = 100.0;
		CopyVectors(eyePos, endPos);
		endPos[0] += direction[0] * range;
		endPos[1] += direction[1] * range;
		endPos[2] += direction[2] * range;
		TR_TraceRayFilter(eyePos, endPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter_DontHitSelf, client);
		TR_GetEndPosition(endPos);
		RF2_Object_Base obj = RF2_Object_Base(GetNearestEntity(endPos, "rf2_object*"));
		if (obj.IsValid())
		{
			float pos[3];
			obj.GetAbsOrigin(pos);
			if (GetVectorDistance(endPos, pos, true) <= sq(range))
			{
				Call_StartForward(obj.OnInteractForward);
				Call_PushCell(client);
				Call_PushCell(obj);
				Action action;
				Call_Finish(action);
				return action;
			}
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
		// don't nag dead players for trying to change class
		if (IsPlayerAlive(client) && !IsPlayerMinion(client))
		{
			RF2_PrintToChat(client, "%t", "NoChangeClass");
		}
		
		if (TF2_GetPlayerClass(client) != TFClass_Unknown)
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", desiredClass);
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
		if (IsPlayerSurvivor(client) && IsSingleplayer())
		{
			RF2_PrintToChat(client, "%t", "NoChangeTeam");
			return Plugin_Handled;
		}
		
		if (strcmp2(command, "autoteam"))
		{
			return Plugin_Handled;
		}

		int team = GetClientTeam(client);
		int newTeam;
		if (strcmp2(command, "spectate"))
		{
			newTeam = 1;
		}
		else
		{
			char teamName[16];
			GetCmdArg(1, teamName, sizeof(teamName));
			if (strcmp2(teamName, "random"))
			{
				return Plugin_Handled;
			}
			
			newTeam = FindTeamByName(teamName);
			if (newTeam < 0)
			{
				return Plugin_Continue;
			}
		}
		
		if (IsTeleporterBoss(client) || team == TEAM_SURVIVOR && IsPlayerAlive(client) && IsPlayerSurvivor(client) && !g_bGracePeriod)
		{
			RF2_PrintToChat(client, "%t", "NoChangeTeam");
			return Plugin_Handled;
		}
		else if (IsPlayerSurvivor(client))
		{
			ReshuffleSurvivor(client, newTeam);
		}
		else if (newTeam == TEAM_SURVIVOR)
		{
			CreateTimer(1.0, Timer_MinionSpawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	return Plugin_Continue;
}

public Action OnChangeSpec(int client, const char[] command, int args)
{
	if (!IsSingleplayer(false))
		ResetAFKTime(client);

	RequestFrame(RF_CheckSpecTarget, GetClientUserId(client));
	return Plugin_Continue;
}

public void RF_CheckSpecTarget(int client)
{
	client = GetClientOfUserId(client);

	// apparently can be invalid?
	if (!IsValidClient(client))
		return;
	
	/*int specTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	if (IsValidClient(specTarget) && IsPlayerSurvivor(specTarget) && !GetCookieBool(specTarget, g_coDisableSpecMenu))
	{
		ShowItemMenu(client, specTarget);
	}
	*/
}

public Action OnBuildCommand(int client, const char[] command, int args)
{
	if (g_bWaitingForPlayers || !IsClientInGame(client))
		return Plugin_Continue;
	
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
	else if (!IsPlayerMinion(client)) // Only minions can suicide
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
	// IsClientTimingOut() doesn't work in OnClientDisconnect, so this is required to know if a client times out when disconnecting
	g_bPlayerTimingOut[client] = !IsFakeClient(client) && IsClientTimingOut(client);
	if (g_bWaitingForPlayers && !IsPlayerAlive(client) && GetClientTeam(client) > 1)
	{
		TF2_RespawnPlayer(client);
	}
	
	if (!g_bRoundActive)
		return;
	
	float engineTime = GetEngineTime();
	bool bot = IsFakeClient(client);

	if (!bot && !IsStageCleared() && g_flLoopMusicAt[client] > 0.0 && engineTime >= g_flLoopMusicAt[client])
	{
		RF2_Object_Teleporter teleporter = GetCurrentTeleporter();
		if (!teleporter.IsValid() || teleporter.EventState != TELE_EVENT_PREPARING)
		{
			StopMusicTrack(client);
			PlayMusicTrack(client);
		}
	}
	
	if (!IsPlayerAlive(client))
		return;
	
	if (bot)
	{
		TFBot_Think(TFBot(client));
	}
	
	TFClassType class = TF2_GetPlayerClass(client);
	if (class == TFClass_Engineer)
	{
		float tickedTime = GetTickedTime();
		if (tickedTime >= g_flPlayerNextMetalRegen[client])
		{
			int metal;
			if (GetClientTeam(client) == TEAM_ENEMY)
			{
				metal = 999999;
			}
			else
			{
				metal = RoundToFloor(float(g_cvEngiMetalRegenAmount.IntValue) * (1.0 + float(GetPlayerLevel(client)) * 0.12));
			}

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
			int airDashLimit = GetPlayerItemCount(client, ItemScout_MonarchWings)+1;
			if (g_iPlayerAirDashCounter[client] < airDashLimit)
			{
				g_iPlayerAirDashCounter[client]++;
				OnPlayerAirDash(client, g_iPlayerAirDashCounter[client]);
			}
		}
	}
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (!RF2_IsEnabled())
		return;
	
	if (condition == TFCond_Taunting && !g_bWaitingForPlayers)
	{
		if (IsFakeClient(client) && GetEntProp(client, Prop_Send, "m_iTauntIndex"))
		{
			// Bots never do non-weapon taunts
			TF2_RemoveCondition(client, TFCond_Taunting);
		}
		else if (!GetEntProp(client, Prop_Send, "m_iTauntIndex")) // Weapon taunts are always 0
		{
			int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (activeWeapon > 0 && IsWeaponTauntBanned(activeWeapon))
			{
				TF2_RemoveCondition(client, TFCond_Taunting);
				SlapPlayer(client);
				EmitSoundToClient(client, SND_NOPE);
			}
		}
	}
	else if (condition == TFCond_BlastJumping)
	{
		if (PlayerHasItem(client, ItemSoldier_HawkWarrior) && CanUseCollectorItem(client, ItemSoldier_HawkWarrior))
		{
			float meleeRangeBonus = fmin(1.0 + CalcItemMod(client, ItemSoldier_HawkWarrior, 1), 1.0 + GetItemMod(ItemSoldier_HawkWarrior, 2));
			int melee = GetPlayerWeaponSlot(client, WeaponSlot_Melee);
			if (melee != INVALID_ENT)
			{
				TF2Attrib_SetByDefIndex(melee, 264, meleeRangeBonus);
			}
		}
	}
	else if (condition == TFCond_Dazed)
	{
		if (!RF2_CanBeStunned(client) && IsPlayerStunned(client))
		{
			TF2_RemoveCondition(client, TFCond_Dazed);
			return;
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
	if (!RF2_IsEnabled())
		return;
	
	if (condition == TFCond_BlastJumping && CanUseCollectorItem(client, ItemSoldier_HawkWarrior))
	{
		int melee = GetPlayerWeaponSlot(client, WeaponSlot_Melee);
		if (melee != INVALID_ENT)
		{
			TF2Attrib_RemoveByDefIndex(melee, 264);
		}
	}
	else if (condition == TFCond_Buffed && PlayerHasItem(client, Item_MisfortuneFedora))
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

int g_iLastFiredWeapon[MAXTF2PLAYERS] = {INVALID_ENT, ...};
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
			if (RollAttackCrit(client, melee ? DMG_MELEE : DMG_GENERIC))
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
			&& (!IsPlayerSurvivor(client) || GetClientHealth(client) / RF2_GetCalculatedMaxHealth(client) >= GetItemMod(ItemPyro_PyromancerMask, 5))
			&& GetTickedTime() >= g_flPlayerNextFireSpellTime[client])
		{
			float speed = GetItemMod(ItemPyro_PyromancerMask, 2) + CalcItemMod(client, ItemPyro_PyromancerMask, 3, -1);
			speed = fmin(speed, GetItemMod(ItemPyro_PyromancerMask, 4));
			float eyePos[3], eyeAng[3];
			GetClientEyePosition(client, eyePos);
			GetClientEyeAngles(client, eyeAng);
			float damage = GetItemMod(ItemPyro_PyromancerMask, 0) + CalcItemMod(client, ItemPyro_PyromancerMask, 1, -1);
			int fireball = ShootProjectile(client, "rf2_projectile_fireball", eyePos, eyeAng, speed, damage);
			SetEntItemProc(fireball, ItemPyro_PyromancerMask);
			g_flPlayerNextFireSpellTime[client] = GetTickedTime() + GetItemMod(ItemPyro_PyromancerMask, 6);
		}
		
		if (PlayerHasItem(client, ItemDemo_ConjurersCowl) && CanUseCollectorItem(client, ItemDemo_ConjurersCowl)
			&& (!IsPlayerSurvivor(client) || GetClientHealth(client) / RF2_GetCalculatedMaxHealth(client) >= GetItemMod(ItemDemo_ConjurersCowl, 5))
			&& GetTickedTime() >= g_flPlayerNextDemoSpellTime[client])
		{
			float speed = GetItemMod(ItemDemo_ConjurersCowl, 2) + CalcItemMod(client, ItemDemo_ConjurersCowl, 3, -1);
			speed = fmin(speed, GetItemMod(ItemDemo_ConjurersCowl, 4));
			float eyePos[3], eyeAng[3];
			GetClientEyePosition(client, eyePos);
			GetClientEyeAngles(client, eyeAng);
			float damage = GetItemMod(ItemDemo_ConjurersCowl, 0) + CalcItemMod(client, ItemDemo_ConjurersCowl, 1, -1);
			int beam = ShootProjectile(client, "rf2_projectile_beam", eyePos, eyeAng, speed, damage, -4.0);
			SetEntItemProc(beam, ItemDemo_ConjurersCowl);
			g_flPlayerNextDemoSpellTime[client] = GetTickedTime() + GetItemMod(ItemDemo_ConjurersCowl, 6);
		}
	}
	
	// A player is firing tf_weapon_sniperrifle_classic in midair.
	// Because of the DHook that we use to get this to work, the weapon firing sound will not play as it is predicted, so we need to play it manually here.
	if (g_bWasOffGround)
	{
		static char sound[PLATFORM_MAX_PATH];
		switch (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
		{
			case 14, 201, 664, 792, 801, 881, 890, 899, 908, 957, 966: // Stock
			{
				sound = GSND_SNIPER_STOCK;
			}
			
			case 230: // Sydney Sleeper
			{
				sound = GSND_SYDNEY;
			}
			
			case 402: // Bazaar Bargain
			{
				sound = GSND_BAZAAR;
			}
			
			case 526: // Machina
			{
				sound = GSND_MACHINA;
			}

			case 752: // Hitman's Heatmaker
			{
				sound = GSND_HEATMAKER;
			}

			case 851: // AWP
			{
				sound = GSND_AWP;
			}

			case 1098: // Classic
			{
				sound = GSND_CLASSIC;
			}

			case 30665: // Shooting Star
			{
				sound = GSND_SHOOTINGSTAR;
			}
			
			default:
			{
				sound = GSND_SNIPER_STOCK;
			}
		}
		
		if (result)
		{
			StrCat(sound, sizeof(sound), "Crit");
		}
		
		EmitGameSoundToAll(sound, client);
	}

	return changed ? Plugin_Changed : Plugin_Continue;
}

public void RF_NextPrimaryAttack(int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return;
	
	int weapon;
	if ((weapon = EntRefToEntIndex(g_iLastFiredWeapon[client])) == INVALID_ENT)
		return;
	
	// Calculate based on the time the weapon was fired at since that was in the last frame.
	float gameTime = g_flWeaponFireTime[client];
	float time = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
	
	time -= gameTime;
	time *= GetPlayerFireRateMod(client, weapon);
	
	// Melee weapons have a swing speed cap
	bool melee = (GetPlayerWeaponSlot(client, WeaponSlot_Melee) == weapon);
	if (time < 0.3 && melee)
	{
		time = 0.3;
	}
	
	if (!melee && IsPlayerSurvivor(client) && time <= GetTickInterval())
	{
		static char classname[128];
		GetEntityClassname(weapon, classname, sizeof(classname));
		if (!strcmp2(classname, "tf_weapon_flamethrower") && !strcmp2(classname, "tf_weapon_minigun"))
		{
			TriggerAchievement(client, ACHIEVEMENT_FIRERATECAP);
		}
	}
	
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", gameTime+time);
}

public Action Hook_ProjectileForceDamage(int entity, int other)
{
	if (!IsValidClient(other) && !IsNPC(other) && !IsBuilding(other))
	{
		RemoveEntity2(entity);
		return Plugin_Handled;
	}
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (!IsValidEntity2(owner))
	{
		owner = 0;
	}
	
	float damage = g_flProjectileForcedDamage[entity];
	int damageFlags = DMG_SONIC;
	if (HasEntProp(entity, Prop_Send, "m_bCritical") && GetEntProp(entity, Prop_Send, "m_bCritical"))
	{
		damageFlags |= DMG_CRIT;
	}
	
	RF_TakeDamage(other, entity, owner, damage, damageFlags);
	RemoveEntity2(entity);
	return Plugin_Handled;
}

public void TF2_OnWaitingForPlayersStart()
{
	if (!RF2_IsEnabled())
		return;
	
	// Hide any map spawned objects
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "rf2_object*")) != INVALID_ENT)
	{
		if (RF2_Object_Base(entity).MapPlaced)
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
	g_flWaitRestartTime = 0.0;
	PrintToServer("%T", "WaitingEnd", LANG_SERVER);
}

public void OnGameFrame()
{
	if (g_bPluginEnabled)
	{
		if (g_flWaitRestartTime > 0.0 && GetTickedTime() >= g_flWaitRestartTime && GetTotalHumans(false) == 0)
		{
			PrintToServer("[RF2] Waited too long for players to join. Restarting game...");
			g_flWaitRestartTime = 0.0;
			ReloadPlugin(true);
		}
		
		if (g_flNextAutoReloadCheckTime > 0.0 && GetTickedTime() >= g_flNextAutoReloadCheckTime)
		{
			int time = GetPluginModifiedTime();
			if (time != -1 && time != g_iFileTime)
			{
				g_flNextAutoReloadCheckTime = 0.0;
				
				// if server is empty, we can just reload now
				if (!g_bGameInitialized && GetTotalHumans(false) == 0)
				{
					LogMessage("A change to the plugin has been detected, reloading in 8 seconds.");
					g_flAutoReloadTime = GetTickedTime()+8.0;
				}
				else
				{
					LogMessage("A change to the plugin has been detected, locking plugin loads/reloads.");
					InsertServerCommand("sm plugins load_lock");
				}
			}
			else
			{
				g_flNextAutoReloadCheckTime = GetTickedTime() + 1.0;
			}
		}
		
		if (!g_bGameInitialized && g_flAutoReloadTime > 0.0 && GetTickedTime() >= g_flAutoReloadTime)
		{
			g_flAutoReloadTime = 0.0;
			ReloadPlugin(false);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!RF2_IsEnabled() || entity < 0 || entity >= MAX_EDICTS)
		return;
	
	g_flCashValue[entity] = 0.0;
	g_iEntityPathFollowerIndex[entity] = -1;
	g_iItemDamageProc[entity] = Item_Null;
	g_iLastItemDamageProc[entity] = Item_Null;
	g_iEntLastHitItemProc[entity] = Item_Null;
	g_bDisposableSentry[entity] = false;
	g_bDontDamageOwner[entity] = false;
	g_bDontRemoveWearable[entity] = false;
	g_bItemWearable[entity] = false;
	g_bCashBomb[entity] = false;
	g_bFiredWhileRocketJumping[entity] = false;
	g_flTeleporterNextSpawnTime[entity] = -1.0;
	
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
			RemoveEntity2(entity);
		}
	}
	else if (strcmp2(classname, "tf_projectile_balloffire"))
	{
		// Dragon's Fury is stupid and doesn't fire CalcIsAttackCritical()
		RequestFrame(RF_DragonFuryCritCheck, EntIndexToEntRef(entity));
	}
	else if (g_hHookRiflePostFrame && StrContains(classname, "tf_weapon_sniperrifle") == 0)
	{
		DHookEntity(g_hHookRiflePostFrame, false, entity, _, DHook_RiflePostFrame);
		DHookEntity(g_hHookRiflePostFrame, true, entity, _, DHook_RiflePostFramePost);
	}
	else if (IsEntityBlacklisted(classname))
	{
		RemoveEntity2(entity);
	}
	else if (IsBuilding(entity))
	{
		if (g_hHookStartUpgrading)
		{
			DHookEntity(g_hHookStartUpgrading, false, entity, _, DHook_StartUpgrading);
			DHookEntity(g_hHookStartUpgrading, true, entity, _, DHook_StartUpgradingPost);
		}
		
		SDKHook(entity, SDKHook_OnTakeDamage, Hook_BuildingOnTakeDamage);
		SDKHook(entity, SDKHook_OnTakeDamagePost, Hook_BuildingOnTakeDamagePost);
		CreateTimer(0.5, Timer_BuildingHealthRegen, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (IsNPC(entity))
	{
		SDKHook(entity, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamageAlive);
		SDKHook(entity, SDKHook_OnTakeDamageAlivePost, Hook_OnTakeDamageAlivePost);
		if (g_hHookShouldCollideWith && !IsTank(entity))
		{
			ILocomotion loco = CBaseEntity(entity).MyNextBotPointer().GetLocomotionInterface();
			DHookRaw(g_hHookShouldCollideWith, true, view_as<Address>(loco), _, DHook_ShouldCollideWith);
		}
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
	else if (IsBuilding(entity) && TF2_GetObjectType2(entity) == TFObject_Sentry)
	{
		int index;
		int builder = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
		if (builder > 0 && g_hPlayerExtraSentryList[builder] && (index = g_hPlayerExtraSentryList[builder].FindValue(entity)) != INVALID_ENT)
		{
			g_hPlayerExtraSentryList[builder].Erase(index);
		}
	}
	
	PathFollower pf = GetEntPathFollower(entity);
	if (pf && pf.IsValid())
	{
		pf.Invalidate();
	}
	
	g_iEntityPathFollowerIndex[entity] = -1;
	g_flCashValue[entity] = 0.0;
}

public void RF_DragonFuryCritCheck(int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (IsValidClient(owner))
	{
		if (RollAttackCrit(owner))
		{
			SetEntProp(entity, Prop_Send, "m_bCritical", true);
			StopSound(owner, SNDCHAN_AUTO, SND_WEAPON_CRIT);
			EmitSoundToAll(SND_WEAPON_CRIT, owner);
		}
		
		int weapon = GetPlayerWeaponSlot(owner, 0);
		if (weapon > 0)
		{
			static char classname[64];
			GetEntityClassname(weapon, classname, sizeof(classname));
			if (strcmp2(classname, "tf_weapon_rocketlauncher_fireball"))
			{
				float mult = GetPlayerFireRateMod(owner, weapon);
				SetEntPropFloat(weapon, Prop_Send, "m_flRechargeScale", mult);
				if (0.8 / mult <= GetTickInterval())
				{
					TriggerAchievement(owner, ACHIEVEMENT_FIRERATECAP);
				}
			}
		}
	}
}

public MRESReturn DHook_ShouldCollideWith(Address loco, DHookReturn returnVal, DHookParam params)
{
	int client = params.Get(1);
	if (client > 0 && client <= MaxClients)
	{
		returnVal.Value = false;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
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
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return;

	int launcher = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

	if (launcher > 0 && IsValidClient(owner))
	{
		char buffer[PLATFORM_MAX_PATH];
		TF2Attrib_HookValueString("", "custom_projectile_model", launcher, buffer, sizeof(buffer));

		if (buffer[0])
		{
			SetEntityModel2(entity, buffer);
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
		RemoveEntity2(entity);
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
			RemoveEntity2(entity);
		}
	}
}

public Action Hook_CashTouch(int entity, int other)
{
	if (IsValidClient(other))
	{
		if (!IsPlayerSurvivor(other) && !IsPlayerMinion(other))
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
	bool inflictorIsBuilding = inflictor > 0 && IsBuilding(inflictor);
	bool attackerIsNpc = IsNPC(attacker);
	bool validWeapon = weapon > 0 && !IsCombatChar(weapon); // Apparently the weapon can be the attacker??
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
	
	if (inflictor > 0 && !ShouldDamageOwner(inflictor) && victim == GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity"))
	{
		return Plugin_Handled;
	}
	
	float originalDamage = damage;
	int originalDamageType = damageType;
	bool ignoreResist;
	if (attackerIsClient && validWeapon)
	{
		int initial;
		if (TF2Attrib_HookValueInt(initial, "mod_pierce_resists_absorbs", weapon) > 0)
		{
			ignoreResist = true;
		}
	}
	
	if (inflictorIsBuilding)
	{
		if (GetEntProp(inflictor, Prop_Data, "m_iTeamNum") == TEAM_ENEMY)
			damageType |= DMG_PREVENT_PHYSICS_FORCE;
		
		if (victim == attacker)
		{
			damage *= 0.4;
			damageType &= ~DMG_CRIT;
			return Plugin_Changed;
		}
	}
	
	if (victimIsClient && IsSingleplayer(false) && IsPlayerSurvivor(victim))
	{
		damage *= 0.8;
	}
	
	if ((victimIsBuilding || victimIsNpc || victimIsClient && IsBoss(victim)) && attackerIsClient && PlayerHasItem(attacker, Item_Graybanns))
	{
		damage *= 1.0 + CalcItemMod(attacker, Item_Graybanns, 0);
	}
	
	static char inflictorClassname[64];
	if (inflictor > 0)
	{
		GetEntityClassname(inflictor, inflictorClassname, sizeof(inflictorClassname));
	}
	
	if (inflictor > 0 && damageType & DMG_CRUSH && victimIsClient && IsTank(inflictor))
	{
		// block tank crush damage
		return Plugin_Handled;
	}
	
	bool selfDamage = (attacker == victim || inflictor == victim);
	bool rangedDamage = (damageType & DMG_BULLET || damageType & DMG_BLAST || damageType & DMG_IGNITE || damageType & DMG_SONIC);
	bool invuln = victimIsClient && IsInvuln(victim);
	
	if (victimIsClient)
	{
		// because there's no fall damage, red team takes increased self blast damage, although it is capped at 15% max hp due to damage scaling
		if (selfDamage && rangedDamage && IsPlayerSurvivor(victim))
		{
			damage *= 1.3;
		}
		
		if (PlayerHasItem(victim, Item_Goalkeeper))
		{
			int activeWeapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
			if (activeWeapon != INVALID_ENT && activeWeapon == GetPlayerWeaponSlot(victim, WeaponSlot_Melee))
			{
				damage *= 1.0 + CalcItemMod(victim, Item_Goalkeeper, 3);
			}
		}
	}
	else if (victimIsNpc)
	{
		static char classname[128];
		GetEntityClassname(victim, classname, sizeof(classname));
		
		if (inflictorIsBuilding)
		{
			if (RF2_SentryBuster(victim).IsValid())
			{
				damage *= 0.25;
				damage = fmax(damage, 1.0);
			}
		}
		else if (attackerIsClient && IsPlayerSurvivor(attacker) && g_iPlayerLastAttackedTank[attacker] != victim && IsTank(victim))
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
		proc *= GetDamageCustomProcCoefficient(damageCustom);
		if (validWeapon)
		{
			proc *= GetWeaponProcCoefficient(weapon);
			if (victimIsClient)
			{
				if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 173) // Vita-Saw
				{
					TF2_AddCondition(victim, TFCond_Milked, 5.0, attacker);
				}
				else if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 413) // Solemn Vow
				{
					TF2_AddCondition(victim, TFCond_Jarated, 5.0);
				}
			}
		}
		
		if (inflictorIsBuilding)
		{
			proc *= 0.5;
		}
		else if (inflictor > 0)
		{
			if (StrContains(inflictorClassname, "tf_projectile") == 0)
			{
				if (victimIsClient && IsPlayerSurvivor(victim) && HasEntProp(inflictor, Prop_Send, "m_iDeflected") && GetEntProp(inflictor, Prop_Send, "m_iDeflected"))
				{
					damage = fmin(damage, float(RF2_GetCalculatedMaxHealth(victim))*0.5);
				}
				
				if (strcmp2(inflictorClassname, "tf_projectile_rocket") || strcmp2(inflictorClassname, "tf_projectile_energy_ball") 
					|| strcmp2(inflictorClassname, "tf_projectile_sentryrocket"))
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
			}
			else if (strcmp2(inflictorClassname, "entity_medigun_shield"))
			{
				proc *= 0.02; // This thing does damage every damn tick
			}
		}
		
		bool afterburn;
		switch (damageCustom)
		{
			case TF_CUSTOM_BLEEDING:
			{
				proc *= 0.0;
				if (!selfDamage)
				{
					float bonus = 1.0;
					bonus += CalcItemMod(attacker, Item_Antlers, 2);
					bonus += CalcItemMod(attacker, ItemSniper_Bloodhound, 3);
					bonus += CalcItemMod(attacker, Item_Executioner, 4);
					damage *= bonus;
				}
			}
			
			case TF_CUSTOM_BURNING, TF_CUSTOM_BURNING_FLARE, TF_CUSTOM_BURNING_ARROW, TF_CUSTOM_DRAGONS_FURY_BONUS_BURNING:
			{
				afterburn = true;
				proc *= 0.0;
			}
			
			case TF_CUSTOM_PENETRATE_ALL_PLAYERS, TF_CUSTOM_PENETRATE_HEADSHOT:
			{
				if (PlayerHasItem(attacker, Item_MaxHead))
				{
					damage *= 1.0 + CalcItemMod(attacker, Item_MaxHead, 1);
				}
			}
			
			case TF_CUSTOM_STICKBOMB_EXPLOSION:
			{
				if (IsPlayerSurvivor(attacker) && !selfDamage)
				{
					damage *= 5.0;
				}
			}
		}
		
		// So here's an explanation for this. For a very long time, I did not realize
		// that buildings don't call OnTakeDamageAlive when they take damage. So as a result,
		// buildings went for a very long time without being affected by ANY damage modifications.
		// It's fixed now, but to avoid severely disrupting Engineer's balancing,
		// RED Team buildings are not affected by enemy damage multipliers.
		if (!victimIsBuilding || GetEntProp(victim, Prop_Data, "m_iTeamNum") == TEAM_ENEMY)
		{
			damage *= GetPlayerDamageMult(attacker);
		}
		
		if (!selfDamage && inflictor > 0 && g_bFiredWhileRocketJumping[inflictor] 
			&& PlayerHasItem(attacker, ItemSoldier_Compatriot) && CanUseCollectorItem(attacker, ItemSoldier_Compatriot))
		{
			damage *= 1.0 + CalcItemMod(attacker, ItemSoldier_Compatriot, 0);
		}
		
		int procItem = GetEntItemProc(attacker);
		if (procItem > Item_Null)
		{
			proc *= GetItemProcCoeff(procItem);
		}
		else if (inflictor > 0)
		{
			procItem = GetEntItemProc(inflictor);
		}
		
		if (inflictor > 0 && GetEntItemProc(inflictor) > Item_Null && GetEntItemProc(inflictor) <= MAX_ITEMS)
		{
			proc *= GetItemProcCoeff(GetEntItemProc(inflictor));
		}
		
		if (PlayerHasItem(attacker, ItemPyro_LastBreath) && CanUseCollectorItem(attacker, ItemPyro_LastBreath))
		{
			if (victimIsClient && !afterburn && (damageType & DMG_MELEE || validWeapon && GetPlayerWeaponSlot(attacker, WeaponSlot_Secondary) == weapon)
				&& (TF2_IsPlayerInCondition(victim, TFCond_OnFire) || TF2_IsPlayerInCondition(victim, TFCond_BurningPyro)))
			{
				TF2_AddCondition(victim, TFCond_MarkedForDeathSilent, CalcItemMod(attacker, ItemPyro_LastBreath, 0), attacker);
			}
		}
		
		if (inflictorIsBuilding)
		{
			if (PlayerHasItem(attacker, ItemEngi_BrainiacHairpiece) && CanUseCollectorItem(attacker, ItemEngi_BrainiacHairpiece))
			{
				if (g_flSentryNextLaserTime[inflictor] <= GetTickedTime() && !IsSentryDisposable(inflictor))
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
			if (selfDamage && IsBoss(victim) && !Enemy(victim).AllowSelfDamage)
			{
				// bosses normally don't do damage to themselves
				damage = 0.0;
				return Plugin_Changed;
			}
			
			// backstabs do set damage against survivors and bosses
			if (damageCustom == TF_CUSTOM_BACKSTAB)
			{
				if (IsPlayerMinion(attacker))
				{
					damage = 150.0 * GetEnemyDamageMult();
				}
				else if (IsBoss(victim))
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
					if (IsFakeClient(victim))
					{
						TFBot(victim).RealizeSpy(attacker);
					}
				}
				else if (IsPlayerSurvivor(victim))
				{
					damage = float(RF2_GetCalculatedMaxHealth(victim)) * 0.35;
				}
			}
			else if (StrContains(inflictorClassname, "tf_projectile_rocket") != -1
				|| strcmp2(inflictorClassname, "tf_projectile_energy_ball"))
			{
				if (PlayerHasItem(attacker, ItemSoldier_WarPig) && CanUseCollectorItem(attacker, ItemSoldier_WarPig))
				{
					damage *= 1.0 + CalcItemMod(attacker, ItemSoldier_WarPig, 1);
				}
			}
		}
		
		if (!selfDamage && !invuln) // General damage modifications will be done here
		{
			if (PlayerHasItem(attacker, Item_PointAndShoot))
			{
				int maxStacks = CalcItemModInt(attacker, Item_PointAndShoot, 0);
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
				
				if (PlayerHasItem(attacker, ItemSoldier_HawkWarrior) && CanUseCollectorItem(attacker, ItemSoldier_HawkWarrior))
				{
					if (TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping))
					{
						damage *= 1.0 + CalcItemMod(attacker, ItemSoldier_HawkWarrior, 0);
					}
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
		
		if (victimIsNpc)
		{
			static char victimClassname[64];
			GetEntityClassname(victim, victimClassname, sizeof(victimClassname));
			bool halloweenNpc = strcmp2(victimClassname, "headless_hatman") || strcmp2(victimClassname, "eyeball_boss") || strcmp2(victimClassname, "tf_zombie");
			if (halloweenNpc && !(damageType & DMG_CRIT) && !validWeapon)
			{
				// Halloween NPCs don't fire TF2_OnTakeDamageModifyRules()
				int attackerProc = GetLastEntItemProc(attacker);
				bool canCrit = attackerProc != ItemSniper_HolyHunter && !(StrContains(inflictorClassname, "tf_proj") != -1 && HasEntProp(inflictor, Prop_Send, "m_bCritical"));
				if (canCrit && RollAttackCrit(attacker))
				{
					damageType |= DMG_CRIT;
				}
			}
			
			bool skeleton = IsSkeleton(victim);
			if (skeleton && validWeapon && GetPlayerWeaponSlot(attacker, WeaponSlot_Primary) == weapon && TF2Attrib_HookValueInt(0, "mod use metal ammo type", weapon) > 0)
			{
				// Skeletons don't give widowmaker ammo by default
				GivePlayerAmmo(attacker, RoundToFloor(damage), TFAmmoType_Metal, true);
			}
			
			if (halloweenNpc && skeleton && damageType & DMG_CRIT)
			{
				// Skeletons normally don't take crit damage
				damage *= 3.0;
			}
		}
	}
	else if (attackerIsNpc)
	{
		if (strcmp2(inflictorClassname, "headless_hatman")) // this guy does 80% of victim HP by default, that is a big nono
		{
			damage = 250.0 * GetEnemyDamageMult();
			if (victimIsClient && IsPlayerSurvivor(victim))
			{
				damage *= 0.75;
			}
		}
		else
		{
			// Monoculus insta-kills players who touch his portal when he is spawning, prevent this
			bool monoculus = strcmp2(inflictorClassname, "eyeball_boss");
			if (monoculus && damageCustom == TF_CUSTOM_PLASMA)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
			
			damage *= GetEnemyDamageMult();
			if (monoculus && victimIsClient && IsPlayerSurvivor(victim))
			{
				damage *= 0.75;
			}
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
		
		if (PlayerHasItem(victim, ItemHeavy_Pugilist) && CanUseCollectorItem(victim, ItemHeavy_Pugilist))
		{
			// Resist while spun up
			if (TF2_IsPlayerInCondition(victim, TFCond_Slowed))
			{
				damage *= CalcItemMod_HyperbolicInverted(victim, ItemHeavy_Pugilist, 0);
			}
		}
		
		if (PlayerHasItem(victim, Item_SpiralSallet) && damage > 0.0)
		{
			damage = fmax(damage-CalcItemMod(victim, Item_SpiralSallet, 0), 1.0);
		}
	}
	
	// Self damage is capped at 20% max health
	if (victimIsClient && selfDamage && validWeapon && IsPlayerSurvivor(victim))
	{
		damage = fmin(damage, float(RF2_GetCalculatedMaxHealth(victim))*0.2);
	}
	
	g_flDamageProc = proc; // carry over
	damage = fmin(damage, 32767.0); // Damage in TF2 overflows after this value (16 bit)
	return damage != originalDamage || originalDamageType != damageType ? Plugin_Changed : Plugin_Continue;
}

public void Hook_OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damageType, int weapon,
const float damageForce[3], const float damagePosition[3], int damageCustom)
{
	bool attackerIsClient = IsValidClient(attacker);
	bool victimIsClient = IsValidClient(victim);
	bool invuln = victimIsClient && IsInvuln(victim);
	bool validWeapon = weapon > 0 && !IsCombatChar(weapon); // Apparently the weapon can be the attacker??
	bool selfDamage = victim == attacker;
	float proc = g_flDamageProc;
	
	if (victimIsClient)
	{
		if (CanPlayerRegen(victim) && damage > 0.0)
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
		
		if (attackerIsClient && PlayerHasItem(attacker, Item_Antlers) 
			&& damageCustom != TF_CUSTOM_BLEEDING && attacker != victim && inflictor != victim)
		{
			float chance = GetItemMod(Item_Antlers, 0) * proc;
			if (RandChanceFloatEx(attacker, 0.001, 1.0, chance))
			{
				TF2_MakeBleed(victim, attacker, GetItemMod(Item_Antlers, 1));
			}
		}
	}
	else if (IsTank(victim))
	{
		if (IsValidClient(attacker) && GetEntProp(victim, Prop_Data, "m_iHealth") <= 0)
		{
			TriggerAchievement(attacker, ACHIEVEMENT_TANKBUSTER);
		}
	}
	else if (IsSkeleton(victim))
	{
		Event event = CreateEvent("npc_hurt", true);
		if (event)
		{
			int health = GetEntProp(victim, Prop_Data, "m_iHealth");
			event.SetInt("entindex", victim);
			event.SetInt("health", health > 0 ? health : 0);
			event.SetInt("damageamount", RoundToFloor(damage));
			event.SetBool("crit", (damageType & DMG_CRIT) ? true : false);
			if (attacker > 0 && attacker <= MaxClients)
			{
				event.SetInt("attacker_player", GetClientUserId(attacker));
				event.SetInt("weaponid", 0);
			}
			else
			{
				event.SetInt("attacker_player", 0);
				event.SetInt("weaponid", 0);
			}
			
			event.Fire();
		}
	}
	
	if (attackerIsClient)
	{
		int procItem = GetEntItemProc(attacker);
		if (procItem == Item_Null && inflictor > 0)
			procItem = GetEntItemProc(inflictor);
		
		SetEntItemProc(attacker, Item_Null);
		g_iEntLastHitItemProc[victim] = procItem;
		
		if (validWeapon)
		{
			static char wepClassname[64];
			GetEntityClassname(weapon, wepClassname, sizeof(wepClassname));
			if (strcmp2(wepClassname, "tf_weapon_rocketlauncher_fireball") && damageCustom == TF_CUSTOM_DRAGONS_FURY_IGNITE)
			{
				float mult = GetPlayerFireRateMod(attacker, weapon)*1.5;
				SetEntPropFloat(weapon, Prop_Send, "m_flRechargeScale", mult);
				if (0.8 / mult <= GetTickInterval())
				{
					TriggerAchievement(attacker, ACHIEVEMENT_FIRERATECAP);
				}
			}
		}
		
		if (!selfDamage && !invuln)
		{
			if (PlayerHasItem(attacker, Item_Law) && inflictor > 0 && procItem != Item_Law && !g_bPlayerLawCooldown[attacker])
			{
				float random = GetItemMod(Item_Law, 0);
				random *= proc;
				
				if (RandChanceFloatEx(attacker, 0.001, 1.0, random))
				{
					const float rocketSpeed = 1200.0;
					float angles[3], pos[3], enemyPos[3];
					GetEntPos(attacker, pos);
					GetEntPos(victim, enemyPos);
					pos[2] += 30.0;
					enemyPos[2] += 30.0;
					GetVectorAnglesTwoPoints(pos, enemyPos, angles);
					float dmg = GetItemMod(Item_Law, 1) + CalcItemMod(attacker, Item_Law, 2, -1);
					int rocket = ShootProjectile(attacker, "tf_projectile_sentryrocket", pos, angles, rocketSpeed, dmg);
					SetShouldDamageOwner(rocket, false);
					SetEntItemProc(rocket, Item_Law);
					EmitSoundToAll(SND_LAW_FIRE, attacker, _, _, _, 0.6);
					g_bPlayerLawCooldown[attacker] = true;
					CreateTimer(0.4, Timer_LawCooldown, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			
			if (PlayerHasItem(attacker, Item_HorrificHeadsplitter) && damageType & DMG_MELEE)
			{
				HealPlayer(attacker, CalcItemModInt(attacker, Item_HorrificHeadsplitter, 0), false);
				g_bMeleeMiss[attacker] = false;
			}
			
			if (PlayerHasItem(attacker, Item_RoBro) && procItem != Item_RoBro)
			{
				float chance = GetItemMod(Item_RoBro, 0) * proc;
				if (RandChanceFloatEx(attacker, 0.001, 100.0, chance))
				{
					int limit = GetItemModInt(Item_RoBro, 1) + CalcItemModInt(attacker, Item_RoBro, 6);
					limit = imin(limit, GetItemModInt(Item_RoBro, 5));
					float range = GetItemMod(Item_RoBro, 2) + CalcItemMod(attacker, Item_RoBro, 3, -1);
					float dmg = GetItemMod(Item_RoBro, 4);
					ArrayList hitEnemies = new ArrayList();
					int lastHitEnemy = victim; // use victim as a starting point
					int team = GetClientTeam(attacker);
					bool foundEnemy = true;
					int entity = INVALID_ENT;
					int closestEnemy = INVALID_ENT;
					float closestRange, dist;
					float pos1[3], pos2[3];
					while (foundEnemy)
					{
						entity = INVALID_ENT;
						closestEnemy = INVALID_ENT;
						closestRange = range;
						while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT)
						{
							if (entity == victim || !IsCombatChar(entity) || hitEnemies.FindValue(entity) != INVALID_ENT)
								continue;
							
							if (GetEntProp(entity, Prop_Data, "m_iTeamNum") == team)
								continue;
							
							if (IsValidClient(entity) && !IsPlayerAlive(entity))
								continue;
							
							dist = DistBetween(lastHitEnemy, entity);
							if (dist <= closestRange && IsLOSClear(lastHitEnemy, entity))
							{
								closestEnemy = entity;
								closestRange = dist;
							}
						}
						
						foundEnemy = (closestEnemy != INVALID_ENT);
						if (foundEnemy)
						{
							EmitGameSoundToAll("Weapon_BarretsArm.Zap", closestEnemy);
							CBaseEntity(lastHitEnemy).WorldSpaceCenter(pos1);
							CBaseEntity(closestEnemy).WorldSpaceCenter(pos2);
							TE_SetupBeamPoints(pos1, pos2, g_iBeamModel, 0, 0, 0, 0.5, 8.0, 8.0, 0, 10.0, {100, 100, 255, 200}, 20);
							TE_SendToAll();
							
							RF_TakeDamage(closestEnemy, attacker, attacker, dmg, DMG_SHOCK|DMG_PREVENT_PHYSICS_FORCE, Item_RoBro);
							hitEnemies.Push(closestEnemy);
							lastHitEnemy = closestEnemy;
							if (hitEnemies.Length-1 >= limit)
							{
								break;
							}
						}
					}
					
					delete hitEnemies;
				}
			}
			
			if (IsPlayerSurvivor(attacker))
			{
				if (damage >= 10000.0)
				{
					TriggerAchievement(attacker, ACHIEVEMENT_BIGDAMAGE);
				}
				
				if (damage >= 32767.0)
				{
					TriggerAchievement(attacker, ACHIEVEMENT_DAMAGECAP);
				}
			}
		}
	}
}

// NOTE: Buildings don't call this when they take damage, use the other damage hooks instead.
public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon,
float damageForce[3], float damagePosition[3], int damageCustom, CritType &critType)
{
	if (!RF2_IsEnabled() || !g_bRoundActive)
		return Plugin_Continue;
	
	CritType originalCritType = critType;
	float proc = g_flDamageProc;
	float originalDamage = damage;
	bool validWeapon = weapon > 0 && !IsCombatChar(weapon); // Apparently the weapon can be the attacker??
	if (IsValidClient(attacker) && attacker != victim && IsValidEntity2(inflictor))
	{
		bool rolledCrit;
		int attackerProc = GetLastEntItemProc(attacker);
		int inflictorProc = GetEntItemProc(inflictor);
		static char classname[128];
		GetEntityClassname(inflictor, classname, sizeof(classname));
		bool canCrit = attackerProc != ItemSniper_HolyHunter && !(StrContains(classname, "tf_proj") != -1 && HasEntProp(inflictor, Prop_Send, "m_bCritical"));
		
		// Check for full crits for any damage that isn't against a building and isn't from a weapon.
		if (!validWeapon && canCrit && !IsBuilding(victim))
		{
			if (critType != CritType_Crit || critType == CritType_MiniCrit && !PlayerHasItem(attacker, Item_Executioner))
			{
				rolledCrit = RollAttackCrit(attacker);
				if (rolledCrit)
				{
					critType = CritType_Crit;
				}
			}
		}
		
		if (validWeapon)
		{
			if (critType == CritType_Crit && !rolledCrit && IsValidClient(attacker) && IsPlayerSurvivor(attacker))
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
		
		if (inflictorProc == ItemStrange_HandsomeDevil && critType == CritType_MiniCrit)
		{
			critType = CritType_Crit;
		}
		
		// Executioner converts minicrits to full crits
		if (canCrit && PlayerHasItem(attacker, Item_Executioner) && critType == CritType_MiniCrit)
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
					}
					
					// Executioner has a chance to cause bleeding on crit damage
					if (IsValidClient(victim) && PlayerHasItem(attacker, Item_Executioner)
						&& damageCustom != TF_CUSTOM_BLEEDING && !TF2_IsPlayerInCondition(victim, TFCond_Bonked) && !g_bExecutionerBleedCooldown[attacker])
					{
						if (RandChanceFloatEx(attacker, 0.001, 1.0, GetItemMod(Item_Executioner, 0) * proc))
						{
							TF2_MakeBleed(victim, attacker, GetItemMod(Item_Executioner, 1));
							g_bExecutionerBleedCooldown[attacker] = true;
							CreateTimer(0.2, Timer_ExecutionerBleedCooldown, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
		}
	}
	
	// Changing the crit type here will not change the damage, so we have to modify the damage ourselves.
	// An issue will also occur when changing the crit type here where it plays the wrong effect or no effect at all.
	// We can only fake a missing crit effect; an incorrect crit effect (such as minicrit -> crit spawning the minicrit effect) cannot be fixed.
	bool bonked = IsValidClient(victim) && TF2_IsPlayerInCondition(victim, TFCond_Bonked);
	if (originalCritType != critType)
	{
		switch (originalCritType)
		{
			case CritType_None:
			{
				damageType |= DMG_CRIT;

				if (critType == CritType_Crit)
				{
					if (!bonked)
					{
						TE_TFParticle("crit_text", damagePosition, victim);
						EmitGameSoundToClient(attacker, GSND_CRIT);
					}

					damage *= 3.0;
				}
				else // Mini crit
				{
					if (!bonked)
					{
						TE_TFParticle("minicrit_text", damagePosition, victim);
						EmitGameSoundToClient(attacker, GSND_MINICRIT);
					}

					damage *= 1.35;
				}
			}

			case CritType_MiniCrit:
			{
				if (critType == CritType_Crit)
				{
					if (!bonked)
					{
						TE_TFParticle("crit_text", damagePosition, victim);
						EmitGameSoundToClient(attacker, GSND_CRIT);
					}

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
					if (!bonked)
					{
						TE_TFParticle("minicrit_text", damagePosition, victim);
						EmitGameSoundToClient(attacker, GSND_MINICRIT);
					}
					
					damage /= 3.0;
					damage *= 1.35;
				}
				else // Non crit
				{
					damage /= 3.0;
				}
			}
		}
	}
	
	damage = fmin(damage, 32767.0); // Damage in TF2 overflows after this value (16 bit)
	return damage != originalDamage ? Plugin_Changed : Plugin_Continue;
}

public Action Hook_BuildingOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
		float damageForce[3], float damagePosition[3], int damagecustom)
{
	return Hook_OnTakeDamageAlive(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
}

public void Hook_BuildingOnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon,
		const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	Hook_OnTakeDamageAlivePost(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
}

public Action Timer_ExecutionerBleedCooldown(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return Plugin_Continue;

	g_bExecutionerBleedCooldown[client] = false;
	return Plugin_Continue;
}

public void Hook_WeaponSwitchPost(int client, int weapon)
{
	if (IsFakeClient(client))
	{
		TFBot(client).RemoveButtonFlag(IN_RELOAD);
	}
	else if (PlayerHasItem(client, ItemEngi_HeadOfDefense) && CanUseCollectorItem(client, ItemEngi_HeadOfDefense))
	{
		if (!g_bPlayerExtraSentryHint[client] && GetPlayerWeaponSlot(client, WeaponSlot_PDA2) == weapon)
		{
			PrintHintText(client, "%t", "ExtraSentryHint");
			g_bPlayerExtraSentryHint[client] = true;
		}
		
		int builderWep = GetPlayerWeaponSlot(client, WeaponSlot_Builder);
		if (builderWep != weapon && GetPlayerBuildingCount(client, TFObject_Sentry) >= CalcItemModInt(client, ItemEngi_HeadOfDefense, 0) + 1)
		{
			SetSentryBuildState(client, false);
		}
		else if (GetPlayerWeaponSlot(client, WeaponSlot_PDA) == weapon)
		{
			SetSentryBuildState(client, true);
		}
		else if (builderWep != weapon)
		{
			SetSentryBuildState(client, false);
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
		TriggerAchievement(client, ACHIEVEMENT_POCKETMEDIC);
	}
}

public void RF_ClearViewPunch(int client)
{
	if (!IsClientInGame(client))
		return;
	
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

public Action Timer_LawCooldown(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return Plugin_Continue;

	g_bPlayerLawCooldown[client] = false;
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3])
{
	if (!RF2_IsEnabled())
		return Plugin_Continue;
	
	bool bot = IsFakeClient(client);
	if (!bot)
	{
		if (buttons && !IsSingleplayer(false))
		{
			ResetAFKTime(client);
		}
	}
	
	if (g_bWaitingForPlayers || !IsPlayerAlive(client))
		return Plugin_Continue;

	Action action = Plugin_Continue;
	if (bot)
	{
		action = TFBot_OnPlayerRunCmd(client, buttons, impulse);
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
	bool allowPress;
	if (GetCookieBool(client, g_coSwapStrangeButton))
	{
		allowPress = buttons & IN_ATTACK3 && GetPlayerWeaponSlot(client, WeaponSlot_PDA2) != GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	}
	else if (buttons & IN_RELOAD)
	{
		allowPress = true;
	}
	
	if (!bot && allowPress)
	{
		if (!reloadPressed[client])
		{
			// Don't conflict with the Vaccinator or Eureka Effect. Player must be pressing IN_SCORE when holding these weapons.
			bool tabRequired;
			int initial;

			if (TF2_GetPlayerClass(client) == TFClass_Medic)
			{
				int medigun = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
				if (medigun != INVALID_ENT && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == medigun)
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
				if (wrench != INVALID_ENT && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == wrench)
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
				if (g_hPlayerExtraSentryList[client].Length > 0 && GetPlayerWeaponSlot(client, WeaponSlot_PDA2) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
				{
					int entity = g_hPlayerExtraSentryList[client].Get(0);
					if (IsValidEntity2(entity))
					{
						SetVariantInt(GetEntProp(entity, Prop_Send, "m_iHealth")+9999);
						AcceptEntityInput(entity, "RemoveHealth");
					}
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
	if (g_iPlayerFootstepType[client] == FootstepType_GiantRobot && GetTickedTime() >= nextFootstepTime[client] 
		&& !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !IsPlayerStunned(client))
	{
		if ((buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT) && GetEntityFlags(client) & FL_ONGROUND)
		{
			float fwdVel[3], sideVel[3], vel[3];
			GetAngleVectors(angles, fwdVel, NULL_VECTOR, NULL_VECTOR);
			GetAngleVectors(angles, NULL_VECTOR, sideVel, NULL_VECTOR);
			NormalizeVector(fwdVel, fwdVel);
			NormalizeVector(sideVel, sideVel);
			CopyVectors(velocity, vel);
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
					GetClassString(class, classString, sizeof(classString));

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
				
				PrecacheSound(sample);
				EmitSoundToAll(sample, client);
				float duration = g_flPlayerGiantFootstepInterval[client] * (RF2_GetCalculatedSpeed(client) / RF2_GetBaseSpeed(client));
				nextFootstepTime[client] = GetTickedTime() + duration;
			}
		}
	}
	
	return action;
}

public Action PlayerSoundHook(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& client, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	if (!RF2_IsEnabled() || g_bWaitingForPlayers || !IsValidClient(client))
		return Plugin_Continue;
	
	if (GetClientTeam(client) == TEAM_ENEMY || IsPlayerMinion(client) || TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		Action action = Plugin_Continue;
		int voiceType = g_iPlayerVoiceType[client];
		int footstepType = g_iPlayerFootstepType[client];
		
		if (TF2_IsPlayerInCondition(client, TFCond_Disguised) && !IsPlayerMinion(client))
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
		if (TF2_IsPlayerInCondition(client, TFCond_Disguised) && !IsPlayerMinion(client))
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
				GetClassString(class, classString, sizeof(classString), true);
				
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
				PrecacheSound2(sample);
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
						
					PrecacheSound2(sample);
				}

				// Only works this way for some reason
				if (TF2_IsPlayerInCondition(client, TFCond_Disguised) && !IsPlayerMinion(client))
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
		if (TF2_IsPlayerInCondition(client, TFCond_Disguised) && !IsPlayerMinion(client))
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
