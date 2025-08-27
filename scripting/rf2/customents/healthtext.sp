#pragma semicolon 1
#pragma newdecls required

enum HealthColorType
{
	HEALTHCOLOR_HIGH,
	HEALTHCOLOR_MEDIUM,
	HEALTHCOLOR_LOW,
};

static CEntityFactory g_Factory;
methodmap RF2_HealthText < CBaseEntity
{
	public RF2_HealthText(int entity)
	{
		return view_as<RF2_HealthText>(entity);
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
		g_Factory = new CEntityFactory("rf2_healthtext", OnCreate);
		g_Factory.DeriveFromClass("point_worldtext");
		g_Factory.BeginDataMapDesc()
			.DefineEntityField("m_hTarget")
			.DefineFloatField("m_flTextZOffset")
			.DefineStringField("m_szDisplayName")
			.DefineColorField("m_HealthColors", 3)
		.EndDataMapDesc();
		g_Factory.Install();
	}
	
	property int Target
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hTarget");
		}
		
		public set(int target)
		{
			this.SetPropEnt(Prop_Data, "m_hTarget", target);
		}
	}
	
	property float TextSize
	{
		public get()
		{
			return this.GetPropFloat(Prop_Send, "m_flTextSize");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Send, "m_flTextSize", value);
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
	
	public void SetTarget(int target, float zOffset=80.0, const char[] displayName="", const char[] attachment="")
	{
		this.Target = target;
		this.SetDisplayName(displayName);
		float pos[3];
		GetEntPos(target, pos);
		pos[2] += zOffset;
		this.Teleport(pos);
		ParentEntity(this.index, target, attachment, true);
	}
	
	public int GetDisplayName(char[] buffer, int size)
	{
		return this.GetPropString(Prop_Data, "m_szDisplayName", buffer, size);
	}
	
	public void SetDisplayName(const char[] name)
	{
		this.SetPropString(Prop_Data, "m_szDisplayName", name);
	}
	
	public void GetHealthColor(HealthColorType type, int buffer[4])
	{
		this.GetPropColor(Prop_Data, "m_HealthColors", buffer[0], buffer[1], buffer[2], buffer[3], view_as<int>(type));
	}
	
	public void SetHealthColor(HealthColorType type, int color[4])
	{
		this.SetPropColor(Prop_Data, "m_HealthColors", color[0], color[1], color[2], color[3], view_as<int>(type));
	}
	
	// Fixed from baseentity.inc
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

RF2_HealthText CreateHealthText(int target, float zOffset=80.0, float textSize=20.0, const char[] displayName="", const char[] attachment="")
{
	RF2_HealthText text = RF2_HealthText(CreateEntityByName("rf2_healthtext"));
	text.TextSize = textSize;
	text.TextZOffset = zOffset;
	text.SetTarget(target, zOffset, displayName, attachment);
	text.Spawn();
	return text;
}

static void OnCreate(RF2_HealthText text)
{
	text.SetProp(Prop_Send, "m_nOrientation", 1);
	text.SetHealthColor(HEALTHCOLOR_HIGH, {50, 255, 50, 255});
	text.SetHealthColor(HEALTHCOLOR_MEDIUM, {255, 255, 0, 255});
	text.SetHealthColor(HEALTHCOLOR_LOW, {255, 50, 50, 255});
	SDKHook(text.index, SDKHook_SpawnPost, OnSpawnPost);
}

static void OnSpawnPost(int entity)
{
	//RF2_HealthText text = RF2_HealthText(entity);
	RequestFrame(RF_UpdateText, EntIndexToEntRef(entity));
}

public void RF_UpdateText(int entity)
{
	int entref = entity;
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return;
	
	RF2_HealthText text = RF2_HealthText(entity);
	if (!IsValidEntity2(text.Target))
	{
		RemoveEntity2(text.index);
		return;
	}
	
	CBaseEntity target = CBaseEntity(text.Target);
	bool isClient = IsValidClient(target.index);
	if (isClient)
	{
		if (!IsPlayerAlive(target.index))
		{
			RemoveEntity2(text.index);
			return;
		}
	}

	RF2_ProvidenceShieldCrystal crystal = RF2_ProvidenceShieldCrystal(text.Target);
	if (crystal.IsValid() && crystal.Destroyed)
	{
		static char time[16];
		FormatEx(time, sizeof(time), "%.0f", FloatAbs(GetGameTime()-crystal.RegenerateAt));
		SetVariantString(time);
		text.AcceptInput("SetText");
		SetVariantColor({255, 255, 255, 255});
		text.AcceptInput("SetColor");
		RequestFrame(RF_UpdateText, entref);
		return;
	}
	
	int health = imax(target.GetProp(Prop_Data, "m_iHealth"), 0);
	int maxHealth;
	if (isClient)
	{
		maxHealth = RF2_GetCalculatedMaxHealth(target.index);
	}
	else if (RF2_TankBoss(target.index).IsValid())
	{
		maxHealth = RF2_TankBoss(target.index).MaxHealth;
	}
	else
	{
		maxHealth = target.GetProp(Prop_Data, "m_iMaxHealth");
	}
	
	static char str[256];
	FormatEx(str, sizeof(str), "%i / %i", health, maxHealth);
	SetVariantString(str);
	text.AcceptInput("SetText");
	bool rainbow = isClient && IsInvuln(target.index);
	text.SetProp(Prop_Send, "m_bRainbow", rainbow);
	if (!rainbow)
	{
		int color[4];
		if (health <= maxHealth/4)
		{
			text.GetHealthColor(HEALTHCOLOR_LOW, color);
		}
		else if (health <= maxHealth/2)
		{
			text.GetHealthColor(HEALTHCOLOR_MEDIUM, color);
		}
		else
		{
			text.GetHealthColor(HEALTHCOLOR_HIGH, color);
		}
		
		SetVariantColor(color);
		text.AcceptInput("SetColor");
	}
	
	RequestFrame(RF_UpdateText, entref);
}
