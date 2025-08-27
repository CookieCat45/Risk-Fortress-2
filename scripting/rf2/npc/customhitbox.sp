#pragma newdecls required
#pragma semicolon 1

static CEntityFactory g_Factory;
static ArrayList g_hHitEntities;

methodmap RF2_CustomHitbox < CBaseAnimating
{
	public RF2_CustomHitbox(int entity)
	{
		return view_as<RF2_CustomHitbox>(entity);
	}
	
	public static RF2_CustomHitbox Create(int owner=0)
	{
		RF2_CustomHitbox box = RF2_CustomHitbox(CreateEntityByName("rf2_custom_hitbox"));
		SetEntityOwner(box.index, owner);
		return box;
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
		g_Factory = new CEntityFactory("rf2_custom_hitbox", OnCreate);
		g_Factory.DeriveFromClass("prop_dynamic_override");
		g_Factory.BeginDataMapDesc()
			.DefineFloatField("m_flDamage")
			.DefineIntField("m_iDamageFlags")
			.DefineBoolField("m_bReturnHitEnts")
			.DefineFloatField("m_flBuildingDamageMult")
			.DefineVectorField("m_vecDamageForce")
			.DefineVectorField("m_vecCustomMins")
			.DefineVectorField("m_vecCustomMaxs")
			.DefineEntityField("m_hAttacker")
			.DefineEntityField("m_hInflictor")
		.EndDataMapDesc();
		g_Factory.Install();
	}
	
	property float Damage
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flDamage");
		}

		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flDamage", value);
		}
	}

	property int DamageFlags
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iDamageFlags");
		}

		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iDamageFlags", value);
		}
	}

	property float BuildingDamageMult
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flBuildingDamageMult");
		}

		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flBuildingDamageMult", value);
		}
	}
	
	property int Attacker
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hAttacker");
		}
		
		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hAttacker", value);
		}
	}

	property int Inflictor
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hInflictor");
		}
		
		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hInflictor", value);
		}
	}
	
	property bool ReturnHitEnts
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bReturnHitEnts"));
		}

		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bReturnHitEnts", value);
		}
	}
	
	public void GetDamageForce(float buffer[3])
	{
		this.GetPropVector(Prop_Data, "m_vecDamageForce", buffer);
	}
	
	public void SetDamageForce(const float vec[3])
	{
		this.SetPropVector(Prop_Data, "m_vecDamageForce", vec);
	}

	public void GetMins(float buffer[3])
	{
		this.GetPropVector(Prop_Data, "m_vecCustomMins", buffer);
	}

	public void GetMaxs(float buffer[3])
	{
		this.GetPropVector(Prop_Data, "m_vecCustomMaxs", buffer);
	}
	
	public void SetMins(const float vec[3])
	{
		this.SetPropVector(Prop_Data, "m_vecCustomMins", vec);
	}
	
	public void SetMaxs(const float vec[3])
	{
		this.SetPropVector(Prop_Data, "m_vecCustomMaxs", vec);
	}
	
	public ArrayList DoDamage(bool remove=true)
	{
		int entity = MaxClients+1;
		int owner = GetEntPropEnt(this.index, Prop_Data, "m_hOwnerEntity");
		if (!IsValidEntity2(this.Attacker))
		{
			this.Attacker = owner;
		}
		
		if (!IsValidEntity2(this.Inflictor))
		{
			this.Inflictor = owner;
		}
		
		int team = GetEntTeam(owner);
		float force[3], vel[3];
		this.GetDamageForce(force);
		if (!g_hHitEntities)
		{
			g_hHitEntities = new ArrayList();
		}
		g_hHitEntities.Clear();
		
		while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT)
		{
			if (!IsValidEntity2(entity) || !IsCombatChar(entity))
				continue;
			
			if (IsValidClient(entity) && !IsPlayerAlive(entity))
				continue;

			if (entity == owner || GetEntTeam(entity) == team)
				continue;
			
			if (DoEntitiesIntersect(this.index, entity))
			{
				bool building = IsBuilding(entity);
				RF_TakeDamage(entity, this.Inflictor, this.Attacker, building ? this.Damage*this.BuildingDamageMult : this.Damage, this.DamageFlags);
				if (!building)
				{
					this.GetDamageForce(force);
					if (VectorSum(force, true) > 0.0)
					{
						GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
						AddVectors(force, vel, vel);
						TeleportEntity(entity, _, _, vel);
					}
				}
				
				g_hHitEntities.Push(entity);
			}
		}
		
		if (remove)
		{
			RemoveEntity2(this.index);
		}
		
		#if defined DEVONLY
		float pos[3];
		this.GetAbsOrigin(pos);
		float mins[3], maxs[3];
		this.GetMins(mins);
		this.GetMaxs(maxs);
		TE_DrawBoxAll(pos, pos, mins, maxs, 1.0, g_iBeamModel, {0, 255, 255, 255});
		#endif

		return this.ReturnHitEnts ? g_hHitEntities.Clone() : null;
	}
}

static void OnCreate(RF2_CustomHitbox box)
{
	SDKHook(box.index, SDKHook_SpawnPost, OnSpawnPost);
	box.SetProp(Prop_Send, "m_nSolidType", SOLID_OBB);
	box.SetModel(MODEL_CRATE);
	box.SetRenderMode(RENDER_NONE);
}

static void OnSpawnPost(int entity)
{
	RF2_CustomHitbox box = RF2_CustomHitbox(entity);
	float mins[3], maxs[3];
	box.GetMins(mins);
	box.GetMaxs(maxs);
	box.SetPropVector(Prop_Send, "m_vecMins", mins);
	box.SetPropVector(Prop_Send, "m_vecMinsPreScaled", mins);
	box.SetPropVector(Prop_Send, "m_vecMaxs", maxs);
	box.SetPropVector(Prop_Send, "m_vecMaxsPreScaled", maxs);
	SetEntityCollisionGroup(box.index, COLLISION_GROUP_DEBRIS_TRIGGER);
}
