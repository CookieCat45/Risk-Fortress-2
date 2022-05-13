#if defined _RF2_robots_included
 #endinput
#endif
#define _RF2_robots_included

float g_flCashValue[MAX_EDICTS];
int g_iRobotAmount; // This is the amount of bots currently loaded

// General robot data
char g_szLoadedRobots[MAX_ROBOT_TYPES][MAX_CONFIG_NAME_LENGTH];
char g_szAllLoadedRobots[MAX_ROBOT_TYPES * MAX_CONFIG_NAME_LENGTH] = "; "; // One string containing all the config names

char g_szRobotName[MAX_ROBOT_TYPES][64];
char g_szRobotDesc[MAX_ROBOT_TYPES][PLATFORM_MAX_PATH];
char g_szRobotModel[MAX_ROBOT_TYPES][PLATFORM_MAX_PATH];

int g_iRobotTfClass[MAX_ROBOT_TYPES];
int g_iRobotBaseHp[MAX_ROBOT_TYPES];
float g_flRobotBaseSpeed[MAX_ROBOT_TYPES];
float g_flRobotModelScale[MAX_ROBOT_TYPES];
bool g_bRobotIsGiant[MAX_ROBOT_TYPES];

float g_flRobotXPAward[MAX_ROBOT_TYPES];
float g_flRobotCashAward[MAX_ROBOT_TYPES];

// TFBot
int g_iTFBotDifficulty[MAX_ROBOT_TYPES];
float g_flTFBotMinReloadTime[MAX_ROBOT_TYPES];

// Robot weapon data
char g_szRobotWeaponName[MAX_ROBOT_TYPES][TF_WEAPON_SLOTS][128];
char g_szRobotWeaponAttributes[MAX_ROBOT_TYPES][TF_WEAPON_SLOTS][MAX_ATTRIBUTE_STRING_LENGTH];
int g_iRobotWeaponIndex[MAX_ROBOT_TYPES][TF_WEAPON_SLOTS];
bool g_bRobotWeaponVisible[MAX_ROBOT_TYPES][TF_WEAPON_SLOTS];
int g_iRobotWeaponAmount[MAX_ROBOT_TYPES];

// Wearables
char g_szRobotWearableName[MAX_ROBOT_TYPES][MAX_ROBOT_WEARABLES][128];
char g_szRobotWearableAttributes[MAX_ROBOT_TYPES][MAX_ROBOT_WEARABLES][MAX_ATTRIBUTE_STRING_LENGTH];
int g_iRobotWearableIndex[MAX_ROBOT_TYPES][MAX_ROBOT_WEARABLES];
bool g_bRobotWearableVisible[MAX_ROBOT_TYPES][MAX_ROBOT_WEARABLES];
int g_iRobotWearableAmount[MAX_ROBOT_TYPES];

void LoadRobots(char[] names)
{
	if (g_iRobotAmount >= MAX_ROBOT_TYPES)
	{
		char mapName[128];
		GetCurrentMap(mapName, sizeof(mapName));
		LogError("Max robot type limit of %i reached on map %s", MAX_ROBOT_TYPES, mapName);
		return;
	}
	
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, RobotConfig);
	if (!FileExists(config))
	{
		RF2_PrintToChatAll("Config file %s does not exist, please correct this", config);
		ThrowError("File %s does not exist", config);
	}
	
	int robotAmount;
	char sectionName[16];
	Handle robotKey = CreateKeyValues("robots");
	FileToKeyValues(robotKey, config);
	
	char robotArray[MAX_ROBOT_TYPES][MAX_CONFIG_NAME_LENGTH];
	char buffer[MAX_CONFIG_NAME_LENGTH];
	int count = ExplodeString(names, " ; ", robotArray, MAX_ROBOT_TYPES, MAX_CONFIG_NAME_LENGTH);
	
	for (int robot = g_iRobotAmount; robot < count+g_iRobotAmount; robot++)
	{
		if (!KvJumpToKey(robotKey, robotArray[robot]))
		{
			LogError("Couldn't find robot type \"%s\" in %s/%s!", robotArray[robot], ConfigPath, RobotConfig);
			continue;
		}
		
		KvGetSectionName(robotKey, g_szLoadedRobots[robot], MAX_CONFIG_NAME_LENGTH);
		
		// Already loaded? (Or possibly a duplicate name)
		if (StrContainsEx(g_szAllLoadedRobots, g_szLoadedRobots[robot]) != -1)
		{
			LogMessage("An attempt to load robot \"%s\" was made, but it is either already loaded or a duplicate config name.\nIf this robot is a minion, you can probably ignore this message.", g_szLoadedRobots[robot]);
			continue;
		}
		
		// name, model, description
		KvGetString(robotKey, "name", g_szRobotName[robot], PLATFORM_MAX_PATH, "Unnamed robot");
		KvGetString(robotKey, "desc", g_szRobotDesc[robot], PLATFORM_MAX_PATH, "(No description found...)");
		KvGetString(robotKey, "model", g_szRobotModel[robot], PLATFORM_MAX_PATH, "models/player/soldier.mdl");
		g_flRobotModelScale[robot] = KvGetFloat(robotKey, "model_scale", 1.0);
		g_bRobotIsGiant[robot] = view_as<bool>(KvGetNum(robotKey, "giant", 0));
		
		if (!FileExists(g_szRobotModel[robot], true))
		{
			PrintToChatAll("Model %s for robot \"%s\" could not be found!", g_szRobotModel[robot], g_szLoadedRobots[robot]);
			FormatEx(g_szRobotModel[robot], PLATFORM_MAX_PATH, "models/player/soldier.mdl");
		}
		PrecacheModel(g_szRobotModel[robot]);
		
		// TF class, health, and speed
		g_iRobotTfClass[robot] = KvGetNum(robotKey, "class", 1);
		g_iRobotBaseHp[robot] = KvGetNum(robotKey, "health", 150);
		g_flRobotBaseSpeed[robot] = KvGetFloat(robotKey, "speed", 300.0);
		
		g_iTFBotDifficulty[robot] = KvGetNum(robotKey, "tf_bot_difficulty", TFBotDifficulty_Hard);
		g_flTFBotMinReloadTime[robot] = KvGetFloat(robotKey, "tf_bot_min_reload_time", 0.75);
		
		// XP and cash awards on death
		g_flRobotXPAward[robot] = KvGetFloat(robotKey, "xp_award", 15.0);
		g_flRobotCashAward[robot] = KvGetFloat(robotKey, "cash_award", 20.0);
		
		g_iRobotWeaponAmount[robot] = 0;
		// weapons
		for (int wep = 0; wep < TF_WEAPON_SLOTS; wep++)
		{
			FormatEx(sectionName, sizeof(sectionName), "weapon%i", wep+1);
			if (!KvJumpToKey(robotKey, sectionName))
				break;
			
			KvGetString(robotKey, "classname", g_szRobotWeaponName[robot][wep], PLATFORM_MAX_PATH, "null");
			KvGetString(robotKey, "attributes", g_szRobotWeaponAttributes[robot][wep], MAX_ATTRIBUTE_STRING_LENGTH, "");
			g_iRobotWeaponIndex[robot][wep] = KvGetNum(robotKey, "index", 5);
			g_bRobotWeaponVisible[robot][wep] = view_as<bool>(KvGetNum(robotKey, "visible", 1));
			g_iRobotWeaponAmount[robot]++;
			
			KvGoBack(robotKey);
		}
		
		g_iRobotWearableAmount[robot] = 0;
		// wearables
		for (int wearable = 0; wearable < MAX_ROBOT_WEARABLES; wearable++)
		{
			FormatEx(sectionName, sizeof(sectionName), "wearable%i", wearable+1);
			if (!KvJumpToKey(robotKey, sectionName))
				continue;
			
			KvGetString(robotKey, "classname", g_szRobotWearableName[robot][wearable], PLATFORM_MAX_PATH, "tf_wearable");
			KvGetString(robotKey, "attributes", g_szRobotWearableAttributes[robot][wearable], MAX_ATTRIBUTE_STRING_LENGTH, "");
			g_iRobotWearableIndex[robot][wearable] = KvGetNum(robotKey, "index", 5000);
			g_bRobotWearableVisible[robot][wearable] = view_as<bool>(KvGetNum(robotKey, "visible", 1));
			g_iRobotWearableAmount[robot]++;
			
			KvGoBack(robotKey);
		}
		
		robotAmount++;
		if (robotAmount >= MAX_ROBOT_TYPES)
		{
			char mapName[128];
			GetCurrentMap(mapName, sizeof(mapName));
			LogError("Max robot type limit of %i reached on map %s", MAX_ROBOT_TYPES, mapName);
			break;
		}
		
		// Store the name in one giant string so we don't have to loop through all the names
		// to tell if this guy is already loaded.
		FormatEx(buffer, sizeof(buffer), "%s ; ", g_szLoadedRobots[robot]);
		ReplaceStringEx(g_szAllLoadedRobots, sizeof(g_szAllLoadedRobots), "; ", buffer);
		
		KvRewind(robotKey);
	}
	delete robotKey;
	g_iRobotAmount += robotAmount;
	
	char message[sizeof(g_szAllLoadedRobots)];
	FormatEx(message, sizeof(message), "%s", g_szAllLoadedRobots);
	ReplaceString(message, sizeof(message), " ; ", "");
	ReplaceString(message, sizeof(message), " ", "\n");
	
	PrintToServer("\n[RF2] Loaded robots:\n%s\n", message);
}

// Returns the index of a currently-loaded robot at random, optionally can retrieve the config name
int GetRandomRobot(bool getName = false, char[] name="", int size=0)
{
	int random = GetRandomInt(0, g_iRobotAmount-1);
	
	if (getName)
		FormatEx(name, size, "%s", g_szLoadedRobots[random]);
		
	return random;
}

void SpawnRobot(int client, int type, int spawnEntity=-1, bool force=false)
{
	if (IsPlayerAlive(client))
	{
		if (force)
		{
			ChangeClientTeam(client, 0);
		}
		else
		{
			return;
		}
	}
	
	ChangeClientTeam(client, TEAM_ROBOT);
	
	if (IsFakeClient(client))
		SetEntProp(client, Prop_Send, "m_nBotSkill", g_iTFBotDifficulty[type]);
	
	float pos[3];
	if (!IsValidEntity(spawnEntity))
	{
		int randomSurvivor = GetRandomPlayer(TEAM_SURVIVOR);
		if (IsValidClient(randomSurvivor))
		{
			GetClientAbsOrigin(randomSurvivor, pos);
		}
		else
		{
			pos[0] = GetRandomFloat(-3000.0, 3000.0);
			pos[1] = GetRandomFloat(-3000.0, 3000.0);
			pos[2] = GetRandomFloat(-1500.0, 1500.0);
		}
	}
	else
	{
		GetEntPropVector(spawnEntity, Prop_Data, "m_vecAbsOrigin", pos);
	}
	
	float mins[3] = PLAYER_MINS;
	float maxs[3] = PLAYER_MAXS;
	ScaleVector(mins, g_flRobotModelScale[type]);
	ScaleVector(maxs, g_flRobotModelScale[type]);
	float zOffset = 15.0 * g_flRobotModelScale[type];
	
	float spawnPos[3];
	CNavArea area = GetSpawnPointFromNav(pos, spawnPos, MIN_SPAWN_DIST, MAX_SPAWN_DIST, true, mins, maxs, MASK_PLAYERSOLID, zOffset);
	if (area == NULL_AREA)
	{
		char mapName[256];
		GetCurrentMap(mapName, sizeof(mapName));
		LogError("[NAV] NavArea was somehow NULL_AREA on map %s.", mapName);
		
		DataPack pack;
		CreateDataTimer(0.1, Timer_TrySpawnAgain, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(client);
		pack.WriteCell(type);
		pack.WriteCell(spawnEntity);
		pack.WriteCell(force);
		return;
	}
	
	g_iPlayerRobotType[client] = type;
	g_iPlayerBaseHealth[client] = g_iRobotBaseHp[type];
	g_flPlayerMaxSpeed[client] = g_flRobotBaseSpeed[type];
	
	if (g_bRobotIsGiant[type])
		g_bIsGiant[client] = true;
		
	TF2_RespawnPlayer(client);
	TeleportEntity(client, spawnPos, NULL_VECTOR, NULL_VECTOR);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_flRobotModelScale[type]);
	TF2_AddCondition(client, TFCond_UberchargedCanteen, 1.0);
	TF2_AddCondition(client, TFCond_SpawnOutline, 4.0);
	TF2_SetPlayerClass(client, view_as<TFClassType>(g_iRobotTfClass[type]));

	SetVariantString(g_szRobotModel[type]);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMinsPreScaled", mins);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxsPreScaled", maxs);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", mins);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", maxs);
	
	TF2_RemoveAllWearables(client);
	TF2_RemoveAllWeapons(client);
	for (int i = 0; i < g_iRobotWeaponAmount[type]; i++)
	{
		CreateWeapon(client, 
		g_szRobotWeaponName[type][i], 
		g_iRobotWeaponIndex[type][i], 
		g_szRobotWeaponAttributes[type][i], 
		g_bRobotWeaponVisible[type][i]);
	}
	
	for (int i = 0; i < g_iRobotWearableAmount[type]; i++)
	{
		CreateWearable(client, 
		g_szRobotWearableName[type][i], 
		g_iRobotWearableIndex[type][i], 
		g_szRobotWearableAttributes[type][i], 
		g_bRobotWearableVisible[type][i]);
	}
	
	g_iPlayerStatWearable[client] = CreateWearable(client, "tf_wearable", ATTRIBUTE_WEARABLE_INDEX, BASE_PLAYER_ATTRIBUTES, false);
}

public Action Timer_TrySpawnAgain(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	if (!IsClientInGame(client))
		return;
		
	int type = pack.ReadCell();
	int spawnEntity = pack.ReadCell();
	bool force = view_as<bool>(pack.ReadCell());
	
	SpawnRobot(client, type, spawnEntity, force);
}

public Action RoboSoundHook(int clients[MAXTF2PLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	if (!g_bPluginEnabled || g_bWaitingForPlayers)
		return Plugin_Continue;
	
	if (IsValidClient(entity) && GetClientTeam(entity) == TEAM_ROBOT)
	{
		TFClassType class = TF2_GetPlayerClass(entity);
		if (StrContains(sample, "vo/") != -1)
		{
			//bool TauntLine;
			//if (StrContains(sample, "taunts/") != -1)
			//	TauntLine = true;
			
			bool NoGiantLines; // Some classes don't have these.
			if (class == TFClass_Sniper || class == TFClass_Medic || class == TFClass_Engineer)
			{
				NoGiantLines = true;
				pitch = SNDPITCH_LOW; // We can lower the pitch of the sound instead.
			}

			//if (TauntLine)
			//	Format(sample, sizeof(sample), "%s%s", "taunts/", sample);
			
			char classString[16];
			char newString[32];
			GetClassString(class, classString, sizeof(classString), true);
			
			if (g_bIsGiant[entity] && !NoGiantLines)
			{
				ReplaceString(sample, sizeof(sample), "vo/", "vo/mvm/mght/");
				FormatEx(newString, sizeof(newString), "%smvm_m_", classString);
			}
			else
			{
				ReplaceString(sample, sizeof(sample), "vo/", "vo/mvm/norm/");
				FormatEx(newString, sizeof(newString), "%smvm_", classString);
			}
			
			ReplaceString(sample, sizeof(sample), classString, newString);
			PrecacheSound(sample);
			return Plugin_Changed;
		}
		else if (StrContains(sample, "player/footsteps/") != -1 && !TF2_IsPlayerInCondition(entity, TFCond_Disguised) && !g_bIsGiant[entity])
		{
			int random = GetRandomInt(1, 18);
			if (random > 9)
				FormatEx(sample, sizeof(sample), "mvm/player/footsteps/robostep_%i.wav", random);
			else
				FormatEx(sample, sizeof(sample), "mvm/player/footsteps/robostep_0%i.wav", random);
			
			PrecacheSound(sample);
			EmitSoundToAll(sample, entity, channel, level, flags, volume, pitch);
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

/*
*
*	Cash stuff
*
*/
void SpawnCashDrop(float cashValue, float pos[3], int size=1)
{
	char classname[128];
	switch (size)
	{
		case 1: classname = "item_currencypack_small";
		case 2: classname = "item_currencypack_medium";
		case 3: classname = "item_currencypack_large";
		default: classname = "item_currencypack_small";
	}
	
	int entity = CreateEntityByName(classname);
	g_flCashValue[entity] = cashValue;
	
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);
	CreateTimer(0.25, Timer_CashMagnet, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(CASH_BURN_TIME, Timer_DeleteEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CashMagnet(Handle timer, int entity)
{
	if (!IsValidEntity(entity))
		return Plugin_Stop;
	
	float origin[3];
	float scoutOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", origin);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		// Scouts pick up cash in a radius automatically, like in MvM, though he does not heal from it. (That may be put on an item later.)
		if (GetClientTeam(i) == TEAM_SURVIVOR && TF2_GetPlayerClass(i) == TFClass_Scout)
		{
			GetClientAbsOrigin(i, scoutOrigin);
			if (GetVectorDistance(origin, scoutOrigin, true) <= Pow(450.0, 2.0))
			{
				EmitSoundToAll(SOUND_MONEY_PICKUP, entity);
				PickupCash(i, entity);
			}
		}
	}
	return Plugin_Continue;
}

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

Action PickupCash(int client, int entity)
{
	// If client is 0 or below, the cash is most likely being collected automatically.
	if (client < 1 || GetClientTeam(client) == TEAM_SURVIVOR)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
				
			if (GetClientTeam(i) == TEAM_SURVIVOR)
				g_flPlayerCash[i] += g_flCashValue[entity];
		}
		
		if (client > 0)
		{
			SetVariantString("randomnum:25");
			AcceptEntityInput(client, "AddContext");
	
			SetVariantString("IsMvMDefender:1");
			AcceptEntityInput(client, "AddContext");
			
			SetVariantString("TLK_MVM_MONEY_PICKUP");
			AcceptEntityInput(client, "SpeakResponseConcept");
			AcceptEntityInput(client, "ClearContext");
		}
		
		if (IsValidEntity(entity))
			RemoveEntity(entity);
			
		return Plugin_Continue;
	}
	return Plugin_Handled;
}