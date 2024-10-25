#if defined _RF2_included
 #endinput
#endif
#define _RF2_included

#include <morecolors>
#pragma semicolon 1
#pragma newdecls required

#define MAX_SURVIVORS 8
#define TEAM_SURVIVOR 2
#define TEAM_ENEMY 3

// Items -------------------------------------------------------------------------------------------------------------------------------------
#define MAX_ITEMS 200
#define MAX_ITEM_MODIFIERS 16

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
	Item_TripleA = 11,
	Item_ClassCrown = 12,
	ItemPyro_BrigadeHelm = 13,
	Item_Dangeresque = 14,
	Item_Law = 15,
	ItemStrange_VirtualViewfinder = 16,
	Item_RoBro = 17,
	Item_Horace = 18,
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
	Item_DapperTopper = 41,
	ItemStrange_HeartOfGold = 42,
	ItemScout_MonarchWings = 43,
	ItemMedic_BlightedBeak = 44,
	ItemMedic_ProcedureMask = 45,
	ItemPyro_PyromancerMaskOld = 46,
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
	Item_Graybanns = 75,
	Item_Antlers = 76,
	ItemEngi_Toadstool = 77,
	Item_HauntedKey = 78,
	Item_MetalHelmet = 79,
	ItemStrange_Dragonborn = 80,
	ItemPyro_PyromancerMask = 81,
	ItemStrange_DemonicDome = 82,
	ItemSpy_StealthyScarf = 83,
	ItemSpy_Showstopper = 84,
	ItemSniper_VillainsVeil = 85,
	Item_BeaconFromBeyond = 86,
	ItemStrange_SpecialRing = 87,
	ItemScout_FedFedora = 88,
	ItemStrange_ModestHat = 89,
	ItemCommunity_MercMedal = 90,
	Item_AlienParasite = 91,
	Item_CheatersLament = 92,
	Item_CheatersLament_Recharging = 93,
	ItemStrange_Longwave = 94,
	ItemHeavy_GoneCommando = 95,
	ItemStrange_Botler = 96,
	Item_BedouinBandana = 97,
	Item_HauntedHat = 98,
	ItemDemo_OldBrimstone = 99,
	ItemMedic_MechaMedes = 100,
	Item_OldCrown = 101,
	ItemStrange_OneWayTicket = 102,
	ItemStrange_LittleBuddy = 103,
	Item_ApertureHat = 104,
	Item_Capacitor = 105,
	Item_Ballcap = 106,
	Item_Hachimaki = 107,
	Item_LilBitey = 108,
	Item_MaxValid,
};

enum
{
	Quality_None,
	Quality_Normal,
	Quality_Genuine,
	Quality_Unusual,
	Quality_Haunted,
	Quality_Collectors,
	Quality_Strange,
	Quality_HauntedStrange,
	Quality_Community,
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
 * Returns whether or not a given player is a boss.
 *
 * @param client			Player index.
 * @param teleporterBoss	Also check if the player is a teleporter boss (bosses that must be killed to complete the Teleporter event).
 * @return					True if player is a boss, false otherwise.
 */
native bool RF2_IsPlayerBoss(int client, bool teleporterBoss=false);

/**
 * Returns whether or not a given player is a minion.
 *
 * @param client			Player index.
 * @return					True if player is a minion, false otherwise.
 */
native bool RF2_IsPlayerMinion(int client);

/**
 * Returns the player's current Survivor index.
 * Note that this will still return a positive value for Survivors who are considered dead.
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
 * @param item			Item index.
 * @param allowMinions	If false, will always return 0 if the player is a minion.
 * @return				Amount of the item, or -1 if item index is invalid.
 */
native int RF2_GetPlayerItemAmount(int client, int item, bool allowMinions=false);

/**
 * Calculates an item modifier. Uses the formula N*M where N is the number of items and M is the item modifier.
 *
 * @param client		Player index.
 * @param item			Item index.
 * @param slot			Item modifier slot, starting from 0.
 * @param extraAmount	Extra arbitrary value to add or subtract to N.
 * @param allowMinions	If false and the player is a minion, will be calculated with an item count of 0.
 * @return				Calculation result.
 */
native float RF2_CalcItemMod(int client, int item, int slot, int extraAmount=0, bool allowMinions=false);

/**
 * Calculates an item modifier. Uses the formula 1-1/(1+M*N) where N is the number of items and M is the item modifier.
 *
 * @param client		Player index.
 * @param item			Item index.
 * @param slot			Item modifier slot, starting from 0.
 * @param extraAmount	Extra arbitrary value to add or subtract to N.
 * @param allowMinions	If false and the player is a minion, will be calculated with an item count of 0.
 * @return				Calculation result.
 */
native float RF2_CalcItemMod_Hyperbolic(int client, int item, int slot, int extraAmount=0, bool allowMinions=false);

/**
 * Calculates an item modifier. Uses the formula 1/(1+M*N) where N is the number of items and M is the item modifier.
 *
 * @param client		Player index.
 * @param item			Item index.
 * @param slot			Item modifier slot, starting from 0.
 * @param extraAmount	Extra arbitrary value to add or subtract to N.
 * @param allowMinions	If false and the player is a minion, will be calculated with an item count of 0.
 * @return				Calculation result.
 */
native float RF2_CalcItemMod_HyperbolicInverted(int client, int item, int slot, int extraAmount=0, bool allowMinions=false);

/**
 * Returns the value of the item modifier in the specified slot.
 *
 * @param item			Item index.
 * @param slot			Item modifier slot, starting from 0.
 * @return				Item modifier value.
 */
native float RF2_GetItemMod(int item, int slot);

/**
 * Rolls a random number within the min and max values. If the result of GetRandomInt(min, max) is below or equal to goal, returns true.
 *
 * @param min		Minimum random bound.
 * @param max		Maximum random bound.
 * @param goal		Goal value.
 * @param result	Optional parameter to store the result of the roll.
 * @return			True if roll succeeds, false otherwise.
 */
native bool RF2_RandChanceInt(int min, int max, int goal, int &result=0);

/**
 * Rolls a random number within the min and max values. If the result of GetRandomFloat(min, max) is below or equal to goal, returns true.
 *
 * @param min		Minimum random bound.
 * @param max		Maximum random bound.
 * @param goal		Goal value.
 * @param result	Optional parameter to store the result of the roll.
 * @return			True if roll succeeds, false otherwise.
 */
native bool RF2_RandChanceFloat(float min, float max, float goal, float &result=0.0);

/**
 * Rolls a random number within the min and max values. If the result of GetRandomInt(min, max) is below or equal to goal, returns true.
 * Factors in luck stat from the client.
 *
 * @param client	Player to use for luck factor.
 * @param min		Minimum random bound.
 * @param max		Maximum random bound.
 * @param goal		Goal value.
 * @param result	Optional parameter to store the result of the roll.
 * @return			True if roll succeeds, false otherwise.
 */
native bool RF2_RandChanceIntEx(int client, int min, int max, int goal, int &result=0);

/**
 * Rolls a random number within the min and max values. If the result of GetRandomFloat(min, max) is below or equal to goal, returns true.
 * Factors in luck stat from the client.
 * 
 * @param client	Player to use for luck factor.
 * @param min		Minimum random bound.
 * @param max		Maximum random bound.
 * @param goal		Goal value.
 * @param result	Optional parameter to store the result of the roll.
 * @return			True if roll succeeds, false otherwise.
 */
native bool RF2_RandChanceFloatEx(int client, float min, float max, float goal, float &result=0.0);

/**
 * Returns the player's current equipment item.
 *
 * @param client		Player index.
 * @return				Player's current equipment item, or Item_Null if they have none.
 */
native int RF2_GetPlayerEquipmentItem(int client);

/**
 * Returns the proc coefficient of the item.
 *
 * @param item			Item index.
 * @return				Item's proc coefficient.
 */
native float RF2_GetItemProcCoeff(int item);

/**
 * Returns the quality of the item
 *
 * @param item			Item index.
 * @return				Item quality.
 */
native int RF2_GetItemQuality(int item);

/**
 * Returns the total number of items that are currently loaded.
 *
 * @return		Number of items loaded.
 */
native int RF2_GetTotalItems();

/**
 * Finds an item using its KeyValues file name and section name.
 *
 * @param fileName		Custom items file name.
 * @param sectionName	Item section name.
 * @return				Item index, or Item_Null if no item was found.
 */
native int RF2_FindCustomItem(const char[] fileName, const char[] sectionName);

/**
 * Returns whether or not the item is a custom item that was loaded from the custom_items directory.
 *
 * @param item			Item index.
 * @return				True if the item is a custom item, false otherwise.
 */
stock bool RF2_IsCustomItem(int item)
{
	return item >= Item_MaxValid && item < RF2_GetTotalItems();
}

/**
 * Gives a player items.
 *
 * @param client		Player index.
 * @param item			Item index.
 * @param amount		Amount to give. Negative values can be passed to take away items.
 */
native void RF2_GivePlayerItem(int client, int item, int amount);

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
 * Shoots a projectile. Note that spell projectiles (e.g tf_projectile_spellfireball) will only work with player entities.
 * Supports projectiles that use rf2_projectile_base (e.g rf2_projectile_shuriken).
 *
 * @param owner			Owner entity.
 * @param classname		Projectile entity classname.
 * @param pos			Position.
 * @param angles		Angles.
 * @param speed			Projectile speed.
 * @param damage		Projectile damage. -1.0 will use the projectile's default damage.
 * @param arc			Vertical movement arc.
 * @param allowCrit		If the projectile has m_bCritical and the owner is a player, try to roll for a random crit.
 * @param spawn			Whether or not the projectile should be spawned immediately after creation.
 * @return				Projectile entity index, or INVALID_ENT_REFERENCE on failure.
 */
native int RF2_ShootProjectile(int owner=INVALID_ENT_REFERENCE, const char[] classname, const float pos[3], const float angles[3], 
	float speed, float damage=-1.0, float arc=0.0, bool allowCrit=true, bool spawn=true);

/** 
 * Does damage to entities in the specified radius.
 * 
 * @param attacker 			Entity responsible for the daamge.
 * @param inflictor 		Entity dealing the damage.
 * @param pos 				Position to deal damage from.
 * @param item 				Item index associated with the damage, if any. Only works if attacker is a client.
 * @param baseDamage 		Base damage.
 * @param damageFlags 		Damage flags.
 * @param radius 			Radius of the damage.
 * @param minFalloffMult	Minimum damage falloff.
 * @param allowSelfDamage	Allow self damage.
 * @param blacklist			ArrayList of entities to ignore when dealing damage.
 * @param returnHitEnts		If true, return an ArrayList of entities that were hit.
 *
 * @return If returnHitEnts is TRUE, return ArrayList of hit entities, otherwise return NULL.
 */
native ArrayList RF2_DoRadiusDamage(int attacker, int inflictor, const float pos[3], int item=Item_Null, float baseDamage, int damageFlags, 
	float radius, float minFalloffMult=0.3, bool allowSelfDamage=false, ArrayList blacklist=null, bool returnHitEnts=false);

/**
 * Applies damage to an entity. 
 * Can associate an item with the damage dealt using the `procItem` parameter.
 *
 * @param entity         Entity index taking damage
 * @param inflictor      Inflictor entity index
 * @param attacker       Attacker entity index
 * @param damage         Amount of damage
 * @param damageType     Bitfield of damage types
 * @param procItem		 The item type associated with the damage
 * @param weapon         Weapon index (orangebox and later) or -1 for unspecified
 * @param damageForce    Velocity of damage force
 * @param damagePosition Origin of damage
 */
native void RF2_TakeDamage(int entity, int inflictor, int attacker, float damage, int damageType=0, int procItem=Item_Null, 
	int weapon=INVALID_ENT_REFERENCE, const float damageForce[3]=NULL_VECTOR, const float damagePosition[3]=NULL_VECTOR);

/**
 * Sets the item type associated with this entity.
 * 
 * @param entity		Entity index
 * @param item			Item type
 * @noreturn
 */
native void RF2_SetEntItemProc(int entity, int item);

/**
 * Returns the item type associated with this entity.
 * 
 * @param entity		Entity index
 * @return				Item type associated with the entity, or Item_Null if there is none.
 */
native int RF2_GetEntItemProc(int entity);

/**
 * Returns the maximum number of stages (the number of stages before a loop occurs).
 *
 * @return			Maximum stage number.
 */
native int RF2_GetMaxStages();

/**
 * Returns the current stage number (NOT the number of stages completed; use RF2_GetCompletedStages() for that)
 *
 * @return			Current stage number.
 */
native int RF2_GetCurrentStage();

/**
 * Returns the number of stages that have been completed.
 *
 * @return			Completed stage count.
 */
native int RF2_GetCompletedStages();

/**
 * Returns the number of times the game has been looped.
 *
 * @return			Loop count.
 */
native int RF2_GetLoopCount();

/**
 * Returns the current Teleporter entity.
 *
 * @return			Teleporter entity index, or -1 if there is none present.
 */
native int RF2_GetTeleporterEntity();

/**
 * Returns whether or not Tank Destruction Mode is active.
 *
 * @return			True if active, false otherwise.
 */
native bool RF2_IsTankDestructionMode();

/** 
 * Called when an entity takes damage.
 * 
 * @param victim			Entity taking damage
 * @param attacker 			Entity responsible for the damage
 * @param inflictor 		Entity dealing the damage
 * @param damage			Damage being dealt
 * @param damageType		Damage flags
 * @param weapon			Weapon entity index if present
 * @param damageForce		Velocity of damage force
 * @param damagePosition	Origin of damage
 * @param damageCustom		Custom damage type
 * @param attackerItem		Item associated with the attacker, usually set if the attacker is a client
 * @param inflictorItem		Item associated with the inflictor, usually set if the inflictor is something like a projectile triggered by an item
 * @param critType			Crit type. 0 = none, 1 = crit, 2 = mini-crit
 * @param procCoeff			Proc coefficient
 * @return Plugin_Stop/Plugin_Handled to prevent damage, Plugin_Changed if any parameters are changed, Plugin_Continue otherwise
 */
forward Action RF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, 
	float damageForce[3], float damagePosition[3], int damageCustom, int attackerItem, int inflictorItem, int &critType, float &procCoeff);

/**
 * Called when an item is loaded from a custom items file in the `configs/rf2/custom_items/` directory.
 * 
 * @param fileName			The name of the custom items file, with the .cfg extension included.
 * @param sectionName		The item's section name in the file.
 * @param index				The item's index. Note that this is NOT the item_type key, but a value assigned at runtime. You should cache this value globally.
 */
forward void RF2_OnCustomItemLoaded(const char[] fileName, const char[] sectionName, int index);

/**
 * Called when an item is updated on a player (e.g. an item is picked up or dropped).
 * 
 * @param client			Player index.
 * @param item				Item index.
 */
forward void RF2_OnPlayerItemUpdate(int client, int item);

// Called when the Teleporter event is started.
forward void RF2_OnTeleporterEventStart();

// Called when the Teleporter event ends. 
// This is also called if the level is marked as cleared for any other reason, such as destroying the last Tank in Tank Destruction Mode.
forward void RF2_OnTeleporterEventEnd();

// Called when the grace period has begun.
forward void RF2_OnGracePeriodStart();

// Called when the grace period has ended.
forward void RF2_OnGracePeriodEnd();

// Prints a message to a client with the [RF2] tag. Uses the same parameters and supports color tags.
stock void RF2_PrintToChat(int client, const char[] message, any ...)
{
	char buffer[512];
	VFormat(buffer, sizeof(buffer), message, 3);
	CPrintToChat(client, "{lightseagreen}[RF2] {default}%s", buffer);
}

// Prints a message to all clients with the [RF2] tag. Uses the same parameters and supports color tags.
stock void RF2_PrintToChatAll(const char[] message, any ...)
{
	char buffer[512];
	VFormat(buffer, sizeof(buffer), message, 2);
	CPrintToChatAll("{lightseagreen}[RF2] {default}%s", buffer);
}

// Replies to a command with the [RF2] tag. Uses the same parameters and supports color tags.
stock void RF2_ReplyToCommand(int client, const char[] message, any ...)
{
	char buffer[512];
	VFormat(buffer, sizeof(buffer), message, 3);
	if (client == 0)
	{
		CRemoveTags(buffer, sizeof(buffer));
	}
	
	CReplyToCommand(client, "{lightseagreen}[RF2] {default}%s", buffer);
}

public SharedPlugin __pl_rf2 =
{
	name = "rf2",
	file = "rf2.smx",
#if defined REQUIRE_PLUGIN
		required = 1,
#else
		required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_rf2_SetNTVOptional()
{
	MarkNativeAsOptional("RF2_IsRF2Enabled");
	MarkNativeAsOptional("RF2_IsPlayerBoss");
	MarkNativeAsOptional("RF2_IsPlayerMinion");
	MarkNativeAsOptional("RF2_GetPlayerItemAmount");
	MarkNativeAsOptional("RF2_CalcItemMod");
	MarkNativeAsOptional("RF2_CalcItemMod_Hyperbolic");
	MarkNativeAsOptional("RF2_CalcItemMod_HyperbolicInverted");
	MarkNativeAsOptional("RF2_GetItemMod");
	MarkNativeAsOptional("RF2_RandChanceInt");
	MarkNativeAsOptional("RF2_RandChanceFloat");
	MarkNativeAsOptional("RF2_RandChanceIntEx");
	MarkNativeAsOptional("RF2_RandChanceFloatEx");
	MarkNativeAsOptional("RF2_GetPlayerEquipmentItem");
	MarkNativeAsOptional("RF2_GetItemProcCoeff");
	MarkNativeAsOptional("RF2_GetItemQuality");
	MarkNativeAsOptional("RF2_GetTotalItems");
	MarkNativeAsOptional("RF2_FindCustomItem");
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
	MarkNativeAsOptional("RF2_ShootProjectile");
	MarkNativeAsOptional("RF2_DoRadiusDamage");
	MarkNativeAsOptional("RF2_TakeDamage");
	MarkNativeAsOptional("RF2_SetEntItemProc");
	MarkNativeAsOptional("RF2_GetEntItemProc");
	MarkNativeAsOptional("RF2_GetMaxStages");
	MarkNativeAsOptional("RF2_GetCurrentStage");
	MarkNativeAsOptional("RF2_GetCompletedStages");
	MarkNativeAsOptional("RF2_GetLoopCount");
	MarkNativeAsOptional("RF2_GetTeleporterEntity");
	MarkNativeAsOptional("RF2_IsTankDestructionMode");
}
#endif
