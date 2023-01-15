#if defined _RF2_tank_boss_included
 #endinput
#endif
#define _RF2_tank_boss_included

#define PATH_TRACK_START "rf2_tank_start"
#define ATTACHMENT_LAUNCHER_R "launcherR"
#define ATTACHMENT_LAUNCHER_L "launcherL"

void BeginTankDestructionMode()
{
	g_iTankKillRequirement = SpawnTanks();
	RF2_PrintToChatAll("The Tank has arrived. Destroy it, RED Team!");
	PlayMusicTrackAll();
}

void EndTankDestructionMode()
{
	ForceTeamWin(TEAM_SURVIVOR);
	RF2_PrintToChatAll("{lime}Victory!{default} All Tanks have been destroyed.");
}

static int SpawnTanks()
{
	int spawnCount = 1;
	spawnCount += (g_iSubDifficulty > SubDifficulty_Hard) ? g_iSubDifficulty-2 : 0;
	float time = 17.5;
	
	for (int i = 1; i <= spawnCount; i++)
	{
		if (i == 1)
		{
			CreateTankBoss();
		}
		else // delay the rest of the spawns by a bit
		{
			CreateTimer(time, Timer_CreateTankBoss, _, TIMER_FLAG_NO_MAPCHANGE);
			time += 17.5;
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
	
	spawn = spawnPoints[GetRandomInt(0, spawnPointCount-1)];
	float pos[3];
	float angles[3];
	GetEntPropVector(spawn, Prop_Data, "m_vecAbsOrigin", pos);
	GetEntPropVector(spawn, Prop_Data, "m_angAbsRotation", angles);
	angles[0] = 0.0;
	angles[2] = 0.0;
	
	tankBoss = CreateEntityByName("tank_boss");
	int health = g_cvTankBaseHealth.IntValue;
	health = RoundToFloor(float(health) * (1.0 + (float(RF2_GetEnemyLevel()-1) * g_cvTankHealthScale.FloatValue)));
	TeleportEntity(tankBoss, pos, angles);
	DispatchSpawn(tankBoss);
	
	float speed = g_cvTankBaseSpeed.FloatValue;
	switch (g_iDifficultyLevel)
	{
		case DIFFICULTY_STEEL: speed *= 1.25;
		case DIFFICULTY_TITANIUM: speed *= 1.5;
	}
	
	SetEntProp(tankBoss, Prop_Data, "m_iHealth", health);
	SetVariantFloat(speed);
	AcceptEntityInput(tankBoss, "SetSpeed");
	
	SetEntProp(tankBoss, Prop_Send, "m_nModelIndexOverrides", g_iTankModelIndex, _, 0);
	SetEntProp(tankBoss, Prop_Send, "m_nModelIndexOverrides", g_iTankModelIndex, _, 1);
	SetEntProp(tankBoss, Prop_Send, "m_nModelIndexOverrides", g_iTankModelIndex, _, 2);
	SetEntProp(tankBoss, Prop_Send, "m_nModelIndexOverrides", g_iTankModelIndex, _, 3);
	SetEntityModel(tankBoss, MODEL_BADASS_TANK);
	
	TankBossSetSequence(tankBoss, "movement");
	
	/**
	 * In TF2's code, tank_boss is hardcoded to change its model based on the damage it has taken compared to its max health.
	 * This will trick it into thinking it never needs to change its damage model,
	 * preventing it from overriding our customized model we use for tanks. The tank's actual health remains the same. 
	 */
	SetEntProp(tankBoss, Prop_Data, "m_iMaxHealth", 0);
	
	g_iTanksSpawned++;
	
	int pitch = SNDPITCH_NORMAL;
	if (g_iTanksSpawned > 1)
		pitch = SNDPITCH_HIGH;
	
	EmitSoundToAll(SOUND_BOSS_SPAWN, _, _, _, _, _, pitch);
	
	return tankBoss;
}

static void TankBossSetSequence(int entity, const char[] sequenceName)
{
	int sequence = CBaseAnimating(entity).LookupSequence(sequenceName);
	if (sequence > -1)
	{
		SetEntProp(entity, Prop_Send, "m_nSequence", sequence);
	}
	else
	{
		LogError("[TankBossSetSequence] Invalid sequence \"%s\"", sequenceName);
	}
}

public void Output_OnTankKilled(const char[] output, int caller, int activator, float delay)
{
	if (!g_bTankBossMode)
		return;
	
	g_iTanksKilledObjective++;
	g_iTotalTanksKilled++;
	if (g_iTanksKilledObjective >= g_iTankKillRequirement)
	{
		EndTankDestructionMode();
	}
}

public void Output_OnTankHealthBelow50Percent(const char[] output, int caller, int activator, float delay)
{
	if (!g_bTankBossMode || g_iDifficultyLevel < DIFFICULTY_IRON)
		return;
	
	float speedMultiplier = g_cvTankSpeedBoost.FloatValue;
	if (speedMultiplier > 1.0)
	{
		float speed = GetEntPropFloat(caller, Prop_Data, "m_speed");
		speed *= speedMultiplier;
		
		SetVariantFloat(speed);
		AcceptEntityInput(caller, "SetSpeed");
		EmitSoundToAll(SOUND_TANK_SPEED_UP, caller);
	}
}