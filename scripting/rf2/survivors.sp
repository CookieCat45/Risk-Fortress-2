#if defined _RF2_survivors_included
 #endinput
#endif
#define _RF2_survivors_included

#pragma semicolon 1
#pragma newdecls required

#define BASE_NEXT_LEVEL_XP 150.0

int g_iSurvivorCount = 1;
int g_iSurvivorBaseHealth[TF_CLASSES];
int g_iSavedItem[MAX_INVENTORIES][MAX_ITEMS];
int g_iSavedLevel[MAX_INVENTORIES] = {1, ...};
int g_iSavedEquipmentItem[MAX_INVENTORIES];
int g_iSurvivorGivenItems[MAX_INVENTORIES];

float g_flSurvivorMaxSpeed[TF_CLASSES];
float g_flSavedXP[MAX_INVENTORIES];
float g_flTotalXP[MAX_INVENTORIES];
float g_flSavedNextLevelXP[MAX_INVENTORIES] = {BASE_NEXT_LEVEL_XP, ...};

char g_szSurvivorAttributes[TF_CLASSES][MAX_ATTRIBUTE_STRING_LENGTH];
bool g_bSurvivorInventoryClaimed[MAX_INVENTORIES];
StringMap g_hPlayerSteamIDToInventoryIndex;
StringMap g_hPlayerNameToInventoryIndex;

void LoadSurvivorStats()
{
	KeyValues survivorKey = CreateKeyValues("survivors");
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, SurvivorConfig);
	if (!survivorKey.ImportFromFile(config))
	{
		delete survivorKey;
		ThrowError("File %s does not exist", config);
	}
	
	TFClassType class;
	bool firstKey = true;
	char sectionName[32];
	
	for (int i = 0; i < TF_CLASSES; i++)
	{
		if (firstKey ? survivorKey.GotoFirstSubKey(false) : survivorKey.GotoNextKey(false))
		{
			survivorKey.GetSectionName(sectionName, sizeof(sectionName));
			if ((class = TF2_GetClass(sectionName)) != TFClass_Unknown)
			{
				g_iSurvivorBaseHealth[class] = survivorKey.GetNum("health", 450);
				g_flSurvivorMaxSpeed[class] = survivorKey.GetFloat("speed", 300.0);
				survivorKey.GetString("attributes", g_szSurvivorAttributes[class], sizeof(g_szSurvivorAttributes[]));
				firstKey = false;
			}
		}
	}
	
	delete survivorKey;
}

bool CreateSurvivors()
{
	if (!g_hPlayerSteamIDToInventoryIndex)
		g_hPlayerSteamIDToInventoryIndex = new StringMap();
	
	if (!g_hPlayerNameToInventoryIndex)
		g_hPlayerNameToInventoryIndex = new StringMap();
	
	int humanCount = GetPlayersOnTeam(TEAM_SURVIVOR, false, true) + GetPlayersOnTeam(TEAM_ENEMY, false, true);
	ArrayList survivorList = new ArrayList();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsPlayerSpectator(i) || humanCount > 1 && (AreClientCookiesCached(i) && !GetCookieBool(i, g_coBecomeSurvivor)))
			continue;
			
		if (IsFakeClient(i))
		{
			if (!g_cvBotsCanBeSurvivor.BoolValue)
			{
				SilentlyKillPlayer(i);
				ChangeClientTeam(i, TEAM_ENEMY);
				continue;
			}
			else
			{
				SetEntProp(i, Prop_Send, "m_nBotSkill", TFBotSkill_Expert);
			}
		}
		
		if (IsAdminReserved(i))
		{
			RF2_PrintToChat(i, "%t", "AdminReservePenalty", GetTotalHumans(false), GetDesiredPlayerCap());
			SilentlyKillPlayer(i);
			ChangeClientTeam(i, 1);
			continue;
		}
		
		if (GetClientTeam(i) != TEAM_ENEMY)
		{
			if (IsPlayerAlive(i))
			{
				SilentlyKillPlayer(i);
			}
			
			ChangeClientTeam(i, TEAM_ENEMY);
		}
		
		survivorList.Push(i);
	}
	
	// sort by queue points
	survivorList.SortCustom(SortSurvivorListByPoints);
	int maxSurvivors = g_cvMaxSurvivors.IntValue;
	if (survivorList.Length > maxSurvivors)
		survivorList.Resize(maxSurvivors);
	
	int survivorCount, client, index;
	for (int i = 0; i < survivorList.Length; i++)
	{
		client = survivorList.Get(i);
		index = survivorCount;
		g_iPlayerSurvivorIndex[client] = index;
		MakeSurvivor(client, index);
		survivorCount++;
		index = -1;
	}
	
	g_iSurvivorCount = survivorCount;
	delete survivorList;
	return survivorCount > 0;
}

void MakeSurvivor(int client, int index, bool resetPoints=true, bool loadInventory=true)
{
	if (resetPoints)
		RF2_SetSurvivorPoints(client, 0);
	
	// Player is probably still on the class select screen, so we need to kick them out by giving them a random class.
	if (TF2_GetPlayerClass(client) == TFClass_Unknown)
	{
		TF2_SetPlayerClass(client, view_as<TFClassType>(GetRandomInt(1, 9)));
	}
	
	ResetAFKTime(client);
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel"); // In case this was from the command or otherwise, clear our custom model
	TFClassType class = TF2_GetPlayerClass(client);
	g_iPlayerSurvivorIndex[client] = index;
	g_iPlayerBaseHealth[client] = g_iSurvivorBaseHealth[class];
	g_flPlayerMaxSpeed[client] = g_flSurvivorMaxSpeed[class];
	TF2Attrib_RemoveAll(client);
	SetClassAttributes(client);
	ChangeClientTeam(client, TEAM_SURVIVOR);
	TF2_RemoveAllWeapons(client);
	TF2_RemoveAllWearables(client);
	TF2_RespawnPlayer(client);
	TF2_AddCondition(client, TFCond_UberchargedCanteen, 5.0);
	SetEntProp(client, Prop_Send, "m_bGlowEnabled", true);
	g_flPlayerTimeSinceLastItemPickup[client] = GetTickedTime();
	if (GetPlayerWeaponSlot(client, WeaponSlot_Melee) == INVALID_ENT)
	{
		//LogError("Caught A-Pose bug on %N, attempting to fix", client);
		TF2_RespawnPlayer(client);
	}
	
	if (loadInventory)
	{
		int invIndex = PickInventoryIndex(client);
		g_iPlayerInventoryIndex[client] = invIndex;
		
		// likely a mid-game join, so get us up to speed
		int totalInvs = imax(1, GetTotalClaimedInventories());
		int itemsToGive = (GetTotalSurvivorItems() / totalInvs) - GetTotalSurvivorItems(invIndex);
		itemsToGive += 3 * g_iStagesCompleted;
		const int collectorLimit = 10;
		int collectorItems;
		itemsToGive -= g_iSurvivorGivenItems[invIndex];
		if (g_bGameInitialized && itemsToGive > 0 && !g_bSurvivorInventoryClaimed[invIndex])
		{
			// if we join in a game and our inventory is empty, get us up to speed
			float highestXp = GetHighestSurvivorXP();
			g_iPlayerLevel[client] = 1;
			g_flPlayerXP[client] = 0.0;
			g_flPlayerNextLevelXP[client] = BASE_NEXT_LEVEL_XP;
			UpdatePlayerXP(client, highestXp);
			for (int i = 1; i <= itemsToGive; i++)
			{
				if (collectorItems < collectorLimit && GetRandomInt(1, 10) == 1)
				{
					GiveItem(client, GetRandomCollectorItem(class));
					collectorItems++;
				}
				else
				{
					GiveItem(client, GetRandomItem(79, 20, 1));
				}
			}
			
			/*
			if (g_iLoopCount >= 2 && g_iSavedItem[invIndex][Item_PrideScarf] < itemsToGive/3)
			{
				// Give a bunch of health otherwise the player just endlessly dies at this point
				GiveItem(client, Item_PrideScarf, imin(imax((itemsToGive/3)-g_iSavedItem[invIndex][Item_PrideScarf], 0), 100));
				GiveItem(client, Item_SpiralSallet, 10-imin(g_iSavedItem[invIndex][Item_SpiralSallet], 10));
				GiveItem(client, Item_ClassCrown);
			}
			*/
			
			if (g_iSavedEquipmentItem[invIndex] == Item_Null)
			{
				GiveItem(client, GetRandomItemEx(Quality_Strange));
			}
			
			// save now so it actually keeps our items
			SaveSurvivorInventory(client, invIndex);
			g_iSurvivorGivenItems[invIndex] += itemsToGive;
		}
		
		g_bSurvivorInventoryClaimed[invIndex] = true;
		LoadSurvivorInventory(client, invIndex);
	}
	else // we should still update our items in case this is a respawn
	{
		UpdateItemsForPlayer(client);
	}
	
	GiveCommunityItems(client);
	if (!IsFakeClient(client) && !GetCookieBool(client, g_coTutorialSurvivor))
	{
		CreateTimer(1.0, Timer_SurvivorTutorial, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

void UpdateItemsForPlayer(int client)
{
	for (int i = 1; i <= GetTotalItems(); i++)
	{
		UpdatePlayerItem(client, i);
	}
}

void SetClassAttributes(int client)
{
	TFClassType class = TF2_GetPlayerClass(client);
	if (g_szSurvivorAttributes[class][0])
	{
		char buffer[MAX_ATTRIBUTE_STRING_LENGTH];
		strcopy(buffer, sizeof(buffer), g_szSurvivorAttributes[class]);
		ReplaceString(buffer, sizeof(buffer), " ; ", " = ");
		char attrs[32][32];
		int count = ExplodeString(buffer, " = ", attrs, 32, 32, true);
		
		int attrib, totalAttribs;
		float val;
		for (int n = 0; n <= count+1; n+=2)
		{
			attrib = StringToInt(attrs[n]);
			if (IsAttributeBlacklisted(attrib) || attrib <= 0)
				continue;
			
			val = StringToFloat(attrs[n+1]);
			totalAttribs++;
			if (totalAttribs > MAX_ATTRIBUTES)
				break;
				
			TF2Attrib_SetByDefIndex(client, attrib, val);
		}
		
		if (totalAttribs > MAX_ATTRIBUTES)
		{
			char tfClassName[16];
			GetClassString(class, tfClassName, sizeof(tfClassName));
			LogError("[SetClassAttributes] Survivor class %i (%s) reached attribute limit of %i", view_as<int>(class), tfClassName, MAX_ATTRIBUTES);
		}
	}
}

public int SortSurvivorListByPoints(int index1, int index2, ArrayList array, Handle hndl)
{
	int client1 = array.Get(index1);
	int client2 = array.Get(index2);
	
	// move bots, AFK people and those who don't want to be survivors to the end of the list
	bool survivor1 = GetCookieBool(client1, g_coBecomeSurvivor);
	bool survivor2 = GetCookieBool(client2, g_coBecomeSurvivor);
	if (!AreClientCookiesCached(client1))
		survivor1 = true;
	if (!AreClientCookiesCached(client2))
		survivor2 = true;
	
	if (!survivor1 && !survivor2)
	{
		return 0;
	}
	else if (!survivor1)
	{
		return 1;
	}
	else if (!survivor2)
	{
		return -1;
	}
	
	if (IsPlayerAFK(client1) && IsPlayerAFK(client2))
	{
		return 0;
	}
	else if (IsFakeClient(client1) || IsPlayerAFK(client1))
	{
		return 1;
	}
	else if (IsFakeClient(client2) || IsPlayerAFK(client2))
	{
		return -1;
	}
	
	int points1 = RF2_GetSurvivorPoints(client1);
	int points2 = RF2_GetSurvivorPoints(client2);
	if (points1 == points2)
		return 0;
	
	return points1 > points2 ? -1 : 1;
}

public Action Timer_SurvivorTutorial(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
	
	PrintKeyHintText(client, "%t", "SurvivorTutorial");
	CreateTimer(13.0, Timer_SurvivorTutorial2, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Timer_SurvivorTutorial2(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
	
	PrintKeyHintText(client, "%t", "SurvivorTutorial2");
	CreateTimer(13.0, Timer_SurvivorTutorial3, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action Timer_SurvivorTutorial3(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
	
	SetClientCookie(client, g_coTutorialSurvivor, "1");
	return Plugin_Continue;
}

void LoadSurvivorInventory(int client, int index)
{
	g_iPlayerEquipmentItem[client] = g_iSavedEquipmentItem[index];
	g_iPlayerEquipmentItemCharges[client] = 1;
	if (GetPlayerEquipmentItem(client) != Item_Null && PlayerHasItem(client, Item_BatteryCanteens))
	{
		g_flPlayerEquipmentItemCooldown[client] = GetPlayerEquipmentItemCooldown(client);
		CreateTimer(0.1, Timer_EquipmentCooldown, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	for (int i = 1; i <= GetTotalItems(); i++)
	{
		if (!IsEquipmentItem(i))
			g_iPlayerItem[client][i] = g_iSavedItem[index][i];
			
		UpdatePlayerItem(client, i);
	}
	
	float cashBonus = 1.0 + (2.0 * float(g_iLoopCount));
	if (g_bTankBossMode)
	{
		cashBonus += 2.0;
	}
	
	SetPlayerCash(client, 100.0 * RF2_Object_Base.GetCostMultiplier() * cashBonus);
	g_iPlayerLevel[client] = g_iSavedLevel[index];
	g_flPlayerXP[client] = g_flSavedXP[index];
	g_iItemsTaken[RF2_GetSurvivorIndex(client)] = 0;
	
	if (g_iPlayerLevel[client] > 1)
	{
		g_flPlayerNextLevelXP[client] = g_flSavedNextLevelXP[index];
	}
	else
	{
		g_flPlayerNextLevelXP[client] = g_cvSurvivorBaseXpRequirement.FloatValue;
	}
}

void SaveSurvivorInventory(int client, int index, bool saveSteamId=true)
{
	if (index < 0)
		return;
		
	for (int i = 1; i < GetTotalItems(); i++)
	{
		if (IsEquipmentItem(i))
			continue;
		
		g_iSavedItem[index][i] = GetPlayerItemCount(client, i, true);
	}
	
	g_iSavedLevel[index] = g_iPlayerLevel[client];
	g_flSavedXP[index] = g_flPlayerXP[client];
	g_flSavedNextLevelXP[index] = g_flPlayerNextLevelXP[client];
	g_iSavedEquipmentItem[index] = GetPlayerEquipmentItem(client);
	
	char steamId[MAX_AUTHID_LENGTH], name[MAX_NAME_LENGTH];
	if (saveSteamId)
	{
		if (GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
		{
			g_hPlayerSteamIDToInventoryIndex.SetValue(steamId, index, false);
		}
		
		// In case SteamIDs are unavailable, we can fall back to player names
		GetClientName(client, name, sizeof(name));
		g_hPlayerNameToInventoryIndex.SetValue(name, index, false);
	}
}

float GetHighestSurvivorXP()
{
	float highest;
	for (int i = 0; i < g_cvMaxSurvivors.IntValue; i++)
	{
		if (g_flTotalXP[i] <= 0.0)
			continue;
	
		if (highest <= 1 || g_flTotalXP[i] > highest)
			highest = g_flTotalXP[i];
	}
	
	return highest;
}

int GetTotalSurvivorItems(int index=-1)
{
	int total;
	if (index >= 0)
	{
		for (int i = 0; i < MAX_ITEMS; i++)
		{
			total += g_iSavedItem[index][i];
		}
		
		return total;
	}
	
	for (int i = 0; i < MAX_INVENTORIES; i++)
	{
		for (int j = 0; j < MAX_ITEMS; j++)
		{
			total += g_iSavedItem[i][j];
		}
	}
	
	return total;
}

int GetTotalClaimedInventories()
{
	int total;
	for (int i = 0; i < MAX_INVENTORIES; i++)
	{
		if (g_bSurvivorInventoryClaimed[i])
			total++;
	}
	
	return total;
}

void CalculateSurvivorItemShare(bool recalculate=true)
{
	int survivorCount;
	
	// We want to remember how many objects were spawned at the beginning of the round. If recalculate is true, don't touch our object count.
	static int objectCount;
	if (!recalculate)
	{
		objectCount = 0;
	}
	
	int entity = INVALID_ENT;
	RF2_Object_Crate crate;
	while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT)
	{
		if (entity > 0 && entity <= MaxClients && IsPlayerSurvivor(entity, false))
			survivorCount++;
		
		if (!recalculate)
		{
			crate = RF2_Object_Crate(entity);
			if (crate.IsValid() && !crate.IsBonus && crate.Type != Crate_Strange && crate.Type != Crate_Haunted)
			{
				objectCount++;
			}
		}
	}
	
	if (survivorCount == 0)
		return;
	
	int itemShare = objectCount / survivorCount;
	for (int i = 0; i < MAX_SURVIVORS; i++)
	{
		if (survivorCount == 1)
		{
			g_iItemLimit[i] = 99999;
			break;
		}
		else
		{
			g_iItemLimit[i] = itemShare;
		}	
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerSurvivor(i, false))
		{
			g_iItemLimit[RF2_GetSurvivorIndex(i)] += GetPlayerCrateBonus(i);
		}
	}
}

bool IsSurvivorIndexValid(int index)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		if (RF2_GetSurvivorIndex(i) == index)
			return true;
	}
	
	return false;
}

int GetFreeSurvivorIndex()
{
	for (int i = 0; i < MAX_SURVIVORS; i++)
	{
		if (!IsSurvivorIndexValid(i))
			return i;
	}

	return -1;
}

void UpdatePlayerXP(int client, float xpAmount=0.0)
{
	if (IsSingleplayer(false))
	{
		// XP is increased in singleplayer
		xpAmount *= 1.75;
	}
	
	g_flPlayerXP[client] += xpAmount;
	if (g_flPlayerXP[client] >= g_flPlayerNextLevelXP[client])
	{
		PlayerLevelUp(client);
		
		float xpRemaining = g_flPlayerXP[client] - g_flPlayerNextLevelXP[client];
		float oldNextXP = g_flPlayerNextLevelXP[client];
		g_flPlayerNextLevelXP[client] *= g_cvSurvivorXpRequirementScale.FloatValue;
		
		// If we can still level up, do this again
		if (xpRemaining >= g_flPlayerNextLevelXP[client])
		{
			g_flPlayerXP[client] -= oldNextXP;
			UpdatePlayerXP(client);
		}
		else
		{
			if (xpRemaining < 0.0)
				xpRemaining = FloatAbs(xpRemaining);
				
			g_flPlayerXP[client] = xpRemaining;
		}
	}
	
	g_flTotalXP[RF2_GetSurvivorIndex(client)] += xpAmount;
}

void PlayerLevelUp(int client)
{
	int oldLevel = g_iPlayerLevel[client];
	g_iPlayerLevel[client]++;
	
	CalculatePlayerMaxHealth(client);
	CalculatePlayerMiscStats(client);
	RF2_PrintToChat(client, "%t", "YouLevelUp", oldLevel, g_iPlayerLevel[client]);
}

bool IsPlayerSurvivor(int client, bool aliveOnly=true)
{
	return RF2_GetSurvivorIndex(client) >= 0 && (!aliveOnly || IsPlayerAlive(client)) && GetClientTeam(client) == TEAM_SURVIVOR;
}

bool IsSingleplayer(bool fullCheck=true)
{
	if (g_iSurvivorCount > 1)
		return false;
	
	return !fullCheck || GetTotalHumans(false) <= 1;
}

// Returns true if a player timed out and we're waiting for them to rejoin.
// single=true means only return if there are no players on RED (likely singleplayer).
bool WaitingForPlayerRejoin(bool single=false)
{
	if (single)
	{
		return g_hCrashedPlayerSteamIDs.Size > 0 && GetPlayersOnTeam(TEAM_SURVIVOR, true) == 0;
	}
	else
	{
		return g_hCrashedPlayerSteamIDs.Size > 0;
	}	
}

bool IsPlayerMinion(int client)
{
	return g_bPlayerIsMinion[client];
}

void SpawnMinion(int client)
{
	g_bPlayerIsMinion[client] = true;
	g_bPlayerSpawningAsMinion[client] = false;
	float pos[3], center[3];
	int target = GetRandomPlayer(TEAM_SURVIVOR);
	if (IsValidClient(target))
	{
		GetEntPos(target, center);
	}
	else
	{
		GetWorldCenter(center);
	}
	
	GetSpawnPoint(center, pos, 0.0, 10000.0, _, _, _, _, _, 30.0);
	TFClassType class = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"));
	if (class == TFClass_Unknown)
	{
		class = view_as<TFClassType>(GetRandomInt(1, 9));
	}
	
	TF2_SetPlayerClass(client, class);
	TF2_RespawnPlayer(client);
	TF2_RemoveAllWeapons(client);
	TF2_RemoveDemoShield(client);
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "tf_powerup_bottle")) != INVALID_ENT)
	{
		if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
		{
			TF2_RemoveWearable(client, entity);
			break;
		}
	}
	
	g_iPlayerVoiceType[client] = VoiceType_Robot;
	g_iPlayerVoicePitch[client] = SNDPITCH_HIGH;
	g_iPlayerFootstepType[client] = FootstepType_Robot;
	TeleportEntity(client, pos);
	switch (class)
	{
		case TFClass_Scout:
		{
			SetVariantString(MODEL_BOT_SCOUT);
			CreateWeapon(client, "tf_weapon_lunchbox_drink", 1145, _, true);
			CreateWeapon(client, "tf_weapon_bat_wood", 44, "218 = 1", true);
			g_iPlayerBaseHealth[client] = 315;
			g_flPlayerMaxSpeed[client] = 420.0;
		}
		
		case TFClass_Soldier:
		{
			SetVariantString(MODEL_BOT_SOLDIER);
			CreateWeapon(client, "tf_weapon_shotgun_soldier", 10, "3 = 0.7");
			CreateWeapon(client, "tf_weapon_shovel", 447, _, true);
			g_iPlayerBaseHealth[client] = 500;
			g_flPlayerMaxSpeed[client] = 280.0;
		}
		
		case TFClass_Pyro:
		{
			SetVariantString(MODEL_BOT_PYRO);
			CreateWeapon(client, "tf_weapon_rocketpack", 1179, _, true);
			CreateWeapon(client, "tf_weapon_fireaxe", 348, _, true);
			g_iPlayerBaseHealth[client] = 450;
			g_flPlayerMaxSpeed[client] = 320.0;
		}
		
		case TFClass_DemoMan:
		{
			SetVariantString(MODEL_BOT_DEMO);
			CreateWeapon(client, "tf_weapon_sword", 404, _, true);
			CreateWearable(client, "tf_wearable_demoshield", 1099, _, true);
			g_iPlayerBaseHealth[client] = 450;
			g_flPlayerMaxSpeed[client] = 300.0;
		}
		
		case TFClass_Heavy:
		{
			SetVariantString(MODEL_BOT_HEAVY);
			CreateWeapon(client, "tf_weapon_fists", 5, "2 = 1.2");
			CreateWeapon(client, "tf_weapon_lunchbox", 863, _, true);
			g_iPlayerBaseHealth[client] = 800;
			g_flPlayerMaxSpeed[client] = 260.0;
		}
		
		case TFClass_Engineer:
		{
			SetVariantString(MODEL_BOT_ENGINEER);
			CreateWeapon(client, "tf_weapon_wrench", 7, "276 = 1 ; 345 = 3.0");
			CreateWeapon(client, "tf_weapon_pda_engineer_build", 25);
			CreateWeapon(client, "tf_weapon_pda_engineer_destroy", 26);
			CreateWeapon(client, "tf_weapon_builder", 28);
			g_iPlayerBaseHealth[client] = 300;
			g_flPlayerMaxSpeed[client] = 320.0;
		}
		
		case TFClass_Medic:
		{
			SetVariantString(MODEL_BOT_MEDIC);
			CreateWeapon(client, "tf_weapon_crossbow", 1079, "1 = 0.5", true);
			CreateWeapon(client, "tf_weapon_medigun", 411, "314 = -3 ; 7 = 0.6", true);
			CreateWeapon(client, "tf_weapon_bonesaw", 1143, "1 = 0.8");
			g_iPlayerBaseHealth[client] = 375;
			g_flPlayerMaxSpeed[client] = 360.0;
		}
		
		case TFClass_Sniper:
		{
			SetVariantString(MODEL_BOT_SNIPER);
			CreateWeapon(client, "tf_weapon_jar", 1105, "278 = 2.0");
			CreateWeapon(client, "tf_weapon_club", 3);
			g_iPlayerBaseHealth[client] = 300;
			g_flPlayerMaxSpeed[client] = 320.0;
		}
		
		case TFClass_Spy:
		{
			SetVariantString(MODEL_BOT_SPY);
			CreateWeapon(client, "tf_weapon_knife", 892);
			CreateWeapon(client, "tf_weapon_pda_spy", 27);
			CreateWeapon(client, "tf_weapon_invis", 30);
			CreateWeapon(client, "tf_weapon_sapper", 810, _, true);
			g_iPlayerBaseHealth[client] = 300;
			g_flPlayerMaxSpeed[client] = 360.0;
		}
	}
	
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 0.5);
	TF2_AddCondition(client, TFCond_UberchargedCanteen, 2.5);
	TF2Attrib_SetByDefIndex(client, 62, 0.25); // "dmg taken from crit reduced"
	TF2Attrib_SetByDefIndex(client, 252, 0.25); // "damage force reduction"
	CBaseEntity(client).AddFlag(FL_NOTARGET);
	if (g_iLoopCount >= 1)
	{
		TF2_AddCondition(client, TFCond_DefenseBuffed);
		TF2_AddCondition(client, TFCond_RuneStrength);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly);
		TF2Attrib_SetByDefIndex(client, 326, 2.0);
		TF2Attrib_SetByDefIndex(client, 610, 2.0);
	}
}

int PickInventoryIndex(int client)
{
	int index = -1;
	char steamId[MAX_AUTHID_LENGTH], name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	if (GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
	{
		if (g_hPlayerSteamIDToInventoryIndex && !g_hPlayerSteamIDToInventoryIndex.GetValue(steamId, index))
		{
			g_hPlayerNameToInventoryIndex.GetValue(name, index);
		}
	}
	else if (g_hPlayerNameToInventoryIndex)
	{
		g_hPlayerNameToInventoryIndex.GetValue(name, index);
	}
	
	if (index == -1) // we don't have an inventory, pick an empty one
	{
		for (int i = 0; i < MAX_INVENTORIES; i++)
		{
			if (!g_bSurvivorInventoryClaimed[i])
				return i;
		}
	}
	
	return index;
}

// Returns total number of items the player is lagging behind by, 0 otherwise.
// Compares the total items of this player to whoever has the most items.
int GetPlayerCrateBonus(int client)
{
	if (g_iLoopCount > 0)
		return 0;
	
	float lagBehindPercent = g_cvSurvivorLagBehindThreshold.FloatValue;
	if (lagBehindPercent <= 0.0)
		return 0;
	
	int count;
	int highestItems, itemHogger;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerSurvivor(i))
			continue;
		
		count = GetTotalSurvivorItems(g_iPlayerInventoryIndex[i]);
		if (highestItems == 0 || count > highestItems)
		{
			highestItems = count;
			itemHogger = i;
		}
	}
	
	if (highestItems <= 0 || itemHogger == client)
		return 0;
	
	int myCount = GetTotalSurvivorItems(g_iPlayerInventoryIndex[client]);
	if (RoundToFloor(float(highestItems) * lagBehindPercent) >= myCount)
	{
		return imin(highestItems-myCount, g_cvSurvivorMaxExtraCrates.IntValue);
	}
	
	return 0;
}

// live check means we are checking this during gameplay, not during initialization or when round is starting etc.
bool IsItemSharingEnabled(bool liveCheck=true)
{
	if (!g_cvItemShareEnabled.BoolValue)
		return false;
	
	if (GetRF2GameRules().DisableItemSharing)
		return false;
	
	// count bots for debugging purposes
	if (GetPlayersOnTeam(TEAM_SURVIVOR, true, false) <= 1)
		return false;
	
	int loopCount = g_cvItemShareDisableLoopCount.IntValue;
	if (loopCount > 0 && g_iLoopCount >= loopCount && g_cvItemShareEnabled.IntValue == 1)
		return false;
	
	if (IsInUnderworld())
		return false;
	
	// anything below this will only be checked during gameplay
	if (!liveCheck)
		return true;
	
	if (g_bItemSharingDisabledForMap)
		return false;
	
	bool playersNeedItems;
	if (g_cvItemShareEnabled.IntValue == 1 && g_cvItemShareDisableThreshold.FloatValue > 0.0 && !IsSingleplayer(false))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerSurvivor(i) && !DoesPlayerHaveEnoughItems(i))
			{
				playersNeedItems = true;
				break;
			}
		}
	}
	
	if (IsStageCleared() && g_cvItemShareEnabled.IntValue == 1 && !playersNeedItems)
		return false;
	
	return playersNeedItems;
}

bool DoesPlayerHaveEnoughItems(int client)
{
	if (GetCookieInt(client, g_coItemShareKarma) <= -2) // bad karma, don't take this player into consideration
		return true;
	
	if (g_bPlayerItemShareExcluded[client])
		return true;
	
	// player is taking too long to pick stuff up
	if (!IsBossEventActive() || g_iTanksKilledObjective >= g_iTankKillRequirement)
	{
		if (g_flPlayerTimeSinceLastItemPickup[client]+50.0 < GetTickedTime())
		{
			g_bPlayerItemShareExcluded[client] = true;
			return true;
		}
	}
	
	if (g_cvItemShareDisableThreshold.FloatValue <= 0.0 || g_iItemsTaken[RF2_GetSurvivorIndex(client)] >= GetPlayerRequiredItems(client))
		return true;
	
	// don't bother with AFK players
	if (IsPlayerAFK(client))
		return true;
	
	if (IsStageCleared())
	{
		// players who don't have enough money to purchase a small crate at the end of the stage also don't count
		if (GetPlayerCash(client) < g_cvObjectBaseCost.FloatValue * g_flCurrentCostMult)
		{
			return true;
		}
	}
	
	return false;
}

int GetPlayerRequiredItems(int client)
{
	return RoundFloat(float(g_iItemLimit[RF2_GetSurvivorIndex(client)]) * g_cvItemShareDisableThreshold.FloatValue);
}

bool AreAnyPlayersLackingItems()
{
	if (!IsItemSharingEnabled())
		return false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerSurvivor(i) && !DoesPlayerHaveEnoughItems(i))
		{
			return true;
		}
	}

	return false;
}

void GiveCommunityItems(int client)
{
	if (!PlayerHasItem(client, ItemCommunity_MercMedal) && (GetCookieBool(client, g_coEarnedAllAchievements) || PlayerHasAllAchievements(client)))
	{
		GiveItem(client, ItemCommunity_MercMedal);
	}
}
