#pragma semicolon 1
#pragma newdecls required

#define NULL_ENEMY view_as<Enemy>(-1)
#define MAX_ENEMIES 64
#define MAX_WEARABLES 6

int g_iEnemyCount;
char g_szLoadedEnemies[MAX_ENEMIES][64];

// General enemy data
static TFClassType g_iEnemyTfClass[MAX_ENEMIES];
static int g_iEnemyBaseHp[MAX_ENEMIES];
static int g_iEnemyWeight[MAX_ENEMIES];
static int g_iEnemyItem[MAX_ENEMIES][MAX_ITEMS];
static int g_iEnemyActiveLimit[MAX_ENEMIES];
static int g_iEnemySpawnLimit[MAX_ENEMIES];
static int g_iEnemyEyeGlowColor[MAX_ENEMIES][3];
static char g_szEnemyName[MAX_ENEMIES][MAX_NAME_LENGTH];
static char g_szEnemyModel[MAX_ENEMIES][PLATFORM_MAX_PATH];
static char g_szEnemyGroup[MAX_ENEMIES][64];
static float g_flEnemyBaseSpeed[MAX_ENEMIES];
static float g_flEnemyModelScale[MAX_ENEMIES];
static float g_flEnemyXPAward[MAX_ENEMIES];
static float g_flEnemyCashAward[MAX_ENEMIES];
static float g_flEnemySpawnCooldown[MAX_ENEMIES];
static float g_flEnemyItemDamageModifier[MAX_ENEMIES];
static float g_flEnemyBaseCarriedCash[MAX_ENEMIES];
static bool g_bEnemyAlwaysCrit[MAX_ENEMIES];
static bool g_bEnemyFullRage[MAX_ENEMIES];
static bool g_bEnemyNoBleeding[MAX_ENEMIES];
static bool g_bEnemyShouldGlow[MAX_ENEMIES];
static bool g_bEnemyNoCrits[MAX_ENEMIES];
static bool g_bEnemyEyeGlow[MAX_ENEMIES];
static bool g_bEnemyCustomEyeGlow[MAX_ENEMIES];
static bool g_bEnemyEngineIdleSound[MAX_ENEMIES];

// Suicide Bomber (Sentry Busters)
static bool g_bEnemySuicideBomber[MAX_ENEMIES];
static bool g_bEnemySuicideBombDamageFalloff[MAX_ENEMIES];
static bool g_bEnemySuicideBombBusterSounds[MAX_ENEMIES];
static bool g_bEnemySuicideBombFriendlyFire[MAX_ENEMIES];
static float g_flEnemySuicideBombDamage[MAX_ENEMIES];
static float g_flEnemySuicideBombDelay[MAX_ENEMIES];
static float g_flEnemySuicideBombRange[MAX_ENEMIES];

// TFBot
static int g_iEnemyBotSkill[MAX_ENEMIES];
static int g_iEnemyBotBehaviorAttributes[MAX_ENEMIES];
static int g_iEnemyBotDemoStickyDetCount[MAX_ENEMIES];
static int g_iEnemyBotForcedWeaponSlot[MAX_ENEMIES];
static float g_flEnemyBotMeleeDistance[MAX_ENEMIES];
static float g_flEnemyBotMaxVisionRange[MAX_ENEMIES];
static bool g_bEnemyBotSkillNoOverride[MAX_ENEMIES];
static bool g_bEnemyBotAggressive[MAX_ENEMIES];
static bool g_bEnemyBotRocketJump[MAX_ENEMIES];
static bool g_bEnemyBotHoldFireUntilReloaded[MAX_ENEMIES];
static bool g_bEnemyBotAlwaysAttack[MAX_ENEMIES];
static bool g_bEnemyBotAlwaysJump[MAX_ENEMIES];
static bool g_bEnemyBotUberOnSight[MAX_ENEMIES];
static bool g_bEnemyBotScavengerAI[MAX_ENEMIES];
static bool g_bEnemyBotScavengerIgnoreEnemies[MAX_ENEMIES];
static ArrayList g_hEnemyBotTags[MAX_ENEMIES];

// Weapons
static bool g_bEnemyWeaponUseStaticAttributes[MAX_ENEMIES][TF_WEAPON_SLOTS];
static bool g_bEnemyWeaponVisible[MAX_ENEMIES][TF_WEAPON_SLOTS];
static bool g_bEnemyWeaponFirstActive[MAX_ENEMIES][TF_WEAPON_SLOTS];
static bool g_bEnemyWeaponStartWithEmptyClip[MAX_ENEMIES][TF_WEAPON_SLOTS];
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
float g_flEnemyHeadScale[MAX_ENEMIES] = {1.5, ...};
float g_flEnemyTorsoScale[MAX_ENEMIES] = {1.0, ...};
float g_flEnemyHandScale[MAX_ENEMIES] = {1.0, ...};
static bool g_bEnemyAllowSelfDamage[MAX_ENEMIES];
static char g_szEnemyConditions[MAX_ENEMIES][256];
static ArrayList g_hEnemyScripts[MAX_ENEMIES];
static char g_szEnemyScriptCode[MAX_ENEMIES][4096];

// Bosses
static bool g_bEnemyIsBoss[MAX_ENEMIES];
static bool g_bBossGiantWeaponSounds[MAX_ENEMIES];
static float g_flBossFootstepInterval[MAX_ENEMIES];
#define TF_TEAM_PVE_INVADERS_GIANTS 4

methodmap Enemy
{
	public Enemy(int client)
	{
		return EnemyByIndex(g_iPlayerEnemyType[client]);
	}
	
	public static Enemy FindByInternalName(const char[] name)
	{
		for (int i = 0; i < g_iEnemyCount; i++)
		{
			Enemy enemy = EnemyByIndex(i);
			if (strcmp2(enemy.GetInternalName(), name))
			{
				return enemy;
			}
		}
		
		return NULL_ENEMY;
	}
	
	public bool IsAllowedToSpawn()
	{
		if (this.ActiveLimit > 0 && this.GetTotalActive() >= this.ActiveLimit)
			return false;
		
		char name[64];
		name = this.GetInternalName();
		int val;
		if (this.SpawnLimit > 0 && g_hEnemyTypeNumSpawned.GetValue(name, val) && val >= this.SpawnLimit)
		{
			return false;
		}

		float cd;
		if (this.SpawnCooldown > 0.0 && g_hEnemyTypeCooldowns.GetValue(name, cd) && GetGameTime() < cd)
		{
			return false;
		}
		
		if (g_szCurrentEnemyGroup[0])
		{
			char group[64];
			this.GetGroup(group, sizeof(group));
			if (group[0] && StrContainsEx(group, g_szCurrentEnemyGroup, false) == -1)
			{
				return false;
			}
		}

		return true;
	}
	
	public int GetTotalActive()
	{
		int count;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;
			
			if (IsEnemy(i) && Enemy(i).Index == this.Index && IsPlayerAlive(i) 
				|| g_iPlayerEnemySpawnType[i] == this.Index || g_iPlayerBossSpawnType[i] == this.Index)
			{
				count++;
			}
		}
	
		return count;
	}
	
	public char[] GetInternalName()
	{
		// spcomp loves to complain about the way you return strings...
		char name[64];
		strcopy(name, sizeof(name), g_szLoadedEnemies[this.Index]);
		return name;
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

	public int GetGroup(char[] buffer, int size)
	{
		return strcopy(buffer, size, g_szEnemyGroup[this.Index]);
	}
	
	public void SetGroup(const char[] group)
	{
		strcopy(g_szEnemyGroup[this.Index], sizeof(g_szEnemyGroup[]), group);
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
	
	property bool AlwaysCrit
	{
		public get()			{ return g_bEnemyAlwaysCrit[this.Index]; }
		public set(bool value)	{ g_bEnemyAlwaysCrit[this.Index] = value; }
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
	
	property bool ShouldGlow
	{
		public get()			{ return g_bEnemyShouldGlow[this.Index]; }
		public set(bool value)	{ g_bEnemyShouldGlow[this.Index] = value; }
	}

	property bool NoCrits
	{
		public get()			{ return g_bEnemyNoCrits[this.Index]; }
		public set(bool value)	{ g_bEnemyNoCrits[this.Index] = value; }
	}

	property bool EyeGlow
	{
		public get()			{ return g_bEnemyEyeGlow[this.Index]; }
		public set(bool value)	{ g_bEnemyEyeGlow[this.Index] = value; }
	}
	
	property bool CustomEyeGlow
	{
		public get()			{ return g_bEnemyCustomEyeGlow[this.Index]; }
		public set(bool value)	{ g_bEnemyCustomEyeGlow[this.Index] = value; }
	}
	
	property bool EngineSound
	{
		public get()			{ return g_bEnemyEngineIdleSound[this.Index]; }
		public set(bool value)	{ g_bEnemyEngineIdleSound[this.Index] = value; }
	}

	property bool SuicideBomber
	{
		public get()			{ return g_bEnemySuicideBomber[this.Index]; }
		public set(bool value)	{ g_bEnemySuicideBomber[this.Index] = value; }
	}
	
	property bool SuicideBombBusterSounds
	{
		public get()			{ return g_bEnemySuicideBombBusterSounds[this.Index]; }
		public set(bool value)	{ g_bEnemySuicideBombBusterSounds[this.Index] = value; }
	}

	property bool SuicideBombDamageFalloff
	{
		public get()			{ return g_bEnemySuicideBombDamageFalloff[this.Index]; }
		public set(bool value)	{ g_bEnemySuicideBombDamageFalloff[this.Index] = value; }
	}
	
	property bool SuicideBombFriendlyFire
	{
		public get()			{ return g_bEnemySuicideBombFriendlyFire[this.Index]; }
		public set(bool value)	{ g_bEnemySuicideBombFriendlyFire[this.Index] = value; }
	}
	
	property float SuicideBombDamage
	{
		public get()			{ return g_flEnemySuicideBombDamage[this.Index]; }
		public set(float value)	{ g_flEnemySuicideBombDamage[this.Index] = value; }
	}
	
	property float SuicideBombRange
	{
		public get()			{ return g_flEnemySuicideBombRange[this.Index]; }
		public set(float value)	{ g_flEnemySuicideBombRange[this.Index] = value; }
	}
	
	property float SuicideBombDelay
	{
		public get()			{ return g_flEnemySuicideBombDelay[this.Index]; }
		public set(float value)	{ g_flEnemySuicideBombDelay[this.Index] = value; }
	}
	
	property float BaseCarriedCash
	{
		public get()			{ return g_flEnemyBaseCarriedCash[this.Index]; }
		public set(float value)	{ g_flEnemyBaseCarriedCash[this.Index] = value; }
	}

	property ArrayList BotTags
	{
		public get()				{ return g_hEnemyBotTags[this.Index]; }
		public set(ArrayList value)	{ g_hEnemyBotTags[this.Index] = value; }
	}
	
	property bool BotUberOnSight
	{
		public get()			{ return g_bEnemyBotUberOnSight[this.Index]; }
		public set(bool value)	{ g_bEnemyBotUberOnSight[this.Index] = value; }
	}
	
	property bool BotScavengerAI
	{
		public get()			{ return g_bEnemyBotScavengerAI[this.Index]; }
		public set(bool value)	{ g_bEnemyBotScavengerAI[this.Index] = value; }
	}
	
	property bool BotScavengerIgnoreEnemies
	{
		public get()			{ return g_bEnemyBotScavengerIgnoreEnemies[this.Index]; }
		public set(bool value)	{ g_bEnemyBotScavengerIgnoreEnemies[this.Index] = value; }
	}

	property int BotSkill
	{
		public get()			{ return g_iEnemyBotSkill[this.Index];  }
		public set(int value)	{ g_iEnemyBotSkill[this.Index] = value; }
	}

	property bool BotSkillNoOverride
	{
		public get()			{ return g_bEnemyBotSkillNoOverride[this.Index];  }
		public set(bool value)	{ g_bEnemyBotSkillNoOverride[this.Index] = value; }
	}
	
	property int BotBehaviorAttributes
	{
		public get()			{ return g_iEnemyBotBehaviorAttributes[this.Index];  }
		public set(int value)	{ g_iEnemyBotBehaviorAttributes[this.Index] = value; }
	}
	
	property int BotDemoStickyDetCount
	{
		public get()			{ return g_iEnemyBotDemoStickyDetCount[this.Index];  }
		public set(int value)	{ g_iEnemyBotDemoStickyDetCount[this.Index] = value; }
	}
	
	property int BotForcedWeaponSlot
	{
		public get()			{ return g_iEnemyBotForcedWeaponSlot[this.Index];  }
		public set(int value)	{ g_iEnemyBotForcedWeaponSlot[this.Index] = value; }
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
	
	property bool BotAlwaysAttack
	{
		public get()			{ return g_bEnemyBotAlwaysAttack[this.Index];  }
		public set(bool value)	{ g_bEnemyBotAlwaysAttack[this.Index] = value; }
	}
	
	property float BotMeleeDistance
	{
		public get()			{ return g_flEnemyBotMeleeDistance[this.Index];  }
		public set(float value)	{ g_flEnemyBotMeleeDistance[this.Index] = value; }
	}
	
	property float BotMaxVisionRange
	{
		public get()			{ return g_flEnemyBotMaxVisionRange[this.Index];  }
		public set(float value)	{ g_flEnemyBotMaxVisionRange[this.Index] = value; }
	}

	property bool BotAlwaysJump
	{
		public get()			{ return g_bEnemyBotAlwaysJump[this.Index];  }
		public set(bool value)	{ g_bEnemyBotAlwaysJump[this.Index] = value; }
	}
	
	property int WeaponCount
	{
		public get() 			{ return g_iEnemyWeaponAmount[this.Index]; }
		public set(int value)	{ g_iEnemyWeaponAmount[this.Index] = value; }
	}
	
	property int ActiveLimit
	{
		public get() 			{ return g_iEnemyActiveLimit[this.Index]; }
		public set(int value)	{ g_iEnemyActiveLimit[this.Index] = value; }
	}

	property int SpawnLimit
	{
		public get() 			{ return g_iEnemySpawnLimit[this.Index]; }
		public set(int value)	{ g_iEnemySpawnLimit[this.Index] = value; }
	}

	property float SpawnCooldown
	{
		public get()			{ return g_flEnemySpawnCooldown[this.Index]; }
		public set(float value)	{ g_flEnemySpawnCooldown[this.Index] = value; }
	}
	
	property float ItemDamageModifier
	{
		public get()			{ return g_flEnemyItemDamageModifier[this.Index]; }
		public set(float value)	{ g_flEnemyItemDamageModifier[this.Index] = value; }
	}
	
	public void SetEyeGlowColor(const int color[3])
	{
		g_iEnemyEyeGlowColor[this.Index][0] = color[0];
		g_iEnemyEyeGlowColor[this.Index][1] = color[1];
		g_iEnemyEyeGlowColor[this.Index][2] = color[2];
	}
	
	public void GetEyeGlowColor(int color[3])
	{
		color[0] = g_iEnemyEyeGlowColor[this.Index][0];
		color[1] = g_iEnemyEyeGlowColor[this.Index][1];
		color[2] = g_iEnemyEyeGlowColor[this.Index][2];
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

	public bool WeaponStartWithEmptyClip(int slot)
	{
		return g_bEnemyWeaponStartWithEmptyClip[this.Index][slot];
	}

	public void SetWeaponStartWithEmptyClip(int slot, bool value)
	{
		g_bEnemyWeaponStartWithEmptyClip[this.Index][slot] = value;
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
	
	public int GetScriptCode(char[] buffer, int size)
	{
		return strcopy(buffer, size, g_szEnemyScriptCode[this.Index]);
	}
	
	public void SetScriptCode(const char[] code)
	{
		strcopy(g_szEnemyScriptCode[this.Index], sizeof(g_szEnemyScriptCode[]), code);
	}
	
	property ArrayList Scripts
	{
		public get()				{ return g_hEnemyScripts[this.Index]; }
		public set(ArrayList value)	{g_hEnemyScripts[this.Index] = value; }
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

	public void DoSuicideBomb(int client)
	{
		if (!TF2_IsPlayerInCondition(client, TFCond_Taunting))
		{
			// make sure we are actually taunting before anything
			return;
		}

		TF2Attrib_AddCustomPlayerAttribute(client, "increased air control", 0.0);
		TF2Attrib_AddCustomPlayerAttribute(client, "no_jump", 1.0);
		TF2Attrib_AddCustomPlayerAttribute(client, "no_duck", 1.0);
		TF2Attrib_AddCustomPlayerAttribute(client, "no_attack", 1.0);
		TF2Attrib_AddCustomPlayerAttribute(client, "move speed penalty", 0.0);
		ForceSpeedUpdate(client);
		TF2_AddCondition(client, TFCond_FreezeInput);
		TF2_AddCondition(client, TFCond_UberchargedHidden);
		TF2_AddCondition(client, TFCond_ImmuneToPushback);
		if (this.SuicideBombBusterSounds)
		{
			EmitGameSoundToAll("MVM.SentryBusterSpin", client);
		}
		
		CreateTimer(this.SuicideBombDelay, Timer_SuicideBomb, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

static void Timer_SuicideBomb(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)) || !IsPlayerAlive(client))
		return;
	
	Enemy enemy = Enemy(client);
	if (enemy == NULL_ENEMY || !enemy.SuicideBomber)
		return;
	
	float pos[3];
	GetEntPos(client, pos, true);
	TE_TFParticle("fireSmokeExplosion", pos);
	SetEntityHealth(client, 1);
	TF2_RemoveCondition(client, TFCond_PreventDeath);
	TF2_RemoveCondition(client, TFCond_UberchargedHidden);
	UTIL_ScreenShake(pos, 10.0, 5.0, 4.0, 1000.0, SHAKE_START, true);
	EmitSoundToAll(SND_SENTRYBUSTER_BOOM, client, _, SNDLEVEL_SCREAMING);
	DoRadiusDamage(client, client, pos, _, enemy.SuicideBombDamage, DMG_BLAST|DMG_PREVENT_PHYSICS_FORCE,
		enemy.SuicideBombRange, enemy.SuicideBombDamageFalloff ? 0.3 : 1.0, _, _, _, _, _, enemy.SuicideBombFriendlyFire);
	
	FakeClientCommand(client, "explode");
}

Enemy EnemyByIndex(int index)
{
	return view_as<Enemy>(index);
}

void LoadEnemiesFromPack(const char[] config, bool bosses=false, bool reset=false)
{
	KeyValues enemyKey = bosses ? CreateKeyValues("bosses") : CreateKeyValues("enemies");
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "%s/%s.cfg", ConfigPath, config);
	if (!enemyKey.ImportFromFile(path))
	{
		LogError("[LoadEnemiesFromPack] File %s does not exist", path);
		return;
	}
	
	if (reset)
		g_iEnemyCount = 0;
	
	bool firstKey;
	char sectionName[64];
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
		PrintToServer("[RF2] Found enemy type: %s", g_szLoadedEnemies[e]);
		
		// TF class, health, and speed
		enemy.BaseHealth = enemyKey.GetNum("health", 150);
		enemy.BaseSpeed = enemyKey.GetFloat("speed", 300.0);
		char classType[16];
		enemyKey.GetString("class", classType, sizeof(classType), "");
		enemy.Class = TF2_GetClass(classType);
		if (enemy.Class == TFClass_Unknown)
		{
			enemy.Class = view_as<TFClassType>(enemyKey.GetNum("class", 1));
		}

		// name, model, description
		enemyKey.GetString("name", g_szEnemyName[e], sizeof(g_szEnemyName[]), "unnamed");
		enemyKey.GetString("group", g_szEnemyGroup[e], sizeof(g_szEnemyGroup[]));
		enemy.ModelScale = enemyKey.GetFloat("model_scale", enemy.IsBoss ? 1.75 : 1.0);
		enemyKey.GetString("model", g_szEnemyModel[e], sizeof(g_szEnemyModel[]));
		if (!g_szEnemyModel[e][0])
		{
			// default to class based model
			switch (enemy.Class)
			{
				case TFClass_Scout: strcopy(g_szEnemyModel[e], sizeof(g_szEnemyModel[]), 
					enemy.IsBoss ? MODEL_GIANT_SCOUT : MODEL_BOT_SCOUT);
				
				case TFClass_Soldier: strcopy(g_szEnemyModel[e], sizeof(g_szEnemyModel[]), 
					enemy.IsBoss ? MODEL_GIANT_SOLDIER : MODEL_BOT_SOLDIER);

				case TFClass_Pyro: strcopy(g_szEnemyModel[e], sizeof(g_szEnemyModel[]), 
					enemy.IsBoss ? MODEL_GIANT_PYRO : MODEL_BOT_PYRO);

				case TFClass_DemoMan: strcopy(g_szEnemyModel[e], sizeof(g_szEnemyModel[]), 
					enemy.IsBoss ? MODEL_GIANT_DEMO : MODEL_BOT_DEMO);

				case TFClass_Heavy: strcopy(g_szEnemyModel[e], sizeof(g_szEnemyModel[]), 
					enemy.IsBoss ? MODEL_GIANT_HEAVY : MODEL_BOT_HEAVY);
				
				case TFClass_Engineer: strcopy(g_szEnemyModel[e], sizeof(g_szEnemyModel[]), MODEL_BOT_ENGINEER);
				case TFClass_Medic: strcopy(g_szEnemyModel[e], sizeof(g_szEnemyModel[]), MODEL_BOT_MEDIC);
				case TFClass_Sniper: strcopy(g_szEnemyModel[e], sizeof(g_szEnemyModel[]), MODEL_BOT_SNIPER);
				case TFClass_Spy: strcopy(g_szEnemyModel[e], sizeof(g_szEnemyModel[]), MODEL_BOT_SPY);
			}
		}

		if (FileExists(g_szEnemyModel[e], true))
		{
			AddModelToDownloadsTable(g_szEnemyModel[e]);
		}
		else
		{
			LogError("[LoadEnemiesFromPack] Model %s for enemy \"%s\" could not be found!", g_szEnemyModel[e], g_szLoadedEnemies[e]);
			enemy.SetModel(MODEL_ERROR);
		}
		
		enemy.BotSkill = enemyKey.GetNum("tf_bot_difficulty", TFBotSkill_Normal);
		enemy.BotSkillNoOverride = asBool(enemyKey.GetNum("tf_bot_difficulty_no_override"));
		enemy.BotBehaviorAttributes = enemyKey.GetNum("tf_bot_behavior_flags", 0);
		enemy.BotDemoStickyDetCount = enemyKey.GetNum("tf_bot_demo_sticky_det_count", 1);
		enemy.BotForcedWeaponSlot = enemyKey.GetNum("tf_bot_forced_weapon_slot", -1);
		enemy.BotAlwaysJump = asBool(enemyKey.GetNum("tf_bot_constant_jump", false));
		enemy.BotAggressive = asBool(enemyKey.GetNum("tf_bot_aggressive", false));
		enemy.BotRocketJump = asBool(enemyKey.GetNum("tf_bot_rocketjump", false));
		enemy.BotHoldFireReload = asBool(enemyKey.GetNum("tf_bot_hold_fire_until_reload", false));
		enemy.BotAlwaysAttack = asBool(enemyKey.GetNum("tf_bot_always_attack", false));
		enemy.BotMeleeDistance = enemyKey.GetFloat("tf_bot_melee_distance");
		enemy.BotMaxVisionRange = enemyKey.GetFloat("tf_bot_max_vision_range", 6000.0);
		enemy.BotUberOnSight = asBool(enemyKey.GetNum("tf_bot_uber_on_sight", false));
		enemy.BotScavengerAI = asBool(enemyKey.GetNum("tf_bot_scavenger_ai", false));
		enemy.BotScavengerIgnoreEnemies = asBool(enemyKey.GetNum("tf_bot_scavenger_ignore_enemies", true));
		enemy.BaseCarriedCash = enemyKey.GetFloat("base_carried_cash");
		enemy.XPAward = enemyKey.GetFloat("xp_award", 15.0);
		enemy.CashAward = enemyKey.GetFloat("cash_award", 20.0);
		enemy.Weight = enemyKey.GetNum("weight", 50);
		enemy.ActiveLimit = enemyKey.GetNum("active_limit");
		enemy.SpawnLimit = enemyKey.GetNum("spawn_limit");
		enemy.SpawnCooldown = enemyKey.GetFloat("spawn_cooldown");
		enemy.FullRage = asBool(enemyKey.GetNum("full_rage", false));
		enemy.NoBleeding = asBool(enemyKey.GetNum("no_bleeding", true));
		enemy.ShouldGlow = asBool(enemyKey.GetNum("glow", false));
		enemy.NoCrits = asBool(enemyKey.GetNum("no_crits", false));
		enemy.EyeGlow = asBool(enemyKey.GetNum("eye_glow", true));
		int dummy;
		if (enemyKey.GetNameSymbol("eye_glow_color", dummy))
		{
			enemyKey.GetColor("eye_glow_color", 
				g_iEnemyEyeGlowColor[e][0], 
				g_iEnemyEyeGlowColor[e][1], 
				g_iEnemyEyeGlowColor[e][2],
				dummy);
				
			enemy.CustomEyeGlow = true;
		}
		
		enemy.EngineSound = asBool(enemyKey.GetNum("engine_idle_sound", enemy.IsBoss));
		enemy.SuicideBomber = enemyKey.JumpToKey("suicide_bomber");
		if (enemy.SuicideBomber)
		{
			enemy.SuicideBombDamage = enemyKey.GetFloat("damage", 600.0);
			enemy.SuicideBombRange = enemyKey.GetFloat("range", 300.0);
			enemy.SuicideBombDelay = enemyKey.GetFloat("delay", 2.0);
			enemy.SuicideBombFriendlyFire = asBool(enemyKey.GetNum("friendly_fire", 1));
			enemy.SuicideBombBusterSounds = asBool(enemyKey.GetNum("use_buster_sounds", 1));
			enemy.SuicideBombDamageFalloff = asBool(enemyKey.GetNum("use_damage_falloff", 1));
			enemyKey.GoBack();
		}
		
		if (enemy.Scripts)
		{
			delete enemy.Scripts;
		}
		
		enemyKey.GetString("script_code", g_szEnemyScriptCode[e], sizeof(g_szEnemyScriptCode[]));
		if (enemyKey.JumpToKey("scripts"))
		{
			enemy.Scripts = new ArrayList(PLATFORM_MAX_PATH);
			int i = 1;
			char key[8], script[PLATFORM_MAX_PATH], scriptPath[PLATFORM_MAX_PATH];
			for ( ;; )
			{
				IntToString(i, key, sizeof(key));
				enemyKey.GetString(key, script, sizeof(script));
				if (script[0])
				{
					FormatEx(scriptPath, sizeof(scriptPath), "scripts/vscripts/%s", script);
					if (!FileExists(scriptPath))
					{
						LogError("[LoadEnemiesFromPack] The script file \"%s\" for enemy \"%s\" does not exist", 
							script, g_szLoadedEnemies[e]);
							
						i++;
						continue;
					}
					
					enemy.Scripts.PushString(script);
				}
				else
				{
					break;
				}
				
				i++;
			}

			enemyKey.GoBack();
		}
		
		if (enemy.BotTags)
		{
			delete enemy.BotTags;
		}

		if (enemyKey.JumpToKey("tags"))
		{
			enemy.BotTags = new ArrayList(64);
			int i = 1;
			char key[8], tag[64];
			for ( ;; )
			{
				IntToString(i, key, sizeof(key));
				enemyKey.GetString(key, tag, sizeof(tag));
				if (tag[0])
				{
					enemy.BotTags.PushString(tag);
				}
				else
				{
					break;
				}
				
				i++;
			}

			enemyKey.GoBack();
		}
		
		enemy.WeaponCount = 0;
		for (int w = 0; w < TF_WEAPON_SLOTS; w++)
		{
			g_szEnemyWeaponAttributes[e][w] = "";
		}
		
		for (int w = 0; w < TF_WEAPON_SLOTS; w++)
		{
			FormatEx(sectionName, sizeof(sectionName), "weapon%i", w+1);
			if (!enemyKey.JumpToKey(sectionName))
			{
				break;
			}
			
			enemyKey.GetString("classname", g_szEnemyWeaponName[e][w], sizeof(g_szEnemyWeaponName[][]), "null");
			if (enemyKey.JumpToKey("attributes"))
			{
				char key[128], val[128];
				for (int i = 1; i > 0; i++)
				{
					if (i == 1 && !enemyKey.GotoFirstSubKey(false))
					{
						break;
					}
					
					enemyKey.GetSectionName(key, sizeof(key));
					int id = AttributeNameToDefIndex(key);
					if (id != -1)
					{
						enemyKey.GetString(NULL_STRING, val, sizeof(val));
						if (i == 1)
						{
							Format(g_szEnemyWeaponAttributes[e][w], sizeof(g_szEnemyWeaponAttributes[][]),
								"%s%d = %s", g_szEnemyWeaponAttributes[e][w], id, val);
						}
						else
						{
							Format(g_szEnemyWeaponAttributes[e][w], sizeof(g_szEnemyWeaponAttributes[][]),
								"%s ; %d = %s", g_szEnemyWeaponAttributes[e][w], id, val);
						}
						
					}
					else
					{
						LogError("[LoadEnemiesFromPack] Invalid attribute '%s' in '%s'", key, config);
					}

					if (i >= 16)
					{
						LogError("[WARNING] Maximum number of attributes on a weapon exceeded (%s: %s)", 
						enemy.GetInternalName(), sectionName);
					}
					
					if (!enemyKey.GotoNextKey(false))
					{
						enemyKey.GoBack();
						break;
					}
				}
				
				TrimString(g_szEnemyWeaponAttributes[e][w]);
				enemyKey.GoBack();
			}
			
			enemy.SetWeaponIndex(w, enemyKey.GetNum("index", 5));
			enemy.SetWeaponVisible(w, asBool(enemyKey.GetNum("visible", true)));
			enemy.SetWeaponUseStaticAtts(w, !asBool(enemyKey.GetNum("strip_attributes", false)));
			enemy.SetWeaponIsFirstActive(w, asBool(enemyKey.GetNum("active_weapon", false)));
			enemy.SetWeaponStartWithEmptyClip(w, asBool(enemyKey.GetNum("empty_clip", false)));
			enemy.WeaponCount++;
			enemyKey.GoBack();
		}
		
		enemy.WearableCount = 0;
		for (int w = 0; w < MAX_WEARABLES; w++)
		{
			g_szEnemyWearableAttributes[e][w] = "";
		}

		for (int w = 0; w < MAX_WEARABLES; w++)
		{
			FormatEx(sectionName, sizeof(sectionName), "wearable%i", w+1);
			if (!enemyKey.JumpToKey(sectionName))
				continue;
			
			if (enemyKey.JumpToKey("attributes"))
			{
				char key[128], val[128];
				for (int i = 1; i > 0; i++)
				{
					if (i == 1 && !enemyKey.GotoFirstSubKey(false))
					{
						break;
					}
					
					enemyKey.GetSectionName(key, sizeof(key));
					int id = AttributeNameToDefIndex(key);
					if (id != -1)
					{
						enemyKey.GetString(NULL_STRING, val, sizeof(val));
						if (i == 1)
						{
							Format(g_szEnemyWearableAttributes[e][w], sizeof(g_szEnemyWearableAttributes[][]),
								"%s%d = %s", g_szEnemyWearableAttributes[e][w], id, val);
						}
						else
						{
							Format(g_szEnemyWearableAttributes[e][w], sizeof(g_szEnemyWearableAttributes[][]),
								"%s ; %d = %s", g_szEnemyWearableAttributes[e][w], id, val);
						}
					}
					else
					{
						LogError("[LoadEnemiesFromPack] Invalid attribute '%s' in '%s'", key, config);
					}
					
					if (!enemyKey.GotoNextKey(false))
					{
						enemyKey.GoBack();
						break;
					}
				}
				
				TrimString(g_szEnemyWearableAttributes[e][w]);
				enemyKey.GoBack();
			}
			
			enemyKey.GetString("classname", g_szEnemyWearableName[e][w], sizeof(g_szEnemyWearableName[][]), "tf_wearable");
			enemy.SetWearableIndex(w, enemyKey.GetNum("index", 5));
			enemy.SetWearableVisible(w, asBool(enemyKey.GetNum("visible", true)));
			enemy.SetWearableUseStaticAtts(w, !asBool(enemyKey.GetNum("strip_attributes", false)));
			enemy.WearableCount++;
			enemyKey.GoBack();
		}
		
		for (int i = 1; i < GetTotalItems(); i++)
		{
			enemy.SetItem(i, 0);
		}
		
		int itemId;
		if (enemyKey.JumpToKey("items"))
		{
			if (enemyKey.GotoFirstSubKey(false))
			{
				for ( ;; )
				{
					enemyKey.GetSectionName(sectionName, sizeof(sectionName));
					itemId = GetItemFromSectionName(sectionName);
					if (itemId > Item_Null)
					{
						enemy.SetItem(itemId, enemyKey.GetNum(NULL_STRING));
					}
					
					if (!enemyKey.GotoNextKey(false))
					{
						break;
					}
				}

				enemyKey.GoBack();
			}

			enemyKey.GoBack();
		}
		
		enemy.ItemDamageModifier = enemyKey.GetFloat("item_damage_modifier", 1.0);

		bool noGiantLines = enemy.IsBoss && (enemy.Class == TFClass_Sniper || enemy.Class == TFClass_Medic 
			|| enemy.Class == TFClass_Engineer || enemy.Class == TFClass_Spy);
		
		enemy.VoiceType = enemyKey.GetNum("voice_type", VoiceType_Robot);
		enemy.VoicePitch = enemyKey.GetNum("voice_pitch", noGiantLines ? SNDPITCH_LOW : SNDPITCH_NORMAL);
		enemy.FootstepType = enemyKey.GetNum("footstep_type", enemy.IsBoss ? FootstepType_GiantRobot : FootstepType_Robot);
		enemy.AllowSelfDamage = asBool(enemyKey.GetNum("allow_self_damage", enemy.IsBoss ? false : true));
		enemy.HeadScale = enemyKey.GetFloat("head_scale", enemy.IsBoss ? 1.5 : 1.0);
		enemy.TorsoScale = enemyKey.GetFloat("torso_scale", 1.0);
		enemy.HandScale = enemyKey.GetFloat("hand_scale", 1.0);
		enemy.AlwaysCrit = asBool(enemyKey.GetNum("always_crit"));
		enemyKey.GetString("spawn_conditions", g_szEnemyConditions[e], sizeof(g_szEnemyConditions[]), "");
		
		if (enemy.IsBoss)
		{
			enemy.BossGiantWeaponSounds = asBool(enemyKey.GetNum("use_giant_weapon_sounds", true));
			enemy.BossFootstepInterval = enemyKey.GetFloat("giant_footstep_interval", enemy.Class == TFClass_Scout ? 0.18 : 0.5);
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
// Optionally can retrieve the internal name.
int GetRandomEnemy(bool getName=false, char[] buffer="", int size=0)
{
	ArrayList enemyList = new ArrayList();
	for (int i = 0; i < g_iEnemyCount; i++)
	{
		Enemy enemy = EnemyByIndex(i);
		if (enemy.IsBoss || enemy.Weight <= 0 || !enemy.IsAllowedToSpawn())
			continue;
		
		for (int j = 1; j <= enemy.Weight; j++)
			enemyList.Push(i);
	}
	
	if (enemyList.Length <= 0)
	{
		delete enemyList;
		return -1;
	}

	Enemy selected = EnemyByIndex(enemyList.Get(GetRandomInt(0, enemyList.Length-1)));
	if (getName)
	{
		strcopy(buffer, size, selected.GetInternalName());
	}
	
	delete enemyList;
	return selected.Index;
}

// Returns the index of a currently-loaded boss at random based on weight.
// Optionally can retrieve the internal name.
int GetRandomBoss(bool getName=false, char[] buffer="", int size=0)
{
	int scavengerLordLevel = g_cvScavengerLordSpawnLevel.IntValue;
	if (scavengerLordLevel > 0 && g_iEnemyLevel >= scavengerLordLevel*10)
	{
		// start randomly replacing bosses with Scavenger Lord once we get deep enough into enemy level
		int chanceMax = scavengerLordLevel * 200;
		if (RandChanceInt(0, chanceMax, imin(g_iEnemyLevel, chanceMax/2)))
		{
			Enemy scavengerLord = Enemy.FindByInternalName("scavenger_lord");
			if (scavengerLord != NULL_ENEMY)
			{
				return scavengerLord.Index;
			}
		}
	}
	
	ArrayList bossList = new ArrayList();
	for (int i = 0; i < g_iEnemyCount; i++)
	{
		Enemy enemy = EnemyByIndex(i);
		if (!enemy.IsBoss || enemy.Weight <= 0 || !enemy.IsAllowedToSpawn())
			continue;

		for (int j = 1; j <= enemy.Weight; j++)
			bossList.Push(i);
	}
	
	if (bossList.Length <= 0)
	{
		delete bossList;
		return -1;
	}
	
	Enemy selected = EnemyByIndex(bossList.Get(GetRandomInt(0, bossList.Length-1)));
	if (getName)
	{
		strcopy(buffer, size, selected.GetInternalName());
	}
	
	delete bossList;
	return selected.Index;
}

bool SpawnEnemy(int client, int type, const float pos[3]=OFF_THE_MAP, float minDist=-1.0, float maxDist=-1.0, bool recursive=true, int recurseCount=0)
{
	g_bPlayerInSpawnQueue[client] = true;
	Enemy enemy = EnemyByIndex(type);
	
	if (IsPlayerAlive(client))
	{
		SilentlyKillPlayer(client);
	}
	
	ChangeClientTeam(client, TEAM_ENEMY);
	float mins[3] = PLAYER_MINS;
	float maxs[3] = PLAYER_MAXS;
	ScaleVector(mins, enemy.ModelScale);
	ScaleVector(maxs, enemy.ModelScale);
	CNavArea area;
	float spawnPos[3];
	bool useSpawnPoints = !g_bPlayerSpawnedByTeleporter[client] && GetRF2GameRules().UseTeamSpawnForEnemies;
	if (!useSpawnPoints)
	{
		float checkPos[3];
		bool player;
		if (CompareVectors(pos, OFF_THE_MAP))
		{
			int randomSurvivor = GetRandomPlayer(TEAM_SURVIVOR);
			if (IsValidClient(randomSurvivor))
			{
				GetEntPos(randomSurvivor, checkPos);
				player = true;
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
		
		float zOffset = 30.0 * enemy.ModelScale;
		// Engineers spawn further away from players
		float extraDist = player && enemy.Class == TFClass_Engineer ? 3000.0 : 0.0;
		float minSpawnDistance = minDist < 0.0 ? g_cvEnemyMinSpawnDistance.FloatValue : minDist;
		float maxSpawnDistance = maxDist < 0.0 ? g_cvEnemyMaxSpawnDistance.FloatValue + extraDist : maxDist;
		maxSpawnDistance += float(recurseCount) * 300.0;
		area = GetSpawnPoint(checkPos, spawnPos, minSpawnDistance, maxSpawnDistance, TEAM_SURVIVOR, true, mins, maxs, MASK_PLAYERSOLID, zOffset);
	}
	
	if (!area && !useSpawnPoints)
	{
		if (recursive)
		{
			// try again next frame
			DataPack pack;
			CreateDataTimer(0.3, Timer_SpawnEnemyRecursive, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(GetClientUserId(client));
			pack.WriteCell(type);
			pack.WriteFloat(pos[0]);
			pack.WriteFloat(pos[1]);
			pack.WriteFloat(pos[2]);
			pack.WriteFloat(minDist);
			pack.WriteFloat(maxDist);
			pack.WriteCell(recurseCount+1);
		}
		
		return false;
	}
	
	g_bPlayerInSpawnQueue[client] = false;
	g_iPlayerEnemyType[client] = type;
	g_iPlayerBaseHealth[client] = enemy.BaseHealth;
	g_flPlayerMaxSpeed[client] = enemy.BaseSpeed;
	SetPlayerCash(client, enemy.BaseCarriedCash * RF2_Object_Crate.GetCostMultiplier());
	TF2_SetPlayerClass(client, enemy.Class);
	TF2_RespawnPlayer(client);
	if (!useSpawnPoints)
	{
		TeleportEntity(client, spawnPos);
	}
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_flEnemyModelScale[type]);
	TF2_AddCondition(client, TFCond_UberchargedCanteen, 1.0);
	TF2_AddCondition(client, TFCond_FreezeInput, 1.0);
	if (enemy.SpawnCooldown > 0.0)
	{
		g_hEnemyTypeCooldowns.SetValue(enemy.GetInternalName(), GetGameTime()+enemy.SpawnCooldown);
	}

	if (enemy.SpawnLimit > 0)
	{
		int spawnTotal;
		g_hEnemyTypeNumSpawned.GetValue(enemy.GetInternalName(), spawnTotal);
		g_hEnemyTypeNumSpawned.SetValue(enemy.GetInternalName(), spawnTotal+1);
	}
	
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
	int activeWeapon = INVALID_ENT;
	int weapon;
	for (int i = 0; i < enemy.WeaponCount; i++)
	{
		enemy.GetWeaponName(i, name, sizeof(name));
		enemy.GetWeaponAttributes(i, attributes, sizeof(attributes));
		weapon = CreateWeapon(client, name, enemy.WeaponIndex(i), attributes, enemy.WeaponUseStaticAtts(i), enemy.WeaponVisible(i));
		if (IsValidEntity2(weapon))
		{
			if (activeWeapon == INVALID_ENT && enemy.WeaponIsFirstActive(i))
			{
				activeWeapon = weapon;
			}

			if (enemy.WeaponStartWithEmptyClip(i))
			{
				if (IsEnergyWeapon(weapon))
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flEnergy", 0.0);
				}
				else
				{
					SetEntProp(weapon, Prop_Send, "m_iClip1", 0);
				}
			}
		}
	}
	
	if (activeWeapon != INVALID_ENT)
	{
		for (int i = 0; i < TF_WEAPON_SLOTS; i++)
		{
			if (GetPlayerWeaponSlot(client, i) == activeWeapon)
			{
				ForceWeaponSwitch(client, i, true);
				break;
			}
		}
	}
	
	for (int i = 1; i < GetTotalItems(); i++)
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
		
		if (wearable != INVALID_ENT)
			g_bDontRemoveWearable[wearable] = true;
	}
	
	if (enemy.FullRage)
	{
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
	}
	
	if (enemy.ShouldGlow)
	{
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", true);
	}

	if (enemy.FootstepType == FootstepType_GiantRobot && !g_cvOldGiantFootsteps.BoolValue)
	{
		TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
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
	
	if (enemy.AlwaysCrit || IsCurseActive(Curse_Annihilation))
	{
		TF2_AddCondition(client, TFCond_CritCanteen);
	}
	
	g_iPlayerVoiceType[client] = enemy.VoiceType;
	g_iPlayerVoicePitch[client] = enemy.VoicePitch;
	g_iPlayerFootstepType[client] = enemy.FootstepType;
	SetEntPropFloat(client, Prop_Send, "m_flHeadScale", enemy.HeadScale);
	SetEntPropFloat(client, Prop_Send, "m_flTorsoScale", enemy.TorsoScale);
	SetEntPropFloat(client, Prop_Send, "m_flHandScale", enemy.HandScale);
	if (g_bPlayerSpawnedByTeleporter[client])
	{
		TE_TFParticle("eyeboss_tp_player", spawnPos);
		TF2_AddCondition(client, TFCond_TeleportedGlow, 15.0);
		g_bPlayerSpawnedByTeleporter[client] = false;
	}
	
	if (enemy.SuicideBomber)
	{
		if (IsFakeClient(client))
		{
			TFBot(client).AddFlag(TFBOTFLAG_SUICIDEBOMBER);
		}
		
		TF2_AddCondition(client, TFCond_PreventDeath);
		if (enemy.SuicideBombBusterSounds)
		{
			EmitGameSoundToAll("MVM.SentryBusterIntro", client);
			EmitGameSoundToAll("MVM.SentryBusterLoop", client);
		}
	}
	
	if (enemy.Scripts)
	{
		char script[PLATFORM_MAX_PATH];
		for (int i = 0; i < enemy.Scripts.Length; i++)
		{
			enemy.Scripts.GetString(i, script, sizeof(script));
			SetVariantString(script);
			AcceptEntityInput(client, "RunScriptFile");
			DebugMsg("Running script file %s", script);
		}
	}
	
	char code[4096];
	enemy.GetScriptCode(code, sizeof(code));
	if (code[0])
	{
		DebugMsg("Running script code %s", code);
		RunScriptCode(client, code);
	}
	
	if (IsFakeClient(client))
	{
		if (!enemy.BotSkillNoOverride)
		{
			switch (RF2_GetDifficulty())
			{
				case DIFFICULTY_SCRAP:
				{
					TFBot(client).SetSkillLevel(TFBotSkill_Easy);
				}
				
				// Bots have more skill on higher difficulties
				case DIFFICULTY_STEEL:
				{
					if (enemy.BotSkill < TFBotSkill_Hard && enemy.BotSkill != TFBotSkill_Expert)
					{
						TFBot(client).SetSkillLevel(TFBotSkill_Hard);
					}
					else
					{
						TFBot(client).SetSkillLevel(enemy.BotSkill);
					}
				}
				
				case DIFFICULTY_TITANIUM, DIFFICULTY_AUSTRALIUM: TFBot(client).SetSkillLevel(TFBotSkill_Expert);
				default: TFBot(client).SetSkillLevel(enemy.BotSkill);
			}
			
			int skill = TFBot(client).GetSkillLevel();
			if (g_iEnemyLevel >= 300)
			{
				TFBot(client).SetSkillLevel(TFBotSkill_Expert);
			}
			else if (g_iEnemyLevel >= 150)
			{
				if (skill < TFBotSkill_Hard)
				{
					TFBot(client).SetSkillLevel(TFBotSkill_Hard);
				}
			}
			else if (g_iEnemyLevel >= 50)
			{
				if (skill < TFBotSkill_Normal)
				{
					TFBot(client).SetSkillLevel(TFBotSkill_Normal);
				}
			}
		}
		else
		{
			TFBot(client).SetSkillLevel(enemy.BotSkill);
		}
		
		enemy.BotBehaviorAttributes |= QUOTA_MANANGED;
		if (enemy.Class == TFClass_Engineer)
		{
			enemy.BotBehaviorAttributes |= REMOVE_ON_DEATH;
			enemy.BotBehaviorAttributes |= BECOME_SPECTATOR_ON_DEATH;
			enemy.BotBehaviorAttributes |= RETAIN_BUILDINGS;
		}
		
		if (enemy.BotBehaviorAttributes)
		{
			TFBot(client).BehaviorAttributes = enemy.BotBehaviorAttributes;
		}
		
		if (enemy.BotAggressive)
		{
			TFBot(client).AddFlag(TFBOTFLAG_AGGRESSIVE);
		}
		
		if (enemy.BotRocketJump)
		{
			TFBot(client).AddFlag(TFBOTFLAG_ROCKETJUMP);
		}
		
		if (enemy.BotScavengerAI)
		{
			TFBot(client).AddFlag(TFBOTFLAG_SCAVENGER);
		}
		
		if (enemy.BotHoldFireReload)
		{
			TFBot(client).AddFlag(TFBOTFLAG_HOLDFIRE);
		}

		if (enemy.BotAlwaysAttack)
		{
			TFBot(client).AddFlag(TFBOTFLAG_ALWAYSATTACK);
		}
		
		if (enemy.BotAlwaysJump)
		{
			TFBot(client).AddFlag(TFBOTFLAG_SPAMJUMP);
		}
		
		VScriptCmd cmd;
		cmd.Append(Format2("self.SetMaxVisionRangeOverride(%.0f)", enemy.BotMaxVisionRange));
		cmd.Run(client);
		if (enemy.BotTags)
		{
			char tag[64];
			for (int i = 0; i < enemy.BotTags.Length; i++)
			{
				VScriptCmd tagCmd;
				enemy.BotTags.GetString(i, tag, sizeof(tag));
				tagCmd.Append(Format2("self.AddBotTag(`%s`)", tag));
				tagCmd.Run(client);
			}
		}
	}
	
	if (enemy.EyeGlow)
	{
		float color[3];
		if (enemy.CustomEyeGlow)
		{
			color[0] = float(g_iEnemyEyeGlowColor[type][0]);
			color[1] = float(g_iEnemyEyeGlowColor[type][1]);
			color[2] = float(g_iEnemyEyeGlowColor[type][2]);
		}
		else
		{
			color = TFBot(client).GetSkillLevel() >= TFBotSkill_Hard ? {255.0, 180.0, 36.0} : {0.0, 240.0, 255.0};
		}
		
		if (enemy.IsBoss)
		{
			if (LookupEntityAttachment(client, "eye_boss_1"))
			{
				TE_TFParticle("bot_eye_glow", {0.0, 0.0, 0.0}, client, PATTACH_POINT_FOLLOW, "eye_boss_1", 
					false, true, color);
			}
			
			if (LookupEntityAttachment(client, "eye_boss_2"))
			{
				TE_TFParticle("bot_eye_glow", {0.0, 0.0, 0.0}, client, PATTACH_POINT_FOLLOW, "eye_boss_2", 
					false, true, color);
			}
		}
		else
		{
			if (LookupEntityAttachment(client, "eye_1"))
			{
				TE_TFParticle("bot_eye_glow", {0.0, 0.0, 0.0}, client, PATTACH_POINT_FOLLOW, "eye_1", 
					false, true, color);
			}
			
			if (LookupEntityAttachment(client, "eye_2"))
			{
				TE_TFParticle("bot_eye_glow", {0.0, 0.0, 0.0}, client, PATTACH_POINT_FOLLOW, "eye_2", 
					false, true, color);
			}
		}
	}
	
	if (enemy.EngineSound)
	{
		float center[3];
		GetEntPos(client, center, true);
		switch (enemy.Class)
		{
			case TFClass_Scout: EmitAmbientGameSound("MVM.GiantScoutLoop", center, client);
			case TFClass_Soldier: EmitAmbientGameSound("MVM.GiantSoldierLoop", center, client);
			case TFClass_Pyro: EmitAmbientGameSound("MVM.GiantPyroLoop", center, client);
			case TFClass_DemoMan: EmitAmbientGameSound("MVM.GiantDemomanLoop", center, client);
			case TFClass_Heavy: EmitAmbientGameSound("MVM.GiantHeavyLoop", center, client);
		}
	}
	
	return true;
}

bool SpawnBoss(int client, int type, const float pos[3]=OFF_THE_MAP, bool teleporterBoss=false, float minDist=-1.0, float maxDist=-1.0, bool recursive=true, int recurseCount=0)
{
	if (maxDist < 0.0)
	{
		if (teleporterBoss)
		{
			maxDist = GetCurrentTeleporter().Radius * 2.0;
		}
		else
		{
			maxDist = g_cvEnemyMaxSpawnDistance.FloatValue;
		}
	}
	
	maxDist += float(recurseCount) * 300.0;
	if (SpawnEnemy(client, type, pos, minDist, maxDist, false))
	{
		Enemy boss = EnemyByIndex(type);
		g_bPlayerIsTeleporterBoss[client] = teleporterBoss;
		if (boss.BossGiantWeaponSounds)
		{
			int weapon = GetPlayerWeaponSlot(client, 0);
			if (weapon != INVALID_ENT)
			{
				// trick game into playing MvM giant weapon sounds
				SetEntProp(weapon, Prop_Send, "m_iTeamNum", TF_TEAM_PVE_INVADERS_GIANTS);
			}
		}
		
		//SetEntProp(client, Prop_Send, "m_bGlowEnabled", teleporterBoss);
		//SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
		g_flPlayerGiantFootstepInterval[client] = boss.BossFootstepInterval;
		TF2Attrib_SetByName(client, "damage force reduction", 0.2);
		TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.2);
		TF2Attrib_SetByName(client, "increased jump height", 1.35);
		TF2Attrib_SetByName(client, "patient overheal penalty", 0.0);
		TF2Attrib_SetByName(client, "aiming movespeed increased", 10.0);
		
		if (teleporterBoss)
		{
			CreateHealthText(client, 100.0*boss.ModelScale, 20.0, g_szEnemyName[type]);
			OutlineTeleporterBosses();
		}
		
		if (strcmp2(boss.GetInternalName(), "scavenger_lord"))
		{
			int givenItems;
			int itemCount = imin(g_iEnemyLevel/g_cvScavengerLordLevelItemRatio.IntValue, g_cvScavengerLordMaxItems.IntValue);
			while (givenItems < itemCount)
			{
				int item = GetRandomItem(60, 30, 3, 7);
				if (g_bItemScavengerNoSpawnWith[item])
					continue;
				
				GiveItem(client, item);
				givenItems++;
			}
			
			// also equip a random strange item
			int randomStrange;
			for ( ;; )
			{
				randomStrange = GetRandomItemEx(Quality_Strange);
				if (!g_bItemScavengerNoSpawnWith[randomStrange] && g_bItemInDropPool[randomStrange])
				{
					break;
				}
			}
			
			GiveItem(client, randomStrange);
		}
		
		return true;
	}
	else if (recursive)
	{
		// try again next frame
		DataPack pack;
		CreateDataTimer(0.3, Timer_SpawnBossRecursive, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(GetClientUserId(client));
		pack.WriteCell(type);
		pack.WriteFloat(pos[0]);
		pack.WriteFloat(pos[1]);
		pack.WriteFloat(pos[2]);
		pack.WriteCell(teleporterBoss);
		pack.WriteFloat(minDist);
		pack.WriteFloat(maxDist);
		pack.WriteCell(recurseCount+1);
	}
	
	return false;
}

void SummonTeleporterBosses(RF2_Object_Teleporter teleporter)
{
	int bossCount = 1 + ((RF2_GetSurvivorCount()-1)/2) + RoundToFloor(g_flDifficultyCoeff/(g_cvSubDifficultyIncrement.FloatValue*2.5));
	bossCount = imin(imax(bossCount, 1), GetPlayersOnTeam(TEAM_ENEMY));
	ArrayList players = FindBestPlayersToSpawn(bossCount, true);
	float time;
	for (int i = 0; i < players.Length; i++)
	{
		int client = players.Get(i);
		g_bPlayerInSpawnQueue[client] = true;
		int randomBoss = GetRandomBoss();
		if (randomBoss == -1)
			continue;

		// don't spawn all the bosses at once, as it will cause client crashes if there are too many
		DataPack pack;
		CreateDataTimer(time, Timer_SpawnTeleporterBoss, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(GetClientUserId(client));
		pack.WriteCell(randomBoss);
		pack.WriteCell(teleporter.index);
		time += 0.1;
	}
	
	delete players;
	EmitSoundToAll(SND_BOSS_SPAWN);
}

ArrayList FindBestPlayersToSpawn(int count, bool bossRules=false)
{
	ArrayList players = new ArrayList();
	int retries;
	for ( ;; )
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (players.FindValue(i) != -1 || !IsClientInGame(i) || IsSpecBot(i))
				continue;
			
			if (IsScavengerLord(i))
				continue;
			
			// Don't use alive players until our first retry
			// Never use players in the spawn queue, players who are Teleporter bosses, or players not in Blue team
			if (IsPlayerAlive(i) && retries == 0 || g_bPlayerInSpawnQueue[i] || g_bPlayerIsTeleporterBoss[i] || GetClientTeam(i) != TEAM_ENEMY)
				continue;
			
			// Don't use alive bosses until our second retry
			if (retries < 2 && IsBoss(i))
				continue;

			// Don't use human players if we don't allow them
			if (!IsFakeClient(i) && !g_cvAllowHumansInBlue.BoolValue)
				continue;

			// Don't use human players with boss preference turned off until our second retry
			if (bossRules && retries < 2 && !IsFakeClient(i) && !GetCookieBool(i, g_coBecomeBoss))
				continue;
			
			players.Push(i);
			if (players.Length >= count)
			{
				return players;
			}
		}

		// if we don't have enough players to spawn, try again with less restrictions
		// First retry - use alive players, but not bosses
		// Second retry - use alive players, including bosses (but not teleporter bosses) and use players with boss preference turned off
		// After that, give up
		if (players.Length < count)
		{
			retries++;
			if (retries >= 3)
			{
				break;
			}
		}
		else
		{
			break;
		}
	}

	return players;
}

// Limit the number of teleporter bosses with outlines for performance reasons
void OutlineTeleporterBosses(int count=4)
{
	ArrayList bosses = new ArrayList();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || !IsBoss(i, true) || Enemy(i) != NULL_ENEMY && Enemy(i).ShouldGlow)
			continue;

		// reset glow on every teleporter boss
		SetEntProp(i, Prop_Send, "m_bGlowEnabled", false);
		bosses.Push(i);
	}

	if (bosses.Length > count)
		bosses.Resize(count);

	for (int i = 0; i < bosses.Length; i++)
	{
		SetEntProp(bosses.Get(i), Prop_Send, "m_bGlowEnabled", true);
	}

	delete bosses;
}

public void Timer_SpawnTeleporterBoss(Handle time, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if (!client || !IsClientInGame(client))
		return;
	
	int type = pack.ReadCell();
	int spawnEntity = pack.ReadCell();
	g_bPlayerIsTeleporterBoss[client] = true;
	float pos[3];
	GetEntPos(spawnEntity, pos);
	SpawnBoss(client, type, pos, true);
}

public void Timer_SpawnEnemyRecursive(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if (!IsValidClient(client))
		return;
	
	int type = pack.ReadCell();
	float pos[3];
	pos[0] = pack.ReadFloat();
	pos[1] = pack.ReadFloat();
	pos[2] = pack.ReadFloat();
	float minDist = pack.ReadFloat();
	float maxDist = pack.ReadFloat();
	int recurseCount = pack.ReadCell();
	SpawnEnemy(client, type, pos, minDist, maxDist, true, recurseCount);
}

public void Timer_SpawnBossRecursive(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if (!IsValidClient(client))
		return;
	
	int type = pack.ReadCell();
	float pos[3];
	pos[0] = pack.ReadFloat();
	pos[1] = pack.ReadFloat();
	pos[2] = pack.ReadFloat();
	bool teleporterBoss = pack.ReadCell();
	float minDist = pack.ReadFloat();
	float maxDist = pack.ReadFloat();
	int recurseCount = pack.ReadCell();
	SpawnBoss(client, type, pos, teleporterBoss, minDist, maxDist, true, recurseCount);
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

void StunRadioWave()
{
	bool aliveEnemies;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_ENEMY)
		{
			if (IsScavengerLord(i))
				continue;
			
			if (TF2_GetPlayerClass(i) == TFClass_Medic)
			{
				int medigun = GetPlayerWeaponSlot(i, WeaponSlot_Secondary);
				if (medigun != INVALID_ENT)
				{
					SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", 0.0);
				}
			}

			TF2_RemoveCondition(i, TFCond_MegaHeal);
			TF2_RemoveCondition(i, TFCond_Bonked);
			TF2_AddCondition(i, TFCond_MVMBotRadiowave, 20.0);
			aliveEnemies = true;
		}
	}
	
	if (aliveEnemies)
	{
		EmitSoundToAll(SND_ENEMY_STUN);
		EmitSoundToAll(SND_STUN);
	}
}

bool IsScavengerLord(int client)
{
	return Enemy(client) != NULL_ENEMY && strcmp2(Enemy(client).GetInternalName(), "scavenger_lord");
}