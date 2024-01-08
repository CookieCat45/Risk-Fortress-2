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

static CEntityFactory g_Factory;
static ConVar g_cvPhysPush;
ConVar g_cvSuicideBombRange;
static int g_Busters;

ConVar g_cvBusterSpawnInterval;

#include "actions/sentry_buster/main.sp"
#include "actions/sentry_buster/detonate.sp"

methodmap RF2_SentryBuster < CBaseCombatCharacter
{
	public RF2_SentryBuster(int entIndex)
	{
		return view_as<RF2_SentryBuster>(entIndex);
	}
	
	public bool IsValid()
	{
		if (!CBaseCombatCharacter(this.index).IsValid())
		{
			return false;
		}
		
		return CEntityFactory.GetFactoryOfEntity(this.index) == g_Factory;
	}

	public static void Initialize()
	{
		g_Factory = new CEntityFactory("rf2_npc_sentry_buster", OnCreate, OnRemove);
		g_Factory.DeriveFromNPC();
		g_Factory.SetInitialActionFactory(RF2_SentryBusterMainAction.GetFactory());
		g_Factory.BeginDataMapDesc()
			.DefineEntityField("m_Target")
			.DefineIntField("m_PathFollower")
			.DefineIntField("m_moveXPoseParameter")
			.DefineIntField("m_moveYPoseParameter")
			.DefineIntField("m_idleSequence")
			.DefineIntField("m_runSequence")
			.DefineIntField("m_airSequence")
		.EndDataMapDesc();

		g_Factory.Install();
	}
	
	public static RF2_SentryBuster Create(CBaseEntity target)
	{
		RF2_SentryBuster buster = RF2_SentryBuster(CreateEntityByName("rf2_npc_sentry_buster"));
		buster.Target = target;
		float targetPos[3], pos[3], mins[3], maxs[3];
		GetEntPos(target.index, targetPos);
		buster.GetPropVector(Prop_Send, "m_vecMins", mins);
		buster.GetPropVector(Prop_Send, "m_vecMaxs", maxs);
		GetSpawnPoint(targetPos, pos, 2000.0, 6500.0, TEAM_SURVIVOR, true, mins, maxs, MASK_NPCSOLID, 15.0);
		buster.Teleport(pos);
		return buster;
	}

	property CBaseEntity Target
	{
		public get()
		{
			return CBaseEntity(EntRefToEntIndex(this.GetPropEnt(Prop_Data, "m_Target")));
		}

		public set(CBaseEntity entity)
		{
			this.SetPropEnt(Prop_Data, "m_Target", EnsureEntRef(entity.index));
		}
	}

	property PathFollower Path
	{
		public get()
		{
			return view_as<PathFollower>(this.GetProp(Prop_Data, "m_PathFollower"));
		}

		public set(PathFollower value)
		{
			this.SetProp(Prop_Data, "m_PathFollower", value);
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
		PrecacheScriptSound("Announcer.MVM_Sentry_Buster_Alert_Another");
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
			{
				continue;
			}

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
					SDKHooks_TakeDamage(victim.index, this.index, this.index, damage, DMG_BLAST, _, force, center);
				}
				else
				{
					SDKHooks_TakeDamage(victim.index, this.index, this.index, damage, DMG_BLAST|DMG_PREVENT_PHYSICS_FORCE, _, _, center);
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
		RemoveEntity(this.index);
	}

	public bool IsLOSClearFromTarget(CBaseEntity target, bool checkGlass = true)
	{
		if (!target.IsValid())
		{
			return false;
		}
		int traceEnt;
		float eyePos[3], targetPos[3];
		this.WorldSpaceCenter(eyePos);
		target.WorldSpaceCenter(targetPos);
		if (IsValidClient(target.index))
		{
			GetClientEyePosition(target.index, targetPos);
		}
		int flags = CONTENTS_SOLID | CONTENTS_MOVEABLE | CONTENTS_MIST | CONTENTS_MONSTERCLIP;
		if (checkGlass)
		{
			flags = flags | CONTENTS_GRATE | CONTENTS_WINDOW;
		}
		Handle trace = TR_TraceRayFilterEx(eyePos, targetPos,
		flags,
		RayType_EndPoint, TraceFilter_DontHitSelf, this.index);
		bool visible = !TR_DidHit(trace);
		traceEnt = TR_GetEntityIndex(trace);
		delete trace;
		if (!visible && traceEnt == target.index)
		{
			visible = true;
		}
		return visible;
	}
}

static void OnCreate(RF2_SentryBuster buster)
{
	SDKHook(buster.index, SDKHook_ThinkPost, ThinkPost);
	SDKHook(buster.index, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
	CBaseNPC npc = TheNPCs.FindNPCByEntIndex(buster.index);
	
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
	buster.Target = CBaseEntity(INVALID_ENT_REFERENCE);

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

static void ThinkPost(int ent)
{
	RF2_SentryBuster(ent).SetNextThink(GetGameTime());
}

static void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3])
{
	RF2_SentryBuster buster = RF2_SentryBuster(victim);
	int health = buster.GetProp(Prop_Data, "m_iHealth");
	TE_TFParticle("bot_impact_heavy", damagePosition);
	Event event = CreateEvent("npc_hurt");
	if (event)
	{
		event.SetInt("entindex", buster.index);
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

static void OnRemove(RF2_SentryBuster buster)
{
	StopSound(buster.index, SNDCHAN_STATIC, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
	if (buster.Path)
	{
		buster.Path.Destroy();
		buster.Path = view_as<PathFollower>(0);
	}
}

void SentryBuster_OnMapStart()
{
	g_Busters = 0;
	RF2_SentryBuster.Precache();
	
	static bool init;
	if (!init)
	{
		RF2_SentryBuster.Initialize();
		g_cvPhysPush = FindConVar("phys_pushscale");
		g_cvSuicideBombRange = FindConVar("tf_bot_suicide_bomb_range");
		g_cvBusterSpawnInterval = CreateConVar("rf2_sentry_buster_spawn_interval", "120", "Interval in seconds that Sentry Busters will spawn if RED has sentries.", FCVAR_NOTIFY, true, 0.0);
		init = true;
	}
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
	if (bf)
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
		if (!IsClientInGame(i) || (!bAirShake && (eCommand == SHAKE_START) && !(GetEntityFlags(i) & FL_ONGROUND)))
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
	{
		return false;
	}

	if (IsObject(entity))
	{
		return false;
	}

	return true;
}

public bool SentryBusterPath_FilterOnlyActors(int entity, int contentsMask, int desiredcollisiongroup)
{
	return ((entity > 0 && entity <= MaxClients) || CBaseEntity(entity).IsCombatCharacter());
}

void DoSentryBusterWave()
{
	ArrayList sentryList = CreateArray();
	int builder;
	int entity = -1;

	while ((entity = FindEntityByClassname(entity, "obj_sentrygun")) != -1)
	{
		if (GetEntProp(entity, Prop_Data, "m_iTeamNum") != TEAM_SURVIVOR)
		{
			continue;
		}

		builder = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
		if (builder <= 0)
		{
			continue;
		}

		if (g_hPlayerExtraSentryList[builder].FindValue(entity) != -1) // Don't count disposable sentries
		{
			continue;
		}

		sentryList.Push(entity);
	}
	
	for (int i = 0; i < sentryList.Length; i++)
	{
		RF2_SentryBuster.Create(CBaseEntity(sentryList.Get(i)));
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

bool IsSentryBusterActive()
{
	return FindEntityByClassname(MaxClients + 1, "rf2_npc_sentry_buster") != -1;
}
