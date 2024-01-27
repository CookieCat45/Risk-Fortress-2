#if defined _RF2_included
 #endinput
#endif
#define _RF2_included

#pragma semicolon 1
#pragma newdecls required

// Players -------------------------------------------------------------------------------------------------------------------------------------
#define TEAM_SURVIVOR view_as<int>(TFTeam_Red)
#define TEAM_ENEMY view_as<int>(TFTeam_Blue)
#define MAX_SURVIVORS 8

// Items -------------------------------------------------------------------------------------------------------------------------------------
enum
{
	Item_Null = 0,
	Item_TombReaders = 1,
	Item_PrideScarf = 2,
	Item_EyeCatcher = 3,
	Item_MaimLicense = 4,
	Item_RobinWalkers = 5,
	Item_RoundedRifleman = 6,
	Item_Archimedes = 7,
	Item_PointAndShoot = 8,
	Item_PocketMedic = 9,
	Item_BanditsBoots = 10,
	Item_BoomBoxers = 11,
	Item_ClassCrown = 12,
	Item_ProofOfPurchase = 13,
	Item_Dangeresque = 14,
	Item_Law = 15,
	ItemStrange_VirtualViewfinder = 16,
	ItemStrange_RoBro = 17,
	ItemStrange_Spellbook = 18,
	Item_HorsemannHead = 19,
	Item_Monoculus = 20,
	Item_SaxtonHat = 21,
	Item_ScrapMetal = 22,
	Item_ReclaimedMetal = 23,
	Item_RefinedMetal = 24,
	ItemSpy_NohMercy = 25,
	ItemMedic_WeatherMaster = 26,
	Item_KillerExclusive = 27,
	Item_WhaleBoneCharm = 28,
	Item_BruiserBandana = 29,
	Item_Executioner = 30,
	Item_PillarOfHats = 31,
	Item_CrypticKeepsake = 32,
	Item_HorrificHeadsplitter = 33,
	Item_Tux = 34,
	Item_LuckyCatHat = 35,
	Item_MisfortuneFedora = 36,
	Item_DarkHelm = 37,
	Item_UFO = 38,
	Item_Goalkeeper = 39,
	ItemSpy_CounterfeitBillycock = 40,
	Item_PrinnyPouch = 41,
	ItemStrange_HeartOfGold = 42,
	ItemScout_MonarchWings = 43,
	ItemMedic_BlightedBeak = 44,
	ItemMedic_ProcedureMask = 45,
	ItemPyro_PyromancerMask = 46,
	ItemEngi_Teddy = 47,
	ItemEngi_HeadOfDefense = 48,
	ItemSniper_HolyHunter = 49,
	ItemEngi_BrainiacHairpiece = 50,
	ItemDemo_ConjurersCowl = 51,
	ItemSoldier_Compatriot = 52,
	ItemHeavy_ToughGuyToque = 53,
	Item_BatteryCanteens = 54,
	ItemStrange_NastyNorsemann = 55,
	Item_Marxman = 56,
	ItemStrange_ScaryMask = 57,
	ItemStrange_DarkHunter = 58,
	ItemStrange_LegendaryLid = 59,
	ItemStrange_CroneDome = 60,
	ItemStrange_HandsomeDevil = 61,
	ItemSoldier_WarPig = 62,
	ItemHeavy_Pugilist = 63,
	ItemPyro_LastBreath = 64,
	Item_SaintMark = 65,
	ItemDemo_ScotchBonnet = 66,
	ItemScout_LongFallBoots = 67,
	ItemSniper_Bloodhound = 68,
	ItemSoldier_HawkWarrior = 69,
	Item_DeusSpecs = 70,
	Item_MaxHead = 71,
	ItemStrange_PartyHat = 72,
	ItemStrange_RobotChicken = 73,
	Item_SpiralSallet = 74,
	Item_MaxValid,
};

enum
{
	Quality_None = -1,
	Quality_Normal,
	Quality_Genuine,
	Quality_Unusual,
	Quality_Haunted,
	Quality_Collectors,
	Quality_Strange,
	Quality_HauntedStrange,
	Quality_MaxValid,
};

// Difficulty -------------------------------------------------------------------------------------------------------------------------------------
enum
{
	DIFFICULTY_SCRAP,
	DIFFICULTY_IRON,
	DIFFICULTY_STEEL,
	DIFFICULTY_TITANIUM,
	DIFFICULTY_MAX,
};

#define	DifficultyFactor_Scrap 0.75
#define	DifficultyFactor_Iron 1.0
#define	DifficultyFactor_Steel 1.5
#define DifficultyFactor_Titanium 2.0

enum
{
	SubDifficulty_Easy,
	SubDifficulty_Normal,
	SubDifficulty_Hard,
	SubDifficulty_VeryHard,
	SubDifficulty_Insane,
	SubDifficulty_Impossible,
	SubDifficulty_ISeeYou,
	SubDifficulty_ComingForYou,
	SubDifficulty_Hahaha,
};

/**
 * Returns whether or not RF2 is currently enabled.
 *
 * @return		True if RF2 is enabled, false otherwise.
 */
native bool RF2_IsEnabled();

/**
 * Returns whether a player is considered stun immune or not. (stun immune players can still be slowed.)
 *
 * @param client	Player index.
 * @return			True if player can be stunned, false otherwise.
 */
native bool RF2_CanBeStunned(int client);

/**
 * Checks whether or not a player is a boss.
 *
 * @param client			Player index.
 * @param teleporterBoss	Also check if the player is a teleporter boss (bosses that must be killed to complete the Teleporter event).
 * @return					True if player is a boss, false otherwise.
 */
native bool RF2_IsPlayerBoss(int client, bool teleporterBoss=false);

/**
 * Returns the player's current Survivor index.
 *
 * @param client	Player index.
 * @return			Player's Survivor index. -1 if the player is not a Survivor. 
 */
native int RF2_GetSurvivorIndex(int client);

/**
 * Returns the player's Survivor level.
 *
 * @param client	Player index.
 * @return			Player's Survivor level. -1 if the player is not a Survivor. 
 */
native int RF2_GetSurvivorLevel(int client);

/**
 * Returns the amount of an item that a player has.
 *
 * @param client		Player index.
 * @param itemIdx		Item index.
 * @return			Amount of the item, or -1 if item index is invalid.
 */
native int RF2_GetPlayerItemAmount(int client, int itemIdx);

/**
 * Gives a player items.
 *
 * @param client		Player index.
 * @param itemIdx		Item index.
 * @param amount		Amount to give. Negative values can be passed to take away items.
 */
native void RF2_GivePlayerItem(int client, int itemIdx, int amount);

/**
 * Returns the enemy level.
 *
 * @return			Enemy level. 
 */
native int RF2_GetEnemyLevel();

/**
 * Returns the number of Survivors that were present at the beginning of the level (meaning killed and disconnected Survivors still count).
 *
 * @return			Number of Survivors.
 */
native int RF2_GetSurvivorCount();

/**
 * Gets the Survivor queue points of a player.
 *
 * @param client	Player index.
 * @return			Survivor queue points of player.
 */
native int RF2_GetSurvivorPoints(int client);

/**
 * Sets the Survivor queue points of a player.
 *
 * @param client	Player index.
 * @param points	New points value.
 */
native void RF2_SetSurvivorPoints(int client, int points);

/**
 * Returns the current difficulty coefficient value.
 *
 * @return			Difficulty coefficient.
 */
native float RF2_GetDifficultyCoeff();

/**
 * Returns the current sub difficulty (Easy, Normal, ...)
 *
 * @return			Sub difficulty value.
 */
native int RF2_GetSubDifficulty();

/**
 * Returns the game difficulty (Scrap, Iron, Steel, ...)
 *
 * @return			Game difficulty value.
 */
native int RF2_GetDifficulty();

/**
 * Returns the base max health stat of a player.
 *
 * @param client	Player index.
 * @return			Player base max health stat.
 */
native int RF2_GetBaseMaxHealth(int client);

/**
 * Returns the calculated max health stat of a player.
 *
 * @param client	Player index.
 * @return			Player max health stat.
 */
native int RF2_GetCalculatedMaxHealth(int client);

/**
 * Returns the base speed stat of a player.
 *
 * @param class		Class index.
 * @return			Class base speed.
 */
native float RF2_GetBaseSpeed(int client);

/**
 * Returns the fully calculated speed stat of a player.
 *
 * @param client	Player index.
 * @return			Player speed stat.
 */
native float RF2_GetCalculatedSpeed(int client);

/**
 * Returns the maximum number of stages (the number of stages before a loop occurs).
 *
 * @return			Maximum stage number.
 */
native int RF2_GetMaxStages();

/**
 * Returns the current stage number.
 *
 * @return			Current stage number.
 */
native int RF2_GetCurrentStage();

/**
 * Returns the current Teleporter entity.
 *
 * @return			Teleporter entity index, or -1 if the Teleporter event isn't active.
 */
native int RF2_GetTeleporterEntity();

/**
 * Returns whether or not Tank Destruction Mode is active.
 *
 * @return			True if active, false otherwise.
 */
native bool RF2_IsTankDestructionMode();

// Called when the Teleporter event is started.
forward void RF2_OnTeleporterEventStart();

// Called when the grace period has begun.
forward void RF2_OnGracePeriodStart();

// Called when the grace period has ended.
forward void RF2_OnGracePeriodEnd();

// Prints a message to a client with the [RF2] tag. Uses the same parameters and supports color tags.
stock void RF2_PrintToChat(int client, const char[] message, any ...)
{
	char buffer[PLATFORM_MAX_PATH];
	VFormat(buffer, sizeof(buffer), message, 3);
	CPrintToChat(client, "{lightseagreen}[RF2] {default}%s", buffer);
}

// Prints a message to all clients with the [RF2] tag. Uses the same parameters and supports color tags.
stock void RF2_PrintToChatAll(const char[] message, any ...)
{
	char buffer[PLATFORM_MAX_PATH];
	VFormat(buffer, sizeof(buffer), message, 2);
	CPrintToChatAll("{lightseagreen}[RF2] {default}%s", buffer);
}

// Replies to a command with the [RF2] tag. Uses the same parameters and supports color tags.
stock void RF2_ReplyToCommand(int client, const char[] message, any ...)
{
	char buffer[PLATFORM_MAX_PATH];
	VFormat(buffer, sizeof(buffer), message, 3);
	if (client == 0)
	{
		CRemoveTags(buffer, sizeof(buffer));
	}
	
	CReplyToCommand(client, "{lightseagreen}[RF2] {default}%s", buffer);
}

public SharedPlugin __pl_RF2 =
{
	name = "Risk Fortress 2",
	file = "rf2.smx",
	#if defined REQUIRE_PLUGIN
		required = 1,
	#else
		required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_RF2_SetNTVOptional()
{
	MarkNativeAsOptional("RF2_IsRF2Enabled");
	MarkNativeAsOptional("RF2_CanBeStunned");
	MarkNativeAsOptional("RF2_IsPlayerBoss");
	MarkNativeAsOptional("RF2_GetPlayerItemAmount");
	MarkNativeAsOptional("RF2_GivePlayerItem");
	MarkNativeAsOptional("RF2_GetEnemyLevel");
	MarkNativeAsOptional("RF2_GetSurvivorIndex");
	MarkNativeAsOptional("RF2_GetSurvivorLevel");
	MarkNativeAsOptional("RF2_GetSurvivorCount");
	MarkNativeAsOptional("RF2_GetSurvivorPoints");
	MarkNativeAsOptional("RF2_SetSurvivorPoints");
	MarkNativeAsOptional("RF2_GetDifficultyCoeff");
	MarkNativeAsOptional("RF2_GetSubDifficulty");
	MarkNativeAsOptional("RF2_GetDifficulty");
	MarkNativeAsOptional("RF2_GetBaseMaxHealth");
	MarkNativeAsOptional("RF2_GetCalculatedMaxHealth");
	MarkNativeAsOptional("RF2_GetBaseSpeed");
	MarkNativeAsOptional("RF2_GetCalculatedSpeed");
	MarkNativeAsOptional("RF2_GetMaxStages");
	MarkNativeAsOptional("RF2_GetCurrentStage");
	MarkNativeAsOptional("RF2_GetTeleporterEntity");
	MarkNativeAsOptional("RF2_IsTankDestructionMode");
}
#endif
