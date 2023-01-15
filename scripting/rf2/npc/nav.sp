#if defined _RF2_nav_included
 #endinput
#endif
#define _RF2_nav_included

#pragma semicolon 1
#pragma newdecls required

static bool g_bDisableIncursionHook;

/**
 * A function designed to find a valid random spawn point on the map for players, NPCs, objects, and whatever else.
 * @param pos					Position to start searching for spawn points.
 * @param resultPos				Result spawn position, if a spawn point is successfully found.
 * @param minDist				Minimum distance from search position.
 * @param maxDist				Maximum distance from search position.
 * @param filterTeam				Don't choose a spawn point too close to players on this team. 
 *								If this is above 3 (TFTeam_Blue), all players will be filtered. -1 to skip filtering.
 *					
 * @param doSpawnTrace		Do a trace to ensure that players and NPCs will not get stuck.
 * @param mins					Hull mins for the trace hull spawn check.
 * @param maxs					Hull maxs for the trace hull spawn check.
 * @param traceFlags				Trace flags. MASK_PLAYERSOLID for players, MASK_NPCSOLID for NPCs.
 * @param zOffset				Offset the Z position of the result spawn position by this much.
 * @return			CNavArea associated with the spawn point if found. NULL_AREA otherwise.
 */
CNavArea GetSpawnPointFromNav(const float pos[3], float resultPos[3], 
float minDist=650.0, float maxDist=1650.0, int filterTeam=-1, 
bool doSpawnTrace=true, const float mins[3]=PLAYER_MINS, const float maxs[3]=PLAYER_MAXS, int traceFlags=MASK_PLAYERSOLID, float zOffset=0.0)
{
	float navPos[3];
	CopyVectors(pos, navPos);
	CNavArea area = TheNavMesh.GetNearestNavArea(navPos, false, MAX_MAP_SIZE, false, false);
	
	// This should never happen, but just in case
	if (area == NULL_AREA)
	{
		float angles[3], direction[3], worldCenter[3];
		GetWorldCenter(worldCenter);
		GetVectorAnglesTwoPoints(navPos, worldCenter, angles);
		GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(direction, direction);
		
		float distance = GetVectorDistance(navPos, worldCenter) * 0.01;
		int attempts;
		
		while (area == NULL_AREA && attempts < 100)
		{
			navPos[0] += direction[0] * distance;
			navPos[1] += direction[1] * distance;
			navPos[2] += direction[2] * distance;
			
			area = TheNavMesh.GetNearestNavArea(navPos, true, MAX_MAP_SIZE, false, false); // We don't care about Z this time.
			attempts++;
		}
	}
	
	SurroundingAreasCollector collector = TheNavMesh.CollectSurroundingAreas(area, maxDist, maxDist, maxDist);
	int areaCount = collector.Count();
	ArrayList areaArray = CreateArray(1, areaCount);
	int validAreaCount, randomArea;
	
	for (int i = 0; i < areaCount; i++)
	{
		area = collector.Get(i);
		if (view_as<CTFNavArea>(area).HasAttributeTF(NO_SPAWNING))
		{
			continue;
		}
		
		if (area.GetCostSoFar() >= minDist)
		{
			areaArray.Set(validAreaCount, i);
		}
	}
	
	areaArray.Resize(validAreaCount);
	area = NULL_AREA;
	
	if (!doSpawnTrace)
	{
		randomArea = areaArray.Get(GetRandomInt(0, validAreaCount-1));
		area = collector.Get(randomArea);
		area.GetCenter(resultPos);
	}
	else
	{
		int randomCell;
		float spawnPos[3], playerPos[3];
		bool canSpawn = true;
		bool npc = traceFlags & MASK_NPCSOLID || traceFlags & MASK_NPCSOLID_BRUSHONLY;
		
		while (validAreaCount > 0)
		{
			randomCell = GetRandomInt(0, validAreaCount-1);
			randomArea = areaArray.Get(randomCell);
			area = collector.Get(randomArea);
			area.GetCenter(spawnPos);
			spawnPos[2] += zOffset;
			
			TR_TraceHullFilter(spawnPos, spawnPos, mins, maxs, traceFlags, TraceFilter_SpawnCheck, npc);
			if (TR_DidHit())
			{
				area = NULL_AREA;
				validAreaCount--;

				if (areaArray.FindValue(randomArea) != -1)
				{
					areaArray.Erase(randomCell);
				}
			}
			else
			{
				if (filterTeam > -1)
				{
					canSpawn = true;
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!canSpawn)
							continue;
						
						if (!IsClientInGameEx(i) || !IsPlayerAlive(i) 
						|| filterTeam <= view_as<int>(TFTeam_Blue) && GetClientTeam(i) != filterTeam)
							continue;

						GetClientAbsOrigin(i, playerPos);
						if (GetVectorDistance(spawnPos, playerPos, true) <= sq(minDist))
						{
							area = NULL_AREA;
							validAreaCount--;
							if (areaArray.FindValue(randomArea) != -1)
							{
								areaArray.Erase(randomCell);
							}
							
							canSpawn = false;
						}
					}
				}
				
				if (canSpawn) // We can spawn here.
				{
					CopyVectors(spawnPos, resultPos);
					break;
				}
			}
		}
	}
	
	delete collector;
	delete areaArray;
	return area;
}

void SDK_ComputeIncursionDistances()
{
	if (!g_hSDKComputeIncursion)
		return;
	
	int entity = -1;
	char name[32];
	float pos[3];
	CNavArea redArea, blueArea;
	
	// Method A: respawnrooms
	while ((entity = FindEntityByClassname(entity, "func_respawnroom")) != -1)
	{
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
		
		switch (view_as<TFTeam>(GetEntProp(entity, Prop_Send, "m_iTeamNum")))
		{
			case TFTeam_Red:  if (!redArea) redArea = TheNavMesh.GetNearestNavArea(pos, true, _, _, false);
			case TFTeam_Blue: if (!blueArea) blueArea = TheNavMesh.GetNearestNavArea(pos, true, _, _, false);
		}
	}
	
	// Method B: info_target
	entity = -1;
	while ((!redArea || !blueArea) && (entity = FindEntityByClassname(entity, "info_target")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		
		if (!redArea && strcmp(name, "rf2_incursion_area_red") == 0)
		{
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
			redArea = TheNavMesh.GetNearestNavArea(pos, true, _, _, false);
		}
		else if (!blueArea && strcmp(name, "rf2_incursion_area_blue") == 0)
		{
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
			blueArea = TheNavMesh.GetNearestNavArea(pos, true, _, _, false);
		}
	}
	
	g_bDisableIncursionHook = true;
	
	if (redArea) SDKCall(g_hSDKComputeIncursion, TheNavMesh.Address, redArea, TFTeam_Red);
	if (blueArea) SDKCall(g_hSDKComputeIncursion, TheNavMesh.Address, blueArea, TFTeam_Blue);
	
	g_bDisableIncursionHook = false;
	
	if (redArea && blueArea)
	{
		LogMessage("[GetIncursionAreas] Located incursion areas for both teams successfully.");
	}
	else
	{
		if (!redArea)
		{
			LogError("[GetIncursionAreas] Could not locate incursion area for Red team. Bots may perform poorly.");
		}
		
		if (!blueArea)
		{
			LogError("[GetIncursionAreas] Could not locate incursion area for Blue team. Bots may perform poorly.");
		}
	}
}

public MRESReturn DHook_ComputeIncursionDistances(Address navMesh, Handle params)
{
	if (g_bDisableIncursionHook) // SDKCall
	{
		return MRES_Ignored;
	}
	
	return MRES_Supercede;
}