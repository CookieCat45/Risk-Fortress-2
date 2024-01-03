#if defined _RF2_survivors_included
 #endinput
#endif
#define _RF2_survivors_included

#pragma semicolon 1
#pragma newdecls required

int g_iSurvivorCount = 1;
int g_iSurvivorBaseHealth[TF_CLASSES];
int g_iSavedItem[MAX_SURVIVORS][MAX_ITEMS];
int g_iSavedLevel[MAX_SURVIVORS] = {1, ...};
int g_iSavedEquipmentItem[MAX_SURVIVORS];
int g_iSavedHauntedKeys[MAX_SURVIVORS];

float g_flSurvivorMaxSpeed[TF_CLASSES];
float g_flSavedXP[MAX_SURVIVORS];
float g_flSavedNextLevelXP[MAX_SURVIVORS] = {150.0, ...};

char g_szSurvivorAttributes[TF_CLASSES][MAX_ATTRIBUTE_STRING_LENGTH];
bool g_bSurvivorInventoryClaimed[MAX_SURVIVORS];
StringMap g_hPlayerSteamIDToInventoryIndex;

void LoadSurvivorStats()
{
	KeyValues survivorKey = CreateKeyValues("survivors");
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, SurvivorConfig);
	if (!survivorKey.ImportFromFile(config))
	{
		delete survivorKey;
		ThrowError("File %s does not exist", config);
	}
	
	TFClassType class;
	bool firstKey = true;
	char sectionName[32];
	
	for (int i = 0; i < TF_CLASSES; i++)
	{
		if (firstKey ? survivorKey.GotoFirstSubKey(false) : survivorKey.GotoNextKey(false))
		{
			survivorKey.GetSectionName(sectionName, sizeof(sectionName));
			if ((class = TF2_GetClass(sectionName)) != TFClass_Unknown)
			{
				g_iSurvivorBaseHealth[class] = survivorKey.GetNum("health", 450);
				g_flSurvivorMaxSpeed[class] = survivorKey.GetFloat("speed", 300.0);
				survivorKey.GetString("attributes", g_szSurvivorAttributes[class], sizeof(g_szSurvivorAttributes[]));
				
				firstKey = false;
			}
		}
	}
	
	delete survivorKey;
}

bool CreateSurvivors()
{
	if (!g_hPlayerSteamIDToInventoryIndex)
		g_hPlayerSteamIDToInventoryIndex = new StringMap();
	
	ArrayList survivorList = new ArrayList();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsPlayerSpectator(i))
			continue;
			
		if (IsFakeClient(i))
		{
			if (!g_cvBotsCanBeSurvivor.BoolValue)
			{
				SilentlyKillPlayer(i);
				ChangeClientTeam(i, TEAM_ENEMY);
				continue;
			}
			else
			{
				SetEntProp(i, Prop_Send, "m_nBotSkill", TFBotDifficulty_Expert);
			}
		}
		
		if (GetClientTeam(i) != TEAM_ENEMY)
		{
			if (IsPlayerAlive(i))
			{
				SilentlyKillPlayer(i);
			}
			
			ChangeClientTeam(i, TEAM_ENEMY);
		}
		
		survivorList.Push(i);
	}
	
	// sort by queue points
	survivorList.SortCustom(SortSurvivorListByPoints);
	int maxSurvivors = g_cvMaxSurvivors.IntValue;
	if (survivorList.Length > maxSurvivors)
		survivorList.Resize(maxSurvivors);
	
	// sort by inventory index, so people who own inventories can get their stuff back first
	survivorList.SortCustom(SortSurvivorListByInventory);
	bool indexTaken[MAX_SURVIVORS];
	int survivorCount, client, index;
	char steamId[MAX_AUTHID_LENGTH];
	
	for (int i = 0; i < survivorList.Length; i++)
	{
		client = survivorList.Get(i);
		if (g_bGameInitialized && !IsFakeClient(client))
		{
			int steamIDIndex;
			// check to see if we can get our own inventory back
			if (GetClientAuthId(client, AuthId_SteamID64, steamId, sizeof(steamId)) 
				&& g_hPlayerSteamIDToInventoryIndex.GetValue(steamId, steamIDIndex) && !indexTaken[steamIDIndex])
			{
				index = steamIDIndex;
			}
			else
			{
				// if we can't do that, try to find an empty inventory
				int index2 = -1;
				for (int s = 0; s < maxSurvivors; s++)
				{
					if (indexTaken[s])
						continue;
					
					if (!g_bSurvivorInventoryClaimed[s])
					{
						index2 = s;
						break;
					}
				}
				
				if (index2 == -1)
				{
					// if we can't find an empty inventory, just find the next inventory that hasn't been taken by someone else
					for (int s = 0; s < maxSurvivors; s++)
					{
						if (!indexTaken[s])
						{
							index2 = s;
							break;
						}
					}
				}
				
				index = index2;
			}
		}
		else
		{
			index = survivorCount;
		}
		
		g_iPlayerSurvivorIndex[client] = index;
		indexTaken[index] = true;
		MakeSurvivor(client, index);
		g_bSurvivorInventoryClaimed[index] = true;
		survivorCount++;
		index = -1;
	}
	
	g_iSurvivorCount = survivorCount;
	delete survivorList;
	return survivorCount > 0;
}

void MakeSurvivor(int client, int index, bool resetPoints=true, bool loadInventory=true)
{
	if (resetPoints)
		g_iPlayerSurvivorPoints[client] = 0;

	// Player is probably still on the class select screen, so we need to kick them out by giving them a random class.
	if (TF2_GetPlayerClass(client) == TFClass_Unknown)
	{
		TF2_SetPlayerClass(client, view_as<TFClassType>(GetRandomInt(1, 9)));
	}
	
	ResetAFKTime(client, false);
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel"); // In case this was from the command or otherwise, clear our custom model
	TFClassType class = TF2_GetPlayerClass(client);
	g_iPlayerSurvivorIndex[client] = index;
	g_iPlayerBaseHealth[client] = g_iSurvivorBaseHealth[class];
	g_flPlayerMaxSpeed[client] = g_flSurvivorMaxSpeed[class];
	
	TF2Attrib_RemoveAll(client);
	if (g_szSurvivorAttributes[class][0])
	{
		char buffer[MAX_ATTRIBUTE_STRING_LENGTH];
		strcopy(buffer, sizeof(buffer), g_szSurvivorAttributes[class]);
		ReplaceString(buffer, sizeof(buffer), " ; ", " = ");
		char attrs[32][32];
		int count = ExplodeString(buffer, " = ", attrs, 32, 32, true);
		
		int attrib, totalAttribs;
		float val;
		for (int n = 0; n <= count+1; n+=2)
		{
			attrib = StringToInt(attrs[n]);
			if (IsAttributeBlacklisted(attrib) || attrib <= 0)
				continue;
			
			val = StringToFloat(attrs[n+1]);
			
			totalAttribs++;
			if (totalAttribs > MAX_ATTRIBUTES)
				break;
				
			TF2Attrib_SetByDefIndex(client, attrib, val);
		}
		
		if (totalAttribs > MAX_ATTRIBUTES)
		{
			char tfClassName[16];
			TF2_GetClassString(class, tfClassName, sizeof(tfClassName));
			LogError("[MakeSurvivor] Survivor class %i (%s) reached attribute limit of %i", view_as<int>(class), tfClassName, MAX_ATTRIBUTES);
		}
	}
	
	ChangeClientTeam(client, TEAM_SURVIVOR);
	
	// This is so weapons/wearables update properly on plugin reloads.
	TF2_RemoveAllWeapons(client);
	TF2_RemoveAllWearables(client);
	TF2_RespawnPlayer(client);
	TF2_AddCondition(client, TFCond_UberchargedCanteen, 5.0);
	SetEntProp(client, Prop_Send, "m_bGlowEnabled", true);
	
	if (loadInventory)
	{
		if (g_bGameInitialized && IsSurvivorInventoryEmpty(index))
		{
			// if we join in a game and our inventory is empty, get us up to speed
			g_iPlayerLevel[client] = GetLowestSurvivorLevel();
			int itemsToGive = GetTotalSurvivorItems() / GetTotalClaimedInventories();
			for (int i = 1; i <= itemsToGive; i++)
			{
				GiveItem(client, GetRandomItem(79, 20, 1));
			}
		}
		else
		{
			LoadSurvivorInventory(client, index);
		}
	}
	else // we should still update our items in case this is a respawn
	{
		for (int i = 1; i < Item_MaxValid; i++)
		{
			if (PlayerHasItem(client, i))
			{
				UpdatePlayerItem(client, i);
			}
		}
	}
	
	if (!IsFakeClient(client) && !GetClientCookieInt(client, g_coTutorialSurvivor))
	{
		CreateTimer(1.0, Timer_SurvivorTutorial, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public int SortSurvivorListByPoints(int index1, int index2, ArrayList array, Handle hndl)
{
	int client1 = array.Get(index1);
	int client2 = array.Get(index2);
	
	// move bots, AFK people and those who don't want to be survivors to the end of the list
	if (!g_bPlayerBecomeSurvivor[client1] && !g_bPlayerBecomeSurvivor[client2])
	{
		return 0;
	}
	else if (!g_bPlayerBecomeSurvivor[client1])
	{
		return 1;
	}
	else if (!g_bPlayerBecomeSurvivor[client2])
	{
		return -1;
	}
	
	if (IsPlayerAFK(client1) && IsPlayerAFK(client2))
	{
		return 0;
	}
	else if (IsFakeClient(client1) || IsPlayerAFK(client1))
	{
		return 1;
	}
	else if (IsFakeClient(client2) || IsPlayerAFK(client2))
	{
		return -1;
	}
	
	if (g_iPlayerSurvivorPoints[client1] == g_iPlayerSurvivorPoints[client2])
		return 0;
	
	return g_iPlayerSurvivorPoints[client1] > g_iPlayerSurvivorPoints[client2] ? -1 : 1;
}

public int SortSurvivorListByInventory(int index1, int index2, ArrayList array, Handle hndl)
{
	int client1 = array.Get(index1);
	int client2 = array.Get(index2);

	if (IsFakeClient(client1))
	{
		return 1;
	}
	else if (IsFakeClient(client2))
	{
		return -1;
	}

	int inv1 = GetClientOwnedInventory(client1);
	int inv2 = GetClientOwnedInventory(client2);

	// whoever owns the lowest inventory index should be made a survivor first, so they can get their inventory back
	if (inv1 == inv2)
	{
		return 0;
	}
	else if (inv1 == -1)
	{
		return 1;
	}
	else if (inv2 == -1)
	{
		return -1;
	}
	else if (inv1 >= 0 && inv1 < inv2)
	{
		return -1;
	}
	else if (inv2 >= 0 && inv2 < inv1)
	{
		return 1;
	}
	
	return 0;
}

public Action Timer_SurvivorTutorial(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
	
	PrintKeyHintText(client, "%t", "SurvivorTutorial");
	CreateTimer(13.0, Timer_SurvivorTutorial2, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Timer_SurvivorTutorial2(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
	
	PrintKeyHintText(client, "%t", "SurvivorTutorial2");
	SetClientCookie(client, g_coTutorialSurvivor, "1");
	return Plugin_Continue;
}

void LoadSurvivorInventory(int client, int index)
{
	g_iPlayerEquipmentItem[client] = g_iSavedEquipmentItem[index];
	g_iPlayerEquipmentItemCharges[client] = 1;
	if (GetPlayerEquipmentItem(client) != Item_Null && PlayerHasItem(client, Item_BatteryCanteens))
	{
		g_flPlayerEquipmentItemCooldown[client] = GetPlayerEquipmentItemCooldown(client);
		CreateTimer(0.1, Timer_EquipmentCooldown, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	for (int i = 0; i < Item_MaxValid; i++)
	{
		if (IsEquipmentItem(i))
			continue;
		
		g_iPlayerItem[client][i] = g_iSavedItem[index][i];
		if (PlayerHasItem(client, i))
		{
			UpdatePlayerItem(client, i);
		}
	}
	
	g_iPlayerLevel[client] = g_iSavedLevel[index];
	g_flPlayerXP[client] = g_flSavedXP[index];
	g_iPlayerHauntedKeys[client] = g_iSavedHauntedKeys[index];
	g_flPlayerCash[client] = 100.0 * GetObjectCostMultiplier();
	g_iItemsTaken[index] = 0;
	
	if (g_iPlayerLevel[client] > 1)
	{
		g_flPlayerNextLevelXP[client] = g_flSavedNextLevelXP[index];
	}
	else
	{
		g_flPlayerNextLevelXP[client] = g_cvSurvivorBaseXpRequirement.FloatValue;
	}
	
	PrintCenterText(client, "%t", "GivenInventory", index+1);
}

void SaveSurvivorInventory(int client, int index, bool saveSteamId=true)
{
	if (index < 0)
		return;
		
	for (int i = 0; i < Item_MaxValid; i++)
	{
		if (IsEquipmentItem(i))
			continue;
		
		g_iSavedItem[index][i] = GetPlayerItemCount(client, i);
	}
	
	g_iSavedLevel[index] = g_iPlayerLevel[client];
	g_flSavedXP[index] = g_flPlayerXP[client];
	g_flSavedNextLevelXP[index] = g_flPlayerNextLevelXP[client];
	g_iSavedEquipmentItem[index] = GetPlayerEquipmentItem(client);
	g_iSavedHauntedKeys[index] = g_iPlayerHauntedKeys[client];
	
	char steamId[MAX_AUTHID_LENGTH];
	if (saveSteamId && GetClientAuthId(client, AuthId_SteamID64, steamId, sizeof(steamId)))
	{
		g_hPlayerSteamIDToInventoryIndex.SetValue(steamId, index, false);
	}
}

// Checks if the client's SteamID is associated with the inventory for this survivor index
bool DoesClientOwnInventory(int client, int index)
{
	if (!g_hPlayerSteamIDToInventoryIndex)
		return false;
	
	char steamId[MAX_AUTHID_LENGTH];
	int index2;
	
	return GetClientAuthId(client, AuthId_SteamID64, steamId, sizeof(steamId)) 
		&& g_hPlayerSteamIDToInventoryIndex.GetValue(steamId, index2) && index2 == index;
}

int GetClientOwnedInventory(int client)
{
	for (int i = 0; i < g_cvMaxSurvivors.IntValue; i++)
	{
		if (DoesClientOwnInventory(client, i))
			return i;
	}
	
	return -1;
}

bool IsSurvivorInventoryEmpty(int index)
{
	return !g_bSurvivorInventoryClaimed[index];
}

int GetLowestSurvivorLevel()
{
	int lowest = 1;
	for (int i = 0; i < g_cvMaxSurvivors.IntValue; i++)
	{
		if (g_iSavedLevel[i] <= 1)
			continue;
	
		if (lowest <= 1 || g_iSavedLevel[i] < lowest)
			lowest = g_iSavedLevel[i];
	}
	
	return lowest;
}

int GetTotalSurvivorItems()
{
	int total;
	for (int i = 0; i < g_cvMaxSurvivors.IntValue; i++)
	{
		for (int j = 0; j < MAX_ITEMS; j++)
		{
			total += g_iSavedItem[i][j];
		}
	}

	return total;
}

int GetTotalClaimedInventories()
{
	int total;
	for (int i = 0; i < g_cvMaxSurvivors.IntValue; i++)
	{
		if (g_bSurvivorInventoryClaimed[i])
			total++;
	}

	return total;
}

void CalculateSurvivorItemShare(bool recalculate=true)
{
	int survivorCount;
	
	// We want to remember how many objects were spawned at the beginning of the round. If recalculate is true, don't touch our object count.
	static int objectCount;
	if (!recalculate)
	{
		objectCount = 0;
	}
	
	char classname[32];
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		if (entity < 1)
			continue;
		
		if (entity <= MaxClients && IsPlayerSurvivor(entity))
			survivorCount++;
		
		if (!recalculate)
		{
			GetEntityClassname(entity, classname, sizeof(classname));
			
			if (StrContains(classname, "rf2_object_crate") == 0)
			{
				objectCount++;
			}
		}
	}
	
	if (survivorCount == 0)
		return;
	
	int itemShare = objectCount / survivorCount;
	for (int i = 0; i < MAX_SURVIVORS; i++)
	{
		if (survivorCount == 1)
		{
			g_iItemLimit[i] = 99999;
			break;
		}
		else
		{
			g_iItemLimit[i] = itemShare;
		}	
	}
}

bool IsSurvivorIndexValid(int index)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		if (RF2_GetSurvivorIndex(i) == index)
			return true;
	}
	
	return false;
}

void UpdatePlayerXP(int client, float xpAmount=0.0)
{
	if (IsSingleplayer(false))
	{
		// XP is increased in singleplayer
		xpAmount *= 1.75;
	}
	
	g_flPlayerXP[client] += xpAmount;
	if (g_flPlayerXP[client] >= g_flPlayerNextLevelXP[client])
	{
		PlayerLevelUp(client);
		
		float xpRemaining = g_flPlayerXP[client] - g_flPlayerNextLevelXP[client];
		float oldNextXP = g_flPlayerNextLevelXP[client];
		g_flPlayerNextLevelXP[client] *= g_cvSurvivorXpRequirementScale.FloatValue;
		
		// If we can still level up, do this again
		if (xpRemaining >= g_flPlayerNextLevelXP[client])
		{
			g_flPlayerXP[client] -= oldNextXP;
			UpdatePlayerXP(client);
		}
		else
		{
			if (xpRemaining < 0.0)
				xpRemaining = FloatAbs(xpRemaining);
				
			g_flPlayerXP[client] = xpRemaining;
		}
	}
}

void PlayerLevelUp(int client)
{
	int oldLevel = g_iPlayerLevel[client];
	g_iPlayerLevel[client]++;
	
	CalculatePlayerMaxHealth(client);
	CalculatePlayerMiscStats(client);
	RF2_PrintToChat(client, "%t", "YouLevelUp", oldLevel, g_iPlayerLevel[client]);
}

bool IsPlayerSurvivor(int client)
{
	return (RF2_GetSurvivorIndex(client) > -1);
}

bool IsSingleplayer(bool fullCheck=true)
{
	return g_iSurvivorCount == 1 || fullCheck && GetTotalHumans(false) == 1;
}