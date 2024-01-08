#if defined _RF2_natives_forwards_included
 #endinput
#endif
#define _RF2_natives_forwards_included

#pragma semicolon 1
#pragma newdecls required

void LoadNatives()
{
	CreateNative("RF2_IsEnabled", Native_IsEnabled);
	CreateNative("RF2_CanBeStunned", Native_CanBeStunned);
	CreateNative("RF2_IsPlayerBoss", Native_IsPlayerBoss);
	CreateNative("RF2_GetPlayerItemAmount", Native_GetPlayerItemAmount);
	CreateNative("RF2_GivePlayerItem", Native_GivePlayerItem);
	CreateNative("RF2_GetEnemyLevel", Native_GetEnemyLevel);
	CreateNative("RF2_GetSurvivorIndex", Native_GetSurvivorIndex);
	CreateNative("RF2_GetSurvivorLevel", Native_GetSurvivorLevel);
	CreateNative("RF2_GetSurvivorCount", Native_GetSurvivorCount);
	CreateNative("RF2_GetSurvivorPoints", Native_GetSurvivorPoints);
	CreateNative("RF2_SetSurvivorPoints", Native_SetSurvivorPoints);
	CreateNative("RF2_GetDifficultyCoeff", Native_GetDifficultyCoeff);
	CreateNative("RF2_GetSubDifficulty", Native_GetSubDifficulty);
	CreateNative("RF2_GetDifficulty", Native_GetDifficulty);
	CreateNative("RF2_GetBaseMaxHealth", Native_GetBaseMaxHealth);
	CreateNative("RF2_GetCalculatedMaxHealth", Native_GetCalculatedMaxHealth);
	CreateNative("RF2_GetBaseSpeed", Native_GetBaseSpeed);
	CreateNative("RF2_GetCalculatedSpeed", Native_GetCalculatedSpeed);
	CreateNative("RF2_GetMaxStages", Native_GetMaxStages);
	CreateNative("RF2_GetCurrentStage", Native_GetCurrentStage);
	CreateNative("RF2_GetTeleporterEntity", Native_GetTeleporterEntity);
	CreateNative("RF2_IsTankDestructionMode", Native_IsTankDestructionMode);
}

void LoadForwards()
{
	g_fwTeleEventStart = new GlobalForward("RF2_OnTeleporterEventStart", ET_Ignore);
	g_fwTeleEventEnd = new GlobalForward("RF2_OnTeleporterEventEnd", ET_Ignore);
	g_fwGracePeriodStart = new GlobalForward("RF2_OnGracePeriodStart", ET_Ignore);
	g_fwGracePeriodEnded = new GlobalForward("RF2_OnGracePeriodEnd", ET_Ignore);
	
	g_fwPrivateOnMapStart = new PrivateForward(ET_Ignore); 
	g_fwPrivateOnMapStart.AddFunction(INVALID_HANDLE, SentryBuster_OnMapStart);
	g_fwPrivateOnMapStart.AddFunction(INVALID_HANDLE, BadassTank_OnMapStart);
	g_fwPrivateOnMapStart.AddFunction(INVALID_HANDLE, RaidBoss_OnMapStart);
	g_fwPrivateOnMapStart.AddFunction(INVALID_HANDLE, Galleom_OnMapStart);
	g_fwPrivateOnMapStart.AddFunction(INVALID_HANDLE, CustomHitbox_OnMapStart);
}

public any Native_IsEnabled(Handle plugin, int numParams)
{
	return g_bPluginEnabled;
}

public any Native_CanBeStunned(Handle plugin, int numParams)
{
	return g_bPlayerStunnable[GetNativeCell(1)];
}

public any Native_IsPlayerBoss(Handle plugin, int numParams)
{
	return IsBoss(GetNativeCell(1), GetNativeCell(2));
}

public any Native_GetPlayerItemAmount(Handle plugin, int numParams)
{
	int item = GetNativeCell(2);
	
	if (item <= Item_Null || item >= Item_MaxValid)
		return -1;
	
	return GetPlayerItemCount(GetNativeCell(1), item);
}

public any Native_GivePlayerItem(Handle plugin, int numParams)
{
	GiveItem(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
	return 0;
}

public any Native_GetEnemyLevel(Handle plugin, int numParams)
{
	return g_iEnemyLevel;
}

public any Native_GetSurvivorIndex(Handle plugin, int numParams)
{
	return g_iPlayerSurvivorIndex[GetNativeCell(1)];
}

public any Native_GetSurvivorLevel(Handle plugin, int numParams)
{
	return g_iPlayerLevel[GetNativeCell(1)];
}

public any Native_GetSurvivorCount(Handle plugin, int numParams)
{
	return g_iSurvivorCount;
}	

public any Native_GetSurvivorPoints(Handle plugin, int numParams)
{
	return g_iPlayerSurvivorPoints[GetNativeCell(1)];
}

public any Native_SetSurvivorPoints(Handle plugin, int numParams)
{
	g_iPlayerSurvivorPoints[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetDifficultyCoeff(Handle plugin, int numParams)
{	
	return g_flDifficultyCoeff;
}

public any Native_GetSubDifficulty(Handle plugin, int numParams)
{	
	return g_iSubDifficulty;
}

public any Native_GetDifficulty(Handle plugin, int numParams)
{
	return g_iDifficultyLevel;
}

public any Native_GetBaseMaxHealth(Handle plugin, int numParams)
{
	return g_iPlayerBaseHealth[GetNativeCell(1)];
}

public any Native_GetCalculatedMaxHealth(Handle plugin, int numParams)
{
	return g_iPlayerCalculatedMaxHealth[GetNativeCell(1)];
}

public any Native_GetBaseSpeed(Handle plugin, int numParams)
{
	return g_flPlayerMaxSpeed[GetNativeCell(1)];
}

public any Native_GetCalculatedSpeed(Handle plugin, int numParams)
{
	return g_flPlayerCalculatedMaxSpeed[GetNativeCell(1)];
}

public any Native_GetMaxStages(Handle plugin, int numParams)
{
	return g_iMaxStages;
}

public any Native_GetCurrentStage(Handle plugin, int numParams)
{
	return g_iCurrentStage;
}

public any Native_GetTeleporterEntity(Handle plugin, int numParams)
{
	return GetTeleporterEntity();
}

public any Native_IsTankDestructionMode(Handle plugin, int numParams)
{
	return g_bTankBossMode;
}