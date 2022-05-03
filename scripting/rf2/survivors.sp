#if defined _RF2_survivors_included
 #endinput
#endif
#define _RF2_survivors_included

#pragma semicolon 1
#pragma newdecls required

int g_iSurvivorCount = 1; // number of survivors to spawn this round
int g_iSurvivorPoints[MAXTF2PLAYERS] = { 0, ... }; // survivor queue points
bool g_bSurvivorIndexUsed[MAX_SURVIVORS];

int g_iSurvivorBaseHealth[TF_CLASSES];
float g_flSurvivorMaxSpeed[TF_CLASSES];
//char g_szSurvivorAttributes[TF_CLASSES][MAX_ATTRIBUTE_STRING_LENGTH];

int g_iSavedItem[MAX_SURVIVORS][MAX_ITEMS];
int g_iSavedLevel[MAX_SURVIVORS] = {1, ...};
float g_flSavedXP[MAX_SURVIVORS];
float g_flSavedNextLevelXP[MAX_SURVIVORS] = {BASE_XP_REQUIREMENT, ...};

stock void LoadSurvivorStats()
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, SurvivorConfig);
	if (!FileExists(config))
	{
		RF2_PrintToChatAll("Config file %s does not exist, please correct this", config);
		ThrowError("File %s does not exist", config);
	}
	
	Handle survivorKey = CreateKeyValues("survivors");
	FileToKeyValues(survivorKey, config);
	char sectionName[32];
	TFClassType class;
	bool firstKey = true;
	
	for (int i = 0; i < TF_CLASSES; i++)
	{
		if (firstKey ? KvGotoFirstSubKey(survivorKey) : KvGotoNextKey(survivorKey))
		{
			KvGetSectionName(survivorKey, sectionName, sizeof(sectionName));
			if ((class = TF2_GetClass(sectionName)) != TFClass_Unknown)
			{
				g_iSurvivorBaseHealth[class] = KvGetNum(survivorKey, "health", 450);
				g_flSurvivorMaxSpeed[class] = KvGetFloat(survivorKey, "speed", 300.0);
				//KvGetString(survivorKey, "attributes", g_szSurvivorAttributes[class], MAX_ATTRIBUTE_STRING_LENGTH, "");
				
				firstKey = false;
			}
		}
	}
	delete survivorKey;
}

stock bool SetSurvivors()
{
	int points[MAXTF2PLAYERS] = {-1, ...};
	bool valid[MAXTF2PLAYERS];
	bool allowBots = GetConVarBool(g_cvBotsCanBeSurvivor);
		
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
			
		if (IsFakeClient(i))
		{
			if (!allowBots)
			{
				ChangeClientTeam(i, 0); // this changes their team without making a bunch of corpses
				ChangeClientTeam(i, TEAM_ROBOT);
				continue;
			}
			else
			{
				SetEntProp(i, Prop_Send, "m_nBotSkill", TFBotDifficulty_Expert);
			}
		}
		
		points[i] = g_iSurvivorPoints[i];
		valid[i] = true;
		
		if (GetClientTeam(i) != TEAM_ROBOT)
		{
			// setting team to 0 first moves them over to BLU team quietly
			ChangeClientTeam(i, 0);
			ChangeClientTeam(i, TEAM_ROBOT);
		}
	}
	
	SortIntegers(points, sizeof(points), Sort_Descending); // sort all the points so we can find out who has the highest
	int count;
	bool selected[MAXTF2PLAYERS];
	
	// If the game has already started, prioritize an index that's already been used by a player previously.
	int prioritizedIndex = -1;
	bool indexTaken[MAX_SURVIVORS];
	int oldIndex;
	
	if (g_bGameStarted)
	{
		for (int i = 0; i < MAX_SURVIVORS; i++)
		{
			if (g_bSurvivorIndexUsed[i])
			{
				prioritizedIndex = i;
				break;
			}
		}
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!valid[i] || selected[i])
			continue;
		
		if (count >= MAX_SURVIVORS) // we hit survivor cap, so break the loop
			break;
			
		if (points[count] == RF2_GetSurvivorPoints(i)) // if client owns these points, they are a survivor since it's the highest
		{
			selected[i] = true;
			
			if (prioritizedIndex > -1)
			{
				g_iPlayerSurvivorIndex[i] = prioritizedIndex;
				oldIndex = prioritizedIndex;
				indexTaken[prioritizedIndex] = true;
				
				for (int index = 0; index < MAX_SURVIVORS; index++)
				{
					if (indexTaken[index])
						continue;
					
					if (g_bSurvivorIndexUsed[index])
					{
						prioritizedIndex = index;
						break;
					}
				}
				
				if (prioritizedIndex == oldIndex) // no more used indexes were found, the rest are empty
				{
					prioritizedIndex = -1;
				}
			}
			else
			{
				g_iPlayerSurvivorIndex[i] = count;
				indexTaken[count] = true;
			}
			
			CreateSurvivor(i, g_iPlayerSurvivorIndex[i]);
			g_bSurvivorIndexUsed[g_iPlayerSurvivorIndex[i]] = true;
			
			count++;
			i = 0; // loop through players again
		}
	}
	g_iSurvivorCount = count;
	
	if (count > 0)
		return true;
	else
		return false;
}

stock void CreateSurvivor(int client, int index, bool resetPoints=true, bool respawn=true)
{
	if (resetPoints)
		g_iSurvivorPoints[client] = 0;
	
	TFClassType class = TF2_GetPlayerClass(client);
	g_iPlayerBaseHealth[client] = g_iSurvivorBaseHealth[class];
	g_flPlayerMaxSpeed[client] = g_flSurvivorMaxSpeed[class];
	
	ChangeClientTeam(client, TEAM_SURVIVOR);
	if (respawn)
	{
		TF2_RespawnPlayer(client);
		TF2_AddCondition(client, TFCond_UberchargedCanteen, 5.0);
	}
	
	if (!IsValidEntity(g_iPlayerStatWearable[client]))
	{
		g_iPlayerStatWearable[client] = CreateWearable(client, "tf_wearable", ATTRIBUTE_WEARABLE_INDEX, BASE_PLAYER_ATTRIBUTES, true);
	}
	
	LoadSurvivorInventory(client, index);
}

stock void LoadSurvivorInventory(int client, int index)
{
	for (int i = 0; i < MAX_ITEMS; i++)
	{
		g_iPlayerItem[client][i] = g_iSavedItem[index][i];
		if (g_iPlayerItem[client][i] > 0)
		{
			UpdatePlayerItem(client, i);
			EquipItemAsWearable(client, i);
		}
	}
	
	g_iPlayerLevel[client] = g_iSavedLevel[index];
	g_flPlayerXP[client] = g_flSavedXP[index];
	g_flPlayerNextLevelXP[client] = g_flSavedNextLevelXP[index];
}

stock void SaveSurvivorInventory(int client, int index)
{
	for (int i = 0; i < MAX_ITEMS; i++)
	{
		g_iSavedItem[index][i] = g_iPlayerItem[client][i];
	}
	
	g_iSavedLevel[index] = g_iPlayerLevel[client];
	g_flSavedXP[index] = g_flPlayerXP[client];
	g_flSavedNextLevelXP[index] = g_flPlayerNextLevelXP[client];
	
	if (IsValidClient(client))
		PrintToServer("[RF2] Saved Survivor inventory of client %i, index %i", client, index);
}

stock bool IsSurvivorIndexValid(int index)
{
	for (int i = 1; i < MAXTF2PLAYERS; i++)
	{
		if (g_iPlayerSurvivorIndex[i] == index)
			return true;
	}
	return false;
}

stock void UpdatePlayerXP(int client, float xpAmount=0.0)
{
	g_flPlayerXP[client] += xpAmount;
		
	if (g_flPlayerXP[client] >= g_flPlayerNextLevelXP[client])
	{
		UpdatePlayerLevel(client);
		
		float xpRemaining = g_flPlayerXP[client] - g_flPlayerNextLevelXP[client];
		float oldNextXP = g_flPlayerNextLevelXP[client];
		g_flPlayerNextLevelXP[client] *= XP_REQUIREMENT_SCALE;
		
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

stock void UpdatePlayerLevel(int client)
{
	int oldLevel = g_iPlayerLevel[client];
	g_iPlayerLevel[client]++;
	CalculatePlayerMaxHealth(client, true);
	RF2_PrintToChat(client, "Your Level: {lime}%i -> %i", oldLevel, g_iPlayerLevel[client]);
	
	//int maxHealth = CalculatePlayerMaxHealth(client, true);
	//float value = IntToFloat(maxHealth);
	//int health = GetEntProp(client, Prop_Data, "m_iHealth");
	//SetEntityHealth(client, health + maxHealth / 4);
}