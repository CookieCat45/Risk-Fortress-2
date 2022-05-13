#if defined _RF2_bosses_included
 #endinput
#endif
#define _RF2_bosses_included

int g_iBossAmount; // This is the amount of bosses currently loaded

// General boss data
char g_szLoadedBosses[MAX_BOSS_TYPES][MAX_CONFIG_NAME_LENGTH];
char g_szAllLoadedBosses[MAX_BOSS_TYPES * MAX_CONFIG_NAME_LENGTH] = "; "; // One string containing all the config names

char g_szBossName[MAX_BOSS_TYPES][64];
char g_szBossDesc[MAX_BOSS_TYPES][PLATFORM_MAX_PATH];
char g_szBossModel[MAX_BOSS_TYPES][PLATFORM_MAX_PATH];

int g_iBossTfClass[MAX_BOSS_TYPES];
int g_iBossBaseHp[MAX_BOSS_TYPES];
float g_flBossBaseSpeed[MAX_BOSS_TYPES];
float g_flBossModelScale[MAX_BOSS_TYPES];
bool g_bBossIsGiant[MAX_BOSS_TYPES];

int g_iBossBotDifficulty[MAX_BOSS_TYPES];

float g_flBossXPAward[MAX_BOSS_TYPES];
float g_flBossCashAward[MAX_BOSS_TYPES];

char g_szBossConditions[MAX_BOSS_TYPES][256];

// Weapons
char g_szBossWeaponName[MAX_BOSS_TYPES][TF_WEAPON_SLOTS][128];
char g_szBossWeaponAttributes[MAX_BOSS_TYPES][TF_WEAPON_SLOTS][MAX_ATTRIBUTE_STRING_LENGTH];
int g_iBossWeaponIndex[MAX_BOSS_TYPES][TF_WEAPON_SLOTS];
bool g_bBossWeaponVisible[MAX_BOSS_TYPES][TF_WEAPON_SLOTS];
int g_iBossWeaponAmount[MAX_BOSS_TYPES];

// Wearables
char g_szBossWearableName[MAX_BOSS_TYPES][MAX_BOSS_WEARABLES][128];
char g_szBossWearableAttributes[MAX_BOSS_TYPES][MAX_BOSS_WEARABLES][MAX_ATTRIBUTE_STRING_LENGTH];
int g_iBossWearableIndex[MAX_BOSS_TYPES][MAX_BOSS_WEARABLES];
bool g_bBossWearableVisible[MAX_BOSS_TYPES][MAX_BOSS_WEARABLES];
int g_iBossWearableAmount[MAX_BOSS_TYPES];

// Minions (TODO)
char g_szBossMinions[MAX_BOSS_TYPES][PLATFORM_MAX_PATH];
float g_flBossMinionSpawnInterval[MAX_BOSS_TYPES];
bool g_bBossMinionInstantSpawn[MAX_BOSS_TYPES] = {true, ...};
int g_iBossMinionSpawnCount[MAX_BOSS_TYPES];

void LoadBosses(char[] names)
{
	if (g_iBossAmount >= MAX_BOSS_TYPES)
	{
		char mapName[128];
		GetCurrentMap(mapName, sizeof(mapName));
		LogError("Max boss limit of %i reached on map %s", MAX_BOSS_TYPES, mapName);
		return;
	}
	
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, BossConfig);
	if (!FileExists(config))
	{
		RF2_PrintToChatAll("Config file %s does not exist, please correct this", config);
		ThrowError("File %s does not exist", config);
	}
	
	int bossAmount;
	char sectionName[16];
	Handle bossKey = CreateKeyValues("bosses");
	FileToKeyValues(bossKey, config);
	
	char bossArray[MAX_BOSS_TYPES][MAX_CONFIG_NAME_LENGTH];
	char buffer[MAX_CONFIG_NAME_LENGTH];
	int count = ExplodeString(names, " ; ", bossArray, MAX_BOSS_TYPES, MAX_CONFIG_NAME_LENGTH);
	
	for (int boss = g_iBossAmount; boss < count+g_iBossAmount; boss++)
	{
		if (!KvJumpToKey(bossKey, bossArray[boss]))
		{
			LogError("Couldn't find boss \"%s\" in %s/%s!", bossArray[boss], ConfigPath, BossConfig);
			continue;
		}
		
		KvGetSectionName(bossKey, g_szLoadedBosses[boss], MAX_CONFIG_NAME_LENGTH);
		
		// Already loaded? (Or possibly a duplicate name)
		if (StrContainsEx(g_szAllLoadedBosses, g_szLoadedBosses[boss]) != -1)
		{
			LogMessage("An attempt to load boss \"%s\" was made, but it is either already loaded or a duplicate config name.", g_szLoadedBosses[boss]);
			continue;
		}
		
		// name, model, description
		KvGetString(bossKey, "name", g_szBossName[boss], PLATFORM_MAX_PATH, "Unnamed boss");
		KvGetString(bossKey, "desc", g_szBossDesc[boss], PLATFORM_MAX_PATH, "(No description found...)");
		KvGetString(bossKey, "model", g_szBossModel[boss], PLATFORM_MAX_PATH, "models/player/soldier.mdl");
		g_flBossModelScale[boss] = KvGetFloat(bossKey, "model_scale", 1.75);
		g_bBossIsGiant[boss] = view_as<bool>(KvGetNum(bossKey, "giant", 1));
		
		if (!FileExists(g_szBossModel[boss], true))
		{
			LogError("Model %s for boss \"%s\" could not be found!", g_szBossModel[boss], g_szLoadedBosses[boss]);
			FormatEx(g_szBossModel[boss], PLATFORM_MAX_PATH, "models/player/soldier.mdl");
		}
		PrecacheModel(g_szBossModel[boss]);
		
		// TF class, health, and speed
		g_iBossTfClass[boss] = KvGetNum(bossKey, "class", 6);
		g_iBossBaseHp[boss] = KvGetNum(bossKey, "health", 2000);
		g_flBossBaseSpeed[boss] = KvGetFloat(bossKey, "speed", 230.0);
		
		g_iBossBotDifficulty[boss] = KvGetNum(bossKey, "tf_bot_difficulty", TFBotDifficulty_Expert);
		
		// boss minions
		KvGetString(bossKey, "minions", g_szBossMinions[boss], PLATFORM_MAX_PATH, "");
		g_flBossMinionSpawnInterval[boss] = KvGetFloat(bossKey, "minion_spawn_interval", 40.0);
		g_bBossMinionInstantSpawn[boss] = view_as<bool>(KvGetNum(bossKey, "minion_instant_spawn", 1));
		g_iBossMinionSpawnCount[boss] = KvGetNum(bossKey, "minion_spawn_count", 3);
		
		if (g_szBossMinions[boss][0] != '\0')
			LoadRobots(g_szBossMinions[boss]);
		
		// XP and cash awards on death
		g_flBossXPAward[boss] = KvGetFloat(bossKey, "xp_award", 300.0);
		g_flBossCashAward[boss] = KvGetFloat(bossKey, "cash_award", 500.0);
		KvGetString(bossKey, "spawn_conditions", g_szBossConditions[boss], 256, "");
		
		g_iBossWeaponAmount[boss] = 0;
		// weapons
		for (int wep = 0; wep < TF_WEAPON_SLOTS; wep++)
		{
			FormatEx(sectionName, sizeof(sectionName), "weapon%i", wep);
			if (!KvJumpToKey(bossKey, sectionName))
				break;
			
			KvGetString(bossKey, "classname", g_szBossWeaponName[boss][wep], PLATFORM_MAX_PATH, "null");
			KvGetString(bossKey, "attributes", g_szBossWeaponAttributes[boss][wep], MAX_ATTRIBUTE_STRING_LENGTH, "");
			g_iBossWeaponIndex[boss][wep] = KvGetNum(bossKey, "index", 5);
			g_bBossWeaponVisible[boss][wep] = view_as<bool>(KvGetNum(bossKey, "visible", 1));
			g_iBossWeaponAmount[boss]++;
			
			KvGoBack(bossKey);
		}
		
		g_iBossWearableAmount[boss] = 0;
		// wearables
		for (int wearable = 0; wearable < MAX_BOSS_WEARABLES; wearable++)
		{
			FormatEx(sectionName, sizeof(sectionName), "wearable%i", wearable+1);
			if (!KvJumpToKey(bossKey, sectionName))
				break;
			
			KvGetString(bossKey, "classname", g_szBossWearableName[boss][wearable], PLATFORM_MAX_PATH, "tf_wearable");
			KvGetString(bossKey, "attributes", g_szBossWearableAttributes[boss][wearable], MAX_ATTRIBUTE_STRING_LENGTH, "");
			g_iBossWearableIndex[boss][wearable] = KvGetNum(bossKey, "index", 5000);
			g_bBossWearableVisible[boss][wearable] = view_as<bool>(KvGetNum(bossKey, "visible", 1));
			g_iBossWearableAmount[boss]++;
			
			KvGoBack(bossKey);
		}
		
		bossAmount++;
		if (bossAmount >= MAX_BOSS_TYPES)
		{
			char mapName[128];
			GetCurrentMap(mapName, sizeof(mapName));
			LogError("Max boss limit of %i reached on map %s", MAX_BOSS_TYPES, mapName);
			break;
		}
		
		// Store the name in one giant string so we don't have to loop through all the names
		// to tell if this guy is already loaded.
		FormatEx(buffer, sizeof(buffer), "%s ; ", g_szLoadedBosses[boss]);
		ReplaceStringEx(g_szAllLoadedBosses, sizeof(g_szAllLoadedBosses), "; ", buffer);
		KvGoBack(bossKey);
	}
	delete bossKey;
	g_iBossAmount += bossAmount;
	
	char message[sizeof(g_szAllLoadedBosses)];
	FormatEx(message, sizeof(message), "%s", g_szAllLoadedBosses);
	ReplaceString(message, sizeof(message), " ; ", "");
	ReplaceString(message, sizeof(message), " ", "\n");
	
	PrintToServer("[RF2] Loaded bosses:\n%s\n", message);
}

int GetRandomBoss(bool getName = false, char[] name="", int size=0)
{
	int random = GetRandomInt(0, g_iBossAmount-1);
	
	if (getName)
		FormatEx(name, size, "%s", g_szLoadedBosses[random]);
		
	return random;
}

void SummonTeleporterBosses(int entity)
{
	// First, we need to find the best candidates for bosses.
	int playerPoints[MAXTF2PLAYERS];
	int bossPoints[MAXTF2PLAYERS];
	bool valid[MAXTF2PLAYERS];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_ROBOT)
		{
			bossPoints[i] = -9999999999;
			continue;
		}
		
		valid[i] = true;
		if (!IsPlayerAlive(i)) // Dead robots have the biggest priority, obviously.
			bossPoints[i] += 9999;	
		
		/*We'll do a coin flip to determine whether this player's points factor in to their priority.
		The coin flip is so if you do well, you have a higher chance of becoming the boss, but not always -
		to give other players a chance even if they aren't scoring as high as their peers.*/
			
		if (!IsFakeClient(i))
		{
			bossPoints[i] += 250; // Players are prioritized over TFBots, so have a free 250 points.
			if (GetRandomInt(1, 2) == 1)
				bossPoints[i] += GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iScore", _, i);
		}
		
		// Non-bosses and non-giants are obviously prioritized as well.
		if (!g_bIsBoss[i])
			bossPoints[i] += 2000;
				
		if (!g_bIsGiant[i])
			bossPoints[i] += 500;
			
		if (g_bIsAFK[i])
			bossPoints[i] -= 5000;
			
		playerPoints[i] = bossPoints[i];
	}
		
	SortIntegers(bossPoints, sizeof(bossPoints), Sort_Descending);
	int highestPoints = bossPoints[0];
	int count;
	int bossCount = 1 + (GetPlayersOnTeam(TEAM_SURVIVOR, true)-1) + (g_iSubDifficulty-1 / 2);
	if (bossCount < 1)
		bossCount = 1;
	
	float time;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!valid[i] || g_bIsTeleporterBoss[i])
			continue;
		
		if (playerPoints[i] == highestPoints)
		{
			// don't spawn all the bosses at once, as it will cause client crashes if there are too many
			DataPack pack;
			CreateDataTimer(time, Timer_SpawnTeleporterBoss, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(i);
			pack.WriteCell(GetRandomBoss());
			pack.WriteCell(entity);
			time += 0.5;
			valid[i] = false;
			
			count++;
			if (count >= bossCount)
				break;
				
			highestPoints = bossPoints[count];
			i = 0; // reset our loop
		}
	}
	
	EmitSoundToAll(SOUND_BOSS_SPAWN);
}

public Action Timer_SpawnTeleporterBoss(Handle time, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int type = pack.ReadCell();
	int spawnEntity = pack.ReadCell();
	
	g_bIsTeleporterBoss[client] = true;
	SpawnBoss(client, type, spawnEntity, true);
}

void SpawnBoss(int client, int type, int spawnEntity=-1, bool force=true)
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
		SetEntProp(client, Prop_Send, "m_nBotSkill", g_iBossBotDifficulty[type]);
	
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
	
	ScaleVector(mins, g_flBossModelScale[type]);
	ScaleVector(maxs, g_flBossModelScale[type]);
	float zOffset = 15.0 * g_flBossModelScale[type];
	
	float spawnPos[3];
	CNavArea area = GetSpawnPointFromNav(pos, spawnPos, MIN_SPAWN_DIST, MAX_SPAWN_DIST, true, mins, maxs, MASK_PLAYERSOLID, zOffset);
	if (!area)
	{
		char mapName[256];
		GetCurrentMap(mapName, sizeof(mapName));
		LogError("[NAV] NavArea was somehow NULL on map \"%s\".", mapName);
		
		DataPack pack = CreateDataPack();
		pack.WriteCell(client);
		pack.WriteCell(type);
		pack.WriteCell(spawnEntity);
		pack.WriteCell(force);
		RequestFrame(RF_TrySpawnAgainBoss, pack); // try again on every frame instead of on a timer, as boss spawns are much more important
		
		return;
	}
	
	g_iPlayerBossType[client] = type;
	g_iPlayerBaseHealth[client] = g_iBossBaseHp[type];
	g_flPlayerMaxSpeed[client] = g_flBossBaseSpeed[type];
	
	if (g_bBossIsGiant[type])
		g_bIsGiant[client] = true;
		
	TF2_RespawnPlayer(client);
	TeleportEntity(client, spawnPos, NULL_VECTOR, NULL_VECTOR);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_flBossModelScale[type]);
	TF2_AddCondition(client, TFCond_UberchargedCanteen, 1.0);
	TF2_AddCondition(client, TFCond_SpawnOutline, 4.0);
	TF2_SetPlayerClass(client, view_as<TFClassType>(g_iBossTfClass[type]));

	SetVariantString(g_szBossModel[type]);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMinsPreScaled", mins);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxsPreScaled", maxs);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", mins);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", maxs);
	
	SetEntProp(client, Prop_Data, "m_bloodColor", -1);
	
	TF2_RemoveAllWearables(client);
	TF2_RemoveAllWeapons(client);
	for (int i = 0; i < g_iBossWeaponAmount[type]; i++)
	{
		CreateWeapon(client, 
		g_szBossWeaponName[type][i], 
		g_iBossWeaponIndex[type][i], 
		g_szBossWeaponAttributes[type][i], 
		g_bBossWeaponVisible[type][i]);
	}
	
	for (int i = 0; i < g_iBossWearableAmount[type]; i++)
	{
		CreateWearable(client, 
		g_szBossWearableName[type][i], 
		g_iBossWearableIndex[type][i], 
		g_szBossWearableAttributes[type][i], 
		g_bBossWearableVisible[type][i]);
	}
	
	if (g_szBossConditions[type][0] != '\0')
	{
		char buffer[256];
		FormatEx(buffer, sizeof(buffer), g_szBossConditions[type]);
		
		ReplaceString(buffer, MAX_ATTRIBUTE_STRING_LENGTH, " ; ", "=");
		char buffers[16][32];
		int count = ExplodeString(buffer, "=", buffers, 16, 32);
		
		int cond;
		float duration;
		for (int i = 0; i < count; i+=2)
		{
			cond = StringToInt(buffers[i]);
			duration = StringToFloat(buffers[i+1]);
			
			TF2_AddCondition(client, view_as<TFCond>(cond), duration);
		}
	}
	
	g_bIsBoss[client] = true;
	
	if (!g_bIsTeleporterBoss[client])
	{
		EmitSoundToAll(SOUND_BOSS_SPAWN);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
	}
	g_iPlayerStatWearable[client] = CreateWearable(client, "tf_wearable", ATTRIBUTE_WEARABLE_INDEX, BASE_PLAYER_ATTRIBUTES, false);
}

public void RF_TrySpawnAgainBoss(DataPack pack)
{
	pack.Reset();
	
	int client = pack.ReadCell();
	if (!IsClientInGame(client))
		return;
	
	int type = pack.ReadCell();
	int spawnEntity = pack.ReadCell();
	bool force = view_as<bool>(pack.ReadCell());
	
	delete pack;
	SpawnBoss(client, type, spawnEntity, force);
}