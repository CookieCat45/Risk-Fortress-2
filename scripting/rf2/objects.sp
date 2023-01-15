#if defined _RF2_objects_included
 #endinput
#endif
#define _RF2_objects_included

#pragma semicolon 1
#pragma newdecls required

// Doesn't block player movement, but still allowed to be hit by player weapons
#define COLLISION_GROUP_OBJECT COLLISION_GROUP_PROJECTILE

int g_iObjectState[MAX_EDICTS] = {ObjectState_Invalid, ...};
float g_flObjectCost[MAX_EDICTS];
int g_iObjectItem[MAX_EDICTS];
int g_iObjectBenchType[MAX_EDICTS];

float g_flTeleporterRadius;
float g_flTeleporterCharge;
float g_flTeleporterOrigin[3];

int g_iTeleporter = -1;
int g_iTeleporterActivator = -1;
bool g_bTeleporterEventCompleted;

int SpawnObjects()
{
	// Make sure everything is gone first.
	DespawnObjects();
	
	char mapName[PLATFORM_MAX_PATH];
	GetCurrentMap(mapName, sizeof(mapName));
	
	int survivors = g_iSurvivorCount;
	
	char targetName[128];
	int entity;
	if (!g_bTankBossMode)
	{
		entity = MaxClients+1;
		int teleporter[MAX_TELEPORTERS], teleporterCount;
		bool teleporterError;
		// Find our teleporter spawnpoints
		while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
		{
			if (g_iObjectState[entity] == ObjectState_Invalid)
			{
				GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));
				if (strcmp(targetName, OBJECT_TELEPORTER) == 0) // is this a teleporter spawnpoint? if so, add it to our array
				{
					if (teleporterCount > MAX_TELEPORTERS)
					{
						if (!teleporterError)
						{
							LogError("[SpawnObjects] Map \"%s\" has hit the limit of %i for Teleporter spawn points, please reduce the amount!", mapName, MAX_TELEPORTERS);
							teleporterError = true;
						}	
						continue;
					}
					
					teleporter[teleporterCount] = entity;
					teleporterCount++;
				}
			}
		}
		
		// now "spawn" the teleporter at a random location
		int randomTele = GetRandomInt(0, teleporterCount-1);
		SpawnTeleporter(teleporter[randomTele]);
	}
	
	// now spawn objects
	int spawnCount = g_cvObjectBaseCount.IntValue * survivors + RoundToCeil(g_flDifficultyCoeff / (g_cvSubDifficultyIncrement.FloatValue / 5.0));
	int maxSpawns = g_cvMaxObjects.IntValue;
	if (spawnCount > maxSpawns)
		spawnCount = maxSpawns;
	
	int spawns;
	float spawnPos[3];
	
	// Need to get the size of the map so we know how far we can spawn objects
	float worldMins[3];
	float worldMaxs[3];
	GetEntPropVector(0, Prop_Send, "m_WorldMins", worldMins);
	GetEntPropVector(0, Prop_Send, "m_WorldMaxs", worldMaxs);
	
	float length = FloatAbs(worldMins[0]) + FloatAbs(worldMaxs[0]);
	float width = FloatAbs(worldMins[1]) + FloatAbs(worldMaxs[1]);
	float distance = SquareRoot(length * width);
	
	float worldCenter[3];
	GetWorldCenter(worldCenter);
	
	int attempts;
	int nearestObject;
	float nearestObjectPos[3];
	char name[32];
	float spreadDistance = g_cvObjectSpreadDistance.FloatValue;
	
	while (spawns < spawnCount && attempts < 1000)
	{
		GetSpawnPointFromNav(worldCenter, spawnPos, 0.0, distance, _, true);
		nearestObject = GetNearestEntity(spawnPos, "prop_dynamic");
		
		if (nearestObject != -1)
		{
			GetEntPropString(nearestObject, Prop_Data, "m_iName", name, sizeof(name));
			if (StrContains(name, "rf2_") != -1)
			{
				GetEntPropVector(nearestObject, Prop_Data, "m_vecAbsOrigin", nearestObjectPos);
				if (GetVectorDistance(spawnPos, nearestObjectPos, true) <= sq(spreadDistance)) // Too close to another object.
				{
					attempts++;
					continue;
				}
			}
		}
		
		if (RandChanceInt(1, 100, 25))
		{
			switch (GetRandomInt(1, 12))
			{
				case 1, 2: CreateObject(spawnPos, OBJECT_CRATE_LARGE, MODEL_CRATE, 1.3);
				case 3: CreateObject(spawnPos, OBJECT_CRATE_STRANGE, MODEL_CRATE_STRANGE, 0.5);
				case 4:	CreateObject(spawnPos, OBJECT_CRATE_HAUNTED, MODEL_CRATE_HAUNTED, 1.25);
				case 5, 6, 7: CreateObject(spawnPos, OBJECT_CRATE_COLLECTOR, MODEL_CRATE_COLLECTOR);
				case 8, 9, 10: CreateObject(spawnPos, OBJECT_WORKBENCH, MODEL_WORKBENCH);
				case 11, 12: CreateObject(spawnPos, OBJECT_SCRAPPER, MODEL_SCRAPPER, 1.5);
			}
		}
		else
		{
			CreateObject(spawnPos, OBJECT_CRATE, MODEL_CRATE);
		}
		
		spawns++;
	}
	
	// Delete unused spawnpoints.
	entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));
		if (g_iObjectState[entity] != ObjectState_Active && strcmp(targetName, OBJECT_TELEPORTER) == 0)
		{
			RemoveEntity(entity);
		}
	}
	
	return spawns;
}

void DespawnObjects()
{
	int teleporterSpawns;
	char targetName[128];
	
	// find all placed objects when the map starts
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{	
		GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));
		if (StrContains(targetName, "rf2_object") != -1)
		{
			if (strcmp(targetName, OBJECT_TELEPORTER) == 0) // teleporters are handled differently
			{
				SetEntityModel(entity, MODEL_INVISIBLE);
				AcceptEntityInput(entity, "DisableCollision");
				teleporterSpawns++;
			}
			else
			{
				RemoveEntity(entity);	
			}
			
			g_iObjectState[entity] = ObjectState_Invalid;
		}
	}
	
	// delete items as well
	entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "env_sprite")) != -1)
	{	
		GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));
		if (StrContains(targetName, "rf2_object") != -1)
		{
			RemoveEntity(entity);
		}
	}
}

int CreateObject(float pos[3], const char[] type, const char[] model, float modelScale=1.0, 
bool collision=true, int collisionGroup=COLLISION_GROUP_OBJECT, int solidType=SOLID_BBOX)
{
	int entity = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(entity, "model", model);
	DispatchKeyValue(entity, "targetname", type);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);
	SetEntProp(entity, Prop_Send, "m_fEffects", EF_ITEM_BLINK);
	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", modelScale);
	
	float costMultiplier = GetObjectCostMultiplier();
	
	int sprite = -1;
	if (StrContains(type, OBJECT_CRATE) != -1)
	{
		if (strcmp(type, OBJECT_CRATE) == 0)
		{
			g_flObjectCost[entity] = g_cvObjectBaseCost.FloatValue * costMultiplier;
			g_iObjectItem[entity] = GetRandomItem(79, 20, 1);
		}
		else if (strcmp(type, OBJECT_CRATE_LARGE) == 0)
		{
			g_flObjectCost[entity] = g_cvObjectBaseCost.FloatValue * costMultiplier * 2.0;
			g_iObjectItem[entity] = GetRandomItem(0, 85, 15);
		}
		else if (strcmp(type, OBJECT_CRATE_STRANGE) == 0)
		{
			g_flObjectCost[entity] = g_cvObjectBaseCost.FloatValue * costMultiplier * 1.5;
			g_iObjectItem[entity] = GetRandomItemEx(Quality_Strange);
			SetEntityRenderColor(entity, 255, 100, 0);
		}
		else if (strcmp(type, OBJECT_CRATE_HAUNTED) == 0)
		{
			// we take haunted keys
			g_iObjectItem[entity] = GetRandomItemEx(Quality_Haunted);
		}
		else if (strcmp(type, OBJECT_CRATE_COLLECTOR) == 0)
		{
			// our item is decided when we're opened
			g_flObjectCost[entity] = g_cvObjectBaseCost.FloatValue * costMultiplier * 2.0;
		}
		
		SDKHook(entity, SDKHook_OnTakeDamage, Hook_OnCrateHit);
	}
	else if (strcmp(type, OBJECT_WORKBENCH) == 0)
	{
		int result;
		if (RandChanceInt(1, 100, 65, result))
		{
			g_iObjectBenchType[entity] = Quality_Normal;
		}
		else if (result <= 95)
		{
			g_iObjectBenchType[entity] = Quality_Genuine;
		}
		else
		{
			g_iObjectBenchType[entity] = Quality_Unusual;
		}
		
		g_iObjectItem[entity] = GetRandomItemEx(g_iObjectBenchType[entity]);
		sprite = CreateEntityByName("env_sprite");
		DispatchKeyValue(sprite, "model", g_szItemSprite[g_iObjectItem[entity]]);
		DispatchKeyValueFloat(sprite, "scale", g_flItemSpriteScale[g_iObjectItem[entity]]);
		DispatchKeyValue(sprite, "rendermode", "9");
	}
	
	if (collision)
	{
		AcceptEntityInput(entity, "EnableCollision");
		SetEntProp(entity, Prop_Send, "m_nSolidType", solidType);
		SetEntityCollisionGroup(entity, collisionGroup);
	}
	else
	{
		AcceptEntityInput(entity, "DisableCollision");
	}
	
	if (g_cvDebugShowObjectSpawns.BoolValue)
	{
		PrintToServer("[RF2] %s spawned at %.0f %.0f %.0f, cost %.0f", type, pos[0], pos[1], pos[2], g_flObjectCost[entity]);
		PrintToConsoleAll("[RF2] %s spawned at %.0f %.0f %.0f, cost %.0f", type, pos[0], pos[1], pos[2], g_flObjectCost[entity]);
	}
	
	float endPos[3];
	float angles[3];
	angles[0] = 90.0;
	Handle trace = TR_TraceRayFilterEx(pos, angles, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite, TraceWallsOnly);
	TR_GetEndPosition(endPos, trace);
	delete trace;
	
	if (!TR_PointOutsideWorld(endPos))
	{
		if (strcmp(type, OBJECT_WORKBENCH) != 0)
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
	
	if (sprite > -1)
	{
		float spritePos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", spritePos);
		spritePos[2] += 50.0;
		TeleportEntity(sprite, spritePos);
		DispatchSpawn(sprite);
		
		SetEntPropString(entity, Prop_Data, "m_iName", "sprite_parent_name");
		SetVariantString("sprite_parent_name");
		AcceptEntityInput(sprite, "SetParent");
		SetEntPropString(entity, Prop_Data, "m_iName", type);
	}
	
	// Non-solid. Shrink bounding box to prevent blockage of AI line of sight.
	if (!collision || collisionGroup == COLLISION_GROUP_OBJECT)
	{
		SetEntPropVector(entity, Prop_Send, "m_vecSpecifiedSurroundingMins", {0.0, 0.0, 0.0});
		SetEntPropVector(entity, Prop_Send, "m_vecSpecifiedSurroundingMaxs", {0.0, 0.0, 0.0});
	}
	
	g_iObjectState[entity] = ObjectState_Active;
	return entity;
}

float GetObjectCostMultiplier()
{
	float value = 1.0 + (g_flDifficultyCoeff / g_cvSubDifficultyIncrement.FloatValue);
	value += FloatFraction(Pow(1.35, float(g_iStagesCompleted)));
	
	if (value < 1.0)
		value = 1.0;
		
	return value;
}

static void SpawnTeleporter(int entity)
{
	if (GetTeleporterEntity() != -1)
	{
		LogError("[SpawnTeleporter] Attempted to spawn a Teleporter entity, but one already exists. Only one should exist at a time.");
		return;
	}
	
	g_iTeleporter = entity;
	SetEntityModel(entity, MODEL_TELEPORTER);
	SetEntPropString(entity, Prop_Data, "m_iName", OBJECT_TELEPORTER);
	AcceptEntityInput(entity, "EnableCollision");
	SetEntProp(entity, Prop_Send, "m_fEffects", EF_ITEM_BLINK);
	
	if (g_cvDebugShowObjectSpawns.BoolValue)
	{
		float pos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
		
		PrintToServer("[RF2] %s spawned at %.0f %.0f %.0f", OBJECT_TELEPORTER, pos[0], pos[1], pos[2]);
		PrintToConsoleAll("[RF2] %s spawned at %.0f %.0f %.0f", OBJECT_TELEPORTER, pos[0], pos[1], pos[2]);
	}

	g_iObjectState[entity] = ObjectState_Active;
}

public Action Hook_OnCrateHit(int entity, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePosition[3], int damageCustom)
{
	if (g_iObjectState[entity] != ObjectState_Active)
		return Plugin_Continue;
	
	if (attacker > 0 && attacker <= MaxClients && IsPlayerSurvivor(attacker))
	{
		if (damageType & DMG_MELEE)
		{
			char name[64];
			GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
			
			if (strcmp(name, OBJECT_CRATE_HAUNTED) != 0)
			{
				if (g_flPlayerCash[attacker] >= g_flObjectCost[entity])
				{
					g_flPlayerCash[attacker] -= g_flObjectCost[entity];
				}
				else
				{
					EmitSoundToClient(attacker, NOPE);
					PrintCenterText(attacker, "You can't afford to open this! (Cost: $%.0f, you have: $%.0f)", g_flObjectCost[entity], g_flPlayerCash[attacker]);
					return Plugin_Continue;
				}
			}
			else if (g_iPlayerHauntedKeys[attacker] > 0) // haunted crate
			{
				g_iPlayerHauntedKeys[attacker]--;
			}
			else
			{
				EmitSoundToClient(attacker, NOPE);
				PrintCenterText(attacker, "You don't have any Haunted Keys to open this!");
				return Plugin_Continue;
			}
			
			float origin[3];
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", origin);
			origin[2] += 40.0;
			
			int item;
			if (strcmp(name, OBJECT_CRATE_COLLECTOR) == 0)
			{
				item = GetRandomCollectorItem(view_as<int>(TF2_GetPlayerClass(attacker)));
			}
			else
			{
				item = g_iObjectItem[entity];
			}

			float removeTime;
			
			switch (GetItemQuality(item))
			{
				case Quality_Unusual:
				{
					EmitAmbientSound(SOUND_DROP_UNUSUAL, origin);
					EmitAmbientSound(SOUND_DROP_UNUSUAL, origin);
					EmitAmbientSound(SOUND_DROP_UNUSUAL, origin);
					EmitAmbientSound(SOUND_DROP_UNUSUAL, origin);
					TE_SetupParticle(PARTICLE_UNUSUAL_CRATE_OPEN, origin);
					
					removeTime = 2.9;
					CreateTimer(4.0, Timer_UltraRareResponse, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
				}
				case Quality_Haunted:
				{
					EmitAmbientSound(SOUND_DROP_HAUNTED, origin);
					// Doesn't work with "ghost_appearation" for some reason...?
					//TE_SetupParticle(PARTICLE_HAUNTED_CRATE_OPEN, origin);
					
					int particle = CreateEntityByName("info_particle_system");
					DispatchKeyValue(particle, "effect_name", PARTICLE_HAUNTED_CRATE_OPEN);
					TeleportEntity(particle, origin);
					DispatchSpawn(particle);
					ActivateEntity(particle);
					AcceptEntityInput(particle, "Start");
					CreateTimer(3.0, Timer_DeleteEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
					
					int shake = CreateEntityByName("env_shake");
					DispatchKeyValueFloat(shake, "radius", 150.0);
					DispatchKeyValue(shake, "spawnflags", "13");
					DispatchKeyValueFloat(shake, "amplitude", 12.0);
					DispatchKeyValueFloat(shake, "duration", 3.0);
					DispatchKeyValueFloat(shake, "frequency", 20.0);
					
					TeleportEntity(shake, origin, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(shake);
					AcceptEntityInput(shake, "StartShake");
					CreateTimer(3.0, Timer_DeleteEntity, EntIndexToEntRef(shake), TIMER_FLAG_NO_MAPCHANGE);
				}
				default:
				{
					EmitSoundToAll(SOUND_DROP_DEFAULT, entity);
					TE_SetupParticle(PARTICLE_NORMAL_CRATE_OPEN, origin);
					removeTime = 0.0;
				}
			}
			
			g_iObjectState[entity] = ObjectState_Inactive;

			DataPack pack;
			CreateDataTimer(removeTime, Timer_SpawnItem, pack, TIMER_FLAG_NO_MAPCHANGE);
			
			pack.WriteCell(GetClientUserId(attacker));
			pack.WriteCell(item);
			pack.WriteFloat(origin[0]);
			pack.WriteFloat(origin[1]);
			pack.WriteFloat(origin[2]);
			
			CreateTimer(removeTime, Timer_DeleteEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
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
	int client;
	int item;
	float pos[3];
	
	pack.Reset();
	client = pack.ReadCell();
	if ((client = GetClientOfUserId(client)) == 0)
		client = -1;
	
	item = pack.ReadCell();
	pos[0] = pack.ReadFloat();
	pos[1] = pack.ReadFloat();
	pos[2] = pack.ReadFloat();
	
	SpawnItem(item, pos, client);
	return Plugin_Continue;
}

/*This is called when pressing E on an object.
* Example: activating a Teleporter, checking the cost of a crate.
* Non example: Smashing open a crate with a melee weapon.
* Returns true if an object was successfully interacted with.*/
bool ObjectInteract(int client)
{
	float eyePos[3], eyeAng[3], endPos[3], direction[3];
	GetClientEyePosition(client, eyePos);
	CopyVectors(eyePos, endPos);
	
	GetClientEyeAngles(client, eyeAng);
	GetAngleVectors(eyeAng, direction, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(direction, direction);
	
	endPos[0] += direction[0] * 100.0;
	endPos[1] += direction[1] * 100.0;
	endPos[2] += direction[2] * 100.0;
	
	TR_TraceRayFilter(eyePos, endPos, MASK_SOLID, RayType_EndPoint, TraceDontHitSelf, client);
	int obj = GetNearestEntity(endPos, "prop_dynamic");
	if (IsValidEntity(obj) && g_iObjectState[obj] == ObjectState_Active)
	{
		float objPos[3];
		GetEntPropVector(obj, Prop_Data, "m_vecAbsOrigin", objPos);
		if (GetVectorDistance(endPos, objPos, true) <= sq(150.0))
		{
			char targetName[128];
			GetEntPropString(obj, Prop_Data, "m_iName", targetName, sizeof(targetName));
			return ActivateObject(client, obj, targetName);
		}
	}
	
	return false;
}

bool ActivateObject(int client, int obj, const char[] targetName)
{
	if (g_flObjectCost[obj] > 0.0) // Display the cost for this object, but don't try to open it
	{
		PrintCenterText(client, "This costs $%.0f.", g_flObjectCost[obj]);
		return true;
	}
	else if (strcmp(targetName, OBJECT_TELEPORTER) == 0)
	{	
		if (g_bGracePeriod)
		{
			RF2_PrintToChat(client, "You can't activate the Teleporter right now.");
			return true;
		}
		
		StartTeleporterVote(client, g_bTeleporterEventCompleted);
		return true;
	}
	else if (strcmp(targetName, OBJECT_WORKBENCH) == 0)
	{
		ArrayList itemArray = CreateArray(1, g_iItemCount);
		int quality = g_iObjectBenchType[obj];
		int count, item;
		bool result;
		
		for (int i = 1; i < g_iItemCount; i++)
		{
			if (i != g_iObjectItem[obj] && GetItemQuality(i) == quality && PlayerHasItem(client, i))
			{
				if (i == Item_ScrapMetal || i == Item_ReclaimedMetal || i == Item_RefinedMetal)
				{
					item = i;
					break;
				}
				
				itemArray.Set(count, i);
				count++;
			}
		}
		
		if (count > 0 && item <= Item_Null)
		{
			item = itemArray.Get(GetRandomInt(0, count-1));
		}
		
		if (item > Item_Null)
		{
			GiveItem(client, item, -1);
			GiveItem(client, g_iObjectItem[obj], 1);
			EmitSoundToAll(SOUND_USE_WORKBENCH, client);
			PrintCenterText(client, "You traded 1 %s for a %s.", g_szItemName[item], g_szItemName[g_iObjectItem[obj]]);
			result = true;
		}
		else
		{
			char qualityName[32];
			GetQualityName(quality, qualityName, sizeof(qualityName));
			EmitSoundToClient(client, NOPE);
			PrintCenterText(client, "You don't have any items to exchange! You need %s quality items.", qualityName);
			result = false;
		}
		
		delete itemArray;
		return result;
	}
	else if (strcmp(targetName, OBJECT_SCRAPPER) == 0)
	{
		ShowScrapperMenu(client);
	}
	
	return false;
}

void ShowScrapperMenu(int client, bool message=true)
{
	Menu menu = CreateMenu(Menu_ItemScrapper);
	SetMenuTitle(menu, "What would you like to scrap?");
	
	int count;
	int quality;
	char info[8];
	char display[128];
	for (int i = 1; i < g_iItemCount; i++)
	{
		if (i == Item_ScrapMetal || i == Item_ReclaimedMetal || i == Item_RefinedMetal)
			continue;
		
		if (PlayerHasItem(client, i))
		{
			quality = GetItemQuality(i);
			if (quality == Quality_Normal || quality == Quality_Genuine || quality == Quality_Unusual || quality == Quality_Haunted)
			{
				IntToString(i, info, sizeof(info));
				FormatEx(display, sizeof(display), "%s[%i]", g_szItemName[i], g_iPlayerItem[client][i]);
				AddMenuItem(menu, info, display);
				count++;
			}
		}
	}
	
	if (count > 0)
	{
		DisplayMenu(menu, client, 12);
	}
	else if (message)
	{
		EmitSoundToClient(client, NOPE);
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
			GetMenuItem(menu, param2, info, sizeof(info));
			int item = StringToInt(info);
			
			if (PlayerHasItem(param1, item))
			{
				GiveItem(param1, item, -1);
				int quality = GetItemQuality(item);
				int scrap = -1;
				
				switch (quality)
				{
					case Quality_Normal: scrap = Item_ScrapMetal;
					case Quality_Genuine: scrap = Item_ReclaimedMetal;
					case Quality_Unusual: scrap = Item_RefinedMetal;
				}
				
				if (scrap > -1)
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
	
	g_iTeleporterActivator = GetClientUserId(client);
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
				break;
		}
	}
	
	Handle menu;
	if (nextStageVote)
	{
		menu = CreateMenu(Menu_NextStageVote);
		SetMenuTitle(menu, "Depart now? (%N)", client);
	}
	else
	{
		menu = CreateMenu(Menu_TeleporterVote);
		SetMenuTitle(menu, "Start the Teleporter event? (%N)", client);
	}
		
	AddMenuItem(menu, "Yes", "Yes");
	AddMenuItem(menu, "No", "No");
	SetMenuExitButton(menu, false);
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
				PrepareTeleporterEvent();
			}
			else
			{
				g_iTeleporterActivator = -1;
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

void PrepareTeleporterEvent()
{
	g_iTeleporterActivator = GetClientOfUserId(g_iTeleporterActivator);
	if (!IsValidClient(g_iTeleporterActivator) || !IsPlayerSurvivor(g_iTeleporterActivator))
	{
		g_iTeleporterActivator = -1;
	}
	
	g_bTeleporterEventPreparing = true;
	
	if (g_iTeleporterActivator > 0)
	{
		RF2_PrintToChatAll("%N activated the Teleporter...", g_iTeleporterActivator);
	}
	else
	{
		RF2_PrintToChatAll("The Teleporter has been activated...");
	}
	
	int teleporter = GetTeleporterEntity();
	SetEntProp(teleporter, Prop_Send, "m_fEffects", 0);
	GetEntPropVector(teleporter, Prop_Data, "m_vecAbsOrigin", g_flTeleporterOrigin);
	CreateTimer(3.0, Timer_StartTeleporterEvent, teleporter, TIMER_FLAG_NO_MAPCHANGE);

	// start some effects (fog and shake)
	int shake = CreateEntityByName("env_shake");
	DispatchKeyValue(shake, "spawnflags", "9");
	DispatchKeyValueFloat(shake, "radius", MAX_MAP_SIZE);
	DispatchKeyValueFloat(shake, "amplitude", 16.0);
	DispatchKeyValueFloat(shake, "duration", 3.0);
	DispatchKeyValueFloat(shake, "frequency", 50.0);
	
	DispatchSpawn(shake);
	TeleportEntity(shake, g_flTeleporterOrigin, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(shake, "StartShake");
	
	CreateTimer(3.0, Timer_DeleteEntity, EntIndexToEntRef(shake), TIMER_FLAG_NO_MAPCHANGE);
	
	int fog = CreateEntityByName("env_fog_controller");
	DispatchKeyValue(fog, "spawnflags", "1");
	DispatchKeyValueInt(fog, "fogenabled", 1);
	DispatchKeyValueFloat(fog, "fogstart", 100.0);
	DispatchKeyValueFloat(fog, "fogend", 250.0);
	DispatchKeyValueFloat(fog, "fogmaxdensity", 0.7);
	DispatchKeyValue(fog, "fogcolor", "40 0 0");
	
	DispatchSpawn(fog);
	AcceptEntityInput(fog, "TurnOn");			
		
	StopMusicTrackAll();
	
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

static void StartTeleporterEvent(int entity)
{
	g_bTeleporterEvent = true;
	g_bTeleporterEventPreparing = false;
	
	float teleporterRadiusMultiplier = g_cvTeleporterRadiusMultiplier.FloatValue;
	g_flTeleporterRadius = TELEPORTER_RADIUS * teleporterRadiusMultiplier;
	
	Call_StartForward(f_TeleEventStart);
	Call_PushCell(g_iTeleporterActivator);
	Call_Finish();
	
	const float baseModelScale = 1.55;
	float modelScale = baseModelScale * teleporterRadiusMultiplier;
	char buffer[16];
	FloatToString(modelScale, buffer, sizeof(buffer));
	
	int radiusProp = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(radiusProp, "modelscale", buffer);
	DispatchKeyValue(radiusProp, "fademaxdist", "0");
	DispatchKeyValue(radiusProp, "fademindist", "0");
	DispatchKeyValue(radiusProp, "model", MODEL_TELEPORTER_RADIUS);

	DispatchSpawn(radiusProp);
	TeleportEntity(radiusProp, g_flTeleporterOrigin, NULL_VECTOR, NULL_VECTOR);
	SetEntityRenderMode(radiusProp, RENDER_TRANSCOLOR);
	SetEntityRenderColor(radiusProp, 255, 255, 255, 75);
	
	// Summon our bosses for this event
	SummonTeleporterBosses(entity);
	
	int spawnCount;
	int eyeSpawnCount;
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
			spawnCount += g_iPlayerItem[i][Item_HorsemannHead];
		
			if (spawnCount > bossSpawnLimit)
				spawnCount = bossSpawnLimit;
		}
		
		if (PlayerHasItem(i, Item_Monoculus))
		{
			eyeSpawnCount += g_iPlayerItem[i][Item_Monoculus];
			
			if (eyeSpawnCount > bossSpawnLimit)
				eyeSpawnCount = bossSpawnLimit;
		}
	}
	
	if (spawnCount > 0 || eyeSpawnCount > 0)
	{
		int boss;
		float resultPos[3];
		float mins[3] = PLAYER_MINS;
		float maxs[3] = PLAYER_MAXS;
		ScaleVector(mins, 1.75);
		ScaleVector(maxs, 1.75);
		const float zOffset = 25.0;
		char mapName[256];
		CNavArea area;
		float time;
		
		while (spawnCount > 0 || eyeSpawnCount > 0)
		{
			area = GetSpawnPointFromNav(g_flTeleporterOrigin, resultPos, 0.0, g_flTeleporterRadius, 4, true, mins, maxs, MASK_NPCSOLID, zOffset);
			if (area != NULL_AREA)
			{
				if (spawnCount > 0)
				{
					boss = CreateEntityByName("headless_hatman");
					spawnCount--;
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
			else
			{
				GetCurrentMap(mapName, sizeof(mapName));
				LogError("[NAV] NavArea was somehow NULL_AREA on map \"%s\". This is either a bug or a NavMesh issue!", mapName);
			}
		}
	}
	
	CreateTimer(0.1, Timer_TeleporterThink, entity, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_TeleporterThink(Handle timer, int entity)
{
	int aliveSurvivors;
	int aliveBosses;
	float origin[3];
	
	// calculate alive survivors first
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i) || !IsPlayerAlive(i))
			continue;
		
		if (IsPlayerSurvivor(i))
			aliveSurvivors++;
		else if (g_bPlayerIsTeleporterBoss[i])
			aliveBosses++;
	}
	
	// now let's see how many of them are actually in the radius, so we can add charge based on that
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i) || !IsPlayerAlive(i) || !IsPlayerSurvivor(i))
		{
			continue;
		}
		
		GetClientAbsOrigin(i, origin);
		
		float distance;
		distance = GetVectorDistance(origin, g_flTeleporterOrigin);
		
		if (distance <= g_flTeleporterRadius)
		{
			g_flTeleporterCharge += 0.1 / aliveSurvivors;
			if (g_flTeleporterCharge > 100.0)
				g_flTeleporterCharge = 100.0;
			
			FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "Teleporter Charge: %.0f percent...\nBosses Left: %i", g_flTeleporterCharge, aliveBosses);
		}
		else
		{
			strcopy(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "Get inside the Teleporter radius!");
		}
	}
	
	// end once all teleporter bosses are dead and charge is 100%
	if (g_flTeleporterCharge >= 100.0 && aliveBosses == 0)
	{
		EndTeleporterEvent();
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

static void EndTeleporterEvent()
{
	g_flTeleporterCharge = 0.0;
	g_bTeleporterEvent = false;
	g_bTeleporterEventCompleted = true;
	
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
	SetEntProp(GetTeleporterEntity(), Prop_Send, "m_fEffects", EF_ITEM_BLINK);
	
	int entity = MaxClients+1;
	char modelName[PLATFORM_MAX_PATH];
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_ModelName", modelName, sizeof(modelName));
		if (strcmp(modelName, MODEL_TELEPORTER_RADIUS) == 0)
		{
			RemoveEntity(entity);
			break;
		}
	}
	
	RF2_PrintToChatAll("{lime}Teleporter event completed! {default}Interact with the teleporter again to leave.");
	StopMusicTrackAll();
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
	if (IsValidEntity(g_iWorldCenterEntity))
	{
		GetEntPropVector(g_iWorldCenterEntity, Prop_Data, "m_vecAbsOrigin", vec);
		return;
	}
	
	int entity = MaxClients+1;
	char targetName[128];
	bool found;
	
	while ((entity = FindEntityByClassname(entity, "info_target")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));
		if (strcmp(targetName, WORLD_CENTER) == 0)
		{
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vec);
			found = true;
			g_iWorldCenterEntity = entity;
			break;
		}
	}

	if (!found) // last resort. 0 0 0 is not always the center of the map, but sometimes it is
	{
		CopyVectors(NULL_VECTOR, vec);
	}
}

int GetTeleporterEntity()
{
	return g_iTeleporter;
}

float GetTeleporterRadius()
{
	return g_flTeleporterRadius;
}