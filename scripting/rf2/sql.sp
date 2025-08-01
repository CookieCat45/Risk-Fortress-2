#pragma semicolon 1
#pragma newdecls required

static Database g_hDataBase;
static bool g_bIsDataBaseCached[MAXPLAYERS];
ArrayList g_hObtainedItems[MAXPLAYERS];

void CreateSQL()
{
	Database base;
	char error[512];
	if (SQL_CheckConfig("rf2_database"))
	{
		base = SQL_Connect("rf2_database", true, error, sizeof(error));
		if (!base)
		{
			LogError(error);
			return;
		}
	}
	else
	{
		base = SQLite_UseDatabase("rf2_database", error, sizeof(error));
		if (!base)
		{
			LogError(error);
			return;
		}
	}

	Transaction action = new Transaction();
	char formatter[1024];
	FormatEx(formatter, sizeof(formatter), "CREATE TABLE IF NOT EXISTS achievements ("
	... "steamid INTEGER NOT NULL, "
	... "name TEXT NOT NULL, "
	... "progress INTEGER NOT NULL);");

	action.AddQuery(formatter);

	FormatEx(formatter, sizeof(formatter), "CREATE TABLE IF NOT EXISTS item_log ("
	... "steamid INTEGER NOT NULL, "
	... "name TEXT NOT NULL, "
	... "obtained INTEGER NOT NULL);");

	action.AddQuery(formatter);
	base.Execute(action, Database_Success, Database_FailHandle, base);
}

static void Database_Success(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	g_hDataBase = data;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientAuthorized(i))
		{
			OnClientAuthorized(i, NULL_STRING);
		}
	}
}

static void Database_Fail(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError(error);
}

static void Database_FailHandle(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError(error);
	CloseHandle(data);
}

static void Database_RetryClient(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	int client = GetClientOfUserId(data);
	if (IsValidClient(client))
	{
		OnClientAuthorized(client, error);
	}
	
	LogError(error);
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if (!g_hDataBase || IsFakeClient(client))
	{
		return;
	}
	
	int id = GetSteamAccountID(client);
	if (id == 0)
	{
		return;
	}

	Transaction action = new Transaction();
	char formatter[256];
	FormatEx(formatter, sizeof(formatter), "SELECT * FROM achievements WHERE steamid = %d;", id);
	action.AddQuery(formatter);
	FormatEx(formatter, sizeof(formatter), "SELECT * FROM item_log WHERE steamid = %d;", id);
	action.AddQuery(formatter);
	g_hDataBase.Execute(action, Database_Setup, Database_RetryClient, GetClientUserId(client));
	g_hObtainedItems[client] = new ArrayList(ByteCountToCells(64));
}

static void Database_Setup(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	int client = GetClientOfUserId(data);
	if (client <= 0 || client > MaxClients)
	{
		return;
	}
	
	char formatter[256], name[64];
	Transaction action;
	if (results[0].MoreRows) // Achievements
	{
		do
		{
			if (results[0].FetchRow())
			{
				results[0].FetchString(1, formatter, sizeof(formatter));
				int achievement = GetAchievementFromName(formatter);
				SetAchievementProgress(client, achievement, results[0].FetchInt(2), false);
			}
		}
		while (results[0].MoreRows);
	}
	else
	{
		action = new Transaction();
		for (int i = 0; i < MAX_ACHIEVEMENTS; i++)
		{
			GetAchievementInternalName(i, name, sizeof(name));
			int value;
			if (g_coAchievementCookies[i]) // DEV NOTE: When we get rid of cookies, just delete this if statement
			{
				char buffer[16];
				g_coAchievementCookies[i].Get(client, buffer, sizeof(buffer));
				value = StringToInt(buffer);
				SetAchievementProgress(client, i, value, false);
			}

			FormatEx(formatter, sizeof(formatter), "INSERT INTO achievements (steamid, name, progress) VALUES ('%d', '%s', '%d')", GetSteamAccountID(client), name, value);
			action.AddQuery(formatter);
		}
	}

	if (results[1].MoreRows) // Items
	{
		do
		{
			if (results[1].FetchRow() && results[1].FetchInt(2) != 0)
			{
				results[1].FetchString(1, formatter, sizeof(formatter));
				if (!g_hObtainedItems[client])
				{
					g_hObtainedItems[client] = new ArrayList(ByteCountToCells(64));
				}
				
				g_hObtainedItems[client].PushString(formatter);
			}
		}
		while (results[1].MoreRows);
	}
	else
	{
		if (!action)
		{
			action = new Transaction();
		}

		for (int i = 1; i < GetTotalItems(); i++)
		{
			FormatEx(formatter, sizeof(formatter), "INSERT INTO item_log (steamid, name, obtained) VALUES ('%d', '%s', '%d')", 
				GetSteamAccountID(client), g_szItemSectionName[i], view_as<int>(IsItemInLogbookCookie(client, i)));
			if (IsItemInLogbookCookie(client, i))
			{
				if (!g_hObtainedItems[client])
				{
					g_hObtainedItems[client] = new ArrayList(ByteCountToCells(64));
				}

				g_hObtainedItems[client].PushString(g_szItemSectionName[i]);
			}
			
			action.AddQuery(formatter);
		}
	}

	if (action)
	{
		g_hDataBase.Execute(action, _, Database_Fail);
	}

	g_bIsDataBaseCached[client] = true;
}

void DataBase_OnDisconnected(int client)
{
	if (!g_hDataBase || IsFakeClient(client) || !g_bIsDataBaseCached[client])
	{
		if (g_hObtainedItems[client])
		{
			delete g_hObtainedItems[client];
		}

		return;
	}

	int id = GetSteamAccountID(client);
	if (id == 0)
	{
		if (g_hObtainedItems[client])
		{
			delete g_hObtainedItems[client];
		}

		return;
	}

	Transaction action = new Transaction();
	char formatter[256];
	char name[64];
	for (int i = 0; i < MAX_ACHIEVEMENTS; i++)
	{
		GetAchievementInternalName(i, name, sizeof(name));
		int value = GetAchievementProgress(client, i);
		
		FormatEx(formatter, sizeof(formatter), "INSERT INTO achievements (steamid, name, progress) VALUES ('%d', '%s', '%d')", 
			id, name, value);
		action.AddQuery(formatter);
		FormatEx(formatter, sizeof(formatter), "UPDATE achievements SET "
		... "progress = %d "
		... "WHERE steamid = %d AND name = \"%s\";", value, id, name);
		action.AddQuery(formatter);
	}

	for (int i = 1; i < GetTotalItems(); i++)
	{
		int index = -1;
		if (g_hObtainedItems[client])
		{
			index = g_hObtainedItems[client].FindString(g_szItemSectionName[i]);
		}
		
		FormatEx(formatter, sizeof(formatter), "INSERT INTO item_log (steamid, name, obtained) VALUES ('%d', '%s', '%d')", 
			id, g_szItemSectionName[i], index == -1 ? 0 : 1);
			
		action.AddQuery(formatter);
		FormatEx(formatter, sizeof(formatter), "UPDATE item_log SET "
		... "obtained = %d "
		... "WHERE steamid = %d AND name = \"%s\";", index == -1 ? 0 : 1, id, g_szItemSectionName[i]);
		action.AddQuery(formatter);
	}

	g_hDataBase.Execute(action, _, Database_Fail, _, DBPrio_High);
	g_bIsDataBaseCached[client] = false;
	if (g_hObtainedItems[client])
	{
		delete g_hObtainedItems[client];
	}
}

void UpdateSQLAchievement(int client, int achievement, int value)
{
	if (!g_hDataBase || IsFakeClient(client) || !g_bIsDataBaseCached[client])
	{
		return;
	}

	int id = GetSteamAccountID(client);
	if (id == 0)
	{
		return;
	}

	Transaction action = new Transaction();
	char formatter[256];
	char name[64];
	GetAchievementInternalName(achievement, name, sizeof(name));
	FormatEx(formatter, sizeof(formatter), "INSERT INTO achievements (steamid, name, progress) VALUES ('%d', '%s', '%d')", 
		id, name, value);
	action.AddQuery(formatter);
	FormatEx(formatter, sizeof(formatter), "UPDATE achievements SET "
		... "progress = %d "
		... "WHERE steamid = %d AND name = \"%s\";", value, id, name);
	
	action.AddQuery(formatter);
	g_hDataBase.Execute(action, _, Database_Fail, _, DBPrio_High);
}

ArrayList GetItemLogSQL(int client)
{
	return g_hObtainedItems[client];
}

void AddItemToSQL(int client, int item)
{
	if (!g_hDataBase || IsFakeClient(client) || !g_bIsDataBaseCached[client])
	{
		return;
	}

	int id = GetSteamAccountID(client);
	if (id == 0)
	{
		return;
	}
	
	Transaction action = new Transaction();
	char formatter[256];
	FormatEx(formatter, sizeof(formatter), "INSERT INTO item_log (steamid, name, obtained) VALUES ('%d', '%s', '1')", 
		id, g_szItemSectionName[item]);
	
	action.AddQuery(formatter);
	FormatEx(formatter, sizeof(formatter), "UPDATE item_log SET "
		... "obtained = 1 "
		... "WHERE steamid = %d AND name = \"%s\";", id, g_szItemSectionName[item]);
	
	action.AddQuery(formatter);
	g_hDataBase.Execute(action, _, Database_Fail, _, DBPrio_High);
	g_hObtainedItems[client].PushString(g_szItemSectionName[item]);
}
