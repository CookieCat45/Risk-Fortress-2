#pragma semicolon 1
#pragma newdecls required

int g_iWeaponCount[TF_CLASSES];

// These are for Survivors, not enemies or bosses.
int g_iWeaponIndexReplacement[TF_CLASSES][MAX_WEAPONS];

char g_szWeaponIndexIdentifier[TF_CLASSES][MAX_WEAPONS][PLATFORM_MAX_PATH];
char g_szWeaponAttributes[TF_CLASSES][MAX_WEAPONS][MAX_ATTRIBUTE_STRING_LENGTH];
char g_szWeaponClassnameReplacement[TF_CLASSES][MAX_WEAPONS][64];

bool g_bWeaponStripAttributes[TF_CLASSES][MAX_WEAPONS];
bool g_bWeaponHasStringAttributes[TF_CLASSES][MAX_WEAPONS];
char g_szWeaponStringAttributeName[TF_CLASSES][MAX_WEAPONS][MAX_STRING_ATTRIBUTES][128];
char g_szWeaponStringAttributeValue[TF_CLASSES][MAX_WEAPONS][MAX_STRING_ATTRIBUTES][PLATFORM_MAX_PATH];

void LoadWeapons()
{
	KeyValues weaponKey = CreateKeyValues("weapons");
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, WeaponConfig);
	if (!weaponKey.ImportFromFile(config))
	{
		ThrowError("File %s does not exist", config);
	}
	
	bool firstKey = true;
	bool firstAttrib = true;
	int count, strAttribCount;
	char tfClassName[32];
	
	for (int i = 1; i < TF_CLASSES; i++)
	{
		GetClassString(view_as<TFClassType>(i), tfClassName, sizeof(tfClassName));
		
		if (weaponKey.JumpToKey(tfClassName))
		{
			// go through our weapon indexes for this class
			while (firstKey ? weaponKey.GotoFirstSubKey(false) : weaponKey.GotoNextKey(false))
			{
				weaponKey.GetSectionName(g_szWeaponIndexIdentifier[i][count], sizeof(g_szWeaponIndexIdentifier[][]));
				weaponKey.GetString("add_attributes", g_szWeaponAttributes[i][count], sizeof(g_szWeaponAttributes[][]));
				weaponKey.GetString("classname", g_szWeaponClassnameReplacement[i][count], sizeof(g_szWeaponClassnameReplacement[][]));
				g_iWeaponIndexReplacement[i][count] = weaponKey.GetNum("index", -1);
				g_bWeaponStripAttributes[i][count] = asBool(weaponKey.GetNum("strip_attributes", false));
				
				// do we have any string attributes?
				if (weaponKey.JumpToKey("string_attributes"))
				{
					while (firstAttrib ? weaponKey.GotoFirstSubKey(false) : weaponKey.GotoNextKey(false))
					{
						g_bWeaponHasStringAttributes[i][count] = true;
						weaponKey.GetSectionName(g_szWeaponStringAttributeName[i][count][strAttribCount], sizeof(g_szWeaponStringAttributeName[][][]));
						weaponKey.GetString(NULL_STRING, g_szWeaponStringAttributeValue[i][count][strAttribCount], sizeof(g_szWeaponStringAttributeValue[][][]));
						
						if (strcmp2(g_szWeaponStringAttributeName[i][count][strAttribCount], "custom projectile model"))
						{
							if (FileExists(g_szWeaponStringAttributeValue[i][count][strAttribCount], true))
							{
								AddModelToDownloadsTable(g_szWeaponStringAttributeValue[i][count][strAttribCount]);
							}
							else
							{
								g_szWeaponStringAttributeValue[i][count][strAttribCount] = MODEL_ERROR;
							}
						}
						
						strAttribCount++;
						firstAttrib = false;
					}
					
					firstAttrib = true;
					weaponKey.GoBack();
				}
				
				count++;
				firstKey = false;
			}
			
			g_iWeaponCount[i] = count;
			firstKey = true;
		}
		
		count = 0;
		weaponKey.Rewind();
	}
	
	delete weaponKey;
}

static bool g_bSetStringAttributes;
static TFClassType g_StringAttributeClass;
static int g_iStringAttributeWeapon; // Not to be confused with entity indexes
static bool g_bDisableGiveItemForward;
public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int index, Handle &item)
{
	if (!RF2_IsEnabled() || !g_bRoundActive)
		return Plugin_Continue;
	
	if (g_bDisableGiveItemForward || !IsPlayerSurvivor(client) || IsPlayerMinion(client))
		return Plugin_Continue;
	
	Action action = Plugin_Continue;
	int flags;
	TFClassType class = TF2_GetPlayerClass(client);
	char buffer[64];
	int totalAttribs;
	IntToString(index, buffer, sizeof(buffer));
	for (int i = 0; i < g_iWeaponCount[class]; i++)
	{
		if (StrContainsEx(g_szWeaponIndexIdentifier[class][i], buffer) == -1)
			continue;

		item = TF2Items_CreateItem(flags);
		TF2Items_SetClassname(item, classname);
		bool newWeapon;
		
		// Using the OVERRIDE_CLASSNAME flag in this forward does not work properly,
		// we need to do this ugly workaround by creating an entirely new weapon.
		if (g_szWeaponClassnameReplacement[class][i][0])
		{
			newWeapon = true;
			TF2Items_SetClassname(item, g_szWeaponClassnameReplacement[class][i]);
		}
		
		// strip the static attributes for this weapon?
		if (g_bWeaponStripAttributes[class][i])
		{
			flags |= OVERRIDE_ATTRIBUTES;
			action = Plugin_Changed;
			TF2Items_SetNumAttributes(item, 0);
		}
		else
		{
			action = Plugin_Changed;
			flags |= OVERRIDE_ATTRIBUTES;
			int attribArray[MAX_STATIC_ATTRIBUTES];
			float valueArray[MAX_STATIC_ATTRIBUTES];
			int count = TF2Attrib_GetStaticAttribs(index, attribArray, valueArray, MAX_STATIC_ATTRIBUTES);
			for (int n = 0; n < count; n++)
			{
				if (!IsAttributeBlacklisted(attribArray[n]) && attribArray[n] > 0)
				{
					totalAttribs++;
					if (totalAttribs < MAX_STATIC_ATTRIBUTES)
					{
						TF2Items_SetNumAttributes(item, totalAttribs);
						TF2Items_SetAttribute(item, totalAttribs-1, attribArray[n], valueArray[n]);
					}
				}
			}
		}
		
		if (g_iWeaponIndexReplacement[class][i] >= 0)
		{
			action = Plugin_Changed;
			flags |= OVERRIDE_ITEM_DEF;
			TF2Items_SetItemIndex(item, g_iWeaponIndexReplacement[class][i]);
		}
		
		if (g_szWeaponAttributes[class][i][0])
		{
			action = Plugin_Changed;
			flags |= OVERRIDE_ATTRIBUTES;
			char attributes[MAX_ATTRIBUTE_STRING_LENGTH], attrs[32][32];
			strcopy(attributes, sizeof(attributes), g_szWeaponAttributes[class][i]);
			ReplaceString(attributes, sizeof(attributes), " ; ", " = ");
			int count = ExplodeString(attributes, " = ", attrs, 32, 32, true);
			
			if (count > 0)
			{
				int attrib;
				float val;

				for (int n = 0; n <= count+1; n+=2)
				{
					attrib = StringToInt(attrs[n]);
					if (!IsAttributeBlacklisted(attrib) && attrib > 0)
					{
						val = StringToFloat(attrs[n+1]);
						totalAttribs++;
						if (totalAttribs < MAX_STATIC_ATTRIBUTES)
						{
							TF2Items_SetNumAttributes(item, totalAttribs);
							TF2Items_SetAttribute(item, totalAttribs-1, attrib, val);
						}
					}							
				}
			}
		}
		
		if (g_bWeaponHasStringAttributes[class][i])
		{
			// we'll have to set these in Post because we don't have the weapon entity yet
			g_bSetStringAttributes = true;
			g_StringAttributeClass = class;
			g_iStringAttributeWeapon = i;
		}

		if (totalAttribs > MAX_STATIC_ATTRIBUTES)
		{
			LogError("[TF2Items_OnGiveNamedItem] Item %i (%s) exceeded static attribute limit of %i", index, classname, MAX_STATIC_ATTRIBUTES);
		}
		
		if (newWeapon)
		{
			// If we aren't changing the item index, we need to set the old one
			if (!(flags & OVERRIDE_ITEM_DEF))
			{
				flags |= OVERRIDE_ITEM_DEF;
				TF2Items_SetItemIndex(item, index);
			}
			
			flags |= FORCE_GENERATION;
			TF2Items_SetFlags(item, flags);
			DataPack pack = new DataPack();
			pack.WriteCell(client);
			pack.WriteCell(item);
			RequestFrame(RF_ReplaceNewWeapon, pack);
			action = Plugin_Handled;
		}
		else
		{
			TF2Items_SetFlags(item, flags);
		}
		
		break;
	}
	
	return action;
}

public void RF_ReplaceNewWeapon(DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	Handle item = pack.ReadCell();
	delete pack;
	
	if (!item)
		return;
	
	RequestFrame(RF_ResetGiveItemBool); // just in case
	g_bDisableGiveItemForward = true;
	int weapon = TF2Items_GiveNamedItem(client, item);
	g_bDisableGiveItemForward = false;
	delete item;
	EquipPlayerWeapon(client, weapon);
}

public void RF_ResetGiveItemBool()
{
	g_bDisableGiveItemForward = false;
}

public int TF2Items_OnGiveNamedItem_Post(int client, char[] classname, int index, int level, int quality, int entity)
{
	if (!RF2_IsEnabled() || !IsValidEntity2(entity))
		return 0;
	
	if (g_bSetStringAttributes)
	{
		TFClassType class = g_StringAttributeClass;
		int weapon = g_iStringAttributeWeapon; // Not to be confused with entity indexes
		
		for (int i = 0; i < MAX_STRING_ATTRIBUTES; i++)
		{
			if (TF2Attrib_IsValidAttributeName(g_szWeaponStringAttributeName[class][weapon][i]))
			{
				// Block these attributes, they cause client crashes.
				if (strcmp2(g_szWeaponStringAttributeName[class][weapon][i], "min_viewmodel_offset") ||
				strcmp2(g_szWeaponStringAttributeName[class][weapon][i], "custom name attr") ||
				strcmp2(g_szWeaponStringAttributeName[class][weapon][i], "custom desc attr"))
				{
					LogError("Disallowing string attribute \"%s\". Setting this WILL cause clients to CRASH!", g_szWeaponStringAttributeName[class][weapon][i]);
					continue;
				}
				
				PrintToServer(g_szWeaponStringAttributeName[class][weapon][i]);
				TF2Attrib_SetFromStringValue(entity, g_szWeaponStringAttributeName[class][weapon][i], g_szWeaponStringAttributeValue[class][weapon][i]);
			}
			else
			{
				LogError("Unknown string attribute %s", g_szWeaponStringAttributeName[class][weapon][i]);
			}
		}
		
		g_bSetStringAttributes = false;
	}
	
	SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
	RequestFrame(RF_MeleeSmackHook, EntIndexToEntRef(entity));
	return 0;
}

public void RF_MeleeSmackHook(int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return;
	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (IsValidClient(client) && GetPlayerWeaponSlot(client, WeaponSlot_Melee) == entity)
	{
		g_hHookMeleeSmack.HookEntity(Hook_Pre, entity, DHook_MeleeSmack);
		g_hHookMeleeSmack.HookEntity(Hook_Post, entity, DHook_MeleeSmackPost);
	}
}

int CreateWeapon(int client, char[] classname, int index, const char[] attributes = "", bool staticAttributes=false, bool visible=true, int quality = TF2Quality_Unique)
{
	Handle weapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(weapon, classname);
	TF2Items_SetItemIndex(weapon, index);
	
	// now for the attributes:
	if (attributes[0] || staticAttributes)
	{
		char buffer[MAX_ATTRIBUTE_STRING_LENGTH];
		strcopy(buffer, sizeof(buffer), attributes);
		ReplaceString(buffer, MAX_ATTRIBUTE_STRING_LENGTH, " ; ", " = ");
		char attrs[32][32];
		int count = ExplodeString(buffer, " = ", attrs, 32, 32, true);
		
		int attribCount, attribSlot, staticAttribCount;
		bool maxAttribs;
		
		attribCount = imin(count/2, MAX_STATIC_ATTRIBUTES);
		TF2Items_SetNumAttributes(weapon, attribCount+1);
		
		if (staticAttributes)
		{
			int attribArray[MAX_STATIC_ATTRIBUTES];
			float valueArray[MAX_STATIC_ATTRIBUTES];
			staticAttribCount = TF2Attrib_GetStaticAttribs(index, attribArray, valueArray, MAX_STATIC_ATTRIBUTES);
			
			if (staticAttribCount > 0)
			{
				int totalAttribs = imin(attribCount+staticAttribCount, MAX_STATIC_ATTRIBUTES);
				TF2Items_SetNumAttributes(weapon, totalAttribs);
				
				for (int i = 0; i < staticAttribCount; i++)
				{
					if (IsAttributeBlacklisted(attribArray[i]) || attribArray[i] <= 0)
						continue;
					
					TF2Items_SetAttribute(weapon, attribSlot, attribArray[i], valueArray[i]);
					attribSlot++;
					if (attribSlot >= MAX_STATIC_ATTRIBUTES)
					{
						maxAttribs = true;
						break;
					}
				}
			}
		}
		
		if (attribCount > 0 && !maxAttribs)
		{
			int attrib;
			float val;
			for (int i = 0; i <= count+1; i+=2)
			{
				attrib = StringToInt(attrs[i]);
				if (IsAttributeBlacklisted(attrib) || attrib <= 0)
				{
					continue;
				}
				
				val = StringToFloat(attrs[i+1]);
				TF2Items_SetAttribute(weapon, attribSlot, attrib, val);
				attribSlot++;
				
				if (attribSlot >= MAX_STATIC_ATTRIBUTES)
				{
					maxAttribs = true;
					break;
				}
			}
		}
		
		if (maxAttribs) // Uh oh.
		{
			LogError("[CreateWeapon] Maximum number of static attributes reached (%i) on weapon \"%s\" index %i\n\"%s\"\nstatic attribute count = %i", MAX_ATTRIBUTES, classname, index, attributes, staticAttribCount);
		}
		
		TF2Items_SetNumAttributes(weapon, attribSlot+1);
	}
	
	TF2Items_SetLevel(weapon, 69);
	TF2Items_SetQuality(weapon, quality);
	
	int wepEnt = TF2Items_GiveNamedItem(client, weapon);
	EquipPlayerWeapon(client, wepEnt);
	delete weapon;
	
	if (!visible)
	{
		SetEntProp(wepEnt, Prop_Send, "m_nModelIndex", -1);
		SetEntProp(wepEnt, Prop_Send, "m_iWorldModelIndex", -1);
		
		for (int i = 0; i <= 3; i++)
		{
			SetEntProp(wepEnt, Prop_Send, "m_nModelIndexOverrides", -1, _, i);
		}
		
		SetEntPropFloat(wepEnt, Prop_Send, "m_flModelScale", 0.001);
	}
	
	if (strcmp2(classname, "tf_weapon_builder") && index == 28)
	{
		SetEntProp(wepEnt, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
		SetEntProp(wepEnt, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
		SetEntProp(wepEnt, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
		SetEntProp(wepEnt, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
	}
	else if (strcmp2(classname, "tf_weapon_sapper"))
	{
		SetEntProp(wepEnt, Prop_Send, "m_iObjectType", 3);
		SetEntProp(wepEnt, Prop_Data, "m_iSubType", 3);
	}
	
	SetEntProp(wepEnt, Prop_Send, "m_bValidatedAttachedEntity", true);
	return wepEnt;
}

int CreateWearable(int client, const char[] classname, int index, const char[] attributes="", bool staticAttributes=false, 
bool visible = true, const char[] model="", int quality=0, int level=0)
{
	int wearable = CreateEntityByName(classname);
	if (wearable == -1)
	{
		LogError("[CreateWearable] Tried to create a wearable for %N, but it had an invalid classname: %s", client, classname);
		return wearable;
	}
	
	SetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex", index);
	SetEntProp(wearable, Prop_Send, "m_bInitialized", true);
	
	SetEntProp(wearable, Prop_Send, "m_iEntityQuality", quality);
	SetEntProp(wearable, Prop_Send, "m_iEntityLevel", level);
	
	int totalAttribs;
	if (attributes[0])
	{
		char buffer[MAX_ATTRIBUTE_STRING_LENGTH];
		strcopy(buffer, sizeof(buffer), attributes);
		ReplaceString(buffer, MAX_ATTRIBUTE_STRING_LENGTH, " ; ", " = ");
		char attrs[32][32];
		int count = ExplodeString(buffer, " = ", attrs, 32, 32, true);
		
		int attrib;
		float val;
		
		for (int n = 0; n <= count+1; n+=2)
		{
			attrib = StringToInt(attrs[n]);
			if (IsAttributeBlacklisted(attrib) || attrib <= 0)
			{
				continue;
			}
			
			val = StringToFloat(attrs[n+1]);
			
			totalAttribs++;
			if (totalAttribs > MAX_ATTRIBUTES)
			{
				break;
			}
				
			TF2Attrib_SetByDefIndex(wearable, attrib, val);
		}
		
		if (staticAttributes)
		{
			int attribArray[MAX_ATTRIBUTES];
			float valueArray[MAX_ATTRIBUTES];
			int staticAttribCount = TF2Attrib_GetStaticAttribs(index, attribArray, valueArray, MAX_STATIC_ATTRIBUTES);
			
			if (staticAttribCount > 0)
			{
				totalAttribs += staticAttribCount;
				if (totalAttribs > MAX_ATTRIBUTES)
					staticAttribCount = imin(staticAttribCount, totalAttribs-staticAttribCount);

				for (int i = 0; i < staticAttribCount; i++)
				{
					if (IsAttributeBlacklisted(attribArray[i]) || attribArray[i] <= 0)
						continue;
					
					TF2Attrib_SetByDefIndex(wearable, attribArray[i], valueArray[i]);
				}
			}
		}
	}
	
	if (totalAttribs > MAX_ATTRIBUTES)
	{
		LogError("[CreateWearable] Wearable %i (%s) exceeded attribute limit of %i", index, classname, MAX_ATTRIBUTES);
	}
	
	if (!visible)
	{
		SetEntityRenderMode(wearable, RENDER_NONE);
	}
	
	if (model[0])
	{
		int modelIndex = PrecacheModel2(model);
		SetEntityModel2(wearable, model);

		for (int i = 0; i <= 3; i++)
		{
			SetEntProp(wearable, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, i);
		}
	}
	
	DispatchSpawn(wearable);
	SDK_EquipWearable(client, wearable);
	SetEntProp(wearable, Prop_Send, "m_bValidatedAttachedEntity", true);
	return wearable;
}

// Remove ALL wearables, including plugin created ones.
void TF2_RemoveAllWearables(int client)
{
	int entity = MaxClients+1;
	char classname[64];
	while ((entity = FindEntityByClassname(entity, "tf_*")) != INVALID_ENT)
	{
		GetEntityClassname(entity, classname, sizeof(classname));
		if (StrContains(classname, "tf_wearable") == -1 && !strcmp2(classname, "tf_powerup_bottle"))
		{
			continue;
		}
		
		if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
		{
			TF2_RemoveWearable(client, entity);
		}
	}
}

void TF2_RemoveDemoShield(int client)
{
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "tf_wearable_demoshield")) != INVALID_ENT)
	{
		if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
		{
			TF2_RemoveWearable(client, entity);
		}
	}
}

// Removes any wearables not created by the plugin
void TF2_RemoveLoadoutWearables(int client)
{
	int entity = MaxClients+1;
	char classname[64];
	while ((entity = FindEntityByClassname(entity, "tf_*")) != INVALID_ENT)
	{
		if (g_bDontRemoveWearable[entity] || g_bItemWearable[entity])
			continue;
		
		GetEntityClassname(entity, classname, sizeof(classname));
		if (StrContains(classname, "tf_wearable") == INVALID_ENT && !strcmp2(classname, "tf_powerup_bottle"))
		{
			continue;
		}
		
		if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
		{
			TF2_RemoveWearable(client, entity);
		}
	}
}

// some weapon's proc coefficient are handled differently, like rocket/grenade launchers, and won't be in here
float GetWeaponProcCoefficient(int weapon)
{
	static char classname[128];
	GetEntityClassname(weapon, classname, sizeof(classname));
	if (strcmp2(classname, "tf_weapon_flamethrower") || strcmp2(classname, "tf_weapon_minigun") || strcmp2(classname, "tf_weapon_syringegun_medic"))
	{
		return 0.2;
	}
	else if (strcmp2(classname, "tf_weapon_pistol") || strcmp2(classname, "tf_weapon_smg") || strcmp2(classname, "tf_weapon_pipebomblauncher"))
	{
		return 0.5;
	}
	
	return 1.0;
}

/*
bool IsEffectBarWeapon(int weapon)
{
	static char classname[32];
	GetEntityClassname(weapon, classname, sizeof(classname));
	
	return (StrContains(classname, "tf_weapon_lunchbox") != INVALID_ENT
	|| StrContains(classname, "tf_weapon_jar") != INVALID_ENT
	|| strcmp2(classname, "tf_weapon_cleaver")
	|| strcmp2(classname, "tf_weapon_bat_wood")
	|| strcmp2(classname, "tf_weapon_bat_giftwrap")
	|| strcmp2(classname, "tf_weapon_rocketpack")
	|| strcmp2(classname, "tf_weapon_invis")
	|| strcmp2(classname, "tf_wearable_demoshield")
	|| strcmp2(classname, "tf_wearable_razorback"));
}
*/

int SDK_GetWeaponClipSize(int entity)
{
	if (g_hSDKGetMaxClip1)
	{
		return SDKCall(g_hSDKGetMaxClip1, entity);
	}
		
	return -1;
}

void SDK_EquipWearable(int client, int entity)
{
	if (g_hSDKEquipWearable)
	{
		SDKCall(g_hSDKEquipWearable, client, entity);
	}
}

public MRESReturn DHook_MeleeSmack(int weapon)
{
	int owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (IsValidClient(owner) && PlayerHasItem(owner, Item_HorrificHeadsplitter))
	{
		g_bMeleeMiss[owner] = true;
	}
	
	// Melee goes through bubble shields (still makes the sound of hitting it but whatever)
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "rf2_dispenser_shield")) != INVALID_ENT)
	{
		SetEntProp(entity, Prop_Send, "m_nSolidType", SOLID_NONE);
		SetEntityCollisionGroup(entity, COLLISION_GROUP_NONE);
	}
	
	// Don't hit teammates (note: only works for BLU team(?), but that's what we want anyway)
	GameRules_SetProp("m_bPlayingMannVsMachine", true);
	return MRES_Ignored;
}

public MRESReturn DHook_MeleeSmackPost(int weapon)
{
	int owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (IsValidClient(owner) && g_bMeleeMiss[owner])
	{
		if (PlayerHasItem(owner, Item_HorrificHeadsplitter))
		{
			RequestFrame(RF_MissCheck, GetClientUserId(owner));
		}
	}
	
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "rf2_dispenser_shield")) != INVALID_ENT)
	{
		SetEntProp(entity, Prop_Send, "m_nSolidType", SOLID_VPHYSICS);
		SetEntityCollisionGroup(entity, TFCOLLISION_GROUP_COMBATOBJECT);
	}
	
	GameRules_SetProp("m_bPlayingMannVsMachine", false);
	return MRES_Ignored;
}

public void RF_MissCheck(int client)
{
	if (!(client = GetClientOfUserId(client)))
		return;
	
	bool missed = g_bMeleeMiss[client];
	g_bMeleeMiss[client] = false;
	if (missed)
	{
		RF_TakeDamage(client, client, client, CalcItemMod(client, Item_HorrificHeadsplitter, 1), DMG_SLASH|DMG_PREVENT_PHYSICS_FORCE, Item_HorrificHeadsplitter);
		TF2_MakeBleed(client, client, 5.0);
	}
}

public MRESReturn Detour_SetReloadTimer(int weapon, DHookParam params)
{
	if (!RF2_IsEnabled())
		return MRES_Ignored;
	
	int owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (!IsValidClient(owner))
		return MRES_Ignored;
	
	float reloadTime = params.Get(1);
	float mult = GetPlayerReloadMod(owner);
	int viewModel = GetEntPropEnt(owner, Prop_Send, "m_hViewModel");
	if (IsValidEntity2(viewModel))
	{
		DataPack pack = new DataPack();
		pack.WriteCell(EntIndexToEntRef(viewModel));
		pack.WriteFloat(reloadTime/(reloadTime*mult));
		RequestFrame(RF_VMPlaybackRate, pack);
	}
	
	params.Set(1, reloadTime*mult);
	return MRES_ChangedHandled;
}

public void RF_VMPlaybackRate(DataPack pack)
{
	pack.Reset();
	int viewModel = EntRefToEntIndex(pack.ReadCell());
	if (viewModel == INVALID_ENT)
	{
		delete pack;
		return;
	}
	
	float rate = pack.ReadFloat();
	delete pack;
	SetEntPropFloat(viewModel, Prop_Send, "m_flPlaybackRate", fmin(rate, 12.0));
}

bool g_bWasOffGround;
public MRESReturn DHook_RiflePostFrame(int entity)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (IsValidClient(owner))
	{
		// Allow firing while in midair
		if (!(GetEntityFlags(owner) & FL_ONGROUND))
		{
			g_bWasOffGround = true;
			SetEntPropEnt(owner, Prop_Data, "m_hGroundEntity", 0);
			SetEntPropEnt(owner, Prop_Send, "m_hGroundEntity", 0);
		}
	}
	
	return MRES_Ignored;
}

public MRESReturn DHook_RiflePostFramePost(int entity)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (IsValidClient(owner) && g_bWasOffGround)
	{
		SetEntPropEnt(owner, Prop_Data, "m_hGroundEntity", INVALID_ENT);
		SetEntPropEnt(owner, Prop_Send, "m_hGroundEntity", INVALID_ENT);
	}
	
	g_bWasOffGround = false;
	return MRES_Ignored;
}

bool IsVoodooCursedCosmetic(int wearable)
{
	int index = GetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex");
	return index >= 5617 && index <= 5625;
}

bool IsWeaponTauntBanned(int weapon)
{
	char classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	return index == 128 || index == 775 // Equalizer/Escape Plan
		|| index == 44 || index == 450 // Sandman/Atomizer
		|| index == 1179 || index == 1180 // Thermal Thruster/Gas Passer
		|| index == 741 || index == 1181 // Rainblower/Hot Hand
		|| index == 142 // Gunslinger
		|| index == 37 || index == 1003 // Ubersaw
		|| strcmp2(classname, "tf_weapon_knife")
		|| strcmp2(classname, "tf_weapon_shotgun_pyro")
		|| strcmp2(classname, "tf_weapon_flaregun")
		|| strcmp2(classname, "tf_weapon_compound_bow")
		|| strcmp2(classname, "tf_weapon_fists")
		|| strcmp2(classname, "tf_weapon_sword")
		|| strcmp2(classname, "tf_weapon_katana")
		|| strcmp2(classname, "tf_weapon_sentry_revenge");
}

bool IsEnergyWeapon(int weapon)
{
	char classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	return strcmp2(classname, "tf_weapon_raygun") || strcmp2(classname, "tf_weapon_particle_cannon") || strcmp2(classname, "tf_weapon_drg_pomson");
}

bool IsWeaponWearable(int wearable)
{
	int index = GetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex");
	return index == 642 // Cozy Camper
	|| index == 133 // Gunboats
	|| index == 444 // Mantreads
	|| index == 405 || index == 608 // Demo boots
	|| index == 131 || index == 406 || index == 1099 || index == 1144 // Shields
	|| index == 57 // Razorback
	|| index == 231; // Darwin's Danger Shield
}

// Blacklist for attributes that waste slots or cause issues. Mostly for static attributes.
bool IsAttributeBlacklisted(int id)
{
	return id == 796 || // "min viewmodel offset" (causes client crashes when set by plugins)
	id == 2058 || // "meter_label" (another string attribute that can crash clients)
	id >= 292 && id <= 294 || // "kill eater" attributes (these are for TF2 strange items, they do nothing for us but waste slots)
	id == 388 || // "kill eater kill type"
	id >= 379 && id <= 384 || // even MORE kill eater attributes
	id == 214 || // another kill eater attribute...
	id == 494 || id == 495 || // last of the kill eater attributes
	id == 2029 || // "allowed in medieval mode"
	id == 719 || // "weapon_uses_stattrack_module"
	id == 731 || // "weapon_allow_inspect"
	id == 817 || // "inspect_viewmodel_offset"
	id == 724 || // "weapon_stattrak_module_scale"
	id == 25 || // "hidden secondary max ammo penalty" (don't need these, players have infinite ammo)
	id == 37 || // "hidden primary max ammo bonus"
	id >= 76 && id <= 79; // more maxammo attributes
}
