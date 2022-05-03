#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf2items>
#include <morecolors>
#include <PathFollower>
#include <PathFollower_Nav>

#pragma semicolon 1
#pragma newdecls required

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

bool g_bPluginEnabled;
bool g_bGameStarted;
bool g_bWaitingForPlayers;
bool g_bRoundActive;
bool g_bGracePeriod;
bool g_bGameOver;
bool g_bStageWon;
bool g_bMapChanging;

bool g_bSeedSet;
int g_iSeed;

// Difficulty
float g_flSecondsPassed;
int g_iMinutesPassed;

float g_flSubDifficultyIncrement = 50.0;
float g_flDifficultyCoeff;
float g_flDifficultyFactor = DifficultyFactor_Rainstorm;
int g_iDifficultyLevel = DIFFICULTY_RAINSTORM;
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

// g_iStagesCompleted+1, g_iMinutesPassed, hudSeconds, g_iEnemyLevel, g_iPlayerLevel[i], g_flPlayerXP[i], 
// g_flPlayerNextLevelXP[i], g_flPlayerCash[i], g_szHudDifficulty, g_szTeleporterHud[i]
char g_szSurvivorHudText[512] = "\n\n\nStage %i | %02d:%02d\nEnemy Level: %i | Your Level: %i\n%.0f/%.0f XP | Cash: $%.0f\n%s\n%s";

// g_iStagesCompleted+1, g_iMinutesPassed, hudSeconds, g_iEnemyLevel, g_szHudDifficulty
char g_szHudText[512] = "\n\n\nStage %i | %02d:%02d\nEnemy Level: %i\n%s";

// Players
int g_iPlayerLevel[MAXTF2PLAYERS] = {1, ...};
float g_flPlayerXP[MAXTF2PLAYERS];
float g_flPlayerNextLevelXP[MAXTF2PLAYERS] = {BASE_XP_REQUIREMENT, ...};
float g_flPlayerCash[MAXTF2PLAYERS];

int g_iPlayerStatWearable[MAXTF2PLAYERS] = {-1, ...}; // Wearable entity used to store specific attributes on player

int g_iPlayerBaseHealth[MAXTF2PLAYERS] = {1, ...};
int g_iPlayerCalculatedMaxHealth[MAXTF2PLAYERS] = {1, ...};
float g_flPlayerMaxSpeed[MAXTF2PLAYERS] = { 300.0, ... };
float g_flPlayerCalculatedMaxSpeed[MAXTF2PLAYERS] = {300.0, ...};
float g_flHealthRegenTime[MAXTF2PLAYERS];

int g_iPlayerSurvivorIndex[MAXTF2PLAYERS] = {-1, ...};

int g_iPlayerRobotType[MAXTF2PLAYERS] = {-1, ...};
bool g_bIsGiant[MAXTF2PLAYERS];
bool g_bGiantFootstepCooldown[MAXTF2PLAYERS];
float g_flGiantFootstepInterval[MAXTF2PLAYERS] = {0.5, ...};

bool g_bIsBoss[MAXTF2PLAYERS];
bool g_bIsTeleporterBoss[MAXTF2PLAYERS];
int g_iPlayerBossType[MAXTF2PLAYERS] = {-1, ...};

bool g_bStunnable[MAXTF2PLAYERS] = { true, ... };

float g_flAFKTime[MAXTF2PLAYERS];
bool g_bIsAFK[MAXTF2PLAYERS];

// Variables for tracking stats for post-game results
int g_iTotalRobotsKilled;
int g_iTotalBossesKilled;
int g_iTotalItemsFound;

// Timers
Handle g_hPlayerTimer = null;
Handle g_hHudTimer = null;
Handle g_hDifficultyTimer = null;

// SDK
Handle g_hSDKEquipWearable;
Handle g_hSDKGetLocomotion;
Handle g_hSDKGetVision;
Handle g_hSDKApproach;
Handle g_hSDKGetPrimaryKnownThreat;
Handle g_hSDKGetNextBot;
Handle g_hSDKGetEntity;
Handle g_hSDKGetMaxClip1;

// Forwards
Handle f_TeleEventStart;
Handle f_GracePeriodStart;
Handle f_GracePeriodEnded;

// ConVars
ConVar g_cvAlwaysSkipWait;
ConVar g_cvDebugNoMapChange;
ConVar g_cvDebugShowDifficultyCoeff;
ConVar g_cvDebugDontEndGame;
ConVar g_cvEnableAFKManager;
ConVar g_cvAFKManagerKickTime;
ConVar g_cvBotsCanBeSurvivor;
ConVar g_cvSubDifficultyIncrement;
ConVar g_cvDifficultyScaleMultiplier;
ConVar g_cvShowObjectSpawns;
ConVar g_cvForceSeed;
ConVar g_cvShowSeedInConsole;

// Includes
#include "rf2/items.sp"
#include "rf2/survivors.sp"
#include "rf2/objects.sp"
#include "rf2/bosses.sp"
#include "rf2/robots.sp"
#include "rf2/stages.sp"
#include "rf2/weapons.sp"
#include "rf2/tf_bot.sp"
#include "rf2/stocks.sp"
#include "rf2/natives_forwards.sp"
#include "rf2/commands_convars.sp"

// ================ //
// ================ //
// 	   General	 	//
// ================ //
// ================ //
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char gameName[8];
	GetGameFolderName(gameName, sizeof(gameName));
	if (strcmp(gameName, "tf") != 0)
	{
		FormatEx(error, err_max, "This plugin was developed for Team Fortress 2 only");
		return APLRes_Failure;
	}
	
	LogMessage("Risk Fortress 2 is loading...");
	LoadNatives();
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadGameData();
	LoadForwards();
	LoadCommandsAndCvars();
	
	LoadTranslations("common.phrases");
	
	g_hMainHudSync = CreateHudSynchronizer();
	AddNormalSoundHook(view_as<NormalSHook>(RoboSoundHook));
	
	g_flSubDifficultyIncrement = GetConVarFloat(g_cvSubDifficultyIncrement);
}

stock void LoadGameData()
{
	Handle gamedata = LoadGameConfigFile("rf2");
	
	// CBasePlayer::EquipWearable ----------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	
	g_hSDKEquipWearable = EndPrepSDKCall();
	if(!g_hSDKEquipWearable)
		LogError("[GAMEDATA] Failed to create call for CBasePlayer::EquipWearable");
		
	// INextBot::GetLocomotionInterface ----------------------------------------------------------
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "INextBot::GetLocomotionInterface");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	
	g_hSDKGetLocomotion = EndPrepSDKCall();
	if(!g_hSDKGetLocomotion)
		LogError("[GAMEDATA] Failed to create call for INextBot::GetLocomotionInterface");
		
	// INextBot::GetVisionInterface -------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "INextBot::GetVisionInterface");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	
	g_hSDKGetVision = EndPrepSDKCall();
	if (!g_hSDKGetVision)
		LogError("[GAMEDATA] Failed to create call for INextBot::GetVisionInterface");
	
	// IVision::GetPrimaryKnownThreat -----------------------------------------------------------
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "IVision::GetPrimaryKnownThreat");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	
	g_hSDKGetPrimaryKnownThreat = EndPrepSDKCall();
	if (!g_hSDKGetPrimaryKnownThreat)
		LogError("[GAMEDATA] Failed to create call for IVision::GetPrimaryKnownThreat");
		
	// CBaseEntity::MyNextBotPointer ------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBaseEntity::MyNextBotPointer");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	
	g_hSDKGetNextBot = EndPrepSDKCall();
	if (!g_hSDKGetNextBot)
		LogError("[GAMEDATA] Failed to create call for CBaseEntity::MyNextBotPointer");
		
	// ILocomotion::Approach --------------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "ILocomotion::Approach");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	
	g_hSDKApproach = EndPrepSDKCall();
	if (!g_hSDKApproach)
		LogError("[GAMEDATA] Failed to create call for ILocomotion::Approach");
	
	// CKnownEntity::GetEntity ------------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CKnownEntity::GetEntity");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	
	g_hSDKGetEntity = EndPrepSDKCall();
	if (!g_hSDKGetEntity)
		LogError("[GAMEDATA] Failed to create call for CKnownEntity::GetEntity");

	// CTFWeaponBase::GetMaxClip1 ---------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFWeaponBase::GetMaxClip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	g_hSDKGetMaxClip1 = EndPrepSDKCall();
	if (!g_hSDKGetMaxClip1)
		LogError("[GAMEDATA] Failed to create call for CTFWeaponBase::GetMaxClip1");
	
	delete gamedata;
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{	
		if (!IsClientInGame(i))
			continue;
		
		StopMusicTrack(i);
		SetVariantString("");
		AcceptEntityInput(i, "SetCustomModel");
	}
}

public void OnMapStart()
{
	char mapName[256];
	char buffer[8];
	GetCurrentMap(mapName, sizeof(mapName));
	SplitString(mapName, "_", buffer, sizeof(buffer));
	Format(buffer, sizeof(buffer), "%s_", buffer);
	
	if (strcmp(buffer, "rf2_") == 0)
	{
		g_bPluginEnabled = true;
		if (GameRules_GetProp("m_bInWaitingForPlayers"))
			g_bWaitingForPlayers = true;
		
		PrecacheModel(MODEL_INVISIBLE);
		PrecacheModel(MODEL_TELEPORTER);
		PrecacheModel(MODEL_TELEPORTER_RADIUS);
		PrecacheModel(MODEL_CRATE);
		
		PrecacheSound(SOUND_ITEM_PICKUP);
		PrecacheSound(SOUND_GAME_OVER);
		PrecacheSound(SOUND_MONEY_PICKUP);
		
		PrecacheSound(SOUND_DROP_DEFAULT);
		PrecacheSound(SOUND_DROP_UNUSUAL);
		PrecacheSound(NOPE);
		
		PrecacheSound(SOUND_BOSS_SPAWN);
		PrecacheSound(SOUND_SENTRYBUSTER_BOOM);
		PrecacheSound(SOUND_ROBOT_STUN);
		
		PrecacheSound(SOUND_BELL);
		
		PrecacheSound("weapons/eviction_notice_01.wav");
		PrecacheSound("weapons/eviction_notice_02.wav");
		PrecacheSound("weapons/eviction_notice_03.wav");
		PrecacheSound("weapons/eviction_notice_04.wav");
		
		// TF2 ConVars
		InsertServerCommand("sm_tf2_maxspeed %i", SPEED_LIMIT);
		
		// Why is this a dev-only convar? :/
		ConVar WaitTime = FindConVar("mp_waitingforplayers_time");
		SetConVarFlags(WaitTime, GetConVarFlags(WaitTime) & ~FCVAR_DEVELOPMENTONLY);
		SetConVarInt(WaitTime, WAIT_TIME);

		SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
		SetConVarInt(FindConVar("mp_forcecamera"), 0);
		SetConVarInt(FindConVar("mp_forceautoteam"), 1);
		SetConVarFloat(FindConVar("mp_respawnwavetime"), 99999.0);
		SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), 0);
		SetConVarInt(FindConVar("tf_avoidteammates_pushaway"), 0);
		SetConVarInt(FindConVar("tf_use_fixed_weaponspreads"), 1);
		SetConVarInt(FindConVar("tf_weapon_criticals"), 0);
		
		// TFBots
		SetConVarInt(FindConVar("tf_bot_defense_must_defend_time"), -1);
		SetConVarInt(FindConVar("tf_bot_offense_must_push_time"), -1);
		SetConVarInt(FindConVar("tf_bot_taunt_victim_chance"), 0);
		SetConVarString(FindConVar("tf_bot_quota_mode"), "fill");
		SetConVarInt(FindConVar("tf_bot_quota"), GetMaxHumanPlayers()-1);
		
		ConVar BotConsiderClass = FindConVar("tf_bot_reevaluate_class_in_spawnroom");
		SetConVarFlags(BotConsiderClass, GetConVarFlags(BotConsiderClass) & ~FCVAR_CHEAT);
		SetConVarInt(BotConsiderClass, 0);
		
		char team[8];
		switch (TEAM_ROBOT)
		{
			case TFTeam_Blue:	team = "blue";
			case TFTeam_Red:	team = "red";
		}
		SetConVarString(FindConVar("mp_humans_must_join_team"), team);
		
		// Round events
		HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Pre);
		HookEvent("teamplay_round_win", Event_RoundEnd, EventHookMode_Post);
		
		// Player events
		HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
		HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
		// Command listeners
		AddCommandListener(OnCallForMedic, "voicemenu");
		AddCommandListener(OnChangeClass, "joinclass");
		AddCommandListener(OnChangeTeam, "autoteam");
		AddCommandListener(OnChangeTeam, "jointeam");
		AddCommandListener(OnChangeTeam, "spectate");
		
		AddCommandListener(OnChangeSpec, "spec_next");
		AddCommandListener(OnChangeSpec, "spec_prev");
		
		AddTempEntHook("TFBlood", TEHook_TFBlood);
		
		LoadMapSettings(mapName);
		LoadItems();
		LoadWeapons();
		LoadSurvivorStats();
		g_iMaxStages = GetMaxStages();
		
		if (!g_bSeedSet)
		{
			int forcedSeed;
			if ((forcedSeed = GetConVarInt(g_cvForceSeed)) >= 0)
			{
				g_iSeed = forcedSeed;
				SetConVarInt(g_cvForceSeed, -1);
			}
			else
			{
				g_iSeed = GetRandomInt(0, 2147483647);
			}
			
			LogMessage("Seed for this game: %i", g_iSeed);
			if (GetConVarBool(g_cvShowSeedInConsole))
			{
				PrintToConsoleAll("[RF2] Seed for this game: %i", g_iSeed);
			}
			
			g_bSeedSet = true;
		}
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i))
				continue;
				
			SDKHook(i, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamageAlive);
		}
		
		CreateTimer(0.2, Timer_TFBotThink, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, Timer_AFKManager, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(60.0, Timer_PluginMessage, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		g_bPluginEnabled = false;
		PrintToServer("The current map (%s) isn't an RF2-compatible map. RF2 will be disabled.", mapName);
		InsertServerCommand("sm_tf2_maxspeed 520");
		
		Handle WaitTime = FindConVar("mp_waitingforplayers_time");
		SetConVarFlags(WaitTime, GetConVarFlags(WaitTime) & ~FCVAR_DEVELOPMENTONLY);
		ResetConVar(WaitTime);
	
		ResetConVar(FindConVar("mp_teams_unbalance_limit"));
		ResetConVar(FindConVar("mp_forcecamera"));
		ResetConVar(FindConVar("mp_forceautoteam"));
		ResetConVar(FindConVar("mp_respawnwavetime"));
		ResetConVar(FindConVar("tf_dropped_weapon_lifetime"));
		ResetConVar(FindConVar("tf_avoidteammates_pushaway"));
		ResetConVar(FindConVar("tf_use_fixed_weaponspreads"));
		ResetConVar(FindConVar("tf_weapon_criticals"));
		
		ResetConVar(FindConVar("tf_bot_defense_must_defend_time"));
		ResetConVar(FindConVar("tf_bot_offense_must_push_time"));
		ResetConVar(FindConVar("tf_bot_taunt_victim_chance"));
		ResetConVar(FindConVar("tf_bot_quota_mode"));
		ResetConVar(FindConVar("tf_bot_quota"));
		
		Handle BotConsiderClass = FindConVar("tf_bot_reevaluate_class_in_spawnroom");
		SetConVarFlags(BotConsiderClass, GetConVarFlags(BotConsiderClass) & ~FCVAR_CHEAT);
		ResetConVar(BotConsiderClass);
		
		Handle BotAlwaysFullReload = FindConVar("tf_bot_always_full_reload");
		SetConVarFlags(BotAlwaysFullReload, GetConVarFlags(BotAlwaysFullReload) & ~FCVAR_CHEAT);
		ResetConVar(BotAlwaysFullReload);
		
		SetConVarString(FindConVar("mp_humans_must_join_team"), "any");
	}
}

public void OnMapEnd()
{
	if (!g_bPluginEnabled)
		return;
	
	g_bMapChanging = true;
	
	if (g_bGameOver)
	{
		RestartGame(true);
		return;
	}
	else if (g_bStageWon)
	{
		g_iStagesCompleted++;
	}
	
	UnhookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Pre);
	UnhookEvent("teamplay_round_win", Event_RoundEnd, EventHookMode_Post);
	
	UnhookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	RemoveCommandListener(OnCallForMedic, "voicemenu");
	RemoveCommandListener(OnChangeClass, "joinclass");
	RemoveCommandListener(OnChangeTeam, "jointeam");
	RemoveCommandListener(OnChangeTeam, "autoteam");
	RemoveCommandListener(OnChangeTeam, "spectate");
	
	RemoveCommandListener(OnChangeSpec, "spec_next");
	RemoveCommandListener(OnChangeSpec, "spec_prev");
	
	RemoveTempEntHook("TFBlood", TEHook_TFBlood);
	
	g_bRoundActive = false;
	g_bGracePeriod = false;
	g_bStageWon = false;
	g_bWaitingForPlayers = false;
	
	g_hPlayerTimer = null;
	g_hHudTimer = null;
	g_hDifficultyTimer = null;
	g_iRespawnWavesCompleted = 0;
	
	g_iRobotAmount = 0;
	g_iBossAmount = 0;
	g_iItemCount = 0;
	
	g_szAllLoadedRobots = "; ";
	g_szAllLoadedBosses = "; ";
	g_szRobotPacks = "";
	g_szBossPacks = "";
	
	g_iTeleporter = -1;
	g_iTeleporterActivator = -1;
	g_bTeleporterEventCompleted = false;
	
	for (int i = 1; i < MAXTF2PLAYERS; i++)
	{
		g_iTFBotNextBot[i] = Address_Null;
		g_iTFBotLocomotion[i] = Address_Null;
		g_iTFBotVision[i] = Address_Null;
		
		if (g_iPlayerSurvivorIndex[i] >= 0)
		{
			SaveSurvivorInventory(i, g_iPlayerSurvivorIndex[i]);
		}
		
		if (IsValidClient(i))
		{
			StopMusicTrack(i);
		}
		
		RefreshClient(i);
		for (int item = 0; item < MAX_ITEMS; item++)
		{
			g_iPlayerItem[i][item] = 0;
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (g_bPluginEnabled)
	{
		SDKHook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamageAlive);
		
		if (IsFakeClient(client))
		{
			g_iTFBotNextBot[client] = GetNextBot(client);
			g_iTFBotLocomotion[client] = GetLocomotionInterface(g_iTFBotNextBot[client]);
			g_iTFBotVision[client] = GetVisionInterface(g_iTFBotNextBot[client]);
		}
	}
}

public void OnClientDisconnect(int client)
{
	if (!g_bPluginEnabled)
		return;
	
	StopMusicTrack(client); // to reset the timer
	
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
			LogMessage("All human players have disconnected from the server. Restarting the game...");
			RestartGame(true);
			return;
		}
	}
	
	// We need to deal with survivors who disconnect during the grace period.
	if (g_bGracePeriod && g_iPlayerSurvivorIndex[client] >= 0)
	{
		SaveSurvivorInventory(client, g_iPlayerSurvivorIndex[client]);
		
		// Find the best candidate to replace this guy with.
		bool allowBots = GetConVarBool(g_cvBotsCanBeSurvivor);
		int points[MAXTF2PLAYERS];
		int playerPoints[MAXTF2PLAYERS];
		bool valid[MAXTF2PLAYERS];
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (i == client || !IsClientInGame(i) || g_iPlayerSurvivorIndex[i] >= 0)
				continue;
			
			// If we are allowing bots, they lose points in favor of players.
			if (IsFakeClient(i))
			{
				if (!allowBots)
					continue;
					
				points[i] -= 250;
			}
			
			// Dead players and non-bosses have higher priority.
			if (!IsPlayerAlive(i))
				points[i] += 5000;
				
			if (GetClientTeam(i) == TEAM_ROBOT)
				points[i] += 500;
			
			points[i] += GetRandomInt(1, 50);
			playerPoints[i] = points[i];			
			valid[i] = true;
		}
		
		SortIntegers(points, sizeof(points), Sort_Descending);
		int highestPoints = points[0];
		
		for (int i = 1; i < MAXTF2PLAYERS; i++)
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
	
	if (!g_bMapChanging)
		RefreshClient(client);
}

// ================================================================ //
// ================================================================ //
// 	    					Events 									//
// ================================================================ //
// ================================================================ //

// event_round_start ------------------------------------------------------------------
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnabled || g_bWaitingForPlayers)
		return Plugin_Continue;
	
	if (!SetSurvivors())
	{
		RF2_PrintToChatAll("No Survivors were spawned! Restarting game...");
		RestartGame(true);
		return Plugin_Continue;
	}
	
	g_bGameStarted = true;
	CreateTimer(0.5, Timer_KillAllRobots, _, TIMER_FLAG_NO_MAPCHANGE);
	
	SpawnObjects();
	
	if (g_hPlayerTimer != null)
		delete g_hPlayerTimer;
	if (g_hHudTimer != null)
		delete g_hHudTimer;
	if (g_hDifficultyTimer != null)
		delete g_hDifficultyTimer;
	
	g_hPlayerTimer = CreateTimer(0.1, Timer_PlayerTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	g_hHudTimer = CreateTimer(0.1, Timer_Hud, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	g_hDifficultyTimer = CreateTimer(1.0, Timer_Difficulty, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
			
		StopMusicTrack(i);
	}
	
	CreateTimer(0.1, Timer_PlayMusic, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(g_flGracePeriodTime, Timer_EndGracePeriod, _, TIMER_FLAG_NO_MAPCHANGE);
	
	g_bRoundActive = true;
	g_bGracePeriod = true;
	Call_StartForward(f_GracePeriodStart);
	Call_Finish();
	
	CreateTimer(3.0, Timer_DeleteFuncRespawnroom, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action Timer_DeleteFuncRespawnroom(Handle timer)
{
	// Bots will not follow players into respawn rooms, engineers can't build in them, and players can respawn in them. Many reasons for this.
	// The timer is to allow TF2 to compute incursion distances between the spawnrooms for bots before they're deleted. 3 seconds seems to be enough time.
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "func_respawnroom")) != -1)
	{
		RemoveEntity(entity);
	}
}

// event_round_end ------------------------------------------------------------------
public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnabled || GetConVarInt(g_cvDebugNoMapChange) != 0)
		return Plugin_Continue;
		
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && g_iPlayerSurvivorIndex[i] < 0 && !IsFakeClient(i))
		{
			g_iSurvivorPoints[i] += 10;
			RF2_PrintToChat(i, "You gained {lime}10 {default}Survivor Points from this round.");
		}
	}
	
	int winningTeam = event.GetInt("team");
	if (winningTeam == TEAM_SURVIVOR)
	{
		if (g_iCurrentStage >= g_iMaxStages-1)
		{
			g_iLoopCount++;
			g_iCurrentStage = 0;
		}
		else
		{
			g_iCurrentStage++;
		}
		
		g_bStageWon = true;
		CreateTimer(14.0, Timer_SetNextStage, g_iCurrentStage, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (winningTeam == TEAM_ROBOT)
	{	
		g_bGameOver = true;
		CreateTimer(14.0, Timer_SetNextStage, 0, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	g_bRoundActive = false;
	return Plugin_Continue;
}

// player_spawn ------------------------------------------------------------------
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnabled || g_bWaitingForPlayers)
		return Plugin_Continue;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = GetClientTeam(client);
	
	// Bots should never join red team outside of waiting for players.
	if (IsFakeClient(client))
	{
		if (team != TEAM_ROBOT && !GetConVarBool(g_cvBotsCanBeSurvivor))
		{
			ChangeClientTeam(client, 0);
			ChangeClientTeam(client, TEAM_ROBOT);
		}
		TFBot_Spawn(client);
	}
	
	// Robots should never spawn during the grace period, if it somehow happens.
	if (g_bGracePeriod && team == TEAM_ROBOT)
	{
		TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
		SDKHooks_TakeDamage(client, 0, 0, 9999999.0, DMG_PREVENT_PHYSICS_FORCE);
		ForcePlayerSuicide(client);
	}
	
	RequestFrame(RF_CalculateStats, client);
	if (g_iPlayerSurvivorIndex[client] >= 0)
	{
		CreateSurvivor(client, g_iPlayerSurvivorIndex[client], false, false);
	}
		
	return Plugin_Continue;
}

public void RF_CalculateStats(int client)
{
	if (!IsClientInGame(client))
		return;
	
	CalculatePlayerMaxHealth(client, true, true);
	CalculatePlayerMaxSpeed(client);
}

// player_death ------------------------------------------------------------------
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnabled || g_bWaitingForPlayers || !g_bRoundActive)
		return Plugin_Continue;
	
	bool reset = true;

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	int victimTeam = GetClientTeam(victim);
	int attackerTeam;
	
	if (victimTeam == TEAM_ROBOT)
	{
		if (!g_bGracePeriod)
		{
			float origin[3];
			GetClientAbsOrigin(victim, origin);
			
			float cashAmount;
			if (g_iPlayerRobotType[victim] != -1)
			{
				g_iTotalRobotsKilled++;
				cashAmount = g_flRobotCashAward[g_iPlayerRobotType[victim]];
			}
			else if (g_bIsBoss[victim])
			{
				cashAmount = g_flBossCashAward[g_iPlayerBossType[victim]];
				g_iTotalBossesKilled++;
			}
			
			SpawnCashDrop(GetRandomInt(1, 3), cashAmount, origin);
		}
		else // If the grace period is active, die silently.
		{
			RequestFrame(RF_DeleteRagdoll, victim);
			return Plugin_Stop;
		}
	}
	
	if (attacker > 0)
	{
		attackerTeam = GetClientTeam(attacker);
		ItemDeathEffects(attacker, victim);
		
		if (victimTeam == TEAM_ROBOT && attackerTeam == TEAM_SURVIVOR)
		{
			float xp;
			
			if (g_iPlayerRobotType[victim] != -1)
				xp = g_flRobotXPAward[g_iPlayerRobotType[victim]];
			else if (g_bIsBoss[victim])
				xp = g_flBossXPAward[g_iPlayerBossType[victim]];
			
			UpdatePlayerXP(attacker, xp);
		}
	}
	
	if (victimTeam == TEAM_SURVIVOR)
	{
		if (!g_bGracePeriod)
		{
			SaveSurvivorInventory(victim, g_iPlayerSurvivorIndex[victim]);
			PrintDeathMessage(victim);
			
			int fog = CreateEntityByName("env_fog_controller");
			if (IsValidEntity(fog))
			{
				DispatchKeyValue(fog, "targetname", "DeathFog");
				DispatchKeyValue(fog, "spawnflags", "1");
				DispatchKeyValue(fog, "fogenabled", "1");
				DispatchKeyValue(fog, "fogstart", "50.0");
				DispatchKeyValue(fog, "fogend", "100.0");
				DispatchKeyValue(fog, "fogmaxdensity", "0.9");
				DispatchKeyValue(fog, "fogcolor", "255 0 0");
				
				DispatchSpawn(fog);				
				AcceptEntityInput(fog, "TurnOn");					
			}
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i))
					continue;
			
				SetVariantString("DeathFog");
				AcceptEntityInput(i, "SetFogController");
			}
			CreateTimer(0.1, Timer_DeleteEntity, EntIndexToEntRef(fog), TIMER_FLAG_NO_MAPCHANGE);
			
			// Change the victim's team on a timer to avoid some strange behavior.
			CreateTimer(0.3, Timer_ChangeTeamOnDeath, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
			
			int alive = 0;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsValidClient(i) || i == victim)
					continue;
					
				if (IsPlayerAlive(i) && g_iPlayerSurvivorIndex[i] >= 0)
					alive++;
			}
			
			if (alive == 0 && GetConVarInt(g_cvDebugDontEndGame) == 0) // Game over, man!
			{
				GameOver();
			}
		}
		else
		{
			reset = false;
			
			// Respawning players right inside of player_death also causes strange behaviour.
			CreateTimer(0.1, Timer_RespawnSurvivor, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	if (g_bIsGiant[victim])
	{
		EmitSoundToAll(SOUND_SENTRYBUSTER_BOOM, victim);
		EmitSoundToAll(SOUND_SENTRYBUSTER_BOOM, victim);
		EmitSoundToAll(SOUND_SENTRYBUSTER_BOOM, victim);
		EmitSoundToAll(SOUND_SENTRYBUSTER_BOOM, victim);
		
		float origin[3];
		GetClientAbsOrigin(victim, origin);
		TE_SetupParticle("fireSmokeExplosion", origin);
		RequestFrame(RF_DeleteRagdoll, victim);
	}
	
	if (reset)
		RefreshClient(victim);
	
	return Plugin_Continue;
}

// ================================================================ //
// ================================================================ //
// 	    				Event Timers 								//
// ================================================================ //
// ================================================================ //

// player_death ------------------------------------------------------------------
public Action Timer_KillAllRobots(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) == TEAM_SURVIVOR)
			continue;
		
		TF2_RemoveCondition(i, TFCond_UberchargedCanteen);
		SDKHooks_TakeDamage(i, 0, 0, 9999999.0, DMG_PREVENT_PHYSICS_FORCE);
		ForcePlayerSuicide(i);
	}
}

public void RF_DeleteRagdoll(int client)
{
	if (IsClientInGame(client))
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

public Action Timer_RespawnSurvivor(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || g_iPlayerSurvivorIndex[client] < 0)
		return;
	
	CreateSurvivor(client, g_iPlayerSurvivorIndex[client]);
}

public Action Timer_EndGracePeriod(Handle timer)
{
	if (!g_bGracePeriod) // grace period was probably ended early by /rf2_skipgrace
		return;
		
	g_bGracePeriod = false;
	
	CreateTimer(5.0, Timer_RespawnWave, _, TIMER_FLAG_NO_MAPCHANGE);
	
	Call_StartForward(f_GracePeriodEnded);
	Call_Finish();
	
	RF2_PrintToChatAll("Grace period has ended. Death on RED will result in joining BLU.");
}

public Action Timer_RespawnWave(Handle timer)
{
	if (!g_bPluginEnabled || !g_bRoundActive || g_bTeleporterEventCompleted)
		return;
	
	// start the timer again first so any errors that may or may not happen don't abort our entire spawning system.
	float duration = (25.0 - 1.5 * (g_iSurvivorCount - 1)) - (IntToFloat(g_iEnemyLevel-1) * 0.5);
	if (g_bTeleporterEvent)
	{
		float multiplier = (0.8 - (0.02 * g_iSurvivorCount-1));
		duration *= multiplier;
		
		// The longer the stage goes on, the faster the robots spawn, but this is clamped based on the difficulty.
		float reduction = IntToFloat(g_iRespawnWavesCompleted) * 0.5;
		float maxReduction = 5.0 + (IntToFloat(g_iSubDifficulty) * 1.0);
		if (reduction > maxReduction)
			reduction = maxReduction;
		
		duration -= reduction;
	}
	
	if (duration < MIN_RESPAWN_WAVE_TIME)
		duration = MIN_RESPAWN_WAVE_TIME;
	
	CreateTimer(duration, Timer_RespawnWave, _, TIMER_FLAG_NO_MAPCHANGE);
	
	int maxCount = GetRandomInt(1, 3) + g_iSurvivorCount-1 + g_iSubDifficulty;
	if (maxCount > MAX_SPAWN_WAVE_COUNT)
		maxCount = MAX_SPAWN_WAVE_COUNT;
	
	Handle respawnArray = CreateArray(1, MAXTF2PLAYERS);
	int count;
	static int spawnPoints[MAXTF2PLAYERS];
	bool finished, ignorePoints, chosen[MAXTF2PLAYERS], pointsGiven[MAXTF2PLAYERS];
	
	// grab our next players for the spawn
	for (int i = 1; i <= MaxClients; i++)
	{
		if (chosen[i] || !IsClientInGame(i) || GetClientTeam(i) != TEAM_ROBOT || IsPlayerAlive(i))
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
			ignorePoints = true; // not enough spawns. ignore the points system
			i = 1;
		}
	}
	
	ResizeArray(respawnArray, count);
	for (int i = 0; i < count; i++)
	{
		int client = GetArrayCell(respawnArray, i);
		int type = GetRandomRobot();
		SpawnRobot(client, type);
	}
	delete respawnArray;
	g_iRespawnWavesCompleted++;
}

public Action Timer_SetNextStage(Handle timer, int stage)
{
	if (g_bForceNextMap)
	{
		char reason[64];
		FormatEx(reason, sizeof(reason), "%s forced the next map", g_szMapForcer);
		ForceChangeLevel(g_szForcedMap, reason);
		g_bForceNextMap = false;
	}
	else
	{
		SetNextStage(stage);
	}
}

public Action Timer_ChangeTeamOnDeath(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return;
		
	ChangeClientTeam(client, TEAM_ROBOT);
}

// ================================================================ //
// ================================================================ //
// 	    					General Timers 							//
// ================================================================ //
// ================================================================ //
public Action Timer_Hud(Handle timer)
{
	if (!g_bPluginEnabled)
	{
		g_hHudTimer = null;
		return Plugin_Stop;
	}
	
	SetHudTextParams(-1.0, -1.3, 0.15, g_iMainHudR, g_iMainHudG, g_iMainHudB, 255);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		if (g_bGameOver)
		{
			// Calculate our score and rank.
			int score;
			char rank[8];
			score += g_iTotalRobotsKilled * 5;
			score += g_iTotalBossesKilled * 300;
			score += g_iTotalItemsFound * 50;
			score += g_iStagesCompleted * 1000;
			
			if (score >= 50000)
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
			
			SetHudTextParams(-1.0, -1.3, 0.15, 255, 100, 100, 255);
			ShowSyncHudText(i, g_hMainHudSync, 
			"\n\n\n\nGAME OVER\n\nRobots slain: %i\nBosses slain: %i\nStages completed: %i\nItems found: %i\n\nTotal Score: %i\nRank: %s", 
			g_iTotalRobotsKilled, g_iTotalBossesKilled, g_iStagesCompleted, g_iTotalItemsFound, score, rank);
			return Plugin_Continue;
		}
		
		int hudSeconds = RoundFloat((g_flSecondsPassed) - (g_iMinutesPassed * 60.0));
		if (GetClientTeam(i) == TEAM_SURVIVOR)
		{
			ShowSyncHudText(i, g_hMainHudSync, g_szSurvivorHudText, g_iStagesCompleted+1, g_iMinutesPassed, 
			hudSeconds, g_iEnemyLevel, g_iPlayerLevel[i], g_flPlayerXP[i], g_flPlayerNextLevelXP[i], g_flPlayerCash[i],
			g_szHudDifficulty, g_szTeleporterHud[i]);
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
	float playerFactor = ((g_iSurvivorCount-1) * 0.15) + 1.0;
	if (playerFactor < 1.0)
		playerFactor = 1.0;
	
	// this scales a bit too hard in higher survivor counts
	float value = 1.12 - (0.03 * IntToFloat(g_iSurvivorCount-1));
	if (value < 1.02)
		value = 1.02;
		
	float stageFactor = Pow(value, IntToFloat(g_iStagesCompleted));
	
	g_flDifficultyCoeff = (timeFactor * stageFactor * playerFactor) * g_flDifficultyFactor;
	g_flDifficultyCoeff *= GetConVarFloat(g_cvDifficultyScaleMultiplier);
	
	if (GetConVarInt(g_cvDebugShowDifficultyCoeff) != 0)
		PrintCenterTextAll("g_flDifficultyCoeff = %f", g_flDifficultyCoeff);

	int currentLevel = g_iEnemyLevel;
	g_iEnemyLevel = RoundToFloor(1.0 + g_flDifficultyCoeff / (g_flSubDifficultyIncrement / 4.0));
	
	if (g_iEnemyLevel < 1)
		g_iEnemyLevel = 1;
		
	if (g_iEnemyLevel > currentLevel) // enemy level just increased
	{
		RF2_PrintToChatAll("Enemy Level: {red}%i -> %i", currentLevel, g_iEnemyLevel);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
			
			if (GetClientTeam(i) == TEAM_ROBOT)
				CalculatePlayerMaxHealth(i, true);
		}
	}
	
	float subTime = g_flDifficultyCoeff / g_flSubDifficultyIncrement;
	// increment the sub difficulty depending on difficulty value
	if (subTime >= g_iSubDifficulty+1)
	{
		g_iSubDifficulty++;
		SetHudDifficulty(g_iSubDifficulty);
		EmitSoundToAll(SOUND_BELL);
	}
	else if (subTime < g_iSubDifficulty) // or decrement if we're somehow lower
	{
		g_iSubDifficulty--;
		SetHudDifficulty(g_iSubDifficulty);
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
	int primary;
	int secondary;
	int ammoType;
	
	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		// All players have infinite reserve ammo.
		primary = GetPlayerWeaponSlot(i, WeaponSlot_Primary);
		secondary = GetPlayerWeaponSlot(i, WeaponSlot_Secondary);
		if (IsValidEntity(primary))
		{
			ammoType = GetEntProp(primary, Prop_Data, "m_iPrimaryAmmoType");
			if (ammoType > -1)
			{
				GivePlayerAmmo(i, 999999, ammoType, true);
			}
		}
		
		if (IsValidEntity(secondary))
		{
			ammoType = GetEntProp(secondary, Prop_Data, "m_iPrimaryAmmoType");
			if (ammoType > -1 && ammoType != 4 && ammoType != 5) // 4 and 5 are Jarate and Mad Milk, which we don't want here
			{
				GivePlayerAmmo(i, 999999, ammoType, true);
			}
		}
		
		// Health Regen
		if (GetClientTeam(i) == TEAM_SURVIVOR)
		{
			g_flHealthRegenTime[i] -= 0.1;
			if (g_flHealthRegenTime[i] <= 0.0)
			{
				g_flHealthRegenTime[i] = 0.0;
				maxHealth = g_iPlayerCalculatedMaxHealth[i];
				health = GetEntProp(i, Prop_Data, "m_iHealth");

				if (health < maxHealth)
				{
					healAmount = RoundFloat((IntToFloat(maxHealth) * 0.0025));
					
					if (g_iPlayerItem[i][Item_Archimedes] > 0)
						healAmount = RoundFloat(IntToFloat(healAmount) * (IntToFloat(g_iPlayerItem[i][Item_Archimedes]) * 0.3));
					
					if (g_iDifficultyLevel >= DIFFICULTY_MONSOON)
						healAmount = RoundFloat(IntToFloat(healAmount) * 0.6);
					if (healAmount < 1)
						healAmount = 1;

					SetEntityHealth(i, health+healAmount);
				}
			}
		}
	}

	return Plugin_Continue;
}

// ======================== //
// ======================== //
// 	   	Other Timers 		//
// ======================== //
// ======================== //
public Action Timer_PluginMessage(Handle timer)
{
	if (!g_bPluginEnabled)
		return;
		
	static int message;
	const int maxMessages = 0;
	
	switch (message)
	{
		case 0: RF2_PrintToChatAll("{lightblue}Risk Fortress 2{default} version {pink}%s{default} created by {indianred}CookieCat", PLUGIN_VERSION);
		
	}
	
	message++;
	if (message > maxMessages)
		message = 0;
}

public Action Timer_DeleteEntity(Handle timer, int entity)
{
	entity = EntRefToEntIndex(entity);
	if (entity != INVALID_ENT_REFERENCE)
		RemoveEntity(entity);
}

public Action Timer_AFKManager(Handle timer)
{
	if (!g_bPluginEnabled || GetConVarBool(g_cvEnableAFKManager) == false)
		return;
	
	float afkTime = GetConVarFloat(g_cvAFKManagerKickTime);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		g_flAFKTime[i] += 1.0;
		if (g_flAFKTime[i] >= afkTime * 0.5)
		{
			PrintCenterText(i, "You have been detected as AFK. Press any button or you will be kicked shortly.");
			g_bIsAFK[i] = true;
		}
			
		if (g_flAFKTime[i] >= afkTime)
		{
			KickClient(i, "Kicked for being AFK.");
			g_flAFKTime[i] = 0.0;
			g_bIsAFK[i] = false;
		}
	}
}

public Action Timer_GiantFootstep(Handle timer, int client)
{
	g_bGiantFootstepCooldown[client] = false;
}

public Action Timer_StunCooldown(Handle timer, int client)
{
	g_bStunCooldown[client] = false;
}

// ======================= //
// ======================= //
// 	   Command listeners   //
// ======================= //
// ======================= //
public Action OnCallForMedic(int client, const char[] command, int args)
{
	if (!g_bPluginEnabled)
		return Plugin_Continue;
	
	if (GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client))
	{
		char arg1[8], arg2[8];
		int num1, num2;
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		num1 = StringToInt(arg1);
		num2 = StringToInt(arg2);
		
		if (num1 != 0 || num2 != 0) // voicemenu 0 0 only
			return Plugin_Continue;
			
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
	if (g_bRoundActive && !g_bGracePeriod || GetClientTeam(client) == TEAM_ROBOT)
	{
		RF2_PrintToChat(client, "You can't change your class at this time!");
		
		if (desiredClass != TFClass_Unknown)
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", view_as<int>(desiredClass));
		
		return Plugin_Handled;
	}
	else if (GetClientTeam(client) == TEAM_SURVIVOR)
	{
		ForcePlayerSuicide(client);
		TF2_SetPlayerClass(client, desiredClass); // so stats update properly
		CreateSurvivor(client, g_iPlayerSurvivorIndex[client]);
	}
	return Plugin_Continue;
}

public Action OnChangeTeam(int client, const char[] command, int args)
{
	if (!g_bPluginEnabled)
		return Plugin_Continue;
	
	int team = GetClientTeam(client);
	
	if (team == TEAM_ROBOT || team == TEAM_SURVIVOR)
	{
		RF2_PrintToChat(client, "You can't change your team!");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnChangeSpec(int client, const char[] command, int args)
{
	ResetAFKTime(client);
}

// ================================= //
// ================================= //
// 	  			Other				 //
// ================================= //
// ================================= //
public void OnGameFrame()
{
	if (!g_bPluginEnabled || !g_bRoundActive)
		return;
	
	float speed;
	int primary;
	static char classname[128];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
			
		// Calculate speed
		speed = g_flPlayerCalculatedMaxSpeed[i];
		if (g_bIsGiant[i] && g_flPlayerCalculatedMaxSpeed[i] < 230.0)
		{
			// crouch at normal speed if we're a giant and are slower than a normal Heavy
			if (GetEntProp(i, Prop_Send, "m_bDucked"))
				speed *= 3.0;
		}
		
		// Some of these are purposefully hardcoded to match up with TF2's speed values.
		if (TF2_IsPlayerInCondition(i, TFCond_Charging))
		{
			speed = 720.0 + g_flPlayerCalculatedMaxSpeed[i] - g_flPlayerMaxSpeed[i];
		}
		else if (TF2_IsPlayerInCondition(i, TFCond_Slowed))
		{
			switch (TF2_GetPlayerClass(i))
			{
				case TFClass_Heavy:
				{
					speed *= 0.47;
				}
				case TFClass_Sniper:
				{
					primary = GetPlayerWeaponSlot(i, WeaponSlot_Primary);
					if (primary != INVALID_ENT_REFERENCE)
					{
						GetEntityClassname(primary, classname, sizeof(classname));
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
		SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", speed);
	}
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if (!g_bPluginEnabled || g_bWaitingForPlayers)
		return Plugin_Continue;
	
	if (RollAttackCrit(client))
	{
		result = true;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void TF2_OnWaitingForPlayersStart()
{
	if (GetConVarInt(g_cvAlwaysSkipWait) != 0)
		InsertServerCommand("mp_restartgame_immediate 1");
	
	g_bMapChanging = false; // At least one player has loaded in at this point
	g_bWaitingForPlayers = true;
	PrintToServer("[RF2] Waiting For Players sequence started.");
}

public void TF2_OnWaitingForPlayersEnd()
{
	g_bWaitingForPlayers = false;
	PrintToServer("[RF2] Waiting For Players sequence ended.");
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!g_bPluginEnabled)
		return;
	
	if (StrContains(classname, "item_currencypack") != -1)
	{
		SDKHook(entity, SDKHook_StartTouch, Hook_CashTouch);
		SDKHook(entity, SDKHook_Touch, Hook_CashTouch);
	}
	else if (StrContains(classname, "func_regenerate") != -1 || StrContains(classname, "tf_ammo_pack") != -1
	|| StrContains(classname, "item_") != -1 || StrContains(classname, "tf_logic_") != -1)
	{
		RemoveEntity(entity);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (!g_bPluginEnabled || !IsValidEntity(entity))
		return;
		
	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (strcmp(classname, "tf_wearable") == 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;
				
			if (g_iPlayerStatWearable[i] == entity)
			{
				g_iPlayerStatWearable[i] = -1;
				break;
			}
		}
	}
}

public Action Hook_CashTouch(int entity, int other)
{
	if (IsValidClient(other))
	{
		Action action = PickupCash(other, entity);
		return action;
	}
	
	char classname[32];
	GetEntityClassname(other, classname, sizeof(classname));
	if (strcmp(classname, "trigger_hurt") == 0)
		PickupCash(0, entity);
		
	return Plugin_Continue;
}

public Action Hook_OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!g_bPluginEnabled || g_bWaitingForPlayers)
		return Plugin_Continue;
	
	if (!IsValidClient(victim) || !IsValidClient(attacker))
		return Plugin_Continue;
	
	if (attacker == victim && g_bIsBoss[victim])
	{
		// bosses don't do damage to themselves
		damage = 0.0;
		return Plugin_Changed;
	}
	
	bool changed;
	int attackerTeam = GetClientTeam(attacker);
	int victimTeam = GetClientTeam(victim);
	
	// backstabs do set damage against bosses, obviously
	if (damagecustom == TF_CUSTOM_BACKSTAB && g_bIsBoss[victim])
	{
		damage = BOSS_BASE_BACKSTAB_DAMAGE;
	}
	
	if (attackerTeam == TEAM_SURVIVOR)
	{
		damage *= 1.0 + (IntToFloat(g_iPlayerLevel[attacker]-1) * LEVEL_DAMAGE_INCREASE);
		changed = true;
	}
	else if (attackerTeam == TEAM_ROBOT)
	{
		damage *= 1.0 + (IntToFloat(g_iEnemyLevel-1) * LEVEL_DAMAGE_INCREASE);
		changed = true;
	}
	
	if (RollAttackCrit(attacker))
	{
		damagetype &= ~DMG_CRIT; // mini-crits use this same flag :/
		damagetype |= DMG_CRIT;
		changed = true;
	}
	
	if (victimTeam == TEAM_SURVIVOR)
	{
		int maxHealth = g_iPlayerCalculatedMaxHealth[victim];
		float seconds = 5.0 * (damage / IntToFloat(maxHealth));
		if (seconds > 5.0)
			seconds = 5.0;
		else if (seconds < 0.5)
			seconds = 0.5;
			
		g_flHealthRegenTime[victim] += seconds;
		if (g_flHealthRegenTime[victim] > 5.0)
			g_flHealthRegenTime[victim] = 5.0;
			
		if (g_iPlayerItem[victim][Item_FedFedora] > 0)
		{
			float chance = 100.0 * (damage / IntToFloat(maxHealth));
			if (chance < 8.0)
				chance = 8.0;
			
			if (GetRandomFloat(0.0, 100.0) <= chance)
			{
				SDKHooks_TakeDamage(attacker, victim, victim, 
				20.0 * (1.0 + (IntToFloat(g_iPlayerItem[victim][Item_FedFedora]-1) * 0.3)), DMG_PREVENT_PHYSICS_FORCE);
				
				char sound[64];
				FormatEx(sound, sizeof(sound), "weapons/eviction_notice_0%i.wav", GetRandomInt(1, 4));
				EmitSoundToAll(sound, attacker);
			}
		}
	}
	
	if (g_iPlayerItem[attacker][Item_Executioner] > 0 && g_bIsBoss[victim] && !IsInvuln(victim))
	{
		if (damagetype & DMG_CLUB || damagetype & DMG_SLASH && damagecustom != TF_CUSTOM_BLEEDING)
		{
			float health = IntToFloat(GetClientHealth(victim));
			float maxHealth = IntToFloat(g_iPlayerCalculatedMaxHealth[victim]);
			
			float multiplier = 1.0 * (1.0 + 0.3 * IntToFloat(g_iPlayerItem[attacker][Item_Executioner]-1));
			if (health / maxHealth <= 10.0 * multiplier)
			{
				// ded
				damage = 99999999.0;
				damagetype |= DMG_CRIT;
				changed = true;
			}
		}
	}
	
	if (changed)
		return Plugin_Changed;

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype)
{
	if (g_bPluginEnabled)
	{
		if (!IsFakeClient(client))
		{
			if (buttons)
				ResetAFKTime(client);
		}
		else
		{
			/*
			float velocity[3];
			float pos[3];
			float ang[3];
			GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);
			velocity[2] = 0.0;
			
			GetClientAbsOrigin(client, pos);
			GetVectorAngles(velocity, ang);
			ang[0] = 0.0;
			
			float height = 93.0;
			float crouchHeight = 63.0;
			float scale = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
			
			height *= scale;
			crouchHeight *= scale;
			
			pos[2] += height;
			
			Handle trace = TR_TraceRayFilterEx(pos, ang, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite, TraceWallsOnly);
			if (TR_DidHit(trace))
			{
				float endPos[3];
				TR_GetEndPosition(endPos, trace);
				
				// We probably want to crouch through here.
				if (GetVectorDistance(pos, endPos, true) <= Pow(200.0, 2.0))
				{
					// Can we actually get through here by crouching?
					pos[2] -= height;
					pos[2] += crouchHeight;
					
					delete trace;
					trace = TR_TraceRayFilterEx(pos, ang, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite, TraceWallsOnly);
					if (TR_DidHit(trace))
					{
						TR_GetEndPosition(endPos, trace);
						if (GetVectorDistance(pos, endPos, true) > Pow(200.0, 2.0))
							buttons |= IN_DUCK; // Yes we can.
					}
				}
			}
			delete trace;
			*/
			
			if (buttons & IN_JUMP)
			{
				buttons |= buttons & IN_DUCK; // Bots always crouch jump
			}
			
			if (buttons & IN_ATTACK)
			{
				int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				int secondary = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
				
				if (IsValidEntity(secondary) && secondary == activeWeapon)
				{
					static char classname[32];
					GetEntityClassname(secondary, classname, sizeof(classname));
					
					// TFBots have a bug where they won't switch off jar-type weapons after throwing. Forcing them to let go of IN_ATTACK fixes this.
					if (StrContains(classname, "tf_weapon_jar") != -1)
					{
						int ammoType = GetEntProp(secondary, Prop_Data, "m_iPrimaryAmmoType");
						if (GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType) == 0)
						{
							buttons &= ~IN_ATTACK;
						}
					}
				}
			}
		}
			
		if (g_bIsGiant[client] && !g_bGiantFootstepCooldown[client])
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
						
						// Sniper, Spy, Engineer do not have giant footsteps sounds, so we'll use the "common" ones.
						if (class == TFClass_Sniper || class == TFClass_Spy || class == TFClass_Engineer)
						{
							FormatEx(sample, sizeof(sample), "mvm/giant_common/giant_common_step_0%i.wav", GetRandomInt(1, 8));
						}
						else
						{
							char classString[16];
							GetClassString(class, classString, sizeof(classString));
							
							// Lucky for us, each giant class has exactly 4 giant footstep sounds.
							// Though some of the filenames don't have underscores before the number. -.- (Soldier and Heavy)
							if (class == TFClass_Soldier || class == TFClass_Heavy)
								FormatEx(sample, sizeof(sample), "mvm/giant_%s/giant_%s_step0%i.wav", classString, classString, GetRandomInt(1, 4));
							else
								FormatEx(sample, sizeof(sample), "mvm/giant_%s/giant_%s_step_0%i.wav", classString, classString, GetRandomInt(1, 4));
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
}

public Action TEHook_TFBlood(const char[] name, const int[] clients, int numClients, float delay)
{
	int client = TE_ReadNum("entindex");
	if (IsValidClient(client))
	{
		if (GetClientTeam(client) == TEAM_ROBOT)
		{
			float pos[3];
			pos[0] = TE_ReadFloat("m_vecOrigin[0]");
			pos[1] = TE_ReadFloat("m_vecOrigin[1]");
			pos[2] = TE_ReadFloat("m_vecOrigin[2]");
			
			DataPack pack = CreateDataPack();
			pack.WriteFloat(pos[0]);
			pack.WriteFloat(pos[1]);
			pack.WriteFloat(pos[2]);
			RequestFrame(RF_SparkEffect, pack); // spawn the new tempent on the next frame and block this one
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void RF_SparkEffect(DataPack pack)
{
	float pos[3];
	pack.Reset();
	pos[0] = pack.ReadFloat();
	pos[1] = pack.ReadFloat();
	pos[2] = pack.ReadFloat();
	
	TE_SetupParticle("lowV_blood_impact_red_01", pos);
}

//#file "Risk Fortress 2"