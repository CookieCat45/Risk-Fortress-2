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
			.DefineEntityField("m_hWorldTextEnt")
			.DefineStringField("m_szWorldText")
			.DefineFloatField("m_flTextZOffset")
			.DefineFloatField("m_flTextSize")
			.DefineEntityField("m_hGlow")
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

	property int WorldText
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hWorldTextEnt");
		}
		
		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hWorldTextEnt", value);
		}
	}

	property float TextZOffset
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flTextZOffset");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flTextZOffset", value);
		}
	}

	property float TextSize
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flTextSize");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flTextSize", value);
			if (IsValidEntity2(this.WorldText))
			{
				SetVariantFloat(value);
				CBaseEntity(this.WorldText).AcceptInput("SetTextSize");
			}
		}
	}
	
	public int GetWorldText(char[] buffer, int size)
	{
		return this.GetPropString(Prop_Data, "m_szWorldText", buffer, size);
	}
	
	public void SetWorldText(const char[] text)
	{
		this.SetPropString(Prop_Data, "m_szWorldText", text);
		if (IsValidEntity2(this.WorldText))
		{
			SetVariantString(text);
			CBaseEntity(this.WorldText).AcceptInput("SetText");
		}
	}
	
	public void CreateWorldText()
	{
		this.WorldText = CreateEntityByName("point_worldtext");
		CBaseEntity text = CBaseEntity(this.WorldText);
		char worldText[256];
		this.GetWorldText(worldText, sizeof(worldText));
		text.KeyValue("message", worldText);
		text.KeyValueFloat("textsize", this.TextSize);
		text.KeyValue("orientation", "1");
		text.KeyValue("color", "255 255 100 255");
		float pos[3];
		this.GetAbsOrigin(pos);
		pos[2] += this.TextZOffset;
		text.Teleport(pos);
		text.Spawn();
		SetVariantString("!activator");
		text.AcceptInput("SetParent", this.index);
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
	
	public void HookInteract(OnInteractCallback func)
	{
		this.OnInteractForward.AddFunction(INVALID_HANDLE, func);
	}
	
	public void SetModel(const char[] model)
	{
		SetEntityModel2(this.index, model);
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
				FormatEx(name, sizeof(name), "rf2object_%i", this.index);
				this.SetPropString(Prop_Data, "m_iName", name);
				glow.KeyValue("target", name);
				SetVariantColor({255, 255, 255, 255});
				glow.AcceptInput("SetGlowColor");
				float pos[3];
				this.GetAbsOrigin(pos);
				glow.Teleport(pos);
				glow.Spawn();
				glow.AcceptInput("Enable");
			}
		}
		else if (IsValidEntity2(this.GlowEnt))
		{
			RemoveEntity2(this.GlowEnt);
		}
	}
}

static void OnCreate(RF2_Object_Base obj)
{
	obj.OnInteractForward = new PrivateForward(ET_Hook, Param_Cell, Param_Cell);
	obj.HookInteract(ObjectBase_OnInteract);
	obj.Effects |= EF_ITEM_BLINK;
	obj.Active = true;
	obj.TextZOffset = 50.0;
	obj.TextSize = 6.0;
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
	
	char worldText[256];
	obj.GetWorldText(worldText, sizeof(worldText));
	if (worldText[0])
	{
		CreateTimer(0.5, Timer_WorldText, EntIndexToEntRef(obj.index), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_WorldText(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE)
		return Plugin_Stop;
	
	RF2_Object_Base obj = RF2_Object_Base(entity);
	float pos[3];
	obj.GetAbsOrigin(pos);
	if (GetNearestPlayer(pos, _, 500.0, TEAM_SURVIVOR, _, true) != -1)
	{
		if (!IsValidEntity2(obj.WorldText))
		{
			obj.CreateWorldText();
		}
	}
	else if (IsValidEntity2(obj.WorldText))
	{
		if (obj.index != GetCurrentTeleporter().index || RF2_Object_Teleporter(obj.index).EventState != TELE_EVENT_ACTIVE)
		{
			RemoveEntity2(obj.WorldText);
		}
	}
	
	return Plugin_Continue;
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
