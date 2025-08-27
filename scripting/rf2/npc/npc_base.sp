#pragma newdecls required
#pragma semicolon 1

static CEntityFactory g_Factory;
typedef OnActionCallback = function void(RF2_NPC_Base npc, const char[] action);

enum TargetMethod
{
	TargetMethod_Closest,
	TargetMethod_ClosestNew,
}

enum TargetType
{
	TargetType_Any,
	TargetType_Player,
	TargetType_Building,
	TargetType_NoMinions,
	TargetType_NoBuildings,
	TargetType_NoMinionsOrBuildings,
};

methodmap RF2_NPC_Base < CBaseCombatCharacter
{
	public RF2_NPC_Base(int entity)
	{
		return view_as<RF2_NPC_Base>(entity);
	}
	
	public bool IsValid()
	{
		if (!IsValidEntity2(this.index) || this.BaseNpc == INVALID_NPC)
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
			.DefineEntityField("m_hRaidBossSpawner")
			.DefineEntityField("m_hHealthText")
			.DefineIntField("m_hOnDoAction")
			.DefineBoolField("m_bDoUnstuckChecks")
			.DefineBoolField("m_bCanBeHeadshot")
			.DefineBoolField("m_bCanBeBackstabbed")
			.DefineFloatField("m_flBaseBackstabDamage")
			.DefineFloatField("m_flLastUnstuckTime")
			.DefineFloatField("m_flDormantTime")
			.DefineVectorField("m_vecStuckPos")
			.DefineIntField("m_iDefendTeam", _, "defendteam") // we won't target this team
			.DefineInputFunc("DoAction", InputFuncValueType_String, Input_DoAction)
		.EndDataMapDesc();
		g_Factory.Install();
		HookMapStart(BaseNPC_OnMapStart);
	}
	
	property int Target
	{
		public get()
		{
			return EntRefToEntIndex(this.GetPropEnt(Prop_Data, "m_hTarget"));
		}
		
		public set(int entity)
		{
			this.SetPropEnt(Prop_Data, "m_hTarget", EnsureEntRef(entity));
		}
	}
	
	property PathFollower Path
	{
		public get()
		{
			return GetEntPathFollower(this.index);
		}
	}

	property RF2_HealthText HealthText
    {
        public get()
        {
            return view_as<RF2_HealthText>(this.GetPropEnt(Prop_Data, "m_hHealthText"));
        }

        public set(RF2_HealthText value)
        {
            this.SetPropEnt(Prop_Data, "m_hHealthText", value.index);
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

	property int RaidBossSpawner
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hRaidBossSpawner");
		}

		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hRaidBossSpawner", value);
		}
	}

	property PrivateForward OnDoAction
	{
		public get()
		{
			return view_as<PrivateForward>(this.GetProp(Prop_Data, "m_hOnDoAction"));
		}

		public set(PrivateForward value)
		{
			this.SetProp(Prop_Data, "m_hOnDoAction", value);
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

	property bool CanBeHeadshot
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bCanBeHeadshot"));
		}

		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bCanBeHeadshot", value);
		}
	}

	property bool CanBeBackstabbed
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bCanBeBackstabbed"));
		}

		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bCanBeBackstabbed", value);
		}
	}

	property float BaseBackstabDamage
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flBaseBackstabDamage");
		}

		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flBaseBackstabDamage", value);
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
			return this.GetProp(Prop_Data, "m_iMaxHealth");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iMaxHealth", value);
		}
	}

	// Do not target this team
	property int DefendTeam
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iDefendTeam");
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

	public bool IsRaidBoss()
	{
		return IsValidEntity2(this.RaidBossSpawner);
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
	
	public bool IsPlayingGesture(const char[] seq)
	{
		return IsPlayingGesture(this.index, seq);
	}

	public bool IsTargetValid()
	{
		return IsValidEntity2(this.Target) && (!IsValidClient(this.Target) || IsPlayerAlive(this.Target));
	}
	
	public int GetNewTarget(TargetMethod method=TargetMethod_Closest, TargetType type=TargetType_Any, float maxDist=0.0)
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
			if (!IsValidEntity2(entity) || method == TargetMethod_ClosestNew && entity == this.Target)
				continue;

			if (!IsCombatChar(entity))
				continue;

			if (IsValidClient(entity) && !IsPlayerAlive(entity))
				continue;
			
			if (type != TargetType_Any)
			{
				bool valid = true;
				switch (type)
				{
					case TargetType_Player: valid = IsValidClient(entity);
					case TargetType_Building: valid = IsBuilding(entity);
					case TargetType_NoBuildings: valid = !IsBuilding(entity);
					case TargetType_NoMinions: valid = !IsNPC(entity) && (!IsValidClient(entity) || !IsPlayerMinion(entity));
					case TargetType_NoMinionsOrBuildings: valid = (!IsValidClient(entity) || !IsPlayerMinion(entity)) && !IsBuilding(entity) && !IsNPC(entity);
				}

				if (!valid)
					continue;
			}

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
	
	public void ApproachEntity(int entity, float maxDist=0.0, bool walk=false)
	{
		float targetPos[3];
		if (IsBuilding(entity) && GetEntProp(entity, Prop_Send, "m_bCarried"))
		{
			int builder = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
			GetEntPos(builder, targetPos, true);
		}
		else
		{
			GetEntPos(entity, targetPos, true);
		}

		this.Path.ComputeToPos(this.Bot, targetPos, maxDist);
		this.Path.Update(this.Bot);
		walk ? this.Locomotion.Walk() : this.Locomotion.Run();
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
	
	public void SetGlowColor(int r=255, int g=255, int b=255, int a=255)
	{
		if (IsValidEntity2(this.GlowEnt))
		{
			int color[4];
			color[0] = r;
			color[1] = g;
			color[2] = b;
			color[3] = a;
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
	
	public void SpewGibs(const char[][] gibModels, int size)
	{
		float pos[3], angles[3], vel[3];
		this.WorldSpaceCenter(pos);
		for (int i = 0; i < size; i++)
		{
			int prop = CreateEntityByName("prop_physics_multiplayer");
			DispatchKeyValueInt(prop, "spawnflags", 4);
			SetEntityModel2(prop, gibModels[i]);
			angles[0] = GetRandomFloat(-179.0, 0.0);
			angles[1] = GetRandomFloat(-179.0, 179.0);
			angles[2] = GetRandomFloat(-179.0, 179.0);
			GetAngleVectors(angles, vel, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(vel, vel);
			ScaleVector(vel, GetRandomFloat(500.0, 1250.0));
			TeleportEntity(prop, pos, angles);
			DispatchSpawn(prop);
			SDK_ApplyAbsVelocityImpulse(prop, vel);
			CreateTimer(GetRandomFloat(10.0, 18.0), Timer_DeleteEntity, EntIndexToEntRef(prop), TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	public void HookOnAction(OnActionCallback callback)
	{
		if (!this.OnDoAction)
		{
			this.OnDoAction = new PrivateForward(ET_Ignore, Param_Any, Param_String);
		}

		this.OnDoAction.AddFunction(INVALID_HANDLE, callback);
	}

	public void DoAction(const char[] action)
	{
		if (!this.OnDoAction)
			return;

		Call_StartForward(this.OnDoAction);
		Call_PushCell(this);
		Call_PushString(action);
		Call_Finish();
	}
}

void BaseNPC_OnMapStart()
{
	
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
	SDKHook(npc.index, SDKHook_TraceAttack, Hook_OnTraceAttack);
	npc.HookOnAction(OnAction);
	npc.AddFlag(FL_NPC);
	npc.DefendTeam = -1;
	npc.DoUnstuckChecks = true;
	npc.BaseBackstabDamage = 750.0;
	npc.FollowerIndex = GetFreePathFollowerIndex(npc.index);
}

static void OnRemove(RF2_NPC_Base npc)
{
	if (npc.OnDoAction)
	{
		RequestFrame(RF_DeleteForward, npc.OnDoAction);
		npc.OnDoAction = null;
	}
}

static void RF_DeleteForward(PrivateForward fwd)
{
	delete fwd;
}

static void OnAction(RF2_NPC_Base npc, const char[] action)
{
	#if defined DEVONLY
	char classname[128];
	npc.GetClassname(classname, sizeof(classname));
	CPrintToChatAll("{yellow}\"%s\" {default}doing action: {lightblue}\"%s\"", classname, action);
	#endif

	npc.Bot.OnCommandString(action);
}

static void ThinkPost(int entity)
{
	RF2_NPC_Base npc = RF2_NPC_Base(entity);
	npc.SetNextThink(GetGameTime());

	// If we have a target, make sure it isn't a dead player
	if (IsValidClient(npc.Target) && !IsPlayerAlive(npc.Target))
	{
		npc.Target = INVALID_ENT;
	}
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

static void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damageCustom)
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

	if (npc.Health <= 0 && npc.IsRaidBoss())
	{
		RF2_RaidBossSpawner(npc.RaidBossSpawner).FireOutput("OnBossHealthDepleted");
	}
}

static Action Timer_UnstuckCheck(Handle timer, int entity)
{
	RF2_NPC_Base npc = RF2_NPC_Base(EntRefToEntIndex(entity));
	if (!npc.IsValid() || !npc.DoUnstuckChecks)
	{
		return Plugin_Stop;
	}

	if (!npc.Locomotion.IsAttemptingToMove())
		return Plugin_Continue;
	
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

public void Input_DoAction(int entity, int activator, int caller, const char[] value)
{
	RF2_NPC_Base(entity).DoAction(value);
}
