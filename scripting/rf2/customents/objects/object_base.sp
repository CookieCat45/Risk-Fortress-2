#pragma semicolon 1
#pragma newdecls required

static CEntityFactory g_Factory;
typedef OnInteractCallback = function Action(int client, RF2_Object_Base obj);

methodmap RF2_Object_Base < CBaseAnimating
{
	public RF2_Object_Base(int entity)
	{
		return view_as<RF2_Object_Base>(entity);
	}
	
	public static CEntityFactory GetFactory()
	{
		return g_Factory;
	}
	
	public bool IsValid()
	{
		if (this.index == 0 || !IsValidEntity2(this.index))
		{
			return false;
		}
		
		static char classname[128];
		this.GetClassname(classname, sizeof(classname));
		return StrContains(classname, "rf2_object") != -1;
	}
	
	public static void Init()
	{
		g_Factory = new CEntityFactory("rf2_object_base", OnCreate, OnRemove);
		g_Factory.IsAbstract = true;
		g_Factory.DeriveFromClass("prop_dynamic_override");
		g_Factory.BeginDataMapDesc()
			.DefineIntField("m_OnInteract")
			.DefineBoolField("m_bActive", _, "active")
			.DefineBoolField("m_bMapPlaced")
			.DefineInputFunc("SetActive", InputFuncValueType_Boolean, Input_SetActive)
		.EndDataMapDesc();
		g_Factory.Install();
	}
	
	property PrivateForward OnInteractForward
	{
		public get()
		{
			return view_as<PrivateForward>(this.GetProp(Prop_Data, "m_OnInteract"));
		}

		public set(PrivateForward fwd)
		{
			this.SetProp(Prop_Data, "m_OnInteract", fwd);
		}
	}

	property bool Active
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bActive"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bActive", value);
		}
	}
	
	property bool MapPlaced
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bMapPlaced"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bMapPlaced", value);
		}
	}
	
	property int Effects
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_fEffects");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_fEffects", value);
		}
	}
	
	public void HookInteract(OnInteractCallback func)
	{
		this.OnInteractForward.AddFunction(INVALID_HANDLE, func);
	}
}

static void OnCreate(RF2_Object_Base obj)
{
	obj.OnInteractForward = new PrivateForward(ET_Hook, Param_Cell, Param_Cell);
	obj.HookInteract(ObjectBase_OnInteract);
	obj.Effects |= EF_ITEM_BLINK;
	obj.Active = true;
	if (!RF2_Object_Teleporter(obj.index).IsValid())
	{
		obj.SetProp(Prop_Send, "m_usSolidFlags", FSOLID_TRIGGER_TOUCH_DEBRIS|FSOLID_TRIGGER|FSOLID_NOT_SOLID|FSOLID_CUSTOMBOXTEST);
		obj.SetProp(Prop_Send, "m_nSolidType", SOLID_OBB);
		SetEntityCollisionGroup(obj.index, COLLISION_GROUP_DEBRIS_TRIGGER);
	}
	
	SDKHook(obj.index, SDKHook_SpawnPost, OnSpawnPost);
	obj.AcceptInput("EnableCollision");
}

static void OnSpawnPost(int entity)
{
	RF2_Object_Base obj = RF2_Object_Base(entity);
	if (g_cvDebugShowObjectSpawns.BoolValue)
	{
		float pos[3];
		char classname[128];
		obj.GetAbsOrigin(pos);
		obj.GetClassname(classname, sizeof(classname));
		PrintToServer("[RF2] %s spawned at %.0f %.0f %.0f", classname, pos[0], pos[1], pos[2]);
		PrintToConsoleAll("[RF2] %s spawned at %.0f %.0f %.0f", classname, pos[0], pos[1], pos[2]);
	}
}

static void OnRemove(RF2_Object_Base obj)
{
	RequestFrame(RF_DeleteForward, obj.OnInteractForward);
}

static void RF_DeleteForward(PrivateForward fwd)
{
	if (fwd)
		delete fwd;
}

// This is activated from a voicecommand callback.
// Return Plugin_Handled to suppress the voicecommand.
// Return Plugin_Stop to stop the object from being interacted with entirely.
static Action ObjectBase_OnInteract(int client, RF2_Object_Base obj)
{
	if (!obj.Active)
		return Plugin_Stop;
	
	return Plugin_Continue;
}

// Note: Use SpawnCrate() for crate objects
RF2_Object_Base CreateObject(const char[] classname, const float pos[3], bool spawn=true)
{
	RF2_Object_Base obj = RF2_Object_Base(CreateEntityByName(classname));
	obj.Teleport(pos);
	
	if (spawn)
		obj.Spawn();
	
	float endPos[3], angles[3];
	angles[0] = 90.0;
	Handle trace = TR_TraceRayFilterEx(pos, angles, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite, TraceFilter_WallsOnly);
	TR_GetEndPosition(endPos, trace);
	delete trace;
	if (!TR_PointOutsideWorld(endPos))
	{
		if (!RF2_Object_Workbench(obj.index).IsValid())
		{
			angles[0] = GetRandomFloat(-25.0, 25.0);
			angles[1] = GetRandomFloat(-180.0, 180.0);
			angles[2] = GetRandomFloat(-25.0, 25.0);
			obj.Teleport(endPos, angles);
		}
		else
		{
			obj.Teleport(endPos);
		}
	}
	
	return obj;
}

static void Input_SetActive(int entity, int activator, int caller, any value)
{
	RF2_Object_Base obj = RF2_Object_Base(entity);
	obj.Active = value;
	if (value)
	{
		obj.Effects |= EF_ITEM_BLINK;
	}
	else
	{
		obj.Effects &= ~EF_ITEM_BLINK;
	}
}
