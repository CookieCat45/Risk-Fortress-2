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
int g_iCurrentCustomTrack = -1;
ArrayList g_hCustomTracks;
ArrayList g_hCustomTracksDuration;

void LoadMapSettings(const char[] mapName)
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "%s/maps", ConfigPath);
	KeyValues mapKey = new KeyValues("map");

	// Check for special maps first
	char underworld[PLATFORM_MAX_PATH], final[PLATFORM_MAX_PATH];
	FormatEx(underworld, sizeof(underworld), "%s/underworld/%s.cfg", path, mapName);
	FormatEx(final, sizeof(final), "%s/final/%s.cfg", path, mapName);
	bool isUnderworld = mapKey.ImportFromFile(underworld);
	bool isFinal = mapKey.ImportFromFile(final);
	if (isUnderworld || isFinal)
	{
		if (isUnderworld)
		{
			strcopy(g_szUnderworldMap, sizeof(g_szUnderworldMap), mapName);
		}
		else if (isFinal)
		{
			strcopy(g_szFinalMap, sizeof(g_szFinalMap), mapName);
		}

		PrintToServer("[RF2] Loading settings for SPECIAL map: %s", mapName);
		ReadMapKeys(mapKey);
		delete mapKey;
		return;
	}

	char dir[PLATFORM_MAX_PATH];
	bool found;
	for (int i = 1; i <= g_iMaxStages; i++)
	{
		FormatEx(dir, sizeof(dir), "%s/stage%i/%s.cfg", path, i, mapName);
		if (mapKey.ImportFromFile(dir))
		{
			found = true;
			break;
		}
	}

	if (found)
	{
		PrintToServer("[RF2] Loading settings for map: %s", mapName);
		ReadMapKeys(mapKey);
	}
	else
	{
		LogError("Could not locate settings for map %s, using defaults!", mapName);
		g_szStageBGM = NULL;
		g_szBossBGM = NULL;
		g_flStageBGMDuration = 0.0;
		g_flBossBGMDuration = 0.0;
		g_szEnemyPackName = "";
		g_szBossPackName = "";
		g_flGracePeriodTime = 30.0;
		g_flStartMoneyMultiplier = 1.0;
		g_bDisableEurekaTeleport = false;
		g_bDisableItemDropping = false;
	}

	delete mapKey;
}

void ReadMapKeys(KeyValues mapKey)
{
	mapKey.GetString("theme", g_szStageBGM, sizeof(g_szStageBGM), NULL);
	g_flStageBGMDuration = mapKey.GetFloat("theme_duration", 0.0);
	mapKey.GetString("boss_theme", g_szBossBGM, sizeof(g_szBossBGM), NULL);
	g_flBossBGMDuration = mapKey.GetFloat("boss_theme_duration", 0.0);
	bool useAlt = (g_iLoopCount > 0 || g_cvDebugUseAltMapSettings.BoolValue);
	if (useAlt)
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
	
	int i = 1;
	char customTrackKey[32], customTrack[PLATFORM_MAX_PATH];
	g_hCustomTracks.Clear();
	g_hCustomTracksDuration.Clear();
	for ( ;; )
	{
		float time;
		FormatEx(customTrackKey, sizeof(customTrackKey), "custom_track_%d", i);

		if (useAlt)
		{
			StrCat(customTrackKey, sizeof(customTrackKey), "_alt");
			mapKey.GetString(customTrackKey, customTrack, sizeof(customTrack));
			if (!customTrack[0])
			{
				// alt wasn't found, fall back to normal
				ReplaceStringEx(customTrackKey, sizeof(customTrackKey), "_alt", "");
				mapKey.GetString(customTrackKey, customTrack, sizeof(customTrack));
				if (!customTrack[0])
					break;
			}

			StrCat(customTrackKey, sizeof(customTrackKey), "_duration");
			time = mapKey.GetFloat(customTrackKey);
		}
		else
		{
			mapKey.GetString(customTrackKey, customTrack, sizeof(customTrack));
			if (!customTrack[0])
				break;

			StrCat(customTrackKey, sizeof(customTrackKey), "_duration");
			time = mapKey.GetFloat(customTrackKey);
		}
		
		g_hCustomTracks.Resize(i+1);
		g_hCustomTracks.SetString(i, customTrack);
		g_hCustomTracksDuration.Resize(i+1);
		g_hCustomTracksDuration.Set(i, time);
		AddSoundToDownloadsTable(customTrack);
		PrintToServer("[RF2] Loaded custom music track %d: %s", i, customTrack);
		i++;
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
	g_flStartMoneyMultiplier = mapKey.GetFloat("start_money_multiplier", 1.0);
	g_flBossSpawnChanceBonus = mapKey.GetFloat("boss_spawn_chance_bonus", 0.0);
	g_flMaxSpawnWaveTime = mapKey.GetFloat("max_spawn_wave_time", 0.0);
	g_bTankBossMode = asBool(mapKey.GetNum("tank_destruction", false));
	g_bDisableEurekaTeleport = asBool(mapKey.GetNum("disable_eureka_teleport", false));
	g_bDisableItemDropping = asBool(mapKey.GetNum("disable_item_dropping", false));
}

int FindMaxStages()
{
	int stageCount;
	char path[PLATFORM_MAX_PATH], dir[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "%s/maps", ConfigPath);
	for ( ;; )
	{
		FormatEx(dir, sizeof(dir), "%s/stage%i", path, stageCount+1);
		if (DirExists(dir))
		{
			stageCount++;
		}
		else
		{
			break;
		}
	}

	return stageCount;
}

ArrayList GetMapsForStage(int stage)
{
	ArrayList mapList = new ArrayList(128);
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "%s/maps/stage%i", ConfigPath, stage);
	DirectoryListing directory = OpenDirectory(path);
	if (!directory)
		return mapList;

	char map[128];
	FileType type;
	while (directory.GetNext(map, sizeof(map), type))
	{
		if (type != FileType_File)
			continue;

		ReplaceString(map, sizeof(map), ".cfg", "", false);
		if (RF2_IsMapValid(map))
		{
			mapList.PushString(map);
		}
	}

	delete directory;
	return mapList;
}

bool RF2_IsMapValid(char[] mapName)
{
	if (!IsMapValid(mapName))
		return false;
	
	// If it's the underworld map or the final map, we don't have to do anything here
	if (g_szUnderworldMap[0] && StrContains(g_szUnderworldMap, mapName, false) == 0 
		|| g_szFinalMap[0] && StrContains(g_szFinalMap, mapName, false) == 0)
	{
		return true;
	}
	
	FileType type;
	char path[PLATFORM_MAX_PATH], dir[PLATFORM_MAX_PATH], map[128];
	BuildPath(Path_SM, path, sizeof(path), "%s/maps", ConfigPath);
	for (int i = 1; i <= g_iMaxStages; i++)
	{
		FormatEx(dir, sizeof(dir), "%s/stage%i", path, i);
		DirectoryListing directory = OpenDirectory(dir);
		if (!directory)
			continue;

		while (directory.GetNext(map, sizeof(map), type))
		{
			if (type != FileType_File)
				continue;

			ReplaceString(map, sizeof(map), ".cfg", "", false);
			if (StrContains(map, mapName) == 0)
			{
				delete directory;
				return true;
			}
		}

		delete directory;
	}

	return false;
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

bool IsInUnderworld()
{
	return g_bInUnderworld;
}

bool IsInFinalMap()
{
	return g_bInFinalMap;
}

bool DoesUnderworldExist()
{
	return g_szUnderworldMap[0] && RF2_IsMapValid(g_szUnderworldMap);
}

bool DoesFinalMapExist()
{
	return g_szFinalMap[0] && RF2_IsMapValid(g_szFinalMap);
}

public void Timer_PlayMusicDelay(Handle timer)
{
	PlayMusicTrackAll();
}

void PlayMusicTrack(int client)
{
	if (!IsMusicEnabled(client))
		return;
	
	StopMusicTrack(client);
	if (IsCustomTrackPlaying())
	{
		PlayCustomMusicTrack(client, g_iCurrentCustomTrack);
		return;
	}

	bool bossEvent = IsBossEventActive();
	if (bossEvent && g_szBossBGM[0])
	{
		strcopy(g_szClientBGM[client], sizeof(g_szClientBGM[]), g_szBossBGM);
	}
	else
	{
		strcopy(g_szClientBGM[client], sizeof(g_szClientBGM[]), g_szStageBGM);
	}
	
	if ((!bossEvent || !g_szBossBGM[0]) && g_flStageBGMDuration > 0.0)
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

void PlayCustomMusicTrack(int client, int trackIndex)
{
	if (!IsMusicEnabled(client))
		return;

	StopMusicTrack(client);
	char music[PLATFORM_MAX_PATH];
	g_hCustomTracks.GetString(trackIndex, music, sizeof(music));
	float time = g_hCustomTracksDuration.Get(trackIndex);
	g_flLoopMusicAt[client] = GetEngineTime() + time+0.1;
	strcopy(g_szClientBGM[client], sizeof(g_szClientBGM[]), music);
	
	#if defined DEVONLY
	CPrintToChatAll("Playing custom music track %d: {yellow}%s {default}for {green}%.0f{default} seconds", trackIndex, music, time);
	#endif
	// delay because stopping the sound in the same frame or client lagging can sometimes end up with it not playing
	CreateTimer(0.1, Timer_PlayMusicDelaySingle, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

bool IsCustomTrackPlaying()
{
	return g_iCurrentCustomTrack >= 0;
}

bool IsMusicPaused()
{
	if (IsStageCleared())
		return true;

	RF2_GameRules gamerules = GetRF2GameRules();
	if (gamerules.IsValid())
	{
		return gamerules.MusicPaused;
	}

	return false;
}

public void Timer_PlayMusicDelaySingle(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return;
	
	EmitSoundToClient(client, g_szClientBGM[client]);
}

void StopMusicTrack(int client)
{
	g_flLoopMusicAt[client] = -1.0;
	if (!g_bMapChanging && IsClientInGame(client) && (!IsFakeClient(client) || IsClientSourceTV(client)))
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

bool IsMusicEnabled(int client)
{
	// Play music for SourceTV bot
	if (IsClientSourceTV(client))
		return true;

	if (IsFakeClient(client))
		return false;

	return GetCookieBool(client, g_coMusicEnabled);
}

void PlayCustomMusicTrackAll(int trackIndex)
{
	// this will usually be called from map logic, so warn that the track doesn't exist instead of getting an array index error
	if (trackIndex >= g_hCustomTracks.Length)
	{
		char map[PLATFORM_MAX_PATH];
		GetCurrentMap(map, sizeof(map));
		LogError("[PlayCustomMusicTrack] Track %d doesn't exist. Map: %s", trackIndex, map);
		return;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
			
		PlayCustomMusicTrack(i, trackIndex);
	}

	g_iCurrentCustomTrack = trackIndex;
}

void StopMusicTrackAll()
{
	for (int i = 1; i <= MAXTF2PLAYERS; i++)
	{
		if (i > MaxClients)
			continue;

		StopMusicTrack(i);
	}

	g_iCurrentCustomTrack = -1;
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
	
	return false;
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