#if defined _RF2_tank_boss_included
 #endinput
#endif
#define _RF2_tank_boss_included

#pragma semicolon 1
#pragma newdecls required

#define MODEL_TANK_BADASS "models/rf2/boss_bots/boss_tank_badass.mdl"
#define PATH_TRACK_START "rf2_tank_start"
#define ATT_ROCKET_R "rocket_r"
#define ATT_ROCKET_L "rocket_l"
#define ATT_LASER "laser"

#define TANK_BASE_CASH_DROP 350.0
#define ROCKET_ATTACK_COOLDOWN 2.0
#define LASER_ATTACK_COOLDOWN 25.0
#define BARRAGE_ATTACK_COOLDOWN 50.0

#define SND_TANK_LASERSHOOT "rf2/sfx/boss_tank_badass/laser_shoot.wav"
#define SND_TANK_LASERRISE "weapons/teleporter_build_open2.wav"
#define SND_TANK_LASERRISE_END "weapons/sentry_upgrading2.wav"

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
static bool g_bTankDeploying[MAX_EDICTS];
static bool g_bTankSpeedBoost[MAX_EDICTS];

enum
{
	SPECIAL_NONE,
	SPECIAL_LASER,
	SPECIAL_BARRAGE,
};

void BadassTank_Init()
{
	CEntityFactory factory = new CEntityFactory("rf2_tank_boss_badass", BadassTank_OnCreate);
	factory.DeriveFromClass("tank_boss");
	factory.BeginDataMapDesc()
		.DefineFloatField("m_flNextRocketAttackR")
		.DefineFloatField("m_flNextRocketAttackL")
		.DefineFloatField("m_flNextLaserAttack")
		.DefineFloatField("m_flNextBarrageAttack")
		.DefineIntField("m_iSpecialAttack")
		.DefineIntField("m_iActualMaxHealth")
	.EndDataMapDesc();
	factory.Install();
	HookMapStart(BadassTank_OnMapStart);
}

void BadassTank_OnMapStart()
{
	g_iBadassTankModelIndex = PrecacheModel2(MODEL_TANK_BADASS, true);
	AddModelToDownloadsTable(MODEL_TANK_BADASS, false);
	PrecacheSound2(SND_TANK_LASERRISE, true);
	PrecacheSound2(SND_TANK_LASERRISE_END, true);
	AddSoundToDownloadsTable(SND_TANK_LASERSHOOT);
	PrecacheSoundArray(g_szTankLaserVoices, sizeof(g_szTankLaserVoices));
	PrecacheSoundArray(g_szTankBarrageVoices, sizeof(g_szTankBarrageVoices));
}

static void BadassTank_OnCreate(int entity)
{
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", g_iBadassTankModelIndex, _, 0);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", g_iBadassTankModelIndex, _, 1);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", g_iBadassTankModelIndex, _, 2);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", g_iBadassTankModelIndex, _, 3);
	
	float gameTime = GetGameTime();
	SetEntPropFloat(entity, Prop_Data, "m_flNextRocketAttackR", gameTime+ROCKET_ATTACK_COOLDOWN);
	SetEntPropFloat(entity, Prop_Data, "m_flNextRocketAttackL", gameTime+ROCKET_ATTACK_COOLDOWN*1.5);
	SetEntPropFloat(entity, Prop_Data, "m_flNextLaserAttack", gameTime+LASER_ATTACK_COOLDOWN);
	SetEntPropFloat(entity, Prop_Data, "m_flNextBarrageAttack", gameTime+BARRAGE_ATTACK_COOLDOWN);
	SDKHook(entity, SDKHook_Think, Hook_BadassTankThink);
	SDKHook(entity, SDKHook_SpawnPost, Hook_BadassTankSpawnPost);
}

public void Hook_BadassTankSpawnPost(int entity)
{
	SetEntityModel2(entity, MODEL_TANK_BADASS);
	
	// The reason this needs to be done is because Tanks will change their model based on how much damage they have taken
	// in relation to their max health. Setting their max health to 0 AFTER spawning will prevent this behaviour.
	// Making our own damaged models would have to be done manually as the default ones are hardcoded.
	int maxHealth = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
	SetEntProp(entity, Prop_Data, "m_iActualMaxHealth", maxHealth);
	SetEntProp(entity, Prop_Data, "m_iMaxHealth", 0);
	SetSequence(entity, "movement");
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
	RF2_PrintToChatAll("%t", "AllTanksDestroyed");
	CreateTimer(30.0, Timer_CommandReminder, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	RF2_Object_Teleporter.ToggleObjectsStatic(true);
	
	int randomItem;
	char name[MAX_NAME_LENGTH], quality[32];
	bool collector;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerSurvivor(i))
			continue;
		
		collector = (!IsSingleplayer(false) && !g_bPlayerTookCollectorItem[i] && g_iLoopCount == 0 || GetRandomInt(1, 10) <= 2);
		randomItem = collector ? GetRandomCollectorItem(TF2_GetPlayerClass(i)) : GetRandomItemEx(Quality_Genuine);
		GiveItem(i, randomItem, _, true);
		GetItemName(randomItem, name, sizeof(name));
		GetQualityColorTag(GetItemQuality(randomItem), quality, sizeof(quality));
		RF2_PrintToChatAll("%t", "TeleporterItemReward", i, quality, name);
		PrintHintText(i, "%t", "GotItemReward", name);
		TriggerAchievement(i, ACHIEVEMENT_TELEPORTER);
		
		char text[256];
		FormatEx(text, sizeof(text), "%T", "EndLevelCommandReminder", i);
		CRemoveTags(text, sizeof(text));
		PrintCenterText(i, text);
	}
	
	StunRadioWave();
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "obj_*")) != INVALID_ENT)
	{
		if (GetEntTeam(entity) == TEAM_ENEMY)
		{
			SetEntityHealth(entity, 1);
			RF_TakeDamage(entity, 0, 0, MAX_DAMAGE, DMG_PREVENT_PHYSICS_FORCE);
		}
	}
	
	RF2_GameRules gamerules = GetRF2GameRules();
	if (gamerules.IsValid())
	{
		gamerules.FireOutput("OnTankDestructionComplete");
	}
}

public Action Timer_CommandReminder(Handle timer)
{
	RF2_PrintToChatAll("%t", "EndLevelCommandReminder");
	char text[256];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerSurvivor(i) || IsFakeClient(i))
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
			CreateTankBoss(badass);
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
	if (!RF2_IsEnabled() || !g_bRoundActive || !g_bTankBossMode)
		return Plugin_Continue;
		
	CreateTankBoss(badass);
	return Plugin_Continue;
}

static int CreateTankBoss(bool badass=false)
{
	ArrayList spawnPoints = new ArrayList();
	int tankBoss = INVALID_ENT;
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
		return INVALID_ENT;
	}
	
	spawn = spawnPoints.Get(GetRandomInt(0, spawnPoints.Length-1));
	delete spawnPoints;
	float pos[3], angles[3];
	GetEntPos(spawn, pos);
	GetEntPropVector(spawn, Prop_Data, "m_angAbsRotation", angles);
	angles[0] = 0.0;
	angles[2] = 0.0;
	
	if (!badass)
	{
		tankBoss = CreateEntityByName("tank_boss");
	}
	else
	{
		tankBoss = CreateEntityByName("rf2_tank_boss_badass");
	}
	
	int health = RoundToFloor(float(g_cvTankBaseHealth.IntValue) * (1.0 + (float(RF2_GetEnemyLevel()-1) * g_cvTankHealthScale.FloatValue)));
	if (IsSingleplayer(false))
	{
		health = RoundToFloor(float(health) * 0.75);
	}
	else
	{
		health = RoundToFloor(float(health) * (1.0 + 0.2*float(RF2_GetSurvivorCount()-1)));
	}
	
	SetEntProp(tankBoss, Prop_Data, "m_iHealth", health);
	SetEntProp(tankBoss, Prop_Data, "m_iMaxHealth", health);
	float speed = g_cvTankBaseSpeed.FloatValue;
	SetEntPropFloat(tankBoss, Prop_Data, "m_speed", speed);
	TeleportEntity(tankBoss, pos, angles);
	DispatchSpawn(tankBoss);
	RF2_HealthText text = CreateHealthText(tankBoss, 230.0, 35.0, badass ? "BADASS TANK" : "TANK");
	if (badass)
	{
		text.SetHealthColor(HEALTHCOLOR_HIGH, {0, 75, 200, 255});
	}
	else
	{
		text.SetHealthColor(HEALTHCOLOR_HIGH, {70, 150, 255, 255});
	}
	
	g_bTankDeploying[tankBoss] = false;
	g_bTankSpeedBoost[tankBoss] = false;
	SDKHook(tankBoss, SDKHook_Think, Hook_TankBossThink);
	g_iTanksSpawned++;
	
	int pitch = SNDPITCH_NORMAL;
	if (g_iTanksSpawned > 1)
	{
		pitch = SNDPITCH_HIGH;
	}
	
	EmitSoundToAll(SND_BOSS_SPAWN, _, _, _, _, _, pitch);
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
			int maxHealth;
			if (IsTankBadass(entity))
			{
				maxHealth = GetEntProp(entity, Prop_Data, "m_iActualMaxHealth");
			}
			else
			{
				maxHealth = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
			}			
			
			if (health < RoundToFloor(float(maxHealth) * g_cvTankBoostHealth.FloatValue))
			{
				g_bTankSpeedBoost[entity] = true;
				float speed = GetEntPropFloat(entity, Prop_Data, "m_speed");
				SetEntPropFloat(entity, Prop_Data, "m_speed", speed * value);
				EmitSoundToAll(SND_TANK_SPEED_UP, entity);
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

	bool wasSharingEnabled = IsItemSharingEnabled();
	g_iTanksKilledObjective++;
	g_iTotalTanksKilled++;
	if (g_iTanksKilledObjective >= g_iTankKillRequirement)
	{
		if (wasSharingEnabled && !IsItemSharingEnabled())
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerSurvivor(i))
				{
					PrintKeyHintText(i, "%t", "ItemSharingDisabled");
				}
			}
		}
		
		EndTankDestructionMode();
	}
}

// ---------------------------------------------- Badass Tank -----------------------------------------------------------

public void Hook_BadassTankThink(int entity)
{
	float gameTime = GetGameTime();
	int special = GetEntProp(entity, Prop_Data, "m_iSpecialAttack");
	if (special != SPECIAL_BARRAGE)
	{
		float nextRocketAttack[2];
		nextRocketAttack[0] = GetEntPropFloat(entity, Prop_Data, "m_flNextRocketAttackR");
		nextRocketAttack[1] = GetEntPropFloat(entity, Prop_Data, "m_flNextRocketAttackL");

		// is it time to fire a rocket?
		if (gameTime >= nextRocketAttack[0] || gameTime >= nextRocketAttack[1])
		{
			char attachmentName[16];
			attachmentName = gameTime >= nextRocketAttack[0] ? ATT_ROCKET_R : ATT_ROCKET_L;
			int attachment = LookupEntityAttachment(entity, attachmentName);
			if (attachment > 0)
			{
				float pos[3], angles[3];
				const float speed = 1100.0;
				const float damage = 150.0;
				GetEntityAttachment(entity, attachment, pos, NULL_VECTOR);
				GetEntPropVector(entity, Prop_Send, "m_angRotation", angles);
				
				int rocket = ShootProjectile(entity, "tf_projectile_sentryrocket", pos, angles, speed, damage, -10.0);
				SetEntityMoveType(rocket, MOVETYPE_FLYGRAVITY);
				CreateTimer(0.1, Timer_TankRocketFixAngles, EntIndexToEntRef(rocket), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				EmitSoundToAll(SND_LAW_FIRE, entity, _, _, _, _, _, _, pos);

				float attackRate, nextAttackTime;
				switch (RF2_GetDifficulty())
				{
					case DIFFICULTY_STEEL: attackRate = 0.75;
					case DIFFICULTY_TITANIUM: attackRate = 0.5;
					default: attackRate = 1.0;
				}

				nextAttackTime = ROCKET_ATTACK_COOLDOWN * attackRate;
				
				if (strcmp(attachmentName, ATT_ROCKET_L) == 0)
				{
					AddGesture(entity, "fire_rocket_l");
					SetEntPropFloat(entity, Prop_Data, "m_flNextRocketAttackL", gameTime+nextAttackTime*1.5);
				}
				else
				{
					AddGesture(entity, "fire_rocket_r");
					SetEntPropFloat(entity, Prop_Data, "m_flNextRocketAttackR", gameTime+nextAttackTime);
				}
			}
		}
	}
	
	float nextLaserAttack = GetEntPropFloat(entity, Prop_Data, "m_flNextLaserAttack");
	float nextBarrageAttack = GetEntPropFloat(entity, Prop_Data, "m_flNextBarrageAttack");
	if (special == SPECIAL_NONE)
	{
		// decide our next special attack if we can use one
		int newSpecial;
		if (gameTime >= nextLaserAttack || gameTime >= nextBarrageAttack)
		{
			// both are ready? decide randomly
			if (gameTime >= nextLaserAttack && gameTime >= nextBarrageAttack)
			{
				newSpecial = GetRandomInt(SPECIAL_LASER, SPECIAL_BARRAGE);
			}
			else
			{
				newSpecial = gameTime >= nextLaserAttack ? SPECIAL_LASER : SPECIAL_BARRAGE;
			}
			
			// don't waste our special attacks if there are no enemies nearby
			float pos[3];
			GetEntPos(entity, pos);
			pos[2] += 100.0;
			int team = GetEntTeam(entity);
			int enemyTeam = team == TEAM_ENEMY ? TEAM_SURVIVOR : TEAM_ENEMY;
			
			if (newSpecial != SPECIAL_NONE 
			&& (GetNearestPlayer(pos, _, 2000.0, enemyTeam, true) != -1 || GetNearestEntity(pos, "obj_*", _, 2000.0, enemyTeam, true) != -1))
			{
				switch (newSpecial)
				{
					case SPECIAL_LASER:
					{
						special = newSpecial;
						SetEntProp(entity, Prop_Data, "m_iSpecialAttack", special);
						float duration = AddGesture(entity, "eye_rise", _, _, 0.25);
						
						int num = GetRandomInt(0, sizeof(g_szTankLaserVoices)-1);
						EmitSoundToAll(g_szTankLaserVoices[num], entity, _, 120);
						EmitSoundToAll(g_szTankLaserVoices[num], entity, _, 120);
						EmitSoundToAll(SND_TANK_LASERRISE, entity, _, 120);
						
						if (nextBarrageAttack - GetGameTime() <= 10.0)
						{
							SetEntPropFloat(entity, Prop_Data, "m_flNextBarrageAttack", nextBarrageAttack + duration + 10.0);
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
							SetEntProp(entity, Prop_Data, "m_iSpecialAttack", special);
							CBaseAnimatingOverlay(entity).RemoveAllGestures();
							int num = GetRandomInt(0, sizeof(g_szTankBarrageVoices)-1);
							EmitSoundToAll(g_szTankBarrageVoices[num], entity, _, 120);
							EmitSoundToAll(g_szTankBarrageVoices[num], entity, _, 120);
							EmitSoundToAll(SND_TANK_LASERRISE, entity, _, 120);
							
							float duration = AddGesture(entity, "rocket_turn_up", _, _, 0.2, 2);
							if (nextLaserAttack - GetGameTime() <= 10.0)
							{
								SetEntPropFloat(entity, Prop_Data, "m_flNextLaserAttack", nextLaserAttack + duration + 10.0);
							}
						}
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
			if (!IsPlayingGesture(entity, "eye_rise"))
			{
				if (!IsPlayingGesture(entity, "eye_up"))
				{
					AddGesture(entity, "eye_up", _, false);
					
					float duration;
					switch (RF2_GetDifficulty())
					{
						//case DIFFICULTY_STEEL: duration = 12.5;
						//case DIFFICULTY_TITANIUM: duration = 17.0;
						default: duration = 9.0;
					}
					
					StopSound(entity, SNDCHAN_AUTO, SND_TANK_LASERRISE);
					EmitSoundToAll(SND_TANK_LASERRISE_END, entity, _, 120);
					CreateTimer(duration, Timer_EndLaserAttack, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
					SetEntPropFloat(entity, Prop_Data, "m_flNextBarrageAttack", nextBarrageAttack+duration);
				}
				
				static float nextShot[2048];
				float tickedTime = GetTickedTime();
				if (tickedTime >= nextShot[entity])
				{
					float pos[3];
					const float range = 2500.0;
					int team = GetEntTeam(entity);
					int enemyTeam = team == TEAM_ENEMY ? TEAM_SURVIVOR : TEAM_ENEMY;
					int attachment = LookupEntityAttachment(entity, ATT_LASER);
					GetEntityAttachment(entity, attachment, pos, NULL_VECTOR);
					int nearestPlayer = GetNearestPlayer(pos, _, range, enemyTeam, true);
					int nearestBuilding = GetNearestEntity(pos, "obj_*", _, range, enemyTeam, true);
					
					float playerPos[3], buildingPos[3];
					float playerDist = -1.0;
					if (nearestPlayer != -1)
					{
						GetEntPos(nearestPlayer, playerPos);
						playerDist = GetVectorDistance(pos, playerPos, true);
						playerPos[2] += 30.0;
					}
					
					int target;
					
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
					
					if (target > 0)
					{
						// Face our target
						float rot[3], angles[3];
						GetEntPropVector(entity, Prop_Send, "m_angRotation", rot);
						
						if (target == nearestPlayer)
						{
							GetVectorAnglesTwoPoints(pos, playerPos, angles);
						}
						else
						{
							GetVectorAnglesTwoPoints(pos, buildingPos, angles);
						}
						
						int poseParam = CBaseAnimating(entity).LookupPoseParameter("eye_look");
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
						
						CBaseAnimating(entity).SetPoseParameter(poseParam, value);
						float laserPos[3], dir[3];
						GetAngleVectors(angles, dir, NULL_VECTOR, NULL_VECTOR);
						NormalizeVector(dir, dir);
						laserPos[0] = pos[0] + dir[0] * 15.0;
						laserPos[1] = pos[1] + dir[1] * 15.0;
						laserPos[2] = pos[2] + 10.0;
						
						const float speed = 1000.0;
						const float damage = 35.0;
						int laser = ShootProjectile(entity, "tf_projectile_rocket", pos, angles, speed, damage);
						SetEntityModel2(laser, MODEL_INVISIBLE);
						EmitSoundToAll(SND_TANK_LASERSHOOT, entity, _, 120);
						SpawnInfoParticle("drg_cow_rockettrail_fire_blue", pos, _, laser);
						SpawnInfoParticle("teleported_flash", laserPos, 0.1);
						float fireRate = float(GetEntProp(entity, Prop_Data, "m_iHealth")) / float(GetEntProp(entity, Prop_Data, "m_iActualMaxHealth"));
						fireRate = fmax(fireRate, 0.5);
						nextShot[entity] = tickedTime + (0.2 * fireRate);
					}
				}
			}
		}
		
		case SPECIAL_BARRAGE:
		{
			if (!IsPlayingGesture(entity, "rocket_turn_up"))
			{
				if (!IsPlayingGesture(entity, "rocket_up"))
				{
					AddGesture(entity, "rocket_up", _, false);
					StopSound(entity, SNDCHAN_AUTO, SND_TANK_LASERRISE);
					EmitSoundToAll(SND_TANK_LASERRISE_END, entity, _, 120);
					
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
						CreateTimer(time, Timer_TankFireHomingRockets, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
						time += 0.2;
					}
					
					CreateTimer(time, Timer_EndBarrageAttack, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
					SetEntPropFloat(entity, Prop_Data, "m_flNextLaserAttack", nextLaserAttack+time);
				}
			}
		}
	}
}

public Action Timer_TankFireHomingRockets(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return Plugin_Continue;
	
	int attachment[2];
	float pos[3];
	attachment[0] = LookupEntityAttachment(entity, ATT_ROCKET_L);
	attachment[1] = LookupEntityAttachment(entity, ATT_ROCKET_R);
	
	for (int i = 0; i <= 1; i++)
	{
		GetEntityAttachment(entity, attachment[i], pos, NULL_VECTOR);
		const float speed = 1000.0;
		const float damage = 100.0;
		
		float angles[3];
		angles[0] = -90.0;
		angles[1] = GetRandomFloat(-180.0, 180.0);
		
		int rocket = ShootProjectile(entity, "tf_projectile_sentryrocket", pos, angles, speed, damage, -10.0);
		SetEntityMoveType(rocket, MOVETYPE_FLYGRAVITY);
		CreateTimer(0.1, Timer_TankRocketFixAngles, EntIndexToEntRef(rocket), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	EmitSoundToAll(SND_LAW_FIRE, entity);
	AddGesture(entity, "rocket_shoot_up", _, _, _, 2);
	return Plugin_Continue;
}

public Action Timer_EndLaserAttack(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return Plugin_Continue;

	SetEntProp(entity, Prop_Data, "m_iSpecialAttack", SPECIAL_NONE);
	SetEntPropFloat(entity, Prop_Data, "m_flNextLaserAttack", GetGameTime()+LASER_ATTACK_COOLDOWN);
	CBaseAnimatingOverlay(entity).RemoveAllGestures();
	return Plugin_Continue;
}

public Action Timer_EndBarrageAttack(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return Plugin_Continue;

	SetEntProp(entity, Prop_Data, "m_iSpecialAttack", SPECIAL_NONE);
	SetEntPropFloat(entity, Prop_Data, "m_flNextBarrageAttack", GetGameTime()+BARRAGE_ATTACK_COOLDOWN);
	CBaseAnimatingOverlay(entity).RemoveAllGestures();
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

bool IsTankBadass(int entity)
{
	static char classname[128];
	GetEntityClassname(entity, classname, sizeof(classname));
	return strcmp2(classname, "rf2_tank_boss_badass");
}

bool IsTank(int entity)
{
	static char classname[128];
	GetEntityClassname(entity, classname, sizeof(classname));
	return StrContains(classname, "tank_boss") != -1;
}
