#if defined _RF2_objects_included
 #endinput
#endif
#define _RF2_objects_included

#pragma semicolon 1
#pragma newdecls required

enum
{
	TELE_EVENT_INACTIVE,
	TELE_EVENT_PREPARING,
	TELE_EVENT_ACTIVE,
	TELE_EVENT_COMPLETE,
};

int g_iTeleporterEntRef = -1;

bool IsObject(int entity)
{
	CEntityFactory factory = CEntityFactory.GetFactoryOfEntity(entity);
	if (!factory)
		return false;
	
	char classname[128];
	factory.GetClassname(classname, sizeof(classname));
	return (StrContains(classname, "rf2_object") == 0);
}

int SpawnObjects()
{
	// Make sure everything is gone first
	DespawnObjects();
	
	// Show any map spawned objects now
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		if (entity <= MaxClients)
			continue;
		
		if (IsObject(entity) && GetEntProp(entity, Prop_Data, "m_bMapPlaced"))
		{
			AcceptEntityInput(entity, "TurnOn");
		}
	}

	if (!g_bTankBossMode)
	{
		ArrayList teleporterSpawns = CreateArray();
		
		// Find our teleporter spawnpoints
		entity = -1;
		while ((entity = FindEntityByClassname(entity, "rf2_teleporter_spawn")) != -1)
		{
			teleporterSpawns.Push(entity);
		}
		
		if (teleporterSpawns.Length > 0)
		{
			// now spawn the teleporter at a random location
			int spawnPoint = teleporterSpawns.Get(GetRandomInt(0, teleporterSpawns.Length-1));
			int teleporter = CreateEntityByName("rf2_object_teleporter");
			
			float pos[3], angles[3];
			GetEntPropVector(spawnPoint, Prop_Data, "m_vecAbsOrigin", pos);
			GetEntPropVector(spawnPoint, Prop_Send, "m_angRotation", angles);
			TeleportEntity(teleporter, pos, angles);
			DispatchSpawn(teleporter);
			g_iTeleporterEntRef = EntIndexToEntRef(teleporter);
			
			FireEntityOutput(spawnPoint, "OnChosen");
		}
		else
		{
			char mapName[256];
			GetCurrentMap(mapName, sizeof(mapName));
			LogError("Map %s has no rf2_teleporter_spawn entities!!", mapName);
		}
		
		delete teleporterSpawns;
	}
	
	// now spawn objects
	int spawnCount = g_cvObjectBaseCount.IntValue * RF2_GetSurvivorCount() + RoundToCeil(g_flDifficultyCoeff / (g_cvSubDifficultyIncrement.FloatValue / 5.0));
	int maxSpawns = g_cvMaxObjects.IntValue;
	
	if (spawnCount > maxSpawns)
		spawnCount = maxSpawns;
	
	int spawns, attempts, nearestObject;
	float spawnPos[3], nearestPos[3], worldCenter[3], worldMins[3], worldMaxs[3];
	float spreadDistance = g_cvObjectSpreadDistance.FloatValue;
	
	GetWorldCenter(worldCenter);
	
	// Need to get the size of the map so we know how far we can spawn objects
	GetEntPropVector(0, Prop_Send, "m_WorldMins", worldMins);
	GetEntPropVector(0, Prop_Send, "m_WorldMaxs", worldMaxs);
	float length = FloatAbs(worldMins[0]) + FloatAbs(worldMaxs[0]);
	float width = FloatAbs(worldMins[1]) + FloatAbs(worldMaxs[1]);
	float distance = SquareRoot(length * width);
	
	while (spawns < spawnCount && attempts < 1000)
	{
		GetSpawnPoint(worldCenter, spawnPos, 0.0, distance, _, true);
		nearestObject = GetNearestEntityEx(spawnPos, "rf2_object");
		
		if (nearestObject != -1)
		{
			GetEntPropVector(nearestObject, Prop_Data, "m_vecAbsOrigin", nearestPos);
			if (GetVectorDistance(spawnPos, nearestPos, true) <= sq(spreadDistance)) // Too close to another object.
			{
				attempts++;
				continue;
			}
		}
		
		if (RandChanceFloat(0.01, 100.0, g_cvObjectSpecialChance.FloatValue))
		{
			switch (GetRandomInt(1, 13))
			{
				case 1, 2, 3: CreateObject("rf2_object_crate_large", spawnPos);
				case 4, 5: CreateObject("rf2_object_crate_strange", spawnPos);
				case 6:	CreateObject("rf2_object_crate_haunted", spawnPos);
				case 7, 8: CreateObject("rf2_object_crate_collector", spawnPos);
				case 9, 10, 11: CreateObject("rf2_object_workbench", spawnPos);
				case 12, 13: CreateObject("rf2_object_scrapper", spawnPos);
			}
		}
		else
		{
			CreateObject("rf2_object_crate", spawnPos);
		}
		
		spawns++;
	}
	
	return spawns;
}

void DespawnObjects()
{
	char classname[128];
	int entity = -1;
	
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		if (entity <= MaxClients)
			continue;
		
		GetEntityClassname(entity, classname, sizeof(classname));
		if (strcmp2(classname, "rf2_item") || StrContains(classname, "rf2_object") == 0 && !GetEntProp(entity, Prop_Data, "m_bMapPlaced"))
		{
			RemoveEntity(entity);
		}
	}
}

int CreateObject(const char[] classname, float pos[3])
{
	int entity = CreateEntityByName(classname);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);
	
	if (StrContains(classname, "rf2_object_crate") == 0)
	{
		SDKHook(entity, SDKHook_OnTakeDamage, Hook_OnCrateHit);
	}
	
	if (g_cvDebugShowObjectSpawns.BoolValue)
	{
		PrintToServer("[RF2] %s spawned at %.0f %.0f %.0f", classname, pos[0], pos[1], pos[2]);
		PrintToConsoleAll("[RF2] %s spawned at %.0f %.0f %.0f", classname, pos[0], pos[1], pos[2]);
	}
	
	float endPos[3], angles[3];
	angles[0] = 90.0;
	Handle trace = TR_TraceRayFilterEx(pos, angles, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite, TraceFilter_WallsOnly);
	TR_GetEndPosition(endPos, trace);
	delete trace;
	
	if (!TR_PointOutsideWorld(endPos))
	{
		if (!strcmp2(classname, "rf2_object_workbench"))
		{
			angles[0] = GetRandomFloat(-25.0, 25.0);
			angles[1] = GetRandomFloat(-180.0, 180.0);
			angles[2] = GetRandomFloat(-25.0, 25.0);
			TeleportEntity(entity, endPos, angles);
		}
		else
		{
			TeleportEntity(entity, endPos);
		}
	}
	
	return entity;
}

public Action Hook_OnCrateHit(int entity, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePosition[3], int damageCustom)
{
	if (attacker < 1 || attacker > MaxClients || !IsPlayerSurvivor(attacker) || !(damageType & DMG_MELEE))
		return Plugin_Continue;
		
	if (!GetEntProp(entity, Prop_Data, "m_bActive"))
		return Plugin_Continue;
	
	char classname[128];
	GetEntityClassname(entity, classname, sizeof(classname));
	float cost = GetEntPropFloat(entity, Prop_Data, "m_flCost");
	
	if (strcmp2(classname, "rf2_object_crate_haunted"))
	{
		if (g_iPlayerHauntedKeys[attacker] > 0)
		{
			g_iPlayerHauntedKeys[attacker]--;
		}
		else
		{
			EmitSoundToClient(attacker, SOUND_NOPE);
			PrintCenterText(attacker, "You don't have any Haunted Keys to open this!");
			return Plugin_Continue;
		}
	}
	else if (g_flPlayerCash[attacker] >= cost)
	{
		g_flPlayerCash[attacker] -= cost;
	}
	else
	{
		EmitSoundToClient(attacker, SOUND_NOPE);
		PrintCenterText(attacker, "You can't afford to open this! (Cost: $%.0f, you have: $%.0f)", cost, g_flPlayerCash[attacker]);
		return Plugin_Continue;
	}
	
	float pos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
	pos[2] += 40.0;
	
	int item;
	if (strcmp2(classname, "rf2_object_crate_collector"))
	{
		item = GetRandomCollectorItem(view_as<int>(TF2_GetPlayerClass(attacker)));
	}
	else
	{
		item = GetEntProp(entity, Prop_Data, "m_iItem");
	}

	float removeTime, particleRemoveTime;
	
	int particle = CreateEntityByName("info_particle_system");
	switch (GetItemQuality(item))
	{
		case Quality_Unusual:
		{
			EmitAmbientSound(SOUND_DROP_UNUSUAL, pos);
			EmitAmbientSound(SOUND_DROP_UNUSUAL, pos);
			EmitAmbientSound(SOUND_DROP_UNUSUAL, pos);
			EmitAmbientSound(SOUND_DROP_UNUSUAL, pos);
			DispatchKeyValue(particle, "effect_name", PARTICLE_UNUSUAL_CRATE_OPEN);
			
			removeTime = 2.9;
			particleRemoveTime = 10.0;
			CreateTimer(4.0, Timer_UltraRareResponse, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
		}
		case Quality_Haunted:
		{
			EmitAmbientSound(SOUND_DROP_HAUNTED, pos);
			// Doesn't work with "ghost_appearation" for some reason...?
			//TE_TFParticle(PARTICLE_HAUNTED_CRATE_OPEN, pos);
			
			DispatchKeyValue(particle, "effect_name", PARTICLE_HAUNTED_CRATE_OPEN);
			
			int shake = CreateEntityByName("env_shake");
			DispatchKeyValueFloat(shake, "radius", 150.0);
			DispatchKeyValue(shake, "spawnflags", "13");
			DispatchKeyValueFloat(shake, "amplitude", 12.0);
			DispatchKeyValueFloat(shake, "duration", 3.0);
			DispatchKeyValueFloat(shake, "frequency", 20.0);
			
			TeleportEntity(shake, pos, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(shake);
			AcceptEntityInput(shake, "StartShake");
			CreateTimer(3.0, Timer_DeleteEntity, EntIndexToEntRef(shake), TIMER_FLAG_NO_MAPCHANGE);
			particleRemoveTime = 3.0;
		}
		default:
		{
			EmitSoundToAll(SOUND_DROP_DEFAULT, entity);
			DispatchKeyValue(particle, "effect_name", PARTICLE_NORMAL_CRATE_OPEN);
			removeTime = 0.0;
			particleRemoveTime = 3.0;
		}
	}
	
	TeleportEntity(particle, pos);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "Start");
	CreateTimer(particleRemoveTime, Timer_DeleteEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	
	SetEntProp(entity, Prop_Data, "m_bActive", false);
	
	DataPack pack;
	CreateDataTimer(removeTime, Timer_SpawnItem, pack, TIMER_FLAG_NO_MAPCHANGE);
	
	pack.WriteCell(item);
	pack.WriteCell(GetClientUserId(attacker));
	pack.WriteFloat(pos[0]);
	pack.WriteFloat(pos[1]);
	pack.WriteFloat(pos[2]);
	
	CreateTimer(removeTime, Timer_DeleteEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action Timer_UltraRareResponse(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
		
	SetVariantString("TLK_MVM_LOOT_ULTRARARE");
	AcceptEntityInput(client, "SpeakResponseConcept");
	return Plugin_Continue;
}

public Action Timer_SpawnItem(Handle timer, DataPack pack)
{
	int client, item;
	float pos[3];
	
	pack.Reset();
	
	item = pack.ReadCell();
	client = pack.ReadCell();
	pos[0] = pack.ReadFloat();
	pos[1] = pack.ReadFloat();
	pos[2] = pack.ReadFloat();
	
	SpawnItem(item, pos, client);
	return Plugin_Continue;
}

/**
* This is called when a player tries pressing E on an object.
* Example: activating a Teleporter, checking the cost of a crate.
* Non example: Smashing open a crate with a melee weapon.
* Returns true if an object was successfully interacted with.
*/
bool ObjectInteract(int client)
{
	float eyePos[3], eyeAng[3], endPos[3], direction[3];
	GetClientEyePosition(client, eyePos);
	GetClientEyeAngles(client, eyeAng);
	
	GetAngleVectors(eyeAng, direction, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(direction, direction);
	
	const float range = 100.0;
	CopyVectors(eyePos, endPos);
	endPos[0] += direction[0] * range;
	endPos[1] += direction[1] * range;
	endPos[2] += direction[2] * range;
	
	TR_TraceRayFilter(eyePos, endPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter_DontHitSelf, client);
	TR_GetEndPosition(endPos);
	int entity = GetNearestEntityEx(endPos, "rf2_object");
	
	if (entity > 0 && GetEntProp(entity, Prop_Data, "m_bActive"))
	{
		float pos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
		
		char classname[128];
		GetEntityClassname(entity, classname, sizeof(classname));
		
		if (GetVectorDistance(endPos, pos, true) <= sq(range))
		{
			return ActivateObject(client, entity);
		}
	}
	
	return false;
}

bool ActivateObject(int client, int entity)
{
	char classname[128];
	GetEntityClassname(entity, classname, sizeof(classname));
	
	float cost;
	if (HasEntProp(entity, Prop_Data, "m_flCost"))
	{
		cost = GetEntPropFloat(entity, Prop_Data, "m_flCost");
	}
	
	if (cost > 0.0) // Display the cost for this object, but don't try to open it
	{
		PrintCenterText(client, "This costs $%.0f.", cost);
		return true;
	}
	else if (strcmp2(classname, "rf2_object_teleporter"))
	{
		if (g_bGracePeriod || GetRF2GameRules() != INVALID_ENT_REFERENCE && !GetEntProp(GetRF2GameRules(), Prop_Data, "m_bPlayerTeleporterActivation"))
		{
			RF2_PrintToChat(client, "You can't activate the Teleporter right now.");
			return true;
		}
		
		StartTeleporterVote(client, IsStageCleared());
		return true;
	}
	else if (strcmp2(classname, "rf2_object_workbench"))
	{
		ArrayList itemArray = CreateArray();
		int quality = GetEntProp(entity, Prop_Data, "m_iQuality");
		int benchItem = GetEntProp(entity, Prop_Data, "m_iItem");
		int item;
		
		for (int i = 1; i <= GetItemCount(); i++)
		{
			if (i != benchItem && GetItemQuality(i) == quality && PlayerHasItem(client, i))
			{
				if (IsScrapItem(i)) // priority
				{
					item = i;
					break;
				}
				
				itemArray.Push(i);
			}
		}
		
		if (itemArray.Length > 0 && item <= Item_Null)
		{
			item = itemArray.Get(GetRandomInt(0, itemArray.Length-1));
		}
		
		delete itemArray;
		
		if (item > Item_Null)
		{
			GiveItem(client, item, -1);
			GiveItem(client, benchItem, 1);
			EmitSoundToAll(SOUND_USE_WORKBENCH, client);
			PrintCenterText(client, "You traded 1 %s for a %s.", g_szItemName[item], g_szItemName[benchItem]);
			return true;
		}
		else
		{
			char qualityName[32];
			GetQualityName(quality, qualityName, sizeof(qualityName));
			EmitSoundToClient(client, SOUND_NOPE);
			PrintCenterText(client, "You don't have any items to exchange! You need %s quality items.", qualityName);
			return false;
		}
	}
	else if (strcmp2(classname, "rf2_object_scrapper"))
	{
		ShowScrapperMenu(client);
	}
	
	return false;
}

void ShowScrapperMenu(int client, bool message=true)
{
	Menu menu = CreateMenu(Menu_ItemScrapper);
	menu.SetTitle("What would you like to scrap?");
	
	int count, quality;
	char info[8], display[128];
	for (int i = 1; i <= GetItemCount(); i++)
	{
		if (IsScrapItem(i))
			continue;
		
		if (PlayerHasItem(client, i))
		{
			quality = GetItemQuality(i);
			if (quality == Quality_Normal || quality == Quality_Genuine || quality == Quality_Unusual || quality == Quality_Haunted)
			{
				IntToString(i, info, sizeof(info));
				FormatEx(display, sizeof(display), "%s[%i]", g_szItemName[i], GetPlayerItemCount(client, i));
				menu.AddItem(info, display);
				count++;
			}
		}
	}
	
	if (count > 0)
	{
		menu.Display(client, 12);
	}
	else if (message)
	{
		EmitSoundToClient(client, SOUND_NOPE);
		PrintCenterText(client, "You have no items to scrap!");
	}
}

public int Menu_ItemScrapper(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[8];
			menu.GetItem(param2, info, sizeof(info));
			int item = StringToInt(info);
			
			if (PlayerHasItem(param1, item))
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
					GiveItem(param1, scrap, 1);
					PrintCenterText(param1, "You scrapped 1 %s for 1 %s.", g_szItemName[item], g_szItemName[scrap]);
				}
				else // haunted item, give haunted key
				{
					g_iPlayerHauntedKeys[param1]++;
					PrintCenterText(param1, "You scrapped 1 %s for 1 Haunted Key.", g_szItemName[item]);
				}
				
				EmitSoundToClient(param1, SOUND_USE_SCRAPPER);
				ShowScrapperMenu(param1, false);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

void StartTeleporterVote(int client, bool nextStageVote=false)
{
	if (IsVoteInProgress())
	{
		RF2_PrintToChat(client, "There is already a vote in progress. Please wait until it finishes.");
		return;
	}
	
	int clients[MAX_SURVIVORS];
	int clientCount;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i) || !IsPlayerAlive(i))
			continue;
			
		if (IsPlayerSurvivor(i))
		{
			clients[clientCount] = i;
			clientCount++;
			if (clientCount >= MAX_SURVIVORS)
			{
				break;
			}
		}
	}
	
	Menu menu;
	if (nextStageVote)
	{
		menu = CreateMenu(Menu_NextStageVote);
		menu.SetTitle("Depart now? (%N)", client);
	}
	else
	{
		menu = CreateMenu(Menu_TeleporterVote);
		menu.SetTitle("Start the Teleporter event? (%N)", client);
	}
		
	menu.AddItem("Yes", "Yes");
	menu.AddItem("No", "No");
	menu.ExitButton = false;
	VoteMenu(menu, clients, clientCount, 12);
}

public int Menu_TeleporterVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_VoteEnd:
		{
			if (param1 == 0)
			{
				PrepareTeleporterEvent(GetTeleporterEntity());
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public int Menu_NextStageVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_VoteEnd:
		{
			if (param1 == 0)
				ForceTeamWin(TEAM_SURVIVOR);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

void PrepareTeleporterEvent(int teleporter)
{
	SetEntProp(teleporter, Prop_Data, "m_iEventState", TELE_EVENT_PREPARING);
	RF2_PrintToChatAll("The Teleporter has been activated...");
	
	StopMusicTrackAll();
	
	float pos[3];
	SetEntProp(teleporter, Prop_Send, "m_fEffects", 0);
	SetEntProp(teleporter, Prop_Data, "m_bActive", false);
	GetEntPropVector(teleporter, Prop_Data, "m_vecAbsOrigin", pos);
	CreateTimer(3.0, Timer_StartTeleporterEvent, teleporter, TIMER_FLAG_NO_MAPCHANGE);
	
	// start some effects (fog and shake)
	UTIL_ScreenShake(pos, 16.0, 50.0, 3.0, MAX_MAP_SIZE, SHAKE_START, true);
	
	int fog = CreateEntityByName("env_fog_controller");
	DispatchKeyValue(fog, "spawnflags", "1");
	DispatchKeyValueInt(fog, "fogenabled", 1);
	DispatchKeyValueFloat(fog, "fogstart", 100.0);
	DispatchKeyValueFloat(fog, "fogend", 250.0);
	DispatchKeyValueFloat(fog, "fogmaxdensity", 0.7);
	DispatchKeyValue(fog, "fogcolor", "40 0 0");
	
	DispatchSpawn(fog);
	AcceptEntityInput(fog, "TurnOn");			
	
	const float time = 3.0;
	int oldFog[MAXTF2PLAYERS] = {-1, ...};
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i))
			continue;
		
		oldFog[i] = GetEntPropEnt(i, Prop_Data, "m_hCtrl");
		SetEntPropEnt(i, Prop_Data, "m_hCtrl", fog);
		
		DataPack pack;
		CreateDataTimer(time, Timer_RestorePlayerFog, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(GetClientUserId(i));
		pack.WriteCell(EntIndexToEntRef(oldFog[i]));
	}
	
	CreateTimer(time, Timer_KillFog, EntIndexToEntRef(fog), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_StartTeleporterEvent(Handle timer, int entity)
{
	StartTeleporterEvent(entity);
	return Plugin_Continue;
}

void StartTeleporterEvent(int teleporter)
{
	SetEntProp(teleporter, Prop_Data, "m_iEventState", TELE_EVENT_ACTIVE);
	
	Call_StartForward(g_fwTeleEventStart);
	Call_Finish();
	
	int gamerules = GetRF2GameRules();
	if (gamerules != INVALID_ENT_REFERENCE)
	{
		FireEntityOutput(gamerules, "OnTeleporterEventStart");
	}
	
	int bubble = CreateEntityByName("prop_dynamic_override");
	SetEntityModel(bubble, MODEL_TELEPORTER_RADIUS);
	DispatchKeyValue(bubble, "fademaxdist", "0");
	DispatchKeyValue(bubble, "fademindist", "0");
	SetEntityRenderMode(bubble, RENDER_TRANSCOLOR);
	SetEntityRenderColor(bubble, 255, 255, 255, 75);
	const float baseModelScale = 1.55;
	SetEntPropFloat(bubble, Prop_Send, "m_flModelScale", baseModelScale * g_cvTeleporterRadiusMultiplier.FloatValue);
	
	float pos[3];
	GetEntPropVector(teleporter, Prop_Data, "m_vecAbsOrigin", pos);
	TeleportEntity(bubble, pos);
	DispatchSpawn(bubble);
	SetEntPropEnt(teleporter, Prop_Data, "m_hBubble", bubble);
	float radius = TELEPORTER_RADIUS * g_cvTeleporterRadiusMultiplier.FloatValue;
	SetEntPropFloat(teleporter, Prop_Data, "m_flRadius", radius);
	
	// Summon our bosses for this event
	SummonTeleporterBosses(teleporter);
	
	int hhhSpawnCount, eyeSpawnCount;
	const int bossSpawnLimit = 20;
	
	PlayMusicTrackAll();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i) || !IsPlayerAlive(i))
		{
			continue;
		}
			
		if (PlayerHasItem(i, Item_HorsemannHead))
		{
			hhhSpawnCount += GetPlayerItemCount(i, Item_HorsemannHead);
		
			if (hhhSpawnCount > bossSpawnLimit)
				hhhSpawnCount = bossSpawnLimit;
		}
		
		if (PlayerHasItem(i, Item_Monoculus))
		{
			eyeSpawnCount += GetPlayerItemCount(i, Item_Monoculus);
			
			if (eyeSpawnCount > bossSpawnLimit)
				eyeSpawnCount = bossSpawnLimit;
		}
	}
	
	if (hhhSpawnCount > 0 || eyeSpawnCount > 0)
	{
		int boss;
		float resultPos[3];
		float mins[3] = PLAYER_MINS;
		float maxs[3] = PLAYER_MAXS;
		ScaleVector(mins, 1.75);
		ScaleVector(maxs, 1.75);
		const float zOffset = 25.0;
		CNavArea area;
		float time;
		
		while (hhhSpawnCount > 0 || eyeSpawnCount > 0)
		{
			area = GetSpawnPoint(pos, resultPos, 0.0, radius, 4, true, mins, maxs, MASK_NPCSOLID, zOffset);
			if (area)
			{
				if (hhhSpawnCount > 0)
				{
					boss = CreateEntityByName("headless_hatman");
					hhhSpawnCount--;
				}
				else if (eyeSpawnCount > 0)
				{
					boss = CreateEntityByName("eyeball_boss");
					SetEntProp(boss, Prop_Data, "m_iTeamNum", 5);
					eyeSpawnCount--;
				}
				
				TeleportEntity(boss, resultPos);
				
				// this is really just to prevent earrape, especially with Monoculus...
				CreateTimer(time, Timer_DelayHalloweenBossSpawn, boss, TIMER_FLAG_NO_MAPCHANGE);
				time += 0.3;
			}
		}
	}
	
	CreateTimer(0.1, Timer_TeleporterThink, EntIndexToEntRef(teleporter), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_TeleporterThink(Handle timer, int teleporter)
{
	if ((teleporter = EntRefToEntIndex(teleporter)) == INVALID_ENT_REFERENCE)
	{
		return Plugin_Stop;
	}
	
	int aliveSurvivors, aliveBosses;
	float distance;
	float pos[3], telePos[3];
	float radius = GetEntPropFloat(teleporter, Prop_Data, "m_flRadius");
	float charge = GetEntPropFloat(teleporter, Prop_Data, "m_flCharge");
	GetEntPropVector(teleporter, Prop_Data, "m_vecAbsOrigin", telePos);
	
	// calculate alive survivors first
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i) || !IsPlayerAlive(i))
			continue;
		
		if (IsPlayerSurvivor(i))
		{
			aliveSurvivors++;
		}
		else if (g_bPlayerIsTeleporterBoss[i])
		{
			aliveBosses++;
		}
	}
	
	// now let's see how many of them are actually in the radius, so we can add charge based on that
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i) || !IsPlayerAlive(i) || !IsPlayerSurvivor(i))
		{
			continue;
		}
		
		GetClientAbsOrigin(i, pos);
		distance = GetVectorDistance(pos, telePos);
		
		if (distance <= radius)
		{
			if (charge < 100.0)
			{
				charge += 0.1 / aliveSurvivors;
				SetEntPropFloat(teleporter, Prop_Data, "m_flCharge", charge);
			}
			
			FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "Teleporter Charge: %.0f percent...\nBosses Left: %i", charge, aliveBosses);
		}
		else
		{
			strcopy(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "Get inside the Teleporter radius!");
		}
	}
	
	// end once all teleporter bosses are dead and charge is 100%
	if (charge >= 100.0 && aliveBosses == 0)
	{
		EndTeleporterEvent(teleporter);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

void EndTeleporterEvent(int teleporter)
{
	SetEntProp(teleporter, Prop_Data, "m_iEventState", TELE_EVENT_COMPLETE);
	
	bool aliveEnemies;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGameEx(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_ENEMY)
		{
			TF2_StunPlayer(i, 20.0, _, TF_STUNFLAG_BONKSTUCK);
			aliveEnemies = true;
		}
	}
	
	if (aliveEnemies)
	{
		EmitSoundToAll(SOUND_ENEMY_STUN);
	}
	
	EmitSoundToAll(SOUND_TELEPORTER_CHARGED);
	SetEntProp(teleporter, Prop_Send, "m_fEffects", EF_ITEM_BLINK);
	RF2_PrintToChatAll("{lime}Teleporter event completed! {default}Interact with the teleporter again to leave.");
	StopMusicTrackAll();
	
	Call_StartForward(g_fwTeleEventEnd);
	Call_Finish();
	
	int gamerules = GetRF2GameRules();
	if (gamerules != INVALID_ENT_REFERENCE)
	{
		FireEntityOutput(gamerules, "OnTeleporterEventComplete");
	}
}

public Action Timer_DelayHalloweenBossSpawn(Handle timer, int entity)
{
	DispatchSpawn(entity);
	int health = 3000 + (RF2_GetEnemyLevel() * 500);
	SetEntProp(entity, Prop_Data, "m_iMaxHealth", health);
	SetEntProp(entity, Prop_Data, "m_iHealth", health);
	
	return Plugin_Continue;
}

void GetWorldCenter(float vec[3])
{
	if (EntRefToEntIndex(g_iWorldCenterEntity) != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(EntRefToEntIndex(g_iWorldCenterEntity), Prop_Data, "m_vecAbsOrigin", vec);
		return;
	}
	
	int entity = MaxClients+1;
	char targetName[128];
	bool found;
	
	while ((entity = FindEntityByClassname(entity, "info_target")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));
		if (strcmp2(targetName, WORLD_CENTER))
		{
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vec);
			found = true;
			g_iWorldCenterEntity = EntIndexToEntRef(entity);
			break;
		}
	}

	if (!found) // last resort. 0 0 0 is not always the center of the map, but sometimes it is
	{
		CopyVectors(NULL_VECTOR, vec);
	}
}

float GetObjectCostMultiplier()
{
	float value = 1.0 + (g_flDifficultyCoeff / g_cvSubDifficultyIncrement.FloatValue);
	value += FloatFraction(Pow(1.35, float(g_iStagesCompleted)));
	
	if (value < 1.0)
		value = 1.0;
		
	return value;
}

float CalculateObjectCost(int entity)
{
	if (GetEntProp(entity, Prop_Data, "m_bMapPlaced"))
	{
		float cost = GetEntPropFloat(entity, Prop_Data, "m_flCost");
		
		// This object's cost was set by the mapper
		if (cost >= 0.0)
			return cost;
	}
	
	char classname[128];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (strcmp2(classname, "rf2_object_crate"))
	{
		return g_cvObjectBaseCost.FloatValue * GetObjectCostMultiplier();
	}
	else if (strcmp2(classname, "rf2_object_crate_large") || strcmp2(classname, "rf2_object_crate_collector"))
	{
		return g_cvObjectBaseCost.FloatValue * GetObjectCostMultiplier() * 2.0;
	}
	else if (strcmp2(classname, "rf2_object_crate_strange"))
	{
		return g_cvObjectBaseCost.FloatValue * GetObjectCostMultiplier() * 1.5;
	}
	
	return 0.0;
}

int GetTeleporterEntity()
{
	return EntRefToEntIndex(g_iTeleporterEntRef);
}

int GetTeleporterEventState()
{
	int teleporter = GetTeleporterEntity();
	if (teleporter == INVALID_ENT_REFERENCE)
	{
		return TELE_EVENT_INACTIVE;
	}
	
	return GetEntProp(teleporter, Prop_Data, "m_iEventState");
}