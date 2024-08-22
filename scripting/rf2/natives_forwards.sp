#if defined _RF2_natives_forwards_included
 #endinput
#endif
#define _RF2_natives_forwards_included

#pragma semicolon 1
#pragma newdecls required

void LoadNatives()
{
	CreateNative("RF2_IsEnabled", Native_IsEnabled);
	CreateNative("RF2_IsPlayerBoss", Native_IsPlayerBoss);
	CreateNative("RF2_IsPlayerMinion", Native_IsPlayerMinion);
	CreateNative("RF2_GetPlayerItemAmount", Native_GetPlayerItemAmount);
	CreateNative("RF2_CalcItemMod", Native_CalcItemMod);
	CreateNative("RF2_CalcItemMod_Hyperbolic", Native_CalcItemMod_Hyperbolic);
	CreateNative("RF2_CalcItemMod_HyperbolicInverted", Native_CalcItemMod_HyperbolicInverted);
	CreateNative("RF2_GetItemMod", Native_GetItemMod);
	CreateNative("RF2_RandChanceInt", Native_RandChanceInt);
	CreateNative("RF2_RandChanceFloat", Native_RandChanceFloat);
	CreateNative("RF2_RandChanceIntEx", Native_RandChanceIntEx);
	CreateNative("RF2_RandChanceFloatEx", Native_RandChanceFloatEx);
	CreateNative("RF2_GetPlayerEquipmentItem", Native_GetPlayerEquipmentItem);
	CreateNative("RF2_GetItemProcCoeff", Native_GetItemProcCoeff);
	CreateNative("RF2_GetItemQuality", Native_GetItemQuality);
	CreateNative("RF2_GetTotalItems", Native_GetTotalItems);
	CreateNative("RF2_FindCustomItem", Native_FindCustomItem);
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
	CreateNative("RF2_ShootProjectile", Native_ShootProjectile);
	CreateNative("RF2_DoRadiusDamage", Native_DoRadiusDamage);
	CreateNative("RF2_TakeDamage", Native_TakeDamage);
	CreateNative("RF2_SetEntItemProc", Native_SetEntItemProc);
	CreateNative("RF2_GetEntItemProc", Native_GetEntItemProc);
	CreateNative("RF2_GetMaxStages", Native_GetMaxStages);
	CreateNative("RF2_GetCurrentStage", Native_GetCurrentStage);
	CreateNative("RF2_GetCompletedStages", Native_GetCompletedStages);
	CreateNative("RF2_GetLoopCount", Native_GetLoopCount);
	CreateNative("RF2_GetTeleporterEntity", Native_GetTeleporterEntity);
	CreateNative("RF2_IsTankDestructionMode", Native_IsTankDestructionMode);
}

void LoadForwards()
{
	g_fwTeleEventStart = new GlobalForward("RF2_OnTeleporterEventStart", ET_Ignore);
	g_fwTeleEventEnd = new GlobalForward("RF2_OnTeleporterEventEnd", ET_Ignore);
	g_fwGracePeriodStart = new GlobalForward("RF2_OnGracePeriodStart", ET_Ignore);
	g_fwGracePeriodEnded = new GlobalForward("RF2_OnGracePeriodEnd", ET_Ignore);
	g_fwOnTakeDamage = new GlobalForward("RF2_OnTakeDamage", ET_Hook, Param_Cell, Param_CellByRef, Param_CellByRef, Param_FloatByRef, Param_CellByRef, 
		Param_CellByRef, Param_Array, Param_Array, Param_Cell, Param_CellByRef, Param_Cell, Param_Cell, Param_Float);

	g_fwOnCustomItemLoaded = new GlobalForward("RF2_OnCustomItemLoaded", ET_Ignore, Param_String, Param_String, Param_Cell);
	g_fwOnPlayerItemUpdate = new GlobalForward("RF2_OnPlayerItemUpdate", ET_Ignore, Param_Cell, Param_Cell);
}

public any Native_IsEnabled(Handle plugin, int numParams)
{
	return g_bPluginEnabled;
}

public any Native_IsPlayerBoss(Handle plugin, int numParams)
{
	return IsBoss(GetNativeCell(1), GetNativeCell(2));
}

public any Native_IsPlayerMinion(Handle plugin, int numParams)
{
	return IsPlayerMinion(GetNativeCell(1));
}

public any Native_GetPlayerItemAmount(Handle plugin, int numParams)
{
	return GetPlayerItemCount(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public any Native_CalcItemMod(Handle plugin, int numParams)
{
	return CalcItemMod(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5));
}

public any Native_CalcItemMod_Hyperbolic(Handle plugin, int numParams)
{
	return CalcItemMod_Hyperbolic(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5));
}

public any Native_CalcItemMod_HyperbolicInverted(Handle plugin, int numParams)
{
	return CalcItemMod_HyperbolicInverted(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5));
}

public any Native_GetItemMod(Handle plugin, int numParams)
{
	return GetItemMod(GetNativeCell(1), GetNativeCell(2));
}

public any Native_RandChanceInt(Handle plugin, int numParams)
{
	int ref = GetNativeCellRef(4);
	bool result = RandChanceInt(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), ref);
	SetNativeCellRef(4, ref);
	return result;
}

public any Native_RandChanceFloat(Handle plugin, int numParams)
{
	float ref = GetNativeCellRef(4);
	bool result = RandChanceFloat(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), ref);
	SetNativeCellRef(4, ref);
	return result;
}

public any Native_RandChanceIntEx(Handle plugin, int numParams)
{
	int ref = GetNativeCellRef(5);
	bool result = RandChanceIntEx(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), ref);
	SetNativeCellRef(5, ref);
	return result;
}

public any Native_RandChanceFloatEx(Handle plugin, int numParams)
{
	float ref = GetNativeCellRef(5);
	bool result = RandChanceFloatEx(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), ref);
	SetNativeCellRef(5, ref);
	return result;
}

public any Native_GetPlayerEquipmentItem(Handle plugin, int numParams)
{
	return GetPlayerEquipmentItem(GetNativeCell(1));
}

public any Native_GetItemProcCoeff(Handle plugin, int numParams)
{
	return GetItemProcCoeff(GetNativeCell(1));
}

public any Native_GetItemQuality(Handle plugin, int numParams)
{
	return GetItemQuality(GetNativeCell(1));
}

public any Native_GetTotalItems(Handle plugin, int numParams)
{
	return GetTotalItems();
}

public any Native_FindCustomItem(Handle plugin, int numParams)
{
	char file[PLATFORM_MAX_PATH], name[64];
	GetNativeString(1, file, sizeof(file));
	GetNativeString(2, name, sizeof(name));
	for (int i = 1; i < GetTotalItems(); i++)
	{
		if (strcmp2(file, g_szCustomItemFileName[i]) && strcmp2(name, g_szItemSectionName[i]))
		{
			return i;
		}
	}
	
	return Item_Null;
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
	return GetCookieInt(GetNativeCell(1), g_coSurvivorPoints);
}

public any Native_SetSurvivorPoints(Handle plugin, int numParams)
{
	SetCookieInt(GetNativeCell(1), g_coSurvivorPoints, GetNativeCell(2));
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

public any Native_ShootProjectile(Handle plugin, int numParams)
{
	char classname[128];
	GetNativeString(2, classname, sizeof(classname));
	float pos[3], angles[3];
	GetNativeArray(3, pos, sizeof(pos));
	GetNativeArray(4, angles, sizeof(angles));
	return ShootProjectile(GetNativeCell(1), classname, pos, angles, GetNativeCell(5), GetNativeCell(6), GetNativeCell(7), GetNativeCell(8), GetNativeCell(9));
}

public any Native_DoRadiusDamage(Handle plugin, int numParams)
{
	float pos[3];
	GetNativeArray(3, pos, sizeof(pos));
	return DoRadiusDamage(GetNativeCell(1), GetNativeCell(2), pos, GetNativeCell(4), GetNativeCell(5), GetNativeCell(6), GetNativeCell(7), GetNativeCell(8),
		GetNativeCell(9), GetNativeCell(10), GetNativeCell(11));
}

public any Native_TakeDamage(Handle plugin, int numParams)
{
	float pos[3], force[3];
	GetNativeArray(8, force, sizeof(force));
	GetNativeArray(9, pos, sizeof(pos));
	RF_TakeDamage(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), GetNativeCell(6), GetNativeCell(7), force, pos);
	return 0;
}

public any Native_SetEntItemProc(Handle plugin, int numParams)
{
	SetEntItemProc(GetNativeCell(1), GetNativeCell(2));
	return 0;
}

public any Native_GetEntItemProc(Handle plugin, int numParams)
{
	return GetEntItemProc(GetNativeCell(1));
}

public any Native_GetMaxStages(Handle plugin, int numParams)
{
	return g_iMaxStages;
}

public any Native_GetCurrentStage(Handle plugin, int numParams)
{
	return g_iCurrentStage;
}

public any Native_GetCompletedStages(Handle plugin, int numParams)
{
	return g_iStagesCompleted;
}

public any Native_GetLoopCount(Handle plugin, int numParams)
{
	return g_iLoopCount;
}

public any Native_GetTeleporterEntity(Handle plugin, int numParams)
{
	return GetCurrentTeleporter().index;
}

public any Native_IsTankDestructionMode(Handle plugin, int numParams)
{
	return g_bTankBossMode;
}