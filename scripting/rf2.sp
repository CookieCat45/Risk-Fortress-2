#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#include <tf2_stocks>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

#if defined DEVONLY
#define PLUGIN_VERSION "1.6.6-DEVONLY"
#else
#define PLUGIN_VERSION "1.6.6"
#endif

#include <rf2>
#include "rf2/defs.sp"
#include <cbasenpc>
#include <cbasenpc/tf/nav>
#include <tf2attributes>
#include <tf2items>
#include <tf_ontakedamage>

#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#define REQUIRE_PLUGIN

public Plugin myinfo =
{
	name		=	"Risk Fortress 2",
	author		=	"CookieCat",
	description	=	"TF2 endless roguelike adventure game mode inspired by and based on Risk of Rain 2.",
	version		=	PLUGIN_VERSION,
	url			=	"",
};

// General
bool g_bPluginEnabled;
bool g_bStatsLoaded;
bool g_bLateLoad;
bool g_bGameInitialized;
bool g_bWaitingForPlayers;
bool g_bRoundActive;
bool g_bGracePeriod;
bool g_bGameOver;
bool g_bGameWon;
bool g_bMapChanging;
bool g_bConVarsModified;
bool g_bPluginReloading;
bool g_bTankBossMode;
bool g_bRaidBossMode;
bool g_bGoombaAvailable;
bool g_bRoundEnding;
bool g_bInUnderworld;
bool g_bInFinalMap;
bool g_bScavengerLordDroppedItems;
bool g_bChangeDetected;
bool g_bServerRestarting;
bool g_bForceRifleSound;
bool g_bMapRunning;
bool g_bRingCashBonus;
bool g_bEnteringUnderworld;
bool g_bEnteringFinalArea;
bool g_bItemSharingDisabledForMap;
//bool g_bCustomEventsAvailable;
int g_iFileTime;
float g_flWaitRestartTime;
float g_flNextAutoReloadCheckTime;
float g_flAutoReloadTime;
float g_flCurrentCostMult;
float g_flHeadshotDamage;
char g_szForcedMap[256];
char g_szMapForcerName[MAX_NAME_LENGTH];
char g_szCurrentEnemyGroup[64];
Address g_aEngineServer;
Address g_aGameEventManager;
ConVar g_cvSvCheats;

// Map settings
bool g_bDisableEurekaTeleport;
bool g_bDisableItemDropping;
float g_flGracePeriodTime = 30.0;
float g_flStartMoneyMultiplier = 1.0;
float g_flBossSpawnChanceBonus;
float g_flMaxSpawnWaveTime;
float g_flLoopMusicAt[MAXPLAYERS] = {-1.0, ...};
float g_flStageBGMDuration;
float g_flBossBGMDuration;

int g_iTotalEnemiesKilled;
int g_iTotalBossesKilled;
int g_iTotalTanksKilled;
int g_iTotalItemsFound;
int g_iTanksKilledObjective;
int g_iTankKillRequirement = 1;
int g_iTanksSpawned;
int g_iMetalItemsDropped[MAXPLAYERS];
int g_iWorldCenterEntity = INVALID_ENT;
int g_iTeleporterEntRef = INVALID_ENT;
int g_iRF2GameRulesEntity = INVALID_ENT;

// Difficulty
float g_flSecondsPassed;
float g_flDifficultyCoeff;
float g_flRoundStartSeconds;
bool g_bTeleporterEventReminder;

int g_iMinutesPassed;
int g_iDifficultyLevel = DIFFICULTY_SCRAP;
int g_iSubDifficulty = SubDifficulty_Easy;
int g_iStagesCompleted;
int g_iCurrentStage = 1;
int g_iLoopCount;
int g_iEnemyLevel = 1;
int g_iRespawnWavesCompleted;

// HUD
#define MAIN_HUD_Y -1.4
Handle g_hMainHudSync;
Handle g_hObjectiveHudSync;
Handle g_hMiscHudSync;
int g_iMainHudR = 100;
int g_iMainHudG = 255;
int g_iMainHudB = 100;
char g_szHudDifficulty[128] = "Difficulty: Easy";
char g_szObjectiveHud[MAXPLAYERS][128];

// g_iStagesCompleted+1, g_iMinutesPassed, hudSeconds, g_iEnemyLevel, g_iPlayerLevel[i], g_flPlayerXP[i],
// g_flPlayerNextLevelXP[i], cashString, g_szHudDifficulty, strangeItemInfo, miscText
char g_szSurvivorHudText[2048] = "\n\nStage %i (%s) | %02d:%02d\nEnemy Level: %i | Your Level: %i\n%.0f/%.0f XP | Cash: %s\n%s\n%s";

// g_iStagesCompleted+1, g_iMinutesPassed, hudSeconds, g_iEnemyLevel, g_szHudDifficulty, strangeItemInfo
char g_szEnemyHudText[1024] = "\n\nStage %i (%s) | %02d:%02d\nEnemy Level: %i\n%s\n%s";

// Players
bool g_bPlayerViewingItemMenu[MAXPLAYERS];
bool g_bPlayerIsTeleporterBoss[MAXPLAYERS];
bool g_bPlayerIsAFK[MAXPLAYERS];
bool g_bPlayerExtraSentryHint[MAXPLAYERS];
bool g_bPlayerInSpawnQueue[MAXPLAYERS];
bool g_bPlayerHasVampireSapper[MAXPLAYERS];
bool g_bPlayerEquipmentCooldownActive[MAXPLAYERS];
bool g_bPlayerTookCollectorItem[MAXPLAYERS];
bool g_bPlayerSpawnedByTeleporter[MAXPLAYERS];
bool g_bPlayerHealBurstCooldown[MAXPLAYERS];
bool g_bPlayerTimingOut[MAXPLAYERS];
bool g_bPlayerMeleeMiss[MAXPLAYERS];
bool g_bPlayerIsMinion[MAXPLAYERS];
bool g_bPlayerSpawningAsMinion[MAXPLAYERS];
bool g_bPlayerRifleAutoFire[MAXPLAYERS];
bool g_bPlayerToggledAutoFire[MAXPLAYERS];
bool g_bPlayerOpenedHelpMenu[MAXPLAYERS];
bool g_bPlayerViewingItemDesc[MAXPLAYERS];
bool g_bPlayerReviveActivated[MAXPLAYERS];
bool g_bPlayerItemShareExcluded[MAXPLAYERS];
bool g_bPlayerHauntedKeyDrop[MAXPLAYERS];
bool g_bPlayerFullMinigunMoveSpeed[MAXPLAYERS];
bool g_bPlayerPermaDeathMark[MAXPLAYERS];
bool g_bPlayerIsDyingBoss[MAXPLAYERS];
bool g_bPlayerPressedCanteenButton[MAXPLAYERS];
bool g_bPlayerYetiSmash[MAXPLAYERS];
bool g_bPlayerHeadshotBleeding[MAXPLAYERS];

float g_flPlayerXP[MAXPLAYERS];
float g_flPlayerNextLevelXP[MAXPLAYERS] = {100.0, ...};
float g_flPlayerCash[MAXPLAYERS];
float g_flPlayerMaxSpeed[MAXPLAYERS] = {300.0, ...};
float g_flPlayerCalculatedMaxSpeed[MAXPLAYERS] = {300.0, ...};
float g_flPlayerHealthRegenTime[MAXPLAYERS];
float g_flPlayerNextMetalRegen[MAXPLAYERS];
float g_flPlayerEquipmentItemCooldown[MAXPLAYERS];
float g_flPlayerGiantFootstepInterval[MAXPLAYERS] = {0.5, ...};
float g_flPlayerAFKTime[MAXPLAYERS];
float g_flPlayerVampireSapperCooldown[MAXPLAYERS];
float g_flPlayerVampireSapperDamage[MAXPLAYERS];
float g_flPlayerVampireSapperDuration[MAXPLAYERS];
float g_flPlayerReloadBuffDuration[MAXPLAYERS];
float g_flPlayerNextDemoSpellTime[MAXPLAYERS];
float g_flPlayerNextFireSpellTime[MAXPLAYERS];
float g_flPlayerRegenBuffTime[MAXPLAYERS];
float g_flPlayerKnifeStunCooldown[MAXPLAYERS];
float g_flPlayerRifleHeadshotBonusTime[MAXPLAYERS];
float g_flPlayerGravityJumpBonusTime[MAXPLAYERS];
float g_flPlayerTimeSinceLastPing[MAXPLAYERS];
float g_flPlayerTimeSinceLastItemPickup[MAXPLAYERS];
float g_flPlayerCaberRechargeAt[MAXPLAYERS];
float g_flPlayerHeavyArmorPoints[MAXPLAYERS] = {100.0, ...};
float g_flPlayerShieldRegenTime[MAXPLAYERS];
float g_flPlayerRocketJumpTime[MAXPLAYERS];
float g_flPlayerLastTabPressTime[MAXPLAYERS];
float g_flPlayerHardHatLastResistTime[MAXPLAYERS];
float g_flPlayerLastBlockTime[MAXPLAYERS];
float g_flPlayerDelayedHealTime[MAXPLAYERS];
float g_flPlayerLifestealTime[MAXPLAYERS];
float g_flPlayerWarswornBuffTime[MAXPLAYERS];
float g_flPlayerMedicShieldNextUseTime[MAXPLAYERS];
float g_flPlayerNextParasiteHealTime[MAXPLAYERS];
float g_flPlayerNextExecutionerBleedTime[MAXPLAYERS];
float g_flPlayerNextLawFireTime[MAXPLAYERS];
float g_flPlayerWealthRingRadius[MAXPLAYERS];
float g_flPlayerJetpackEndTime[MAXPLAYERS];
float g_flBlockMedicCall[MAXPLAYERS];
float g_flBannerSwitchTime[MAXPLAYERS];

int g_iPlayerInventoryIndex[MAXPLAYERS] = {-1, ...};
int g_iPlayerLevel[MAXPLAYERS] = {1, ...};
int g_iPlayerBaseHealth[MAXPLAYERS] = {1, ...};
int g_iPlayerCalculatedMaxHealth[MAXPLAYERS] = {1, ...};
int g_iPlayerSurvivorIndex[MAXPLAYERS] = {-1, ...};
int g_iPlayerEquipmentItemCharges[MAXPLAYERS] = {1, ...};
int g_iPlayerEnemyType[MAXPLAYERS] = {-1, ...};
int g_iPlayerEnemySpawnType[MAXPLAYERS] = {-1, ...};
int g_iPlayerBossSpawnType[MAXPLAYERS] = {-1, ...};
int g_iPlayerVoiceType[MAXPLAYERS];
int g_iPlayerVoicePitch[MAXPLAYERS] = {SNDPITCH_NORMAL, ...};
int g_iPlayerFootstepType[MAXPLAYERS] = {FootstepType_Normal, ...};
int g_iPlayerFireRateStacks[MAXPLAYERS];
int g_iPlayerAirDashCounter[MAXPLAYERS];
int g_iPlayerLastAttackedTank[MAXPLAYERS] = {INVALID_ENT, ...};
int g_iPlayerItemsTaken[MAX_SURVIVORS];
int g_iPlayerItemLimit[MAX_SURVIVORS];
int g_iPlayerVampireSapperAttacker[MAXPLAYERS] = {INVALID_ENT, ...};
int g_iPlayerLastScrapMenuItem[MAXPLAYERS];
int g_iPlayerLastItemMenuItem[MAXPLAYERS];
int g_iPlayerLastDropMenuItem[MAXPLAYERS];
int g_iPlayerLastItemLogItem[MAXPLAYERS];
int g_iPlayerUnusualsUnboxed[MAXPLAYERS];
int g_iPlayerGoombaChain[MAXPLAYERS];
int g_iPlayerLastPingedEntity[MAXPLAYERS] = {INVALID_ENT, ...};
int g_iPlayerShieldHealth[MAXPLAYERS];
int g_iPlayerCollectorSwapCount[MAXPLAYERS];
int g_iPlayerPowerupBottle[MAXPLAYERS] = {INVALID_ENT, ...};
int g_iPlayerRollerMine[MAXPLAYERS] = {INVALID_ENT, ...};

char g_szPlayerOriginalName[MAXPLAYERS][MAX_NAME_LENGTH];
ArrayList g_hPlayerExtraSentryList[MAXPLAYERS];
StringMap g_hCrashedPlayerSteamIDs;
Handle g_hCrashedPlayerTimers[MAX_SURVIVORS];

// Entities
PathFollower g_iEntityPathFollower[MAX_EDICTS];
//TFClassType g_iDroppedWeaponClass[MAX_EDICTS] = {TFClass_Unknown, ...};
int g_iItemDamageProc[MAX_EDICTS];
int g_iLastItemDamageProc[MAX_EDICTS];
int g_iEntLastHitItemProc[MAX_EDICTS]; // Mainly for use in OnPlayerDeath
int g_iCashBombSize[MAX_EDICTS];

bool g_bDisposableSentry[MAX_EDICTS];
bool g_bDontDamageOwner[MAX_EDICTS];
bool g_bCashBomb[MAX_EDICTS];
bool g_bDontRemoveWearable[MAX_EDICTS];
bool g_bItemWearable[MAX_EDICTS];
bool g_bEntityGlowing[MAX_EDICTS];
float g_flBusterSpawnTime;
float g_flProjectileForcedDamage[MAX_EDICTS];
float g_flSentryNextLaserTime[MAX_EDICTS];
float g_flCashBombAmount[MAX_EDICTS];
float g_flCashValue[MAX_EDICTS];
float g_flTeleporterNextSpawnTime[MAX_EDICTS];
float g_flLastHalloweenBossAttackTime[MAX_EDICTS][MAXPLAYERS];

ArrayList g_hHHHTargets;
ArrayList g_hMonoculusTargets;
StringMap g_hEnemyTypeCooldowns;
StringMap g_hEnemyTypeNumSpawned;

// Timers
Handle g_hPlayerTimer;
Handle g_hHudTimer;
Handle g_hDifficultyTimer;
Handle g_hItemTimer;
Handle g_hEntityGlowResetTimer[MAX_EDICTS];

// Gamedata handles
Handle g_hSDKEquipWearable;
Handle g_hSDKDoQuickBuild;
Handle g_hSDKGetMaxHealth;
Handle g_hSDKIntersects;
Handle g_hSDKWeaponSwitch;
Handle g_hSDKRealizeSpy;
Handle g_hSDKSpawnZombie;
Handle g_hSDKTankSetStartNode;
Handle g_hSDKCreateDroppedWeapon;
Handle g_hSDKLoadEvents;
Handle g_hSDKRaiseFlag;
DynamicDetour g_hDetourHandleRageGain;
DynamicDetour g_hDetourApplyPunchImpulse;
DynamicDetour g_hDetourOverhealBonus;
DynamicDetour g_hDetourEyeFindVictim;
DynamicDetour g_hDetourEyePickSpot;
DynamicDetour g_hDetourHHHChaseable;
DynamicDetour g_hDetourOnWeaponFired;
DynamicDetour g_hDetourGCPreClientUpdate;
DynamicDetour g_hDetourFindMap;
DynamicDetour g_hDetourCreateEvent;
DynamicDetour g_hDetourWeaponPickup;
DynamicHook g_hHookTakeHealth;
DynamicHook g_hHookStartUpgrading;
DynamicHook g_hHookOnWrenchHit;
DynamicHook g_hHookVPhysicsCollision;
DynamicHook g_hHookRiflePostFrame;
DynamicHook g_hHookIsCombatItem;
DynamicHook g_hHookMeleeSmack;
DynamicHook g_hHookForceRespawn;
DynamicHook g_hHookCreateFakeClientEx;
DynamicHook g_hHookDedicatedServer;
DynamicHook g_hHookPassesFilterImpl;
DynamicHook g_hHookIsAbleToSee;
DynamicHook g_hHookPhysicsSolidMask;

// Forwards
GlobalForward g_fwTeleEventStart;
GlobalForward g_fwTeleEventEnd;
GlobalForward g_fwGracePeriodStart;
GlobalForward g_fwGracePeriodEnded;
GlobalForward g_fwOnTakeDamage;
GlobalForward g_fwOnCustomItemLoaded;
GlobalForward g_fwOnPlayerItemUpdate;
GlobalForward g_fwOnActivateStrange;
PrivateForward g_fwOnMapStart;

// ConVars
ConVar g_cvMaxHumanPlayers;
ConVar g_cvMaxSurvivors;
ConVar g_cvGameResetTime;
ConVar g_cvAlwaysSkipWait;
ConVar g_cvEnableAFKManager;
ConVar g_cvAFKOnlyKickSurvivors;
ConVar g_cvAFKManagerKickTime;
ConVar g_cvAFKKickAdmins;
ConVar g_cvBotsCanBeSurvivor;
ConVar g_cvBotWanderRecomputeDist;
ConVar g_cvBotWanderTime;
ConVar g_cvBotWanderMaxDist;
ConVar g_cvBotWanderMinDist;
ConVar g_cvSubDifficultyIncrement;
ConVar g_cvDifficultyScaleMultiplier;
ConVar g_cvAlwaysAllowTitaniumVoting;
ConVar g_cvMaxObjects;
ConVar g_cvCashBurnTime;
ConVar g_cvSurvivorHealthScale;
ConVar g_cvSurvivorDamageScale;
ConVar g_cvSurvivorBaseXpRequirement;
ConVar g_cvSurvivorXpRequirementScale;
ConVar g_cvSurvivorLagBehindThreshold;
ConVar g_cvSurvivorMaxExtraCrates;
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
ConVar g_cvEnemyPowerupLevel;
ConVar g_cvBossPowerupLevel;
ConVar g_cvPowerupLevelChanceMult;
ConVar g_cvPowerupRegenLevel;
ConVar g_cvPowerupHasteLevel;
ConVar g_cvPowerupVampireLevel;
ConVar g_cvPowerupResistLevel;
ConVar g_cvPowerupStrengthLevel;
ConVar g_cvBossStabDamageType;
ConVar g_cvBossStabDamagePercent;
ConVar g_cvBossStabDamageAmount;
ConVar g_cvTeleporterRadiusMultiplier;
ConVar g_cvObjectSpreadDistance;
ConVar g_cvObjectBaseCost;
ConVar g_cvObjectBaseCount;
ConVar g_cvBarrelSpawnCount;
ConVar g_cvExtraMiscObjects;
ConVar g_cvItemShareEnabled;
ConVar g_cvItemShareMaxTime;
ConVar g_cvTankBaseHealth;
ConVar g_cvTankHealthScale;
ConVar g_cvTankBaseSpeed;
ConVar g_cvTankSpeedBoost;
ConVar g_cvTankBoostHealth;
ConVar g_cvTankBoostDifficulty;
ConVar g_cvTankSpawnCap;
ConVar g_cvSurvivorQuickBuild;
ConVar g_cvEnemyQuickBuild;
ConVar g_cvMeleeCritChanceBonus;
ConVar g_cvEngiMetalRegenInterval;
ConVar g_cvEngiMetalRegenAmount;
ConVar g_cvHauntedKeyDropChanceMax;
ConVar g_cvAllowHumansInBlue;
ConVar g_cvTimeBeforeRestart;
ConVar g_cvHiddenServerStartTime;
ConVar g_cvWaitExtendTime;
ConVar g_cvItemShareDisableThreshold;
ConVar g_cvItemShareDisableLoopCount;
ConVar g_cvRequiredStagesForStatue;
ConVar g_cvEnableOneShotProtection;
ConVar g_cvOldGiantFootsteps;
ConVar g_cvPlayerAbsenceLimit;
ConVar g_cvMinStagesClearedToForfeit;
ConVar g_cvScavengerLordSpawnLevel;
ConVar g_cvScavengerLordMaxItems;
ConVar g_cvScavengerLordLevelItemRatio;
ConVar g_cvServerStarted;
ConVar g_cvStage1StartingMap;
ConVar g_cvAggressiveRestarting;
ConVar g_cvGamePlayedCount;
ConVar g_cvEnableGiantPainSounds;
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
Cookie g_coDisableItemCosmetics;
Cookie g_coEarnedAllAchievements;
Cookie g_coPingObjectsHint;
Cookie g_coAlwaysShowItemCounts;
Cookie g_coItemShareKarma;
Cookie g_coAltItemMenuButton;

// TFBots
TFBot g_TFBot[MAXPLAYERS];
ArrayList g_hTFBotEngineerBuildings[MAXPLAYERS];

public const char g_szTeddyBearSounds[][] =
{
	"rf2/sfx/bear1.wav",
	"rf2/sfx/bear2.wav",
	"rf2/sfx/bear3.wav",
};

#include "rf2/overrides.sp"
#include "rf2/vscript_funcs.sp"
#include "rf2/items.sp"
#include "rf2/survivors.sp"
#include "rf2/entityfactory.sp"
#include "rf2/enemies.sp"
#include "rf2/stages.sp"

#include "rf2/customents/gamerules.sp"
#include "rf2/customents/item_ent.sp"
#include "rf2/customents/healthtext.sp"
#include "rf2/customents/dispenser_shield.sp"
#include "rf2/customents/world_center.sp"
#include "rf2/customents/trigger_exit.sp"
#include "rf2/customents/tank_spawner.sp"
#include "rf2/customents/raid_boss_spawner.sp"
#include "rf2/customents/logic_bot_death.sp"

#include "rf2/customents/objects/object_base.sp"
#include "rf2/customents/objects/object_teleporter.sp"
#include "rf2/customents/objects/object_crate.sp"
#include "rf2/customents/objects/object_workbench.sp"
#include "rf2/customents/objects/object_scrapper.sp"
#include "rf2/customents/objects/object_gravestone.sp"
#include "rf2/customents/objects/object_altar.sp"
#include "rf2/customents/objects/object_pumpkin.sp"
#include "rf2/customents/objects/object_statue.sp"
#include "rf2/customents/objects/object_tree.sp"
#include "rf2/customents/objects/object_fountain.sp"
#include "rf2/customents/objects/object_barrel.sp"
#include "rf2/customents/objects/object_pedestal.sp"

#include "rf2/customents/projectiles/projectile_base.sp"
#include "rf2/customents/projectiles/projectile_shuriken.sp"
#include "rf2/customents/projectiles/projectile_bomb.sp"
#include "rf2/customents/projectiles/projectile_beam.sp"
#include "rf2/customents/projectiles/projectile_fireball.sp"
#include "rf2/customents/projectiles/projectile_kunai.sp"
#include "rf2/customents/projectiles/projectile_skull.sp"
#include "rf2/customents/projectiles/projectile_homingrocket.sp"
#include "rf2/customents/projectiles/projectile_shrapnel.sp"
#include "rf2/customents/customhitbox.sp"

#include "rf2/customents/filters/filter_minion.sp"

#include "rf2/cookies.sp"
#include "rf2/sql.sp"
#include "rf2/weapons.sp"
#include "rf2/general_funcs.sp"
#include "rf2/clients.sp"
#include "rf2/entities.sp"
#include "rf2/buildings.sp"
#include "rf2/natives_forwards.sp"
#include "rf2/commands_convars.sp"
#include "rf2/achievements.sp"
#include "rf2/npc/nav.sp"
#include "rf2/npc/tf_bot.sp"
#include "rf2/npc/npc_base.sp"
#include "rf2/npc/actions/baseattack.sp"
#include "rf2/npc/npc_tank_boss.sp"
#include "rf2/npc/npc_sentry_buster.sp"
#include "rf2/npc/npc_raidboss_galleom.sp"
#include "rf2/npc/npc_companion_base.sp"
#include "rf2/npc/npc_robot_butler.sp"
#include "rf2/npc/npc_false_providence.sp"
#include "rf2/customents/providence_shield_crystal.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		strcopy(error, err_max, "This plugin was developed for use with Team Fortress 2 only");
		return APLRes_Failure;
	}
	
	char altPluginName[64];
	#if defined DEVONLY
	altPluginName = "rf2.smx";
	#else
	altPluginName = "rf2_development.smx";
	#endif
	if (FindPluginByFile(altPluginName))
	{
		FormatEx(error, err_max, "A different version of the plugin is already running (%s)", altPluginName);
		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;
	g_bMapRunning = late;
	RegPluginLibrary("rf2");
	LoadNatives();
	LoadForwards();
	return APLRes_Success;
}

public void OnPluginStart()
{
	InstallEnts();
	LoadGameData();
	LoadCommandsAndCvars();
	BakeCookies();
	CreateSQL();
	LoadTranslations("common.phrases");
	LoadTranslations("rf2.phrases");
	LoadTranslations("rf2_achievements.phrases");
	g_hCrashedPlayerSteamIDs = new StringMap();
	g_hEnemyTypeCooldowns = new StringMap();
	g_hEnemyTypeNumSpawned = new StringMap();
	g_hHHHTargets = new ArrayList();
	g_hMonoculusTargets = new ArrayList();
	g_hCustomTracks = new ArrayList(PLATFORM_MAX_PATH);
	g_hCustomTracksDuration = new ArrayList();
	g_iFileTime = GetPluginModifiedTime();
	g_cvSvCheats = FindConVar("sv_cheats");
	if (g_cvHiddenServerStartTime.FloatValue == 0.0)
	{
		g_cvHiddenServerStartTime.FloatValue = GetEngineTime();
	}
	
	if (g_hDetourFindMap)
	{
		char dummy[256];
		FindMap("give_me_my_cvengineserver_pointer", dummy, 256);
	}
	
	if (g_hDetourCreateEvent)
	{
		CreateEvent("give_me_my_cgameeventmanager_pointer", true);
	}
}

public void OnPluginEnd()
{
	if (RF2_IsEnabled())
	{
		FindConVar("tf_bot_offline_practice").SetBool(false);
		StopMusicTrackAll();
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (IsValidClient(i))
			{
				SetClientName(i, g_szPlayerOriginalName[i]);
				StopLoopingSounds(i);
			}
		}
	}
	
	CleanPathFollowers();
}

void LoadGameData()
{
	GameData gamedata = new GameData("rf2");
	if (!gamedata)
	{
		SetFailState("[SDK] Failed to locate gamedata file \"rf2.txt\"");
	}
	
	// Courtesy of Batfoxkid
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, "EconEntity_OnOwnerKillEaterEvent_Batched");
	if (!detour.Enable(Hook_Pre, BlockKillEaterEvent))
	{
		LogError("[DHooks] Could not create detour for EconEntity_OnOwnerKillEaterEvent_Batched");
	}
	
	delete detour;
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKEquipWearable = EndPrepSDKCall();
	if (!g_hSDKEquipWearable)
	{
		LogError("[SDK] Failed to create call for CBasePlayer::EquipWearable");
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
	
	
	g_hHookIsCombatItem = new DynamicHook(gamedata.GetOffset("CBaseEntity::IsCombatItem"), HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity);
	if (!g_hHookIsCombatItem)
	{
		LogError("[DHooks] Failed to create virtual hook for CBaseEntity::IsCombatItem");
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
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFTankBoss::SetStartingPathTrackNode");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer); // targetname of path_track entity
	g_hSDKTankSetStartNode = EndPrepSDKCall();
	if (!g_hSDKTankSetStartNode)
	{
		LogError("[SDK] Failed to create call for CTFTankBoss::SetStartingPathTrackNode");
	}
	
	
	g_hHookMeleeSmack = new DynamicHook(gamedata.GetOffset("CTFWeaponBaseMelee::Smack"), HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	if (!g_hHookMeleeSmack)
	{
		LogError("[DHooks] Failed to create virtual hook for CTFWeaponBaseMelee::Smack");
	}
	
	
	g_hDetourApplyPunchImpulse = DynamicDetour.FromConf(gamedata, "CTFPlayer::ApplyPunchImpulseX");
	if (!g_hDetourApplyPunchImpulse || !g_hDetourApplyPunchImpulse.Enable(Hook_Pre, Detour_ApplyPunchImpulse))
	{
		LogError("[DHooks] Failed to create detour for CTFPlayer::ApplyPunchImpulseX");
	}
	

	g_hDetourOverhealBonus = DynamicDetour.FromConf(gamedata, "CWeaponMedigun::GetOverhealBonus");
	if (!g_hDetourOverhealBonus || !g_hDetourOverhealBonus.Enable(Hook_Pre, Detour_GetOverhealBonus))
	{
		LogError("[DHooks] Failed to create detour for CWeaponMedigun::GetOverhealBonus");
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
	
	
	g_hHookOnWrenchHit = new DynamicHook(gamedata.GetOffset("CBaseObject::OnWrenchHit"), HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity);
	if (g_hHookOnWrenchHit)
	{
		g_hHookOnWrenchHit.AddParam(HookParamType_CBaseEntity); // player hitting the building
		g_hHookOnWrenchHit.AddParam(HookParamType_CBaseEntity); // wrench hitting the building
		g_hHookOnWrenchHit.AddParam(HookParamType_VectorPtr); // hit location
	}
	else
	{
		LogError("[DHooks] Failed to create virtual hook for CBaseObject::OnWrenchHit");
	}
	
	
	g_hDetourHandleRageGain = DynamicDetour.FromConf(gamedata, "HandleRageGain");
	if (!g_hDetourHandleRageGain || !g_hDetourHandleRageGain.Enable(Hook_Pre, Detour_HandleRageGain))
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
	
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CZombie::SpawnAtPos");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef); // position
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue); // lifetime
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // team
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL); // owner
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // skeleton type
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKSpawnZombie = EndPrepSDKCall();
	if (!g_hSDKSpawnZombie)
	{
		LogError("[SDK] Failed to create call for CZombie::SpawnAtPos");
	}
	
	
	g_hDetourEyeFindVictim = DynamicDetour.FromConf(gamedata, "CEyeballBoss::FindClosestVisibleVictim");
	if (!g_hDetourEyeFindVictim || !g_hDetourEyeFindVictim.Enable(Hook_Pre, Detour_EyeFindVictim) || !g_hDetourEyeFindVictim.Enable(Hook_Post, Detour_EyeFindVictimPost))
	{
		LogError("[DHooks] Failed to create detour for CEyeballBoss::FindClosestVisibleVictim");
	}
	
	
	g_hDetourEyePickSpot = DynamicDetour.FromConf(gamedata, "CEyeballBoss::PickNewSpawnSpot");
	if (!g_hDetourEyePickSpot || !g_hDetourEyePickSpot.Enable(Hook_Pre, Detour_EyePickSpot))
	{
		LogError("[DHooks] Failed to create detour for CEyeballBoss::PickNewSpawnSpot");
	}
	
	
	g_hDetourHHHChaseable = DynamicDetour.FromConf(gamedata, "CHeadlessHatmanAttack::IsPotentiallyChaseable");
	if (!g_hDetourHHHChaseable || !g_hDetourHHHChaseable.Enable(Hook_Post, Detour_IsPotentiallyChaseablePost))
	{
		LogError("[DHooks] Failed to create detour for CHeadlessHatmanAttack::IsPotentiallyChaseable");
	}
	
	
	g_hDetourOnWeaponFired = DynamicDetour.FromConf(gamedata, "CTFBot::OnWeaponFired");
	if (!g_hDetourOnWeaponFired || !g_hDetourOnWeaponFired.Enable(Hook_Pre, Detour_OnWeaponFired))
	{
		// TODO: Fix this goddamn Windows signature
		//LogError("[DHooks] Failed to create detour for CTFBot::OnWeaponFired");
	}
	
	
	g_hHookRiflePostFrame = new DynamicHook(gamedata.GetOffset("CTFSniperRifle::ItemPostFrame"), HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	if (!g_hHookRiflePostFrame)
	{
		LogError("[DHooks] Failed to create virtual hook for CTFSniperRifle::ItemPostFrame");
	}
	
	
	g_hDetourGCPreClientUpdate = DynamicDetour.FromConf(gamedata, "CTFGCServerSystem::PreClientUpdate");
	if (!g_hDetourGCPreClientUpdate || !g_hDetourGCPreClientUpdate.Enable(Hook_Pre, Detour_GCPreClientUpdate) || !g_hDetourGCPreClientUpdate.Enable(Hook_Post, Detour_GCPreClientUpdatePost))
	{
		LogError("[DHooks] Failed to create detour for CTFGCServerSystem::PreClientUpdate");
	}
	
	
	g_hDetourFindMap = DynamicDetour.FromConf(gamedata, "CVEngineServer::FindMap");
	if (!g_hDetourFindMap || !g_hDetourFindMap.Enable(Hook_Pre, Detour_FindMap))
	{
		LogError("[DHooks] Failed to create detour for CVEngineServer::FindMap");
	}
	
	
	g_hDetourCreateEvent = DynamicDetour.FromConf(gamedata, "CGameEventManager::CreateEvent");
	if (!g_hDetourCreateEvent || !g_hDetourCreateEvent.Enable(Hook_Pre, Detour_CreateEvent))
	{
		LogError("[DHooks] Failed to create detour for CGameEventManager::CreateEvent");
	}
	
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CGameEventManager::LoadEventsFromFile");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hSDKLoadEvents = EndPrepSDKCall();
	if (!g_hSDKLoadEvents)
	{
		LogError("[SDK] Failed to create call to CGameEventManager::LoadEventsFromFile");
	}
	
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFBuffItem::RaiseFlag");
	g_hSDKRaiseFlag = EndPrepSDKCall();
	if (!g_hSDKRaiseFlag)
	{
		LogError("[SDK] Failed to create call to CTFBuffItem::RaiseFlag");
	}
	
	
	g_hDetourWeaponPickup = DynamicDetour.FromConf(gamedata, "CTFDroppedWeapon::InitPickedUpWeapon");
	if (!g_hDetourWeaponPickup || !g_hDetourWeaponPickup.Enable(Hook_Post, Detour_WeaponPickupPost))
	{
		LogError("[DHooks] Failed to create detour for CTFDroppedWeapon::InitPickedUpWeapon");
	}
	
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFDroppedWeapon::Create");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL); // last owner of weapon
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef); // origin
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef); // angles
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer); // model name
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // pItem (CEconItemView)
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKCreateDroppedWeapon = EndPrepSDKCall();
	if (!g_hSDKCreateDroppedWeapon)
	{
		LogError("[SDK] Failed to create call to CTFDroppedWeapon::Create");
	}
	
	
	g_hHookCreateFakeClientEx = new DynamicHook(gamedata.GetOffset("CVEngineServer::CreateFakeClientEx"), HookType_Raw, ReturnType_Edict, ThisPointer_Address);
	if (g_hHookCreateFakeClientEx)
	{
		g_hHookCreateFakeClientEx.AddParam(HookParamType_CharPtr);
		g_hHookCreateFakeClientEx.AddParam(HookParamType_Bool);
	}
	else
	{
		LogError("[DHooks] Failed to create dynamic hook for CVEngineServer::CreateFakeClientEx");
	}
	
	
	g_hHookDedicatedServer = new DynamicHook(gamedata.GetOffset("CVEngineServer::IsDedicatedServer"), HookType_Raw, ReturnType_Bool, ThisPointer_Address);
	if (!g_hHookDedicatedServer)
	{
		LogError("[DHooks] Failed to create dynamic hook for CVEngineServer::IsDedicatedServer");
	}


	g_hHookPassesFilterImpl = new DynamicHook(gamedata.GetOffset("CBaseFilter::PassesFilterImpl"), HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity);
	if (g_hHookPassesFilterImpl)
	{
		g_hHookPassesFilterImpl.AddParam(HookParamType_CBaseEntity); // Caller (e.g. a trigger)
		g_hHookPassesFilterImpl.AddParam(HookParamType_CBaseEntity); // Activator (entity going through the filter)
	}
	else
	{
		LogError("[DHooks] Failed to create dynamic hook for CBaseFilter::PassesFilterImpl");
	}
	
	
	g_hHookIsAbleToSee = new DynamicHook(gamedata.GetOffset("IVision::IsAbleToSee(CBaseEntity)"), HookType_Raw, ReturnType_Bool, ThisPointer_Address);
	if (g_hHookIsAbleToSee)
	{
		g_hHookIsAbleToSee.AddParam(HookParamType_CBaseEntity); // subject
		g_hHookIsAbleToSee.AddParam(HookParamType_Int); // checkFOV type
		g_hHookIsAbleToSee.AddParam(HookParamType_VectorPtr); // visibleSpot
	}
	else
	{
		LogError("[DHooks] Failed to create dynamic hook for IVision::IsAbleToSee(CBaseEntity)");
	}
	
	
	g_hHookPhysicsSolidMask = new DynamicHook(gamedata.GetOffset("CBaseEntity::PhysicsSolidMaskForEntity"), HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity);
	if (!g_hHookPhysicsSolidMask)
	{
		LogError("[DHooks] Failed to create dynamic hook for CBaseEntity::PhysicsSolidMaskForEntity");
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
	gamedata = new GameData("sm-tf2.games");
	g_hHookForceRespawn = new DynamicHook(gamedata.GetOffset("ForceRespawn"), HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	if (!g_hHookForceRespawn)
	{
		LogError("[DHooks] Failed to create virtual hook for ForceRespawn");
	}
	
	delete gamedata;
}

public void OnMapStart()
{
	if (g_bConVarsModified && !g_bPluginReloading)
	{
		ResetConVars();
		g_bConVarsModified = false;
	}
	
	// This was a reload map change
	if (g_bPluginReloading)
	{
		char fileName[32];
		GetPluginFilename(INVALID_HANDLE, fileName, sizeof(fileName));
		ReplaceStringEx(fileName, sizeof(fileName), ".smx", "");
		InsertServerCommand("sm plugins load_unlock; sm plugins reload %s", fileName);
		return;
	}
	
	//g_bCustomEventsAvailable = false;
	if (g_aGameEventManager && g_hSDKLoadEvents)
	{
		char eventsFile[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, eventsFile, sizeof(eventsFile), "data/rf2/rf2events.res");
		LogMessage("Loading custom events file '%s'", eventsFile);
		if (SDKCall(g_hSDKLoadEvents, g_aGameEventManager, eventsFile))
		{
			//g_bCustomEventsAvailable = true;
			LogMessage("Success!");
		}
		else
		{
			LogError("FAILED to load custom events file '%s'", eventsFile);
		}
	}
	else
	{
		LogError("FAILED to load custom events file (Missing Gamedata!)");
	}
	
	g_bMapChanging = false;
	g_bMapRunning = true;
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
					OnClientPostAdminCheck(i);
				}
			}
		}
		
		if (MaxClients < 32)
		{
			LogMessage("This server has only %i maxplayers. 32 maxplayers is recommended for Risk Fortress 2.", MaxClients);
		}
		
		if (!TheNavMesh.IsLoaded())
		{
			SetFailState("[NAV] The NavMesh for map \"%s\" does not exist", mapName);
		}
		
		if (!TheNavMesh.IsAnalyzed())
		{
			LogError("[NAV] The NavMesh for map \"%s\" needs a nav_analyze", mapName);
		}
		
		UpdateGameDescription();
		LoadAssets();
		if (!g_bLateLoad)
		{
			// this causes problems when changing default values of cvars
			//AutoExecConfig(true, "RiskFortress2");
		}
		
		ConVar maxSpeed = FindConVar("sm_tf2_maxspeed");
		if (!maxSpeed)
		{
			// There are two plugins that uncap max speed - try the other one
			maxSpeed = FindConVar("tf_maxspeed_limit");
		}
		
		if (maxSpeed)
		{
			maxSpeed.FloatValue = 900.0;
		}
		
		GameRules_SetProp("m_nForceUpgrades", 2); // force some MvM specific mechanics
		
		// These are ConVars we're OK with being set by server.cfg, but we'll set our personal defaults.
		// If configs wish to change these, they will be overridden by them later.
		FindConVar("sv_alltalk").SetBool(true);
		FindConVar("tf_use_fixed_weaponspreads").SetBool(true);
		FindConVar("tf_avoidteammates_pushaway").SetBool(false);
		FindConVar("tf_bot_pyro_shove_away_range").SetFloat(0.0);
		FindConVar("sv_tags").Flags = 0;
		FindConVar("tv_enable").SetBool(true);
		FindConVar("mp_tournament_redteamname").SetString("SURVIVORS");
		FindConVar("mp_tournament_blueteamname").SetString("ROBOTS");
		SetMVMPlayerCvar(GetDesiredPlayerCap());
		
		// Why is this a development only ConVar Valve?
		ConVar waitTime = FindConVar("mp_waitingforplayers_time");
		waitTime.Flags &= ~FCVAR_DEVELOPMENTONLY;
		waitTime.SetInt(WAIT_TIME_DEFAULT);
		
		HookEvents();
		
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
		AddCommandListener(OnEurekaTeleport, "eureka_teleport");
		
		// Everything else
		HookEntityOutput("tank_boss", "OnKilled", Output_OnTankKilled);
		HookEntityOutput("rf2_tank_boss_badass", "OnKilled", Output_OnTankKilled);
		HookUserMessage(GetUserMessageId("SayText2"), UserMessageHook_SayText2, true);
		AddNormalSoundHook(PlayerSoundHook);
		AddTempEntHook("TFBlood", TEHook_TFBlood);
		g_hMainHudSync = CreateHudSynchronizer();
		g_hObjectiveHudSync = CreateHudSynchronizer();
		g_hMiscHudSync = CreateHudSynchronizer();
		
		// ALWAYS load items first
		if (GetTotalItems() <= 0)
		{
			LoadItems();
		}
		
		g_iMaxStages = FindMaxStages();
		if (!g_szUnderworldMap[0])
			FindSpecialMap(SpecialMap_Underworld);
		if (!g_szFinalMap[0])
			FindSpecialMap(SpecialMap_Final);
			
		LoadMapSettings(mapName);
		g_bTropicsMapExists = RF2_IsMapValid("rf2_tropics"); // For ACHIEVEMENT_TEMPLESECRET - hide it if the map doesn't exist
		if (!g_bStatsLoaded)
		{
			LoadWeapons();
			LoadSurvivorStats();
			g_bStatsLoaded = true;
		}
		
		Call_StartForward(g_fwOnMapStart);
		Call_Finish();
		CreateTimer(1.0, Timer_AFKManager, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(60.0, Timer_PluginMessage, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		if (g_bLateLoad)
		{
			DespawnObjects();
		}
		
		if (g_szUnderworldMap[0])
			g_bInUnderworld = StrContains(mapName, g_szUnderworldMap, false) == 0;

		if (g_szFinalMap[0])
			g_bInFinalMap = StrContains(mapName, g_szFinalMap, false) == 0;
		
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
		// before we do anything, check if this is a server startup
		if (!g_cvServerStarted.BoolValue)
		{
			g_cvServerStarted.BoolValue = true;
			if (g_cvStage1StartingMap.BoolValue)
			{
				PrintToServer("\n*\n*\n*\n[RF2] The server just booted. Choosing a random startup map...\n*\n*\n*\n");
				ReloadPlugin(true);
				return;
			}
		}
		
		// Here are ConVars that we don't want changed by configs
		ConVar droppedWeaponLife = FindConVar("tf_dropped_weapon_lifetime");
		droppedWeaponLife.Flags &= ~FCVAR_CHEAT;
		droppedWeaponLife.SetInt(999999);
		FindConVar("sv_quota_stringcmdspersecond").SetInt(5000); // So Engie bots don't get kicked
		FindConVar("mp_teams_unbalance_limit").SetInt(0);
		FindConVar("mp_forcecamera").SetBool(false);
		FindConVar("mp_maxrounds").SetInt(9999);
		FindConVar("mp_timelimit").SetInt(99999);
		FindConVar("mp_forceautoteam").SetBool(true);
		FindConVar("mp_respawnwavetime").SetFloat(99999.0);
		FindConVar("mp_bonusroundtime").SetInt(15);
		FindConVar("tf_weapon_criticals").SetBool(false);
		FindConVar("tf_forced_holiday").SetInt(2);
		FindConVar("tf_player_movement_restart_freeze").SetBool(false);
		FindConVar("sm_vote_progress_hintbox").SetBool(true);
		FindConVar("mp_humans_must_join_team").SetString(g_cvAllowHumansInBlue.BoolValue ? "any" : "red");
		InsertServerCommand("sv_pure 0");
		
		// Remove Goomba immunities on stunned players
		ConVar goombaBonk = FindConVar("goomba_bonked_immun");
		ConVar goombaStun = FindConVar("goomba_stun_immun");
		if (goombaBonk)
		{
			goombaBonk.BoolValue = false;
			goombaStun.BoolValue = false;
		}

		UpdateBotQuota();
		char class[32];
		TF2_GetClassString(view_as<TFClassType>(GetRandomInt(1, 9)), class, sizeof(class));
		FindConVar("tf_bot_force_class").SetString(class);
		FindConVar("tf_bot_quota_mode").SetString("normal");
		FindConVar("tf_bot_defense_must_defend_time").SetInt(-1);
		FindConVar("tf_bot_offense_must_push_time").SetInt(-1);
		FindConVar("tf_bot_taunt_victim_chance").SetInt(0);
		FindConVar("tf_bot_join_after_player").SetBool(true);
		FindConVar("tf_bot_auto_vacate").SetBool(false);
		ConVar botConsiderClass = FindConVar("tf_bot_reevaluate_class_in_spawnroom");
		botConsiderClass.Flags = botConsiderClass.Flags & ~FCVAR_CHEAT;
		botConsiderClass.SetBool(false);
		g_bConVarsModified = true;
	}
}

public void OnMapEnd()
{
	g_bMapChanging = true;
	g_bMapRunning = false;
	g_szForcedMap = "";
	if (RF2_IsEnabled())
	{
		if (!g_bGameOver && g_bGameInitialized && !IsInUnderworld())
		{
			g_iStagesCompleted++;
		}
		
		if (g_bGameWon && g_iDifficultyLevel >= DIFFICULTY_STEEL)
		{
			// Create a file as a flag saying that we won on a high difficulty setting. We shouldn't use a cvar as that will get reset if the server restarts.
			CreateSteelVictoryFlag();
		}
		
		CleanUp();
	}
}

void HookEvents()
{
	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_Pre);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Post);
	HookEvent("teamplay_broadcast_audio", OnBroadcastAudio, EventHookMode_Pre);
	HookEvent("post_inventory_application", OnPostInventoryApplication, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_chargedeployed", OnPlayerChargeDeployed, EventHookMode_Post);
	HookEvent("player_dropobject", OnPlayerDropObject, EventHookMode_Post);
	HookEvent("player_builtobject", OnPlayerBuiltObject, EventHookMode_Post);
	HookEvent("player_upgradedobject", OnPlayerUpgradeObject, EventHookMode_Post);
	HookEvent("player_team", OnChangeTeamMessage, EventHookMode_Pre);
	HookEvent("player_connect_client", OnPlayerConnect, EventHookMode_Pre);
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_healonhit", OnPlayerHealOnHit, EventHookMode_Pre);
	HookEvent("npc_hurt", OnNpcHurt, EventHookMode_Post);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
}

void UnhookEvents()
{
	UnhookEvent("teamplay_round_start", OnRoundStart, EventHookMode_Pre);
	UnhookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Post);
	UnhookEvent("teamplay_broadcast_audio", OnBroadcastAudio, EventHookMode_Pre);
	UnhookEvent("post_inventory_application", OnPostInventoryApplication, EventHookMode_Post);
	UnhookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	UnhookEvent("player_chargedeployed", OnPlayerChargeDeployed, EventHookMode_Post);
	UnhookEvent("player_dropobject", OnPlayerDropObject, EventHookMode_Post);
	UnhookEvent("player_builtobject", OnPlayerBuiltObject, EventHookMode_Post);
	UnhookEvent("player_upgradedobject", OnPlayerUpgradeObject, EventHookMode_Post);
	UnhookEvent("player_team", OnChangeTeamMessage, EventHookMode_Pre);
	UnhookEvent("player_connect_client", OnPlayerConnect, EventHookMode_Pre);
	UnhookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
	UnhookEvent("player_healonhit", OnPlayerHealOnHit, EventHookMode_Pre);
	UnhookEvent("npc_hurt", OnNpcHurt, EventHookMode_Post);
	UnhookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
}

void CleanUp()
{
	CleanPathFollowers();
	UnhookEvents();
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
	RemoveCommandListener(OnEurekaTeleport, "eureka_teleport");
	UnhookEntityOutput("tank_boss", "OnKilled", Output_OnTankKilled);
	UnhookEntityOutput("rf2_tank_boss_badass", "OnKilled", Output_OnTankKilled);
	UnhookUserMessage(GetUserMessageId("SayText2"), UserMessageHook_SayText2, true);
	RemoveNormalSoundHook(PlayerSoundHook);
	RemoveTempEntHook("TFBlood", TEHook_TFBlood);
	
	g_bRoundActive = false;
	g_bGracePeriod = false;
	g_bWaitingForPlayers = false;
	g_bRoundEnding = false;
	g_bEnteringUnderworld = false;
	g_bItemSharingDisabledForMap = false;
	g_bInUnderworld = false;
	g_bInFinalMap = false;
	g_bScavengerLordDroppedItems = false;
	g_flNextAutoReloadCheckTime = 0.0;
	g_flAutoReloadTime = 0.0;
	//g_flMinSpawnDistOverride = -1.0;
	//g_flMaxSpawnDistOverride = -1.0;
	g_flBossSpawnChanceBonus = 0.0;
	g_flMaxSpawnWaveTime = 0.0;
	g_hPlayerTimer = null;
	g_hHudTimer = null;
	g_hDifficultyTimer = null;
	g_hItemTimer = null;
	g_iRespawnWavesCompleted = 0;
	g_szEnemyPackName = "";
	g_szBossPackName = "";
	g_iTeleporterEntRef = INVALID_ENT;
	g_iWorldCenterEntity = INVALID_ENT;
	g_iRF2GameRulesEntity = INVALID_ENT;
	g_bTankBossMode = false;
	g_bRaidBossMode = false;
	g_iTanksKilledObjective = 0;
	g_iTankKillRequirement = 1;
	g_iTanksSpawned = 0;
	g_flWaitRestartTime = 0.0;
	g_iCurrentCustomTrack = -1;
	g_bTeleporterEventReminder = false;
	g_bRingCashBonus = false;
	delete g_hMainHudSync;
	delete g_hObjectiveHudSync;
	delete g_hMiscHudSync;
	g_hCrashedPlayerSteamIDs.Clear();
	g_hEnemyTypeCooldowns.Clear();
	g_hEnemyTypeNumSpawned.Clear();
	g_hHHHTargets.Clear();
	g_hMonoculusTargets.Clear();
	SetAllInArray(g_hCrashedPlayerTimers, sizeof(g_hCrashedPlayerTimers), INVALID_HANDLE);
	StopMusicTrackAll();
	g_hCustomTracks.Clear();
	g_hCustomTracksDuration.Clear();
	
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

	ConVar tournament = FindConVar("mp_tournament");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			SendConVarValue(i, tournament, "0");
		}
	}
}

void LoadAssets()
{
	// Models
	AddModelToDownloadsTable(MODEL_BOT_SCOUT);
	AddModelToDownloadsTable(MODEL_BOT_SOLDIER);
	AddModelToDownloadsTable(MODEL_BOT_PYRO);
	AddModelToDownloadsTable(MODEL_BOT_DEMO);
	AddModelToDownloadsTable(MODEL_BOT_HEAVY);
	AddModelToDownloadsTable(MODEL_BOT_ENGINEER);
	AddModelToDownloadsTable(MODEL_BOT_MEDIC);
	AddModelToDownloadsTable(MODEL_BOT_SNIPER);
	AddModelToDownloadsTable(MODEL_BOT_SPY);
	AddModelToDownloadsTable(MODEL_GIANT_SCOUT);
	AddModelToDownloadsTable(MODEL_GIANT_SOLDIER);
	AddModelToDownloadsTable(MODEL_GIANT_PYRO);
	AddModelToDownloadsTable(MODEL_GIANT_DEMO);
	AddModelToDownloadsTable(MODEL_GIANT_HEAVY);
	g_iBeamModel = PrecacheModel2(MAT_BEAM, true);
	PrecacheModel2(MODEL_ROLLERMINE, true);
	PrecacheModel2(MODEL_ROLLERMINE_SPIKES, true);
	
	// Sounds
	PrecacheSound2(SND_ITEM_PICKUP, true);
	PrecacheSound2(SND_GAME_OVER, true);
	PrecacheSound2(SND_EVIL_LAUGH, true);
	PrecacheSound2(SND_LASTMAN, true);
	PrecacheSound2(SND_SCAVENGER_LORD_WARNING, true);
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
	PrecacheSound2(SND_THUNDER, true);
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
	PrecacheSound2(SND_TELEPORTER_BLU_START, true);
	PrecacheSound2(SND_TELEPORTER_BLU, true);
	PrecacheSound2(SND_DOOMSDAY_EXPLODE, true);
	PrecacheSound2(SND_ACHIEVEMENT, true);
	PrecacheSound2(SND_DRAGONBORN2, true);
	PrecacheSound2(SND_AUTOFIRE_TOGGLE, true);
	PrecacheSound2(SND_AUTOFIRE_SHOOT, true);
	PrecacheSound2(SND_STUN, true);
	PrecacheSound2(SND_PARACHUTE, true);
	PrecacheSound2(SND_HINT, true);
	PrecacheSound2(SND_ENTER_HELL, true);
	PrecacheSound2(SND_LONGWAVE_USE, true);
	PrecacheSound2(SND_REVIVE, true);
	PrecacheSound2(SND_MULTICRATE_CYCLE, true);
	PrecacheSound2(SND_BOSS_DEATH, true);
	PrecacheSound2(SND_MEDSHIELD_DEPLOY, true);
	PrecacheSound2("weapons/flame_thrower_loop.wav", true);
	PrecacheSound2("weapons/flame_thrower_start.wav", true);
	PrecacheSound2("weapons/flame_thrower_end.wav", true);
	PrecacheSound2("vo/halloween_boss/knight_attack01.mp3", true);
	PrecacheSound2("vo/halloween_boss/knight_attack02.mp3", true);
	PrecacheSound2("vo/halloween_boss/knight_attack03.mp3", true);
	PrecacheSound2("vo/halloween_boss/knight_attack04.mp3", true);
	PrecacheScriptSound(GSND_CRIT);
	PrecacheScriptSound(GSND_MINICRIT);
	PrecacheScriptSound(GSND_MVM_POWERUP);
	PrecacheScriptSound("MVM.GiantScoutLoop");
	PrecacheScriptSound("MVM.GiantSoldierLoop");
	PrecacheScriptSound("MVM.GiantPyroLoop");
	PrecacheScriptSound("MVM.GiantDemomanLoop");
	PrecacheScriptSound("MVM.GiantHeavyLoop");
	PrecacheSound2(")mvm/sentrybuster/mvm_sentrybuster_spin.wav", true);
	PrecacheSound2("npc/roller/mine/rmine_blades_out1.wav", true);
	PrecacheSound2("npc/roller/mine/rmine_blades_out2.wav", true);
	PrecacheSound2("npc/roller/mine/rmine_blades_out3.wav", true);
	PrecacheSound2("npc/roller/mine/rmine_blades_in1.wav", true);
	PrecacheSound2("npc/roller/mine/rmine_blades_in2.wav", true);
	PrecacheSound2("npc/roller/mine/rmine_blades_in3.wav", true);
	PrecacheSound2("npc/roller/mine/combine_mine_deploy1.wav", true);
	PrecacheSound2("npc/roller/mine/rmine_explode_shock1.wav", true);
	PrecacheSound2("npc/roller/mine/rmine_tossed1.wav", true);
	PrecacheSound2("npc/roller/mine/rmine_seek_loop2.wav", true);
	char sample[PLATFORM_MAX_PATH];
	for (int i = 1; i <= 18; i++)
	{
		if (i > 9)
		{
			FormatEx(sample, sizeof(sample), "mvm/player/footsteps/robostep_%i.wav", i);
		}
		else
		{
			FormatEx(sample, sizeof(sample), "mvm/player/footsteps/robostep_0%i.wav", i);
		}
		
		PrecacheSound2(sample);
	}
	
	AddSoundToDownloadsTable(SND_LASER);
	AddSoundToDownloadsTable(SND_WEAPON_CRIT);
	AddSoundToDownloadsTable(SND_DRAGONBORN);
	AddSoundToDownloadsTable(SND_1UP);
	AddSoundToDownloadsTable(SND_EVIL_LAUGH);
	PrecacheSoundArray(g_szTeddyBearSounds, sizeof(g_szTeddyBearSounds));
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
	ResetConVar(FindConVar("mp_humans_must_join_team"));
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
	ResetConVar(FindConVar("tf_bot_auto_vacate"));
	ResetConVar(FindConVar("tf_bot_reevaluate_class_in_spawnroom"));
	ResetConVar(FindConVar("tf_bot_quota"));
	ResetConVar(FindConVar("tf_bot_quota_mode"));
	ResetConVar(FindConVar("tf_bot_pyro_shove_away_range"));
	ResetConVar(FindConVar("tf_bot_force_class"));
	ResetConVar(FindConVar("tf_allow_server_hibernation"));
	ResetConVar(FindConVar("tf_mvm_defenders_team_size"));
	ResetConVar(FindConVar("tf_mvm_max_connected_players"));
	ResetConVar(FindConVar("tf_bot_offline_practice"));
	ResetConVar(FindConVar("tv_enable"));
	ResetConVar(FindConVar("mp_tournament_redteamname"));
	ResetConVar(FindConVar("mp_tournament_blueteamname"));
	ConVar goombaBonk = FindConVar("goomba_bonked_immun");
	ConVar goombaStun = FindConVar("goomba_stun_immun");
	if (goombaBonk)
	{
		ResetConVar(goombaBonk);
		ResetConVar(goombaStun);
	}

	ConVar maxSpeed = FindConVar("sm_tf2_maxspeed");
	if (!maxSpeed)
	{
		// There are two plugins that uncap max speed - try the other one
		maxSpeed = FindConVar("tf_maxspeed_limit");
	}
	
	if (maxSpeed)
	{
		ResetConVar(maxSpeed);
	}
}

public void OnAllPluginsLoaded()
{
	g_bGoombaAvailable = LibraryExists("goomba");
	if (g_bGoombaAvailable)
	{
		#if !defined _goomba_included_
		LogError("The Goomba Stomp plugin is present, but rf2.smx was compiled without goomba.inc. Please correct this.");
		#endif
	}
}

public void OnClientConnected(int client)
{
	if (RF2_IsEnabled() && !IsFakeClient(client))
	{
		UpdateBotQuota();
	}
}

public void OnClientPutInServer(int client)
{
	RefreshClient(client);
	GetClientName(client, g_szPlayerOriginalName[client], sizeof(g_szPlayerOriginalName[]));
	if (!g_bRoundActive && !IsSpecBot(client) && !IsFakeClient(client))
	{
		CreateTimer(1.5, Timer_PlayerJoinTeam, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (RF2_IsEnabled() && !IsSpecBot(client))
	{
		if (IsFakeClient(client))
		{
			TFBot(client).Path = PathFollower(INVALID_FUNCTION, FilterIgnoreActors, FilterOnlyActors);
			SDKHook(client, SDKHook_WeaponCanSwitchTo, Hook_TFBotWeaponCanSwitch);
			SDKHook(client, SDKHook_Touch, Hook_TFBotTouch);
			SDKHook(client, SDKHook_TouchPost, Hook_TFBotTouchPost);
			if (g_hHookIsAbleToSee)
			{
				IVision vision = TFBot(client).GetVision();
				if (vision)
				{
					g_hHookIsAbleToSee.HookRaw(Hook_Pre, view_as<Address>(vision), DHook_IsAbleToSee);
					g_hHookIsAbleToSee.HookRaw(Hook_Post, view_as<Address>(vision), DHook_IsAbleToSeePost);
				}
			}
		}
		else
		{
			// required for custom team names
			// needs to be 0 in preround or else the tournament hud will show
			ConVar tournament = FindConVar("mp_tournament");
			SendConVarValue(client, tournament, g_bRoundActive ? "1" : "0");
		}
		
		if (g_bRoundActive && !IsMusicPaused())
		{
			PlayMusicTrack(client);
		}
		
		SDKHook(client, SDKHook_PreThink, Hook_PreThink);
		SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
		SDKHook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamageAlive);
		SDKHook(client, SDKHook_OnTakeDamageAlivePost, Hook_OnTakeDamageAlivePost);
		SDKHook(client, SDKHook_WeaponSwitchPost, Hook_WeaponSwitchPost);
		SDKHook(client, SDKHook_TraceAttack, Hook_OnTraceAttack);
		
		if (g_hHookTakeHealth)
		{
			g_hHookTakeHealth.HookEntity(Hook_Pre, client, DHook_TakeHealth);
		}
		
		if (g_hHookForceRespawn)
		{
			g_hHookForceRespawn.HookEntity(Hook_Pre, client, DHook_ForceRespawn);
		}
		
		g_hPlayerExtraSentryList[client] = new ArrayList();
	}
}

public void Timer_PlayerJoinTeam(Handle timer, int client)
{
	if (!g_bWaitingForPlayers || g_bRoundActive || !(client = GetClientOfUserId(client)) || IsPlayerAlive(client))
		return;
	
	ChangeClientTeam(client, GetRandomInt(2, 3));
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

public void Timer_MakeSurvivor(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if (client == 0)
		return;
	
	int index = pack.ReadCell();
	TF2_SetPlayerClass(client, view_as<TFClassType>(pack.ReadCell()));
	MakeSurvivor(client, index, false);
	PrintHintText(client, "To avoid crashes in the future, try turning off Multicore Rendering in advanced video options.");
}

public void OnClientDisconnect(int client)
{
	if (!RF2_IsEnabled())
		return;
	
	StopMusicTrack(client);
	if (g_bPlayerTimingOut[client] && IsPlayerSurvivor(client, false) && !IsPlayerMinion(client))
	{
		RF2_PrintToChatAll("{yellow}%N {red}crashed or lost connection on RED and has 5 minutes to reconnect!", client);
		PrintToServer("%N crashed or lost connection on RED and has 5 minutes to reconnect!", client);
		char authId[MAX_AUTHID_LENGTH], class[128];
		if (GetClientAuthId(client, AuthId_Steam2, authId, sizeof(authId)))
		{
			int index = RF2_GetSurvivorIndex(client);
			int invIndex = g_iPlayerInventoryIndex[client];
			g_hCrashedPlayerSteamIDs.SetValue(authId, index);
			FormatEx(class, sizeof(class), "%s_CLASS", authId);
			g_hCrashedPlayerSteamIDs.SetValue(class, TF2_GetPlayerClass(client)); // Remember class
			SaveSurvivorInventory(client, invIndex);
			DataPack pack;
			g_hCrashedPlayerTimers[index] = CreateDataTimer(300.0, Timer_PlayerReconnect, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteString(authId);
			if (IsSingleplayer())
			{
				FindConVar("tf_allow_server_hibernation").SetBool(false);
				FindConVar("tf_bot_join_after_player").SetBool(false);
			}
		}
	}
	else if (!IsFakeClient(client))
	{
		if (g_bRoundActive && !g_bGameOver && !g_bGameWon && !g_bMapChanging)
		{
			CheckRedTeam(client);
		}
		
		DataBase_OnDisconnected(client);
	}
	
	if (!g_bPlayerTimingOut[client] && !g_bPluginReloading && !IsFakeClient(client))
	{
		if (IsPlayerSurvivor(client, false))
		{
			SaveSurvivorInventory(client, g_iPlayerInventoryIndex[client]);
			CalculateSurvivorItemShare();
		}
	}
	
	if (IsValidEntity2(g_iPlayerRollerMine[client]))
	{
		RemoveEntity(g_iPlayerRollerMine[client]);
	}
	
	g_bPlayerTimingOut[client] = false;
}

public void OnClientDisconnect_Post(int client)
{
	if (!RF2_IsEnabled())
		return;

	g_flLoopMusicAt[client] = -1.0;
	if (g_hPlayerExtraSentryList[client])
	{
		delete g_hPlayerExtraSentryList[client];
		g_hPlayerExtraSentryList[client] = null;
	}
	
	if (TFBot(client).Path)
	{
		TFBot(client).Path.Destroy();
		TFBot(client).Path = view_as<PathFollower>(0);
	}
	
	g_iPlayerInventoryIndex[client] = -1;
	g_iPlayerSurvivorIndex[client] = -1;
	g_iPlayerCollectorSwapCount[client] = 0;
	g_flPlayerCash[client] = 0.0;
	g_iMetalItemsDropped[client] = 0;
	g_bPlayerIsDyingBoss[client] = false;
	g_bPlayerSpawningAsMinion[client] = false;
	g_bPlayerToggledAutoFire[client] = false;
	g_bPlayerHauntedKeyDrop[client] = false;
	g_bPlayerReviveActivated[client] = false;
	g_bPlayerItemShareExcluded[client] = false;
	g_hPlayerItemDescTimer[client] = null;
	RefreshClient(client, true);
	ResetAFKTime(client);
	UpdateBotQuota();
}

public void Timer_PlayerReconnect(Handle timer, DataPack pack)
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
}

void CheckRedTeam(int client)
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client || !IsClientInGame(i))
			continue;
		
		if (IsPlayerSurvivor(i) && !IsPlayerMinion(i))
			count++;
	}
	
	if (count <= 0 && !g_bRoundEnding) // Everybody on RED is gone, game over
	{
		RF2_PrintToChatAll("%t", "AllHumansDisconnected");
		GameOver();
	}
}

public Action OnRoundStart(Event event, const char[] eventName, bool dontBroadcast)
{
	if (!RF2_IsEnabled() || g_bWaitingForPlayers)
		return Plugin_Continue;
	
	InsertServerCommand("mp_restartgame_immediate 0");
	g_bRoundActive = true;
	g_bGracePeriod = true;
	g_bRoundEnding = false;
	g_szCurrentEnemyGroup = "";
	if (!CreateSurvivors())
	{
		g_bRoundActive = false;
		g_bGracePeriod = false;
		if (!g_bGameInitialized || GetTotalHumans(false) > 0)
		{
			if (g_cvAggressiveRestarting.BoolValue)
			{
				if (g_cvGamePlayedCount.IntValue >= 1 && GetTotalHumans(false) <= 0)
				{
					InsertServerCommand("quit");
					return Plugin_Continue;
				}
			}
			
			InsertServerCommand("mp_waitingforplayers_restart 1");
		}
		else
		{
			PrintToServer("%T", "NoSurvivorsSpawned", LANG_SERVER);
			if (g_cvAggressiveRestarting.BoolValue)
			{
				if (g_cvGamePlayedCount.IntValue >= 1)
				{
					InsertServerCommand("quit");
					return Plugin_Continue;
				}	
			}
			
			ReloadPlugin();
		}
		
		return Plugin_Continue;
	}

	RF2_GameRules rfGamerules = GetRF2GameRules();
	if (rfGamerules.IsValid())
	{
		rfGamerules.FireOutput("OnRoundStart");
		g_iLoopCount > 0 || g_cvDebugUseAltMapSettings.BoolValue ? rfGamerules.FireOutput("OnRoundStartPostLoop") : rfGamerules.FireOutput("OnRoundStartPreLoop");
	}
	
	if (!g_bGameInitialized)
	{
		CreateTimer(2.0, Timer_DifficultyVote, _, TIMER_FLAG_NO_MAPCHANGE);
		g_bGameInitialized = true;
		UpdateGameDescription();
	}
	
	g_flRoundStartSeconds = g_flSecondsPassed;
	int gamerules = FindEntityByClassname(-1, "tf_gamerules");
	if (gamerules == INVALID_ENT)
	{
		gamerules = CreateEntityByName("tf_gamerules");
	}
	
	GameRules_SetPropFloat("m_flNextRespawnWave", GetGameTime()+999999.0, 2);
	GameRules_SetPropFloat("m_flNextRespawnWave", GetGameTime()+999999.0, 3);
	SetVariantInt(9999);
	AcceptEntityInput(gamerules, "SetRedTeamRespawnWaveTime");
	SetVariantInt(9999);
	AcceptEntityInput(gamerules, "SetBlueTeamRespawnWaveTime");
	
	SpawnObjects();
	g_flCurrentCostMult = RF2_Object_Base.GetCostMultiplier();
	
	// fix map-spawned objects having no collision(?)
	RF2_Object_Base obj;
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "rf2_object*")) != INVALID_ENT)
	{
		obj = RF2_Object_Base(entity);
		if (obj.MapPlaced)
		{
			if (!RF2_Object_Teleporter(obj.index).IsValid())
			{
				obj.SetProp(Prop_Send, "m_usSolidFlags", FSOLID_TRIGGER_TOUCH_DEBRIS|FSOLID_TRIGGER|FSOLID_NOT_SOLID|FSOLID_CUSTOMBOXTEST);
				obj.SetProp(Prop_Send, "m_nSolidType", SOLID_OBB);
				SetEntityCollisionGroup(obj.index, COLLISION_GROUP_DEBRIS_TRIGGER);
			}
		}
	}

	ConVar tournament = FindConVar("mp_tournament");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			SendConVarValue(i, tournament, "1");
		}
	}
	
	int breakable = MaxClients+1;
	while ((breakable = FindEntityByClassname(breakable, "func_breakable")) != INVALID_ENT)
	{
		SetEntTeam(breakable, TEAM_SURVIVOR); // so caber hits don't detonate
	}
	
	if (g_hPlayerTimer)
		delete g_hPlayerTimer;
	
	if (g_hHudTimer)
		delete g_hHudTimer;
	
	if (g_hDifficultyTimer)
		delete g_hDifficultyTimer;
	
	if (g_hItemTimer)
		delete g_hItemTimer;
	
	g_hPlayerTimer = CreateTimer(0.1, Timer_PlayerTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	g_hHudTimer = CreateTimer(0.1, Timer_PlayerHud, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	g_hDifficultyTimer = CreateTimer(1.0, Timer_Difficulty, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	g_hItemTimer = CreateTimer(0.1, Timer_UpdateItems, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	StopMusicTrackAll();
	CreateTimer(0.25, Timer_PlayMusicDelay, _, TIMER_FLAG_NO_MAPCHANGE);
	
	// Begin grace period
	if (g_flGracePeriodTime >= 0.0)
	{
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
	}
	else
	{
		g_bGracePeriod = false;
		entity = MaxClients+1;
		char name[128];
		while ((entity = FindEntityByClassname(entity, "team_round_timer")) != INVALID_ENT)
		{
			// make sure it doesn't have a name, to avoid messing with map logic (ones starting with zz_ are ones created by the game)
			GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
			if (name[0] && StrContains(name, "zz_") != 0)
				continue;
			
			if (GetEntProp(entity, Prop_Send, "m_nState") == 0)
			{
				RemoveEntity(entity);
				break;
			}
		}
	}
	
	if (IsCurseActive(Curse_Scarcity))
	{
		InsertServerCommand("ent_remove_all rf2_object_crate");
		InsertServerCommand("ent_remove_all rf2_object_altar");
		InsertServerCommand("ent_remove_all rf2_object_pedestal");
	}
	
	Call_StartForward(g_fwGracePeriodStart);
	Call_Finish();
	GameRules_SetProp("m_nGameType", -1);
	return Plugin_Continue;
}

public void Timer_DifficultyVote(Handle timer)
{
	if (!IsVoteInProgress())
	{
		StartDifficultyVote();
	}
	else // Try again in a bit
	{
		CreateTimer(5.0, Timer_DifficultyVote, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

void StartDifficultyVote()
{
	Menu menu = new Menu(Menu_DifficultyVote);
	menu.SetTitle("Vote for the game's difficulty level!");
	menu.AddItem("0", "Scrap (Easy)");
	menu.AddItem("1", "Iron (Normal)");
	menu.AddItem("2", "Steel (Hard)");
	
	bool achievement = true;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerSurvivor(i))
		{
			if (!IsAchievementUnlocked(i, ACHIEVEMENT_BEATGAMESTEEL)
				&& !IsAchievementUnlocked(i, ACHIEVEMENT_BEATGAMETITANIUM))
			{
				// Every player needs to have either of these achievements for Titanium to always show up
				achievement = false;
				break;
			}
		}
	}
	
	if (achievement || GetRandomInt(1, 20) == 1 || g_cvAlwaysAllowTitaniumVoting.BoolValue || DoesSteelVictoryFlagExist())
	{
		menu.AddItem("3", "Titanium (Expert)");
	}
	
	int clients[MAXPLAYERS] = {-1, ...};
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
			SetDifficultyLevel(StringToInt(info));
			char difficultyName[64];
			GetDifficultyName(g_iDifficultyLevel, difficultyName, sizeof(difficultyName), _, true);
			if (g_iDifficultyLevel < DIFFICULTY_TITANIUM)
			{
				RF2_PrintToChatAll("%t", "DifficultySet", difficultyName);
			}
			else
			{
				EmitSoundToAll(SND_EVIL_LAUGH);
				EmitSoundToAll(SND_EVIL_LAUGH);
				RF2_PrintToChatAll("%t", "DifficultySetDeadly", difficultyName);
				RemoveSteelVictoryFlag();
			}
		}
		case MenuAction_VoteCancel:
		{
			if (!g_bPluginReloading) // Causes an error when the plugin is reloading for some reason
			{
				SetDifficultyLevel(GetRandomInt(DIFFICULTY_SCRAP, DIFFICULTY_IRON));
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
			//RF2_PrintToChat(i, "%t", "GainedSurvivorPoints");
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
			
			CreateTimer(12.0, Timer_ConvertXP, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
			if (!IsSingleplayer(false) && g_cvItemShareEnabled.BoolValue && g_cvItemShareDisableThreshold.FloatValue > 0.0)
			{
				int value = GetCookieInt(i, g_coItemShareKarma);
				int items = g_iPlayerItemsTaken[RF2_GetSurvivorIndex(i)];
				int required = GetPlayerRequiredItems(i);
				if (items <= 0)
				{
					// very bad karma
					value = imax(-2, value-2);
				}
				else if (items < required)
				{
					// bad karma
					value = imax(-2, value-1);
				}
				else
				{
					value = imin(2, value+1); // good karma
				}
				
				SetCookieInt(i, g_coItemShareKarma, value);
			}
		}
		
		if (g_bEnteringUnderworld)
		{
			CreateTimer(10.5, Timer_EnterUnderworldEffect, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		CreateTimer(14.0, Timer_SetNextStage, DetermineNextStage(), TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (winningTeam == TEAM_ENEMY)
	{
		g_bGameOver = true;
	}
	
	return Plugin_Continue;
}

public void Timer_ConvertXP(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)) || !IsPlayerSurvivor(client, false))
		return;

	const float maxXp = 60000.0;
	UpdatePlayerXP(client, fmin(maxXp, GetPlayerCash(client)/3.0));
	SetPlayerCash(client, 0.0);
}

public Action OnBroadcastAudio(Event event, const char[] eventName, bool dontBroadcast)
{
	if (!RF2_IsEnabled())
		return Plugin_Continue;

	if (IsInFinalMap())
	{
		// mute the announcer's tank near hatch warnings because there is no bomb hatch in the final map.
		// Temporary solution, should instead add a way to disable this through the rf2_gamerules entity in maps. (TODO)
		char sound[PLATFORM_MAX_PATH];
		event.GetString("sound", sound, sizeof(sound));
		if (strcmp2(sound, "Announcer.MVM_Tank_Alert_Near_Hatch")
			|| strcmp2(sound, "Announcer.MVM_Tank_Alert_Halfway_Multiple")
			|| strcmp2(sound, "Announcer.MVM_Tank_Alert_Halfway"))
		{
			return Plugin_Handled;
		}
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
	
	StopLoopingSounds(client);
	if (g_bWaitingForPlayers && !IsFakeClient(client))
	{
		if (g_cvAlwaysSkipWait.BoolValue)
		{
			InsertServerCommand("mp_restartgame_immediate 1");
		}
		else
		{
			CreateTimer(1.0, Timer_SkipWaitHint, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	g_bPlayerIsDyingBoss[client] = false;
	if (!g_bRoundActive)
		return Plugin_Continue;
	
	int team = GetClientTeam(client);
	if (team == TEAM_ENEMY) // Remove loadout wearables for enemies
	{
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
	
	if (TF2_GetPlayerClass(client) == TFClass_Engineer && (!IsPlayerSurvivor(client) || !g_bGracePeriod))
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
		if (TFBot(client).Path)
		{
			if (TFBot(client).Path.IsValid())
			{
				TFBot(client).Path.Invalidate();
			}
		}
	}
	
	g_bPlayerViewingItemMenu[client] = false;
	g_flPlayerHeavyArmorPoints[client] = 100.0;
	CancelClientMenu(client, true);
	ClientCommand(client, "slot10");
	TF2Attrib_SetByName(client, "mod see enemy health", 1.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	TF2_AddCondition(client, TFCond_UberchargedHidden, 0.2);
	if (g_bGracePeriod && IsPlayerSurvivor(client) && !IsPlayerMinion(client) && TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		int medigun = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
		if (medigun != INVALID_ENT)
		{
			// Medic spawns with full ubercharge so that he can go scout for boxes without having to build his uber
			SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", 1.0);
		}
	}
	
	// Initialize our stats (health, speed, kb resist) the next frame to ensure it's correct
	RequestFrame(RF_InitStats, client);
	
	// Calculate max speed on a timer again to fix a... weird issue with players spawning in and being REALLY slow.
	// I don't know why it happens, but this fixes it, so, cool I guess?
	CreateTimer(0.1, Timer_FixSpeedIssue, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	SetEntityRenderMode(client, RENDER_NORMAL);
	UpdateWeaponMeters(client);
	return Plugin_Continue;
}

public void Timer_SkipWaitHint(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return;
	
	PrintHintText(client, "%t", "SkipWaitHint");
}

public void RF_InitStats(int client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (!IsPlayerMinion(client))
		{
			UpdateItemsForPlayer(client);
		}

		CalculatePlayerMaxHealth(client, false, true);
		CalculatePlayerMaxSpeed(client);
		CalculatePlayerMiscStats(client);
	}

	if (g_bRoundActive && IsEnemy(client))
	{
		SetEntityRenderColor(client, 255, 255, 255);
		int powerUpLevel = IsBoss(client) ? g_cvBossPowerupLevel.IntValue : g_cvEnemyPowerupLevel.IntValue;
		if (powerUpLevel > 0 && g_iEnemyLevel >= powerUpLevel 
			&& RandChanceInt(0, powerUpLevel*g_cvPowerupLevelChanceMult.IntValue, g_iEnemyLevel))
		{
			static char sound[PLATFORM_MAX_PATH];
			TFCond rune = GetRandomMannpowerRune_Enemies(client, sound, sizeof(sound));
			if (rune != view_as<TFCond>(-1))
			{
				TF2_AddCondition(client, rune);
				EmitSoundToAll(sound, client);
				switch (rune)
				{
					case TFCond_RuneRegen: 		SetEntityRenderColor(client, 0, 255, 0);
					case TFCond_RuneVampire: 	SetEntityRenderColor(client, 255, 0, 0);
					case TFCond_RuneHaste:		SetEntityRenderColor(client, 0, 255, 255);
					case TFCond_RuneResist:		SetEntityRenderColor(client, 0, 0, 255);
					case TFCond_RuneStrength:	SetEntityRenderColor(client, 150, 0, 255);
				}
			}
		}
	}
}

public void Timer_FixSpeedIssue(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)) || !IsPlayerAlive(client))
		return;
	
	CalculatePlayerMaxSpeed(client);
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!RF2_IsEnabled())
		return Plugin_Continue;
	
	Action action = Plugin_Continue;
	if (event.GetInt("playerpenetratecount") > 0)
	{
		// No Machina earrape
		event.SetInt("playerpenetratecount", 0);
		action = Plugin_Changed;
	}

	int deathFlags = event.GetInt("death_flags");
	if (deathFlags & TF_DEATHFLAG_DEADRINGER)
		return action;
	
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (g_bWaitingForPlayers)
	{
		CreateTimer(0.1, Timer_RespawnPlayerPreRound, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	StopLoopingSounds(victim);
	KillAnnotation(victim);
	if (IsValidEntity2(g_iPlayerRollerMine[victim]))
	{
		RemoveEntity(g_iPlayerRollerMine[victim]);
	}
	
	if (!g_bRoundActive)
		return action;
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int inflictor = event.GetInt("inflictor_entindex");
	int weaponIndex = event.GetInt("weapon_def_index");
	int weaponId = event.GetInt("weaponid");
	int damageType = event.GetInt("damagebits");
	int customkill = event.GetInt("customkill");
	int assister = GetClientOfUserId(event.GetInt("assister"));
	CritType critType = view_as<CritType>(event.GetInt("crit_type"));
	bool fakeKillMessage;
	
	// No dominations
	deathFlags &= ~(TF_DEATHFLAG_KILLERDOMINATION | TF_DEATHFLAG_ASSISTERDOMINATION | TF_DEATHFLAG_KILLERREVENGE | TF_DEATHFLAG_ASSISTERREVENGE);
	event.SetInt("death_flags", deathFlags);
	int victimTeam = GetClientTeam(victim);
	int itemProc = g_iEntLastHitItemProc[victim];
	if (attacker > 0)
	{
		switch (itemProc)
		{
			case ItemSoldier_WarPig: event.SetString("weapon", "obj_sentrygun3");
			
			case ItemDemo_ConjurersCowl, ItemMedic_WeatherMaster: event.SetString("weapon", "spellbook_lightning");
			
			case Item_Dangeresque, Item_SaxtonHat, ItemSniper_HolyHunter, ItemStrange_JackHat,
				ItemStrange_CroneDome, ItemSpy_Showstopper, ItemHeavy_GoneCommando, 
				ItemStrange_Botler, ItemStrange_HumanCannonball: event.SetString("weapon", "pumpkindeath");
			
			case ItemEngi_BrainiacHairpiece, ItemStrange_VirtualViewfinder, Item_RoBro, ItemMedic_MechaMedes: event.SetString("weapon", "merasmus_zap");
			
			case ItemStrange_LegendaryLid, ItemStrange_HandsomeDevil, Item_BedouinBandana: event.SetString("weapon", "kunai");
			
			case ItemScout_FedFedora: event.SetString("weapon", "headshot");
			
			case ItemPyro_PyromancerMask, Item_OldCrown: event.SetString("weapon", "spellbook_fireball");
			
			case ItemStrange_Dragonborn: event.SetString("weapon", "spellbook_teleport");
			
			case Item_WealthHat:
			{
				event.SetString("weapon", "firedeath");
				event.SetInt("customkill", TF_CUSTOM_GOLD_WRENCH);
				event.SetInt("death_flags", deathFlags|TF_DEATHFLAG_AUSTRALIUM);
				customkill = TF_CUSTOM_GOLD_WRENCH;
			}
		}
		
		if (attacker != victim)
		{
			DoItemKillEffects(attacker, inflictor, victim, damageType, critType, assister, customkill);
		}
	}
	
	RF2_NPC_Base npc = RF2_NPC_Base(inflictor);
	if (npc.IsValid())
	{
		int sourceTv = GetSourceTVBot();
		if (sourceTv != INVALID_ENT)
		{
			char displayName[64];
			GetEntityDisplayName(npc.index, displayName, sizeof(displayName));
			if (displayName[0])
			{
				event.SetInt("attacker", GetClientUserId(sourceTv));
				SetClientName(sourceTv, displayName);
				fakeKillMessage = true;
				action = Plugin_Stop;
			}
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
		SetVariantString("ParticleEffectStop");
		AcceptEntityInput(victim, "DispatchEffect");
		if (!IsFakeClient(victim))
		{
			SetClientName(victim, g_szPlayerOriginalName[victim]);
		}

		g_bPlayerIsDyingBoss[victim] = IsBoss(victim);
		if (!g_bGracePeriod)
		{
			float pos[3];
			float cashAmount;
			int size;
			GetEntPos(victim, pos);
			if (IsEnemy(victim))
			{
				g_iTotalEnemiesKilled++;
				cashAmount = Enemy(victim).CashAward;
				if (IsBoss(victim))
				{
					g_iTotalBossesKilled++;
					size = 3;
					EmitSoundToAll(SND_SENTRYBUSTER_BOOM, victim, _, SNDLEVEL_SCREAMING);
					TE_TFParticle("hightower_explosion", pos);
					RequestFrame(RF_DeleteRagdoll, victim);
				}
				
				bool isScavengerLord = strcmp2(Enemy(victim).GetInternalName(), "scavenger_lord");
				if (IsFakeClient(victim) && TFBot(victim).HasFlag(TFBOTFLAG_SCAVENGER)
					&& (!isScavengerLord || !g_bScavengerLordDroppedItems))
				{
					RF2_Item item = RF2_Item(INVALID_ENT);
					int prop = INVALID_ENT;
					float botPos[3];
					GetEntPos(victim, botPos, true);
					const int maxDroppedItems = 60;
					ArrayList itemList = GetPlayerItemList(victim, maxDroppedItems, true);
					if (!g_bScavengerLordDroppedItems)
						g_bScavengerLordDroppedItems = isScavengerLord;
						
					for (int i = 0; i < itemList.Length; i++)
					{
						item = RF2_Item(CreateEntityByName("rf2_item"));
						prop = CreateEntityByName("prop_physics_multiplayer");
						SetEntityModel2(prop, "models/items/ammopack_small.mdl");
						SetEntPropFloat(prop, Prop_Send, "m_flModelScale", 4.0);
						TeleportEntity(prop, botPos);
						DispatchKeyValueInt(prop, "nodamageforces", 1);
						DispatchKeyValueFloat(prop, "physdamagescale", 0.0);
						DispatchSpawn(prop);
						SDKHook(prop, SDKHook_VPhysicsUpdatePost, Hook_ItemPhysicsUpdate);
						SetEntityRenderMode(prop, RENDER_TRANSCOLOR);
						SetEntityRenderColor(prop, 0, 0, 0, 0);
						float vel[3];
						vel[0] = GetRandomFloat(-400.0, 400.0);
						vel[1] = GetRandomFloat(-400.0, 400.0);
						vel[2] = GetRandomFloat(-400.0, 400.0);
						ApplyAbsVelocityImpulse(prop, vel);
						item.Type = itemList.Get(i);
						botPos[2] += 15.0;
						item.Teleport(botPos);
						item.Spawn();
						ParentEntity(item.index, prop);
						botPos[2] -= 15.0;
						CreateTimer(10.0, Timer_ClearItemPhysics, EntIndexToEntRef(item.index), TIMER_FLAG_NO_MAPCHANGE);
					}
					
					delete itemList;
				}
			}
			
			cashAmount *= 1.0 + (float(RF2_GetEnemyLevel()-1) * g_cvEnemyCashDropScale.FloatValue);
			if (PlayerHasAnyRune(victim))
			{
				// Elites drop much more money
				cashAmount *= 3.0;
			}
			
			if (IsValidClient(attacker) && PlayerHasItem(attacker, Item_BanditsBoots))
			{
				cashAmount *= 1.0 + CalcItemMod(attacker, Item_BanditsBoots, 0);
			}
			
			cashAmount += GetPlayerCash(victim);
			pos[2] += 20.0;
			int cashEntity = SpawnCashDrop(cashAmount, pos, size);
			if (IsValidClient(attacker))
			{
				if (!g_bPlayerHauntedKeyDrop[attacker])
				{
					int max = g_cvHauntedKeyDropChanceMax.IntValue;
					if (max > 0 && RandChanceIntEx(attacker, 1, max, 1))
					{
						PrintCenterText(attacker, "%t", "HauntedKeyDrop", victim);
						g_bPlayerHauntedKeyDrop[attacker] = true;
						GiveItem(attacker, Item_HauntedKey, 1, true);
					}
				}

				if (damageType & DMG_CRUSH && IsBoss(victim))
				{
					TriggerAchievement(attacker, ACHIEVEMENT_GOOMBA);
				}
				
				if (weaponIndex == 416 && TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping) && IsBoss(victim))
				{
					TriggerAchievement(attacker, ACHIEVEMENT_MARKETGARDEN);
				}
				
				if (TF2_GetPlayerClass(attacker) == TFClass_Sniper)
				{
					if (weaponId == TF_WEAPON_SNIPERRIFLE
						|| weaponId == TF_WEAPON_SNIPERRIFLE_DECAP
						|| weaponId == TF_WEAPON_SNIPERRIFLE_CLASSIC)
					{
						PickupCash(attacker, cashEntity);
					}
				}
				
				TriggerAchievement(attacker, ACHIEVEMENT_KILL10K);
				TriggerAchievement(attacker, ACHIEVEMENT_KILL100K);
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

		if (Enemy(victim) != NULL_ENEMY)
		{
			int type = g_iPlayerEnemyType[victim];
			static char botName[64], buffer[64];
			strcopy(botName, sizeof(botName), g_szLoadedEnemies[type]);
			int entity = INVALID_ENT;
			while ((entity = FindEntityByClassname(entity, "rf2_logic_bot_death")) != INVALID_ENT)
			{
				RF2_Logic_BotDeath logic = RF2_Logic_BotDeath(entity);
				if (logic.GetProp(Prop_Data, "m_bDisabled"))
					continue;
					
				logic.GetBotName(buffer, sizeof(buffer));
				if (buffer[0] && strcmp2(buffer, botName))
				{
					logic.FireOutput("OnBotDeath", attacker);
				}
			}

			if (g_bPlayerIsTeleporterBoss[victim])
			{
				OutlineTeleporterBosses();
			}
		}
	}
	else if (IsPlayerSurvivor(victim) && !IsPlayerMinion(victim))
	{
		RoundState state = GameRules_GetRoundState();
		if (!g_bGracePeriod && state != RoundState_TeamWin)
		{
			CreateTimer(3.5, Timer_SurvivorDeath, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		if (!g_bGracePeriod && !GetRF2GameRules().DisableDeath && state != RoundState_TeamWin)
		{
			SaveSurvivorInventory(victim, g_iPlayerInventoryIndex[victim]);
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
			int alive = 0;
			int lastMan;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || i == victim)
					continue;
				
				if (IsPlayerAlive(i) && IsPlayerSurvivor(i) && !IsPlayerMinion(i))
				{
					alive++;
					lastMan = i;
				}
			}
			
			if (alive == 0 && !g_cvDebugDontEndGame.BoolValue && !g_bRoundEnding) // Game over, man!
			{
				GetRF2GameRules().FireOutput("OnAllSurvivorsDead");
				GameOver();
			}
			else if (alive == 1)
			{
				PrintCenterText(lastMan, "%t", "LastMan");
				EmitSoundToAll(SND_LASTMAN);
				SpeakResponseConcept_MVM(lastMan, "TLK_MVM_LAST_MAN_STANDING");
			}
			
			TriggerAchievement(victim, ACHIEVEMENT_DIE);
			TriggerAchievement(victim, ACHIEVEMENT_DIE100);
		}
		else if (!GetRF2GameRules().DisableDeath && state != RoundState_TeamWin)
		{
			float pos[3];
			GetEntPos(victim, pos);
			DataPack pack;
			CreateDataTimer(0.3, Timer_SuicideTeleport, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(GetClientUserId(victim));
			pack.WriteFloat(pos[0]);
			pack.WriteFloat(pos[1]);
			pack.WriteFloat(pos[2]);
		}
	}
	
	bool wasSurvivor = IsPlayerSurvivor(victim, false);
	RefreshClient(victim);
	if (wasSurvivor)
	{
		// Recalculate our item sharing for other players
		CalculateSurvivorItemShare();
	}
	
	if (fakeKillMessage)
	{
		Event newEvent = CreateEvent("player_death", true);
		newEvent.SetInt("attacker", event.GetInt("attacker"));
		newEvent.SetInt("userid", event.GetInt("userid"));
		CreateTimer(0.2, Timer_FakeKillMessage, newEvent, TIMER_FLAG_NO_MAPCHANGE);
	}

	return action;
}

public void Hook_ItemPhysicsUpdate(int entity)
{
	// never rotate so the item doesn't sink into the ground
	CBaseEntity(entity).SetLocalAngles({0.0, 0.0, 0.0});
}

public void Timer_ClearItemPhysics(Handle timer, int entity)
{
	RF2_Item item = RF2_Item(EntRefToEntIndex(entity));
	if (item.IsValid())
	{
		int moveparent = GetEntPropEnt(entity, Prop_Send, "moveparent");
		if (IsValidEntity2(moveparent))
		{
			item.AcceptInput("ClearParent");
			char classname[64];
			GetEntityClassname(moveparent, classname, sizeof(classname));
			if (StrContains(classname, "prop_physics") == 0)
			{
				RemoveEntity(moveparent);
			}
		}
	}
}

public void Timer_FakeKillMessage(Handle timer, Event event)
{
	event.Fire();
}

public void Timer_ReloadPluginNoMapChange(Handle timer)
{
	ReloadPlugin(false);
}

public void Timer_RespawnPlayerPreRound(Handle timer, int client)
{
	if (!g_bWaitingForPlayers || (client = GetClientOfUserId(client)) <= 0)
		return;
	
	TF2_RespawnPlayer(client);
}

public void Timer_SurvivorDeath(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || g_bGameWon || g_bGameOver)
		return;
	
	if (GetRF2GameRules().DisableDeath)
	{
		TF2_RespawnPlayer(client);
	}
	else if (GetCookieBool(client, g_coSpecOnDeath))
	{
		ChangeClientTeam(client, 1);
	}
	else if (!IsSingleplayer())
	{
		g_bPlayerSpawningAsMinion[client] = true;
		CreateTimer(0.5, Timer_MinionSpawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		PrintCenterText(client, "%t", "MinionSpawn");
	}
}

public void Timer_MinionSpawn(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return;
	
	g_bPlayerSpawningAsMinion[client] = false;
	if (IsPlayerAlive(client) || GetClientTeam(client) != TEAM_SURVIVOR)
		return;

	if (!GetRF2GameRules().AllowMinionSpawning)
	{
		CreateTimer(1.0, Timer_MinionSpawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		PrintKeyHintText(client, "Minion spawning has been disabled by the map.");
		return;
	}

	SpawnMinion(client);
}

public void Timer_KillFog(Handle timer, int fog)
{
	if (EntRefToEntIndex(fog) == INVALID_ENT)
		return;

	AcceptEntityInput(fog, "TurnOff");
	RemoveEntity(fog);
}

public void Timer_RestorePlayerFog(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());

	if (client == 0)
		return;

	int fog = EntRefToEntIndex(pack.ReadCell());
	if (fog != INVALID_ENT)
	{
		SetEntPropEnt(client, Prop_Data, "m_hCtrl", fog);
	}

	return;
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
			RemoveEntity(entity);
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
			if (!IsValidEntity2(entity) || entity == medic)
				continue;
			
			if (!IsCombatChar(entity) || IsValidClient(entity) && !IsPlayerAlive(entity))
				continue;
			
			if (GetEntTeam(entity) == team)
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

	if (PlayerHasItem(medic, ItemMedic_MechaMedes))
	{
		CreateTimer(GetItemMod(ItemMedic_MechaMedes, 0), Timer_MedicTeslaCoil, GetClientUserId(medic), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action Timer_MedicTeslaCoil(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return Plugin_Stop;

	int medigun = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
	if (medigun == INVALID_ENT || !GetEntProp(medigun, Prop_Send, "m_bChargeRelease")
		&& !TF2_IsPlayerInCondition(client, TFCond_UberBulletResist)
		&& !TF2_IsPlayerInCondition(client, TFCond_UberBlastResist)
		&& !TF2_IsPlayerInCondition(client, TFCond_UberFireResist))
		return Plugin_Stop;

	// only zap if medigun is out
	if (medigun != GetActiveWeapon(client))
		return Plugin_Continue;

	bool vaccinator = (TF2Attrib_HookValueInt(0, "set_charge_type", medigun) == 3);
	float damage = GetItemMod(ItemMedic_MechaMedes, 1) + CalcItemMod(client, ItemMedic_MechaMedes, 2, -1);
	float range = GetItemMod(ItemMedic_MechaMedes, 3) + CalcItemMod(client, ItemMedic_MechaMedes, 4, -1);
	if (vaccinator)
		damage *= 0.25;

	ArrayList allies = new ArrayList();
	allies.Push(client);
	// Heal target also gets the tesla effect
	int healTarget = GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
	if (IsValidClient(healTarget))
		allies.Push(healTarget);

	for (int i = 0; i < allies.Length; i++)
	{
		int ally = allies.Get(i);
		float pos[3];
		GetEntPos(ally, pos, true);
		ArrayList enemies = GetNearestCombatChars(pos, GetItemModInt(ItemMedic_MechaMedes, 5), 0.0, range, GetEntTeam(ally), true);
		for (int a = 0; a < enemies.Length; a++)
		{
			int enemy = enemies.Get(a);
			float enemyPos[3];
			GetEntPos(enemy, enemyPos, true);
			EmitGameSoundToAll("Weapon_BarretsArm.Zap", enemy);
			TE_SetupBeamPoints(pos, enemyPos, g_iBeamModel, 0, 0, 0, 0.5, 8.0, 8.0, 0, 10.0, {255, 255, 100, 200}, 20);
			TE_SendToAll();
			RF_TakeDamage(enemy, ally, ally, damage, DMG_SHOCK|DMG_PREVENT_PHYSICS_FORCE, ItemMedic_MechaMedes);
		}

		delete enemies;
	}

	delete allies;
	return Plugin_Continue;
}

public Action OnPlayerDropObject(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bRoundActive)
		return Plugin_Continue;

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
	
	if (TF2_GetObjectType2(building) == TFObject_Dispenser)
	{
		RF2_DispenserShield shield = GetDispenserShield(building);
		if (shield.IsValid())
		{
			shield.UpdateBatteryText();
		}
	}
	
	CalculatePlayerMaxHealth(client, false);
	return Plugin_Continue;
}

public void RF_DispenserQuickBuild(int building)
{
	SDK_DoQuickBuild(building);
}

static bool g_bTeleSoundPlayed[MAX_EDICTS];
public Action OnPlayerBuiltObject(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bRoundActive)
		return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	int building = event.GetInt("index");
	TFObjectType type = TF2_GetObjectType2(building);
	bool carryDeploy = asBool(GetEntProp(building, Prop_Send, "m_bCarryDeploy"));

	if (IsFakeClient(client) && g_hTFBotEngineerBuildings[client])
	{
		if (g_hTFBotEngineerBuildings[client].FindValue(EntIndexToEntRef(building)) == -1)
		{
			g_hTFBotEngineerBuildings[client].Push(EntIndexToEntRef(building));
		}
	}

	if (!carryDeploy && (IsPlayerMinion(client) || GetPlayerBuildingCount(client, TFObject_Sentry, false) > 1))
	{
		SetEntPropFloat(building, Prop_Send, "m_flModelScale", 0.6);
		if (type== TFObject_Sentry)
		{
			if (!IsPlayerMinion(client))
			{
				SetEntProp(building, Prop_Send, "m_iObjectMode", TFObjectMode_Disposable); // forces main sentry to always show in building HUD
			}
			
			SetEntProp(building, Prop_Send, "m_bMiniBuilding", true);
			g_hPlayerExtraSentryList[client].Push(building);
			g_bDisposableSentry[building] = true;
		}
		
		if (GetPlayerBuildingCount(client, TFObject_Sentry, false) >= CalcItemModInt(client, ItemEngi_HeadOfDefense, 0))
		{
			SetSentryBuildState(client, false);
		}
		
		if (!carryDeploy)
		{
			int maxHealth = CalculateBuildingMaxHealth(client, building);
			SetVariantInt(RoundToCeil(float(maxHealth)*0.5));
			AcceptEntityInput(building, "AddHealth");
		}
	}
	else if (type == TFObject_Dispenser && IsPlayerSurvivor(client) && !IsPlayerMinion(client))
	{
		RF2_DispenserShield shield = GetDispenserShield(building);
		if (!shield.IsValid())
		{
			if (g_hHookOnWrenchHit)
			{
				g_hHookOnWrenchHit.HookEntity(Hook_Pre, building, DHook_OnWrenchHitDispenser);
			}
			
			shield = CreateDispenserShield(GetEntTeam(client), building);
			// shield will start inactive. Wait until the dispenser finishes building.
			CreateTimer(0.1, Timer_DispenserShieldThink, EntIndexToEntRef(shield.index), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if (type == TFObject_Teleporter)
	{
		if (GetClientTeam(client) == TEAM_ENEMY)
		{
			if (g_flTeleporterNextSpawnTime[building] < 0.0)
				g_flTeleporterNextSpawnTime[building] = GetTickedTime()+(36.0/float(GetEntProp(building, Prop_Send, "m_iUpgradeLevel")));
		
			g_bTeleSoundPlayed[building] = false;
			RequestFrame(RF_TeleporterThink, EntIndexToEntRef(building));
		}
	}
	
	if (!carryDeploy && (GameRules_GetProp("m_bInSetup") || GetRF2GameRules().AllowQuickBuild))
	{
		SDK_DoQuickBuild(building, true);
	}
	
	if (GetPlayerBuildingCount(client, TFObject_Sentry) >= 10)
	{
		TriggerAchievement(client, ACHIEVEMENT_SENTRIES);
	}
	
	CalculatePlayerMaxHealth(client, false);
	return Plugin_Continue;
}

public Action OnPlayerUpgradeObject(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bRoundActive)
		return Plugin_Continue;

	int building = event.GetInt("index");
	int builder = GetEntPropEnt(building, Prop_Send, "m_hBuilder");
	if (IsValidClient(builder) && IsPlayerAlive(builder))
	{
		// delay by one frame to override max health set by upgrading
		RequestFrame(RF_DelayMaxHealthUpdate, GetClientUserId(builder));
	}

	return Plugin_Continue;
}

public void RF_DelayMaxHealthUpdate(int client)
{
	client = GetClientOfUserId(client);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		CalculatePlayerMaxHealth(client, false);
	}
}

public Action Timer_DispenserShieldThink(Handle timer, int entity)
{
	RF2_DispenserShield shield = RF2_DispenserShield(EntRefToEntIndex(entity));
	if (!shield.IsValid() || !IsValidEntity2(shield.Dispenser))
	{
		if (shield.IsValid())
			RemoveEntity(shield.index);
		
		return Plugin_Stop;
	}
	
	bool active = (shield.Battery > 0 && !shield.UserDisabled
		&& !GetEntProp(shield.Dispenser, Prop_Send, "m_bBuilding")
		&& !GetEntProp(shield.Dispenser, Prop_Send, "m_bCarried")
		&& !GetEntProp(shield.Dispenser, Prop_Send, "m_bHasSapper"));
	
	// make sure we have the correct collision state as it seems to be finicky sometimes
	if (active && shield.Enabled)
	{
		shield.SetProp(Prop_Send, "m_nSolidType", SOLID_VPHYSICS);
		SetEntityCollisionGroup(shield.index, TFCOLLISION_GROUP_COMBATOBJECT);
	}
	else
	{
		shield.SetProp(Prop_Send, "m_nSolidType", SOLID_NONE);
		SetEntityCollisionGroup(shield.index, 0);
	}

	if (!shield.Enabled && !shield.UserDisabled)
	{
		if (active)
		{
			shield.Toggle(true, true);
		}
	}
	else if (!active && !shield.UserDisabled)
	{
		shield.Toggle(false, true);
	}
	else
	{
		if (GetGameTime() > shield.NextModelUpdateTime)
		{
			int dispLevel = GetEntProp(shield.Dispenser, Prop_Send, "m_iHighestUpgradeLevel");
			if (dispLevel != shield.Level && dispLevel > shield.Level)
			{
				shield.Level = dispLevel;
				switch (dispLevel)
				{
					case 1:
					{
						shield.SetModel(MODEL_DISPENSER_SHIELD_L1);
					}
					case 2:
					{
						shield.SetModel(MODEL_DISPENSER_SHIELD_L2);
						EmitGameSoundToAll("WeaponMedigun_Vaccinator.Charged_tier_03", shield.index);
					}
					case 3:
					{
						shield.SetModel(MODEL_DISPENSER_SHIELD);
						EmitGameSoundToAll("WeaponMedigun_Vaccinator.Charged_tier_04", shield.index);
					}
				}
			}
			
			shield.NextModelUpdateTime = GetGameTime()+0.25;
		}
		
		if (!g_bGracePeriod && GetGameTime() > shield.NextBatteryDrainTime)
		{
			if (!shield.UserDisabled)
			{
				int battery = shield.Battery;
				shield.Battery = imax(0, battery-1);
				shield.UpdateBatteryText();
			}
			
			shield.NextBatteryDrainTime = GetGameTime()+0.25;
		}
		
		bool carried = asBool(GetEntProp(shield.Dispenser, Prop_Send, "m_bCarried"));
		if (carried || !shield.Enabled)
		{
			// the collision of the shield seems to always reset to solid even when disabled, so I'm doing it this way to make sure it doesn't
			shield.SetProp(Prop_Send, "m_nSolidType", SOLID_NONE);
			SetEntityCollisionGroup(shield.index, 0);
		}
		
		if (carried)
		{
			shield.UpdateBatteryText();
		}
	}
	
	return Plugin_Continue;
}

public void RF_TeleporterThink(int building)
{
	if (g_bGameWon || (building = EntRefToEntIndex(building)) == INVALID_ENT || GetEntProp(building, Prop_Send, "m_bCarried"))
		return;
	
	if (GetEntProp(building, Prop_Send, "m_bBuilding") || GetEntProp(building, Prop_Send, "m_bHasSapper"))
	{
		RequestFrame(RF_TeleporterThink, EntIndexToEntRef(building));
		return;
	}
	
	if (!g_bTeleSoundPlayed[building])
	{
		EmitSoundToAll(SND_TELEPORTER_BLU_START);
		float pos[3];
		GetEntPos(building, pos);
		SpawnInfoParticle("teleporter_mvm_bot_persist", pos, _, building);
		g_bTeleSoundPlayed[building] = true;
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
		float bossChance = fmin(subIncrement+g_flBossSpawnChanceBonus, max);
		
		for (int i = 0; i < enemies.Length; i++)
		{
			client = enemies.Get(i);
			bool enemiesAvailable = GetRandomEnemy() != -1;
			bool bossesAvailable = GetRandomBoss() != -1;
			if (!enemiesAvailable && !bossesAvailable)
			{
				break;
			}
			
			if (bossesAvailable && 
				(RF2_GetSubDifficulty() >= SubDifficulty_Impossible || IsInFinalMap()) 
				&& RandChanceFloat(0.0, max, bossChance))
			{
				g_iPlayerBossSpawnType[client] = GetRandomBoss();
			}
			else if (enemiesAvailable)
			{
				g_iPlayerEnemySpawnType[client] = GetRandomEnemy();
			}
			else
			{
				continue;
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

public void Timer_SpawnEnemyTeleporter(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	if ((client = GetClientOfUserId(client)) == 0)
		return;

	int teleporter = EntRefToEntIndex(pack.ReadCell());
	if (teleporter == INVALID_ENT)
	{
		g_iPlayerEnemySpawnType[client] = -1;
		g_iPlayerBossSpawnType[client] = -1;
		return;
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
	event.SetInt("amount", RoundToFloor(float(amount) * GetPlayerHealthMult(client)));
	return Plugin_Changed;
}

public Action OnNpcHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (event.GetBool("crit"))
	{
		int npc = event.GetInt("entindex");
		int attacker = GetClientOfUserId(event.GetInt("attacker_player"));
		if (IsValidClient(attacker))
		{
			int clients[MAXPLAYERS];
			clients[0] = attacker;
			float pos[3];
			GetEntPos(npc, pos, true);
			TE_TFParticle("crit_text", pos, _, _, _, _, _, _, clients, 1);
			EmitGameSoundToClient(attacker, GSND_CRIT);
		}
	}
	
	return Plugin_Continue;
}

static float g_flPlayerNextCritSoundTime[MAXPLAYERS];
public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (event.GetBool("crit") || event.GetBool("minicrit"))
	{
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if (IsValidClient(attacker))
		{
			if (GetTickedTime() < g_flPlayerNextCritSoundTime[attacker])
			{
				// prevent earrape from crit sounds on bots
				event.SetBool("crit", false);
				event.SetBool("minicrit", false);
				event.SetInt("bonuseffect", -1);
				return Plugin_Changed;
			}
			
			g_flPlayerNextCritSoundTime[attacker] = GetTickedTime()+0.3;
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
	
	// Begin our enemy spawning
	CreateTimer(5.0, Timer_EnemySpawnWave, _, TIMER_FLAG_NO_MAPCHANGE);
	g_flBusterSpawnTime = g_cvBusterSpawnInterval.FloatValue;
	CreateTimer(1.0, Timer_BusterSpawnWave, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	Call_StartForward(g_fwGracePeriodEnded);
	Call_Finish();
	GetRF2GameRules().FireOutput("OnGracePeriodEnd");
	if (!g_bTankBossMode)
	{
		RF2_PrintToChatAll("%t", "GracePeriodEnded");
	}
	else
	{
		BeginTankDestructionMode();
	}
	
	if (Enemy.FindByInternalName("scavenger_lord") != NULL_ENEMY)
	{
		int chanceMax = g_cvScavengerLordSpawnLevel.IntValue * 5;
		if (RandChanceInt(1, chanceMax, g_iEnemyLevel))
		{
			CreateTimer(GetRandomFloat(30.0, 50.0), Timer_SpawnScavengerLord, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	int entity = MaxClients+1;
	char name[128];
	// We have to do this crap or else bots will misbehave, thinking it's still setup time. They won't attack players and will randomly taunt.
	while ((entity = FindEntityByClassname(entity, "team_round_timer")) != INVALID_ENT)
	{
		// make sure it doesn't have a name, to avoid messing with map logic (ones starting with zz_ are created by the game)
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if (name[0] && StrContains(name, "zz_") != 0)
			continue;
		
		if (GetEntProp(entity, Prop_Send, "m_nState") == 0)
		{
			UnhookSingleEntityOutput(entity, "team_round_timer", Output_GraceTimerFinished);
			SetVariantFloat(1.0);
			AcceptEntityInput(entity, "SetSetupTime");
			CreateTimer(2.0, Timer_DeleteEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerSurvivor(i, false))
			continue;
		
		if (!IsPlayerAlive(i))
		{
			TF2_RespawnPlayer(i); // respawn this guy if they're dead for some reason
		}
		
		if (PlayerHasItem(i, Item_HauntedHat))
		{
			ArrayList buffs = new ArrayList();
			buffs.Push(TFCond_CritOnFirstBlood);
			
			// make crits extra rare
			for (int a = 1; a <= 2; a++)
			{
				buffs.Push(TFCond_MegaHeal);
				buffs.Push(TFCond_DefenseBuffed);
				buffs.Push(TFCond_BalloonHead);
				buffs.Push(TFCond_RegenBuffed);
				if (!PlayerHasItem(i, Item_MisfortuneFedora))
				{
					buffs.Push(TFCond_Buffed);
				}
			}
			
			TF2_AddCondition(i, buffs.Get(GetRandomInt(0, buffs.Length-1)), CalcItemMod(i, Item_HauntedHat, 0));
			delete buffs;
			
			ArrayList debuffs = new ArrayList();
			debuffs.Push(TFCond_Dazed);
			debuffs.Push(TFCond_Bleeding);
			debuffs.Push(TFCond_MarkedForDeath);
			TFCond debuff = debuffs.Get(GetRandomInt(0, debuffs.Length-1));
			delete debuffs;
			if (debuff == TFCond_Dazed)
			{
				TF2_StunPlayer(i, CalcItemMod(i, Item_HauntedHat, 1), 0.35, TF_STUNFLAG_SLOWDOWN, i);
			}
			else if (debuff == TFCond_Bleeding)
			{
				TF2_MakeBleed(i, i, CalcItemMod(i, Item_HauntedHat, 1));
			}
			else
			{
				TF2_AddCondition(i, debuff, CalcItemMod(i, Item_HauntedHat, 1));
			}
		}
		
		if (PlayerHasItem(i, ItemEngi_BrainiacHairpiece) && CanUseCollectorItem(i, ItemEngi_BrainiacHairpiece))
		{
			// remove powerup canteen if we already have it equipped to prevent conflict
			int powerBottle = MaxClients+1;
			while ((powerBottle = FindEntityByClassname(powerBottle, "tf_powerup_bottle")) != INVALID_ENT)
			{
				if (GetEntPropEnt(powerBottle, Prop_Send, "m_hOwnerEntity") == i)
				{
					TF2_RemoveWearable(i, powerBottle);
				}
			}
			
			powerBottle = CreateWearable(i, "tf_powerup_bottle", 489, _, true);
			g_bDontRemoveWearable[powerBottle] = true;
			int charges = CalcItemModInt(i, ItemEngi_BrainiacHairpiece, 4);
			SetEntProp(powerBottle, Prop_Send, "m_usNumCharges", charges);
			TF2Attrib_SetByName(powerBottle, "powerup max charges", float(charges));
			TF2Attrib_SetByName(powerBottle, "building instant upgrade", 1.0);
			g_iPlayerPowerupBottle[i] = powerBottle;
		}
	}
}

public Action UserMessageHook_SayText2(UserMsg msg, BfRead bf, const int[] clients, int numClients, bool reliable, bool init)
{
	char message[128];
	bf.ReadString(message, sizeof(message));
	bf.ReadString(message, sizeof(message));
	if (StrContains(message, "Name_Change") != -1) // Hide name change messages, they really get spammy with bots.
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void Timer_SpawnScavengerLord(Handle timer)
{
	int client = INVALID_ENT;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_ENEMY && !IsPlayerAlive(i))
		{
			client = i;
			break;
		}
	}
	
	if (client == INVALID_ENT)
	{
		// wait for a dead slot
		CreateTimer(0.2, Timer_SpawnScavengerLord, _, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	
	Enemy scavengerLord = Enemy.FindByInternalName("scavenger_lord");
	if (scavengerLord == NULL_ENEMY)
		return;
	
	float pos[3];
	GetWorldCenter(pos);
	if (SpawnBoss(client, scavengerLord.Index, pos, false))
	{
		if (g_iEnemyLevel < g_cvScavengerLordSpawnLevel.IntValue*10)
		{
			PrintCenterTextAll("%t", "ScavengerLordWarning");
			EmitSoundToAll(SND_SCAVENGER_LORD_WARNING);
		}
	}
	else
	{
		// spawn failed, try again in a bit
		CreateTimer(0.5, Timer_SpawnScavengerLord, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

int g_iEnemySpawnPoints[MAXPLAYERS];
public void Timer_EnemySpawnWave(Handle timer)
{
	if (!RF2_IsEnabled() || !g_bRoundActive || g_iEnemyCount <= 0 || IsStageCleared())
		return;
	
	int survivorCount = RF2_GetSurvivorCount();
	float duration = g_cvEnemyBaseSpawnWaveTime.FloatValue - 2.0 * float(survivorCount-1);
	const int acceleratedLevels = 12;
	duration -= float(imin(RF2_GetEnemyLevel()-1, acceleratedLevels)) * 0.6;
	duration -= float(imax(RF2_GetEnemyLevel()-1-acceleratedLevels, 0)) * 0.2;
	
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
	
	if (g_flMaxSpawnWaveTime > 0.0)
	{
		duration = fmin(duration, g_flMaxSpawnWaveTime);
	}

	duration = fmax(duration, g_cvEnemyMinSpawnWaveTime.FloatValue);
	CreateTimer(duration, Timer_EnemySpawnWave, _, TIMER_FLAG_NO_MAPCHANGE);
	if (g_cvDebugDisableEnemySpawning.BoolValue || WaitingForPlayerRejoin(true) || !GetRF2GameRules().AllowEnemySpawning)
		return;
	
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
		for (int i = 1; i < MAXPLAYERS; i++)
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
	const float max = 250.0;
	float bossChance = fmin(subIncrement+g_flBossSpawnChanceBonus, max);
	
	respawnArray.SortCustom(SortEnemySpawnArray);
	if (respawnArray.Length > spawnCount)
		respawnArray.Resize(spawnCount);
	
	for (int i = 0; i < respawnArray.Length; i++)
	{
		client = respawnArray.Get(i);
		bool enemiesAvailable = GetRandomEnemy() != -1;
		bool bossesAvailable = GetRandomBoss() != -1;
		if (!enemiesAvailable && !bossesAvailable)
		{
			break;
		}
		
		if (bossesAvailable && 
			(RF2_GetSubDifficulty() >= SubDifficulty_Impossible || IsInFinalMap()) 
			&& RandChanceFloat(0.0, max, bossChance))
		{
			g_iPlayerBossSpawnType[client] = GetRandomBoss();
		}
		else if (enemiesAvailable)
		{
			g_iPlayerEnemySpawnType[client] = GetRandomEnemy();
		}
		else
		{
			continue;
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

public void Timer_SetNextStage(Handle timer, int stage)
{
	g_iCurrentStage = stage;
	if (g_iCurrentStage == 1 && !g_bEnteringFinalArea)
	{
		g_iLoopCount++;
	}
	
	// rf2_setnextmap or Tree of Fate
	if (g_szForcedMap[0] && !g_bEnteringFinalArea)
	{
		char reason[64];
		if (g_szMapForcerName[0])
		{
			FormatEx(reason, sizeof(reason), "%s forced the next map", g_szMapForcerName);
			g_szMapForcerName = "";
		}
		else
		{
			reason = "Tree of Fate";
		}
		
		g_bMapChanging = true;
		ForceChangeLevel(g_szForcedMap, reason);
	}
	else if (g_bEnteringUnderworld)
	{
		ForceChangeLevel(g_szUnderworldMap, "Entering the Underworld");
	}
	else if (g_bEnteringFinalArea)
	{
		ForceChangeLevel(g_szFinalMap, "Entering the final area");
	}
	else
	{
		SetNextStage(stage);
	}
}

public void Timer_EnterUnderworldEffect(Handle timer)
{
	float pos[3];
	GetWorldCenter(pos);
	UTIL_ScreenShake(pos, 10.0, 10.0, 10.0, 9999999.0, SHAKE_START, true);
	EmitSoundToAll(SND_ENTER_HELL);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			UTIL_ScreenFade(i, {255, 255, 255, 255}, 2.5, 10.0, FFADE_PURGE|FFADE_OUT);
		}
	}
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
	static char miscText[512];
	SetHudTextParams(-1.0, MAIN_HUD_Y, 0.15, g_iMainHudR, g_iMainHudG, g_iMainHudB, 255);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		if (g_bGameOver || g_bGameWon)
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
			
			static int color[4];
			static char text[128];
			text = "";
			static float victoryMessageTime;
			if (g_bGameOver)
			{
				text = "GAME OVER";
				color[0] = 255;
				color[1] = 100;
				color[2] = 100;
				color[3] = 255;
			}
			else if (IsInUnderworld())
			{
				text = "Fate Unknown...";
				color[0] = 100;
				color[1] = 100;
				color[2] = 255;
				color[3] = 255;
			}
			else
			{
				victoryMessageTime += 0.1;
				if (victoryMessageTime < 14.0)
				{
					text = "\n\n\n\n\n...and so they left, still with a thirst for bolts and blood.";
				}
				else
				{
					text = "Victory";
					if (IsPlayerSurvivor(i))
					{
						TriggerAchievement(i, ACHIEVEMENT_BEATGAME);
						if (RF2_GetDifficulty() >= DIFFICULTY_STEEL)
						{
							TriggerAchievement(i, ACHIEVEMENT_BEATGAMESTEEL);
						}
						
						if (RF2_GetDifficulty() >= DIFFICULTY_TITANIUM)
						{
							TriggerAchievement(i, ACHIEVEMENT_BEATGAMETITANIUM);
						}
					}
				}
				
				color[0] = 50;
				color[1] = 255;
				color[2] = 50;
				color[3] = 255;
			}
			
			SetHudTextParams(-1.0, -1.3, 0.15, color[0], color[1], color[2], color[3]);
			if (!g_bGameOver && victoryMessageTime > 0.0 && victoryMessageTime < 7.0)
			{
				ShowSyncHudText(i, g_hMainHudSync, text);
			}
			else
			{
				ShowSyncHudText(i, g_hMainHudSync,
					"\n\n\n\n%s\n\nEnemies slain: %i\nBosses slain: %i\nStages completed: %i\nItems found: %i\nTanks destroyed: %i\nTOTAL SCORE: %i points\nRANK: %s",
					text, g_iTotalEnemiesKilled, g_iTotalBossesKilled, g_iStagesCompleted, g_iTotalItemsFound, g_iTotalTanksKilled, score, rank);
			}
			
			continue;
		}
		
		hudSeconds = RoundFloat((g_flSecondsPassed) - (float(g_iMinutesPassed) * 60.0));
		strangeItem = GetPlayerEquipmentItem(i);
		if (strangeItem > Item_Null && !IsPlayerMinion(i))
		{
			GetItemName(strangeItem, strangeItemInfo, sizeof(strangeItemInfo));
			
			if (g_iPlayerEquipmentItemCharges[i] > 0)
			{
				static char buttonText[32];
				if (HoldingReloadUseWeapon(i))
				{
					buttonText = "TAB+RELOAD (TAB+R)";
				}
				else
				{
					buttonText = "RELOAD (R)";
				}
				
				if (g_flPlayerEquipmentItemCooldown[i] > 0.0) // multi-stack recharge?
				{
					Format(strangeItemInfo, sizeof(strangeItemInfo), "%s[%i] READY! %s [%.1f]",
						strangeItemInfo, g_iPlayerEquipmentItemCharges[i], buttonText, g_flPlayerEquipmentItemCooldown[i]);
				}
				else
				{
					Format(strangeItemInfo, sizeof(strangeItemInfo), "%s[%i] READY! %s",
						strangeItemInfo, g_iPlayerEquipmentItemCharges[i], buttonText);
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
		int r, g, b;
		r = 255;
		g = 255;
		b = 255;
		static char difficultyName[32];
		GetDifficultyName(RF2_GetDifficulty(), difficultyName, sizeof(difficultyName), false);
		if (IsPlayerSurvivor(i))
		{
			if (!g_bGracePeriod)
			{
				bool tanksLeft = g_iTanksKilledObjective < g_iTankKillRequirement;
				if (IsValidEntity2(g_iPlayerLastAttackedTank[i]))
				{
					RF2_TankBoss tank = RF2_TankBoss(g_iPlayerLastAttackedTank[i]);
					if (tank.IsValid())
					{
						static char name[32];
						name = tank.Type != TankType_Normal ? tank.Type != TankType_Badass ? "Super Badass Tank" : "Badass Tank" : "Tank";
						FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), 
							g_bTankBossMode && tanksLeft ? "Tanks Destroyed: %i/%i\n%s Health: %i/%i" : "%s Health: %i/%i",
							g_iTanksKilledObjective, g_iTankKillRequirement, name, tank.Health, tank.MaxHealth);
					}
				}
				else if (g_bTankBossMode)
				{
					g_iPlayerLastAttackedTank[i] = INVALID_ENT;
					if (!tanksLeft)
					{
						g_szObjectiveHud[i] = "";
					}
					else
					{
						FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "Tanks Destroyed: %i/%i",
							g_iTanksKilledObjective, g_iTankKillRequirement);
					}
				}
			}
			
			if (HasJetpack(i))
			{
				Format(miscText, sizeof(miscText), "%sJetpack Time: %.1f\n", miscText, FloatAbs(g_flPlayerJetpackEndTime[i]-GetTickedTime()));
			}
			
			if (PlayerHasItem(i, Item_MetalHelmet))
			{
				int maxShieldHealth = CalcItemModInt(i, Item_MetalHelmet, 2);
				if (g_iPlayerShieldHealth[i] > 0)
				{
					Format(miscText, sizeof(miscText), "%sShield Health: %i/%i\n", miscText, g_iPlayerShieldHealth[i], maxShieldHealth);
				}
				else
				{
					Format(miscText, sizeof(miscText), "%s***SHIELD DOWN*** %.1f\n", miscText,
						FloatAbs(g_flPlayerShieldRegenTime[i]-GetGameTime()));
				}
			}

			if (PlayerHasItem(i, Item_PointAndShoot) && g_iPlayerFireRateStacks[i] > 0)
			{
				Format(miscText, sizeof(miscText), "%sAttack Buff Stacks: %i/%i\n", miscText,
					g_iPlayerFireRateStacks[i], CalcItemModInt(i, Item_PointAndShoot, 0));
			}

			bool hardHat = PlayerHasItem(i, Item_ApertureHat);
			bool horace = PlayerHasItem(i, Item_Horace);
			if (hardHat || horace)
			{
				if (horace)
				{
					float time = fmax(0.0, g_flPlayerLastBlockTime[i]+GetItemMod(Item_Horace, 0)-GetTickedTime());
					if (time > 0.0)
					{
						Format(miscText, sizeof(miscText),
							hardHat ? "%s***DAMAGE BLOCK DOWN*** %.1f ||| " : "%s***DAMAGE BLOCK DOWN*** %.1f\n", miscText, time);
					}
					else
					{
						Format(miscText, sizeof(miscText),
							hardHat ? "%sDamage Block Active ||| " : "%sDamage Block Active\n", miscText);
					}
				}

				if (hardHat)
				{
					float time = fmax(0.0, g_flPlayerHardHatLastResistTime[i]+GetItemMod(Item_ApertureHat, 1)-GetTickedTime());
					if (time > 0.0)
					{
						Format(miscText, sizeof(miscText), "%s***RESISTANCE DOWN*** %.1f\n", miscText, time);
					}
					else
					{
						Format(miscText, sizeof(miscText), "%sHard Hat Resist: %.0f%s\n", miscText,
							(1.0-CalcItemMod_Reciprocal(i, Item_ApertureHat, 0))*100.0, "%%");
					}
				}
			}
			
			/*
			if (PlayerHasItem(i, Item_Hachimaki) && g_flPlayerDelayedHealTime[i] > 0.0)
			{
				Format(miscText, sizeof(miscText), "%sDelayed Heal: %.1f\n", 
					miscText, fmax(0.0, g_flPlayerDelayedHealTime[i]-GetTickedTime()));
			}
			*/
			
			if (PlayerHasItem(i, Item_LilBitey))
			{
				float time = fmax(0.0, g_flPlayerLifestealTime[i]-GetTickedTime());
				if (time > 0.0)
				{
					Format(miscText, sizeof(miscText), "%sLifesteal Pulse: %.1f\n", miscText, time);
				}
			}

			if (PlayerHasItem(i, ItemSoldier_HawkWarrior) && CanUseCollectorItem(i, ItemSoldier_HawkWarrior)
				&& TF2_IsPlayerInCondition(i, TFCond_BlastJumping))
			{
				float time = FloatAbs(g_flPlayerRocketJumpTime[i]-GetTickedTime());
				Format(miscText, sizeof(miscText), "%sRocket Jump Time: %.1f/%.1f\n", miscText, time,
					GetItemMod(ItemSoldier_HawkWarrior, 0));
			}

			TFClassType class = TF2_GetPlayerClass(i);
			if (class == TFClass_Spy && g_flPlayerVampireSapperCooldown[i] > 0.0)
			{
				Format(miscText, sizeof(miscText), "%sSapper Cooldown: %.1f\n", miscText, g_flPlayerVampireSapperCooldown[i]);
			}
			else if (class == TFClass_DemoMan && g_flPlayerCaberRechargeAt[i] > 0.0)
			{
				Format(miscText, sizeof(miscText), "%sCaber: %.1f\n", miscText, FloatAbs(g_flPlayerCaberRechargeAt[i]-GetGameTime()));
			}
			else if (class == TFClass_Sniper)
			{
				int rifle = GetPlayerWeaponSlot(i, WeaponSlot_Primary);
				if (rifle != INVALID_ENT && rifle == GetActiveWeapon(i))
				{
					static char classname[64];
					GetEntityClassname(rifle, classname, sizeof(classname));
					if (!strcmp2(classname, "tf_weapon_compound_bow"))
					{
						float charge = GetEntPropFloat(rifle, Prop_Send, "m_flChargedDamage")/1.5;
						bool slowed = TF2_IsPlayerInCondition(i, TFCond_Slowed);
						if (g_bPlayerRifleAutoFire[i] || !slowed)
						{
							if (!g_bPlayerToggledAutoFire[i])
							{
								Format(miscText, sizeof(miscText), "%sAuto-Fire: %s (ATTACK3/Middle Mouse to toggle)\n", miscText, g_bPlayerRifleAutoFire[i] ? "ON" : "OFF");
							}
							else
							{
								Format(miscText, sizeof(miscText), "%sAuto-Fire: %s\n", miscText, g_bPlayerRifleAutoFire[i] ? "ON" : "OFF");
							}
							
						}
						else if (slowed)
						{
							Format(miscText, sizeof(miscText), "%sCharge: %.0f%s\n", miscText, charge, "%%");
						}
					}
				}
			}
			else if (class == TFClass_Heavy && PlayerHasItem(i, ItemHeavy_Pugilist))
			{
				if (TF2_IsPlayerInCondition(i, TFCond_Slowed))
				{
					Format(miscText, sizeof(miscText), "%sHEAVY ARMOR: %.0f (%.0f%s RESIST)\n", miscText, g_flPlayerHeavyArmorPoints[i],
						GetItemMod(ItemHeavy_Pugilist, 0) * g_flPlayerHeavyArmorPoints[i], "%%");

					b = 255;
					g = 255;
					r = 100;
				}
				else
				{
					Format(miscText, sizeof(miscText), "%s[ARMOR INACTIVE]: %.0f (%.0f%s RESIST)\n", miscText, g_flPlayerHeavyArmorPoints[i],
						GetItemMod(ItemHeavy_Pugilist, 0) * g_flPlayerHeavyArmorPoints[i], "%%");
					
					r = 255;
					g = 100;
					b = 100;
				}
			}
			else if (class == TFClass_Medic && PlayerHasItem(i, ItemMedic_ProcedureMask))
			{
				if (g_flPlayerMedicShieldNextUseTime[i] > GetGameTime())
				{
					float rage = GetEntPropFloat(i, Prop_Send, "m_flRageMeter");
					if (rage > 0.0)
					{
						Format(miscText, sizeof(miscText), "%sSHIELD ENERGY: %.1f\n", miscText, rage);
						r = 255;
						g = 255;
						b = 100;
					}
					else
					{
						r = 255;
						g = 100;
						b = 100;
					}

					Format(miscText, sizeof(miscText), "%s***SHIELD COOLDOWN*** %.1f\n", miscText,
						FloatAbs(GetGameTime()-g_flPlayerMedicShieldNextUseTime[i]));
				}
				else
				{
					int medigun = GetPlayerWeaponSlot(i, WeaponSlot_Secondary);
					if (medigun == INVALID_ENT || medigun != GetActiveWeapon(i))
					{
						Format(miscText, sizeof(miscText), "%sSHIELD READY - SWITCH TO YOUR MEDIGUN TO USE\n", miscText);
					}
					else
					{
						Format(miscText, sizeof(miscText), "%sSHIELD READY - ATTACK3/MIDDLE MOUSE TO USE\n", miscText);
					}
					
					b = 255;
					g = 255;
					r = 100;
				}
			}
			else if (class == TFClass_Engineer)
			{
				int dispenser = GetBuiltObject(i, TFObject_Dispenser);
				RF2_DispenserShield shield = dispenser != INVALID_ENT ? GetDispenserShield(dispenser) : RF2_DispenserShield(INVALID_ENT);
				if (shield.IsValid())
				{
					if (shield.Battery <= 25)
					{
						r = 255;
						g = 100;
						b = 100;
					}
					else if (shield.Battery <= 50)
					{
						r = 255;
						g = 255;
						b = 100;
					}
					else
					{
						r = 100;
						g = 255;
						b = 100;
					}
					
					if (shield.UserDisabled)
					{
						Format(miscText, sizeof(miscText), "%s***SHIELD DISABLED***\nSHIELD BATTERY: %i\n", miscText, shield.Battery);
					}
					else
					{
						Format(miscText, sizeof(miscText), "%sSHIELD BATTERY: %i\n", miscText, shield.Battery);
					}
				}
				
				if (PlayerHasItem(i, ItemEngi_BrainiacHairpiece))
				{
					int powerBottle = g_iPlayerPowerupBottle[i];
					if (IsValidEntity2(powerBottle))
					{
						int charges = GetEntProp(powerBottle, Prop_Send, "m_usNumCharges");
						if (charges > 0)
						{
							if (!g_bPlayerPressedCanteenButton[i])
							{
								g_bPlayerPressedCanteenButton[i] = asBool(GetEntProp(powerBottle, Prop_Send, "m_bActive"));
							}
							
							if (!g_bPlayerPressedCanteenButton[i])
							{
								Format(miscText, sizeof(miscText), "%s\nBUILD CANTEENS: %i [MVM CANTEEN BUTTON TO USE]\n", 
									miscText, charges);
							}
							else
							{
								Format(miscText, sizeof(miscText), "%s\nBUILD CANTEENS: %i\n", 
									miscText, charges);
							}
						}
					}
				}
				
				if (PlayerHasItem(i, ItemEngi_HeadOfDefense))
				{
					Format(miscText, sizeof(miscText), "%sDISPOSABLE SENTRIES: %i/%i\n", miscText,
						g_hPlayerExtraSentryList[i].Length, CalcItemModInt(i, ItemEngi_HeadOfDefense, 0));
				}
			}
			
			if (miscText[0])
			{
				SetHudTextParams(-1.0, 0.7, 0.15, r/2, g/2, b/2, 50);
				ShowSyncHudText(i, g_hMiscHudSync, miscText);
				SetHudTextParams(-1.0, MAIN_HUD_Y, 0.15, g_iMainHudR, g_iMainHudG, g_iMainHudB, 255);
			}
			
			static char cashString[64];
			FormatEx(cashString, sizeof(cashString), "$%.0f", g_flPlayerCash[i]);
			if (g_bRingCashBonus)
			{
				Format(cashString, sizeof(cashString), "%s (%.1fx BONUS)", cashString, 1.0+GetItemMod(ItemStrange_SpecialRing, 0));
			}
			
			ShowSyncHudText(i, g_hMainHudSync, g_szSurvivorHudText, g_iStagesCompleted+1, difficultyName, g_iMinutesPassed,
				hudSeconds, g_iEnemyLevel, g_iPlayerLevel[i], g_flPlayerXP[i], g_flPlayerNextLevelXP[i],
				cashString, g_szHudDifficulty, strangeItemInfo);
		}
		else
		{
			ShowSyncHudText(i, g_hMainHudSync, g_szEnemyHudText, g_iStagesCompleted+1, difficultyName, g_iMinutesPassed, hudSeconds,
				g_iEnemyLevel, g_szHudDifficulty, strangeItemInfo);
		}
		
		if (g_szObjectiveHud[i][0] 
			&& (GetCurrentTeleporter().index == INVALID_ENT || RF2_Object_Teleporter.IsEventActive()))
		{
			SetHudTextParams(-1.0, -0.66, 0.15, g_iMainHudR, g_iMainHudG, g_iMainHudB, 255);
			ShowSyncHudText(i, g_hObjectiveHudSync, g_szObjectiveHud[i]);
			SetHudTextParams(-1.0, MAIN_HUD_Y, 0.15, g_iMainHudR, g_iMainHudG, g_iMainHudB, 255);
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
	
	if (g_bGameOver || g_bGracePeriod || WaitingForPlayerRejoin(true) || GetRF2GameRules().TimerPaused)
		return Plugin_Continue;
	
	g_flSecondsPassed += 1.0;
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
			if (!IsClientInGame(i) || !IsPlayerAlive(i) || IsPlayerSurvivor(i) && !IsPlayerMinion(i))
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
		if (g_iSubDifficulty <= SubDifficulty_Hahaha && GetTickedTime() > lastBellTime+10.0)
		{
			EmitSoundToAll(SND_BELL);
			lastBellTime = GetTickedTime();
		}
	}
	
	return Plugin_Continue;
}

public Action Timer_PlayerTimer(Handle timer)
{
	if (!RF2_IsEnabled())
	{
		g_hPlayerTimer = null;
		return Plugin_Stop;
	}
	
	if (g_bServerRestarting)
	{
		PrintCenterTextAll("%t", "ServerRestart");
	}
	
	int maxHealth, health, healAmount, weapon, ammoType;
	int sentry = INVALID_ENT;
	int team, index;
	static char names[2048];
	names = "";
	bool stageCleared = IsStageCleared();
	bool itemShare = IsItemSharingEnabled();
	bool missingItems;
	bool canDisableSharing;
	static float timeSincePingHint[MAXPLAYERS];
	float maxShareTime = g_cvItemShareMaxTime.FloatValue;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsSpecBot(i))
			continue;
		
		if (g_bRoundActive && itemShare && IsPlayerSurvivor(i, false))
		{
			canDisableSharing = true;
			if (!DoesPlayerHaveEnoughItems(i))
			{
				missingItems = true;
				index = RF2_GetSurvivorIndex(i);
				if (!IsBossEventActive())
				{
					Format(names, sizeof(names), "%s- %N (%i/%i) - %.0f\n", names, i, g_iPlayerItemsTaken[index], GetPlayerRequiredItems(i), 
						FloatAbs((g_flPlayerTimeSinceLastItemPickup[i]+maxShareTime))-GetTickedTime());
				}
			}
			
			if (g_iPlayerItemsTaken[RF2_GetSurvivorIndex(i)] < GetPlayerRequiredItems(i))
			{
				canDisableSharing = false;
			}
		}
		
		if (g_bRoundActive)
		{
			team = GetClientTeam(i);
			if (!IsPlayerAlive(i))
			{
				if (g_bGameWon || g_bGameOver)
					continue;
				
				if (team == TEAM_SURVIVOR && (g_cvBotsCanBeSurvivor.BoolValue || !IsFakeClient(i)))
				{
					if (IsInUnderworld())
					{
						// Allow late spawns in the underworld
						int freeIndex = GetFreeSurvivorIndex();
						if (freeIndex != -1 && !IsPlayerSurvivor(i, false))
						{
							MakeSurvivor(i, freeIndex, false);
						}
					}
					else if (!g_bGracePeriod && !GetRF2GameRules().DisableDeath && !g_bPlayerSpawningAsMinion[i])
					{
						g_bPlayerSpawningAsMinion[i] = true;
						CreateTimer(5.0, Timer_MinionSpawn, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				else if (team == TEAM_ENEMY)
				{
					if (!g_cvAllowHumansInBlue.BoolValue && !IsFakeClient(i))
					{
						ChangeClientTeam(i, TEAM_SURVIVOR);
					}
				}
			}
			else if (team == TEAM_SURVIVOR && !IsPlayerSurvivor(i) && !IsPlayerMinion(i))
			{
				SilentlyKillPlayer(i);
				if (IsFakeClient(i))
				{
					KickClient(i);
				}
			}
			else if (team == TEAM_ENEMY && (g_bGracePeriod || !IsEnemy(i)))
			{
				SilentlyKillPlayer(i);
				if (IsFakeClient(i))
				{
					KickClient(i);
				}
			}
		}
		
		// All players have infinite reserve ammo
		weapon = GetActiveWeapon(i);
		if (weapon != INVALID_ENT)
		{
			ammoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
			bool scoutSecondary;
			if (ammoType == TFAmmoType_Secondary)
			{
				// don't refill for scout secondaries since they use this ammo type to work with Whale Bone Charm
				int id = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
				if (id == 812 || id == 222 || id == 1121)
				{
					scoutSecondary = true;
				}
			}
			
			if (!scoutSecondary && ammoType > TFAmmoType_None && ammoType < TFAmmoType_Metal)
			{
				GivePlayerAmmo(i, 999999, ammoType, true);
			}
		}

		if (TF2_GetPlayerClass(i) == TFClass_DemoMan && IsPlayerSurvivor(i))
		{
			int caber = GetPlayerWeaponSlot(i, WeaponSlot_Melee);
			if (caber != INVALID_ENT)
			{
				// Recharging caber
				static char classname[64];
				GetEntityClassname(caber, classname, sizeof(classname));
				if (strcmp2(classname, "tf_weapon_stickbomb"))
				{
					bool detonated = asBool(GetEntProp(caber, Prop_Send, "m_iDetonated"));
					if (detonated)
					{
						if (g_flPlayerCaberRechargeAt[i] == 0.0)
						{
							g_flPlayerCaberRechargeAt[i] = GetGameTime()+60.0;
						}
						else if (GetGameTime() >= g_flPlayerCaberRechargeAt[i])
						{
							SetEntProp(caber, Prop_Send, "m_iDetonated", false);
							g_flPlayerCaberRechargeAt[i] = 0.0;
							EmitGameSoundToClient(i, "Item.Materialize");
							PrintHintText(i, "Your Ullapool Caber has been recharged");
						}
					}
				}
			}
		}
		
		if (timeSincePingHint[i]+30.0 <= GetTickedTime() && !GetCookieBool(i, g_coPingObjectsHint))
		{
			int target = GetClientAimTarget(i, false);
			if (RF2_Object_Base(target).IsValid())
			{
				static char classname[128];
				if (weapon != INVALID_ENT)
				{
					GetEntityClassname(weapon, classname, sizeof(classname));
				}
				
				if (weapon == INVALID_ENT || StrContains(classname, "tf_weapon_sniperrifle") == -1)
				{
					PrintHintText(i, "%t", "PingObjectsHint");
					timeSincePingHint[i] = GetTickedTime();
				}
			}
		}
		
		// Health Regen
		if (CanPlayerRegen(i))
		{
			if (g_flPlayerRegenBuffTime[i] > 0.0)
				g_flPlayerRegenBuffTime[i] -= 0.1;
			
			// Regen rune does nothing outside of Mannpower, make it triple health regen and decrease health regen freeze time
			bool regenRune = TF2_IsPlayerInCondition(i, TFCond_RuneRegen);
			g_flPlayerHealthRegenTime[i] -= regenRune ? 0.3 : 0.1;
			if (g_flPlayerHealthRegenTime[i] <= 0.0)
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
					
					if (IsPlayerMinion(i))
					{
						healAmount += 3 * g_iSubDifficulty;
					}
					
					if (IsPlayerSurvivor(i))
					{
						if (RF2_GetDifficulty() == DIFFICULTY_STEEL)
						{
							g_flPlayerHealthRegenTime[i] += 0.2;
						}
						else if (RF2_GetDifficulty() >= DIFFICULTY_TITANIUM)
						{
							g_flPlayerHealthRegenTime[i] += 0.3;
						}
						else if (RF2_GetDifficulty() == DIFFICULTY_SCRAP)
						{
							healAmount = RoundFloat(float(healAmount) * 2.0);
						}
					}

					if (regenRune)
					{
						healAmount *= 3;
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
		
		if (PlayerHasItem(i, Item_Hachimaki) 
			&& g_flPlayerDelayedHealTime[i] > 0.0 && g_flPlayerDelayedHealTime[i] <= GetTickedTime())
		{
			HealPlayer(i, CalcItemModInt(i, Item_Hachimaki, 1));
			EmitGameSoundToClient(i, "HealthKit.Touch");
			g_flPlayerDelayedHealTime[i] = 0.0;
		}

		if (PlayerHasItem(i, Item_LilBitey)
			&& g_flPlayerLifestealTime[i] <= GetTickedTime())
		{
			float range = GetItemMod(Item_LilBitey, 1);
			float pos[3];
			GetEntPos(i, pos, true);
			int limit = CalcItemModInt(i, Item_LilBitey, 2);
			float damage = CalcItemMod(i, Item_LilBitey, 3);
			ArrayList hitEnts = DoRadiusDamage(i, i, pos, Item_LilBitey, damage, DMG_SLASH|DMG_PREVENT_PHYSICS_FORCE, 
				range, 1.0, _, _, true, _, limit);
			
			if (hitEnts.Length > 0)
			{
				int totalHeal;
				float victimPos[3];
				for (int a = 0; a < hitEnts.Length; a++)
				{
					int victim = hitEnts.Get(a);
					totalHeal += GetItemModInt(Item_LilBitey, 4);
					GetEntPos(victim, victimPos, true);
					TE_SetupBeamPoints(pos, victimPos, 
						g_iBeamModel, 0, 0, 0, 0.5, 8.0, 8.0, 0, 10.0, {255, 50, 255, 255}, 10);
					TE_SendToAll();
				}

				EmitGameSoundToAll("Weapon_Pomson.DrainedVictim", i);
				EmitGameSoundToAll("Weapon_BarretsArm.Zap", i);
				HealPlayer(i, totalHeal);
				g_flPlayerLifestealTime[i] = GetTickedTime()+GetItemMod(Item_LilBitey, 0);
			}
				
			delete hitEnts;
		}
		
		if (g_flPlayerWealthRingRadius[i] > 0.0)
		{
			if (PlayerHasItem(i, Item_WealthHat))
			{
				float pos[3];
				GetEntPos(i, pos);
				pos[2] += 20.0;
				TE_SetupBeamRingPoint(pos, g_flPlayerWealthRingRadius[i], g_flPlayerWealthRingRadius[i]+0.1,
					g_iBeamModel, 0, 0, 0, 0.11, 5.0, 5.0, {255, 255, 0, 255}, 5, 0);
				
				TE_SendToAll();
				float damage = GetItemMod(Item_WealthHat, 0) + CalcItemMod(i, Item_WealthHat, 1, -1);
				ArrayList hitEnts = DoRadiusDamage(i, i, pos, Item_WealthHat, damage, DMG_IGNITE|DMG_PREVENT_PHYSICS_FORCE, 
					g_flPlayerWealthRingRadius[i], _, _, _, true);
				
				int victim;
				for (int a = 0; a < hitEnts.Length; a++)
				{
					victim = hitEnts.Get(a);
					if (IsValidClient(victim))
					{
						TF2_IgnitePlayer(victim, i, 10.0);
						EmitSoundToAll("misc/null.wav", victim, SNDCHAN_VOICE);
					}
				}
				
				delete hitEnts;
			}
			
			g_flPlayerWealthRingRadius[i] = fmax(0.0, g_flPlayerWealthRingRadius[i]-GetItemMod(Item_WealthHat, 5));
		}

		if (g_iPlayerShieldHealth[i] <= 0 && GetGameTime() >= g_flPlayerShieldRegenTime[i] && PlayerHasItem(i, Item_MetalHelmet))
		{
			EmitGameSoundToClient(i, "WeaponMedigun_Vaccinator.Charged_tier_04");
			g_iPlayerShieldHealth[i] = CalcItemModInt(i, Item_MetalHelmet, 2);
		}

		if (g_flPlayerHealthRegenTime[i] <= 0.0)
		{
			if (g_flPlayerHeavyArmorPoints[i] < 100.0 && PlayerHasItem(i, ItemHeavy_Pugilist) && CanUseCollectorItem(i, ItemHeavy_Pugilist))
			{
				g_flPlayerHeavyArmorPoints[i] = fmin(g_flPlayerHeavyArmorPoints[i] + (CalcItemMod(i, ItemHeavy_Pugilist, 1)*0.1), 100.0);
			}
			
			int maxShield = CalcItemModInt(i, Item_MetalHelmet, 2);
			if (GetGameTime() >= g_flPlayerShieldRegenTime[i] 
				&& g_iPlayerShieldHealth[i] > 0 && g_iPlayerShieldHealth[i] < maxShield 
				&& PlayerHasItem(i, Item_MetalHelmet))
			{
				// slowly regenerate
				g_iPlayerShieldHealth[i] = imin(
					g_iPlayerShieldHealth[i]+RoundToCeil(float(maxShield)*GetItemMod(Item_MetalHelmet, 4)*0.1), maxShield);
			}
		}
		
		if (PlayerHasItem(i, ItemSpy_Showstopper) && CanUseCollectorItem(i, ItemSpy_Showstopper))
		{
			bool inCond = TF2_IsPlayerInCondition(i, TFCond_CritHype);
			if (g_flPlayerKnifeStunCooldown[i] > 0.0)
			{
				g_flPlayerKnifeStunCooldown[i] = fmax(0.0, g_flPlayerKnifeStunCooldown[i]-0.1);
				if (inCond)
				{
					TF2_RemoveCondition(i, TFCond_CritHype);
				}
			}
			else if (!inCond)
			{
				TF2_AddCondition(i, TFCond_CritHype); // just for glow effect, does nothing on Spy (still plays the sound though, which is clientside :/)
			}
		}
		
		// hotfix - start equipment cooldown if it stops for some reason?
		if (!g_bPlayerEquipmentCooldownActive[i])
		{
			if (g_flPlayerEquipmentItemCooldown[i] > 0.0)
			{
				g_bPlayerEquipmentCooldownActive[i] = true;
				CreateTimer(0.1, Timer_EquipmentCooldown, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else if (g_flPlayerEquipmentItemCooldown[i] <= 0.0)
		{
			g_bPlayerEquipmentCooldownActive[i] = false;
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
					SetVariantInt(30000);
					AcceptEntityInput(sentry, "RemoveHealth");
				}
			}
		}
	}
	
	if (!IsSingleplayer(false) && g_cvItemShareEnabled.BoolValue)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!g_bPlayerViewingItemDesc[i] && IsClientInGame(i) 
				&& !IsFakeClient(i) && GetClientTeam(i) != TEAM_ENEMY 
				&& !IsBossEventActive()
				&& (stageCleared || (GetCookieBool(i, g_coTutorialSurvivor) && GetCookieBool(i, g_coTutorialItemPickup)))
				&& (stageCleared || GetCookieBool(i, g_coAlwaysShowItemCounts)))
			{
				if (missingItems)
				{
					PrintKeyHintText(i, "Players who need to pick up items:\n%s", names);
				}
				else
				{
					if (canDisableSharing)
					{
						g_bItemSharingDisabledForMap = true;
					}
					
					PrintKeyHintText(i, "");
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
	const int maxMessages = 7;
	
	switch (message)
	{
		case 0: RF2_PrintToChatAll("%t", "TipNewPlayer");
		case 1: RF2_PrintToChatAll("%t", "TipItemLog");
		case 2: RF2_PrintToChatAll("%t", "TipCredits", PLUGIN_VERSION);
		case 3: RF2_PrintToChatAll("%t", "TipQueue");
		case 4: RF2_PrintToChatAll("%t", "TipMenu");
		case 5:	RF2_PrintToChatAll("%t", "TipDiscord");
		case 6: RF2_PrintToChatAll("%t", "TipAchievements");
		case 7: RF2_PrintToChatAll("%t", "TipSettings");
	}
	
	message++;
	if (message > maxMessages)
		message = 0;

	return Plugin_Continue;
}

public void Timer_DeleteEntity(Handle timer, int entity)
{
	entity = EntRefToEntIndex(entity);
	if (entity != INVALID_ENT)
		RemoveEntity(entity);
}

public Action Timer_AFKManager(Handle timer)
{
	if (!RF2_IsEnabled() || IsSingleplayer())
		return Plugin_Continue;
	
	int humanCount = GetTotalHumans();
	float afkKickTime = g_cvAFKManagerKickTime.FloatValue;
	bool kickAdmins = g_cvAFKKickAdmins.BoolValue;
	bool managerEnabled = g_cvEnableAFKManager.BoolValue;
	bool survivorsOnly = g_cvAFKOnlyKickSurvivors.BoolValue;
	float time = afkKickTime * 0.5;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		g_flPlayerAFKTime[i] += 1.0;
		if (g_flPlayerAFKTime[i] >= time)
		{
			if (!g_bPlayerIsAFK[i])
			{
				g_bPlayerIsAFK[i] = true;
				OnPlayerEnterAFK(i);
			}
			else if (managerEnabled && GetClientTeam(i) > 1)
			{
				PrintCenterText(i, "%t", "AFKDetected");
			}
		}
		
		if ((!survivorsOnly || IsPlayerSurvivor(i, false)) && g_bRoundActive 
			&& managerEnabled && !IsSingleplayer(false) && g_flPlayerAFKTime[i] >= afkKickTime && humanCount > 1)
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
		if(g_flBlockMedicCall[client] < GetTickedTime())
			return OnCallForMedic(client);
	}

	return Plugin_Continue;
}

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	if (!RF2_IsEnabled() || !IsClientInGame(client))
		return Plugin_Continue;

	char buffer[64];
	KvGetSectionName(kv, buffer, sizeof(buffer));
	//Medic E call, its really really delayed it is NOT the same as voicemenu 0 0, this is way faster.
	if(StrEqual(buffer, "+helpme_server", false))
	{
		//add a delay, so if you call E it doesnt do the voice menu one, though keep the voice menu one for really epic cfg nerds.
		g_flBlockMedicCall[client] = GetTickedTime() + 0.5;
		return OnCallForMedic(client);
	}
	
	return Plugin_Continue;
}

Action OnCallForMedic(int client)
{
	if (!IsPlayerAlive(client))
	{
		int target = GetSpectateTarget(client);
		if (IsValidClient(target) && IsPlayerSurvivor(target))
		{
			ShowItemMenu(client, target);
		}
		
		return Plugin_Continue;
	}
	
	if (IsPlayerSurvivor(client) || IsPlayerMinion(client))
	{
		if (g_flPlayerLastTabPressTime[client]+0.6 >= GetTickedTime())
		{
			ShowItemMenu(client); // shortcut
			return Plugin_Handled;
		}
		
		if (IsPlayerSurvivor(client) && PickupItem(client))
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
		if (obj.IsValid() && obj.OnInteractForward)
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
	if (IsFakeClient(client) || g_bRoundActive && !g_bGracePeriod && !GetRF2GameRules().DisableDeath || GetClientTeam(client) == TEAM_ENEMY)
	{
		// don't nag dead players for trying to change class
		if (!IsFakeClient(client) && IsPlayerAlive(client) && !IsPlayerMinion(client))
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
		
		if (!g_bWaitingForPlayers && team == TEAM_ENEMY && !g_cvAllowHumansInBlue.BoolValue)
		{
			RF2_PrintToChat(client, "%t", "NoChangeTeam");
			return Plugin_Handled;
		}
		else if (IsTeleporterBoss(client) || team == TEAM_SURVIVOR && IsPlayerAlive(client) && IsPlayerSurvivor(client) && !g_bGracePeriod)
		{
			RF2_PrintToChat(client, "%t", "NoChangeTeam");
			return Plugin_Handled;
		}
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

public Action OnEurekaTeleport(int client, const char[] command, int args)
{
	if (g_bWaitingForPlayers)
		return Plugin_Continue;

	if (g_bDisableEurekaTeleport)
	{
		PrintCenterText(client, "%t", "EurekaBanned");
		EmitSoundToClient(client, SND_NOPE);
		TF2_RemoveCondition(client, TFCond_Taunting);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action OnSuicide(int client, const char[] command, int args)
{
	if (!RF2_IsEnabled() || !g_bRoundActive || GetRF2GameRules().DisableDeath)
		return Plugin_Continue;
	
	if (IsPlayerSurvivor(client) && !g_bGracePeriod && !IsPlayerMinion(client)) // Only minions can suicide
	{
		RF2_PrintToChat(client, "%t", "NoSuicide");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void Timer_SuicideTeleport(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if (!client || !IsClientInGame(client) || IsPlayerAlive(client))
		return;
	
	float pos[3];
	pos[0] = pack.ReadFloat();
	pos[1] = pack.ReadFloat();
	pos[2] = pack.ReadFloat();
	TF2_RespawnPlayer(client);
	TeleportEntity(client, pos);
	g_bPlayerSpawningAsMinion[client] = false;
}

public void Hook_PreThink(int client)
{
	// IsClientTimingOut() doesn't work in OnClientDisconnect, so this is required to know if a client times out when disconnecting
	g_bPlayerTimingOut[client] = !IsFakeClient(client) && IsClientTimingOut(client);
	if (g_bWaitingForPlayers && !IsPlayerAlive(client) && GetClientTeam(client) > 1)
	{
		TF2_RespawnPlayer(client);
	}
	
	float engineTime = GetEngineTime();
	bool bot = IsFakeClient(client);
	if (g_bRoundActive && (!bot || IsClientSourceTV(client)) && !IsMusicPaused() && g_flLoopMusicAt[client] > 0.0 && engineTime >= g_flLoopMusicAt[client])
	{
		RF2_Object_Teleporter teleporter = GetCurrentTeleporter();
		if (IsCustomTrackPlaying() || !teleporter.IsValid() || teleporter.EventState != TELE_EVENT_PREPARING)
		{
			PlayMusicTrack(client);
		}
	}
	
	if (!g_bServerRestarting && g_bWaitingForPlayers && !IsFakeClient(client) && !GetCookieBool(client, g_coBecomeSurvivor))
	{
		PrintCenterText(client, "%t", "SurvivorDisabledWarning");
	}
	
	if (IsInspectButtonPressed(client))
	{
		int target = INVALID_ENT;
		if (IsPlayerAlive(client))
		if (IsPlayerAlive(client))
		{
			target = GetClientAimTarget(client);
		}
		else
		{
			target = GetSpectateTarget(client);
		}
		
		if (IsValidClient(target) && IsPlayerSurvivor(target))
		{
			ShowItemMenu(client, target);
		}
	}
	
	if (!IsPlayerAlive(client))
		return;
	
	if (g_bRoundActive && bot)
	{
		TFBot_Think(TFBot(client));
	}
	
	if (IsValidEntity2(g_iPlayerRollerMine[client]))
	{
		float pos[3];
		GetEntPos(g_iPlayerRollerMine[client], pos);
		CBaseEntity(client).SetLocalOrigin(pos);
	}
	
	static float lastViewAngles[MAXPLAYERS][3];
	if (TF2_IsPlayerInCondition(client, TFCond_Dazed) && GetEntProp(client, Prop_Send, "m_iStunFlags") & TF_STUNFLAG_BONKSTUCK)
	{
		// If hard stunned, force last view angle to prevent hitbox desync when rotating view
		TeleportEntity(client, _, lastViewAngles[client]);
	}
	else
	{
		GetClientEyeAngles(client, lastViewAngles[client]);
	}
	
	if (PlayerHasItem(client, ItemScout_MonarchWings) && CanUseCollectorItem(client, ItemScout_MonarchWings))
	{
		UpdatePlayerGravity(client);
	}
	
	TFClassType class = TF2_GetPlayerClass(client);
	if (g_bRoundActive && class == TFClass_Engineer)
	{
		float tickedTime = GetTickedTime();
		if (tickedTime >= g_flPlayerNextMetalRegen[client])
		{
			int metal;
			if (g_bGracePeriod || GetClientTeam(client) == TEAM_ENEMY)
			{
				metal = 999999;
			}
			else
			{
				metal = RoundToFloor(float(g_cvEngiMetalRegenAmount.IntValue) * (1.0 + float(GetPlayerLevel(client)) * 0.12));
			}
			
			GivePlayerAmmo(client, metal, TFAmmoType_Metal, true);
			float time = g_bGracePeriod ? 0.1 : g_cvEngiMetalRegenInterval.FloatValue;
			g_flPlayerNextMetalRegen[client] = tickedTime + time;
		}
	}
	else if (class == TFClass_Scout)
	{
		int primary = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
		if (primary != INVALID_ENT)
		{
			if (GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex") == 448
				&& !TF2_IsPlayerInCondition(client, TFCond_CritHype))
			{
				// Soda Popper behaves like pre gun mettle
				float vel1[3], vel2[3], angles[3];
				GetClientAbsAngles(client, angles);
				GetAngleVectors(angles, vel1, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(vel1, vel1);
				GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vel2);
				NormalizeVector(vel2, vel2);
				float dot = FloatAbs(GetVectorDotProduct(vel1, vel2));
				float hype = GetEntPropFloat(client, Prop_Send, "m_flHypeMeter");
				SetEntPropFloat(client, Prop_Send, "m_flHypeMeter", fmin(100.0, hype+(dot*0.08)));
			}
		}

		if ((GetEntityFlags(client) & FL_ONGROUND))
		{
			g_iPlayerAirDashCounter[client] = 0;
			if (g_iPlayerGoombaChain[client] > 0 && !IsValidClient(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity")))
			{
				g_iPlayerGoombaChain[client] = 0;
			}
		}
		else
		{
			int airDashes = GetEntProp(client, Prop_Send, "m_iAirDash");
			if (airDashes > 0 && airDashes != g_iPlayerAirDashCounter[client])
			{
				int airDashLimit = 1;
				int activeWeapon = GetActiveWeapon(client);
				if (activeWeapon != INVALID_ENT)
				{
					airDashLimit += TF2Attrib_HookValueInt(0, "air_dash_count", activeWeapon);
				}
				
				if (g_iPlayerAirDashCounter[client] < airDashLimit)
				{
					g_iPlayerAirDashCounter[client]++;
					OnPlayerAirDash(client);
				}
			}
		}
	}
	else if (class == TFClass_Heavy)
	{
		// fix extra reserve sandviches not recharging
		float itemCharge = GetEntPropFloat(client, Prop_Send, "m_flItemChargeMeter", WeaponSlot_Secondary);
		if (itemCharge >= 100.0)
		{
			int maxAmmo = TF2Attrib_HookValueInt(1, "mult_maxammo_grenades1", client);
			if (GetEntProp(client, Prop_Send, "m_iAmmo", _, TFAmmoType_Jarate) < maxAmmo)
			{
				SetEntPropFloat(client, Prop_Send, "m_flItemChargeMeter", 0.0, WeaponSlot_Secondary);
			}
		}
	}
	
	if (IsEnemy(client))
	{
		// Make sure we aren't stuck inside of any players. If we are, we should change our collision group
		float mins[3], maxs[3];
		GetClientMins(client, mins);
		GetClientMaxs(client, maxs);
		float pos[3];
		GetEntPos(client, pos);
		TR_TraceHullFilter(pos, pos, mins, maxs, MASK_PLAYERSOLID, TraceFilter_OtherTeamPlayers, client, TRACE_ENTITIES_ONLY);
		if (TR_DidHit())
		{
			// Stop colliding with players until we're not intersecting with them anymore
			SetEntityCollisionGroup(client, TFCOLLISION_GROUP_TANK);
		}
		else
		{
			SetEntityCollisionGroup(client, COLLISION_GROUP_PLAYER);
		}
	}
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (!RF2_IsEnabled())
		return;
	
	if (condition == TFCond_Taunting && !g_bWaitingForPlayers)
	{
		Enemy enemy = Enemy(client);
		if (enemy != NULL_ENEMY && enemy.SuicideBomber)
		{
			enemy.DoSuicideBomb(client);
		}
		else if (IsFakeClient(client) && GetEntProp(client, Prop_Send, "m_iTauntIndex")
				|| IsValidEntity2(g_iPlayerRollerMine[client]))
		{
			TF2_RemoveCondition(client, TFCond_Taunting);
		}
		else if (!GetEntProp(client, Prop_Send, "m_iTauntIndex")) // Weapon taunts are always 0
		{
			int activeWeapon = GetActiveWeapon(client);
			if (activeWeapon > 0 && IsWeaponTauntBanned(activeWeapon))
			{
				TF2_RemoveCondition(client, TFCond_Taunting);
				SlapPlayer(client);
				EmitSoundToClient(client, SND_NOPE);
			}
		}
	}
	else if (condition == TFCond_Disguising)
	{
		int offset = FindSendPropInfo("CTFPlayer", "m_bHasPasstimeBall") - 760;
		float gameTime = GetGameTime();
		float disguiseTime = GetEntDataFloat(client, offset) - gameTime;
		disguiseTime *= 1.0 - fmin(1.0, CalcItemMod(client, ItemSpy_CounterfeitBillycock, 2));
		SetEntDataFloat(client, offset, gameTime+disguiseTime);
	}
	else if (condition == TFCond_Cloaked)
	{
		CalculatePlayerMaxSpeed(client);
	}
	else if (condition == TFCond_BlastJumping)
	{
		if (PlayerHasItem(client, ItemSoldier_HawkWarrior) && CanUseCollectorItem(client, ItemSoldier_HawkWarrior))
		{
			g_flPlayerRocketJumpTime[client] = GetTickedTime();
		}
	}
	else if (condition == TFCond_Parachute)
	{
		if (IsPlayerSurvivor(client))
		{
			TF2_AddCondition(client, TFCond_MarkedForDeathSilent);
		}
	}
	else if (condition == TFCond_RuneVampire || condition == TFCond_RuneWarlock
		|| condition == TFCond_RuneKnockout || condition == TFCond_KingRune || condition == TFCond_KingAura)
	{
		// These runes modify max health
		CalculatePlayerMaxHealth(client);
		if (condition == TFCond_KingAura || condition == TFCond_KingRune)
		{
			UpdatePlayerFireRate(client);
		}
	}
	else if (condition == TFCond_RuneHaste || condition == TFCond_RuneAgility || condition == TFCond_SpeedBuffAlly
		|| condition == TFCond_RegenBuffed || condition == TFCond_HalloweenSpeedBoost || condition == TFCond_Slowed || condition == TFCond_Dazed)
	{
		CalculatePlayerMaxSpeed(client);
		if (condition == TFCond_RuneHaste)
		{
			UpdatePlayerFireRate(client);
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (!RF2_IsEnabled())
		return;
	
	if (condition == TFCond_PreventDeath)
	{
		Enemy enemy = Enemy(client);
		if (enemy != NULL_ENEMY && enemy.SuicideBomber)
		{
			TF2_AddCondition(client, TFCond_PreventDeath);
		}
	}
	else if (condition == TFCond_Bleeding)
	{
		g_bPlayerHeadshotBleeding[client] = false;
	}
	else if (condition == TFCond_BlastJumping)
	{
		if (PlayerHasItem(client, ItemSoldier_HawkWarrior) && CanUseCollectorItem(client, ItemSoldier_HawkWarrior))
		{
			if (GetTickedTime()-g_flPlayerRocketJumpTime[client] >= GetItemMod(ItemSoldier_HawkWarrior, 0))
			{
				RemoveAllRunes(client);
				EmitSoundToClient(client, SND_RUNE_HASTE);
				TF2_AddCondition(client, TFCond_PowerupModeDominant, CalcItemMod(client, ItemSoldier_HawkWarrior, 1));
				TF2_AddCondition(client, TFCond_RuneHaste, CalcItemMod(client, ItemSoldier_HawkWarrior, 1));
			}
		}
	}
	else if (condition == TFCond_Bonked)
	{
		if (GetClientTeam(client) == TEAM_SURVIVOR)
		{
			TF2_RemoveCondition(client, TFCond_Dazed);
		}
	}
	else if (condition == TFCond_Buffed && PlayerHasItem(client, Item_MisfortuneFedora))
	{
		TF2_AddCondition(client, TFCond_Buffed);
	}
	else if (condition == TFCond_MarkedForDeathSilent && g_bPlayerPermaDeathMark[client])
	{
		TF2_AddCondition(client, TFCond_MarkedForDeathSilent);
	}
	else if (condition == TFCond_Cloaked)
	{
		CalculatePlayerMaxSpeed(client);
	}
	else if (condition == TFCond_Charging)
	{
		if (PlayerHasItem(client, ItemDemo_ScotchBonnet) && CanUseCollectorItem(client, ItemDemo_ScotchBonnet))
		{
			TF2_AddCondition(client, TFCond_CritOnDamage, CalcItemMod(client, ItemDemo_ScotchBonnet, 2));
		}
	}
	else if (condition == TFCond_Parachute)
	{
		if (IsPlayerSurvivor(client))
		{
			TF2_RemoveCondition(client, TFCond_MarkedForDeathSilent);
		}
	}
	else if (condition == TFCond_Dazed)
	{
		// fix weapons not being unhidden for when stuns are removed
		int activeWep = GetActiveWeapon(client);
		if (activeWep != INVALID_ENT)
		{
			SetEntProp(activeWep, Prop_Send, "m_fEffects", 
				GetEntProp(activeWep, Prop_Send, "m_fEffects") & ~EF_NODRAW);
		}
	}
	else if (condition == TFCond_RuneVampire || condition == TFCond_RuneWarlock
	|| condition == TFCond_RuneKnockout || condition == TFCond_KingRune || condition == TFCond_KingAura)
	{
		// These runes modify max health
		CalculatePlayerMaxHealth(client);
		if (condition == TFCond_KingAura || condition == TFCond_KingRune)
		{
			UpdatePlayerFireRate(client);
		}
	}
	else if (condition == TFCond_RuneHaste || condition == TFCond_RuneAgility || condition == TFCond_SpeedBuffAlly
	|| condition == TFCond_RegenBuffed || condition == TFCond_HalloweenSpeedBoost || condition == TFCond_Slowed || condition == TFCond_Dazed)
	{
		if (condition == TFCond_SpeedBuffAlly)
		{
			g_bPlayerFullMinigunMoveSpeed[client] = false;
		}
		else if (condition == TFCond_RuneHaste)
		{
			UpdatePlayerFireRate(client);
		}
		else if (condition == TFCond_Slowed)
		{
			if (TF2_GetPlayerClass(client) == TFClass_Heavy && IsPlayerSurvivor(client))
			{
				// faster wind down speed
				int minigun = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
				if (minigun != INVALID_ENT)
				{
					float timeIdle = GetEntPropFloat(minigun, Prop_Send, "m_flTimeWeaponIdle");
					timeIdle = fmax(0.0, timeIdle-GetGameTime());
					const float mult = 10.0;
					timeIdle /= mult;
					SetEntPropFloat(minigun, Prop_Send, "m_flTimeWeaponIdle", GetGameTime()+timeIdle);
					SetEntPropFloat(minigun, Prop_Send, "m_flPlaybackRate", mult);
				}
			}
		}

		CalculatePlayerMaxSpeed(client);
	}
}

static int g_iLastFiredWeapon[MAXPLAYERS] = {INVALID_ENT, ...};
public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponName, bool &result)
{
	if (!RF2_IsEnabled() || !g_bRoundActive)
		return Plugin_Continue;
	
	bool changed;
	bool melee = GetPlayerWeaponSlot(client, WeaponSlot_Melee) == weapon;
	if (g_flPlayerWarswornBuffTime[client] > GetTickedTime())
	{
		if (!melee)
		{
			// infinite shots
			SetWeaponClip(weapon, GetWeaponClipSize(weapon));
		}
	}
	else if (g_flPlayerWarswornBuffTime[client] > 0.0)
	{
		UpdatePlayerFireRate(client);
		g_flPlayerWarswornBuffTime[client] = 0.0;
	}
	
	g_iLastFiredWeapon[client] = EntIndexToEntRef(weapon);
	RequestFrame(RF_NextPrimaryAttack, GetClientUserId(client));
	
	// Use our own crit logic
	if (!result)
	{
		if (TF2Attrib_HookValueInt(1, "mult_crit_chance", weapon) != 0
			&& !strcmp2(weaponName, "tf_weapon_knife"))
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
		if (PlayerHasItem(client, ItemPyro_PyromancerMaskOld) && CanUseCollectorItem(client, ItemPyro_PyromancerMaskOld)
			&& (!IsPlayerSurvivor(client) || GetClientHealth(client) / RF2_GetCalculatedMaxHealth(client) >= GetItemMod(ItemPyro_PyromancerMaskOld, 5))
			&& GetTickedTime() >= g_flPlayerNextFireSpellTime[client])
		{
			float speed = GetItemMod(ItemPyro_PyromancerMaskOld, 2) + CalcItemMod(client, ItemPyro_PyromancerMaskOld, 3, -1);
			speed = fmin(speed, GetItemMod(ItemPyro_PyromancerMaskOld, 4));
			float eyePos[3], eyeAng[3];
			GetClientEyePosition(client, eyePos);
			GetClientEyeAngles(client, eyeAng);
			float damage = GetItemMod(ItemPyro_PyromancerMaskOld, 0) + CalcItemMod(client, ItemPyro_PyromancerMaskOld, 1, -1);
			int fireball = ShootProjectile(client, "rf2_projectile_fireball", eyePos, eyeAng, speed, damage);
			SetEntItemProc(fireball, ItemPyro_PyromancerMaskOld);
			g_flPlayerNextFireSpellTime[client] = GetTickedTime() + GetItemMod(ItemPyro_PyromancerMaskOld, 6);
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
	// Because of the DHook we use to get that to actually work, the weapon firing sound will not play as it is predicted, so we need to play it manually here.
	if (g_bWasOffGround || g_bForceRifleSound)
	{
		ForceRifleSound(client, result);
		g_bForceRifleSound = false;
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
	
	float time = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack")-GetGameTime();
	if (IsPlayerSurvivor(client) && time <= GetTickInterval())
	{
		static char classname[128];
		GetEntityClassname(weapon, classname, sizeof(classname));
		if (!strcmp2(classname, "tf_weapon_flamethrower") && !strcmp2(classname, "tf_weapon_minigun"))
		{
			TriggerAchievement(client, ACHIEVEMENT_FIRERATECAP);
		}
	}
}

void ForceRifleSound(int client, bool crit=false)
{
	static char sound[PLATFORM_MAX_PATH];
	int weapon = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
	if (weapon == INVALID_ENT)
		return;
	
	if (g_bPlayerRifleAutoFire[client])
	{
		EmitSoundToAll(SND_AUTOFIRE_SHOOT, client, _, _, _, fmax(0.35, GetPlayerReloadMod(client)));
		if (crit)
		{
			EmitSoundToAll(SND_WEAPON_CRIT, client);
		}

		return;
	}
	else
	{
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
				if (GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") >= 150.0)
				{
					sound = GSND_MACHINA_FULL;
				}
				else
				{
					sound = GSND_MACHINA;
				}
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
	}
	
	if (crit)
	{
		StrCat(sound, sizeof(sound), "Crit");
	}
	
	EmitGameSoundToAll(sound, client);
}

public Action Hook_ProjectileForceDamage(int entity, int other)
{
	if (!IsValidClient(other) && !IsNPC(other) && !IsBuilding(other))
	{
		RemoveEntity(entity);
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
	RemoveEntity(entity);
	return Plugin_Handled;
}

public void TF2_OnWaitingForPlayersStart()
{
	if (!RF2_IsEnabled())
		return;
	
	// Disable TF2 achievements and stat tracking
	// We need to enable it here because this cvar otherwise prevents waiting for players from starting at all.
	FindConVar("tf_bot_offline_practice").SetBool(true);
	GameRules_SetPropFloat("m_flNextRespawnWave", GetGameTime()+999999.0, 2);
	GameRules_SetPropFloat("m_flNextRespawnWave", GetGameTime()+999999.0, 3);
	g_bWaitingForPlayers = true;
	CreateTimer(0.1, Timer_GameRulesOutputDelay, _, TIMER_FLAG_NO_MAPCHANGE); // Delay to ensure map logic runs properly
	PrintToServer("%T", "WaitingStart", LANG_SERVER);
	//float waitTime = FindConVar("mp_waitingforplayers_time").FloatValue;
	//CreateTimer(waitTime*0.8, Timer_ExtendWaitCheck, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void Timer_ExtendWaitCheck(Handle timer)
{
	if (!g_bWaitingForPlayers || !ArePlayersConnecting() || IsVoteInProgress())
		return;

	Menu vote = new Menu(Menu_ExtendWaitVote);
	vote.SetTitle("It looks like %d player(s) are still connecting. Extend waiting for players?", GetTotalHumans(false)-GetTotalHumans(true));
	vote.AddItem("Yes", "Yes");
	vote.AddItem("No", "No");
	vote.ExitButton = false;
	int clients[MAXPLAYERS];
	int clientCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) <= 1 || IsFakeClient(i))
			continue;
		
		clients[clientCount] = i;
		clientCount++;
	}
	
	vote.DisplayVote(clients, clientCount, 10);
}

public void Timer_GameRulesOutputDelay(Handle timer)
{
	if (!g_bWaitingForPlayers)
		return;

	RF2_GameRules gameRules = GetRF2GameRules();
	if (gameRules.IsValid())
	{
		gameRules.FireOutput("OnWaitingForPlayers");
		g_iLoopCount > 0 || g_cvDebugUseAltMapSettings.BoolValue ? gameRules.FireOutput("OnWaitingForPlayersPostLoop") : gameRules.FireOutput("OnWaitingForPlayersPreLoop");
	}
	
	return;
}

public void TF2_OnWaitingForPlayersEnd()
{
	if (!RF2_IsEnabled())
		return;

	g_bWaitingForPlayers = false;
	g_flWaitRestartTime = 0.0;
	PrintToServer("%T", "WaitingEnd", LANG_SERVER);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && !IsSpecBot(i) && GetClientTeam(i) != TEAM_ENEMY)
		{
			SilentlyKillPlayer(i);
			ChangeClientTeam(i, TEAM_ENEMY);
		}
	}
}

public void OnGameFrame()
{
	if (!g_bPluginEnabled)
		return;
		
	if (!g_bGameInitialized && g_cvGamePlayedCount.IntValue >= 1 
		&& GetGameTime() >= 60.0 && g_cvAggressiveRestarting.BoolValue 
		&& GetTotalHumans(false) <= 0)
	{
		// restart if everyone left and the game hasn't started
		PrintToServer("[RF2] Everyone has left. Restarting the server...");
		InsertServerCommand("quit");
	}
	
	if (g_flWaitRestartTime > 0.0 && GetTickedTime() >= g_flWaitRestartTime && GetTotalHumans(false) == 0)
	{
		// restart after a while if everyone left in the middle of a game after a map change
		PrintToServer("[RF2] Waited too long for players to join. Restarting...");
		g_flWaitRestartTime = 0.0;
		if (g_cvAggressiveRestarting.BoolValue)
		{
			InsertServerCommand("quit");
		}
		else
		{
			ReloadPlugin();
		}
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

static bool g_bProjectileIgnoreShields[MAX_EDICTS];
public void OnEntityCreated(int entity, const char[] classname)
{
	if (!RF2_IsEnabled())
		return;
	
	if (entity < 0 || entity >= MAX_EDICTS)
		return;
	
	g_bProjectileIgnoreShields[entity] = false;
	g_hEntityGlowResetTimer[entity] = null;
	g_flCashValue[entity] = 0.0;
	g_iItemDamageProc[entity] = Item_Null;
	g_iLastItemDamageProc[entity] = Item_Null;
	g_iEntLastHitItemProc[entity] = Item_Null;
	g_bDisposableSentry[entity] = false;
	g_bDontDamageOwner[entity] = false;
	g_bDontRemoveWearable[entity] = false;
	g_bItemWearable[entity] = false;
	g_bCashBomb[entity] = false;
	g_bEntityGlowing[entity] = false;
	g_flTeleporterNextSpawnTime[entity] = -1.0;
	SetAllInArray(g_flLastHalloweenBossAttackTime[entity], sizeof(g_flLastHalloweenBossAttackTime[]), 0.0);
	if (StrContains(classname, "tf_projectile") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, Hook_ProjectileSpawnPost);
	}
	
	if (classname[0] == 'i' && StrContains(classname, "item_") == 0)
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
	else if (strcmp2(classname, "tf_projectile_balloffire") || strcmp2(classname, "tf_projectile_energy_ring"))
	{
		// Dragon's Fury is stupid and doesn't fire the calc is attack critical function
		if (strcmp2(classname, "tf_projectile_balloffire"))
			RequestFrame(RF_DragonFuryCritCheck, EntIndexToEntRef(entity));
		
		RequestFrame(RF_CollideWithShields, EntIndexToEntRef(entity));
	}
	else if (g_hHookRiflePostFrame && StrContains(classname, "tf_weapon_sniperrifle") == 0)
	{
		g_hHookRiflePostFrame.HookEntity(Hook_Pre, entity, DHook_RiflePostFrame);
		g_hHookRiflePostFrame.HookEntity(Hook_Post, entity, DHook_RiflePostFramePost);
	}
	else if (strcmp2(classname, "team_round_timer"))
	{
		if (IsInUnderworld())
		{
			// hotfix
			RemoveEntity(entity);
		}
	}
	else if (IsBuilding(entity))
	{
		if (g_hHookStartUpgrading)
		{
			g_hHookStartUpgrading.HookEntity(Hook_Pre, entity, DHook_StartUpgrading);
			g_hHookStartUpgrading.HookEntity(Hook_Post, entity, DHook_StartUpgradingPost);
		}
		
		SDKHook(entity, SDKHook_OnTakeDamage, Hook_BuildingOnTakeDamage);
		SDKHook(entity, SDKHook_OnTakeDamagePost, Hook_BuildingOnTakeDamagePost);
		CreateTimer(0.5, Timer_BuildingHealthRegen, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (IsNPC(entity))
	{
		SDKHook(entity, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamageAlive);
		SDKHook(entity, SDKHook_OnTakeDamageAlivePost, Hook_OnTakeDamageAlivePost);
		SDKHook(entity, SDKHook_SpawnPost, Hook_NPCSpawnPost);
		if (IsSkeleton(entity))
		{
			SDKHook(entity, SDKHook_OnTakeDamage, Hook_SkeletonFriendlyFireFix);
		}
	}
	else if (IsEntityBlacklisted(classname))
	{
		RemoveEntity(entity);
	}
	else if (strcmp2(classname, "tf_dropped_weapon"))
	{
		RequestFrame(RF_WeaponDropped, EntIndexToEntRef(entity));
	}
}

public void RF_WeaponDropped(int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return;
	
	// check the player who dropped this item
	int offset = GetEntSendPropOffs(entity, "m_flChargeLevel", true)+4; // m_hPlayer
	int dropper = GetEntDataEnt2(entity, offset);
	
	// 0 means this is plugin created since we set this to world to avoid auto deletion
	if (dropper != 0 && (!IsValidClient(dropper) || !IsPlayerSurvivor(dropper) || IsPlayerMinion(dropper)))
	{
		// only survivors can drop weapons
		RemoveEntity(entity);
	}
	else if (dropper != 0)
	{
		SetEntDataEnt2(entity, offset, 0);
	}
}

public void Hook_NPCSpawnPost(int entity)
{
	SetEntityCollisionGroup(entity, TFCOLLISION_GROUP_TANK);
}

public void OnEntityDestroyed(int entity)
{
	if (!RF2_IsEnabled())
		return;
	
	if (entity < 0 || entity >= MAX_EDICTS)
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
	else if (RF2_Item(entity).IsValid())
	{
		int moveparent = GetEntPropEnt(entity, Prop_Send, "moveparent");
		if (IsValidEntity2(moveparent))
		{
			char classname[64];
			GetEntityClassname(moveparent, classname, sizeof(classname));
			if (StrContains(classname, "prop_physics") == 0)
			{
				// some items get parented to physics props
				RemoveEntity(moveparent);
			}
		}
	}
	
	if (g_iEntityPathFollower[entity])
	{
		g_iEntityPathFollower[entity].Destroy();
		g_iEntityPathFollower[entity] = view_as<PathFollower>(0);
	}
	
	// We can't check npc.IsValid() here because the NPC index is invalid at this point
	static char classname[128];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (StrContains(classname, "rf2_npc") != -1)
	{
		RF2_NPC_Base npc = RF2_NPC_Base(entity);
		if (npc.IsRaidBoss())
		{
			RF2_RaidBossSpawner(npc.RaidBossSpawner).OnBossKilled();
		}
	}
	
	g_flCashValue[entity] = 0.0;
	if (IsCombatChar(entity) || RF2_Object_Base(entity).IsValid() || RF2_Item(entity).IsValid())
	{
		KillAnnotation(entity);
	}
}

public void RF_CollideWithShields(int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return;
	
	float pos[3], mins[3], maxs[3];
	GetEntPos(entity, pos);
	GetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);
	TR_TraceHullFilter(pos, pos, mins, maxs, MASK_SOLID, TraceFilter_DispenserShield, GetEntTeam(entity), TRACE_ENTITIES_ONLY);
	if (TR_DidHit())
	{
		RemoveEntity(entity);
		return;
	}
	
	RequestFrame(RF_CollideWithShields, EntIndexToEntRef(entity));
}

public void RF_DragonFuryCritCheck(int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (!IsValidClient(owner))
		return;

	if (RollAttackCrit(owner))
	{
		SetEntProp(entity, Prop_Send, "m_bCritical", true);
		StopSound(owner, SNDCHAN_AUTO, SND_WEAPON_CRIT);
		EmitSoundToAll(SND_WEAPON_CRIT, owner);
	}
	
	int weapon = GetPlayerWeaponSlot(owner, WeaponSlot_Primary);
	if (weapon > 0)
	{
		static char classname[64];
		GetEntityClassname(weapon, classname, sizeof(classname));
		if (strcmp2(classname, "tf_weapon_rocketlauncher_fireball"))
		{
			float mult = GetPlayerFireRateMod(owner, weapon);
			//SetEntPropFloat(weapon, Prop_Send, "m_flRechargeScale", mult);
			TF2Attrib_SetByName(weapon, "item_meter_charge_rate", mult);
			if (0.8 / mult <= GetTickInterval())
			{
				TriggerAchievement(owner, ACHIEVEMENT_FIRERATECAP);
			}
		}
	}
}

bool IsEntityBlacklisted(const char[] classname)
{
	return (strcmp2(classname, "func_regenerate") || strcmp2(classname, "tf_ammo_pack")
	|| strcmp2(classname, "halloween_souls_pack") || strcmp2(classname, "func_respawnroom")
	|| strcmp2(classname, "teleport_vortex"));
}

public void Hook_ProjectileSpawnPost(int entity)
{
	RequestFrame(RF_ProjectileSpawnPost, EntIndexToEntRef(entity));
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
	}
	
	static char classname[128];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (strcmp2(classname, "tf_projectile_syringe") || strcmp2(classname, "tf_projectile_healing_bolt"))
	{
		// fix syringes and crossbow bolts not colliding with custom npcs
		SetEntityCollisionGroup(entity, COLLISION_GROUP_BREAKABLE_GLASS);
	}
}

static float g_flHealthKitSpawnTime[MAX_EDICTS];
public void Hook_HealthKitSpawnPost(int entity)
{
	g_flHealthKitSpawnTime[entity] = GetTickedTime();
	// make sure we don't accidentally delete thrown lunchbox items
	if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") <= 0)
	{
		RemoveEntity(entity);
	}
	else
	{
		SDKHook(entity, SDKHook_StartTouch, Hook_HealthKitStartTouch);
		SDKHook(entity, SDKHook_Touch, Hook_HealthKitTouch);
	}
}

public Action Hook_HealthKitStartTouch(int entity, int other)
{
	if (IsValidClient(other) && GetClientTeam(other) == TEAM_ENEMY)
		return Plugin_Handled;
	
	if (g_flHealthKitSpawnTime[entity]+0.3 < GetTickedTime()) // heavy can't pick up sandvich for 0.3s after throw
	{
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if (IsValidClient(owner) && owner == other)
		{
			int sandvich = GetPlayerWeaponSlot(owner, WeaponSlot_Secondary);
			if (sandvich != INVALID_ENT)
			{
				// if a heavy picks up his own sandvich, remove 1 sandvich from reserve
				// this is necessary to fix a stupid bug where heavy gets 2 sandviches instead of 1
				// if he picks up his own sandvich while having an increased ammo reserve cap
				int ammo = GetEntProp(owner, Prop_Send, "m_iAmmo", _, TFAmmoType_Jarate);
				SetEntProp(owner, Prop_Send, "m_iAmmo", ammo-1, _, TFAmmoType_Jarate);
				RequestFrame(RF_FixSandvichMeter, owner);
			}
		}
	}

	return Plugin_Continue;
}

static void RF_FixSandvichMeter(int owner)
{
	if (!IsClientInGame(owner))
		return;
	
	int maxAmmo = TF2Attrib_HookValueInt(1, "mult_maxammo_grenades1", owner);
	if (GetEntProp(owner, Prop_Send, "m_iAmmo", _, TFAmmoType_Jarate) < maxAmmo)
	{
		// also do this or else the meter will stop charging
		SetEntPropFloat(owner, Prop_Send, "m_flItemChargeMeter", 0.0, WeaponSlot_Secondary);
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
		if (!IsPlayerSurvivor(other) && !IsPlayerMinion(other) 
			&& (!IsFakeClient(other) || !TFBot(other).HasFlag(TFBOTFLAG_SCAVENGER)))
			return Plugin_Handled;
		
		PickupCash(other, entity);
	}
	
	return Plugin_Continue;
}

public Action Hook_OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &ammoType, int hitbox, int hitGroup)
{
	if (!RF2_IsEnabled() || !g_bRoundActive)
		return Plugin_Continue;
	
	if (IsValidClient(attacker))
	{
		if (PlayerHasItem(attacker, ItemScout_FedFedora) && CanUseCollectorItem(attacker, ItemScout_FedFedora))
		{
			// This hook gets called when shooting teammates apparently??
			if (damageType & DMG_BUCKSHOT && hitGroup == 1 && IsValidClient(victim) && GetClientTeam(attacker) != GetClientTeam(victim)
				&& GetActiveWeapon(attacker) == GetPlayerWeaponSlot(attacker, WeaponSlot_Primary))
			{
				if (IsValidClient(victim) && !IsBoss(victim) && !IsPlayerStunned(victim))
				{
					float chance = CalcItemMod_Hyperbolic(attacker, ItemScout_FedFedora, 1);
					if (RandChanceFloatEx(attacker, 0.001, 1.0, chance))
					{
						TF2_StunPlayer(victim, GetItemMod(ItemScout_FedFedora, 2), _, TF_STUNFLAG_BONKSTUCK, attacker);
						TriggerAchievement(attacker, ACHIEVEMENT_SCOUTSTUN);
					}
				}
				
				SetEntItemProc(attacker, ItemScout_FedFedora);
			}
		}

		RF2_NPC_Base npc = RF2_NPC_Base(victim);
		if (npc.IsValid() && hitGroup == 1 && damageType & DMG_USE_HITLOCATIONS && npc.CanBeHeadshot)
		{
			damageType |= DMG_CRIT;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon,
	float damageForce[3], float damagePosition[3], int damageCustom)
{
	if (!RF2_IsEnabled() || !g_bRoundActive || attacker >= MAX_EDICTS)
		return Plugin_Continue;

	bool victimIsClient = IsValidClient(victim);
	if (victimIsClient)
	{
		// this gets called for friendly fire -.-
		if (IsValidEntity2(attacker) && attacker != victim && GetEntTeam(victim) != GetEntTeam(attacker) 
			&& !IsInvuln(victim) && PlayerHasItem(victim, Item_Horace))
		{
			if (GetTickedTime()-g_flPlayerLastBlockTime[victim] >= GetItemMod(Item_Horace, 0))
			{
				// Block damage and heal
				TE_TFParticle("miss_text", damagePosition);
				EmitSoundToAll(g_szTeddyBearSounds[GetRandomInt(0, sizeof(g_szTeddyBearSounds)-1)], victim);
				HealPlayer(victim, CalcItemModInt(victim, Item_Horace, 1));
				TF2_AddCondition(victim, TFCond_UberchargedHidden, GetItemMod(Item_Horace, 2));
				g_flPlayerLastBlockTime[victim] = GetTickedTime();
				return Plugin_Handled;
			}
		}
		
		/*
		if (IsValidClient(attacker) && Enemy(attacker) != NULL_ENEMY && Enemy(attacker).SuicideBomber
			&& Enemy(attacker).SuicideBombFriendlyFire)
		{
			if (GetClientTeam(attacker) == GetClientTeam(victim) && damageType & DMG_BLAST)
			{
				damage = Enemy(attacker).SuicideBombDamage*2.0;
				return Plugin_Changed;
			}
		}
		*/
	}

	return Plugin_Continue;
}

float g_flDamageProc;
public Action TF2_OnTakeDamageModifyRules(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon,
	float damageForce[3], float damagePosition[3], int damageCustom, CritType &critType)
{
	if (!RF2_IsEnabled() || !g_bRoundActive || attacker >= MAX_EDICTS)
		return Plugin_Continue;
	
	CritType originalCritType = critType;
	float proc = 1.0;
	float originalDamage = damage;
	int originalDamageType = damageType;
	bool selfDamage = (attacker == victim || inflictor == victim);
	bool rangedDamage = (damageType & DMG_BULLET || damageType & DMG_BUCKSHOT || damageType & DMG_BLAST || damageType & DMG_IGNITE || damageType & DMG_SONIC);
	bool validWeapon = weapon > 0 && !IsCombatChar(weapon); // Apparently the weapon can be the attacker??
	bool inflictorIsBuilding = inflictor > 0 && IsBuilding(inflictor);
	bool victimIsClient = IsValidClient(victim);
	int attackerProc = GetEntItemProc(attacker);
	int inflictorProc = IsValidEntity2(inflictor) && inflictor < MAX_EDICTS ? GetEntItemProc(inflictor) : Item_Null;
	Call_StartForward(g_fwOnTakeDamage);
	Call_PushCell(victim);
	Call_PushCellRef(attacker);
	Call_PushCellRef(inflictor);
	Call_PushFloatRef(damage);
	Call_PushCellRef(damageType);
	Call_PushCellRef(weapon);
	Call_PushArray(damageForce, 3);
	Call_PushArray(damagePosition, 3);
	Call_PushCell(damageCustom);
	Call_PushCell(attackerProc);
	Call_PushCell(inflictorProc);
	Call_PushCellRef(critType);
	Call_PushFloatRef(proc);
	Action result;
	Call_Finish(result);
	if (result == Plugin_Handled || result == Plugin_Stop)
	{
		return result;
	}
	
	static char inflictorClassname[64];
	if (inflictor > 0)
	{
		GetEntityClassname(inflictor, inflictorClassname, sizeof(inflictorClassname));
	}

	int procItem = GetEntItemProc(attacker);
	if (inflictor > 0)
	{
		procItem = GetEntItemProc(inflictor);
	}

	if (procItem != Item_Null && IsValidClient(attacker) && IsEnemy(attacker))
	{
		damage *= Enemy(attacker).ItemDamageModifier;
	}
	
	if (victimIsClient && damageCustom == TF_CUSTOM_BACKSTAB && GetClientTeam(victim) == TEAM_ENEMY)
	{
		// resist powerup blocks backstabs, so just remove it
		TF2_RemoveCondition(victim, TFCond_RuneResist);
	}
	
	if (validWeapon && IsValidClient(attacker))
	{
		proc *= GetWeaponProcCoefficient(weapon);
		if (victimIsClient)
		{
			int itemDef = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			if (itemDef == 173) // Vita-Saw
			{
				TF2_AddCondition(victim, TFCond_Milked, 5.0, attacker);
			}
			else if (itemDef == 413) // Solemn Vow
			{
				TF2_AddCondition(victim, TFCond_Jarated, 5.0);
			}
			else if (itemDef == 1098) // The Classic
			{
				if (!IsPlayerStunned(victim))
				{
					TF2_StunPlayer(victim, 3.0, 0.6, TF_STUNFLAG_SLOWDOWN, attacker);
				}
			}
			else if (itemDef == 656) // Holiday Punch
			{
				TF2_AddCondition(victim, TFCond_Milked, 8.0);
			}
			else if (itemDef == 414) // Liberty Launcher
			{
				// apply z velocity attribute also applies for self damage, we don't want that
				if (IsPlayerSurvivor(attacker) && !selfDamage)
				{
					float vel[3];
					vel[2] = 300.0;
					vel[2] = TF2Attrib_HookValueFloat(vel[2], "damage_force_reduction", victim);
					ApplyAbsVelocityImpulse(victim, vel);
				}
			}

			bool afterburn = damageType & DMG_BURN && (damageCustom == TF_CUSTOM_BURNING || damageCustom == TF_CUSTOM_BURNING_FLARE 
				|| damageCustom == TF_CUSTOM_BURNING_ARROW || damageCustom == TF_CUSTOM_DRAGONS_FURY_BONUS_BURNING);

			if (PlayerHasItem(attacker, ItemPyro_LastBreath) && CanUseCollectorItem(attacker, ItemPyro_LastBreath))
			{
				if (afterburn)
				{
					damage *= 1.0 + CalcItemMod(attacker, ItemPyro_LastBreath, 2);
				}

				bool gas = TF2_IsPlayerInCondition(victim, TFCond_Gas);
				bool primary = weapon == GetPlayerWeaponSlot(attacker, WeaponSlot_Primary);
				bool shouldProcLastBreath = gas || validWeapon && (strcmp2(inflictorClassname, "tf_projectile_flare") || damageType & DMG_MELEE 
					|| !afterburn || GetPlayerWeaponSlot(attacker, WeaponSlot_Secondary) == weapon);

				if (victimIsClient && shouldProcLastBreath && (gas || !primary))
				{
					if (validWeapon && !primary && TF2_IsPlayerInCondition(victim, TFCond_MarkedForDeath) || TF2_IsPlayerInCondition(victim, TFCond_MarkedForDeathSilent))
					{
						damage *= 1.0 + CalcItemMod(attacker, ItemPyro_LastBreath, 1);
					}

					if (TF2_IsPlayerInCondition(victim, TFCond_OnFire) || TF2_IsPlayerInCondition(victim, TFCond_BurningPyro))
					{
						TF2_AddCondition(victim, TFCond_MarkedForDeathSilent, CalcItemMod(attacker, ItemPyro_LastBreath, 0), attacker);
					}
				}
			}
		}
	}
	
	if (inflictorIsBuilding)
	{
		if (IsSentryDisposable(inflictor))
		{
			// disposables don't proc items, period
			proc = 0.0;
		}
		else
		{
			proc *= 0.33;
		}
	}
	else if (inflictor > 0)
	{
		if (StrContains(inflictorClassname, "tf_projectile") == 0)
		{
			if (victimIsClient && IsPlayerSurvivor(victim) && HasEntProp(inflictor, Prop_Send, "m_iDeflected") && GetEntProp(inflictor, Prop_Send, "m_iDeflected"))
			{
				// Reflect damage against players should never do more than half their health
				damage = fmin(damage, float(RF2_GetCalculatedMaxHealth(victim))*0.5);
			}
			
			bool mangler = strcmp2(inflictorClassname, "tf_projectile_energy_ball");
			if (mangler || strcmp2(inflictorClassname, "tf_projectile_rocket") || strcmp2(inflictorClassname, "tf_projectile_sentryrocket"))
			{
				int offset = FindSendPropInfo("CTFProjectile_Rocket", "m_hLauncher") + 16;
				int enemy = GetEntDataEnt2(inflictor, offset); // m_hEnemy
				if (enemy != victim) // enemy == victim means direct damage was dealt, otherwise this is splash
				{
					proc *= 0.5; // reduced proc coefficient for splash damage
				}
				else if (validWeapon)
				{
					if (victimIsClient && !IsBoss(victim) && !IsPlayerStunned(victim)
						&& PlayerHasItem(attacker, ItemSoldier_Compatriot) 
						&& CanUseCollectorItem(attacker, ItemSoldier_Compatriot))
					{
						damage *= 1.0 + CalcItemMod(attacker, ItemSoldier_Compatriot, 2);
						float chance = CalcItemMod_Hyperbolic(attacker, ItemSoldier_Compatriot, 0);
						if (RandChanceFloatEx(attacker, 0.0, 1.0, chance))
						{
							TF2_StunPlayer(victim, GetItemMod(ItemSoldier_Compatriot, 1), _, TF_STUNFLAG_BONKSTUCK, attacker);
						}
					}
				}

				if (mangler && validWeapon && GetEntProp(inflictor, Prop_Send, "m_bChargedShot"))
				{
					// mangler charged shot does more damage with clip size
					damage *= 1.0 + (float(GetWeaponClipSize(weapon)) * 0.3);
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
		}
		else if (strcmp2(inflictorClassname, "entity_medigun_shield"))
		{
			proc *= 0.02;
			if (PlayerHasItem(attacker, ItemMedic_ProcedureMask) && CanUseCollectorItem(attacker, ItemMedic_ProcedureMask))
			{
				damage *= 1.0 + CalcItemMod(attacker, ItemMedic_ProcedureMask, 3, -1);
			}
		}
	}
	
	bool afterburn = damageType & DMG_BURN && (damageCustom == TF_CUSTOM_BURNING || damageCustom == TF_CUSTOM_BURNING_FLARE 
		|| damageCustom == TF_CUSTOM_BURNING_ARROW || damageCustom == TF_CUSTOM_DRAGONS_FURY_BONUS_BURNING);

	if (afterburn)
	{
		proc *= 0.0;
	}

	switch (damageCustom)
	{
		case TF_CUSTOM_BLEEDING:
		{
			proc *= 0.0;
			if (!selfDamage)
			{
				float bonus = 1.0;
				bonus += CalcItemMod(attacker, Item_Antlers, 2);
				if (CanUseCollectorItem(attacker, ItemSniper_Bloodhound))
				{
					bonus += CalcItemMod(attacker, ItemSniper_Bloodhound, 3);
				}
				
				bonus += CalcItemMod(attacker, Item_Executioner, 4);
				damage *= bonus;
			}
			else
			{
				// Players can stall themselves in the air indefinitely with self bleed damage, prevent this
				damageType |= DMG_PREVENT_PHYSICS_FORCE;
			}
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
	
	if (procItem > Item_Null)
	{
		proc *= GetItemProcCoeff(procItem);
	}

	if (IsValidClient(attacker) && attacker != victim && IsValidEntity2(inflictor))
	{
		bool rolledCrit;
		static char classname[128];
		GetEntityClassname(inflictor, classname, sizeof(classname));
		bool canCrit = attackerProc != ItemSniper_HolyHunter && !(StrContains(classname, "tf_proj") != -1 && HasEntProp(inflictor, Prop_Send, "m_bCritical"));
		
		// Check for full crits for any damage that isn't against a building and isn't from a weapon.
		if (!validWeapon && canCrit && !IsBuilding(victim))
		{
			if (critType != CritType_Crit)
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
			if (critType == CritType_Crit && !rolledCrit 
				&& IsValidClient(attacker) 
				&& IsPlayerSurvivor(attacker)
				&& (TF2_IsPlayerInCondition(attacker, TFCond_CritMmmph) || !IsPlayerCritBoosted(attacker)))
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
		
		if (inflictorProc == ItemPyro_PyromancerMask && critType != CritType_Crit && IsValidClient(victim))
		{
			if (TF2_IsPlayerInCondition(victim, TFCond_OnFire) || TF2_IsPlayerInCondition(victim, TFCond_BurningPyro))
			{
				if (TF2_IsPlayerInCondition(victim, TFCond_MarkedForDeath) || TF2_IsPlayerInCondition(victim, TFCond_MarkedForDeathSilent))
				{
					critType = CritType_Crit;
				}
				else
				{
					critType = CritType_MiniCrit;
				}
			}
		}
		
		if (attackerProc == ItemScout_FedFedora && critType == CritType_None)
		{
			critType = CritType_MiniCrit;
		}
		
		if (inflictorProc == ItemStrange_HandsomeDevil && critType == CritType_MiniCrit)
		{
			critType = CritType_Crit;
		}

		if (IsValidClient(victim)
			&& (IsValidClient(attacker) && IsEnemy(attacker) && Enemy(attacker).NoCrits 
				|| TF2_IsPlayerInCondition(victim, TFCond_DefenseBuffed) || TF2_IsPlayerInCondition(victim, TFCond_RuneResist)))
		{
			critType = CritType_None;
		}
		
		if (critType != CritType_None)
		{
			if (critType == CritType_Crit)
			{
				// Cryptic Keepsake converts crit chance to crit damage, other than its own crit chance
				if (PlayerHasItem(attacker, Item_CrypticKeepsake))
				{
					float mult = 1.0 + CalcItemMod(attacker, Item_TombReaders, 0) + CalcItemMod(attacker, Item_Executioner, 5);
					if (PlayerHasItem(attacker, Item_SaxtonHat) && damageType & DMG_MELEE)
					{
						mult += CalcItemMod(attacker, Item_SaxtonHat, 1);
					}
					
					damage *= mult;
				}
				
				// Executioner has a chance to cause bleeding on crit damage
				if (g_flPlayerNextExecutionerBleedTime[attacker] <= GetTickedTime()
					&& damageCustom != TF_CUSTOM_BLEEDING && PlayerHasItem(attacker, Item_Executioner)
					&& IsValidClient(victim) && !TF2_IsPlayerInCondition(victim, TFCond_Bonked))
				{
					if (RandChanceFloatEx(attacker, 0.001, 1.0, GetItemMod(Item_Executioner, 0) * proc))
					{
						TF2_MakeBleed(victim, attacker, GetItemMod(Item_Executioner, 1));
						g_flPlayerNextExecutionerBleedTime[attacker] = GetTickedTime()+0.2;
					}
				}
			}
		}
	}

	// Changing the crit type here will not change the damage, so we have to modify the damage manually
	if (originalCritType != critType)
	{
		switch (originalCritType)
		{
			case CritType_None:
			{
				damageType |= DMG_CRIT;
				if (critType == CritType_Crit) // None -> Crit
				{
					damage *= 3.0;
				}
				else // None -> Mini-Crit
				{
					damage *= 1.35;
				}
			}
			
			case CritType_MiniCrit:
			{
				if (critType == CritType_Crit) // Mini-Crit -> Crit
				{
					damage /= 1.35;
					damage *= 3.0;
				}
				else // Mini-Crit -> None
				{
					damage /= 1.35;
				}
			}
			
			case CritType_Crit:
			{
				if (critType == CritType_MiniCrit) // Crit -> Mini-Crit
				{
					damage /= 3.0;
					damage *= 1.35;
				}
				else // Crit -> None
				{
					damage /= 3.0;
				}
			}
		}
	}
	
	if (victimIsClient && damage > 0.0)
	{
		if (!selfDamage && PlayerHasItem(victim, Item_ApertureHat))
		{
			float time = GetItemMod(Item_ApertureHat, 1);
			if (g_flPlayerHardHatLastResistTime[victim]+time <= GetTickedTime())
			{
				damage *= CalcItemMod_Reciprocal(victim, Item_ApertureHat, 0);
				g_flPlayerHardHatLastResistTime[victim] = GetTickedTime();
				EmitGameSoundToAll("Player.ResistanceLight", victim);
				EmitGameSoundToAll("Player.ResistanceLight", victim);
			}
		}
	}

	if (victimIsClient && (PlayerHasItem(victim, Item_MetalHelmet) || PlayerHasItem(victim, ItemHeavy_Pugilist)))
	{
		float baseDmg;
		if (critType != CritType_None)
		{
			if (critType == CritType_Crit)
			{
				baseDmg = damage/3.0;
			}
			else if (critType == CritType_MiniCrit)
			{
				baseDmg = damage/1.35;
			}
		}
		else
		{
			baseDmg = damage;
		}

		if (!selfDamage && g_flPlayerHeavyArmorPoints[victim] > 0.0 && PlayerHasItem(victim, ItemHeavy_Pugilist) && CanUseCollectorItem(victim, ItemHeavy_Pugilist))
		{
			// Heavy Armor while spun up
			if (TF2_IsPlayerInCondition(victim, TFCond_Slowed))
			{
				damage *= 1.0 - (GetItemMod(ItemHeavy_Pugilist, 0) * (g_flPlayerHeavyArmorPoints[victim]/100.0));
				float maxHp = float(RF2_GetCalculatedMaxHealth(victim));
				float armorDeduction = (100.0 * (1.0-(fmax(maxHp-baseDmg, 0.0) / maxHp))) * GetItemMod(ItemHeavy_Pugilist, 2);
				g_flPlayerHeavyArmorPoints[victim] = fmax(g_flPlayerHeavyArmorPoints[victim]-armorDeduction, 0.0);
			}
		}

		if (g_iPlayerShieldHealth[victim] > 0 && PlayerHasItem(victim, Item_MetalHelmet))
		{
			if (rangedDamage)
			{
				damage *= GetItemMod(Item_MetalHelmet, 0);
			}
			
			if (critType != CritType_None)
			{
				float dmgBonus = damage-baseDmg;
				dmgBonus *= CalcItemMod_Reciprocal(victim, Item_MetalHelmet, 1);
				damage = baseDmg+dmgBonus;
			}

			if (!selfDamage)
			{
				g_iPlayerShieldHealth[victim] = imax(0, g_iPlayerShieldHealth[victim]-RoundToFloor(baseDmg));
				if (g_iPlayerShieldHealth[victim] <= 0)
				{
					EmitGameSoundToClient(victim, "Player.ResistanceHeavy");
					EmitGameSoundToClient(victim, "Player.ResistanceHeavy");
					g_flPlayerShieldRegenTime[victim] = GetGameTime() + GetItemMod(Item_MetalHelmet, 3);
				}
			}
		}

		damage = fmax(1.0, damage);
	}

	if (IsValidClient(attacker))
	{
		switch (damageCustom)
		{
			case TF_CUSTOM_HEADSHOT, TF_CUSTOM_HEADSHOT_DECAPITATION, TF_CUSTOM_PENETRATE_HEADSHOT:
			{
				g_flHeadshotDamage = damage;
				if (IsValidClient(victim) && PlayerHasItem(attacker, ItemSniper_Bloodhound) && CanUseCollectorItem(attacker, ItemSniper_Bloodhound))
				{
					g_bPlayerHeadshotBleeding[victim] = true;
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
		}
	}

	// Raid bosses never take more than 3.5% of their max HP from a backstab
	if (damageType & DMG_MELEE && damageType & DMG_CRIT && damageType & DMG_SLASH && validWeapon && IsValidClient(attacker) && IsPlayerSurvivor(attacker) 
		&& !IsPlayerMinion(attacker) && RF2_NPC_Base(victim).IsValid() && RF2_NPC_Base(victim).IsRaidBoss() && RF2_NPC_Base(victim).CanBeBackstabbed
		&& TF2_GetPlayerClass(attacker) == TFClass_Spy)
	{
		static char weaponClass[128];
		GetEntityClassname(weapon, weaponClass, sizeof(weaponClass));
		if (strcmp2(weaponClass, "tf_weapon_knife"))
		{
			damage = fmin(damage, float(RF2_NPC_Base(victim).MaxHealth)*0.035);
		}
	}

	g_flDamageProc = proc;
	return damage != originalDamage || originalDamageType != damageType || originalCritType != critType ? Plugin_Changed : Plugin_Continue;
}

public Action Hook_OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon,
float damageForce[3], float damagePosition[3], int damageCustom)
{
	if (!RF2_IsEnabled() || attacker >= MAX_EDICTS)
		return Plugin_Continue;
	
	if (IsValidClient(victim))
	{
		GameRules_SetProp("m_bPlayingMannVsMachine", false); // prevent server crash from a dhook we use
	}
	
	if (!g_bRoundActive)
		return Plugin_Continue;
	
	float proc = g_flDamageProc;
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

		static char wepClassname[64];
		GetEntityClassname(weapon, wepClassname, sizeof(wepClassname));
		if (strcmp2(wepClassname, "tf_weapon_flamethrower"))
		{
			damage *= GetPlayerFireRateMod(attacker, weapon); // Fire rate increases flamethrower damage
		}
	}

	// backstabs first, before any damage modifiers get applied
	if (damageCustom == TF_CUSTOM_BACKSTAB)
	{
		if (IsPlayerSurvivor(victim) && !IsPlayerMinion(victim))
		{
			damage = float(RF2_GetCalculatedMaxHealth(victim)) * 0.35;
			return Plugin_Changed;
		}
		else if (IsPlayerMinion(attacker))
		{
			damage = 200.0;
		}
		else if (IsBoss(victim))
		{
			int stabType = g_cvBossStabDamageType.IntValue;
			if (stabType == 0)
			{
				damage = g_cvBossStabDamageAmount.FloatValue;
			}
			else if (stabType == 1)
			{
				damage = float(RF2_GetCalculatedMaxHealth(victim)) * g_cvBossStabDamagePercent.FloatValue;
			}
			
			damage *= 1.0 + CalcItemMod(attacker, ItemSpy_NohMercy, 0);
			if (IsFakeClient(victim))
			{
				TFBot(victim).RealizeSpy(attacker);
			}
		}
	}
	else
	{
		RF2_NPC_Base npc = RF2_NPC_Base(victim);
		if (npc.IsValid() && npc.CanBeBackstabbed && damageType & DMG_MELEE && validWeapon
			&& IsPlayerSurvivor(attacker) && !IsPlayerMinion(attacker) && TF2_GetPlayerClass(attacker) == TFClass_Spy 
			&& weapon == GetPlayerWeaponSlot(attacker, WeaponSlot_Melee))
		{
			// NPC backstabs (snatched code from Slender Fortress)
			float npcPos[3], eyePos[3], buffer[3], angles[3];
			GetClientEyePosition(attacker, eyePos);
			npc.WorldSpaceCenter(npcPos);
			npc.GetAbsAngles(angles);
			SubtractVectors(eyePos, npcPos, buffer);
			GetVectorAngles(buffer, buffer);
			float diff = FloatAbs(AngleNormalize(buffer[1] - angles[1]));
			if (diff >= 90.0)
			{
				damageType |= DMG_CRIT;
				damage = npc.BaseBackstabDamage * (1.0+CalcItemMod(attacker, ItemSpy_NohMercy, 0));
				if (npc.IsRaidBoss())
				{
					// cooldown for raid boss NPCs so spies don't shred them instantly
					EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100);
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime() + 2.0);
				}

				int meleeIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
				switch (meleeIndex)
				{
					case 356: // Kunai
					{
						HealPlayer(attacker, TF2Attrib_HookValueInt(0, "heal_on_kill", weapon));
					}
					case 461: // Big Earner
					{
						TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 4.0);
					}
				}
			}
		}
	}
	
	if (inflictorIsBuilding)
	{
		// Reduce self damage from bullets
		if (victim == attacker)
		{
			damage *= 0.4;
			damageType &= ~DMG_CRIT;
			return Plugin_Changed;
		}
		else
		{
			// No sentry knockback
			damageType |= DMG_PREVENT_PHYSICS_FORCE;
		}
	}
	
	bool selfDamage = (attacker == victim || inflictor == victim);
	// reduce damage taken in singleplayer since the player will usually be the target of all incoming fire
	// also can apply in multiplayer but only on scrap
	if (victimIsClient && (IsSingleplayer(false) || g_iDifficultyLevel <= DIFFICULTY_SCRAP) && IsPlayerSurvivor(victim) 
		&& (validWeapon || !selfDamage) && (IsCombatChar(attacker) || IsCombatChar(inflictor)))
	{
		if (g_iDifficultyLevel <= DIFFICULTY_SCRAP)
		{
			damage *= 0.6;
		}
		else
		{
			damage *= 0.8;
		}
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
	
	bool rangedDamage = (damageType & DMG_BULLET || damageType & DMG_BUCKSHOT || damageType & DMG_BLAST || damageType & DMG_IGNITE || damageType & DMG_SONIC);
	bool invuln = victimIsClient && IsInvuln(victim);
	
	if (victimIsClient)
	{
		if (PlayerHasItem(victim, Item_Goalkeeper))
		{
			int activeWeapon = GetActiveWeapon(victim);
			if (activeWeapon != INVALID_ENT && activeWeapon == GetPlayerWeaponSlot(victim, WeaponSlot_Melee))
			{
				damage *= 1.0 + CalcItemMod(victim, Item_Goalkeeper, 3);
			}
		}
	}
	else if (victimIsNpc)
	{
		if (inflictorIsBuilding)
		{
			if (RF2_SentryBuster(victim).IsValid())
			{
				damage *= 0.1;
				damage = fmax(damage, 1.0);
			}
		}
		else if (IsTank(victim))
		{
			if (validWeapon)
			{
				static char classname[128];
				GetEntityClassname(weapon, classname, sizeof(classname));
				if (StrContains(classname, "tf_weapon_minigun") == 0)
				{
					damage *= 2.0; // Miniguns have a 75% damage penalty against Tanks, let's make that 50% instead.
				}
				
				if (attackerIsClient && IsPlayerSurvivor(attacker) && g_iPlayerLastAttackedTank[attacker] != victim)
				{
					g_iPlayerLastAttackedTank[attacker] = victim;
				}
			}
		}
	}
	
	if (attackerIsClient)
	{
		if (IsPlayerMinion(attacker) && validWeapon)
		{
			CBaseEntity(attacker).RemoveFlag(FL_NOTARGET);
		}
		
		int procItem = GetEntItemProc(attacker);
		if (inflictor > 0)
		{
			procItem = GetEntItemProc(inflictor);
		}
		
		if (!selfDamage)
		{
			damage *= GetPlayerDamageMult(attacker);
		}
		
		if (!selfDamage && PlayerHasItem(attacker, Item_BeaconFromBeyond) && RF2_Object_Teleporter.IsEventActive())
		{
			damage *= CalcItemMod_Reciprocal(attacker, Item_BeaconFromBeyond, 1);
		}
		
		if (inflictor > 0 && GetEntItemProc(inflictor) > Item_Null && GetEntItemProc(inflictor) <= MAX_ITEMS)
		{
			proc *= GetItemProcCoeff(GetEntItemProc(inflictor));
		}
		
		if (damageType & DMG_BLAST && /*PlayerHasItem(attacker, ItemDemo_OldBrimstone) &&*/ CanUseCollectorItem(attacker, ItemDemo_OldBrimstone))
		{
			if (selfDamage)
			{
				// don't increase self damage and make sure we don't get hit by the increased explosion radius from our own weapons
				if (StrContains(inflictorClassname, "tf_projectile_pipe") != -1)
				{
					// check both origin + eye pos
					float myPos[3], eyePos[3], pipePos[3];
					GetEntPos(victim, myPos);
					GetClientEyePosition(victim, eyePos);
					GetEntPos(inflictor, pipePos);
					const float dist = 200.0;
					// pipe/sticky radius is 146, but this does seem a bit inaccurate because the game detects it differently, so add more leniency
					if (GetVectorDistance(myPos, pipePos) > dist && GetVectorDistance(eyePos, pipePos) > dist)
					{
						return Plugin_Handled;
					}
				}
			}
			else
			{
				damage *= 1.0 + CalcItemMod(attacker, ItemDemo_OldBrimstone, 0);
			}
		}
		
		if (damageType & DMG_MELEE && GetClientTeam(attacker) != TEAM_SURVIVOR)
		{
			// getting juggled by melee attacks is annoying
			damageType |= DMG_PREVENT_PHYSICS_FORCE;
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
					time *= CalcItemMod_Reciprocal(attacker, ItemEngi_BrainiacHairpiece, 1, -1);
					g_flSentryNextLaserTime[inflictor] = GetTickedTime()+time;
				}
			}
		}
		
		if (!victimIsBuilding && !victimIsNpc)
		{
			if (selfDamage && IsEnemy(victim) && !Enemy(victim).AllowSelfDamage && damageCustom != TF_CUSTOM_TELEFRAG)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
			
			// backstabs do set damage against survivors and bosses
			if (damageCustom == TF_CUSTOM_BACKSTAB)
			{
				if (PlayerHasItem(attacker, ItemSpy_Showstopper) && CanUseCollectorItem(attacker, ItemSpy_Showstopper))
				{
					if (g_flPlayerKnifeStunCooldown[attacker] <= 0.0)
					{
						float dmg = GetItemMod(ItemSpy_Showstopper, 0) + CalcItemMod(attacker, ItemSpy_Showstopper, 1, -1);
						float radius = GetItemMod(ItemSpy_Showstopper, 2) + CalcItemMod(attacker, ItemSpy_Showstopper, 3, -1);
						float duration = GetItemMod(ItemSpy_Showstopper, 4);
						float pos[3];
						CBaseEntity(victim).WorldSpaceCenter(pos);
						ArrayList hitEnts = DoRadiusDamage(attacker, attacker, pos, ItemSpy_Showstopper, dmg, DMG_BLAST|DMG_CLUB, radius, _, _, _, true);
						int hitEnt = INVALID_ENT;
						for (int i = 0; i < hitEnts.Length; i++)
						{
							hitEnt = hitEnts.Get(i);
							if (IsValidClient(hitEnt) && !IsBoss(hitEnt) && !IsPlayerStunned(hitEnt))
							{
								TF2_StunPlayer(hitEnt, duration, _, TF_STUNFLAG_BONKSTUCK, attacker);
								TF2_AddCondition(hitEnt, TFCond_FreezeInput, duration, attacker);
							}
						}
						
						g_flPlayerKnifeStunCooldown[attacker] = GetItemMod(ItemSpy_Showstopper, 6);
						delete hitEnts;
					}
				}
			}
			
			if (procItem == ItemSpy_Showstopper && IsBoss(victim))
			{
				damage *= GetItemMod(ItemSpy_Showstopper, 5);
			}
		}
		
		if (!selfDamage && !invuln)
		{
			if (PlayerHasItem(attacker, Item_PointAndShoot))
			{
				int maxStacks = CalcItemModInt(attacker, Item_PointAndShoot, 0);
				if (g_iPlayerFireRateStacks[attacker] < maxStacks)
				{
					g_iPlayerFireRateStacks[attacker]++;
					UpdatePlayerFireRate(attacker);
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
				
				if (TF2_IsPlayerInCondition(attacker, TFCond_RuneKnockout))
				{
					// Knockout doesn't function by itself outside of Mannpower, so make it double melee damage and do heavy knockback
					damage *= 2.0;
					if (victimIsClient)
					{
						float vel[3], angles[3], pos1[3], pos2[3];
						GetEntPos(attacker, pos1, true);
						GetEntPos(victim, pos2, true);
						GetVectorAnglesTwoPoints(pos1, pos2, angles);
						angles[0] = -60.0;
						GetAngleVectors(angles, vel, NULL_VECTOR, NULL_VECTOR);
						NormalizeVector(vel, vel);
						ScaleVector(vel, 500.0);
						ScaleVector(vel, TF2Attrib_HookValueFloat(1.0, "damage_force_reduction", victim));
						ApplyAbsVelocityImpulse(victim, vel);
						RemoveAllRunes(victim);
					}
				}
			}
			else
			{
				if (PlayerHasItem(attacker, Item_Goalkeeper))
				{
					// Ranged damage penalty
					damage *= CalcItemMod_Reciprocal(attacker, Item_Goalkeeper, 2);
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
			if (halloweenNpc)
			{
				if (!(damageType & DMG_CRIT) && !validWeapon)
				{
					int attackerProc = GetLastEntItemProc(attacker);
					bool canCrit = attackerProc != ItemSniper_HolyHunter && !(inflictor != INVALID_ENT && StrContains(inflictorClassname, "tf_proj") != -1 && HasEntProp(inflictor, Prop_Send, "m_bCritical"));
					if (canCrit && RollAttackCrit(attacker))
					{
						damageType |= DMG_CRIT;
					}
				}
				
				// Keep track of who damages us
				g_flLastHalloweenBossAttackTime[victim][attacker] = GetGameTime();
			}
			
			if (halloweenNpc && IsSkeleton(victim) && damageType & DMG_CRIT)
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
			if (victimIsClient && IsPlayerSurvivor(victim) && !PlayerHasItem(victim, Item_HorsemannHead))
			{
				// reduce damage to players that aren't carrying the item
				damage *= 0.4;
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
			
			// don't scale sentry buster damage vs Survivors
			if (!victimIsClient || !RF2_SentryBuster(attacker).IsValid() || IsPlayerMinion(victim) || !IsPlayerSurvivor(victim))
			{
				damage *= GetEnemyDamageMult();
			}
			
			if (monoculus && victimIsClient && IsPlayerSurvivor(victim) && !PlayerHasItem(victim, Item_Monoculus))
			{
				// reduce damage to players that aren't carrying the item
				damage *= 0.4;
			}
		}
	}
	
	// Now for our resistances
	if (victimIsClient && !ignoreResist)
	{
		if (rangedDamage && PlayerHasItem(victim, Item_DarkHelm))
		{
			damage *= 1.0 - GetItemMod(Item_DarkHelm, 0);
		}
		
		if (PlayerHasItem(victim, ItemSpy_CounterfeitBillycock) && CanUseCollectorItem(victim, ItemSpy_CounterfeitBillycock))
		{
			// If we're disguised and uncloaked, this item gives us resist
			if (TF2_IsPlayerInCondition(victim, TFCond_Disguised) && !TF2_IsPlayerInCondition(victim, TFCond_Cloaked))
			{
				damage *= CalcItemMod_Reciprocal(victim, ItemSpy_CounterfeitBillycock, 1);
			}
		}

		if (damage > 0.0 && PlayerHasItem(victim, Item_SpiralSallet))
		{
			damage -= CalcItemMod(victim, Item_SpiralSallet, 0);
		}

		damage = fmax(damage, 1.0);
	}

	if (victimIsBuilding && RF2_Projectile_Base(inflictor).IsValid())
	{
		damage *= RF2_Projectile_Base(inflictor).BuildingDamageMult;
	}

	// self blast damage is reduced and capped
	if (victimIsClient && selfDamage && rangedDamage && (validWeapon || inflictorIsBuilding) && IsPlayerSurvivor(victim))
	{
		damage = float(RF2_GetCalculatedMaxHealth(victim)) * 0.15;
		
		// Special damage reduction rules for Soldier
		if (TF2_GetPlayerClass(victim) == TFClass_Soldier)
		{
			static float lastRocketJumpTime[MAXPLAYERS];
			if (GetEntityFlags(victim) & FL_ONGROUND
				|| !TF2_IsPlayerInCondition(victim, TFCond_BlastJumping)
		 		|| lastRocketJumpTime[victim]+1.0 >= GetTickedTime())
			{
				// Reduce self damage based on fire+reload rate IF we are not rocket jumping.
				// Also don't blow ourselves up if we rocket jump with several rockets at once.
				damage *= Pow(GetPlayerFireRateMod(victim) * GetPlayerReloadMod(victim), 0.75);
			}
			else
			{
				// Rocket jumping extends health regen time a bit
				g_flPlayerHealthRegenTime[victim] += 2.0;
				g_flPlayerHealthRegenTime[victim] = fmin(g_flPlayerHealthRegenTime[victim], 5.0);
				lastRocketJumpTime[victim] = GetTickedTime();
			}
		}
		
		if (damageType & DMG_BLAST && validWeapon)
		{
			damage = fmax(damage, float(RF2_GetCalculatedMaxHealth(victim))*0.005);
		}
	}

	g_flDamageProc = proc; // carry over to other damage hooks
	if (victimIsClient && !selfDamage && DoesPlayerHaveOSP(victim))
	{
		// One-shot protection: if a Survivor is above 90% HP, damage cannot deal more than 90% of max HP.
		float maxDmg = float(RF2_GetCalculatedMaxHealth(victim))*0.9;
		if (damage > maxDmg)
		{
			TF2_AddCondition(victim, TFCond_UberchargedHidden, 0.5);
			TF2_RemoveCondition(victim, TFCond_Bleeding);
			TF2_RemoveCondition(victim, TFCond_OnFire);
			TF2_RemoveCondition(victim, TFCond_BurningPyro);
			TF2_RemoveCondition(victim, TFCond_Gas);
			g_flPlayerHealthRegenTime[victim] = 5.0; // since invuln blocks health regen timer
		}
		
		damage = fmin(damage, maxDmg);
	}
	
	damage = fmin(damage, 2147483647.0);
	return damage != originalDamage || originalDamageType != damageType ? Plugin_Changed : Plugin_Continue;
}

public void Hook_OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damageType, int weapon,
const float damageForce[3], const float damagePosition[3], int damageCustom)
{
	if (!RF2_IsEnabled() || attacker >= MAX_EDICTS)
		return;
	
	bool attackerIsClient = IsValidClient(attacker);
	bool victimIsClient = IsValidClient(victim);
	bool invuln = victimIsClient && IsInvuln(victim);
	bool validWeapon = weapon > 0 && !IsCombatChar(weapon); // Apparently the weapon can be the attacker??
	bool selfDamage = victim == attacker;
	float proc = g_flDamageProc;
	
	if (victimIsClient)
	{
		Enemy enemy = Enemy(victim);
		if (enemy != NULL_ENEMY && enemy.SuicideBomber && GetClientHealth(victim) <= 1 && !IsInvuln(victim)
			&& !TF2_IsPlayerInCondition(victim, TFCond_Taunting))
		{
			SetEntityHealth(victim, 1);
			FakeClientCommand(victim, "taunt");
		}
		
		if (CanPlayerRegen(victim) && damage > 0.0 && !invuln)
		{
			const float regenTimeMin = 0.5;
			const float regenTimeMax = 5.0;
			float seconds = fmax(5.0 * (damage / float(RF2_GetCalculatedMaxHealth(victim))), regenTimeMin);
			g_flPlayerHealthRegenTime[victim] = fmin(g_flPlayerHealthRegenTime[victim]+seconds, regenTimeMax);
		}
		
		if (!invuln && !g_bGracePeriod)
		{
			if (PlayerHasItem(victim, Item_PocketMedic) && !GetRF2GameRules().DisableDeath)
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
		
		if (PlayerHasItem(victim, Item_CheatersLament) && GetClientHealth(victim) <= 0 
			&& !g_bGracePeriod && !GetRF2GameRules().DisableDeath)
		{
			SetEntityHealth(victim, RF2_GetCalculatedMaxHealth(victim));
			TF2_AddCondition(victim, TFCond_UberchargedCanteen);
			TF2_AddCondition(victim, TFCond_UberBulletResist);
			TF2_AddCondition(victim, TFCond_UberBlastResist);
			TF2_AddCondition(victim, TFCond_UberFireResist);
			TF2_AddCondition(victim, TFCond_MegaHeal);
			TF2_AddCondition(victim, TFCond_CritOnFirstBlood);
			TF2_SetPlayerPowerPlay(victim, true);
			g_bPlayerReviveActivated[victim] = true;
			CreateTimer(GetItemMod(Item_CheatersLament, 0), Timer_PowerPlayExpire, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
			GiveItem(victim, Item_CheatersLament, -1);
			GiveItem(victim, Item_CheatersLament_Recharging, 1, true);
		}
		
		if (!selfDamage && !invuln && proc > 0.0 
			&& PlayerHasItem(victim, Item_Capacitor) && (!attackerIsClient || GetEntItemProc(attacker) != Item_Capacitor)
			&& RandChanceFloatEx(victim, 0.001, 1.0, GetItemMod(Item_Capacitor, 3)))
		{
			float range = GetItemMod(Item_Capacitor, 0);
			if (DistBetween(victim, attacker) <= range)
			{
				float dmgDealt = CalcItemMod(victim, Item_Capacitor, 1) * proc;
				RF_TakeDamage(attacker, victim, victim, dmgDealt, DMG_PREVENT_PHYSICS_FORCE|DMG_SHOCK, Item_Capacitor);
				float victimPos[3], attackerPos[3];
				GetEntPos(victim, victimPos, true);
				GetEntPos(attacker, attackerPos, true);
				if (attackerIsClient)
				{
					float angles[3], vel[3];
					GetVectorAnglesTwoPoints(victimPos, attackerPos, angles);
					angles[0] = -40.0;
					GetAngleVectors(angles, vel, NULL_VECTOR, NULL_VECTOR);
					NormalizeVector(vel, vel);
					float force = CalcItemMod(victim, Item_Capacitor, 2) * fmax(proc, 0.5);
					ScaleVector(vel, force);
					ScaleVector(vel, TF2Attrib_HookValueFloat(1.0, "damage_force_reduction", attacker));
					TeleportEntity(attacker, _, _, vel);
				}
				
				EmitGameSoundToAll("Player.ResistanceHeavy", attacker);
				EmitGameSoundToAll("Weapon_BarretsArm.Zap", victim);
				TE_SetupBeamPoints(victimPos, attackerPos, 
					g_iBeamModel, 0, 0, 0, 0.5, 8.0, 8.0, 0, 10.0, {255, 50, 50, 255}, 20);
				TE_SendToAll();
			}
		}
		
		if (attackerIsClient && validWeapon)
		{
			int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			if (index == 740)
			{
				// remove scorch shot knockback
				if (!TF2_IsPlayerInCondition(victim, TFCond_ImmuneToPushback))
				{
					TF2_AddCondition(victim, TFCond_ImmuneToPushback, 0.001);
				}
			}
		}

		if (attackerIsClient && !selfDamage && !invuln && PlayerHasAnyRune(victim))
		{
			if (PlayerHasItem(attacker, Item_Ballcap) && GetEntItemProc(attacker) != Item_Ballcap
				// FIXME: Somehow, procing Rotation Sensation with the rollermine causes a server crash.
				&& GetEntItemProc(attacker) != ItemStrange_JackHat 
				&& RandChanceFloatEx(attacker, 0.001, 1.0, GetItemMod(Item_Ballcap, 0)*proc))
			{
				TFCond rune = GetPlayerRune(victim);
				RemoveAllRunes(victim);
				RemoveAllRunes(attacker);
				TF2_AddCondition(attacker, rune, CalcItemMod(attacker, Item_Ballcap, 4));
				char soundBuffer[PLATFORM_MAX_PATH];
				switch (rune)
				{
					case TFCond_RuneAgility: strcopy(soundBuffer, sizeof(soundBuffer), SND_RUNE_AGILITY);
					case TFCond_RuneHaste: strcopy(soundBuffer, sizeof(soundBuffer), SND_RUNE_HASTE);
					case TFCond_RuneKnockout: strcopy(soundBuffer, sizeof(soundBuffer), SND_RUNE_KNOCKOUT);
					case TFCond_RunePrecision: strcopy(soundBuffer, sizeof(soundBuffer), SND_RUNE_PRECISION);
					case TFCond_RuneRegen: strcopy(soundBuffer, sizeof(soundBuffer), SND_RUNE_REGEN);
					case TFCond_RuneResist: strcopy(soundBuffer, sizeof(soundBuffer), SND_RUNE_RESIST);
					case TFCond_RuneStrength: strcopy(soundBuffer, sizeof(soundBuffer), SND_RUNE_STRENGTH);
					case TFCond_RuneVampire: strcopy(soundBuffer, sizeof(soundBuffer), SND_RUNE_VAMPIRE);
					case TFCond_RuneWarlock: strcopy(soundBuffer, sizeof(soundBuffer), SND_RUNE_WARLOCK);
				}

				EmitSoundToAll(soundBuffer, attacker);
				float pos[3];
				GetEntPos(victim, pos, true);
				DoExplosionEffect(pos);
				ArrayList hitEnts = DoRadiusDamage(attacker, attacker, pos, 
					Item_Ballcap, CalcItemMod(attacker, Item_Ballcap, 1), DMG_BLAST|DMG_PREVENT_PHYSICS_FORCE, 
					GetItemMod(Item_Ballcap, 2), _, _, _, true);

				for (int i = 0; i < hitEnts.Length; i++)
				{
					int entity = hitEnts.Get(i);
					if (IsValidClient(entity))
					{
						TF2_StunPlayer(entity, CalcItemMod(attacker, Item_Ballcap, 3), _, TF_STUNFLAG_BONKSTUCK, attacker);
					}
				}

				delete hitEnts;
			}
		}

		if (PlayerHasItem(victim, Item_Hachimaki) && !IsInvuln(victim))
		{
			g_flPlayerDelayedHealTime[victim] = GetTickedTime()+GetItemMod(Item_Hachimaki, 0);
		}
	}
	else if (IsTank(victim))
	{
		if (IsValidClient(attacker) && GetEntProp(victim, Prop_Data, "m_iHealth") <= 0)
		{
			TriggerAchievement(attacker, ACHIEVEMENT_TANKBUSTER);
		}
	}
	else
	{
		bool skeleton = IsSkeleton(victim);
		if (skeleton)
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

		if ((skeleton || RF2_NPC_Base(victim).IsValid()) 
			&& validWeapon && GetPlayerWeaponSlot(attacker, WeaponSlot_Primary) == weapon && TF2Attrib_HookValueInt(0, "mod_use_metal_ammo_type", weapon) > 0)
		{
			// Skeletons and NPCS don't give widowmaker ammo by default, do it next frame because the metal hasn't been depleted yet
			DataPack pack = new DataPack();
			pack.WriteCell(GetClientUserId(attacker));
			pack.WriteCell(RoundToFloor(damage));
			RequestFrame(RF_WidowmakerAmmo, pack);
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
			if ((damageType & DMG_BULLET || damageType & DMG_BUCKSHOT))
			{
				if (PlayerHasItem(attacker, ItemHeavy_GoneCommando) && CanUseCollectorItem(attacker, ItemHeavy_GoneCommando))
				{
					float chance = GetItemMod(ItemHeavy_GoneCommando, 3) * proc;
					if (RandChanceFloatEx(attacker, 0.0, 1.0, chance))
					{
						int count = GetItemModInt(ItemHeavy_GoneCommando, 2);
						float pos[3], angles[3];
						GetEntPos(victim, pos, true);
						angles[1] = GetRandomFloat(-179.0, 179.0);
						float dmg = GetItemMod(ItemHeavy_GoneCommando, 0) + CalcItemMod(attacker, ItemHeavy_GoneCommando, 1, -1);
						for (int i = 1; i <= count; i++)
						{
							RF2_Projectile_Shrapnel shrapnel = RF2_Projectile_Shrapnel(ShootProjectile(attacker, "rf2_projectile_shrapnel", pos, angles, 1000.0, dmg));
							shrapnel.AddIgnoredEnt(victim);
							angles[1] = GetRandomFloat(-179.0, 179.0);
						}
					}
				}

				if (PlayerHasItem(attacker, ItemHeavy_ToughGuyToque) && CanUseCollectorItem(attacker, ItemHeavy_ToughGuyToque))
				{
					g_bPlayerFullMinigunMoveSpeed[attacker] = true;
					TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, CalcItemMod(attacker, ItemHeavy_ToughGuyToque, 2));
				}
			}
		}
		
		if (!selfDamage && !invuln)
		{
			if (g_flPlayerNextLawFireTime[attacker] <= GetTickedTime() 
				&& PlayerHasItem(attacker, Item_Law) && inflictor > 0 && procItem != Item_Law)
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
					float dmg = GetItemMod(Item_Law, 1) + CalcItemMod(attacker, Item_Law, 2, -1);
					int rocket = ShootProjectile(attacker, "tf_projectile_rocket", pos, angles, rocketSpeed, dmg);
					SetShouldDamageOwner(rocket, false);
					SetEntItemProc(rocket, Item_Law);
					EmitSoundToAll(SND_LAW_FIRE, attacker, _, _, _, 0.6);
					g_flPlayerNextLawFireTime[attacker] = GetTickedTime()+0.4;
				}
			}
			
			if (PlayerHasItem(attacker, Item_HorrificHeadsplitter) && damageType & DMG_MELEE)
			{
				HealPlayer(attacker, CalcItemModInt(attacker, Item_HorrificHeadsplitter, 0), false);
				TF2_RemoveCondition(attacker, TFCond_Bleeding);
				if (victimIsClient)
				{
					TF2_MakeBleed(victim, attacker, GetItemMod(Item_HorrificHeadsplitter, 2));
				}

				g_bPlayerMeleeMiss[attacker] = false;
			}
			
			if (PlayerHasItem(attacker, Item_RoBro) && procItem != Item_RoBro)
			{
				float chance = GetItemMod(Item_RoBro, 0) * proc;
				if (RandChanceFloatEx(attacker, 0.0, 1.0, chance))
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
							if (!IsValidEntity2(entity) || entity == victim || !IsCombatChar(entity) || hitEnemies.FindValue(entity) != INVALID_ENT)
								continue;
							
							if (GetEntTeam(entity) == team)
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
							DataPack pack = new DataPack();
							pack.WriteCell(EntIndexToEntRef(closestEnemy));
							pack.WriteCell(EntIndexToEntRef(attacker));
							pack.WriteFloat(dmg);
							RequestFrame(RF_RoBroDealDamage, pack);
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

			switch (damageCustom)
			{
				case TF_CUSTOM_CHARGE_IMPACT:
				{
					if (PlayerHasItem(attacker, ItemDemo_OldBrimstone) && CanUseCollectorItem(attacker, ItemDemo_OldBrimstone))
					{
						float boomPos[3];
						GetEntPos(attacker, boomPos, true);
						float dmg = GetItemMod(ItemDemo_OldBrimstone, 2);
						float radius = GetItemMod(ItemDemo_OldBrimstone, 3) * (1.0 + CalcItemMod(attacker, ItemDemo_OldBrimstone, 1));
						DoRadiusDamage(attacker, attacker, boomPos, ItemDemo_OldBrimstone, dmg, DMG_BLAST, radius);
						DoExplosionEffect(boomPos);
					}
				}
			}
			
			if (PlayerHasItem(attacker, Item_AlienParasite) && g_flPlayerNextParasiteHealTime[attacker] <= GetTickedTime())
			{
				HealPlayer(attacker, CalcItemModInt(attacker, Item_AlienParasite, 0));
				g_flPlayerNextParasiteHealTime[attacker] = GetTickedTime()+0.1;
			}
			
			if (IsPlayerSurvivor(attacker))
			{
				if (damage >= 10000.0 && damageCustom != TF_CUSTOM_BACKSTAB && !selfDamage)
				{
					TriggerAchievement(attacker, ACHIEVEMENT_BIGDAMAGE);
				}
				
				/*
				if (damage >= 32767.0 && damageCustom != TF_CUSTOM_BACKSTAB && !selfDamage)
				{
					TriggerAchievement(attacker, ACHIEVEMENT_DAMAGECAP);
				}
				*/
			}

			if (PlayerHasItem(attacker, Item_OldCrown) && validWeapon)
			{
				int entity = INVALID_ENT;
				while ((entity = FindEntityByClassname(entity, "rf2_projectile_fireball")) != INVALID_ENT)
				{
					RF2_Projectile_Fireball fireball = RF2_Projectile_Fireball(entity);
					if (GetEntItemProc(fireball.index) == Item_OldCrown && fireball.Owner == attacker && fireball.HomingTarget == fireball.Owner)
					{
						// Unleash the fire upon this poor soul
						fireball.HomingSpeed = 400.0;
						fireball.HomingTarget = victim;
					}
				}
			}
		}
	}
}

public void RF_RoBroDealDamage(DataPack pack)
{
	pack.Reset();
	int victim = EntRefToEntIndex(pack.ReadCell());
	int attacker = EntRefToEntIndex(pack.ReadCell());
	if (victim == INVALID_ENT || attacker == INVALID_ENT)
	{
		delete pack;
		return;
	}
	
	float damage = pack.ReadFloat();
	delete pack;
	RF_TakeDamage(victim, attacker, attacker, damage, DMG_SHOCK|DMG_PREVENT_PHYSICS_FORCE, Item_RoBro);
}

public Action Hook_BuildingOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon,
		float damageForce[3], float damagePosition[3], int damageCustom)
{
	Action result1 = Hook_OnTakeDamageAlive(victim, attacker, inflictor, damage, damageType, 
		weapon, damageForce, damagePosition, damageCustom);
		
	Call_StartForward(g_fwOnTakeDamage);
	Call_PushCell(victim);
	Call_PushCellRef(attacker);
	Call_PushCellRef(inflictor);
	Call_PushFloatRef(damage);
	Call_PushCellRef(damageType);
	Call_PushCellRef(weapon);
	Call_PushArray(damageForce, 3);
	Call_PushArray(damagePosition, 3);
	Call_PushCell(damageCustom);
	Call_PushCell(GetEntItemProc(attacker));
	Call_PushCell(GetEntItemProc(inflictor));
	int dummy;
	Call_PushCellRef(dummy);
	Call_PushFloatRef(g_flDamageProc);
	Action result2;
	Call_Finish(result2);
	return result2 == Plugin_Continue ? result1 : result2;
}

public void Hook_BuildingOnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon,
		const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	Hook_OnTakeDamageAlivePost(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
}

public void RF_WidowmakerAmmo(DataPack pack)
{
	pack.Reset();
	int attacker = GetClientOfUserId(pack.ReadCell());
	int metal = pack.ReadCell();
	delete pack;
	GivePlayerAmmo(attacker, metal, TFAmmoType_Metal, true);
}

public Action Hook_SkeletonFriendlyFireFix(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon,
		float damageForce[3], float damagePosition[3], int damageCustom)
{
	if (IsValidClient(attacker) && GetClientTeam(attacker) == GetEntTeam(victim))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public void Timer_PowerPlayExpire(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return;
	
	TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
	TF2_RemoveCondition(client, TFCond_UberBulletResist);
	TF2_RemoveCondition(client, TFCond_UberBlastResist);
	TF2_RemoveCondition(client, TFCond_UberFireResist);
	TF2_RemoveCondition(client, TFCond_MegaHeal);
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_SetPlayerPowerPlay(client, false);
}

public void Hook_WeaponSwitchPost(int client, int weapon)
{
	if (IsFakeClient(client))
	{
		TFBot(client).RemoveButtonFlag(IN_RELOAD);
	}
	
	if (PlayerHasItem(client, ItemEngi_HeadOfDefense) && CanUseCollectorItem(client, ItemEngi_HeadOfDefense))
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
	else if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		if (GetEntPropFloat(client, Prop_Send, "m_flRageMeter") > 0.0)
		{
			int medigun = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
			if (medigun != weapon)
			{
				// kill the shield if we switch from medigun
				int shield = MaxClients+1;
				while ((shield = FindEntityByClassname(shield, "entity_medigun_shield")) != INVALID_ENT)
				{
					if (GetEntPropEnt(shield, Prop_Data, "m_hOwnerEntity") == client)
					{
						RemoveEntity(shield);
					}
				}
			}
			else
			{
				CreateMedigunShield(client, false);
			}
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
		TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock, GetItemMod(Item_PocketMedic, 3));
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

public void Timer_DecayFireRateBuff(Handle timer, int client)
{
	if (g_iPlayerFireRateStacks[client] > 0)
	{
		g_iPlayerFireRateStacks[client]--;
		UpdatePlayerFireRate(client);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3])
{
	if (!RF2_IsEnabled())
		return Plugin_Continue;
	
	// Apparently non-connected clients can call this??? (SourceTV?)
	if (!IsClientInGame(client) || IsSpecBot(client))
		return Plugin_Continue;
	
	bool bot = IsFakeClient(client);
	if (!bot)
	{
		if (buttons)
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

	if (IsRollermine(client))
	{
		float vel[3], ang[3], fwd[3], right[3];
		GetClientEyeAngles(client, ang);
		ang[0] = 0.0;
		GetAngleVectors(ang, fwd, right, NULL_VECTOR);
		NormalizeVector(fwd, fwd);
		NormalizeVector(right, right);
		float accel = GetItemMod(ItemStrange_JackHat, 0);
		bool onGround = (GetEntityFlags(g_iPlayerRollerMine[client]) & FL_ONGROUND) != 0;
		if (buttons & IN_DUCK && onGround)
		{
			accel *= 0.5; // go slower when ducking	
		}
		
		if (onGround)
		{
			if (buttons & IN_JUMP)
			{
				ApplyAbsVelocityImpulse(EntRefToEntIndex(g_iPlayerRollerMine[client]), {0.0, 0.0, 400.0});
				CBaseEntity(EntRefToEntIndex(g_iPlayerRollerMine[client])).RemoveFlag(FL_ONGROUND);
			}
		}
		else
		{
			accel *= 0.5; // slower in the air
		}
		
		if (buttons & IN_FORWARD)
		{
			vel[0] += 1.0 * fwd[0];
			vel[1] += 1.0 * fwd[1];
			vel[2] += 1.0 * fwd[2];
		}
		else if (buttons & IN_BACK)
		{
			vel[0] -= 1.0 * fwd[0];
			vel[1] -= 1.0 * fwd[1];
			vel[2] -= 1.0 * fwd[2];
		}
		
		if (buttons & IN_MOVERIGHT)
		{
			vel[0] += 1.0 * right[0];
			vel[1] += 1.0 * right[1];
			vel[2] += 1.0 * right[2];
		}
		else if (buttons & IN_MOVELEFT)
		{
			vel[0] -= 1.0 * right[0];
			vel[1] -= 1.0 * right[1];
			vel[2] -= 1.0 * right[2];
		}
		
		ScaleVector(vel, accel);
		ApplyAbsVelocityImpulse(EntRefToEntIndex(g_iPlayerRollerMine[client]), vel);
	}
	
	static bool jumpPressed[MAXPLAYERS];
	static bool jetpackSound[MAXPLAYERS];
	static int jetpackParticle[MAXPLAYERS][2];
	if (buttons & IN_JUMP)
	{
		if (HasJetpack(client))
		{
			// MK 50
			float power = GetItemMod(ItemStrange_MK50, 3);
			float cap = GetItemMod(ItemStrange_MK50, 4);
			float myVel[3];
			GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", myVel);
			if (myVel[2] < cap)
			{
				myVel[2] = fmin(cap, myVel[2]+power);
				CBaseEntity(client).SetAbsVelocity(myVel);
			}
			
			if (!jumpPressed[client])
			{
				if (!jetpackSound[client])
				{
					EmitSoundToAll("weapons/flame_thrower_loop.wav", client);
					jetpackSound[client] = true;
				}
				
				if (!IsValidEntity2(jetpackParticle[client][0]))
				{
					int attachment = LookupEntityAttachment(client, "foot_L");
					if (attachment != 0)
					{
						float pos[3];
						GetEntityAttachment(client, attachment, pos, NULL_VECTOR);
						jetpackParticle[client][0] = EntIndexToEntRef(
							SpawnInfoParticle("rockettrail_!", pos, _, client, "foot_L"));
					}
				}
				
				if (!IsValidEntity2(jetpackParticle[client][1]))
				{
					int attachment = LookupEntityAttachment(client, "foot_R");
					if (attachment != 0)
					{
						float pos[3];
						GetEntityAttachment(client, attachment, pos, NULL_VECTOR);
						jetpackParticle[client][1] = EntIndexToEntRef(
							SpawnInfoParticle("rockettrail_!", pos, _, client, "foot_R"));
					}
				}
			}
		}
		else if (jetpackSound[client])
		{
			StopSound(client, SNDCHAN_AUTO, "weapons/flame_thrower_loop.wav");
			StopSound(client, SNDCHAN_AUTO, "weapons/flame_thrower_loop.wav");
			EmitSoundToAll("weapons/flame_thrower_end.wav", client);
			jetpackSound[client] = false;
			if (IsValidEntity2(jetpackParticle[client][0]))
			{
				RemoveEntity(jetpackParticle[client][0]);
			}
			if (IsValidEntity2(jetpackParticle[client][1]))
			{
				RemoveEntity(jetpackParticle[client][1]);
			}
		}
		
		jumpPressed[client] = true;
	}
	else
	{
		if (jetpackSound[client])
		{
			StopSound(client, SNDCHAN_AUTO, "weapons/flame_thrower_loop.wav");
			StopSound(client, SNDCHAN_AUTO, "weapons/flame_thrower_loop.wav");
			EmitSoundToAll("weapons/flame_thrower_end.wav", client);
			jetpackSound[client] = false;
			if (IsValidEntity2(jetpackParticle[client][0]))
			{
				RemoveEntity(jetpackParticle[client][0]);
			}
			if (IsValidEntity2(jetpackParticle[client][1]))
			{
				RemoveEntity(jetpackParticle[client][1]);
			}
		}
		
		jumpPressed[client] = false;
	}
	
	if (buttons & IN_DUCK && HasJetpack(client))
	{
		float myVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", myVel);
		myVel[2] = 0.0;
		CBaseEntity(client).SetAbsVelocity(myVel);
	}
	
	static bool scorePressed[MAXPLAYERS];
	if (!bot && buttons & IN_SCORE)
	{
		g_flPlayerLastTabPressTime[client] = GetTickedTime();
		if (!scorePressed[client])
		{
			if (GetCookieBool(client, g_coAltItemMenuButton))
			{
				if (g_bPlayerViewingItemMenu[client])
				{
					CancelClientMenu(client, true);
					ClientCommand(client, "slot10");
				}
				else
				{
					ShowItemMenu(client);
				}
			}
			
			scorePressed[client] = true;
		}
	}
	else
	{
		scorePressed[client] = false;
	}

	if (!bot && buttons & IN_ATTACK)
	{
		if ((IsPlayerSurvivor(client) || IsPlayerMinion(client)) && g_flPlayerVampireSapperCooldown[client] <= 0.0 && TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			if (!TF2_IsPlayerInCondition(client, TFCond_Cloaked) && GetGameTime() >= GetEntPropFloat(client, Prop_Send, "m_flInvisChangeCompleteTime"))
			{
				int sapper = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
				if (sapper > 0 && GetActiveWeapon(client) == sapper)
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
	
	static bool reloadPressed[MAXPLAYERS];
	if (!bot && buttons & IN_RELOAD)
	{
		if (!reloadPressed[client])
		{
			// Don't conflict with the Vaccinator or Eureka Effect. Player must be pressing IN_SCORE when holding these weapons.
			if ((buttons & IN_SCORE || !HoldingReloadUseWeapon(client)) && GetPlayerEquipmentItem(client) > Item_Null)
			{
				if (!ActivateStrangeItem(client))
				{
					EmitGameSoundToClient(client, "Player.DenyWeaponSelection");
				}
			}
		}
		
		reloadPressed[client] = true;
	}
	else
	{
		reloadPressed[client] = false;
	}
	
	static bool attack3Pressed[MAXPLAYERS];
	if (!bot && buttons & IN_ATTACK3)
	{
		bool canPing = true;
		if (!attack3Pressed[client])
		{
			if (!(buttons & IN_SCORE))
			{
				TFClassType class = TF2_GetPlayerClass(client);
				if (class == TFClass_Engineer)
				{
					if (GetPlayerWeaponSlot(client, WeaponSlot_PDA2) == GetActiveWeapon(client))
					{
						canPing = false;

						if (g_hPlayerExtraSentryList[client].Length > 0)
						{
							int entity = g_hPlayerExtraSentryList[client].Get(0);
							if (IsValidEntity2(entity))
							{
								SetVariantInt(GetEntProp(entity, Prop_Send, "m_iHealth")+9999);
								AcceptEntityInput(entity, "RemoveHealth");
							}
						}
					}
					else
					{
						float eyePos[3], eyeAng[3];
						GetClientEyePosition(client, eyePos);
						GetClientEyeAngles(client, eyeAng);
						TR_TraceRayFilter(eyePos, eyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter_DontHitSelf, client);
						int dispenser = TR_GetEntityIndex();
						if (IsBuilding(dispenser) && TF2_GetObjectType(dispenser) == TFObject_Dispenser && GetEntPropEnt(dispenser, Prop_Send, "m_hBuilder") == client)
						{
							RF2_DispenserShield shield = GetDispenserShield(dispenser);
							if (shield.IsValid())
							{
								canPing = false;
								if (shield.Enabled)
								{
									shield.Toggle(false, true);
									shield.UserDisabled = true;
								}
								else if (shield.UserDisabled)
								{
									if (shield.Battery > 0 
										&& !GetEntProp(dispenser, Prop_Send, "m_bHasSapper") 
										&& !GetEntProp(dispenser, Prop_Send, "m_bCarried")
										&& !GetEntProp(dispenser, Prop_Send, "m_bBuilding"))
									{
										shield.UserDisabled = false;
										shield.Toggle(true, true);
									}
								}
								
								shield.UpdateBatteryText();
							}
						}
					}
				}
				else if (class == TFClass_Sniper)
				{
					int rifle = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
					if (rifle != INVALID_ENT && rifle == GetActiveWeapon(client))
					{
						static char classname[64];
						GetEntityClassname(rifle, classname, sizeof(classname));
						if (!strcmp2(classname, "tf_weapon_compound_bow"))
						{
							canPing = false;
							g_bPlayerRifleAutoFire[client] = !g_bPlayerRifleAutoFire[client];
							g_bPlayerToggledAutoFire[client] = true;
							EmitSoundToClient(client, SND_AUTOFIRE_TOGGLE);
						}
					}
				}
				else if (class == TFClass_Medic)
				{
					int medigun = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
					if (medigun != INVALID_ENT && medigun == GetActiveWeapon(client))
					{
						if (PlayerHasItem(client, ItemMedic_ProcedureMask)
							&& g_flPlayerMedicShieldNextUseTime[client] <= GetGameTime())
						{
							CreateMedigunShield(client);
							g_flPlayerMedicShieldNextUseTime[client] = GetGameTime()+GetItemMod(ItemMedic_ProcedureMask, 2);
						}
					}
				}
			}
		}
		
		if (canPing)
		{
			if ((IsPlayerSurvivor(client) || IsPlayerMinion(client)) 
				&& g_flPlayerTimeSinceLastPing[client]+PING_COOLDOWN < GetTickedTime())
			{
				if (PingObjects(client))
				{
					g_flPlayerTimeSinceLastPing[client] = GetTickedTime();
				}
			}
		}
		
		attack3Pressed[client] = true;
	}
	else
	{
		attack3Pressed[client] = false;
	}
	
	if (buttons & IN_ATTACK && g_bPlayerRifleAutoFire[client] && TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		int rifle = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
		if (rifle == GetActiveWeapon(client))
		{
			float charge = GetEntPropFloat(rifle, Prop_Send, "m_flChargedDamage")/1.5;
			if (charge > 0.0)
			{
				buttons &= ~IN_ATTACK;
				g_bForceRifleSound = true; // We need to force the rifle sound as it won't play if we do this
			}
		}
	}

	static float nextFootstepTime[MAXPLAYERS];
	if (g_iPlayerFootstepType[client] == FootstepType_GiantRobot 
		&& GetTickedTime() >= nextFootstepTime[client] 
		&& g_cvOldGiantFootsteps.BoolValue
		&& !TF2_IsPlayerInCondition(client, TFCond_Disguised) 
		&& !IsPlayerStunned(client))
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
				
				PrecacheSound(sample);
				EmitSoundToAll(sample, client);
				float duration = g_flPlayerGiantFootstepInterval[client];
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
	
	int team = GetClientTeam(client);
	if (team == TEAM_ENEMY && (g_bGracePeriod || !g_bRoundActive))
		return Plugin_Stop;

	int originalPitch = pitch;
	bool footsteps = StrContains(sample, "player/footsteps/", false) != -1;
	if (channel != SNDCHAN_VOICE && !footsteps)
		return Plugin_Continue;
	
	if (team == TEAM_ENEMY || IsPlayerMinion(client) || TF2_IsPlayerInCondition(client, TFCond_Disguised))
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
		bool blacklist[MAXPLAYERS];

		// If we're disguised, play the original sample to our teammates before doing anything.
		if (TF2_IsPlayerInCondition(client, TFCond_Disguised) && !IsPlayerMinion(client))
		{
			for (int i = 0; i < numClients; i++)
			{
				if (clients[i] == client || !IsValidClient(clients[i]))
					continue;

				if (GetClientTeam(clients[i]) == team)
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
			if (pitch != originalPitch)
				action = Plugin_Changed;
			
			if (voiceType == VoiceType_Robot)
			{
				if (!g_cvEnableGiantPainSounds.BoolValue)
				{
					if ((IsBoss(client) || g_bPlayerIsDyingBoss[client]) && (StrContains(sample, "pain", false) != -1))
					{
						return Plugin_Stop;
					}
				}
				
				action = Plugin_Changed;
				bool noGiantLines = (class == TFClass_Sniper || class == TFClass_Medic || class == TFClass_Engineer || class == TFClass_Spy);
				char classString[16], newString[32];
				TF2_GetClassString(class, classString, sizeof(classString), true);
				if ((IsBoss(client) || g_bPlayerIsDyingBoss[client]) && !noGiantLines)
				{
					g_bPlayerIsDyingBoss[client] = false;
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
		else if (footsteps)
		{
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
				}
				
				// Match MVM.BotStep
				level = 87;
				channel = SNDCHAN_STATIC;
				volume = 0.35;
				pitch = GetRandomInt(95, 100);
				if (TF2_IsPlayerInCondition(client, TFCond_Disguised) && !IsPlayerMinion(client))
				{
					EmitSoundToClient(client, sample, client, SNDCHAN_STATIC, level, flags, volume, pitch);

					for (int i = 0; i < numClients; i++)
					{
						if (clients[i] != client && !blacklist[clients[i]] && IsClientInGame(clients[i]))
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

public bool TraceFilter_DispenserShield(int entity, int mask, int team)
{
	return RF2_DispenserShield(entity).IsValid() && GetEntTeam(entity) != team;
}

public bool TraceFilter_OtherTeamPlayers(int entity, int mask, int self)
{
	if (entity != self && IsValidClient(entity) && GetClientTeam(entity) != GetClientTeam(self))
	{
		return true;
	}

	return false;
}
