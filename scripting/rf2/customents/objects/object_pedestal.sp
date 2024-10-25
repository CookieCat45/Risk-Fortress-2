#pragma semicolon 1
#pragma newdecls required

#define MODEL_PEDESTAL "models/props_mvm/mvm_museum_pedestal.mdl"
static CEntityFactory g_Factory;

methodmap RF2_Object_Pedestal < RF2_Object_Base
{
	public RF2_Object_Pedestal(int entity)
	{
		return view_as<RF2_Object_Pedestal>(entity);
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
		g_Factory = new CEntityFactory("rf2_object_pedestal", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Object_Base.GetFactory());
		g_Factory.BeginDataMapDesc()
            .DefineBoolField("m_bSpinning")
            .DefineBoolField("m_bSpinTick")
            .DefineEntityField("m_hItemSprite")
            .DefineEntityField("m_hUser")
            .DefineIntField("m_iItemType")
            .DefineFloatField("m_flSpinTime")
		.EndDataMapDesc();
		g_Factory.Install();
		HookMapStart(Fountain_OnMapStart);
	}

    property bool Spinning
    {
        public get()
        {
            return asBool(this.GetProp(Prop_Data, "m_bSpinning"));
        }

        public set(bool value)
        {
            this.SetProp(Prop_Data, "m_bSpinning", value);
        }
    }

    property bool SpinTick
    {
        public get()
        {
            return asBool(this.GetProp(Prop_Data, "m_bSpinTick"));
        }

        public set(bool value)
        {
            this.SetProp(Prop_Data, "m_bSpinTick", value);
        }
    }

    property int ItemSprite
    {
        public get()
        {
            return this.GetPropEnt(Prop_Data, "m_hItemSprite");
        }

        public set(int value)
        {
            this.SetPropEnt(Prop_Data, "m_hItemSprite", value);
        }
    }

    property int User
    {
        public get()
        {
            return this.GetPropEnt(Prop_Data, "m_hUser");
        }

        public set(int value)
        {
            this.SetPropEnt(Prop_Data, "m_hUser", value);
        }
    }

    property int ItemType
    {
        public get()
        {
            return this.GetProp(Prop_Data, "m_iItemType");
        }

        public set(int value)
        {
            this.SetProp(Prop_Data, "m_iItemType", value);
        }
    }

    property float SpinTime
    {
        public get()
        {
            return this.GetPropFloat(Prop_Data, "m_flSpinTime");
        }

        public set(float value)
        {
            this.SetPropFloat(Prop_Data, "m_flSpinTime", value);
        }
    }
}

static void OnCreate(RF2_Object_Pedestal pedestal)
{
    pedestal.SetModel(MODEL_PEDESTAL);
    pedestal.HookInteract(OnInteract);
    pedestal.SetGlowColor(255, 100, 255, 255);
    pedestal.User = INVALID_ENT;
    if (pedestal.Cost <= 0.0)
    {
        pedestal.Cost = 120.0 * RF2_Object_Base.GetCostMultiplier();
    }
    
    char text[256];
    FormatEx(text, sizeof(text), "Call for Medic\nStart Roulette ($%.0f)", pedestal.Cost);
    pedestal.SetWorldText(text);
    pedestal.TextZOffset = 90.0;
	pedestal.TextSize = 10.0;
	pedestal.SetTextColor(255, 255, 255, 255);
    pedestal.SetObjectName("Roulette Pedestal");
}

static Action OnInteract(int client, RF2_Object_Pedestal pedestal)
{
    if (pedestal.Spinning)
    {
        if (pedestal.ItemType == Item_Null || client != pedestal.User)
            return Plugin_Handled;

        pedestal.Spinning = false;
        pedestal.Active = false;
        pedestal.SetWorldText("");
        float pos[3];
        pedestal.WorldSpaceCenter(pos);
        pos[2] += 45.0;
        SpawnItem(pedestal.ItemType, pos, client, 10.0);
        EmitGameSoundToAll("Halloween.spelltick_set", pedestal.index);
        RemoveEntity(pedestal.index);
        return Plugin_Handled;
    }

    if (GetPlayerCash(client) >= pedestal.Cost)
	{
		AddPlayerCash(client, -pedestal.Cost);
		pedestal.Spinning = true;
        pedestal.SetWorldText("Call for Medic to stop");
        pedestal.SpinTime = 1.0;
        pedestal.User = client;
        CreateTimer(pedestal.SpinTime, Timer_SpinRoulette, EntIndexToEntRef(pedestal.index), TIMER_FLAG_NO_MAPCHANGE);
        EmitSoundToAll(SND_CASH, pedestal.index);
	}
	else
	{
		EmitSoundToClient(client, SND_NOPE);
		PrintCenterText(client, "%t", "NotEnoughMoney", pedestal.Cost, GetPlayerCash(client));
	}

    return Plugin_Handled;
}

static void Timer_SpinRoulette(Handle timer, int entity)
{
    RF2_Object_Pedestal pedestal = RF2_Object_Pedestal(EntRefToEntIndex(entity));
    if (!pedestal.IsValid() || !pedestal.Spinning)
        return;

    if (!IsValidClient(pedestal.User) || !IsPlayerAlive(pedestal.User))
    {
        pedestal.User = INVALID_ENT;
        pedestal.Spinning = false;
        pedestal.ItemType = Item_Null;
        pedestal.SetWorldText("Call for Medic\nStart Roulette");
        pedestal.Cost = 0.0;
        if (IsValidEntity2(pedestal.ItemSprite))
            RemoveEntity(pedestal.ItemSprite);

        return;
    }

    int item = GetRandomItem(150, 49, 1);
    pedestal.ItemType = item;
    if (IsValidEntity2(pedestal.ItemSprite))
        RemoveEntity(pedestal.ItemSprite);

    pedestal.ItemSprite = CreateEntityByName("env_sprite");
    DispatchKeyValue(pedestal.ItemSprite, "model", g_szItemSprite[item]);
    DispatchKeyValueFloat(pedestal.ItemSprite, "scale", g_flItemSpriteScale[item]);
    DispatchKeyValueInt(pedestal.ItemSprite, "rendermode", 9);
    float pos[3];
	pedestal.WorldSpaceCenter(pos);
    pos[2] += 45.0;
    TeleportEntity(pedestal.ItemSprite, pos);
    DispatchSpawn(pedestal.ItemSprite);
    ParentEntity(pedestal.ItemSprite, pedestal.index);
    switch (GetItemQuality(item))
    {
        case Quality_Genuine:		SetEntityRenderColor(pedestal.ItemSprite, 125, 255, 125, 100);
        case Quality_Unusual: 		SetEntityRenderColor(pedestal.ItemSprite, 200, 125, 255, 100);
        case Quality_Strange:		SetEntityRenderColor(pedestal.ItemSprite, 200, 150, 0, 100);
        case Quality_Collectors:	SetEntityRenderColor(pedestal.ItemSprite, 255, 100, 100, 100);
        case Quality_Haunted, 
            Quality_HauntedStrange:	SetEntityRenderColor(pedestal.ItemSprite, 125, 255, 255, 100);
    }

    if (GetItemQuality(item) == Quality_Unusual && g_iItemSpriteUnusualEffect[item] >= 0)
	{
		pos[2] += 25.0;
		TE_TFParticle(g_szUnusualEffectName[g_iItemSpriteUnusualEffect[item]], pos, pedestal.ItemSprite, PATTACH_ABSORIGIN);
	}

    EmitGameSoundToAll(pedestal.SpinTick ? "Halloween.spelltick_b" : "Halloween.spelltick_a", pedestal.index);
    pedestal.SpinTick = !pedestal.SpinTick;
    pedestal.SpinTime /= 1.04;
    CreateTimer(pedestal.SpinTime, Timer_SpinRoulette, EntIndexToEntRef(pedestal.index), TIMER_FLAG_NO_MAPCHANGE);
}
