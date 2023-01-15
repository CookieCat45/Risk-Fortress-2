#if defined _RF2_bosses_included
 #endinput
#endif
#define _RF2_bosses_included

#pragma semicolon 1
#pragma newdecls required

#define TF_TEAM_PVE_INVADERS_GIANTS 4

int g_iBossCount; // This is the amount of bosses currently loaded

// General boss data
char g_szLoadedBosses[MAX_BOSSES][MAX_CONFIG_NAME_LENGTH];

char g_szBossName[MAX_BOSSES][PLATFORM_MAX_PATH];
char g_szBossDesc[MAX_BOSSES][PLATFORM_MAX_PATH];
char g_szBossModel[MAX_BOSSES][PLATFORM_MAX_PATH];

int g_iBossTfClass[MAX_BOSSES];
int g_iBossBaseHp[MAX_BOSSES];
float g_flBossBaseSpeed[MAX_BOSSES];
float g_flBossModelScale[MAX_BOSSES];
bool g_bBossIsGiant[MAX_BOSSES];
bool g_bBossAllowSelfDamage[MAX_BOSSES];

float g_flBossHeadScale[MAX_BOSSES] = {1.5, ...};
float g_flBossTorsoScale[MAX_BOSSES] = {1.0, ...};
float g_flBossHandScale[MAX_BOSSES] = {1.0, ...};

int g_iBossBotDifficulty[MAX_BOSSES];
float g_flBossBotMinReloadTime[MAX_BOSSES];
bool g_bBossBotAggressive[MAX_BOSSES];

float g_flBossXPAward[MAX_BOSSES];
float g_flBossCashAward[MAX_BOSSES];

char g_szBossConditions[MAX_BOSSES][256];

int g_iBossItem[MAX_BOSSES][MAX_ITEMS];

bool g_bBossFullRage[MAX_BOSSES];

// Weapons
char g_szBossWeaponName[MAX_BOSSES][TF_WEAPON_SLOTS][128];
char g_szBossWeaponAttributes[MAX_BOSSES][TF_WEAPON_SLOTS][MAX_ATTRIBUTE_STRING_LENGTH];
int g_iBossWeaponIndex[MAX_BOSSES][TF_WEAPON_SLOTS];
bool g_bBossWeaponUseStaticAttributes[MAX_BOSSES][TF_WEAPON_SLOTS];
bool g_bBossWeaponVisible[MAX_BOSSES][TF_WEAPON_SLOTS];
int g_iBossWeaponAmount[MAX_BOSSES];

// Wearables
char g_szBossWearableName[MAX_BOSSES][MAX_WEARABLES][128];
char g_szBossWearableAttributes[MAX_BOSSES][MAX_WEARABLES][MAX_ATTRIBUTE_STRING_LENGTH];
int g_iBossWearableIndex[MAX_BOSSES][MAX_WEARABLES];
bool g_bBossWearableVisible[MAX_BOSSES][MAX_WEARABLES];
int g_iBossWearableAmount[MAX_BOSSES];

// Minions (TODO)
char g_szBossMinions[MAX_BOSSES][PLATFORM_MAX_PATH];
float g_flBossMinionSpawnInterval[MAX_BOSSES];
bool g_bBossMinionInstantSpawn[MAX_BOSSES] = {true, ...};
int g_iBossMinionSpawnCount[MAX_BOSSES];

// Sound/voice
bool g_bBossGiantWeaponSounds[MAX_BOSSES] = {true, ...};
bool g_bBossVoiceNoPainSounds[MAX_BOSSES] = {true, ...};
int g_iBossVoiceType[MAX_BOSSES] = {VoiceType_Robot, ...};
int g_iBossVoicePitch[MAX_BOSSES] = {SNDPITCH_NORMAL, ...};
int g_iBossFootstepType[MAX_BOSSES] = {FootstepType_GiantRobot, ...};
float g_flBossFootstepInterval[MAX_BOSSES] = {0.5, ...};

void LoadBossesFromPack(const char[] config)
{
	if (g_iBossCount >= MAX_BOSSES)
	{
		LogError("[LoadBossesFromPack] Max boss limit of %i reached!", MAX_BOSSES);
		return;
	}
	
	char path[PLATFORM_MAX_PATH], sectionName[16];
	BuildPath(Path_SM, path, sizeof(path), "%s/%s.cfg", ConfigPath, config);
	
	if (!FileExists(path))
	{
		LogError("[LoadBossesFromPack] Config file %s does not exist, please correct this!", path);
		return;
	}
	
	KeyValues bossKey = CreateKeyValues("bosses");
	bossKey.ImportFromFile(path);
	
	bool firstKey;
	
	for (int boss = g_iBossCount; boss <= g_iBossCount; boss++)
	{
		if (!firstKey)
		{
			bossKey.GotoFirstSubKey();
			firstKey = true;
		}
		else if (!bossKey.GotoNextKey())
		{
			break;
		}
		
		bossKey.GetSectionName(g_szLoadedBosses[boss], sizeof(g_szLoadedBosses[]));
		
		// name, model, description
		bossKey.GetString("name", g_szBossName[boss], sizeof(g_szBossName[]), "Unnamed boss");
		bossKey.GetString("desc", g_szBossDesc[boss], sizeof(g_szBossDesc[]), "(No description found...)");
		bossKey.GetString("model", g_szBossModel[boss], sizeof(g_szBossModel[]), "models/player/soldier.mdl");
		g_flBossModelScale[boss] = bossKey.GetFloat("model_scale", 1.75);
		g_bBossIsGiant[boss] = bool(bossKey.GetNum("giant", true));
		g_bBossAllowSelfDamage[boss] = bool(bossKey.GetNum("allow_self_damage", false));
		
		g_flBossHeadScale[boss] = bossKey.GetFloat("head_scale", 1.5);
		g_flBossTorsoScale[boss] = bossKey.GetFloat("torso_scale", 1.0);
		g_flBossHandScale[boss] = bossKey.GetFloat("hand_scale", 1.0);
		
		if (FileExists(g_szBossModel[boss]))
		{
			PrecacheModel(g_szBossModel[boss]);
			AddModelToDownloadsTable(g_szBossModel[boss]);
		}
		else
		{
			LogError("[LoadBossesFromPack] Model %s for boss \"%s\" could not be found!", g_szBossModel[boss], g_szLoadedBosses[boss]);
			strcopy(g_szBossModel[boss], sizeof(g_szBossModel[]), MODEL_ERROR);
		}
		
		// TF class, health, and speed
		g_iBossTfClass[boss] = bossKey.GetNum("class", 3);
		g_iBossBaseHp[boss] = bossKey.GetNum("health", 3000);
		g_flBossBaseSpeed[boss] = bossKey.GetFloat("speed", 120.0);
		
		g_iBossBotDifficulty[boss] = bossKey.GetNum("tf_bot_difficulty", TFBotDifficulty_Expert);
		g_flBossBotMinReloadTime[boss] = bossKey.GetFloat("tf_bot_min_reload_time", 1.5);
		g_bBossBotAggressive[boss] = bool(bossKey.GetNum("tf_bot_aggressive", false));
		
		// boss minions (TODO)
		bossKey.GetString("minions", g_szBossMinions[boss], sizeof(g_szBossMinions[]), "");
		g_flBossMinionSpawnInterval[boss] = bossKey.GetFloat("minion_spawn_interval", 40.0);
		g_bBossMinionInstantSpawn[boss] = bool(bossKey.GetNum("minion_instant_spawn", true));
		g_iBossMinionSpawnCount[boss] = bossKey.GetNum("minion_spawn_count", 3);
		
		//if (g_szBossMinions[boss][0])
		//	LoadEnemies(g_szBossMinions[boss]);
		
		// XP and cash awards on death
		g_flBossXPAward[boss] = bossKey.GetFloat("xp_award", 300.0);
		g_flBossCashAward[boss] = bossKey.GetFloat("cash_award", 500.0);
		bossKey.GetString("spawn_conditions", g_szBossConditions[boss], sizeof(g_szBossConditions[]), "");
		
		g_bBossFullRage[boss] = bool(bossKey.GetNum("full_rage", false));
		
		g_iBossWeaponAmount[boss] = 0;
		// weapons
		for (int wep = 0; wep < TF_WEAPON_SLOTS; wep++)
		{
			FormatEx(sectionName, sizeof(sectionName), "weapon%i", wep+1);
			if (!bossKey.JumpToKey(sectionName))
				break;
			
			bossKey.GetString("classname", g_szBossWeaponName[boss][wep], sizeof(g_szBossWeaponName[][]), "null");
			bossKey.GetString("attributes", g_szBossWeaponAttributes[boss][wep], sizeof(g_szBossWeaponAttributes[][]), "");
			g_iBossWeaponIndex[boss][wep] = bossKey.GetNum("index", 5);
			g_bBossWeaponVisible[boss][wep] = bool(bossKey.GetNum("visible", true));
			g_bBossWeaponUseStaticAttributes[boss][wep] = bool(bossKey.GetNum("static_attributes", false));
			g_iBossWeaponAmount[boss]++;
			
			bossKey.GoBack();
		}
		
		g_iBossWearableAmount[boss] = 0;
		// wearables
		for (int wearable = 0; wearable < MAX_WEARABLES; wearable++)
		{
			FormatEx(sectionName, sizeof(sectionName), "wearable%i", wearable+1);
			if (!bossKey.JumpToKey(sectionName))
				break;
			
			bossKey.GetString("classname", g_szBossWearableName[boss][wearable], sizeof(g_szBossWearableName[][]), "tf_wearable");
			bossKey.GetString("attributes", g_szBossWearableAttributes[boss][wearable], sizeof(g_szBossWearableAttributes[][]), "");
			g_iBossWearableIndex[boss][wearable] = bossKey.GetNum("index", 5000);
			g_bBossWearableVisible[boss][wearable] = bool(bossKey.GetNum("visible", true));
			g_iBossWearableAmount[boss]++;
			
			bossKey.GoBack();
		}
		
		int itemId;
		if (bossKey.JumpToKey("items"))
		{
			for (int item = 1; item < Item_MaxValid; item++)
			{
				if (item == 1 && bossKey.GotoFirstSubKey(false) || bossKey.GotoNextKey(false))
				{
					bossKey.GetSectionName(sectionName, sizeof(sectionName));
					if ((itemId = StringToInt(sectionName)) > Item_Null)
					{
						g_iBossItem[boss][itemId] = bossKey.GetNum(NULL_STRING);
					}
				}
			}
			
			bossKey.GoBack();
			bossKey.GoBack();
		}
		
		// Sound/voice keyvalues
		g_bBossGiantWeaponSounds[boss] = bool(bossKey.GetNum("use_giant_weapon_sounds", true));
		g_iBossVoiceType[boss] = bossKey.GetNum("voice_type", VoiceType_Robot);
		g_iBossVoicePitch[boss] = bossKey.GetNum("voice_pitch", SNDPITCH_NORMAL);
		g_bBossVoiceNoPainSounds[boss] = bool(bossKey.GetNum("voice_no_pain", true));
		g_iBossFootstepType[boss] = bossKey.GetNum("footstep_type", FootstepType_GiantRobot);
		g_flBossFootstepInterval[boss] = bossKey.GetFloat("giant_footstep_interval", g_iBossTfClass[boss] == view_as<int>(TFClass_Scout) ? 0.25 : 0.5);
		
		g_iBossCount++;
		if (g_iBossCount >= MAX_BOSSES)
		{
			LogError("[LoadBossesFromPack] Max boss limit of %i reached!", MAX_BOSSES);
			break;
		}
	}
	
	delete bossKey;
	PrintToServer("[RF2] Bosses loaded: %i", g_iBossCount);
}

int GetRandomBoss(bool getName = false, char[] name="", int size=0)
{
	int random = GetRandomInt(0, g_iBossCount-1);
	
	if (getName)
		strcopy(name, size, g_szLoadedBosses[random]);
		
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
		if (!IsClientInGameEx(i) || GetClientTeam(i) != TEAM_ENEMY)
		{
			bossPoints[i] = -9999999999;
			continue;
		}
		
		valid[i] = true;
		if (!IsPlayerAlive(i)) // Dead enemies have the biggest priority, obviously.
			bossPoints[i] += 9999;	
		
		/**
		* We'll randomly decide whether or not this player's points factor in to their priority.
		* If you do well, you have a higher chance of becoming the boss, but not always -
		* to give other players a chance even if they aren't scoring as high as their peers. */
		
		if (!IsFakeClientEx(i))
		{
			bossPoints[i] += 250; // Players are prioritized over TFBots, so have a free 250 points.
			if (GetRandomInt(1, 4) == 1)
			{
				// Add points based on score, but not always.
				bossPoints[i] += GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iScore", _, i);
			}
		}
		
		// Non-bosses are obviously prioritized as well.
		if (GetBossType(i) < 0)
			bossPoints[i] += 2000;
			
		if (IsPlayerAFK(i))
			bossPoints[i] -= 5000;
			
		playerPoints[i] = bossPoints[i];
	}
	
	SortIntegers(bossPoints, sizeof(bossPoints), Sort_Descending);
	int highestPoints = bossPoints[0];
	int count;
	int bossCount = 1 + ((GetPlayersOnTeam(TEAM_SURVIVOR, true)-1)/2) + ((g_iSubDifficulty-1)/2);
	if (bossCount < 1)
		bossCount = 1;
	
	float time;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!valid[i] || g_bPlayerIsTeleporterBoss[i])
			continue;
		
		if (playerPoints[i] == highestPoints)
		{
			// don't spawn all the bosses at once, as it will cause client crashes if there are too many
			DataPack pack;
			CreateDataTimer(time, Timer_SpawnTeleporterBoss, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(GetClientUserId(i));
			pack.WriteCell(GetRandomBoss());
			pack.WriteCell(entity);
			time += 0.1;
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
	int client = GetClientOfUserId(pack.ReadCell());
	if (client == 0 || !IsClientInGameEx(client))
		return Plugin_Continue;
	
	int type = pack.ReadCell();
	int spawnEntity = pack.ReadCell();
	
	g_bPlayerIsTeleporterBoss[client] = true;
	SpawnBoss(client, type, spawnEntity, true, true);
	return Plugin_Continue;
}

void SpawnBoss(int client, int type, int spawnEntity=-1, bool force=true, bool teleporterBoss=false)
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
				if (g_iBossBotDifficulty[type] < TFBotDifficulty_Hard && g_iBossBotDifficulty[type] != TFBotDifficulty_Expert)
				{
					SetEntProp(client, Prop_Send, "m_nBotSkill", TFBotDifficulty_Hard);
				}
				else
				{
					SetEntProp(client, Prop_Send, "m_nBotSkill", g_iBossBotDifficulty[type]);
				}
			}
			case DIFFICULTY_TITANIUM:
			{
				SetEntProp(client, Prop_Send, "m_nBotSkill", TFBotDifficulty_Expert);
			}
			
			default:
			{
				SetEntProp(client, Prop_Send, "m_nBotSkill", g_iBossBotDifficulty[type]);
			}
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
	ScaleVector(mins, g_flBossModelScale[type]);
	ScaleVector(maxs, g_flBossModelScale[type]);
	float zOffset = 15.0 * g_flBossModelScale[type];
	
	float spawnPos[3];
	float minSpawnDistance = g_cvEnemyMinSpawnDistance.FloatValue;
	float maxSpawnDistance;
	
	if (!teleporterBoss)
		maxSpawnDistance = g_cvEnemyMaxSpawnDistance.FloatValue;
	else
		maxSpawnDistance = GetTeleporterRadius();
	
	CNavArea area = GetSpawnPointFromNav(pos, spawnPos, minSpawnDistance, maxSpawnDistance, TEAM_SURVIVOR, true, mins, maxs, MASK_PLAYERSOLID, zOffset);
	if (!area)
	{
		DataPack pack = CreateDataPack();
		pack.WriteCell(GetClientUserId(client));
		pack.WriteCell(type);
		pack.WriteCell(spawnEntity);
		pack.WriteCell(force);
		RequestFrame(RF_TrySpawnAgainBoss, pack); // try again on every frame instead of on a timer, as boss spawns are much more important
		
		return;
	}
	
	g_iPlayerBossType[client] = type;
	g_iPlayerBaseHealth[client] = g_iBossBaseHp[type];
	g_flPlayerMaxSpeed[client] = g_flBossBaseSpeed[type];
		
	TF2_SetPlayerClass(client, view_as<TFClassType>(g_iBossTfClass[type]));
	TF2_RespawnPlayer(client);
	TeleportEntity(client, spawnPos, NULL_VECTOR, NULL_VECTOR);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_flBossModelScale[type]);
	TF2_AddCondition(client, TFCond_UberchargedCanteen, 1.0);
	
	SetVariantString(g_szBossModel[type]);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
	
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMinsPreScaled", mins);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxsPreScaled", maxs);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", mins);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", maxs);
	
	SetEntProp(client, Prop_Data, "m_bloodColor", -1);
	
	TF2_RemoveAllWeapons(client);
	
	if (g_szBossConditions[type][0])
	{
		char buffer[256];
		strcopy(buffer, sizeof(buffer), g_szBossConditions[type]);
		Format(buffer, sizeof(buffer), "%s = a = ", buffer);
		ReplaceString(buffer, MAX_ATTRIBUTE_STRING_LENGTH, " ; ", " = ");
		char buffers[16][32];
		int count = ExplodeString(buffer, " = ", buffers, 16, 32);
		
		int cond;
		float duration;
		for (int i = 0; i <= count+1; i+=2)
		{
			cond = StringToInt(buffers[i]);
			duration = StringToFloat(buffers[i+1]);
			
			TF2_AddCondition(client, view_as<TFCond>(cond), duration);
		}
	}
	
	for (int i = 0; i < g_iBossWeaponAmount[type]; i++)
	{
		CreateWeapon(client, 
		g_szBossWeaponName[type][i], 
		g_iBossWeaponIndex[type][i], 
		g_szBossWeaponAttributes[type][i], 
		g_bBossWeaponUseStaticAttributes[type][i],
		g_bBossWeaponVisible[type][i]);
	}
	
	for (int i = 1; i < Item_MaxValid; i++)
	{
		if (g_iBossItem[type][i] > 0)
		{
			GiveItem(client, i, g_iBossItem[type][i]);
		}
	}
	
	int wearable;
	for (int i = 0; i < g_iBossWearableAmount[type]; i++)
	{
		wearable = CreateWearable(client, 
		g_szBossWearableName[type][i], 
		g_iBossWearableIndex[type][i], 
		g_szBossWearableAttributes[type][i], 
		g_bBossWearableVisible[type][i]);
		
		g_bDontRemoveWearable[wearable] = true;
	}
	
	if (g_bBossFullRage[type])
	{
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
	}
	
	if (teleporterBoss)
	{
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", true);
	}
	
	if (g_bBossGiantWeaponSounds[type])
	{
		int weapon = GetPlayerWeaponSlot(client, 0);
		if (weapon != -1)
		{
			// trick game into playing MvM giant weapon sounds
			SetEntProp(weapon, Prop_Send, "m_iTeamNum", TF_TEAM_PVE_INVADERS_GIANTS);
		}
	}
	
	SetEntPropFloat(client, Prop_Send, "m_flHeadScale", g_flBossHeadScale[type]);
	SetEntPropFloat(client, Prop_Send, "m_flTorsoScale", g_flBossTorsoScale[type]);
	SetEntPropFloat(client, Prop_Send, "m_flHandScale", g_flBossHandScale[type]);
	
	g_iPlayerVoiceType[client] = g_iBossVoiceType[type];
	g_iPlayerVoicePitch[client] = g_iBossVoicePitch[type];
	g_bPlayerVoiceNoPainSounds[client] = g_bBossVoiceNoPainSounds[type];
	g_iPlayerFootstepType[client] = g_iBossFootstepType[type];
	g_flPlayerGiantFootstepInterval[client] = g_flBossFootstepInterval[type];
}

public void RF_TrySpawnAgainBoss(DataPack pack)
{
	pack.Reset();
	
	int client = GetClientOfUserId(pack.ReadCell());
	if (client == 0 || !IsClientInGameEx(client))
	{
		delete pack;
		return;
	}
	
	int type = pack.ReadCell();
	int spawnEntity = pack.ReadCell();
	bool force = bool(pack.ReadCell());
	delete pack;
	
	SpawnBoss(client, type, spawnEntity, force);
}

int GetBossType(int client)
{
	return g_iPlayerBossType[client];
}

int GetBossCount()
{
	return g_iBossCount;
}

int GetBossName(int type, char[] buffer, int size)
{
	return strcopy(buffer, size, g_szBossName[type]);
}

bool IsTeleporterBoss(int client)
{
	return g_bPlayerIsTeleporterBoss[client];
}