#pragma semicolon 1
#pragma newdecls required

#define MODEL_SCRAPPER "models/props_trainyard/blast_furnace_skybox002.mdl"
static CEntityFactory g_Factory;

methodmap RF2_Object_Scrapper < RF2_Object_Base
{
	public RF2_Object_Scrapper(int entity)
	{
		return view_as<RF2_Object_Scrapper>(entity);
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
		g_Factory = new CEntityFactory("rf2_object_scrapper", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Object_Base.GetFactory());
		g_Factory.Install();
		HookMapStart(Scrapper_OnMapStart);
	}
	
	public static void ShowScrapMenu(int client, bool message=true)
	{
		Menu menu = new Menu(Menu_ItemScrapper);
		menu.SetTitle("What would you like to scrap?");
		int count, item;
		char info[8], display[128];
		bool collector;
		TFClassType class = TF2_GetPlayerClass(client);
		ArrayList itemList = GetSortedItemList(true, false);
		for (int i = 0; i < itemList.Length; i++)
		{
			item = itemList.Get(i);
			if (!PlayerHasItem(client, item, true) || GetItemQuality(item) == Quality_Community || GetItemQuality(item) == Quality_Strange)
				continue;	
			
			if (!collector && GetItemQuality(item) == Quality_Collectors && GetCollectorItemClass(item) != class)
			{
				FormatEx(display, sizeof(display), "%T", "ScrapCollectors", client);
				menu.InsertItem(0, "scrap_collectors", display);
				collector = true;
			}
			
			IntToString(item, info, sizeof(info));
			if (IsEquipmentItem(item))
			{
				display = g_szItemName[item];
			}
			else
			{
				FormatEx(display, sizeof(display), "%s[%i]", g_szItemName[item], GetPlayerItemCount(client, item, true));
			}
			
			menu.AddItem(info, display);
			count++;
		}

		delete itemList;
		if (count > 0)
		{
			menu.DisplayAt(client, g_iPlayerLastScrapMenuItem[client], 12);
		}
		else if (message)
		{
			EmitSoundToClient(client, SND_NOPE);
			PrintCenterText(client, "%t", "NothingToScrap");
		}
	}
}

void Scrapper_OnMapStart()
{
	PrecacheModel2(MODEL_SCRAPPER, true);
}

static void OnCreate(RF2_Object_Scrapper scrapper)
{
	scrapper.DisallowNonSurvivorMinions = true;
	scrapper.SetModel(MODEL_SCRAPPER);
	scrapper.HookInteract(Scrapper_OnInteract);
	scrapper.TextZOffset = 35.0;
	scrapper.SetWorldText("Call for Medic to scrap your items!");
	scrapper.SetObjectName("Scrapper");
}

static Action Scrapper_OnInteract(int client, RF2_Object_Scrapper scrapper)
{
	RF2_Object_Scrapper.ShowScrapMenu(client);
	return Plugin_Handled;
}

public int Menu_ItemScrapper(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			g_iPlayerLastScrapMenuItem[param1] = GetMenuSelectionPosition();
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			int item = StringToInt(info);
			if (strcmp2(info, "scrap_collectors"))
			{
				int total, count;
				TFClassType class = TF2_GetPlayerClass(param1);
				for (int i = 1; i < GetTotalItems(); i++)
				{
					if (GetItemQuality(i) != Quality_Collectors || !PlayerHasItem(param1, i))
						continue;
					
					if (GetCollectorItemClass(i) == class)
						continue;
					
					count = GetPlayerItemCount(param1, i, true);
					GiveItem(param1, i, -count);
					total += count;
				}
				
				if (total <= 0)
				{
					EmitSoundToClient(param1, SND_NOPE);
					PrintCenterText(param1, "%t", "NoCollectorItems");
					return 0;
				}
				
				ArrayList itemList = new ArrayList();
				int randomItem;
				int itemCount[MAX_ITEMS];
				
				for (int i = 1; i <= total; i++)
				{
					randomItem = GetRandomCollectorItem(class);
					GiveItem(param1, randomItem, _, true);
					itemCount[randomItem]++;
					
					if (itemList.FindValue(randomItem) == -1)
					{
						itemList.Push(randomItem);
					}
				}
				
				char itemName[64];
				for (int i = 0; i < itemList.Length; i++)
				{
					randomItem = itemList.Get(i);
					GetItemName(randomItem, itemName, sizeof(itemName));
					RF2_PrintToChat(param1, "%t", "ReceivedCollectorItem", itemCount[randomItem], itemName);
				}
				
				EmitSoundToClient(param1, SND_USE_SCRAPPER);
				RF2_Object_Scrapper.ShowScrapMenu(param1, false);
				delete itemList;
			}
			else if (item != Item_Null && PlayerHasItem(param1, item, true) && GetItemQuality(item) != Quality_Strange)
			{
				if (IsEquipmentItem(item))
				{
					g_iPlayerEquipmentItem[param1] = Item_Null;
				}
				else
				{
					GiveItem(param1, item, -1);
				}
				
				int quality = GetItemQuality(item);
				int scrap;
				
				switch (quality)
				{
					case Quality_Normal: scrap = Item_ScrapMetal;
					case Quality_Genuine: scrap = Item_ReclaimedMetal;
					case Quality_Unusual: scrap = Item_RefinedMetal;
				}
				
				if (quality == Quality_Collectors)
				{
					GiveItem(param1, Item_ScrapMetal, 1, true);
					GiveItem(param1, Item_ReclaimedMetal, 1, true);
					PrintCenterText(param1, "%t", "UsedScrapperCollectors", g_szItemName[item], g_szItemName[Item_ScrapMetal], g_szItemName[Item_ReclaimedMetal]);
				}
				else if (scrap > Item_Null)
				{
					GiveItem(param1, scrap, 1, true);
					PrintCenterText(param1, "%t", "UsedScrapper", g_szItemName[item], g_szItemName[scrap]);
				}
				else if (IsHauntedItem(item)) // haunted item, give haunted key
				{
					GiveItem(param1, Item_HauntedKey, 1, true);
					PrintCenterText(param1, "%t", "UsedScrapperHaunted", g_szItemName[item]);
				}
				
				EmitSoundToClient(param1, SND_USE_SCRAPPER);
				RF2_Object_Scrapper.ShowScrapMenu(param1, false);
			}
		}
		case MenuAction_Cancel:
		{
			g_iPlayerLastScrapMenuItem[param1] = 0;
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}