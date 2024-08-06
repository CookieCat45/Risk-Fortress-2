#pragma semicolon 1
#pragma newdecls required

#define MODEL_FOUNTAIN "models/props_c17/fountain_01.mdl"

enum
{
	FountainType_Chance,
	FountainType_Life,
	FountainType_Fire,
	FountainType_Electric,
};

static CEntityFactory g_Factory;
methodmap RF2_Object_Fountain < RF2_Object_Base
{
	public RF2_Object_Fountain(int entity)
	{
		return view_as<RF2_Object_Fountain>(entity);
	}
	
	public static CEntityFactory GetFactory()
	{
		return g_Factory;
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
		g_Factory = new CEntityFactory("rf2_object_fountain", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Object_Base.GetFactory());
		g_Factory.BeginDataMapDesc()
			.DefineIntField("m_iType", _, "type")
			.DefineIntField("m_iTimesUsed")
		.EndDataMapDesc();
		g_Factory.Install();
		HookMapStart(Fountain_OnMapStart);
	}
	
	property int Type
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iType");
		}

		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iType", value);
		}
	}
	
	property int TimesUsed
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iTimesUsed");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iTimesUsed", value);
		}
	}
}

void Fountain_OnMapStart()
{
	PrecacheModel2(MODEL_FOUNTAIN, true);
}

static void OnCreate(RF2_Object_Fountain fountain)
{
	fountain.SetModel(MODEL_FOUNTAIN);
	fountain.HookInteract(Fountain_OnInteract);
	SDKHook(fountain.index, SDKHook_SpawnPost, OnSpawnPost);
}

static void OnSpawnPost(int entity)
{
	RF2_Object_Fountain fountain = RF2_Object_Fountain(entity);
	switch (fountain.Type)
	{
		case FountainType_Chance:
		{
			fountain.SetRenderColor(0, 0, 255);
			fountain.SetGlowColor(0, 0, 255);
		}
		
		case FountainType_Life:
		{
			fountain.SetRenderColor(0, 255, 0);
			fountain.SetGlowColor(0, 255, 0);
		}
		
		case FountainType_Fire:
		{
			fountain.SetRenderColor(255, 0, 0);
			fountain.SetGlowColor(255, 0, 0);
		}
		
		case FountainType_Electric:
		{
			fountain.SetRenderColor(255, 255, 0);
			fountain.SetGlowColor(255, 255, 0);
		}
	}
}

static Action Fountain_OnInteract(int client, RF2_Object_Fountain fountain)
{
	switch (fountain.Type)
	{
	
	}
	
	return Plugin_Handled;
}
