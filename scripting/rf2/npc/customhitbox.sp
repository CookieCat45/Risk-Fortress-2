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
		if (this.index == 0 || !IsValidEntity2(this.index))
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
			.DefineVectorField("m_vecDamageForce")
			.DefineVectorField("m_vecCustomMins")
			.DefineVectorField("m_vecCustomMaxs")
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
	
	public void SetMins(const float vec[3])
	{
		this.SetPropVector(Prop_Data, "m_vecCustomMins", vec);
	}

	public void GetMaxs(float buffer[3])
	{
		this.GetPropVector(Prop_Data, "m_vecCustomMaxs", buffer);
	}
	
	public void SetMaxs(const float vec[3])
	{
		this.SetPropVector(Prop_Data, "m_vecCustomMaxs", vec);
	}
	
	public ArrayList DoDamage(bool remove=true)
	{
		int entity = -1;
		int owner = GetEntPropEnt(this.index, Prop_Data, "m_hOwnerEntity");
		int team = GetEntProp(owner, Prop_Data, "m_iTeamNum");
		float force[3], vel[3];
		this.GetDamageForce(force);
		if (!g_hHitEntities)
		{
			g_hHitEntities = new ArrayList();
		}
		g_hHitEntities.Clear();
		
		while ((entity = FindEntityByClassname(entity, "*")) != -1)
		{
			if (!IsCombatChar(entity))
				continue;
			
			if (entity == owner || GetEntProp(entity, Prop_Data, "m_iTeamNum") == team)
				continue;
			
			if (DoEntitiesIntersect(this.index, entity))
			{
				SDKHooks_TakeDamage2(entity, owner, owner, this.Damage, this.DamageFlags);
				this.GetDamageForce(force);
				if (VectorSum(force, true) > 0.0)
				{
					GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
					AddVectors(force, vel, vel);
					TeleportEntity(entity, _, _, vel);
				}
				
				g_hHitEntities.Push(entity);
			}
		}
		
		if (remove)
		{
			RemoveEntity2(this.index);
		}
		
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
