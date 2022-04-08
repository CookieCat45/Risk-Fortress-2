#if defined _RF2_objects_included
 #endinput
#endif
#define _RF2_objects_included

#define OBJ_TELEPORTER "rf2_object_teleporter"
#define MAX_TELEPORTERS 16
#define TELEPORTER_RADIUS 1500.0

#define OBJ_ALTAR "rf2_object_altar"
#define MAX_ALTARS 8

#define MAX_OBJECTS 128
#define BASE_OBJECT_COUNT 10

#define OBJ_CRATE "rf2_object_crate"
#define OBJ_CRATE_LARGE "rf2_object_crate_large"
#define CRATE_BASE_COST 50.0
#define CRATE_LARGE_BASE_COST 150.0

int g_iObjectState[2048] = {Obj_None, ...};
float g_flObjectCost[2048];

float g_flTeleporterRadius;
float g_flTeleporterCharge;
float g_flTeleporterOrigin[3];

int g_iTeleporter;
int g_iTeleporterActivator;
bool g_bTeleporterEvent;
bool g_bTeleporterEventCompleted;

char g_szTeleporterHud[MAXTF2PLAYERS][64];

stock int SpawnObjects()
{
	DespawnObjects();
	char mapName[PLATFORM_MAX_PATH];
	GetCurrentMap(mapName, sizeof(mapName));
	
	int teleporter[MAX_TELEPORTERS], teleporterCount;
	bool teleporterError;
	
	int survivors = RF2_GetSurvivorCount();
	
	// Find our teleporter spawnpoints
	char targetName[128];
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		if (g_iObjectState[entity] == Obj_None)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));
			if (strcmp(targetName, OBJ_TELEPORTER) == 0) // is this a teleporter spawnpoint? if so, add it to our array
			{
				if (teleporterCount > MAX_TELEPORTERS)
				{
					if (!teleporterError)
					{
						LogError("Map %s has hit the limit of %i for Teleporter spawn points, please reduce the amount!", mapName, MAX_TELEPORTERS);
						teleporterError = true;
					}	
					continue;
				}
				
				teleporter[teleporterCount] = entity;
				teleporterCount++;
			}
		}
	}
	
	// now spawn the teleporter at a random location
	int randomTele = GetRandomInt(0, teleporterCount-1);
	SpawnTeleporter(teleporter[randomTele]);
	
	// now spawn objects
	int spawnCount = BASE_OBJECT_COUNT * survivors + RoundFloat(g_flDifficultyCoeff / (g_flSubDifficultyIncrement / 5.0));
	if (spawnCount > MAX_OBJECTS)
		spawnCount = MAX_OBJECTS;
		
	int crateCount = RoundToFloor(IntToFloat(spawnCount) * 0.6); // 60% of all objects will be crates.
	//int miscCount = spawnCount - crateCount;
	
	int spawns;
	float pos[3];
	float spawnPos[3];
	float angles[3];
	float direction[3];
	float randomDist;
	NavArea area;
	
	while (spawns < spawnCount)
	{
		pos[2] = GetRandomFloat(-800.0, 800.0); // always 0 0 0 with random elevation
		angles[1] = GetRandomFloat(-180.0, 180.0);
		GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(direction, direction);
		
		randomDist = GetRandomFloat(0.0, 8000.0);
		pos[0] += direction[0] * randomDist;
		pos[1] += direction[1] * randomDist;
		pos[2] += direction[2] * randomDist;
		
		area = TheNavMesh.GetNearestNavArea_Vec(pos, true, 999999999.0, false, false);
		area.GetRandomPoint(spawnPos);
		
		if (crateCount > 0)
		{
			CreateObject(spawnPos, OBJ_CRATE, MODEL_CRATE, 0.5, true, 2);
			PrintToServer("Crate spawned at %.0f %.0f %.0f", spawnPos[0], spawnPos[1], spawnPos[2]);
			crateCount--;
		}
		
		CopyVectors(NULL_VECTOR, pos);
		spawns++;
	}
	
	// delete unused spawnpoints to save on edicts
	entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));
		if (g_iObjectState[entity] != Obj_Active && strcmp(targetName, OBJ_TELEPORTER) == 0)
			RemoveEntity(entity);
	}
	
	return spawns;
}

stock void DespawnObjects(bool logSpawns = false)
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
			if (strcmp(targetName, OBJ_TELEPORTER) == 0) // teleporters are handled differently
			{
				SetEntityModel(entity, MODEL_INVISIBLE);
				AcceptEntityInput(entity, "DisableCollision");
				teleporterSpawns++;
			}
			else
			{
				RemoveEntity(entity);	
			}
			g_iObjectState[entity] = Obj_None;
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

stock int CreateObject(float pos[3], const char[] name, const char[] model, float scale=1.0, bool collision=true, int solidType=4)
{
	int entity = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(entity, "model", model);
	DispatchKeyValue(entity, "targetname", name);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);
	
	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", scale);
	
	if (strcmp(name, OBJ_CRATE) == 0)
	{
		SDKHook(entity, SDKHook_OnTakeDamage, Hook_OnCrateHit);
		float exponent = (g_flDifficultyCoeff / (750.0 + (g_flDifficultyCoeff / g_flSubDifficultyIncrement * 15.0))) + 1.0;
		g_flObjectCost[entity] = Pow(CRATE_BASE_COST, exponent);
		
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
	
	g_iObjectState[entity] = Obj_Active;
	return entity;
}

stock void SpawnTeleporter(int entity)
{
	SetEntityModel(entity, MODEL_TELEPORTER);
	SetEntPropString(entity, Prop_Data, "m_iName", OBJ_TELEPORTER);
	AcceptEntityInput(entity, "EnableCollision");
	g_iObjectState[entity] = Obj_Active;
}

public Action Hook_OnCrateHit(int entity, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (g_iObjectState[entity] != Obj_Active)
		return;
	
	if (IsValidClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR)
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
				PrintCenterText(attacker, "You can't afford to open this! (Cost: $%.0f)", g_flObjectCost[entity]);
				return;
			}
			
			float origin[3];
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", origin);
			origin[2] += 40.0;
			
			int item = GetRandomItem(80.0, 20.0, 0.0);
			float removeTime;
			
			switch (g_iItemQuality[item])
			{
				case Quality_Normal, Quality_Genuine:
				{
					EmitSoundToAll(SOUND_DROP_DEFAULT, entity);
					TE_SetupParticle(PARTICLE_NORMAL_CRATE_OPEN, origin);
					
					g_iObjectState[entity] = Obj_None;
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
					
					g_iObjectState[entity] = Obj_None;
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
stock bool ObjectInteract(int client)
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
	if (IsValidEntity(obj) && g_iObjectState[obj] == Obj_Active)
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

stock bool ActivateObject(int client, int obj, const char[] targetName)
{
	if (strcmp(targetName, OBJ_CRATE) == 0) // Display the cost for this crate, but don't try to open it
	{
		PrintCenterText(client, "This crate costs $%.0f to open.", g_flObjectCost[obj]);
		return true;
	}
	else if (strcmp(targetName, OBJ_TELEPORTER) == 0)
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
			g_iTeleporter = obj;
			g_iTeleporterActivator = client;
			return true;
		}
	}
	return false;
}

stock void StartTeleporterVote(int client, bool nextStageVote=false)
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
		if (!IsValidClient(i, true))
			continue;
			
		if (GetClientTeam(i) == TEAM_SURVIVOR)
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
			PrepareTeleporterEvent();
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

stock void PrepareTeleporterEvent()
{
	g_bTeleporterEvent = true;
	
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
		StopMusicTrack(i);
		
		if (!IsValidClient(i))
			continue;
	
		SetVariantString("TeleporterFog");
		AcceptEntityInput(i, "SetFogController");
	}
	CreateTimer(3.0, Timer_DeleteEntity, EntIndexToEntRef(fog), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_StartTeleporterEvent(Handle timer, int entity)
{
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
		PlayMusicTrack(i, true);
	
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
		if (!IsValidClient(i, true))
			continue;
		
		if (GetClientTeam(i) == TEAM_SURVIVOR)
			aliveSurvivors++;
		else if (g_bIsTeleporterBoss[i] && GetClientTeam(i) == TEAM_ROBOT)
			aliveBosses++;
	}
	
	// now let's see how many of them are actually in the radius, so we can add charge based on that
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i, true) || GetClientTeam(i) != TEAM_SURVIVOR)
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
		EndTeleporterEvent(entity);	
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

stock void EndTeleporterEvent(int teleporter)
{
	g_flTeleporterCharge = 0.0;
	g_bTeleporterEvent = false;
	g_bTeleporterEventCompleted = true;
	
	bool aliveRobots;
	for (int i = 1; i < MAXTF2PLAYERS; i++)
	{
		FormatEx(g_szTeleporterHud[i], 64, "");
		/*if (IsValidClient(i, true) && GetClientTeam(i) == TEAM_ROBOT)
		{
			TF2_StunPlayer(i, 20.0, _, TF_STUNFLAG_BONKSTUCK);
			aliveRobots = true;
		}
		*/
	}
	
	if (aliveRobots)
		EmitSoundToAll(SOUND_ROBOT_STUN);

	RF2_PrintToChatAll("{lime}Teleporter event completed! Interact with the teleporter to progress to the next stage.");
}