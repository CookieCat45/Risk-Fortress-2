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

	char name[64];
	for (int i = 0; i < MAX_ACHIEVEMENTS; i++)
	{
		GetAchievementInternalName(i, name, sizeof(name));
		FormatEx(formatter, sizeof(formatter), "CREATE TABLE IF NOT EXISTS %s ("
		... "steamid INTEGER PRIMARY KEY, "
		... "progress INTEGER NOT NULL);", name);
		action.AddQuery(formatter);
	}

	base.Execute(action, Database_Success, Database_FailHandle, base);

	RegAdminCmd("rf2_transfer_database", Command_TransferDatabase, ADMFLAG_ROOT);
}

static void Database_Success(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	g_hDataBase = data;
	//CleanUselessSQLAchievements();
	//CreateTimer(1.0, Timer_VacuumSQL, _, TIMER_FLAG_NO_MAPCHANGE);
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
	char formatter[256], name[64];
	for (int i = 0; i < MAX_ACHIEVEMENTS; i++)
	{
		GetAchievementInternalName(i, name, sizeof(name));
		FormatEx(formatter, sizeof(formatter), "SELECT progress FROM %s WHERE steamid = %d;", name, id);
		action.AddQuery(formatter, i);
	}
	g_hDataBase.Execute(action, Database_SetupAchievements, _, GetClientUserId(client));

	action = new Transaction();
	for (int i = 1; i < GetTotalItems(); i++)
	{
		FormatEx(formatter, sizeof(formatter), "SELECT obtained FROM ITEM_%s WHERE steamid = %d;", g_szItemSectionName[i], id);
		action.AddQuery(formatter, i);
	}
	g_hDataBase.Execute(action, Database_SetupItems, Database_RetryClient, GetClientUserId(client));
}

static void Database_SetupAchievements(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	int client = GetClientOfUserId(data);
	if (client <= 0 || client > MaxClients)
	{
		return;
	}

	char formatter[256];
	for (int i = 0; i < MAX_ACHIEVEMENTS; i++)
	{
		GetAchievementInternalName(queryData[i], formatter, sizeof(formatter));
		if (results[i] == null || !results[i].MoreRows)
		{
			continue;
		}

		if (results[i].FetchRow())
		{
			SetAchievementProgress(client, i, results[i].FetchInt(0), false);
		}
	}
}

static void Database_SetupItems(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	int client = GetClientOfUserId(data);
	if (client <= 0 || client > MaxClients)
	{
		return;
	}

	for (int i = 1; i < GetTotalItems(); i++)
	{
		if (results[i - 1] == null || !results[i - 1].FetchRow())
		{
			continue;
		}

		if (results[i - 1].FetchRow() && results[i - 1].FetchInt(0))
		{
			if (g_hObtainedItems[client] == null)
			{
				g_hObtainedItems[client] = new ArrayList(ByteCountToCells(64));
			}

			g_hObtainedItems[client].PushString(g_szItemSectionName[i]);
		}
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
		if (value <= 0)
		{
			continue;
		}

		FormatEx(formatter, sizeof(formatter), "INSERT INTO %s (steamid, progress) VALUES (%d, %d)"
		... "ON CONFLICT (steamid) DO UPDATE SET progress = %d WHERE steamid = %d;",
			name, id, value, value, id);
		action.AddQuery(formatter);
	}

	for (int i = 1; i < GetTotalItems(); i++)
	{
		int index = -1;
		if (g_hObtainedItems[client])
		{
			index = g_hObtainedItems[client].FindString(g_szItemSectionName[i]);
		}

		if (index == -1)
		{
			continue;
		}

		FormatEx(formatter, sizeof(formatter), "INSERT INTO ITEM_%s (steamid, obtained) VALUES (%d, 1)"
		... "ON CONFLICT (steamid) DO UPDATE SET obtained = 1 WHERE steamid = %d;",
			g_szItemSectionName[i], id, id);

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
	FormatEx(formatter, sizeof(formatter), "INSERT INTO %s (steamid, progress) VALUES (%d, %d)"
		... "ON CONFLICT (steamid) DO UPDATE SET progress = %d WHERE steamid = %d;",
			name, id, value, value, id);

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
	FormatEx(formatter, sizeof(formatter), "INSERT INTO ITEM_%s (steamid, obtained) VALUES (%d, 1)"
		... "ON CONFLICT (steamid) DO UPDATE SET obtained = 1 WHERE steamid = %d;",
			g_szItemSectionName[item], id, id);
	action.AddQuery(formatter);
	g_hDataBase.Execute(action, _, Database_Fail, _, DBPrio_High);
	if (g_hObtainedItems[client] == null)
	{
		g_hObtainedItems[client] = new ArrayList(ByteCountToCells(64));
	}
	g_hObtainedItems[client].PushString(g_szItemSectionName[item]);
}

/*void CleanUselessSQLAchievements()
{
	if (!g_hDataBase)
	{
		return;
	}

	Transaction action = new Transaction();
	char formatter[1024], name[64];
	for (int i = 0; i < MAX_ACHIEVEMENTS; i++)
	{
		GetAchievementInternalName(i, name, sizeof(name));
		FormatEx(formatter, sizeof(formatter), "DELETE FROM %s WHERE progress = 0;", name);
		action.AddQuery(formatter);
	}
	g_hDataBase.Execute(action, _, Database_Fail);
}

static Action Timer_VacuumSQL(Handle timer)
{
	if (!g_hDataBase)
	{
		return Plugin_Stop;
	}

	Transaction action = new Transaction();
	action.AddQuery("PRAGMA auto_vacuum = 1;");
	action.AddQuery("COMMIT;");
	action.AddQuery("VACUUM;");
	action.AddQuery("COMMIT;");
	g_hDataBase.Execute(action, _, Database_Fail);

	return Plugin_Stop;
}*/

Action Timer_CreateItemTables(Handle timer)
{
	Transaction action = new Transaction();
	char formatter[1024];
	for (int i = 1; i < GetTotalItems(); i++)
	{
		FormatEx(formatter, sizeof(formatter), "CREATE TABLE IF NOT EXISTS ITEM_%s ("
		... "steamid INTEGER PRIMARY KEY, "
		... "obtained INTEGER NOT NULL);", g_szItemSectionName[i]);
		action.AddQuery(formatter);
	}

	g_hDataBase.Execute(action, _, Database_FailHandle);

	return Plugin_Stop;
}

static Action Command_TransferDatabase(int client, int args)
{
	DoDatabaseTransfer();
	return Plugin_Handled;
}

static void DoDatabaseTransfer()
{
	char formatter[1024], name[64];
	Transaction action = new Transaction();
	for (int i = 0; i < MAX_ACHIEVEMENTS; i++)
	{
		GetAchievementInternalName(i, name, sizeof(name));
		FormatEx(formatter, sizeof(formatter), "SELECT * FROM achievements WHERE name = '%s';", name);
		action.AddQuery(formatter);
	}

	g_hDataBase.Execute(action, Database_TransferAchievements, Database_Fail);
}

static void Database_TransferAchievements(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	Transaction action;
	int index = 0;
	char formatter[1024], name[64];
	PrintToServer("Starting executing");
	while (index < MAX_ACHIEVEMENTS && results[index].MoreRows && results[index].FetchRow())
	{
		PrintToServer("%i", index);
		int progress = results[index].FetchInt(2);
		int steamid = results[index].FetchInt(0);
		if (action == null)
		{
			action = new Transaction();
		}
		GetAchievementInternalName(index, name, sizeof(name));
		FormatEx(formatter, sizeof(formatter), "INSERT INTO %s (steamid, progress) VALUES (%d, %d)", name, steamid, progress);
		action.AddQuery(formatter);
		FormatEx(formatter, sizeof(formatter), "DELETE FROM achievements WHERE steamid = %d AND name = '%s';", steamid, name);
		action.AddQuery(formatter);
		index++;
	}
	PrintToServer("Executing transfers");

	g_hDataBase.Execute(action, Database_TransferSuccess, Database_Fail);
}

static void Database_TransferSuccess(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	PrintToServer("Done");
	DoDatabaseTransfer();
}