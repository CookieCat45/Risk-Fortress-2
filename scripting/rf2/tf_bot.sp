#if defined _RF2_tfbot_included
 #endinput
#endif
#define _RF2_tfbot_included

Address g_iTFBotNextBot[MAXTF2PLAYERS];
Address g_iTFBotLocomotion[MAXTF2PLAYERS];
Address g_iTFBotVision[MAXTF2PLAYERS];

bool g_bTFBotStrafing[MAXTF2PLAYERS];

Handle g_hTFBotWalkToTeleporterTimer[MAXTF2PLAYERS];
bool g_bTFBotWalkingToTeleporter[MAXTF2PLAYERS];

public void OnClientDisconnect_Post(int client)
{
	g_iTFBotNextBot[client] = Address_Null;
	g_iTFBotVision[client] = Address_Null;
	g_iTFBotLocomotion[client] = Address_Null;
	
	g_bTFBotStrafing[client] = false;
	g_bTFBotWalkingToTeleporter[client] = false;
}

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
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i, true) || !IsFakeClient(i) || !PF_Exists(i))
			continue;

		GetClientAbsOrigin(i, botPos);
		threat = GetEntityFromKnown(GetPrimaryKnownThreat(g_iTFBotVision[i], false));
			
		if (IsValidEntity(threat))
		{
			class = TF2_GetPlayerClass(i);
			if (GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(i, 2))
				melee = true;
				
			if (melee || g_bIsGiant[i])
			{
				if (class != TFClass_Engineer && class != TFClass_Spy)
				{
					PF_StartPathing(i);
					// Forcing bots to rush players when they have their melee out,
					// since default TFBot melee AI is pretty laughable.
					GetEntPropVector(threat, Prop_Data, "m_vecAbsOrigin", threatPos);
					
					skill = GetEntProp(i, Prop_Send, "m_nBotSkill");
					// randomly strafe if we're hard or above to throw off our enemy
					if (threat <= MaxClients && skill >= TFBotDifficulty_Hard)
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
						
						// don't bother if we can't access that area, most likely in a closed space such as a hallway
						if (!PF_IsPathToVectorPossible(i, threatPos))
							GetEntPropVector(threat, Prop_Data, "m_vecAbsOrigin", threatPos);

						if (!g_bTFBotStrafing[i])
						{
							// expert bots strafe more often
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
				}
			}
		}
		else if (g_bTeleporterEvent)
		{
			GetEntPropVector(g_iTeleporter, Prop_Data, "m_vecAbsOrigin", teleporterPos);
			if (!g_bTFBotWalkingToTeleporter[i] && GetVectorDistance(botPos, teleporterPos, true) <= Pow(3400.0, 2.0)) // stick close to the teleporter
			{
				PF_StartPathing(i);
				PF_SetGoalVector(i, teleporterPos);
				
				g_hTFBotWalkToTeleporterTimer[i] = CreateTimer(16.0, Timer_StopWalkingToTeleporter, 
				GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE); // stop after a bit
				
				g_bTFBotWalkingToTeleporter[i] = true;
			}
			else if (g_bTFBotWalkingToTeleporter[i] && g_hTFBotWalkToTeleporterTimer[i] != null)
			{
				if (GetVectorDistance(botPos, teleporterPos, true) <= 600.0) // we can stop when we're this close
					TriggerTimer(g_hTFBotWalkToTeleporterTimer[i], true);
			}
		}
		else
		{
			PF_StopPathing(i);
		}
	}
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

// NavMesh/NavArea stuff
stock NavArea GetSpawnPointFromNav(float pos[3], float minDist=MIN_SPAWN_DIST, float startDist=1000.0, float pos2[3] = NULL_VECTOR, bool randomDirection=false, float distMult=1.5)
{
	float direction[3];
	float angles[3];
	
	if (randomDirection)
		angles[1] = GetRandomFloat(0.0, 360.0);
	else
		GetVectorAnglesTwoPoints(pos, pos2, angles);
		
	GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(direction, direction);
	
	minDist *= GetRandomFloat(1.0, distMult);
	pos[0] += direction[0] * minDist;
	pos[1] += direction[1] * minDist;
	pos[2] += direction[2] * minDist;
	
	NavArea area;
	int attempts;
	while (attempts < 200 && !area)
	{
		area = TheNavMesh.GetNearestNavArea_Vec(pos, true, startDist, false, false);
		attempts++;
		startDist += 100.0;
	}
	
	if (!area) // Still null? No distance limit then!
		area = TheNavMesh.GetNearestNavArea_Vec(pos, true, 999999999.0, false, false);
	
	if (area)
	{
		int adjacentCount[4];
		adjacentCount[NORTH] = area.GetAdjacentCount(NORTH);
		adjacentCount[EAST] = area.GetAdjacentCount(EAST);
		adjacentCount[WEST] = area.GetAdjacentCount(WEST);
		adjacentCount[SOUTH] = area.GetAdjacentCount(SOUTH);
		
		int highest;
		NavDirType dir;
		for (int i = 0; i < 4; i++)
		{
			if (adjacentCount[i] > highest)
			{
				highest = adjacentCount[i];
				dir = view_as<NavDirType>(i);
			}
		}
		
		NavArea oldArea = area;
		area = area.GetAdjacentArea(dir, GetRandomInt(1, highest)-1);
		if (!area)
			area = oldArea;
	}

	return area;
}