#if defined _RF2_enemies_included
 #endinput
#endif
#define _RF2_enemies_included

#pragma semicolon 1
#pragma newdecls required

int g_iEnemyCount;
char g_szLoadedEnemies[MAX_ENEMIES][64];

// General enemy data
int g_iEnemyTfClass[MAX_ENEMIES];
int g_iEnemyBaseHp[MAX_ENEMIES];
int g_iEnemyWeight[MAX_ENEMIES];
int g_iEnemyItem[MAX_ENEMIES][MAX_ITEMS];

float g_flEnemyBaseSpeed[MAX_ENEMIES];
float g_flEnemyModelScale[MAX_ENEMIES];
float g_flEnemyXPAward[MAX_ENEMIES];
float g_flEnemyCashAward[MAX_ENEMIES];

bool g_bEnemyFullRage[MAX_ENEMIES];
bool g_bEnemyNoBleeding[MAX_ENEMIES];

char g_szEnemyName[MAX_ENEMIES][PLATFORM_MAX_PATH];
char g_szEnemyDesc[MAX_ENEMIES][PLATFORM_MAX_PATH];
char g_szEnemyModel[MAX_ENEMIES][PLATFORM_MAX_PATH];

// TFBot
int g_iEnemyBotSkill[MAX_ENEMIES];
bool g_bEnemyBotAggressive[MAX_ENEMIES];
bool g_bEnemyBotRocketJump[MAX_ENEMIES];

// Weapons
bool g_bEnemyWeaponUseStaticAttributes[MAX_ENEMIES][TF_WEAPON_SLOTS];
bool g_bEnemyWeaponVisible[MAX_ENEMIES][TF_WEAPON_SLOTS];
int g_iEnemyWeaponIndex[MAX_ENEMIES][TF_WEAPON_SLOTS];
int g_iEnemyWeaponAmount[MAX_ENEMIES];
char g_szEnemyWeaponName[MAX_ENEMIES][TF_WEAPON_SLOTS][128];
char g_szEnemyWeaponAttributes[MAX_ENEMIES][TF_WEAPON_SLOTS][MAX_ATTRIBUTE_STRING_LENGTH];

// Wearables
int g_iEnemyWearableAmount[MAX_ENEMIES];
int g_iEnemyWearableIndex[MAX_ENEMIES][MAX_WEARABLES];
bool g_bEnemyWearableStaticAttributes[MAX_ENEMIES][MAX_WEARABLES];
bool g_bEnemyWearableVisible[MAX_ENEMIES][MAX_WEARABLES];
char g_szEnemyWearableName[MAX_ENEMIES][MAX_WEARABLES][128];
char g_szEnemyWearableAttributes[MAX_ENEMIES][MAX_WEARABLES][MAX_ATTRIBUTE_STRING_LENGTH];

// Sound/voice
int g_iEnemyVoiceType[MAX_ENEMIES] = {VoiceType_Robot, ...};
int g_iEnemyVoicePitch[MAX_ENEMIES] = {SNDPITCH_NORMAL, ...};
int g_iEnemyFootstepType[MAX_ENEMIES] = {FootstepType_Robot, ...};

void LoadEnemiesFromPack(const char[] config)
{
	KeyValues enemyKey = CreateKeyValues("enemies");
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "%s/%s.cfg", ConfigPath, config);
	if (!enemyKey.ImportFromFile(path))
	{
		ThrowError("File %s does not exist", path);
	}
	
	g_iEnemyCount = 0;
	bool firstKey;
	char sectionName[16];
	
	for (int enemy = g_iEnemyCount; enemy <= g_iEnemyCount; enemy++)
	{
		if (!firstKey)
		{
			enemyKey.GotoFirstSubKey();
			firstKey = true;
		}
		else if (!enemyKey.GotoNextKey())
		{
			break;
		}
		
		enemyKey.GetSectionName(g_szLoadedEnemies[enemy], sizeof(g_szLoadedEnemies[]));
		
		// name, model, description
		enemyKey.GetString("name", g_szEnemyName[enemy], sizeof(g_szEnemyName[]), "Unnamed enemy");
		enemyKey.GetString("desc", g_szEnemyDesc[enemy], sizeof(g_szEnemyDesc[]), "(No description found...)");
		enemyKey.GetString("model", g_szEnemyModel[enemy], sizeof(g_szEnemyModel[]), "models/player/soldier.mdl");
		g_flEnemyModelScale[enemy] = enemyKey.GetFloat("model_scale", 1.0);
		
		if (FileExists(g_szEnemyModel[enemy]))
		{
			PrecacheModel(g_szEnemyModel[enemy]);
			AddModelToDownloadsTable(g_szEnemyModel[enemy]);
		}
		else
		{
			LogError("[LoadEnemiesFromPack] Model %s for enemy \"%s\" could not be found!", g_szEnemyModel[enemy], g_szLoadedEnemies[enemy]);
			g_szEnemyModel[enemy] = MODEL_ERROR;
		}
		
		// TF class, health, and speed
		g_iEnemyTfClass[enemy] = enemyKey.GetNum("class", 1);
		g_iEnemyBaseHp[enemy] = enemyKey.GetNum("health", 150);
		g_flEnemyBaseSpeed[enemy] = enemyKey.GetFloat("speed", 300.0);
		
		g_iEnemyBotSkill[enemy] = enemyKey.GetNum("tf_bot_difficulty", TFBotDifficulty_Normal);
		g_bEnemyBotAggressive[enemy] = bool(enemyKey.GetNum("tf_bot_aggressive", false));
		g_bEnemyBotRocketJump[enemy] = bool(enemyKey.GetNum("tf_bot_rocketjump", false));
		
		// XP and cash awards on death
		g_flEnemyXPAward[enemy] = enemyKey.GetFloat("xp_award", 15.0);
		g_flEnemyCashAward[enemy] = enemyKey.GetFloat("cash_award", 20.0);
		g_iEnemyWeight[enemy] = enemyKey.GetNum("weight", 50);
		if (g_iEnemyWeight[enemy] < 0)
		{
			g_iEnemyWeight[enemy] = 1;
		}
		else if (g_iEnemyWeight[enemy] > 100)
		{
			g_iEnemyWeight[enemy] = 100;
		}
		
		g_bEnemyFullRage[enemy] = bool(enemyKey.GetNum("full_rage", false));
		g_bEnemyNoBleeding[enemy] = bool(enemyKey.GetNum("no_bleeding", true));
		
		g_iEnemyWeaponAmount[enemy] = 0;
		// weapons
		for (int wep = 0; wep < TF_WEAPON_SLOTS; wep++)
		{
			FormatEx(sectionName, sizeof(sectionName), "weapon%i", wep+1);
			if (!enemyKey.JumpToKey(sectionName))
			{
				break;
			}
			
			enemyKey.GetString("classname", g_szEnemyWeaponName[enemy][wep], sizeof(g_szEnemyWeaponName[][]), "null");
			enemyKey.GetString("attributes", g_szEnemyWeaponAttributes[enemy][wep], sizeof(g_szEnemyWeaponAttributes[][]), "");
			g_iEnemyWeaponIndex[enemy][wep] = enemyKey.GetNum("index", 5);
			g_bEnemyWeaponVisible[enemy][wep] = bool(enemyKey.GetNum("visible", true));
			g_bEnemyWeaponUseStaticAttributes[enemy][wep] = bool(enemyKey.GetNum("static_attributes", false));
			g_iEnemyWeaponAmount[enemy]++;
			
			enemyKey.GoBack();
		}
		
		g_iEnemyWearableAmount[enemy] = 0;
		// wearables
		for (int wearable = 0; wearable < MAX_WEARABLES; wearable++)
		{
			FormatEx(sectionName, sizeof(sectionName), "wearable%i", wearable+1);
			if (!enemyKey.JumpToKey(sectionName))
				continue;

			enemyKey.GetString("classname", g_szEnemyWearableName[enemy][wearable], sizeof(g_szEnemyWearableName[][]), "tf_wearable");
			enemyKey.GetString("attributes", g_szEnemyWearableAttributes[enemy][wearable], sizeof(g_szEnemyWearableAttributes[][]), "");
			g_iEnemyWearableIndex[enemy][wearable] = enemyKey.GetNum("index", 5000);
			g_bEnemyWearableStaticAttributes[enemy][wearable] = bool(enemyKey.GetNum("static_attributes", false));
			g_bEnemyWearableVisible[enemy][wearable] = bool(enemyKey.GetNum("visible", true));
			g_iEnemyWearableAmount[enemy]++;
			
			enemyKey.GoBack();
		}
		
		int itemId;
		if (enemyKey.JumpToKey("items"))
		{
			for (int item = 1; item < Item_MaxValid; item++)
			{
				if (item == 1 && enemyKey.GotoFirstSubKey(false) || enemyKey.GotoNextKey(false))
				{
					enemyKey.GetSectionName(sectionName, sizeof(sectionName));
					
					if ((itemId = StringToInt(sectionName)) > Item_Null)
					{
						g_iEnemyItem[enemy][itemId] = enemyKey.GetNum(NULL_STRING);
					}
				}
			}
			
			enemyKey.GoBack();
			enemyKey.GoBack();
		}
		
		g_iEnemyVoiceType[enemy] = enemyKey.GetNum("voice_type", VoiceType_Robot);
		g_iEnemyVoicePitch[enemy] = enemyKey.GetNum("voice_pitch", SNDPITCH_NORMAL);
		g_iEnemyFootstepType[enemy] = enemyKey.GetNum("footstep_type", FootstepType_Robot);

		g_iEnemyCount++;
		if (g_iEnemyCount >= MAX_ENEMIES)
		{
			LogError("[LoadEnemiesFromPack] Max enemy type limit of %i reached!", MAX_ENEMIES);
			break;
		}
	}
	
	delete enemyKey;
	PrintToServer("[RF2] Enemies loaded: %i", g_iEnemyCount);
}

// Returns the index of a currently-loaded enemy at random based on weight.
// Optionally can retrieve the config name.
int GetRandomEnemy(bool getName=false, char[] buffer="", int size=0)
{
	ArrayList enemyList = CreateArray();
	int selected;
	
	for (int i = 0; i < g_iEnemyCount; i++)
	{
		if (g_iEnemyWeight[i] <= 0)
			continue;
		
		for (int j = 1; j <= g_iEnemyWeight[i]; j++)
			enemyList.Push(i);
	}
	
	selected = enemyList.Get(GetRandomInt(0, enemyList.Length-1));
	
	if (getName)
	{
		strcopy(buffer, size, g_szLoadedEnemies[selected]);
	}
	
	delete enemyList;
	return selected;
}

void SpawnEnemy(int client, int type, const float pos[3]=OFF_THE_MAP, float minDist=-1.0, float maxDist=-1.0)
{
	g_bPlayerInSpawnQueue[client] = true;
	
	if (IsPlayerAlive(client))
	{
		SilentlyKillPlayer(client);
	}
	
	ChangeClientTeam(client, TEAM_ENEMY);
	
	if (IsFakeClient(client))
	{
		switch (RF2_GetDifficulty())
		{
			case DIFFICULTY_STEEL:
			{
				if (g_iEnemyBotSkill[type] < TFBotDifficulty_Hard && g_iEnemyBotSkill[type] != TFBotDifficulty_Expert)
				{
					g_TFBot[client].SetSkillLevel(TFBotDifficulty_Hard);
				}
				else
				{
					g_TFBot[client].SetSkillLevel(g_iEnemyBotSkill[type]);
				}
			}
			
			case DIFFICULTY_TITANIUM: g_TFBot[client].SetSkillLevel(TFBotDifficulty_Expert);
			
			default: g_TFBot[client].SetSkillLevel(g_iEnemyBotSkill[type]);
		}
		
		if (g_bEnemyBotAggressive[type])
		{
			g_TFBot[client].AddFlag(TFBOTFLAG_AGGRESSIVE);
		}
		
		if (g_bEnemyBotRocketJump[type])
		{
			g_TFBot[client].AddFlag(TFBOTFLAG_ROCKETJUMP);
		}
	}
	
	float checkPos[3];
	if (CompareVectors(pos, OFF_THE_MAP))
	{
		int randomSurvivor = GetRandomPlayer(TEAM_SURVIVOR);
		if (IsValidClient(randomSurvivor))
		{
			GetEntPos(randomSurvivor, checkPos);
		}
		else
		{
			checkPos[0] = GetRandomFloat(-3000.0, 3000.0);
			checkPos[1] = GetRandomFloat(-3000.0, 3000.0);
			checkPos[2] = GetRandomFloat(-1500.0, 1500.0);
		}
	}
	else
	{
		CopyVectors(pos, checkPos);
	}

	float mins[3] = PLAYER_MINS;
	float maxs[3] = PLAYER_MAXS;
	ScaleVector(mins, g_flEnemyModelScale[type]);
	ScaleVector(maxs, g_flEnemyModelScale[type]);
	float zOffset = 25.0 * g_flEnemyModelScale[type];
	
	float spawnPos[3];
	float minSpawnDistance = minDist < 0.0 ? g_cvEnemyMinSpawnDistance.FloatValue : minDist;
	float maxSpawnDistance = maxDist < 0.0 ? g_cvEnemyMaxSpawnDistance.FloatValue : maxDist;
	CNavArea area = GetSpawnPoint(checkPos, spawnPos, minSpawnDistance, maxSpawnDistance, TEAM_SURVIVOR, true, mins, maxs, MASK_PLAYERSOLID, zOffset);
	
	if (!area)
	{
		// try again next frame
		DataPack pack = CreateDataPack();
		pack.WriteCell(client);
		pack.WriteCell(type);
		pack.WriteFloat(pos[0]);
		pack.WriteFloat(pos[1]);
		pack.WriteFloat(pos[2]);
		pack.WriteFloat(minDist);
		pack.WriteFloat(maxDist);
		
		RequestFrame(RF_SpawnEnemyRecursive, pack);
		return;
	}
	
	g_bPlayerInSpawnQueue[client] = false;
	
	g_iPlayerEnemyType[client] = type;
	g_iPlayerBaseHealth[client] = g_iEnemyBaseHp[type];
	g_flPlayerMaxSpeed[client] = g_flEnemyBaseSpeed[type];
	
	TF2_SetPlayerClass(client, view_as<TFClassType>(g_iEnemyTfClass[type]));
	TF2_RespawnPlayer(client);
	TeleportEntity(client, spawnPos, NULL_VECTOR, NULL_VECTOR);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_flEnemyModelScale[type]);
	TF2_AddCondition(client, TFCond_UberchargedCanteen, 1.0);
	
	SetVariantString(g_szEnemyModel[type]);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
	
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMinsPreScaled", mins);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxsPreScaled", maxs);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", mins);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", maxs);
	
	TF2_RemoveAllWeapons(client);
	for (int i = 0; i < g_iEnemyWeaponAmount[type]; i++)
	{
		CreateWeapon(client, 
		g_szEnemyWeaponName[type][i], 
		g_iEnemyWeaponIndex[type][i], 
		g_szEnemyWeaponAttributes[type][i],
		g_bEnemyWeaponUseStaticAttributes[type][i],
		g_bEnemyWeaponVisible[type][i]);
	}
	
	for (int i = 1; i < Item_MaxValid; i++)
	{
		if (g_iEnemyItem[type][i] > 0)
		{
			GiveItem(client, i, g_iEnemyItem[type][i]);
		}
	}
	
	int wearable;
	for (int i = 0; i < g_iEnemyWearableAmount[type]; i++)
	{
		wearable = CreateWearable(client, 
		g_szEnemyWearableName[type][i], 
		g_iEnemyWearableIndex[type][i], 
		g_szEnemyWearableAttributes[type][i], 
		g_bEnemyWearableStaticAttributes[type][i],
		g_bEnemyWearableVisible[type][i]);
		
		g_bDontRemoveWearable[wearable] = true;
	}
	
	if (g_bEnemyFullRage[type])
	{
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
	}
	
	g_iPlayerVoiceType[client] = g_iEnemyVoiceType[type];
	g_iPlayerVoicePitch[client] = g_iEnemyVoicePitch[type];
	g_iPlayerFootstepType[client] = g_iEnemyFootstepType[type];
}

public void RF_SpawnEnemyRecursive(DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	if (!IsValidClient(client))
	{
		delete pack;
		return;
	}
	
	int type = pack.ReadCell();
	
	float pos[3];
	pos[0] = pack.ReadFloat();
	pos[1] = pack.ReadFloat();
	pos[2] = pack.ReadFloat();
	
	float minDist = pack.ReadFloat();
	float maxDist = pack.ReadFloat();
	
	delete pack;
	SpawnEnemy(client, type, pos, minDist, maxDist);
}

int GetPlayerEnemyType(int client)
{
	return g_iPlayerEnemyType[client];
}

int GetEnemyCount()
{
	return g_iEnemyCount;
}

int GetEnemyName(int type, char[] buffer, int size)
{
	return strcopy(buffer, size, g_szEnemyName[type]);
}

float GetEnemyHealthMult()
{
	return 1.0 + float(RF2_GetEnemyLevel()-1) * g_cvEnemyHealthScale.FloatValue;
}

float GetEnemyDamageMult()
{
	return 1.0 + float(RF2_GetEnemyLevel()-1) * g_cvEnemyDamageScale.FloatValue;
}