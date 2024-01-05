#if defined _RF2_items_included
 #endinput
#endif
#define _RF2_items_included

#pragma semicolon 1
#pragma newdecls required

#define MAX_UNUSUAL_EFFECTS 64

int g_iItemCount;
int g_iBeamModel;

int g_iPlayerItem[MAXTF2PLAYERS][MAX_ITEMS];
int g_iPlayerEquipmentItem[MAXTF2PLAYERS];
int g_iItemSchemaIndex[MAX_ITEMS] = {-1, ...};
int g_iItemQuality[MAX_ITEMS] = {Quality_None, ...};
int g_iCollectorItemClass[MAX_ITEMS];

float g_flItemModifier[MAX_ITEMS][MAX_ITEM_MODIFIERS];
float g_flEquipmentItemCooldown[MAX_ITEMS] = {40.0, ...};
float g_flItemSpriteScale[MAX_ITEMS] = {1.0, ...};

char g_szItemName[MAX_ITEMS][MAX_NAME_LENGTH];
char g_szItemDesc[MAX_ITEMS][512];
char g_szItemDescHint[MAX_ITEMS][512];
char g_szItemUnusualEffectName[MAX_ITEMS][MAX_NAME_LENGTH];

bool g_bItemInDropPool[MAX_ITEMS];
bool g_bLaserHitDetected[MAX_EDICTS];

// Unusual effects
int g_iUnusualEffectCount;
int g_iItemUnusualEffect[MAX_ITEMS] = {-1, ...};
int g_iItemSpriteUnusualEffect[MAX_ITEMS] = {-1, ...};
int g_iUnusualEffectType[MAX_UNUSUAL_EFFECTS]; // Unusual effects have IDs for use with the attribute

char g_szUnusualEffectName[MAX_UNUSUAL_EFFECTS][MAX_NAME_LENGTH];
char g_szUnusualEffectDisplayName[MAX_UNUSUAL_EFFECTS][MAX_NAME_LENGTH];
char g_szItemEquipRegion[MAX_ITEMS][64];
char g_szItemSprite[MAX_ITEMS][PLATFORM_MAX_PATH];

void LoadItems()
{
	KeyValues effectKey = CreateKeyValues("");
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, ItemConfig);
	if (!effectKey.ImportFromFile(config))
	{
		delete effectKey;
		ThrowError("File %s does not exist", config);
	}
	
	// Do our unusual effects first so we have them when we load the items
	g_iUnusualEffectCount = 0;
	char buffer[64], split[16];
	effectKey.GetSectionName(buffer, sizeof(buffer));
	
	if (strcmp2(buffer, "items"))
	{
		effectKey.GotoNextKey();
	}
	
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
	
	// Now items
	g_iItemCount = 0;
	int item;
	KeyValues itemKey = CreateKeyValues("");
	itemKey.ImportFromFile(config);
	itemKey.GetSectionName(buffer, sizeof(buffer));
	
	bool error;
	// don't assume the position of the effects tree
	if (strcmp2(buffer, "effects", false))
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
	
	for (int i = 0; i < Item_MaxValid; i++)
	{
		if (i == 0 && itemKey.GotoFirstSubKey() || itemKey.GotoNextKey())
		{	
			// This value will correspond to the item's index in the plugin so we know what the item does.
			item = itemKey.GetNum("item_type", Item_Null);
			itemKey.GetString("name", g_szItemName[item], sizeof(g_szItemName[]), "Unnamed Item");

			itemKey.GetString("desc", g_szItemDesc[item], sizeof(g_szItemDesc[]), "(No description found...)");
			itemKey.GetString("desc_hint", g_szItemDescHint[item], sizeof(g_szItemDescHint[]), g_szItemDesc[item]);
			CRemoveTags(g_szItemDescHint[item], sizeof(g_szItemDescHint[]));
			char dummy[1];
			dummy[0] = 10;
			ReplaceString(g_szItemDescHint[item], sizeof(g_szItemDescHint[]), "\\n", dummy, false);
			
			itemKey.GetString("equip_regions", g_szItemEquipRegion[item], sizeof(g_szItemEquipRegion[]), "none");
			itemKey.GetString("sprite", g_szItemSprite[item], sizeof(g_szItemSprite[]), MAT_DEBUGEMPTY);
			g_bItemInDropPool[item] = asBool(itemKey.GetNum("in_item_pool", true));
			
			if (FileExists(g_szItemSprite[item], true))
			{
				PrecacheModel(g_szItemSprite[item]);
				AddMaterialToDownloadsTable(g_szItemSprite[item]);
			}
			else
			{
				LogError("[LoadItems] Bad item sprite for item %i (%s: %s)", item, g_szItemName[item], g_szItemSprite[item]);
			}
			
			// The effect of item modifiers are arbitrary, and depend on the item. Some may not use them at all.
			for (int n = 0; n < MAX_ITEM_MODIFIERS; n++)
			{
				FormatEx(buffer, sizeof(buffer), "item_modifier_%i", n+1);
				g_flItemModifier[item][n] = itemKey.GetFloat(buffer, 0.1);
			}
			
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
				case Quality_Strange, Quality_HauntedStrange: g_flEquipmentItemCooldown[item] = itemKey.GetFloat("strange_cooldown", 40.0);
			}
			
			g_iItemCount++;
		}
		else
		{
			break;
		}
	}
	
	PrintToServer("[RF2] Items loaded: %i", g_iItemCount);
	delete itemKey;
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
	ArrayList array = CreateArray();
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
	
	for (int i = 1; i <= GetTotalItems(); i++)
	{
		if (!g_bItemInDropPool[i] || GetItemQuality(i) == Quality_Collectors)
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
	ArrayList array = CreateArray();
	int item;
	
	for (int i = 1; i <= GetTotalItems(); i++)
	{
		if (!g_bItemInDropPool[i])
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
	ArrayList array = CreateArray();
	int item;
	
	for (int i = 0; i <= GetTotalItems(); i++)
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

int SpawnItem(int index, const float pos[3], int spawner=-1, float ownTime=0.0)
{
	int item = CreateEntityByName("rf2_item");
	if (!IsValidEntity(item))
	{
		return -1;
	}
	
	SetEntProp(item, Prop_Data, "m_iIndex", index);
	SetEntPropEnt(item, Prop_Data, "m_hOriginalItemOwner", spawner);
	TeleportEntity(item, pos);
	DispatchSpawn(item);
	
	if (IsValidClient(spawner)) // We spawned this item, so we own it unless we don't pick it up, assuming we don't want it.
	{
		SetEntPropEnt(item, Prop_Data, "m_hItemOwner", spawner);
		if (ownTime > 0.0)
		{
			CreateTimer(ownTime, Timer_ClearItemOwner, EntIndexToEntRef(item), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	int quality = GetItemQuality(index);
	switch (quality)
	{
		case Quality_Genuine:		SetEntityRenderColor(item, 125, 255, 125);
		case Quality_Unusual: 		SetEntityRenderColor(item, 200, 125, 255);
		case Quality_Strange:		SetEntityRenderColor(item, 200, 150, 0);
		case Quality_Collectors:	SetEntityRenderColor(item, 255, 100, 100);
		case Quality_Haunted, 
			Quality_HauntedStrange:	SetEntityRenderColor(item, 125, 255, 255);
	}
	
	if (quality == Quality_Unusual && g_iItemSpriteUnusualEffect[index] >= 0)
	{
		float effectPos[3];
		CopyVectors(pos, effectPos);
		effectPos[2] += 25.0;
		TE_TFParticle(g_szUnusualEffectName[g_iItemSpriteUnusualEffect[index]], effectPos, item, PATTACH_ABSORIGIN);
	}

	return item;
}

public Action Timer_ClearItemOwner(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE)
		return Plugin_Continue;
		
	SetEntPropEnt(entity, Prop_Data, "m_hItemOwner", -1);
	SetEntPropEnt(entity, Prop_Data, "m_hSubject", -1);
	return Plugin_Continue;
}

// negative values are accepted for amount
void GiveItem(int client, int item, int amount=1, bool addToLogbook=false)
{
	if (IsEquipmentItem(item))
	{
		int strangeItem = GetPlayerEquipmentItem(client);
		
		if (strangeItem > Item_Null && IsPlayerSurvivor(client))
		{
			float pos[3];
			GetEntPos(client, pos);
			pos[2] += 30.0;
			DropItem(client, strangeItem, pos, _, 6.0);
		}
		
		g_iPlayerEquipmentItem[client] = item;
	}
	else
	{
		g_iPlayerItem[client][item] += amount;
		
		if (GetPlayerItemCount(client, item) < 0)
		{
			g_iPlayerItem[client][item] = 0;
		}
	}
	
	if (addToLogbook)
	{
		AddItemToLogbook(client, item);	
	}

	UpdatePlayerItem(client, item);
}

// Subject is who we're dropping the item for, or -1 if we don't care
bool DropItem(int client, int item, float pos[3], int subject=-1, float ownTime=0.0)
{
	if (GetPlayerItemCount(client, item) <= 0 && !IsEquipmentItem(item))
		return false;
	
	if (IsEquipmentItem(item) && GetPlayerEquipmentItem(client) != item)
		return false;
	
	int entity = SpawnItem(item, pos, client);
	SetEntProp(entity, Prop_Data, "m_bDropped", true);
	
	if (subject > 0)
	{
		// Only the dropper or the one we dropped the item for can pick this up.
		SetEntPropEnt(entity, Prop_Data, "m_hSubject", subject);
		if (subject != client)
		{
			PrintHintText(subject, "%t", "DroppedItemForYou", client, g_szItemName[item]);
		}
	}
	
	if (ownTime > 0.0) // If we own this item but the owner/subject takes too long to pick it up, it's free for taking
	{
		CreateTimer(ownTime, Timer_ClearItemOwner, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		SetEntPropEnt(entity, Prop_Data, "m_hItemOwner", -1);
	}
	
	if (IsEquipmentItem(item))
	{
		g_iPlayerEquipmentItem[client] = Item_Null;
	}
	else
	{
		g_iPlayerItem[client][item]--;
	}
	
	UpdatePlayerItem(client, item);
	if (IsPlayerSurvivor(client) && GetItemQuality(item) != Quality_Strange)
	{
		int index = RF2_GetSurvivorIndex(client);
		if (g_iItemsTaken[index] > 0)
			g_iItemsTaken[index]--;
	}
	
	return true;
}

bool PickupItem(int client)
{
	if (g_bItemPickupCooldown[client])
		return false;
	
	const float range = 90.0;
	
	float eyePos[3], endPos[3], eyeAng[3], direction[3];
	GetClientEyePosition(client, eyePos);
	CopyVectors(eyePos, endPos);
	
	GetClientEyeAngles(client, eyeAng);
	GetAngleVectors(eyeAng, direction, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(direction, direction);
	
	endPos[0] += direction[0] * range;
	endPos[1] += direction[1] * range;
	endPos[2] += direction[2] * range;
	
	TR_TraceRayFilter(eyePos, endPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceFilter_DontHitSelf, client);
	TR_GetEndPosition(endPos);
	
	int item = GetNearestEntity(endPos, "rf2_item");
	if (item == -1)
	{
		return false;
	}

	float pos[3];
	GetEntPos(item, pos);
	
	if (GetVectorDistance(pos, endPos, true) <= sq(range))
	{
		bool itemShare = g_cvItemShareEnabled.BoolValue;
		int index = RF2_GetSurvivorIndex(client);
		int itemIndex = GetEntProp(item, Prop_Data, "m_iIndex");
		int spawner = GetEntPropEnt(item, Prop_Data, "m_hItemOwner");
		int subject = GetEntPropEnt(item, Prop_Data, "m_hSubject");
		int originalSpawner = GetEntPropEnt(item, Prop_Data, "m_hOriginalItemOwner");
		bool dropped = asBool(GetEntProp(item, Prop_Data, "m_bDropped"));
		int quality = GetItemQuality(itemIndex);
		
		// Strange items do not count towards the limit.
		if (itemShare && g_iItemLimit[index] > 0 && !IsEquipmentItem(itemIndex) && subject != client
		&& ((spawner == client || originalSpawner == client) || !IsValidClient(spawner) || !IsPlayerSurvivor(spawner)) && g_iItemsTaken[index] >= g_iItemLimit[index])
		{
			EmitSoundToClient(client, SND_NOPE);
			PrintCenterText(client, "%t", "ItemShareLimit", g_iItemLimit[index]);
			return true;
		}
		
		if (IsValidClient(spawner) && IsPlayerSurvivor(spawner) 
			&& client != spawner && client != subject)
		{
			EmitSoundToClient(client, SND_NOPE);
			PrintCenterText(client, "%t", "NotForYou");
			return true;
		}

		if (quality == Quality_Collectors)
		{
			g_bPlayerTookCollectorItem[client] = true;
		}
		
		GiveItem(client, itemIndex, _, true);
		RemoveEntity(item);
		char qualityTag[32], itemName[128], qualityName[32];
		GetItemName(itemIndex, itemName, sizeof(itemName));
		GetQualityColorTag(quality, qualityTag, sizeof(qualityTag));
		GetQualityName(quality, qualityName, sizeof(qualityName));
		PrintKeyHintText(client, "%s (%s)\n%s", g_szItemName[itemIndex], qualityName, g_szItemDescHint[itemIndex]);

		if (IsEquipmentItem(itemIndex))
		{
			RF2_PrintToChatAll("%t", "PickupItemStrange", client, qualityTag, itemName);
		}
		else
		{
			RF2_PrintToChatAll("%t", "PickupItem", client, qualityTag, itemName, GetPlayerItemCount(client, itemIndex));
		}
		
		//RF2_PrintToChat(client, "%s%s{default}: %s", qualityTag, itemName, g_szItemDesc[itemIndex]);
		EmitSoundToAll(SND_ITEM_PICKUP, client);
		
		if (!dropped || spawner == client || originalSpawner == client)
		{
			if (!dropped)
				g_iTotalItemsFound++;
			
			if (!IsEquipmentItem(itemIndex))
			{
				g_iItemsTaken[index]++;
				
				// Notify our player that they've reached their limit.
				if (itemShare && g_iItemLimit[index] > 0 && g_iItemsTaken[index] >= g_iItemLimit[index])
				{
					PrintCenterText(client, "%t", "ItemShareLimit", g_iItemLimit[index]);
				}
			}
		}
		
		if (g_bPlayerAutomaticItemMenu[client] || g_bPlayerViewingItemMenu[client])
		{
			ShowItemMenu(client);
		}
		
		if (!GetClientCookieInt(client, g_coTutorialItemPickup))
		{
			PrintKeyHintText(client, "%t", "ItemPickupTutorial2");
			SetClientCookie(client, g_coTutorialItemPickup, "1");
		}
		
		g_bItemPickupCooldown[client] = true;
		CreateTimer(0.2, Timer_ItemPickupCooldown, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		return true;
	}
	
	return false;
}

public Action Timer_ItemPickupCooldown(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;

	g_bItemPickupCooldown[client] = false;
	return Plugin_Continue;
}

int EquipItemAsWearable(int client, int item)
{
	if (GetItemQuality(item) == Quality_Collectors && !CanUseCollectorItem(client, item))
		return -1;
	
	if (GetPlayerWearableCount(client, true) >= MAX_ITEMS && GetItemQuality(item) != Quality_Strange)
		return -1;
	
	if (HasItemAsWearable(client, item))
		return -1;
	
	int wearable = -1;
	int entity = MaxClients+1;
	int index;
	bool valid = true;
	bool breakLoop;
	
	while ((entity = FindEntityByClassname(entity, "tf_wearable")) != -1)
	{
		if (!g_bItemWearable[entity] || GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != client)
			continue;
		
		index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		
		for (int i = 1; i <= GetTotalItems(); i++)
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
		
		SetEntProp(wearable, Prop_Send, "m_bValidatedAttachedEntity", true);
		
		entity = MaxClients+1;
		while ((entity = FindEntityByClassname(entity, "tf_wearable")) != -1)
		{
			// Remove one loadout wearable
			if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client && !g_bDontRemoveWearable[entity] && !g_bItemWearable[entity])
			{
				TF2_RemoveWearable(client, entity);
				break;
			}
		}
	}
	
	return wearable;
}

bool HasItemAsWearable(int client, int item)
{
	int entity;
	
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
	int entity, index;
	
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
		case Quality_Haunted: return 2;
		case Quality_Collectors: return 3;
		case Quality_Unusual: return 4;
		case Quality_Strange, Quality_HauntedStrange: return 5;
	}
	
	return -1;
}

void UpdatePlayerItem(int client, int item)
{
	switch (item)
	{
		case Item_PrideScarf, Item_ClassCrown:
		{
			CalculatePlayerMaxHealth(client);
		}
		case Item_RoundedRifleman, Item_WhaleBoneCharm, Item_PrinnyPouch:
		{
			float amount;
			if (item == Item_RoundedRifleman || item == Item_PrinnyPouch)
			{
				amount = CalcItemMod_HyperbolicInverted(client, item, 0);
			}
			else
			{
				amount = 1.0 + CalcItemMod(client, Item_WhaleBoneCharm, 0);
			}
			
			int weapon, ammoType;
			TFClassType class = TF2_GetPlayerClass(client);
			
			for (int i = WeaponSlot_Primary; i <= WeaponSlot_InvisWatch; i++)
			{
				weapon = GetPlayerWeaponSlot(client, i);
				if (weapon <= 0)
					continue;
					
				if (item == Item_PrinnyPouch)
				{
					if (class == TFClass_Spy && i == WeaponSlot_InvisWatch)
					{
						TF2Attrib_SetByDefIndex(weapon, 35, amount); // "mult cloak meter regen rate"
					}
				}
				else
				{
					ammoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType"); // we may not need to waste an attribute slot here
					
					if (ammoType != TFAmmoType_None && ammoType < TFAmmoType_Metal && GetEntProp(weapon, Prop_Send, "m_iClip1") >= 0)
					{
						if (item == Item_RoundedRifleman)
						{
							TF2Attrib_SetByDefIndex(weapon, 548, amount); // "halloween reload time decreased"
						}
						else if (item == Item_WhaleBoneCharm)
						{
							TF2Attrib_SetByDefIndex(weapon, 424, amount); // "clip size penalty HIDDEN"
						}
					}
				}
			}
			
			int wearable = MaxClients+1;
			if (class == TFClass_DemoMan)
			{
				while ((wearable = FindEntityByClassname(wearable, "tf_wearable_demoshield")) != -1)
				{
					if (GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity") != client)
						continue;
					
					// This attribute is a regular percentage, yet attribute 278 is an inverted percentage. Okay Valve, whatever you say.
					TF2Attrib_SetByDefIndex(wearable, 249, 1.0+CalcItemMod(client, Item_PrinnyPouch, 0)); // "charge recharge rate increased"
					break;
				}
			}
			else if (class == TFClass_Sniper)
			{
				while ((wearable = FindEntityByClassname(wearable, "tf_wearable_razorback")) != -1)
				{
					if (GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity") != client)
						continue;
					
					TF2Attrib_SetByDefIndex(wearable, 278, amount); // "effect bar recharge rate increased"
					break;
				}
			}
		}
		case Item_RobinWalkers:
		{
			CalculatePlayerMaxSpeed(client);
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
				TF2Attrib_SetByDefIndex(client, 326, jumpHeightAmount); // "increased jump height"
				TF2Attrib_SetByDefIndex(client, 610, airControlAmount); // "increased air control"
			}
			else
			{
				TF2Attrib_RemoveByDefIndex(client, 326);
				TF2Attrib_RemoveByDefIndex(client, 610);
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
		}
		case Item_UFO:
		{
			if (PlayerHasItem(client, Item_UFO))
			{
				SetEntityGravity(client, CalcItemMod_HyperbolicInverted(client, Item_UFO, 0));
				
				float pushForce = 1.0 + CalcItemMod_Hyperbolic(client, Item_UFO, 1);
				TF2Attrib_SetByDefIndex(client, 329, pushForce); // "airblast vulnerability multiplier"
				TF2Attrib_SetByDefIndex(client, 525, pushForce); // "damage force increase"
			}
			else
			{
				SetEntityGravity(client, 1.0);
				TF2Attrib_RemoveByDefIndex(client, 329);
				TF2Attrib_RemoveByDefIndex(client, 525);
			}
		}
		case ItemEngi_Teddy:
		{
			if (CanUseCollectorItem(client, ItemEngi_Teddy))
			{
				int wrench = GetPlayerWeaponSlot(client, WeaponSlot_Melee);
				if (wrench > 0)
				{
					if (PlayerHasItem(client, ItemEngi_Teddy))
					{
						float firingSpeed = CalcItemMod_HyperbolicInverted(client, item, 0);
						float constructRate = 1.0 + CalcItemMod(client, item, 1);
						TF2Attrib_SetByDefIndex(wrench, 343, firingSpeed); // "engy sentry fire rate increased"
						TF2Attrib_SetByDefIndex(wrench, 92, constructRate); // "Construction rate increased"
					}
					else
					{
						TF2Attrib_RemoveByDefIndex(wrench, 343);
						TF2Attrib_RemoveByDefIndex(wrench, 92);
					}
				}
			}
		}
		case ItemMedic_BlightedBeak, ItemMedic_ProcedureMask:
		{
			int medigun = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
			if (medigun > 0)
			{
				if (item == ItemMedic_BlightedBeak && PlayerHasItem(client, item) && CanUseCollectorItem(client, item))
				{
					/*
					float attrUberRate, attrUberDuration;
					Address attrib;
					if ((attrib = TF2Attrib_GetByDefIndex(medigun, 9)) != Address_Null)
					{
						attrUberRate = TF2Attrib_GetValue(attrib);
					}
					
					if ((attrib = TF2Attrib_GetByDefIndex(medigun, 314)) != Address_Null)
					{
						attrUberDuration = TF2Attrib_GetValue(attrib);
					}
					*/
					
					float uberRate = 1.0 + CalcItemMod(client, item, 0);
					float uberDuration = CalcItemMod(client, item, 1);
					TF2Attrib_SetByDefIndex(medigun, 10, uberRate); // "ubercharge rate bonus"
					TF2Attrib_SetByDefIndex(medigun, 314, uberDuration); // "uber duration bonus"
				}
				else if (item == ItemMedic_ProcedureMask && PlayerHasItem(client, item) && CanUseCollectorItem(client, item))
				{
					float healRateBonus = 1.0 + CalcItemMod(client, item, 0);
					float overhealBonus = 1.0 + CalcItemMod(client, item, 1);
					TF2Attrib_SetByDefIndex(medigun, 493, healRateBonus); // "healing mastery"
					TF2Attrib_SetByDefIndex(medigun, 11, overhealBonus); // "overheal bonus"
				}
				else
				{
					if (item == ItemMedic_BlightedBeak)
					{
						TF2Attrib_RemoveByDefIndex(medigun, 9);
						TF2Attrib_RemoveByDefIndex(medigun, 314);
					}
					else if (item == ItemMedic_ProcedureMask)
					{
						TF2Attrib_RemoveByDefIndex(medigun, 493);
						TF2Attrib_RemoveByDefIndex(medigun, 11);
					}
				}
			}
		}
		case ItemHeavy_ToughGuyToque:
		{
			if (CanUseCollectorItem(client, ItemHeavy_ToughGuyToque))
			{
				int minigun = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
				if (minigun > 0)
				{
					if (PlayerHasItem(client, ItemHeavy_ToughGuyToque))
					{
						float count = CalcItemMod(client, ItemHeavy_ToughGuyToque, 0);
						{
							TF2Attrib_SetByDefIndex(minigun, 323, count); // "attack projectiles"
						}
					}
					else
					{
						TF2Attrib_RemoveByDefIndex(minigun, 323);
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
				int maxCharges = RoundToFloor(CalcItemMod(client, Item_BatteryCanteens, 1, 1));
				if (g_iPlayerEquipmentItemCharges[client] < maxCharges)
				{
					g_flPlayerEquipmentItemCooldown[client] = GetPlayerEquipmentItemCooldown(client);
					g_bEquipmentCooldownActive[client] = true;
					CreateTimer(0.1, Timer_EquipmentCooldown, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		case Item_Marxman:
		{
			if (PlayerHasItem(client, Item_Marxman))
			{
				float amount = CalcItemMod_HyperbolicInverted(client, Item_Marxman, 0);
				TF2Attrib_SetByDefIndex(client, 178, amount); // "deploy time decreased"
				
				// These classes don't have weapons that benefit from accuracy bonuses (at least afaik)
				TFClassType class = TF2_GetPlayerClass(client);
				if (class != TFClass_Medic && class != TFClass_DemoMan)
				{
					int primary = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
					int secondary = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
					amount = CalcItemMod_HyperbolicInverted(client, Item_Marxman, 1);
					
					if (primary > 0)
					{
						TF2Attrib_SetByDefIndex(primary, 106, amount); // "weapon spread bonus"
					}
					
					if (secondary > 0)
					{
						TF2Attrib_SetByDefIndex(secondary, 106, amount);
					}
				}
			}
			else
			{
				TF2Attrib_RemoveByDefIndex(client, 178);
				int primary = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
				int secondary = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
				if (primary > 0)
				{
					TF2Attrib_RemoveByDefIndex(primary, 106);
				}
				
				if (secondary > 0)
				{
					TF2Attrib_RemoveByDefIndex(secondary, 106);
				}
			}
		}
		case ItemSoldier_WarPig:
		{
			if (CanUseCollectorItem(client, ItemSoldier_WarPig))
			{
				int launcher = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
				if (launcher > 0)
				{
					if (PlayerHasItem(client, ItemSoldier_WarPig))
					{
						float projSpeed = 1.0 + CalcItemMod(client, ItemSoldier_WarPig, 0);
						TF2Attrib_SetByDefIndex(launcher, 103, projSpeed); // "Projectile speed increased"
					}
					else
					{
						TF2Attrib_RemoveByDefIndex(launcher, 103);
					}
				}
			}
		}
		case ItemDemo_ScotchBonnet:
		{
			if (CanUseCollectorItem(client, ItemDemo_ScotchBonnet))
			{
				int primary = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
				int secondary = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
				if (primary > 0)
				{
					if (PlayerHasItem(client, ItemDemo_ScotchBonnet))
					{
						float projSpeed = 1.0 + CalcItemMod(client, ItemDemo_ScotchBonnet, 0);
						TF2Attrib_SetByDefIndex(primary, 103, projSpeed); // "Projectile speed increased"
					}
					else
					{
						TF2Attrib_RemoveByDefIndex(primary, 103);
					}
				}
				
				if (secondary > 0)
				{
					if (PlayerHasItem(client, ItemDemo_ScotchBonnet))
					{
						float chargeRate = CalcItemMod_HyperbolicInverted(client, ItemDemo_ScotchBonnet, 1);
						TF2Attrib_SetByDefIndex(secondary, 670, chargeRate); // "stickybomb charge rate"
					}
					else
					{
						TF2Attrib_RemoveByDefIndex(secondary, 670);
					}
				}
			}
		}
	}
	
	if (!PlayerHasItem(client, item) && !IsEquipmentItem(item) || IsEquipmentItem(item) && GetPlayerEquipmentItem(client) != item)
	{
		RemoveItemAsWearable(client, item); // Remove the wearable if we don't have the item anymore.
		
		// Try and see if we can find another wearable to equip
		int qualityPriority = GetQualityEquipPriority(GetItemQuality(item));
		while (qualityPriority >= 0)
		{
			for (int i = 1; i <= GetTotalItems(); i++)
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
	
	if (IsPlayerSurvivor(client))
	{
		// update for spectators
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || IsPlayerAlive(i))
				continue;
			
			if (GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") == client)
				ShowItemMenu(i, client);
		}
	}
}

// If the result of GetRandomInt(min, max) is below or equal to goal, returns true. Factors in luck stat from client.
bool RandChanceIntEx(int client, int min, int max, int goal, int &result=0)
{
	int random, badRolls;
	int rollTimes = 1 + GetPlayerLuckStat(client);
	bool success;
	
	if (rollTimes < 0)
	{
		// We are unlucky. Roll once. To succeed, we must roll as many successful rolls as we have bad rolls.
		badRolls = rollTimes * -1;
		rollTimes = 1;
	}
	
	for (int i = 1; i <= rollTimes; i++)
	{
		if ((random = GetRandomInt(min, max)) <= goal)
		{
			if (badRolls <= 0) // If we have no bad rolls, we are successful.
			{
				success = true;
				break;
			}
			else // We have a bad roll. Decrement and try again for a bad result.
			{
				badRolls--;
				i = 0;
			}
		}
	}
	
	result = random;
	return success;
}

// If the result of GetRandomFloat(min, max) is below or equal to goal, returns true. Factors in luck stat from client.
bool RandChanceFloatEx(int client, float min, float max, float goal, float &result=0.0)
{
	float random;
	int rollTimes = 1 + GetPlayerLuckStat(client);
	int badRolls;
	bool success;
	
	if (rollTimes < 0)
	{
		// We are unlucky. Roll once. To succeed, we must roll as many successful rolls as we have bad rolls.
		badRolls = rollTimes * -1;
		rollTimes = 1;
	}
	
	for (int i = 1; i <= rollTimes; i++)
	{
		if ((random = GetRandomFloat(min, max)) <= goal)
		{
			if (badRolls <= 0) // If we have no bad rolls, we are successful.
			{
				success = true;
				break;
			}
			else // We have a bad roll. Decrement and try again for a bad result.
			{
				badRolls--;
				i = 0;
			}
		}
	}
	
	result = random;
	return success;
}

void DoItemDeathEffects(int attacker, int victim, int damageType=DMG_GENERIC, CritType critType)
{
	if (damageType & DMG_MELEE)
	{
		if (PlayerHasItem(attacker, Item_SaxtonHat))
		{
			if (critType == CritType_Crit)
			{
				// Must be done a frame later to prevent bugs with player_death event
				DataPack pack = CreateDataPack();
				pack.WriteCell(attacker);
				pack.WriteCell(victim);
				RequestFrame(RF_SaxtonRadiusDamage, pack);
			}
		}
		
		if (PlayerHasItem(attacker, Item_Goalkeeper))
		{
			float chance = CalcItemMod_Hyperbolic(attacker, Item_Goalkeeper, 0);
			if (RandChanceFloatEx(attacker, 0.0, 1.0, chance))
			{
				TF2_AddCondition(attacker, TFCond_CritOnKill, GetItemMod(Item_Goalkeeper, 1));
			}
		}
	}
	
	if (PlayerHasItem(attacker, Item_KillerExclusive) && GetPlayerEquipmentItem(attacker) > Item_Null)
	{
		g_flPlayerEquipmentItemCooldown[attacker] -= CalcItemMod(attacker, Item_KillerExclusive, 0);
		g_flPlayerEquipmentItemCooldown[attacker] = fmax(g_flPlayerEquipmentItemCooldown[attacker], 0.0);
	}
	
	if (PlayerHasItem(attacker, Item_Executioner) && critType == CritType_Crit)
	{
		float radius = GetItemMod(Item_Executioner, 2);
		float bleedTime = CalcItemMod(attacker, Item_Executioner, 3);
		float victimPos[3], enemyPos[3];
		GetEntPos(victim, victimPos);
		victimPos[2] += 30.0;
		
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
				TF2_MakeBleed(i, attacker, bleedTime);
			}
		}
	}
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
	DoRadiusDamage(attacker, attacker, Item_SaxtonHat, victimPos, damage, DMG_BLAST, 180.0, _, 0.6, true);
}

bool ActivateStrangeItem(int client)
{
	if (g_iPlayerEquipmentItemCharges[client] <= 0)
		return false;
	
	if (GetPercentInvisible(client) > 0.0)
		return false;
	
	switch (GetPlayerEquipmentItem(client))
	{
		case ItemStrange_RoBro:
		{
			// This messes with things like banners and phlog. We can at least restore the client's old rage value after.
			float oldRage = GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
			DataPack pack;
			CreateDataTimer(GetItemMod(ItemStrange_RoBro, 0)+0.1, Timer_RestoreRage, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(GetClientUserId(client));
			pack.WriteCell(GetClientTeam(client));
			pack.WriteFloat(oldRage);
			
			int shield = CreateEntityByName("entity_medigun_shield");
			SetEntityOwner(shield, client);
			SetEntProp(shield, Prop_Send, "m_iTeamNum", GetClientTeam(client));
			SetEntPropFloat(client, Prop_Send, "m_flRageMeter", GetItemMod(ItemStrange_RoBro, 0)*10.0);
			SetEntProp(client, Prop_Send, "m_bRageDraining", true);
			
			DispatchKeyValueInt(shield, "skin", GetEntProp(client, Prop_Data, "m_iTeamNum")-2);
			SetEntityModel(shield, MODEL_MEDISHIELD);
			DispatchSpawn(shield);
			EmitSoundToAll(SND_MEDISHIELD, shield);
		}

		case ItemStrange_HeartOfGold:
		{
			const float range = 250.0;
			int team = GetClientTeam(client);
			
			// Heal me and teammates around me
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != team)
					continue;
				
				if (client != i && DistBetween(client, i) > range)
					continue;
				
				int maxHealth = RF2_GetCalculatedMaxHealth(i);
				int heal = RoundToFloor(maxHealth * GetItemMod(ItemStrange_HeartOfGold, 0));
				HealPlayer(i, heal, true);
			}
			
			EmitSoundToAll(SND_SPELL_OVERHEAL, client);
		}
		
		case ItemStrange_Spellbook:
		{
			char spellType[64], response[64], sound[PLATFORM_MAX_PATH];
			bool projectileArc;
			
			// This item may cast a spell beneficial to the user, or backfire and harm them instead.
			if (RandChanceIntEx(client, 1, 8, 7))
			{
				int luck = GetPlayerLuckStat(client);
				
				switch (GetRandomInt(1 + imin(luck, 18), 18))
				{
					case 1, 2, 3:
					{
						spellType = "tf_projectile_spellfireball";
						sound = SND_SPELL_FIREBALL;
						
						// TLK_PLAYER_CAST_FIREBALL doesn't work for some reason. This is better than nothing.
						response = "TLK_PLAYER_CAST_MERASMUS_ZAP";
					}
					case 4, 5, 6:
					{
						spellType = "tf_projectile_spellbats";
						sound = SND_SPELL_BATS;
						response = "TLK_PLAYER_CAST_MERASMUS_ZAP";
						projectileArc = true;
					}
					case 7, 8, 9:
					{
						spellType = "BlastJump";
						sound = SND_SPELL_JUMP;
						response = "TLK_PLAYER_CAST_BLAST_JUMP";
					}
					case 10, 11, 12:
					{
						spellType = "Overheal";
						sound = SND_SPELL_OVERHEAL;
						response = "TLK_PLAYER_CAST_SELF_HEAL";
					}
					case 13, 14, 15:
					{
						spellType = "Stealth";
						sound = SND_SPELL_STEALTH;
						response = "TLK_PLAYER_CAST_STEALTH";
					}
					case 16:
					{
						spellType = "tf_projectile_spellmeteorshower";
						sound = SND_SPELL_METEOR;
						response = "TLK_PLAYER_CAST_METEOR_SWARM";
						projectileArc = true;
					}
					case 17:
					{
						spellType = "tf_projectile_spellspawnboss";
						response = "TLK_PLAYER_CAST_MONOCULOUS";
					}
					case 18:
					{
						spellType = "tf_projectile_lightningorb";
						sound = SND_SPELL_LIGHTNING;
						response = "TLK_PLAYER_CAST_LIGHTNING_BALL";
					}
				}
				
				float eyePos[3], eyeAng[3];
				GetClientEyePosition(client, eyePos);
				GetClientEyeAngles(client, eyeAng);
				float speed = 1100.0;
				if (strcmp2(spellType, "tf_projectile_lightningorb"))
				{
					speed = 500.0;
				}
				
				float arc;
				if (projectileArc)
					arc = -15.0;
				
				// Try shooting our projectile. If it's an invalid entity, we have a non-projectile spell.
				int entity = ShootProjectile(client, spellType, eyePos, eyeAng, speed, _, arc);
				
				if (!IsValidEntity(entity))
				{
					if (strcmp2(spellType, "BlastJump"))
					{
						float velocity[3];
						GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);
						if (velocity[2] < 600.0)
						{
							velocity[2] = 600.0 * 1.5;
						}
						else
						{
							velocity[2] *= 1.5;
						}
	
						TeleportEntity(client, _, _, velocity);
					}
					else if (strcmp2(spellType, "Overheal"))
					{
						TF2_AddCondition(client, TFCond_HalloweenQuickHeal, 3.0);
						TF2_AddCondition(client, TFCond_UberchargedOnTakeDamage, 1.0);
					}
					else if (strcmp2(spellType, "Stealth"))
					{
						TF2_AddCondition(client, TFCond_Stealthed, 8.0);
					}
				}
				
				if (TF2_GetClientTeam(client) == TFTeam_Red)
				{
					TE_TFParticle("spell_cast_wheel_red", NULL_VECTOR, client, PATTACH_ABSORIGIN_FOLLOW);
				}
				else
				{
					TE_TFParticle("spell_cast_wheel_blue", NULL_VECTOR, client, PATTACH_ABSORIGIN_FOLLOW);
				}
				
				if (sound[0])
				{
					EmitSoundToAll(sound, client);
				}
				
				if (response[0])
				{
					SpeakResponseConcept(client, response);
				}
			}
			else // Backfire!
			{
				switch (GetRandomInt(1, 4))
				{
					case 1: // BURN!
					{
						TF2_IgnitePlayer(client, client, 10.0);
					}
					case 2: // "Bloody piss..."
					{
						TF2_MakeBleed(client, client, 5.0);
						TF2_AddCondition(client, TFCond_Jarated, 10.0, client);
					}
					case 3: // Admin slaps.
					{
						SlapPlayer(client, 1);
						SlapPlayer(client, 1);
						SlapPlayer(client, 67);
					}
					case 4:
					{
						if (GetRandomInt(1, 100) == 1)
						{
							// Dance, dance, DANCE!!!
							float eyePos[3];
							GetClientEyePosition(client, eyePos);
							StartThrillerDance(eyePos);
						}
						else // Just a stun, then.
						{
							TF2_StunPlayer(client, 4.0, _, TF_STUNFLAGS_GHOSTSCARE, client);
						}
					}
				}
			}
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
			GetItemMod(ItemStrange_VirtualViewfinder, 0), DMG_SONIC|DMG_PREVENT_PHYSICS_FORCE, 25.0, colors, "partyhat");
		}
		
		case ItemStrange_NastyNorsemann:
		{
			if (TF2_IsPlayerInCondition(client, TFCond_HasRune))
			{
				EmitSoundToClient(client, SND_NOPE);
				PrintCenterText(client, "%t", "AlreadyHasRune");
				return false;
			}
			
			char sound[PLATFORM_MAX_PATH];
			TFCond rune = TF2_GetRandomMannpowerRune(sound, sizeof(sound));
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
			TF2_AddCondition(client, TFCond_StealthedUserBuffFade, GetItemMod(ItemStrange_DarkHunter, 0));
		}
		
		case ItemStrange_LegendaryLid:
		{
			float pos[3], angles[3];
			GetClientEyePosition(client, pos);
			GetClientEyeAngles(client, angles);
			
			ShootProjectile(client, "rf2_projectile_shuriken", pos, angles, 
				GetItemMod(ItemStrange_LegendaryLid, 2), GetItemMod(ItemStrange_LegendaryLid, 0), -2.0);
			
			angles[1] += 10.0;
			ShootProjectile(client, "rf2_projectile_shuriken", pos, angles, 
				GetItemMod(ItemStrange_LegendaryLid, 2), GetItemMod(ItemStrange_LegendaryLid, 0), -2.0);
			
			angles[1] -= 20.0;
			ShootProjectile(client, "rf2_projectile_shuriken", pos, angles, 
				GetItemMod(ItemStrange_LegendaryLid, 2), GetItemMod(ItemStrange_LegendaryLid, 0), -2.0);
			
			ClientPlayGesture(client, "ACT_MP_THROW");
			EmitSoundToAll(SND_THROW, client);
		}
		
		case ItemStrange_CroneDome:
		{
			float pos[3], angles[3];
			GetClientEyePosition(client, pos);
			GetClientEyeAngles(client, angles);
			
			ShootProjectile(client, "rf2_projectile_bomb", pos, angles, 
				GetItemMod(ItemStrange_CroneDome, 3), GetItemMod(ItemStrange_CroneDome, 1), -2.0);
			
			ClientPlayGesture(client, "ACT_MP_THROW");
			EmitSoundToAll(SND_THROW, client);
		}
		
		case ItemStrange_HandsomeDevil:
		{
			float pos[3], angles[3];
			GetClientEyePosition(client, pos);
			GetClientEyeAngles(client, angles);
			
			ShootProjectile(client, "rf2_projectile_kunai", pos, angles, 
				GetItemMod(ItemStrange_HandsomeDevil, 2), GetItemMod(ItemStrange_HandsomeDevil, 0), -2.0);
			
			ClientPlayGesture(client, "ACT_MP_THROW");
			EmitSoundToAll(SND_THROW, client);
		}
	}
	
	// Don't go on cooldown if our charges are above the limit; we likely dropped some battery canteens
	int maxCharges = RoundToFloor(CalcItemMod(client, Item_BatteryCanteens, 1, 1));
	if (g_iPlayerEquipmentItemCharges[client] <= maxCharges)
	{
		if (g_flPlayerEquipmentItemCooldown[client] <= 0.0)
		{
			g_bEquipmentCooldownActive[client] = true;
			CreateTimer(0.1, Timer_EquipmentCooldown, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		
		g_flPlayerEquipmentItemCooldown[client] = GetPlayerEquipmentItemCooldown(client);
	}
	
	if (PlayerHasItem(client, Item_SaintMark))
	{
		float buff = GetItemMod(Item_SaintMark, 0);
		float duration = GetItemMod(Item_SaintMark, 1) + CalcItemMod(client, Item_SaintMark, 2, -1);
		if (g_flPlayerReloadBuffDuration[client] <= 0.0)
		{
			int primary = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
			int secondary = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
			
			if (primary > 0)
			{
				TF2Attrib_SetByDefIndex(primary, 318, buff); // "faster reload rate"
			}
			
			if (secondary > 0)
			{
				TF2Attrib_SetByDefIndex(secondary, 318, buff);
			}
			
			g_flPlayerReloadBuffDuration[client] = duration;
			CreateTimer(0.1, Timer_ReloadBuffEnd, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			g_flPlayerReloadBuffDuration[client] = duration;
		}
	}
	
	g_iPlayerEquipmentItemCharges[client]--;
	return true;
}

public Action Timer_ReloadBuffEnd(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return Plugin_Stop;
	
	g_flPlayerReloadBuffDuration[client] -= 0.1;
	if (g_flPlayerReloadBuffDuration[client] <= 0.0)
	{
		int primary = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
		int secondary = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
		
		if (primary > 0)
		{
			TF2Attrib_RemoveByDefIndex(primary, 318);
		}
		
		if (secondary > 0)
		{
			TF2Attrib_RemoveByDefIndex(secondary, 318);
		}
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

float GetPlayerEquipmentItemCooldown(int client)
{
	int item = GetPlayerEquipmentItem(client);
	if (!IsEquipmentItem(item))
		return 0.0;
	
	float cooldown = g_flEquipmentItemCooldown[item] * CalcItemMod_HyperbolicInverted(client, Item_BatteryCanteens, 0);
	if (IsPlayerSurvivor(client) && IsArtifactActive(REDArtifact_Efficiency))
	{
		cooldown *= 0.25;
	}
	
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
	if ((client = GetClientOfUserId(client)) == 0 || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	g_bEquipmentCooldownActive[client] = true;
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
				g_bEquipmentCooldownActive[client] = false;
				return Plugin_Stop;
			}
		}
		else
		{
			g_bEquipmentCooldownActive[client] = false;
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

void FireLaser(int attacker, int item=Item_Null, const float pos[3], const float angles[3], bool infiniteRange=true, 
const float endPos[3]=NULL_VECTOR, float damage, int damageFlags, float size, int colors[4], const char[] particleAttach="")
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
	
	Handle trace = TR_TraceRayFilterEx(pos, vec, MASK_PLAYERSOLID_BRUSHONLY, type, TraceFilter_WallsOnly);
	TR_GetEndPosition(end, trace);
	delete trace;
	
	TE_SetupBeamPoints(pos, end, g_iBeamModel, 0, 0, 0, 0.4, size, size, 0, 2.0, colors, 8);
	TE_SendToAll();
	EmitSoundToAll(SND_LASER, attacker);
	
	if (particleAttach[0])
	{
		TE_TFParticle("drg_manmelter_impact", pos, attacker, PATTACH_POINT, particleAttach);
	}
	else
	{
		TE_TFParticle("drg_manmelter_impact", pos);
	}
	
	
	// hitbox
	float mins[3], maxs[3];
	mins[0] = -size; mins[1] = -size; mins[2] = -size;
	maxs[0] = size; maxs[1] = size; maxs[2] = size;
	trace = TR_TraceHullFilterEx(pos, end, mins, maxs, MASK_PLAYERSOLID_BRUSHONLY, TraceFilter_BeamHitbox, attacker);
	
	int team = GetEntProp(attacker, Prop_Data, "m_iTeamNum");
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		if (entity > 0 && g_bLaserHitDetected[entity])
		{
			g_bLaserHitDetected[entity] = false;
			
			if (GetEntProp(entity, Prop_Data, "m_iTeamNum") == team)
				continue;
			
			if (item > Item_Null && IsValidClient(attacker))
			{
				SetEntItemDamageProc(attacker, item);
			}
			
			SDKHooks_TakeDamage(entity, attacker, attacker, damage, damageFlags);
		}
	}
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

void StartThrillerDance(const float pos[3])
{
	g_bThrillerActive = true;
	
	float spawnPos[3];
	CNavArea area = GetSpawnPoint(pos, spawnPos, 300.0, 1400.0, -1, false);
	if (!area)
	{
		GetWorldCenter(spawnPos);
	}
	
	int merasmus = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(merasmus, "model", MODEL_MERASMUS);
	DispatchKeyValue(merasmus, "DefaultAnim", "Stand_MELEE");
	TeleportEntity(merasmus, spawnPos);
	DispatchSpawn(merasmus);
	AcceptEntityInput(merasmus, "DisableCollision");
	
	EmitAmbientSound(SND_MERASMUS_APPEAR, spawnPos, _, SNDLEVEL_TRAIN);
	TE_TFParticle("merasmus_spawn", spawnPos);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		SetVariantInt(1);
		AcceptEntityInput(i, "SetForcedTauntCam");
		TF2_AddCondition(i, TFCond_HalloweenThriller);
	}
	
	StopMusicTrackAll();
	FindConVar("nb_stop").SetInt(1);
	CreateTimer(2.0, Timer_HalloweenThriller, merasmus, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_HalloweenThriller(Handle timer, int merasmus)
{
	switch (g_iThrillerRepeatCount)
	{
		case 1, 3:
		{
			if (g_iThrillerRepeatCount == 1)
			{
				switch (GetRandomInt(1, 3))
				{
					case 1: EmitSoundToAll(SND_MERASMUS_DANCE1);
					case 2: EmitSoundToAll(SND_MERASMUS_DANCE2);
					case 3: EmitSoundToAll(SND_MERASMUS_DANCE3);
				}
			}
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || !IsPlayerAlive(i))
					continue;
				
				FakeClientCommand(i, "taunt");
			}
			
			SetVariantString("taunt06");
			AcceptEntityInput(merasmus, "SetAnimation");
		}
		case 5:
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i))
					continue;
				
				if (IsPlayerAlive(i))
				{
					TF2_RemoveCondition(i, TFCond_HalloweenThriller);
				}
				
				SetVariantInt(0);
				AcceptEntityInput(i, "SetForcedTauntCam");
			}
			
			float pos[3];
			GetEntPos(merasmus, pos);
			EmitAmbientSound(SND_MERASMUS_DISAPPEAR, pos, _, SNDLEVEL_TRAIN);
			TE_TFParticle("merasmus_spawn", pos);
			
			RemoveEntity(merasmus);
			FindConVar("nb_stop").SetInt(0);
			
			PlayMusicTrackAll();
			g_bThrillerActive = false;
			g_iThrillerRepeatCount = 0;
			return Plugin_Stop;
		}
	}
	
	g_iThrillerRepeatCount++;
	return Plugin_Continue;
}

public Action Timer_RestoreRage(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	int team = pack.ReadCell();
	
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != team)
		return Plugin_Continue;
	
	SetEntProp(client, Prop_Send, "m_bRageDraining", false);
	SetEntPropFloat(client, Prop_Send, "m_flRageMeter", pack.ReadFloat());
	return Plugin_Continue;
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

int GetPlayerItemCount(int client, int item)
{
	return g_iPlayerItem[client][item];
}

int GetPlayerEquipmentItem(int client)
{
	return g_iPlayerEquipmentItem[client];
}

float CalcItemMod(int client, int item, int slot, int extraAmount=0)
{
	return g_flItemModifier[item][slot] * float(g_iPlayerItem[client][item]+extraAmount);
}

float CalcItemMod_Hyperbolic(int client, int item, int slot, int extraAmount=0)
{
	return 1.0 - 1.0 / (1.0 + g_flItemModifier[item][slot] * float(g_iPlayerItem[client][item]+extraAmount));
}

float CalcItemMod_HyperbolicInverted(int client, int item, int slot, int extraAmount=0)
{
	return 1.0 / (1.0 + g_flItemModifier[item][slot] * float(g_iPlayerItem[client][item]+extraAmount));
}

float GetItemProcCoefficient(int item)
{
	switch (item)
	{
		//case ItemStrange_VirtualViewfinder: return 0.75;
	}
	
	return 1.0;
}

// Returns a list of items sorted by quality
ArrayList GetSortedItemList(bool poolOnly=true, bool allowMetals=true)
{
	ArrayList items = new ArrayList();
	for (int i = 1; i < Item_MaxValid; i++)
	{
		if (poolOnly && !g_bItemInDropPool[i] && !IsScrapItem(i))
			continue;
		
		if (!allowMetals && IsScrapItem(i))
			continue;
		
		items.Push(i);
	}
	
	items.SortCustom(SortItemList);
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
	
	if (quality1 == quality2)
		return 0;
	
	return quality1 > quality2 ? -1 : 1;
}

bool PlayerHasItem(int client, int item)
{
	if (IsEquipmentItem(item))
	{
		return (GetPlayerEquipmentItem(client) == item);
	}
	
	return (GetPlayerItemCount(client, item) > 0);
}

bool IsScrapItem(int item)
{
	return item == Item_ScrapMetal || item == Item_ReclaimedMetal || item == Item_RefinedMetal;
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
	if (item <= Item_Null || item >= Item_MaxValid || !AreClientCookiesCached(client) || IsItemInLogbook(client, item))
		return;
	
	char buffer[2048], itemId[16];
	GetItemLogCookie(client, buffer, sizeof(buffer));
	FormatEx(itemId, sizeof(itemId), ";%i;", item);
	if (!buffer[0])
	{
		strcopy(buffer, sizeof(buffer), itemId);
	}
	else
	{
		StrCat(buffer, sizeof(buffer), itemId);
	}
	
	SetItemLogCookie(client, buffer);
}

bool IsItemInLogbook(int client, int item)
{
	if (item <= Item_Null || item >= Item_MaxValid || !AreClientCookiesCached(client))
		return false;
	
	char buffer[2048], itemId[16];
	GetItemLogCookie(client, buffer, sizeof(buffer));
	FormatEx(itemId, sizeof(itemId), ";%i;", item);
	return StrContains(buffer, itemId, false) != -1;
}
