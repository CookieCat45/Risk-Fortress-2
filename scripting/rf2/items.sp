#pragma semicolon 1
#pragma newdecls required

#define MAX_UNUSUAL_EFFECTS 64

int g_iItemCount;
int g_iBeamModel;

int g_iPlayerItem[MAXPLAYERS][MAX_ITEMS];
int g_iPlayerEquipmentItem[MAXPLAYERS];
int g_iItemSchemaIndex[MAX_ITEMS] = {-1, ...};
int g_iItemQuality[MAX_ITEMS] = {Quality_None, ...};
int g_iCollectorItemClass[MAX_ITEMS];

float g_flItemModifier[MAX_ITEMS][MAX_ITEM_MODIFIERS];
float g_flEquipmentItemCooldown[MAX_ITEMS] = {40.0, ...};
float g_flEquipmentItemMinCooldown[MAX_ITEMS];
float g_flItemSpriteScale[MAX_ITEMS] = {1.0, ...};
float g_flItemProcCoeff[MAX_ITEMS] = {1.0, ...};

char g_szItemSectionName[MAX_ITEMS][64];
char g_szCustomItemFileName[MAX_ITEMS][PLATFORM_MAX_PATH];
char g_szItemName[MAX_ITEMS][64];
char g_szItemDesc[MAX_ITEMS][512];
char g_szItemUnusualEffectName[MAX_ITEMS][64];

bool g_bItemInDropPool[MAX_ITEMS];
bool g_bItemCanBeDropped[MAX_ITEMS] = {true, ...};
bool g_bItemForceShowInInventory[MAX_ITEMS];
bool g_bItemMultiplayerOnly[MAX_ITEMS];
bool g_bItemExcludeFromLog[MAX_ITEMS];
bool g_bItemScavengerNoSpawnWith[MAX_ITEMS];
bool g_bItemScavengerNoPickup[MAX_ITEMS];
bool g_bLaserHitDetected[MAX_EDICTS];

// Unusual effects
int g_iUnusualEffectCount;
int g_iItemUnusualEffect[MAX_ITEMS] = {-1, ...};
int g_iItemSpriteUnusualEffect[MAX_ITEMS] = {-1, ...};
int g_iUnusualEffectType[MAX_UNUSUAL_EFFECTS]; // Unusual effects have IDs for use with the attribute

char g_szUnusualEffectName[MAX_UNUSUAL_EFFECTS][64];
char g_szUnusualEffectDisplayName[MAX_UNUSUAL_EFFECTS][64];
char g_szItemEquipRegion[MAX_ITEMS][64];
char g_szItemSprite[MAX_ITEMS][PLATFORM_MAX_PATH];

int LoadItems(const char[] customPath="")
{
	char config[PLATFORM_MAX_PATH], buffer[64], file[PLATFORM_MAX_PATH];
	bool custom = asBool(customPath[0]);
	int count;
	if (custom)
	{
		strcopy(config, sizeof(config), customPath);
		// remove the file path, we just want the name of the file here
		file = config;
		char temp[PLATFORM_MAX_PATH];
		SplitString(file, "custom_items\\", temp, sizeof(temp));
		StrCat(temp, sizeof(temp), "custom_items\\");
		ReplaceStringEx(file, sizeof(file), temp, "");
		ReplaceString(file, sizeof(file), "/", "");
		ReplaceString(file, sizeof(file), "\\", "");
	}
	else
	{
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, ItemConfig);
	}
	
	// Do our unusual effects first so we have them when we load the items
	if (!custom)
	{
		KeyValues effectKey = CreateKeyValues("");
		if (!effectKey.ImportFromFile(config))
		{
			delete effectKey;
			ThrowError("File %s does not exist", config);
		}

		g_iUnusualEffectCount = 0;
		effectKey.GetSectionName(buffer, sizeof(buffer));
		if (strcmp2(buffer, "items"))
		{
			effectKey.GotoNextKey();
		}
		
		char split[16];
		for (int i = 0; i < MAX_UNUSUAL_EFFECTS; i++)
		{
			if (i == 0 && effectKey.GotoFirstSubKey(false) || effectKey.GotoNextKey(false))
			{
				effectKey.GetSectionName(g_szUnusualEffectDisplayName[i], sizeof(g_szUnusualEffectDisplayName[]));
				effectKey.GetString(NULL_STRING, buffer, sizeof(buffer));
				ReplaceString(buffer, sizeof(buffer), " ", ""); // remove whitespace
				SplitString(buffer, ";", split, sizeof(split));
				ReplaceStringEx(buffer, sizeof(buffer), split, "");
				ReplaceStringEx(buffer, sizeof(buffer), ";", "");
				g_iUnusualEffectType[i] = StringToInt(split);
				strcopy(g_szUnusualEffectName[i], sizeof(g_szUnusualEffectName[]), buffer);
				g_iUnusualEffectCount++;
			}
		}
		
		delete effectKey;
	}
	
	if (!custom)
		g_iItemCount = 0;

	int item;
	KeyValues itemKey = CreateKeyValues("");
	if (!itemKey.ImportFromFile(config))
	{
		delete itemKey;
		ThrowError("File %s does not exist", config);
	}
	
	itemKey.GetSectionName(buffer, sizeof(buffer));
	bool error;
	// don't assume the position of the effects tree
	if (!custom && strcmp2(buffer, "effects", false))
	{
		error = !itemKey.GotoNextKey();
	}
	else
	{
		error = !strcmp2(buffer, "items", false);
	}
	
	if (error)
	{
		delete itemKey;
		ThrowError("Keyvalues section \"items\" does not exist in %s", config);
	}
	
	for (int i = 0; i < MAX_ITEMS; i++)
	{
		if (i == 0 && itemKey.GotoFirstSubKey() || itemKey.GotoNextKey())
		{
			// This value will correspond to the item's index in the plugin so we know what the item does.
			if (!custom)
			{
				item = itemKey.GetNum("item_type", Item_Null);
			}
			else
			{
				item = g_iItemCount; // use the next available slot for subplugin items
				strcopy(g_szCustomItemFileName[item], sizeof(g_szCustomItemFileName[]), file);
			}
			
			itemKey.GetSectionName(g_szItemSectionName[item], sizeof(g_szItemSectionName[]));
			itemKey.GetString("name", g_szItemName[item], sizeof(g_szItemName[]), "Unnamed Item");
			itemKey.GetString("desc", g_szItemDesc[item], sizeof(g_szItemDesc[]), "(No description found...)");
			CRemoveTags(g_szItemDesc[item], sizeof(g_szItemDesc[]));
			char dummy[1];
			dummy[0] = 10;
			ReplaceString(g_szItemDesc[item], sizeof(g_szItemDesc[]), "\\n", dummy, false);
			itemKey.GetString("equip_regions", g_szItemEquipRegion[item], sizeof(g_szItemEquipRegion[]), "none");
			itemKey.GetString("sprite", g_szItemSprite[item], sizeof(g_szItemSprite[]), MAT_DEBUGEMPTY);
			g_bItemInDropPool[item] = asBool(itemKey.GetNum("in_item_pool", true));
			g_bItemCanBeDropped[item] = asBool(itemKey.GetNum("can_be_dropped", true));
			g_bItemForceShowInInventory[item] = asBool(itemKey.GetNum("force_show_inv", false));
			g_bItemMultiplayerOnly[item] = asBool(itemKey.GetNum("multiplayer_only", false));
			g_bItemExcludeFromLog[item] = asBool(itemKey.GetNum("exclude_from_log", false));
			g_bItemScavengerNoSpawnWith[item] = asBool(itemKey.GetNum("scavenger_no_spawn_with", false));
			g_bItemScavengerNoPickup[item] = asBool(itemKey.GetNum("scavenger_no_pickup", false));
			if (item == ItemScout_LongFallBoots && !IsGoombaAvailable())
			{
				// this item requires the goomba stomp plugin to function
				g_bItemInDropPool[item] = false;
			}
			
			if (FileExists(g_szItemSprite[item], true))
			{
				AddMaterialToDownloadsTable(g_szItemSprite[item]);
			}
			else
			{
				LogError("[LoadItems] Bad item sprite for item %i (%s: %s)", item, g_szItemSectionName[item], g_szItemSprite[item]);
			}
			
			for (int n = 0; n < MAX_ITEM_MODIFIERS; n++)
			{
				FormatEx(buffer, sizeof(buffer), "item_modifier_%i", n);
				g_flItemModifier[item][n] = itemKey.GetFloat(buffer, 0.1);
			}
			
			g_flItemProcCoeff[item] = itemKey.GetFloat("proc_coeff", 1.0);
			g_iItemSchemaIndex[item] = itemKey.GetNum("schema_index", -1);
			g_flItemSpriteScale[item] = itemKey.GetFloat("sprite_scale", 0.5);
			g_iItemQuality[item] = itemKey.GetNum("quality", Quality_Normal);
			switch (g_iItemQuality[item])
			{
				case Quality_Unusual:
				{
					if (item != Item_RefinedMetal && g_iUnusualEffectCount > 0)
					{
						int random = GetRandomInt(0, g_iUnusualEffectCount-1);
						g_iItemUnusualEffect[item] = g_iUnusualEffectType[random];
						g_iItemSpriteUnusualEffect[item] = random;
						strcopy(g_szItemUnusualEffectName[item], sizeof(g_szItemUnusualEffectName[]), g_szUnusualEffectDisplayName[random]);
					}
				}
				
				case Quality_Collectors: g_iCollectorItemClass[item] = itemKey.GetNum("collector_item_class", 0);
				case Quality_Strange, Quality_HauntedStrange: 
				{
					g_flEquipmentItemCooldown[item] = itemKey.GetFloat("strange_cooldown", 40.0);
					g_flEquipmentItemMinCooldown[item] = itemKey.GetFloat("strange_cooldown_min", 0.0);
				}
				
				case Quality_Community: // Should never ever be in the item pool
				{
					g_bItemInDropPool[item] = false;
				}
			}
			
			g_iItemCount++;
			count++;
			if (custom)
			{
				// let any subplugins know that a custom item has been loaded
				Call_StartForward(g_fwOnCustomItemLoaded);
				Call_PushString(file);
				Call_PushString(g_szItemSectionName[item]);
				Call_PushCell(item);
				Call_PushCell(itemKey);
				Call_Finish();
			}
		}
		else
		{
			break;
		}
	}
	
	if (!custom)
	{
		// we just finished loading the base items, now load custom items from subplugins
		LoadCustomItems();
	}
	
	CheckForDuplicateSectionNames();
	delete itemKey;
	return count;
}

void LoadCustomItems()
{
	int count;
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "%s/%s", ConfigPath, "custom_items/");
	DirectoryListing dir = OpenDirectory(path);
	if (!dir)
	{
		LogError("The %s directory was not found. Custom items will not be loaded.", path);
	}
	else
	{
		FileType type;
		char file[PLATFORM_MAX_PATH], buffer[PLATFORM_MAX_PATH];
		while (dir.GetNext(file, sizeof(file), type))
		{
			if (type != FileType_File || strcmp2(file, "dummy.cfg"))
				continue;

			FormatEx(buffer, sizeof(buffer), "%s/%s", path, file);
			LogMessage("Loading custom items file: %s", file);
			count += LoadItems(buffer);
		}

		delete dir;
	}
	
	PrintToServer("[RF2] Items loaded: %i (%i custom)", g_iItemCount, count);
}

void CheckForDuplicateSectionNames()
{
	ArrayList list = new ArrayList(64);
	for (int i = 0; i < GetTotalItems(); i++)
	{
		if (list.FindString(g_szItemSectionName[i]) != -1)
		{
			LogError("[WARNING] Found duplicate item section name: '%s' for item %i. Change it or it will cause issues.", g_szItemSectionName[i], i);
		}
		
		list.PushString(g_szItemSectionName[i]);
	}
	
	delete list;
}

bool CheckEquipRegionConflict(const char[] buffer1, const char[] buffer2)
{
	if (strcmp2(buffer1, "none") || strcmp2(buffer2, "none"))
		return false;
	
	char tempBuffer[128], explodeBuffers[3][256];
	FormatEx(tempBuffer, sizeof(tempBuffer), "%s ; none ; ", buffer1);
	int count = ExplodeString(tempBuffer, " ; ", explodeBuffers, 3, 256);
	for (int i = 0; i < count; i++)
	{
		if (StrContainsEx(explodeBuffers[i], buffer2) != -1)
			return true;
	}
	
	return false;
}

int GetRandomItem(int normalWeight=0, int genuineWeight=0, 
	int unusualWeight=0, int hauntedWeight=0, int strangeWeight=0, bool allowHauntedStrange=true)
{
	ArrayList array = new ArrayList();
	int quality, count, item;

	for (int i = 0; i < Quality_MaxValid; i++)
	{
		if (i == Quality_Collectors || i == Quality_HauntedStrange)
			continue;
		
		switch (i)
		{
			case Quality_Normal: count = normalWeight;
			case Quality_Genuine: count = genuineWeight;
			case Quality_Unusual: count = unusualWeight;
			case Quality_Haunted: count = hauntedWeight;
			case Quality_Strange: count = strangeWeight;
		}
		
		if (count <= 0)
			continue;
		
		for (int j = 1; j <= count; j++)
			array.Push(i);
	}
	
	quality = array.Get(GetRandomInt(0, array.Length-1));
	array.Clear();
	for (int i = 1; i < GetTotalItems(); i++)
	{
		if (!g_bItemInDropPool[i] || GetItemQuality(i) == Quality_Collectors)
			continue;
		
		if (g_bItemMultiplayerOnly[i] && IsSingleplayer(false))
			continue;

		if (GetItemQuality(i) == quality 
			|| quality == Quality_Haunted && allowHauntedStrange && GetItemQuality(i) == Quality_HauntedStrange)
		{
			array.Push(i);
		}
	}
	
	if (array.Length > 0)
	{
		item = array.Get(GetRandomInt(0, array.Length-1));
	}
	else if (quality != Quality_Normal)
	{
		// No items found. Try Normal items.
		delete array;
		return GetRandomItemEx(Quality_Normal);
	}
	
	delete array;
	return item;
}

int GetRandomItemEx(int quality)
{	
	ArrayList array = new ArrayList();
	int item;
	for (int i = 1; i < GetTotalItems(); i++)
	{
		if (!g_bItemInDropPool[i])
			continue;
		
		if (g_bItemMultiplayerOnly[i] && IsSingleplayer(false))
			continue;

		if (g_iItemQuality[i] == quality)
			array.Push(i);
	}
	
	if (array.Length > 0)
	{
		item = array.Get(GetRandomInt(0, array.Length-1));
	}
	else if (quality != Quality_Normal)
	{
		// No items found. Try Normal items.
		delete array;
		return GetRandomItemEx(Quality_Normal);
	}
	
	delete array;
	return item;
}

int GetRandomCollectorItem(TFClassType class)
{
	ArrayList array = new ArrayList();
	int item;
	for (int i = 0; i < GetTotalItems(); i++)
	{
		if (!g_bItemInDropPool[i])
			continue;

		if (g_iItemQuality[i] == Quality_Collectors && GetCollectorItemClass(i) == class)
		{
			array.Push(i);
		}
	}
	
	if (array.Length > 0)
	{
		item = array.Get(GetRandomInt(0, array.Length-1));
	}
	else
	{
		// No items found. Try Genuine items.
		delete array;
		return GetRandomItemEx(Quality_Genuine);
	}
	
	delete array;
	return item;
}

TFClassType GetCollectorItemClass(int item)
{
	return view_as<TFClassType>(g_iCollectorItemClass[item]);
}

bool CanUseCollectorItem(int client, int item)
{
	return TF2_GetPlayerClass(client) == GetCollectorItemClass(item);
}

// negative values are accepted for amount
void GiveItem(int client, int type, int amount=1, bool addToLogbook=false)
{
	if (IsEquipmentItem(type))
	{
		if (amount < 0)
		{
			if (g_iPlayerEquipmentItem[client] == type)
				g_iPlayerEquipmentItem[client] = Item_Null;
		}
		else
		{
			int strangeItem = GetPlayerEquipmentItem(client);
			if (strangeItem > Item_Null && IsPlayerSurvivor(client))
			{
				float pos[3];
				GetEntPos(client, pos);
				pos[2] += 30.0;
				DropItem(client, strangeItem, pos, _, 6.0);
			}
			
			g_iPlayerEquipmentItem[client] = type;
		}
	}
	else
	{
		g_iPlayerItem[client][type] += amount;
		if (GetPlayerItemCount(client, type, true, true) < 0)
		{
			g_iPlayerItem[client][type] = 0;
		}
	}
	
	if (addToLogbook)
	{
		AddItemToLogbook(client, type);	
	}
	
	UpdatePlayerItem(client, type);
}

int EquipItemAsWearable(int client, int item)
{
	if (GetCookieBool(client, g_coDisableItemCosmetics))
		return INVALID_ENT;
	
	if (GetItemQuality(item) == Quality_Collectors && !CanUseCollectorItem(client, item))
		return INVALID_ENT;
	
	if (GetPlayerWearableCount(client, true) >= MAX_ITEMS && GetItemQuality(item) != Quality_Strange)
		return INVALID_ENT;
	
	if (HasItemAsWearable(client, item))
		return INVALID_ENT;
	
	int wearable = INVALID_ENT;
	int entity = MaxClients+1;
	int index;
	bool valid = true;
	bool breakLoop;
	
	while ((entity = FindEntityByClassname(entity, "tf_wearable")) != -1)
	{
		if (!g_bItemWearable[entity] || GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != client)
			continue;
		
		index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		
		for (int i = 1; i < GetTotalItems(); i++)
		{
			if (PlayerHasItem(client, i) && index == g_iItemSchemaIndex[i])
			{
				if (CheckEquipRegionConflict(g_szItemEquipRegion[item], g_szItemEquipRegion[i]))
				{
					if (GetQualityEquipPriority(g_iItemQuality[item]) >= GetQualityEquipPriority(g_iItemQuality[i]))
					{
						TF2_RemoveWearable(client, entity);
						valid = true;
						breakLoop = true;
						break;
					}
					else
					{
						valid = false;
					}
				}
			}
		}
		
		if (breakLoop)
		{
			break;
		}
	}
	
	if (valid)
	{
		int actualQuality = GetActualItemQuality(g_iItemQuality[item]);
		char attribute[16];
		if (GetItemQuality(item) == Quality_Unusual)
		{
			FormatEx(attribute, sizeof(attribute), "134 = %i", g_iItemUnusualEffect[item]);
		}
		
		wearable = CreateWearable(client, "tf_wearable", g_iItemSchemaIndex[item], attribute, true, true, "", actualQuality, GetRandomInt(1, 128));
		g_bItemWearable[wearable] = true;
		
		// Enemy item wearables have the flashing effect, so RED players can more easily tell what they have.
		if (GetClientTeam(client) == TEAM_ENEMY)
		{
			SetEntProp(wearable, Prop_Send, "m_fEffects", EF_ITEM_BLINK);
			SDK_EquipWearable(client, wearable); // need to equip a 2nd time if we do this to prevent weird attachment issues
		}
		
		if (IsRollermine(client))
		{
			SetEntityRenderMode(wearable, RENDER_NONE);
		}
		
		SetEntProp(wearable, Prop_Send, "m_bValidatedAttachedEntity", true);
		if (!IsPlayerMinion(client))
		{
			entity = MaxClients+1;
			while ((entity = FindEntityByClassname(entity, "tf_wearable")) != -1)
			{
				// Remove one loadout wearable (don't remove zombie ones cause it causes funky stuff to happen)
				if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client 
					&& !g_bDontRemoveWearable[entity] && !g_bItemWearable[entity]
					&& !IsVoodooCursedCosmetic(entity)
					&& !IsWeaponWearable(entity))
				{
					TF2_RemoveWearable(client, entity);
					break;
				}
			}
		}
	}
	
	return wearable;
}

bool HasItemAsWearable(int client, int item)
{
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "tf_wearable")) != -1)
	{
		if (!g_bItemWearable[entity] || GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != client)
			continue;
	
		if (GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == g_iItemSchemaIndex[item])
			return true;
	}
	
	return false;
}

void RemoveItemAsWearable(int client, int item)
{
	int entity = MaxClients+1;
	int index;
	while ((entity = FindEntityByClassname(entity, "tf_wearable")) != -1)
	{
		if (!g_bItemWearable[entity] || g_bDontRemoveWearable[entity] || GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != client)
			continue;
		
		index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		
		// g_bDontRemoveWearable means this wearable is associated with an item
		if (index == g_iItemSchemaIndex[item])
		{
			// TODO: This causes issues with cosmetics that toggle bodygroups. Not sure how to fix. Taunting corrects it for some reason??
			TF2_RemoveWearable(client, entity);
			break;
		}
	}
}

int GetQualityEquipPriority(int quality)
{
	switch (quality)
	{
		case Quality_Normal: return 0;
		case Quality_Genuine: return 1;
		case Quality_Collectors: return 2;
		case Quality_Haunted: return 3;
		case Quality_Unusual: return 4;
		case Quality_Strange, Quality_HauntedStrange: return 5;
		case Quality_Community: return 6;
	}
	
	return -1;
}

void UpdatePlayerItem(int client, int item, bool updateStats=true)
{
	Call_StartForward(g_fwOnPlayerItemUpdate);
	Call_PushCell(client);
	Call_PushCell(item);
	Call_Finish();
	switch (item)
	{
		case Item_MaxHead, Item_MaimLicense, Item_RoundedRifleman:
		{
			if (updateStats)
			{
				UpdatePlayerFireRate(client);
			}
			
			if (item == Item_MaxHead)
			{
				float value = CalcItemMod(client, Item_MaxHead, 0);
				int primary = GetPlayerWeaponSlot(client, 0);
				int secondary = GetPlayerWeaponSlot(client, 1);
				if (primary != INVALID_ENT)
				{
					if (PlayerHasItem(client, item))
					{
						TF2Attrib_SetByName(primary, "projectile penetration", value);
					}
				}
				
				if (secondary != INVALID_ENT)
				{
					if (PlayerHasItem(client, item))
					{
						TF2Attrib_SetByName(secondary, "projectile penetration", value);
					}
				}
			}
			
		}
		case Item_PrideScarf, Item_ClassCrown:
		{
			if (updateStats)
			{
				CalculatePlayerMaxHealth(client);
			}
		}
		case Item_WhaleBoneCharm:
		{
			float amount = 1.0 + CalcItemMod(client, Item_WhaleBoneCharm, 0);
			int weapon, ammoType;
			
			// Special case for certain effect bar items e.g. Jarate, Sandman, Wrap Assassin
			TF2Attrib_SetByName(client, "maxammo grenades1 increased", 1.0+float(GetPlayerItemCount(client, item)/2));
			TF2Attrib_SetByName(client, "maxammo secondary increased", 1.0+float(GetPlayerItemCount(client, item)/2));
			int max1 = TF2Attrib_HookValueInt(1, "mult_maxammo_grenades1", client);
			
			// hardcoding to 36 because this really only matters for scout
			int max2 = TF2Attrib_HookValueInt(36, "mult_maxammo_secondary", client);
			
			for (int i = WeaponSlot_Primary; i <= WeaponSlot_InvisWatch; i++)
			{
				weapon = GetPlayerWeaponSlot(client, i);
				if (weapon == INVALID_ENT)
					continue;
				
				// heatmaker utilizes clip size for charge rate cap
				bool heatmaker = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 752;
				ammoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType"); // we may not need to waste an attribute slot here
				if (heatmaker || ammoType != TFAmmoType_None && ammoType < TFAmmoType_Metal && GetWeaponClipSize(weapon) > 0)
				{
					if (IsEnergyWeapon(weapon))
					{
						if (PlayerHasItem(client, Item_WhaleBoneCharm))
						{
							TF2Attrib_SetByName(weapon, "clip size bonus upgrade", amount);
						}
						else
						{
							TF2Attrib_RemoveByName(weapon, "clip size bonus upgrade");
						}
					}
					else
					{
						if (PlayerHasItem(client, Item_WhaleBoneCharm))
						{
							TF2Attrib_SetByName(weapon, "clip size penalty HIDDEN", amount);
						}
						else
						{
							TF2Attrib_RemoveByName(weapon, "clip size penalty HIDDEN");
						}
					}
				}
				
				if ((ammoType == TFAmmoType_Secondary || ammoType == TFAmmoType_Jarate) && IsEffectBarWeapon(weapon))
				{
					int ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType);
					int max = ammoType == TFAmmoType_Jarate ? max1 : max2;
					if (ammo < max && GetEntPropFloat(weapon, Prop_Send, "m_flEffectBarRegenTime") <= GetGameTime())
					{
						GivePlayerAmmo(client, max-ammo, ammoType, true);
					}
				}
			}
		}
		case Item_RobinWalkers, Item_TripleA, Item_DarkHelm:
		{
			if (updateStats)
			{
				CalculatePlayerMaxSpeed(client);
				if (item == Item_DarkHelm)
				{
					CalculatePlayerMaxHealth(client);
				}

				if (item == Item_TripleA)
				{
					UpdatePlayerFireRate(client);
				}
			}
		}
		case Item_HorrificHeadsplitter:
		{
			if (!PlayerHasItem(client, Item_HorrificHeadsplitter))
			{
				TF2_RemoveCondition(client, TFCond_Bleeding);
			}
		}
		case Item_Tux:
		{
			if (PlayerHasItem(client, Item_Tux))
			{
				float jumpHeightAmount = 1.0 + CalcItemMod(client, Item_Tux, 0);
				float airControlAmount = 1.0 + CalcItemMod(client, Item_Tux, 1);
				TF2Attrib_SetByName(client, "increased jump height", jumpHeightAmount);
				TF2Attrib_SetByName(client, "increased air control", airControlAmount);
			}
		}
		case Item_MisfortuneFedora:
		{
			if (PlayerHasItem(client, Item_MisfortuneFedora))
			{
				TF2_AddCondition(client, TFCond_Buffed);
			}
			else
			{
				TF2_RemoveCondition(client, TFCond_Buffed);
			}

			if (updateStats)
			{
				CalculatePlayerMaxHealth(client);
			}
		}
		case Item_UFO:
		{
			UpdatePlayerGravity(client);
			if (PlayerHasItem(client, Item_UFO))
			{
				float pushForce = 1.0 + CalcItemMod_Hyperbolic(client, Item_UFO, 1);
				TF2Attrib_SetByName(client, "airblast vulnerability multiplier", pushForce);
				TF2Attrib_SetByName(client, "damage force increase", pushForce);
			}
		}
		case ItemEngi_Teddy:
		{
			if (CanUseCollectorItem(client, ItemEngi_Teddy))
			{
				int wrench = GetPlayerWeaponSlot(client, WeaponSlot_Melee);
				if (wrench != INVALID_ENT)
				{
					if (PlayerHasItem(client, ItemEngi_Teddy))
					{
						float maxMetal = 1.0 + CalcItemMod(client, item, 0);
						float constructRate = 1.0 + CalcItemMod(client, item, 1);
						TF2Attrib_SetByName(wrench, "maxammo metal increased", maxMetal);
						TF2Attrib_SetByName(wrench, "Construction rate increased", constructRate);
					}
				}
			}
		}
		case ItemMedic_BlightedBeak, ItemMedic_ProcedureMask:
		{
			int medigun = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
			if (medigun != INVALID_ENT)
			{
				if (item == ItemMedic_BlightedBeak && PlayerHasItem(client, item) && CanUseCollectorItem(client, item))
				{
					float uberRate = 1.0 + CalcItemMod(client, item, 0);
					float uberDuration = CalcItemMod(client, item, 1);
					TF2Attrib_SetByName(medigun, "ubercharge rate bonus", uberRate);
					TF2Attrib_SetByName(medigun, "uber duration bonus", uberDuration);
				}
				else if (item == ItemMedic_ProcedureMask && PlayerHasItem(client, item) && CanUseCollectorItem(client, item))
				{
					float healRateBonus = 1.0 + CalcItemMod(client, item, 0);
					float overhealBonus = 1.0 + CalcItemMod(client, item, 1);
					TF2Attrib_SetByName(medigun, "healing mastery", healRateBonus);
					TF2Attrib_SetByName(medigun, "overheal bonus", overhealBonus);
				}
			}
		}
		case ItemHeavy_ToughGuyToque:
		{
			if (CanUseCollectorItem(client, item))
			{
				int minigun = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
				if (minigun != INVALID_ENT)
				{
					if (PlayerHasItem(client, item))
					{
						float count = CalcItemMod(client, item, 0);
						float revSpeed = CalcItemMod_Reciprocal(client, item, 1);
						TF2Attrib_SetByName(minigun, "attack projectiles", count);
						TF2Attrib_SetByName(minigun, "minigun spinup time decreased", revSpeed);
					}
				}	
			}
		}
		case ItemDemo_OldBrimstone:
		{
			if (CanUseCollectorItem(client, item))
			{
				float value = 1.0 + CalcItemMod(client, ItemDemo_OldBrimstone, 1);
				int primary = GetPlayerWeaponSlot(client, 0);
				int secondary = GetPlayerWeaponSlot(client, 1);
				if (primary != INVALID_ENT)
				{
					if (PlayerHasItem(client, item))
					{
						TF2Attrib_SetByName(primary, "blast radius increased", value);
					}
				}
				
				if (secondary != INVALID_ENT)
				{
					if (PlayerHasItem(client, item))
					{
						TF2Attrib_SetByName(secondary, "blast radius increased", value);
					}
				}
			}
		}
		case Item_BatteryCanteens:
		{
			// start cooldown if we're below max charges
			int equipment = GetPlayerEquipmentItem(client);
			if (equipment > Item_Null && g_flPlayerEquipmentItemCooldown[client] <= 0.0)
			{
				int maxCharges = CalcItemModInt(client, item, 1, 1);
				if (g_iPlayerEquipmentItemCharges[client] < maxCharges)
				{
					g_flPlayerEquipmentItemCooldown[client] = GetPlayerEquipmentItemCooldown(client);
					g_bPlayerEquipmentCooldownActive[client] = true;
					CreateTimer(0.1, Timer_EquipmentCooldown, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		case Item_Marxman:
		{
			if (PlayerHasItem(client, item))
			{
				float amount = CalcItemMod_Reciprocal(client, item, 0);
				TF2Attrib_SetByName(client, "deploy time decreased", amount);
				
				// These classes don't have weapons that benefit from accuracy bonuses, so don't bother
				TFClassType class = TF2_GetPlayerClass(client);
				if (class != TFClass_Medic && class != TFClass_DemoMan)
				{
					int primary = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
					int secondary = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
					amount = CalcItemMod_Reciprocal(client, item, 1);
					
					if (primary != INVALID_ENT)
					{
						TF2Attrib_SetByName(primary, "weapon spread bonus", amount);
					}
					
					if (secondary != INVALID_ENT)
					{
						TF2Attrib_SetByName(secondary, "weapon spread bonus", amount);
						if (GetEntProp(secondary, Prop_Send, "m_iItemDefinitionIndex") == 1179)
						{
							// Special case for the Thermal Thruster
							TF2Attrib_SetByName(secondary, "holster_anim_time", 0.8*CalcItemMod_Reciprocal(client, item, 0));
						}
					}
				}
			}
		}
		case ItemSoldier_WarPig:
		{
			if (CanUseCollectorItem(client, item))
			{
				int launcher = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
				if (launcher != INVALID_ENT)
				{
					if (PlayerHasItem(client, item))
					{
						float projSpeed = 1.0 + CalcItemMod(client, item, 0);
						int index = GetEntProp(launcher, Prop_Send, "m_iItemDefinitionIndex");
						if (index == 127) // Direct Hit
						{
							projSpeed = fmin(projSpeed, 1.5);
						}
						else if (index == 414) // Liberty Launcher
						{
							projSpeed = fmin(projSpeed, 1.9);
						}
						else
						{
							projSpeed = fmin(projSpeed, 2.7);
						}
						
						TF2Attrib_SetByName(launcher, "Projectile speed increased HIDDEN", projSpeed);
					}
				}
			}
		}
		case ItemDemo_ScotchBonnet:
		{
			if (CanUseCollectorItem(client, item))
			{
				int primary = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
				int secondary = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
				if (primary != INVALID_ENT)
				{
					if (PlayerHasItem(client, item))
					{
						float projSpeed = 1.0 + CalcItemMod(client, item, 0);
						TF2Attrib_SetByName(primary, "Projectile speed increased HIDDEN", projSpeed);
					}
				}
				
				if (secondary != INVALID_ENT)
				{
					if (PlayerHasItem(client, item))
					{
						float chargeRate = CalcItemMod_Reciprocal(client, item, 1);
						if (GetEntProp(secondary, Prop_Send, "m_iItemDefinitionIndex") == 1150)
						{
							// QuickieBomb hotfix
							chargeRate *= 0.3;
						}
						
						TF2Attrib_SetByName(secondary, "stickybomb charge rate", chargeRate);
					}
				}
			}
		}
		case ItemEngi_Toadstool:
		{
			if (CanUseCollectorItem(client, item))
			{
				if (PlayerHasItem(client, item))
				{
					TF2Attrib_SetByName(client, "engy dispenser radius increased", 1.0 + CalcItemMod(client, item, 1));
				}
			}
		}
		case ItemPyro_BrigadeHelm:
		{
			if (CanUseCollectorItem(client, item))
			{
				int primary = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
				if (primary != INVALID_ENT)
				{
					if (PlayerHasItem(client, item))
					{
						float value = GetItemMod(item, 1) * (1.0 - CalcItemMod_Reciprocal(client, item, 0));
						TF2Attrib_SetByName(primary, "flame_spread_degree", value);
						TF2Attrib_SetByName(primary, "damage bonus HIDDEN", 1.0+CalcItemMod(client, item, 2));
						TF2Attrib_SetByName(primary, "airblast pushback scale", 1.0+CalcItemMod(client, ItemPyro_BrigadeHelm, 3));
					}
				}
			}
		}
		
		case ItemSpy_StealthyScarf:
		{
			int watch = GetPlayerWeaponSlot(client, WeaponSlot_InvisWatch);
			if (watch != INVALID_ENT)
			{
				if (PlayerHasItem(client, item) && CanUseCollectorItem(client, item))
				{
					TF2Attrib_SetByName(watch, "mult decloak rate", 1.0-fmin(0.99, CalcItemMod(client, item, 1)));
				}
			}
		}
		
		case ItemSniper_VillainsVeil:
		{
			int rifle = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
			if (rifle != INVALID_ENT)
			{
				if (PlayerHasItem(client, item) && CanUseCollectorItem(client, item))
				{
					// Huntsman charge speed uses the fast_reload attribute only (although it does affect the reload speed too but W/E)
					char classname[64];
					GetEntityClassname(rifle, classname, sizeof(classname));
					if (strcmp2(classname, "tf_weapon_compound_bow"))
					{
						TF2Attrib_SetByName(rifle, "faster reload rate", CalcItemMod_Reciprocal(client, item, 0));
					}
					else
					{
						TF2Attrib_SetByName(rifle, "SRifle Charge rate increased", 1.0+CalcItemMod(client, item, 0));
					}
					
					UpdatePlayerReloadRate(client);
				}
			}
		}
		
		case ItemScout_FedFedora:
		{
			int primary = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
			if (primary != INVALID_ENT)
			{
				if (PlayerHasItem(client, item) && CanUseCollectorItem(client, item))
				{
					TF2Attrib_SetByName(primary, "bullets per shot bonus", 1.0+CalcItemMod(client, ItemScout_FedFedora, 0));
				}
			}
		}
		
		case ItemSoldier_HawkWarrior:
		{
			if (PlayerHasItem(client, item))
			{
				TF2Attrib_SetByName(client, "mod_air_control_blast_jump", 1.0+CalcItemMod(client, item, 2));
			}
		}
	}
	
	if (!PlayerHasItem(client, item) && !IsEquipmentItem(item) || IsEquipmentItem(item) && GetPlayerEquipmentItem(client) != item)
	{
		RemoveItemAsWearable(client, item); // Remove the wearable if we don't have the item anymore.
		
		// See if we can find another wearable to equip
		int qualityPriority = GetQualityEquipPriority(GetItemQuality(item));
		while (qualityPriority >= 0)
		{
			for (int i = 1; i < GetTotalItems(); i++)
			{
				if (i != item && PlayerHasItem(client, i) && GetQualityEquipPriority(GetItemQuality(i)) >= qualityPriority)
				{
					if (CheckEquipRegionConflict(g_szItemEquipRegion[item], g_szItemEquipRegion[i]))
					{
						EquipItemAsWearable(client, i);
						qualityPriority = -1;
						break;
					}
				}
			}
			
			qualityPriority--;
		}
	}
	else
	{
		EquipItemAsWearable(client, item);
	}
}

void DoItemKillEffects(int attacker, int inflictor, int victim, int damageType=DMG_GENERIC, CritType critType=CritType_None, int assister=INVALID_ENT, int damageCustom=0)
{
	if (damageType & DMG_MELEE)
	{
		if (PlayerHasItem(attacker, Item_SaxtonHat))
		{
			if (critType == CritType_Crit)
			{
				// Must be done a frame later to prevent bugs with player_death event
				DataPack pack = new DataPack();
				pack.WriteCell(attacker);
				pack.WriteCell(victim);
				RequestFrame(RF_SaxtonRadiusDamage, pack);
			}
		}
		
		if (PlayerHasItem(attacker, Item_Goalkeeper))
		{
			if (!TF2_IsPlayerInCondition(attacker, TFCond_CritOnKill))
			{
				float chance = fmin(CalcItemMod_Hyperbolic(attacker, Item_Goalkeeper, 0), 1.0);
				if (RandChanceFloatEx(attacker, 0.0, 1.0, chance))
				{
					TF2_AddCondition(attacker, TFCond_CritOnKill, GetItemMod(Item_Goalkeeper, 1));
				}
			}
			
			TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, CalcItemMod(attacker, Item_Goalkeeper, 4));
		}
	}
	
	int equipment = GetPlayerEquipmentItem(attacker);
	if (PlayerHasItem(attacker, Item_KillerExclusive) && GetPlayerEquipmentItem(attacker) > Item_Null 
		&& g_flPlayerEquipmentItemCooldown[attacker] > 0.0
		&& g_flPlayerEquipmentItemCooldown[attacker] > g_flEquipmentItemMinCooldown[equipment])
	{
		float reduction = fmax(0.0, CalcItemMod(attacker, Item_KillerExclusive, 0));
		g_flPlayerEquipmentItemCooldown[attacker] = fmax(g_flPlayerEquipmentItemCooldown[attacker]-reduction, g_flEquipmentItemMinCooldown[equipment]);
	}
	
	if (PlayerHasItem(attacker, Item_Executioner) && critType == CritType_Crit)
	{
		float radius = GetItemMod(Item_Executioner, 2);
		float victimPos[3], enemyPos[3];
		GetEntPos(victim, victimPos, true);
		EmitAmbientSound(SND_BLEED_EXPLOSION, victimPos, _, SNDLEVEL_TRAIN);
		TE_TFParticle("env_sawblood", victimPos);
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (i == victim || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(attacker) == GetClientTeam(i))
				continue;
			
			GetEntPos(i, enemyPos);
			TR_TraceRayFilter(victimPos, enemyPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceFilter_WallsOnly);
			
			if (!TR_DidHit() && GetVectorDistance(victimPos, enemyPos, true) <= sq(radius))
			{
				TF2_MakeBleed(i, attacker, GetItemMod(Item_Executioner, 3));
			}
		}
	}
	
	if (PlayerHasItem(attacker, Item_BedouinBandana))
	{
		if (RandChanceFloatEx(attacker, 0.0, 1.0, GetItemMod(Item_BedouinBandana, 0)))
		{
			float damage = GetItemMod(Item_BedouinBandana, 1) + CalcItemMod(attacker, Item_BedouinBandana, 2, -1);
			float speed = GetItemMod(Item_BedouinBandana, 4);
			int count = GetItemModInt(Item_BedouinBandana, 3);
			float victimPos[3], spawnPos[3], angles[3], dir[3];
			GetClientEyePosition(victim, victimPos);
			victimPos[2] -= 10.0;
			for (int i = 1; i <= count; i++)
			{
				// spread the knives out a bit
				GetAngleVectors(angles, dir, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(dir, dir);
				CopyVectors(victimPos, spawnPos);
				float rand = GetRandomFloat(25.0, 75.0);
				spawnPos[0] += dir[0] * rand;
				spawnPos[1] += dir[1] * rand;
				spawnPos[2] += dir[2] * rand;
				
				RF2_Projectile_Kunai kunai = RF2_Projectile_Kunai(ShootProjectile(attacker, "rf2_projectile_kunai", spawnPos, angles, speed, damage, _, _, false));
				kunai.Homing = true;
				kunai.Flying = true;
				kunai.DeactivateOnHit = false;
				kunai.SetWorldImpactSound(""); // otherwise there will be earrape
				SetEntItemProc(kunai.index, Item_BedouinBandana);
				kunai.SetRedTrail("flaregun_trail_red");
				kunai.SetBlueTrail("flaregun_trail_blue");
				kunai.AltParticleSpawn = true;
				kunai.Spawn();
				angles[1] += 60.0;
			}
		}
	}
	
	if (PlayerHasItem(attacker, Item_BruiserBandana))
	{
		int heal = CalcItemModInt(attacker, Item_BruiserBandana, 0);
		if (TF2_IsPlayerInCondition(victim, TFCond_MarkedForDeath) || TF2_IsPlayerInCondition(victim, TFCond_MarkedForDeathSilent))
		{
			heal = RoundFloat(float(heal) * GetItemMod(Item_BruiserBandana, 5));
		}
		
		HealPlayer(attacker, heal);
		if (RandChanceFloatEx(attacker, 0.0, 1.0, CalcItemMod(attacker, Item_BruiserBandana, 1)))
		{
			DataPack pack = new DataPack();
			pack.WriteCell(attacker);
			pack.WriteCell(victim);
			RequestFrame(RF_BandanaExplosion, pack);
		}
	}
	
	if (damageCustom == TF_CUSTOM_HEADSHOT || damageCustom == TF_CUSTOM_HEADSHOT_DECAPITATION || damageCustom == TF_CUSTOM_PENETRATE_HEADSHOT)
	{
		DataPack pack = new DataPack();
		pack.WriteCell(attacker);
		pack.WriteCell(victim);
		RequestFrame(RF_DoHeadshotBonuses, pack);
	}
	else if (damageCustom == TF_CUSTOM_BACKSTAB)
	{
		if (PlayerHasItem(attacker, ItemSpy_NohMercy) && CanUseCollectorItem(attacker, ItemSpy_NohMercy))
		{
			RemoveAllRunes(attacker);
			TF2_AddCondition(attacker, TFCond_RuneHaste, CalcItemMod(attacker, ItemSpy_NohMercy, 1));
		}
	}

	if (PlayerHasItem(attacker, ItemSoldier_WarPig) && CanUseCollectorItem(attacker, ItemSoldier_WarPig) && IsValidEntity2(inflictor))
	{
		char inflictorClassname[64];
		GetEntityClassname(inflictor, inflictorClassname, sizeof(inflictorClassname));
		bool homingRocket = strcmp2(inflictorClassname, "rf2_projectile_homingrocket");
		if (homingRocket || strcmp2(inflictorClassname, "tf_projectile_rocket") || strcmp2(inflictorClassname, "tf_projectile_energy_ball") 
			|| strcmp2(inflictorClassname, "tf_projectile_sentryrocket"))
		{
			int enemy;
			if (!homingRocket)
			{
				int offset = FindSendPropInfo("CTFProjectile_Rocket", "m_hLauncher") + 16;
				enemy = GetEntDataEnt2(inflictor, offset); // m_hEnemy
			}
			else
			{
				enemy = RF2_Projectile_HomingRocket(inflictor).ImpactTarget;
			}
			
			if (enemy == victim)
			{
				// direct rocket kill (do this on next frame because the rocket can proc into itself which can cause the server to potentially hang)
				if (RandChanceFloatEx(attacker, 0.0, 1.0, GetItemMod(ItemSoldier_WarPig, 1)))
				{
					DataPack pack = new DataPack();
					pack.WriteCell(attacker);
					pack.WriteCell(victim);
					RequestFrame(RF_FireHomingRockets, pack);
				}
			}
		}
	}
	
	if (PlayerHasItem(attacker, Item_DapperTopper) && !g_bPlayerHealBurstCooldown[attacker])
	{
		g_flPlayerRegenBuffTime[attacker] = GetItemMod(Item_DapperTopper, 1);
		g_flPlayerHealthRegenTime[attacker] = 0.0;
		if (GetClientHealth(attacker) >= RF2_GetCalculatedMaxHealth(attacker) && RandChanceFloatEx(attacker, 0.0, 1.0, fmin(1.0, GetItemMod(Item_DapperTopper, 2))))
		{
			float healPercent = CalcItemMod(attacker, Item_DapperTopper, 3);
			float radius = GetItemMod(Item_DapperTopper, 4);
			int team = GetClientTeam(attacker);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team && DistBetween(attacker, i) <= radius)
				{
					HealPlayer(i, RoundToFloor(float(RF2_GetCalculatedMaxHealth(i))*healPercent), true);
				}
			}
			
			EmitSoundToAll(SND_SPELL_OVERHEAL, attacker);
			g_bPlayerHealBurstCooldown[attacker] = true;
			CreateTimer(GetItemMod(Item_DapperTopper, 5), Timer_HealBurstCooldown, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	if (PlayerHasItem(attacker, ItemPyro_PyromancerMask) && CanUseCollectorItem(attacker, ItemPyro_PyromancerMask)
		&& RandChanceFloatEx(attacker, 0.0001, 1.0, GetItemMod(ItemPyro_PyromancerMask, 5)))
	{
		if (TF2_IsPlayerInCondition(victim, TFCond_OnFire) || TF2_IsPlayerInCondition(victim, TFCond_BurningPyro))
		{
			float angles[3], pos[3];
			GetEntPos(victim, pos, true);
			angles[0] = -80.0;
			angles[1] = 180.0;
			RF2_Projectile_Fireball fireball;
			int count = GetItemModInt(ItemPyro_PyromancerMask, 4);
			float damage = GetItemMod(ItemPyro_PyromancerMask, 0) + CalcItemMod(attacker, ItemPyro_PyromancerMask, 1, -1);
			float radius = GetItemMod(ItemPyro_PyromancerMask, 2) + CalcItemMod(attacker, ItemPyro_PyromancerMask, 3, -1);
			float angAdd = 360.0 / float(count);
			for (int i = 1; i <= count; i++)
			{
				fireball = RF2_Projectile_Fireball(ShootProjectile(attacker, "rf2_projectile_fireball", pos, angles, 425.0, damage));
				SetEntItemProc(fireball.index, ItemPyro_PyromancerMask);
				fireball.Flying = false;
				fireball.Radius = radius;
				angles[1] += angAdd;
			}
			
			EmitAmbientSound(SND_SPELL_FIREBALL, pos);
		}
	}
	
	if (PlayerHasItem(attacker, Item_OldCrown))
	{
		float chance = GetItemMod(Item_OldCrown, 0);
		if (RandChanceFloatEx(attacker, 0.0, 1.0, chance))
		{
			// don't spawn too many fireballs
			int limit = GetItemModInt(Item_OldCrown, 1);
			int count;
			int entity = MaxClients+1;
			while ((entity = FindEntityByClassname(entity, "rf2_projectile_fireball")) != INVALID_ENT)
			{
				RF2_Projectile_Fireball fireball = RF2_Projectile_Fireball(entity);
				if (fireball.Owner == attacker && GetEntItemProc(fireball.index) == Item_OldCrown)
				{
					count++;
				}
			}
			
			int total = count;
			int spawnCount;
			int spawnLimit = GetItemModInt(Item_OldCrown, 1);
			float damage = GetItemMod(Item_OldCrown, 2) + CalcItemMod(attacker, Item_OldCrown, 3, -1);
			float pos[3], victimPos[3], angles[3];
			GetEntPos(attacker, pos, true);
			GetEntPos(victim, victimPos, true);
			GetVectorAnglesTwoPoints(victimPos, pos, angles);
			while (total < limit && spawnCount < spawnLimit)
			{
				RF2_Projectile_Fireball fireball = RF2_Projectile_Fireball(ShootProjectile(attacker, "rf2_projectile_fireball", 
					victimPos, angles, 1000.0, damage, _, _, false));
				fireball.Homing = true;
				fireball.HomingTarget = attacker;
				fireball.DeactivateOnHit = false;
				fireball.HomingSpeed = GetRandomFloat(15.0, 20.0);
				fireball.SetWorldImpactSound("misc/null.wav");
				SetEntItemProc(fireball.index, Item_OldCrown);
				fireball.Spawn();
				spawnCount++;
				total++;
				angles[1] += GetRandomFloat(20.0, 75.0);
				angles[0] += GetRandomFloat(20.0, 75.0);
			}
		}
	}
	
	if (GetClientTeam(victim) == TEAM_ENEMY)
	{
		int pillarOfHatsOwner = INVALID_ENT;
		if (PlayerHasItem(attacker, Item_PillarOfHats))
		{
			pillarOfHatsOwner = attacker;
		}
		else if (IsValidClient(assister) && PlayerHasItem(assister, Item_PillarOfHats))
		{
			pillarOfHatsOwner = assister;
		}
		
		if (IsValidClient(pillarOfHatsOwner) && g_iMetalItemsDropped[pillarOfHatsOwner] < CalcItemModInt(pillarOfHatsOwner, Item_PillarOfHats, 4))
		{
			float scrapChance = CalcItemMod(pillarOfHatsOwner, Item_PillarOfHats, 0);
			float recChance = CalcItemMod(pillarOfHatsOwner, Item_PillarOfHats, 1);
			float refChance = CalcItemMod(pillarOfHatsOwner, Item_PillarOfHats, 2);
			float totalChance = scrapChance + recChance + refChance;
			totalChance = fmin(totalChance, 1.0);
			float result;
			
			if (RandChanceFloatEx(pillarOfHatsOwner, 0.0, 1.0, totalChance, result))
			{
				int item;
				if (result <= refChance)
				{
					item = Item_RefinedMetal;
				}
				else if (result <= recChance)
				{
					item = Item_ReclaimedMetal;
				}
				else
				{
					item = Item_ScrapMetal;
				}
				
				EmitSoundToClient(pillarOfHatsOwner, SND_USE_SCRAPPER);
				EmitSoundToClient(pillarOfHatsOwner, SND_USE_SCRAPPER);
				GiveItem(pillarOfHatsOwner, item, 1, true);
				char name[64];
				GetItemName(item, name, sizeof(name));
				PrintCenterText(pillarOfHatsOwner, "%t", "PillarOfHatsDrop", name);
				g_iMetalItemsDropped[pillarOfHatsOwner]++;
			}
		}
		
		if (PlayerHasItem(attacker, Item_Dangeresque) && GetClientTeam(victim))
		{
			if (RandChanceFloatEx(attacker, 0.0, 1.0, fmin(1.0, GetItemMod(Item_Dangeresque, 3))))
			{
				int bomb = CreateEntityByName("tf_projectile_pipe");
				float pos[3];
				GetEntPos(victim, pos);
				pos[2] += 30.0;
				TeleportEntity(bomb, pos);
				float damage = GetItemMod(Item_Dangeresque, 0) + CalcItemMod(attacker, Item_Dangeresque, 1, -1);
				SetEntPropFloat(bomb, Prop_Send, "m_flDamage", damage);
				float radius = GetItemMod(Item_Dangeresque, 4) + CalcItemMod(attacker, Item_Dangeresque, 5, -1);
				SetEntPropFloat(bomb, Prop_Send, "m_DmgRadius", radius);
				SetEntityOwner(bomb, attacker);
				SetEntTeam(bomb, GetEntTeam(attacker));
				g_bCashBomb[bomb] = true;
				if (IsEnemy(victim))
				{
					g_flCashBombAmount[bomb] = Enemy(victim).CashAward;
					g_iCashBombSize[bomb] = 2;
				}

				g_flCashBombAmount[bomb] *= 1.0 + (float(GetPlayerLevel(victim)-1) * g_cvEnemyCashDropScale.FloatValue);
				if (PlayerHasItem(attacker, Item_BanditsBoots))
				{
					g_flCashBombAmount[bomb] *= 1.0 + CalcItemMod(attacker, Item_BanditsBoots, 0);
				}
				
				SDKHook(bomb, SDKHook_StartTouch, Hook_DisableTouch);
				SDKHook(bomb, SDKHook_Touch, Hook_DisableTouch);
				SetShouldDamageOwner(bomb, false);
				SetEntItemProc(bomb, Item_Dangeresque);
				DispatchSpawn(bomb);
				ActivateEntity(bomb);
				SetEntityModel2(bomb, MODEL_CASH_BOMB);
				TE_TFParticle("mvm_cash_embers_red", pos, bomb, PATTACH_ABSORIGIN_FOLLOW);
			}
		}
	}
}

public void RF_DoHeadshotBonuses(DataPack pack)
{
	pack.Reset();
	int attacker = pack.ReadCell();
	int victim = pack.ReadCell();
	delete pack;
	if (!IsValidClient(attacker) || !IsValidClient(victim))
		return;
		
	DoHeadshotBonuses(attacker, victim, g_flHeadshotDamage);
}

public void RF_BandanaExplosion(DataPack pack)
{
	pack.Reset();
	int attacker = pack.ReadCell();
	int victim = pack.ReadCell();
	delete pack;
	if (!IsValidClient(attacker) || !IsValidClient(victim))
		return;
		
	float victimPos[3];
	GetEntPos(victim, victimPos, true);
	DoExplosionEffect(victimPos);
	ArrayList hitEnts = DoRadiusDamage(attacker, attacker, victimPos, Item_BruiserBandana, 
		GetItemMod(Item_BruiserBandana, 2), DMG_BLAST|DMG_PREVENT_PHYSICS_FORCE, GetItemMod(Item_BruiserBandana, 3), _, _, _, true);
	
	for (int i = 0; i < hitEnts.Length; i++)
	{
		int entity = hitEnts.Get(i);
		if (entity != victim && IsValidClient(entity))
		{
			TF2_AddCondition(entity, TFCond_MarkedForDeathSilent, GetItemMod(Item_BruiserBandana, 4), attacker);
		}
	}

	delete hitEnts;
}

public void RF_FireHomingRockets(DataPack pack)
{
	pack.Reset();
	int attacker = pack.ReadCell();
	int victim = pack.ReadCell();
	delete pack;
	if (!IsValidClient(attacker) || !IsValidClient(victim))
		return;
	
	float victimPos[3], angles[3];
	GetEntPos(victim, victimPos, true);
	float damage = GetItemMod(ItemSoldier_WarPig, 2) + CalcItemMod(attacker, ItemSoldier_WarPig, 3, -1);
	float speed = GetItemMod(ItemSoldier_WarPig, 4) + CalcItemMod(attacker, ItemSoldier_WarPig, 5, -1);
	for (int i = 1; i <= GetItemMod(ItemSoldier_WarPig, 6); i++)
	{
		RF2_Projectile_HomingRocket rocket = RF2_Projectile_HomingRocket(ShootProjectile(attacker, "rf2_projectile_homingrocket", 
			victimPos, angles, speed, damage));
		
		angles[1] += 135.0;
		rocket.HomingSpeed = speed;
		SetEntItemProc(rocket.index, ItemSoldier_WarPig);
	}
	
	EmitAmbientSound(SND_LAW_FIRE, victimPos, _, _, _, 0.75);
}

public void Timer_HealBurstCooldown(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return;

	g_bPlayerHealBurstCooldown[client] = false;
}

public void RF_SaxtonRadiusDamage(DataPack pack)
{
	pack.Reset();
	int attacker = pack.ReadCell();
	int victim = pack.ReadCell();
	delete pack;
	float victimPos[3];
	GetEntPos(victim, victimPos);
	float damage = GetItemMod(Item_SaxtonHat, 2) + CalcItemMod(attacker, Item_SaxtonHat, 3, -1);
	DoRadiusDamage(attacker, attacker, victimPos, Item_SaxtonHat, damage, DMG_BLAST, 180.0, 0.6);
	DoExplosionEffect(victimPos, true);
	TriggerAchievement(attacker, ACHIEVEMENT_SAXTON);
}

public Action Hook_BlockWeaponSwitch(int client, int weapon)
{
	return Plugin_Stop;
}

bool ActivateStrangeItem(int client)
{
	if (g_iPlayerEquipmentItemCharges[client] <= 0 || IsPlayerMinion(client))
		return false;
	
	int equipment = GetPlayerEquipmentItem(client);
	if (GetPercentInvisible(client) > 0.0 && equipment == ItemStrange_DarkHunter)
		return false;
	
	if (IsPlayerStunned(client) || TF2_IsPlayerInCondition(client, TFCond_Taunting))
		return false;
		
	if (IsRollermine(client))
		return false;
		
	Call_StartForward(g_fwOnActivateStrange);
	Call_PushCell(client);
	Call_PushCell(equipment);
	Action action = Plugin_Continue;
	Call_Finish(action);
	if (action == Plugin_Handled || action == Plugin_Stop)
	{
		return false;
	}
	
	if (equipment == ItemStrange_PartyHat)
	{
		ArrayList equipmentList = new ArrayList();
		for (int i = 1; i < GetTotalItems(); i++)
		{
			if (i == ItemStrange_PartyHat 
				|| i == ItemStrange_LittleBuddy 
				|| i == ItemStrange_ModestHat
				|| !g_bItemInDropPool[i]
				|| !IsEquipmentItem(i) 
				|| GetItemQuality(i) == Quality_HauntedStrange)
				continue;
			
			equipmentList.Push(i);
		}
		
		equipment = equipmentList.Get(GetRandomInt(0, equipmentList.Length-1));
		delete equipmentList;
	}
	
	switch (equipment)
	{
		case ItemStrange_Botler:
		{
			RF2_RobotButler bot = RF2_RobotButler(CreateEntityByName("rf2_npc_robot_butler"));
			bot.Master = client;
			bot.Team = GetClientTeam(client);
			int health = RoundToFloor(GetItemMod(ItemStrange_Botler, 0) * GetEnemyHealthMult());
			bot.MaxHealth = health;
			bot.Health = health;
			bot.HealCooldown = GetItemMod(ItemStrange_Botler, 1);
			bot.BombDamage = GetItemMod(ItemStrange_Botler, 2);
			bot.BombRadius = GetItemMod(ItemStrange_Botler, 3);
			bot.SuicideBombAt = GetGameTime()+GetItemMod(ItemStrange_Botler, 4);
			float pos[3];
			GetEntPos(client, pos);
			TE_TFParticle("eyeboss_tp_player", pos);
			EmitAmbientGameSound("Building_Teleporter.Send", pos);
			bot.Teleport(pos);
			bot.Spawn();
		}
		
		case ItemStrange_RobotChicken:
		{
			TF2_AddCondition(client, TFCond_CritOnFlagCapture, GetItemMod(ItemStrange_RobotChicken, 0));
		}
		
		case ItemStrange_Longwave:
		{
			bool teleFound;
			RF2_Object_Teleporter teleporter = RF2_Object_Teleporter(FindEntityByClassname(MaxClients+1, "rf2_object_teleporter"));
			if (teleporter.IsValid() && !IsGlowing(teleporter.index) && teleporter.EventState == TELE_EVENT_INACTIVE)
			{
				teleporter.SetGlow(true);
				teleFound = true;
			}
			
			float pos[3];
			GetEntPos(client, pos, true);
			ArrayList crateList = GetNearestEntities(pos, "rf2_object_crate");
			crateList.Resize(imin(crateList.Length, GetItemModInt(ItemStrange_Longwave, 0)));
			if (crateList.Length <= 0 && !teleFound)
			{
				EmitSoundToClient(client, SND_NOPE);
				PrintCenterText(client, "%t", "NoObjectsFound");
				delete crateList;
				return false;
			}

			for (int i = 0; i < crateList.Length; i++)
			{
				RF2_Object_Crate(crateList.Get(i)).PingMe(_, GetItemMod(ItemStrange_Longwave, 1));
			}
			
			// Outline all barrels as well
			int barrel = MaxClients+1;
			while ((barrel = FindEntityByClassname(barrel, "rf2_object_barrel")) != INVALID_ENT)
			{
				RF2_Object_Barrel(barrel).PingMe(_, GetItemMod(ItemStrange_Longwave, 1));
			}

			EmitSoundToAll(SND_LONGWAVE_USE, client);
			EmitSoundToAll(SND_LONGWAVE_USE, client);
			TE_TFParticle("hammer_bell_ring_shockwave", pos);
			delete crateList;
		}
		
		case ItemStrange_HeartOfGold:
		{
			const float range = 500.0;
			int team = GetClientTeam(client);
			float pos[3];
			char particle[32];
			particle = team == view_as<int>(TFTeam_Red) ? "spell_overheal_red" : "spell_overheal_blue";
			// Heal me and teammates around me
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != team)
					continue;
				
				if (client != i && DistBetween(client, i) > range)
					continue;
				
				int maxHealth = RF2_GetCalculatedMaxHealth(i);
				int heal = RoundToFloor(float(maxHealth) * GetItemMod(ItemStrange_HeartOfGold, 0));
				HealPlayer(i, heal);
				CBaseEntity(i).WorldSpaceCenter(pos);
				SpawnInfoParticle(particle, pos, 3.0, i);
			}
			
			EmitSoundToAll(SND_SPELL_OVERHEAL, client);
		}
		
		case ItemStrange_SpecialRing:
		{
			if (g_bRingCashBonus)
				return false;
			
			g_bRingCashBonus = true;
			EmitSoundToAll(SND_CASH);
			CreateTimer(GetItemMod(ItemStrange_SpecialRing, 1), Timer_EndRingBonus, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		case ItemStrange_VirtualViewfinder:
		{
			float eyePos[3], angles[3], direction[3];
			GetClientEyePosition(client, eyePos);
			GetClientEyeAngles(client, angles);
			GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(direction, direction);
			eyePos[0] += direction[0] * 10.0;
			eyePos[1] += direction[1] * 10.0;
			eyePos[2] += direction[2] * 10.0;
			
			int colors[4];
			colors[3] = 255;
			if (TF2_GetClientTeam(client) == TFTeam_Red)
			{
				colors[0] = 255;
				colors[1] = 100;
				colors[2] = 100;
			}
			else
			{
				colors[0] = 100;
				colors[1] = 100;
				colors[2] = 255;
			}
			
			FireLaser(client, ItemStrange_VirtualViewfinder, eyePos, angles, true, _, 
				GetItemMod(ItemStrange_VirtualViewfinder, 0), DMG_SONIC|DMG_PREVENT_PHYSICS_FORCE, 25.0, colors, "head");
		}
		
		case ItemStrange_NastyNorsemann:
		{
			RemoveAllRunes(client);
			char sound[PLATFORM_MAX_PATH];
			TFCond rune = GetRandomMannpowerRune(sound, sizeof(sound));
			TF2_AddCondition(client, rune, GetItemMod(ItemStrange_NastyNorsemann, 0));
			EmitSoundToAll(sound, client);
		}
		
		case ItemStrange_ScaryMask:
		{
			float range = Pow(GetItemMod(ItemStrange_ScaryMask, 0), 2.0);
			float stunDuration = GetItemMod(ItemStrange_ScaryMask, 1);
			float buffDuration = GetItemMod(ItemStrange_ScaryMask, 2);
			float pos[3], victimPos[3];
			char sound[PLATFORM_MAX_PATH];
			FormatEx(sound, sizeof(sound), "vo/halloween_boss/knight_attack0%i.mp3", GetRandomInt(1, 4));
			EmitSoundToAll(sound, client);
			
			GetClientAbsOrigin(client, pos);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsValidClient(i) || !IsPlayerAlive(i) || GetClientTeam(i) == GetClientTeam(client))
					continue;
				
				if (RF2_IsPlayerBoss(i))
					continue;
				
				GetClientAbsOrigin(i, victimPos);
				if (GetVectorDistance(pos, victimPos, true) > range)
					continue;
				
				TF2_StunPlayer(i, stunDuration, 0.0, TF_STUNFLAGS_GHOSTSCARE, client);
				TF2_AddCondition(i, TFCond_SpeedBuffAlly, buffDuration);
				TF2_AddCondition(i, TFCond_Buffed, buffDuration);
			}
		}
		
		case ItemStrange_DarkHunter:
		{
			EmitSoundToAll(SND_SPELL_STEALTH, client);
			TF2_AddCondition(client, TFCond_Stealthed, GetItemMod(ItemStrange_DarkHunter, 0));
		}
		
		case ItemStrange_LegendaryLid:
		{
			float pos[3], angles[3];
			GetClientEyePosition(client, pos);
			GetClientEyeAngles(client, angles);
			
			int shuriken = ShootProjectile(client, "rf2_projectile_shuriken", pos, angles, 
				GetItemMod(ItemStrange_LegendaryLid, 2), GetItemMod(ItemStrange_LegendaryLid, 0), -2.0);
			
			SetEntItemProc(shuriken, ItemStrange_LegendaryLid);

			angles[1] += 10.0;
			shuriken = ShootProjectile(client, "rf2_projectile_shuriken", pos, angles, 
				GetItemMod(ItemStrange_LegendaryLid, 2), GetItemMod(ItemStrange_LegendaryLid, 0), -2.0);
			
			SetEntItemProc(shuriken, ItemStrange_LegendaryLid);
			
			angles[1] -= 20.0;
			shuriken = ShootProjectile(client, "rf2_projectile_shuriken", pos, angles, 
				GetItemMod(ItemStrange_LegendaryLid, 2), GetItemMod(ItemStrange_LegendaryLid, 0), -2.0);
			
			SetEntItemProc(shuriken, ItemStrange_LegendaryLid);
			
			ClientPlayGesture(client, "ACT_MP_THROW");
			EmitSoundToAll(SND_THROW, client);
		}
		
		case ItemStrange_CroneDome:
		{
			float pos[3], angles[3];
			GetClientEyePosition(client, pos);
			GetClientEyeAngles(client, angles);
			
			int bomb = ShootProjectile(client, "rf2_projectile_bomb", pos, angles, 
				GetItemMod(ItemStrange_CroneDome, 3), GetItemMod(ItemStrange_CroneDome, 1), -2.0);
			
			SetEntItemProc(bomb, ItemStrange_CroneDome);

			ClientPlayGesture(client, "ACT_MP_THROW");
			EmitSoundToAll(SND_THROW, client);
		}
		
		case ItemStrange_HandsomeDevil:
		{
			float pos[3], angles[3];
			GetClientEyePosition(client, pos);
			GetClientEyeAngles(client, angles);
			
			int kunai = ShootProjectile(client, "rf2_projectile_kunai", pos, angles, 
				GetItemMod(ItemStrange_HandsomeDevil, 2), GetItemMod(ItemStrange_HandsomeDevil, 0), -2.0);
			
			SetEntItemProc(kunai, ItemStrange_HandsomeDevil);

			ClientPlayGesture(client, "ACT_MP_THROW");
			EmitSoundToAll(SND_THROW, client);
		}
		
		case ItemStrange_Dragonborn:
		{
			EmitSoundToAll(SND_DRAGONBORN, client);
			EmitSoundToAll(SND_DRAGONBORN, client);
			CreateTimer(0.5, Timer_FusRoDah, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		case ItemStrange_DemonicDome:
		{
			float damage = float(RF2_GetCalculatedMaxHealth(client))*GetItemMod(ItemStrange_DemonicDome, 0);
			if (damage >= float(GetClientHealth(client)))
			{
				return false;
			}
			
			float pos[3], angles[3];
			GetClientEyePosition(client, pos);
			GetClientEyeAngles(client, angles);
			RF2_Projectile_Skull skull = RF2_Projectile_Skull(ShootProjectile(client, "rf2_projectile_skull", pos, angles, 1000.0, GetItemMod(ItemStrange_DemonicDome, 1)));
			int target = GetClientAimTarget(client, false);
			if (target > 0 && IsCombatChar(target))
			{
				skull.HomingTarget = target;
			}
			
			ClientPlayGesture(client, "ACT_MP_THROW");
			EmitSoundToAll(SND_SPELL_FIREBALL, client);
			SDKHooks_TakeDamage(client, client, client, damage, DMG_SLASH|DMG_PREVENT_PHYSICS_FORCE);
		}
		
		case ItemStrange_ModestHat:
		{
			RF2_Item item = GetItemInPickupRange(client);
			if (!item.IsValid() || !item.CanBeShuffledBy(client))
			{
				return false;
			}
			
			ArrayList randomItems = new ArrayList();
			int type = item.Type;
			int quality = GetItemQuality(type);
			for (int i = 1; i < GetTotalItems(); i++)
			{
				if (g_bItemInDropPool[i] && (GetItemQuality(i) == quality || IsHauntedItem(i) && IsHauntedItem(type)) && i != type)
				{
					if (quality == Quality_Collectors && g_iCollectorItemClass[type] != g_iCollectorItemClass[i])
						continue;

					randomItems.Push(i);
				}
			}
			
			if (randomItems.Length > 0)
			{
				int randomItem = randomItems.Get(GetRandomInt(0, randomItems.Length-1));
				RF2_Item newItem = RF2_Item(CreateEntityByName("rf2_item"));
				newItem.Type = randomItem;
				newItem.Shuffled = true;
				newItem.Owner = client;
				newItem.OwnTime = 8.0;
				CreateTimer(0.1, Timer_ClearItemOwner, EntIndexToEntRef(newItem.index), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				
				float pos[3];
				item.GetAbsOrigin(pos);
				newItem.Teleport(pos);
				newItem.Spawn();
				EmitSoundToAll(SND_USE_WORKBENCH, newItem.index);
				TE_TFParticle("mvm_loot_smoke", pos);
				RemoveEntity(item.index);
				if (quality == Quality_Unusual)
				{
					TriggerAchievement(client, ACHIEVEMENT_RECYCLER);
				}
			}
			else
			{
				delete randomItems;
				return false;
			}
			
			delete randomItems;
		}

		case ItemStrange_OneWayTicket:
		{
			if (g_bPlayerPermaDeathMark[client])
			{
				PrintCenterText(client, "%t", "AlreadyMarked");
				EmitSoundToClient(client, SND_NOPE);
				return false;
			}

			ArrayList deadAllies = new ArrayList();
			for (int i = 1; i <= MaxClients; i++)
			{
				if (i == client || !IsPlayerSurvivor(i, false) || !IsPlayerMinion(i) && IsPlayerAlive(i))
					continue;
				
				deadAllies.Push(i);
			}

			if (deadAllies.Length <= 0)
			{
				PrintCenterText(client, "%t", "NoAlliesDead");
				EmitSoundToClient(client, SND_NOPE);
				delete deadAllies;
				return false;
			}

			int ally = deadAllies.Get(GetRandomInt(0, deadAllies.Length-1));
			delete deadAllies;
			if (IsPlayerAlive(ally))
				SilentlyKillPlayer(ally);

			float pos[3];
			GetEntPos(client, pos, true);
			SetVariantString("");
			AcceptEntityInput(ally, "SetCustomModel");
			TF2_RespawnPlayer(ally);
			TeleportEntity(ally, pos);
			TF2_AddCondition(ally, TFCond_UberchargedCanteen, 5.0);
			g_bPlayerPermaDeathMark[client] = true;
			TF2_AddCondition(client, TFCond_MarkedForDeathSilent);
			GiveItem(client, ItemStrange_OneWayTicket, -1);
			GiveItem(client, ItemStrange_LittleBuddy, 1, true);
			EmitSoundToAll(SND_REVIVE, ally, _, SNDLEVEL_SCREAMING);
			EmitSoundToAll(SND_MERASMUS_APPEAR, ally, _, SNDLEVEL_SCREAMING);
			SpawnInfoParticle("eyeboss_death_vortex", pos, 10.0);
			TE_TFParticle("ghost_appearation", pos);
		}

		case ItemStrange_LittleBuddy:
		{
			if (GetClientTeam(client) == TEAM_SURVIVOR)
			{
				CPrintToChatAll("{red}%N{default} :  Ahoy!", client);
			}
			else
			{
				CPrintToChatAll("{blue}%N{default} :  Ahoy!", client);
			}
		}

		case ItemStrange_WarswornHelm:
		{
			g_flPlayerWarswornBuffTime[client] = GetTickedTime()+GetItemMod(ItemStrange_WarswornHelm, 0);
			UpdatePlayerFireRate(client);
			EmitGameSoundToAll(GSND_MVM_POWERUP, client);
		}
		
		case ItemStrange_JackHat:
		{
			if (TF2_GetPlayerClass(client) == TFClass_Engineer)
			{
				// make sure we're not hauling a building
				int weapon = GetActiveWeapon(client);
				char classname[128];
				GetEntityClassname(weapon, classname, sizeof(classname));
				if (strcmp2(classname, "tf_weapon_builder"))
				{
					return false;
				}
			}
			
			// prepare ourselves to become a roller mine
			SetEntityCollisionGroup(client, TFCOLLISION_GROUP_ROCKET_BUT_NOT_WITH_OTHER_ROCKETS);
			TF2Attrib_AddCustomPlayerAttribute(client, "no_attack", 1.0, GetItemMod(ItemStrange_JackHat, 3)+1.0);
			SetVariantInt(1);
			AcceptEntityInput(client, "SetForcedTauntCam");
			SetEntityMoveType(client, MOVETYPE_OBSERVER);
			SetEntityRenderMode(client, RENDER_NONE);
			if (TF2_IsPlayerInCondition(client, TFCond_Slowed))
			{
				int weapon = GetActiveWeapon(client);
				if (weapon != INVALID_ENT)
				{
					char classname[128];
					GetEntityClassname(weapon, classname, sizeof(classname));
					if (strcmp2(classname, "tf_weapon_minigun"))
					{
						// kill minigun windup sound (this glitches the animation for a bit after but w/e)
						SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", GetGameTime());
						SetEntProp(weapon, Prop_Send, "m_iWeaponState", 1);
					}
				}
			}
			
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", INVALID_ENT);
			SDKHook(client, SDKHook_WeaponCanSwitchTo, Hook_BlockWeaponSwitch);
			SetEntProp(client, Prop_Data, "m_takedamage", DAMAGE_NO);
			
			// create the roller mine
			int rollerMine = CreateEntityByName("prop_physics_multiplayer");
			DispatchKeyValueInt(rollerMine, "nodamageforces", 1);
			DispatchKeyValueFloat(rollerMine, "physdamagescale", 0.0);
			SetEntPropFloat(rollerMine, Prop_Send, "m_flModelScale", 1.25);
			SetEntityModel2(rollerMine, MODEL_ROLLERMINE);
			float pos[3];
			GetEntPos(client, pos, true);
			TeleportEntity(rollerMine, pos);
			DispatchSpawn(rollerMine);
			SetEntProp(rollerMine, Prop_Send, "m_nSolidType", SOLID_VPHYSICS);
			SetEntProp(rollerMine, Prop_Send, "m_usSolidFlags", FSOLID_TRIGGER|FSOLID_NOT_STANDABLE);
			SetEntityCollisionGroup(rollerMine, COLLISION_GROUP_PLAYER);
			g_iPlayerRollerMine[client] = EntIndexToEntRef(rollerMine);
			SetEntityOwner(rollerMine, client);
			SetEntProp(rollerMine, Prop_Data, "m_iTeamNum", GetClientTeam(client));
			CreateTimer(1.3, Timer_RollerMineSpikes, g_iPlayerRollerMine[client], TIMER_FLAG_NO_MAPCHANGE);
			EmitSoundToAll("npc/roller/mine/combine_mine_deploy1.wav", rollerMine);
			EmitSoundToAll("npc/roller/mine/combine_mine_deploy1.wav", rollerMine);
			EmitSoundToAll("npc/roller/mine/rmine_tossed1.wav", rollerMine);
			EmitSoundToAll("npc/roller/mine/rmine_tossed1.wav", rollerMine);
			float vel[3];
			GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vel);
			SetPhysVelocity(rollerMine, vel);
			if (g_hHookPhysicsSolidMask)
			{
				// necessary to prevent the player from escaping the map boundaries
				g_hHookPhysicsSolidMask.HookEntity(Hook_Pre, rollerMine, DHook_RollerMineSolidMask);	
			}
			
			if (g_hHookVPhysicsCollision)
			{
				g_hHookVPhysicsCollision.HookEntity(Hook_Post, rollerMine, DHook_RollerMinePhysics);
			}
			
			int wearable = MaxClients+1;
			while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != INVALID_ENT)
			{
				if (GetEntPropEnt(wearable, Prop_Data, "m_hOwnerEntity") == client)
					SetEntityRenderMode(wearable, RENDER_NONE);
			}
			
			while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != INVALID_ENT)
			{
				if (GetEntPropEnt(wearable, Prop_Data, "m_hOwnerEntity") == client)
					SetEntityRenderMode(wearable, RENDER_NONE);
			}
			
			CreateTimer(GetItemMod(ItemStrange_JackHat, 3), Timer_RollerMineEndAnim, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(GetItemMod(ItemStrange_JackHat, 3)+1.0, Timer_EndRollerMine, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		case ItemStrange_PocketYeti:
		{
			if (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != 0) // not standing on world?
				return false;
			
			ForceTaunt(client, 1183);
			if (!TF2_IsPlayerInCondition(client, TFCond_Taunting)) // couldn't taunt?
				return false;
			
			if (GetEntProp(client, Prop_Send, "m_iTauntIndex") != 1183) // wrong taunt?
				return false;
			
			g_bPlayerYetiSmash[client] = true;
			TF2_AddCondition(client, TFCond_MegaHeal, 9.0);
			TF2_AddCondition(client, TFCond_UberchargedHidden, 9.0);
			CreateTimer(5.3, Timer_YetiSmash, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		case ItemStrange_MK50:
		{
			g_flPlayerJetpackEndTime[client] = GetTickedTime() + GetItemMod(ItemStrange_MK50, 0);
			UpdatePlayerGravity(client);
			float airControlAmount = 1.0 + GetItemMod(ItemStrange_MK50, 2);
			if (PlayerHasItem(client, Item_Tux))
			{
				airControlAmount += CalcItemMod(client, Item_Tux, 1);
			}
			
			TF2Attrib_SetByName(client, "increased air control", airControlAmount);
			CreateTimer(GetItemMod(ItemStrange_MK50, 0)+0.1, Timer_UpdateGravity, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	// Don't go on cooldown if our charges are above the limit; we likely dropped some battery canteens
	int maxCharges = RoundToFloor(CalcItemMod(client, Item_BatteryCanteens, 1, 1));
	if (g_iPlayerEquipmentItemCharges[client] <= maxCharges)
	{
		if (g_flPlayerEquipmentItemCooldown[client] <= 0.0)
		{
			g_bPlayerEquipmentCooldownActive[client] = true;
			CreateTimer(0.1, Timer_EquipmentCooldown, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		
		g_flPlayerEquipmentItemCooldown[client] = GetPlayerEquipmentItemCooldown(client);
	}
	
	if (PlayerHasItem(client, Item_SaintMark))
	{
		float duration = GetItemMod(Item_SaintMark, 1) + CalcItemMod(client, Item_SaintMark, 2, -1);
		if (g_flPlayerReloadBuffDuration[client] <= 0.0)
		{
			g_flPlayerReloadBuffDuration[client] = duration;
			CreateTimer(0.1, Timer_ReloadBuffEnd, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			g_flPlayerReloadBuffDuration[client] = duration;
		}

		UpdatePlayerFireRate(client);
	}
	
	g_iPlayerEquipmentItemCharges[client]--;
	return true;
}

public void Timer_UpdateGravity(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)) || !IsPlayerAlive(client))
		return;
		
	UpdatePlayerGravity(client);
}

public void Timer_YetiSmash(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)) || !IsPlayerAlive(client))
		return;
	
	float pos[3];
	GetEntPos(client, pos, true);
	float damage = GetItemMod(ItemStrange_PocketYeti, 0);
	float radius = GetItemMod(ItemStrange_PocketYeti, 1);
	
	// we want knockback on ragdolls, so copy the way the dragonborn helm does it
	int team = GetClientTeam(client);
	ArrayList blacklist = new ArrayList();
	blacklist.Push(client);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (client == i || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) == team)
			continue;
		
		if (DistBetween(client, i) <= radius)
		{
			float randomVel[3];
			randomVel[0] = GetRandomFloat(-99999.0, 99999.0);
			randomVel[1] = GetRandomFloat(-99999.0, 99999.0);
			randomVel[2] = 99999.0;
			RF_TakeDamage(i, client, client, damage, DMG_PREVENT_PHYSICS_FORCE, ItemStrange_PocketYeti, _, randomVel);
			float victimPos[3], ang[3], vel[3];
			GetEntPos(i, victimPos, true);
			GetVectorAnglesTwoPoints(pos, victimPos, ang);
			GetAngleVectors(ang, vel, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(vel, vel);
			ScaleVector(vel, GetItemMod(ItemStrange_PocketYeti, 2));
			vel[2] = GetItemMod(ItemStrange_PocketYeti, 2)*0.5;
			ApplyAbsVelocityImpulse(i, vel);
			TF2_AddCondition(i, TFCond_AirCurrent, 5.0);
			blacklist.Push(i);
		}
	}
	
	// also hit other entities
	DoRadiusDamage(client, client, pos, 
		ItemStrange_PocketYeti, damage, DMG_PREVENT_PHYSICS_FORCE, radius, _, _, blacklist);

	g_bPlayerYetiSmash[client] = false;
	UTIL_ScreenShake(pos, 10.0, 5.0, 3.0, radius*4.0, SHAKE_START, true);
	delete blacklist;
}

void OnRollerMineCollide(int mine, int entity)
{
	float ang[3], vel[3], pos1[3], pos2[3];
	GetEntPos(mine, pos1, true);
	GetEntPos(entity, pos2, true);
	GetVectorAnglesTwoPoints(pos2, pos1, ang);
	ang[0] = -45.0;
	GetAngleVectors(ang, vel, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vel, vel);
	ScaleVector(vel, 700.0);
	SetPhysVelocity(mine, vel);
	if (IsValidClient(entity))
	{
		GetVectorAnglesTwoPoints(pos1, pos2, ang);
		ang[0] = -45.0;
		GetAngleVectors(ang, vel, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vel, vel);
		ScaleVector(vel, 700.0);
		ApplyAbsVelocityImpulse(entity, vel);
	}
	
	int owner = GetEntPropEnt(mine, Prop_Data, "m_hOwnerEntity");
	ArrayList blacklist = new ArrayList();
	blacklist.Push(entity);
	
	// hit entity takes the full damage always
	RF_TakeDamage(entity, owner, owner, GetItemMod(ItemStrange_JackHat, 1), 
		DMG_BLAST|DMG_PREVENT_PHYSICS_FORCE, ItemStrange_JackHat);
	DoRadiusDamage(owner, owner, pos2, ItemStrange_JackHat, GetItemMod(ItemStrange_JackHat, 1), 
		DMG_BLAST|DMG_PREVENT_PHYSICS_FORCE, GetItemMod(ItemStrange_JackHat, 2), _, _, blacklist);
	
	delete blacklist;
	DoExplosionEffect(pos1, false);
	EmitSoundToAll("npc/roller/mine/rmine_explode_shock1.wav", mine);
	EmitSoundToAll("npc/roller/mine/rmine_explode_shock1.wav", mine);
}

public void Hook_RollerMineStartTouchPost(int entity, int other)
{
	if (IsCombatChar(other) 
		&& GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") != other
		&& GetEntTeam(entity) != GetEntTeam(other))
	{
		OnRollerMineCollide(entity, other);
	}
}

public void Timer_RollerMineSpikes(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return;
		
	SetEntityModel2(entity, MODEL_ROLLERMINE_SPIKES);
	SDKHook(entity, SDKHook_StartTouchPost, Hook_RollerMineStartTouchPost);
	char sound[PLATFORM_MAX_PATH];
	FormatEx(sound, sizeof(sound), "npc/roller/mine/rmine_blades_out%d.wav", GetRandomInt(1, 3));
	EmitSoundToAll(sound, entity);
	EmitSoundToAll(sound, entity);
	EmitSoundToAll("npc/roller/mine/rmine_seek_loop2.wav", entity);
	EmitSoundToAll("npc/roller/mine/rmine_seek_loop2.wav", entity);
}

public void Timer_RollerMineEndAnim(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return;
		
	int rollerMine = EntRefToEntIndex(g_iPlayerRollerMine[client]);
	if (rollerMine == INVALID_ENT)
		return;
		
	SetEntityModel2(rollerMine, MODEL_ROLLERMINE);
	SDKUnhook(rollerMine, SDKHook_StartTouchPost, Hook_RollerMineStartTouchPost);
	char sound[PLATFORM_MAX_PATH];
	FormatEx(sound, sizeof(sound), "npc/roller/mine/rmine_blades_in%d.wav", GetRandomInt(1, 3));
	EmitSoundToAll(sound, rollerMine);
	EmitSoundToAll(sound, rollerMine);
	StopSound(rollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
	StopSound(rollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
	StopSound(rollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
	StopSound(rollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
}

public void Timer_EndRollerMine(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)) || !IsPlayerAlive(client))
		return;
		
	int rollerMine = EntRefToEntIndex(g_iPlayerRollerMine[client]);
	if (rollerMine == INVALID_ENT)
		return;
	
	SetEntityCollisionGroup(client, COLLISION_GROUP_PLAYER);
	TF2Attrib_RemoveCustomPlayerAttribute(client, "no_attack");
	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntityRenderMode(client, RENDER_NORMAL);
	SDKUnhook(client, SDKHook_WeaponCanSwitchTo, Hook_BlockWeaponSwitch);
	SetEntProp(client, Prop_Data, "m_takedamage", DAMAGE_YES);
	ClientCommand(client, "lastinv");
	for (int i = 0; i <= WeaponSlot_Melee; i++)
	{
		if (IsValidEntity2(GetPlayerWeaponSlot(client, i)))
		{
			ForceWeaponSwitch(client, i, true);
			break;
		}	
	}
	
	int wearable = MaxClients+1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != INVALID_ENT)
	{
		if (GetEntPropEnt(wearable, Prop_Data, "m_hOwnerEntity") == client)
			SetEntityRenderMode(wearable, RENDER_NORMAL);
	}
	
	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != INVALID_ENT)
	{
		if (GetEntPropEnt(wearable, Prop_Data, "m_hOwnerEntity") == client)
			SetEntityRenderMode(wearable, RENDER_NORMAL);
	}
	
	float mins[3], maxs[3], playerPos[3];
	GetEntPos(client, playerPos);
	GetClientMins(client, mins);
	GetClientMaxs(client, maxs);
	TR_TraceHullFilter(playerPos, playerPos, mins, maxs, MASK_PLAYERSOLID, TraceFilter_RollerMineEnd, client);
	if (TR_DidHit())
	{
		// unstuck
		float pos[3];
		GetEntPos(rollerMine, pos, true);
		float dist = 200.0;
		CNavArea area = TheNavMesh.GetNavArea(pos, 200.0);
		if (area)
		{
			// if there's a nav area directly below us, try to use that first
			float navPos[3];
			area.GetCenter(navPos);
			navPos[2] += 15.0;
			TR_TraceHullFilter(navPos, navPos, mins, maxs, MASK_PLAYERSOLID, TraceFilter_RollerMineEnd, client);
			if (!TR_DidHit())
			{
				TeleportEntity(client, navPos);
			}
			else
			{
				area = NULL_AREA;
			}
		}
		
		if (!area)
		{
			pos[2] += 15.0; // helps a bit to find unstuck spots closer to us
			float spawnPos[3];
			int filterTeam = GetClientTeam(client) == 2 ? 3 : 2;
			while (!area)
			{
				area = GetSpawnPoint(pos, spawnPos, 0.0, dist, filterTeam, true, mins, maxs, MASK_PLAYERSOLID);
				TR_TraceRayFilter(pos, spawnPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceFilter_WallsOnly);
				if (TR_DidHit())
				{
					area = NULL_AREA;
				}
				
				dist += 100.0;
			}
			
			TeleportEntity(client, spawnPos);
		}
		
	}
	
	float physVel[3];
	GetPhysVelocity(rollerMine, physVel);
	RemoveEntity(rollerMine);
	CBaseEntity(client).SetAbsVelocity(physVel);
}

public bool TraceFilter_RollerMineEnd(int entity, int mask, int client)
{
	if (EntIndexToEntRef(entity) == g_iPlayerRollerMine[client])
		return false;
		
	return TraceFilter_SpawnCheck(entity, mask, GetEntTeam(client));
}

public MRESReturn DHook_RollerMineSolidMask(int entity, DHookReturn returnVal)
{
	returnVal.Value = MASK_PLAYERSOLID;
	return MRES_Supercede;
}

public MRESReturn DHook_RollerMinePhysics(int entity, DHookParam params)
{
	int hitEntity = params.GetObjectVar(2, 108, ObjectValueType_CBaseEntityPtr);
	if (hitEntity == 0)
	{
		float nextGroundCheckTime[MAX_EDICTS];
		if (GetTickedTime() >= nextGroundCheckTime[entity] && !(CBaseEntity(entity).GetFlags() & FL_ONGROUND))
		{
			// check directly below us for solid ground - we don't want to allow climbing walls
			float pos[3];
			GetEntPos(entity, pos);
			pos[2] -= 10.0;
			float mins[3] = {-4.0, -4.0, -16.0};
			float maxs[3] = {4.0, 4.0, 16.0};
			TR_TraceHullFilter(pos, pos, mins, maxs, MASK_PLAYERSOLID, TraceFilter_WallsOnly);
			if (TR_DidHit() || TR_PointOutsideWorld(pos))
			{
				CBaseEntity(entity).AddFlag(FL_ONGROUND);
				nextGroundCheckTime[entity] = GetTickedTime()+0.3;
			}
		}
	}
	
	return MRES_Ignored;
}

public bool TraceFilter_RollerMine(int entity, int mask, int self)
{
	if (entity == self || !IsValidClient(entity) && !IsNPC(entity))
		return false;
	
	if (GetEntTeam(self) == GetEntTeam(entity))
		return false;
	
	return true;
}

public void Timer_EndRingBonus(Handle timer)
{
	g_bRingCashBonus = false;
}

public void Timer_FusRoDah(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)) || !IsPlayerAlive(client))
		return;
	
	float range = GetItemMod(ItemStrange_Dragonborn, 0);
	int team = GetClientTeam(client);
	float eyePos[3], targetPos[3], angles[3], vel[3];
	GetClientEyePosition(client, eyePos);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) == team)
			continue;
		
		if (DistBetween(client, i) <= range)
		{
			RF_TakeDamage(i, client, client, GetItemMod(ItemStrange_Dragonborn, 1), DMG_PREVENT_PHYSICS_FORCE, ItemStrange_Dragonborn, _, {99999.0, 99999.0, 99999.0});
			GetEntPos(i, targetPos);
			GetVectorAnglesTwoPoints(eyePos, targetPos, angles);
			GetAngleVectors(angles, vel, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(vel, vel);
			ScaleVector(vel, GetItemMod(ItemStrange_Dragonborn, 2));
			vel[2] = FloatAbs(vel[2]*2.0);
			TF2_AddCondition(i, TFCond_AirCurrent, 5.0);
			TeleportEntity(i, _, _, {0.0, 0.0, 0.0});
			TeleportEntity(i, _, _, vel);
		}
	}
	
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "tf_projectile*")) != INVALID_ENT)
	{
		if (GetEntTeam(entity) != team && DistBetween(client, entity) <= range*1.25)
		{
			GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
			ScaleVector(vel, -2.0);
			TeleportEntity(entity, _, _, vel);
			SetEntityOwner(entity, client);
			SetEntTeam(entity, team);
		}
	}
	
	entity = MaxClients+1;
	RF2_Projectile_Base proj;
	while ((entity = FindEntityByClassname(entity, "rf2_projectile*")) != INVALID_ENT)
	{
		if (GetEntTeam(entity) != team && DistBetween(client, entity) <= range*1.25)
		{
			GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
			ScaleVector(vel, -2.0);
			ApplyAbsVelocityImpulse(entity, vel);
			proj = RF2_Projectile_Base(entity);
			if (proj.Homing)
			{
				proj.HomingTarget = proj.Owner;
			}
			
			proj.Owner = client;
			proj.DamageOwner = true;
			proj.Team = team;
		}
	}
	
	EmitSoundToAll(SND_DRAGONBORN2, client);
	eyePos[2] -= 8.0;
	TE_TFParticle("mvm_soldier_shockwave", eyePos);
	UTIL_ScreenShake(eyePos, 10.0, 30.0, 3.0, 1000.0, SHAKE_START, true);
}

public Action Timer_ReloadBuffEnd(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return Plugin_Stop;
	
	g_flPlayerReloadBuffDuration[client] -= 0.1;
	if (g_flPlayerReloadBuffDuration[client] <= 0.0)
		return Plugin_Stop;
	
	return Plugin_Continue;
}

float GetPlayerEquipmentItemCooldown(int client)
{
	int item = GetPlayerEquipmentItem(client);
	if (!IsEquipmentItem(item))
		return 0.0;
	
	float cooldown = fmax(g_flEquipmentItemMinCooldown[item], g_flEquipmentItemCooldown[item] * CalcItemMod_Reciprocal(client, Item_DeusSpecs, 0));
	bool cooldownActive = g_flPlayerEquipmentItemCooldown[client] > 0.0;
	if (cooldownActive)
	{
		float remainingCooldown = cooldown - g_flPlayerEquipmentItemCooldown[client];
		cooldown -= remainingCooldown;
	}
	
	return cooldown;
}

public Action Timer_EquipmentCooldown(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || !g_bGracePeriod && !IsPlayerAlive(client))
		return Plugin_Stop;
	
	g_bPlayerEquipmentCooldownActive[client] = true;
	g_flPlayerEquipmentItemCooldown[client] -= 0.1;
	if (g_flPlayerEquipmentItemCooldown[client] <= 0.0)
	{
		g_flPlayerEquipmentItemCooldown[client] = 0.0;
		int maxCharges = RoundToFloor(CalcItemMod(client, Item_BatteryCanteens, 1, 1));
		
		if (g_iPlayerEquipmentItemCharges[client] < maxCharges)
		{
			g_iPlayerEquipmentItemCharges[client]++;
			if (g_iPlayerEquipmentItemCharges[client] < maxCharges) // still lower? start cooldown again
			{
				g_flPlayerEquipmentItemCooldown[client] = GetPlayerEquipmentItemCooldown(client);
			}
			else
			{
				g_bPlayerEquipmentCooldownActive[client] = false;
				return Plugin_Stop;
			}
		}
		else
		{
			g_bPlayerEquipmentCooldownActive[client] = false;
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

void FireLaser(int attacker, int item=Item_Null, const float pos[3], const float angles[3], bool infiniteRange=true, 
	const float endPos[3]=NULL_VECTOR, float damage, int damageFlags, float size, int colors[4], const char[] particleAttach="", 
	bool particle=true, bool playSound=true, float life=0.4, float friendlyFireMult=0.0)
{
	RayType type;
	float vec[3], end[3];
	if (infiniteRange)
	{
		type = RayType_Infinite;
		vec = angles;
	}
	else
	{
		type = RayType_EndPoint;
		vec = endPos;
	}
	
	TR_TraceRayFilter(pos, vec, MASK_PLAYERSOLID_BRUSHONLY, type, TraceFilter_WallsOnly);
	TR_GetEndPosition(end);
	TE_SetupBeamPoints(pos, end, g_iBeamModel, 0, 0, 0, life, size, size, 0, 2.0, colors, 8);
	TE_SendToAll();

	if (playSound)
		EmitSoundToAll(SND_LASER, attacker);
	
	if (particle)
	{
		if (particleAttach[0])
		{
			TE_TFParticle("drg_manmelter_impact", pos, attacker, PATTACH_POINT, particleAttach);
		}
		else
		{
			TE_TFParticle("drg_manmelter_impact", pos);
		}
	}
	
	// hitbox
	float mins[3], maxs[3];
	mins[0] = -size; mins[1] = -size; mins[2] = -size;
	maxs[0] = size; maxs[1] = size; maxs[2] = size;
	maxs[0] += GetVectorDistance(pos, end);
	RF2_CustomHitbox hitbox = RF2_CustomHitbox.Create(attacker);
	hitbox.Damage = damage;
	hitbox.DamageFlags = damageFlags;
	hitbox.ItemProc = item;
	hitbox.FriendlyFireMult = friendlyFireMult;
	hitbox.SetMins(mins);
	hitbox.SetMaxs(maxs);
	hitbox.Teleport(pos, angles);
	hitbox.Spawn();
	hitbox.DoDamage();
}

public bool TraceFilter_BeamHitbox(int entity, int mask, int self)
{
	if (entity == self)
		return false;
	
	if (IsValidClient(entity) || IsBuilding(entity) || IsNPC(entity))
	{
		g_bLaserHitDetected[entity] = true;
	}
	
	return false;
}

int GetQualityColorTag(int quality, char[] buffer, int size)
{
	int cells;
	switch (quality)
	{
		case Quality_Normal: cells = strcopy(buffer, size, "{normal}");
		case Quality_Genuine: cells = strcopy(buffer, size, "{genuine}");
		case Quality_Unusual: cells = strcopy(buffer, size, "{unusual}");
		case Quality_Collectors: cells = strcopy(buffer, size, "{collectors}");
		case Quality_Strange: cells = strcopy(buffer, size, "{strange}");
		case Quality_Haunted, Quality_HauntedStrange: cells = strcopy(buffer, size, "{haunted}");
	}
	
	return cells;
}

int GetQualityName(int quality, char[] buffer, int size)
{
	int cells;
	switch (quality)
	{
		case Quality_Normal: cells = strcopy(buffer, size, "Normal");
		case Quality_Genuine: cells = strcopy(buffer, size, "Genuine");
		case Quality_Unusual: cells = strcopy(buffer, size, "Unusual");
		case Quality_Collectors: cells = strcopy(buffer, size, "Collectors");
		case Quality_Strange: cells = strcopy(buffer, size, "Strange");
		case Quality_Haunted, Quality_HauntedStrange: cells = strcopy(buffer, size, "Haunted");
		case Quality_Community: cells = strcopy(buffer, size, "Community");
	}
	
	return cells;
}

int GetActualItemQuality(int quality)
{
	switch (quality)
	{
		case Quality_Normal: return TF2Quality_Normal;
		case Quality_Genuine: return TF2Quality_Genuine;
		case Quality_Unusual: return TF2Quality_Unusual;
		case Quality_Collectors: return TF2Quality_Collectors;
		case Quality_Strange: return TF2Quality_Strange;
		case Quality_Haunted, Quality_HauntedStrange: return TF2Quality_Haunted;
		case Quality_Community: return TF2Quality_Community;
	}
	
	return TF2Quality_Normal;
}

int GetItemName(int item, char[] buffer, int size, bool includeEffect=true)
{
	int cells;
	if (includeEffect && GetItemQuality(item) == Quality_Unusual)
	{
		cells = FormatEx(buffer, size, "%s %s", g_szItemUnusualEffectName[item], g_szItemName[item]);
	}
	else
	{
		cells = strcopy(buffer, size, g_szItemName[item]);
	}
	
	return cells;
}

int GetItemQuality(int item)
{
	return g_iItemQuality[item];
}

float GetItemMod(int item, int slot)
{
	return g_flItemModifier[item][slot];
}

int GetItemModInt(int item, int slot)
{
	return RoundToFloor(g_flItemModifier[item][slot]);
}

/*
int GetItemModInt(int item, int slot)
{
	return RoundToFloor(g_flItemModifier[item][slot]);
}
*/

/*
bool GetItemModBool(int item, int slot)
{
	return asBool((GetItemModInt(item, slot)));
}
*/

int GetPlayerItemCount(int client, int item, bool allowMinions=false, bool allowDead=false)
{
	if (!allowMinions && IsPlayerMinion(client) || !allowDead && !IsPlayerAlive(client))
		return 0;
	
	return g_iPlayerItem[client][item];
}

int GetPlayerEquipmentItem(int client)
{
	return g_iPlayerEquipmentItem[client];
}

float CalcItemMod(int client, int item, int slot, int extraAmount=0, bool allowMinions=false)
{
	int count = g_iPlayerItem[client][item]+extraAmount;
	if (!allowMinions && IsPlayerMinion(client) || !IsPlayerAlive(client))
		count = 0;
	
	return g_flItemModifier[item][slot] * float(count);
}

float CalcItemMod_Hyperbolic(int client, int item, int slot, int extraAmount=0, bool allowMinions=false)
{
	int count = g_iPlayerItem[client][item]+extraAmount;
	if (!allowMinions && IsPlayerMinion(client) || !IsPlayerAlive(client))
		count = 0;
	
	return 1.0 - 1.0 / (1.0 + g_flItemModifier[item][slot] * float(count));
}

float CalcItemMod_Reciprocal(int client, int item, int slot, int extraAmount=0, bool allowMinions=false)
{
	int count = g_iPlayerItem[client][item]+extraAmount;
	if (!allowMinions && IsPlayerMinion(client) || !IsPlayerAlive(client))
		count = 0;
	
	return 1.0 / (1.0 + g_flItemModifier[item][slot] * float(count));
}

int CalcItemModInt(int client, int item, int slot, int extraAmount=0, bool allowMinions=false)
{
	int count = g_iPlayerItem[client][item]+extraAmount;
	if (!allowMinions && IsPlayerMinion(client) || !IsPlayerAlive(client))
		count = 0;

	return RoundToFloor(g_flItemModifier[item][slot] * float(count));
}

/*
int CalcItemModInt_Hyperbolic(int client, int item, int slot, int extraAmount=0)
{
	return RoundToFloor(1.0 - 1.0 / (1.0 + g_flItemModifier[item][slot] * float(g_iPlayerItem[client][item]+extraAmount)));
}
*/

/*
int CalcItemModInt_Reciprocal(int client, int item, int slot, int extraAmount=0)
{
	return RoundToFloor(1.0 / (1.0 + g_flItemModifier[item][slot] * float(g_iPlayerItem[client][item]+extraAmount)));
}
*/

float GetItemProcCoeff(int item)
{
	return g_flItemProcCoeff[item];
}

ArrayList GetPlayerItemList(int client, int max=0, bool shuffle=false)
{
	ArrayList items = new ArrayList();
	for (int i = 1; i < GetTotalItems(); i++)
	{
		if (GetItemQuality(i) == Quality_Community)
			continue;
		
		if (g_iPlayerItem[client][i] > 0 || GetPlayerEquipmentItem(client) == i)
		{
			if (GetItemQuality(i) == Quality_Strange || GetItemQuality(i) == Quality_HauntedStrange)
			{
				items.Push(i);
			}
			else
			{
				for (int a = 1; a <= g_iPlayerItem[client][i]; a++)
				{
					items.Push(i);
				}
			}
			
			if (shuffle)
			{
				items.SwapAt(items.Length-1, GetRandomInt(0, items.Length-1));
			}
		}
	}
	
	if (max > 0 && items.Length > max)
		items.Resize(max);
	
	return items;
}

// Returns a list of items sorted by quality
ArrayList GetSortedItemList(bool poolOnly=true, bool allowMetals=true, 
	bool allowCommunity=false, bool byPriority=false,
	bool allowLogExcluded=true)
{
	ArrayList items = new ArrayList();
	for (int i = 1; i < GetTotalItems(); i++)
	{
		if (!allowLogExcluded && g_bItemExcludeFromLog[i])
			continue;

		if (!g_bItemForceShowInInventory[i])
		{
			if (poolOnly && !g_bItemInDropPool[i] 
				&& !IsScrapItem(i) && (!allowCommunity || GetItemQuality(i) != Quality_Community))
				continue;

			if (!allowMetals && IsScrapItem(i))
				continue;
		}
		
		items.Push(i);
	}
	
	if (byPriority)
	{
		items.SortCustom(SortItemListByEquipPriority);
	}
	else
	{
		items.SortCustom(SortItemList);
	}
	
	return items;
}

public int SortItemList(int index1, int index2, ArrayList array, Handle hndl)
{
	int item1 = array.Get(index1);
	int item2 = array.Get(index2);
	
	if (IsScrapItem(item1) && !IsScrapItem(item2))
	{
		return -1;
	}
	else if (IsScrapItem(item2) && !IsScrapItem(item1))
	{
		return 1;
	}
	
	int quality1 = GetItemQuality(item1);
	int quality2 = GetItemQuality(item2);
	
	if (quality1 == Quality_Community)
		return 1;
	if (quality2 == Quality_Community)
		return -1;
	
	if (quality1 > quality2)
		return 1;
	if (quality1 < quality2)
		return -1;
	
	if (quality1 == Quality_Collectors && quality2 == Quality_Collectors)
	{
		int classIndex1 = GetClassMenuIndex(GetCollectorItemClass(item1));
		int classIndex2 = GetClassMenuIndex(GetCollectorItemClass(item2));
		if (classIndex1 > classIndex2)
			return 1;
		if (classIndex1 < classIndex2)
			return -1;
	}
	
	static char name1[128], name2[128];
	GetItemName(item1, name1, sizeof(name1), false);
	GetItemName(item2, name2, sizeof(name2), false);
	return strcmp(name1, name2);
}

public int SortItemListByEquipPriority(int index1, int index2, ArrayList array, Handle hndl)
{
	int item1 = array.Get(index1);
	int item2 = array.Get(index2);
	
	if (IsScrapItem(item1) && !IsScrapItem(item2))
	{
		return -1;
	}
	else if (IsScrapItem(item2) && !IsScrapItem(item1))
	{
		return 1;
	}
	
	int quality1 = GetItemQuality(item1);
	int quality2 = GetItemQuality(item2);
	
	if (quality1 == Quality_Community)
		return 1;
	if (quality2 == Quality_Community)
		return -1;
	
	if (GetQualityEquipPriority(quality1) < GetQualityEquipPriority(quality2))
		return 1;
	if (GetQualityEquipPriority(quality2) < GetQualityEquipPriority(quality1))
		return -1;
	
	if (quality1 == Quality_Collectors && quality2 == Quality_Collectors)
	{
		int classIndex1 = GetClassMenuIndex(GetCollectorItemClass(item1));
		int classIndex2 = GetClassMenuIndex(GetCollectorItemClass(item2));
		if (classIndex1 > classIndex2)
			return 1;
		if (classIndex1 < classIndex2)
			return -1;
	}
	
	static char name1[128], name2[128];
	GetItemName(item1, name1, sizeof(name1), false);
	GetItemName(item2, name2, sizeof(name2), false);
	return strcmp(name1, name2);
}

bool PlayerHasItem(int client, int item, bool allowMinions=false, bool allowDead=false)
{
	if (IsEquipmentItem(item))
	{
		return (GetPlayerEquipmentItem(client) == item);
	}
	
	return (GetPlayerItemCount(client, item, allowMinions, allowDead) > 0);
}

bool IsScrapItem(int item)
{
	return item == Item_ScrapMetal || item == Item_ReclaimedMetal || item == Item_RefinedMetal || item == Item_HauntedKey;
}

bool IsEquipmentItem(int item)
{
	int quality = GetItemQuality(item);
	return quality == Quality_Strange || quality == Quality_HauntedStrange;
}

int GetTotalItems()
{
	return g_iItemCount;
}

void AddItemToLogbook(int client, int item)
{
	if (item <= Item_Null || item >= Item_MaxValid || GetItemLogSQL(client) == null || IsItemInLogbook(client, item))
	{
		return;
	}

	AddItemToSQL(client, item);
	ArrayList items = GetSortedItemList();
	int count;
	for (int i = 0; i < items.Length; i++)
	{
		if (IsItemInLogbook(client, items.Get(i)))
		{
			count++;
		}
	}

	SetAchievementProgress(client, ACHIEVEMENT_FULLITEMLOG, count);
	delete items;
}

bool IsItemInLogbook(int client, int item)
{
	if (item <= Item_Null || item >= Item_MaxValid || g_bItemExcludeFromLog[item] || GetItemLogSQL(client) == null)
	{
		return false;
	}

	return GetItemLogSQL(client).FindString(g_szItemSectionName[item]) != -1;
}

bool IsItemInLogbookCookie(int client, int item)
{
	if (item <= Item_Null || item >= Item_MaxValid || g_bItemExcludeFromLog[item] || !AreClientCookiesCached(client))
		return false;
	
	char buffer[2048], itemId[16];
	GetItemLogCookie(client, buffer, sizeof(buffer));
	FormatEx(itemId, sizeof(itemId), ";%i;", item);
	return StrContains(buffer, itemId, false) != -1;
}

#if defined _goomba_included_
public Action OnStomp(int attacker, int victim, float &damageMultiplier, float &damageBonus, float &jumpPower)
{
	if (!RF2_IsEnabled())
		return Plugin_Continue;
	
	bool canGoomba = PlayerHasItem(attacker, ItemScout_LongFallBoots) && CanUseCollectorItem(attacker, ItemScout_LongFallBoots);
	if (!canGoomba)
	{
		return Plugin_Handled;
	}
		
	if (IsInvuln(victim)) // Goombas damage through Uber by default, let's prevent that
	{
		damageMultiplier = 0.0;
		damageBonus = 0.0;
		return Plugin_Changed;
	}
	
	// Goombas by default do the victim's health in damage, let's instead give it a base damage value
	damageMultiplier = 0.0;
	damageBonus = GetItemMod(ItemScout_LongFallBoots, 0) + (1.0 + CalcItemMod(attacker, ItemScout_LongFallBoots, 1, -1));
	jumpPower = GetItemMod(ItemScout_LongFallBoots, 2) + (1.0 * CalcItemMod(attacker, ItemScout_LongFallBoots, 3, -1));
	SetEntItemProc(attacker, ItemScout_LongFallBoots);
	g_iPlayerGoombaChain[attacker]++;
	if (g_iPlayerGoombaChain[attacker] > 8)
	{
		EmitSoundToAll(SND_1UP, attacker);
		EmitSoundToAll(SND_1UP, attacker);
	}
	
	if (g_iPlayerGoombaChain[attacker] >= 15)
	{
		TriggerAchievement(attacker, ACHIEVEMENT_GOOMBACHAIN);
	}
	
	return Plugin_Changed;
}

public int OnStompPost(int attacker, int victim, float damageMultiplier, float damageBonus, float jumpPower)
{
	if (!RF2_IsEnabled())
		return 0;
	
	SetEntItemProc(attacker, Item_Null);
	return 0;
}
#endif

void DoHeadshotBonuses(int attacker, int victim, float damage)
{
	if (PlayerHasItem(attacker, ItemSniper_HolyHunter) && CanUseCollectorItem(attacker, ItemSniper_HolyHunter))
	{
		float pos[3];
		GetEntPos(victim, pos);
		pos[2] += 30.0;
		float radiusDamage = damage * GetItemMod(ItemSniper_HolyHunter, 0);
		radiusDamage *= 1.0 + CalcItemMod(attacker, ItemSniper_HolyHunter, 1, -1);
		float radius = GetItemMod(ItemSniper_HolyHunter, 2);
		radius *= 1.0 + CalcItemMod(attacker, ItemSniper_HolyHunter, 3, -1);
		DoRadiusDamage(attacker, attacker, pos, ItemSniper_HolyHunter, radiusDamage, DMG_BLAST, radius);
		DoExplosionEffect(pos);
	}
	
	if (PlayerHasItem(attacker, ItemSniper_VillainsVeil) && CanUseCollectorItem(attacker, ItemSniper_VillainsVeil))
	{
		float time = GetItemMod(ItemSniper_VillainsVeil, 2);
		g_flPlayerRifleHeadshotBonusTime[attacker] = GetTickedTime() + time;
		UpdatePlayerFireRate(attacker);
		CreateTimer(time+0.1, Timer_UpdateFireRate, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
		TF2_AddCondition(attacker, TFCond_CritHype, time);
		int rifle = GetPlayerWeaponSlot(attacker, WeaponSlot_Primary);
		if (rifle != INVALID_ENT)
		{
			SetEntPropFloat(rifle, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
		}
	}
}

public void Timer_UpdateFireRate(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)) || !IsPlayerAlive(client))
		return;
		
	UpdatePlayerFireRate(client);
}

bool IsHauntedItem(int item)
{
	return GetItemQuality(item) == Quality_Haunted || GetItemQuality(item) == Quality_HauntedStrange;
}

int GetItemFromSectionName(const char[] name)
{
	for (int i = 1; i < GetTotalItems(); i++)
	{
		if (strcmp2(g_szItemSectionName[i], name))
		{
			return i;
		}
	}
	
	return Item_Null;
}

int GetPlayerItemsOfQuality(int client, int quality)
{
	int total;
	for (int i = 1; i < GetTotalItems(); i++)
	{
		if (PlayerHasItem(client, i, true, true) && GetItemQuality(i) == quality)
		{
			total += GetPlayerItemCount(client, i, true, true);
		}
	}
	
	return total;
}

static int g_iLastShownItem[MAXPLAYERS];
Handle g_hPlayerItemDescTimer[MAXPLAYERS];
void ShowItemDesc(int client, int item)
{
	if (g_iLastShownItem[client] == item)
		return;
	
	int quality = GetItemQuality(item);
	char qualityTag[32], itemName[128], qualityName[32];
	GetItemName(item, itemName, sizeof(itemName));
	GetQualityColorTag(quality, qualityTag, sizeof(qualityTag));
	GetQualityName(quality, qualityName, sizeof(qualityName));
	char fullString[512], partialString[200];
	int chars = FormatEx(fullString, sizeof(fullString), "%s (%s)\n%s", g_szItemName[item], qualityName, g_szItemDesc[item]);
	bool split;
	if (chars >= 248)
	{
		split = true;
		strcopy(partialString, sizeof(partialString), fullString);
		ReplaceStringEx(fullString, sizeof(fullString), partialString, "-");
		PrintKeyHintText(client, "%s-", partialString);
		DataPack pack = new DataPack();
		CreateDataTimer(9.0, Timer_SecondDesc, pack, TIMER_FLAG_NO_MAPCHANGE);
		g_iLastShownItem[client] = item;
		pack.WriteCell(GetClientUserId(client));
		pack.WriteCell(item);
		pack.WriteString(fullString);
	}
	else
	{
		PrintKeyHintText(client, fullString);
	}
	
	g_bPlayerViewingItemDesc[client] = true;
	if (g_hPlayerItemDescTimer[client])
	{
		delete g_hPlayerItemDescTimer[client];
	}
	
	g_hPlayerItemDescTimer[client] = CreateTimer(split ? 17.0 : 13.0, Timer_PlayerViewingItemDesc, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public void Timer_SecondDesc(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if (!client)
		return;
	
	int item = pack.ReadCell();
	if (g_iLastShownItem[client] != item)
		return;
	
	char buffer[200];
	pack.ReadString(buffer, sizeof(buffer));
	PrintKeyHintText(client, buffer);
	g_iLastShownItem[client] = Item_Null;
}

public void Timer_PlayerViewingItemDesc(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return;
	
	g_hPlayerItemDescTimer[client] = null;
	g_bPlayerViewingItemDesc[client] = false;
}
