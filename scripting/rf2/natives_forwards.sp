#if defined _RF2_natives_forwards_included
 #endinput
#endif
#define _RF2_natives_forwards_included

void LoadNatives()
{
	CreateNative("RF2_IsRF2Enabled", Native_IsRF2Enabled);
	CreateNative("RF2_CanBeStunned", Native_CanBeStunned);
	CreateNative("RF2_IsPlayerBoss", Native_IsPlayerBoss);
	CreateNative("RF2_GetPlayerItemAmount", Native_GetPlayerItemAmount);
	CreateNative("RF2_IsTeleporterEvent", Native_IsTeleporterEvent);
	
	CreateNative("RF2_GetSurvivorCount", Native_GetSurvivorCount);
	CreateNative("RF2_GetSurvivorPoints", Native_GetSurvivorPoints);
	CreateNative("RF2_SetSurvivorPoints", Native_SetSurvivorPoints);
	
	CreateNative("RF2_GetDifficultyCoeff", Native_GetDifficultyCoeff);
	CreateNative("RF2_GetSubDifficulty", Native_GetSubDifficulty);
	CreateNative("RF2_GetInitialDifficulty", Native_GetInitialDifficulty);
	
	CreateNative("RF2_GetBaseMaxHealth", Native_GetBaseMaxHealth);
	CreateNative("RF2_GetCalculatedMaxHealth", Native_GetCalculatedMaxHealth);
	CreateNative("RF2_GetBaseSpeed", Native_GetBaseSpeed);
	CreateNative("RF2_GetCalculatedSpeed", Native_GetCalculatedSpeed);
	
	CreateNative("RF2_GetMaxStages", Native_GetMaxStages);
	CreateNative("RF2_GetCurrentStage", Native_GetCurrentStage);
	CreateNative("RF2_GetTeleporterEntity", Native_GetTeleporterEntity);
}

void LoadForwards()
{
	f_TeleEventStart = CreateGlobalForward("RF2_OnTeleporterEventStart", ET_Hook, Param_Cell);
	f_GracePeriodStart = CreateGlobalForward("RF2_OnGracePeriodStart", ET_Ignore);
	f_GracePeriodEnded = CreateGlobalForward("RF2_OnGracePeriodEnd", ET_Ignore);
}

public any Native_IsRF2Enabled(Handle plugin, int numParams)
{
	return g_bPluginEnabled;
}

public any Native_CanBeStunned(Handle plugin, int numParams)
{
	return g_bStunnable[GetNativeCell(1)];
}

public any Native_IsPlayerBoss(Handle plugin, int numParams)
{
	if (GetNativeCell(2) == true)
		return g_bIsTeleporterBoss[GetNativeCell(1)];
		
	return g_bIsBoss[GetNativeCell(1)];
}

public any Native_GetPlayerItemAmount(Handle plugin, int numParams)
{
	RF2ItemType itemIdx = GetNativeCell(2);
	if (itemIdx <= Item_Null || itemIdx >= Item_MaxValid)
		return -1;
	
	return g_iPlayerItem[GetNativeCell(1)][itemIdx];
}

public any Native_GetSurvivorCount(Handle plugin, int numParams)
{
	return g_iSurvivorCount;
}	

public any Native_GetSurvivorPoints(Handle plugin, int numParams)
{
	return g_iSurvivorPoints[GetNativeCell(1)];
}

public any Native_SetSurvivorPoints(Handle plugin, int numParams)
{
	g_iSurvivorPoints[GetNativeCell(1)] = GetNativeCell(2);
}

public any Native_GetDifficultyCoeff(Handle plugin, int numParams)
{	
	return g_flDifficultyCoeff;
}

public any Native_GetSubDifficulty(Handle plugin, int numParams)
{	
	return g_iSubDifficulty;
}

public any Native_GetInitialDifficulty(Handle plugin, int numParams)
{
	return g_iDifficultyLevel;
}

public any Native_IsTeleporterEvent(Handle plugin, int numParams)
{
	return g_bTeleporterEvent;
}

public any Native_GetSurvivorIndex(Handle plugin, int numParams)
{
	return g_iPlayerSurvivorIndex[GetNativeCell(1)];
}

public any Native_GetSurvivorLevel(Handle plugin, int numParams)
{
	return g_iPlayerLevel[GetNativeCell(1)];
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
	return g_iTeleporter;
}