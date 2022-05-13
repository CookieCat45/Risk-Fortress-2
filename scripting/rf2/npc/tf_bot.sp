#if defined _RF2_tfbot_included
 #endinput
#endif
#define _RF2_tfbot_included

void TFBot_Spawn(int client)
{
	if (IsFakeClient(client))
	{
		if (!g_TFBotPathFollower[client])
		{
			g_TFBotPathFollower[client] = PathFollower(_, Path_FilterIgnoreActors, Path_FilterOnlyActors);
		}
		
		if (g_TFBotPathFollower[client].IsValid())
		{
			g_TFBotPathFollower[client].Invalidate();
		}
	}
}

// Run through OnGameFrame()
void TFBot_Think()
{
	bool melee;
	bool threatIsClient;
	int threat;
	int skill;
	int team;
	int enemyTeam;
	int activeWeapon;
	static int randomNum[MAXTF2PLAYERS];
	
	INextBot nextBot;
	//ILocomotion locomotion;
	IVision vision;
	CKnownEntity known;
	
	TFClassType class;
	
	float botPos[3];
	float tracePos[3];
	float threatPos[3];
	float teleporterPos[3];
	float angles[3];
	float direction[3];
	
	Handle trace;
	int attempts;
	float totalOffset;
	float endPos[3];
	bool foundPath;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsFakeClient(i))
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
		
		if (!g_TFBotPathFollower[i])
		{
			g_TFBotPathFollower[i] = PathFollower(_, Path_FilterIgnoreActors, Path_FilterOnlyActors);
		}
		
		if (g_iPlayerRobotType[i] >= 0 || g_iPlayerBossType[i] >= 0)
		{
			activeWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			if (activeWeapon == GetPlayerWeaponSlot(i, WeaponSlot_Primary) || activeWeapon == GetPlayerWeaponSlot(i, WeaponSlot_Secondary))
			{
				// TODO: finish this later (minimum reload time)
			}
		}
		
		nextBot = CBaseEntity(i).MyNextBotPointer();
		vision = nextBot.GetVisionInterface();
		
		GetClientAbsOrigin(i, botPos);
		known = vision.GetPrimaryKnownThreat(false);
		
		threat = -1;
		if (known != NULL_KNOWN_ENTITY)
			threat = known.GetEntity();
			
		team = GetClientTeam(i);
		
		if (threat > 0)
		{
			threatIsClient = IsValidClient(threat);
			if (threatIsClient && IsInvuln(threat)) // if our current threat is ubered, run away
			{
				GetClientAbsOrigin(threat, threatPos);
				CopyVectors(botPos, tracePos);
				tracePos[2] += 30.0;
				GetVectorAnglesTwoPoints(tracePos, threatPos, angles);
				
				angles[0] = 0.0;
				totalOffset = 0.0;
				attempts = 0;
				foundPath = false;
				while (!foundPath && attempts < 6)
				{
					trace = TR_TraceRayFilterEx(tracePos, angles, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter_SpawnCheck);
					TR_GetEndPosition(endPos, trace);
					delete trace;
					
					// Probably nearing a dead end here. Try changing direction.
					if (GetVectorDistance(tracePos, endPos, true) <= Pow(250.0, 2.0))
					{
						if (totalOffset >= 0.0)
						{
							angles[1] += 15.0;
							totalOffset += 15.0;
							
							if (totalOffset >= 60.0)
							{
								angles[1] = -15.0;
								totalOffset = -15.0;
							}
						}
						else
						{
							angles[1] -= 15.0;
							totalOffset -= -15.0;
						}
						
						attempts++;
					}
					else
					{
						foundPath = true;
						break;
					}
				}
				
				TFBot_UpdatePathPos(i, endPos, 450.0);
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
							if (TR_PointOutsideWorld(threatPos) || TR_GetPointContents(threatPos) == MASK_PLAYERSOLID)
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
						
						TFBot_UpdatePathPos(i, threatPos, 2000.0);
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
				TFBot_UpdatePathPos(i, teleporterPos, TELEPORTER_RADIUS*1.5);
				
				// Stop after a bit
				g_hTFBotWalkToTeleporterTimer[i] = CreateTimer(16.0, Timer_TFBotStopWalkingToTeleporter, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
				g_bTFBotWalkingToTeleporter[i] = true;
			}
			else if (g_bTFBotWalkingToTeleporter[i] && g_hTFBotWalkToTeleporterTimer[i] != null)
			{
				if (GetVectorDistance(botPos, teleporterPos, true) <= Pow(300.0, 2.0)) // we can stop when we're this close
					TriggerTimer(g_hTFBotWalkToTeleporterTimer[i], true);
			}
		}
		
		if (!g_bTFBotAutoPathCooldown[i] && !g_bTFBotWalkingToTeleporter[i] && g_iTFBotAutoPathTarget[i] > 0 && threat < 0)
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
				TFBot_UpdatePathTarget(i, g_iTFBotAutoPathTarget[i], 2500.0);
				
				// reduce lag
				//g_bTFBotAutoPathCooldown[i] = true;
				//CreateTimer(PATH_COOLDOWN, Timer_TFBotAutoPathCooldown, i, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else if (g_iTFBotAutoPathTarget[i] < 1 && !g_bTFBotAutoPathSearchCooldown[i])
		{
			enemyTeam = -1;
			
			if (team == TEAM_SURVIVOR)
				enemyTeam = TEAM_ROBOT;
			else if (team == TEAM_ROBOT)
				team = TEAM_SURVIVOR;
			
			if ((g_iTFBotAutoPathTarget[i] = GetNearestPlayer(botPos, enemyTeam)) > -1)
			{
				g_hTFBotAutoPathTimer[i] = CreateTimer(AUTO_PATH_TARGET_TIME, Timer_TFBotChangeAutoPathTarget, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
			}
			
			g_bTFBotAutoPathSearchCooldown[i] = true;
			CreateTimer(PATH_COOLDOWN, Timer_TFBotAutoPathSearchCooldown, i, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

void TFBot_UpdatePathPos(int client, float pos[3], float distance=1000.0)
{
	INextBot nextBot = CBaseEntity(client).MyNextBotPointer();
	ILocomotion locomotion = nextBot.GetLocomotionInterface();
	bool goalReached = true;
	
	if (!g_bTFBotComputePathCooldown[client])
	{
		goalReached = g_TFBotPathFollower[client].ComputeToPos(nextBot, pos, distance);
		g_bTFBotComputePathCooldown[client] = true;
		CreateTimer(PATH_COOLDOWN, Timer_TFBotComputePathCooldown, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (goalReached && g_TFBotPathFollower[client].IsValid())
	{
		g_TFBotPathFollower[client].Update(nextBot);
		locomotion.Run();
	}
	else
	{
		g_TFBotPathFollower[client].Invalidate();
		locomotion.Stop();
	}
}

void TFBot_UpdatePathTarget(int client, int target, float distance=1000.0)
{
	INextBot nextBot = CBaseEntity(client).MyNextBotPointer();
	ILocomotion locomotion = nextBot.GetLocomotionInterface();
	bool goalReached = true;
	
	if (!g_bTFBotComputePathCooldown)
	{
		goalReached = g_TFBotPathFollower[client].ComputeToTarget(nextBot, target, distance);
		g_bTFBotComputePathCooldown[client] = true;
		CreateTimer(PATH_COOLDOWN, Timer_TFBotComputePathCooldown, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (goalReached && g_TFBotPathFollower[client].IsValid())
	{
		g_TFBotPathFollower[client].Update(nextBot);
		locomotion.Run();
	}
	else
	{
		g_TFBotPathFollower[client].Invalidate();
		locomotion.Stop();
	}
}

public Action Timer_TFBotStrafe(Handle timer, int client)
{
	g_bTFBotStrafing[client] = false;
}

public Action Timer_TFBotStopWalkingToTeleporter(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return;
		
	//PF_StopPathing(client);
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

public Action Timer_TFBotComputePathCooldown(Handle timer, int client)
{
	g_bTFBotComputePathCooldown[client] = false;
}

public Action Timer_TFBotAutoPathSearchCooldown(Handle timer, int client)
{
	g_bTFBotAutoPathSearchCooldown[client] = false;
}

public Action TFBot_OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype)
{
	if (buttons & IN_JUMP)
	{
		buttons |= buttons & IN_DUCK; // Bots always crouch jump
	}
	
	if (buttons & IN_ATTACK)
	{
		int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		int secondary = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
		
		if (IsValidEntity(secondary) && secondary == activeWeapon)
		{
			// TFBots have a bug where they won't switch off jar-type weapons after throwing. Forcing them to let go of IN_ATTACK fixes this.
			int ammoType = GetEntProp(secondary, Prop_Data, "m_iPrimaryAmmoType");
			if (ammoType >= TFAmmoType_Jarate && GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType) == 0)
			{
				buttons &= ~IN_ATTACK;
			}
		}
	}
	
	return Plugin_Continue;
}

// NavMesh/NavArea stuff
CNavArea GetSpawnPointFromNav(float pos[3], float resultPos[3], float minDist=MIN_SPAWN_DIST, float maxDist=MAX_SPAWN_DIST, bool doTrace=true, float mins[3] = PLAYER_MINS, float maxs[3] = PLAYER_MAXS, int traceFlags = MASK_PLAYERSOLID, float zOffset=0.0)
{
	CNavArea area = TheNavMesh.GetNearestNavArea(pos, false, 999999999.0, false, false);
	if (area == NULL_AREA) // This should never happen, but just in case
	{
		float angles[3];
		float direction[3];
		float worldCenter[3];
		GetWorldCenter(worldCenter);
		GetVectorAnglesTwoPoints(pos, worldCenter, angles);
		GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(direction, direction);
		float distance = GetVectorDistance(pos, worldCenter) * 0.01;
		int attempts;
		
		while (area == NULL_AREA && attempts < 100)
		{
			pos[0] += direction[0] * distance;
			pos[1] += direction[1] * distance;
			pos[2] += direction[2] * distance;
			
			area = TheNavMesh.GetNearestNavArea(pos, true, 999999999.0, false, false);
			attempts++;
		}
	}
	
	SurroundingAreasCollector collector = TheNavMesh.CollectSurroundingAreas(area, maxDist, 9999999.0, 9999999.0);
	
	int areaCount = collector.Count();
	Handle areaArray = CreateArray(1, areaCount);
	int validAreaCount;
	for (int i = 0; i < areaCount; i++)
	{
		if (collector.Get(i).GetCostSoFar() >= minDist)
		{
			SetArrayCell(areaArray, validAreaCount, i);
			validAreaCount++;
		}
	}
	
	ResizeArray(areaArray, validAreaCount);
	area = NULL_AREA;
	int randomArea;
	
	if (!doTrace)
	{
		randomArea = GetArrayCell(areaArray, GetRandomInt(0, validAreaCount-1));
		area = collector.Get(randomArea);
		area.GetCenter(resultPos);
	}
	else
	{
		Handle trace;
		float spawnPos[3];
		
		while (validAreaCount > 0)
		{
			int randomCell = GetRandomInt(0, validAreaCount-1);
			randomArea = GetArrayCell(areaArray, randomCell);
			area = collector.Get(randomArea);
			area.GetCenter(spawnPos);
			spawnPos[2] += zOffset;

			trace = TR_TraceHullFilterEx(spawnPos, spawnPos, mins, maxs, traceFlags, TraceFilter_SpawnCheck, -1);
			if (TR_DidHit(trace))
			{
				area = NULL_AREA;
				validAreaCount--;
				RemoveFromArray(areaArray, randomCell);
				delete trace;
			}
			else
			{
				delete trace;
				CopyVectors(spawnPos, resultPos);
				break;
			}
		}
	}
	
	delete collector;
	delete areaArray;
	return area;
}
