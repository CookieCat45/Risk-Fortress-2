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
			.DefineIntField("m_iItemQuality", _, "item_quality") // Quality of the item on the workbench
			.DefineIntField("m_iTradeQuality", _, "trade_quality") // Quality of the items that must be traded in
			.DefineIntField("m_iCustomItemCost", _, "custom_item_cost")
			.DefineIntField("m_iCost")
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
	
	property int ItemQuality
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iItemQuality");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iItemQuality", value);
		}
	}
	
	property int TradeQuality
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iTradeQuality");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iTradeQuality", value);
		}
	}

	property int CustomItemCost
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iCustomItemCost");
		}
		
		public set (int value)
		{
			this.SetProp(Prop_Data, "m_iCustomItemCost", value);
		}
	}

	property int Cost
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iCost");
		}
		
		public set (int value)
		{
			this.SetProp(Prop_Data, "m_iCost", value);
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
	SDKHook(bench.index, SDKHook_SpawnPost, OnSpawnPost);
}

static void OnSpawnPost(int entity)
{
	RF2_Object_Workbench bench = RF2_Object_Workbench(entity);
	if (IsMapRunning())
	{
		// choose a random item quality if mapper doesn't force a specific one
		if (bench.ItemQuality == Quality_None)
		{
			int result;
			if (RandChanceInt(1, 100, 65, result))
			{
				bench.ItemQuality = Quality_Normal;
			}
			else if (result <= 99)
			{
				bench.ItemQuality = Quality_Genuine;
			}
			else
			{
				bench.ItemQuality = Quality_Unusual;
			}
		}
		
		// use item quality as trade quality if mapper doesn't force a specific one
		bool forcedTradeQuality;
		if (bench.TradeQuality == Quality_None)
		{
			bench.TradeQuality = bench.ItemQuality;
		}
		else
		{
			forcedTradeQuality = true;
		}
		
		// choose a random item if mapper doesn't force a specific one
		if (bench.Item == Item_Null)
		{
			bench.Item = GetRandomItemEx(forcedTradeQuality ? bench.TradeQuality : bench.ItemQuality);
		}
		
		char text[256], qualityName[32];
		GetQualityName(bench.TradeQuality, qualityName, sizeof(qualityName));
		bench.Cost = bench.CustomItemCost > 1 ? bench.CustomItemCost : 1;
		
		FormatEx(text, sizeof(text), "Call for Medic to trade for 1 %s! (Requires %i %s %s)", 
			g_szItemName[bench.Item], bench.Cost, qualityName, bench.Cost > 1 ? "items" : "item");
		
		bench.SetWorldText(text);
		bench.TextZOffset = 90.0;
		char name[256];
		FormatEx(name, sizeof(name), "Workbench (%s)", g_szItemName[bench.Item]);
		bench.SetObjectName(name);
		CBaseEntity sprite = CBaseEntity(CreateEntityByName("env_sprite"));
		bench.Sprite = sprite;
		sprite.KeyValue("model", g_szItemSprite[bench.Item]);
		sprite.KeyValueFloat("scale", g_flItemSpriteScale[bench.Item]);
		sprite.KeyValue("rendermode", "9"); // mfw no CBaseEntity.KeyValueInt
		float pos[3];
		bench.GetAbsOrigin(pos);
		pos[2] += bench.MapPlaced ? 60.0 : 35.0;
		sprite.Teleport(pos);
		sprite.Spawn();
		switch (GetItemQuality(bench.Item))
		{
			case Quality_Genuine:		sprite.SetRenderColor(125, 255, 125);
			case Quality_Unusual: 		sprite.SetRenderColor(200, 125, 255);
			case Quality_Strange:		sprite.SetRenderColor(200, 150, 0);
			case Quality_Collectors:	sprite.SetRenderColor(255, 100, 100);
			case Quality_Haunted, 
				Quality_HauntedStrange:	sprite.SetRenderColor(125, 255, 255);
		}
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
	ArrayList itemArray = new ArrayList();
	ArrayList itemsToTrade = new ArrayList();
	int quality = bench.TradeQuality;
	int benchItem = bench.Item;
	int cost = bench.Cost;
	int scrapItem;
	
	for (int i = 1; i <= GetTotalItems(); i++)
	{
		if (i != benchItem && GetItemQuality(i) == quality && PlayerHasItem(client, i, true))
		{
			if (IsScrapItem(i)) // priority
			{
				scrapItem = i;
				continue;
			}
			
			itemArray.Push(i);
		}
	}
	
	if (scrapItem != Item_Null)
	{
		int scrapCount = GetPlayerItemCount(client, scrapItem, true);
		do 
		{
			itemsToTrade.Push(scrapItem);
		}
		while (itemsToTrade.Length < scrapCount && itemsToTrade.Length < cost);
	}
	
	if (itemsToTrade.Length < cost && itemArray.Length > 0)
	{
		int item, index;
		int itemCounts[MAX_ITEMS];
		do
		{
			index = GetRandomInt(0, itemArray.Length-1);
			item = itemArray.Get(index);
			if (itemCounts[item] < GetPlayerItemCount(client, item, true))
			{
				itemsToTrade.Push(item);
				itemCounts[item]++;
			}
			else
			{
				itemArray.Erase(index);
			}
		}
		while (itemArray.Length > 0 && itemsToTrade.Length < cost);
	}
	
	delete itemArray;
	char qualityName[32];
	GetQualityName(quality, qualityName, sizeof(qualityName));
	if (itemsToTrade.Length >= cost)
	{
		int item, lastItem;
		bool oneItem = true;
		for (int i = 0; i < itemsToTrade.Length; i++)
		{
			item = itemsToTrade.Get(i);
			if (lastItem != Item_Null && item != lastItem)
			{
				oneItem = false;
			}
			
			GiveItem(client, item, -1, false);
			lastItem = item;
		}
		
		GiveItem(client, benchItem, 1, true);
		EmitSoundToAll(SND_USE_WORKBENCH, client);
		ShowItemDesc(client, benchItem);
		if (oneItem)
		{
			PrintCenterText(client, "%t", "UsedWorkbench", cost, g_szItemName[item], g_szItemName[benchItem], GetPlayerItemCount(client, item, true), g_szItemName[item]);
		}
		else
		{
			PrintCenterText(client, "%t", "UsedWorkbenchMulti", cost, qualityName, g_szItemName[benchItem]);
		}
	}
	else
	{
		PrintCenterText(client, "%t", "NoExchange", cost, qualityName);
		EmitSoundToClient(client, SND_NOPE);
	}
	
	delete itemsToTrade;
	return Plugin_Handled;
}
