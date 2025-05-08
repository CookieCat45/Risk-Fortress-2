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
		if (!IsValidEntity2(this.index))
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
			.DefineIntField("m_iCustomItemReward", _, "custom_item_reward")
			.DefineIntField("m_iCost")
			.DefineIntField("m_iReward")
			.DefineBoolField("m_bIsComposter", _, "is_composter")
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

	property int CustomItemReward
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iCustomItemReward");
		}
		
		public set (int value)
		{
			this.SetProp(Prop_Data, "m_iCustomItemReward", value);
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

	property int Reward
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iReward");
		}
		
		public set (int value)
		{
			this.SetProp(Prop_Data, "m_iReward", value);
		}
	}

	property bool IsComposter
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bIsComposter"));
		}
		
		public set (bool value)
		{
			this.SetProp(Prop_Data, "m_bIsComposter", value);
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

	public Action DoTrade(int client)
	{
		ArrayList itemArray = new ArrayList();
		ArrayList itemsToTrade = new ArrayList();
		int scrapItem;
		int benchItem = this.ItemQuality == Quality_Collectors ? GetRandomCollectorItem(TF2_GetPlayerClass(client)) : this.Item;
		
		for (int i = 1; i < GetTotalItems(); i++)
		{
			if (i != benchItem && GetItemQuality(i) == this.TradeQuality && PlayerHasItem(client, i, true))
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
			while (itemsToTrade.Length < scrapCount && itemsToTrade.Length < this.Cost);
		}
		
		if (itemsToTrade.Length < this.Cost && itemArray.Length > 0)
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
			while (itemArray.Length > 0 && itemsToTrade.Length < this.Cost);
		}
		
		delete itemArray;
		char qualityName[32];
		GetQualityName(this.TradeQuality, qualityName, sizeof(qualityName));
		if (itemsToTrade.Length >= this.Cost)
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
			
			GiveItem(client, benchItem, this.Reward, true);
			EmitSoundToAll(SND_USE_WORKBENCH, client);
			ShowItemDesc(client, benchItem);
			if (oneItem)
			{
				PrintCenterText(client, "%t", "UsedWorkbench", this.Cost, g_szItemName[item], g_szItemName[benchItem], GetPlayerItemCount(client, item, true), g_szItemName[item], this.Reward);
			}
			else
			{
				PrintCenterText(client, "%t", "UsedWorkbenchMulti", this.Cost, qualityName, g_szItemName[benchItem], this.Reward);
			}
		}
		else
		{
			PrintCenterText(client, "%t", "NoExchange", this.Cost, qualityName);
			EmitSoundToClient(client, SND_NOPE);
		}
		
		delete itemsToTrade;
		return Plugin_Handled;
	}
	
	public static bool IsAnyComposterActive()
	{
		int entity = MaxClients+1;
		while ((entity = FindEntityByClassname(entity, "rf2_object_workbench")) != INVALID_ENT)
		{
			if (RF2_Object_Workbench(entity).IsComposter)
				return true;
		}
		
		return false;
	}
}

void Workbench_OnMapStart()
{
	PrecacheModel2(MODEL_WORKBENCH, true);
}

static void OnCreate(RF2_Object_Workbench bench)
{
	bench.DisallowNonSurvivorMinions = true;
	bench.SetModel(MODEL_WORKBENCH);
	bench.HookInteract(Workbench_OnInteract);
	SDKHook(bench.index, SDKHook_SpawnPost, OnSpawnPost);
}

static void OnSpawnPost(int entity)
{
	if (!IsMapRunning())
		return;
	
	RF2_Object_Workbench bench = RF2_Object_Workbench(entity);
	if (bench.IsComposter)
	{
		bench.ItemQuality = Quality_Collectors;
	}
	else if (bench.ItemQuality == Quality_None)
	{
		// choose a random item quality if mapper doesn't force a specific one
		if (GetRandomInt(1, 40) == 1 && !RF2_Object_Workbench.IsAnyComposterActive())
		{
			// 1 in 40 for a composter (trades 2 greens for a collectors)
			bench.IsComposter = true;
			bench.ItemQuality = Quality_Collectors;
		}
		else
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
	}
	else if (IsInUnderworld() && bench.ItemQuality != Quality_Haunted && !IsScrapItem(bench.Item)
		&& GetRandomInt(1, 40) == 1 && !RF2_Object_Workbench.IsAnyComposterActive())
	{
		// also allow composters to spawn in hell
		bench.IsComposter = true;
		bench.ItemQuality = Quality_Collectors;
		bench.TradeQuality = Quality_Genuine;
	}
	
	// use item quality as trade quality if mapper doesn't force a specific one
	bool forcedTradeQuality;
	if (bench.TradeQuality == Quality_None)
	{
		if (bench.IsComposter)
		{
			bench.TradeQuality = Quality_Genuine;
		}
		else
		{
			bench.TradeQuality = bench.ItemQuality;
		}
	}
	else
	{
		forcedTradeQuality = true;
	}
	
	// choose a random item if mapper doesn't force a specific one
	if (bench.Item == Item_Null)
	{
		int quality = forcedTradeQuality ? bench.TradeQuality : bench.ItemQuality;
		ArrayList validItems = GetSortedItemList(true, false);
		for (int i = validItems.Length-1; i >= 0; i--)
		{
			if (GetItemQuality(validItems.Get(i)) != quality)
			{
				validItems.Erase(i);
			}
		}

		// try not to have duplicates
		int other = MaxClients+1;
		int index = -1;
		RF2_Object_Workbench otherBench;
		while ((other  = FindEntityByClassname(other, "rf2_object_workbench")) != INVALID_ENT)
		{
			otherBench = RF2_Object_Workbench(other);
			if (otherBench.Item != Item_Null)
			{
				index = validItems.FindValue(otherBench.Item);
				if (index != -1)
				{
					validItems.Erase(index);
				}
			}
		}

		if (validItems.Length > 0)
		{
			bench.Item = validItems.Get(GetRandomInt(0, validItems.Length-1));
		}
		else
		{
			bench.Item = GetRandomItemEx(quality);
		}

		delete validItems;
	}
	
	char text[256], qualityName[32];
	GetQualityName(bench.TradeQuality, qualityName, sizeof(qualityName));
	bench.Cost = bench.CustomItemCost > 1 ? bench.CustomItemCost : bench.IsComposter ? 2 : 1;
	bench.Reward = bench.CustomItemReward > 1 ? bench.CustomItemReward : 1;
	
	if (bench.IsComposter)
	{
		FormatEx(text, sizeof(text), "Call for Medic\nTo trade for %i Collector's quality item!\n(Requires %i %s %s)", bench.Reward,
			bench.Cost, qualityName, bench.Cost > 1 ? "items" : "item");
	}
	else
	{
		FormatEx(text, sizeof(text), "Call for Medic\nTo trade for %i %s!\n(Requires %i %s %s)", bench.Reward,
			g_szItemName[bench.Item], bench.Cost, qualityName, bench.Cost > 1 ? "items" : "item");
	}
	
	bench.SetWorldText(text);
	bench.TextZOffset = bench.IsComposter ? 115.0 : 100.0;
	char name[256];
	FormatEx(name, sizeof(name), "Workbench (%s)", g_szItemName[bench.Item]);
	bench.SetObjectName(name);
	CBaseEntity sprite = CBaseEntity(CreateEntityByName("env_sprite"));
	bench.Sprite = sprite;
	if (bench.IsComposter)
	{
		sprite.KeyValue("model", "materials/hud/backpack_01.vmt");
		sprite.KeyValueFloat("scale", 0.04);
	}
	else
	{
		sprite.KeyValue("model", g_szItemSprite[bench.Item]);
		sprite.KeyValueFloat("scale", g_flItemSpriteScale[bench.Item]);
	}
	
	sprite.KeyValueInt("rendermode", 9);
	float pos[3];
	bench.GetAbsOrigin(pos);
	pos[2] += bench.MapPlaced ? 60.0 : 35.0;
	sprite.Teleport(pos);
	sprite.Spawn();
	int color[4] = {255, 255, 255, 255};
	if (bench.IsComposter)
	{
		color = {255, 100, 100, 255};
	}
	else
	{
		switch (GetItemQuality(bench.Item))
		{
			case Quality_Genuine:		color = {125, 255, 125, 255};
			case Quality_Unusual: 		color = {200, 125, 255, 255};
			case Quality_Strange:		color = {200, 150, 0, 255};
			case Quality_Collectors:	color = {255, 100, 100, 255};
			case Quality_Haunted, 
				Quality_HauntedStrange:	color = {125, 255, 255, 255};
		}
	}
	
	sprite.SetRenderColor(color[0], color[1], color[2], color[3]);
	bench.SetGlowColor(color[0], color[1], color[2], color[3]);
}

static void OnRemove(RF2_Object_Workbench bench)
{
	if (bench.Sprite.IsValid())
	{
		RemoveEntity(bench.Sprite.index);
	}
}

static Action Workbench_OnInteract(int client, RF2_Object_Workbench bench)
{
	return bench.DoTrade(client);
}
