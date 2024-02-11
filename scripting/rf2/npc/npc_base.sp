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
		g_Factory = new CEntityFactory("rf2_npc_raidboss_base", OnCreate, OnRemove);
		g_Factory.IsAbstract = true;
		g_Factory.DeriveFromNPC();
		g_Factory.BeginDataMapDesc()
			.DefineEntityField("m_hTarget")
			.DefineEntityField("m_hGlow")
			.DefineIntField("m_PathFollower")
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
			return view_as<PathFollower>(this.GetProp(Prop_Data, "m_PathFollower"));
		}

		public set(PathFollower value)
		{
			this.SetProp(Prop_Data, "m_PathFollower", value);
		}
	}
	
	property CBaseNPC BaseNpc
	{
		public get()
		{
			return TheNPCs.FindNPCByEntIndex(this.index);
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
	
	public bool IsPlayingSequence(const char[] sequence)
	{
		int seq = this.GetProp(Prop_Send, "m_nSequence");
		return seq >= 0 && this.LookupSequence(sequence) == seq;
	}
	
	public int GetNewTarget(float maxDist=0.0)
	{
		float pos[3];
		this.WorldSpaceCenter(pos);
		int entity = -1;
		int targetTeam, target;
		float dist;
		float nearestDist = -1.0;
		maxDist = sq(maxDist);
		while ((entity = FindEntityByClassname(entity, "*")) != -1)
		{
			if (!IsCombatChar(entity))
				continue;
			
			if (IsValidClient(entity) && !IsPlayerAlive(entity))
				continue;
			
			targetTeam = GetEntProp(entity, Prop_Data, "m_iTeamNum");
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
		if (state)
		{
			if (!IsValidEntity2(this.GlowEnt))
			{
				this.GlowEnt = CreateEntityByName("tf_glow");
				CBaseEntity glow = CBaseEntity(this.GlowEnt);
				char name[128];
				FormatEx(name, sizeof(name), "rf2npc_%i", this.index);
				this.SetPropString(Prop_Data, "m_iName", name);
				glow.KeyValue("target", name);
				SetVariantColor({255, 255, 255, 255});
				glow.AcceptInput("SetGlowColor");
				
				float pos[3];
				this.GetAbsOrigin(pos);
				glow.Teleport(pos);
				glow.Spawn();
				glow.AcceptInput("Enable");
				ParentEntity(glow.index, this.index);
			}
		}
		else if (IsValidEntity2(this.GlowEnt))
		{
			RemoveEntity2(this.GlowEnt);
		}
	}
	
	public void SetGlowColor(int color[4])
	{
		if (IsValidEntity2(this.GlowEnt))
		{
			SetVariantColor(color);
			AcceptEntityInput(this.GlowEnt, "SetGlowColor");
		}
	}
}

CEntityFactory GetBaseNPCFactory()
{
	return g_Factory;
}

static void OnCreate(RF2_NPC_Base npc)
{
	SDKHook(npc.index, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
	SDKHook(npc.index, SDKHook_ThinkPost, ThinkPost);
	npc.DefendTeam = -1;
}

static void OnRemove(RF2_NPC_Base npc)
{
	if (npc.Path)
	{
		npc.Path.Destroy();
		npc.Path = view_as<PathFollower>(0);
	}
}

static void ThinkPost(int entity)
{
	RF2_NPC_Base(entity).SetNextThink(GetGameTime());
}

static void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3])
{
	RF2_NPC_Base npc = RF2_NPC_Base(victim);
	int health = npc.GetProp(Prop_Data, "m_iHealth");
	TE_TFParticle("bot_impact_heavy", damagePosition);
	Event event = CreateEvent("npc_hurt");
	if (event)
	{
		event.SetInt("entindex", npc.index);
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

void BaseNPC_OnMapStart()
{
	PrecacheSound(SND_BOSS_DEATH, true);
}
