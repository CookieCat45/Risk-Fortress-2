#if defined _RF2_tfbot_included
 #endinput
#endif
#define _RF2_tfbot_included

#define AUTO_PATH_TARGET_TIME 25.0
#define AUTO_PATH_COOLDOWN 1.0

Address g_iTFBotNextBot[MAXTF2PLAYERS];
Address g_iTFBotLocomotion[MAXTF2PLAYERS];
Address g_iTFBotVision[MAXTF2PLAYERS];

bool g_bTFBotStrafing[MAXTF2PLAYERS];

Handle g_hTFBotWalkToTeleporterTimer[MAXTF2PLAYERS];
bool g_bTFBotWalkingToTeleporter[MAXTF2PLAYERS];

Handle g_hTFBotAutoPathTimer[MAXTF2PLAYERS];
bool g_bTFBotAutoPathCooldown[MAXTF2PLAYERS];
int g_iTFBotAutoPathTarget[MAXTF2PLAYERS] = {-1, ...};

stock Address GetNextBot(int entity)
{
	if (g_hSDKGetNextBot)
		return SDKCall(g_hSDKGetNextBot, entity);
		
	return Address_Null;
}

stock Address GetLocomotionInterface(Address iNextBot)
{
	if (g_hSDKGetLocomotion && iNextBot != Address_Null)
		return SDKCall(g_hSDKGetLocomotion, iNextBot);
		
	return Address_Null;
}

stock Address GetVisionInterface(Address iNextBot)
{
	if (g_hSDKGetVision && iNextBot != Address_Null)
		return SDKCall(g_hSDKGetVision, iNextBot);
		
	return Address_Null;
}

stock Address GetPrimaryKnownThreat(Address iVision, bool onlyVisibleThreats)
{
	if (g_hSDKGetPrimaryKnownThreat && iVision != Address_Null)
		return SDKCall(g_hSDKGetPrimaryKnownThreat, iVision, onlyVisibleThreats);
		
	return Address_Null;
}

stock int GetEntityFromKnown(Address iKnownEntity)
{
	if (g_hSDKGetEntity && iKnownEntity != Address_Null)
		return SDKCall(g_hSDKGetEntity, iKnownEntity);
		
	return -1;
}

stock void Approach(Address iLocomotion, const float pos[3], float goalWeight)
{
	if (g_hSDKApproach && iLocomotion != Address_Null)
		SDKCall(g_hSDKApproach, iLocomotion, pos, goalWeight);
}

stock void TFBot_Spawn(int client)
{
	if (!PF_Exists(client))
		PF_Create(client, 18.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 0.1);

	PF_EnableCallback(client, PFCB_Approach, TFBot_Approach);
}

public Action Timer_TFBotThink(Handle timer)
{
	if (!g_bPluginEnabled)
		return;
		
	bool melee;
	int threat;
	TFClassType class;
	float botPos[3];
	float threatPos[3];
	float teleporterPos[3];
	float angles[3];
	float direction[3];
	static int randomNum[MAXTF2PLAYERS];
	int skill;
	Handle survivorArray = CreateArray(1, MAX_SURVIVORS);
	int survivorCount;
	bool pathing[MAXTF2PLAYERS];
	int activeWeapon;
	bool threatIsClient;
	int team;
	float enemyPos[3];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
			
		if (g_iPlayerSurvivorIndex[i] >= 0)
		{
			SetArrayCell(survivorArray, survivorCount, i);
			survivorCount++;
		}
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsFakeClient(i) || !PF_Exists(i))
			continue;
		
		if (!IsPlayerAlive(i))
		{
			if (g_hTFBotAutoPathTimer[i] != null)
			{
				KillTimer(g_hTFBotAutoPathTimer[i]);
				g_hTFBotAutoPathTimer[i] = null;
			}
			
			continue;
		}
		
		if (g_iPlayerRobotType[i] >= 0 || g_iPlayerBossType[i] >= 0)
		{
			activeWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			if (activeWeapon == GetPlayerWeaponSlot(i, WeaponSlot_Primary) || activeWeapon == GetPlayerWeaponSlot(i, WeaponSlot_Secondary))
			{
				// TODO: finish this later (minimum reload time)
			}
		}
		
		GetClientAbsOrigin(i, botPos);
		threat = GetEntityFromKnown(GetPrimaryKnownThreat(g_iTFBotVision[i], false));
		team = GetClientTeam(i);
		
		if (IsValidEntity(threat) || g_bIsBoss[i])
		{
			threatIsClient = IsValidClient(threat);
			if (threatIsClient && IsInvuln(threat)) // don't walk at ubered enemies, duh
			{
				pathing[i] = false;
			}
			else
			{
				class = TF2_GetPlayerClass(i);
				if (GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(i, WeaponSlot_Melee))
				{
					melee = true;
				}
				
				if (melee)
				{
					if (class != TFClass_Engineer && class != TFClass_Spy)
					{
						pathing[i] = true;
						
						// Force bots to rush players when they have their melee out, since default TFBot melee AI is pretty laughable.
						GetEntPropVector(threat, Prop_Data, "m_vecAbsOrigin", threatPos);
						
						skill = GetEntProp(i, Prop_Send, "m_nBotSkill");
						// Randomly strafe if we're hard or above to throw off our enemy
						if (threatIsClient && skill >= TFBotDifficulty_Hard)
						{
							GetVectorAnglesTwoPoints(botPos, threatPos, angles);
							angles[0] = 0.0;
							GetAngleVectors(angles, NULL_VECTOR, direction, NULL_VECTOR);
							NormalizeVector(direction, direction);
							
							if (!g_bTFBotStrafing[i])
								randomNum[i] = GetRandomInt(1, 2);
							
							if (randomNum[i] == 1)
							{
								threatPos[0] += direction[0] * 120.0;
								threatPos[1] += direction[1] * 120.0;
								threatPos[2] += direction[2] * 120.0;
							}
							else
							{
								threatPos[0] += direction[0] * -120.0;
								threatPos[1] += direction[1] * -120.0;
								threatPos[2] += direction[2] * -120.0;
							}
							
							// Don't bother if we can't access that area, we're most likely in a closed space such as a hallway.
							if (!PF_IsPathToVectorPossible(i, threatPos))
								GetEntPropVector(threat, Prop_Data, "m_vecAbsOrigin", threatPos);
	
							if (!g_bTFBotStrafing[i])
							{
								// Expert bots strafe more often.
								if (skill >= TFBotDifficulty_Expert)
									CreateTimer(GetRandomFloat(0.8, 1.35), Timer_TFBotStrafe, i, TIMER_FLAG_NO_MAPCHANGE);
								else
									CreateTimer(GetRandomFloat(1.25, 1.75), Timer_TFBotStrafe, i, TIMER_FLAG_NO_MAPCHANGE);
							}
							g_bTFBotStrafing[i] = true;
							
						}
						
						if (PF_IsPathToVectorPossible(i, threatPos))
						{
							PF_SetGoalVector(i, threatPos);
						}
						else
						{
							pathing[i] = false;
						}
					}
				}
			}
		}
		else if (g_bTeleporterEvent)
		{
			GetEntPropVector(g_iTeleporter, Prop_Data, "m_vecAbsOrigin", teleporterPos);
			
			// stick close to the teleporter
			if (!g_bTFBotWalkingToTeleporter[i] && GetVectorDistance(botPos, teleporterPos, true) <= Pow(TELEPORTER_RADIUS, 2.0))
			{
				pathing[i] = true;
				PF_SetGoalVector(i, teleporterPos);
				
				// Stop after a bit
				g_hTFBotWalkToTeleporterTimer[i] = CreateTimer(16.0, Timer_StopWalkingToTeleporter, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
				g_bTFBotWalkingToTeleporter[i] = true;
			}
			else if (g_bTFBotWalkingToTeleporter[i] && g_hTFBotWalkToTeleporterTimer[i] != null)
			{
				if (GetVectorDistance(botPos, teleporterPos, true) <= Pow(300.0, 2.0)) // we can stop when we're this close
					TriggerTimer(g_hTFBotWalkToTeleporterTimer[i], true);
			}
		}
		
		if (!g_bTFBotAutoPathCooldown[i] && !g_bTFBotWalkingToTeleporter[i] && g_iTFBotAutoPathTarget[i] != -1 && !IsValidEntity(threat))
		{
			if (!IsClientInGame(g_iTFBotAutoPathTarget[i]) || !IsPlayerAlive(g_iTFBotAutoPathTarget[i]) || GetClientTeam(g_iTFBotAutoPathTarget[i]) == team)
			{
				if (g_hTFBotAutoPathTimer[i] != null)
				{
					KillTimer(g_hTFBotAutoPathTimer[i]);
					g_hTFBotAutoPathTimer[i] = null;
				}
				
				g_iTFBotAutoPathTarget[i] = -1;
				g_bTFBotAutoPathCooldown[i] = false;
			}
			else
			{
				GetClientAbsOrigin(g_iTFBotAutoPathTarget[i], enemyPos);
				PF_SetGoalVector(i, enemyPos);
				pathing[i] = true;
				
				// reduce lag
				g_bTFBotAutoPathCooldown[i] = true;
				CreateTimer(AUTO_PATH_COOLDOWN, Timer_TFBotAutoPathCooldown, i, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else if (g_iTFBotAutoPathTarget[i] == -1)
		{
			int enemyTeam = -1;
			
			if (team == TEAM_SURVIVOR)
				enemyTeam = TEAM_ROBOT;
			else if (team == TEAM_ROBOT)
				team = TEAM_SURVIVOR;
			
			if ((g_iTFBotAutoPathTarget[i] = GetNearestPlayer(botPos, enemyTeam)) > -1)
			{
				g_hTFBotAutoPathTimer[i] = CreateTimer(AUTO_PATH_TARGET_TIME, Timer_TFBotChangeAutoPathTarget, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		
		if (pathing[i] || g_bTFBotWalkingToTeleporter[i])
		{
			PF_StartPathing(i);
		}
		else
		{
			PF_StopPathing(i);
		}
	}
	
	delete survivorArray;
}

public void TFBot_Approach(int client, const float vec[3])
{
	Approach(g_iTFBotLocomotion[client], vec, 1.0);
}

public Action Timer_TFBotStrafe(Handle timer, int client)
{
	g_bTFBotStrafing[client] = false;
}

public Action Timer_StopWalkingToTeleporter(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return;
		
	PF_StopPathing(client);
	g_bTFBotWalkingToTeleporter[client] = false;
	g_hTFBotWalkToTeleporterTimer[client] = null;
}

public Action Timer_TFBotChangeAutoPathTarget(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || !IsPlayerAlive(client))
		return;
		
	g_iTFBotAutoPathTarget[client] = -1;
	g_hTFBotAutoPathTimer[client] = null;
}

public Action Timer_TFBotAutoPathCooldown(Handle timer, int client)
{
	g_bTFBotAutoPathCooldown[client] = false;
}

// NavMesh/NavArea stuff
stock NavArea GetSpawnPointFromNav(float pos[3], float minDist=MIN_SPAWN_DIST, float maxDist=MAX_SPAWN_DIST, float mins[3] = PLAYER_MINS, float maxs[3] = PLAYER_MAXS, int maxAttempts=100)
{
	if (TR_PointOutsideWorld(pos)) // spawn positions outside of the world break the spawning system
	{
		float angles[3];
		float direction[3];
		GetVectorAnglesTwoPoints(pos, NULL_VECTOR, angles); // get angles to world origin
		GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(direction, direction);
		float increment = GetVectorDistance(pos, NULL_VECTOR) * 0.01; // how much distance we'll move on each jump towards the world origin
		
		int attempts;
		while (attempts < 100)
		{
			pos[0] += direction[0] * increment;
			pos[1] += direction[1] * increment;
			pos[2] += direction[2] * increment;
			
			if (TR_PointOutsideWorld(pos))
				attempts++;
			else
				break;
		}
		
		if (TR_PointOutsideWorld(pos)) // absolute last resort
		{
			pos[0] = 0.0;
			pos[1] = 0.0;
			pos[2] = 0.0;
		}
	}
	
	float originalPos[3];
	CopyVectors(pos, originalPos);
	
	float direction[3];
	float angles[3];
	angles[1] = GetRandomFloat(0.0, 360.0);
	
	GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(direction, direction);

	pos[0] += direction[0] * minDist;
	pos[1] += direction[1] * minDist;
	pos[2] += direction[2] * minDist;
	
	NavArea area;
	int attempts;
	int retries;
	float spawnPos[3];
	Handle trace;
	
	while (attempts < maxAttempts)
	{
		area = TheNavMesh.GetNearestNavArea_Vec(pos, true, maxDist, false, true);
		if (area)
		{
			area.GetCenter(spawnPos);
			//spawnPos[2] += maxs[2] * 0.2;
			
			trace = TR_TraceHullFilterEx(spawnPos, spawnPos, mins, maxs, MASK_PLAYERSOLID, TraceFilter_SpawnCheck, -1);
			if (TR_DidHit(trace))
			{
				area = NavArea_Null;
				pos[0] += direction[0] * minDist;
				pos[1] += direction[1] * minDist;
				pos[2] += direction[2] * minDist;
			}
			else
			{
				delete trace;
				break;
			}
			delete trace;
		}
		else
		{
			pos[0] += direction[0] * 20.0;
			pos[1] += direction[1] * 20.0;
			pos[2] += direction[2] * 20.0;
		}
		
		if (attempts == maxAttempts-1 && retries < 10)
		{
			// try a different angle
			angles[1] += 45.0;
			if (angles[1] > 360.0)
				angles[1] = 45.0;
				
			GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(direction, direction);
			CopyVectors(originalPos, pos);
			
			attempts = 0;
			retries++;
		}
		attempts++;
	}
	
	
	if (!area)
	{
		char mapName[128];
		GetCurrentMap(mapName, sizeof(mapName));
		LogError("GetSpawnPointFromNav: NavArea returned NULL, attempts: %i, map: %s", maxAttempts * retries, mapName);
	}
	
	return area;
}