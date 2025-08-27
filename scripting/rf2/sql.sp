#pragma semicolon 1
#pragma newdecls required

static Database g_DataBase;
static bool g_IsDataBaseCached[MAXTF2PLAYERS];
ArrayList g_ObtainedItems[MAXTF2PLAYERS];

void CreateSQL()
{
	Database base;
	char error[512];
	if (SQL_CheckConfig("rf2_database"))
	{
		base = SQL_Connect("rf2_database", true, error, sizeof(error));
		if (base == null)
		{
			PrintToServer("%s", error);
			return;
		}
	}
	else
	{
		base = SQLite_UseDatabase("rf2_database", error, sizeof(error));
		if (base == null)
		{
			PrintToServer("%s", error);
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
	g_DataBase = data;
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
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if (g_DataBase == null)
	{
		return;
	}

	if (IsFakeClient(client))
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

	g_DataBase.Execute(action, Database_Setup, Database_RetryClient, GetClientUserId(client));
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
			int value = 0;
			if (g_coAchievementCookies[i] != null) // DEV NOTE: When we get rid of cookies, just delete this if statement
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
				if (g_ObtainedItems[client] == null)
				{
					g_ObtainedItems[client] = new ArrayList(ByteCountToCells(64));
				}
				g_ObtainedItems[client].PushString(formatter);
			}
		}
		while (results[1].MoreRows);
	}
	else
	{
		if (action == null)
		{
			action = new Transaction();
		}

		for (int i = Item_TombReaders; i < Item_MaxValid; i++)
		{
			FormatEx(formatter, sizeof(formatter), "INSERT INTO item_log (steamid, name, obtained) VALUES ('%d', '%s', '%d')", 
				GetSteamAccountID(client), g_szItemSectionName[i], view_as<int>(IsItemInLogbookCookie(client, i)));
			if (IsItemInLogbookCookie(client, i))
			{
				if (g_ObtainedItems[client] == null)
				{
					g_ObtainedItems[client] = new ArrayList(ByteCountToCells(64));
				}
				g_ObtainedItems[client].PushString(g_szItemSectionName[i]);
			}
			action.AddQuery(formatter);
		}
	}

	if (action != null)
	{
		g_DataBase.Execute(action, _, Database_Fail);
	}

	g_IsDataBaseCached[client] = true;
}

void DataBase_OnDisconnected(int client)
{
	if (g_DataBase == null || IsFakeClient(client) || !g_IsDataBaseCached[client])
	{
		if (g_ObtainedItems[client] != null)
		{
			delete g_ObtainedItems[client];
		}

		return;
	}

	int id = GetSteamAccountID(client);
	if (id == 0)
	{
		if (g_ObtainedItems[client] != null)
		{
			delete g_ObtainedItems[client];
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

		FormatEx(formatter, sizeof(formatter), "UPDATE achievements SET "
		... "progress = %d "
		... "WHERE steamid = %d AND name = \"%s\";", value, id, name);
		action.AddQuery(formatter);
	}

	for (int i = Item_TombReaders; i < Item_MaxValid; i++)
	{
		int index = -1;
		if (g_ObtainedItems[client] != null)
		{
			index = g_ObtainedItems[client].FindString(g_szItemSectionName[i]);
		}
		FormatEx(formatter, sizeof(formatter), "UPDATE item_log SET "
		... "obtained = %d "
		... "WHERE steamid = %d AND name = \"%s\";", index == -1 ? 0 : 1, id, g_szItemSectionName[i]);
		action.AddQuery(formatter);
	}

	g_DataBase.Execute(action, _, Database_Fail, _, DBPrio_High);

	g_IsDataBaseCached[client] = false;

	if (g_ObtainedItems[client] != null)
	{
		delete g_ObtainedItems[client];
	}
}

void UpdateSQLAchievement(int client, int achievement, int value)
{
	if (g_DataBase == null || IsFakeClient(client) || !g_IsDataBaseCached[client])
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

	FormatEx(formatter, sizeof(formatter), "UPDATE achievements SET "
		... "progress = %d "
		... "WHERE steamid = %d AND name = \"%s\";", value, id, name);
	
	action.AddQuery(formatter);

	g_DataBase.Execute(action, _, Database_Fail, _, DBPrio_High);
}

ArrayList GetItemLogSQL(int client)
{
	return g_ObtainedItems[client];
}

void AddItemToSQL(int client, int item)
{
	if (g_DataBase == null || IsFakeClient(client) || !g_IsDataBaseCached[client])
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

	FormatEx(formatter, sizeof(formatter), "UPDATE item_log SET "
		... "obtained = 1 "
		... "WHERE steamid = %d AND name = \"%s\";", id, g_szItemSectionName[item]);
	
	action.AddQuery(formatter);

	g_DataBase.Execute(action, _, Database_Fail, _, DBPrio_High);

	g_ObtainedItems[client].PushString(g_szItemSectionName[item]);
}