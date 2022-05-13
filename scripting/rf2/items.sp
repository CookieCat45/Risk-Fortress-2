#if defined _RF2_items_included
 #endinput
#endif
#define _RF2_items_included

int g_iItemCount;

int g_iPlayerItem[MAXTF2PLAYERS][MAX_ITEMS];
int g_iEntityItemIndex[MAX_EDICTS];

int g_iItemSchemaIndex[MAX_ITEMS] = {-1, ...};
RF2ItemQuality g_eItemQuality[MAX_ITEMS] = {Quality_None, ...};

char g_szItemName[MAX_ITEMS][32];
char g_szItemDesc[MAX_ITEMS][PLATFORM_MAX_PATH];
float g_flItemModifier[MAX_ITEMS];

char g_szItemEquipRegion[MAX_ITEMS][PLATFORM_MAX_PATH];
char g_szItemSprite[MAX_ITEMS][PLATFORM_MAX_PATH];
float g_flItemSpriteScale[MAX_ITEMS] = {1.0, ...};

bool g_bItemUnused[MAX_ITEMS];

bool g_bStunCooldown[MAXTF2PLAYERS] = { false, ... };

void LoadItems()
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, ItemConfig);
	if (!FileExists(config))
		SetFailState("File %s does not exist", config);
		
	Handle itemConfig = CreateKeyValues("items");
	FileToKeyValues(itemConfig, config);
	char nameBuffer[128];
	
	for (int i = 0; i < MAX_ITEMS; i++)
	{
		if (i == 0 && KvGotoFirstSubKey(itemConfig) || KvGotoNextKey(itemConfig))
		{
			KvGetString(itemConfig, "name", nameBuffer, sizeof(nameBuffer), "Unnamed Item");
			
			// This value will correspond to the item's index in the plugin so it knows what the item does.
			int item = KvGetNum(itemConfig, "item_index", view_as<int>(Item_Null));
			
			g_bItemUnused[item] = view_as<bool>(KvGetNum(itemConfig, "unused", 0));
			
			FormatEx(g_szItemName[item], PLATFORM_MAX_PATH, "%s", nameBuffer);
			KvGetString(itemConfig, "desc", g_szItemDesc[item], PLATFORM_MAX_PATH, "(No description found...)");
			KvGetString(itemConfig, "equip_regions", g_szItemEquipRegion[item], PLATFORM_MAX_PATH, "none");
			KvGetString(itemConfig, "sprite", g_szItemSprite[item], PLATFORM_MAX_PATH, DEBUGEMPTY);
			
			if (strcmp(g_szItemSprite[item], DEBUGEMPTY) == 0 || !FileExists(g_szItemSprite[item], true))
			{
				LogError("Failed to find item sprite for item_index %i (%s)\n(%s)\n", 
				item, nameBuffer, g_szItemSprite[item]);
			}
			
			// The effect of this value depends on the item
			g_flItemModifier[item] = KvGetFloat(itemConfig, "item_modifier", 1.0);
			
			g_iItemSchemaIndex[item] = KvGetNum(itemConfig, "schema_index", 5000);
			g_flItemSpriteScale[item] = KvGetFloat(itemConfig, "sprite_scale", 0.5);
			
			g_eItemQuality[item] = view_as<RF2ItemQuality>(KvGetNum(itemConfig, "quality", view_as<int>(Quality_Normal)));
			g_iItemCount++;
		}
		else
		{
			PrintToServer("[RF2] Items loaded: %i", g_iItemCount);
			break;
		}
	}
	
	delete itemConfig;
}

bool CheckEquipRegionConflict(const char[] buffer1, const char[] buffer2)
{
	if (strcmp(buffer1, "none") == 0 || strcmp(buffer2, "none") == 0)
	{
		return false;
	}
	
	char explodeBuffers[3][256];
	int count = ExplodeString(buffer1, " ; ", explodeBuffers, 3, 256);
	
	for (int i = 0; i < count; i++)
	{
		if (StrContainsEx(explodeBuffers[i], buffer2) != -1)
		{
			return true;
		}
	}
	return false;
}

int GetRandomItem(float normalChance=79.0, float genuineChance=20.0, float unusualChance=1.0, float collectorsChance=0.0, float hauntedChance=0.0, float strangeChance=0.0)
{
	RF2ItemQuality quality;
	float random = GetRandomFloat(0.0, normalChance+genuineChance+unusualChance+collectorsChance+hauntedChance+strangeChance);
	
	if (random <= normalChance)
		quality = Quality_Normal;
	else if (random <= normalChance+genuineChance)
		quality = Quality_Genuine;
	else if (random <= normalChance+genuineChance+unusualChance)
		quality = Quality_Unusual;
	else if (random <= normalChance+genuineChance+unusualChance+collectorsChance)
		quality = Quality_Collectors;
	else if (random <= normalChance+genuineChance+unusualChance+collectorsChance+hauntedChance)
		quality = Quality_Haunted;
	else if (random <= normalChance+genuineChance+unusualChance+collectorsChance+hauntedChance+strangeChance)
		quality = Quality_Strange;
		
	Handle itemArray = CreateArray(1, g_iItemCount);
	int count;
	
	for (int i = 0; i < g_iItemCount; i++)
	{
		if (g_bItemUnused[i])
			continue;
		
		if (g_eItemQuality[i] == quality)
		{
			SetArrayCell(itemArray, count, i);
			count++;
		}
	}
	ResizeArray(itemArray, count);
	
	int item;
	if (count == 0)
	{
		char buffer[32];
		GetQualityName(quality, buffer, sizeof(buffer));
		LogError("No items exist for quality %i! (%s)", quality, buffer);
	}
	else
	{
		item = GetArrayCell(itemArray, GetRandomInt(0, count-1));
	}
	
	delete itemArray;
	return item;
}

int SpawnItem(int item, float pos[3])
{
	int sprite = CreateEntityByName("env_sprite");
	g_iEntityItemIndex[sprite] = item;
	DispatchKeyValue(sprite, "model", g_szItemSprite[item]);
	
	char buffer[16];
	FloatToString(g_flItemSpriteScale[item], buffer, sizeof(buffer));
	DispatchKeyValue(sprite, "scale", buffer);
	DispatchKeyValue(sprite, "rendermode", "9");
	
	DispatchSpawn(sprite);
	TeleportEntity(sprite, pos, NULL_VECTOR, NULL_VECTOR);
	SetEntPropString(sprite, Prop_Data, "m_iName", OBJECT_ITEM);
	
	return sprite;
}

bool PickupItem(int client)
{
	float eyePos[3], endPos[3], eyeAng[3], direction[3];
	GetClientEyePosition(client, eyePos);
	CopyVectors(eyePos, endPos);
	
	GetClientEyeAngles(client, eyeAng);
	GetAngleVectors(eyeAng, direction, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(direction, direction);
	
	endPos[0] += direction[0] * 90.0;
	endPos[1] += direction[1] * 90.0;
	endPos[2] += direction[2] * 90.0;
	
	TR_TraceRayFilter(eyePos, endPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceDontHitSelf, client);
	TR_GetEndPosition(endPos);
	
	int itemSprite = GetNearestEntity(endPos, "env_sprite", OBJECT_ITEM);
	if (IsValidEntity(itemSprite))
	{
		int item = g_iEntityItemIndex[itemSprite];
		g_iPlayerItem[client][item]++;
		
		UpdatePlayerItem(client, item);
		EquipItemAsWearable(client, item);
		
		if (IsValidEntity(itemSprite))
			RemoveEntity(itemSprite);
			
		char qualityTag[32];
		GetQualityColorTag(g_eItemQuality[item], qualityTag, sizeof(qualityTag));
		RF2_PrintToChatAll("{yellow}%N{default} picked up %s%s {lightgray}[%i]", client, qualityTag, g_szItemName[item], g_iPlayerItem[client][item]);
		
		RF2_PrintToChat(client, "%s%s{default}: %s", qualityTag, g_szItemName[item], g_szItemDesc[item]);
		EmitSoundToAll(SOUND_ITEM_PICKUP, client);
		g_iTotalItemsFound++;
		
		return true;
	}
	return false;
}

void EquipItemAsWearable(int client, int item)
{
	int entity = MaxClients+1;
	int index;
	bool valid = true;
	bool breakLoop;
	
	while ((entity = FindEntityByClassname(entity, "tf_wearable")) != -1)
	{
		if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != client)
		{
			continue;
		}
		
		index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		for (int i = 0; i < g_iItemCount; i++)
		{
			if (index == g_iItemSchemaIndex[i])
			{
				if (CheckEquipRegionConflict(g_szItemEquipRegion[item], g_szItemEquipRegion[i]))
				{
					if (g_eItemQuality[item] < g_eItemQuality[i])
					{
						valid = false;
						continue;
					}
					
					TF2_RemoveWearable(client, entity);
					valid = true;
					breakLoop = true;
					break;
				}
			}
		}
		
		if (breakLoop)
			break;
	}
	
	if (valid)
	{
		int actualQuality = GetActualItemQuality(g_eItemQuality[item]);
		CreateWearable(client, "tf_wearable", g_iItemSchemaIndex[item], "", true, actualQuality, GetRandomInt(1, 9999));
	}
}

void UpdatePlayerItem(int client, int item)
{
	float itemMult = flt(g_iPlayerItem[client][item]);
	switch (item)
	{
		/*
		case Item_MaimLicense:
		{
			int weapon;
			float amount = 1.0 / (1.0 + (0.08 * itemMult));
			for (int i = 0; i <= 2; i++)
			{
				weapon = GetPlayerWeaponSlot(client, i);
				if (IsValidEntity(weapon))
				{
					TF2Attrib_SetByDefIndex(weapon, 348, amount);
				}
			}
		}
		*/
		case Item_EyeCatcher:
		{
			int weapon = GetPlayerWeaponSlot(client, WeaponSlot_Melee);
			if (IsValidEntity(weapon))
			{
				float amount = 1.0 + (g_flItemModifier[Item_EyeCatcher] * itemMult);
				TF2Attrib_SetByDefIndex(weapon, 476, amount);
			}
		}
		case Item_PrideScarf:
		{
			CalculatePlayerMaxHealth(client);
		}
		case Item_RoundedRifleman:
		{
			int weapon;
			float amount = 1.0 / (1.0 + (g_flItemModifier[Item_RoundedRifleman] * itemMult));
			for (int i = 0; i <= 1; i++)
			{
				weapon = GetPlayerWeaponSlot(client, i);
				if (IsValidEntity(weapon))
				{
					TF2Attrib_SetByDefIndex(weapon, 548, amount);
				}
			}
		}
		case Item_RobinWalkers:
		{
			CalculatePlayerMaxSpeed(client);
		}
	}
}

/*
void ItemDeathEffects(int attacker, int victim)
{
	if (g_iPlayerItem[attacker][Item_PartyHat] > 0)
	{
		float origin[3];
		GetClientAbsOrigin(victim, origin);
		
		int explosion = CreateEntityByName("env_explosion");
		float damage = 80.0;
		damage *= 1.0 + (flt(g_iPlayerItem[attacker][Item_PartyHat]-1) * 0.2);
		
		char buffer[16];
		FloatToString(damage, buffer, sizeof(buffer));
		
		DispatchKeyValue(explosion, "iMagnitude", buffer);
		DispatchKeyValue(explosion, "iRadiusOverride", "250.0");
		SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", attacker);
		SetEntProp(explosion, Prop_Send, "m_iTeamNum", GetClientTeam(attacker));
		
		TeleportEntity(explosion, origin, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(explosion);
		AcceptEntityInput(explosion, "Explode");
		TE_SetupParticle(PARTICLE_CONFETTI, origin);
		
		int randomSound = GetRandomInt(1, 5);
		switch (randomSound)
		{
			case 1: EmitSoundToAll(SOUND_PARTY1, _, _, _, _, _, _, _, origin);
			case 2: EmitSoundToAll(SOUND_PARTY2, _, _, _, _, _, _, _, origin);
			case 3: EmitSoundToAll(SOUND_PARTY3, _, _, _, _, _, _, _, origin);
			case 4: EmitSoundToAll(SOUND_PARTY4, _, _, _, _, _, _, _, origin);
			case 5: EmitSoundToAll(SOUND_PARTY5, _, _, _, _, _, _, _, origin);
		}
	}
}
*/

int GetQualityColorTag(RF2ItemQuality quality, char[] buffer, int size)
{
	int cells;
	switch (quality)
	{
		case Quality_Normal: cells = FormatEx(buffer, size, "{normal}");
		case Quality_Genuine: cells = FormatEx(buffer, size, "{genuine}");
		case Quality_Unusual: cells = FormatEx(buffer, size, "{unusual}");
		case Quality_Haunted: cells = FormatEx(buffer, size, "{haunted}");
		case Quality_Collectors: cells = FormatEx(buffer, size, "{collectors}");
		case Quality_Strange: cells = FormatEx(buffer, size, "{strange}");
	}
	return cells;
}

int GetQualityName(RF2ItemQuality quality, char[] buffer, int size)
{
	int cells;
	switch (quality)
	{
		case Quality_Normal: cells = FormatEx(buffer, size, "Normal");
		case Quality_Genuine: cells = FormatEx(buffer, size, "Genuine");
		case Quality_Unusual: cells = FormatEx(buffer, size, "Unusual");
		case Quality_Haunted: cells = FormatEx(buffer, size, "Haunted");
		case Quality_Collectors: cells = FormatEx(buffer, size, "Collectors");
		case Quality_Strange: cells = FormatEx(buffer, size, "Strange");
	}
	return cells;
}

int GetActualItemQuality(RF2ItemQuality quality)
{
	switch (quality)
	{
		case Quality_Normal: return TF2Quality_Normal;
		case Quality_Genuine: return TF2Quality_Genuine;
		case Quality_Unusual: return TF2Quality_Unusual;
		case Quality_Haunted: return TF2Quality_Haunted;
		case Quality_Collectors: return TF2Quality_Collectors;
		case Quality_Strange: return TF2Quality_Strange;
	}
	return TF2Quality_Normal;
}

int GetItemName(int item, char[] buffer, int size)
{
	int cells = FormatEx(buffer, size, "%s", g_szItemName[item]);
	return cells;
}