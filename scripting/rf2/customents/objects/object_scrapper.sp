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
		if (this.index == 0 || !IsValidEntity2(this.index))
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
		int count;
		char info[8], display[128];
		bool collector;
		for (int i = 1; i <= GetTotalItems(); i++)
		{
			if (IsScrapItem(i) || IsEquipmentItem(i) || !PlayerHasItem(client, i, true) || GetItemQuality(i) == Quality_Community)
				continue;
			
			if (GetItemQuality(i) == Quality_Collectors)
			{
				if (IsPlayerMinion(client) || GetCollectorItemClass(i) == TF2_GetPlayerClass(client))
				{
					continue;
				}
				else if (!collector)
				{
					FormatEx(display, sizeof(display), "%T", "ScrapCollectors", client);
					menu.InsertItem(0, "scrap_collectors", display);
					collector = true;
				}
			}
			
			IntToString(i, info, sizeof(info));
			FormatEx(display, sizeof(display), "%s[%i]", g_szItemName[i], GetPlayerItemCount(client, i, true));
			menu.AddItem(info, display);
			count++;
		}
		
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
			bool scrapAllCollectors = strcmp2(info, "scrap_collectors");
			
			if (scrapAllCollectors || item != Item_Null && PlayerHasItem(param1, item, true))
			{
				TFClassType class = TF2_GetPlayerClass(param1);
				if (scrapAllCollectors || GetItemQuality(item) == Quality_Collectors && GetCollectorItemClass(item) != class)
				{
					if (scrapAllCollectors)
					{
						int total, count;
						for (int i = 1; i <= GetTotalItems(); i++)
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
					else
					{
						GiveItem(param1, item, -1);
						int randomItem = GetRandomCollectorItem(TF2_GetPlayerClass(param1));
						GiveItem(param1, randomItem, _, true);
						PrintCenterText(param1, "%t", "UsedScrapper", g_szItemName[item], g_szItemName[randomItem]);
						EmitSoundToClient(param1, SND_USE_SCRAPPER);
						RF2_Object_Scrapper.ShowScrapMenu(param1, false);
					}
				}
				else if (GetItemQuality(item) != Quality_Collectors)
				{
					GiveItem(param1, item, -1);
					int quality = GetItemQuality(item);
					int scrap;
					
					switch (quality)
					{
						case Quality_Normal: scrap = Item_ScrapMetal;
						case Quality_Genuine: scrap = Item_ReclaimedMetal;
						case Quality_Unusual: scrap = Item_RefinedMetal;
					}
					
					if (scrap > Item_Null)
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