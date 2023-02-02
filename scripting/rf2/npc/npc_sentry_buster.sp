#if defined _RF2_sentry_buster_included
 #endinput
#endif
#define _RF2_sentry_buster_included

#pragma semicolon 1
#pragma newdecls required

// Original Sentry Buster NPC plugin by Kenzzer: https://github.com/Kenzzer/sm_plugins/tree/master/sentrybuster
#define MODEL_BUSTER "models/bots/demo/bot_sentry_buster.mdl"
#define BUSTER_BASE_HEALTH 1500
#define BUSTER_BASE_DAMAGE 1000.0

#define FFADE_IN			0x0001		// Just here so we don't pass 0 into the function
#define FFADE_OUT			0x0002		// Fade out (not in)
#define FFADE_MODULATE		0x0004		// Modulate (don't blend)
#define FFADE_STAYOUT		0x0008		// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE			0x0010		// Purges all other fades, replacing them with this one
#define SCREENFADE_FRACBITS	9

enum ShakeCommand_t
{
	SHAKE_START = 0,
	SHAKE_STOP,
	SHAKE_AMPLITUDE,
	SHAKE_FREQUENCY,
	SHAKE_START_RUMBLEONLY,
	SHAKE_START_NORUMBLE,
};

static CEntityFactory g_EntityFactory;
static ConVar g_cvPhysPush;
static ConVar g_cvSuicideBombRange;
static NextBotActionFactory g_ActionFactoryMain;
static NextBotActionFactory g_ActionFactoryExplode;

ConVar g_cvBusterSpawnKillThreshold;
ConVar g_cvBusterSpawnKillRatio;
int g_iSentryKillCounter;

methodmap SentryBuster < CBaseCombatCharacter
{
	property int hTarget
	{
		public get()
		{
			return GetEntPropEnt(this.index, Prop_Data, "m_hTarget");
		}
		public set(int entity)
		{
			SetEntPropEnt(this.index, Prop_Data, "m_hTarget", entity);
		}
	}

	public static void Precache()
	{
		PrecacheScriptSound("MVM.SentryBusterExplode");
		PrecacheScriptSound("MVM.SentryBusterSpin");
		PrecacheScriptSound("MVM.SentryBusterLoop");
		PrecacheScriptSound("MVM.SentryBusterIntro");
		PrecacheScriptSound("MVM.SentryBusterStep");
		PrecacheScriptSound("Announcer.MVM_Sentry_Buster_Alert");
		
		PrecacheModel(MODEL_BUSTER, true);
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
			if (entity < 1)
				continue;
			
			CBaseEntity victim = CBaseEntity(entity);
			if (victim.IsCombatCharacter())
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
				bool boss = (victim.index <= MaxClients && GetPlayerBossType(victim.index) >= 0);
				
				if (IsBuilding(victim.index))
				{
					damage = float(victim.GetProp(Prop_Data, "m_iHealth")) * 10.0;
				}
				else
				{
					damage = BUSTER_BASE_DAMAGE * GetEnemyDamageMult();
					
					if (boss)
						damage *= 0.1;
				}
				
				if (!boss)
				{
					float force[3];
					CalculateMeleeDamageForce(damage, delta, 1.0, force);
					SDKHooks_TakeDamage(victim.index, this.index, this.index, damage, DMG_BLAST, _, force, center, false);
				}
				else
				{
					SDKHooks_TakeDamage(victim.index, this.index, this.index, damage, DMG_BLAST|DMG_PREVENT_PHYSICS_FORCE, _, _, center, false);
				}
			}
		}
		
		delete victims;
		RequestFrame(RF_DeleteBuster, EntIndexToEntRef(this.index));
	}

	public void OnCreate()
	{
		int health = RoundToFloor(float(BUSTER_BASE_HEALTH) * GetEnemyHealthMult());
		this.SetProp(Prop_Data, "m_iHealth", health);
		this.SetPropFloat(Prop_Data, "m_flModelScale", 1.75);
		
		// We robots, don't bleed
		this.SetProp(Prop_Data, "m_bloodColor", -1);
		// For triggers
		this.AddFlag(FL_CLIENT);

		this.SetModel(MODEL_BUSTER);
		this.SetProp(Prop_Data, "m_moveXPoseParameter", this.LookupPoseParameter("move_x"));
		this.SetProp(Prop_Data, "m_moveYPoseParameter", this.LookupPoseParameter("move_y"));
		this.SetProp(Prop_Data, "m_idleSequence", this.LookupSequence("Stand_MELEE"));
		this.SetProp(Prop_Data, "m_runSequence", this.LookupSequence("Run_MELEE"));
		this.SetProp(Prop_Data, "m_airSequence", this.LookupSequence("a_jumpfloat_ITEM1"));
		this.hTarget = INVALID_ENT_REFERENCE;

		SDKHook(this.index, SDKHook_SpawnPost, SentryBuster_SpawnPost);
		SDKHook(this.index, SDKHook_OnTakeDamageAlivePost, SentryBuster_OnTakeDamageAlivePost);
		this.Hook_HandleAnimEvent(SentryBuster_HandleAnimEvent);

		CBaseNPC npc = TheNPCs.FindNPCByEntIndex(this.index);

		npc.flStepSize = 18.0;
		npc.flGravity = 800.0;
		npc.flAcceleration = 2000.0;
		npc.flJumpHeight = 85.0;
		npc.flWalkSpeed = 440.0;
		npc.flRunSpeed = 440.0;
		npc.flDeathDropHeight = 2000.0;
	}

	public void OnSpawnPost()
	{
		EmitGameSoundToAll("MVM.SentryBusterLoop", this.index);
	}
}

void SentryBuster_OnMapStart()
{
	SentryBuster.Precache();
	
	static bool init;
	if (!init)
	{
		SentryBuster_InitBehavior();
		SentryBusterExplode_InitBehavior();
		
		g_cvPhysPush = FindConVar("phys_pushscale");
		g_cvSuicideBombRange = FindConVar("tf_bot_suicide_bomb_range");
		
		g_cvBusterSpawnKillThreshold = CreateConVar("rf2_sentry_buster_kill_threshold", "6", "How many kills Sentries on the Survivor team must get for a Sentry Buster wave to spawn.", FCVAR_NOTIFY, true, 0.0);
		g_cvBusterSpawnKillRatio = CreateConVar("rf2_sentry_buster_kill_level_ratio", "1", "Per enemy level, how many additional kills by sentries are needed to spawn Sentry Busters.", FCVAR_NOTIFY, true, 0.0);
		
		g_EntityFactory = new CEntityFactory("rf2_npc_sentry_buster", SentryBuster_OnCreate, SentryBuster_OnRemove);
		g_EntityFactory.DeriveFromNPC();
		g_EntityFactory.SetInitialActionFactory(g_ActionFactoryMain);
		g_EntityFactory.BeginDataMapDesc()
			.DefineIntField("m_moveXPoseParameter")
			.DefineIntField("m_moveYPoseParameter")
			.DefineIntField("m_idleSequence")
			.DefineIntField("m_runSequence")
			.DefineIntField("m_airSequence")
			.DefineEntityField("m_hTarget")
		.EndDataMapDesc();

		g_EntityFactory.Install();
		init = true;
	}
}

static void RF_DeleteBuster(int ref)
{
	int actor = EntRefToEntIndex(ref);
	if (actor != INVALID_ENT_REFERENCE)
	{
		RemoveEntity(actor);
	}
}

static void SentryBuster_OnCreate(int entity)
{
	SentryBuster buster = view_as<SentryBuster>(entity);
	buster.OnCreate();
}

static void SentryBuster_SpawnPost(int entity)
{
	SentryBuster buster = view_as<SentryBuster>(entity);
	buster.OnSpawnPost();
}

public void SentryBuster_OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3]) 
{
	int health = GetEntProp(victim, Prop_Data, "m_iHealth");
	if (health < 1)
	{
		health = 1;
		// We cannot die, no matter how. We go kaboom first
		SetEntProp(victim, Prop_Data, "m_iHealth", health);
	}

	TE_TFParticle("bot_impact_heavy", damagePosition);

	Event event = CreateEvent("npc_hurt");
	if (event) 
	{
		event.SetInt("entindex", victim);
		event.SetInt("health", health > 0 ? health : 0);
		event.SetInt("damageamount", RoundToFloor(damage));
		event.SetBool("crit", (damagetype & DMG_CRIT) == DMG_CRIT);

		if (attacker > 0 && attacker <= MaxClients)
		{
			event.SetInt("attacker_player", GetClientUserId(attacker));
			event.SetInt("weaponid", 0);
		}
		else 
		{
			event.SetInt("attacker_player", 0);
			event.SetInt("weaponid", 0);
		}

		event.Fire();
	}
}

static void SentryBuster_OnRemove(int entity)
{
	StopSound(entity, SNDCHAN_STATIC, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
}

static MRESReturn SentryBuster_HandleAnimEvent(int actor, Handle hParams)
{
	int event = DHookGetParamObjectPtrVar(hParams, 1, 0, ObjectValueType_Int);
	if (event == 7001)
	{
		EmitGameSoundToAll("MVM.SentryBusterStep", actor);
	}
	return MRES_Ignored;
}

int FixedUnsigned16(float value, int scale)
{
	int output;

	output = RoundToFloor(value * float(scale));
	if (output < 0)
	{
		output = 0;
	}
	if (output > 0xFFFF)
	{
		output = 0xFFFF;
	}

	return output;
}

void UTIL_ScreenFade(int player, int color[4], float fadeTime, float fadeHold, int flags)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageOne("Fade", player, USERMSG_RELIABLE));
	if (bf != null)
	{
		bf.WriteShort(FixedUnsigned16(fadeTime, 1 << SCREENFADE_FRACBITS));
		bf.WriteShort(FixedUnsigned16(fadeHold, 1 << SCREENFADE_FRACBITS));
		bf.WriteShort(flags);
		bf.WriteByte(color[0]);
		bf.WriteByte(color[1]);
		bf.WriteByte(color[2]);
		bf.WriteByte(color[3]);

		EndMessage();
	}
}

const float MAX_SHAKE_AMPLITUDE = 16.0;
void UTIL_ScreenShake(const float center[3], float amplitude, float frequency, float duration, float radius, ShakeCommand_t eCommand, bool bAirShake)
{
	float localAmplitude;

	if (amplitude > MAX_SHAKE_AMPLITUDE)
	{
		amplitude = MAX_SHAKE_AMPLITUDE;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i) || (!bAirShake && (eCommand == SHAKE_START) && !(GetEntityFlags(i) & FL_ONGROUND)))
		{
			continue;
		}

		CBaseCombatCharacter cb = CBaseCombatCharacter(i);
		float playerCenter[3];
		cb.WorldSpaceCenter(playerCenter);

		localAmplitude = ComputeShakeAmplitude(center, playerCenter, amplitude, radius);

		// This happens if the player is outside the radius, in which case we should ignore 
		// all commands
		if (localAmplitude < 0)
		{
			continue;
		}

		TransmitShakeEvent(i, localAmplitude, frequency, duration, eCommand);
	}
}

float ComputeShakeAmplitude(const float center[3], const float shake[3], float amplitude, float radius) 
{
	if (radius <= 0)
	{
		return amplitude;
	}

	float localAmplitude = -1.0;
	float delta[3];
	SubtractVectors(center, shake, delta);
	float distance = GetVectorLength(delta);

	if (distance <= radius)
	{
		// Make the amplitude fall off over distance
		float perc = 1.0 - (distance / radius);
		localAmplitude = amplitude * perc;
	}

	return localAmplitude;
}

void TransmitShakeEvent(int player, float localAmplitude, float frequency, float duration, ShakeCommand_t eCommand)
{
	if ((localAmplitude > 0.0 ) || (eCommand == SHAKE_STOP))
	{
		if (eCommand == SHAKE_STOP)
		{
			localAmplitude = 0.0;
		}

		BfWrite msg = UserMessageToBfWrite(StartMessageOne("Shake", player, USERMSG_RELIABLE));
		if (msg != null)
		{
			msg.WriteByte(view_as<int>(eCommand));
			msg.WriteFloat(localAmplitude);
			msg.WriteFloat(frequency);
			msg.WriteFloat(duration);

			EndMessage();
		}
	}
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
	if ((entity > 0 && entity <= MaxClients) || !CBaseEntity(entity).IsCombatCharacter())
		return false;
	
	return true;
}

public bool SentryBusterPath_FilterOnlyActors(int entity, int contentsMask, int desiredcollisiongroup)
{
	return ((entity > 0 && entity <= MaxClients) || CBaseEntity(entity).IsCombatCharacter());
}

void SentryBuster_InitBehavior()
{
	g_ActionFactoryMain = new NextBotActionFactory("SentryBusterMain");
	g_ActionFactoryMain.BeginDataMapDesc()
		.DefineIntField("m_PathFollower")
		.DefineIntField("m_PathFailures")
		.DefineFloatField("m_PathLastTime")
	.EndDataMapDesc();
	g_ActionFactoryMain.SetCallback(NextBotActionCallbackType_OnStart, SentryBusterMain_OnStart);
	g_ActionFactoryMain.SetCallback(NextBotActionCallbackType_Update, SentryBusterMain_Update);
	g_ActionFactoryMain.SetCallback(NextBotActionCallbackType_OnEnd, SentryBusterMain_OnEnd);
}

static void SentryBusterMain_OnStart(NextBotAction action, int actor, NextBotAction prevAction)
{
	action.SetData("m_PathFollower", PathFollower(_, SentryBusterPath_FilterIgnoreActors, SentryBusterPath_FilterOnlyActors));
	action.SetData("m_PathFailures", 0);
	action.SetDataFloat("m_PathLastTime", 0.0);
}

static int SentryBusterMain_Update(NextBotAction action, int actor, float interval)
{
	float vecPos[3];
	GetEntPropVector(actor, Prop_Data, "m_vecAbsOrigin", vecPos);

	SentryBuster pCC = view_as<SentryBuster>(actor);
	INextBot bot = pCC.MyNextBotPointer();
	NextBotGroundLocomotion loco = view_as<NextBotGroundLocomotion>(bot.GetLocomotionInterface());

	bool onGround = !!(GetEntityFlags(actor) & FL_ONGROUND);

	int target = GetEntPropEnt(actor, Prop_Data, "m_hTarget");
	bool valid = IsValidEntity(target);
	if (valid && IsBuilding(target))
	{
		if (GetEntProp(target, Prop_Send, "m_bCarried"))
		{
			target = GetEntPropEnt(target, Prop_Send, "m_hBuilder");
		}
	}
	
	if (IsValidClient(target) && IsPlayerAlive(target) || valid)
	{
		float vecTargetPos[3];
		GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vecTargetPos);

		float dist = GetVectorDistance(vecTargetPos, vecPos);

		loco.FaceTowards(vecTargetPos);

		if (dist > (g_cvSuicideBombRange.FloatValue / 3) && pCC.GetProp(Prop_Data, "m_iHealth") > 1)
		{
			PathFollower path = action.GetData("m_PathFollower");
			if (path)
			{
				float gameTime = GetGameTime();
				if (gameTime > action.GetDataFloat("m_PathLastTime") + 0.2)
				{
					int pathingFailures = action.GetData("m_PathFailures") + 1;
					if (!path.ComputeToTarget(bot, target))
					{
						if (pathingFailures == 3)
						{
							return action.ChangeTo(SentryBusterExplode_Create());
						}
					}
					else
					{
						pathingFailures = 0;
					}
					
					action.SetData("m_PathFailures", pathingFailures);
					action.SetDataFloat("m_PathLastTime", gameTime);
				}
				
				path.Update(bot);
				loco.Run();
			}
		}
		else if (onGround)
		{
			return action.ChangeTo(SentryBusterExplode_Create());
		}
	}
	else
	{
		// find new target
		float origin[3];
		pCC.WorldSpaceCenter(origin);
		int entity = GetNearestEntity(origin, "obj_sentrygun", _, _, TEAM_SURVIVOR);
		
		// No targets left, explode
		if (entity == -1)
			return action.ChangeTo(SentryBusterExplode_Create());
	}

	float speed = loco.GetGroundSpeed();
	int sequence = GetEntProp(actor, Prop_Send, "m_nSequence");

	if (speed < 0.01)
	{
		int idleSequence = GetEntProp(actor, Prop_Data, "m_idleSequence");
		if (sequence != idleSequence)
		{
			pCC.ResetSequence(idleSequence);
		}
	}
	else
	{
		int runSequence = GetEntProp(actor, Prop_Data, "m_runSequence");
		int airSequence = GetEntProp(actor, Prop_Data, "m_airSequence");

		if (!onGround)
		{
			if (sequence != airSequence)
			{
				pCC.ResetSequence(airSequence);
			}
		}
		else
		{			
			if (runSequence != -1 && sequence != runSequence)
			{
				pCC.ResetSequence(runSequence);
			}
		}

		float vecForward[3], vecRight[3], vecUp[3];
		pCC.GetVectors(vecForward, vecRight, vecUp);
			
		float vecMotion[3];
		loco.GetGroundMotionVector(vecMotion);

		pCC.SetPoseParameter(pCC.GetProp(Prop_Data, "m_moveXPoseParameter"), GetVectorDotProduct(vecMotion, vecForward));
		pCC.SetPoseParameter(pCC.GetProp(Prop_Data, "m_moveYPoseParameter"), GetVectorDotProduct(vecMotion, vecRight));
	}

	return action.Continue();
}

static void SentryBusterMain_OnEnd(NextBotAction action, int actor, NextBotAction nextAction)
{
	PathFollower path = action.GetData("m_PathFollower");
	if (path)
	{
		path.Destroy();
	}
}

NextBotAction SentryBusterExplode_Create()
{
	return g_ActionFactoryExplode.Create();
}

static int SentryBusterExplode_OnStart(NextBotAction action, int actor, NextBotAction prevAction)
{
	CBaseCombatCharacter cb = CBaseCombatCharacter(actor);
	int sequence = cb.LookupSequence("taunt04");

	if (sequence == -1)
	{
		return action.Done();
	}
	
	cb.ResetSequence(sequence);
	cb.SetPropFloat(Prop_Data, "m_flCycle", 0.0);
	cb.SetProp(Prop_Data, "m_takedamage", 0);
	EmitGameSoundToAll("MVM.SentryBusterSpin", actor);

	return action.Continue();
}

static int SentryBusterExplode_Update(NextBotAction action, int actor, float interval)
{
	float cycle = GetEntPropFloat(actor, Prop_Send, "m_flCycle");
	if (cycle == 1.0)
	{
		view_as<SentryBuster>(actor).Detonate();
		return action.Done();
	}

	return action.Continue();
}

void SentryBusterExplode_InitBehavior()
{
	g_ActionFactoryExplode = new NextBotActionFactory("SentryBusterExplode");
	g_ActionFactoryExplode.SetCallback(NextBotActionCallbackType_OnStart, SentryBusterExplode_OnStart);
	g_ActionFactoryExplode.SetCallback(NextBotActionCallbackType_Update, SentryBusterExplode_Update);
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
		{
			continue;
		}
		
		sentryList.Push(entity);
	}
	
	for (int i = 0; i < sentryList.Length; i++)
	{
		SpawnSentryBuster(sentryList.Get(i));
	}
	
	if (sentryList.Length > 0)
	{
		EmitGameSoundToAll("Announcer.MVM_Sentry_Buster_Alert");
		CreateTimer(5.0, Timer_SentryBusterIntroLoop, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	delete sentryList;
}

void SpawnSentryBuster(int target)
{
	float targetPos[3], pos[3], mins[3], maxs[3];
	GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", targetPos);
	
	int entity = CreateEntityByName("rf2_npc_sentry_buster");
	SetEntProp(entity, Prop_Data, "m_iTeamNum", TEAM_ENEMY);
	SetEntPropEnt(entity, Prop_Data, "m_hTarget", target);
	DispatchSpawn(entity);
	
	GetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);
	GetSpawnPoint(targetPos, pos, 2000.0, 6500.0, TEAM_SURVIVOR, true, mins, maxs, MASK_NPCSOLID, 15.0);
	TeleportEntity(entity, pos);
}

public Action Timer_SentryBusterIntroLoop(Handle timer)
{
	if (IsSentryBusterActive())
	{
		EmitGameSoundToAll("MVM.SentryBusterIntro");
	}
	else
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

bool IsSentryBusterActive()
{
	while (FindEntityByClassname(MaxClients+1, "rf2_npc_sentry_buster") != -1)
	{
		return true;
	}
	
	return false;
}