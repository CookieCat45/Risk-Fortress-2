#if defined _RF2_objects_included
 #endinput
#endif
#define _RF2_objects_included

RF2ObjectState g_eObjectState[MAX_EDICTS] = {ObjectState_Inactive, ...};
float g_flObjectCost[MAX_EDICTS];
int g_iObjectItem[MAX_EDICTS];

float g_flTeleporterRadius;
float g_flTeleporterCharge;
float g_flTeleporterOrigin[3];

int g_iTeleporter = -1;
int g_iTeleporterActivator = -1;
bool g_bTeleporterEvent;
bool g_bTeleporterEventCompleted;

char g_szTeleporterHud[MAXTF2PLAYERS][64];

int SpawnObjects()
{
	DespawnObjects();
	SetRandomSeed(g_iSeed+g_iStagesCompleted);
	
	char mapName[PLATFORM_MAX_PATH];
	GetCurrentMap(mapName, sizeof(mapName));
	
	int teleporter[MAX_TELEPORTERS], teleporterCount;
	bool teleporterError;
	
	int survivors = g_iSurvivorCount;
	
	// Find our teleporter spawnpoints
	char targetName[128];
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		if (g_eObjectState[entity] == ObjectState_Inactive)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));
			if (strcmp(targetName, OBJECT_TELEPORTER) == 0) // is this a teleporter spawnpoint? if so, add it to our array
			{
				if (teleporterCount > MAX_TELEPORTERS)
				{
					if (!teleporterError)
					{
						LogError("Map \"%s\" has hit the limit of %i for Teleporter spawn points, please reduce the amount!", mapName, MAX_TELEPORTERS);
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
	
	// now spawn objects
	int spawnCount = BASE_OBJECT_COUNT * survivors + RoundFloat(g_flDifficultyCoeff / (g_flSubDifficultyIncrement / 5.0));
	if (spawnCount > MAX_OBJECTS)
		spawnCount = MAX_OBJECTS;
		
	int crateCount = RoundToFloor(flt(spawnCount) * GetRandomFloat(0.6, 0.7)); // 60% to 70% of all objects will be crates
	//int miscCount = spawnCount - crateCount;
	
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
	PrintToServer("[RF2] World center: %.0f %.0f %.0f", worldCenter[0], worldCenter[1], worldCenter[2]);
	
	while (spawns < spawnCount)
	{
		GetSpawnPointFromNav(worldCenter, spawnPos, 0.0, distance, true);
		
		if (crateCount > 0)
		{
			CreateObject(spawnPos, OBJECT_CRATE, MODEL_CRATE, true, SOLID_BBOX);
			crateCount--;
		}
		
		spawns++;
	}
	
	// delete unused spawnpoints
	entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));
		if (g_eObjectState[entity] != ObjectState_Active && strcmp(targetName, OBJECT_TELEPORTER) == 0)
			RemoveEntity(entity);
	}
	
	PrintToServer("Total objects spawned: %i", spawns);
	return spawns;
}

void DespawnObjects(bool logSpawns = false)
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
			g_eObjectState[entity] = ObjectState_Inactive;
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
	
	if (logSpawns)
		LogMessage("Teleporter spawnpoints: %i", teleporterSpawns);
}

int CreateObject(float pos[3], const char[] name, const char[] model, bool collision=true, int solidType=SOLID_BBOX)
{
	int entity = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(entity, "model", model);
	DispatchKeyValue(entity, "targetname", name);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);
	
	float costMultiplier = 1.0 + (g_flDifficultyCoeff / g_flSubDifficultyIncrement);
	costMultiplier += FloatFraction(Pow(1.2, flt(g_iStagesCompleted)));
	
	if (costMultiplier < 1.0)
		costMultiplier = 1.0;
	
	if (strcmp(name, OBJECT_CRATE) == 0)
	{
		g_flObjectCost[entity] = CRATE_BASE_COST * costMultiplier;
		g_iObjectItem[entity] = GetRandomItem(79.0, 20.0, 1.0);
		
		SDKHook(entity, SDKHook_OnTakeDamage, Hook_OnCrateHit);
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		CreateTimer(0.5, Timer_ObjectGlow, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (collision)
	{
		AcceptEntityInput(entity, "EnableCollision");
		SetEntProp(entity, Prop_Send, "m_nSolidType", solidType);
	}
	else
	{
		AcceptEntityInput(entity, "DisableCollision");
	}
	
	if (GetConVarBool(g_cvShowObjectSpawns))
	{
		PrintToServer("[RF2] %s spawned at %.0f %.0f %.0f, cost %.0f", name, pos[0], pos[1], pos[2], g_flObjectCost[entity]);
		PrintToConsoleAll("[RF2] %s spawned at %.0f %.0f %.0f, cost %.0f", name, pos[0], pos[1], pos[2], g_flObjectCost[entity]);
	}
	
	g_eObjectState[entity] = ObjectState_Active;
	return entity;
}

void SpawnTeleporter(int entity)
{
	if (g_iTeleporter != -1)
	{
		LogError("Attempted to spawn a Teleporter entity, but one already exists. Only one should exist at a time.");
		return;
	}
	
	g_iTeleporter = entity;
	SetEntityModel(entity, MODEL_TELEPORTER);
	SetEntPropString(entity, Prop_Data, "m_iName", OBJECT_TELEPORTER);
	AcceptEntityInput(entity, "EnableCollision");
	
	if (GetConVarBool(g_cvShowObjectSpawns))
	{
		float pos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
		
		PrintToServer("[RF2] %s spawned at %.0f %.0f %.0f", OBJECT_TELEPORTER, pos[0], pos[1], pos[2]);
		PrintToConsoleAll("[RF2] %s spawned at %.0f %.0f %.0f", OBJECT_TELEPORTER, pos[0], pos[1], pos[2]);
	}
	g_eObjectState[entity] = ObjectState_Active;
}

public Action Hook_OnCrateHit(int entity, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (g_eObjectState[entity] != ObjectState_Active)
		return;
	
	if (IsValidClient(attacker) && g_iPlayerSurvivorIndex[attacker] > -1)
	{
		// Melee damage only
		if (damagetype & DMG_CLUB || damagetype & DMG_SLASH)
		{
			if (g_flPlayerCash[attacker] >= g_flObjectCost[entity])
			{
				g_flPlayerCash[attacker] -= g_flObjectCost[entity];
			}
			else
			{
				EmitSoundToClient(attacker, NOPE);
				PrintCenterText(attacker, "You can't afford to open this! (Cost: $%.0f, you have: $%.0f)", g_flObjectCost[entity], g_flPlayerCash[attacker]);
				return;
			}
			
			float origin[3];
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", origin);
			origin[2] += 40.0;
			
			int item = g_iObjectItem[entity];
			float removeTime;
			
			switch (g_eItemQuality[item])
			{
				case Quality_Normal, Quality_Genuine:
				{
					EmitSoundToAll(SOUND_DROP_DEFAULT, entity);
					TE_SetupParticle(PARTICLE_NORMAL_CRATE_OPEN, origin);
					
					g_eObjectState[entity] = ObjectState_Inactive;
					removeTime = 0.0;
				}
				case Quality_Unusual:
				{
					int soundEntity = CreateEntityByName("info_target");
					TeleportEntity(soundEntity, origin, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(soundEntity);
					
					EmitSoundToAll(SOUND_DROP_UNUSUAL, soundEntity);
					EmitSoundToAll(SOUND_DROP_UNUSUAL, soundEntity);
					EmitSoundToAll(SOUND_DROP_UNUSUAL, soundEntity);
					EmitSoundToAll(SOUND_DROP_UNUSUAL, soundEntity);
					TE_SetupParticle(PARTICLE_UNUSUAL_CRATE_OPEN, origin);
					
					g_eObjectState[entity] = ObjectState_Inactive;
					removeTime = 2.9;
					
					CreateTimer(4.0, Timer_UltraRareResponse, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
					
					CreateTimer(18.0, Timer_DeleteEntity, EntIndexToEntRef(soundEntity), TIMER_FLAG_NO_MAPCHANGE);
				}
			}

			DataPack pack;
			CreateDataTimer(removeTime, Timer_SpawnItem, pack, TIMER_FLAG_NO_MAPCHANGE);
			
			pack.WriteCell(item);
			pack.WriteFloat(origin[0]);
			pack.WriteFloat(origin[1]);
			pack.WriteFloat(origin[2]);
			
			CreateTimer(removeTime, Timer_DeleteEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Timer_UltraRareResponse(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return;
		
	SetVariantString("TLK_MVM_LOOT_ULTRARARE");
	AcceptEntityInput(client, "SpeakResponseConcept");
}

public Action Timer_SpawnItem(Handle timer, DataPack pack)
{
	int item;
	float pos[3];
	
	pack.Reset();
	item = pack.ReadCell();
	pos[0] = pack.ReadFloat();
	pos[1] = pack.ReadFloat();
	pos[2] = pack.ReadFloat();
	
	SpawnItem(item, pos);
}

public Action Timer_ObjectGlow(Handle timer, int entity)
{
	if (!IsValidEntity(entity))
		return Plugin_Stop;
	
	int red, green, blue, alpha;
	GetEntityRenderColor(entity, red, green, blue, alpha);
	
	if (red == 255)
		SetEntityRenderColor(entity, 0, 255, 0);
	else
		SetEntityRenderColor(entity, 255, 255, 255);
	
	return Plugin_Continue;
}

/*This is called when pressing E on an object.
* Example: activating a Teleporter, checking the cost of a crate.
* Non example: Smashing open a crate.*/
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
	if (IsValidEntity(obj) && g_eObjectState[obj] == ObjectState_Active)
	{
		float objPos[3];
		GetEntPropVector(obj, Prop_Data, "m_vecAbsOrigin", objPos);
		if (GetVectorDistance(endPos, objPos, true) <= Pow(150.0, 2.0))
		{
			char targetName[128];
			GetEntPropString(obj, Prop_Data, "m_iName", targetName, sizeof(targetName));
			if (ActivateObject(client, obj, targetName))
				return true;
		}
	}
	
	return false;
}

bool ActivateObject(int client, int obj, const char[] targetName)
{
	if (strcmp(targetName, OBJECT_CRATE) == 0) // Display the cost for this crate, but don't try to open it
	{
		PrintCenterText(client, "This crate costs $%.0f to open.", g_flObjectCost[obj]);
		return true;
	}
	else if (strcmp(targetName, OBJECT_TELEPORTER) == 0)
	{
		Action retVal = Plugin_Continue;
		
		Call_StartForward(f_TeleEventStart);
		Call_PushCell(client);
		Call_Finish(retVal);
		
		if (retVal == Plugin_Handled || g_bGracePeriod)
			return true;
		
		if (g_bTeleporterEventCompleted)
		{
			StartTeleporterVote(client, true);
		}
		else
		{
			StartTeleporterVote(client);
			return true;
		}
	}
	return false;
}

void StartTeleporterVote(int client, bool nextStageVote=false)
{
	if (IsVoteInProgress())
	{
		RF2_PrintToChat(client, "There is already a vote in progress. Please wait until it finishes.");
		return;
	}
		
	g_iTeleporterActivator = client;
	int clients[MAX_SURVIVORS];
	int clientCount;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
			
		if (g_iPlayerSurvivorIndex[i] >= 0)
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
		SetMenuTitle(menu, "Progress to the next stage? (%N)", client);
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
	if (action == MenuAction_VoteEnd)
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
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public int Menu_NextStageVote(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_VoteEnd)
	{
		if (param1 == 0)
			ForceTeamWin(TEAM_SURVIVOR);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

void PrepareTeleporterEvent()
{
	RF2_PrintToChatAll("%N activated the Teleporter...", g_iTeleporterActivator);
	GetEntPropVector(g_iTeleporter, Prop_Data, "m_vecAbsOrigin", g_flTeleporterOrigin);
	CreateTimer(3.0, Timer_StartTeleporterEvent, g_iTeleporter, TIMER_FLAG_NO_MAPCHANGE);

	// start some effects (fog and shake)
	int shake = CreateEntityByName("env_shake");
	DispatchKeyValue(shake, "spawnflags", "9");
	DispatchKeyValue(shake, "radius", "999999.0");
	DispatchKeyValue(shake, "amplitude", "16.0");
	DispatchKeyValue(shake, "duration", "3.0");
	DispatchKeyValue(shake, "frequency", "50");
	
	DispatchSpawn(shake);
	TeleportEntity(shake, g_flTeleporterOrigin, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(shake, "StartShake");

	CreateTimer(3.0, Timer_DeleteEntity, EntIndexToEntRef(shake), TIMER_FLAG_NO_MAPCHANGE);

	int fog = CreateEntityByName("env_fog_controller");
	DispatchKeyValue(fog, "targetname", "TeleporterFog");
	DispatchKeyValue(fog, "spawnflags", "1");
	DispatchKeyValue(fog, "fogenabled", "1");
	DispatchKeyValue(fog, "fogstart", "100.0");
	DispatchKeyValue(fog, "fogend", "250.0");
	DispatchKeyValue(fog, "fogmaxdensity", "0.7");
	DispatchKeyValue(fog, "fogcolor", "40 0 0");
			
	DispatchSpawn(fog);				
	AcceptEntityInput(fog, "TurnOn");					
		
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		StopMusicTrack(i);
		SetVariantString("TeleporterFog");
		AcceptEntityInput(i, "SetFogController");
	}
	CreateTimer(3.0, Timer_DeleteEntity, EntIndexToEntRef(fog), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_StartTeleporterEvent(Handle timer, int entity)
{
	g_bTeleporterEvent = true;
	g_flTeleporterRadius = TELEPORTER_RADIUS;
	
	int radiusProp = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(radiusProp, "modelscale", "1.55");
	DispatchKeyValue(radiusProp, "fademaxdist", "0");
	DispatchKeyValue(radiusProp, "fademindist", "0");
	DispatchKeyValue(radiusProp, "model", MODEL_TELEPORTER_RADIUS);

	DispatchSpawn(radiusProp);
	TeleportEntity(radiusProp, g_flTeleporterOrigin, NULL_VECTOR, NULL_VECTOR);
	SetEntityRenderMode(radiusProp, RENDER_TRANSCOLOR);
	SetEntityRenderColor(radiusProp, 255, 255, 255, 75);
	
	SummonTeleporterBosses(entity);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || !g_bMusicEnabled[i])
			continue;
			
		PlayMusicTrack(i, true);
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
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if (g_iPlayerSurvivorIndex[i] >= 0)
			aliveSurvivors++;
		else if (g_bIsTeleporterBoss[i])
			aliveBosses++;
	}
	
	// now let's see how many of them are actually in the radius, so we can add charge based on that
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || g_iPlayerSurvivorIndex[i] < 0)
			continue;
		
		GetClientAbsOrigin(i, origin);
		
		float distance;
		distance = GetVectorDistance(origin, g_flTeleporterOrigin);
		
		if (distance <= g_flTeleporterRadius)
		{
			g_flTeleporterCharge += 0.1 / aliveSurvivors;
			if (g_flTeleporterCharge > 100.0)
				g_flTeleporterCharge = 100.0;
			
			FormatEx(g_szTeleporterHud[i], 64, "Teleporter Charge: %.0f percent...\nBosses Left: %i", g_flTeleporterCharge, aliveBosses);
		}
		else
		{
			FormatEx(g_szTeleporterHud[i], 64, "Get inside the Teleporter radius!");
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

void EndTeleporterEvent()
{
	g_flTeleporterCharge = 0.0;
	g_bTeleporterEvent = false;
	g_bTeleporterEventCompleted = true;
	
	//bool aliveRobots;
	for (int i = 1; i < MAXTF2PLAYERS; i++)
	{
		FormatEx(g_szTeleporterHud[i], 64, "");
		/*if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_ROBOT)
		{
			TF2_StunPlayer(i, 20.0, _, TF_STUNFLAG_BONKSTUCK);
			aliveRobots = true;
		}
		*/
	}
	
	//if (aliveRobots)
	//	EmitSoundToAll(SOUND_ROBOT_STUN);

	RF2_PrintToChatAll("{lime}Teleporter event completed!{default} Interact with the teleporter to go to the next stage.");
}

void GetWorldCenter(float vec[3])
{
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
			break;
		}
	}
	
	// rf2_world_center doesn't exist, time for plan B
	if (!found)
	{
		char mapName[128];
		GetCurrentMap(mapName, sizeof(mapName));
		LogError("rf2_world_center not found on map \"%s\"!", mapName);
		
		int redSpawn = MaxClients+1;
		int blueSpawn = MaxClients+1;
		bool redSpawnFound;
		bool blueSpawnFound;
		
		while ((redSpawn = FindEntityByClassname(redSpawn, "func_respawnroom")) != -1)
		{
			if (GetEntProp(redSpawn, Prop_Data, "m_iTeamNum") == view_as<int>(TFTeam_Red))
			{
				redSpawnFound = true;
				break;
			}
		}
		
		while ((blueSpawn = FindEntityByClassname(blueSpawn, "func_respawnroom")) != -1)
		{
			if (GetEntProp(blueSpawn, Prop_Data, "m_iTeamNum") == view_as<int>(TFTeam_Blue))
			{
				blueSpawnFound = true;
				break;
			}
		}
		
		if (redSpawnFound && blueSpawnFound)
		{
			float redSpawnPos[3];
			float blueSpawnPos[3];
			float angles[3];
			float direction[3];
			GetEntPropVector(redSpawn, Prop_Data, "m_vecAbsOrigin", redSpawnPos);
			GetEntPropVector(blueSpawn, Prop_Data, "m_vecAbsOrigin", blueSpawnPos);
			
			GetVectorAnglesTwoPoints(redSpawnPos, blueSpawnPos, angles);
			GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(direction, direction);
			
			float distance = GetVectorDistance(redSpawnPos, blueSpawnPos) * 0.5;
			
			CopyVectors(redSpawnPos, vec);
			vec[0] += direction[0] * distance;
			vec[1] += direction[1] * distance;
			vec[2] += direction[2] * distance;
		}
		else // last resort. 0 0 0 is not always the center of the map, but sometimes it is
		{
			CopyVectors(NULL_VECTOR, vec);
		}
	}
}