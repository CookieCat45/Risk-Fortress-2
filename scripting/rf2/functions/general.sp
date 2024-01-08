#if defined _RF2_functions_general_included
 #endinput
#endif
#define _RF2_functions_general_included

#pragma semicolon 1
#pragma newdecls required

// If the result of GetRandomInt(min, max) is below or equal to goal, returns true.
bool RandChanceInt(int min, int max, int goal, int &result=0)
{
	result = GetRandomInt(min, max);
	return result <= goal;
}

// If the result of GetRandomFloat(min, max) is below or equal to goal, returns true.
bool RandChanceFloat(float min, float max, float goal, float &result=0.0)
{
	result = GetRandomFloat(min, max);
	return result <= goal;
}

void ForceTeamWin(int team)
{
	int point;
	point = FindEntityByClassname(point, "team_control_point_master");
	
	if (!IsValidEntity(point))
	{
		point = CreateEntityByName("team_control_point_master");
	}
	
	SetVariantInt(team);
	AcceptEntityInput(point, "SetWinner");
}

void GameOver()
{
	g_bGameOver = true;
	
	int fog = CreateEntityByName("env_fog_controller");
	DispatchKeyValue(fog, "spawnflags", "1");
	DispatchKeyValueInt(fog, "fogenabled", 1);
	DispatchKeyValueFloat(fog, "fogstart", 500.0);
	DispatchKeyValueFloat(fog, "fogend", 800.0);
	DispatchKeyValueFloat(fog, "fogmaxdensity", 0.5);
	DispatchKeyValue(fog, "fogcolor", "15 0 0");
		
	DispatchSpawn(fog);				
	AcceptEntityInput(fog, "TurnOn");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		SetEntPropEnt(i, Prop_Data, "m_hCtrl", fog);
	}
	
	PrintToServer("[RF2] Game Over!");
	EmitSoundToAll(SND_GAME_OVER);
	ForceTeamWin(TEAM_ENEMY);
}

void ReloadPlugin(bool changeMap=true)
{
	if (!g_bMapChanging)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;
				
			SetVariantString("");
			AcceptEntityInput(i, "SetCustomModel");
			
			if (IsPlayerAlive(i))
			{
				TF2_RemoveAllWeapons(i);
				TF2_RemoveAllWearables(i);
				SilentlyKillPlayer(i);
			}
		}
		
		StopMusicTrackAll();
		if (!changeMap && GetTotalHumans() == 0)
		{
			InsertServerCommand("mp_waitingforplayers_restart 1");
		}
	}
	
	g_bPluginReloading = true;
	
	if (changeMap)
	{
		SetNextStage(0);
	}
	else
	{
		if (!g_bWaitingForPlayers && !g_bMapChanging)
		{
			InsertServerCommand("mp_restartgame_immediate 2");
		}
		
		InsertServerCommand("sm plugins reload rf2; sm_reload_translations");
	}
}

bool IsBossEventActive()
{
	return GetTeleporterEventState() == TELE_EVENT_ACTIVE || g_bTankBossMode && !g_bGracePeriod;
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
			g_szHudDifficulty = "HAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHA";
		}
	}
}

void SetDifficultyLevel(int level)
{
	//int oldLevel = g_iDifficultyLevel;
	g_iDifficultyLevel = level;
	OnDifficultyChanged(level);
}

void OnDifficultyChanged(int newLevel)
{
	int skill;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsFakeClient(i) || !IsPlayerAlive(i))
			continue;
			
		skill = g_TFBot[i].GetSkillLevel();
		
		switch (newLevel)
		{
			case DIFFICULTY_SCRAP, DIFFICULTY_IRON:
			{
				Enemy enemy = Enemy(i);
				int oldSkill = enemy.BotSkill;
				
				if (skill != oldSkill)
					g_TFBot[i].SetSkillLevel(oldSkill);
			}
			
			case DIFFICULTY_STEEL:
			{
				if (skill < TFBotDifficulty_Hard && skill != TFBotDifficulty_Expert)
					g_TFBot[i].SetSkillLevel(TFBotDifficulty_Hard);
			}
			
			case DIFFICULTY_TITANIUM:
			{
				if (skill < TFBotDifficulty_Expert)
					g_TFBot[i].SetSkillLevel(TFBotDifficulty_Expert);
			}
		}
	}
}

int GetDifficultyName(int difficulty, char[] buffer, int size, bool colorTags=true)
{
	int cells;
	switch (difficulty)
	{
		case DIFFICULTY_SCRAP: cells = strcopy(buffer, size, "{saddlebrown}Scrap{default}");
		case DIFFICULTY_IRON: cells = strcopy(buffer, size, "{gray}Iron{default}");
		case DIFFICULTY_STEEL: cells = strcopy(buffer, size, "{darkgray}Steel{default}");
		case DIFFICULTY_TITANIUM: cells = strcopy(buffer, size, "{whitesmoke}Titanium{default}");
		default:  cells = strcopy(buffer, size, "unknown");
	}
	
	if (!colorTags)
	{
		CRemoveTags(buffer, size);
	}
	
	return cells;
}

float GetDifficultyFactor(int difficulty)
{
	switch (difficulty)
	{
		case DIFFICULTY_SCRAP: return DifficultyFactor_Scrap;
		case DIFFICULTY_IRON: return DifficultyFactor_Iron;
		case DIFFICULTY_STEEL: return DifficultyFactor_Steel;
		case DIFFICULTY_TITANIUM: return DifficultyFactor_Titanium;
	}
	
	return DifficultyFactor_Iron;
}

// It does not matter if the .mdl extension is included in the path or not.
void AddModelToDownloadsTable(const char[] file)
{
	char buffer[PLATFORM_MAX_PATH];
	char extension[16];
	strcopy(buffer, sizeof(buffer), file);
	ReplaceStringEx(buffer, sizeof(buffer), ".mdl", "");
	
	for (int i = 1; i <= 6; i++)
	{
		switch (i)
		{
			case 1: extension = ".mdl";
			case 2: extension = ".vvd";
			case 3: extension = ".dx80.vtx";
			case 4: extension = ".dx90.vtx";
			case 5: extension = ".sw.vtx";
			case 6: extension = ".phy";
		}
		
		Format(buffer, sizeof(buffer), "%s%s", buffer, extension);
		if (FileExists(buffer))
		{
			AddFileToDownloadsTable(buffer);
		}
		else if (strcmp2(extension, ".mdl") && !FileExists(buffer, true)) // we only care about reporting if the .mdl file missing, and non Valve files
		{
			LogError("File \"%s\" is missing from the server files. It will not be added to the downloads table.", buffer);
		}
		
		ReplaceStringEx(buffer, sizeof(buffer), extension, "");
	}
}

// This will ensure that sound/ is at the beginning of the file path if it isn't.
void AddSoundToDownloadsTable(const char[] file)
{
	char buffer[PLATFORM_MAX_PATH];
	strcopy(buffer, sizeof(buffer), file);
	
	if (StrContains(buffer, "sound/") != 0)
	{
		FormatEx(buffer, sizeof(buffer), "sound/%s", file);
	}
	
	if (FileExists(buffer))
	{
		AddFileToDownloadsTable(buffer);
	}
	else if (!FileExists(buffer, true)) // don't show warnings for Valve files.
	{
		LogError("File \"%s\" is missing from the server files. It will not be added to the downloads table.", buffer);
	}
}

// This will remove the extension and attempt to download both the .vmt and .vtf files with the file path given. 
// If neither exist, an error is logged. 
// materials/ MUST be included in the file path!
stock void AddMaterialToDownloadsTable(const char[] file)
{	
	bool exists, valveFile;
	char buffer[PLATFORM_MAX_PATH];
	strcopy(buffer, sizeof(buffer), file);
	ReplaceStringEx(buffer, sizeof(buffer), ".vmt", "");
	ReplaceStringEx(buffer, sizeof(buffer), ".vtf", "");
	
	Format(buffer, sizeof(buffer), "%s.vmt", buffer);
	if (FileExists(buffer))
	{
		exists = true;
		AddFileToDownloadsTable(buffer);
	}
	else if (FileExists(buffer, true)) // Check if the file exists in the game's .vpk files
	{
		valveFile = true;
	}
	
	if (!valveFile)
	{
		ReplaceStringEx(buffer, sizeof(buffer), ".vmt", "");
		Format(buffer, sizeof(buffer), "%s.vtf", buffer);
		if (FileExists(buffer))
		{
			exists = true;
			AddFileToDownloadsTable(buffer);
		}
		else if (FileExists(buffer, true))
		{
			valveFile = true;
		}
	}	
	
	if (!exists && !valveFile)
	{
		ReplaceStringEx(buffer, sizeof(buffer), ".vtf", "");
		LogError("Neither a .vmt or .vtf file exists for the file path: \"%s\". It will not be added to the downloads table.", buffer);
	}
}

/*
void TE_DrawBox(int client, const float origin[3], const float endOrigin[3], const float inMins[3], const float inMaxs[3], float duration = 0.1, int laserIndex, int color[4])
{
	float mins[3], maxs[3];
	CopyVectors(inMins, mins);
	CopyVectors(inMaxs, maxs);
	if( mins[0] == maxs[0] && mins[1] == maxs[1] && mins[2] == maxs[2] )
	{
		mins = {-15.0, -15.0, -15.0};
		maxs = {15.0, 15.0, 15.0};
	}
	else
	{
		float start[3], end[3];
		CopyVectors(origin, start);
		CopyVectors(endOrigin, end);
		AddVectors(start, maxs, maxs);
		AddVectors(end, mins, mins);
	}
	
	float pos1[3], pos2[3], pos3[3], pos4[3], pos5[3], pos6[3];
	pos1 = maxs;
	pos1[0] = mins[0];
	pos2 = maxs;
	pos2[1] = mins[1];
	pos3 = maxs;
	pos3[2] = mins[2];
	pos4 = mins;
	pos4[0] = maxs[0];
	pos5 = mins;
	pos5[1] = maxs[1];
	pos6 = mins;
	pos6[2] = maxs[2];
	
	TE_SendBeam(client, maxs, pos1, duration, laserIndex, color);
	TE_SendBeam(client, maxs, pos2, duration, laserIndex, color);
	TE_SendBeam(client, maxs, pos3, duration, laserIndex, color);
	TE_SendBeam(client, pos6, pos1, duration, laserIndex, color);
	TE_SendBeam(client, pos6, pos2, duration, laserIndex, color);
	TE_SendBeam(client, pos6, mins, duration, laserIndex, color);
	TE_SendBeam(client, pos4, mins, duration, laserIndex, color);
	TE_SendBeam(client, pos5, mins, duration, laserIndex, color);
	TE_SendBeam(client, pos5, pos1, duration, laserIndex, color);
	TE_SendBeam(client, pos5, pos3, duration, laserIndex, color);
	TE_SendBeam(client, pos4, pos3, duration, laserIndex, color);
	TE_SendBeam(client, pos4, pos2, duration, laserIndex, color);
}

void TE_SendBeam(int client, const float mins[3], const float maxs[3], float duration = 0.1, int laserIndex, int color[4])
{
	TE_SetupBeamPoints(mins, maxs, laserIndex, laserIndex, 0, 30, duration, 1.0, 1.0, 1, 0.0, color, 30);
	TE_SendToClient(client);
}
*/

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
			{
				return position;
			}
		}
	}
	
	return -1;
}

bool strcmp2(const char[] str1, const char[] str2, bool caseSensitive=true)
{
	if (caseSensitive && str1[0] != str2[0])
	{
		return false;
	}
	
	return (strcmp(str1, str2, caseSensitive) == 0);
}

void CopyVectors(const float vec1[3], float vec2[3])
{
	vec2[0] = vec1[0];
	vec2[1] = vec1[1];
	vec2[2] = vec1[2];
}

bool CompareVectors(const float vec1[3], const float vec2[3])
{
	return(vec1[0] == vec2[0]
		&& vec1[1] == vec2[1]
		&& vec1[2] == vec2[2]);
}

float VectorSum(const float vec[3], bool absolute=false)
{
	if (absolute)
	{
		return FloatAbs(vec[0]) + FloatAbs(vec[1]) + FloatAbs(vec[2]);
	}

	return vec[0] + vec[1] + vec[2];
}

void GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

void SetAllInArray(any[] array, int size, any value)
{
	for (int i = 0; i < size; i++)
		array[i] = value;
}

stock bool asBool(any value)
{
	return view_as<bool>(value);
}

stock float sq(float num)
{
	return Pow(num, 2.0);
}

stock float fmodf(float num, float denom)
{
	return num - denom * RoundToFloor(num / denom);
}

// not implemented by default -_-
stock float operator%(float oper1, float oper2)
{
	return fmodf(oper1, oper2);
}

stock int imin(int val1, int val2)
{
	return val1 < val2 ? val1 : val2;
}

stock int imax(int val1, int val2)
{
	return val1 > val2 ? val1 : val2;
}

stock float fmin(float val1, float val2)
{
	return val1 < val2 ? val1 : val2;
}

stock float fmax(float val1, float val2)
{	
	return val1 > val2 ? val1 : val2;
}