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
char g_szLastInventoryOwner[MAX_SURVIVORS][MAX_NAME_LENGTH];

bool g_bSurvivorIndexUsed[MAX_SURVIVORS];
char g_szSurvivorIndexSteamID[MAX_SURVIVORS][32];

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
	int points[MAXTF2PLAYERS] = {-2140083648, ...};
	int actualPoints[MAXTF2PLAYERS];
	int humanCount;
	bool valid[MAXTF2PLAYERS];
	bool removePoints[MAXTF2PLAYERS] = {true, ...};
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
			
		if (IsFakeClient(i))
		{
			if (!g_cvBotsCanBeSurvivor.BoolValue)
			{
				ForcePlayerSuicide(i);
				FakeClientCommand(i, "explode");
				ChangeClientTeam(i, TEAM_ENEMY);
				continue;
			}
			else
			{
				SetEntProp(i, Prop_Send, "m_nBotSkill", TFBotDifficulty_Expert);
			}
		}
		
		points[i] = g_iPlayerSurvivorPoints[i];
		valid[i] = true;
		
		if (IsFakeClient(i))
		{
			points[i] -= 99999;
		}
		else if (!g_bPlayerBecomeSurvivor[i])
		{
			points[i] -= 9999999;
			removePoints[i] = false;
		}
		
		if (GetClientTeam(i) <= 1)
		{
			points[i] -= 9999;
		}
		
		actualPoints[i] = points[i];
		
		if (GetClientTeam(i) != TEAM_ENEMY)
		{
			if (IsPlayerAlive(i))
			{
				ForcePlayerSuicide(i);
				FakeClientCommand(i, "explode");
			}
			
			ChangeClientTeam(i, TEAM_ENEMY);
		}
	}
	
	SortIntegers(points, sizeof(points), Sort_Descending); // sort all the points so we can find out who has the highest
	int highestPoints = points[0];
	int survivorCount;
	bool selected[MAXTF2PLAYERS];
	
	// If the game has already started, prioritize an index that's already been used by a player previously so we can get that player's inventory.
	int prioritizedIndex = -1;
	bool indexTaken[MAX_SURVIVORS];
	int oldPrioritizedIndex;
	int maxSurvivors = g_cvMaxSurvivors.IntValue;
	
	if (g_bGameInitialized)
	{
		for (int i = 0; i < maxSurvivors; i++)
		{
			if (g_bSurvivorIndexUsed[i])
			{
				prioritizedIndex = i;
				break;
			}
		}
	}
	
	int attempts;
	int i = 1;
	char authId[64];
	int steamIDIndex = -1;

	while (attempts < 500 && survivorCount < maxSurvivors)
	{
		attempts++;
		
		if (!valid[i] || selected[i])
		{
			i++;
			
			if (i >= MAXTF2PLAYERS)
				i = 1;
			
			continue;
		}
		
		if (highestPoints == actualPoints[i]) // if client owns these points, they are a survivor since it's the highest
		{
			selected[i] = true;
			
			if (g_bGameInitialized && !IsFakeClient(i))
			{
				// check to see if we can get our own inventory back
				GetClientAuthId(i, AuthId_SteamID64, authId, sizeof(authId));
				for (int s = 0; s < maxSurvivors; s++)
				{
					if (indexTaken[s] || !g_szSurvivorIndexSteamID[s][0])
						continue;
					
					if (strcmp2(authId, g_szSurvivorIndexSteamID[s]))
					{
						steamIDIndex = s;
						break;
					}
				}
			}
			
			if (prioritizedIndex > -1 || steamIDIndex > -1)
			{
				g_iPlayerSurvivorIndex[i] = steamIDIndex > -1 ? steamIDIndex : prioritizedIndex;
				steamIDIndex = -1;
				indexTaken[g_iPlayerSurvivorIndex[i]] = true;
				
				if (g_iPlayerSurvivorIndex[i] == prioritizedIndex)
				{
					oldPrioritizedIndex = prioritizedIndex;
					
					for (int index = 0; index < maxSurvivors; index++)
					{
						if (indexTaken[index])
							continue;
						
						if (g_bSurvivorIndexUsed[index])
						{
							prioritizedIndex = index;
							break;
						}
					}
					
					if (prioritizedIndex == oldPrioritizedIndex) // no more used indexes were found, the rest are empty
					{
						prioritizedIndex = -1;
					}
				}
			}
			else
			{
				g_iPlayerSurvivorIndex[i] = survivorCount;
				indexTaken[survivorCount] = true;
			}
			
			if (!IsFakeClient(i))
				humanCount++;
			
			MakeSurvivor(i, g_iPlayerSurvivorIndex[i], removePoints[i]);
			g_bSurvivorIndexUsed[g_iPlayerSurvivorIndex[i]] = true;
			survivorCount++;
			highestPoints = points[survivorCount];
			i = 1;
		}
		
		i++;
	}
	
	g_iSurvivorCount = survivorCount;
	return survivorCount > 0;
}

void MakeSurvivor(int client, int index, bool resetPoints=true, bool loadInventory=true)
{
	if (resetPoints)
		g_iPlayerSurvivorPoints[client] = 0;
	
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
	
	// Player is probably still on the class select screen, so we need to kick them out by giving them a random class.
	if (TF2_GetPlayerClass(client) == TFClass_Unknown)
	{
		TF2_SetPlayerClass(client, view_as<TFClassType>(GetRandomInt(1, 9)));
	}
	
	// This is so weapons/wearables update properly on plugin reloads.
	TF2_RemoveAllWeapons(client);
	TF2_RemoveAllWearables(client);
	TF2_RespawnPlayer(client);
	TF2_AddCondition(client, TFCond_UberchargedCanteen, 5.0);
	SetEntProp(client, Prop_Send, "m_bGlowEnabled", true);
	
	if (!IsFakeClient(client))
	{
		GetClientAuthId(client, AuthId_SteamID64, g_szSurvivorIndexSteamID[index], sizeof(g_szSurvivorIndexSteamID[]));
	}
	
	if (loadInventory)
	{
		LoadSurvivorInventory(client, index);
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
	
	if (g_szLastInventoryOwner[index][0])
	{
		PrintCenterText(client, "%t", "GivenInventory", g_szLastInventoryOwner[index]);
	}
}

void SaveSurvivorInventory(int client, int index, bool saveName=true)
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
	
	if (saveName)
	{
		if (IsValidClient(client))
		{
			char clientName[128];
			GetClientName(client, clientName, sizeof(clientName));
			strcopy(g_szLastInventoryOwner[index], sizeof(g_szLastInventoryOwner[]), clientName);
		}
		else
		{
			strcopy(g_szLastInventoryOwner[index], sizeof(g_szLastInventoryOwner[]), "[unknown]");
		}
	}
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
		if (IsSurvivorIndexValid(i))
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
	return g_iSurvivorCount == 1 || fullCheck && GetTotalHumans() == 1;
}