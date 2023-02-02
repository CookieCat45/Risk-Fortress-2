#if defined _RF2_tank_boss_included
 #endinput
#endif
#define _RF2_tank_boss_included

#define PATH_TRACK_START "rf2_tank_start"
#define ATTACHMENT_LAUNCHER_R "launcherR"
#define ATTACHMENT_LAUNCHER_L "launcherL"

#define TANK_BASE_CASH_DROP 350.0

#pragma semicolon 1
#pragma newdecls required

static bool g_bTankDeploying[MAX_EDICTS];
static bool g_bTankSpeedBoost[MAX_EDICTS];

void BeginTankDestructionMode()
{
	g_iTankKillRequirement = SpawnTanks();
	RF2_PrintToChatAll("The Tank has arrived. Destroy it, RED Team!");
	PlayMusicTrackAll();
	
	int gamerules = GetRF2GameRules();
	if (gamerules != INVALID_ENT_REFERENCE)
	{
		FireEntityOutput(gamerules, "OnTankDestructionStart");
	}
}

void EndTankDestructionMode()
{
	ForceTeamWin(TEAM_SURVIVOR);
	RF2_PrintToChatAll("{lime}Victory!{default} All Tanks have been destroyed.");
	
	int gamerules = GetRF2GameRules();
	if (gamerules != INVALID_ENT_REFERENCE)
	{
		FireEntityOutput(gamerules, "OnTankDestructionComplete");
	}
}

static int SpawnTanks()
{
	int spawnCount = 1;
	spawnCount += (g_iSubDifficulty > SubDifficulty_Hard) ? g_iSubDifficulty-2 : 0;
	float time = 15.0;
	
	for (int i = 1; i <= spawnCount; i++)
	{
		if (i == 1)
		{
			CreateTankBoss();
		}
		else // delay the rest of the spawns by a bit
		{
			CreateTimer(time, Timer_CreateTankBoss, _, TIMER_FLAG_NO_MAPCHANGE);
			time += 15.0;
		}
	}
	
	return spawnCount;
}

public Action Timer_CreateTankBoss(Handle timer)
{
	if (!RF2_IsEnabled() || !g_bRoundActive || !g_bTankBossMode)
		return Plugin_Continue;
		
	CreateTankBoss();
	return Plugin_Continue;
}

static int CreateTankBoss()
{
	int spawnPoints[8];
	int tankBoss = -1;
	int spawn, spawnPointCount;
	int entity = MaxClients+1;
	char name[32];
	
	while ((entity = FindEntityByClassname(entity, "path_track")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if (StrContains(name, PATH_TRACK_START) != -1)
		{
			spawnPoints[spawnPointCount] = entity;
			spawnPointCount++;
		}
	}
	
	if (spawnPointCount <= 0)
	{
		char mapName[128];
		GetCurrentMap(mapName, sizeof(mapName));
		LogError("[CreateTankBoss] Map \"%s\" has no path_track entities named \"%s\"! Tanks cannot be spawned!", mapName, PATH_TRACK_START);
		return -1;
	}
	
	float pos[3], angles[3];
	spawn = spawnPoints[GetRandomInt(0, spawnPointCount-1)];
	GetEntPropVector(spawn, Prop_Data, "m_vecAbsOrigin", pos);
	GetEntPropVector(spawn, Prop_Data, "m_angAbsRotation", angles);
	angles[0] = 0.0;
	angles[2] = 0.0;
	
	tankBoss = CreateEntityByName("tank_boss");
	TeleportEntity(tankBoss, pos, angles);
	DispatchSpawn(tankBoss);
	
	int health = RoundToFloor(float(g_cvTankBaseHealth.IntValue) * (1.0 + (float(RF2_GetEnemyLevel()-1) * g_cvTankHealthScale.FloatValue)));
	float speed = g_cvTankBaseSpeed.FloatValue;
	switch (RF2_GetDifficulty())
	{
		case DIFFICULTY_STEEL: speed *= 1.25;
		case DIFFICULTY_TITANIUM: speed *= 1.5;
	}
	
	SetEntProp(tankBoss, Prop_Data, "m_iHealth", health);
	SetEntProp(tankBoss, Prop_Data, "m_iMaxHealth", health);
	SetEntPropFloat(tankBoss, Prop_Data, "m_speed", speed);
	
	g_bTankDeploying[tankBoss] = false;
	g_bTankSpeedBoost[tankBoss] = false;
	SDKHook(tankBoss, SDKHook_Think, Hook_TankBossThink);
	
	/*
	SetEntProp(tankBoss, Prop_Send, "m_nModelIndexOverrides", g_iTankModelIndex, _, 0);
	SetEntProp(tankBoss, Prop_Send, "m_nModelIndexOverrides", g_iTankModelIndex, _, 1);
	SetEntProp(tankBoss, Prop_Send, "m_nModelIndexOverrides", g_iTankModelIndex, _, 2);
	SetEntProp(tankBoss, Prop_Send, "m_nModelIndexOverrides", g_iTankModelIndex, _, 3);
	SetEntityModel(tankBoss, MODEL_BADASS_TANK);
	TankBossSetSequence(tankBoss, "movement");
	
	SetEntProp(tankBoss, Prop_Data, "m_iMaxHealth", 0);
	*/
	
	g_iTanksSpawned++;
	
	int pitch = SNDPITCH_NORMAL;
	if (g_iTanksSpawned > 1)
		pitch = SNDPITCH_HIGH;
	
	EmitSoundToAll(SOUND_BOSS_SPAWN, _, _, _, _, _, pitch);
	
	return tankBoss;
}

public void Hook_TankBossThink(int entity)
{
	// check for deploy animation
	if (!g_bTankDeploying[entity] && !g_bGameOver)
	{
		int sequence = CBaseAnimating(entity).LookupSequence("deploy");
		if (sequence == GetEntProp(entity, Prop_Send, "m_nSequence"))
		{
			g_bTankDeploying[entity] = true;
			CreateTimer(CBaseAnimating(entity).SequenceDuration(sequence), Timer_TankDeployBomb, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		float value = g_cvTankSpeedBoost.FloatValue;
		if (!g_bTankSpeedBoost[entity] && value > 1.0 && RF2_GetDifficulty() >= g_cvTankBoostDifficulty.IntValue)
		{
			int health = GetEntProp(entity, Prop_Data, "m_iHealth");
			int maxHealth = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
			
			if (RoundToFloor(float(maxHealth) * g_cvTankBoostHealth.FloatValue) < health)
			{
				g_bTankSpeedBoost[entity] = true;
				float speed = GetEntPropFloat(entity, Prop_Data, "m_speed");
				SetEntPropFloat(entity, Prop_Data, "m_speed", speed * value);
				EmitSoundToAll(SOUND_TANK_SPEED_UP, entity);
			}
		}
	}
}

public Action Timer_TankDeployBomb(Handle timer, int entity)
{
	if (g_bGameOver || (entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE)
		return Plugin_Continue;
	
	// RIP
	GameOver();
	
	int gamerules = GetRF2GameRules();
	if (gamerules != INVALID_ENT_REFERENCE)
	{
		FireEntityOutput(gamerules, "OnTankDestructionBombDeployed");
	}
	
	return Plugin_Continue;
}

public void Output_OnTankKilled(const char[] output, int caller, int activator, float delay)
{
	if (!g_bTankBossMode)
		return;
	
	float totalCash = TANK_BASE_CASH_DROP * (1.0 + (float(RF2_GetEnemyLevel()-1) * g_cvEnemyCashDropScale.FloatValue));
	float pos[3], ang[3], vel[3];
	GetEntPropVector(caller, Prop_Data, "m_vecAbsOrigin", pos);
	
	for (int i = 1; i <= 10; i++)
	{
		ang[0] = GetRandomFloat(-60.0, -90.0);
		ang[1] = GetRandomFloat(-180.0, 180.0);
		GetAngleVectors(ang, vel, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vel, vel);
		ScaleVector(vel, GetRandomFloat(100.0, 800.0));
		
		SpawnCashDrop(totalCash*0.1, pos, GetRandomInt(2, 3), vel);
	}
	
	g_iTanksKilledObjective++;
	g_iTotalTanksKilled++;
	if (g_iTanksKilledObjective >= g_iTankKillRequirement)
	{
		EndTankDestructionMode();
	}
}