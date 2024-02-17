#pragma semicolon 1
#pragma newdecls required

#define MODEL_WORKBENCH "models/props_manor/table_01.mdl"
static CEntityFactory g_Factory;

methodmap RF2_Object_Workbench < RF2_Object_Base
{
	public RF2_Object_Workbench(int entity)
	{
		return view_as<RF2_Object_Workbench>(entity);
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
		
		return CEntityFactory.GetFactoryOfEntity(this.index) == g_Factory;
	}
	
	public static void Init()
	{
		g_Factory = new CEntityFactory("rf2_object_workbench", OnCreate, OnRemove);
		g_Factory.DeriveFromFactory(RF2_Object_Base.GetFactory());
		g_Factory.BeginDataMapDesc()
			.DefineIntField("m_iBenchItem", _, "item")
			.DefineIntField("m_iQuality", _, "quality")
			.DefineBoolField("m_bForceQuality", _, "forcequality") // For mappers
			.DefineBoolField("m_bForceItem", _, "forceitem") // For mappers
			.DefineEntityField("m_hDisplaySprite")
		.EndDataMapDesc();
		g_Factory.Install();
		HookMapStart(Workbench_OnMapStart);
	}
	
	property int Item
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iBenchItem");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iBenchItem", value);
		}
	}

	property int Quality
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iQuality");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iQuality", value);
		}
	}
	
	property bool ForceQuality
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bForceQuality"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bForceQuality", value);
		}
	}

	property bool ForceItem
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bForceItem"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bForceItem", value);
		}
	}

	property CBaseEntity Sprite
	{
		public get()
		{
			return CBaseEntity(this.GetPropEnt(Prop_Data, "m_hDisplaySprite"));
		}
		
		public set(CBaseEntity sprite)
		{
			this.SetPropEnt(Prop_Data, "m_hDisplaySprite", sprite.index);
		}
	}
}

void Workbench_OnMapStart()
{
	PrecacheModel2(MODEL_WORKBENCH, true);
}

static void OnCreate(RF2_Object_Workbench bench)
{
	bench.SetModel(MODEL_WORKBENCH);
	bench.HookInteract(Workbench_OnInteract);
	if (!bench.ForceQuality)
	{
		int result;
		if (RandChanceInt(1, 100, 65, result))
		{
			bench.Quality = Quality_Normal;
		}
		else if (result <= 99)
		{
			bench.Quality = Quality_Genuine;
		}
		else
		{
			bench.Quality = Quality_Unusual;
		}
	}
	
	if (!bench.ForceQuality || !bench.ForceItem)
	{
		bench.Item = GetRandomItemEx(bench.Quality);
	}
	
	SDKHook(bench.index, SDKHook_SpawnPost, OnSpawnPost);
	char text[256];
	FormatEx(text, sizeof(text), "Press [E] to trade for 1 %s!", g_szItemName[bench.Item]);
	bench.SetWorldText(text);
	bench.TextZOffset = 90.0;
}

static void OnSpawnPost(int entity)
{
	RF2_Object_Workbench bench = RF2_Object_Workbench(entity);
	CBaseEntity sprite = CBaseEntity(CreateEntityByName("env_sprite"));
	bench.Sprite = sprite;
	sprite.KeyValue("model", g_szItemSprite[bench.Item]);
	sprite.KeyValueFloat("scale", g_flItemSpriteScale[bench.Item]);
	sprite.KeyValue("rendermode", "9"); // mfw no CBaseEntity.KeyValueInt
	float pos[3];
	bench.GetAbsOrigin(pos);
	pos[2] += 50.0;
	sprite.Teleport(pos);
	sprite.Spawn();
	switch (bench.Quality)
	{
		case Quality_Genuine:		sprite.SetRenderColor(125, 255, 125);
		case Quality_Unusual: 		sprite.SetRenderColor(200, 125, 255);
		case Quality_Strange:		sprite.SetRenderColor(200, 150, 0);
		case Quality_Collectors:	sprite.SetRenderColor(255, 100, 100);
		case Quality_Haunted, 
			Quality_HauntedStrange:	sprite.SetRenderColor(125, 255, 255);
	}
}

static void OnRemove(RF2_Object_Workbench bench)
{
	if (bench.Sprite.IsValid())
	{
		RemoveEntity2(bench.Sprite.index);
	}
}

static Action Workbench_OnInteract(int client, RF2_Object_Workbench bench)
{
	ArrayList itemArray = CreateArray();
	int quality = bench.Quality;
	int benchItem = bench.Item;
	int item;
	
	for (int i = 1; i <= GetTotalItems(); i++)
	{
		if (i != benchItem && GetItemQuality(i) == quality && PlayerHasItem(client, i))
		{
			if (IsScrapItem(i)) // priority
			{
				item = i;
				break;
			}
			
			itemArray.Push(i);
		}
	}
	
	if (itemArray.Length > 0 && item <= Item_Null)
	{
		item = itemArray.Get(GetRandomInt(0, itemArray.Length-1));
	}
	
	delete itemArray;
	if (item > Item_Null)
	{
		GiveItem(client, item, -1);
		GiveItem(client, benchItem, 1, true);
		EmitSoundToAllEx(SND_USE_WORKBENCH, client);
		PrintCenterText(client, "%t", "UsedWorkbench", g_szItemName[item], g_szItemName[benchItem], GetPlayerItemCount(client, item), g_szItemName[item]);
	}
	else
	{
		char qualityName[32];
		GetQualityName(quality, qualityName, sizeof(qualityName));
		EmitSoundToClientEx(client, SND_NOPE);
		PrintCenterText(client, "%t", "NoExchange", qualityName);
	}

	return Plugin_Handled;
}