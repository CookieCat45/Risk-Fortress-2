#if defined _RF2_survivors_included
 #endinput
#endif
#define _RF2_survivors_included

#pragma semicolon 1
#pragma newdecls required

int g_iSurvivorCount = 1; // number of survivors to spawn this round
int g_iSurvivorPoints[MAXTF2PLAYERS] = { 0, ... }; // survivor queue points

int g_iSurvivorBaseHealth[TF_CLASSES];
float g_flSurvivorMaxSpeed[TF_CLASSES];
//char g_szSurvivorAttributes[TF_CLASSES][MAX_ATTRIBUTE_STRING_LENGTH];

int g_iSavedItem[MAX_SURVIVORS][MAX_ITEMS];
int g_iSavedLevel[MAX_SURVIVORS] = {1, ...};
float g_flSavedXP[MAX_SURVIVORS];
float g_flSavedNextLevelXP[MAX_SURVIVORS] = {60.0, ...};

stock void LoadSurvivorStats()
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, SurvivorConfig);
	if (!FileExists(config))
	{
		ThrowError("File %s does not exist", config);
		RF2_PrintToChatAll("Config file %s does not exist, please correct this", config);
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

/*
stock void SetSurvivorAttributes(int client, TFClassType class)
{
	if (g_szSurvivorAttributes[class][0] != '\0')
	{
		ReplaceString(g_szSurvivorAttributes[class], MAX_ATTRIBUTE_STRING_LENGTH, " ; ", "=");
		char attrs[32][32];
		int count = ExplodeString(g_szSurvivorAttributes[class], "=", attrs, 32, 32);
		
		int attSlot = 0;
		int attrib;
		float val;
		for (int n = 0; n < count; n+=2)
		{
			attrib = StringToInt(attrs[n]);
			val = StringToFloat(attrs[n+1]);
			if (attrib <= 0)
				continue;
			
			TF2Attrib_SetByDefIndex(client, attrib, val);
			attSlot++;
		}
	}
}
*/

stock bool SetSurvivors()
{
	int players;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
			players++;
	}
	
	int count;
	int points[MAXTF2PLAYERS] = {-1, ...};
	bool selected[MAXTF2PLAYERS];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;
			
		if (IsFakeClient(i))
		{
			if (!GetConVarBool(cv_BotsCanBeSurvivor))
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
		
		points[i] = RF2_GetSurvivorPoints(i);
			
		if (GetClientTeam(i) != TEAM_ROBOT)
		{
			ChangeClientTeam(i, 0);
			ChangeClientTeam(i, TEAM_ROBOT);
		}
	}
	SortIntegers(points, sizeof(points), Sort_Descending); // sort all the points so we can find out who has the highest
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;
		
		if (count >= MAX_SURVIVORS) // we hit survivor cap, so break the loop
			break;
			
		if (!selected[i] && points[count] == RF2_GetSurvivorPoints(i)) // if client owns these points, they are a survivor since it's the highest
		{
			selected[i] = true;
			g_iPlayerSurvivorIndex[i] = count;
			SpawnSurvivor(i, g_iPlayerSurvivorIndex[i]);
			
			count++;
			i = 1; // loop through players again
		}
	}
	g_iSurvivorCount = count;
	
	if (count > 0)
		return true;
	else
		return false;
}

stock void SpawnSurvivor(int client, int index)
{
	g_iSurvivorPoints[client] = 0; // reset q points
	
	TFClassType class = TF2_GetPlayerClass(client);
	g_iPlayerBaseHealth[client] = g_iSurvivorBaseHealth[class];
	g_flPlayerMaxSpeed[client] = g_flSurvivorMaxSpeed[class];
	
	ChangeClientTeam(client, TEAM_SURVIVOR);
	TF2_RespawnPlayer(client);
	
	g_iPlayerStatWearable[client] = CreateWearable(client, "tf_wearable", ATTRIBUTE_WEARABLE_INDEX, BASE_PLAYER_ATTRIBUTES, true);
	LoadSurvivorInventory(client, index);
	//CalculatePlayerMaxHealth(client, true, true);
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
}

stock void UpdatePlayerXP(int client, float xpAmount=0.0)
{
	g_flPlayerXP[client] += xpAmount;
		
	if (g_flPlayerXP[client] >= g_flPlayerNextLevelXP[client])
	{
		UpdatePlayerLevel(client);
		
		float xpRemaining = g_flPlayerXP[client] - g_flPlayerNextLevelXP[client];
		float oldNextXP = g_flPlayerNextLevelXP[client];
		g_flPlayerNextLevelXP[client] *= 1.4;
		
		// If we can still level up, do this again
		if (xpRemaining >= g_flPlayerNextLevelXP[client])
		{
			g_flPlayerXP[client] -= oldNextXP;
			UpdatePlayerXP(client);
		}
		else
		{
			if (xpRemaining < 0.0)
				xpRemaining *= -1.0;
				
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