#pragma semicolon 1
#pragma newdecls required

#define MODEL_TANK_BADASS "models/rf2/boss_bots/boss_tank_badass.mdl"
#define MODEL_TANK_SUPER_BADASS "models/rf2/boss_bots/boss_tank_super_badass.mdl"
#define PATH_TRACK_START "rf2_tank_start"
#define ATT_ROCKET_R "rocket_r"
#define ATT_ROCKET_L "rocket_l"
#define ATT_LASER "laser"

#define TANK_BASE_CASH_DROP 350.0
#define ROCKET_ATTACK_COOLDOWN 2.0
#define LASER_ATTACK_COOLDOWN 25.0
#define BARRAGE_ATTACK_COOLDOWN 50.0
#define LASERCANNON_ATTACK_COOLDOWN 60.0

#define SND_TANK_LASERSHOOT "rf2/sfx/boss_tank_badass/laser_shoot.wav"
#define SND_TANK_LASERRISE "weapons/teleporter_build_open2.wav"
#define SND_TANK_LASERRISE_END "weapons/sentry_upgrading2.wav"
#define SND_LASERCANNON_CHARGE "rf2/sfx/boss_tank_badass/super_laser_charge.wav"
#define SND_LASERCANNON_FIRE "rf2/sfx/boss_tank_badass/super_laser_fire.wav"

static const char g_szTankLaserVoices[][] =
{
	"rf2/sfx/boss_tank_badass/vo_charging_laser1.wav",
	"rf2/sfx/boss_tank_badass/vo_charging_laser2.wav",
	"rf2/sfx/boss_tank_badass/vo_charging_laser3.wav",
	"rf2/sfx/boss_tank_badass/vo_charging_laser4.wav"
};

static const char g_szTankBarrageVoices[][] =
{
	"rf2/sfx/boss_tank_badass/vo_firing_missiles1.wav",
	"rf2/sfx/boss_tank_badass/vo_firing_missiles2.wav",
	"rf2/sfx/boss_tank_badass/vo_firing_missiles3.wav",
	"rf2/sfx/boss_tank_badass/vo_firing_missiles4.wav",
	"rf2/sfx/boss_tank_badass/vo_firing_missiles5.wav"
};

static int g_iBadassTankModelIndex;
static int g_iSuperBadassTankModelIndex;

enum
{
	TankType_Normal,
	TankType_Badass,
	TankType_SuperBadass,
};

enum
{
	SPECIAL_NONE,
	SPECIAL_LASER,
	SPECIAL_BARRAGE,
	SPECIAL_LASERCANNON,
};

static bool g_bTankDeploying[MAX_EDICTS];
static bool g_bTankSpeedBoost[MAX_EDICTS];
static CEntityFactory g_Factory;
methodmap RF2_TankBoss < RF2_NPC_Base
{
	public RF2_TankBoss(int entity)
	{
		return view_as<RF2_TankBoss>(entity);
	}
	
	public bool IsValid()
	{
		if (!IsValidEntity2(this.index))
		{
			return false;
		}
		
		return IsTank(this.index);
	}
	
	public bool IsBadass()
	{
		static char classname[128];
		this.GetClassname(classname, sizeof(classname));
		return strcmp2(classname, "rf2_tank_boss_badass");
	}
	
	public static void Init()
	{
		g_Factory = new CEntityFactory("rf2_tank_boss_badass", OnCreate);
		g_Factory.DeriveFromClass("tank_boss");
		g_Factory.BeginDataMapDesc()
			.DefineFloatField("m_flNextRocketAttackR")
			.DefineFloatField("m_flNextRocketAttackL")
			.DefineFloatField("m_flNextLaserAttack")
			.DefineFloatField("m_flNextBarrageAttack")
			.DefineFloatField("m_flNextLaserShot")
			.DefineFloatField("m_flNextLaserCannonAttack")
			.DefineFloatField("m_flLaserCannonChargeTime")
			.DefineFloatField("m_flLaserCannonEndTime")
			.DefineIntField("m_iSpecialAttack")
			.DefineIntField("m_iActualMaxHealth")
			.DefineBoolField("m_bSuperBadass", _, "superbadass")
			.DefineBoolField("m_bFiringLaserCannon")
		.EndDataMapDesc();
		g_Factory.Install();
		HookMapStart(BadassTank_OnMapStart);
	}
	
	property bool SuperBadass
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bSuperBadass"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bSuperBadass", value);
		}
	}

	property bool FiringLaserCannon
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bFiringLaserCannon"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bFiringLaserCannon", value);
		}
	}

	property float NextRocketAttackR
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flNextRocketAttackR");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flNextRocketAttackR", value);
		}
	}

	property float NextRocketAttackL
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flNextRocketAttackL");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flNextRocketAttackL", value);
		}
	}
	
	property float NextLaserAttack
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flNextLaserAttack");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flNextLaserAttack", value);
		}
	}

	property float NextLaserCannonAttack
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flNextLaserCannonAttack");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flNextLaserCannonAttack", value);
		}
	}

	property float LaserCannonChargeTime
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flLaserCannonChargeTime");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flLaserCannonChargeTime", value);
		}
	}

	property float LaserCannonEndTime
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flLaserCannonEndTime");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flLaserCannonEndTime", value);
		}
	}
	
	property float NextBarrageAttack
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flNextBarrageAttack");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flNextBarrageAttack", value);
		}
	}

	property float NextLaserShot
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flNextLaserShot");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flNextLaserShot", value);
		}
	}
	
	property float Speed
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_speed");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_speed", value);
		}
	}
	
	property int SpecialAttack
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iSpecialAttack");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iSpecialAttack", value);
		}
	}
	
	property int Health
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iHealth");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iHealth", value);
		}
	}

	property int MaxHealth
	{
		public get()
		{
			if (this.IsBadass())
				return this.GetProp(Prop_Data, "m_iActualMaxHealth");

			return this.GetProp(Prop_Data, "m_iMaxHealth");
		}
		
		public set(int value)
		{
			if (this.IsBadass())
				this.SetProp(Prop_Data, "m_iActualMaxHealth", value);
			else
				this.SetProp(Prop_Data, "m_iMaxHealth", value);
		}
	}
	
	property bool SpeedBoosted
	{
		public get()
		{
			return g_bTankSpeedBoost[this.index];
		}
		
		public set(bool value)
		{
			g_bTankSpeedBoost[this.index] = value;
		}
	}
	
	property bool Deploying
	{
		public get()
		{
			return g_bTankDeploying[this.index];
		}
		
		public set(bool value)
		{
			g_bTankDeploying[this.index] = value;
		}
	}
	
	public void SetPathTrackNode(int entity)
	{
		char name[128];
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if (!name[0])
		{
			FormatEx(name, sizeof(name), "rf2_pathtack_temp%i", entity);
			DispatchKeyValue(entity, "targetname", name);
			SDKCall(g_hSDKTankSetStartNode, this.index, name);
			DispatchKeyValue(entity, "targetname", "");
		}
		else
		{
			SDKCall(g_hSDKTankSetStartNode, this.index, name);
		}
	}
}

void BadassTank_OnMapStart()
{
	g_iBadassTankModelIndex = PrecacheModel2(MODEL_TANK_BADASS, true);
	g_iSuperBadassTankModelIndex = PrecacheModel2(MODEL_TANK_SUPER_BADASS, true);
	AddModelToDownloadsTable(MODEL_TANK_BADASS, false);
	#if defined PRERELEASE
	AddModelToDownloadsTable(MODEL_TANK_SUPER_BADASS, false);
	AddMaterialToDownloadsTable("materials/rf2/bosses/super_badass_tank/sentry3_blue");
	AddMaterialToDownloadsTable("materials/rf2/bosses/super_badass_tank/tank_eye");
	AddMaterialToDownloadsTable("materials/rf2/bosses/super_badass_tank/tank_eye_shell");
	AddMaterialToDownloadsTable("materials/rf2/bosses/super_badass_tank/tankbody1");
	AddMaterialToDownloadsTable("materials/rf2/bosses/super_badass_tank/tankbody2");
	AddSoundToDownloadsTable(SND_LASERCANNON_CHARGE, false);
	AddSoundToDownloadsTable(SND_LASERCANNON_FIRE, false);
	#endif
	PrecacheSound2(SND_TANK_LASERRISE, true);
	PrecacheSound2(SND_TANK_LASERRISE_END, true);
	PrecacheSound2(SND_LASERCANNON_CHARGE, true);
	PrecacheSound2(SND_LASERCANNON_FIRE, true);
	AddSoundToDownloadsTable(SND_TANK_LASERSHOOT);
	PrecacheSoundArray(g_szTankLaserVoices, sizeof(g_szTankLaserVoices));
	PrecacheSoundArray(g_szTankBarrageVoices, sizeof(g_szTankBarrageVoices));
}

static void OnCreate(RF2_TankBoss tank)
{
	tank.SetProp(Prop_Send, "m_nModelIndexOverrides", g_iBadassTankModelIndex, _, 0);
	tank.SetProp(Prop_Send, "m_nModelIndexOverrides", g_iBadassTankModelIndex, _, 1);
	tank.SetProp(Prop_Send, "m_nModelIndexOverrides", g_iBadassTankModelIndex, _, 2);
	tank.SetProp(Prop_Send, "m_nModelIndexOverrides", g_iBadassTankModelIndex, _, 3);
	
	float gameTime = GetGameTime();
	tank.NextRocketAttackR = gameTime+ROCKET_ATTACK_COOLDOWN;
	tank.NextRocketAttackL = gameTime+ROCKET_ATTACK_COOLDOWN*1.5;
	tank.NextLaserAttack = gameTime+LASER_ATTACK_COOLDOWN;
	tank.NextBarrageAttack = gameTime+BARRAGE_ATTACK_COOLDOWN;
	tank.NextLaserCannonAttack = gameTime+15.0; // use this first (Super Badass only)
	SDKHook(tank.index, SDKHook_Think, Hook_BadassTankThink);
	SDKHook(tank.index, SDKHook_SpawnPost, Hook_BadassTankSpawnPost);
}

public void Hook_BadassTankSpawnPost(int entity)
{
	RF2_TankBoss tank = RF2_TankBoss(entity);
	if (tank.SuperBadass)
	{
		tank.SetModel(MODEL_TANK_SUPER_BADASS);
		tank.SetProp(Prop_Send, "m_nModelIndexOverrides", g_iSuperBadassTankModelIndex, _, 0);
		tank.SetProp(Prop_Send, "m_nModelIndexOverrides", g_iSuperBadassTankModelIndex, _, 1);
		tank.SetProp(Prop_Send, "m_nModelIndexOverrides", g_iSuperBadassTankModelIndex, _, 2);
		tank.SetProp(Prop_Send, "m_nModelIndexOverrides", g_iSuperBadassTankModelIndex, _, 3);
		
		// hide bomb model
		int bomb = MaxClients+1;
		char modelName[PLATFORM_MAX_PATH];
		while ((bomb = FindEntityByClassname(bomb, "prop_dynamic")) != INVALID_ENT)
		{
			if (GetEntPropEnt(bomb, Prop_Send, "moveparent") != tank.index)
				continue;
			
			GetEntPropString(bomb, Prop_Data, "m_ModelName", modelName, sizeof(modelName));
			if (strcmp2(modelName, "models/bots/boss_bot/bomb_mechanism.mdl"))
			{
				SetEntityRenderMode(bomb, RENDER_NONE);
				break;
			}
		}
	}
	else
	{
		tank.SetModel(MODEL_TANK_BADASS);
	}
	
	// The reason this needs to be done is because Tanks will change their model based on how much damage they have taken
	// in relation to their max health. Setting their max health to 0 AFTER spawning will prevent this behaviour.
	int maxHealth = tank.GetProp(Prop_Data, "m_iMaxHealth");
	tank.MaxHealth = maxHealth;
	tank.SetProp(Prop_Data, "m_iMaxHealth", 0);
	tank.SetSequence("movement");
}

void BeginTankDestructionMode()
{
	g_iTankKillRequirement = SpawnTanks();
	RF2_PrintToChatAll("%t", "TanksHaveArrived");
	PlayMusicTrackAll();
	RF2_Object_Teleporter.ToggleObjectsStatic(false);
	RF2_GameRules gamerules = GetRF2GameRules();
	if (gamerules.IsValid())
	{
		gamerules.FireOutput("OnTankDestructionStart");
	}
}

void EndTankDestructionMode()
{
	RF2_Object_Teleporter.ToggleObjectsStatic(true);
	RF2_Object_Teleporter.EventCompletion();
	char text[256];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerSurvivor(i) && !IsPlayerMinion(i))
			continue;
		
		FormatEx(text, sizeof(text), "%T", "EndLevelCommandReminder", i);
		CRemoveTags(text, sizeof(text));
		PrintCenterText(i, text);
	}
	
	RF2_GameRules gamerules = GetRF2GameRules();
	if (gamerules.IsValid())
	{
		gamerules.FireOutput("OnTankDestructionComplete");
	}
	
	RF2_PrintToChatAll("%t", "AllTanksDestroyed");
	CreateTimer(3.0, Timer_CommandReminder, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CommandReminder(Handle timer)
{
	//RF2_PrintToChatAll("%t", "EndLevelCommandReminder");
	char text[256];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerSurvivor(i) && !IsPlayerMinion(i) || IsFakeClient(i))
			continue;
		
		FormatEx(text, sizeof(text), "%T", "EndLevelCommandReminder", i);
		CRemoveTags(text, sizeof(text));
		PrintCenterText(i, text);
	}
	
	return Plugin_Continue;
}

static int SpawnTanks()
{
	int subDifficulty = RF2_GetSubDifficulty();
	float subIncrement = g_cvSubDifficultyIncrement.FloatValue;
	int spawnCount = 1;
	const int maxTanks = 15;
	spawnCount += RoundToFloor(g_flDifficultyCoeff/(subIncrement*1.2));
	spawnCount = imin(spawnCount, maxTanks);
	float time = 10.0;
	int badassTankCount;
	if (subDifficulty >= SubDifficulty_Insane)
	{
		badassTankCount += subDifficulty/4;
	}
	
	for (int i = 1; i <= spawnCount; i++)
	{
		bool badass = badassTankCount > 0 && spawnCount-i <= badassTankCount;
		
		if (i == 1)
		{
			CreateTankBoss(TankType_Normal);
		}
		else // delay the rest of the spawns
		{
			CreateTimer(time, Timer_CreateTankBoss, badass, TIMER_FLAG_NO_MAPCHANGE);
			time += 10.0;
		}
	}
	
	return spawnCount;
}

public Action Timer_CreateTankBoss(Handle timer, bool badass)
{
	if (!g_bRoundActive || !g_bTankBossMode)
		return Plugin_Continue;
		
	CreateTankBoss(badass ? TankType_Badass : TankType_Normal);
	return Plugin_Continue;
}

RF2_TankBoss CreateTankBoss(int type, RF2_TankSpawner spawnPoint=view_as<RF2_TankSpawner>(INVALID_ENT))
{
	float pos[3], angles[3];
	if (spawnPoint.IsValid())
	{
		spawnPoint.GetAbsOrigin(pos);
		spawnPoint.GetAbsAngles(angles);
	}
	else
	{
		ArrayList spawnPoints = new ArrayList();
		int spawn;
		int entity = MaxClients+1;
		char name[32];
		
		while ((entity = FindEntityByClassname(entity, "path_track")) != INVALID_ENT)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
			if (StrContains(name, PATH_TRACK_START) != -1)
			{
				spawnPoints.Push(entity);
			}
		}
		
		if (spawnPoints.Length <= 0)
		{
			delete spawnPoints;
			char mapName[128];
			GetCurrentMap(mapName, sizeof(mapName));
			LogError("[CreateTankBoss] Map \"%s\" has no path_track entities named \"%s\"! Tanks cannot be spawned!", mapName, PATH_TRACK_START);
			return RF2_TankBoss(INVALID_ENT);
		}
		
		spawn = spawnPoints.Get(GetRandomInt(0, spawnPoints.Length-1));
		delete spawnPoints;
		GetEntPos(spawn, pos);
		GetEntPropVector(spawn, Prop_Data, "m_angAbsRotation", angles);
	}
	
	angles[0] = 0.0;
	angles[2] = 0.0;
	RF2_TankBoss tank = RF2_TankBoss(CreateEntityByName(type != TankType_Normal ? "rf2_tank_boss_badass" : "tank_boss"));
	tank.SuperBadass = type == TankType_SuperBadass;
	int health = RoundToFloor(float(g_cvTankBaseHealth.IntValue) * (1.0 + (float(RF2_GetEnemyLevel()-1) * g_cvTankHealthScale.FloatValue)));
	if (IsSingleplayer(false))
	{
		health = RoundToFloor(float(health) * 0.75);
	}
	else
	{
		health = RoundToFloor(float(health) * (1.0 + 0.2*float(RF2_GetSurvivorCount()-1)));
	}
	
	tank.Health = health;
	tank.SetProp(Prop_Data, "m_iMaxHealth", health);
	float speed = g_cvTankBaseSpeed.FloatValue;
	tank.Speed = speed;
	tank.Teleport(pos, angles);
	tank.Spawn();
	RF2_HealthText text = CreateHealthText(tank.index, 230.0, 35.0);
	if (type == TankType_Badass)
	{
		text.SetHealthColor(HEALTHCOLOR_HIGH, {0, 75, 200, 255});
	}
	else if (type == TankType_SuperBadass)
	{
		text.SetHealthColor(HEALTHCOLOR_HIGH, {0, 100, 25, 255});
	}
	else
	{
		text.SetHealthColor(HEALTHCOLOR_HIGH, {70, 150, 255, 255});
	}
	
	SDKHook(tank.index, SDKHook_Think, Hook_TankBossThink);
	g_iTanksSpawned++;
	int pitch = SNDPITCH_NORMAL;
	if (g_iTanksSpawned > 1)
	{
		pitch = SNDPITCH_HIGH;
	}
	
	EmitSoundToAll(SND_BOSS_SPAWN, _, _, _, _, _, pitch);
	return tank;
}

public void Hook_TankBossThink(int entity)
{
	RF2_TankBoss tank = RF2_TankBoss(entity);
	float motion[3], ang[3];
	tank.MyNextBotPointer().GetLocomotionInterface().GetMotionVector(motion);
	GetVectorAngles(motion, ang);
	tank.SetAbsAngles(ang);
	// check for deploy animation
	if (!tank.Deploying && !g_bGameOver)
	{
		int sequence = tank.LookupSequence("deploy");
		if (sequence == tank.GetProp(Prop_Send, "m_nSequence"))
		{
			tank.Deploying = true;
			CreateTimer(tank.SequenceDuration(sequence), Timer_TankDeployBomb, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		float value = g_cvTankSpeedBoost.FloatValue;
		if (!tank.SpeedBoosted && value > 1.0 && RF2_GetDifficulty() >= g_cvTankBoostDifficulty.IntValue)
		{
			if (tank.Health < RoundToFloor(float(tank.MaxHealth) * g_cvTankBoostHealth.FloatValue))
			{
				tank.SpeedBoosted = true;
				tank.Speed *= value;
				EmitSoundToAll(SND_TANK_SPEED_UP, tank.index);
				EmitSoundToAll(SND_TANK_SPEED_UP, tank.index);
			}
		}
	}
}

public Action Timer_TankDeployBomb(Handle timer, int entity)
{
	if (g_bGameOver || (entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return Plugin_Continue;
	
	// RIP
	GameOver();
	RF2_GameRules gamerules = GetRF2GameRules();
	if (gamerules.IsValid())
	{
		gamerules.FireOutput("OnTankDestructionBombDeployed");
	}
	
	return Plugin_Continue;
}

public void Output_OnTankKilled(const char[] output, int caller, int activator, float delay)
{
	RF2_GameRules gamerules = GetRF2GameRules();
	if (gamerules.IsValid())
	{
		gamerules.FireOutput("OnTankDestroyed");
	}
	
	if (!g_bTankBossMode)
		return;
	
	float totalCash = TANK_BASE_CASH_DROP * (1.0 + (float(RF2_GetEnemyLevel()-1) * g_cvEnemyCashDropScale.FloatValue));
	float pos[3], ang[3], vel[3];
	GetEntPos(caller, pos);
	for (int i = 1; i <= 10; i++)
	{
		ang[0] = GetRandomFloat(-60.0, -90.0);
		ang[1] = GetRandomFloat(-180.0, 180.0);
		GetAngleVectors(ang, vel, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vel, vel);
		ScaleVector(vel, GetRandomFloat(100.0, 800.0));
		SpawnCashDrop(totalCash*0.1, pos, GetRandomInt(2, 3), vel);
	}
	
	if (IsStageCleared())
		return;
	
	g_iTanksKilledObjective++;
	g_iTotalTanksKilled++;
	if (g_iTanksKilledObjective >= g_iTankKillRequirement)
	{
		EndTankDestructionMode();
	}
}

// ---------------------------------------------- Badass Tank -----------------------------------------------------------

public void Hook_BadassTankThink(int entity)
{
	RF2_TankBoss tank = RF2_TankBoss(entity);
	float gameTime = GetGameTime();
	int special = tank.SpecialAttack;
	if (special != SPECIAL_BARRAGE)
	{
		float nextRocketAttack[2];
		nextRocketAttack[0] = tank.NextRocketAttackR;
		nextRocketAttack[1] = tank.NextRocketAttackL;
		
		// is it time to fire a rocket?
		if (gameTime >= nextRocketAttack[0] || gameTime >= nextRocketAttack[1])
		{
			char attachmentName[16];
			attachmentName = gameTime >= nextRocketAttack[0] ? ATT_ROCKET_R : ATT_ROCKET_L;
			int attachment = LookupEntityAttachment(tank.index, attachmentName);
			if (attachment > 0)
			{
				float pos[3], angles[3];
				const float speed = 1100.0;
				const float damage = 150.0;
				GetEntityAttachment(tank.index, attachment, pos, NULL_VECTOR);
				tank.GetPropVector(Prop_Send, "m_angRotation", angles);
				
				int rocket = ShootProjectile(tank.index, "tf_projectile_sentryrocket", pos, angles, speed, damage, -10.0);
				SetEntityMoveType(rocket, MOVETYPE_FLYGRAVITY);
				CreateTimer(0.1, Timer_TankRocketFixAngles, EntIndexToEntRef(rocket), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				EmitSoundToAll(SND_LAW_FIRE, tank.index, _, _, _, _, _, _, pos);
				
				float attackRate, nextAttackTime;
				if (tank.SuperBadass)
				{
					attackRate = 0.25;
				}
				else
				{
					switch (RF2_GetDifficulty())
					{
						case DIFFICULTY_STEEL: attackRate = 0.75;
						case DIFFICULTY_TITANIUM: attackRate = 0.5;
						default: attackRate = 1.0;
					}
				}

				nextAttackTime = ROCKET_ATTACK_COOLDOWN * attackRate;
				if (strcmp(attachmentName, ATT_ROCKET_L) == 0)
				{
					tank.AddGesture("fire_rocket_l");
					tank.NextRocketAttackL = gameTime+nextAttackTime*1.5;
				}
				else
				{
					tank.AddGesture("fire_rocket_r");
					tank.NextRocketAttackR = gameTime+nextAttackTime;
				}
			}
		}
	}
	
	float nextLaserAttack = tank.NextLaserAttack;
	float nextBarrageAttack = tank.NextBarrageAttack;
	float nextLaserCannonAttack = tank.NextLaserCannonAttack;
	if (special == SPECIAL_NONE)
	{
		// decide our next special attack if we can use one
		int newSpecial;
		if (gameTime >= nextLaserAttack || gameTime >= nextBarrageAttack || gameTime >= nextLaserCannonAttack && tank.SuperBadass)
		{
			if (gameTime >= nextLaserCannonAttack && tank.SuperBadass)
			{
				// always use laser cannon first if ready
				newSpecial = SPECIAL_LASERCANNON;
			}
			else if (gameTime >= nextLaserAttack && gameTime >= nextBarrageAttack)
			{
				newSpecial = GetRandomInt(SPECIAL_LASER, SPECIAL_BARRAGE);
			}
			else
			{
				// both are ready? decide randomly
				newSpecial = gameTime >= nextLaserAttack ? SPECIAL_LASER : SPECIAL_BARRAGE;
			}
			
			// don't waste our special attacks if there are no enemies nearby
			float pos[3];
			tank.GetAbsOrigin(pos);
			pos[2] += 100.0;
			int team = GetEntTeam(tank.index);
			int enemyTeam = team == TEAM_ENEMY ? TEAM_SURVIVOR : TEAM_ENEMY;
			if (newSpecial != SPECIAL_NONE 
				&& (GetNearestPlayer(pos, _, 2000.0, enemyTeam, true) != INVALID_ENT || GetNearestEntity(pos, "obj_*", _, 2000.0, enemyTeam, true) != INVALID_ENT))
			{
				switch (newSpecial)
				{
					case SPECIAL_LASER:
					{
						special = newSpecial;
						tank.SpecialAttack = special;
						float duration = tank.AddGesture("eye_rise", _, _, 0.25);
						int num = GetRandomInt(0, sizeof(g_szTankLaserVoices)-1);
						EmitSoundToAll(g_szTankLaserVoices[num], tank.index, _, 120);
						EmitSoundToAll(g_szTankLaserVoices[num], tank.index, _, 120);
						EmitSoundToAll(SND_TANK_LASERRISE, tank.index, _, 120);
						if (nextBarrageAttack - GetGameTime() <= 10.0)
						{
							tank.NextBarrageAttack = nextBarrageAttack + duration + 10.0;
						}
					}
					
					case SPECIAL_BARRAGE:
					{
						// check to make sure there's space above us so we don't blast all of our rockets into the ceiling
						float endPos[3];
						const float spaceRequired = 800.0;
						TR_TraceRayFilter(pos, {-90.0, 0.0, 0.0}, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceFilter_WallsOnly);
						TR_GetEndPosition(endPos);
						if (GetVectorDistance(pos, endPos, true) >= sq(spaceRequired))
						{
							special = newSpecial;
							tank.SpecialAttack = special;
							tank.RemoveAllGestures();
							int num = GetRandomInt(0, sizeof(g_szTankBarrageVoices)-1);
							EmitSoundToAll(g_szTankBarrageVoices[num], tank.index, _, 120);
							EmitSoundToAll(g_szTankBarrageVoices[num], tank.index, _, 120);
							EmitSoundToAll(SND_TANK_LASERRISE, tank.index, _, 120);
							float duration = tank.AddGesture("rocket_turn_up", _, _, 0.2, 2);
							if (nextLaserAttack - GetGameTime() <= 10.0)
							{
								tank.NextLaserAttack = nextLaserAttack + duration + 10.0;
							}
						}
					}
					
					case SPECIAL_LASERCANNON: // Super Badass only
					{
						tank.RemoveAllGestures();
						special = newSpecial;
						tank.SpecialAttack = special;
						tank.AddGesture("deploy", _, false, 1.0, 999);
						tank.LaserCannonChargeTime = gameTime+5.0;
						tank.LaserCannonEndTime = gameTime+16.5;
						SpawnInfoParticle("dxhr_lightningball_parent_red", pos, 3.2, tank.index, "lasercannon");
						EmitSoundToAll(SND_LASERCANNON_CHARGE, tank.index, _, SNDLEVEL_SCREAMING);
						EmitSoundToAll(SND_LASERCANNON_CHARGE, tank.index, _, SNDLEVEL_SCREAMING);
						EmitSoundToAll(SND_LASERCANNON_CHARGE, tank.index, _, SNDLEVEL_SCREAMING);
					}
				}
			}
		}
	}
	
	switch (special)
	{
		case SPECIAL_LASER:
		{
			// wait for anim to finish
			if (!tank.IsPlayingGesture("eye_rise"))
			{
				if (!tank.IsPlayingGesture("eye_up"))
				{
					tank.AddGesture("eye_up", _, false);
					float duration;
					switch (RF2_GetDifficulty())
					{
						//case DIFFICULTY_STEEL: duration = 12.5;
						//case DIFFICULTY_TITANIUM: duration = 17.0;
						default: duration = 9.0;
					}
					
					StopSound(tank.index, SNDCHAN_AUTO, SND_TANK_LASERRISE);
					EmitSoundToAll(SND_TANK_LASERRISE_END, tank.index, _, 120);
					CreateTimer(duration, Timer_EndLaserAttack, EntIndexToEntRef(tank.index), TIMER_FLAG_NO_MAPCHANGE);
					tank.NextBarrageAttack = nextBarrageAttack+duration;
				}
				
				float tickedTime = GetTickedTime();
				if (tickedTime >= tank.NextLaserShot)
				{
					float pos[3];
					const float range = 2500.0;
					int team = GetEntTeam(tank.index);
					int enemyTeam = team == TEAM_ENEMY ? TEAM_SURVIVOR : TEAM_ENEMY;
					int attachment = LookupEntityAttachment(tank.index, ATT_LASER);
					GetEntityAttachment(tank.index, attachment, pos, NULL_VECTOR);
					int nearestPlayer = GetNearestPlayer(pos, _, range, enemyTeam, true);
					int nearestBuilding = GetNearestEntity(pos, "obj_*", _, range, enemyTeam, true);
					float playerPos[3], buildingPos[3];
					float playerDist = -1.0;
					if (nearestPlayer != INVALID_ENT)
					{
						GetEntPos(nearestPlayer, playerPos, true);
						playerDist = GetVectorDistance(pos, playerPos, true);
						playerPos[2] += 30.0;
					}
					
					if (nearestBuilding != INVALID_ENT)
					{
						GetEntPos(nearestBuilding, buildingPos, true);
					}
					
					int target = INVALID_ENT;
					if (nearestPlayer > 0 || nearestBuilding > 0)
					{
						// should we target the player, or the building?
						if (nearestPlayer != -1 && playerDist >= 0.0 && nearestBuilding <= 0 || 
							(TF2_GetObjectType2(nearestBuilding) != TFObject_Sentry || GetEntProp(nearestBuilding, Prop_Send, "m_iUpgradeLevel") == 1))
						{
							target = nearestPlayer;
						}
						else
						{
							target = nearestBuilding;
						}
					}
					
					if (target != INVALID_ENT)
					{
						// Face our target
						float rot[3], angles[3];
						tank.GetPropVector(Prop_Send, "m_angRotation", rot);
						if (target == nearestPlayer)
						{
							GetVectorAnglesTwoPoints(pos, playerPos, angles);
						}
						else
						{
							GetVectorAnglesTwoPoints(pos, buildingPos, angles);
						}
						
						int poseParam = tank.LookupPoseParameter("eye_look");
						const float bound = 180.0;
						float value = angles[1] * -1.0;
						value += rot[1];
						if (value < -bound)
						{
							value = bound - (FloatAbs(value) - bound);
						}
						else if (value > bound)
						{
							value = -value + bound;
						}
						
						tank.SetPoseParameter(poseParam, value);
						float laserPos[3], dir[3];
						GetAngleVectors(angles, dir, NULL_VECTOR, NULL_VECTOR);
						NormalizeVector(dir, dir);
						laserPos[0] = pos[0] + dir[0] * 15.0;
						laserPos[1] = pos[1] + dir[1] * 15.0;
						laserPos[2] = pos[2] + 10.0;
						
						const float speed = 1000.0;
						const float damage = 35.0;
						for (int i = 1; i <= (tank.SuperBadass ? 3 : 1); i++)
						{
							if (i == 2)
							{
								angles[1] -= 8.0;
							}
							else if (i == 3)
							{
								angles[1] += 16.0;
							}
							
							int laser = ShootProjectile(tank.index, "tf_projectile_rocket", pos, angles, speed, damage);
							SetEntityCollisionGroup(laser, TFCOLLISION_GROUP_ROCKET_BUT_NOT_WITH_OTHER_ROCKETS); // So the lasers don't collide with themselves
							SetEntityModel2(laser, MODEL_INVISIBLE);
							EmitSoundToAll(SND_TANK_LASERSHOOT, tank.index, _, 120);
							SpawnInfoParticle("drg_cow_rockettrail_fire_blue", pos, _, laser);
						}
						
						SpawnInfoParticle("teleported_flash", laserPos, 0.1);
						float fireRate = float(tank.Health) / float(tank.MaxHealth);
						fireRate = fmax(fireRate, 0.5);
						tank.NextLaserShot = tickedTime + (0.2 * fireRate);
					}
				}
			}
		}
		
		case SPECIAL_BARRAGE:
		{
			if (!tank.IsPlayingGesture("rocket_turn_up"))
			{
				if (!tank.IsPlayingGesture("rocket_up"))
				{
					tank.AddGesture("rocket_up", _, false);
					StopSound(tank.index, SNDCHAN_AUTO, SND_TANK_LASERRISE);
					EmitSoundToAll(SND_TANK_LASERRISE_END, tank.index, _, 120);
					
					// note that this is technically double, as the rockets are fired from both chambers each time
					int rocketCount = 15;
					switch (RF2_GetDifficulty())
					{
						//case DIFFICULTY_STEEL: rocketCount += 5;
						//case DIFFICULTY_TITANIUM: rocketCount += 10;
					}
					
					float time = 0.2;
					for (int i = 1; i <= rocketCount; i++)
					{
						CreateTimer(time, Timer_TankFireHomingRockets, EntIndexToEntRef(tank.index), TIMER_FLAG_NO_MAPCHANGE);
						time += 0.2;
					}
					
					CreateTimer(time, Timer_EndBarrageAttack, EntIndexToEntRef(tank.index), TIMER_FLAG_NO_MAPCHANGE);
					tank.NextLaserAttack = nextLaserAttack+time;
				}
			}
		}
		
		case SPECIAL_LASERCANNON:
		{
			if (gameTime >= tank.LaserCannonChargeTime)
			{
				if (!tank.FiringLaserCannon)
				{
					EmitSoundToAll(SND_LASERCANNON_FIRE, tank.index, _, SNDLEVEL_SCREAMING);
					EmitSoundToAll(SND_LASERCANNON_FIRE, tank.index, _, SNDLEVEL_SCREAMING);
					EmitSoundToAll(SND_LASERCANNON_FIRE, tank.index, _, SNDLEVEL_SCREAMING);
					tank.FiringLaserCannon = true;
				}
				
				float pos[3], angles[3];
				int attachment = LookupEntityAttachment(tank.index, "lasercannon");
				GetEntityAttachment(tank.index, attachment, pos, angles);
				tank.GetAbsAngles(angles);
				angles[0] += 1.5; // angle down slightly
				int color[4];
				color[0] = GetRandomInt(75, 255);
				color[1] = GetRandomInt(75, 255);
				color[2] = GetRandomInt(75, 255);
				color[3] = 255;
				FireLaser(tank.index, _, pos, angles, true, _, 75.0, DMG_SONIC|DMG_PREVENT_PHYSICS_FORCE|DMG_IGNITE, 55.0, color, _, false, false, 0.3);
				if (gameTime >= tank.LaserCannonEndTime)
				{
					tank.SpecialAttack = SPECIAL_NONE;
					tank.NextLaserCannonAttack = gameTime+LASERCANNON_ATTACK_COOLDOWN;
					tank.RemoveAllGestures();
					tank.FiringLaserCannon = false;
				}
			}
		}
	}
}

public Action Timer_TankFireHomingRockets(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return Plugin_Continue;
	
	RF2_TankBoss tank = RF2_TankBoss(entity);
	int attachment[2];
	float pos[3];
	attachment[0] = LookupEntityAttachment(tank.index, ATT_ROCKET_L);
	attachment[1] = LookupEntityAttachment(tank.index, ATT_ROCKET_R);
	for (int i = 0; i <= 1; i++)
	{
		GetEntityAttachment(tank.index, attachment[i], pos, NULL_VECTOR);
		const float speed = 1000.0;
		const float damage = 100.0;
		float angles[3];
		angles[0] = -90.0;
		angles[1] = GetRandomFloat(-180.0, 180.0);
		int rocket = ShootProjectile(tank.index, "tf_projectile_sentryrocket", pos, angles, speed, damage, -10.0);
		SetEntityMoveType(rocket, MOVETYPE_FLYGRAVITY);
		CreateTimer(0.1, Timer_TankRocketFixAngles, EntIndexToEntRef(rocket), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	EmitSoundToAll(SND_LAW_FIRE, entity);
	tank.AddGesture("rocket_shoot_up", _, _, _, 2);
	return Plugin_Continue;
}

public Action Timer_EndLaserAttack(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return Plugin_Continue;
	
	RF2_TankBoss tank = RF2_TankBoss(entity);
	tank.SpecialAttack = SPECIAL_NONE;
	tank.NextLaserAttack = GetGameTime()+LASER_ATTACK_COOLDOWN;
	tank.RemoveAllGestures();
	return Plugin_Continue;
}

public Action Timer_EndBarrageAttack(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return Plugin_Continue;
	
	RF2_TankBoss tank = RF2_TankBoss(entity);
	tank.SpecialAttack = SPECIAL_NONE;
	tank.NextBarrageAttack = GetGameTime()+BARRAGE_ATTACK_COOLDOWN;
	tank.RemoveAllGestures();
	return Plugin_Continue;
}

public Action Timer_TankRocketFixAngles(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return Plugin_Stop;
	
	// MOVETYPE_FLYGRAVITY does not update angles on rockets; we do it ourselves
	float vel[3], angles[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
	GetVectorAngles(vel, angles);
	TeleportEntity(entity, _, angles);
	return Plugin_Continue;
}

bool IsTank(int entity)
{
	static char classname[128];
	GetEntityClassname(entity, classname, sizeof(classname));
	return StrContains(classname, "tank_boss") != -1;
}
