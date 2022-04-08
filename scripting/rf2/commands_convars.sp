#if defined _RF2_commands_convars_included
 #endinput
#endif
#define _RF2_commands_convars_included

bool g_bForceNextMap;
char g_szForcedMap[256];
char g_szMapForcer[128];

void LoadCommandsAndCvars()
{
	RegAdminCmd("rf2_reload", Command_ReloadRF2, ADMFLAG_RCON, "Reloads the plugin. This will restart the round as well.");
	RegAdminCmd("rf2_reloaditems", Command_ReloadItems, ADMFLAG_RCON, "Reloads RF2's item config.");
	RegAdminCmd("rf2_setnextmap", Command_ForceMap, ADMFLAG_RCON, "Forces the next map to the map specified. /rf2_setnextmap <map name>");
	
	RegAdminCmd("rf2_entitycount", Command_EntityCount, ADMFLAG_SLAY, "Shows the total number of networked entities (edicts) in the server.");
	RegAdminCmd("rf2_giveitem", Command_GiveItem, ADMFLAG_RCON, "Give items to a player. /rf2_giveitem <player> <item index> <amount>\nNegative amounts will remove items from a player.");
	RegAdminCmd("rf2_forcewin", Command_ForceWin, ADMFLAG_RCON, "Forces a team to win. /rf2_forcewin red|blue");
	
	RegAdminCmd("rf2_skipwait", Command_SkipWait, ADMFLAG_SLAY, "Skips the Waiting For Players sequence.\nUse only if you are certain all players are fully loaded in.");
	RegAdminCmd("rf2_skipgrace", Command_SkipGracePeriod, ADMFLAG_RCON, "Skip the grace period at the start of a round");
	RegAdminCmd("rf2_skipgraceperiod", Command_SkipGracePeriod, ADMFLAG_RCON, "Skip the grace period at the start of a round");
	
	RegAdminCmd("rf2_addpoints", Command_AddPoints, ADMFLAG_SLAY, "Add queue points to a player. /rf2_addpoints <player> <amount>");
	RegAdminCmd("rf2_givecash", Command_GiveCash, ADMFLAG_RCON, "Give cash to a RED player. /rf2_givecash <player> <amount>");
	
	cv_AlwaysSkipWait = CreateConVar("rf2_always_skip_wait", "0", "Always skip the Waiting For Players sequence. Great for singleplayer.", FCVAR_NOTIFY|FCVAR_REPLICATED);
	cv_DebugNoMapChange = CreateConVar("rf2_skip_map_change", "0", "Prevents the map from changing on round end.", FCVAR_NOTIFY|FCVAR_REPLICATED);
	cv_DebugShowDifficultyCoeff = CreateConVar("rf2_show_difficulty_coeff", "0", "Shows the value of the difficulty coefficient.", FCVAR_NOTIFY|FCVAR_REPLICATED);
	cv_DebugDontEndGame = CreateConVar("rf2_dont_end_game_on_death", "0", "Don't end the game if all of the survivors die.", FCVAR_NOTIFY|FCVAR_REPLICATED);
	cv_EnableAFKManager = CreateConVar("rf2_use_afk_manager", "1", "Use RF2's AFK manager to kick AFK players.", FCVAR_NOTIFY|FCVAR_REPLICATED);
	cv_AFKManagerKickTime = CreateConVar("rf2_afk_kick_time", "120.0", "AFK manager kick time, in seconds.", FCVAR_NOTIFY|FCVAR_REPLICATED);
	cv_BotsCanBeSurvivor = CreateConVar("rf2_bots_join_survivors", "0", "Whether or not bots are allowed to become survivors. Not recommended, generally only for testing purposes.", FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	HookConVarChange(cv_EnableAFKManager, ConVarHook_EnableAFKManager);
}

public Action Command_ReloadRF2(int client, int args)
{
	RestartGame(true);
}

public Action Command_ReloadItems(int client, int args)
{
	if (!g_bPluginEnabled)
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	LoadItems();
	RF2_ReplyToCommand(client, "All items reloaded successfully.");
	return Plugin_Handled;
}

public Action Command_EntityCount(int client, int args)
{
	int count = GetEntityCount();
	RF2_ReplyToCommand(client, "Entity Count: {lime}%i", count);
}

public Action Command_GiveItem(int client, int args)
{
	if (!g_bPluginEnabled)
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	if (args != 3)
	{
		RF2_ReplyToCommand(client, "Usage: /rf2_giveitem <player> <item index> <amount>\nNegative amounts will remove items from a player.");
		return Plugin_Handled;
	}
	char arg1[128], arg2[32], arg3[32];
	
	GetCmdArg(1, arg1, sizeof(arg1)); // player(s)
	
	GetCmdArg(2, arg2, sizeof(arg2)); // item index
	int item = StringToInt(arg2);
	
	GetCmdArg(3, arg3, sizeof(arg3)); // item amount
	int amount = StringToInt(arg3);
	
	char clientName[MAX_TARGET_LENGTH];
	char colour[32];
	int clients[MAXTF2PLAYERS];
	bool multiLanguage;
	
	int newAmount;
	char name[MAX_NAME_LENGTH];
	
	GetItemName(item, name, sizeof(name));
	GetItemQualityColourTag(item, colour, sizeof(colour));
	
	int matches = ProcessTargetString(arg1, client, clients, sizeof(clients), 0, clientName, sizeof(clientName), multiLanguage);
	if (matches < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}
	else if (matches >= 1)
	{
		for (int i = 0; i < matches; i++)
		{
			if (!IsPlayerAlive(clients[i]))
				continue;
			
			g_iPlayerItem[clients[i]][item] += amount;
			if (g_iPlayerItem[clients[i]][item] < 0)
				g_iPlayerItem[clients[i]][item] = 0;
			
			newAmount = g_iPlayerItem[clients[i]][item];
			UpdatePlayerItem(clients[i], item);
			
			if (g_iPlayerItem[clients[i]][item] > 0)
				EquipItemAsWearable(clients[i], item);
			
			RF2_PrintToChatAll("{yellow}%N{default} gave {lime}%i{default} of item %s%s{default} to {yellow}%N{default}. They now have {lime}%i{default} of the item.", 
			client, amount, colour, name, clients[i], newAmount);
		}
	}
	return Plugin_Handled;
}

public Action Command_GiveCash(int client, int args)
{
	if (args != 2)
	{
		RF2_ReplyToCommand(client, "Usage: /rf2_givecash <player> <amount>");
		return Plugin_Handled;
	}
	
	char arg1[128], arg2[32];
	
	GetCmdArg(1, arg1, sizeof(arg1)); // player(s)
	GetCmdArg(2, arg2, sizeof(arg2));
	
	float amount = StringToFloat(arg2);
	
	char clientName[MAX_TARGET_LENGTH];
	int clients[MAXTF2PLAYERS];
	bool multiLanguage;
	
	int matches = ProcessTargetString(arg1, client, clients, sizeof(clients), 0, clientName, sizeof(clientName), multiLanguage);
	if (matches < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}
	else if (matches >= 1)
	{
		for (int i = 0; i < matches; i++)
		{
			if (GetClientTeam(clients[i]) != TEAM_SURVIVOR)
			{
				RF2_ReplyToCommand(client, "%N is not a Survivor.", clients[i]);
				continue;
			}
			if (!IsPlayerAlive(clients[i]))
			{
				RF2_ReplyToCommand(client, "%N is dead.", clients[i]);
				continue;
			}
				
			g_flPlayerCash[clients[i]] += amount;
			RF2_PrintToChatAll("{yellow}%N{default} gave {lime}$%.0f{default} to %N", client, amount, clients[i]);
		}
	}
	return Plugin_Handled;
}

public Action Command_ForceMap(int client, int args)
{
	if (!g_bPluginEnabled)
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	g_bForceNextMap = true;
	char arg1[256];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (arg1[0] == '\0')
	{
		RF2_PrintToChatAll("{yellow}%N {default}cancelled the forced map change.", client);
		g_bForceNextMap = false;
		return Plugin_Handled;
	}
	else
	{
		if (RF2_IsMapValid(arg1))
		{
			FormatEx(g_szForcedMap, sizeof(g_szForcedMap), "%s", arg1);
			
			char clientName[128];
			GetClientName(client, clientName, sizeof(clientName));
			FormatEx(g_szMapForcer, sizeof(g_szMapForcer), "%s", clientName);
			
			RF2_PrintToChatAll("{yellow}%N {default}forced the next map to {yellow}%s", client, arg1);
			RF2_ReplyToCommand(client, "You can undo this by typing {yellow}/rf2_setnextmap{default} without specifying a map.");
			return Plugin_Handled;
		}
		else
		{
			RF2_ReplyToCommand(client, "%s is not a valid map.", arg1);
			return Plugin_Handled;
		}
	}
}

public Action Command_ForceWin(int client, int args)
{
	if (!g_bPluginEnabled)
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		RF2_ReplyToCommand(client, "Usage: /rf2_forcewin <red|blue>");
		return Plugin_Handled;
	}
	
	int team;
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	if (strcmp(arg1, "red") == 0)
	{
		team = view_as<int>(TFTeam_Red);
	}
	else if (strcmp(arg1, "blue") == 0)
	{
		team = view_as<int>(TFTeam_Blue);
	}
	else
	{
		RF2_ReplyToCommand(client, "Usage: /rf2_forcewin <red|blue>");
		return Plugin_Handled;
	}
	
	ForceTeamWin(team);
	return Plugin_Continue;
}

public Action Command_SkipWait(int client, int args)
{
	if (!g_bPluginEnabled)
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	if (g_bWaitingForPlayers)
		InsertServerCommand("mp_restartgame_immediate 1");
	else
		RF2_ReplyToCommand(client, "This command can only be used during the Waiting For Players sequence.");
		
	return Plugin_Handled;
}

public Action Command_SkipGracePeriod(int client, int args)
{
	if (!g_bPluginEnabled)
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	if (!g_bGracePeriod)
	{
		RF2_ReplyToCommand(client, "The grace period is not active.");
		return Plugin_Handled;
	}
	
	CreateTimer(0.0, Timer_EndGracePeriod, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}

public Action Command_AddPoints(int client, int args)
{
	if (!g_bPluginEnabled)
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	if (args != 2)
	{
		RF2_ReplyToCommand(client, "Usage: /rf2_addpoints <player> <amount>");
		return Plugin_Handled;
	}
	
	char arg1[32], arg2[32];
	
	char clientName[MAX_TARGET_LENGTH];
	int clients[MAXTF2PLAYERS];
	bool multiLanguage;
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int matches = ProcessTargetString(arg1, client, clients, sizeof(clients), 0, clientName, sizeof(clientName), multiLanguage);
	int amount = StringToInt(arg2);
	
	if (matches < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}
	else if (matches >= 1)
	{
		for (int i = 0; i < matches; i++)
		{
			g_iSurvivorPoints[clients[i]] += amount;
			RF2_PrintToChatAll("{yellow}%N{default} gave {lime}%i{default} queue points to {yellow}%N{default}.", client, amount, clients[i]);
		}
	}
	return Plugin_Handled;
}

public void ConVarHook_EnableAFKManager(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int iNewValue = StringToInt(newValue);
	if (iNewValue == 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			g_flAFKTime[i] = 0.0;
			g_bIsAFK[i] = false;
		}
	}
}