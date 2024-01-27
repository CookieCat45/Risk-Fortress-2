#if defined _RF2_sentry_buster_included
 #endinput
#endif
#define _RF2_sentry_buster_included

#pragma semicolon 1
#pragma newdecls required

// Original Sentry Buster NPC plugin by Kenzzer: https://github.com/Kenzzer/sm_plugins/tree/master/sentrybuster
#define MODEL_BUSTER "models/bots/demo/bot_sentry_buster.mdl"
#define BUSTER_BASE_HEALTH 1500.0
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
		.EndDataMapDesc();
		g_Factory.Install();
		
		HookMapStart(SentryBuster_OnMapStart);
		g_cvPhysPush = FindConVar("phys_pushscale");
		g_cvSuicideBombRange = FindConVar("tf_bot_suicide_bomb_range");
		g_cvBusterSpawnInterval = CreateConVar("rf2_sentry_buster_spawn_interval", "120", "Interval in seconds that Sentry Busters will spawn if RED has sentries.", FCVAR_NOTIFY, true, 0.0);
	}
	
	public static RF2_SentryBuster Create(int target)
	{
		RF2_SentryBuster buster = RF2_SentryBuster(CreateEntityByName("rf2_npc_sentry_buster"));
		buster.Target = target;
		float targetPos[3], pos[3], mins[3], maxs[3];
		GetEntPos(target, targetPos);
		buster.BaseNpc.GetBodyMins(mins);
		buster.BaseNpc.GetBodyMaxs(maxs);
		const int maxAttempts = 50;
		bool success;
		for (int i = 0; i <= maxAttempts; i++)
		{
			if (GetSpawnPoint(targetPos, pos, 2000.0, 7000.0+float(i*100), TEAM_SURVIVOR, true, mins, maxs, MASK_NPCSOLID, 40.0))
			{
				buster.Teleport(pos);
				success = true;
				break;
			}
		}
		
		if (!success)
		{
			RemoveEntity2(buster.index);
		}
		
		return success ? buster : RF2_SentryBuster(INVALID_ENT_REFERENCE);
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
	
	public void Detonate()
	{
		float pos[3];
		this.GetAbsOrigin(pos);
		
		TE_TFParticle("explosionTrail_seeds_mvm", pos);
		TE_TFParticle("fluidSmokeExpl_ring_mvm", pos);
		EmitGameSoundToAll("MVM.SentryBusterExplode", SOUND_FROM_WORLD, .origin = pos);
		EmitGameSoundToAll("MVM.SentryBusterExplode", SOUND_FROM_WORLD, .origin = pos);
		EmitGameSoundToAll("MVM.SentryBusterExplode", SOUND_FROM_WORLD, .origin = pos);
		UTIL_ScreenShake(pos, 25.0, 5.0, 5.0, 1000.0, SHAKE_START, false);
		ArrayList victims = new ArrayList();
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "*")) != -1)
		{
			if (entity < 1 || entity == this.index)
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
				bool boss = (victim.index <= MaxClients && IsBoss(victim.index));
				
				if (IsBuilding(victim.index))
				{
					damage = float(victim.GetProp(Prop_Data, "m_iHealth")) * 10.0;
				}
				else
				{
					damage = BUSTER_BASE_DAMAGE;

					if (boss)
					{
						damage *= 0.1;
					}
				}
				
				if (!boss)
				{
					float force[3];
					CalculateMeleeDamageForce(damage, delta, 1.0, force);
					SDKHooks_TakeDamage2(victim.index, this.index, this.index, damage, DMG_BLAST, _, force, center);
				}
				else
				{
					SDKHooks_TakeDamage2(victim.index, this.index, this.index, damage, DMG_BLAST|DMG_PREVENT_PHYSICS_FORCE, _, _, center);
				}
			}
		}
		
		delete victims;
		
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
		RemoveEntity2(this.index);
	}
	
	public bool IsLOSClearFromTarget(int target, bool checkGlass = true)
	{
		if (!IsValidEntity2(target))
		{
			return false;
		}
		int traceEnt;
		float eyePos[3], targetPos[3];
		this.WorldSpaceCenter(eyePos);
		CBaseEntity(target).WorldSpaceCenter(targetPos);
		if (IsValidClient(target))
		{
			GetClientEyePosition(target, targetPos);
		}
		
		int flags = CONTENTS_SOLID | CONTENTS_MOVEABLE | CONTENTS_MIST | CONTENTS_MONSTERCLIP;
		if (checkGlass)
		{
			flags = flags | CONTENTS_GRATE | CONTENTS_WINDOW;
		}
		
		Handle trace = TR_TraceRayFilterEx(eyePos, targetPos, flags,
			RayType_EndPoint, TraceFilter_DontHitSelf, this.index);
		
		bool visible = !TR_DidHit(trace);
		traceEnt = TR_GetEntityIndex(trace);
		delete trace;
		if (!visible && traceEnt == target)
		{
			visible = true;
		}
		
		return visible;
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
	buster.Path = PathFollower(_, SentryBusterPath_FilterIgnoreActors, SentryBusterPath_FilterOnlyActors);
	buster.Path.SetMinLookAheadDistance(1024.0);
	
	int health = RoundToFloor(BUSTER_BASE_HEALTH * GetEnemyHealthMult());
	buster.SetProp(Prop_Data, "m_iHealth", health);
	buster.SetPropFloat(Prop_Data, "m_flModelScale", 1.75);
	
	// We robots, don't bleed
	buster.SetProp(Prop_Data, "m_bloodColor", -1);
	// For triggers
	buster.AddFlag(FL_CLIENT);
	
	buster.SetModel(MODEL_BUSTER);
	buster.SetProp(Prop_Data, "m_moveXPoseParameter", buster.LookupPoseParameter("move_x"));
	buster.SetProp(Prop_Data, "m_moveYPoseParameter", buster.LookupPoseParameter("move_y"));
	buster.SetProp(Prop_Data, "m_idleSequence", buster.LookupSequence("Stand_MELEE"));
	buster.SetProp(Prop_Data, "m_runSequence", buster.LookupSequence("Run_MELEE"));
	buster.SetProp(Prop_Data, "m_airSequence", buster.LookupSequence("a_jumpfloat_ITEM1"));
	buster.Target = INVALID_ENT_REFERENCE;
	
	buster.Hook_HandleAnimEvent(HandleAnimEvent);
	buster.SetProp(Prop_Data, "m_iTeamNum", TEAM_ENEMY);
	buster.SetProp(Prop_Send, "m_nSkin", 1);
	
	EmitGameSoundToAll("MVM.SentryBusterLoop", buster.index);
	EmitGameSoundToAll("MVM.SentryBusterIntro", buster.index);
	
	npc.flStepSize = 18.0;
	npc.flGravity = 800.0;
	npc.flAcceleration = 2000.0;
	npc.flJumpHeight = 85.0;
	npc.flWalkSpeed = 440.0;
	npc.flRunSpeed = 440.0;
	npc.flDeathDropHeight = 2000.0;
	
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
	buster.Spawn();
	buster.Activate();
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
		EmitGameSoundToAll("MVM.SentryBusterStep", actor);
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

public bool SentryBusterPath_FilterIgnoreActors(int entity, int contentsMask, int desiredcollisiongroup)
{
	if (RF2_Object_Base(entity).IsValid())
		return true;

	if ((entity > 0 && entity <= MaxClients) || !IsCombatChar(entity))
	{
		return false;
	}
	
	return true;
}

public bool SentryBusterPath_FilterOnlyActors(int entity, int contentsMask, int desiredcollisiongroup)
{
	if (RF2_Object_Base(entity).IsValid())
		return false;

	return ((entity > 0 && entity <= MaxClients) || IsCombatChar(entity));
}

void DoSentryBusterWave()
{
	ArrayList sentryList = CreateArray();
	int builder;
	int entity = -1;

	while ((entity = FindEntityByClassname(entity, "obj_sentrygun")) != -1)
	{
		if (GetEntProp(entity, Prop_Data, "m_iTeamNum") != TEAM_SURVIVOR)
			continue;
		
		builder = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
		if (builder <= 0)
			continue;
		
		if (g_hPlayerExtraSentryList[builder].FindValue(entity) != -1) // Don't count disposable sentries
			continue;
		
		sentryList.Push(entity);
	}
	
	for (int i = 0; i < sentryList.Length; i++)
	{
		if (!RF2_SentryBuster.Create(sentryList.Get(i)).IsValid())
		{
			RequestFrame(RF_BusterSpawnRetry, EntIndexToEntRef(sentryList.Get(i)));
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

public void RF_BusterSpawnRetry(int sentry)
{
	if (IsStageCleared() || (sentry = EntRefToEntIndex(sentry)) == INVALID_ENT_REFERENCE)
		return;
	
	if (!RF2_SentryBuster.Create(sentry).IsValid())
	{
		RequestFrame(RF_BusterSpawnRetry, sentry);
	}
}

bool IsSentryBusterActive()
{
	return FindEntityByClassname(MaxClients + 1, "rf2_npc_sentry_buster") != -1;
}
