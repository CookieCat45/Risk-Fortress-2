#pragma semicolon 1
#pragma newdecls required

enum
{
	ACHIEVEMENT_BIGDAMAGE,
	ACHIEVEMENT_FULLITEMLOG,
	ACHIEVEMENT_DIE,
	ACHIEVEMENT_DIE100,
	ACHIEVEMENT_MARKETGARDEN,
	ACHIEVEMENT_GOOMBA,
	ACHIEVEMENT_AIRJUMPS,
	ACHIEVEMENT_BLOODHOUND,
	ACHIEVEMENT_HEADSPLITTER,
	ACHIEVEMENT_SAXTON,
	ACHIEVEMENT_HALLOWEENBOSSES,
	ACHIEVEMENT_POCKETMEDIC,
	ACHIEVEMENT_SENTRIES,
	ACHIEVEMENT_BADMAGIC,
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
	}
	
	return 1;
}

bool IsAchievementUnlocked(int client, int achievement)
{
	return GetAchievementProgress(client, achievement) >= GetAchievementGoal(achievement);
}

void OnAchievementUnlocked(int client, int achievement)
{
	float pos[3];
	TE_TFParticle("achieved", pos, client, PATTACH_POINT_FOLLOW, "partyhat");
	EmitSoundToAll(SND_ACHIEVEMENT, client);
	char name[64];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		GetAchievementName(achievement, name, sizeof(name), i);
		RF2_PrintToChat(i, "%N has earned the achievement {lightgreen}%s", client, name);
	}
}

int GetAchievementInternalName(int achievement, char[] buffer, int size)
{
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
