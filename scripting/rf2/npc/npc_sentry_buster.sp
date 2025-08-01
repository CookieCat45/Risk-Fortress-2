#pragma semicolon 1
#pragma newdecls required

// Original Sentry Buster NPC plugin by Kenzzer: https://github.com/Kenzzer/sm_plugins/tree/master/sentrybuster
#define MODEL_BUSTER "models/bots/demo/bot_sentry_buster.mdl"
#define BUSTER_BASE_HEALTH 2500.0
#define BUSTER_BASE_DAMAGE 1000.0

enum ShakeCommand_t
{
	SHAKE_START = 0,
	SHAKE_STOP,
	SHAKE_AMPLITUDE,
	SHAKE_FREQUENCY,
	SHAKE_START_RUMBLEONLY,
	SHAKE_START_NORUMBLE,
};

static CEntityFactory g_Factory;
static ConVar g_cvPhysPush;
ConVar g_cvSuicideBombRange;
static int g_Busters;

ConVar g_cvBusterSpawnInterval;

#include "actions/sentry_buster/main.sp"
#include "actions/sentry_buster/detonate.sp"

methodmap RF2_SentryBuster < RF2_NPC_Base
{
	public RF2_SentryBuster(int entIndex)
	{
		return view_as<RF2_SentryBuster>(entIndex);
	}
	
	public bool IsValid()
	{
		if (!IsValidEntity2(this.index))
		{
			return false;
		}
		
		return CEntityFactory.GetFactoryOfEntity(this.index) == g_Factory;
	}
	
	public static void Init()
	{
		g_Factory = new CEntityFactory("rf2_npc_sentry_buster", OnCreate, OnRemove);
		g_Factory.DeriveFromFactory(GetBaseNPCFactory());
		g_Factory.SetInitialActionFactory(RF2_SentryBusterMainAction.GetFactory());
		g_Factory.BeginDataMapDesc()
			.DefineIntField("m_moveXPoseParameter")
			.DefineIntField("m_moveYPoseParameter")
			.DefineIntField("m_idleSequence")
			.DefineIntField("m_runSequence")
			.DefineIntField("m_airSequence")
			.DefineIntField("m_iRepathAttempts")
			.DefineEntityField("m_hDispenser")
		.EndDataMapDesc();
		g_Factory.Install();
		
		HookMapStart(SentryBuster_OnMapStart);
		g_cvPhysPush = FindConVar("phys_pushscale");
		g_cvSuicideBombRange = FindConVar("tf_bot_suicide_bomb_range");
		g_cvBusterSpawnInterval = CreateConVar("rf2_sentry_buster_spawn_interval", "100", "Interval in seconds that Sentry Busters will spawn if RED has sentries.", FCVAR_NOTIFY, true, 0.0);
	}
	
	public static RF2_SentryBuster Create(int target, int team=TEAM_ENEMY)
	{
		RF2_SentryBuster buster = RF2_SentryBuster(CreateEntityByName("rf2_npc_sentry_buster"));
		buster.Team = team;
		buster.Dispenser = INVALID_ENT;
		buster.Target = target;
		if (team == TEAM_SURVIVOR)
		{
			buster.SetRenderColor(255, 100, 100);
			return buster;
		}
		
		float targetPos[3], pos[3], mins[3], maxs[3];
		GetEntPos(target, targetPos);
		if (team == TEAM_ENEMY && IsBuilding(target))
		{
			int builder = GetEntPropEnt(target, Prop_Send, "m_hBuilder");
			if (IsValidClient(builder))
			{
				ShowAnnotation(builder, _, "Sentry Buster's Target", 8.0, target);
				int dispenser = GetBuiltObject(builder, TFObject_Dispenser);
				if (IsValidEntity2(dispenser))
				{
					buster.Dispenser = dispenser;
				}
			}
		}
		
		buster.BaseNpc.GetBodyMins(mins);
		buster.BaseNpc.GetBodyMaxs(maxs);
		bool success;
		if (GetRF2GameRules().UseTeamSpawnForEnemies)
		{
			int spawnPoint = INVALID_ENT;
			ArrayList spawnPoints = new ArrayList();
			while ((spawnPoint = FindEntityByClassname(spawnPoint, "info_player_teamspawn")) != INVALID_ENT)
			{
				if (GetEntTeam(spawnPoint) != team || GetEntProp(spawnPoint, Prop_Data, "m_bDisabled"))
					continue;
				
				GetEntPos(spawnPoint, pos);
				TR_TraceHullFilter(pos, pos, mins, maxs, MASK_NPCSOLID_BRUSHONLY, TraceFilter_WallsOnly, TRACE_WORLD_ONLY);
				if (!TR_DidHit())
				{
					spawnPoints.Push(spawnPoint);
				}
			}
			
			if (spawnPoints.Length > 0)
			{
				spawnPoint = spawnPoints.Get(GetRandomInt(0, spawnPoints.Length-1));
				GetEntPos(spawnPoint, pos);
				buster.Teleport(pos);
				success = true;
			}
			
			delete spawnPoints;
		}
		else if (GetSpawnPoint(targetPos, pos, 2500.0, 25000.0, TEAM_SURVIVOR, true, mins, maxs, MASK_NPCSOLID_BRUSHONLY, 50.0, target))
		{
			buster.Teleport(pos);
			success = true;
		}
		
		if (!success)
		{
			RemoveEntity(buster.index);
		}
		else
		{
			ArrayList playerList = new ArrayList();
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && IsPlayerAlive(i) && IsPlayerSurvivor(i))
				{
					playerList.Push(i);
				}
			}
			
			if (playerList.Length > 0)
			{
				SpeakResponseConcept_MVM(playerList.Get(GetRandomInt(0, playerList.Length-1)), "TLK_MVM_SENTRY_BUSTER");
			}
			
			delete playerList;
		}
		
		return success ? buster : RF2_SentryBuster(INVALID_ENT);
	}
	
	property int RepathAttempts
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iRepathAttempts");
		}
		
		public set (int value)
		{
			this.SetProp(Prop_Data, "m_iRepathAttempts", value);
		}
	}

	property int Dispenser
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hDispenser");
		}

		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hDispenser", value);
		}
	}
	
	public void Detonate()
	{
		float pos[3];
		this.GetAbsOrigin(pos);
		TE_TFParticle("hightower_explosion", pos);
		EmitGameSoundToAll("MVM.SentryBusterExplode", SOUND_FROM_WORLD, .origin = pos);
		EmitGameSoundToAll("MVM.SentryBusterExplode", SOUND_FROM_WORLD, .origin = pos);
		UTIL_ScreenShake(pos, 25.0, 5.0, 5.0, 1000.0, SHAKE_START, false);
		ArrayList victims = new ArrayList();
		int entity = MaxClients+1;
		while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT)
		{
			if (!IsValidEntity2(entity) || entity == this.index)
			{
				continue;
			}
			
			CBaseEntity victim = CBaseEntity(entity);
			if (IsCombatChar(entity))
			{
				victims.Push(victim);
			}
		}

		float center[3], victimCenter[3], delta[3];
		this.WorldSpaceCenter(center);
		IVision vision = this.MyNextBotPointer().GetVisionInterface();
		
		for(int i = 0, max = victims.Length; i < max; ++i)
		{
			CBaseCombatCharacter victim = victims.Get(i);
			if (this.Team == TEAM_SURVIVOR && GetEntTeam(victim.index) == TEAM_SURVIVOR)
				continue;
			
			victim.WorldSpaceCenter(victimCenter);
			SubtractVectors(victimCenter, center, delta);

			if (GetVectorLength(delta) > g_cvSuicideBombRange.FloatValue)
			{
				continue;
			}
			
			if (victim.index > 0 && victim.index <= MaxClients)
			{
				int white[4] = { 255, 255, 255, 255 };
				UTIL_ScreenFade(victim.index, white, 1.0, 0.1, FFADE_IN);
			}
			
			if (vision.IsLineOfSightClearToEntity(victim.index))
			{
				float damage;
				if (IsBuilding(victim.index))
				{
					damage = float(victim.GetProp(Prop_Data, "m_iHealth")) * 10.0;
					RF_TakeDamage(victim.index, this.index, this.index, damage, DMG_BLAST);
				}
				else
				{
					if (victim.index <= MaxClients && IsPlayerSurvivor(victim.index) && !IsPlayerMinion(victim.index))
					{
						// don't instantly kill Survivors, instead do 90% max hp
						damage = float(RF2_GetCalculatedMaxHealth(victim.index)) * 0.9;
					}
					else
					{
						damage = BUSTER_BASE_DAMAGE;
					}
					
					float force[3];
					CalculateMeleeDamageForce(damage, delta, 1.0, force);
					if (this.Team == TEAM_SURVIVOR)
					{
						RF_TakeDamage(victim.index, this.index, this.GetPropEnt(Prop_Data, "m_hOwnerEntity"),
							GetItemMod(ItemStrange_HumanCannonball, 2), DMG_BLAST, ItemStrange_HumanCannonball);
					}
					else
					{
						RF_TakeDamage(victim.index, this.index, this.index, damage, DMG_BLAST, _, _, force, center);
					}
				}
			}
		}
		
		delete victims;
		if (this.Team != TEAM_SURVIVOR)
		{
			ArrayList playerList = new ArrayList();
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && IsPlayerAlive(i) && IsPlayerSurvivor(i))
				{
					playerList.Push(i);
				}
			}
			
			if (playerList.Length > 0)
			{
				SpeakResponseConcept_MVM(playerList.Get(GetRandomInt(0, playerList.Length-1)), "TLK_MVM_SENTRY_BUSTER_DOWN");
			}
			
			delete playerList;
		}
		
		RemoveEntity(this.index);
	}
}

void SentryBuster_OnMapStart()
{
	g_Busters = 0;
	PrecacheScriptSound("MVM.SentryBusterExplode");
	PrecacheScriptSound("MVM.SentryBusterSpin");
	PrecacheScriptSound("MVM.SentryBusterLoop");
	PrecacheScriptSound("MVM.SentryBusterIntro");
	PrecacheScriptSound("MVM.SentryBusterStep");
	PrecacheScriptSound("Announcer.MVM_Sentry_Buster_Alert");
	PrecacheScriptSound("Announcer.MVM_Sentry_Buster_Alert_Another");
	PrecacheModel2(MODEL_BUSTER, true);
}

static void OnCreate(RF2_SentryBuster buster)
{
	CBaseNPC npc = buster.BaseNpc;
	buster.Path.SetMinLookAheadDistance(1024.0);
	int health = RoundToFloor(BUSTER_BASE_HEALTH * GetEnemyHealthMult());
	buster.SetProp(Prop_Data, "m_iHealth", health);
	buster.SetPropFloat(Prop_Data, "m_flModelScale", 1.75);
	
	// We robots, don't bleed
	buster.SetProp(Prop_Data, "m_bloodColor", -1);
	buster.SetModel(MODEL_BUSTER);
	buster.SetProp(Prop_Data, "m_moveXPoseParameter", buster.LookupPoseParameter("move_x"));
	buster.SetProp(Prop_Data, "m_moveYPoseParameter", buster.LookupPoseParameter("move_y"));
	buster.SetProp(Prop_Data, "m_idleSequence", buster.LookupSequence("Stand_MELEE"));
	buster.SetProp(Prop_Data, "m_runSequence", buster.LookupSequence("Run_MELEE"));
	buster.SetProp(Prop_Data, "m_airSequence", buster.LookupSequence("a_jumpfloat_ITEM1"));
	buster.Target = INVALID_ENT;
	buster.Hook_HandleAnimEvent(HandleAnimEvent);
	buster.SetProp(Prop_Data, "m_iTeamNum", TEAM_ENEMY);
	buster.SetProp(Prop_Send, "m_nSkin", 1);
	
	npc.flStepSize = 18.0;
	npc.flGravity = 800.0;
	npc.flAcceleration = 2000.0;
	npc.flJumpHeight = 150.0;
	npc.flWalkSpeed = 440.0;
	npc.flRunSpeed = 440.0;
	npc.flDeathDropHeight = 99999999.0;
	
	buster.Spawn();
	buster.Activate();
	buster.SetGlow(true);
	buster.SetGlowColor(0, 100, 255, 255);
	npc.SetBodyMins(PLAYER_MINS);
	npc.SetBodyMaxs(PLAYER_MAXS);
	RF2_HealthText text = CreateHealthText(buster.index, 150.0, 20.0, "SENTRY BUSTER");
	text.SetHealthColor(HEALTHCOLOR_HIGH, {70, 150, 255, 255});
}

static void OnRemove(RF2_SentryBuster buster)
{
	StopSound(buster.index, SNDCHAN_STATIC, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
}

static MRESReturn HandleAnimEvent(int actor, Handle params)
{
	int event = DHookGetParamObjectPtrVar(params, 1, 0, ObjectValueType_Int);
	if (event == 7001)
	{
		if (GetEntTeam(actor) == TEAM_SURVIVOR)
		{
			char sample[PLATFORM_MAX_PATH];
			int random = GetRandomInt(1, 18);
			if (random > 9)
			{
				FormatEx(sample, sizeof(sample), "mvm/player/footsteps/robostep_%i.wav", random);
			}
			else
			{
				FormatEx(sample, sizeof(sample), "mvm/player/footsteps/robostep_0%i.wav", random);
			}
			
			EmitSoundToAll(sample, actor);
		}
		else
		{
			EmitGameSoundToAll("MVM.SentryBusterStep", actor);
		}
	}

	return MRES_Ignored;
}

void CalculateMeleeDamageForce(float damage, const float vecMeleeDir[3], float scale, float buffer[3])
{
	// Calculate an impulse large enough to push a 75kg man 4 in/sec per point of damage
	float forceScale = damage * 75 * 4;
	float vecForce[3];
	NormalizeVector(vecMeleeDir, vecForce);
	ScaleVector(vecForce, forceScale);
	ScaleVector(vecForce, g_cvPhysPush.FloatValue);
	ScaleVector(vecForce, scale);
	CopyVectors(vecForce, buffer);
}

// Starts after grace period
public Action Timer_BusterSpawnWave(Handle timer)
{
	if (!g_bRoundActive || IsStageCleared() || IsInFinalMap())
		return Plugin_Stop;
	
	if (g_bRaidBossMode || IsSentryBusterActive() || !GetRF2GameRules().AllowEnemySpawning)
		return Plugin_Continue;
	
	bool sentryActive;
	int entity = MaxClients+1;
	int owner;
	while ((entity = FindEntityByClassname(entity, "obj_sentrygun")) != INVALID_ENT)
	{
		owner = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
		if (IsValidClient(owner) && IsPlayerSurvivor(owner))
		{
			// don't count disposable sentries because we don't care about them
			if (IsSentryDisposable(entity))
				continue;
			
			sentryActive = true;
			break;
		}
	}
	
	if (sentryActive)
	{
		g_flBusterSpawnTime -= 1.0;
		if (g_flBusterSpawnTime <= 0.0)
		{
			DoSentryBusterWave();
			g_flBusterSpawnTime = g_cvBusterSpawnInterval.FloatValue;
		}
		else if (g_flBusterSpawnTime <= 10.0)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerSurvivor(i) && !IsPlayerMinion(i) && TF2_GetPlayerClass(i) == TFClass_Engineer)
				{
					PrintCenterText(i, "%t", "SentryBusterWarn", RoundToFloor(g_flBusterSpawnTime));
				}
			}
		}
	}
	else
	{
		g_flBusterSpawnTime = fmin(g_flBusterSpawnTime+8.0, g_cvBusterSpawnInterval.FloatValue);
	}

	return Plugin_Continue;
}

void DoSentryBusterWave()
{
	ArrayList sentryList = new ArrayList();
	int builder;
	int entity = MaxClients+1;
	
	while ((entity = FindEntityByClassname(entity, "obj_sentrygun")) != INVALID_ENT)
	{
		if (GetEntTeam(entity) != TEAM_SURVIVOR)
			continue;
		
		builder = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
		if (builder <= 0)
			continue;
		
		if (IsSentryDisposable(entity))
			continue;
		
		sentryList.Push(entity);
	}
	
	for (int i = 0; i < sentryList.Length; i++)
	{
		RF2_SentryBuster buster = RF2_SentryBuster.Create(sentryList.Get(i));
		if (!buster.IsValid())
		{
			CreateTimer(1.0, Timer_BusterSpawnRetry, EntIndexToEntRef(sentryList.Get(i)), TIMER_FLAG_NO_MAPCHANGE);
		}
		else if (buster.Team != TEAM_SURVIVOR)
		{
			EmitGameSoundToAll("MVM.SentryBusterLoop", buster.index);
			EmitGameSoundToAll("MVM.SentryBusterIntro", buster.index);
		}
	}
	
	if (sentryList.Length > 0)
	{
		if (g_Busters == 0)
		{
			EmitGameSoundToAll("Announcer.MVM_Sentry_Buster_Alert");
		}
		else
		{
			EmitGameSoundToAll("Announcer.MVM_Sentry_Buster_Alert_Another");
		}
		
		g_Busters++;
	}
	
	delete sentryList;
}

static void Timer_BusterSpawnRetry(Handle timer, int sentry)
{
	if (IsStageCleared() || (sentry = EntRefToEntIndex(sentry)) == INVALID_ENT || g_bRaidBossMode || !GetRF2GameRules().AllowEnemySpawning)
		return;
	
	RF2_SentryBuster buster = RF2_SentryBuster.Create(sentry);
	if (!buster.IsValid())
	{
		CreateTimer(1.0, Timer_BusterSpawnRetry, EntIndexToEntRef(sentry), TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (buster.Team != TEAM_SURVIVOR)
	{
		EmitGameSoundToAll("MVM.SentryBusterLoop", buster.index);
		EmitGameSoundToAll("MVM.SentryBusterIntro", buster.index);
	}
}

bool IsSentryBusterActive()
{
	int buster = MaxClients+1;
	while ((buster = FindEntityByClassname(buster, "rf2_npc_sentry_buster")) != INVALID_ENT)
	{
		if (GetEntTeam(buster) == TEAM_ENEMY)
			return true;
	}
	
	return false;
}
