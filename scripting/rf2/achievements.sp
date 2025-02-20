#pragma semicolon 1
#pragma newdecls required

enum
{
	ACHIEVEMENT_BIGDAMAGE = 0,
	ACHIEVEMENT_FULLITEMLOG = 1,
	ACHIEVEMENT_DIE = 2,
	ACHIEVEMENT_DIE100 = 3,
	ACHIEVEMENT_MARKETGARDEN = 4,
	ACHIEVEMENT_GOOMBA = 5,
	ACHIEVEMENT_AIRJUMPS = 6,
	ACHIEVEMENT_BLOODHOUND = 7,
	ACHIEVEMENT_HEADSPLITTER = 8,
	ACHIEVEMENT_SAXTON = 9,
	ACHIEVEMENT_HALLOWEENBOSSES = 10,
	ACHIEVEMENT_POCKETMEDIC = 11,
	ACHIEVEMENT_SENTRIES = 12,
	ACHIEVEMENT_BADMAGIC = 13,
	ACHIEVEMENT_TELEPORTER = 14,
	ACHIEVEMENT_TANKBUSTER = 15,
	ACHIEVEMENT_DAMAGECAP = 16,
	ACHIEVEMENT_FIRERATECAP = 17,
	ACHIEVEMENT_LUCKY = 18,
	ACHIEVEMENT_THUNDER = 19,
	ACHIEVEMENT_DANCE = 20,
	ACHIEVEMENT_TEMPLESECRET = 21,
	ACHIEVEMENT_SCOUTSTUN = 22,
	ACHIEVEMENT_KILL10K = 23,
	ACHIEVEMENT_KILL100K = 24,
	ACHIEVEMENT_GOOMBACHAIN = 25,
	ACHIEVEMENT_RECYCLER = 26,
	ACHIEVEMENT_HITMERASMUS = 27,
	ACHIEVEMENT_GARGOYLE = 28,
	ACHIEVEMENT_OBLITERATE = 29,
	ACHIEVEMENT_BEATGAME = 30,
	ACHIEVEMENT_BEATGAMESTEEL = 31,
	ACHIEVEMENT_BEATGAMETITANIUM = 32,
	
	// * * * INSERT NEW ACHIEVEMENTS DIRECTLY ABOVE THIS COMMENT ONLY! DO NOT REMOVE ANY ACHIEVEMENTS FROM THE ENUM! * * *
	MAX_ACHIEVEMENTS,
}

static int g_Achievement[MAXTF2PLAYERS][MAX_ACHIEVEMENTS];

void TriggerAchievement(int client, int achievement)
{
	if (IsFakeClient(client) || IsAchievementUnlocked(client, achievement))
		return;
	
	int progress = GetAchievementProgress(client, achievement);
	int cap = GetAchievementGoal(achievement);
	progress++;
	if (progress >= cap)
	{
		OnAchievementUnlocked(client, achievement);
	}
	
	progress = imin(progress, cap);
	g_Achievement[client][achievement] = progress;
	UpdateSQLAchievement(client, achievement, progress);
}

void SetAchievementProgress(int client, int achievement, int progress, bool updateDB = true)
{
	if (IsFakeClient(client))
	{
		return;
	}

	int cap = GetAchievementGoal(achievement);
	progress = imin(progress, cap);
	g_Achievement[client][achievement] = progress;

	if (IsAchievementUnlocked(client, achievement))
	{
		return;
	}

	if (updateDB)
	{
		UpdateSQLAchievement(client, achievement, progress);
		if (progress >= cap)
		{
			OnAchievementUnlocked(client, achievement);
		}
	}
}

int GetAchievementProgress(int client, int achievement)
{
	return g_Achievement[client][achievement];
}

int GetAchievementGoal(int achievement)
{
	switch (achievement)
	{
		case ACHIEVEMENT_FULLITEMLOG:
		{
			ArrayList list = GetSortedItemList(_, _, _, _, false);
			int total = list.Length;
			delete list;
			return total;
		}
		
		case ACHIEVEMENT_POCKETMEDIC: return 30;
		
		case ACHIEVEMENT_DIE100, ACHIEVEMENT_SAXTON: return 100;
		
		case ACHIEVEMENT_MARKETGARDEN, ACHIEVEMENT_GOOMBA, ACHIEVEMENT_BADMAGIC: return 10;
		
		case ACHIEVEMENT_TANKBUSTER: return 200;
		
		case ACHIEVEMENT_SCOUTSTUN: return 300;
		
		case ACHIEVEMENT_KILL10K: return 10000;
		
		case ACHIEVEMENT_KILL100K: return 100000;

		case ACHIEVEMENT_RECYCLER: return 10;
	}
	
	return 1;
}

bool IsAchievementUnlocked(int client, int achievement)
{
	return GetAchievementProgress(client, achievement) >= GetAchievementGoal(achievement);
}

bool PlayerHasAllAchievements(int client)
{
	int count;
	for (int i = 0; i < MAX_ACHIEVEMENTS; i++)
	{
		if (!IsAchievementHidden(i) && IsAchievementUnlocked(client, i))
			count++;
	}
	
	return count >= GetTotalAchievements();
}

int GetTotalAchievements(bool allowHidden=false)
{
	int count;
	for (int i = 0; i < MAX_ACHIEVEMENTS; i++)
	{
		if (allowHidden || !IsAchievementHidden(i))
			count++;
	}
	
	return count;
}

bool g_bTropicsMapExists;
bool IsAchievementHidden(int achievement)
{
	if (achievement == ACHIEVEMENT_TEMPLESECRET)
	{
		return !g_bTropicsMapExists;
	}
	
	if (achievement == ACHIEVEMENT_GOOMBA || achievement == ACHIEVEMENT_GOOMBACHAIN)
	{
		return !IsGoombaAvailable();
	}
	
	if (achievement == ACHIEVEMENT_HITMERASMUS || achievement == ACHIEVEMENT_GARGOYLE || achievement == ACHIEVEMENT_OBLITERATE)
	{
		return !DoesUnderworldExist();
	}

	if (achievement == ACHIEVEMENT_BEATGAME || achievement == ACHIEVEMENT_BEATGAMESTEEL || achievement == ACHIEVEMENT_BEATGAMETITANIUM)
	{
		return !DoesFinalMapExist();
	}
	
	// deprecated achievements, always hidden
	return achievement == ACHIEVEMENT_DANCE || achievement == ACHIEVEMENT_BADMAGIC || achievement == ACHIEVEMENT_AIRJUMPS;
}

void OnAchievementUnlocked(int client, int achievement)
{
	float pos[3];
	TE_TFParticle("achieved", pos, client, PATTACH_POINT_FOLLOW, "head");
	EmitSoundToAll(SND_ACHIEVEMENT, client);
	char name[64];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		GetAchievementName(achievement, name, sizeof(name), i);
		RF2_PrintToChat(i, "{yellow}%N{default} has earned the achievement {lightgreen}%s", client, name);
	}
	
	if (PlayerHasAllAchievements(client))
	{
		SetCookieBool(client, g_coEarnedAllAchievements, true);
		PrintCenterText(client, "CONGRATULATIONS!!! You've earned all of the achievements!\nYou've been rewarded with a commemorative Merc Medal!");
	}
	
	PrintHintText(client, "To view your achievements, use the /rf2_achievements command.");
}

int GetAchievementInternalName(int achievement, char[] buffer, int size)
{
	// really wish SourcePawn had a way to convert symbol names to strings...
	switch (achievement)
	{
		case ACHIEVEMENT_BIGDAMAGE: return strcopy(buffer, size, "ACHIEVEMENT_BIGDAMAGE");
		case ACHIEVEMENT_FULLITEMLOG: return strcopy(buffer, size, "ACHIEVEMENT_FULLITEMLOG");
		case ACHIEVEMENT_DIE: return strcopy(buffer, size, "ACHIEVEMENT_DIE");
		case ACHIEVEMENT_DIE100: return strcopy(buffer, size, "ACHIEVEMENT_DIE100");
		case ACHIEVEMENT_MARKETGARDEN: return strcopy(buffer, size, "ACHIEVEMENT_MARKETGARDEN");
		case ACHIEVEMENT_GOOMBA: return strcopy(buffer, size, "ACHIEVEMENT_GOOMBA");
		case ACHIEVEMENT_AIRJUMPS: return strcopy(buffer, size, "ACHIEVEMENT_AIRJUMPS");
		case ACHIEVEMENT_BLOODHOUND: return strcopy(buffer, size, "ACHIEVEMENT_BLOODHOUND");
		case ACHIEVEMENT_HEADSPLITTER: return strcopy(buffer, size, "ACHIEVEMENT_HEADSPLITTER");
		case ACHIEVEMENT_SAXTON: return strcopy(buffer, size, "ACHIEVEMENT_SAXTON");
		case ACHIEVEMENT_HALLOWEENBOSSES: return strcopy(buffer, size, "ACHIEVEMENT_HALLOWEENBOSSES");
		case ACHIEVEMENT_POCKETMEDIC: return strcopy(buffer, size, "ACHIEVEMENT_POCKETMEDIC");
		case ACHIEVEMENT_SENTRIES: return strcopy(buffer, size, "ACHIEVEMENT_SENTRIES");
		case ACHIEVEMENT_BADMAGIC: return strcopy(buffer, size, "ACHIEVEMENT_BADMAGIC");
		case ACHIEVEMENT_TELEPORTER: return strcopy(buffer, size, "ACHIEVEMENT_TELEPORTER");
		case ACHIEVEMENT_TANKBUSTER: return strcopy(buffer, size, "ACHIEVEMENT_TANKBUSTER");
		case ACHIEVEMENT_DAMAGECAP: return strcopy(buffer, size, "ACHIEVEMENT_DAMAGECAP");
		case ACHIEVEMENT_FIRERATECAP: return strcopy(buffer, size, "ACHIEVEMENT_FIRERATECAP");
		case ACHIEVEMENT_THUNDER: return strcopy(buffer, size, "ACHIEVEMENT_THUNDER");
		case ACHIEVEMENT_LUCKY: return strcopy(buffer, size, "ACHIEVEMENT_LUCKY");
		case ACHIEVEMENT_DANCE: return strcopy(buffer, size, "ACHIEVEMENT_DANCE");
		case ACHIEVEMENT_TEMPLESECRET: return strcopy(buffer, size, "ACHIEVEMENT_TEMPLESECRET");
		case ACHIEVEMENT_SCOUTSTUN: return strcopy(buffer, size, "ACHIEVEMENT_SCOUTSTUN");
		case ACHIEVEMENT_KILL10K: return strcopy(buffer, size, "ACHIEVEMENT_KILL10K");
		case ACHIEVEMENT_KILL100K: return strcopy(buffer, size, "ACHIEVEMENT_KILL100K");
		case ACHIEVEMENT_GOOMBACHAIN: return strcopy(buffer, size, "ACHIEVEMENT_GOOMBACHAIN");
		case ACHIEVEMENT_RECYCLER: return strcopy(buffer, size, "ACHIEVEMENT_RECYCLER");
		case ACHIEVEMENT_HITMERASMUS: return strcopy(buffer, size, "ACHIEVEMENT_HITMERASMUS");
		case ACHIEVEMENT_GARGOYLE: return strcopy(buffer, size, "ACHIEVEMENT_GARGOYLE");
		case ACHIEVEMENT_OBLITERATE: return strcopy(buffer, size, "ACHIEVEMENT_OBLITERATE");
		case ACHIEVEMENT_BEATGAME: return strcopy(buffer, size, "ACHIEVEMENT_BEATGAME");
		case ACHIEVEMENT_BEATGAMESTEEL: return strcopy(buffer, size, "ACHIEVEMENT_BEATGAMESTEEL");
		case ACHIEVEMENT_BEATGAMETITANIUM: return strcopy(buffer, size, "ACHIEVEMENT_BEATGAMETITANIUM");
	}
	
	if (!buffer[0])
	{
		LogError("[GetAchievementInternalName] Achievement ID %i is missing!", achievement);
	}
	
	return 0;
}

int GetAchievementFromName(const char[] name)
{
	if (strcmp(name, "ACHIEVEMENT_BIGDAMAGE") == 0)
	{
		return ACHIEVEMENT_BIGDAMAGE;
	}
	else if (strcmp(name, "ACHIEVEMENT_FULLITEMLOG") == 0)
	{
		return ACHIEVEMENT_FULLITEMLOG;
	}
	else if (strcmp(name, "ACHIEVEMENT_DIE") == 0)
	{
		return ACHIEVEMENT_DIE;
	}
	else if (strcmp(name, "ACHIEVEMENT_DIE100") == 0)
	{
		return ACHIEVEMENT_DIE100;
	}
	else if (strcmp(name, "ACHIEVEMENT_MARKETGARDEN") == 0)
	{
		return ACHIEVEMENT_MARKETGARDEN;
	}
	else if (strcmp(name, "ACHIEVEMENT_GOOMBA") == 0)
	{
		return ACHIEVEMENT_GOOMBA;
	}
	else if (strcmp(name, "ACHIEVEMENT_AIRJUMPS") == 0)
	{
		return ACHIEVEMENT_AIRJUMPS;
	}
	else if (strcmp(name, "ACHIEVEMENT_BLOODHOUND") == 0)
	{
		return ACHIEVEMENT_BLOODHOUND;
	}
	else if (strcmp(name, "ACHIEVEMENT_HEADSPLITTER") == 0)
	{
		return ACHIEVEMENT_HEADSPLITTER;
	}
	else if (strcmp(name, "ACHIEVEMENT_SAXTON") == 0)
	{
		return ACHIEVEMENT_SAXTON;
	}
	else if (strcmp(name, "ACHIEVEMENT_HALLOWEENBOSSES") == 0)
	{
		return ACHIEVEMENT_HALLOWEENBOSSES;
	}
	else if (strcmp(name, "ACHIEVEMENT_POCKETMEDIC") == 0)
	{
		return ACHIEVEMENT_POCKETMEDIC;
	}
	else if (strcmp(name, "ACHIEVEMENT_SENTRIES") == 0)
	{
		return ACHIEVEMENT_SENTRIES;
	}
	else if (strcmp(name, "ACHIEVEMENT_BADMAGIC") == 0)
	{
		return ACHIEVEMENT_BADMAGIC;
	}
	else if (strcmp(name, "ACHIEVEMENT_TELEPORTER") == 0)
	{
		return ACHIEVEMENT_TELEPORTER;
	}
	else if (strcmp(name, "ACHIEVEMENT_TANKBUSTER") == 0)
	{
		return ACHIEVEMENT_TANKBUSTER;
	}
	else if (strcmp(name, "ACHIEVEMENT_DAMAGECAP") == 0)
	{
		return ACHIEVEMENT_DAMAGECAP;
	}
	else if (strcmp(name, "ACHIEVEMENT_FIRERATECAP") == 0)
	{
		return ACHIEVEMENT_FIRERATECAP;
	}
	else if (strcmp(name, "ACHIEVEMENT_THUNDER") == 0)
	{
		return ACHIEVEMENT_THUNDER;
	}
	else if (strcmp(name, "ACHIEVEMENT_LUCKY") == 0)
	{
		return ACHIEVEMENT_LUCKY;
	}
	else if (strcmp(name, "ACHIEVEMENT_DANCE") == 0)
	{
		return ACHIEVEMENT_DANCE;
	}
	else if (strcmp(name, "ACHIEVEMENT_TEMPLESECRET") == 0)
	{
		return ACHIEVEMENT_TEMPLESECRET;
	}
	else if (strcmp(name, "ACHIEVEMENT_SCOUTSTUN") == 0)
	{
		return ACHIEVEMENT_SCOUTSTUN;
	}
	else if (strcmp(name, "ACHIEVEMENT_KILL10K") == 0)
	{
		return ACHIEVEMENT_KILL10K;
	}
	else if (strcmp(name, "ACHIEVEMENT_KILL10K") == 0)
	{
		return ACHIEVEMENT_KILL10K;
	}
	else if (strcmp(name, "ACHIEVEMENT_KILL100K") == 0)
	{
		return ACHIEVEMENT_KILL100K;
	}
	else if (strcmp(name, "ACHIEVEMENT_GOOMBACHAIN") == 0)
	{
		return ACHIEVEMENT_GOOMBACHAIN;
	}
	else if (strcmp(name, "ACHIEVEMENT_RECYCLER") == 0)
	{
		return ACHIEVEMENT_RECYCLER;
	}
	else if (strcmp(name, "ACHIEVEMENT_HITMERASMUS") == 0)
	{
		return ACHIEVEMENT_HITMERASMUS;
	}
	else if (strcmp(name, "ACHIEVEMENT_GARGOYLE") == 0)
	{
		return ACHIEVEMENT_GARGOYLE;
	}
	else if (strcmp(name, "ACHIEVEMENT_OBLITERATE") == 0)
	{
		return ACHIEVEMENT_OBLITERATE;
	}
	else if (strcmp(name, "ACHIEVEMENT_BEATGAME") == 0)
	{
		return ACHIEVEMENT_BEATGAME;
	}
	else if (strcmp(name, "ACHIEVEMENT_BEATGAMESTEEL") == 0)
	{
		return ACHIEVEMENT_BEATGAMESTEEL;
	}
	else if (strcmp(name, "ACHIEVEMENT_BEATGAMETITANIUM") == 0)
	{
		return ACHIEVEMENT_BEATGAMETITANIUM;
	}
	else
	{
		LogError("[GetAchievementFromName] Achievement name %s is missing!", name);
	}

	return 0;
}

int GetAchievementName(int achievement, char[] buffer, int size, int client=LANG_SERVER)
{
	char internalName[64];
	GetAchievementInternalName(achievement, internalName, sizeof(internalName));
	return FormatEx(buffer, size, "%T", internalName, client);
}

int GetAchievementDesc(int achievement, char[] buffer, int size, int client=LANG_SERVER)
{
	char internalName[64];
	GetAchievementInternalName(achievement, internalName, sizeof(internalName));
	StrCat(internalName, sizeof(internalName), "_DESC");
	return FormatEx(buffer, size, "%T", internalName, client);
}
