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

// General
bool g_bPluginEnabled;
bool g_bWaitingForPlayers;
bool g_bRoundActive;
bool g_bGracePeriod;
bool g_bGameOver;
bool g_bStageWon;

// Difficulty
float g_flSecondsPassed = 0.0;
int g_iMinutesPassed = 0;

float g_flSubDifficultyIncrement = 60.0;
float g_flDifficultyCoeff;
float g_flDifficultyFactor = DifficultyFactor_Rainstorm;
int g_iDifficultyLevel = DIFFICULTY_RAINSTORM;
int g_iSubDifficulty = SubDifficulty_Easy;

int g_iStagesCompleted;
int g_iLoopCount;
int g_iEnemyLevel = 1;

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
float g_flPlayerNextLevelXP[MAXTF2PLAYERS] = {80.0, ...};
float g_flPlayerCash[MAXTF2PLAYERS];

int g_iPlayerStatWearable[MAXTF2PLAYERS] = {-1, ...}; // Wearable entity used to store specific attributes on player

int g_iPlayerBaseHealth[MAXTF2PLAYERS] = {1, ...};
int g_iPlayerCalculatedMaxHealth[MAXTF2PLAYERS] = {1, ...};
float g_flPlayerBaseDamage[MAXTF2PLAYERS] = {10.0, ...};
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

bool g_bDamageWasCrit[MAXTF2PLAYERS];
//bool g_bDamageWasMiniCrit[MAXTF2PLAYERS];

bool g_bStunnable[MAXTF2PLAYERS] = { true, ... };

float g_flAFKTime[MAXTF2PLAYERS];
bool g_bIsAFK[MAXTF2PLAYERS];

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

// Forwards
Handle f_TeleEventStart;
Handle f_GracePeriodStart;
Handle f_GracePeriodEnded;

// ConVars
ConVar cv_AlwaysSkipWait;
ConVar cv_DebugNoMapChange;
ConVar cv_DebugShowDifficultyCoeff;
ConVar cv_DebugDontEndGame;
ConVar cv_EnableAFKManager;
ConVar cv_AFKManagerKickTime;
ConVar cv_BotsCanBeSurvivor;

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
	LogMessage("RF2 is loading...");
	LoadNatives();
}

public void OnPluginStart()
{
	LoadGameData();
	LoadForwards();
	LoadCommandsAndCvars();
	
	LoadTranslations("common.phrases");
	
	g_hMainHudSync = CreateHudSynchronizer();
	AddNormalSoundHook(view_as<NormalSHook>(RoboSoundHook));
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
		LogError("[Gamedata] Failed to create call for CBasePlayer::EquipWearable");
		
	// INextBot::GetLocomotionInterface ----------------------------------------------------------
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "INextBot::GetLocomotionInterface");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	
	g_hSDKGetLocomotion = EndPrepSDKCall();
	if(!g_hSDKGetLocomotion)
		LogError("[Gamedata] Failed to create call for INextBot::GetLocomotionInterface");
		
	// INextBot::GetVisionInterface -------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "INextBot::GetVisionInterface");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	
	g_hSDKGetVision = EndPrepSDKCall();
	if (!g_hSDKGetVision)
		LogError("[Gamedata] Failed to create call for INextBot::GetVisionInterface");
	
	// IVision::GetPrimaryKnownThreat -----------------------------------------------------------
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "IVision::GetPrimaryKnownThreat");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	
	g_hSDKGetPrimaryKnownThreat = EndPrepSDKCall();
	if (!g_hSDKGetPrimaryKnownThreat)
		LogError("[Gamedata] Failed to create call for IVision::GetPrimaryKnownThreat");
		
	// CBaseEntity::MyNextBotPointer ------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBaseEntity::MyNextBotPointer");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	
	g_hSDKGetNextBot = EndPrepSDKCall();
	if (!g_hSDKGetNextBot)
		LogError("[Gamedata] Failed to create call for CBaseEntity::MyNextBotPointer");
		
	// ILocomotion::Approach --------------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "ILocomotion::Approach");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	
	g_hSDKApproach = EndPrepSDKCall();
	if (!g_hSDKApproach)
		LogError("[Gamedata] Failed to create call for ILocomotion::Approach");
	
	// CKnownEntity::GetEntity ------------------------------------------------------------------
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CKnownEntity::GetEntity");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	
	g_hSDKGetEntity = EndPrepSDKCall();
	if (!g_hSDKGetEntity)
		LogError("[Gamedata] Failed to create call for CKnownEntity::GetEntity");
	
	delete gamedata;
}

public void OnPluginEnd()
{
	for (int i = 1; i < MAXTF2PLAYERS; i++)
	{
		StopMusicTrack(i);
		
		if (IsValidClient(i))
		{
			SetVariantString("");
			AcceptEntityInput(i, "SetCustomModel");
		}
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
		
		// Shouldn't be a dev-only convar Valve!!!!
		Handle WaitTime = FindConVar("mp_waitingforplayers_time");
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
		SetConVarInt(FindConVar("tf_bot_quota"), 31);
		
		Handle BotConsiderClass = FindConVar("tf_bot_reevaluate_class_in_spawnroom");
		SetConVarFlags(BotConsiderClass, GetConVarFlags(BotConsiderClass) & ~FCVAR_CHEAT);
		SetConVarInt(BotConsiderClass, 0);
		
		//Handle BotAlwaysFullReload = FindConVar("tf_bot_always_full_reload");
		//SetConVarFlags(BotAlwaysFullReload, GetConVarFlags(BotAlwaysFullReload) & ~FCVAR_CHEAT);
		//SetConVarInt(BotAlwaysFullReload, 1);
		
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
		HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
		HookEvent("player_invulned", Event_PlayerInvulned, EventHookMode_Post);
	
		// Command listeners
		AddCommandListener(OnCallForMedic, "voicemenu");
		AddCommandListener(OnChangeClass, "joinclass");
		AddCommandListener(OnChangeTeam, "autoteam");
		AddCommandListener(OnChangeTeam, "jointeam");
		AddCommandListener(OnChangeTeam, "spectate");
		
		AddCommandListener(OnChangeSpec, "spec_next");
		AddCommandListener(OnChangeSpec, "spec_prev");
		
		LoadMapSettings(mapName);
		LoadItems();
		LoadWeapons();
		LoadSurvivorStats();
		g_iMaxStages = RF2_GetMaxStages();
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i))
				continue;
				
			SDKHook(i, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamageAlive);
		}
		
		CreateTimer(0.1, Timer_TFBotThink, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, Timer_AFKManager, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		LogMessage("RF2 has loaded successfully.");
	}
	else
	{
		g_bPluginEnabled = false;
		LogMessage("The current map (%s) isn't an RF2-compatible map. RF2 will be disabled.", mapName);
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
	
	if (g_bGameOver)
	{
		RestartGame();
	}
	else if (g_bStageWon)
	{
		g_iStagesCompleted++;
	}
	
	UnhookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Pre);
	UnhookEvent("teamplay_round_win", Event_RoundEnd, EventHookMode_Post);
	
	UnhookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	UnhookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	UnhookEvent("player_invulned", Event_PlayerInvulned, EventHookMode_Post);
	
	RemoveCommandListener(OnCallForMedic, "voicemenu");
	RemoveCommandListener(OnChangeClass, "joinclass");
	RemoveCommandListener(OnChangeTeam, "jointeam");
	RemoveCommandListener(OnChangeTeam, "autoteam");
	RemoveCommandListener(OnChangeTeam, "spectate");
	
	RemoveCommandListener(OnChangeSpec, "spec_next");
	RemoveCommandListener(OnChangeSpec, "spec_prev");
	
	g_bRoundActive = false;
	g_bGracePeriod = false;
	g_bStageWon = false;
	g_bWaitingForPlayers = false;
	
	g_hPlayerTimer = null;
	g_hHudTimer = null;
	g_hDifficultyTimer = null;
	
	g_iRobotAmount = 0;
	g_iBossAmount = 0;
	g_iItemCount = 0;
	
	g_szAllLoadedRobots = "; ";
	g_szAllLoadedBosses = "; ";
	g_szRobotPacks = "";
	g_szBossPacks = "";
	
	g_bTeleporterEventCompleted = false;
	
	for (int i = 1; i < MAXTF2PLAYERS; i++)
	{
		g_iTFBotNextBot[i] = Address_Null;
		g_iTFBotLocomotion[i] = Address_Null;
		g_iTFBotVision[i] = Address_Null;
		
		if (g_iPlayerSurvivorIndex[i] > -1)
			SaveSurvivorInventory(i, g_iPlayerSurvivorIndex[i]);		
		
		StopMusicTrack(i);
		ClientReset(i, true);
			
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

// ================ //
// ================ //
// 	    Events 		//
// ================ //
// ================ //

// event_round_start
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnabled || g_bWaitingForPlayers)
		return Plugin_Continue;
	
	SetSurvivors();
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
	
	for (int i = 1; i < MAXTF2PLAYERS; i++)
		StopMusicTrack(i);
	
	CreateTimer(0.1, Timer_PlayMusic, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(g_flGracePeriodTime, Timer_EndGracePeriod, _, TIMER_FLAG_NO_MAPCHANGE);
	
	g_bRoundActive = true;
	g_bGracePeriod = true;
	Call_StartForward(f_GracePeriodStart);
	Call_Finish();
	
	// remove all func_respawnroom on a timer, so TF2 can compute the incursion distances for the bots
	// if we remove it too early, it will fail, seems to happen around a second after a round starts
	CreateTimer(3.0, Timer_DeleteFuncRespawnroom, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action Timer_DeleteFuncRespawnroom(Handle timer)
{
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "func_respawnroom")) != -1)
		RemoveEntity(entity);
}

// event_round_end
public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnabled || GetConVarInt(cv_DebugNoMapChange) != 0)
		return Plugin_Continue;
		
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) != TEAM_SURVIVOR && !IsFakeClient(i))
		{
			g_iSurvivorPoints[i] += 10;
			RF2_PrintToChat(i, "You gained {lime}10 {default}Survivor Points from this round.");
		}
	}
	
	int winningTeam = event.GetInt("team");
	if (winningTeam == TEAM_SURVIVOR)
	{
		int curStage = RF2_GetStageNum();
		if (curStage >= g_iMaxStages)
		{
			g_iLoopCount++;
			RF2_SetStageNum(0);
		}
		else
		{
			RF2_SetStageNum(curStage+1);
		}
		
		g_bStageWon = true;
		CreateTimer(12.0, Timer_SetNextStage, RF2_GetStageNum(), TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (winningTeam == TEAM_ROBOT)
	{	
		g_bGameOver = true;
		CreateTimer(12.0, Timer_SetNextStage, 0, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	g_bRoundActive = false;
	return Plugin_Continue;
}

// player_spawn
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnabled || g_bWaitingForPlayers)
		return Plugin_Continue;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = GetClientTeam(client);
	
	// Bots should never join red team outside of waiting for players.
	if (IsFakeClient(client))
	{
		if (team != TEAM_ROBOT && !GetConVarBool(cv_BotsCanBeSurvivor))
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
	return Plugin_Continue;
}

public void RF_CalculateStats(int client)
{
	if (!IsValidClient(client, true))
		return;
	
	CalculatePlayerMaxHealth(client, true, true);
	CalculatePlayerMaxSpeed(client);
}

// player_death
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnabled || g_bWaitingForPlayers || !g_bRoundActive)
		return Plugin_Continue;
	
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	int victimTeam = GetClientTeam(victim);
	int attackerTeam;
	
	if (victimTeam == TEAM_ROBOT)
	{
		// Don't drop money if we die during the grace period.
		if (!g_bGracePeriod)
		{
			float origin[3];
			GetClientAbsOrigin(victim, origin);
			
			float cashAmount;
			if (g_iPlayerRobotType[victim] != -1)
				cashAmount = g_flRobotCashAward[g_iPlayerRobotType[victim]];
			else if (g_bIsBoss[victim])
				cashAmount = g_flBossCashAward[g_iPlayerBossType[victim]];
			
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
	
	if (victimTeam == TEAM_SURVIVOR && !g_bGracePeriod)
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
			if (!IsValidClient(i))
				continue;
		
			SetVariantString("DeathFog");
			AcceptEntityInput(i, "SetFogController");
		}
		CreateTimer(0.1, Timer_DeleteEntity, EntIndexToEntRef(fog), TIMER_FLAG_NO_MAPCHANGE);
		
		// Change the victim's team on a timer to avoid some strange behavior
		CreateTimer(0.3, Timer_ChangeTeamOnDeath, victim, TIMER_FLAG_NO_MAPCHANGE);
		
		int alive = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i) || i == victim)
				continue;
				
			if (IsPlayerAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR)
				alive++;
		}
		if (alive == 0 && GetConVarInt(cv_DebugDontEndGame) == 0) // Game over, man!
			GameOver();
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
	
	ClientReset(victim);
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if (g_iPlayerSurvivorIndex[client] > -1)
	{
		SaveSurvivorInventory(client, g_iPlayerSurvivorIndex[client]);
	}
	ClientReset(client, true);
}

stock void RestartGame(bool command = false)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;
			
		if (IsFakeClient(i))
		{
			KickClient(i);
			continue;
		}
		
		TF2_RemoveAllWeapons(i); // clears attributes if we're reloading through the command
	}
	
	if (command && !g_bWaitingForPlayers) // this was called through a server command.
		InsertServerCommand("mp_restartgame_immediate 1");
		
	InsertServerCommand("sm plugins reload rf2");
}

public Action Timer_ResetModel(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return;
		
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");	
}

public void RF_DeleteRagdoll(int client)
{
	if (IsClientInGame(client))
	{
		char classname[16];
		for (int i = MaxClients+1; i <= 2048; i++)
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

// player_hurt
public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bPluginEnabled || g_bWaitingForPlayers)
		return Plugin_Continue;
		
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	bool crit = event.GetBool("crit");
	bool minicrit = event.GetBool("minicrit");
	float damageamount = event.GetFloat("damageamount");
	
	if (!IsValidClient(attacker))
		return Plugin_Continue;
	
	if (crit)
	{
		// RED Snipers get bonus crit damage
		if (GetClientTeam(attacker) == TEAM_SURVIVOR && TF2_GetPlayerClass(attacker) == TFClass_Sniper)
		{
			SetEventFloat(event, "damageamount", damageamount * 1.5);
			return Plugin_Changed;
		}
	}
	else if (minicrit)
	{
		
	}
	return Plugin_Continue;
}

public Action Event_PlayerInvulned(Event event, const char[] name, bool dontBroadcast)
{
	//int client = GetClientOfUserId(event.GetInt("medic_userid"));
}

void GameOver()
{
	for (int i = 1; i < MAXTF2PLAYERS; i++)
		StopMusicTrack(i);
	
	int fog = CreateEntityByName("env_fog_controller");
	DispatchKeyValue(fog, "targetname", "GameOverFog");
	DispatchKeyValue(fog, "spawnflags", "1");
	DispatchKeyValue(fog, "fogenabled", "1");
	DispatchKeyValue(fog, "fogstart", "500.0");
	DispatchKeyValue(fog, "fogend", "800.0");
	DispatchKeyValue(fog, "fogmaxdensity", "0.5");
	DispatchKeyValue(fog, "fogcolor", "15 0 0");
		
	DispatchSpawn(fog);				
	AcceptEntityInput(fog, "TurnOn");					

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;
	
		SetVariantString("GameOverFog");
		AcceptEntityInput(i, "SetFogController");
	}
	EmitSoundToAll(SOUND_GAME_OVER);
	PrintCenterTextAll("GAME OVER!");
	ForceTeamWin(TEAM_ROBOT);
}

// ======================== //
// ======================== //
// 	     Event Timers 		//
// ======================== //
// ======================== //

// event_round_start timers
public Action Timer_KillAllRobots(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || GetClientTeam(i) == TEAM_SURVIVOR)
			continue;
		
		TF2_RemoveCondition(i, TFCond_UberchargedCanteen);
		SDKHooks_TakeDamage(i, 0, 0, 9999999.0, DMG_PREVENT_PHYSICS_FORCE);
		ForcePlayerSuicide(i);
	}
}

public Action Timer_EndGracePeriod(Handle timer)
{
	if (!g_bGracePeriod) // grace period was probably ended early by Command_SkipGracePeriod
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
	
	// start the timer again first so any errors that may happen don't abort our entire spawning system
	float duration = (26.0 - 1.5 * (g_iSurvivorCount - 1)) - (IntToFloat(g_iEnemyLevel-1) * 0.5);
	if (g_bTeleporterEvent)
	{
		float multiplier = (0.8 - (0.02 * g_iSurvivorCount-1));
		duration *= multiplier;
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
		if (chosen[i] || !IsValidClient(i) || GetClientTeam(i) != TEAM_ROBOT || IsPlayerAlive(i))
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
}

// event_round_end timers
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

// player_death timers
public Action Timer_ChangeTeamOnDeath(Handle timer, int client)
{
	if (IsValidClient(client))
		ChangeClientTeam(client, TEAM_ROBOT);
}

// ======================== //
// ======================== //
// 	   		Timers 			//
// ======================== //
// ======================== //
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
		if (!IsValidClient(i) || IsFakeClient(i))
			continue;
		
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

	float TimeFactor = g_flSecondsPassed / 10.0;
	float PlayerFactor = ((g_iSurvivorCount-1) * 0.15) + 1.0;
	if (PlayerFactor < 1.0)
		PlayerFactor = 1.0;
	
	// this scales a bit too hard in higher survivor counts
	float value = 1.12 - (0.1 * IntToFloat(g_iSurvivorCount-1));
	if (value < 1.02)
		value = 1.02;
		
	float StageFactor = Pow(value, IntToFloat(g_iStagesCompleted));
	
	g_flDifficultyCoeff = (TimeFactor * StageFactor * PlayerFactor) * g_flDifficultyFactor;
	
	if (GetConVarInt(cv_DebugShowDifficultyCoeff) != 0)
		PrintCenterTextAll("g_flDifficultyCoeff = %.3f", g_flDifficultyCoeff);

	int currentLevel = g_iEnemyLevel;
	g_iEnemyLevel = RoundToFloor(1.0 + g_flDifficultyCoeff / (g_flSubDifficultyIncrement / 4.0));
	
	if (g_iEnemyLevel < 1)
		g_iEnemyLevel = 1;
		
	if (g_iEnemyLevel > currentLevel) // enemy level just increased
	{
		RF2_PrintToChatAll("Enemy Level: {red}%i -> %i", currentLevel, g_iEnemyLevel);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i, true))
				continue;
			
			if (GetClientTeam(i) == TEAM_ROBOT)
				UpdatePlayerLevel(i);
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
	
	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsValidClient(i, true))
			continue;
		
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
						healAmount = RoundFloat(IntToFloat(healAmount) * (IntToFloat(g_iPlayerItem[i][Item_Archimedes]) * 0.1));
					
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

public void OnGameFrame()
{
	if (!g_bPluginEnabled || !g_bRoundActive)
		return;
	
	float speed;
	int primary;
	static char classname[128];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i, true))
			continue;
			
		// Calculate speed
		speed = g_flPlayerCalculatedMaxSpeed[i];
		if (g_bIsGiant[i] && g_flPlayerCalculatedMaxSpeed[i] < 230.0)
		{
			// crouch at normal speed if we're a giant and are slower than a normal Heavy
			if (GetEntProp(i, Prop_Send, "m_bDucked"))
				speed *= 3.0;
		}
		
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
					primary = GetPlayerWeaponSlot(i, 0);
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

// ======================== //
// ======================== //
// 	   	Other Timers 		//
// ======================== //
// ======================== //
public Action Timer_DeleteEntity(Handle timer, int entity)
{
	entity = EntRefToEntIndex(entity);
	if (entity != INVALID_ENT_REFERENCE)
		RemoveEntity(entity);
}

public Action Timer_AFKManager(Handle timer)
{
	if (!g_bPluginEnabled || GetConVarBool(cv_EnableAFKManager) == false)
		return;
	
	float afkTime = GetConVarFloat(cv_AFKManagerKickTime);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || IsFakeClient(i))
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
		SpawnSurvivor(client, g_iPlayerSurvivorIndex[client]);
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
public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if (!g_bPluginEnabled)
		return Plugin_Continue;
	
	/*
	if (GetClientTeam(client) == TEAM_SURVIVOR)
	{
		if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(client, 2))
		{
			int entCount = GetEntityCount();
			char classname[128];
			float origin[3];
			float cashOrigin[3];
			bool pickedUp;

			// Radius cash pickup, in case cash gets stuck in spots players can't access.
			for (int i = MaxClients+1; i <= entCount; i++)
			{
				if (!IsValidEntity(i))
					continue;
				
				GetEntityClassname(i, classname, sizeof(classname));
				if (strcmp(classname, "item_currencypack_custom") == 0)
				{
					GetClientAbsOrigin(client, origin);
					GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", cashOrigin);
					
					if (GetVectorDistance(origin, cashOrigin, true) <= Pow(300.0, 2.0))
					{
						PickupCash(client, i);
						pickedUp = true;
					}
				}
			}
			if (pickedUp)
				EmitSoundToAll(SOUND_MONEY_PICKUP, client);
		}
	}
	*/
	
	if (RollAttackCrit(client))
	{
		result = true;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock bool RollAttackCrit(int client)
{
	if (GetClientTeam(client) != TEAM_SURVIVOR)
		return false;
	
	float critChance = 0.0 + (IntToFloat(g_iPlayerItem[client][Item_DeusSpecs]) * 4.0);
	
	if (critChance > 100.0)
		critChance = 100.0;
		
	float randomNum = GetRandomFloat(0.0, 99.9);
	if (critChance > randomNum)
		return true;
	else
		return false;
}

public void TF2_OnWaitingForPlayersStart()
{
	if (GetConVarInt(cv_AlwaysSkipWait) != 0)
		InsertServerCommand("mp_restartgame_immediate 1");
		
	g_bWaitingForPlayers = true;
}

public void TF2_OnWaitingForPlayersEnd()
{
	g_bWaitingForPlayers = false;
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
/*
public void OnEntityDestroyed(int entity)
{
	if (!g_bPluginEnabled || !IsValidEntity(entity))
		return;
}
*/
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
	
	if (RollAttackCrit(attacker) && !g_bDamageWasCrit[attacker])
	{
		damagetype &= ~DMG_CRIT; // Reapply for the case that this is actually mini-crit damage
		damagetype |= DMG_CRIT;
	}
	
	if (attackerTeam == TEAM_SURVIVOR)
	{
		damage *= 1.0 + (IntToFloat(g_iPlayerLevel[attacker]) * LEVEL_DAMAGE_INCREASE);
	}
	else if (attackerTeam == TEAM_ROBOT)
	{
		damage *= 1.0 + (IntToFloat(g_iEnemyLevel) * LEVEL_DAMAGE_INCREASE);
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
		
		if (IsValidClient(client) && GetEntityFlags(client) & FL_ONGROUND && !(buttons & IN_JUMP))
		{
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
				if (GetVectorDistance(pos, endPos, true) <= Pow(300.0, 2.0))
				{
					// Can we actually get through here by crouching?
					pos[2] -= height;
					pos[2] += crouchHeight;
					
					delete trace;
					trace = TR_TraceRayFilterEx(pos, ang, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite, TraceWallsOnly);
					if (TR_DidHit(trace))
					{
						TR_GetEndPosition(endPos, trace);
						if (GetVectorDistance(pos, endPos, true) > Pow(300.0, 2.0))
							buttons |= IN_DUCK; // Yes we can.
					}
				}
			}
			delete trace;
			
			if (buttons & IN_JUMP)
			{
				buttons |= buttons & IN_DUCK; // Bots always crouch jump
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

public bool TraceDontHitSelf(int self, int contentsmask, int client)
{
	return !(self == client);
}
