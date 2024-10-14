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

// If the result of GetRandomInt(min, max) is below or equal to goal, returns true. Factors in luck stat from client.
bool RandChanceIntEx(int client, int min, int max, int goal, int &result=0)
{
	int random, badRolls;
	int rollTimes = 1 + GetPlayerLuckStat(client);
	bool success;
	
	if (rollTimes < 0)
	{
		// We are unlucky. Roll once. To succeed, we must roll as many successful rolls as we have bad rolls.
		badRolls = rollTimes * -1;
		rollTimes = 1;
	}
	
	for (int i = 1; i <= rollTimes; i++)
	{
		if ((random = GetRandomInt(min, max)) <= goal)
		{
			if (badRolls <= 0) // If we have no bad rolls, we are successful.
			{
				success = true;
				break;
			}
			else // We have a bad roll. Decrement and try again for a bad result.
			{
				badRolls--;
				i = 0;
			}
		}
	}
	
	result = random;
	return success;
}

// If the result of GetRandomFloat(min, max) is below or equal to goal, returns true. Factors in luck stat from client.
bool RandChanceFloatEx(int client, float min, float max, float goal, float &result=0.0)
{
	float random;
	int rollTimes = 1 + GetPlayerLuckStat(client);
	int badRolls;
	bool success;
	
	if (rollTimes < 0)
	{
		// We are unlucky. Roll once. To succeed, we must roll as many successful rolls as we have bad rolls.
		badRolls = rollTimes * -1;
		rollTimes = 1;
	}
	
	for (int i = 1; i <= rollTimes; i++)
	{
		if ((random = GetRandomFloat(min, max)) <= goal)
		{
			if (badRolls <= 0) // If we have no bad rolls, we are successful.
			{
				success = true;
				break;
			}
			else // We have a bad roll. Decrement and try again for a bad result.
			{
				badRolls--;
				i = 0;
			}
		}
	}
	
	result = random;
	return success;
}

void ForceTeamWin(int team)
{
	int point;
	point = FindEntityByClassname(point, "team_control_point_master");
	if (!IsValidEntity2(point))
	{
		point = CreateEntityByName("team_control_point_master");
	}
	
	SetVariantInt(team);
	AcceptEntityInput(point, "SetWinner");
}

void GameOver()
{
	if (g_bGameWon)
		return;
	
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
	CreateTimer(11.0, Timer_GameOver, _, TIMER_FLAG_NO_MAPCHANGE);
	if (IsServerAutoRestartEnabled())
	{
		if (GetTimeSinceServerStart() >= g_cvTimeBeforeRestart.FloatValue)
		{
			g_bServerRestarting = true;
		}
	}
}

void GameVictory()
{
	if (g_bGameOver)
		return;

	g_bGameWon = true;
	PrintToServer("[RF2] Victory");
	if (IsServerAutoRestartEnabled())
	{
		if (GetTimeSinceServerStart() >= g_cvTimeBeforeRestart.FloatValue)
		{
			g_bServerRestarting = true;
		}
	}

	CreateTimer(30.0, Timer_GameOver, _, TIMER_FLAG_NO_MAPCHANGE);
}

void CreateSteelVictoryFlag()
{
	if (DoesSteelVictoryFlagExist())
		return;
	
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/rf2");
	CreateDirectory(path, 511);
	if (DirExists(path))
	{
		StrCat(path, sizeof(path), "/steel_win.rf2");
		File file = OpenFile(path, "a+");
		WriteFileLine(file, "");
		delete file;
	}
	else
	{
		LogError("[WARNING] Failed to create directory %s", path);
	}
}

void RemoveSteelVictoryFlag()
{
	if (!DoesSteelVictoryFlagExist())
		return;
	
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/rf2");
	StrCat(path, sizeof(path), "/steel_win.rf2");
	DeleteFile(path);
}

bool DoesSteelVictoryFlagExist()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/rf2");
	if (DirExists(path))
	{
		StrCat(path, sizeof(path), "/steel_win.rf2");
		return FileExists(path);
	}

	return false;
}

public void Timer_GameOver(Handle timer)
{
	if (g_bServerRestarting)
	{
		InsertServerCommand("quit");
		return;
	}
	
	if (g_iStagesCompleted == 0 && !IsInUnderworld())
	{
		InsertServerCommand("mp_waitingforplayers_restart 1; tf_bot_kick all");
		CreateTimer(1.2, Timer_ReloadPluginNoMapChange, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		ReloadPlugin(true);
	}
}

void ReloadPlugin(bool changeMap=true)
{	
	if (!g_bMapChanging)
	{
		ConVar tournament = FindConVar("mp_tournament");
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsSpecBot(i))
				continue;
				
			SetVariantString("");
			AcceptEntityInput(i, "SetCustomModel");
			
			if (IsPlayerAlive(i))
			{
				TF2_RemoveAllWeapons(i);
				TF2_RemoveAllWearables(i);
				SilentlyKillPlayer(i);
			}

			if (!IsFakeClient(i))
			{
				SendConVarValue(i, tournament, "0");
			}
		}
		
		StopMusicTrackAll();
		if (!changeMap && g_bWaitingForPlayers && GetTotalHumans() == 0)
		{
			InsertServerCommand("mp_waitingforplayers_restart 1");
		}
	}
	
	g_bPluginReloading = true;
	if (changeMap)
	{
		SetNextStage(1);
	}
	else
	{
		if (!g_bWaitingForPlayers && !g_bMapChanging)
		{
			InsertServerCommand("mp_restartgame_immediate 1");
		}
		
		char fileName[32];
		GetPluginFilename(INVALID_HANDLE, fileName, sizeof(fileName));
		ReplaceStringEx(fileName, sizeof(fileName), ".smx", "");
		InsertServerCommand("sm plugins load_unlock; sm plugins reload %s; sm_reload_translations", fileName);
	}
}

void ExtendWaitTime()
{
	ConVar waitTime = FindConVar("mp_waitingforplayers_time");
	float oldWaitTime = waitTime.FloatValue;
	waitTime.FloatValue = g_cvWaitExtendTime.FloatValue;
	InsertServerCommand("mp_waitingforplayers_restart 1");
	CreateTimer(1.2, Timer_ResetWaitTime, oldWaitTime, TIMER_FLAG_NO_MAPCHANGE);
}

bool IsMapRunning()
{
	return g_bMapRunning;
}

void UTIL_ScreenFade(int player, int color[4], float fadeTime, float fadeHold, int flags)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageOne("Fade", player, USERMSG_RELIABLE));
	if (bf)
	{
		bf.WriteShort(FixedUnsigned16(fadeTime, 1 << SCREENFADE_FRACBITS));
		bf.WriteShort(FixedUnsigned16(fadeHold, 1 << SCREENFADE_FRACBITS));
		bf.WriteShort(flags);
		bf.WriteByte(color[0]);
		bf.WriteByte(color[1]);
		bf.WriteByte(color[2]);
		bf.WriteByte(color[3]);
		EndMessage();
	}
}

const float MAX_SHAKE_AMPLITUDE = 16.0;
void UTIL_ScreenShake(const float center[3], float amplitude, float frequency, float duration, float radius, ShakeCommand_t eCommand, bool bAirShake)
{
	float localAmplitude;
	amplitude = fmin(amplitude, MAX_SHAKE_AMPLITUDE);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || (!bAirShake && (eCommand == SHAKE_START) && !(GetEntityFlags(i) & FL_ONGROUND)))
		{
			continue;
		}
		
		CBaseCombatCharacter cb = CBaseCombatCharacter(i);
		float playerCenter[3];
		cb.WorldSpaceCenter(playerCenter);

		localAmplitude = ComputeShakeAmplitude(center, playerCenter, amplitude, radius);
		// This happens if the player is outside the radius, in which case we should ignore all commands
		if (localAmplitude < 0)
		{
			continue;
		}

		TransmitShakeEvent(i, localAmplitude, frequency, duration, eCommand);
	}
}

int FixedUnsigned16(float value, int scale)
{
	int output;
	
	output = RoundToFloor(value * float(scale));
	if (output < 0)
	{
		output = 0;
	}
	if (output > 0xFFFF)
	{
		output = 0xFFFF;
	}
	
	return output;
}

float ComputeShakeAmplitude(const float center[3], const float shake[3], float amplitude, float radius)
{
	if (radius <= 0)
	{
		return amplitude;
	}
	
	float localAmplitude = -1.0;
	float delta[3];
	SubtractVectors(center, shake, delta);
	float distance = GetVectorLength(delta);
	
	if (distance <= radius)
	{
		// Make the amplitude fall off over distance
		float perc = 1.0 - (distance / radius);
		localAmplitude = amplitude * perc;
	}

	return localAmplitude;
}

void TransmitShakeEvent(int player, float localAmplitude, float frequency, float duration, ShakeCommand_t eCommand)
{
	if ((localAmplitude > 0.0 ) || (eCommand == SHAKE_STOP))
	{
		if (eCommand == SHAKE_STOP)
		{
			localAmplitude = 0.0;
		}
		
		BfWrite msg = UserMessageToBfWrite(StartMessageOne("Shake", player, USERMSG_RELIABLE));
		if (msg)
		{
			msg.WriteByte(view_as<int>(eCommand));
			msg.WriteFloat(localAmplitude);
			msg.WriteFloat(frequency);
			msg.WriteFloat(duration);
			EndMessage();
		}
	}
}

bool IsBossEventActive()
{
	return g_bRaidBossMode || g_bTankBossMode && !g_bGracePeriod || GetCurrentTeleporter().IsValid() && GetCurrentTeleporter().EventState == TELE_EVENT_ACTIVE;
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
			g_szHudDifficulty = "HAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHA";
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
		if (!IsClientInGame(i) || !IsFakeClient(i) || !IsPlayerAlive(i) || Enemy(i) == NULL_ENEMY)
			continue;
			
		skill = TFBot(i).GetSkillLevel();
		switch (newLevel)
		{
			case DIFFICULTY_SCRAP, DIFFICULTY_IRON:
			{
				Enemy enemy = Enemy(i);
				int oldSkill = enemy.BotSkill;
				
				if (skill != oldSkill)
					TFBot(i).SetSkillLevel(oldSkill);
			}
			
			case DIFFICULTY_STEEL:
			{
				if (skill < TFBotSkill_Hard && skill != TFBotSkill_Expert)
					TFBot(i).SetSkillLevel(TFBotSkill_Hard);
			}
			
			case DIFFICULTY_TITANIUM:
			{
				if (skill < TFBotSkill_Expert)
					TFBot(i).SetSkillLevel(TFBotSkill_Expert);
			}
		}
	}

	UpdateGameDescription();
}

int GetDifficultyName(int difficulty, char[] buffer, int size, bool colorTags=true, bool hints=false)
{
	int cells;
	if (hints)
	{
		switch (difficulty)
		{
			case DIFFICULTY_SCRAP: cells = strcopy(buffer, size, "{saddlebrown}Scrap (Easy){default}");
			case DIFFICULTY_IRON: cells = strcopy(buffer, size, "{gray}Iron (Normal){default}");
			case DIFFICULTY_STEEL: cells = strcopy(buffer, size, "{darkgray}Steel (Hard){default}");
			case DIFFICULTY_TITANIUM: cells = strcopy(buffer, size, "{whitesmoke}Titanium (Expert){default}");
			default:  cells = strcopy(buffer, size, "unknown");
		}
	}
	else
	{
		switch (difficulty)
		{
			case DIFFICULTY_SCRAP: cells = strcopy(buffer, size, "{saddlebrown}Scrap{default}");
			case DIFFICULTY_IRON: cells = strcopy(buffer, size, "{gray}Iron{default}");
			case DIFFICULTY_STEEL: cells = strcopy(buffer, size, "{darkgray}Steel{default}");
			case DIFFICULTY_TITANIUM: cells = strcopy(buffer, size, "{whitesmoke}Titanium{default}");
			default:  cells = strcopy(buffer, size, "unknown");
		}
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

void UpdateGameDescription()
{
	#if defined _SteamWorks_Included
	if (GetExtensionFileStatus("SteamWorks.ext") == 1)
	{
		char desc[256], difficultyName[32];
		GetDifficultyName(RF2_GetDifficulty(), difficultyName, sizeof(difficultyName), false);
		FormatEx(desc, sizeof(desc), "Risk Fortress 2 (Stage %d - %s)", g_iStagesCompleted+1, difficultyName);
		SteamWorks_SetGameDescription(desc);
	}
	#endif
}

// It does not matter if the .mdl extension is included in the path or not.
void AddModelToDownloadsTable(const char[] file, bool precache=true)
{
	char buffer[PLATFORM_MAX_PATH], extension[16];
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
		if (FileExists(buffer, true))
		{
			if (FileExists(buffer)) // Non VPK file
				AddFileToDownloadsTable(buffer);
			
			if (precache && i == 1)
			{
				PrecacheModel2(buffer);
			}
		}
		else if (i == 1) // we only care about reporting if the .mdl file missing
		{
			LogError("File \"%s\" is missing from the server files. It will not be added to the downloads table.", buffer);
		}
		
		ReplaceStringEx(buffer, sizeof(buffer), extension, "");
	}
}

// This will ensure that sound/ is at the beginning of the file path if it isn't.
void AddSoundToDownloadsTable(const char[] file, bool precache=true)
{
	char buffer[PLATFORM_MAX_PATH];
	strcopy(buffer, sizeof(buffer), file);
	if (StrContains(buffer, "sound/") != 0)
	{
		FormatEx(buffer, sizeof(buffer), "sound/%s", file);
	}
	
	if (FileExists(buffer, true))
	{
		if (FileExists(buffer)) // Non VPK file
			AddFileToDownloadsTable(buffer);
			
		if (precache)
		{
			// I don't know if sound/ should be omitted here but I'm doing it just in case
			ReplaceStringEx(buffer, sizeof(buffer), "sound/", "");
			PrecacheSound2(buffer);
		}
	}
	else
	{
		LogError("File \"%s\" is missing from the server files. It will not be added to the downloads table.", buffer);
	}
}

// This will remove the extension and attempt to download both the .vmt and .vtf files with the file path given. 
// If neither exist, an error is logged. 
// materials/ MUST be included in the file path!
stock void AddMaterialToDownloadsTable(const char[] file, bool precache=false)
{	
	bool exists;
	char buffer[PLATFORM_MAX_PATH];
	strcopy(buffer, sizeof(buffer), file);
	ReplaceStringEx(buffer, sizeof(buffer), ".vmt", "");
	ReplaceStringEx(buffer, sizeof(buffer), ".vtf", "");
	StrCat(buffer, sizeof(buffer), ".vmt");
	if (FileExists(buffer, true))
	{
		exists = true;
		if (FileExists(buffer)) // Non VPK file
			AddFileToDownloadsTable(buffer);
		
		if (precache)
		{
			PrecacheModel2(buffer, true);
		}
	}
	
	ReplaceStringEx(buffer, sizeof(buffer), ".vmt", ".vtf");
	if (FileExists(buffer, true))
	{
		exists = true;
		if (FileExists(buffer)) // Non VPK file
			AddFileToDownloadsTable(buffer);
	}
	
	if (!exists)
	{
		ReplaceStringEx(buffer, sizeof(buffer), ".vtf", "");
		LogError("Neither a .vmt or .vtf file exists for the file: \"%s\". It will not be added to the downloads table.", buffer);
	}
}

void PrecacheSoundArray(const char[][] soundArray, int size, bool download=true)
{
	for (int i = 0; i < size; i++)
	{
		PrecacheSound2(soundArray[i], true);
		if (download)
		{
			AddSoundToDownloadsTable(soundArray[i], false);
		}
	}
}

void PrecacheModelArray(const char[][] modelArray, int size, bool download=true)
{
	for (int i = 0; i < size; i++)
	{
		PrecacheModel2(modelArray[i], true);
		if (download)
		{
			AddModelToDownloadsTable(modelArray[i], false);
		}
	}
}

int GetPluginModifiedTime()
{
	static char path[PLATFORM_MAX_PATH];
	if (!path[0])
	{
		static char fileName[32];
		if (!fileName[0])
			GetPluginFilename(INVALID_HANDLE, fileName, sizeof(fileName));
			
		BuildPath(Path_SM, path, sizeof(path), "plugins/%s", fileName);
	}
	
	return GetFileTime(path, FileTime_LastChange);
}

static bool g_bPreventServerExit;
public MRESReturn Detour_GCPreClientUpdate(Address gc)
{
	// Wait until we have a CVEngineServer pointer, or else the server will close if maxplayers <32
	if (!RF2_IsEnabled() || !g_aEngineServer)
		return MRES_Ignored;
	
	// Hijack MvM's method of reporting max player count
	g_bPreventServerExit = true;
	GameRules_SetProp("m_bPlayingMannVsMachine", true);
	return MRES_Ignored;
}

public MRESReturn Detour_GCPreClientUpdatePost(Address gc)
{
	if (!RF2_IsEnabled() || !g_aEngineServer)
		return MRES_Ignored;
	
	g_bPreventServerExit = false;
	GameRules_SetProp("m_bPlayingMannVsMachine", false);
	return MRES_Ignored;
}

public MRESReturn Detour_FindMap(Address thisPtr, DHookReturn returnVal, DHookParam params)
{
	// This will be called on plugin start, just so we can get the CVEngineServer address (this is a native SM function)
	g_aEngineServer = thisPtr;
	if (!RF2_IsEnabled())
		return MRES_Ignored;
	
	static bool hook;
	if (!hook)
	{
		// We have the CVEngineServer address, now for our dynamic hook
		if (g_hHookCreateFakeClientEx)
		{
			g_hHookCreateFakeClientEx.HookRaw(Hook_Pre, thisPtr, DHook_CreateFakeClientEx);
		}
		
		if (g_hHookDedicatedServer)
		{
			g_hHookDedicatedServer.HookRaw(Hook_Pre, thisPtr, DHook_IsDedicatedServer);
		}

		hook = true;
	}
	
	return MRES_Ignored;
}

public MRESReturn DHook_CreateFakeClientEx(Address thisPtr, DHookReturn returnVal, DHookParam params)
{
	if (!RF2_IsEnabled())
		return MRES_Ignored;
	
	// Don't show bots in the server browser
	params.Set(2, false);
	return MRES_ChangedHandled;
}

public MRESReturn DHook_IsDedicatedServer(Address thisPtr, DHookReturn returnVal)
{
	if (!g_bPreventServerExit)
		return MRES_Ignored;
	
	// Return false to prevent the server from exiting if maxplayers <32
	// This happens because the GC thinks that we're an MvM server
	returnVal.Value = false;
	return MRES_Supercede;
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


float AngleNormalize(float angle)
{
	while (angle > 180.0)
	{
		angle -= 360.0;
	}
	while (angle < -180.0)
	{
		angle += 360.0;
	}
	return angle;
}

stock void PrintVector(const float vec[3])
{
	PrintToServer("%.2f, %.2f, %.2f", vec[0], vec[1], vec[2]);
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

// Checks if the goomba plugin is loaded, do not call until after OnAllPluginsLoaded()
bool IsGoombaAvailable()
{
	return g_bGoombaAvailable;
}

/*
// Returns number of strings found and removed from the list
int ClearStringFromArrayList(ArrayList list, const char[] string)
{
	char[] str = new char[list.BlockSize];
	int count;
	for (int i = 0; i < list.Length; i++)
	{
		list.GetString(i, str, list.BlockSize);
		if (strcmp2(str, string))
		{
			list.Erase(i);
			i--;
			count++;
		}
	}
	
	return count;
}
*/

bool IsServerAutoRestartEnabled()
{
	return g_cvTimeBeforeRestart.FloatValue > 0.0;
}

float GetTimeSinceServerStart()
{
	return GetEngineTime() - g_cvHiddenServerStartTime.FloatValue;
}

stock void DebugMsgNoSpam(const char[] message, any ...)
{
	#if defined DEVONLY
	char buffer[512];
	static char lastMessage[512];
	VFormat(buffer, sizeof(buffer), message, 2);
	static float lastTime;
	float time = GetTickedTime();
	bool newMsg = strlen(lastMessage) != strlen(buffer);
	if (lastTime+0.8 <= time || newMsg)
	{
		PrintToChatAll("[DEBUG] %s", buffer);
		PrintToServer("[DEBUG] %s", buffer);
		strcopy(lastMessage, sizeof(lastMessage), buffer);
		lastTime = time;
	}
	#endif
}

stock void DebugMsg(const char[] message, any ...)
{
	#if defined DEVONLY
	char buffer[512];
	VFormat(buffer, sizeof(buffer), message, 2);
	PrintToChatAll("[DEBUG] %s", buffer);
	PrintToServer("[DEBUG] %s", buffer);
	#endif
}
