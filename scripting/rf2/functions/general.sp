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
		if (!IsClientInGame(i))
			continue;
		
		SetEntPropEnt(i, Prop_Data, "m_hCtrl", fog);
	}
	
	PrintToServer("[RF2] Game Over!");
	EmitSoundToAll(SND_GAME_OVER);
	ForceTeamWin(TEAM_ENEMY);
}

void ReloadPlugin(bool changeMap=true)
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
	g_bPluginReloading = true;
	
	if (changeMap)
	{
		SetNextStage(0);
	}
	else
	{
		if (!g_bWaitingForPlayers)
		{
			InsertServerCommand("mp_restartgame_immediate 2");
		}
		
		InsertServerCommand("sm plugins reload rf2");
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
				int enemyType = GetPlayerEnemyType(i);
				int bossType = GetPlayerBossType(i);
				int oldSkill = enemyType >= 0 ? g_iEnemyBotSkill[enemyType] : g_iBossBotSkill[bossType];
				
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

void TE_TFParticle(const char[] effectName, const float pos[3], int entity=-1, int attachType=PATTACH_ABSORIGIN, const char[] attachmentName="",
bool reset=false, int clientArray[MAXTF2PLAYERS] = {-1, ...}, int clientAmount=0)
{
	TE_Start("TFParticleEffect");
	
	int index = GetParticleEffectIndex(effectName);
	if (index == -1)
	{
		// try to cache it
		index = PrecacheParticleEffect(effectName);
	}
	
	if (index > -1)
	{
		TE_WriteNum("m_iParticleSystemIndex", index);
		
		if (attachmentName[0])
		{
			int attachPoint = LookupEntityAttachment(entity, attachmentName);
			if (attachPoint != 0)
			{
				TE_WriteNum("m_iAttachmentPointIndex", attachPoint);
			}
		}
		
		if (entity > -1)
		{
			TE_WriteNum("entindex", entity);
		}

		TE_WriteFloat("m_vecOrigin[0]", pos[0]);
		TE_WriteFloat("m_vecOrigin[1]", pos[1]);
		TE_WriteFloat("m_vecOrigin[2]", pos[2]);
		TE_WriteFloat("m_vecStart[0]", pos[0]);
		TE_WriteFloat("m_vecStart[1]", pos[1]);
		TE_WriteFloat("m_vecStart[2]", pos[2]);
		
		TE_WriteNum("m_iAttachType", attachType);
		TE_WriteNum("m_bResetParticles", bool(reset));
		
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
}

int PrecacheParticleEffect(const char[] name)
{
	int index;
	int table = FindStringTable("ParticleEffectNames");
	int count = GetStringTableNumStrings(table);
	char buffer[128];
	
	for (int i = 0; i < count; i++)
	{
		ReadStringTable(table, i, buffer, sizeof(buffer));
		if (strcmp2(buffer, name))
		{
			index = i;
			g_hParticleEffectTable.Resize(i+1);
			g_hParticleEffectTable.SetString(i, name);
			break;
		}
	}
	
	if (index < 0)
	{
		LogError("[PrecacheParticleEffect] Couldn't find particle effect \"%s\".", name);
	}
	
	return index;
}

int GetParticleEffectIndex(const char[] name)
{
	return g_hParticleEffectTable.FindString(name);
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

stock bool bool(any value)
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