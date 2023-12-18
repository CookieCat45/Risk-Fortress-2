#if defined _RF2_commands_convars_included
 #endinput
#endif
#define _RF2_commands_convars_included

#pragma semicolon 1
#pragma newdecls required

bool g_bForceNextMapCommand;
char g_szForcedMap[256];
char g_szMapForcerName[MAX_NAME_LENGTH];

void LoadCommandsAndCvars()
{
	RegAdminCmd("rf2_reload", Command_ReloadRF2, ADMFLAG_ROOT, "Reloads the plugin and restarts the game (without changing the map).");
	RegAdminCmd("rf2_fullreload", Command_FullyReloadRF2, ADMFLAG_ROOT, "Reloads the plugin, restarts the game and changes the map to a Stage 1 map.");
	RegAdminCmd("rf2_reloaditems", Command_ReloadItems, ADMFLAG_ROOT, "Reloads all items.");
	RegAdminCmd("rf2_giveitem", Command_GiveItem, ADMFLAG_SLAY, "Give items to a player. /rf2_giveitem <player> <item name> <amount>\nNegative amounts will remove items from a player.");
	RegAdminCmd("rf2_giveallitems", Command_GiveAllItems, ADMFLAG_ROOT, "Gives a player every item in the game! /rf2_giveallitems <player> <amount>");
	RegAdminCmd("rf2_forcewin", Command_ForceWin, ADMFLAG_SLAY, "Forces a team to win. /rf2_forcewin <red|blue>");
	RegAdminCmd("rf2_skipwait", Command_SkipWait, ADMFLAG_SLAY, "Skips the Waiting For Players sequence.");
	RegAdminCmd("rf2_skipgrace", Command_SkipGracePeriod, ADMFLAG_SLAY, "Skip the grace period at the start of a round");
	RegAdminCmd("rf2_skipgraceperiod", Command_SkipGracePeriod, ADMFLAG_SLAY, "Skip the grace period at the start of a round");
	RegAdminCmd("rf2_addpoints", Command_AddPoints, ADMFLAG_SLAY, "Add queue points to a player. /rf2_addpoints <player> <amount>");
	RegAdminCmd("rf2_givecash", Command_GiveCash, ADMFLAG_SLAY, "Give cash to a RED player. /rf2_givecash <player> <amount>");
	RegAdminCmd("rf2_givexp", Command_GiveXP, ADMFLAG_SLAY, "Give XP to a RED player. /rf2_givexp <player> <amount>");
	RegAdminCmd("rf2_start_teleporter", Command_StartTeleporterEvent, ADMFLAG_SLAY, "Starts the Teleporter event.");
	RegAdminCmd("rf2_spawn_boss", Command_ForceBoss, ADMFLAG_SLAY, "Force a (non-survivor) player to become a boss. /rf2_spawn_boss <player>");
	RegAdminCmd("rf2_spawn_enemy", Command_ForceEnemy, ADMFLAG_SLAY, "Force a (non-survivor) player to become an enemy. /rf2_spawn_enemy <player>");
	RegAdminCmd("rf2_set_difficulty", Command_SetDifficulty, ADMFLAG_SLAY, "Sets the difficulty level. 0 = Scrap, 1 = Iron, 2 = Steel, 3 = Titanium");
	RegAdminCmd("rf2_setnextmap", Command_ForceMap, ADMFLAG_SLAY, "Forces the next map to be the map specified. This will not immediately change the map.");
	RegAdminCmd("rf2_make_survivor", Command_MakeSurvivor, ADMFLAG_SLAY, "Force a player to become a Survivor.\nWill not work if the maximum survivor count has been reached.");
	RegAdminCmd("rf2_addseconds", Command_AddSeconds, ADMFLAG_SLAY, "Add seconds to the difficulty timer. /rf2_addseconds <seconds>");
	
	RegConsoleCmd("rf2_settings", Command_ClientSettings, "Configure your personal settings.");
	RegConsoleCmd("rf2_items", Command_Items, "Opens the Survivor item management menu. TAB+E can be used to open this menu as well.");
	RegConsoleCmd("rf2_afk", Command_AFK, "Puts you into AFK mode instantly.");
	RegConsoleCmd("rf2_endlevel", Command_EndLevel, "Starts the vote to end the level in Tank Destruction mode.");
	RegConsoleCmd("rf2_reset_tutorial", Command_ResetTutorial, "Resets the tutorial.");
	
	char buffer[8];
	IntToString(MaxClients, buffer, sizeof(buffer));
	//g_cvMaxHumanPlayers = CreateConVar("rf2_human_player_limit", buffer, "Max number of human players allowed in the server.", FCVAR_NOTIFY, true, 1.0, true, float(MaxClients));
	
	IntToString(MAX_SURVIVORS, buffer, sizeof(buffer));
	g_cvMaxSurvivors = CreateConVar("rf2_max_survivors", buffer, "Max number of Survivors that can be in the game.", FCVAR_NOTIFY, true, 1.0, true, float(MAX_SURVIVORS));
	
	g_cvAlwaysSkipWait = CreateConVar("rf2_always_skip_wait", "0", "If nonzero, always skip the Waiting For Players sequence. Great for singleplayer.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvEnableAFKManager = CreateConVar("rf2_afk_manager_enabled", "1", "If nonzero, use RF2's AFK manager to kick AFK players.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvAFKManagerKickTime = CreateConVar("rf2_afk_kick_time", "200.0", "AFK manager kick time, in seconds.", FCVAR_NOTIFY);
	g_cvAFKLimit = CreateConVar("rf2_afk_limit", "2", "How many players must be AFK before the AFK manager starts kicking.", FCVAR_NOTIFY, true, 0.0);
	g_cvAFKMinHumans = CreateConVar("rf2_afk_min_humans", "8", "How many human players must be present in the server for the AFK manager to start kicking.", FCVAR_NOTIFY, true, 0.0);
	g_cvAFKKickAdmins = CreateConVar("rf2_afk_kick_admins", "0", "Whether or not administrators of the server should be kicked by the AFK manager.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvSubDifficultyIncrement = CreateConVar("rf2_difficulty_sub_increment", "50.0", "When the difficulty coefficient reaches a multiple of this value, the sub difficulty increases.", FCVAR_NOTIFY);
	g_cvDifficultyScaleMultiplier = CreateConVar("rf2_difficulty_scale_multiplier", "1.0", "Accelerate difficulty scaling by this value.", FCVAR_NOTIFY);
	g_cvBotsCanBeSurvivor = CreateConVar("rf2_survivor_allow_bots", "0", "If nonzero, bots are allowed to become survivors.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvBotWanderRecomputeDist = CreateConVar("rf2_bot_search_recompute_distance", "150.0", "When a TFBot gets this close to its wander destination, find a new destination", FCVAR_NOTIFY);
	g_cvBotWanderTime = CreateConVar("rf2_bot_wander_time", "25.0", "If a TFBot wanders for this long without reaching its destination, find a new destination", FCVAR_NOTIFY);
	g_cvBotWanderMaxDist = CreateConVar("rf2_bot_wander_max_distance", "3000.0", "How far at maximum a TFBot will search for destination areas while wandering", FCVAR_NOTIFY);
	g_cvBotWanderMinDist = CreateConVar("rf2_bot_wander_min_distance", "1000.0", "How far at minimum a TFBot will search for destination areas while wandering", FCVAR_NOTIFY);
	g_cvSurvivorHealthScale = CreateConVar("rf2_survivor_level_health_scale", "0.12", "How much a Survivor's health will increase per level, in decimal percentage.", FCVAR_NOTIFY);
	g_cvSurvivorDamageScale = CreateConVar("rf2_survivor_level_damage_scale", "0.12", "How much a Survivor's damage will increase per level, in decimal percentage.", FCVAR_NOTIFY);
	g_cvSurvivorBaseXpRequirement = CreateConVar("rf2_survivor_xp_base_requirement", "100.0", "Base XP requirement for a Survivor to level up.", FCVAR_NOTIFY, true, 1.0);
	g_cvSurvivorXpRequirementScale = CreateConVar("rf2_survivor_xp_requirement_scale", "1.5", "How much the XP requirement for a Survivor to level up will scale per level, in decimal percentage.", FCVAR_NOTIFY, true, 1.0);
	g_cvCashBurnTime = CreateConVar("rf2_enemy_cash_burn_time", "30.0", "Time in seconds that dropped cash will disappear after spawning.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyHealthScale = CreateConVar("rf2_enemy_level_health_scale", "0.08", "How much the enemy team's health will increase per level, in decimal percentage. Includes neutral enemies, such as Monoculus.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyDamageScale = CreateConVar("rf2_enemy_level_damage_scale", "0.04", "How much the enemy team's damage will increase per level, in decimal percentage. Includes neutral enemies, such as Monoculus.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyXPDropScale = CreateConVar("rf2_enemy_xp_drop_scale", "0.15", "How much enemy XP drops scale per level.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyCashDropScale = CreateConVar("rf2_enemy_cash_drop_scale", "0.15", "How much enemy cash drops scale per level.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyMinSpawnDistance = CreateConVar("rf2_enemy_spawn_min_distance", "1000.0", "The minimum distance an enemy can spawn in relation to Survivors.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyMaxSpawnDistance = CreateConVar("rf2_enemy_spawn_max_distance", "3000.0", "The maximum distance an enemy can spawn in relation to Survivors.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyMinSpawnWaveCount = CreateConVar("rf2_enemy_spawn_min_count", "3", "The absolute minimum number of enemies that can spawn in a single spawn wave.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyMaxSpawnWaveCount = CreateConVar("rf2_enemy_spawn_max_count", "7", "The absolute maximum amount of enemies that can spawn in a single spawn wave.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyMinSpawnWaveTime = CreateConVar("rf2_enemy_spawn_min_wave_time", "2.0", "The minimum amount of time that must pass between enemy spawn waves.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyBaseSpawnWaveTime = CreateConVar("rf2_enemy_spawn_base_wave_time", "30.0", "The base amount of time that passes between spawn waves. Affected by many different factors.", FCVAR_NOTIFY, true, 0.1);
	g_cvBossStabDamageType = CreateConVar("rf2_boss_backstab_damage_type", "0", "Determines how bosses take backstab damage. 0 - raw damage. 1 - percentage.\nBoth benefit from any damage bonuses, excluding crits.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvBossStabDamagePercent = CreateConVar("rf2_boss_backstab_damage_percentage", "0.12", "If rf2_boss_backstab_damage_type is 1, how much health, in decimal percentage, is subtracted from the boss upon backstab.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvBossStabDamageAmount = CreateConVar("rf2_boss_backstab_damage_amount", "750.0", "If rf2_boss_backstab_damage_type is 0, the base damage that is dealt to a boss upon backstab.", FCVAR_NOTIFY, true, 0.0);
	g_cvTeleporterRadiusMultiplier = CreateConVar("rf2_object_teleporter_radius_multiplier", "1.0", "How much to multiply the size of the Teleporter radius.", FCVAR_NOTIFY, true, 0.01);
	g_cvMaxObjects = CreateConVar("rf2_object_max", "90", "The maximum number of objects allowed to spawn. Does not include Teleporters or Altars.", FCVAR_NOTIFY, true, 0.0);
	g_cvObjectSpreadDistance = CreateConVar("rf2_object_spread_distance", "80.0", "The minimum distance that spawned objects must be spread apart from eachother.", FCVAR_NOTIFY, true, 0.0);
	g_cvObjectBaseCount = CreateConVar("rf2_object_base_count", "10", "The base amount of objects that will be spawned. Scales based on player count and the difficulty.", FCVAR_NOTIFY, true, 0.0);
	g_cvObjectBaseCost = CreateConVar("rf2_object_base_cost", "50.0", "The base cost to use objects such as crates. Scales with the difficulty.", FCVAR_NOTIFY, true, 0.0);
	g_cvItemShareEnabled = CreateConVar("rf2_item_share_enabled", "1", "Whether or not to enable item sharing. This prevents Survivors from hogging items in multiplayer.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvTankBaseHealth = CreateConVar("rf2_tank_base_health", "7000", "The base health value of a Tank.", FCVAR_NOTIFY, true, 1.0);
	g_cvTankHealthScale = CreateConVar("rf2_tank_health_scale", "0.1", "How much a Tank's health will scale per enemy level, in decimal percentage.");
	g_cvTankBaseSpeed = CreateConVar("rf2_tank_base_speed", "75.0", "The base speed value of a Tank.", FCVAR_NOTIFY, true, 0.0);
	g_cvTankSpeedBoost = CreateConVar("rf2_tank_speed_boost", "1.5", "When a Tank falls below 50 percent health, speed it up by this much if the difficulty is above or equal to rf2_tank_boost_difficulty.", FCVAR_NOTIFY, true, 1.0);
	g_cvTankBoostHealth = CreateConVar("rf2_tank_boost_health_threshold", "0.5", "If the Tank can gain a speed boost, do so when it falls below this much health.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvTankBoostDifficulty = CreateConVar("rf2_tank_boost_difficulty", "2", "For a Tank to gain a speed boost on lower health, the difficulty (not sub difficulty) level must be at least this value.", FCVAR_NOTIFY, true, 0.0, true, float(DIFFICULTY_TITANIUM));
	g_cvSurvivorQuickBuild = CreateConVar("rf2_survivor_quick_build", "1", "If nonzero, Survivor team Engineer buildings will deploy instantly", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvEnemyQuickBuild = CreateConVar("rf2_enemy_quick_build", "1", "If nonzero, enemy team Engineer buildings will deploy instantly", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvMeleeCritChanceBonus = CreateConVar("rf2_melee_crit_chance_bonus", "2.0", "Critical hit chance bonus for melee weapons.", FCVAR_NOTIFY, true, 0.0);
	g_cvEngiMetalRegenInterval = CreateConVar("rf2_engineer_metal_regen_interval", "2.5", "Interval in seconds that an Engineer will regenerate metal, -1.0 to disable", FCVAR_NOTIFY);
	g_cvEngiMetalRegenAmount = CreateConVar("rf2_engineer_metal_regen_amount", "30", "The base amount of metal an Engineer will regen per interval lapse", FCVAR_NOTIFY, true, 0.0);
	g_cvHauntedKeyDropChanceMax = CreateConVar("rf2_haunted_key_drop_chance_max", "135", "1 in N chance for a Haunted Key to drop each time an enemy is slain.", FCVAR_NOTIFY, true, 0.0);
	
	// Debug
	RegAdminCmd("rf2_debug_playgesture", Command_PlayGesture, ADMFLAG_SLAY, "Plays a gesture animation on yourself");
	RegAdminCmd("rf2_debug_entitycount", Command_EntityCount, ADMFLAG_SLAY, "Shows the total number of networked entities (edicts) in the server.");
	RegAdminCmd("rf2_debug_thriller_test", Command_ThrillerTest, ADMFLAG_ROOT, "\"Darkness falls across the land, the dancing hour is close at hand...\"");
	g_cvDebugNoMapChange = CreateConVar("rf2_debug_skip_map_change", "0", "If nonzero, prevents the map from changing on round end.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvDebugShowObjectSpawns = CreateConVar("rf2_debug_show_object_spawns", "0", "If nonzero, when an object spawns, its name and location will be printed to the console.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvDebugDontEndGame = CreateConVar("rf2_debug_dont_end_game", "0", "If nonzero, don't end the game if all of the survivors die.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvDebugShowDifficultyCoeff = CreateConVar("rf2_debug_show_difficulty_coeff", "0", "If nonzero, shows the value of the difficulty coefficient.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	HookConVarChange(g_cvEnableAFKManager, ConVarHook_EnableAFKManager);
	//HookConVarChange(g_cvMaxHumanPlayers, ConVarHook_MaxHumanPlayers);
}

public Action Command_ReloadRF2(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	ReloadPlugin(false);
	return Plugin_Handled;
}

public Action Command_FullyReloadRF2(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	ReloadPlugin(true);
	return Plugin_Handled;
}

public Action Command_ReloadItems(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	LoadItems();
	RF2_ReplyToCommand(client, "%t", "ItemsReloaded");
	return Plugin_Handled;
}

public Action Command_EntityCount(int client, int args)
{
	RF2_ReplyToCommand(client, "%t", "EntityCount", GetEntityCount());
	return Plugin_Handled;
}

public Action Command_GiveItem(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "%t", "WaitForRoundStart");
		return Plugin_Handled;
	}
	
	if (args < 2)
	{
		RF2_ReplyToCommand(client, "%t", "GiveItemUsage");
		return Plugin_Handled;
	}
	
	char arg1[MAX_NAME_LENGTH], arg2[MAX_NAME_LENGTH];
	GetCmdArg(1, arg1, sizeof(arg1)); // player(s)
	GetCmdArg(2, arg2, sizeof(arg2)); // item name
	
	int item;
	char name[MAX_NAME_LENGTH];
	
	for (int i = 1; i <= GetTotalItems(); i++)
	{
		GetItemName(i, name, sizeof(name), false);
		if (StrContains(name, arg2, false) != -1)
		{
			item = i;
			break;
		}
	}
	
	if (item == Item_Null)
	{
		RF2_ReplyToCommand(client, "%t", "ItemNoMatch", arg2);
		return Plugin_Handled;
	}
	
	int amount = GetCmdArgInt(3); // item amount

	if (amount == 0) // assume 1 if no number is passed
	{
		amount = 1;
	}
	
	char clientName[MAX_TARGET_LENGTH], colour[32];
	int clients[MAXTF2PLAYERS];
	int newAmount;
	bool multiLanguage;
	
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
			newAmount = GetPlayerItemCount(clients[i], item);
			
			if (IsEquipmentItem(item))
			{
				RF2_PrintToChatAll("%t", "GaveItemStrange", client, colour, name, clients[i]);
			}
			else
			{
				RF2_PrintToChatAll("%t", "GaveItem", client, amount, colour, name, clients[i], newAmount);
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_GiveAllItems(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "%t", "WaitForRoundStart");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		RF2_ReplyToCommand(client, "%t", "GiveAllItemsUsage");
		return Plugin_Handled;
	}
	
	char arg1[MAX_NAME_LENGTH];
	GetCmdArg(1, arg1, sizeof(arg1)); // player(s)
	int amount = GetCmdArgInt(2);
	if (amount == 0)
	{
		amount = 1;
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
			for (int j = 1; j <= GetTotalItems(); j++)
			{
				// no equipment items, this will just create a mess
				if (IsEquipmentItem(j))
					continue;
				
				// nah
				if (j == Item_HorrificHeadsplitter)
					continue;

				GiveItem(clients[i], j, amount);
			}
			
			RF2_PrintToChatAll("%t", "OneOfEveryItem", client, amount, clients[i]);
		}
	}

	return Plugin_Handled;
}

public Action Command_GiveCash(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "%t", "WaitForRoundStart");
		return Plugin_Handled;
	}
	
	if (args != 2)
	{
		RF2_ReplyToCommand(client, "%t", "GiveCashUsage");
		return Plugin_Handled;
	}
	
	char arg1[128];
	
	GetCmdArg(1, arg1, sizeof(arg1)); // player(s)
	float amount = GetCmdArgFloat(2);
	
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
				RF2_ReplyToCommand(client, "%t", "NotASurvivor", clients[i]);
				continue;
			}
			else if (!IsPlayerAlive(clients[i]))
			{
				RF2_ReplyToCommand(client, "%t", "IsDead", clients[i]);
				continue;
			}
			
			g_flPlayerCash[clients[i]] += amount;
			RF2_PrintToChatAll("%t", "GaveMoney", client, amount, clients[i]);
		}
	}
	return Plugin_Handled;
}

public Action Command_GiveXP(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "%t", "WaitForRoundStart");
		return Plugin_Handled;
	}
	
	if (args != 2)
	{
		RF2_ReplyToCommand(client, "%t", "GiveXpUsage");
		return Plugin_Handled;
	}
	
	char arg1[MAX_TARGET_LENGTH];
	
	GetCmdArg(1, arg1, sizeof(arg1)); // player(s)
	float amount = GetCmdArgFloat(2);

	if (amount <= 0.0)
	{
		RF2_ReplyToCommand(client, "%t", "MoreThanZero");
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
				RF2_ReplyToCommand(client, "%t", "NotASurvivor", clients[i]);
				continue;
			}
			else if (!IsPlayerAlive(clients[i]))
			{
				RF2_ReplyToCommand(client, "%t", "IsDead", clients[i]);
				continue;
			}
			
			UpdatePlayerXP(clients[i], amount);
			RF2_PrintToChatAll("%t", "GaveXP", client, amount, clients[i]);
		}
	}
	return Plugin_Handled;
}

public Action Command_ForceMap(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	g_bForceNextMapCommand = true;
	char arg1[256];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (!arg1[0])
	{
		RF2_PrintToChatAll("%t", "NextMapCancel", client);
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
			strcopy(g_szMapForcerName, sizeof(g_szMapForcerName), clientName);
			
			RF2_PrintToChatAll("%t", "NextMapForced", client, arg1);
			RF2_ReplyToCommand(client, "%t", "NextMapCanUndo");
			return Plugin_Handled;
		}
		else
		{
			RF2_ReplyToCommand(client, "%t", "InvalidMap", arg1);
			return Plugin_Handled;
		}
	}
}

public Action Command_ForceWin(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "%t", "WaitForRoundStart");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		RF2_ReplyToCommand(client, "%t", "ForceWinUsage");
		return Plugin_Handled;
	}
	
	int team;
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	if (strcmp2(arg1, "red"))
	{
		team = view_as<int>(TFTeam_Red);
	}
	else if (strcmp2(arg1, "blue"))
	{
		team = view_as<int>(TFTeam_Blue);
	}
	else
	{
		RF2_ReplyToCommand(client, "%t", "ForceWinUsage");
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
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	if (g_bWaitingForPlayers)
	{
		InsertServerCommand("mp_restartgame_immediate 1");
	}
	else
	{
		RF2_ReplyToCommand(client, "%t", "WaitingInactive");
	}
	
	return Plugin_Handled;
}

public Action Command_SkipGracePeriod(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "%t", "WaitForRoundStart");
		return Plugin_Handled;
	}
	
	if (!g_bGracePeriod)
	{
		RF2_ReplyToCommand(client, "%t", "GracePeriodNotActive");
		return Plugin_Handled;
	}
	
	EndGracePeriod();
	RF2_ReplyToCommand(client, "%t", "GracePeriodSkipped");
	
	return Plugin_Handled;
}

public Action Command_AddPoints(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	if (args != 2)
	{
		RF2_ReplyToCommand(client, "%t", "AddPointsUsage");
		return Plugin_Handled;
	}
	
	char arg1[32];
	
	char clientName[MAX_TARGET_LENGTH];
	int clients[MAXTF2PLAYERS];
	bool multiLanguage;
	
	GetCmdArg(1, arg1, sizeof(arg1)); // player(s)
	int amount = GetCmdArgInt(2);
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
			g_iPlayerSurvivorPoints[clients[i]] += amount;
			if (g_iPlayerSurvivorPoints[clients[i]] < 0)
				g_iPlayerSurvivorPoints[clients[i]] = 0;
				
			RF2_PrintToChatAll("%t", "GaveQueuePoints", client, amount, clients[i]);
		}
	}
	
	return Plugin_Handled;
}

public Action Command_StartTeleporterEvent(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "%t", "WaitForRoundStart");
		return Plugin_Handled;
	}
	
	int teleporter = GetTeleporterEntity();
	if (teleporter == INVALID_ENT_REFERENCE || g_bTankBossMode || GetTeleporterEventState() == TELE_EVENT_ACTIVE || IsStageCleared())
	{
		RF2_ReplyToCommand(client, "%t", "CannotBeUsed");
		return Plugin_Handled;
	}
	
	if (g_bGracePeriod)
	{
		EndGracePeriod();
	}
	
	PrepareTeleporterEvent(teleporter);
	return Plugin_Handled;
}

public Action Command_ThrillerTest(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	if (client == 0)
	{
		RF2_ReplyToCommand(client, "%t", "OnlyInGame");
		return Plugin_Handled;
	}
	
	float eyePos[3];
	GetClientEyePosition(client, eyePos);
	StartThrillerDance(eyePos);
	return Plugin_Handled;
}

public Action Command_ForceBoss(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	if (GetEnemyCount() <= 0)
	{
		RF2_ReplyToCommand(client, "%t", "NoBossesLoaded");
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
		RF2_ReplyToCommand(client, "%t", "CantUseOnSurvivor");
	}
	else
	{
		ShowBossSpawnMenu(client, target);
	}
	
	return Plugin_Handled;
}

public Action Command_ForceEnemy(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	if (GetEnemyCount() <= 0)
	{
		RF2_ReplyToCommand(client, "%t", "NoEnemiesLoaded");
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
		RF2_ReplyToCommand(client, "%t", "CantUseOnSurvivor");
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
	char buffer[128], info[16], bossName[256];
	
	SetMenuTitle(menu, "%T", "SpawnAs", LANG_SERVER, target);
	for (int i = 0; i < GetEnemyCount(); i++)
	{
		if (!EnemyByIndex(i).IsBoss)
			continue;

		EnemyByIndex(i).GetName(bossName, sizeof(bossName));
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
			char info[32], buffer[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			SplitString(info, ";", buffer, sizeof(buffer));
			
			int client = StringToInt(buffer);
			ReplaceStringEx(info, sizeof(info), buffer, "");
			ReplaceStringEx(info, sizeof(info), ";", "");
			
			if (!IsValidClient(client) || IsPlayerSurvivor(client))
			{
				RF2_PrintToChat(param1, "%t", "TargetInvalid");
			}
			else
			{
				SplitString(info, "_", buffer, sizeof(buffer));
				int type = StringToInt(buffer);
				char bossName[256];
				
				RefreshClient(client);
				float pos[3];
				GetEntPos(param1, pos);
				
				SpawnBoss(client, type, pos, false, 0.0, 2000.0);
				Enemy(client).GetName(bossName, sizeof(bossName));
				RF2_PrintToChat(param1, "%t", "SpawnedAsBoss", client, bossName);
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
	char buffer[128], info[16], enemyName[256];
	
	SetMenuTitle(menu, "%T", "SpawnAs", LANG_SERVER, target);
	for (int i = 0; i < GetEnemyCount(); i++)
	{
		if (EnemyByIndex(i).IsBoss)
			continue;
		
		EnemyByIndex(i).GetName(enemyName, sizeof(enemyName));
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
			char info[32], buffer[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			SplitString(info, ";", buffer, sizeof(buffer));
			
			int client = StringToInt(buffer);
			ReplaceStringEx(info, sizeof(info), buffer, "");
			ReplaceStringEx(info, sizeof(info), ";", "");
			
			if (!IsValidClient(client) || IsPlayerSurvivor(client))
			{
				RF2_PrintToChat(param1, "%t", "TargetInvalid");
			}
			else
			{
				SplitString(info, "_", buffer, sizeof(buffer));
				int type = StringToInt(buffer);
				char enemyName[256];
				
				RefreshClient(client);
				float pos[3];
				GetEntPos(param1, pos);
				
				SpawnEnemy(client, type, pos, 0.0, 2000.0);
				EnemyByIndex(type).GetName(enemyName, sizeof(enemyName));
				RF2_PrintToChat(param1, "%t", "SpawnedAsEnemy", client, enemyName);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public Action Command_AddSeconds(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "%t", "WaitForRoundStart");
		return Plugin_Handled;
	}
	
	float seconds = GetCmdArgFloat(1);
	g_flSecondsPassed += seconds - FloatFraction(seconds);
	RF2_PrintToChatAll("%t", "AddSecondsCommand", client, RoundToFloor(seconds));
	return Plugin_Handled;
}

public Action Command_AFK(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	if (client == 0)
	{
		RF2_ReplyToCommand(client, "%t", "OnlyInGame");
		return Plugin_Handled;
	}
	
	if (IsPlayerAFK(client))
	{
		ResetAFKTime(client);
		return Plugin_Handled;
	}
	
	if (IsTeleporterBoss(client))
	{
		RF2_ReplyToCommand(client, "%t", "NotAsTeleBoss");
		return Plugin_Handled;
	}
	
	if (IsPlayerSurvivor(client))
	{
		if (g_bGracePeriod)
		{
			FakeClientCommand(client, "explode");
			
			if (!IsSingleplayer())
			{
				ReshuffleSurvivor(client, view_as<int>(TFTeam_Spectator));
			}
			else
			{
				TF2_ChangeClientTeam(client, TFTeam_Spectator);
			}
		}
		else
		{
			RF2_ReplyToCommand(client, "%t", "NotAsSurvivorAfterGrace");
			return Plugin_Handled;
		}
	}
	else
	{
		TF2_ChangeClientTeam(client, TFTeam_Spectator);
	}
	
	g_bPlayerIsAFK[client] = true;
	OnPlayerEnterAFK(client);
	return Plugin_Handled;
}

public Action Command_ClientSettings(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	if (client == 0)
	{
		RF2_ReplyToCommand(client, "%t", "OnlyInGame");
		return Plugin_Handled;
	}
	
	ShowClientSettingsMenu(client);
	return Plugin_Handled;
}

void ShowClientSettingsMenu(int client)
{
	Menu menu = CreateMenu(Menu_ClientSettings);
	char buffer[128];
	menu.SetTitle("Risk Fortress 2 Settings");
	
	int lang = GetClientLanguage(client);
	char off[8], on[8];
	FormatEx(off, sizeof(off), "%T", "Off", lang);
	FormatEx(on, sizeof(on), "%T", "On", lang);
	
	FormatEx(buffer, sizeof(buffer), "%T", "ToggleSurvivor", lang, g_bPlayerBecomeSurvivor[client] ? on : off);
	menu.AddItem("survivor_pref", buffer);
	
	FormatEx(buffer, sizeof(buffer), "%T", "ToggleTeleBoss", lang, g_bPlayerBecomeBoss[client] ? on : off);
	menu.AddItem("boss_pref", buffer);
	
	FormatEx(buffer, sizeof(buffer), "%T", "ToggleMusic", lang, g_bPlayerMusicEnabled[client] ? on : off);
	menu.AddItem("music_pref", buffer);
	
	FormatEx(buffer, sizeof(buffer), "%T", "AutoItemMenu", lang, g_bPlayerAutomaticItemMenu[client] ? on : off);
	menu.AddItem("itemmenu_pref", buffer);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_ClientSettings(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[64];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			if (strcmp2(info, "survivor_pref"))
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
			else if (strcmp2(info, "boss_pref"))
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
			else if (strcmp2(info, "music_pref"))
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
			else if (strcmp2(info, "itemmenu_pref"))
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
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}

	if (client == 0)
	{
		RF2_ReplyToCommand(client, "%t", "OnlyInGame");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "%t", "WaitForRoundStart");
		return Plugin_Handled;
	}
	
	if (!IsPlayerSurvivor(client))
	{
		RF2_ReplyToCommand(client, "%t", "YouAreNotSurvivor");
		return Plugin_Handled;
	}
	
	ShowItemMenu(client);
	return Plugin_Handled;
}

void ShowItemMenu(int client, int inspectTarget=-1)
{
	if (!IsPlayerSurvivor(client))
		return;
	
	int target = IsValidClient(inspectTarget) ? inspectTarget : client;
	Menu menu = CreateMenu(Menu_Items);
	char buffer[128], info[16], itemName[MAX_NAME_LENGTH];
	int itemCount;
	int lang = GetClientLanguage(client);
	
	if (!IsSingleplayer(false) && g_cvItemShareEnabled.BoolValue && target != inspectTarget)
	{
		int index = RF2_GetSurvivorIndex(target);
		menu.SetTitle("%T", "YourItemsShareEnabled", lang, g_iItemsTaken[index], g_iItemLimit[index]);
	}
	else
	{
		if (client == target)
		{
			menu.SetTitle("%T", "YourItems", lang);
		}
		else
		{
			menu.SetTitle("%T", "InspectTargetItems", lang, target);
		}
	}
	
	int flags = target == inspectTarget ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
	char qualityName[32];
	GetQualityName(Quality_Strange, qualityName, sizeof(qualityName));
	for (int i = 1; i < Item_MaxValid; i++)
	{
		if (GetPlayerItemCount(target, i) > 0 || IsEquipmentItem(i) && GetPlayerEquipmentItem(target) == i)
		{
			itemCount++;
			GetItemName(i, itemName, sizeof(itemName));
			IntToString(i, info, sizeof(info));
			
			if (IsEquipmentItem(i))
			{
				FormatEx(buffer, sizeof(buffer), "%s [%s]", itemName, qualityName);
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%s [%i]", itemName, GetPlayerItemCount(target, i));
			}
			
			menu.AddItem(info, buffer, flags);
		}
	}
	
	if (itemCount == 0)
	{
		char noItems[64];
		FormatEx(noItems, sizeof(noItems), "%t", "NoItems", lang);
		menu.AddItem("no_items", noItems, flags);
	}
	
	menu.DisplayAt(client, g_iPlayerLastItemMenuItem[client], MENU_TIME_FOREVER);
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
			g_iPlayerLastItemMenuItem[param1] = GetMenuSelectionPosition();

			bool refresh = true;
			char info[16];
			GetMenuItem(menu, param2, info, sizeof(info));
			if (!strcmp2(info, "no_items"))
			{
				int humanCount = GetPlayersOnTeam(TEAM_SURVIVOR, true, true);
				int item = StringToInt(info);
				
				// Drop the item if there are no other human players on our team.
				if (humanCount == 1)
				{
					float pos[3];
					GetEntPos(param1, pos);
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
			g_iPlayerLastItemMenuItem[param1] = 0;
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
	Menu menu = CreateMenu(Menu_ItemDrop);
	char info[64], itemName[MAX_NAME_LENGTH], clientName[MAX_NAME_LENGTH];
	
	GetItemName(item, itemName, sizeof(itemName));
	menu.SetTitle("Drop for who? (%s [%i])", itemName, GetPlayerItemCount(client, item));
	FormatEx(info, sizeof(info), "%i_0", item);
	menu.AddItem(info, "Don't care"); // + didn't ask + L + ratio + cope + seethe + mald + cancelled + blocked + reported + stay mad
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client || !IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
			
		if (IsPlayerSurvivor(i))
		{
			FormatEx(info, sizeof(info), "%i_%i", item, GetClientUserId(i));
			GetClientName(i, clientName, sizeof(clientName));
			menu.AddItem(info, clientName);
		}
	}
	
	menu.ExitButton = false;
	menu.ExitBackButton = true;
	CancelClientMenu(client);
	menu.DisplayAt(client, g_iPlayerLastDropMenuItem[client], MENU_TIME_FOREVER);
}

public int Menu_ItemDrop(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			g_iPlayerLastDropMenuItem[param1] = GetMenuSelectionPosition();
			
			char info[64];
			char itemIndex[8];
			float pos[3];
			GetEntPos(param1, pos);
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
					RF2_PrintToChat(param1, "%t", "TargetInvalid");
				}
				else
				{
					DropItem(param1, item, pos, client);
					RF2_PrintToChat(param1, "%t", "ItemDrop", client);
				}
			}
			
			if (GetPlayerItemCount(param1, item) > 0)
			{
				ShowItemDropMenu(param1, item);
			}
			else
			{
				ShowItemMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			g_iPlayerLastDropMenuItem[param1] = 0;
			
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

public Action Command_SetDifficulty(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	char name[32];
	int level = GetCmdArgInt(1);
	
	if (level < DIFFICULTY_SCRAP || level >= DIFFICULTY_MAX)
	{
		RF2_ReplyToCommand(client, "%t", "InvalidDifficulty");
		return Plugin_Handled;
	}
	
	SetDifficultyLevel(level);
	GetDifficultyName(level, name, sizeof(name));
	
	RF2_PrintToChatAll("%t", "DifficultySetBy", client, name);
	return Plugin_Handled;
}

public Action Command_MakeSurvivor(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	if (!g_bRoundActive)
	{
		RF2_ReplyToCommand(client, "%t", "WaitForRoundStart");
		return Plugin_Handled;
	}
	
	int redCount = GetPlayersOnTeam(TEAM_SURVIVOR, true); 
	if (redCount >= MAX_SURVIVORS)
	{
		RF2_ReplyToCommand(client, "%t", "HitMaxSurvivors", MAX_SURVIVORS);
		return Plugin_Handled;
	}
	
	char arg1[16], clientName[MAX_NAME_LENGTH];
	bool multiLanguage;
	int clients[MAXTF2PLAYERS];
	GetCmdArg(1, arg1, sizeof(arg1));
	
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
			if (IsPlayerSurvivor(clients[i]))
			{
				RF2_ReplyToCommand(client, "%t", "AlreadySurvivor", clients[i]);
				continue;
			}
			
			for (int index = 0; index < MAX_SURVIVORS; index++)
			{
				if (!IsSurvivorIndexValid(index))
				{
					SilentlyKillPlayer(clients[i]);
					MakeSurvivor(clients[i], index, false);
					RF2_ReplyToCommand(client, "%t", "MadeSurvivor", clients[i]);
					if (redCount+1 > g_iSurvivorCount)
					{
						g_iSurvivorCount++;
					}

					break;
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_EndLevel(int client, int args)
{
	if (client == 0)
	{
		RF2_ReplyToCommand(client, "%t", "OnlyInGame");
		return Plugin_Handled;
	}
	
	if (!IsPlayerSurvivor(client) || !g_bTankBossMode || !IsStageCleared() || GameRules_GetRoundState() == RoundState_TeamWin)
	{
		RF2_ReplyToCommand(client, "%t", "CannotBeUsed");
		return Plugin_Handled;
	}
	
	StartTeleporterVote(client, true);
	return Plugin_Handled;
}

public Action Command_ResetTutorial(int client, int args)
{
	if (client == 0)
	{
		RF2_ReplyToCommand(client, "%t", "OnlyInGame");
		return Plugin_Handled;
	}
	
	SetClientCookie(client, g_coTutorialSurvivor, "0");
	SetClientCookie(client, g_coTutorialItemPickup, "0");
	RF2_ReplyToCommand(client, "%t", "TutorialReset");
	return Plugin_Handled;
}

public Action Command_PlayGesture(int client, int args)
{
	if (client == 0)
	{
		RF2_ReplyToCommand(client, "%t", "OnlyInGame");
		return Plugin_Handled;
	}
	
	char gesture[256];
	GetCmdArg(1, gesture, sizeof(gesture));
	if (ClientPlayGesture(client, gesture))
	{
		RF2_ReplyToCommand(client, "Playing gesture '%s'", gesture);
	}
	else
	{
		RF2_ReplyToCommand(client, "Couldn't find gesture '%s'", gesture);
	}
	
	return Plugin_Handled;
}

public void ConVarHook_EnableAFKManager(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int newVal = StringToInt(newValue);
	if (newVal == 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			g_flPlayerAFKTime[i] = 0.0;
			g_bPlayerIsAFK[i] = false;
		}
	}
}

public void ConVarHook_MaxHumanPlayers(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int newVal = StringToInt(newValue);
	ConVar visibleMax = FindConVar("sv_visiblemaxplayers");
	visibleMax.IntValue = newVal;
}
