#if defined _RF2_commands_convars_included
 #endinput
#endif
#define _RF2_commands_convars_included

#pragma semicolon 1
#pragma newdecls required

bool g_bForceNextMapCommand;
char g_szForcedMap[256];
char g_szMapForcer[128];

void LoadCommandsAndCvars()
{
	RegAdminCmd("rf2_reload", Command_ReloadRF2, ADMFLAG_RCON, "Reloads the plugin. This will restart the round as well. Pass 1 to fully restart the game.");
	RegAdminCmd("rf2_fullreload", Command_FullyReloadRF2, ADMFLAG_RCON, "Reloads the plugin and changes the map to a Stage 1 map.");
	RegAdminCmd("rf2_reloaditems", Command_ReloadItems, ADMFLAG_RCON, "Reloads RF2's item config.");
	RegAdminCmd("rf2_setnextmap", Command_ForceMap, ADMFLAG_SLAY, "Forces the next map to the map specified. /rf2_setnextmap <map name>");
	RegAdminCmd("rf2_showitems", Command_ShowItems, ADMFLAG_SLAY, "Prints all items and their numerical IDs to the chat and console.");
	RegAdminCmd("rf2_giveitem", Command_GiveItem, ADMFLAG_SLAY, "Give items to a player. /rf2_giveitem <player> <item index> <amount>\nNegative amounts will remove items from a player.");
	RegAdminCmd("rf2_forcewin", Command_ForceWin, ADMFLAG_SLAY, "Forces a team to win. /rf2_forcewin <red|blue>");
	RegAdminCmd("rf2_skipwait", Command_SkipWait, ADMFLAG_SLAY, "Skips the Waiting For Players sequence. Use only if you are certain all players are fully loaded in.");
	RegAdminCmd("rf2_skipgrace", Command_SkipGracePeriod, ADMFLAG_SLAY, "Skip the grace period at the start of a round");
	RegAdminCmd("rf2_skipgraceperiod", Command_SkipGracePeriod, ADMFLAG_SLAY, "Skip the grace period at the start of a round");
	RegAdminCmd("rf2_addpoints", Command_AddPoints, ADMFLAG_SLAY, "Add queue points to a player. /rf2_addpoints <player> <amount>");
	RegAdminCmd("rf2_givecash", Command_GiveCash, ADMFLAG_SLAY, "Give cash to a RED player. /rf2_givecash <player> <amount>");
	RegAdminCmd("rf2_givexp", Command_GiveXP, ADMFLAG_SLAY, "Give XP to a RED player. /rf2_givexp <player> <amount>");
	RegAdminCmd("rf2_start_teleporter", Command_StartTeleporterEvent, ADMFLAG_SLAY, "Starts the Teleporter event.");
	RegAdminCmd("rf2_spawn_boss", Command_ForceBoss, ADMFLAG_SLAY, "Force a (non-survivor) player to become a boss.");
	RegAdminCmd("rf2_spawn_enemy", Command_ForceEnemy, ADMFLAG_SLAY, "Force a (non-survivor) player to become an enemy.");
	
	RegConsoleCmd("rf2_settings", Command_ClientSettings, "Configure your personal settings.");
	RegConsoleCmd("rf2_items", Command_Items, "Opens the Survivor item management menu. TAB+E can be used to open this menu as well.");
	RegConsoleCmd("rf2_afk", Command_AFK, "Puts you into AFK mode instantly.");
	
	g_cvAlwaysSkipWait = CreateConVar("rf2_always_skip_wait", "0", "If nonzero, always skip the Waiting For Players sequence. Great for singleplayer.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvEnableAFKManager = CreateConVar("rf2_afk_manager_enabled", "1", "If nonzero, use RF2's AFK manager to kick AFK players.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvAFKManagerKickTime = CreateConVar("rf2_afk_kick_time", "120.0", "AFK manager kick time, in seconds.", FCVAR_NOTIFY);
	g_cvAFKLimit = CreateConVar("rf2_afk_limit", "2", "How many players must be AFK before the AFK manager starts kicking.", FCVAR_NOTIFY, true, 0.0);
	g_cvAFKMinHumans = CreateConVar("rf2_afk_min_humans", "8", "How many human players must be present in the server for the AFK manager to start kicking.", FCVAR_NOTIFY, true, 0.0);
	g_cvAFKKickAdmins = CreateConVar("rf2_afk_kick_admins", "0", "Whether or not administrators of the server should be kicked by the AFK manager.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvSubDifficultyIncrement = CreateConVar("rf2_difficulty_sub_increment", "50.0", "When the difficulty coefficient reaches a multiple of this value, the sub difficulty increases.", FCVAR_NOTIFY);
	g_cvDifficultyScaleMultiplier = CreateConVar("rf2_difficulty_scale_multiplier", "1.0", "ConVar that affects difficulty scaling.", FCVAR_NOTIFY);
	g_cvBotsCanBeSurvivor = CreateConVar("rf2_survivor_allow_bots", "0", "If nonzero, bots are allowed to become survivors.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvBotWanderRecomputeDist = CreateConVar("rf2_bot_search_recompute_distance", "150.0", "When a TFBot gets this close to its wander destination, find a new destination", FCVAR_NOTIFY);
	g_cvBotWanderTime = CreateConVar("rf2_bot_wander_time", "25.0", "If a TFBot wanders for this long without reaching its destination, find a new destination", FCVAR_NOTIFY);
	g_cvBotWanderMaxDist = CreateConVar("rf2_bot_wander_max_distance", "3000.0", "How far at maximum a TFBot will search for destination areas while wandering", FCVAR_NOTIFY);
	g_cvBotWanderMinDist = CreateConVar("rf2_bot_wander_min_distance", "1000.0", "How far at minimum a TFBot will search for destination areas while wandering", FCVAR_NOTIFY);
	g_cvSurvivorHealthScale = CreateConVar("rf2_survivor_level_health_scale", "0.2", "How much a Survivor's health will increase per level, in decimal percentage.", FCVAR_NOTIFY);
	g_cvSurvivorDamageScale = CreateConVar("rf2_survivor_level_damage_scale", "0.2", "How much a Survivor's damage will increase per level, in decimal percentage.", FCVAR_NOTIFY);
	g_cvSurvivorBaseXpRequirement = CreateConVar("rf2_survivor_xp_base_requirement", "100.0", "Base XP requirement for a Survivor to level up.", FCVAR_NOTIFY, true, 1.0);
	g_cvSurvivorXpRequirementScale = CreateConVar("rf2_survivor_xp_requirement_scale", "1.5", "How much the XP requirement for a Survivor to level up will scale per level, in decimal percentage.", FCVAR_NOTIFY, true, 1.0);
	g_cvCashBurnTime = CreateConVar("rf2_enemy_cash_burn_time", "30.0", "Time in seconds that dropped cash will disappear after spawning.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyHealthScale = CreateConVar("rf2_enemy_level_health_scale", "0.05", "How much the enemy team's health will increase per level, in decimal percentage. Includes neutral enemies, such as Monoculus.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyDamageScale = CreateConVar("rf2_enemy_level_damage_scale", "0.05", "How much the enemy team's damage will increase per level, in decimal percentage. Includes neutral enemies, such as Monoculus.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyXPDropScale = CreateConVar("rf2_enemy_xp_drop_scale", "0.15", "How much enemy XP drops scale per level.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyCashDropScale = CreateConVar("rf2_enemy_cash_drop_scale", "0.15", "How much enemy cash drops scale per level.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyMinSpawnDistance = CreateConVar("rf2_enemy_spawn_min_distance", "1000.0", "The minimum distance an enemy can spawn in relation to Survivors.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyMaxSpawnDistance = CreateConVar("rf2_enemy_spawn_max_distance", "2000.0", "The maximum distance an enemy can spawn in relation to Survivors.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyMaxSpawnWaveCount = CreateConVar("rf2_enemy_spawn_max_count", "8", "The absolute maximum amount of enemies that can spawn in a single spawn wave.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyMinSpawnWaveTime = CreateConVar("rf2_enemy_spawn_min_wave_time", "6.0", "The minimum amount of time that must pass between enemy spawn waves.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyBaseSpawnWaveTime = CreateConVar("rf2_enemy_spawn_base_wave_time", "25.0", "The base amount of time that passes between spawn waves. Affected by many different factors.", FCVAR_NOTIFY, true, 0.1);
	g_cvBossStabDamageType = CreateConVar("rf2_boss_backstab_damage_type", "0", "Determines how bosses take backstab damage. 0 - raw damage. 1 - percentage.\nBoth benefit from any damage bonuses, excluding crits.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvBossStabDamagePercent = CreateConVar("rf2_boss_backstab_damage_percentage", "0.12", "If rf2_boss_backstab_damage_type is 1, how much health, in decimal percentage, is subtracted from the boss upon backstab.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvBossStabDamageAmount = CreateConVar("rf2_boss_backstab_damage_amount", "750.0", "If rf2_boss_backstab_damage_type is 0, the base damage that is dealt to a boss upon backstab.", FCVAR_NOTIFY, true, 0.0);
	g_cvTeleporterRadiusMultiplier = CreateConVar("rf2_object_teleporter_radius_multiplier", "1.0", "How much to multiply the size of the Teleporter radius size.", FCVAR_NOTIFY, true, 0.01);
	g_cvMaxObjects = CreateConVar("rf2_object_max", "150", "The maximum number of objects allowed to spawn. Does not include Teleporters or Altars.", FCVAR_NOTIFY, true, 0.0);
	g_cvObjectSpreadDistance = CreateConVar("rf2_object_spread_distance", "80.0", "The minimum distance that spawned objects must be spread apart from eachother.", FCVAR_NOTIFY, true, 0.0);
	g_cvObjectBaseCount = CreateConVar("rf2_object_base_count", "12", "The base amount of objects that will be spawned. Scales based on player count and the difficulty.", FCVAR_NOTIFY, true, 0.0);
	g_cvObjectBaseCost = CreateConVar("rf2_object_base_cost", "50.0", "The base cost to use objects such as crates. Scales with the difficulty.", FCVAR_NOTIFY, true, 0.0);
	g_cvItemShareEnabled = CreateConVar("rf2_item_share_enabled", "0", "Whether or not to enable item sharing. This prevents Survivors from hogging items in multiplayer.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvTankBaseHealth = CreateConVar("rf2_tank_base_health", "25000", "The base health value of a Tank.", FCVAR_NOTIFY, true, 1.0);
	g_cvTankHealthScale = CreateConVar("rf2_tank_health_scale", "0.2", "How much a Tank's health will scale per enemy level, in decimal percentage.");
	g_cvTankBaseSpeed = CreateConVar("rf2_tank_base_speed", "75.0", "The base speed value of a Tank. Increased on Steel and Titanium difficulties.", FCVAR_NOTIFY, true, 0.0);
	g_cvTankSpeedBoost = CreateConVar("rf2_tank_speed_boost", "1.5", "When a Tank falls below 50 percent health, speed it up by this much", FCVAR_NOTIFY, true, 1.0);
	g_cvSurvivorQuickBuild = CreateConVar("rf2_survivor_quick_build", "1", "If nonzero, Survivor team Engineer buildings will deploy instantly", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvEnemyQuickBuild = CreateConVar("rf2_enemy_quick_build", "1", "If nonzero, enemy team Engineer buildings will deploy instantly", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvMeleeCritChanceBonus = CreateConVar("rf2_melee_crit_chance_bonus", "2.0", "Critical hit chance bonus for melee weapons.", FCVAR_NOTIFY, true, 0.0);
	g_cvEngiMetalRegenInterval = CreateConVar("rf2_engineer_metal_regen_interval", "2.5", "Interval in seconds that an Engineer will regenerate metal, -1.0 to disable", FCVAR_NOTIFY);
	g_cvEngiMetalRegenAmount = CreateConVar("rf2_engineer_metal_regen_amount", "50", "How much metal an Engineer will regen per interval lapse", FCVAR_NOTIFY, true, 0.0);
	
	// Debug
	RegAdminCmd("rf2_debug_entitycount", Command_EntityCount, ADMFLAG_SLAY, "Shows the total number of networked entities (edicts) in the server.");
	RegAdminCmd("rf2_debug_thriller_test", Command_ThrillerTest, ADMFLAG_SLAY, "\"Darkness falls across the land, the dancing hour is close at hand...\"");
	g_cvDebugNoMapChange = CreateConVar("rf2_debug_skip_map_change", "0", "If nonzero, prevents the map from changing on round end.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvDebugShowObjectSpawns = CreateConVar("rf2_debug_show_object_spawns", "0", "If nonzero, when an object spawns, its name and location will be printed to the console.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvDebugDontEndGame = CreateConVar("rf2_debug_dont_end_game", "0", "If nonzero, don't end the game if all of the survivors die.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvDebugShowDifficultyCoeff = CreateConVar("rf2_debug_show_difficulty_coeff", "0", "If nonzero, shows the value of the difficulty coefficient.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	HookConVarChange(g_cvEnableAFKManager, ConVarHook_EnableAFKManager);
}

public Action Command_ReloadRF2(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	ReloadPlugin(false);
	return Plugin_Handled;
}

public Action Command_FullyReloadRF2(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	ReloadPlugin(true);
	return Plugin_Handled;
}

public Action Command_ReloadItems(int client, int args)
{
	if (!RF2_IsEnabled())
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
	int count;
	for (int i = 0; i <= MAX_EDICTS; i++)
	{
		if (IsValidEntity(i))
			count++;
	}
	
	RF2_ReplyToCommand(client, "Entity Count: {lime}%i", count);
	return Plugin_Handled;
}

public Action Command_GiveItem(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "Wait for the round to start.");
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
	if (item >= Item_MaxValid || item <= Item_Null)
	{
		RF2_ReplyToCommand(client, "Item %i doesn't exist. Type /rf2_showitems to get a list of items printed to your console.", item);
		return Plugin_Handled;
	}
	
	GetCmdArg(3, arg3, sizeof(arg3)); // item amount
	int amount = StringToInt(arg3);
	if (amount == 0)
	{
		RF2_ReplyToCommand(client, "You need to specify an amount other than 0, stupid.");
		return Plugin_Handled;
	}
	
	char clientName[MAX_TARGET_LENGTH];
	char colour[32];
	int clients[MAXTF2PLAYERS];
	bool multiLanguage;
	int newAmount;
	char name[PLATFORM_MAX_PATH];
	
	GetItemName(item, name, sizeof(name));
	GetQualityColorTag(g_iItemQuality[item], colour, sizeof(colour));
	
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
			
			GiveItem(clients[i], item, amount);
			newAmount = g_iPlayerItem[clients[i]][item];
			
			if (GetItemQuality(item) == Quality_Strange)
			{
				RF2_PrintToChatAll("{yellow}%N{default} gave item %s%s{default} to {yellow}%N{default}.", 
				client, colour, name, clients[i]);
			}
			else
			{
				RF2_PrintToChatAll("{yellow}%N{default} gave {lime}%i{default} of item %s%s{default} to {yellow}%N{default}. They now have {lime}%i{default} of the item.", 
				client, amount, colour, name, clients[i], newAmount);
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_GiveCash(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "Wait for the round to start.");
		return Plugin_Handled;
	}
	
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
			RF2_PrintToChatAll("{yellow}%N{default} gave {lime}$%.0f{default} to {yellow}%N", client, amount, clients[i]);
		}
	}
	return Plugin_Handled;
}

public Action Command_GiveXP(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "Wait for the round to start.");
		return Plugin_Handled;
	}
	
	if (args != 2)
	{
		RF2_ReplyToCommand(client, "Usage: /rf2_givexp <player> <amount>");
		return Plugin_Handled;
	}
	
	char arg1[128], arg2[32];
	
	GetCmdArg(1, arg1, sizeof(arg1)); // player(s)
	GetCmdArg(2, arg2, sizeof(arg2));
	
	float amount = StringToFloat(arg2);
	if (amount <= 0)
	{
		RF2_ReplyToCommand(client, "Please specify an amount above 0.");
		return Plugin_Handled;
	}
	
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
			if (!IsPlayerSurvivor(clients[i]))
			{
				RF2_ReplyToCommand(client, "%N is not a Survivor.", clients[i]);
				continue;
			}
			if (!IsPlayerAlive(clients[i]))
			{
				RF2_ReplyToCommand(client, "%N is dead.", clients[i]);
				continue;
			}
			
			UpdatePlayerXP(clients[i], amount);
			RF2_PrintToChatAll("{yellow}%N{default} gave {cyan}%.0f{default} XP to {yellow}%N", client, amount, clients[i]);
		}
	}
	return Plugin_Handled;
}

public Action Command_ForceMap(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	g_bForceNextMapCommand = true;
	char arg1[256];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (!arg1[0])
	{
		RF2_PrintToChatAll("{yellow}%N {default}cancelled the forced map change.", client);
		g_bForceNextMapCommand = false;
		return Plugin_Handled;
	}
	else
	{
		if (RF2_IsMapValid(arg1))
		{
			strcopy(g_szForcedMap, sizeof(g_szForcedMap), arg1);
			
			char clientName[128];
			GetClientName(client, clientName, sizeof(clientName));
			strcopy(g_szMapForcer, sizeof(g_szMapForcer), clientName);
			
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
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "Wait for the round to start.");
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
		g_bStageCleared = true;
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
	
	if (team == TEAM_SURVIVOR)
	{
		ForceTeamWin(team);
	}
	else
	{
		GameOver();
	}
	
	return Plugin_Continue;
}

public Action Command_SkipWait(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	if (g_bWaitingForPlayers)
		InsertServerCommand("mp_restartgame_immediate 1");
	else
		RF2_ReplyToCommand(client, "The Waiting For Players sequence is not active.");
		
	return Plugin_Handled;
}

public Action Command_SkipGracePeriod(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "Wait for the round to start.");
		return Plugin_Handled;
	}
	
	if (!g_bGracePeriod)
	{
		RF2_ReplyToCommand(client, "The grace period is not active.");
		return Plugin_Handled;
	}
	
	EndGracePeriod();
	RF2_ReplyToCommand(client, "The grace period has been skipped.");
	
	return Plugin_Handled;
}

public Action Command_AddPoints(int client, int args)
{
	if (!RF2_IsEnabled())
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
			g_iPlayerSurvivorPoints[clients[i]] += amount;
			if (g_iPlayerSurvivorPoints[clients[i]] < 0)
				g_iPlayerSurvivorPoints[clients[i]] = 0;
				
			RF2_PrintToChatAll("{yellow}%N{default} gave {lime}%i{default} queue points to {yellow}%N{default}.", client, amount, clients[i]);
		}
	}
	
	return Plugin_Handled;
}

public Action Command_ShowItems(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	char name[MAX_NAME_LENGTH];
	char qualityName[32];
	
	for (int i = 1; i < Item_MaxValid; i++)
	{
		GetItemName(i, name, sizeof(name));
		GetQualityName(GetItemQuality(i), qualityName, sizeof(qualityName));
		
		if (!name[0])
			name = "NULL";
		
		if (client == 0)
		{
			PrintToServer("[%i] %s (%s)", i, name, qualityName);
		}
		else
		{
			// PrintToConsole() messages are sent via the unreliable network channel, causing them to be printed out of order. 
			// So unfortunately, we have to spam the client's chat. Oh well.
			PrintToChat(client, "[%i] %s (%s)", i, name, qualityName);
		}
	}
	
	return Plugin_Handled;
}

public Action Command_StartTeleporterEvent(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "Wait for the round to start.");
		return Plugin_Handled;
	}
	
	if (g_bTankBossMode || g_bTeleporterEvent || g_bTeleporterEventCompleted)
	{
		RF2_ReplyToCommand(client, "This can't be used right now!");
		return Plugin_Handled;
	}
	
	if (g_bGracePeriod)
	{
		EndGracePeriod();
	}
	
	g_iTeleporterActivator = GetClientUserId(client);
	PrepareTeleporterEvent();
	return Plugin_Handled;
}

public Action Command_ThrillerTest(int client, int args)
{
	if (client < 0)
	{
		ReplyToCommand(client, "This command can only be used in-game.");
		return Plugin_Handled;
	}
	
	float eyePos[3];
	GetClientEyePosition(client, eyePos);
	StartThrillerDance(eyePos);
	return Plugin_Handled;
}

public Action Command_ForceBoss(int client, int args)
{
	if (GetBossCount() <= 0)
	{
		RF2_ReplyToCommand(client, "There are no bosses loaded!");
		return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1);

	if (target == -1)
	{
		ReplyToTargetError(client, COMMAND_TARGET_NONE);
	}
	else if (IsPlayerSurvivor(target))
	{
		RF2_ReplyToCommand(client, "You can't use this on a Survivor.");
	}
	else
	{
		ShowBossSpawnMenu(client, target);
	}
	
	return Plugin_Handled;
}

public Action Command_ForceEnemy(int client, int args)
{
	if (GetEnemyCount() <= 0)
	{
		RF2_ReplyToCommand(client, "There are no enemies loaded!");
		return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1);

	if (target == -1)
	{
		ReplyToTargetError(client, COMMAND_TARGET_NONE);
	}
	else if (IsPlayerSurvivor(target))
	{
		RF2_ReplyToCommand(client, "You can't use this on a Survivor.");
	}
	else
	{
		ShowEnemySpawnMenu(client, target);
	}
	
	return Plugin_Handled;	
}

void ShowBossSpawnMenu(int client, int target)
{
	Menu menu = CreateMenu(Menu_SpawnBoss);
	char buffer[128];
	char info[16];
	char bossName[256];
	
	SetMenuTitle(menu, "Spawn %N as...", target);
	for (int i = 0; i < GetBossCount(); i++)
	{
		GetBossName(i, bossName, sizeof(bossName));
		strcopy(buffer, sizeof(buffer), bossName);
		FormatEx(info, sizeof(info), "%i;%i_", target, i);
		AddMenuItem(menu, info, buffer);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int Menu_SpawnBoss(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			char buffer[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			SplitString(info, ";", buffer, sizeof(buffer));
			
			int client = StringToInt(buffer);
			ReplaceStringEx(info, sizeof(info), buffer, "");
			ReplaceStringEx(info, sizeof(info), ";", "");
			
			if (!IsValidClient(client) || IsPlayerSurvivor(client))
			{
				RF2_PrintToChat(param1, "Your target has either disconnected or become a Survivor.");
			}
			else
			{
				SplitString(info, "_", buffer, sizeof(buffer));
				int type = StringToInt(buffer);
				char bossName[256];
				
				RefreshClient(client);
				SpawnBoss(client, type, param1, true);
				GetBossName(type, bossName, sizeof(bossName));
				RF2_PrintToChat(param1, "Spawned %N as boss: %s", client, bossName);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

void ShowEnemySpawnMenu(int client, int target)
{
	Menu menu = CreateMenu(Menu_SpawnEnemy);
	char buffer[128];
	char info[16];
	char enemyName[256];
	
	SetMenuTitle(menu, "Spawn %N as...", target);
	for (int i = 0; i < GetEnemyCount(); i++)
	{
		GetEnemyName(i, enemyName, sizeof(enemyName));
		strcopy(buffer, sizeof(buffer), enemyName);
		FormatEx(info, sizeof(info), "%i;%i_", target, i);
		AddMenuItem(menu, info, buffer);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}

public int Menu_SpawnEnemy(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			char buffer[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			SplitString(info, ";", buffer, sizeof(buffer));
			
			int client = StringToInt(buffer);
			ReplaceStringEx(info, sizeof(info), buffer, "");
			ReplaceStringEx(info, sizeof(info), ";", "");
			
			if (!IsValidClient(client) || IsPlayerSurvivor(client))
			{
				RF2_PrintToChat(param1, "Your target has either disconnected or become a Survivor.");
			}
			else
			{
				SplitString(info, "_", buffer, sizeof(buffer));
				int type = StringToInt(buffer);
				char enemyName[256];
				
				RefreshClient(client);
				SpawnEnemy(client, type, param1, true);
				GetEnemyName(type, enemyName, sizeof(enemyName));
				RF2_PrintToChat(param1, "Spawned %N as enemy: %s", client, enemyName);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public Action Command_AFK(int client, int args)
{
	if (client == 0)
	{
		RF2_ReplyToCommand(client, "This command can only be used in-game.");
		return Plugin_Handled;
	}
	
	if (IsSingleplayer())
	{
		RF2_ReplyToCommand(client, "You can't use this in singleplayer!");
		return Plugin_Handled;
	}
	
	if (IsPlayerAFK(client))
	{
		return Plugin_Handled;
	}
	
	if (IsTeleporterBoss(client))
	{
		RF2_ReplyToCommand(client, "You cannot use this as a Teleporter boss.");
		return Plugin_Handled;
	}
	
	if (IsPlayerSurvivor(client))
	{
		if (g_bGracePeriod)
		{
			FakeClientCommand(client, "explode");
			ReshuffleSurvivor(client, view_as<int>(TFTeam_Unassigned));
		}
		else
		{
			RF2_ReplyToCommand(client, "You cannot use this as a Survivor after the grace period.");
			return Plugin_Handled;
		}
	}
	else
	{
		
	}
	
	g_bPlayerIsAFK[client] = true;
	OnPlayerEnterAFK(client);
	return Plugin_Handled;
}

public Action Command_ClientSettings(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	if (client == 0)
	{
		ReplyToCommand(client, "This command can only be used in-game.");
		return Plugin_Handled;
	}
	
	ShowClientSettingsMenu(client);
	return Plugin_Handled;
}

void ShowClientSettingsMenu(int client)
{
	Handle menu = CreateMenu(Menu_ClientSettings);
	char buffer[128];
	SetMenuTitle(menu, "Risk Fortress 2 Settings");
	
	FormatEx(buffer, sizeof(buffer), "Toggle becoming a Survivor (%s)", g_bPlayerBecomeSurvivor[client] ? "ON" : "OFF");
	AddMenuItem(menu, "survivor_pref", buffer);
	
	FormatEx(buffer, sizeof(buffer), "Toggle becoming a Teleporter boss (%s)", g_bPlayerBecomeBoss[client] ? "ON" : "OFF");
	AddMenuItem(menu, "boss_pref", buffer);
	
	FormatEx(buffer, sizeof(buffer), "Toggle music (%s)", g_bPlayerMusicEnabled[client] ? "ON" : "OFF");
	AddMenuItem(menu, "music_pref", buffer);
	
	FormatEx(buffer, sizeof(buffer), "Enable automatic item menu (%s)", g_bPlayerAutomaticItemMenu[client] ? "ON" : "OFF");
	AddMenuItem(menu, "itemmenu_pref", buffer);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int Menu_ClientSettings(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[64];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			if (strcmp(info, "survivor_pref") == 0)
			{
				if (g_bPlayerBecomeSurvivor[param1])
				{
					g_bPlayerBecomeSurvivor[param1] = false;
					SetClientCookie(param1, g_coBecomeSurvivor, "0");
				}
				else
				{
					g_bPlayerBecomeSurvivor[param1] = true;
					SetClientCookie(param1, g_coBecomeSurvivor, "1");
				}
			}
			else if (strcmp(info, "boss_pref") == 0)
			{
				if (g_bPlayerBecomeBoss[param1])
				{
					g_bPlayerBecomeBoss[param1] = false;
					SetClientCookie(param1, g_coBecomeBoss, "0");
				}
				else
				{
					g_bPlayerBecomeBoss[param1] = true;
					SetClientCookie(param1, g_coBecomeBoss, "1");
				}
			}
			else if (strcmp(info, "music_pref") == 0)
			{
				if (g_bPlayerMusicEnabled[param1])
				{
					g_bPlayerMusicEnabled[param1] = false;
					SetClientCookie(param1, g_coMusicEnabled, "0");
					StopMusicTrack(param1);
				}
				else
				{
					g_bPlayerMusicEnabled[param1] = true;
					SetClientCookie(param1, g_coMusicEnabled, "1");
					
					if (g_bRoundActive)
					{
						PlayMusicTrack(param1);
					}
				}
			}
			else if (strcmp(info, "itemmenu_pref") == 0)
			{
				if (g_bPlayerAutomaticItemMenu[param1])
				{
					g_bPlayerAutomaticItemMenu[param1] = false;
					SetClientCookie(param1, g_coAutomaticItemMenu, "0");
				}
				else
				{
					g_bPlayerAutomaticItemMenu[param1] = true;
					SetClientCookie(param1, g_coAutomaticItemMenu, "1");
				}
			}
			
			ShowClientSettingsMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public Action Command_Items(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "RF2 is currently disabled.");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "Wait for the round to start.");
		return Plugin_Handled;
	}
	
	if (client == 0)
	{
		ReplyToCommand(client, "This command can only be used in-game.");
		return Plugin_Handled;
	}
	
	if (!IsPlayerSurvivor(client))
	{
		RF2_ReplyToCommand(client, "You are not a Survivor.");
		return Plugin_Handled;
	}
	
	ShowItemMenu(client);
	return Plugin_Handled;
}

void ShowItemMenu(int client)
{
	if (!IsPlayerSurvivor(client))
		return;
	
	Handle menu = CreateMenu(Menu_Items);
	char buffer[128];
	char info[16];
	char itemName[PLATFORM_MAX_PATH];
	int itemCount;
	SetMenuTitle(menu, "Your Items (select to drop)");
	
	for (int i = 1; i < Item_MaxValid; i++)
	{
		if (g_iPlayerItem[client][i] > 0 || GetItemQuality(i) == Quality_Strange && g_iPlayerStrangeItem[client] == i)
		{
			itemCount++;
			GetItemName(i, itemName, sizeof(itemName));
			IntToString(i, info, sizeof(info));
			
			if (GetItemQuality(i) == Quality_Strange)
			{
				FormatEx(buffer, sizeof(buffer), "%s [STRANGE]", itemName);
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%s [%i]", itemName, g_iPlayerItem[client][i]);
			}
			
			AddMenuItem(menu, info, buffer);
		}
	}
	
	if (itemCount == 0)
	{
		AddMenuItem(menu, "no_items", "You have no items.");
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	g_bPlayerViewingItemMenu[client] = true;
}

public int Menu_Items(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Display:
		{
			g_bPlayerViewingItemMenu[param1] = true;
		}
		case MenuAction_Select:
		{
			bool refresh = true;
			char info[16];
			GetMenuItem(menu, param2, info, sizeof(info));
			if (strcmp(info, "no_items") != 0)
			{
				int humanCount = GetPlayersOnTeam(TEAM_SURVIVOR, true, true);
				int item = StringToInt(info);
				
				// Drop the item if there are no other human players on our team.
				if (humanCount == 1)
				{
					float pos[3];
					GetClientAbsOrigin(param1, pos);
					pos[2] += 25.0;
					DropItem(param1, item, pos);
				}
				else // We ask the client who to drop the item for, so others don't swoop in and steal it.
				{
					refresh = false;
					ShowItemDropMenu(param1, item);
				}
			}
			
			if (refresh)
			{
				ShowItemMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			g_bPlayerViewingItemMenu[param1] = false;
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

void ShowItemDropMenu(int client, int item)
{
	Handle menu = CreateMenu(Menu_ItemDrop);
	char info[64];
	char itemName[PLATFORM_MAX_PATH];
	char clientName[MAX_NAME_LENGTH];
	
	GetItemName(item, itemName, sizeof(itemName));
	SetMenuTitle(menu, "Drop for who? (%s [%i])", itemName, g_iPlayerItem[client][item]);
	FormatEx(info, sizeof(info), "%i_0", item);
	AddMenuItem(menu, info, "Don't care"); // + didn't ask + L + ratio + cope + seethe + mald + cancelled + blocked + reported + stay mad
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client || !IsClientInGameEx(i) || !IsPlayerAlive(i))
			continue;
			
		if (IsPlayerSurvivor(i))
		{
			FormatEx(info, sizeof(info), "%i_%i", item, GetClientUserId(i));
			GetClientName(i, clientName, sizeof(clientName));
			AddMenuItem(menu, info, clientName);
		}
	}
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, false);
	CancelClientMenu(client);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int Menu_ItemDrop(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[64];
			char itemIndex[8];
			float pos[3];
			GetClientAbsOrigin(param1, pos);
			pos[2] += 25.0;
			
			GetMenuItem(menu, param2, info, sizeof(info));
			SplitString(info, "_", itemIndex, sizeof(itemIndex));
			ReplaceStringEx(info, sizeof(info), itemIndex, ""); // Client userid
			ReplaceStringEx(info, sizeof(info), "_", ""); // Item index
			ReplaceStringEx(itemIndex, sizeof(itemIndex), "_", ""); // Item index
			int item = StringToInt(itemIndex); 
			
			if (StringToInt(info) == 0) // 0 means we don't care
			{
				DropItem(param1, item, pos);
			}
			else
			{
				int client = GetClientOfUserId(StringToInt(info));
				if (client == 0 || !IsPlayerSurvivor(client))
				{
					RF2_PrintToChat(param1, "That player has disconnected or is no longer a Survivor.");
				}
				else
				{
					DropItem(param1, item, pos, client);
					RF2_PrintToChat(param1, "Dropped item for player {yellow}%N{default}.", client);
				}
			}
			
			if (g_iPlayerItem[param1][item] > 0)
				ShowItemDropMenu(param1, item);
			else
				ShowItemMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowItemMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public void ConVarHook_EnableAFKManager(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int iNewValue = StringToInt(newValue);
	if (iNewValue == 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			g_flPlayerAFKTime[i] = 0.0;
			g_bPlayerIsAFK[i] = false;
		}
	}
}