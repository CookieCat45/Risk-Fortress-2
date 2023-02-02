#if defined _RF2_functions_clients_included
 #endinput
#endif
#define _RF2_functions_clients_included

#pragma semicolon 1
#pragma newdecls required

void RefreshClient(int client)
{
	g_bPlayerViewingItemMenu[client] = false;
	g_bPlayerIsTeleporterBoss[client] = false;
	g_iPlayerStatWearable[client] = -1;
	g_iPlayerEnemyType[client] = -1;
	g_iPlayerBossType[client] = -1;
	g_iPlayerFireRateStacks[client] = 0;
	g_iPlayerAirDashCounter[client] = 0;
	g_bPlayerExtraSentryHint[client] = false;
	
	SetAllInArray(g_bPlayerInCondition[client], sizeof(g_bPlayerInCondition[]), false);
	g_iPlayerEquipmentItem[client] = Item_Null;
	g_flPlayerEquipmentItemCooldown[client] = 0.0;
	
	g_szObjectiveHud[client] = "";
	
	if (IsClientInGameEx(client) && !g_bMapChanging)
	{
		TF2Attrib_RemoveAll(client);
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", false);
		
		// Clear our custom model on a timer so our ragdoll uses the correct model if we're dying.
		CreateTimer(0.5, Timer_ResetModel, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// Do not reset our Survivor stats if we die in the grace period.
	if (!g_bGracePeriod && IsPlayerSurvivor(client) || g_bMapChanging)
	{
		g_iPlayerLevel[client] = 1;
		g_flPlayerXP[client] = 0.0;
		g_flPlayerCash[client] = 0.0;
		g_flPlayerNextLevelXP[client] = g_cvSurvivorBaseXpRequirement.FloatValue;
		g_iPlayerHauntedKeys[client] = 0;
		g_iPlayerSurvivorIndex[client] = -1;
		SetAllInArray(g_iPlayerItem[client], sizeof(g_iPlayerItem[]), 0);
		
		// Recalculate our item sharing for other players, assuming the game is still going.
		if (!g_bMapChanging)
		{
			CalculateSurvivorItemShare();
		}
	}
	
	g_TFBot[client].GoalArea = NULL_AREA;
	g_TFBot[client].ForcedButtons = 0;
	g_TFBot[client].Flags = 0;
	
	g_TFBot[client].HasBuilt = false;
	g_TFBot[client].IsBuilding = false;
	g_TFBot[client].SentryArea = view_as<CTFNavArea>(NULL_AREA);
	g_TFBot[client].Mission = MISSION_NONE;
}

public Action Timer_ResetModel(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || IsPlayerAlive(client))
		return Plugin_Continue;
	
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");	
	return Plugin_Continue;
}

void SilentlyKillPlayer(int client)
{
	int team = GetClientTeam(client);
	ChangeClientTeam(client, 0);
	ChangeClientTeam(client, team);
}

int GetPlayersOnTeam(int team, bool alive=false, bool onlyHumans=false)
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i) || GetClientTeam(i) != team)
			continue;
			
		if (alive && !IsPlayerAlive(i) || onlyHumans && IsFakeClientEx(i))
			continue;
			
		count++;
	}
	
	return count;
}

int GetRandomPlayer(int team = -1, bool alive=true, bool onlyHumans=false)
{
	int count;
	int playerArray[MAXTF2PLAYERS] = {-1, ...};
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i) || onlyHumans && IsFakeClientEx(i))
			continue;
			
		if (alive && !IsPlayerAlive(i) || team >= 0 && GetClientTeam(i) != team)
			continue;
			
		playerArray[count] = i;
		count++;
	}
	
	return playerArray[GetRandomInt(0, count>0 ? count-1 : count)];
}

int GetTotalHumans(bool inGameOnly=true)
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsFakeClientEx(i))
			continue;
			
		if (!inGameOnly || IsClientInGameEx(i))
		{
			count++;
		}
	}
	
	return count;
}

int HealPlayer(int client, int amount, bool allowOverheal=false)
{
	int health = GetClientHealth(client);
	int maxHealth = RF2_GetCalculatedMaxHealth(client);
	
	// we're already overhealed or at max health, don't do anything if we don't allow overheal
	if (!allowOverheal && health >= maxHealth)
	{
		return 0;
	}
	
	int amountHealed = amount;
	SetEntityHealth(client, health+amount);
	
	if (!allowOverheal && GetClientHealth(client) > maxHealth)
	{
		SetEntityHealth(client, maxHealth);
		amountHealed = maxHealth - health;
	}
	
	return amountHealed;
}

bool RollAttackCrit(int client, float proc, int damageType=DMG_GENERIC, int damageCustom=-1)
{
	float critChance;
	int rollTimes = 1;
	int badRolls;
	bool success;
	bool melee = damageType & DMG_MELEE && damageCustom != TF_CUSTOM_BACKSTAB;
	rollTimes += RoundToFloor(CalcItemMod(client, Item_LuckyCatHat, 0));
	rollTimes -= RoundToFloor(CalcItemMod(client, Item_MisfortuneFedora, 0));
	
	if (rollTimes < 0)
	{
		badRolls = rollTimes * -1;
		rollTimes = 1;
	}
	
	if (!PlayerHasItem(client, Item_CrypticKeepsake))
	{
		if (PlayerHasItem(client, Item_TombReaders))
		{
			critChance += CalcItemMod(client, Item_TombReaders, 0);
		}
		
		if (PlayerHasItem(client, Item_SaxtonHat) && melee)
		{
			critChance += CalcItemMod(client, Item_SaxtonHat, 1);
		}
		
		if (PlayerHasItem(client, Item_BruiserBandana))
		{
			critChance += GetItemMod(Item_BruiserBandana, 1);
		}
	}
	else
	{
		critChance += CalcItemMod(client, Item_CrypticKeepsake, 0);
	}
	
	if (melee)
	{
		critChance *= g_cvMeleeCritChanceBonus.FloatValue;
	}
	
	critChance *= proc;
	
	if (critChance > 1.0)
		critChance = 1.0;
	
	for (int i = 1; i <= rollTimes; i++)
	{
		if (RandChanceFloat(0.01, 1.0, critChance))
		{
			if (badRolls <= 0)
			{
				success = true;
				break;
			}
			else
			{
				badRolls--;
				i = 0;
			}
		}
	}
	
	return success;
}

int GetPlayerLevel(int client)
{
	if (IsPlayerSurvivor(client))
	{
		return g_iPlayerLevel[client];
	}
	else
	{
		return RF2_GetEnemyLevel();
	}
}

bool IsInvuln(int client)
{
	return (TF2_IsPlayerInConditionEx(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInConditionEx(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInConditionEx(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInConditionEx(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInConditionEx(client, TFCond_Bonked) ||
		TF2_IsPlayerInConditionEx(client, TFCond_HalloweenGhostMode) ||
		!GetEntProp(client, Prop_Data, "m_takedamage"));
}

/*
bool IsInvis(int client, bool fullyInvis=true)
{
	return ((TF2_IsPlayerInConditionEx(client, TFCond_Cloaked) ||
		TF2_IsPlayerInConditionEx(client, TFCond_Stealthed) ||
		TF2_IsPlayerInConditionEx(client, TFCond_StealthedUserBuffFade))
		&& (!fullyInvis || !TF2_IsPlayerInConditionEx(client, TFCond_CloakFlicker)
		&& !TF2_IsPlayerInConditionEx(client, TFCond_OnFire)
		&& !TF2_IsPlayerInConditionEx(client, TFCond_Jarated)
		&& !TF2_IsPlayerInConditionEx(client, TFCond_Milked)
		&& !TF2_IsPlayerInConditionEx(client, TFCond_Bleeding)
		&& !TF2_IsPlayerInConditionEx(client, TFCond_Gas)));
}
*/

bool CanPlayerRegen(int client)
{
	if (PlayerHasItem(client, Item_HorrificHeadsplitter))
		return false;
	
	return (IsPlayerSurvivor(client) || 
	PlayerHasItem(client, Item_Archimedes) || 
	PlayerHasItem(client, Item_ClassCrown));
}

void PrintDeathMessage(int client)
{
	char message[256];
	switch (GetRandomInt(1, 10))
	{
		case 1:
		{
			FormatEx(message, sizeof(message), "{red}%N's family will never know how they died.", client);
		}
		case 2:
		{
			FormatEx(message, sizeof(message), "{red}%N really messed up.", client);
		}
		case 3:
		{
			FormatEx(message, sizeof(message), "{red}%N's death was extremely painful.", client);
		}
		case 4:
		{
			FormatEx(message, sizeof(message), "{red}Try playing on \"Scrap\" mode for an easier time, %N.", client);
		}
		case 5:
		{
			FormatEx(message, sizeof(message), "{red}That was absolutely your fault, %N.", client);
		}
		case 6:
		{
			FormatEx(message, sizeof(message), "{red}They will surely feast on %N's flesh.", client);
		}
		case 7:
		{
			FormatEx(message, sizeof(message), "{red}%N dies in a hilarious pose.", client);
		}
		case 8:
		{
			FormatEx(message, sizeof(message), "{red}%N embraces the void.", client);
		}
		case 9:
		{
			FormatEx(message, sizeof(message), "{red}%N had a lot more to live for.", client);
		}
		case 10:
		{
			FormatEx(message, sizeof(message), "{red}%N's body was gone an hour later.", client);
		}
	}
	
	#if defined _colors_included
	CPrintToChatAll(message);
	CRemoveTags(message, sizeof(message));
	#else
	ReplaceStringEx(message, sizeof(message), "{red}", "");
	PrintToChatAll(message);
	#endif
	
	PrintToServer(message);
}

int CalculatePlayerMaxHealth(int client, bool partialHeal=true, bool fullHeal=false)
{
	int oldMaxHealth = RF2_GetCalculatedMaxHealth(client);
	int maxHealth = 1;
	int level = GetPlayerLevel(client);
	float healthScale = IsPlayerSurvivor(client) ? g_cvSurvivorHealthScale.FloatValue : g_cvEnemyHealthScale.FloatValue;
	
	maxHealth = RoundToFloor(float(RF2_GetBaseMaxHealth(client)) * (1.0 + (float(level-1) * healthScale)));
	
	int fakeHealth;
	if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		int heads = GetEntProp(client, Prop_Send, "m_iDecapitations");
		if (heads > 4)
			heads = 4;
		
		fakeHealth = heads * 15;
	}
	
	if (PlayerHasItem(client, Item_PrideScarf))
	{
		maxHealth += RoundToFloor(float(maxHealth) * (1.0 + CalcItemMod(client, Item_PrideScarf, 0))) - maxHealth;
	}
	
	if (PlayerHasItem(client, Item_ClassCrown))
	{
		maxHealth += RoundToFloor(float(maxHealth) * (1.0 + CalcItemMod(client, Item_ClassCrown, 0))) - maxHealth;
	}
	
	// Make sure our attribute wearable exists.
	ValidateStatWearable(client);
	int classMaxHealth = TF2_GetClassMaxHealth(TF2_GetPlayerClass(client));
	
	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		TF2Attrib_SetByDefIndex(g_iPlayerStatWearable[client], 286, 1.0 + (float(level-1)*healthScale)); // building health
		
		// If we have any buildings up, update their max health now
		int buildingMaxHealth, oldBuildingMaxHealth, buildingHealth;
		bool carried;
		
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "*")) != -1)
		{
			if (entity <= MaxClients || !IsBuilding(entity))
				continue;
				
			if (GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client)
			{
				carried = bool(GetEntProp(entity, Prop_Send, "m_bCarried"));
				
				if (GetEntProp(entity, Prop_Send, "m_bMiniBuilding"))
				{
					buildingMaxHealth = 100;
				}
				else
				{
					switch (GetEntProp(entity, Prop_Send, "m_iUpgradeLevel"))
					{
						case 1: buildingMaxHealth = 150;
						case 2: buildingMaxHealth = 180;
						case 3: buildingMaxHealth = 216;
					}
				}
				
				if (!carried)
				{
					oldBuildingMaxHealth = GetEntProp(entity, Prop_Send, "m_iMaxHealth");
				}
				
				buildingMaxHealth = RoundToFloor(float(buildingMaxHealth) * TF2Attrib_HookValueFloat(1.0, "mult_engy_building_health", client));
				SetEntProp(entity, Prop_Send, "m_iMaxHealth", buildingMaxHealth);
				
				if (!carried && !GetEntProp(entity, Prop_Send, "m_bBuilding"))
				{
					buildingHealth = GetEntProp(entity, Prop_Send, "m_iHealth");
					SetVariantInt(buildingHealth+(buildingMaxHealth-oldBuildingMaxHealth));
					AcceptEntityInput(entity, "SetHealth");
				}
			}
		}
	}

	int attributeMaxHealth = TF2Attrib_HookValueInt(0, "add_maxhealth", client);
	Address attrib = TF2Attrib_GetByDefIndex(g_iPlayerStatWearable[client], 26);
	if (attrib != Address_Null)
	{
		attributeMaxHealth -= RoundToFloor(TF2Attrib_GetValue(attrib));
	}
	
	maxHealth += attributeMaxHealth;
	
	TF2Attrib_SetByDefIndex(g_iPlayerStatWearable[client], 26, float(maxHealth-classMaxHealth));
	g_iPlayerCalculatedMaxHealth[client] = maxHealth + fakeHealth + attributeMaxHealth;
	
	if (fullHeal)
	{
		HealPlayer(client, maxHealth, false);
	}
	else if (partialHeal)
	{
		int heal = maxHealth - oldMaxHealth;
		HealPlayer(client, heal, false);
	}
	
	return maxHealth;
}

float CalculatePlayerMaxSpeed(int client)
{
	float speed = g_flPlayerMaxSpeed[client];
	float classMaxSpeed = TF2_GetClassMaxSpeed(TF2_GetPlayerClass(client));
	if (speed < classMaxSpeed)
	{
		speed *= speed / classMaxSpeed;
	}
	
	if (PlayerHasItem(client, Item_RobinWalkers))
	{
		speed *= 1.0 + CalcItemMod(client, Item_RobinWalkers, 0);
	}
	
	g_flPlayerCalculatedMaxSpeed[client] = speed;
	float mult = g_flPlayerCalculatedMaxSpeed[client] / g_flPlayerMaxSpeed[client];
	ValidateStatWearable(client);
	TF2Attrib_SetByDefIndex(g_iPlayerStatWearable[client], 107, mult); // "move speed bonus"
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.00001); // hack to force game to update our speed
	
	return speed;
}

float CalculatePlayerKnockbackResist(int client)
{
	ValidateStatWearable(client);
	
	float value = 1.0 / (1.0 + (float(GetPlayerLevel(client)-1) * g_cvEnemyDamageScale.FloatValue));
	if (!IsPlayerSurvivor(client))
	{
		value *= 0.5;
	}
	
	TF2Attrib_SetByDefIndex(g_iPlayerStatWearable[client], 252, value);
	
	return value;
}

void ValidateStatWearable(int client)
{
	// Create our stat wearable if it doesn't exist already
	if (g_iPlayerStatWearable[client] == -1 || !IsValidEntity(g_iPlayerStatWearable[client]))
	{
		const int wearableIndex = 5000;
		char attributes[MAX_ATTRIBUTE_STRING_LENGTH];
		
		if (GetBossType(client) >= 0)
		{
			attributes = BASE_BOSS_ATTRIBUTES;
		}
		else
		{
			attributes = BASE_PLAYER_ATTRIBUTES;
		}
		
		g_iPlayerStatWearable[client] = CreateWearable(client, "tf_wearable", wearableIndex, attributes, false, false, TF2Quality_Valve, 69);
		g_bDontRemoveWearable[g_iPlayerStatWearable[client]] = true;
	}
}

// Attributes are NOT included!
float GetPlayerFireRateMod(int client)
{
	float multiplier = 1.0;
	
	if (PlayerHasItem(client, Item_MaimLicense))
	{
		multiplier *= CalcItemMod_HyperbolicInverted(client, Item_MaimLicense, 0);
	}
	
	if (PlayerHasItem(client, Item_PointAndShoot) && g_iPlayerFireRateStacks[client] > 0)
	{
		multiplier *= (1.0 / (1.0 + (float(g_iPlayerFireRateStacks[client]) * GetItemMod(Item_PointAndShoot, 1))));
	}
	
	return multiplier;
}

int GetPlayerLuckStat(int client)
{
	int luck;
	luck += RoundToFloor(CalcItemMod(client, Item_LuckyCatHat, 0));
	luck -= RoundToFloor(CalcItemMod(client, Item_MisfortuneFedora, 0));
	return luck;
}

void OnPlayerAirDash(int client, int count)
{
	int airDashLimit = 1;
	airDashLimit += GetPlayerItemCount(client, ItemScout_MonarchWings);
	
	if (count < airDashLimit)
	{
		SetEntProp(client, Prop_Send, "m_iAirDash", 0);
	}
}

int TF2_GetClassMaxHealth(TFClassType class)
{
	switch (class)
	{
		case TFClass_Scout: return 125;
		case TFClass_Soldier: return 200;
		case TFClass_Pyro: return 175;
		case TFClass_DemoMan: return 175;
		case TFClass_Heavy: return 300;
		case TFClass_Engineer: return 125;
		case TFClass_Medic: return 150;
		case TFClass_Sniper: return 125;
		case TFClass_Spy: return 125;
	}
	
	return 75;
}

float TF2_GetClassMaxSpeed(TFClassType class)
{
	switch (class)
	{
		case TFClass_Scout: return 400.0;
		case TFClass_Soldier: return 240.0;
		case TFClass_Pyro: return 300.0;
		case TFClass_DemoMan: return 280.0;
		case TFClass_Heavy: return 230.0;
		case TFClass_Engineer: return 300.0;
		case TFClass_Medic: return 320.0;
		case TFClass_Sniper: return 300.0;
		case TFClass_Spy: return 320.0;
	}
	
	return 300.0;
}

void TF2_GetClassString(TFClassType class, char[] buffer, int size, bool underScore=false, bool capitalize=false)
{
	switch (class)
	{
		case TFClass_Scout: strcopy(buffer, size, "scout");
		case TFClass_Soldier: strcopy(buffer, size, "soldier");
		case TFClass_Pyro: strcopy(buffer, size, "pyro");
		case TFClass_DemoMan: strcopy(buffer, size, "demoman");
		case TFClass_Heavy: strcopy(buffer, size, "heavy");
		case TFClass_Engineer: strcopy(buffer, size, "engineer");
		case TFClass_Medic: strcopy(buffer, size, "medic");
		case TFClass_Sniper: strcopy(buffer, size, "sniper");
		case TFClass_Spy: strcopy(buffer, size, "spy");
		default: strcopy(buffer, size, "unknown");
	}
	
	if (underScore)
		Format(buffer, size, "%s_", buffer);
		
	if (capitalize)
	{
		int chr = buffer[0];
		CharToUpper(chr);
	}
}

int TF2_GetPlayerBuildingCount(int client, TFObjectType type=view_as<TFObjectType>(-1))
{
	int count;
	int entity = -1;
	
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		if (entity <= MaxClients || !IsBuilding(entity))
			continue;
		
		if (view_as<int>(type) == -1 || view_as<TFObjectType>(GetEntProp(entity, Prop_Send, "m_iObjectType")) == type)
		{
			if (GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client)
			{
				count++;
			}
		}
	}
	
	return count;
}

// Use this over TF2_IsPlayerInCondition().
bool TF2_IsPlayerInConditionEx(int client, TFCond condition)
{
	return g_bPlayerInCondition[client][condition];
}

bool IsPlayerAFK(int client)
{
	return g_bPlayerIsAFK[client];
}

void ResetAFKTime(int client)
{
	if (!g_bMapChanging && IsPlayerAFK(client))
	{
		PrintCenterText(client, "You are no longer marked as AFK.");
		if (!IsPlayerAlive(client))
		{
			ChangeClientTeam(client, TEAM_ENEMY);
		}
	}
	
	g_flPlayerAFKTime[client] = 0.0;
	g_bPlayerIsAFK[client] = false;
}

void OnPlayerEnterAFK(int client)
{
	SetClientName(client, g_szPlayerOriginalName[client]);
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGameEx(client));
}

bool IsClientInGameEx(int client)
{
	return g_bPlayerInGame[client];
}

bool IsFakeClientEx(int client)
{
	return g_bPlayerFakeClient[client];
}

public bool TraceFilter_PlayerTeam(int entity, int mask, int team)
{
	if (entity <= MaxClients && GetClientTeam(entity) == team)
		return true;
	
	return false;
}

void SDK_EquipWearable(int client, int entity)
{
	if (g_hSDKEquipWearable)
		SDKCall(g_hSDKEquipWearable, client, entity);
}

public MRESReturn DHook_TakeHealth(int entity, DHookReturn returnVal, DHookParam params)
{
	if (!RF2_IsEnabled() || entity > MaxClients)
	{
		return MRES_Ignored;
	}
	
	float amount = DHookGetParam(params, 1);
	
	if (IsPlayerSurvivor(entity))
	{
		amount *= 1.0 + (float(GetPlayerLevel(entity))-1 * g_cvSurvivorHealthScale.FloatValue);
	}
	else
	{
		amount *= GetEnemyHealthMult();
	}
	
	DHookSetParam(params, 1, amount);
	return MRES_ChangedHandled;
}

public MRESReturn DHook_CanBuild(int client, DHookReturn returnVal, DHookParam params)
{
	if (RF2_IsEnabled() && PlayerHasItem(client, ItemEngi_HeadOfDefense) && DHookGetParam(params, 1) == view_as<int>(TFObject_Sentry))
	{
		if (TF2_GetPlayerBuildingCount(client, TFObject_Sentry) <= RoundToFloor(CalcItemMod(client, ItemEngi_HeadOfDefense, 0))+1)
		{
			DHookSetReturn(returnVal, CB_CAN_BUILD);
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}