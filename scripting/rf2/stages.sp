#pragma semicolon 1
#pragma newdecls required

#define MAX_STAGE_MAPS 16
#define MAX_STAGES 32

int g_iMaxStages;

char g_szEnemyPackName[64];
char g_szBossPackName[64];
char g_szClientBGM[MAXTF2PLAYERS][PLATFORM_MAX_PATH];
char g_szStageBGM[PLATFORM_MAX_PATH];
char g_szBossBGM[PLATFORM_MAX_PATH];
char g_szUnderworldMap[PLATFORM_MAX_PATH];
char g_szFinalMap[PLATFORM_MAX_PATH];

float g_flGracePeriodTime = 30.0;
//float g_flMinSpawnDistOverride = -1.0;
//float g_flMaxSpawnDistOverride = -1.0;
float g_flBossSpawnChanceBonus;
float g_flLoopMusicAt[MAXTF2PLAYERS] = {-1.0, ...};
float g_flStageBGMDuration;
float g_flBossBGMDuration;

void LoadMapSettings(const char[] mapName)
{
	KeyValues mapKey = CreateKeyValues("stages");
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, MapConfig);
	if (!mapKey.ImportFromFile(config))
	{
		delete mapKey;
		ThrowError("File %s does not exist", config);
	}
	
	bool found;
	static int stageKv = 1;
	if (g_szUnderworldMap[0] && StrContains(g_szUnderworldMap, mapName, false) == 0)
	{
		if (mapKey.JumpToKey("special") && mapKey.JumpToKey("underworld"))
		{
			ReadMapKeys(mapKey);
			found = true;
		}
		else
		{
			LogError("Tried to load settings for underworld map (%s) but somehow, the section doesn't exist. Not good!", mapName);
		}
	}
	else if (g_szFinalMap[0] && StrContains(g_szFinalMap, mapName, false) == 0)
	{
		if (mapKey.JumpToKey("special") && mapKey.JumpToKey("final"))
		{
			ReadMapKeys(mapKey);
			found = true;
		}
		else
		{
			LogError("Tried to load settings for final map (%s) but somehow, the section doesn't exist. Not good!", mapName);
		}
	}
	else
	{
		char mapString[PLATFORM_MAX_PATH], section[16], mapId[8];
		FormatEx(section, sizeof(section), "stage%i", stageKv);
		mapKey.JumpToKey(section);
		for (int map = 1; map <= MAX_STAGE_MAPS; map++)
		{
			FormatEx(mapId, sizeof(mapId), "map%i", map);
			if (mapKey.JumpToKey(mapId))
			{
				mapKey.GetString("name", mapString, sizeof(mapString));
				if (StrContains(mapName, mapString) == 0)
				{
					found = true;
					ReadMapKeys(mapKey);
					stageKv = 1;
					break;
				}
			}
			
			mapKey.GoBack();
		}
	}
	
	delete mapKey;
	if (!found)
	{
		if (stageKv >= RF2_GetMaxStages())
		{
			LogError("Could not locate map settings for map %s, using defaults!", mapName);
			g_szStageBGM = NULL;
			g_szBossBGM = NULL;
			g_flStageBGMDuration = 0.0;
			g_flBossBGMDuration = 0.0;
			g_szEnemyPackName = "";
			g_szBossPackName = "";
			g_flGracePeriodTime = 30.0;
			stageKv = 1;
		}
		else
		{
			stageKv++;
			LoadMapSettings(mapName);
		}
	}
}

void ReadMapKeys(KeyValues mapKey)
{
	mapKey.GetString("theme", g_szStageBGM, sizeof(g_szStageBGM), NULL);
	g_flStageBGMDuration = mapKey.GetFloat("theme_duration", 0.0);
	mapKey.GetString("boss_theme", g_szBossBGM, sizeof(g_szBossBGM), NULL);
	g_flBossBGMDuration = mapKey.GetFloat("boss_theme_duration", 0.0);
	if (g_iLoopCount > 0 || g_cvDebugUseAltMapSettings.BoolValue)
	{
		char stageTheme[PLATFORM_MAX_PATH], bossTheme[PLATFORM_MAX_PATH];
		float stageThemeTime, bossThemeTime;
		mapKey.GetString("theme_alt", stageTheme, sizeof(stageTheme), g_szStageBGM);
		mapKey.GetString("boss_theme_alt", bossTheme, sizeof(bossTheme), g_szBossBGM);
		strcopy(g_szStageBGM, sizeof(g_szStageBGM), stageTheme);
		strcopy(g_szBossBGM, sizeof(g_szBossBGM), bossTheme);
		stageThemeTime = g_flStageBGMDuration;
		bossThemeTime = g_flBossBGMDuration;
		g_flStageBGMDuration = mapKey.GetFloat("theme_alt_duration", stageThemeTime);
		g_flBossBGMDuration = mapKey.GetFloat("boss_theme_alt_duration", bossThemeTime);
	}
	
	if (g_szStageBGM[0])
	{
		AddSoundToDownloadsTable(g_szStageBGM);
	}
	
	if (g_szBossBGM[0])
	{
		AddSoundToDownloadsTable(g_szBossBGM);
	}
	
	mapKey.GetString("enemy_pack", g_szEnemyPackName, sizeof(g_szEnemyPackName), "");
	mapKey.GetString("boss_pack", g_szBossPackName, sizeof(g_szBossPackName), "");
	if (g_iLoopCount > 0 || g_cvDebugUseAltMapSettings.BoolValue)
	{
		char enemyPack[64], bossPack[64];
		mapKey.GetString("enemy_pack_loop", enemyPack, sizeof(enemyPack), g_szEnemyPackName);
		mapKey.GetString("boss_pack_loop", bossPack, sizeof(bossPack), g_szBossPackName);
		strcopy(g_szEnemyPackName, sizeof(g_szEnemyPackName), enemyPack);
		strcopy(g_szBossPackName, sizeof(g_szBossPackName), bossPack);
	}
	
	if (g_szEnemyPackName[0])
	{
		LoadEnemiesFromPack(g_szEnemyPackName);
	}
	
	if (g_szBossPackName[0])
	{
		LoadEnemiesFromPack(g_szBossPackName, true);
	}
	
	PrintToServer("[RF2] Enemies/bosses loaded: %i", g_iEnemyCount);
	g_flGracePeriodTime = mapKey.GetFloat("grace_period_time", 30.0);
	g_flBossSpawnChanceBonus = mapKey.GetFloat("boss_spawn_chance_bonus", 0.0);
	g_bTankBossMode = asBool(mapKey.GetNum("tank_destruction", false));
}

int FindMaxStages()
{
	KeyValues mapKey = CreateKeyValues("stages");
	char config[PLATFORM_MAX_PATH], stage[16];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, MapConfig);
	if (!mapKey.ImportFromFile(config))
	{
		delete mapKey;
		ThrowError("File %s does not exist", config);
	}
	
	int stageCount = 0;
	for (int i = 1; i <= MAX_STAGES; i++)
	{
		mapKey.Rewind();
		FormatEx(stage, sizeof(stage), "stage%i", i);
		
		if (mapKey.JumpToKey(stage))
		{
			stageCount++;
		}
		else
		{
			break;
		}
	}
	
	mapKey.Rewind();
	mapKey.JumpToKey("special");
	if (mapKey.JumpToKey("underworld"))
	{
		mapKey.GetString("name", g_szUnderworldMap, sizeof(g_szUnderworldMap));
		mapKey.GoBack();
	}

	if (mapKey.JumpToKey("final"))
	{
		mapKey.GetString("name", g_szFinalMap, sizeof(g_szFinalMap));
		mapKey.GoBack();
	}
	
	delete mapKey;
	return stageCount;
}

void SetNextStage(int stage)
{
	g_iCurrentStage = stage;
	ArrayList mapList = GetMapsForStage(stage);
	if (mapList.Length <= 0)
	{
		ThrowError("No maps defined for stage %i!", stage);
	}
	
	char mapName[128];
	mapList.GetString(GetRandomInt(0, mapList.Length-1), mapName, sizeof(mapName));
	g_bMapChanging = true;
	ForceChangeLevel(mapName, "RF2 automatic map change");
}

ArrayList GetMapsForStage(int stage)
{
	KeyValues mapKey = CreateKeyValues("stages");
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, MapConfig);
	if (!mapKey.ImportFromFile(config))
	{
		delete mapKey;
		ThrowError("File %s does not exist", config);
	}
	
	ArrayList mapList = new ArrayList(128);
	char section[16], mapId[8], mapName[PLATFORM_MAX_PATH];
	FormatEx(section, sizeof(section), "stage%i", stage);
	mapKey.JumpToKey(section);
	for (int map = 0; map <= MAX_STAGE_MAPS; map++)
	{
		FormatEx(mapId, sizeof(mapId), "map%i", map+1);
		if (mapKey.JumpToKey(mapId))
		{
			mapKey.GetString("name", mapName, sizeof(mapName));
			if (!mapName[0])
			{
				LogError("[GetMapsForStage] %s for stage %i (%s) is invalid!", mapId, stage, mapName);
				continue;
			}
			
			mapList.PushString(mapName);
			mapKey.GoBack();
		}
		else
		{
			break;
		}
	}
	
	return mapList;
}

bool RF2_IsMapValid(char[] mapName)
{
	if (!IsMapValid(mapName))
		return false;
	
	// If it's the underworld map or the final map, we don't have to do anything here
	if (g_szUnderworldMap[0] && StrContains(g_szUnderworldMap, mapName, false) == 0 || g_szFinalMap[0] && StrContains(g_szFinalMap, mapName, false) == 0)
	{
		return true;
	}
	
	KeyValues mapKey = CreateKeyValues("stages");
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, MapConfig);
	if (!mapKey.ImportFromFile(config))
	{
		delete mapKey;
		ThrowError("File %s does not exist", config);
	}
	
	char section[16], mapKvName[256], mapId[8];
	for (int i = 0; i <= RF2_GetMaxStages(); i++)
	{
		FormatEx(section, sizeof(section), "stage%i", i+1);
		mapKey.JumpToKey(section);
		for (int map = 0; map <= MAX_STAGE_MAPS; map++)
		{
			FormatEx(mapId, sizeof(mapId), "map%i", map+1);
			if (map > 0)
				mapKey.GoBack();
			
			if (mapKey.JumpToKey(mapId))
			{
				mapKey.GetString("name", mapKvName, sizeof(mapKvName), "map_unknown");
				if (StrContains(mapName, mapKvName) != -1)
				{
					delete mapKey;
					return true;
				}
			}
			else
			{
				break;
			}
		}
		
		mapKey.Rewind();
	}
	
	delete mapKey;
	return false;
}

bool IsInUnderworld()
{
	return g_bInUnderworld;
}

bool DoesUnderworldExist()
{
	return g_szUnderworldMap[0] && RF2_IsMapValid(g_szUnderworldMap);
}

public Action Timer_PlayMusicDelay(Handle timer)
{
	PlayMusicTrackAll();
	return Plugin_Continue;
}

void PlayMusicTrack(int client)
{
	if (IsFakeClient(client) || !GetCookieBool(client, g_coMusicEnabled))
		return;
	
	StopMusicTrack(client);
	GetCurrentMusicTrack(g_szClientBGM[client], sizeof(g_szClientBGM[]));
	
	if ((!IsBossEventActive() || !g_szBossBGM[0]) && g_flStageBGMDuration > 0.0)
	{
		g_flLoopMusicAt[client] = GetEngineTime() + g_flStageBGMDuration+0.1;
	}
	else if (g_flBossBGMDuration > 0.0)
	{
		g_flLoopMusicAt[client] = GetEngineTime() + g_flBossBGMDuration+0.1;
	}
	
	// delay because stopping the sound in the same frame or client lagging can sometimes end up with it not playing
	CreateTimer(0.1, Timer_PlayMusicDelaySingle, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_PlayMusicDelaySingle(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return Plugin_Continue;
	
	EmitSoundToClient(client, g_szClientBGM[client]);
	return Plugin_Continue;
}

void StopMusicTrack(int client)
{
	g_flLoopMusicAt[client] = -1.0;
	
	if (!g_bMapChanging && IsClientInGame(client) && !IsFakeClient(client))
	{
		StopSound(client, SNDCHAN_AUTO, g_szClientBGM[client]);
	}
}

void PlayMusicTrackAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
			
		PlayMusicTrack(i);
	}
}

void StopMusicTrackAll()
{
	for (int i = 1; i <= MAXTF2PLAYERS; i++)
	{
		if (i > MaxClients)
			continue;
			
		StopMusicTrack(i);
	}
}

void GetCurrentMusicTrack(char[] buffer, int size)
{
	if (IsBossEventActive() && g_szBossBGM[0])
	{
		strcopy(buffer, size, g_szBossBGM);
	}
	else
	{
		strcopy(buffer, size, g_szStageBGM);
	}
}

bool IsStageCleared()
{
	RF2_Object_Teleporter teleporter = GetCurrentTeleporter();
	if (teleporter.IsValid())
	{
		return teleporter.EventState == TELE_EVENT_COMPLETE;
	}
	
	if (g_bTankBossMode)
	{
		return g_iTanksKilledObjective >= g_iTankKillRequirement;
	}
	
	return GameRules_GetRoundState() == RoundState_TeamWin && GameRules_GetProp("m_iWinningTeam") == TEAM_SURVIVOR;
}

stock bool IsAboutToLoop()
{
	return g_iCurrentStage >= g_iMaxStages && g_iCurrentStage % g_iMaxStages == 0;
}

int DetermineNextStage()
{
	int nextStage = IsInUnderworld() ? g_iCurrentStage : g_iCurrentStage+1;
	if (nextStage > RF2_GetMaxStages())
	{
		nextStage = 1;
	}
	
	return nextStage;
}