#if defined _RF2_stocks_included
 #endinput
#endif
#define _RF2_stocks_included

/*
bool GetEntityAttachment(int entity, const char[] name, float pos[3] = {0.0, 0.0, 0.0}, float angles[3] = {0.0, 0.0, 0.0})
{
	if (g_hSDKGetAttachment)
		return SDKCall(g_hSDKGetAttachment, entity, name, pos, angles);
		
	return false;
}
*/

// ONLY pass SQUARED distances for minDistance.
int GetNearestEntity(float origin[3], char[] classname, char[] targetname="", float minDistance = -1.0, int team = -1)
{
	int nearestEntity = -1;
	float entityOrigin[3];
	char entName[128];
	bool checkName;
	
	if (targetname[0] != '\0')
		checkName = true;
	
	float distance, nearestDistance = -1.0;
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, classname)) != -1)
	{
		if (checkName)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", entName, sizeof(entName));
			if (strcmp(targetname, entName) != 0)
				continue;
		}
		
		if (team > -1)
		{
			if (GetEntProp(entity, Prop_Data, "m_iTeamNum") != team)
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

// ONLY pass SQUARED distances for minDistance.
int GetNearestPlayer(float origin[3], int team = -1, float minDistance = -1.0, bool aliveCheck=true)
{
	int nearestPlayer = -1;
	float pos[3];
	float distance, nearestDistance = -1.0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
	
		if (aliveCheck && !IsPlayerAlive(i))
			continue;
	
		if (team > -1 && GetClientTeam(i) != team)
			continue;
	
		GetClientAbsOrigin(i, pos);
		distance = GetVectorDistance(origin, pos, true);

		if (distance >= minDistance)
		{
			if (distance < nearestDistance || nearestDistance == -1.0)
			{
				nearestPlayer = i;
				nearestDistance = distance;
			}
		}
	}
	return nearestPlayer;
}

void RefreshClient(int client)
{
	g_bIsBoss[client] = false;
	g_bIsTeleporterBoss[client] = false;
	g_bIsGiant[client] = false;
	g_iPlayerRobotType[client] = -1;
	g_iPlayerBossType[client] = -1;

	if (IsValidClient(client))
		CreateTimer(0.1, Timer_ResetModel, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		
	// Do not reset our Survivor stats if we die in the grace period
	if (!g_bGracePeriod && g_iPlayerSurvivorIndex[client] >= 0 || g_bMapChanging)
	{
		g_iPlayerLevel[client] = 1;
		g_flPlayerXP[client] = 0.0;
		g_flPlayerNextLevelXP[client] = BASE_XP_REQUIREMENT;
		g_iPlayerSurvivorIndex[client] = -1;
	}
	
	g_bTFBotStrafing[client] = false;
	g_bTFBotWalkingToTeleporter[client] = false;
	g_iTFBotAutoPathTarget[client] = -1;
	
	g_bTFBotComputePathCooldown[client] = false;
	g_bTFBotAutoPathCooldown[client] = false;
	g_bTFBotAutoPathSearchCooldown[client] = false;
	
	if (g_hTFBotAutoPathTimer[client] != null)
	{
		KillTimer(g_hTFBotAutoPathTimer[client]);
		g_hTFBotAutoPathTimer[client] = null;
	}
	
	if (g_hMusicLoopTimer[client] != null)
	{
		delete g_hMusicLoopTimer[client];
		g_hMusicLoopTimer[client] = null;
	}
}

int GetPlayersOnTeam(int team, bool alive=false)
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != team)
			continue;
			
		if (alive && !IsPlayerAlive(i))
			continue;
			
		count++;
	}
	
	return count;
}

int GetRandomPlayer(int team = -1, bool alive=true)
{
	int count;
	int playerArray[MAXTF2PLAYERS] = {-1, ...};
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
			
		if (alive && !IsPlayerAlive(i) || team >= 0 && GetClientTeam(i) != team)
			continue;
			
		playerArray[count] = i;
		count++;
	}
	
	return playerArray[GetRandomInt(0, count>0 ? count-1 : count)];
}

public Action Timer_ResetModel(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || IsPlayerAlive(client))
		return;
	
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");	
}

bool IsValidClient(int client)
{
	if(client<1 || client>MaxClients)
		return false;

	if(!IsClientInGame(client))
		return false;
	
	return true;
}

void ForceTeamWin(int team)
{
	int point;
	point = FindEntityByClassname(point, "team_control_point_master");
	
	if (!IsValidEntity(point))
		point = CreateEntityByName("team_control_point_master");
		
	SetVariantInt(team);
	AcceptEntityInput(point, "SetWinner");
}

void GameOver()
{
	int fog = CreateEntityByName("env_fog_controller");
	DispatchKeyValue(fog, "targetname", "GameOverFog");
	DispatchKeyValue(fog, "spawnflags", "1");
	DispatchKeyValue(fog, "fogenabled", "1");
	DispatchKeyValue(fog, "fogstart", "500.0");
	DispatchKeyValue(fog, "fogend", "800.0");
	DispatchKeyValue(fog, "fogmaxdensity", "0.5");
	DispatchKeyValue(fog, "fogcolor", "15 0 0");
		
	DispatchSpawn(fog);				
	AcceptEntityInput(fog, "TurnOn");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		StopMusicTrack(i);
	
		SetVariantString("GameOverFog");
		AcceptEntityInput(i, "SetFogController");
	}
	
	EmitSoundToAll(SOUND_GAME_OVER);
	ForceTeamWin(TEAM_ROBOT);
}

void RestartGame(bool fullRestart=false, bool command=false)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		TF2_RemoveAllWeapons(i);
		TF2_RemoveAllWearables(i);
	}
	
	if (command && !g_bWaitingForPlayers && !fullRestart) // this was called through a server command.
	{
		InsertServerCommand("mp_restartgame_immediate 1");
	}
		
	if (fullRestart)
		SetNextStage(0);
	
	InsertServerCommand("sm plugins reload rf2");
}

void CopyVectors(float vec1[3], float vec2[3])
{
	vec2[0] = vec1[0];
	vec2[1] = vec1[1];
	vec2[2] = vec1[2];
}

float GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

int CalculatePlayerMaxHealth(int client, bool partialHeal=true, bool fullHeal=false)
{
	int oldMaxHealth = g_iPlayerCalculatedMaxHealth[client];
	float flMaxHealth = 1.0;
	
	float flBaseHealth = flt(g_iPlayerBaseHealth[client]);
	float flLevel;
	
	if (g_iPlayerSurvivorIndex[client] >= 0)
	{
		flLevel = flt(g_iPlayerLevel[client]);
	}
	else
	{
		flLevel = flt(g_iEnemyLevel);
	}
	
	flMaxHealth = flBaseHealth * (1.0 + (flLevel-1.0) * LEVEL_HEALTH_INCREASE);
	
	if (g_iPlayerItem[client][Item_PrideScarf] > 0)
	{
		float itemMult = flt(g_iPlayerItem[client][Item_PrideScarf]);
		flMaxHealth += flMaxHealth * (1.0 + (g_flItemModifier[Item_PrideScarf] * itemMult)) - flMaxHealth;
	}
	
	float flClassMaxHealth = flt(TF2_GetClassMaxHealth(TF2_GetPlayerClass(client)));
	TF2Attrib_SetByDefIndex(g_iPlayerStatWearable[client], 26, flMaxHealth-flClassMaxHealth);
	
	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		float value = 1.0 + (flLevel-1.0 * LEVEL_HEALTH_INCREASE);
		TF2Attrib_SetByDefIndex(g_iPlayerStatWearable[client], 286, value); // building health
	}
	
	// Need to do this after
	char classname[64];
	Address attrib;
	int entCount = GetEntityCount();
	for (int i = 0; i <= entCount; i++)
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
				{
					attrib = TF2Attrib_GetByDefIndex(i, 125);
				}
				
				if (attrib != Address_Null)
				{
					flMaxHealth += TF2Attrib_GetValue(attrib);
				}
			}
		}
	}
	
	int roundedMaxHealth = RoundFloat(flMaxHealth);
	if (fullHeal)
	{
		SetEntityHealth(client, roundedMaxHealth);
	}
	else if (partialHeal)
	{
		int heal = roundedMaxHealth - oldMaxHealth;
		SetEntityHealth(client, GetClientHealth(client)+heal);
	}
	
	g_iPlayerCalculatedMaxHealth[client] = roundedMaxHealth;
		
	return roundedMaxHealth;
}

float CalculatePlayerMaxSpeed(int client)
{
	float speed = g_flPlayerMaxSpeed[client];
	
	if (g_iPlayerItem[client][Item_RobinWalkers] > 0)
		speed *= 1.0 + (flt(g_iPlayerItem[client][Item_RobinWalkers]) * g_flItemModifier[Item_RobinWalkers]);
	
	char classname[32];
	Address attrib;
	int entCount = GetEntityCount();
	for (int wep = MaxClients+1; wep <= entCount; wep++)
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

float GetWeaponProcCoefficient(int weapon)
{
	char classname[128];
	GetEntityClassname(weapon, classname, sizeof(classname));
	
	if (strcmp(classname, "tf_weapon_minigun") == 0 || strcmp(classname, "tf_weapon_flamethrower") == 0)
	{
		return 0.65;
	}
	
	return 1.0;
}

bool RollAttackCrit(int client, float proc=1.0)
{
	float critChance = (flt(g_iPlayerItem[client][Item_TombReaders]) * g_flItemModifier[Item_TombReaders]) * proc;
	
	if (critChance > 100.0)
		critChance = 100.0;
		
	float randomNum = GetRandomFloat(0.0, 99.9);
	if (critChance > randomNum)
		return true;
	else
		return false;
}

bool IsInvuln(int client)
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

void PrintDeathMessage(int client)
{
	int randomMessage = GetRandomInt(1, 10);
	char message[256];
	switch (randomMessage)
	{
		case 1:
		{
			FormatEx(message, sizeof(message), "{red}%N's family will never know how they died.", client);
		}
		case 2:
		{
			FormatEx(message, sizeof(message), "{red}%N really messed up.", client);
		}
		case 3:
		{
			FormatEx(message, sizeof(message), "{red}%N's death was extremely painful.", client);
		}
		case 4:
		{
			FormatEx(message, sizeof(message), "{red}Try playing on \"Drizzle\" mode for an easier time, %N.", client);
		}
		case 5:
		{
			FormatEx(message, sizeof(message), "{red}That was absolutely your fault, %N.", client);
		}
		case 6:
		{
			FormatEx(message, sizeof(message), "{red}They will surely feast on %N's flesh.", client);
		}
		case 7:
		{
			FormatEx(message, sizeof(message), "{red}%N dies in a hilarious pose.", client);
		}
		case 8:
		{
			FormatEx(message, sizeof(message), "{red}%N embraces the void.", client);
		}
		case 9:
		{
			FormatEx(message, sizeof(message), "{red}%N had a lot more to live for.", client);
		}
		case 10:
		{
			FormatEx(message, sizeof(message), "{red}%N's body was gone an hour later.", client);
		}
	}
	
	#if defined _colors_included
	CPrintToChatAll(message);
	#else
	ReplaceStringEx(message, sizeof(message), "{red}", "");
	PrintToChatAll(message);
	#endif
}

void ResetAFKTime(int client)
{
	if (g_bIsAFK[client])
		PrintCenterText(client, "You are no longer marked as AFK.");
	
	g_flAFKTime[client] = 0.0;
	g_bIsAFK[client] = false;
}

int TF2_GetClassMaxHealth(TFClassType class)
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

void GetClassString(TFClassType class, char[] buffer, int size, bool underScore=false, bool capitalize=false)
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

void SetHudDifficulty(int difficulty)
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
			g_szHudDifficulty = "Difficulty: Normal";
		}
		case SubDifficulty_Hard:
		{
			g_iMainHudR = 255;
			g_iMainHudG = 125;
			g_iMainHudB = 0;
			g_szHudDifficulty = "Difficulty: Hard";
		}
		case SubDifficulty_VeryHard:
		{
			g_iMainHudR = 255;
			g_iMainHudG = 0;
			g_iMainHudB = 0;
			g_szHudDifficulty = "Difficulty: Very Hard";
		}
		case SubDifficulty_Insane:
		{
			g_iMainHudR = 150;
			g_iMainHudG = 0;
			g_iMainHudB = 0;
			g_szHudDifficulty = "Difficulty: Insane";
		}
		case SubDifficulty_Impossible:
		{
			g_iMainHudR = 130;
			g_iMainHudG = 100;
			g_iMainHudB = 255;
			g_szHudDifficulty = "Difficulty: Impossible";
		}
		case SubDifficulty_ISeeYou:
		{
			g_iMainHudR = 75;
			g_iMainHudG = 45;
			g_iMainHudB = 75;
			g_szHudDifficulty = "I SEE YOU";
		}
		case SubDifficulty_ComingForYou:
		{
			g_iMainHudR = 115;
			g_iMainHudG = 0;
			g_iMainHudB = 0;
			g_szHudDifficulty = "I'M COMING FOR YOU";
		}
		case SubDifficulty_Hahaha:
		{
			g_iMainHudR = 90;
			g_iMainHudG = 0;
			g_iMainHudB = 0;
			g_szHudDifficulty = "HAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHA";
		}
	}
}

// Better way to spawn particles in most cases
void TE_SetupParticle(const char[] effectName, float origin[3], int clientArray[MAXTF2PLAYERS] = {INVALID_ENT_REFERENCE, ...}, int clientAmount = 0)
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
int StrContainsEx(const char[] str, const char[] substr, bool caseSensitive=true)
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

// Converts an integer to a float
float flt(any value)
{
	float newValue = value+0.0;
	return newValue;
}

float ChopFloat(float value, int position)
{
	char buffer[32];
	switch (position)
	{
		case 1: FormatEx(buffer, sizeof(buffer), "%.1f", value);
		case 2: FormatEx(buffer, sizeof(buffer), "%.2f", value);
		case 3: FormatEx(buffer, sizeof(buffer), "%.3f", value);
		case 4: FormatEx(buffer, sizeof(buffer), "%.4f", value);
		case 5: FormatEx(buffer, sizeof(buffer), "%.5f", value);
	}
	
	float result = StringToFloat(buffer);
	return result;
}

public bool TraceFilter_SpawnCheck(int entity, int mask)
{
	if (entity == 0)
		return true;
	
	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	
	// for some reason ragdoll props trigger the check despite not being solid
	if (strcmp(classname, "prop_ragdoll") == 0)
		return false;
	
	// collide with anything solid to players (prop check is just to be safe)
	if (mask == MASK_PLAYERSOLID || StrContains(classname, "prop_"))
		return true;
		
	return false;
}

public bool TraceWallsOnly(int entity, int mask)
{
	return false;
}

public bool TraceDontHitSelf(int self, int contentsmask, int client)
{
	return !(self == client);
}