#pragma semicolon 1
#pragma newdecls required

static CEntityFactory g_Factory;
methodmap RF2_RaidBossSpawner < CBaseEntity
{
	public RF2_RaidBossSpawner(int entity)
	{
		return view_as<RF2_RaidBossSpawner>(entity);
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
		g_Factory = new CEntityFactory("rf2_raid_boss_spawner", OnCreate);
		g_Factory.DeriveFromBaseEntity(true);
        g_Factory.BeginDataMapDesc()
            .DefineEntityField("m_hBoss")
            .DefineStringField("m_szBossClassname", _, "boss_classname")
            .DefineStringField("m_szBossTargetname", _, "boss_targetname")
            .DefineIntField("m_iBaseHealthOverride", _, "base_health_override")
            .DefineIntField("m_iExtraBaseHealthPerPlayer", _, "extra_health_per_player")
            .DefineInputFunc("StartBossBattle", InputFuncValueType_Void, Input_StartBossBattle)
            .DefineInputFunc("DoBossAction", InputFuncValueType_String, Input_DoBossAction)
            .DefineOutput("OnBossHealthDepleted")
            .DefineOutput("OnBossKilled")
            .DefineOutput("OnLastBossKilled")
        .EndDataMapDesc();
        g_Factory.Install();
    }

    property int Boss
    {
        public get()
        {
            return this.GetPropEnt(Prop_Data, "m_hBoss");
        }

        public set(int value)
        {
            this.SetPropEnt(Prop_Data, "m_hBoss", value);
        }
    }

    property int BaseHealthOverride
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iBaseHealthOverride");
		}

		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iBaseHealthOverride", value);
		}
	}

	property int ExtraBaseHealthPerPlayer
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iExtraBaseHealthPerPlayer");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iExtraBaseHealthPerPlayer", value);
		}
	}

    public int GetBossClassname(char[] buffer, int size)
    {
        return this.GetPropString(Prop_Data, "m_szBossClassname", buffer, size);
    }
    
    public void SetBossClassname(const char[] classname)
    {
        this.SetPropString(Prop_Data, "m_szBossClassname", classname);
    }
    
    public int GetBossTargetname(char[] buffer, int size)
    {
        return this.GetPropString(Prop_Data, "m_szBossTargetname", buffer, size);
    }
    
    public void SetBossTargetname(const char[] classname)
    {
        this.SetPropString(Prop_Data, "m_szBossTargetname", classname);
    }

    public bool IsActive()
    {
        return IsValidEntity2(this.Boss);
    }

    public void InitBossBattle()
    {
        char classname[128];
        this.GetBossClassname(classname, sizeof(classname));
        RF2_NPC_Base boss = RF2_NPC_Base(CreateEntityByName(classname));
        if (!boss.IsValid())
        {
            LogError("rf2_raid_boss_spawner: Failed to create boss entity \"%s\".", classname);
            return;
        }
        
        this.Boss = boss.index;
        char targetName[128];
        this.GetBossTargetname(targetName, sizeof(targetName));
        boss.KeyValue("targetname", targetName);
        float pos[3], angles[3];
        this.GetAbsOrigin(pos);
        this.GetAbsAngles(angles);
        boss.RaidBossSpawner = this.index;
        boss.Teleport(pos, angles);
        boss.Spawn();
        if (this.BaseHealthOverride > 0)
		{
			int extraHealth = this.ExtraBaseHealthPerPlayer * (RF2_GetSurvivorCount()-1);
			int health = RoundToFloor(float(this.BaseHealthOverride+extraHealth) * (1.0 + (float(RF2_GetEnemyLevel()-1) * GetEnemyHealthMult())));
            SetEntProp(this.Boss, Prop_Data, "m_iMaxHealth", health);
			SetEntProp(this.Boss, Prop_Data, "m_iHealth", health);
		}
        
        g_bRaidBossMode = true;
    }

    public void OnBossKilled()
    {
        this.FireOutput("OnBossKilled", this.Boss);
        
        // Check if any other raid boss spawners still have bosses active. If they don't, disable raid boss mode.
        bool stillActive;
        int entity = MaxClients+1;
        while ((entity = FindEntityByClassname(entity, "rf2_raid_boss_spawner")) != INVALID_ENT)
        {
            if (entity == this.index)
                continue;

            if (RF2_RaidBossSpawner(entity).IsActive())
            {
                stillActive = true;
                break;
            }
        }

        this.Boss = INVALID_ENT;
        if (!stillActive)
        {
            g_bRaidBossMode = false;
            this.FireOutput("OnLastBossKilled");
        }
    }
}

static void OnCreate(RF2_RaidBossSpawner spawner)
{
    
}

static void Input_StartBossBattle(int entity, int activator, int caller)
{
    RF2_RaidBossSpawner spawner = RF2_RaidBossSpawner(entity);
    if (spawner.IsActive())
        return;

    spawner.InitBossBattle();
}

static void Input_DoBossAction(int entity, int activator, int caller, const char[] value)
{
    RF2_RaidBossSpawner spawner = RF2_RaidBossSpawner(entity);
    if (!spawner.IsActive())
        return;

    RF2_NPC_Base(spawner.Boss).DoAction(value);
}
