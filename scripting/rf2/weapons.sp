#if defined _RF2_weapons_included
 #endinput
#endif
#define _RF2_weapons_included

int g_iWeaponCount;

int g_iWeaponIndex[MAX_WEAPON_INDEXES] = {-1, ...};
char g_szWeaponDisplayName[MAX_WEAPON_INDEXES][64];
char g_szWeaponClassname[MAX_WEAPON_INDEXES][64];
char g_szWeaponAttributes[MAX_WEAPON_INDEXES][MAX_ATTRIBUTE_STRING_LENGTH];
int g_iWeaponIndexReplacement[MAX_WEAPON_INDEXES] = {-1, ...};

stock void LoadWeapons()
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, WeaponConfig);
	if (!FileExists(config))
	{
		ThrowError("File %s does not exist", config);
		RF2_PrintToChatAll("Config file %s does not exist, please correct this", config);
	}
	
	Handle weaponKey = CreateKeyValues("weapons");
	FileToKeyValues(weaponKey, config);
	char sectionName[32];
	bool firstKey = true;
	int count;
	
	for (int i = 0; i < MAX_WEAPON_INDEXES; i++)
	{
		if (firstKey ? KvGotoFirstSubKey(weaponKey) : KvGotoNextKey(weaponKey))
		{
			KvGetSectionName(weaponKey, sectionName, sizeof(sectionName));
			g_iWeaponIndex[i] = StringToInt(sectionName);
			KvGetString(weaponKey, "name", g_szWeaponDisplayName[i], 64, "Unnamed Weapon");
			KvGetString(weaponKey, "classname", g_szWeaponClassname[i], 64, "");
			KvGetString(weaponKey, "attributes", g_szWeaponAttributes[i], MAX_ATTRIBUTE_STRING_LENGTH, "");
			g_iWeaponIndexReplacement[i] = KvGetNum(weaponKey, "index", -1);
			count++;
			
			firstKey = false;
		}
	}
	
	g_iWeaponCount = count;
	PrintToServer("Weapons loaded: %i", count);
	delete weaponKey;
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int index, Handle &hItem)
{
	bool changed;
	for (int i = 0; i < g_iWeaponCount; i++)
	{
		if (g_iWeaponIndex[i] == index)
		{
			int flags;
			if (g_iWeaponIndexReplacement[i] > -1)
			{
				changed = true;
				flags |= OVERRIDE_ITEM_DEF;
			}
				
			if (g_szWeaponClassname[i][0] != '\0')
			{
				changed = true;
				flags |= OVERRIDE_CLASSNAME;
			}
				
			if (g_szWeaponAttributes[i][0] != '\0')
			{
				changed = true;
				flags |= OVERRIDE_ATTRIBUTES;
			}
			
			if (changed)
			{
				hItem = TF2Items_CreateItem(flags);
				
				if (flags & OVERRIDE_ITEM_DEF)
					TF2Items_SetItemIndex(hItem, g_iWeaponIndexReplacement[i]);
					
				if (flags & OVERRIDE_CLASSNAME)
					TF2Items_SetClassname(hItem, g_szWeaponClassname[i]);
					
				if (flags & OVERRIDE_ATTRIBUTES)
				{
					char attributes[MAX_ATTRIBUTE_STRING_LENGTH];
					FormatEx(attributes, sizeof(attributes), "%s", g_szWeaponAttributes[i]);
					
					ReplaceString(attributes, MAX_ATTRIBUTE_STRING_LENGTH, " ; ", "=");
					char attrs[32][32];
					int count = ExplodeString(attributes, "=", attrs, 32, 32);
					TF2Items_SetNumAttributes(hItem, count/2);
					
					int attSlot = 0;
					int attrib;
					float val;
					for (int n = 0; n < count; n+=2)
					{
						attrib = StringToInt(attrs[n]);
						val = StringToFloat(attrs[n+1]);
						if (attrib <= 0)
							continue;
						
						TF2Items_SetAttribute(hItem, attSlot, attrib, val);
						attSlot++;
					}
				}
				return Plugin_Changed;
			}

			break;
		}
	}
	return Plugin_Continue;
}

stock void CreateWeapon(int client, char[] classname, int index, char[] attributes = "", bool visible = true, bool wearable = false)
{
	Handle weapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(weapon, classname);
	TF2Items_SetItemIndex(weapon, index);

	// now for the attributes:
	if (attributes[0] != '\0')
	{
		ReplaceString(attributes, MAX_ATTRIBUTE_STRING_LENGTH, " ; ", "=");
		char attrs[32][32];
		int count = ExplodeString(attributes, "=", attrs, 32, 32);
		TF2Items_SetNumAttributes(weapon, count/2);
		
		int attSlot = 0;
		int attrib;
		float val;
		for (int n = 0; n < count; n+=2)
		{
			attrib = StringToInt(attrs[n]);
			val = StringToFloat(attrs[n+1]);
			if (attrib <= 0)
				continue;
			
			TF2Items_SetAttribute(weapon, attSlot, attrib, val);
			attSlot++;
		}
	}
	TF2Items_SetLevel(weapon, 69);
	TF2Items_SetQuality(weapon, 6);
	
	int wepEnt = TF2Items_GiveNamedItem(client, weapon);
	delete weapon;
	
	if (!wearable)
		EquipPlayerWeapon(client, wepEnt);
	else
		TF2_EquipWearable(client, wepEnt);
	
	if (!visible)
	{
		if (!wearable)
		{
			SetEntProp(wepEnt, Prop_Send, "m_nModelIndex", -1);
			SetEntProp(wepEnt, Prop_Send, "m_iWorldModelIndex", -1);
			SetEntPropFloat(wepEnt, Prop_Send, "m_flModelScale", 0.001);
		}
		else
		{
			SetEntityRenderMode(wepEnt, RENDER_NONE);
		}
	}
}

stock int CreateWearable(int client, char[] classname, int index, char[] attributes = "", bool visible = true)
{
	int wearable = CreateEntityByName(classname);
	if (wearable == INVALID_ENT_REFERENCE)
	{
		LogError("Tried to create a wearable for %N, but it had an invalid classname. (%s)", client, classname);
		return -1;
	}
	
	SetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex", index);
	SetEntProp(wearable, Prop_Send, "m_bInitialized", 1);
	
	SetEntProp(wearable, Prop_Send, "m_iEntityQuality", 6);
	SetEntProp(wearable, Prop_Send, "m_iEntityLevel", 69);
	
	if (attributes[0] != '\0')
	{
		ReplaceString(attributes, MAX_ATTRIBUTE_STRING_LENGTH, " ; ", "=");
		char attrs[32][32];
		int count = ExplodeString(attributes, "=", attrs, 32, 32);
		
		int attrib;
		float val;
		for (int n = 0; n < count; n+=2)
		{
			attrib = StringToInt(attrs[n]);
			val = StringToFloat(attrs[n+1]);
			if (attrib <= 0)
				continue;
			
			TF2Attrib_SetByDefIndex(wearable, attrib, val);
		}
	}
	
	if (!visible)
		SetEntityRenderMode(wearable, RENDER_NONE);
	
	DispatchSpawn(wearable);
	TF2_EquipWearable(client, wearable);
	return wearable;
}

stock void TF2_EquipWearable(int client, int entity)
{
	if (g_hSDKEquipWearable)
		SDKCall(g_hSDKEquipWearable, client, entity);
}