#if defined _RF2_nav_included
 #endinput
#endif
#define _RF2_nav_included

#pragma semicolon 1
#pragma newdecls required

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
 * @param traceFlags			Trace flags.
 * @param zOffset				Offset the Z position of the result spawn position by this much.
 * @return			CNavArea associated with the spawn point if found. NULL_AREA otherwise.
 */
CNavArea GetSpawnPoint(const float pos[3], float resultPos[3], 
float minDist=650.0, float maxDist=1650.0, int filterTeam=-1, 
bool doSpawnTrace=true, const float mins[3]=PLAYER_MINS, const float maxs[3]=PLAYER_MAXS, int traceFlags=MASK_PLAYERSOLID, float zOffset=0.0)
{
	float navPos[3];
	CopyVectors(pos, navPos);
	CNavArea area = TheNavMesh.GetNearestNavArea(navPos, false, MAX_MAP_SIZE, false, false);
	
	// This should never happen, but just in case
	if (!area)
	{
		float angles[3], direction[3], worldCenter[3];
		GetWorldCenter(worldCenter);
		GetVectorAnglesTwoPoints(navPos, worldCenter, angles);
		GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(direction, direction);
		
		float distance = GetVectorDistance(navPos, worldCenter) * 0.01;
		int attempts;
		
		while (!area && attempts < 100)
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
			continue;
		
		if (area.GetCostSoFar() >= minDist)
		{
			areaArray.Set(validAreaCount, i);
			validAreaCount++;
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
		int sentry = INVALID_ENT;
		float spawnPos[3], playerPos[3], sentryPos[3];
		bool canSpawn = true;
		int team = -1;
		team = filterTeam == view_as<int>(TFTeam_Red) ? view_as<int>(TFTeam_Blue) : view_as<int>(TFTeam_Red);
		
		while (validAreaCount > 0)
		{
			randomCell = GetRandomInt(0, validAreaCount-1);
			randomArea = areaArray.Get(randomCell);
			area = collector.Get(randomArea);
			area.GetCenter(spawnPos);
			spawnPos[2] += zOffset;
			
			TR_TraceHullFilter(spawnPos, spawnPos, mins, maxs, traceFlags, TraceFilter_SpawnCheck, team);
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
						
						if (!IsClientInGame(i) || !IsPlayerAlive(i) || filterTeam <= view_as<int>(TFTeam_Blue) && GetClientTeam(i) != filterTeam)
							continue;
						
						// Don't spawn near this player's non-disposable sentry
						if (TF2_GetPlayerClass(i) == TFClass_Engineer)
						{
							while ((sentry = FindEntityByClassname(sentry, "obj_sentrygun")) != INVALID_ENT)
							{
								if (GetEntProp(sentry, Prop_Data, "m_iTeamNum") == filterTeam && GetEntPropEnt(sentry, Prop_Send, "m_hBuilder") == i 
								&& g_hPlayerExtraSentryList[i].FindValue(sentry) == INVALID_ENT)
								{
									GetEntPos(sentry, sentryPos);
									
									if (GetVectorDistance(spawnPos, sentryPos, true) <= sq(minDist))
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
						}
						
						if (canSpawn)
						{
							GetEntPos(i, playerPos);
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

public bool TraceFilter_SpawnCheck(int entity, int mask, int team)
{
	if (RF2_Object_Base(entity).IsValid() && GetEntProp(entity, Prop_Send, "m_CollisionGroup") == COLLISION_GROUP_DEBRIS_TRIGGER)
		return false;
	
	if (team > 0 && (IsValidClient(entity) || IsBuilding(entity) || IsNPC(entity)))
	{
		if (team == GetEntProp(entity, Prop_Data, "m_iTeamNum"))
			return false;
	}
	
	if (mask & MASK_NPCSOLID || mask & MASK_PLAYERSOLID)
		return true;
		
	return false;
}

public bool Path_FilterIgnoreObjects(int entity, int contentsMask, int desiredcollisiongroup)
{	
	// don't worry about objects, most are non solid anyway
	if (RF2_Object_Base(entity).IsValid())
		return true;
	
	return !(contentsMask & MASK_SOLID);
}