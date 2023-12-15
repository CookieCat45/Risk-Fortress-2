#if defined _RF2_enemies_included
 #endinput
#endif
#define _RF2_enemies_included

#pragma semicolon 1
#pragma newdecls required

int g_iEnemyCount;
char g_szLoadedEnemies[MAX_ENEMIES][64];

// General enemy data
static TFClassType g_iEnemyTfClass[MAX_ENEMIES];
static int g_iEnemyBaseHp[MAX_ENEMIES];
static int g_iEnemyWeight[MAX_ENEMIES];
static int g_iEnemyItem[MAX_ENEMIES][MAX_ITEMS];

static float g_flEnemyBaseSpeed[MAX_ENEMIES];
static float g_flEnemyModelScale[MAX_ENEMIES];
static float g_flEnemyXPAward[MAX_ENEMIES];
static float g_flEnemyCashAward[MAX_ENEMIES];

static bool g_bEnemyFullRage[MAX_ENEMIES];
static bool g_bEnemyNoBleeding[MAX_ENEMIES];

static char g_szEnemyName[MAX_ENEMIES][PLATFORM_MAX_PATH];
static char g_szEnemyModel[MAX_ENEMIES][PLATFORM_MAX_PATH];

// TFBot
static int g_iEnemyBotSkill[MAX_ENEMIES];
static bool g_bEnemyBotAggressive[MAX_ENEMIES];
static bool g_bEnemyBotRocketJump[MAX_ENEMIES];
static bool g_bEnemyBotHoldFireUntilReloaded[MAX_ENEMIES];

// Weapons
static bool g_bEnemyWeaponUseStaticAttributes[MAX_ENEMIES][TF_WEAPON_SLOTS];
static bool g_bEnemyWeaponVisible[MAX_ENEMIES][TF_WEAPON_SLOTS];
static bool g_bEnemyWeaponFirstActive[MAX_ENEMIES][TF_WEAPON_SLOTS];
static int g_iEnemyWeaponIndex[MAX_ENEMIES][TF_WEAPON_SLOTS];
static int g_iEnemyWeaponAmount[MAX_ENEMIES];
static char g_szEnemyWeaponName[MAX_ENEMIES][TF_WEAPON_SLOTS][128];
static char g_szEnemyWeaponAttributes[MAX_ENEMIES][TF_WEAPON_SLOTS][MAX_ATTRIBUTE_STRING_LENGTH];

// Wearables
static int g_iEnemyWearableAmount[MAX_ENEMIES];
static int g_iEnemyWearableIndex[MAX_ENEMIES][MAX_WEARABLES];
static bool g_bEnemyWearableStaticAttributes[MAX_ENEMIES][MAX_WEARABLES];
static bool g_bEnemyWearableVisible[MAX_ENEMIES][MAX_WEARABLES];
static char g_szEnemyWearableName[MAX_ENEMIES][MAX_WEARABLES][128];
static char g_szEnemyWearableAttributes[MAX_ENEMIES][MAX_WEARABLES][MAX_ATTRIBUTE_STRING_LENGTH];

// Sound/voice
static int g_iEnemyVoiceType[MAX_ENEMIES] = {VoiceType_Robot, ...};
static int g_iEnemyVoicePitch[MAX_ENEMIES] = {SNDPITCH_NORMAL, ...};
static int g_iEnemyFootstepType[MAX_ENEMIES] = {FootstepType_Robot, ...};

// Other
float g_flEnemyHeadScale[MAX_BOSSES] = {1.5, ...};
float g_flEnemyTorsoScale[MAX_BOSSES] = {1.0, ...};
float g_flEnemyHandScale[MAX_BOSSES] = {1.0, ...};
static bool g_bEnemyAllowSelfDamage[MAX_BOSSES];
static char g_szEnemyConditions[MAX_BOSSES][256];

// Bosses
static bool g_bEnemyIsBoss[MAX_ENEMIES];
static bool g_bBossGiantWeaponSounds[MAX_ENEMIES];
static float g_flBossFootstepInterval[MAX_ENEMIES];
#define TF_TEAM_PVE_INVADERS_GIANTS 4

// Minions (TODO)
/*
static char g_szBossMinions[MAX_BOSSES][PLATFORM_MAX_PATH];
static float g_flBossMinionSpawnInterval[MAX_BOSSES];
static bool g_bBossMinionInstantSpawn[MAX_BOSSES] = {true, ...};
static int g_iBossMinionSpawnCount[MAX_BOSSES];
*/

methodmap Enemy
{
	public Enemy(int client)
	{
		return EnemyByIndex(g_iPlayerEnemyType[client]);
	}
	
	property int Index
	{
		public get() 
		{
			return view_as<int>(this);
		}
	}
	
	property bool IsBoss
	{
		public get()			{ return g_bEnemyIsBoss[this.Index]; }
		public set(bool value)	{ g_bEnemyIsBoss[this.Index] = value; }
	}
	
	public int GetItem(int item)
	{
		return g_iEnemyItem[this.Index][item];
	}
	
	public void SetItem(int item, int value)
	{
		g_iEnemyItem[this.Index][item] = value;
	}
	
	public int GetModel(char[] buffer, int size)
	{
		return strcopy(buffer, size, g_szEnemyModel[this.Index]);
	}
	
	public void SetModel(const char[] model)
	{
		strcopy(g_szEnemyModel[this.Index], sizeof(g_szEnemyModel[]), model);
	}
	
	public int GetName(char[] buffer, int size)
	{
		return strcopy(buffer, size, g_szEnemyName[this.Index]);
	}

	public void SetName(const char[] name)
	{
		strcopy(g_szEnemyName[this.Index], sizeof(g_szEnemyName[]), name);
	}

	property float ModelScale
	{
		public get()			{ return g_flEnemyModelScale[this.Index];  }
		public set(float value)	{ g_flEnemyModelScale[this.Index] = value; }
	}
	
	property TFClassType Class
	{
		public get() 					{ return g_iEnemyTfClass[this.Index];  }
		public set(TFClassType class) 	{ g_iEnemyTfClass[this.Index] = class; }
	}

	property int BaseHealth
	{
		public get()			{ return g_iEnemyBaseHp[this.Index];  }
		public set(int value)	{ g_iEnemyBaseHp[this.Index] = value; }
	}
	
	property float BaseSpeed
	{
		public get()			{ return g_flEnemyBaseSpeed[this.Index];  }
		public set(float value)	{ g_flEnemyBaseSpeed[this.Index] = value; }
	}
	
	property float XPAward
	{
		public get()			{ return g_flEnemyXPAward[this.Index];  }
		public set(float value)	{ g_flEnemyXPAward[this.Index] = value; }
	}
	
	property float CashAward
	{
		public get()			{ return g_flEnemyCashAward[this.Index];  }
		public set(float value)	{ g_flEnemyCashAward[this.Index] = value; }
	}

	property int Weight
	{
		public get()			{ return g_iEnemyWeight[this.Index];  }
		public set(int value)	{ g_iEnemyWeight[this.Index] = value; }
	}
	
	property bool FullRage
	{
		public get()			{ return g_bEnemyFullRage[this.Index]; }
		public set(bool value)	{ g_bEnemyFullRage[this.Index] = value; }
	}

	property bool NoBleeding
	{
		public get()			{ return g_bEnemyNoBleeding[this.Index]; }
		public set(bool value)	{ g_bEnemyNoBleeding[this.Index] = value; }
	}
	
	property int BotSkill
	{
		public get()			{ return g_iEnemyBotSkill[this.Index];  }
		public set(int value)	{ g_iEnemyBotSkill[this.Index] = value; }
	}
	
	property bool BotAggressive
	{
		public get()			{ return g_bEnemyBotAggressive[this.Index];  }
		public set(bool value)	{ g_bEnemyBotAggressive[this.Index] = value; }
	}

	property bool BotRocketJump
	{
		public get()			{ return g_bEnemyBotRocketJump[this.Index];  }
		public set(bool value)	{ g_bEnemyBotRocketJump[this.Index] = value; }
	}
	
	property bool BotHoldFireReload
	{
		public get()			{ return g_bEnemyBotHoldFireUntilReloaded[this.Index];  }
		public set(bool value)	{ g_bEnemyBotHoldFireUntilReloaded[this.Index] = value; }
	}
	
	property int WeaponCount
	{
		public get() 			{ return g_iEnemyWeaponAmount[this.Index]; }
		public set(int value)	{ g_iEnemyWeaponAmount[this.Index] = value; }
	}
	
	public bool WeaponUseStaticAtts(int slot)
	{
		return g_bEnemyWeaponUseStaticAttributes[this.Index][slot];
	}
	
	public bool WeaponIsFirstActive(int slot)
	{
		return g_bEnemyWeaponFirstActive[this.Index][slot];
	}

	public void SetWeaponIsFirstActive(int slot, bool value)
	{
		g_bEnemyWeaponFirstActive[this.Index][slot] = value;
	}

	public void SetWeaponUseStaticAtts(int slot, bool value)
	{
		g_bEnemyWeaponUseStaticAttributes[this.Index][slot] = value;
	}
	
	public bool WeaponVisible(int slot)
	{
		return g_bEnemyWeaponVisible[this.Index][slot];
	}

	public void SetWeaponVisible(int slot, bool value)
	{
		g_bEnemyWeaponVisible[this.Index][slot] = value;
	}
	
	public int WeaponIndex(int slot)
	{
		return g_iEnemyWeaponIndex[this.Index][slot];
	}
	
	public void SetWeaponIndex(int slot, int value)
	{
		g_iEnemyWeaponIndex[this.Index][slot] = value;
	}
	
	public int GetWeaponName(int slot, char[] buffer, int size)
	{
		return strcopy(buffer, size, g_szEnemyWeaponName[this.Index][slot]);
	}
	
	public void SetWeaponName(int slot, const char[] name)
	{
		strcopy(g_szEnemyWeaponName[this.Index][slot], sizeof(g_szEnemyWeaponName[][]), name);
	}
	
	public int GetWeaponAttributes(int slot, char[] buffer, int size)
	{
		return strcopy(buffer, size, g_szEnemyWeaponAttributes[this.Index][slot]);
	}

	public void SetWeaponAttributes(int slot, const char[] value)
	{
		strcopy(g_szEnemyWeaponAttributes[this.Index][slot], sizeof(g_szEnemyWeaponAttributes[][]), value);
	}
	
	property int WearableCount
	{
		public get() 			{ return g_iEnemyWearableAmount[this.Index]; }
		public set(int value)	{ g_iEnemyWearableAmount[this.Index] = value; }
	}
	
	public bool WearableUseStaticAtts(int slot)
	{
		return g_bEnemyWearableStaticAttributes[this.Index][slot];
	}
	
	public void SetWearableUseStaticAtts(int slot, bool value)
	{
		g_bEnemyWearableStaticAttributes[this.Index][slot] = value;
	}

	public bool WearableVisible(int slot)
	{
		return g_bEnemyWearableVisible[this.Index][slot];
	}

	public void SetWearableVisible(int slot, bool value)
	{
		g_bEnemyWearableVisible[this.Index][slot] = value;
	}
	
	public int WearableIndex(int slot)
	{
		return g_iEnemyWearableIndex[this.Index][slot];
	}
	
	public void SetWearableIndex(int slot, int value)
	{
		g_iEnemyWearableIndex[this.Index][slot] = value;
	}
	
	public int GetWearableName(int slot, char[] buffer, int size)
	{
		return strcopy(buffer, size, g_szEnemyWearableName[this.Index][slot]);
	}
	
	public void SetWearableName(int slot, const char[] name)
	{
		strcopy(g_szEnemyWearableName[this.Index][slot], sizeof(g_szEnemyWearableName[][]), name);
	}
	
	public int GetWearableAttributes(int slot, char[] buffer, int size)
	{
		return strcopy(buffer, size, g_szEnemyWearableAttributes[this.Index][slot]);
	}
	
	public void SetWearableAttributes(int slot, const char[] value)
	{
		strcopy(g_szEnemyWearableAttributes[this.Index][slot], sizeof(g_szEnemyWearableAttributes[][]), value);
	}

	property int VoiceType
	{
		public get()			{ return g_iEnemyVoiceType[this.Index]; }
		public set(int value)	{ g_iEnemyVoiceType[this.Index] = value; }
	}

	property int VoicePitch
	{
		public get()			{ return g_iEnemyVoicePitch[this.Index]; }
		public set(int value)	{ g_iEnemyVoicePitch[this.Index] = value; }
	}

	property int FootstepType
	{
		public get()			{ return g_iEnemyFootstepType[this.Index]; }
		public set(int value)	{ g_iEnemyFootstepType[this.Index] = value; }
	}

	property float HeadScale
	{
		public get()			{ return g_flEnemyHeadScale[this.Index]; }
		public set(float value) { g_flEnemyHeadScale[this.Index] = value; }
	}

	property float TorsoScale
	{
		public get()			{ return g_flEnemyTorsoScale[this.Index]; }
		public set(float value) { g_flEnemyTorsoScale[this.Index] = value; }
	}
	
	property float HandScale
	{
		public get()			{ return g_flEnemyHandScale[this.Index]; }
		public set(float value) { g_flEnemyHandScale[this.Index] = value; }
	}
	
	public int GetConds(char[] buffer, int size)
	{
		return strcopy(buffer, size, g_szEnemyConditions[this.Index]);
	}
	
	public void SetConds(const char[] conds)
	{
		strcopy(g_szEnemyConditions[this.Index], sizeof(g_szEnemyConditions[]), conds);
	}

	property bool AllowSelfDamage
	{
		public get()			{ return g_bEnemyAllowSelfDamage[this.Index]; }
		public set(bool value)	{ g_bEnemyAllowSelfDamage[this.Index] = value; }
	}

	property bool BossGiantWeaponSounds
	{
		public get()			{ return g_bBossGiantWeaponSounds[this.Index]; }
		public set(bool value)	{ g_bBossGiantWeaponSounds[this.Index] = value; }
	}
	
	property float BossFootstepInterval
	{
		public get()			{ return g_flBossFootstepInterval[this.Index]; }
		public set(float value)	{ g_flBossFootstepInterval[this.Index] = value; }
	}
}

#define NULL_ENEMY view_as<Enemy>(-1)

Enemy EnemyByIndex(int index)
{
	return view_as<Enemy>(index);
}

void LoadEnemiesFromPack(const char[] config, bool bosses=false)
{
	KeyValues enemyKey = bosses ? CreateKeyValues("bosses") : CreateKeyValues("enemies");
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "%s/%s.cfg", ConfigPath, config);
	if (!enemyKey.ImportFromFile(path))
	{
		ThrowError("File %s does not exist", path);
	}
	
	if (!bosses)
		g_iEnemyCount = 0;

	bool firstKey;
	char sectionName[16];
	Enemy enemy;
	
	for (int e = g_iEnemyCount; e <= g_iEnemyCount; e++)
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
		
		enemyKey.GetSectionName(g_szLoadedEnemies[e], sizeof(g_szLoadedEnemies[]));
		enemy = EnemyByIndex(e);
		enemy.IsBoss = bosses;
		
		// name, model, description
		enemyKey.GetString("name", g_szEnemyName[e], sizeof(g_szEnemyName[]), "unnamed");
		enemyKey.GetString("model", g_szEnemyModel[e], sizeof(g_szEnemyModel[]), "models/player/soldier.mdl");
		enemy.ModelScale = enemyKey.GetFloat("model_scale", enemy.IsBoss ? 1.75 : 1.0);
		
		if (FileExists(g_szEnemyModel[e]))
		{
			PrecacheModel(g_szEnemyModel[e]);
			AddModelToDownloadsTable(g_szEnemyModel[e]);
		}
		else
		{
			LogError("[LoadEnemiesFromPack] Model %s for enemy \"%s\" could not be found!", g_szEnemyModel[e], g_szLoadedEnemies[e]);
			enemy.SetModel(MODEL_ERROR);
		}
		
		// TF class, health, and speed
		enemy.Class = view_as<TFClassType>(enemyKey.GetNum("class", 1));
		enemy.BaseHealth = enemyKey.GetNum("health", 150);
		enemy.BaseSpeed = enemyKey.GetFloat("speed", 300.0);
		
		enemy.BotSkill = enemyKey.GetNum("tf_bot_difficulty", TFBotDifficulty_Normal);
		enemy.BotAggressive = asBool(enemyKey.GetNum("tf_bot_aggressive", false));
		enemy.BotRocketJump = asBool(enemyKey.GetNum("tf_bot_rocketjump", false));
		enemy.BotHoldFireReload = asBool(enemyKey.GetNum("tf_bot_hold_fire_until_reload", false));
		
		// XP and cash awards on death
		enemy.XPAward = enemyKey.GetFloat("xp_award", 15.0);
		enemy.CashAward = enemyKey.GetFloat("cash_award", 20.0);
		enemy.Weight = imin(imax(enemyKey.GetNum("weight", 50), 1), 100);
		
		enemy.FullRage = asBool(enemyKey.GetNum("full_rage", false));
		enemy.NoBleeding = asBool(enemyKey.GetNum("no_bleeding", true));
		
		enemy.WeaponCount = 0;
		for (int w = 0; w < TF_WEAPON_SLOTS; w++)
		{
			FormatEx(sectionName, sizeof(sectionName), "weapon%i", w+1);
			if (!enemyKey.JumpToKey(sectionName))
			{
				break;
			}
			
			enemyKey.GetString("classname", g_szEnemyWeaponName[e][w], sizeof(g_szEnemyWeaponName[][]), "null");
			enemyKey.GetString("attributes", g_szEnemyWeaponAttributes[e][w], sizeof(g_szEnemyWeaponAttributes[][]), "");
			enemy.SetWeaponIndex(w, enemyKey.GetNum("index", 5));
			enemy.SetWeaponVisible(w, asBool(enemyKey.GetNum("visible", true)));
			enemy.SetWeaponUseStaticAtts(w, asBool(enemyKey.GetNum("static_attributes", false)));
			enemy.SetWeaponIsFirstActive(w, asBool(enemyKey.GetNum("active_weapon", false)));
			enemy.WeaponCount++;
			
			enemyKey.GoBack();
		}
		
		enemy.WearableCount = 0;
		for (int w = 0; w < MAX_WEARABLES; w++)
		{
			FormatEx(sectionName, sizeof(sectionName), "wearable%i", w+1);
			if (!enemyKey.JumpToKey(sectionName))
				continue;
			
			enemyKey.GetString("classname", g_szEnemyWearableName[e][w], sizeof(g_szEnemyWearableName[][]), "tf_wearable");
			enemyKey.GetString("attributes", g_szEnemyWearableAttributes[e][w], sizeof(g_szEnemyWearableAttributes[][]), "");
			enemy.SetWearableIndex(w, enemyKey.GetNum("index", 5));
			enemy.SetWearableVisible(w, asBool(enemyKey.GetNum("visible", true)));
			enemy.SetWearableUseStaticAtts(w, asBool(enemyKey.GetNum("static_attributes", false)));
			enemy.WearableCount++;
			
			enemyKey.GoBack();
		}
		
		for (int i = 1; i < Item_MaxValid; i++)
			enemy.SetItem(i, 0);
		
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
						enemy.SetItem(itemId, enemyKey.GetNum(NULL_STRING));
					}
				}
			}
			
			enemyKey.GoBack();
			enemyKey.GoBack();
		}
		
		enemy.VoiceType = enemyKey.GetNum("voice_type", VoiceType_Robot);
		enemy.VoicePitch = enemyKey.GetNum("voice_pitch", SNDPITCH_NORMAL);
		enemy.FootstepType = enemyKey.GetNum("footstep_type", enemy.IsBoss ? FootstepType_GiantRobot : FootstepType_Robot);
		
		enemy.AllowSelfDamage = asBool(enemyKey.GetNum("allow_self_damage", enemy.IsBoss ? false : true));
		enemy.HeadScale = enemyKey.GetFloat("head_scale", enemy.IsBoss ? 1.5 : 1.0);
		enemy.TorsoScale = enemyKey.GetFloat("torso_scale", 1.0);
		enemy.HandScale = enemyKey.GetFloat("hand_scale", 1.0);
		enemyKey.GetString("spawn_conditions", g_szEnemyConditions[e], sizeof(g_szEnemyConditions[]), "");
		
		if (enemy.IsBoss)
		{
			enemy.BossGiantWeaponSounds = asBool(enemyKey.GetNum("use_giant_weapon_sounds", true));
			enemy.BossFootstepInterval = enemyKey.GetFloat("giant_footstep_interval", enemy.Class == TFClass_Scout ? 0.25 : 0.5);
		}
		
		g_iEnemyCount++;
		if (g_iEnemyCount >= MAX_ENEMIES)
		{
			LogError("[LoadEnemiesFromPack] Max enemy type limit of %i reached!", MAX_ENEMIES);
			break;
		}
	}
	
	delete enemyKey;
}

// Returns the index of a currently-loaded enemy at random based on weight.
// Optionally can retrieve the config name.
int GetRandomEnemy(bool getName=false, char[] buffer="", int size=0)
{
	ArrayList enemyList = CreateArray();
	int selected;
	
	for (int i = 0; i < g_iEnemyCount; i++)
	{
		if (EnemyByIndex(i).IsBoss)
			continue;

		for (int j = 1; j <= EnemyByIndex(i).Weight; j++)
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

// Returns the index of a currently-loaded boss at random based on weight.
// Optionally can retrieve the config name.
int GetRandomBoss(bool getName = false, char[] buffer="", int size=0)
{
	ArrayList bossList = CreateArray();
	int selected;
	
	for (int i = 0; i < g_iEnemyCount; i++)
	{
		if (!EnemyByIndex(i).IsBoss)
			continue;
		
		for (int j = 1; j <= EnemyByIndex(i).Weight; j++)
		{
			bossList.Push(i);
		}
	}
	
	selected = bossList.Get(GetRandomInt(0, bossList.Length-1));
	
	if (getName)
	{
		strcopy(buffer, size, g_szLoadedEnemies[selected]);
	}
	
	delete bossList;
	return selected;
}

bool SpawnEnemy(int client, int type, const float pos[3]=OFF_THE_MAP, float minDist=-1.0, float maxDist=-1.0, bool recursive=true)
{
	g_bPlayerInSpawnQueue[client] = true;
	Enemy enemy = EnemyByIndex(type);
	
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
				if (enemy.BotSkill < TFBotDifficulty_Hard && enemy.BotSkill != TFBotDifficulty_Expert)
				{
					g_TFBot[client].SetSkillLevel(TFBotDifficulty_Hard);
				}
				else
				{
					g_TFBot[client].SetSkillLevel(enemy.BotSkill);
				}
			}
			
			case DIFFICULTY_TITANIUM: g_TFBot[client].SetSkillLevel(TFBotDifficulty_Expert);
			
			default: g_TFBot[client].SetSkillLevel(enemy.BotSkill);
		}
		
		if (enemy.BotAggressive)
		{
			g_TFBot[client].AddFlag(TFBOTFLAG_AGGRESSIVE);
		}
		
		if (enemy.BotRocketJump)
		{
			g_TFBot[client].AddFlag(TFBOTFLAG_ROCKETJUMP);
		}
		
		if (enemy.BotHoldFireReload)
		{
			g_TFBot[client].AddFlag(TFBOTFLAG_HOLDFIRE);
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
	ScaleVector(mins, enemy.ModelScale);
	ScaleVector(maxs, enemy.ModelScale);
	float zOffset = 30.0 * enemy.ModelScale;
	
	float spawnPos[3];
	float minSpawnDistance = minDist < 0.0 ? g_cvEnemyMinSpawnDistance.FloatValue : minDist;
	float maxSpawnDistance = maxDist < 0.0 ? g_cvEnemyMaxSpawnDistance.FloatValue : maxDist;
	CNavArea area = GetSpawnPoint(checkPos, spawnPos, minSpawnDistance, maxSpawnDistance, TEAM_SURVIVOR, true, mins, maxs, MASK_PLAYERSOLID, zOffset);
	
	if (!area)
	{
		if (recursive)
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
		}
		
		return false;
	}
	
	g_bPlayerInSpawnQueue[client] = false;
	
	g_iPlayerEnemyType[client] = type;
	g_iPlayerBaseHealth[client] = enemy.BaseHealth;
	g_flPlayerMaxSpeed[client] = enemy.BaseSpeed;
	
	TF2_SetPlayerClass(client, enemy.Class);
	TF2_RespawnPlayer(client);
	TeleportEntity(client, spawnPos, NULL_VECTOR, NULL_VECTOR);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_flEnemyModelScale[type]);
	TF2_AddCondition(client, TFCond_UberchargedCanteen, 1.0);
	
	char model[PLATFORM_MAX_PATH];
	enemy.GetModel(model, sizeof(model));
	SetVariantString(model);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
	
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMinsPreScaled", mins);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxsPreScaled", maxs);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", mins);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", maxs);
	
	TF2_RemoveAllWeapons(client);
	char name[128], attributes[MAX_ATTRIBUTE_STRING_LENGTH];
	int activeWeapon = -1;
	int weapon;
	for (int i = 0; i < enemy.WeaponCount; i++)
	{
		enemy.GetWeaponName(i, name, sizeof(name));
		enemy.GetWeaponAttributes(i, attributes, sizeof(attributes));
		weapon = CreateWeapon(client, name, enemy.WeaponIndex(i), attributes, enemy.WeaponUseStaticAtts(i), enemy.WeaponVisible(i));
		
		if (activeWeapon == -1 && IsValidEntity(weapon) && enemy.WeaponIsFirstActive(i))
		{
			activeWeapon = weapon;
		}
	}
	
	if (activeWeapon != -1)
	{
		for (int i = 0; i < TF_WEAPON_SLOTS; i++)
		{
			if (GetPlayerWeaponSlot(client, i) == activeWeapon)
			{
				ClientCommand(client, "slot%i", i+1);
				break;
			}
		}
	}
	
	for (int i = 1; i < Item_MaxValid; i++)
	{
		if (enemy.GetItem(i) > 0)
		{
			GiveItem(client, i, enemy.GetItem(i));
		}
	}
	
	int wearable;
	for (int i = 0; i < enemy.WearableCount; i++)
	{
		enemy.GetWearableName(i, name, sizeof(name));
		enemy.GetWearableAttributes(i, attributes, sizeof(attributes));
		wearable = CreateWearable(client, name, enemy.WearableIndex(i), attributes, enemy.WearableUseStaticAtts(i), enemy.WearableVisible(i));
		
		if (wearable > 0)
			g_bDontRemoveWearable[wearable] = true;
	}
	
	if (enemy.FullRage)
	{
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
	}
	
	char conds[128];
	enemy.GetConds(conds, sizeof(conds));
	if (conds[0])
	{
		char buffer[256], buffers[16][32];
		strcopy(buffer, sizeof(buffer), conds);
		ReplaceString(buffer, MAX_ATTRIBUTE_STRING_LENGTH, " ; ", " = ");
		int count = ExplodeString(buffer, " = ", buffers, sizeof(buffers), sizeof(buffers[]), true);
		
		for (int i = 0; i <= count+1; i+=2)
		{
			TF2_AddCondition(client, view_as<TFCond>(StringToInt(buffers[i])), StringToFloat(buffers[i+1]));
		}
	}
	
	g_iPlayerVoiceType[client] = enemy.VoiceType;
	g_iPlayerVoicePitch[client] = enemy.VoicePitch;
	g_iPlayerFootstepType[client] = enemy.FootstepType;
	
	SetEntPropFloat(client, Prop_Send, "m_flHeadScale", enemy.HeadScale);
	SetEntPropFloat(client, Prop_Send, "m_flTorsoScale", enemy.TorsoScale);
	SetEntPropFloat(client, Prop_Send, "m_flHandScale", enemy.HandScale);
	
	return true;
}

bool SpawnBoss(int client, int type, const float pos[3]=OFF_THE_MAP, bool teleporterBoss=false, float minDist=-1.0, float maxDist=-1.0, bool recursive=true)
{
	if (maxDist < 0.0)
	{
		if (teleporterBoss)
		{
			maxDist = GetEntPropFloat(GetTeleporterEntity(), Prop_Data, "m_flRadius");
		}
		else
		{
			maxDist = g_cvEnemyMaxSpawnDistance.FloatValue;
		}
	}
	
	if (SpawnEnemy(client, type, pos, minDist, maxDist, false))
	{
		if (teleporterBoss)
		{
			g_bPlayerIsTeleporterBoss[client] = true;
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", true);
		}
		
		if (EnemyByIndex(type).BossGiantWeaponSounds)
		{
			int weapon = GetPlayerWeaponSlot(client, 0);
			if (weapon != -1)
			{
				// trick game into playing MvM giant weapon sounds
				SetEntProp(weapon, Prop_Send, "m_iTeamNum", TF_TEAM_PVE_INVADERS_GIANTS);
			}
		}
		
		g_flPlayerGiantFootstepInterval[client] = EnemyByIndex(type).BossFootstepInterval;
		
		TF2Attrib_SetByDefIndex(client, 252, 0.2); // "damage force reduction"
		TF2Attrib_SetByDefIndex(client, 329, 0.2); // "airblast vulnerability multiplier"
		TF2Attrib_SetByDefIndex(client, 326, 1.35); // "increased jump height"
		
		return true;
	}
	else if (recursive)
	{
		// try again next frame
		DataPack pack = CreateDataPack();
		pack.WriteCell(client);
		pack.WriteCell(type);
		pack.WriteFloat(pos[0]);
		pack.WriteFloat(pos[1]);
		pack.WriteFloat(pos[2]);
		pack.WriteCell(teleporterBoss);
		pack.WriteFloat(minDist);
		pack.WriteFloat(maxDist);
		
		RequestFrame(RF_SpawnBossRecursive, pack);
	}

	return false;
}

void SummonTeleporterBosses(int entity)
{
	// First, we need to find the best candidates for bosses.
	int playerPoints[MAXTF2PLAYERS];
	int bossPoints[MAXTF2PLAYERS];
	bool valid[MAXTF2PLAYERS];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsFakeClient(i) && !g_bPlayerBecomeBoss[i] || g_bPlayerInSpawnQueue[i] || !IsClientInGame(i) || GetClientTeam(i) != TEAM_ENEMY)
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
		* to give other players a chance even if they aren't scoring as high as their peers. 
		*/
		
		if (!IsFakeClient(i))
		{
			bossPoints[i] += 250; // Players are prioritized over bots, so have a free 250 points.
			if (GetRandomInt(1, 4) == 1)
			{
				bossPoints[i] += GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iScore", _, i);
			}
		}
		
		// Non-bosses are obviously prioritized as well.
		if (!IsBoss(i))
			bossPoints[i] += 2000;
			
		if (IsPlayerAFK(i))
			bossPoints[i] -= 5000;
			
		playerPoints[i] = bossPoints[i];
	}
	
	SortIntegers(bossPoints, sizeof(bossPoints), Sort_Descending);
	int highestPoints = bossPoints[0];
	int count;
	int bossCount = 1 + ((GetPlayersOnTeam(TEAM_SURVIVOR, true)-1)/2) + ((RF2_GetSubDifficulty()-1)/2);
	imax(bossCount, 1);
	
	float time;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_bPlayerInSpawnQueue[i] || !valid[i] || g_bPlayerIsTeleporterBoss[i])
			continue;
		
		if (playerPoints[i] == highestPoints)
		{
			g_bPlayerInSpawnQueue[i] = true;
			
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
	
	EmitSoundToAll(SND_BOSS_SPAWN);
}

public Action Timer_SpawnTeleporterBoss(Handle time, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	
	if (client == 0 || !IsClientInGame(client))
		return Plugin_Continue;
	
	int type = pack.ReadCell();
	int spawnEntity = pack.ReadCell();
	
	g_bPlayerIsTeleporterBoss[client] = true;
	float pos[3];
	GetEntPos(spawnEntity, pos);
	
	SpawnBoss(client, type, pos, true);
	return Plugin_Continue;
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

public void RF_SpawnBossRecursive(DataPack pack)
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
	
	bool teleporterBoss = pack.ReadCell();
	
	float minDist = pack.ReadFloat();
	float maxDist = pack.ReadFloat();
	
	delete pack;
	SpawnBoss(client, type, pos, teleporterBoss, minDist, maxDist);
}

int GetEnemyCount()
{
	return g_iEnemyCount;
}

bool IsEnemy(int client)
{
	return Enemy(client) != NULL_ENEMY;
}

bool IsBoss(int client, bool teleporterBoss=false)
{
	return IsEnemy(client) && Enemy(client).IsBoss && (!teleporterBoss || IsTeleporterBoss(client));
}

bool IsTeleporterBoss(int client)
{
	return g_bPlayerIsTeleporterBoss[client];
}

float GetEnemyHealthMult()
{
	return 1.0 + float(RF2_GetEnemyLevel()-1) * g_cvEnemyHealthScale.FloatValue;
}

float GetEnemyDamageMult()
{
	return 1.0 + float(RF2_GetEnemyLevel()-1) * g_cvEnemyDamageScale.FloatValue;
}