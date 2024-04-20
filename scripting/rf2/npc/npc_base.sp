#pragma newdecls required
#pragma semicolon 1

static CEntityFactory g_Factory;
#define SND_BOSS_DEATH "rf2/sfx/boss_death.wav"

methodmap RF2_NPC_Base < CBaseCombatCharacter
{
	public RF2_NPC_Base(int entity)
	{
		return view_as<RF2_NPC_Base>(entity);
	}
	
	public bool IsValid()
	{
		if (!IsValidEntity2(this.index))
		{
			return false;
		}
		
		static char classname[128];
		this.GetClassname(classname, sizeof(classname));
		return StrContains(classname, "rf2_npc") != -1;
	}
	
	public static void Init()
	{
		g_Factory = new CEntityFactory("rf2_npc_base", OnCreate, OnRemove);
		g_Factory.IsAbstract = true;
		g_Factory.DeriveFromNPC();
		g_Factory.BeginDataMapDesc()
			.DefineEntityField("m_hTarget")
			.DefineEntityField("m_hGlow")
			.DefineBoolField("m_bDoUnstuckChecks")
			.DefineFloatField("m_flLastUnstuckTime")
			.DefineFloatField("m_flDormantTime")
			.DefineVectorField("m_vecStuckPos")
			.DefineIntField("m_iDefendTeam", _, "defendteam") // we won't target this team
		.EndDataMapDesc();
		g_Factory.Install();
		HookMapStart(BaseNPC_OnMapStart);
	}
	
	property int Target
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hTarget");
		}
		
		public set(int entity)
		{
			this.SetPropEnt(Prop_Data, "m_hTarget", entity);
		}
	}
	
	property PathFollower Path
	{
		public get()
		{
			return GetEntPathFollower(this.index);
		}
	}

	property int FollowerIndex
	{
		public get()
		{
			return g_iEntityPathFollowerIndex[this.index];
		}

		public set(int value)
		{
			g_iEntityPathFollowerIndex[this.index] = value;
		}
	}

	property bool DoUnstuckChecks
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bDoUnstuckChecks"));
		}

		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bDoUnstuckChecks", value);
		}
	}

	property float LastUnstuckTime
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flLastUnstuckTime");
		}

		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flLastUnstuckTime", value);
		}
	}

	property float DormantTime
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flDormantTime");
		}

		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flDormantTime", value);
		}
	}
	
	property CBaseNPC BaseNpc
	{
		public get()
		{
			return TheNPCs.FindNPCByEntIndex(this.index);
		}
	}
	
	property INextBot Bot
	{
		public get()
		{
			return this.MyNextBotPointer();
		}
	}
	
	property CBaseNPC_Locomotion Locomotion
	{
		public get()
		{
			return this.BaseNpc.GetLocomotion();
		}
	}

	property IVision Vision
	{
		public get()
		{
			return this.Bot.GetVisionInterface();
		}
	}

	property IBody Body
	{
		public get()
		{
			return this.Bot.GetBodyInterface();
		}
	}

	property IIntention Intention
	{
		public get()
		{
			return this.Bot.GetIntentionInterface();
		}
	}

	// Do not target this team
	property int DefendTeam
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_iDefendTeam"));
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iDefendTeam", value);
		}
	}
	
	property int Team
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iTeamNum");
		}

		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iTeamNum", value);
		}
	}

	property int GlowEnt
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hGlow");
		}
		
		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hGlow", value);
		}
	}

	public void SetSequence(const char[] sequence, float playbackrate=1.0)
	{
		int seq = this.LookupSequence(sequence);
		this.ResetSequence(seq);
		this.SetPropFloat(Prop_Send, "m_flPlaybackRate", playbackrate);
	}
	
	public float AddGesture(const char[] sequence, float duration=0.0, bool autokill=true, float playbackrate=1.0, int priority=1)
	{
		return AddGesture(this.index, sequence, duration, autokill, playbackrate, priority);
	}
	
	public float AddGestureByIndex(int seq, float duration=0.0, bool autokill=true, float playbackrate=1.0, int priority=1)
	{
		return AddGestureByIndex(this.index, seq, duration, autokill, playbackrate, priority);
	}
	
	public bool IsPlayingSequence(const char[] sequence)
	{
		int seq = this.GetProp(Prop_Send, "m_nSequence");
		return seq >= 0 && this.LookupSequence(sequence) == seq;
	}
	
	public bool IsPlayingGestureByIndex(int seq)
	{
		return IsPlayingGestureByIndex(this.index, seq);
	}
	
	public int GetNewTarget(float maxDist=0.0)
	{
		float pos[3];
		this.WorldSpaceCenter(pos);
		int entity = MaxClients+1;
		int targetTeam, target;
		float dist;
		float nearestDist = -1.0;
		maxDist = sq(maxDist);
		while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT)
		{
			if (!IsCombatChar(entity))
				continue;
			
			if (IsValidClient(entity) && !IsPlayerAlive(entity))
				continue;
			
			targetTeam = GetEntTeam(entity);
			if (targetTeam == this.Team || targetTeam == this.DefendTeam)
				continue;
			
			dist = DistBetween(this.index, entity, true);
			if ((maxDist <= 0.0 || dist < maxDist) && (nearestDist < 0.0 || dist < nearestDist))
			{
				nearestDist = dist;
				target = entity;
			}
		}
		
		if (target > 0)
			this.Target = target;
		
		return this.Target;
	}
	
	public bool HasLOSTo(CBaseEntity entity)
	{
		return this.MyNextBotPointer().GetVisionInterface().IsLineOfSightClearToEntity(entity.index);
	}
	
	// does not change collison box, use BaseNpc.SetBodyMins/SetBodyMaxs for that
	public void SetHitboxSize(const float mins[3], const float maxs[3])
	{
		this.SetPropVector(Prop_Send, "m_vecMins", mins);
		this.SetPropVector(Prop_Send, "m_vecMaxs", maxs);
		this.SetPropVector(Prop_Send, "m_vecMinsPreScaled", mins);
		this.SetPropVector(Prop_Send, "m_vecMaxsPreScaled", maxs);
		this.SetPropVector(Prop_Send, "m_vecSpecifiedSurroundingMins", mins);
		this.SetPropVector(Prop_Send, "m_vecSpecifiedSurroundingMaxs", maxs);
		this.SetPropVector(Prop_Send, "m_vecSpecifiedSurroundingMinsPreScaled", mins);
		this.SetPropVector(Prop_Send, "m_vecSpecifiedSurroundingMaxsPreScaled", maxs);
	}
	
	public void SetGlow(bool state)
	{
		this.GlowEnt = ToggleGlow(this.index, state);
	}
	
	public void SetGlowColor(int color[4])
	{
		if (IsValidEntity2(this.GlowEnt))
		{
			SetVariantColor(color);
			AcceptEntityInput(this.GlowEnt, "SetGlowColor");
		}
	}

	public void GetStuckPos(float buffer[3])
	{
		this.GetPropVector(Prop_Data, "m_vecStuckPos", buffer);
	}
	
	public void SetStuckPos(const float vec[3])
	{
		this.SetPropVector(Prop_Data, "m_vecStuckPos", vec);
	}
}

void BaseNPC_OnMapStart()
{
	PrecacheSound2(SND_BOSS_DEATH, true);
}

CEntityFactory GetBaseNPCFactory()
{
	return g_Factory;
}

static void OnCreate(RF2_NPC_Base npc)
{
	SDKHook(npc.index, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
	SDKHook(npc.index, SDKHook_ThinkPost, ThinkPost);
	SDKHook(npc.index, SDKHook_SpawnPost, OnSpawnPost);
	npc.DefendTeam = -1;
	npc.DoUnstuckChecks = true;
	npc.FollowerIndex = GetFreePathFollowerIndex(npc.index);
}

static void OnRemove(RF2_NPC_Base npc)
{

}

static void ThinkPost(int entity)
{
	RF2_NPC_Base(entity).SetNextThink(GetGameTime());
}

static void OnSpawnPost(int entity)
{
	RF2_NPC_Base npc = RF2_NPC_Base(entity);
	if (npc.DoUnstuckChecks)
	{
		float pos[3];
		npc.GetAbsOrigin(pos);
		npc.SetStuckPos(pos);
		CreateTimer(0.5, Timer_UnstuckCheck, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

static void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3])
{
	RF2_NPC_Base npc = RF2_NPC_Base(victim);
	int health = npc.GetProp(Prop_Data, "m_iHealth");
	TE_TFParticle("bot_impact_heavy", damagePosition);
	Event event = CreateEvent("npc_hurt", true);
	if (event)
	{
		event.SetInt("entindex", npc.index);
		event.SetInt("health", health > 0 ? health : 0);
		event.SetInt("damageamount", RoundToFloor(damage));
		event.SetBool("crit", (damagetype & DMG_CRIT) ? true : false);
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

static Action Timer_UnstuckCheck(Handle timer, int entity)
{
	RF2_NPC_Base npc = RF2_NPC_Base(EntRefToEntIndex(entity));
	if (!npc.IsValid() || !npc.DoUnstuckChecks)
	{
		return Plugin_Stop;
	}
	
	bool stuck;
	float pos[3], oldStuckPos[3], mins[3], maxs[3];
	npc.GetAbsOrigin(pos);
	npc.GetStuckPos(oldStuckPos);
	npc.SetStuckPos(pos);
	npc.BaseNpc.GetBodyMins(mins);
	npc.BaseNpc.GetBodyMaxs(maxs);
	if (GetVectorDistance(oldStuckPos, pos, true) <= 64.0)
	{
		npc.DormantTime += 0.5;
	}
	else
	{
		npc.DormantTime = 0.0;
	}
	
	if (npc.DormantTime >= 2.0)
	{
		stuck = true;
	}
	else if (npc.DormantTime >= 0.5)
	{
		float mins2[3], maxs2[3];
		CopyVectors(mins, mins2);
		CopyVectors(maxs, maxs2);
		ScaleVector(mins2, 0.9);
		ScaleVector(maxs2, 0.9);
		TR_TraceHullFilter(pos, pos, mins, maxs, MASK_NPCSOLID_BRUSHONLY, TraceFilter_WallsOnly);
		if (TR_DidHit())
		{
			stuck = true;
		}
	}
	
	if (stuck)
	{
		float spawnPos[3];
		CNavArea area = GetSpawnPoint(pos, spawnPos, 0.0, 300.0, 4, true, mins, maxs, MASK_NPCSOLID_BRUSHONLY, maxs[2]*0.25);
		if (area)
		{
			npc.LastUnstuckTime = GetGameTime();
			npc.DormantTime = 0.0;
			npc.Teleport(spawnPos);
		}
	}
	
	return Plugin_Continue;
}
