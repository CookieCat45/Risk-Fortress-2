#if defined _RF2_commands_convars_included
 #endinput
#endif
#define _RF2_commands_convars_included

#pragma semicolon 1
#pragma newdecls required

void LoadCommandsAndCvars()
{
	RegAdminCmd("rf2_reload", Command_ReloadRF2, ADMFLAG_ROOT, "Reloads the plugin and restarts the game (without changing the map).");
	RegAdminCmd("rf2_fullreload", Command_FullyReloadRF2, ADMFLAG_ROOT, "Reloads the plugin, restarts the game and changes the map to a Stage 1 map.");
	RegAdminCmd("rf2_reloaditems", Command_ReloadItems, ADMFLAG_ROOT, "Reloads all items.");
	RegAdminCmd("rf2_giveitem", Command_GiveItem, ADMFLAG_SLAY, "Give items to a player. /rf2_giveitem <player> <item name> <amount>\nNegative amounts will remove items from a player.");
	RegAdminCmd("rf2_giveallitems", Command_GiveAllItems, ADMFLAG_ROOT, "Gives a player every item in the game! /rf2_giveallitems <player> <amount>");
	RegAdminCmd("rf2_forcewin", Command_ForceWin, ADMFLAG_SLAY, "Forces a team to win. /rf2_forcewin <red|blue>");
	RegAdminCmd("rf2_forceskipwait", Command_SkipWait, ADMFLAG_SLAY, "Skips the Waiting For Players sequence forcefully.");
	RegAdminCmd("rf2_skipgrace", Command_SkipGracePeriod, ADMFLAG_SLAY, "Skip the grace period at the start of a round");
	RegAdminCmd("rf2_skipgraceperiod", Command_SkipGracePeriod, ADMFLAG_SLAY, "Skip the grace period at the start of a round");
	RegAdminCmd("rf2_addpoints", Command_AddPoints, ADMFLAG_SLAY, "Add queue points to a player. /rf2_addpoints <player> <amount>");
	RegAdminCmd("rf2_givecash", Command_GiveCash, ADMFLAG_SLAY, "Give cash to a RED player. /rf2_givecash <player> <amount>");
	RegAdminCmd("rf2_givexp", Command_GiveXP, ADMFLAG_SLAY, "Give XP to a RED player. /rf2_givexp <player> <amount>");
	RegAdminCmd("rf2_start_teleporter", Command_StartTeleporterEvent, ADMFLAG_SLAY, "Starts the Teleporter event.");
	RegAdminCmd("rf2_spawn_boss", Command_ForceBoss, ADMFLAG_SLAY, "Spawn a boss.");
	RegAdminCmd("rf2_spawn_enemy", Command_ForceEnemy, ADMFLAG_SLAY, "Spawn an enemy.");
	RegAdminCmd("rf2_set_difficulty", Command_SetDifficulty, ADMFLAG_SLAY, "Sets the difficulty level. 0 = Scrap, 1 = Iron, 2 = Steel, 3 = Titanium");
	RegAdminCmd("rf2_setnextmap", Command_ForceMap, ADMFLAG_SLAY, "Forces the next map to be the map specified. This will not immediately change the map.");
	RegAdminCmd("rf2_make_survivor", Command_MakeSurvivor, ADMFLAG_SLAY, "Force a player to become a Survivor.\nWill not work if the maximum survivor count has been reached.");
	RegAdminCmd("rf2_addseconds", Command_AddSeconds, ADMFLAG_SLAY, "Add seconds to the difficulty timer. /rf2_addseconds <seconds>");
	RegAdminCmd("rf2_particle_test", Command_ParticleTest, ADMFLAG_SLAY, "For testing particle effects.\n/rf2_particle_test <effect name> <method>.\n0 = Spawn via TE, 1 = Spawn via info_particle system, 2 = Spawn via trigger_particle.");
	RegAdminCmd("rf2_tp_to_altar", Command_AltarTeleport, ADMFLAG_SLAY, "Teleports to an altar if one exists");
	RegAdminCmd("rf2_view_afk_times", Command_ViewAFKTimes, ADMFLAG_SLAY, "View player AFK times");

	RegConsoleCmd("rf2_settings", Command_ClientSettings, "Configure your personal settings.");
	RegConsoleCmd("rf2_items", Command_Items, "Opens the Survivor item management menu. TAB+E can be used to open this menu as well.");
	RegConsoleCmd("rf2_endlevel", Command_EndLevel, "Starts the vote to end the level in Tank Destruction mode.");
	RegConsoleCmd("rf2_reset_tutorial", Command_ResetTutorial, "Resets the tutorial.");
	RegConsoleCmd("rf2_skipwait", Command_VoteSkipWait, "Starts a vote to skip the Waiting for Players sequence.");
	RegConsoleCmd("rf2_survivorqueue", Command_SurvivorQueue, "Shows the Survivor queue list.");
	RegConsoleCmd("rf2_itemlog", Command_ItemLog, "Shows a list of items that you've collected.");
	RegConsoleCmd("rf2_logbook", Command_ItemLog, "Shows a list of items that you've collected.");
	RegConsoleCmd("rf2_achievements", Command_Achievements, "Shows a list of achievements in Risk Fortress 2.");
	RegConsoleCmd("rf2_use_strange", Command_UseStrange, "Uses your Strange item, meant to be binded to a key from the console");
	RegConsoleCmd("rf2_interact", Command_Interact, "Functions identically to Call for Medic key, can be binded to a key from the console");
	RegConsoleCmd("rf2_ping", Command_Ping, "Ping an object, meant to be binded to a key from the console");
	RegConsoleCmd("rf2_extend_wait", Command_ExtendWait, "Extends Waiting for Players time significantly.");
	RegConsoleCmd("rf2_discord", Command_Discord, "Show link to the Risk Fortress 2 Discord server.");
	RegConsoleCmd("rf2_helpmenu", Command_HelpMenu, "Shows the help menu.");
	RegConsoleCmd("rf2_help", Command_HelpMenu, "Shows the help menu.");
	RegConsoleCmd("rf2_menu", Command_HelpMenu, "Shows the help menu.");
	RegConsoleCmd("rf2", Command_HelpMenu, "Shows the help menu.");
	
	char buffer[8];
	IntToString(MAX_SURVIVORS, buffer, sizeof(buffer));
	g_cvMaxSurvivors = CreateConVar("rf2_max_survivors", buffer, "Max number of Survivors that can be in the game.", FCVAR_NOTIFY, true, 1.0, true, float(MAX_SURVIVORS));
	g_cvMaxHumanPlayers = CreateConVar("rf2_human_player_limit", "8", "Max number of human players allowed in the server.", FCVAR_NOTIFY, true, 1.0, true, float(MaxClients));
	g_cvGameResetTime = CreateConVar("rf2_max_wait_time", "600", "If the game has already began, amount of time in seconds to wait for players to join before restarting. 0 to disable.", FCVAR_NOTIFY);
	g_cvAlwaysSkipWait = CreateConVar("rf2_always_skip_wait", "0", "If nonzero, always skip the Waiting For Players sequence. Great for singleplayer.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvEnableAFKManager = CreateConVar("rf2_afk_manager_enabled", "1", "If nonzero, use RF2's AFK manager to kick AFK players.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvAFKOnlyKickSurvivors = CreateConVar("rf2_afk_kick_survivors_only", "0", "If nonzero, AFK manager will kick only Survivors", FCVAR_NOTIFY);
	g_cvAFKManagerKickTime = CreateConVar("rf2_afk_kick_time", "210.0", "AFK manager kick time, in seconds.", FCVAR_NOTIFY);
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
	g_cvSurvivorLagBehindThreshold = CreateConVar("rf2_survivor_lag_behind_threshold", "0.6", "If any player has an item count lower than the player with the most items times this value, they will be considered 'lagging behind'. 0 to disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvSurvivorMaxExtraCrates = CreateConVar("rf2_survivor_max_extra_crates", "0", "The highest number of catch-up crates to spawn for a player.", FCVAR_NOTIFY, true, 0.0);
	g_cvCashBurnTime = CreateConVar("rf2_enemy_cash_burn_time", "30.0", "Time in seconds that dropped cash will disappear after spawning.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyHealthScale = CreateConVar("rf2_enemy_level_health_scale", "0.08", "How much the enemy team's health will increase per level, in decimal percentage. Includes neutral enemies, such as Monoculus.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyDamageScale = CreateConVar("rf2_enemy_level_damage_scale", "0.04", "How much the enemy team's damage will increase per level, in decimal percentage. Includes neutral enemies, such as Monoculus.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyXPDropScale = CreateConVar("rf2_enemy_xp_drop_scale", "0.15", "How much enemy XP drops scale per level.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyCashDropScale = CreateConVar("rf2_enemy_cash_drop_scale", "0.15", "How much enemy cash drops scale per level.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyMinSpawnDistance = CreateConVar("rf2_enemy_spawn_min_distance", "1000.0", "The minimum distance an enemy can spawn in relation to Survivors.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyMaxSpawnDistance = CreateConVar("rf2_enemy_spawn_max_distance", "3000.0", "The maximum distance an enemy can spawn in relation to Survivors.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyMinSpawnWaveCount = CreateConVar("rf2_enemy_spawn_min_count", "3", "The absolute minimum number of enemies that can spawn in a single spawn wave.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyMaxSpawnWaveCount = CreateConVar("rf2_enemy_spawn_max_count", "8", "The absolute maximum amount of enemies that can spawn in a single spawn wave.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyMinSpawnWaveTime = CreateConVar("rf2_enemy_spawn_min_wave_time", "2.0", "The minimum amount of time that must pass between enemy spawn waves.", FCVAR_NOTIFY, true, 0.0);
	g_cvEnemyBaseSpawnWaveTime = CreateConVar("rf2_enemy_spawn_base_wave_time", "30.0", "The base amount of time that passes between spawn waves. Affected by many different factors.", FCVAR_NOTIFY, true, 0.1);
	g_cvEnemyPowerupLevel = CreateConVar("rf2_enemy_powerup_level", "100", "The level at which enemies will begin having a chance to gain Mannpower powerups on spawn. 0 to disable.", FCVAR_NOTIFY, true, 0.0);
	g_cvBossPowerupLevel = CreateConVar("rf2_boss_powerup_level", "300", "The level at which bosses will begin having a chance to gain Mannpower powerups on spawn. 0 to disable.", FCVAR_NOTIFY, true, 0.0);
	g_cvBossStabDamageType = CreateConVar("rf2_boss_backstab_damage_type", "0", "Determines how bosses take backstab damage. 0 - raw damage. 1 - percentage.\nBoth benefit from any damage bonuses, excluding crits.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvBossStabDamagePercent = CreateConVar("rf2_boss_backstab_damage_percentage", "0.12", "If rf2_boss_backstab_damage_type is 1, how much health, in decimal percentage, is subtracted from the boss upon backstab.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvBossStabDamageAmount = CreateConVar("rf2_boss_backstab_damage_amount", "750.0", "If rf2_boss_backstab_damage_type is 0, the base damage that is dealt to a boss upon backstab.", FCVAR_NOTIFY, true, 0.0);
	g_cvTeleporterRadiusMultiplier = CreateConVar("rf2_object_teleporter_radius_multiplier", "1.0", "How much to multiply the size of the Teleporter radius.", FCVAR_NOTIFY, true, 0.01);
	g_cvMaxObjects = CreateConVar("rf2_object_max", "120", "The maximum number of objects allowed to spawn. Does not include Teleporters or Altars.", FCVAR_NOTIFY, true, 0.0);
	g_cvObjectSpreadDistance = CreateConVar("rf2_object_spread_distance", "80.0", "The minimum distance that spawned objects must be spread apart from eachother.", FCVAR_NOTIFY, true, 0.0);
	g_cvObjectBaseCount = CreateConVar("rf2_object_base_count", "12", "The base amount of objects that will be spawned. Scales based on player count and the difficulty.", FCVAR_NOTIFY, true, 0.0);
	g_cvObjectBaseCost = CreateConVar("rf2_object_base_cost", "50.0", "The base cost to use objects such as crates. Scales with the difficulty.", FCVAR_NOTIFY, true, 0.0);
	g_cvItemShareEnabled = CreateConVar("rf2_item_share_enabled", "1", "Whether or not to enable the item sharing system. This system is designed to prevent players from hogging items in multiplayer.\n0 = Always disabled, 1 = Disable under certain conditions only, 2 = Disable only if 1 player is on RED.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvItemShareDisableLoopCount = CreateConVar("rf2_item_share_disable_loop_count", "0", "Disable item sharing after this many loops if rf2_item_share_enabled is set to 1. 0 to disable.", FCVAR_NOTIFY, true, 0.0);
	g_cvItemShareDisableThreshold = CreateConVar("rf2_item_share_disable_threshold", "0.6", "If rf2_item_share_enabled is set to 1, disable item sharing after all players have filled at least this much of their item cap. 0 to disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvTankBaseHealth = CreateConVar("rf2_tank_base_health", "6000", "The base health value of a Tank.", FCVAR_NOTIFY, true, 1.0);
	g_cvTankHealthScale = CreateConVar("rf2_tank_health_scale", "0.1", "How much a Tank's health will scale per enemy level, in decimal percentage.");
	g_cvTankBaseSpeed = CreateConVar("rf2_tank_base_speed", "75.0", "The base speed value of a Tank.", FCVAR_NOTIFY, true, 0.0);
	g_cvTankSpeedBoost = CreateConVar("rf2_tank_speed_boost", "1.5", "When a Tank falls below 50 percent health, speed it up by this much if the difficulty is above or equal to rf2_tank_boost_difficulty.", FCVAR_NOTIFY, true, 1.0);
	g_cvTankBoostHealth = CreateConVar("rf2_tank_boost_health_threshold", "0.5", "If the Tank can gain a speed boost, do so when it falls below this much health.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvTankBoostDifficulty = CreateConVar("rf2_tank_boost_difficulty", "2", "For a Tank to gain a speed boost on lower health, the difficulty (not sub difficulty) level must be at least this value.", FCVAR_NOTIFY, true, 0.0, true, float(DIFFICULTY_TITANIUM));
	g_cvSurvivorQuickBuild = CreateConVar("rf2_survivor_quick_build", "1", "If nonzero, Survivor team Engineer buildings will deploy instantly", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvEnemyQuickBuild = CreateConVar("rf2_enemy_quick_build", "1", "If nonzero, enemy team Engineer buildings will deploy instantly", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvMeleeCritChanceBonus = CreateConVar("rf2_melee_crit_chance_bonus", "1.0", "Critical hit chance bonus for melee weapons.", FCVAR_NOTIFY, true, 0.0);
	g_cvEngiMetalRegenInterval = CreateConVar("rf2_engineer_metal_regen_interval", "2.5", "Interval in seconds that an Engineer will regenerate metal, -1.0 to disable", FCVAR_NOTIFY);
	g_cvEngiMetalRegenAmount = CreateConVar("rf2_engineer_metal_regen_amount", "30", "The base amount of metal an Engineer will regen per interval lapse", FCVAR_NOTIFY, true, 0.0);
	g_cvHauntedKeyDropChanceMax = CreateConVar("rf2_haunted_key_drop_chance_max", "135", "1 in N chance for a Haunted Key to drop when an enemy is slain.", FCVAR_NOTIFY, true, 0.0);
	g_cvAllowHumansInBlue = CreateConVar("rf2_blue_allow_humans", "0", "If nonzero, allow humans to spawn in BLU Team.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvTimeBeforeRestart = CreateConVar("rf2_time_before_restart", "28800", "Time in seconds before the server will restart after a run ends, to clear server memory. 0 to disable.", FCVAR_NOTIFY, true, 0.0);
	g_cvHiddenServerStartTime = CreateConVar("rf2_server_start_time", "0", _, FCVAR_HIDDEN);
	g_cvWaitExtendTime = CreateConVar("rf2_wait_extend_time", "600", "If the vote to extend Waiting for Players passes, extend the wait time to this in seconds. 0 to disable extending.", FCVAR_NOTIFY, true, 0.0);
	g_cvRequiredStagesForStatue = CreateConVar("rf2_statue_required_stages", "10", "How many stages need to be completed before being able to interact with the statue in the Underworld", FCVAR_NOTIFY, true, 0.0);
	CreateConVar("rf2_plugin_version", PLUGIN_VERSION, "Plugin version. Don't touch this please.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// Debug
	RegAdminCmd("rf2_hiddenslot_test", Command_TestHiddenSlot, ADMFLAG_ROOT);
	RegAdminCmd("rf2_debug_simulate_crash", Command_SimulateCrash, ADMFLAG_ROOT, "Kicks a player and tells the plugin that they crashed. Used to test the crash protection system.");
	RegAdminCmd("rf2_debug_entitycount", Command_EntityCount, ADMFLAG_SLAY, "Shows the total number of networked entities (edicts) in the server.");
	RegAdminCmd("rf2_debug_thriller_test", Command_ThrillerTest, ADMFLAG_ROOT, "\"Darkness falls across the land, the dancing hour is close at hand...\"");
	RegAdminCmd("rf2_debug_unlock_achievements", Command_UnlockAllAchievements, ADMFLAG_ROOT, "Unlocks every achievement.");
	g_cvDebugNoMapChange = CreateConVar("rf2_debug_skip_map_change", "0", "If nonzero, prevents the map from changing on round end.", FCVAR_NOTIFY, true, 0.0);
	g_cvDebugShowObjectSpawns = CreateConVar("rf2_debug_show_object_spawns", "0", "If nonzero, when an object spawns, its name and location will be printed to the console.", FCVAR_NOTIFY, true, 0.0);
	g_cvDebugDontEndGame = CreateConVar("rf2_debug_dont_end_game", "0", "If nonzero, don't end the game if all of the survivors die.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvDebugShowDifficultyCoeff = CreateConVar("rf2_debug_show_difficulty_coeff", "0", "If nonzero, shows the value of the difficulty coefficient.", FCVAR_NOTIFY, true, 0.0);
	g_cvDebugUseAltMapSettings = CreateConVar("rf2_debug_alt_map_settings", "0", "If nonzero, always use the alternate map settings for the map that is used after looping.", FCVAR_NOTIFY, true, 0.0);
	g_cvDebugDisableEnemySpawning = CreateConVar("rf2_debug_disable_enemy_spawn", "0", "If nonzero, prevent enemies from spawning.", FCVAR_NOTIFY, true, 0.0);
	
	HookConVarChange(g_cvEnableAFKManager, ConVarHook_EnableAFKManager);
	HookConVarChange(g_cvMaxHumanPlayers, ConVarHook_MaxHumanPlayers);
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
		if ((g_bItemInDropPool[i] || IsScrapItem(i)) && StrContains(name, arg2, false) != -1)
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
			newAmount = GetPlayerItemCount(clients[i], item, true);
			if (IsPlayerSurvivor(clients[i]))
			{
				// count towards item share for debugging purposes
				g_iItemsTaken[RF2_GetSurvivorIndex(clients[i])] += amount;
			}
			
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
				if (!g_bItemInDropPool[j] && !IsScrapItem(j))
					continue;
				
				// no equipment items, this will just create a mess
				if (IsEquipmentItem(j))
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
			
			AddPlayerCash(clients[i], amount);
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
	
	char arg1[256];
	GetCmdArg(1, arg1, sizeof(arg1));
	if (!arg1[0])
	{
		RF2_PrintToChatAll("%t", "NextMapCancel", client);
		g_szForcedMap = "";
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
	
	if (GetPlayersOnTeam(TEAM_SURVIVOR, _, true) <= 0 && GetPlayersOnTeam(TEAM_ENEMY, _, true) <= 0)
	{
		RF2_ReplyToCommand(client, "%t", "JoinATeam");
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

public Action Command_VoteSkipWait(int client, int args)
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
	
	if (IsVoteInProgress())
	{
		RF2_ReplyToCommand(client, "%t", "VoteInProgress");
		return Plugin_Handled;
	}
	
	if (GetPlayersOnTeam(TEAM_SURVIVOR, _, true) <= 0 && GetPlayersOnTeam(TEAM_ENEMY, _, true) <= 0)
	{
		RF2_ReplyToCommand(client, "%t", "JoinATeam");
		return Plugin_Handled;
	}
	
	if (g_bWaitingForPlayers)
	{
		// wait until all human players are connected, unless singleplayer
		if (GetTotalHumans(false) <= 1)
		{
			InsertServerCommand("mp_restartgame_immediate 1");
		}
		else
		{
			if (!ArePlayersConnecting())
			{
				Menu vote = new Menu(Menu_SkipWaitVote);
				vote.SetTitle("Skip waiting for players? (%N)", client);
				vote.AddItem("Yes", "Yes");
				vote.AddItem("No", "No");
				vote.ExitButton = false;
				int clients[MAXTF2PLAYERS];
				int clientCount;
				for (int i = 1; i <= MaxClients; i++)
				{
					if (!IsClientInGame(i) || GetClientTeam(i) <= 1 || IsFakeClient(i))
						continue;
					
					clients[clientCount] = i;
					clientCount++;
				}
				
				vote.DisplayVote(clients, clientCount, 10);
			}
			else
			{
				RF2_ReplyToCommand(client, "%t", "WaitForOthers");
			}
		}
	}
	else
	{
		RF2_ReplyToCommand(client, "%t", "WaitingInactive");
	}
	
	return Plugin_Handled;
}

public int Menu_SkipWaitVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_VoteEnd:
		{
			if (param1 == 0 && g_bWaitingForPlayers)
			{
				InsertServerCommand("mp_restartgame_immediate 1");
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public Action Command_ExtendWait(int client, int args)
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
	
	if (g_cvWaitExtendTime.FloatValue <= 0.0)
	{
		RF2_ReplyToCommand(client, "%t", "DisabledByServer");
		return Plugin_Handled;
	}
	
	if (IsVoteInProgress())
	{
		RF2_ReplyToCommand(client, "%t", "VoteInProgress");
		return Plugin_Handled;
	}
	
	if (g_bWaitingForPlayers)
	{
		if (GetTotalHumans(false) <= 1)
		{
			ConVar waitTime = FindConVar("mp_waitingforplayers_time");
			float oldWaitTime = waitTime.FloatValue;
			waitTime.FloatValue = g_cvWaitExtendTime.FloatValue;
			InsertServerCommand("mp_waitingforplayers_restart 1");
			CreateTimer(1.2, Timer_ResetWaitTime, oldWaitTime, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			Menu vote = new Menu(Menu_ExtendWaitVote);
			vote.SetTitle("Extend waiting for players? (%N)", client);
			vote.AddItem("Yes", "Yes");
			vote.AddItem("No", "No");
			vote.ExitButton = false;
			int clients[MAXTF2PLAYERS];
			int clientCount;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || GetClientTeam(i) <= 1 || IsFakeClient(i))
					continue;
				
				clients[clientCount] = i;
				clientCount++;
			}
			
			vote.DisplayVote(clients, clientCount, 10);
		}
		
	}
	else
	{
		RF2_ReplyToCommand(client, "%t", "WaitingInactive");
	}
	
	return Plugin_Handled;
}

public int Menu_ExtendWaitVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_VoteEnd:
		{
			if (param1 == 0 && g_bWaitingForPlayers)
			{
				ConVar waitTime = FindConVar("mp_waitingforplayers_time");
				float oldWaitTime = waitTime.FloatValue;
				waitTime.FloatValue = g_cvWaitExtendTime.FloatValue;
				InsertServerCommand("mp_waitingforplayers_restart 1");
				CreateTimer(1.2, Timer_ResetWaitTime, oldWaitTime, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public Action Timer_ResetWaitTime(Handle timer, float value)
{
	FindConVar("mp_waitingforplayers_time").FloatValue = value;
	return Plugin_Continue;
}

public Action Command_Discord(int client, int args)
{
	RF2_ReplyToCommand(client, "Risk Fortress 2 Discord: {yellow}https://discord.gg/jXje8aKMQK");
	return Plugin_Handled;
}

public Action Command_SurvivorQueue(int client, int args)
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
	
	ArrayList players = new ArrayList();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		players.Push(i);
	}
	
	players.SortCustom(SortSurvivorListByPoints2);
	int player;
	char info[16], display[256];
	Menu menu = new Menu(Menu_SurvivorQueue);
	menu.SetTitle("Survivor Queue List");
	for (int i = 0; i < players.Length; i++)
	{
		player = players.Get(i);
		FormatEx(info, sizeof(info), "player_%i", player);
		FormatEx(display, sizeof(display), "%N [%i]", player, RF2_GetSurvivorPoints(player));
		menu.AddItem(info, display, ITEMDRAW_DISABLED);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
	delete players;
	return Plugin_Handled;
}

public int SortSurvivorListByPoints2(int index1, int index2, ArrayList array, Handle hndl)
{
	int client1 = array.Get(index1);
	int client2 = array.Get(index2);
	bool survivor1 = GetCookieBool(client1, g_coBecomeSurvivor);
	bool survivor2 = GetCookieBool(client2, g_coBecomeSurvivor);
	if (!survivor1 && !survivor2)
	{
		return 0;
	}
	else if (!survivor1)
	{
		return 1;
	}
	else if (!survivor2)
	{
		return -1;
	}
	
	return RF2_GetSurvivorPoints(client1) > RF2_GetSurvivorPoints(client2) ? -1 : 1;
}

public int Menu_SurvivorQueue(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public Action Command_ItemLog(int client, int args)
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
	
	ShowItemLogbook(client);
	return Plugin_Handled;
}

void ShowItemLogbook(int client, int position=0)
{
	Menu logbook = new Menu(Menu_ItemLog);
	char info[16], display[MAX_NAME_LENGTH], quality[32];
	ArrayList items = GetSortedItemList(_, _, _, true);
	int item, count;
	for (int i = 0; i < items.Length; i++)
	{
		item = items.Get(i);
		if (IsItemInLogbook(client, item))
		{
			IntToString(item, info, sizeof(info));
			GetQualityName(GetItemQuality(item), quality, sizeof(quality));
			FormatEx(display, sizeof(display), "%s (%s)", g_szItemName[item], quality);
			logbook.AddItem(info, display);
			count++;
		}
	}
	
	// in case someone has somehow 100% cleared the logbook before the achievement...
	SetAchievementProgress(client, ACHIEVEMENT_FULLITEMLOG, count);
	logbook.SetTitle("Item Logbook (%i/%i items collected)", count, items.Length);
	delete items;
	logbook.DisplayAt(client, position, MENU_TIME_FOREVER);
}

public int Menu_ItemLog(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			g_iPlayerLastItemLogItem[param1] = GetMenuSelectionPosition();
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			int item = StringToInt(info);
			ShowItemInfo(param1, item);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

void ShowItemInfo(int client, int item)
{
	Menu menu = new Menu(Menu_ItemInfo);
	menu.ExitBackButton = true;
	
	char quality[32];
	GetQualityName(GetItemQuality(item), quality, sizeof(quality));
	menu.SetTitle("%s (%s)", g_szItemName[item], quality);
	
	if (IsEquipmentItem(item))
	{
		char cooldown[32];
		FormatEx(cooldown, sizeof(cooldown), "Cooldown: %.1f seconds", g_flEquipmentItemCooldown[item]);
		menu.AddItem("cooldown", cooldown, ITEMDRAW_DISABLED);
		
		if (g_flEquipmentItemMinCooldown[item] > 0.0)
		{
			FormatEx(cooldown, sizeof(cooldown), "Minimum Cooldown: %.1f seconds", g_flEquipmentItemMinCooldown[item]);
			menu.AddItem("min_cooldown", cooldown, ITEMDRAW_DISABLED);
		}
	}
	
	menu.AddItem("desc", g_szItemDesc[item], ITEMDRAW_DISABLED);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_ItemInfo(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowItemLogbook(param1, g_iPlayerLastItemLogItem[param1]);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public Action Command_UseStrange(int client, int args)
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
	
	if (!IsPlayerAlive(client) || GetPlayerEquipmentItem(client) == Item_Null)
	{
		return Plugin_Handled;
	}
	
	if (!ActivateStrangeItem(client))
	{
		EmitGameSoundToClient(client, "Player.DenyWeaponSelection");
	}

	return Plugin_Handled;
}

public Action Command_Interact(int client, int args)
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
	
	OnCallForMedic(client);
	return Plugin_Handled;
}

public Action Command_Ping(int client, int args)
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
	
	if (IsPlayerSurvivor(client) && g_flPlayerTimeSinceLastPing[client]+PING_COOLDOWN < GetTickedTime())
	{
		if (PingObjects(client))
		{
			g_flPlayerTimeSinceLastPing[client] = GetTickedTime();
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Achievements(int client, int args)
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
	
	ShowAchievementsMenu(client);
	return Plugin_Handled;
}

void ShowAchievementsMenu(int client)
{
	Menu menu = new Menu(Menu_Achievements);
	menu.SetTitle("Achievements");
	menu.AddItem("unlocked", "Unlocked Achievements");
	menu.AddItem("locked", "Locked Achievements");
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Achievements(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[16], name[64];
			menu.GetItem(param2, info, sizeof(info));
			bool unlocked = strcmp2(info, "unlocked");
			Menu list = new Menu(Menu_AchievementsDesc);
			list.ExitBackButton = true;
			list.SetTitle(unlocked ? "Unlocked Achievements" : "Locked Achievements");
			for (int i = 0; i < MAX_ACHIEVEMENTS; i++)
			{
				if (unlocked ? IsAchievementUnlocked(param1, i) : !IsAchievementUnlocked(param1, i) && !IsAchievementHidden(i))
				{
					FormatEx(info, sizeof(info), "%i", i);
					GetAchievementName(i, name, sizeof(name), param1);
					int cap = GetAchievementGoal(i);
					if (cap > 1)
					{
						Format(name, sizeof(name), "%s (%i/%i)", name, GetAchievementProgress(param1, i), cap);
					}
					
					list.AddItem(info, name);
				}
			}
			
			list.Display(param1, MENU_TIME_FOREVER);
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public int Menu_AchievementsDesc(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[16], desc[512];
			menu.GetItem(param2, info, sizeof(info));
			GetAchievementDesc(StringToInt(info), desc, sizeof(desc), param1);
			PrintHintText(param1, desc);
			menu.DisplayAt(param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowAchievementsMenu(param1);
			}
		}
		
		case MenuAction_End:
		{
			if (param1 != MenuEnd_Selected)
				delete menu;
		}
	}
	
	return 0;
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
			RF2_SetSurvivorPoints(clients[i], RF2_GetSurvivorPoints(clients[i])+amount);
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
	
	RF2_Object_Teleporter teleporter = GetCurrentTeleporter();
	if (!teleporter.IsValid() || g_bTankBossMode || teleporter.EventState == TELE_EVENT_ACTIVE || IsStageCleared())
	{
		RF2_ReplyToCommand(client, "%t", "CannotBeUsed");
		return Plugin_Handled;
	}
	
	if (g_bGracePeriod)
	{
		EndGracePeriod();
	}
	
	teleporter.Prepare();
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
	
	ShowBossSpawnMenu(client);
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
	
	ShowEnemySpawnMenu(client);
	return Plugin_Handled;	
}

void ShowBossSpawnMenu(int client)
{
	Menu menu = new Menu(Menu_SpawnBoss);
	char buffer[128], info[16], bossName[256];
	menu.SetTitle("%T", "SpawnAs", client);
	for (int i = 0; i < GetEnemyCount(); i++)
	{
		if (!EnemyByIndex(i).IsBoss)
			continue;
		
		EnemyByIndex(i).GetName(bossName, sizeof(bossName));
		strcopy(buffer, sizeof(buffer), bossName);
		FormatEx(info, sizeof(info), "%i", i);
		menu.AddItem(info, buffer);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_SpawnBoss(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[8];
			menu.GetItem(param2, info, sizeof(info));
			int type = StringToInt(info);
			int target = GetRandomPlayer(TEAM_ENEMY, false);
			if (!IsValidClient(target))
			{
				target = GetRandomPlayer(TEAM_ENEMY, true);
			}
			
			if (IsValidClient(target))
			{
				RefreshClient(target);
				float pos[3];
				GetEntPos(param1, pos);
				char bossName[256];
				SpawnBoss(target, type, pos, false, 0.0, 3000.0);
				EnemyByIndex(type).GetName(bossName, sizeof(bossName));
				RF2_PrintToChat(param1, "%t", "SpawnedBoss", bossName);
			}
			else
			{
				RF2_PrintToChat(param1, "%t", "NoValidTargets");
			}
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

void ShowEnemySpawnMenu(int client)
{
	Menu menu = new Menu(Menu_SpawnEnemy);
	char buffer[128], info[16], enemyName[256];
	menu.SetTitle("%T", "SpawnAs", client);
	for (int i = 0; i < GetEnemyCount(); i++)
	{
		if (EnemyByIndex(i).IsBoss)
			continue;
		
		EnemyByIndex(i).GetName(enemyName, sizeof(enemyName));
		strcopy(buffer, sizeof(buffer), enemyName);
		FormatEx(info, sizeof(info), "%i", i);
		menu.AddItem(info, buffer);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_SpawnEnemy(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[8];
			menu.GetItem(param2, info, sizeof(info));
			int type = StringToInt(info);
			int target = GetRandomPlayer(TEAM_ENEMY, false);
			if (!IsValidClient(target))
			{
				target = GetRandomPlayer(TEAM_ENEMY, true);
			}
			
			if (IsValidClient(target))
			{
				RefreshClient(target);
				float pos[3];
				GetEntPos(param1, pos);
				char enemyName[256];
				SpawnEnemy(target, type, pos, 0.0, 3000.0);
				EnemyByIndex(type).GetName(enemyName, sizeof(enemyName));
				RF2_PrintToChat(param1, "%t", "SpawnedEnemy", enemyName);
			}
			else
			{
				RF2_PrintToChat(param1, "%t", "NoValidTargets");
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
			if (!IsSingleplayer())
			{
				ReshuffleSurvivor(client, view_as<int>(TFTeam_Spectator));
			}
			else
			{
				return Plugin_Handled;
			}
			
			RefreshClient(client, true);
			CheckRedTeam(client);
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
		RefreshClient(client, true);
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
	char buffer[128], off[8], on[8];
	Menu menu = new Menu(Menu_ClientSettings);
	SetGlobalTransTarget(client);
	menu.SetTitle("Risk Fortress 2 Settings");
	FormatEx(off, sizeof(off), "%t", "Off");
	FormatEx(on, sizeof(on), "%t", "On");
	FormatEx(buffer, sizeof(buffer), "%t", "ToggleSurvivor", GetCookieBool(client, g_coBecomeSurvivor) ? on : off);
	menu.AddItem("rf2_become_survivor", buffer);
	if (g_cvAllowHumansInBlue.BoolValue)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "ToggleEnemy", GetCookieBool(client, g_coBecomeEnemy) ? on : off);
		menu.AddItem("rf2_become_enemy", buffer);
		
		FormatEx(buffer, sizeof(buffer), "%t", "ToggleTeleBoss", GetCookieBool(client, g_coBecomeBoss) ? on : off);
		menu.AddItem("rf2_become_boss", buffer);
	}
	
	FormatEx(buffer, sizeof(buffer), "%t", "SpecOnDeath", GetCookieBool(client, g_coSpecOnDeath) ? on : off);
	menu.AddItem("rf2_spec_on_death", buffer);
	
	FormatEx(buffer, sizeof(buffer), "%t", "StayInSpec", GetCookieBool(client, g_coStayInSpecOnJoin) ? on : off);
	menu.AddItem("rf2_stay_in_spec", buffer);
	
	FormatEx(buffer, sizeof(buffer), "%t", "ToggleMusic", GetCookieBool(client, g_coMusicEnabled) ? on : off);
	menu.AddItem("rf2_music_enabled", buffer);
	
	FormatEx(buffer, sizeof(buffer), "%t", "ToggleItemMsg", !GetCookieBool(client, g_coDisableItemMessages) ? on : off);
	menu.AddItem("rf2_disable_item_msg", buffer);
	
	FormatEx(buffer, sizeof(buffer), "%t", "ToggleItemHats", GetCookieBool(client, g_coDisableItemCosmetics) ? on : off);
	menu.AddItem("rf2_disable_item_cosmetics", buffer);
	
	FormatEx(buffer, sizeof(buffer), "%t", "ToggleItemCountDisplay", GetCookieBool(client, g_coAlwaysShowItemCounts) ? on : off);
	menu.AddItem("rf2_always_show_item_counts", buffer);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_ClientSettings(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[64];
			menu.GetItem(param2, info, sizeof(info));
			Cookie cookie = FindClientCookie(info);
			bool result = !GetCookieBool(param1, cookie);
			SetCookieBool(param1, cookie, result);
			if (strcmp2(info, "rf2_music_enabled"))
			{
				result ? PlayMusicTrack(param1) : StopMusicTrack(param1);
			}
			
			delete cookie;
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

void ShowItemMenu(int client, int inspectTarget=INVALID_ENT)
{
	if (!IsPlayerSurvivor(client) && inspectTarget == INVALID_ENT)
		return;
	
	int target = IsValidClient(inspectTarget) ? inspectTarget : client;
	Menu menu = new Menu(Menu_Items);
	char buffer[128], info[16], itemName[MAX_NAME_LENGTH];
	int itemCount;
	SetGlobalTransTarget(client);
	if (IsItemSharingEnabled() && target != inspectTarget)
	{
		int index = RF2_GetSurvivorIndex(target);
		menu.SetTitle("%t", "YourItemsShareEnabled", g_iItemsTaken[index], g_iItemLimit[index]);
	}
	else
	{
		if (client == target)
		{
			menu.SetTitle("%t", "YourItems");
		}
		else
		{
			menu.SetTitle("%t", "InspectTargetItems", target);
		}
	}
	
	int flags = target == inspectTarget ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
	char qualityName[32];
	GetQualityName(Quality_Strange, qualityName, sizeof(qualityName));
	ArrayList items = GetSortedItemList(_, _, true, true);
	int item;
	for (int i = 0; i < items.Length; i++)
	{
		item = items.Get(i);
		if (GetPlayerItemCount(target, item, true) > 0 || IsEquipmentItem(item) && GetPlayerEquipmentItem(target) == item)
		{
			itemCount++;
			GetItemName(item, itemName, sizeof(itemName), false);
			IntToString(item, info, sizeof(info));
			
			if (IsEquipmentItem(item))
			{
				FormatEx(buffer, sizeof(buffer), "%s [%s]", itemName, qualityName);
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%s [%i]", itemName, GetPlayerItemCount(target, item, true));
			}
			
			menu.AddItem(info, buffer, flags);
		}
	}
	
	delete items;
	if (itemCount == 0)
	{
		char noItems[64];
		FormatEx(noItems, sizeof(noItems), "%t", "NoItems");
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
			char info[16];
			GetMenuItem(menu, param2, info, sizeof(info));
			if (!strcmp2(info, "no_items"))
			{
				int item = StringToInt(info);
				ShowItemDesc(param1, item);
				if (g_bItemCanBeDropped[item] && GetItemQuality(item) != Quality_Community)
				{
					ShowItemDropMenu(param1, item);
				}
				else
				{
					ShowItemMenu(param1);
				}
			}
			else
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
	Menu menu = new Menu(Menu_ItemDrop);
	char info[64], itemName[MAX_NAME_LENGTH], clientName[MAX_NAME_LENGTH];
	GetItemName(item, itemName, sizeof(itemName));
	menu.SetTitle("Drop for who? (%s [%i])", itemName, GetPlayerItemCount(client, item, true));
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
			
			if (GetPlayerDroppedItemCount(param1) >= 100)
			{
				EmitSoundToClient(param1, SND_NOPE);
				PrintCenterText(param1, "You've dropped too many items at once!");
			}
			else if (StringToInt(info) == 0) // 0 means we don't care
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
					DropItem(param1, item, pos, client, 60.0);
					RF2_PrintToChat(param1, "%t", "ItemDrop", client);
				}
			}
			
			if (GetPlayerItemCount(param1, item, true) > 0)
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
			else
			{
				g_bPlayerViewingItemMenu[param1] = false;
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
	
	if (!IsPlayerSurvivor(client) && !IsPlayerMinion(client) || !g_bTankBossMode || !IsStageCleared() || GameRules_GetRoundState() == RoundState_TeamWin)
	{
		RF2_ReplyToCommand(client, "%t", "CannotBeUsed");
		return Plugin_Handled;
	}
	
	RF2_Object_Teleporter.StartVote(client, true);
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

public Action Command_HelpMenu(int client, int args)
{
	if (client == 0)
	{
		RF2_ReplyToCommand(client, "%t", "OnlyInGame");
		return Plugin_Handled;
	}
	
	ShowHelpMenu(client);
	return Plugin_Handled;
}

void ShowHelpMenu(int client)
{
	Menu menu = new Menu(Menu_HelpMenu);
	menu.SetTitle("Risk Fortress 2 - Help Menu (/rf2_helpmenu)");
	menu.AddItem("tutorial", "What is this gamemode? What's going on?");
	menu.AddItem("commands", "Show list of commands");
	menu.AddItem("discord", "Show Discord link in the chat");
	menu.Display(client, MENU_TIME_FOREVER);
	g_bPlayerOpenedHelpMenu[client] = true;
	SetCookieBool(client, g_coNewPlayer, true);
}

public int Menu_HelpMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if (strcmp2(info, "tutorial"))
			{
				ShowTutorialMenu(param1);
			}
			else if (strcmp2(info, "commands"))
			{
				ShowCommandsList(param1);
			}
			else if (strcmp2(info, "discord"))
			{
				RF2_PrintToChat(param1, "Risk Fortress 2 Discord: {yellow}https://discord.gg/jXje8aKMQK");
				ShowHelpMenu(param1);
			}
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

void ShowCommandsList(int client)
{
	Menu menu = new Menu(Menu_CommandsList);
	menu.ExitBackButton = true;
	menu.SetTitle("Risk Fortress 2 Commands List - Select to use");
	menu.AddItem("rf2_settings", "rf2_settings - Configure your settings");
	menu.AddItem("rf2_achievements", "rf2_achievements - Shows list of achievements");
	menu.AddItem("rf2_skipwait", "rf2_skipwait - Skips Waiting for Players");
	menu.AddItem("rf2_extend_wait", "rf2_extend_wait - Extends Waiting for Players time");
	menu.AddItem("rf2_discord", "rf2_discord - Shows link to Risk Fortress 2 Discord in the chat");
	menu.AddItem("rf2_helpmenu", "rf2_helpmenu - Shows the help menu");
	menu.AddItem("rf2_itemlog", "rf2_itemlog - Shows list of items that you've collected");
	menu.AddItem("rf2_endlevel", "rf2_endlevel - Used to end the round in Tank Destruction or other modes");
	menu.AddItem("rf2_reset_tutorial", "rf2_reset_tutorial - Resets tutorial messages");
	menu.AddItem("rf2_items", "rf2_items - Meant to be binded to a key, opens inventory menu. Default is [TAB/SCOREBOARD] + Call for Medic.", ITEMDRAW_DISABLED);
	menu.AddItem("rf2_use_strange", "rf2_use_strange - Meant to be binded to a key, activates Strange item. Default is R/RELOAD key", ITEMDRAW_DISABLED);
	menu.AddItem("rf2_interact", "rf2_interact - Meant to be binded to a key, functions like Call for Medic to interact with objects.", ITEMDRAW_DISABLED);
	menu.AddItem("rf2_ping", "rf2_ping - Meant to be binded to a key, pings an object you are looking at. Default is Middle Mouse/ATTACK3.", ITEMDRAW_DISABLED);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_CommandsList(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			FakeClientCommand(param1, info);
		}

		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowHelpMenu(param1);
			}
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

void ShowTutorialMenu(int client)
{
	Menu menu = new Menu(Menu_Tutorial);
	char text[512];
	FormatEx(text, sizeof(text), "%T", "Help1", client);
	menu.AddItem("msg", text, ITEMDRAW_DISABLED);
	menu.AddItem("0", "Back");
	menu.AddItem("2", "Next");
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Tutorial(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			int page = StringToInt(info);
			if (page > 0)
			{
				Menu newMenu = new Menu(Menu_Tutorial);
				char msg[512], nextPage[4];
				FormatEx(msg, sizeof(msg), "Help%i", page);
				Format(msg, sizeof(msg), "%T", msg, param1);
				newMenu.AddItem("msg", msg, ITEMDRAW_DISABLED);
				FormatEx(info, sizeof(info), "%i", page-1);
				newMenu.AddItem(info, "Back");
				if (page < 5)
				{
					FormatEx(nextPage, sizeof(nextPage), "%i", page+1);
					newMenu.AddItem(nextPage, "Next");
				}

				newMenu.Display(param1, MENU_TIME_FOREVER);
				
			}
			else
			{
				ShowHelpMenu(param1);
			}
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public Action Command_AltarTeleport(int client, int args)
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

	RF2_Object_Altar altar = RF2_Object_Altar(FindEntityByClassname(INVALID_ENT, "rf2_object_altar"));
	if (altar.IsValid())
	{
		float pos[3];
		altar.WorldSpaceCenter(pos);
		TeleportEntity(client, pos);
	}

	return Plugin_Handled;
}

public Action Command_ViewAFKTimes(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			RF2_ReplyToCommand(client, "%N AFK Time: %.1f", i, g_flPlayerAFKTime[i]);
		}
	}

	return Plugin_Handled;
}

public Action Command_SimulateCrash(int client, int args)
{
	g_bPlayerTimingOut[client] = true;
	KickClientEx(client, "Simulating Crash");
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
	SetMVMPlayerCvar(g_bExtraAdminSlot ? newVal+1 : newVal);
	FindConVar("tf_bot_quota").SetInt(MaxClients-newVal);
}

public Action Command_ParticleTest(int client, int args)
{
	if (client == 0)
	{
		RF2_ReplyToCommand(client, "%t", "OnlyInGame");
		return Plugin_Handled;
	}

	float pos[3];
	GetEntPos(client, pos, true);
	char effect[128];
	GetCmdArg(1, effect, sizeof(effect));
	switch (GetCmdArgInt(2))
	{
		case 0: SpawnInfoParticle(effect, pos, 15.0);
		case 1: TE_TFParticle(effect, pos);
		case 2: SpawnParticleViaTrigger(client, effect);
	}
	
	return Plugin_Handled;
}

public Action Command_UnlockAllAchievements(int client, int args)
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
	
	for (int i = 0; i < MAX_ACHIEVEMENTS; i++)
	{
		SetAchievementProgress(client, i, 999999999);
	}

	return Plugin_Handled;
}

public Action Command_TestHiddenSlot(int client, int args)
{
	if (!RF2_IsEnabled())
	{
		RF2_ReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}
	
	bool state = asBool(GetCmdArgInt(1));
	ToggleHiddenSlot(state);
	return Plugin_Handled;
}