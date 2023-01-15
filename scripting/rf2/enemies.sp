#if defined _RF2_enemies_included
 #endinput
#endif
#define _RF2_enemies_included

#pragma semicolon 1
#pragma newdecls required

float g_flCashValue[MAX_EDICTS];
int g_iEnemyCount; // This is the amount of bots currently loaded

// General enemy data
char g_szLoadedEnemies[MAX_ENEMIES][MAX_CONFIG_NAME_LENGTH];

char g_szEnemyName[MAX_ENEMIES][PLATFORM_MAX_PATH];
char g_szEnemyDesc[MAX_ENEMIES][PLATFORM_MAX_PATH];
char g_szEnemyModel[MAX_ENEMIES][PLATFORM_MAX_PATH];

int g_iEnemyTfClass[MAX_ENEMIES];
int g_iEnemyBaseHp[MAX_ENEMIES];
float g_flEnemyBaseSpeed[MAX_ENEMIES];
float g_flEnemyModelScale[MAX_ENEMIES];

float g_flEnemyXPAward[MAX_ENEMIES];
float g_flEnemyCashAward[MAX_ENEMIES];

int g_iEnemyWeight[MAX_ENEMIES];
int g_iEnemyItem[MAX_ENEMIES][MAX_ITEMS];

bool g_bEnemyFullRage[MAX_ENEMIES];

// TFBot
int g_iEnemyBotDifficulty[MAX_ENEMIES];
float g_flEnemyBotMinReloadTime[MAX_ENEMIES];
bool g_bEnemyBotAggressive[MAX_ENEMIES];
bool g_bEnemyBotRocketJump[MAX_ENEMIES];

// Enemy weapon data
bool g_bEnemyWeaponVisible[MAX_ENEMIES][TF_WEAPON_SLOTS];
char g_szEnemyWeaponName[MAX_ENEMIES][TF_WEAPON_SLOTS][128];
char g_szEnemyWeaponAttributes[MAX_ENEMIES][TF_WEAPON_SLOTS][MAX_ATTRIBUTE_STRING_LENGTH];
int g_iEnemyWeaponIndex[MAX_ENEMIES][TF_WEAPON_SLOTS];
bool g_bEnemyWeaponUseStaticAttributes[MAX_ENEMIES][TF_WEAPON_SLOTS];
int g_iEnemyWeaponAmount[MAX_ENEMIES];

// Wearables
char g_szEnemyWearableName[MAX_ENEMIES][MAX_WEARABLES][128];
char g_szEnemyWearableAttributes[MAX_ENEMIES][MAX_WEARABLES][MAX_ATTRIBUTE_STRING_LENGTH];
int g_iEnemyWearableIndex[MAX_ENEMIES][MAX_WEARABLES];
bool g_bEnemyWearableVisible[MAX_ENEMIES][MAX_WEARABLES];
int g_iEnemyWearableAmount[MAX_ENEMIES];

// Sound/voice
int g_iEnemyVoiceType[MAX_ENEMIES] = {VoiceType_Robot, ...};
int g_iEnemyVoicePitch[MAX_ENEMIES] = {SNDPITCH_NORMAL, ...};
int g_iEnemyFootstepType[MAX_ENEMIES] = {FootstepType_Robot, ...};

void LoadEnemiesFromPack(const char[] config)
{
	if (g_iEnemyCount >= MAX_ENEMIES)
	{
		LogError("[LoadEnemiesFromPack] Max enemy type limit of %i reached!", MAX_ENEMIES);
		return;
	}
	
	char path[PLATFORM_MAX_PATH], sectionName[16];
	bool firstKey;
	
	BuildPath(Path_SM, path, sizeof(path), "%s/%s.cfg", ConfigPath, config);
	
	if (!FileExists(path))
	{
		LogError("[LoadEnemiesFromPack] Config file %s does not exist, please correct this!", path);
		return;
	}
	
	KeyValues enemyKey = CreateKeyValues("enemies");
	enemyKey.ImportFromFile(path);
	
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
		
		g_iEnemyBotDifficulty[enemy] = enemyKey.GetNum("tf_bot_difficulty", TFBotDifficulty_Hard);
		g_flEnemyBotMinReloadTime[enemy] = enemyKey.GetFloat("tf_bot_min_reload_time", 0.75);
		g_bEnemyBotAggressive[enemy] = bool(enemyKey.GetNum("tf_bot_aggressive", false));
		g_bEnemyBotRocketJump[enemy] = bool(enemyKey.GetNum("tf_bot_rocketjump", false));
		
		// XP and cash awards on death
		g_flEnemyXPAward[enemy] = enemyKey.GetFloat("xp_award", 15.0);
		g_flEnemyCashAward[enemy] = enemyKey.GetFloat("cash_award", 20.0);
		
		g_iEnemyWeight[enemy] = enemyKey.GetNum("weight", 50);
		if (g_iEnemyWeight[enemy] < 0)
			g_iEnemyWeight[enemy] = 1;
		else if (g_iEnemyWeight[enemy] > 100)
			g_iEnemyWeight[enemy] = 100;
		
		g_bEnemyFullRage[enemy] = bool(enemyKey.GetNum("full_rage", false));
		
		g_iEnemyWeaponAmount[enemy] = 0;
		// weapons
		for (int wep = 0; wep < TF_WEAPON_SLOTS; wep++)
		{
			FormatEx(sectionName, sizeof(sectionName), "weapon%i", wep+1);
			if (!enemyKey.JumpToKey(sectionName))
				break;
			
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
						g_iEnemyItem[enemy][itemId] = enemyKey.GetNum(NULL_STRING);
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
		strcopy(buffer, size, g_szLoadedEnemies[selected]);
	
	delete enemyList;
	return selected;
}

void SpawnEnemy(int client, int type, int spawnEntity=-1, bool force=false)
{
	if (IsPlayerAlive(client))
	{
		if (force)
		{
			SilentlyKillPlayer(client);
		}
		else
		{
			return;
		}
	}
	
	ChangeClientTeam(client, TEAM_ENEMY);
	
	if (IsFakeClientEx(client))
	{
		switch (RF2_GetDifficulty())
		{
			case DIFFICULTY_STEEL:
			{
				if (g_iEnemyBotDifficulty[type] < TFBotDifficulty_Hard && g_iEnemyBotDifficulty[type] != TFBotDifficulty_Expert)
				{
					SetEntProp(client, Prop_Send, "m_nBotSkill", TFBotDifficulty_Hard);
				}
				else
				{
					SetEntProp(client, Prop_Send, "m_nBotSkill", g_iEnemyBotDifficulty[type]);
				}
			}
			case DIFFICULTY_TITANIUM:
			{
				SetEntProp(client, Prop_Send, "m_nBotSkill", TFBotDifficulty_Expert);
			}
			
			default:
			{
				SetEntProp(client, Prop_Send, "m_nBotSkill", g_iEnemyBotDifficulty[type]);
			}
		}
		
		g_TFBot[client].MinReloadTime = g_flEnemyBotMinReloadTime[type];
		
		if (g_bEnemyBotAggressive[type])
		{
			g_TFBot[client].AddFlag(TFBOTFLAG_AGGRESSIVE);
		}
		
		if (g_bEnemyBotRocketJump[type])
		{
			g_TFBot[client].AddFlag(TFBOTFLAG_ROCKETJUMP);
		}
	}
	
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
	ScaleVector(mins, g_flEnemyModelScale[type]);
	ScaleVector(maxs, g_flEnemyModelScale[type]);
	float zOffset = 15.0 * g_flEnemyModelScale[type];
	
	float spawnPos[3];
	float minSpawnDistance = g_cvEnemyMinSpawnDistance.FloatValue;
	float maxSpawnDistance = g_cvEnemyMaxSpawnDistance.FloatValue;
	CNavArea area = GetSpawnPointFromNav(pos, spawnPos, minSpawnDistance, maxSpawnDistance, TEAM_SURVIVOR, true, mins, maxs, MASK_PLAYERSOLID, zOffset);
	if (area == NULL_AREA)
	{
		DataPack pack;
		CreateDataTimer(0.1, Timer_TrySpawnAgain, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(GetClientUserId(client));
		pack.WriteCell(type);
		pack.WriteCell(spawnEntity);
		pack.WriteCell(force);
		return;
	}
	
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
	CalculatePlayerKnockbackResist(client);
}

public Action Timer_TrySpawnAgain(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if (client == 0)
		return Plugin_Continue;
		
	int type = pack.ReadCell();
	int spawnEntity = pack.ReadCell();
	bool force = view_as<bool>(pack.ReadCell());
	
	SpawnEnemy(client, type, spawnEntity, force);
	return Plugin_Continue;
}

/**
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
	CreateTimer(g_cvCashBurnTime.FloatValue, Timer_DeleteCash, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DeleteCash(Handle timer, int entity)
{
	if (EntRefToEntIndex(entity) == INVALID_ENT_REFERENCE)
		return Plugin_Continue;
		
	float pos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
	TE_SetupParticle("mvm_cash_explosion", pos);
	RemoveEntity(entity);
	
	return Plugin_Continue;
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
		if (!IsClientInGameEx(i) || !IsPlayerAlive(i))
			continue;
		
		// Scouts pick up cash in a radius automatically, like in MvM. Though the healing is on an item: the Heart Of Gold.
		if (GetClientTeam(i) == TEAM_SURVIVOR && TF2_GetPlayerClass(i) == TFClass_Scout)
		{
			GetClientAbsOrigin(i, scoutOrigin);
			if (GetVectorDistance(origin, scoutOrigin, true) <= sq(450.0))
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
	if (other > 0 && other <= MaxClients)
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
		float modifier = 1.0;
		int clients[MAXTF2PLAYERS];
		int clientCount;
		
		// Check for Proof of Purchase item first to make sure everyone gets the bonus.
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGameEx(i) || !IsPlayerSurvivor(i))
				continue;
				
			clients[clientCount] = i;
			clientCount++;			
				
			if (PlayerHasItem(i, Item_ProofOfPurchase))
			{
				modifier += CalcItemMod(i, Item_ProofOfPurchase, 0);
			}
		}
		
		for (int i = 0; i < clientCount; i++)
		{
			g_flPlayerCash[clients[i]] += g_flCashValue[entity] * modifier;
		}
		
		if (client > 0)
		{
			if (PlayerHasItem(client, Item_HeartOfGold))
			{
				int heal = RoundToFloor(CalcItemMod(client, Item_HeartOfGold, 0));
				HealPlayer(client, heal, GetItemModBool(Item_HeartOfGold, 1));
			}
			
			if (GetRandomInt(1, 20) == 1)
			{
				SetVariantString("randomnum:100");
				AcceptEntityInput(client, "AddContext");
				
				SetVariantString("IsMvMDefender:1");
				AcceptEntityInput(client, "AddContext");
				
				SetVariantString("TLK_MVM_MONEY_PICKUP");
				AcceptEntityInput(client, "SpeakResponseConcept");
				AcceptEntityInput(client, "ClearContext");
			}
		}
		
		if (IsValidEntity(entity))
			RemoveEntity(entity);
			
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

int GetEnemyType(int client)
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