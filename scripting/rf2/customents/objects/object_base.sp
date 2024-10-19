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
		if (!IsValidEntity2(this.index))
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
			.DefineFloatField("m_flCost", _, "cost")
			.DefineBoolField("m_bActive", _, "active")
			.DefineBoolField("m_bMapPlaced")
			.DefineBoolField("m_bDisallowNonSurvivorMinions")
			.DefineEntityField("m_hGlow")
			.DefineColorField("m_GlowColor")
			.DefineEntityField("m_hWorldTextEnt")
			.DefineStringField("m_szWorldText")
			.DefineFloatField("m_flTextZOffset")
			.DefineFloatField("m_flTextSize")
			.DefineFloatField("m_flTextDist")
			.DefineColorField("m_TextColor")
			.DefineStringField("m_szObjectName")
			.DefineIntField("m_OnInteractForward")
			.DefineInputFunc("SetActive", InputFuncValueType_Boolean, Input_SetActive)
		.EndDataMapDesc();
		g_Factory.Install();
	}
	
	property PrivateForward OnInteractForward
	{
		public get()
		{
			return view_as<PrivateForward>(this.GetProp(Prop_Data, "m_OnInteractForward"));
		}

		public set(PrivateForward fwd)
		{
			this.SetProp(Prop_Data, "m_OnInteractForward", fwd);
		}
	}
	
	property float Cost
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flCost");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flCost", value);
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
			int r, g, b, a;
			if (value)
			{
				this.GetRenderColor(r, g, b, a);
				this.SetRenderColor(r, g, b, 255);
				this.Effects |= EF_ITEM_BLINK;
			}
			else
			{
				this.Effects &= ~EF_ITEM_BLINK;
				this.SetRenderMode(RENDER_TRANSCOLOR);
				this.GetRenderColor(r, g, b, a);
				this.SetRenderColor(r, g, b, 75);
			}
			
			this.SetProp(Prop_Data, "m_bActive", value);
		}
	}
	
	property bool DisallowNonSurvivorMinions
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bDisallowNonSurvivorMinions"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bDisallowNonSurvivorMinions", value);
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

	property Handle GlowTimer
	{
		public get()
		{
			return g_hEntityGlowResetTimer[this.index];
		}
		
		public set(Handle timer)
		{
			g_hEntityGlowResetTimer[this.index] = timer;
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
	
	property float TextDist
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flTextDist");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flTextDist", value);
		}
	}
	
	public static float GetCostMultiplier()
	{
		float value = 1.0 + (g_flDifficultyCoeff / g_cvSubDifficultyIncrement.FloatValue);
		value += FloatFraction(Pow(1.35, float(g_iStagesCompleted)));
		return fmax(value, 1.0);
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
		int color[4];
		this.GetTextColor(color);
		SetVariantColor(color);
		text.AcceptInput("SetColor");
		float pos[3];
		this.GetAbsOrigin(pos);
		pos[2] += this.TextZOffset;
		text.Teleport(pos);
		text.Spawn();
		ParentEntity(text.index, this.index);
	}
	
	public void GetTextColor(int buffer[4])
	{
		this.GetPropColor(Prop_Data, "m_TextColor", buffer[0], buffer[1], buffer[2], buffer[3]);
	}
	
	public void SetTextColor(int r=255, int g=255, int b=255, int a=255)
	{
		this.SetPropColor(Prop_Data, "m_TextColor", r, g, b, a);
		if (IsValidEntity2(this.WorldText))
		{
			int color[4];
			color[0] = r;
			color[1] = g;
			color[2] = b;
			color[3] = a;
			SetVariantColor(color);
			AcceptEntityInput(this.WorldText, "SetColor");
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
		this.GlowEnt = ToggleGlow(this.index, state);
		if (state)
		{
			int color[4];
			this.GetGlowColor(color);
			SetVariantColor(color);
			AcceptEntityInput(this.GlowEnt, "SetGlowColor");
		}
	}
	
	public void GetGlowColor(int buffer[4])
	{
		this.GetPropColor(Prop_Data, "m_GlowColor", buffer[0], buffer[1], buffer[2], buffer[3]);
	}
	
	public void SetGlowColor(int r=255, int g=255, int b=255, int a=255)
	{
		this.SetPropColor(Prop_Data, "m_GlowColor", r, g, b, a);
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
	
	public void GetObjectName(char[] buffer, int size)
	{
		this.GetPropString(Prop_Data, "m_szObjectName", buffer, size);
	}
	
	public void SetObjectName(const char[] name)
	{
		this.SetPropString(Prop_Data, "m_szObjectName", name);
	}
	
	public void PingMe(const char[] text="", float duration=8.0)
	{
		if (text[0])
		{
			float pos[3];
			this.WorldSpaceCenter(pos);
			ShowAnnotationToAll(pos, text, duration, this.index, this.index);
		}

		if (IsGlowing(this.index, true) || !IsGlowing(this.index, true) && !IsGlowing(this.index))
		{
			this.SetGlow(true);
			if (this.GlowTimer)
			{
				delete this.GlowTimer;
			}
			
			this.GlowTimer = CreateTimer(duration, Timer_ResetGlow, EntIndexToEntRef(this.index), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	public void ScaleHitbox(float value)
	{
		float mins[3], maxs[3];
		this.GetPropVector(Prop_Send, "m_vecMins", mins);
		this.GetPropVector(Prop_Send, "m_vecMaxs", maxs);
		ScaleVector(mins, value);
		ScaleVector(maxs, value);
		this.SetPropVector(Prop_Send, "m_vecMins", mins);
		this.SetPropVector(Prop_Send, "m_vecMaxs", maxs);
		this.SetPropVector(Prop_Send, "m_vecMinsPreScaled", mins);
		this.SetPropVector(Prop_Send, "m_vecMaxsPreScaled", maxs);
		this.SetPropVector(Prop_Send, "m_vecSpecifiedSurroundingMins", mins);
		this.SetPropVector(Prop_Send, "m_vecSpecifiedSurroundingMaxs", maxs);
		this.SetPropVector(Prop_Send, "m_vecSpecifiedSurroundingMinsPreScaled", mins);
		this.SetPropVector(Prop_Send, "m_vecSpecifiedSurroundingMaxsPreScaled", maxs);
	}

	/**
	 * Gets a network property as a color.
	 *
	 * @param type          Property type.
	 * @param prop          Property to use.
	 * @param r             Red component
	 * @param g             Green component
	 * @param b             Blue component
	 * @param a             Alpha component
	 * @param element       Element # (starting from 0) if property is an array.
	 * @error               Invalid entity, offset out of reasonable bounds, or property is not valid.
	 */
	public void GetPropColor(PropType type, const char[] prop, int &r = 0, int &g = 0, int &b = 0, int &a = 0, int element=0)
	{
		int value = this.GetProp(type, prop, _, element);
		r = value & 0xff;
		g = (value >> 8) & 0xff;
		b = (value >> 16) & 0xff;
		a = (value >> 24) & 0xff;
	}
	
	/**
	 * Sets a network property as a color.
	 *
	 * @param type          Property type.
	 * @param prop          Property to use.
	 * @param r             Red component
	 * @param g             Green component
	 * @param b             Blue component
	 * @param a             Alpha component
	 * @param element       Element # (starting from 0) if property is an array.
	 * @return              Number of non-null bytes written.
	 * @error               Invalid entity, offset out of reasonable bounds, or property is not valid.
	 */
	public void SetPropColor(PropType type, const char[] prop, int r = 255, int g = 255, int b = 255, int a = 255, int element=0)
	{
		r = r & 0xff;
		g = (g & 0xff) << 8;
		b = (b & 0xff) << 16;
		a = (a & 0xff) << 24;
		
		this.SetProp(type, prop, r | g | b | a, _, element);
	}
}

static void OnCreate(RF2_Object_Base obj)
{
	obj.OnInteractForward = new PrivateForward(ET_Hook, Param_Cell, Param_Cell);
	obj.HookInteract(ObjectBase_OnInteract);
	obj.Effects |= EF_ITEM_BLINK;
	obj.Active = true;
	obj.MapPlaced = true; // Assume this object is map placed, set to false in CreateObject()
	obj.TextZOffset = 50.0;
	obj.TextSize = 6.0;
	obj.TextDist = 500.0;
	obj.SetTextColor(255, 255, 100, 255);
	obj.SetGlowColor(255, 255, 255, 255);
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
	
	// Because some props are marked as breakable and will break if shot without firing events. Very dumb.
	obj.SetProp(Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
	CreateTimer(0.5, Timer_WorldText, EntIndexToEntRef(obj.index), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

static Action Timer_WorldText(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return Plugin_Stop;
	
	RF2_Object_Base obj = RF2_Object_Base(entity);
	if (!obj.Active && GetCurrentTeleporter().index != obj.index)
	{
		if (IsValidEntity2(obj.WorldText))
		{
			RemoveEntity2(obj.WorldText);
		}
		
		return Plugin_Continue;
	}
	
	float pos[3];
	obj.GetAbsOrigin(pos);
	int nearestPlayer = GetNearestPlayer(pos, _, obj.TextDist, TEAM_SURVIVOR, _, true);
	if (nearestPlayer != INVALID_ENT && IsPlayerSurvivor(nearestPlayer))
	{
		if (!IsValidEntity2(obj.WorldText))
		{
			obj.CreateWorldText();
		}
	}
	else if (IsValidEntity2(obj.WorldText))
	{
		if (GetCurrentTeleporter().index != obj.index || RF2_Object_Teleporter(obj.index).EventState != TELE_EVENT_ACTIVE)
		{
			RemoveEntity2(obj.WorldText);
		}
	}
	
	return Plugin_Continue;
}

static void Timer_ResetGlow(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return;
	
	if (RF2_Object_Teleporter(entity).IsValid() && RF2_Object_Teleporter(entity).EventState != TELE_EVENT_INACTIVE)
	{
		RF2_Object_Base(entity).GlowTimer = null;
		return;
	}
	
	RF2_Object_Base(entity).SetGlow(false);
	RF2_Object_Base(entity).GlowTimer = null;
}

static void OnRemove(RF2_Object_Base obj)
{
	if (obj.OnInteractForward)
	{
		RequestFrame(RF_DeleteForward, obj.OnInteractForward);
		obj.OnInteractForward = null;
	}
}

static void RF_DeleteForward(PrivateForward fwd)
{
	delete fwd;
}

// This is activated from a voicecommand callback.
// Return Plugin_Handled to suppress the voicecommand.
// Return Plugin_Stop to stop the object from being interacted with entirely.
static Action ObjectBase_OnInteract(int client, RF2_Object_Base obj)
{
	if (!obj.Active || GetClientTeam(client) == TEAM_ENEMY)
		return Plugin_Stop;
	
	if (!IsPlayerSurvivor(client) && (obj.DisallowNonSurvivorMinions || !IsPlayerMinion(client)))
	{
		EmitSoundToClient(client, SND_NOPE);
		PrintCenterText(client, "Wait until the next map to use this!");
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

// Note: Use SpawnCrate() for crate objects
RF2_Object_Base CreateObject(const char[] classname, const float pos[3], bool spawn=true, float zOffset=0.0)
{
	RF2_Object_Base obj = RF2_Object_Base(CreateEntityByName(classname));
	if (!obj.IsValid())
	{
		LogError("[CreateObject] Failed to create object: %s", classname);
		return RF2_Object_Base(INVALID_ENT);
	}
	
	obj.MapPlaced = false;
	obj.Teleport(pos);
	
	if (spawn)
		obj.Spawn();
	
	float endPos[3], angles[3];
	angles[0] = 90.0;
	Handle trace = TR_TraceRayFilterEx(pos, angles, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite, TraceFilter_WallsOnly);
	TR_GetEndPosition(endPos, trace);
	endPos[2] += zOffset;
	delete trace;
	if (!TR_PointOutsideWorld(endPos))
	{
		if (!RF2_Object_Workbench(obj.index).IsValid() && !RF2_Object_Pedestal(obj.index).IsValid())
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
	RF2_Object_Base(entity).Active = value;
}
