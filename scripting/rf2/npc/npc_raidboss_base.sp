#pragma newdecls required
#pragma semicolon 1

static CEntityFactory g_Factory;
#define SND_BOSS_DEATH "rf2/sfx/boss_death.wav"

methodmap RF2_RaidBoss_Base < CBaseCombatCharacter
{
	public RF2_RaidBoss_Base(int entity)
	{
		return view_as<RF2_RaidBoss_Base>(entity);
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
		g_Factory = new CEntityFactory("rf2_npc_raidboss_base", OnCreate);
		g_Factory.DeriveFromNPC();
		g_Factory.BeginDataMapDesc()
			.DefineEntityField("m_Target")
			.DefineIntField("m_PathFollower")
			.DefineIntField("m_bAttackBlue", _, "attackblue")
		.EndDataMapDesc();
		g_Factory.Install();
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
	
	property CBaseNPC BaseNpc
	{
		public get()
		{
			return TheNPCs.FindNPCByEntIndex(this.index);
		}
	}
	
	property bool AttackBlue
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bAttackBlue"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bAttackBlue", value);
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
	
	public CBaseEntity GetNewTarget()
	{
		float pos[3];
		this.WorldSpaceCenter(pos);
		this.Target = CBaseEntity(GetNearestPlayer(pos, _, _, this.AttackBlue ? -1 : TEAM_SURVIVOR));
		return this.Target;
	}
	
	public bool HasLOSTo(CBaseEntity entity)
	{
		return this.MyNextBotPointer().GetVisionInterface().IsLineOfSightClearToEntity(entity.index);
	}
	
	// does not change collison box
	public void SetHitboxSize(const float mins[3], const float maxs[3])
	{
		this.SetPropVector(Prop_Send, "m_vecMins", mins);
		this.SetPropVector(Prop_Send, "m_vecMaxs", maxs);
		this.SetPropVector(Prop_Send, "m_vecMinsPreScaled", mins);
		this.SetPropVector(Prop_Send, "m_vecMaxsPreScaled", maxs);
		this.SetPropVector(Prop_Send, "m_vecSpecifiedSurroundingMinsPreScaled", mins);
		this.SetPropVector(Prop_Send, "m_vecSpecifiedSurroundingMaxsPreScaled", maxs);
		this.SetPropVector(Prop_Send, "m_vecSpecifiedSurroundingMins", mins);
		this.SetPropVector(Prop_Send, "m_vecSpecifiedSurroundingMaxs", maxs);
	}
}

static void OnCreate(RF2_RaidBoss_Base boss)
{
	SDKHook(boss.index, SDKHook_SpawnPost, OnSpawnPost);
}

static void OnSpawnPost(int entity)
{
	RF2_RaidBoss_Base boss = RF2_RaidBoss_Base(entity);
	boss.Team = boss.AttackBlue ? 5 : TEAM_ENEMY;
}

void RaidBoss_OnMapStart()
{
	static bool init;
	if (!init)
	{
		RF2_RaidBoss_Base.Initialize();
		init = true;
	}

	PrecacheSound(SND_BOSS_DEATH, true);
}