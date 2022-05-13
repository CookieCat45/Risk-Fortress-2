#if defined _RF2_maps_included
 #endinput
#endif
#define _RF2_maps_included

#define DEFAULT_PACK "default"
#define DEFAULT_BOSS_PACK "default_boss"

int g_iCurrentStage = 0;
int g_iMaxStages = 0;

char g_szClientBGM[MAXTF2PLAYERS][PLATFORM_MAX_PATH];
char g_szStageBGM[PLATFORM_MAX_PATH];
char g_szBossBGM[PLATFORM_MAX_PATH];

char g_szRobotPacks[512];
char g_szBossPacks[512];

float g_flBGMDuration[MAXTF2PLAYERS];
float g_flStageBGMDuration;
float g_flBossBGMDuration;

float g_flGracePeriodTime = 15.0;

Handle g_hMusicLoopTimer[MAXTF2PLAYERS];

void LoadMapSettings(const char[] mapName)
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, MapConfig);
	if (!FileExists(config))
	{
		RF2_PrintToChatAll("Config file %s does not exist, please correct this", config);
		ThrowError("File %s does not exist", config);
	}
	
	char mapString[PLATFORM_MAX_PATH];
	char section[16];
	char mapId[8];
	bool found = false;
	
	Handle mapKey = CreateKeyValues("stages");
	FileToKeyValues(mapKey, config);
	
	static int stageKv = 1;
	FormatEx(section, sizeof(section), "stage%i", stageKv);
	KvJumpToKey(mapKey, section);
	
	for (int map = 0; map <= MAX_STAGE_MAPS; map++)
	{
		FormatEx(mapId, sizeof(mapId), "map%i", map+1);
		if (KvJumpToKey(mapKey, mapId))
		{
			KvGetString(mapKey, "name", mapString, sizeof(mapString));
			if (StrContains(mapName, mapString) != -1)
			{
				found = true;
				stageKv = 1;
				
				KvGetString(mapKey, "theme", g_szStageBGM, sizeof(g_szStageBGM), "vo/null.wav");
				g_flStageBGMDuration = KvGetFloat(mapKey, "theme_duration");
				
				KvGetString(mapKey, "boss_theme", g_szBossBGM, sizeof(g_szBossBGM), "vo/null.wav");
				g_flBossBGMDuration = KvGetFloat(mapKey, "boss_theme_duration");
				
				PrecacheSound(g_szStageBGM);
				PrecacheSound(g_szBossBGM);
				
				KvGetString(mapKey, "robot_packs", g_szRobotPacks, sizeof(g_szRobotPacks), DEFAULT_PACK);
				LoadPacks(g_szRobotPacks);
				
				KvGetString(mapKey, "boss_packs", g_szBossPacks, sizeof(g_szBossPacks), DEFAULT_BOSS_PACK);
				LoadPacks(g_szBossPacks, true);
				
				g_flGracePeriodTime = KvGetFloat(mapKey, "grace_period_time", 15.0);
				
				break;
			}
		}
		KvGoBack(mapKey);
	}
	delete mapKey;
	
	if (!found)
	{
		if (stageKv > MAX_STAGES)
		{
			stageKv = 1;
			LogError("Could not locate map settings for map %s, using defaults!", mapName);
		
			g_szStageBGM = "vo/null.wav";
			g_szBossBGM = "vo/null.wav";
			
			g_szRobotPacks = DEFAULT_PACK;
			g_szBossPacks = DEFAULT_BOSS_PACK;
			LoadPacks(g_szRobotPacks);
			LoadPacks(g_szBossPacks, true);
			
			g_flGracePeriodTime = 15.0;
			
			return;
		}
		
		stageKv++;
		LoadMapSettings(mapName); return;
	}
}

int GetMaxStages()
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, MapConfig);
	if (!FileExists(config))
	{
		RF2_PrintToChatAll("Config file %s does not exist, please correct this", config);
		ThrowError("File %s does not exist", config);
	}
	
	Handle mapKey = CreateKeyValues("stages");
	FileToKeyValues(mapKey, config);
	
	char stage[16];
	int stageCount = 0;
	
	for (int i = 0; i <= MAX_STAGES; i++)
	{
		KvRewind(mapKey);
		FormatEx(stage, sizeof(stage), "stage%i", i+1);
		if (KvJumpToKey(mapKey, stage))
		{
			stageCount++;
		}
		else
		{
			break;
		}
	}
	delete mapKey;
	return stageCount;
}

void LoadPacks(char[] packs, bool bosses = false)
{
	char packArray[32][64];
	int count = ExplodeString(packs, " ; ", packArray, 32, 64);
	
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, PackConfig);
		
	if (!FileExists(config))
	{
		RF2_PrintToChatAll("Config file %s does not exist, please correct this", config);
		ThrowError("File %s does not exist", config);
	}
	
	Handle packKey = CreateKeyValues("packs");
	FileToKeyValues(packKey, config);
	
	if (bosses)
		KvJumpToKey(packKey, "bosses");
	else
		KvJumpToKey(packKey, "robots");
	
	char list[MAX_CONFIG_NAME_LENGTH * MAX_ROBOT_TYPES];
	char buffer[MAX_CONFIG_NAME_LENGTH * MAX_ROBOT_TYPES];
	
	for (int i = 0; i < count; i++)
	{
		KvGetString(packKey, packArray[i], buffer, sizeof(buffer), "");
		if (buffer[0] == '\0')
		{
			if (!bosses)
				LogError("No robots found for pack \"%s\"!", packArray[i]);
			else	
				LogError("No bosses found for pack \"%s\"!", packArray[i]);
		}
		else
		{
			Format(list, sizeof(list), "%s ; %s", list, buffer);
		}
	}
	
	ReplaceStringEx(list, sizeof(list), " ; ", "");
	if (!bosses)
		LoadRobots(list);
	else
		LoadBosses(list);
	
	delete packKey;
}

void SetNextStage(int stage)
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, MapConfig);
	if (!FileExists(config))
	{
		RF2_PrintToChatAll("Config file %s does not exist, please correct this", config);
		ThrowError("File %s does not exist", config);
	}
	
	char section[16];
	char mapId[8];
	char mapName[PLATFORM_MAX_PATH];
	int maps = 0;
	
	Handle mapKey = CreateKeyValues("stages");
	FileToKeyValues(mapKey, config);
	
	FormatEx(section, sizeof(section), "stage%i", stage+1);
	KvJumpToKey(mapKey, section);
	
	for (int map = 0; map <= MAX_STAGE_MAPS; map++)
	{
		FormatEx(mapId, sizeof(mapId), "map%i", map+1);
		if (KvJumpToKey(mapKey, mapId))
		{
			maps++;
			KvGoBack(mapKey);
		}
		else
		{
			break;
		}
	}
	
	int randomMap = GetRandomInt(1, maps);

	FormatEx(mapId, sizeof(mapId), "map%i", randomMap);
	KvJumpToKey(mapKey, mapId);
	KvGetString(mapKey, "name", mapName, sizeof(mapName));
	
	delete mapKey;
	g_bMapChanging = true;
	ForceChangeLevel(mapName, "RF2 automatic map change");
}

bool RF2_IsMapValid(char[] mapName)
{
	if (!IsMapValid(mapName))
		return false;
		
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, MapConfig);
	if (!FileExists(config))
	{
		RF2_PrintToChatAll("Config file %s does not exist, please correct this", config);
		ThrowError("File %s does not exist", config);
	}
	
	Handle mapKey = CreateKeyValues("stages");
	FileToKeyValues(mapKey, config);
	
	char section[16];
	char mapKvName[256];
	char mapId[8];
	
	for (int i = 0; i <= g_iMaxStages; i++)
	{
		FormatEx(section, sizeof(section), "stage%i", i+1);
		KvJumpToKey(mapKey, section);
		
		for (int map = 0; map <= MAX_STAGE_MAPS; map++)
		{
			FormatEx(mapId, sizeof(mapId), "map%i", map+1);
			if (KvJumpToKey(mapKey, mapId))
			{
				KvGetString(mapKey, "name", mapKvName, sizeof(mapKvName), "map_untitled");
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
	}
	delete mapKey;
	return false;
}

public Action Timer_PlayMusic(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || !g_bMusicEnabled[i])
			continue;
			
		PlayMusicTrack(i);
	}
}

public Action Timer_LoopMusic(Handle timer, int client)
{	
	if ((client = GetClientOfUserId(client)) != 0)
	{
		EmitSoundToClient(client, g_szClientBGM[client]);
		g_hMusicLoopTimer[client] = CreateTimer(g_flBGMDuration[client], Timer_LoopMusic, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		g_hMusicLoopTimer[client] = null;
	}
}

void PlayMusicTrack(int client, bool bossTheme=false)
{
	if (!bossTheme)
	{
		FormatEx(g_szClientBGM[client], PLATFORM_MAX_PATH, g_szStageBGM);
		g_flBGMDuration[client] = g_flStageBGMDuration;
	}
	else
	{
		FormatEx(g_szClientBGM[client], PLATFORM_MAX_PATH, g_szBossBGM);
		g_flBGMDuration[client] = g_flBossBGMDuration;
	}
	
	if (g_hMusicLoopTimer[client] != null)
	{
		delete g_hMusicLoopTimer[client];
		g_hMusicLoopTimer[client] = null;
	}
	
	g_hMusicLoopTimer[client] = CreateTimer(g_flBGMDuration[client], Timer_LoopMusic, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	EmitSoundToClient(client, g_szClientBGM[client]);
}

void StopMusicTrack(int client)
{
	if (g_hMusicLoopTimer[client] != null)
	{
		delete g_hMusicLoopTimer[client];
		g_hMusicLoopTimer[client] = null;
	}
	
	if (!IsFakeClient(client))
		StopSound(client, SNDCHAN_AUTO, g_szClientBGM[client]);
}