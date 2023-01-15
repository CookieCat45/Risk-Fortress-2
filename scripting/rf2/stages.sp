#if defined _RF2_maps_included
 #endinput
#endif
#define _RF2_maps_included

#pragma semicolon 1
#pragma newdecls required

#define DEFAULT_PACK_NAME "default"
#define DEFAULT_BOSS_PACK_NAME "default_boss"
#define NULL "vo/null.wav"

int g_iCurrentStage;
int g_iMaxStages;

char g_szClientBGM[MAXTF2PLAYERS][PLATFORM_MAX_PATH];
char g_szStageBGM[PLATFORM_MAX_PATH];
char g_szBossBGM[PLATFORM_MAX_PATH];

float g_flLoopMusicAt[MAXTF2PLAYERS] = {-1.0, ...};
float g_flStageBGMDuration;
float g_flBossBGMDuration;

char g_szPackName[512];
char g_szBossPackName[512];

float g_flGracePeriodTime = 15.0;

void LoadMapSettings(const char[] mapName)
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, MapConfig);
	if (!FileExists(config))
	{
		ThrowError("File %s does not exist", config);
	}
	
	char mapString[PLATFORM_MAX_PATH], section[16], mapId[8];
	static int stageKv = 1;
	bool found;
	
	KeyValues mapKey = CreateKeyValues("stages");
	mapKey.ImportFromFile(config);
	
	FormatEx(section, sizeof(section), "stage%i", stageKv);
	mapKey.JumpToKey(section);
	
	for (int map = 0; map <= MAX_STAGE_MAPS; map++)
	{
		FormatEx(mapId, sizeof(mapId), "map%i", map+1);
		if (mapKey.JumpToKey(mapId))
		{
			mapKey.GetString("name", mapString, sizeof(mapString));
			if (StrContains(mapName, mapString) != -1)
			{
				found = true;
				
				mapKey.GetString("theme", g_szStageBGM, sizeof(g_szStageBGM), NULL);
				g_flStageBGMDuration = mapKey.GetFloat("theme_duration", 60.0);
				
				mapKey.GetString("boss_theme", g_szBossBGM, sizeof(g_szBossBGM), NULL);
				g_flBossBGMDuration = mapKey.GetFloat("boss_theme_duration", 60.0);
				
				if (g_szStageBGM[0])
				{
					AddSoundToDownloadsTable(g_szStageBGM);
					PrecacheSound(g_szStageBGM);
				}
				
				if (g_szBossBGM[0])
				{
					AddSoundToDownloadsTable(g_szBossBGM);
					PrecacheSound(g_szBossBGM);
				}
				
				mapKey.GetString("enemy_pack", g_szPackName, sizeof(g_szPackName), DEFAULT_PACK_NAME);
				mapKey.GetString("boss_pack", g_szBossPackName, sizeof(g_szBossPackName), DEFAULT_BOSS_PACK_NAME);
				LoadEnemiesFromPack(g_szPackName);
				LoadBossesFromPack(g_szBossPackName);
				
				g_flGracePeriodTime = mapKey.GetFloat("grace_period_time", 30.0);
				g_bTankBossMode = bool(mapKey.GetNum("tank_destruction", false));
				
				stageKv = 1;
				break;
			}
		}
		
		mapKey.GoBack();
	}
	
	delete mapKey;
	
	if (!found)
	{
		if (stageKv >= RF2_GetMaxStages())
		{
			LogError("Could not locate map settings for map %s, using defaults!", mapName);
			
			g_szStageBGM = NULL;
			g_szBossBGM = NULL;
			g_flStageBGMDuration = 60.0;
			g_flBossBGMDuration = 60.0;
			
			g_szPackName = DEFAULT_PACK_NAME;
			g_szBossPackName = DEFAULT_BOSS_PACK_NAME;
			
			g_flGracePeriodTime = 15.0;
			stageKv = 1;
		}
		else
		{
			stageKv++;
			LoadMapSettings(mapName);
		}
	}
}

int FindMaxStages()
{
	char config[PLATFORM_MAX_PATH], stage[16];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, MapConfig);
	if (!FileExists(config))
	{
		ThrowError("File %s does not exist", config);
	}
	
	KeyValues mapKey = CreateKeyValues("stages");
	mapKey.ImportFromFile(config);
	
	int stageCount = 0;
	
	for (int i = 0; i <= MAX_STAGES; i++)
	{
		mapKey.Rewind();
		FormatEx(stage, sizeof(stage), "stage%i", i+1);
		
		if (mapKey.JumpToKey(stage))
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

void SetNextStage(int stage)
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, MapConfig);
	if (!FileExists(config))
	{
		ThrowError("File %s does not exist", config);
	}
	
	char section[16], mapId[8], mapName[PLATFORM_MAX_PATH];
	int maps;
	
	KeyValues mapKey = CreateKeyValues("stages");
	mapKey.ImportFromFile(config);
	
	FormatEx(section, sizeof(section), "stage%i", stage+1);
	mapKey.JumpToKey(section);
	
	for (int map = 0; map <= MAX_STAGE_MAPS; map++)
	{
		FormatEx(mapId, sizeof(mapId), "map%i", map+1);
		
		if (mapKey.JumpToKey(mapId))
		{
			maps++;
			mapKey.GoBack();
		}
		else
		{
			break;
		}
	}
	
	int randomMap = GetRandomInt(1, maps);

	FormatEx(mapId, sizeof(mapId), "map%i", randomMap);
	mapKey.JumpToKey(mapId);
	mapKey.GetString("name", mapName, sizeof(mapName));
	
	delete mapKey;
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
		ThrowError("File %s does not exist", config);
	}
	
	KeyValues mapKey = CreateKeyValues("stages");
	mapKey.ImportFromFile(config);
	
	char section[16], mapKvName[256], mapId[8];
	
	for (int i = 0; i <= RF2_GetMaxStages(); i++)
	{
		FormatEx(section, sizeof(section), "stage%i", i+1);
		mapKey.JumpToKey(section);
		
		for (int map = 0; map <= MAX_STAGE_MAPS; map++)
		{
			FormatEx(mapId, sizeof(mapId), "map%i", map+1);
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

public Action Timer_PlayMusicDelay(Handle timer)
{
	PlayMusicTrackAll();
	return Plugin_Continue;
}

void PlayMusicTrack(int client)
{
	if (IsFakeClientEx(client) || !g_bPlayerMusicEnabled[client])
		return;
	
	StopMusicTrack(client);
	GetCurrentMusicTrack(g_szClientBGM[client], sizeof(g_szClientBGM[]));
	
	if (!IsBossEventActive() && g_flStageBGMDuration > 0.0)
	{
		g_flLoopMusicAt[client] = GetEngineTime() + g_flStageBGMDuration;
	}
	else if (g_flBossBGMDuration > 0.0)
	{
		g_flLoopMusicAt[client] = GetEngineTime() + g_flBossBGMDuration;
	}
	
	EmitSoundToClient(client, g_szClientBGM[client]);
}

void StopMusicTrack(int client)
{
	g_flLoopMusicAt[client] = -1.0;
	
	if (IsClientInGameEx(client) && !IsFakeClientEx(client))
	{
		StopSound(client, SNDCHAN_AUTO, g_szClientBGM[client]);
	}
}

void PlayMusicTrackAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i))
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
	if (IsBossEventActive())
	{
		strcopy(buffer, size, g_szBossBGM);
	}
	else
	{
		strcopy(buffer, size, g_szStageBGM);
	}
}