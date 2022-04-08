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
	
	CreateNative("RF2_GetDamageStat", Native_GetDamageStat);
	
	CreateNative("RF2_GetBaseSpeedStat", Native_GetBaseSpeedStat);
	CreateNative("RF2_GetCalculatedSpeedStat", Native_GetCalculatedSpeedStat);
	
	CreateNative("RF2_GetStageNum", Native_GetStageNum);
	CreateNative("RF2_SetStageNum", Native_SetStageNum);
	CreateNative("RF2_GetMaxStages", Native_GetMaxStages);
}

void LoadForwards()
{
	f_TeleEventStart = CreateGlobalForward("RF2_OnTeleporterEventStart", ET_Hook, Param_Cell);
	f_GracePeriodStart = CreateGlobalForward("RF2_OnGracePeriodStart", ET_Ignore);
	f_GracePeriodEnded = CreateGlobalForward("RF2_OnGracePeriodEnd", ET_Ignore);
}

public int Native_IsRF2Enabled(Handle plugin, int numParams)
{
	return g_bPluginEnabled;
}

public int Native_CanBeStunned(Handle plugin, int numParams)
{
	return g_bStunnable[GetNativeCell(1)];
}

public int Native_IsPlayerBoss(Handle plugin, int numParams)
{
	if (GetNativeCell(2) == true)
		return g_bIsTeleporterBoss[GetNativeCell(1)];
		
	return g_bIsBoss[GetNativeCell(1)];
}

public int Native_GetPlayerItemAmount(Handle plugin, int numParams)
{
	return -1;
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

// Player stats natives
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

public any Native_GetDamageStat(Handle plugin, int numParams)
{
	return g_flPlayerBaseDamage[GetNativeCell(1)];
}

public any Native_GetBaseSpeedStat(Handle plugin, int numParams)
{
	return g_flPlayerMaxSpeed[GetNativeCell(1)];
}

public any Native_GetCalculatedSpeedStat(Handle plugin, int numParams)
{
	return g_flPlayerCalculatedMaxSpeed[GetNativeCell(1)];
}

public any Native_GetStageNum(Handle plugin, int numParams)
{
	return g_iCurrentStage;
}

public any Native_SetStageNum(Handle plugin, int numParams)
{
	g_iCurrentStage = GetNativeCell(1);
}

public any Native_GetMaxStages(Handle plugin, int numParams)
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, MapConfig);
	if (!FileExists(config))
	{
		ThrowError("File %s does not exist", config);
		RF2_PrintToChatAll("Config file %s does not exist, please correct this", config);
	}
	
	Handle mapKey = CreateKeyValues("stages");
	FileToKeyValues(mapKey, config);
	
	char stage[16];
	int stageCount = 0;
	
	for (int i = 0; i <= MAX_STAGES; i++)
	{
		KvRewind(mapKey);
		FormatEx(stage, sizeof(stage), "stage%i", i+1);
		if (KvJumpToKey(mapKey, stage))
		{
			stageCount++;
		}
		else
		{
			break;
		}
	}
	delete mapKey;
	return stageCount-1;
}