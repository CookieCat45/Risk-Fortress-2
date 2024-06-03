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
	
	// * * * INSERT NEW ACHIEVEMENTS DIRECTLY ABOVE THIS COMMENT ONLY! DO NOT REMOVE ANY ACHIEVEMENTS FROM THE ENUM! * * *
	MAX_ACHIEVEMENTS,
}

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
	char buffer[16];
	IntToString(progress, buffer, sizeof(buffer));
	g_coAchievementCookies[achievement].Set(client, buffer);
}

void SetAchievementProgress(int client, int achievement, int progress)
{
	if (IsFakeClient(client) || IsAchievementUnlocked(client, achievement))
		return;
	
	int cap = GetAchievementGoal(achievement);
	progress = imin(progress, cap);
	char buffer[16];
	IntToString(progress, buffer, sizeof(buffer));
	g_coAchievementCookies[achievement].Set(client, buffer);
	if (progress >= cap)
	{
		OnAchievementUnlocked(client, achievement);
	}
}

int GetAchievementProgress(int client, int achievement)
{
	char buffer[16];
	g_coAchievementCookies[achievement].Get(client, buffer, sizeof(buffer));
	return StringToInt(buffer);
}

int GetAchievementGoal(int achievement)
{
	switch (achievement)
	{
		case ACHIEVEMENT_FULLITEMLOG:
		{
			ArrayList list = GetSortedItemList();
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
	}
	
	if (!buffer[0])
	{
		LogError("[GetAchievementInternalName] Achievement ID %i is missing!", achievement);
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
