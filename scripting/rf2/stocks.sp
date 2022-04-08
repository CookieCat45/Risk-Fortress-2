#if defined _RF2_stocks_included
 #endinput
#endif
#define _RF2_stocks_included

// ONLY pass SQUARED distances for minDistance.
stock int GetNearestEntity(float origin[3], char[] classname, char[] targetname="", float minDistance = -1.0)
{
    int nearestEntity = -1;
    float entityOrigin[3];
    char entName[128];
    bool checkName;
    
    if (targetname[0] != '\0')
    	checkName = true;
    
    //Get the distance between the first entity and client
    float distance, nearestDistance = -1.0;
    
    //Find all the entity and compare the distances
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, classname)) != -1)
    {
    	if (checkName)
    	{
    		GetEntPropString(entity, Prop_Data, "m_iName", entName, sizeof(entName));
    		if (strcmp(targetname, entName) != 0)
    			continue;
    	}
    	
        GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityOrigin);
        distance = GetVectorDistance(origin, entityOrigin, true);
        
        if (distance >= minDistance)
        {
        	if (distance < nearestDistance || nearestDistance == -1.0)
			{
				nearestEntity = entity;
				nearestDistance = distance;
			}
        }
    }
    return nearestEntity;
}

public bool TraceFilter_SpawnCheck(int entity, int mask, int self)
{
	if (entity == self)
		return false;
	
	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	
	// for some reason these types of entities trigger the check despite not being solid
	if (StrContains(classname, "tf_projectile") != -1 || strcmp(classname, "prop_ragdoll") == 0)
		return false;
	
	// collide with anything solid to players
	if (mask == MASK_PLAYERSOLID)
		return true;
		
	return false;
}

stock void ClientReset(int client, bool disconnect = false)
{
	g_bIsBoss[client] = false;
	g_bIsTeleporterBoss[client] = false;
	g_bIsGiant[client] = false;
	
	g_iPlayerRobotType[client] = -1;
	g_iPlayerBossType[client] = -1;
	
	if (!disconnect)
	{
		CreateTimer(0.1, Timer_ResetModel, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);	
	}
	if (!g_bGracePeriod && g_iPlayerSurvivorIndex[client] > -1)
	{
		g_iPlayerLevel[client] = 1;
		g_flPlayerXP[client] = 0.0;
		g_flPlayerNextLevelXP[client] = 60.0;
		
		g_iPlayerSurvivorIndex[client] = -1;
	}
}

stock bool IsValidClient(int client, bool alivecheck = false)
{
	if(client<1 || client>MaxClients)
		return false;

	if(!IsClientInGame(client))
		return false;
	
	/* These just aren't necessary to check to be honest.
	
	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if(IsClientSourceTV(client) || IsClientReplay(client))
		return false;
	*/
	
	if (alivecheck)
	{
		if (!IsPlayerAlive(client))
			return false;
	}
	
	return true;
}

stock void ForceTeamWin(int team)
{
	int point;
	point = FindEntityByClassname(point, "team_control_point_master");
	
	if (!IsValidEntity(point))
		point = CreateEntityByName("team_control_point_master");
		
	SetVariantInt(team);
	AcceptEntityInput(point, "SetWinner");
}

stock void CopyVectors(float vec1[3], float vec2[3])
{
	vec2[0] = vec1[0];
	vec2[1] = vec1[1];
	vec2[2] = vec1[2];
}

stock float GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

stock void GetClassString(TFClassType class, char[] buffer, int size, bool underScore = false, bool capitalize = false)
{
	switch (class)
	{
		case TFClass_Scout: FormatEx(buffer, size, "scout");
		case TFClass_Soldier: FormatEx(buffer, size, "soldier");
		case TFClass_Pyro: FormatEx(buffer, size, "pyro");
		case TFClass_DemoMan: FormatEx(buffer, size, "demoman");
		case TFClass_Heavy: FormatEx(buffer, size, "heavy");
		case TFClass_Engineer: FormatEx(buffer, size, "engineer");
		case TFClass_Medic: FormatEx(buffer, size, "medic");
		case TFClass_Sniper: FormatEx(buffer, size, "sniper");
		case TFClass_Spy: FormatEx(buffer, size, "spy");
		default: FormatEx(buffer, size, "unknown");
	}
	
	if (underScore)
		Format(buffer, size, "%s_", buffer);
		
	if (capitalize)
	{
		int chr = buffer[0];
		CharToUpper(chr);
	}
}

stock void TF2_RemoveAllWearables(int client)
{
	char classname[64];
	for (int i = MaxClients+1; i <= 2048; i++)
	{
		if (!IsValidEntity(i))
			continue;
			
		GetEntityClassname(i, classname, sizeof(classname));
		if (StrContains(classname, "tf_wearable") != -1 && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client)
			TF2_RemoveWearable(client, i);
	}
}

stock int CalculatePlayerMaxHealth(int client, bool setAttribute=false, bool fullHeal=false)
{
	int team = GetClientTeam(client);
	int maxHealth = 1;
	float extraHealth;
	
	if (team == TEAM_SURVIVOR)
	{
		maxHealth = RoundFloat(g_iPlayerBaseHealth[client] * (1.0 + ((g_iPlayerLevel[client]-1) * LEVEL_HEALTH_INCREASE)));
	}
	else if (team == TEAM_ROBOT)
	{
		maxHealth = RoundFloat(g_iPlayerBaseHealth[client] * (1.0 + ((g_iEnemyLevel-1) * LEVEL_HEALTH_INCREASE)));
	}
	
	if (g_iPlayerItem[client][Item_PrideScarf] > 0)
	{
		float itemMult = IntToFloat(g_iPlayerItem[client][Item_PrideScarf]);
		extraHealth += (IntToFloat(maxHealth) * (1.0 + (0.1 * itemMult))) - IntToFloat(maxHealth);
	}
	
	maxHealth += RoundFloat(extraHealth);
	
	if (!IsValidEntity(g_iPlayerStatWearable[client]))
		g_iPlayerStatWearable[client] = CreateWearable(client, "tf_wearable", ATTRIBUTE_WEARABLE_INDEX, BASE_PLAYER_ATTRIBUTES, true);
		
	if (setAttribute)
	{
		int classMaxHealth = TF2_GetClassMaxHealth(TF2_GetPlayerClass(client));
		TF2Attrib_SetByDefIndex(g_iPlayerStatWearable[client], 26, IntToFloat(maxHealth - classMaxHealth));
		if (TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			float value = 1.0 + (LEVEL_HEALTH_INCREASE * IntToFloat(g_iPlayerLevel[client]-1));
			TF2Attrib_SetByDefIndex(g_iPlayerStatWearable[client], 286, value);
		}
	}
	
	// Need to do this after
	char classname[64];
	Address attrib;
	for (int i = 0; i <= 2048; i++)
	{
		if (!IsValidEntity(i) || i == g_iPlayerStatWearable[client])
			continue;
			
		GetEntityClassname(i, classname, sizeof(classname));
		
		if (StrContains(classname, "tf_wearable") != -1 || StrContains(classname, "tf_weapon") != -1)
		{
			if (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client)
			{
				attrib = TF2Attrib_GetByDefIndex(i, 26);
				if (attrib == Address_Null)
					attrib = TF2Attrib_GetByDefIndex(i, 125);
					
				if (attrib != Address_Null)
				{
					maxHealth += RoundFloat(TF2Attrib_GetValue(attrib));
				}
			}
		}
	}
	
	if (fullHeal)
		SetEntityHealth(client, maxHealth);
	
	g_iPlayerCalculatedMaxHealth[client] = maxHealth;
		
	return maxHealth;
}

stock float CalculatePlayerMaxSpeed(int client)
{
	float speed = g_flPlayerMaxSpeed[client];
	
	if (g_iPlayerItem[client][Item_RobinWalkers] > 0)
		speed *= 1.0 + (IntToFloat(g_iPlayerItem[client][Item_RobinWalkers]) * 0.05);
	
	char classname[32];
	Address attrib;
	
	for (int wep = MaxClients+1; wep <= 2048; wep++)
	{
		if (!IsValidEntity(wep))
			continue;
		
		GetEntityClassname(wep, classname, sizeof(classname));
		if (StrContains(classname, "tf_wearable") != -1 || StrContains(classname, "tf_weapon") != -1)
		{
			if (GetEntPropEnt(wep, Prop_Send, "m_hOwnerEntity") == client)
			{
				if (TF2Attrib_GetByDefIndex(wep, 128) != Address_Null)
				{
					if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") != wep)
						continue;
				}
					
				if ((attrib = TF2Attrib_GetByDefIndex(wep, 107)) != Address_Null) // "move speed bonus"
					speed *= TF2Attrib_GetValue(attrib);
					
				if ((attrib = TF2Attrib_GetByDefIndex(wep, 54)) != Address_Null) // "move speed penalty"
					speed *= TF2Attrib_GetValue(attrib);
					
				if ((attrib = TF2Attrib_GetByDefIndex(wep, 442)) != Address_Null) // "major move speed bonus"
					speed *= TF2Attrib_GetValue(attrib);
					
				if ((attrib = TF2Attrib_GetByDefIndex(wep, 489)) != Address_Null) // "SET BONUS: move speed set bonus"
					speed *= TF2Attrib_GetValue(attrib);
			}
		}
	}
	g_flPlayerCalculatedMaxSpeed[client] = speed;
}

stock int TF2_GetClassMaxHealth(TFClassType class)
{
	switch (class)
	{
		case TFClass_Scout: return 125;
		case TFClass_Soldier: return 200;
		case TFClass_Pyro: return 175;
		case TFClass_DemoMan: return 175;
		case TFClass_Heavy: return 300;
		case TFClass_Engineer: return 125;
		case TFClass_Medic: return 150;
		case TFClass_Sniper: return 125;
		case TFClass_Spy: return 125;
	}
	return 1;
}

stock bool IsInvuln(int client)
{
	if(!IsValidClient(client))
		return true;

	return (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked) ||
		TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) ||
		!GetEntProp(client, Prop_Data, "m_takedamage"));
}

stock void PrintDeathMessage(int client)
{
	char userName[128];
	GetClientName(client, userName, sizeof(userName));
	int randomMessage = GetRandomInt(1, 10);
	switch (randomMessage)
	{
		case 1:
		{
			CPrintToChatAll("{red}%s's family will never know how they died.", userName);
		}
		case 2:
		{
			CPrintToChatAll("{red}%s really messed up.", userName);
		}
		case 3:
		{
			CPrintToChatAll("{red}%s's death was extremely painful.", userName);
		}
		case 4:
		{
			CPrintToChatAll("{red}Try playing on \"Drizzle\" mode for an easier time, %s.", userName);
		}
		case 5:
		{
			CPrintToChatAll("{red}That was absolutely your fault, %s.", userName);
		}
		case 6:
		{
			CPrintToChatAll("{red}They will surely feast on %s's flesh.", userName);
		}
		case 7:
		{
			CPrintToChatAll("{red}%s dies in a hilarious pose.", userName);
		}
		case 8:
		{
			CPrintToChatAll("{red}%s embraces the void.", userName);
		}
		case 9:
		{
			CPrintToChatAll("{red}%s had a lot more to live for.", userName);
		}
		case 10:
		{
			CPrintToChatAll("{red}%s's body was gone an hour later.", userName);
		}
	}
}

stock void SetHudDifficulty(int difficulty)
{
	switch (difficulty)
	{
		case SubDifficulty_Easy:
		{
			g_iMainHudR = 100;
			g_iMainHudG = 255;
			g_iMainHudB = 100;
			g_szHudDifficulty = "Difficulty: Easy";
		}
		case SubDifficulty_Normal:
		{
			g_iMainHudR = 255;
			g_iMainHudG = 215;
			g_iMainHudB = 0;
			Format(g_szHudDifficulty, sizeof(g_szHudDifficulty), "Difficulty: Normal");
		}
		case SubDifficulty_Hard:
		{
			g_iMainHudR = 255;
			g_iMainHudG = 125;
			g_iMainHudB = 0;
			Format(g_szHudDifficulty, sizeof(g_szHudDifficulty), "Difficulty: Hard");
		}
		case SubDifficulty_VeryHard:
		{
			g_iMainHudR = 255;
			g_iMainHudG = 0;
			g_iMainHudB = 0;
			Format(g_szHudDifficulty, sizeof(g_szHudDifficulty), "Difficulty: Very Hard");
		}
		case SubDifficulty_Insane:
		{
			g_iMainHudR = 150;
			g_iMainHudG = 0;
			g_iMainHudB = 0;
			Format(g_szHudDifficulty, sizeof(g_szHudDifficulty), "Difficulty: Insane");
		}
		case SubDifficulty_Impossible:
		{
			g_iMainHudR = 130;
			g_iMainHudG = 100;
			g_iMainHudB = 255;
			Format(g_szHudDifficulty, sizeof(g_szHudDifficulty), "Difficulty: Impossible");
		}
		case SubDifficulty_ISeeYou:
		{
			g_iMainHudR = 75;
			g_iMainHudG = 45;
			g_iMainHudB = 75;
			Format(g_szHudDifficulty, sizeof(g_szHudDifficulty), "I SEE YOU");
		}
		case SubDifficulty_ComingForYou:
		{
			g_iMainHudR = 110;
			g_iMainHudG = 0;
			g_iMainHudB = 0;
			Format(g_szHudDifficulty, sizeof(g_szHudDifficulty), "I'M COMING FOR YOU");
		}
		case SubDifficulty_Hahaha:
		{
			g_iMainHudR = 80;
			g_iMainHudG = 0;
			g_iMainHudB = 0;
			Format(g_szHudDifficulty, sizeof(g_szHudDifficulty), "HAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHA");
		}
	}
}

// Better way to spawn particles in most cases
stock void TE_SetupParticle(const char[] effectName, float origin[3], int clientArray[MAXTF2PLAYERS] = {INVALID_ENT_REFERENCE, ...}, int clientAmount = 0)
{
	TE_Start("TFParticleEffect");
	int table = FindStringTable("ParticleEffectNames");
	int count = GetStringTableNumStrings(table);
	int strIndex = -1;
	char buffer[256];
	
	for (int i = 0; i <= count; i++)
	{
		ReadStringTable(table, i, buffer, sizeof(buffer));
		if (strcmp(buffer, effectName) == 0)
		{
			strIndex = i;
			break;
		}
	}
	
	if (strIndex > -1)
	{
		TE_WriteNum("m_iParticleSystemIndex", strIndex);
		TE_WriteFloat("m_vecOrigin[0]", origin[0]);
		TE_WriteFloat("m_vecOrigin[1]", origin[1]);
		TE_WriteFloat("m_vecOrigin[2]", origin[2]);
		TE_WriteFloat("m_vecStart[0]", origin[0]);
		TE_WriteFloat("m_vecStart[1]", origin[1]);
		TE_WriteFloat("m_vecStart[2]", origin[2]);
	}
	
	if (clientAmount <= 0)
	{
		TE_SendToAll();
	}
	else
	{
		for (int i = 0; i < clientAmount; i++)
			TE_SendToClient(clientArray[i]);
	}
}

// StrContains(), but the string needs to be an exact match.
// This means there must be either whitespace or out-of-bounds characters before and after the found string.
// So if you search "apple" in "applebanana", -1 will be returned, while StrContains() would return a positive value.
// But if you search "apple" in "apple banana", it will return a positive value.
stock int StrContainsEx(const char[] str, const char[] substr, bool caseSensitive=true)
{
	int position = StrContains(str, substr, caseSensitive);
	if (position > -1)
	{
		if (position-1 == -1 || IsCharSpace(str[position-1]))
		{
			int length = strlen(str);
			int subLength = strlen(substr);
			
			if (position + subLength >= length || IsCharSpace(str[position+subLength]))
				return position;
		}
	}
	return -1;
}

stock void ResetAFKTime(int client)
{
	if (g_bIsAFK[client])
		PrintCenterText(client, "You are no longer marked as AFK.");
	
	g_flAFKTime[client] = 0.0;
	g_bIsAFK[client] = false;
}

stock float IntToFloat(int value)
{
	// ok
	float newValue = value+0.0;
	return newValue;
}

public bool TraceWallsOnly(int entity, int mask)
{
	return false;
}