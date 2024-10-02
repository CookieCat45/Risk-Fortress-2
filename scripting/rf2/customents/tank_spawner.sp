#pragma semicolon 1
#pragma newdecls required

static CEntityFactory g_Factory;
methodmap RF2_TankSpawner < CBaseEntity
{
	public RF2_TankSpawner(int entity)
	{
		return view_as<RF2_TankSpawner>(entity);
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
		g_Factory = new CEntityFactory("rf2_tank_spawner", OnCreate);
		g_Factory.DeriveFromBaseEntity(true);
		g_Factory.BeginDataMapDesc()
			.DefineBoolField("m_bUseForTankDestruction", _, "tank_destruction_spawnpoint")
			.DefineIntField("m_iBaseHealthOverride", _, "base_health_override")
			.DefineIntField("m_iExtraBaseHealthPerPlayer", _, "extra_health_per_player")
			.DefineFloatField("m_flSpeedOverride", _, "speed_override")
			.DefineInputFunc("SpawnTank", InputFuncValueType_String, Input_SpawnTank)
			.DefineInputFunc("SpawnBadassTank", InputFuncValueType_String, Input_SpawnBadassTank)
			.DefineInputFunc("SpawnSuperBadassTank", InputFuncValueType_String, Input_SpawnSuperBadassTank)
		.EndDataMapDesc();
		g_Factory.Install();
	}
	
	property bool UseForTankDestruction
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bUseForTankDestruction"));
		}

		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bUseForTankDestruction", value);
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
	
	property float SpeedOverride
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flSpeedOverride");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flSpeedOverride", value);
		}
	}
	
	public void CheckStatOverrides(RF2_TankBoss tank)
	{
		if (this.BaseHealthOverride > 0)
		{
			int extraHealth = this.ExtraBaseHealthPerPlayer * (RF2_GetSurvivorCount()-1);
			int health = RoundToFloor(float(this.BaseHealthOverride+extraHealth) * (1.0 + (float(RF2_GetEnemyLevel()-1) * g_cvTankHealthScale.FloatValue)));
			tank.MaxHealth = health;
			tank.Health = health;
		}
		
		if (this.SpeedOverride >= 0.0)
		{
			tank.Speed = this.SpeedOverride;
		}
	}
}

static void OnCreate(RF2_TankSpawner spawner)
{
	spawner.BaseHealthOverride = 0;
	spawner.SpeedOverride = -1.0;
}

public void Input_SpawnTank(int entity, int activator, int caller, const char[] value)
{
	RF2_TankSpawner spawner = RF2_TankSpawner(entity);
	RF2_TankBoss tank = CreateTankBoss(TankType_Normal, spawner);
	spawner.CheckStatOverrides(tank);
	if (value[0])
	{
		int pathTrack = INVALID_ENT;
		bool found;
		char name[128];
		while ((pathTrack = FindEntityByClassname(pathTrack, "path_track")) != INVALID_ENT)
		{
			GetEntPropString(pathTrack, Prop_Data, "m_iName", name, sizeof(name));
			if (strcmp2(name, value))
			{
				found = true;
				break;
			}
		}
		
		if (found)
			tank.SetPathTrackNode(pathTrack);
	}
}

public void Input_SpawnBadassTank(int entity, int activator, int caller, const char[] value)
{
	RF2_TankSpawner spawner = RF2_TankSpawner(entity);
	RF2_TankBoss tank = CreateTankBoss(TankType_Badass, spawner);
	spawner.CheckStatOverrides(tank);
	if (value[0])
	{
		int pathTrack = INVALID_ENT;
		bool found;
		char name[128];
		while ((pathTrack = FindEntityByClassname(pathTrack, "path_track")) != INVALID_ENT)
		{
			GetEntPropString(pathTrack, Prop_Data, "m_iName", name, sizeof(name));
			if (strcmp2(name, value))
			{
				found = true;
				break;
			}
		}
		
		if (found)
			tank.SetPathTrackNode(pathTrack);
	}
}

public void Input_SpawnSuperBadassTank(int entity, int activator, int caller, const char[] value)
{
	RF2_TankSpawner spawner = RF2_TankSpawner(entity);
	RF2_TankBoss tank = CreateTankBoss(TankType_SuperBadass, spawner);
	spawner.CheckStatOverrides(tank);
	if (value[0])
	{
		int pathTrack = INVALID_ENT;
		bool found;
		char name[128];
		while ((pathTrack = FindEntityByClassname(pathTrack, "path_track")) != INVALID_ENT)
		{
			GetEntPropString(pathTrack, Prop_Data, "m_iName", name, sizeof(name));
			if (strcmp2(name, value))
			{
				found = true;
				break;
			}
		}
		
		if (found)
			tank.SetPathTrackNode(pathTrack);
	}
}
