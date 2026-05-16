#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <rf2>
#include <tf2attributes>
#include <tf2_stocks>


#pragma semicolon 1
#pragma newdecls required


#define MAX_CUSTOM_CONDITIONS 10
#define SND_LAW_FIRE "weapons/sentry_rocket.wav"
#define SND_GLASS_BREAK "physics/glass/glass_sheet_break3.wav"
#define SND_BEEP "buttons/button17.wav"
#define SND_FINAL "weapons/cguard/charging.wav"
#define MAX_EDICTS 2049
#define DMG_DOT DMG_DROWNRECOVER
#define MAX_ITEM_NAME_LENGTH 64


// Custom conditions
bool g_CustomConditions[MAXPLAYERS + 1][MAX_CUSTOM_CONDITIONS];
/*
/	0 = Brass Bucket
/	1 = Foul Cowl
/	2 = Aimframe mark
*/

// Stranges duration display
float g_fBrassBucketBuffExpirationTime[MAXPLAYERS + 1];
float g_fFoulCowlBuffExpirationTime[MAXPLAYERS + 1];

// Accursed Apparition variables
float g_fStoredHealing[MAXPLAYERS + 1];

// Sentry ammo regen variables
bool g_bRocketRegenToggle[MAX_EDICTS];

// Batter's bracers variables
float velocity[3];

// Sucker Slug variables
float g_fActiveSlow[MAXPLAYERS + 1];

// Grim Tweeter variables
float g_flPlayerNextGrimTweeterHealTime[MAXPLAYERS + 1];

// Pyrotechnic Tote variables
float g_flPlayerNextPyrotechnicToteFireTime[MAXPLAYERS + 1];
bool g_bDontDamageOwner[MAX_EDICTS];

// Forgotten King variables
float g_fStoredDmgInstant[MAXPLAYERS + 1];
float g_fStoredDOT[MAXPLAYERS + 1];
float g_fDamagePerTick[MAXPLAYERS + 1];
int g_iForgottenKingsTicksLeft[MAXPLAYERS + 1];

// Airborne Attire variables
bool g_bIsGrounded[MAXPLAYERS + 1];
float g_fGroundTime[MAXPLAYERS + 1];
float g_fGroundedDuration[MAXPLAYERS + 1];
bool g_bHasGroundHook[MAXPLAYERS + 1];

// Peacebreaker variables
int g_isPeacebreakerRocketsRemaining[MAXPLAYERS + 1];

// Die Regime-Panzerung variables
int g_iBulletResistStacks[MAXPLAYERS + 1];
int g_iBlastResistStacks[MAXPLAYERS + 1];
int g_iMeleeResistStacks[MAXPLAYERS + 1];
int g_iCritResistStacks[MAXPLAYERS + 1];

// Barrier items variables
float g_fCurrentBarrier[MAXPLAYERS + 1];

// Voodoo Juju variables
int g_iVoodooJujuProcs[MAXPLAYERS + 1];

// Bonk Boy variables
int g_iBonkBoyStacks[MAXPLAYERS + 1];

// Mister Bones variables
float g_flPlayerNextMisterBonesProc[MAXPLAYERS + 1];

// Aimframe variables
int g_iAimframeStacks[MAXPLAYERS + 1];
bool g_bAimframeAssists[MAXPLAYERS + 1][MAXPLAYERS + 1];

// Hood of Sorrows variables
int g_iHoodOfSorrowsEquipmentCharges[MAXPLAYERS + 1];
bool g_bHoodOfSorrowsMarkedForDeath[MAXPLAYERS + 1];

// Bombinomicon variables
bool g_bLastHitByBombinomicon[MAXPLAYERS + 1][MAXPLAYERS + 1];
bool g_bKilledWithBombinomiconExplosion[MAXPLAYERS + 1];
float g_fPlayerDeathPos[MAXPLAYERS + 1][3];
float g_fPlayerDeathAngles[MAXPLAYERS + 1][3];
bool g_bPlayerExploding[MAXPLAYERS + 1];
int g_iBombinomiconDeathStacks[MAXPLAYERS + 1];
int g_iTimebombTicks[MAXPLAYERS + 1];
int greyColor[4]	= {128, 128, 128, 255};
int whiteColor[4]	= {255, 255, 255, 255};
int g_BeamSprite;
int g_HaloSprite;

// Heavy One Man Army variables
float heavyOneManArmyProcChance[MAXPLAYERS + 1];


// Timers
enum TimerSlot
{
	AccursedApparition,
	ForgottenKing,
	RemoveSlow,
	BulletResist,
	BlastResist,
	MeleeResist,
	CritResist,
	BarrierDepletion,
	BonkBoy,
	AimframeMarkOn,
	AimframeMarkOff,
	HoodOfSorrows,
	Timebomb,
	TimebombKillCheck,
	
	TimerSlotCount
}

Handle g_hTimers[MAXPLAYERS + 1][TimerSlotCount];


// Item list
int g_iParasight;
int g_iBloodBanker;
int g_iBattersBracers;
int g_iLazerGazers;
int g_iFestiveRack;
int g_iAccursedApparition;
int g_isBrassBucket;
int g_iDeadHead;
int g_iSuckerSlug;
int g_isFoulCowl;
int g_iAztecWarrior;
int g_iMachoMann;
int g_iIronLung;
int g_iGrimTweeter;
int g_iSpooktacles;
int g_iPyrotechnicTote;
int g_iBareBearBones;
int g_iForgottenKings;
int g_iSOLDIERBananades;
int g_iDEMOFusedPlates;
int g_iSCOUTAirborneAttire;
int g_isPeacebreaker;
int g_iDieRegimePanzerung;
int g_iDrGrordbortsCrest;
int g_iSightliner;
int g_iBonkBoy;
int g_iVoodooJuju;
int g_iBrimOfFire;
int g_iMisterBones;
int g_iAimframe;
int g_iHoodOfSorrows;
int g_iBombinomicon;
int g_iHEAVYOneManArmy;


char g_sItemNames[MAX_ITEMS][MAX_ITEM_NAME_LENGTH];

void SetGlobalItem(const char[] name, int index)
{
	if (!strcmp(name, "parasight"))              		{ g_iParasight = index; return; }
    if (!strcmp(name, "blood_banker"))           		{ g_iBloodBanker = index; return; }
    if (!strcmp(name, "batters_bracers"))        		{ g_iBattersBracers = index; return; }
    if (!strcmp(name, "lazer_gazers"))           		{ g_iLazerGazers = index; return; }
    if (!strcmp(name, "festive_rack"))           		{ g_iFestiveRack = index; return; }
    if (!strcmp(name, "accursed_apparition"))    		{ g_iAccursedApparition = index; return; }
    if (!strcmp(name, "brass_bucket"))          	 		{ g_isBrassBucket = index; return; }
    if (!strcmp(name, "dead_head"))              		{ g_iDeadHead = index; return; }
    if (!strcmp(name, "sucker_slug"))            		{ g_iSuckerSlug = index; return; }
    if (!strcmp(name, "foul_cowl"))              		{ g_isFoulCowl = index; return; }
    if (!strcmp(name, "aztec_warrior"))          		{ g_iAztecWarrior = index; return; }
    if (!strcmp(name, "macho_mann"))             		{ g_iMachoMann = index; return; }
    if (!strcmp(name, "iron_lung"))              		{ g_iIronLung = index; return; }
    if (!strcmp(name, "grim_tweeter"))           		{ g_iGrimTweeter = index; return; }
    if (!strcmp(name, "spooktacles_item"))      	 		{ g_iSpooktacles = index; return; }
    if (!strcmp(name, "pyrotechnic_tote"))      	 		{ g_iPyrotechnicTote = index; return; }
    if (!strcmp(name, "bare_bear_bones"))       	 		{ g_iBareBearBones = index; return; }
    if (!strcmp(name, "forgotten_kings_restless_head")) 	{ g_iForgottenKings = index; return; }
    if (!strcmp(name, "SOLDIER_bananades"))      		{ g_iSOLDIERBananades = index; return; }
    if (!strcmp(name, "DEMO_fused_plates"))      		{ g_iDEMOFusedPlates = index; return; }
    if (!strcmp(name, "SCOUT_airborne_attire"))  		{ g_iSCOUTAirborneAttire = index; return; }
    if (!strcmp(name, "peacebreaker"))           		{ g_isPeacebreaker = index; return; }
    if (!strcmp(name, "die_regime_panzerung"))   		{ g_iDieRegimePanzerung = index; return; }
    if (!strcmp(name, "dr_grordborts_crest"))    		{ g_iDrGrordbortsCrest = index; return; }
    if (!strcmp(name, "sightliner"))             		{ g_iSightliner = index; return; }
    if (!strcmp(name, "bonk_boy"))               		{ g_iBonkBoy = index; return; }
    if (!strcmp(name, "voodoo_juju"))            		{ g_iVoodooJuju = index; return; }
    if (!strcmp(name, "brim_of_fire"))           		{ g_iBrimOfFire = index; return; }
    if (!strcmp(name, "mister_bones"))           		{ g_iMisterBones = index; return; }
    if (!strcmp(name, "aimframe"))               		{ g_iAimframe = index; return; }
	if (!strcmp(name, "hood_of_sorrows"))     			{ g_iHoodOfSorrows = index; return; }
	if (!strcmp(name, "bombinomicon"))     			{ g_iBombinomicon = index; return; }
	if (!strcmp(name, "HEAVY_OneManArmy"))     			{ g_iHEAVYOneManArmy = index; return; }
}


public void OnPluginStart()
{
	// In case this plugin reloaded and item data is already loaded
	strcopy(g_sItemNames[0], MAX_ITEM_NAME_LENGTH, "parasight");
    strcopy(g_sItemNames[1], MAX_ITEM_NAME_LENGTH, "blood_banker");
    strcopy(g_sItemNames[2], MAX_ITEM_NAME_LENGTH, "batters_bracers");
    strcopy(g_sItemNames[3], MAX_ITEM_NAME_LENGTH, "lazer_gazers");
    strcopy(g_sItemNames[4], MAX_ITEM_NAME_LENGTH, "festive_rack");
    strcopy(g_sItemNames[5], MAX_ITEM_NAME_LENGTH, "accursed_apparition");
    strcopy(g_sItemNames[6], MAX_ITEM_NAME_LENGTH, "brass_bucket");
    strcopy(g_sItemNames[7], MAX_ITEM_NAME_LENGTH, "dead_head");
    strcopy(g_sItemNames[8], MAX_ITEM_NAME_LENGTH, "sucker_slug");
    strcopy(g_sItemNames[9], MAX_ITEM_NAME_LENGTH, "foul_cowl");
    strcopy(g_sItemNames[10], MAX_ITEM_NAME_LENGTH, "aztec_warrior");
    strcopy(g_sItemNames[11], MAX_ITEM_NAME_LENGTH, "macho_mann");
    strcopy(g_sItemNames[12], MAX_ITEM_NAME_LENGTH, "iron_lung");
    strcopy(g_sItemNames[13], MAX_ITEM_NAME_LENGTH, "grim_tweeter");
    strcopy(g_sItemNames[14], MAX_ITEM_NAME_LENGTH, "spooktacles_item");
    strcopy(g_sItemNames[15], MAX_ITEM_NAME_LENGTH, "pyrotechnic_tote");
    strcopy(g_sItemNames[16], MAX_ITEM_NAME_LENGTH, "bare_bear_bones");
    strcopy(g_sItemNames[17], MAX_ITEM_NAME_LENGTH, "forgotten_kings_restless_head");
    strcopy(g_sItemNames[18], MAX_ITEM_NAME_LENGTH, "SOLDIER_bananades");
    strcopy(g_sItemNames[19], MAX_ITEM_NAME_LENGTH, "DEMO_fused_plates");
    strcopy(g_sItemNames[20], MAX_ITEM_NAME_LENGTH, "SCOUT_airborne_attire");
    strcopy(g_sItemNames[21], MAX_ITEM_NAME_LENGTH, "peacebreaker");
    strcopy(g_sItemNames[22], MAX_ITEM_NAME_LENGTH, "die_regime_panzerung");
    strcopy(g_sItemNames[23], MAX_ITEM_NAME_LENGTH, "dr_grordborts_crest");
    strcopy(g_sItemNames[24], MAX_ITEM_NAME_LENGTH, "sightliner");
    strcopy(g_sItemNames[25], MAX_ITEM_NAME_LENGTH, "bonk_boy");
    strcopy(g_sItemNames[26], MAX_ITEM_NAME_LENGTH, "voodoo_juju");
    strcopy(g_sItemNames[27], MAX_ITEM_NAME_LENGTH, "brim_of_fire");
    strcopy(g_sItemNames[28], MAX_ITEM_NAME_LENGTH, "mister_bones");
    strcopy(g_sItemNames[29], MAX_ITEM_NAME_LENGTH, "aimframe");
	strcopy(g_sItemNames[30], MAX_ITEM_NAME_LENGTH, "hood_of_sorrows");
	strcopy(g_sItemNames[31], MAX_ITEM_NAME_LENGTH, "bombinomicon");
	strcopy(g_sItemNames[32], MAX_ITEM_NAME_LENGTH, "HEAVY_OneManArmy");
	
	for (int i = 0; i < sizeof(g_sItemNames); i++)
	{
		int index = RF2_FindCustomItem("custom_items_example.cfg", g_sItemNames[i]);
		SetGlobalItem(g_sItemNames[i], index);
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			HookPlayerGroundChange(client);
			if (RF2_GetPlayerItemAmount(client, g_iAimframe) > 0)
			{
				g_hTimers[client][AimframeMarkOn] = CreateTimer(RF2_GetItemMod(g_iAimframe, 0), Timer_AimframeMarkOn, client, TIMER_REPEAT| TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		g_fActiveSlow[client] = 1.0;
		g_iAimframeStacks[client] = 0;
		heavyOneManArmyProcChance[client] = RF2_GetItemMod(g_iHEAVYOneManArmy, 0);
	}
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

public void OnMapStart()
{
	PrecacheSound(SND_LAW_FIRE, true);
	PrecacheSound("rf2/sfx/custom_sounds/brass_bucket.wav", true);
	PrecacheSound("rf2/sfx/custom_sounds/foul_cowl.wav", true);
	PrecacheSound(SND_GLASS_BREAK, true);
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
    g_HaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	HookPlayerGroundChange(client);
	
	return Plugin_Continue;
}

public void HookPlayerGroundChange(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;
		
	if (!g_bHasGroundHook[client])
	{
		SDKHook(client, SDKHook_GroundEntChangedPost, OnGroundChange);
		g_bHasGroundHook[client] = true;
	}
}

public void OnClientDisconnect(int client)
{
	for (int i = 0; i < view_as<int>(TimerSlotCount); i++)
	{
		if (g_hTimers[client][i] != INVALID_HANDLE)
		{
			delete (g_hTimers[client][i]);
			g_hTimers[client][i] = INVALID_HANDLE;
		}
	}
	
	for (int i = 0; i < MAX_CUSTOM_CONDITIONS; i++)
	{
		g_CustomConditions[client][i] = false;
	}
	
	
	g_fStoredHealing[client] = 0.0;
	g_fStoredDmgInstant[client] = 0.0;
	g_fStoredDOT[client] = 0.0;
	g_fDamagePerTick[client] = 0.0;
	g_bHasGroundHook[client] = false;
	g_fActiveSlow[client] = 1.0;
	g_bPlayerExploding[client] = false;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client == 0)
        return;
		
	int attacker = GetClientOfUserId(event.GetInt("attacker"));	

    // cancel timers if they exist
    for (int i = 0; i < view_as<int>(TimerSlotCount); i++)
	{
		if (g_hTimers[client][i] != INVALID_HANDLE && i != 13)
		{
			delete (g_hTimers[client][i]);
			g_hTimers[client][i] = INVALID_HANDLE;
		}
	}
	
	for (int i = 0; i < MAX_CUSTOM_CONDITIONS; i++)
	{
		g_CustomConditions[client][i] = false;
	}
	
	g_fActiveSlow[client] = 1.0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bAimframeAssists[client][i] = false;
		
		if(g_bLastHitByBombinomicon[client][i] && i == attacker)
		{
			g_bLastHitByBombinomicon[client][i] = false;
			g_bKilledWithBombinomiconExplosion[i] = true;
		}
	}
}

public void RF2_OnCustomItemLoaded(const char[] fileName, const char[] sectionName, int index)
{
	if (!strcmp(fileName, "custom_items_example.cfg"))
    {
        SetGlobalItem(sectionName, index);
    }
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!IsValidEntity(entity))
		return;
	
	if (entity < 0 || entity >= MAX_EDICTS)
		return;
	
	g_bDontDamageOwner[entity] = false;
	
	if (IsBuilding(entity) && GetEntProp(entity, Prop_Send, "m_iObjectType") == 2)
	{
		CreateTimer(6.0, Timer_SentryAmmoRegen, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (IsSkeleton(entity))
	{
		SDKHook(entity, SDKHook_OnTakeDamageAlive, OnSkeletonDamage);
	}
}

public void OnGroundChange(int client)
{
	int groundEnt = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	
	if (groundEnt != 0)
	{
		// landed
		g_bIsGrounded[client] = true;
		g_fGroundTime[client] = GetGameTime();
	}
	else
	{
		// now airborne
		g_bIsGrounded[client] = false;
		g_fGroundedDuration[client] = GetGameTime() - g_fGroundTime[client];
	}
	
	RF2_UpdatePlayerFireRate(client);
}

public Action RF2_OnMiscTextWriting(int client, char[] miscText)
{
	if (g_fBrassBucketBuffExpirationTime[client] - GetTickedTime() > 0.0)
	{
		Format(miscText, 512, "%sBrass Bucket duration : %.1f\n", miscText, g_fBrassBucketBuffExpirationTime[client] - GetTickedTime());
	}
	
	if (g_fFoulCowlBuffExpirationTime[client] - GetTickedTime() > 0.0)
	{
		Format(miscText, 512, "%sFoul Cowl duration : %.1f\n", miscText, g_fFoulCowlBuffExpirationTime[client] - GetTickedTime());
	}
	
	if (g_fCurrentBarrier[client] > 0.0)
	{
		Format(miscText, 512, "%sBarrier Health : %.1f / %.1f\n", miscText, g_fCurrentBarrier[client], float(RF2_GetCalculatedMaxHealth(client)));
	}
	
	if (g_iAimframeStacks[client] > 0)
	{
		Format(miscText, 512, "%sAimframe stacks : %d\n", miscText, g_iAimframeStacks[client]);
	}
	
	return Plugin_Changed;
}

public void RF2_OnPlayerItemUpdate(int client, int item)
{
	int primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	int secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	
	if (item == g_iParasight || item == Item_Marxman)
	{
		float angle = 0.0;
		float spreadPenalty = 1.0;
		
		int amount = RF2_GetPlayerItemAmount(client, g_iParasight);
		
		if (amount > 0)
		{
			angle = RF2_CalcItemMod(client, item, 0);
			
			if (RF2_GetPlayerItemAmount(client, Item_Marxman) > 0)		//compensate the deviation with marxman
			{
				angle -= RF2_GetItemMod(g_iParasight, 3) * RF2_GetPlayerItemAmount(client, Item_Marxman);
				if (GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex") == 730)		//if has beggar
					angle = fmax(3.0, angle);
			}
			
			for (int i = 0; i < amount; i++)		//replacement for pow function because it doesn't work FUCK YOU
			{
				spreadPenalty *= 1.0+RF2_GetItemMod(g_iParasight, 1);
			}
		}
		
		if (primary > MaxClients && IsValidEntity(primary))
		{
			TF2Attrib_SetByName(primary, "projectile spread angle penalty", angle);
			TF2Attrib_SetByName(primary, "spread penalty", spreadPenalty);
		}
		if (secondary > MaxClients && IsValidEntity(secondary))
		{
			TF2Attrib_SetByName(secondary, "projectile spread angle penalty", angle);
			TF2Attrib_SetByName(secondary, "spread penalty", spreadPenalty);
		}
	}
	
	if (item == g_iSOLDIERBananades && TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		if (IsValidEntity(primary))
			TF2Attrib_SetByName(primary, "blast radius increased", 1.0+RF2_CalcItemMod(client, g_iSOLDIERBananades, 1));
		
		if (IsValidEntity(secondary))
		{
			int defIndex = GetEntProp(secondary, Prop_Send, "m_iItemDefinitionIndex");
			if (defIndex == 129 || defIndex == 226 || defIndex == 354)
			{
				TF2Attrib_SetByName(secondary, "increase buff duration", 1.0+RF2_CalcItemMod(client, g_iSOLDIERBananades, 0));
			}
			else
			{
				TF2Attrib_SetByName(secondary, "bullets per shot bonus", 1.0+RF2_CalcItemMod(client, g_iSOLDIERBananades, 2));
			}
		}
	}
	
	if (item == g_iDEMOFusedPlates && TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		// fire rate / reload speed is changed if player has either boots or shield equipped (or both)
		if (!HasBoots_Wearable(client) || !HasShield_Wearable(client))
		{
			RF2_UpdatePlayerFireRate(client);
		}
	}
	
	if (item == g_iAimframe && RF2_GetPlayerItemAmount(client, g_iAimframe) > 0 && g_hTimers[client][AimframeMarkOn] == INVALID_HANDLE)
	{
		g_iAimframeStacks[client] = 0;
		
		g_hTimers[client][AimframeMarkOn] = CreateTimer(RF2_GetItemMod(g_iAimframe, 0), Timer_AimframeMarkOn, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE | TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (item == g_iHEAVYOneManArmy && TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		if (secondary != -1 && IsValidEntity(secondary))
		{
			char classname[64];
			GetEntityClassname(secondary, classname, sizeof(classname));
			
			if (StrEqual(classname, "tf_weapon_shotgun_hwg"))
			{
				TF2Attrib_SetByName(secondary, "bullets per shot bonus", 1.0 + RF2_CalcItemMod(client, g_iHEAVYOneManArmy, 3));
			}
		}
	}
	
	char currentMap[64];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if (item == g_iHoodOfSorrows)
	{
		if (g_hTimers[client][HoodOfSorrows] == INVALID_HANDLE && !StrEqual(currentMap, "rf2_hellscape_r2", true) && RF2_GetPlayerItemAmount(client, g_iHoodOfSorrows) > 0)
		{
			RF2_ActivateStrangeItem(client);
		}
	}
	
	if (RF2_GetPlayerItemAmount(client, g_iHoodOfSorrows) > 0)
	{
		if (RF2_GetPlayerEquipmentItem(client) == Item_Null)
		{
			g_bHoodOfSorrowsMarkedForDeath[client] = true;
			TF2_AddCondition(client, TFCond_MarkedForDeathSilent);
		}
		else
		{
			g_bHoodOfSorrowsMarkedForDeath[client] = false;
			TF2_RemoveCondition(client, TFCond_MarkedForDeathSilent);
		}
	}
	
	if (RF2_GetPlayerEquipmentItem(client) != Item_Null)
	{
		g_bHoodOfSorrowsMarkedForDeath[client] = false;
		TF2_RemoveCondition(client, TFCond_MarkedForDeathSilent);
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (condition == TFCond_MarkedForDeathSilent && g_bHoodOfSorrowsMarkedForDeath[client])
	{
		TF2_AddCondition(client, TFCond_MarkedForDeathSilent);
	}
}

public Action RF2_OnActivateStrangeItem(int client, int equipment)
{	
	if (equipment == g_isBrassBucket)
	{
		if (HasCustomCondition(client, 0))
		{
			return Plugin_Handled;
		}
		EmitSoundToClient(client, "rf2/sfx/custom_sounds/brass_bucket.wav");
		g_fBrassBucketBuffExpirationTime[client] = GetTickedTime() + RF2_GetItemMod(g_isBrassBucket, 1);
		ApplyCustomCondition(client, 0, RF2_GetItemMod(g_isBrassBucket, 1));
	}
	if (equipment == g_isFoulCowl)
	{
		if (HasCustomCondition(client, 1))
		{
			return Plugin_Handled;
		}
		EmitSoundToClient(client, "rf2/sfx/custom_sounds/foul_cowl.wav");
		g_fFoulCowlBuffExpirationTime[client] = GetTickedTime() + RF2_GetItemMod(g_isFoulCowl, 1);
		ApplyCustomCondition(client, 1, RF2_GetItemMod(g_isFoulCowl, 1));
	}
	if (equipment == g_isPeacebreaker)
	{
		g_isPeacebreakerRocketsRemaining[client] = RoundToNearest(RF2_GetItemMod(g_isPeacebreaker, 0));
		float interval = RF2_GetItemMod(g_isPeacebreaker, 1);
		
		CreateTimer(interval, Timer_FireHomingRocket, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE | TIMER_FLAG_NO_MAPCHANGE);
	}
	
	char currentMap[64];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if (RF2_GetPlayerItemAmount(client, g_iHoodOfSorrows) > 0 && !StrEqual(currentMap, "rf2_hellscape_r2", true))
	{
		float chance = RF2_GetItemMod(g_iHoodOfSorrows, 0);
		if (RF2_RandChanceFloatEx(client, 0.0, 1.0, chance))
		{
			RF2_GivePlayerItem(client, equipment, -1);
			RF2_GivePlayerItem(client, Item_HauntedKey, 1);
		}
	}
	
	return Plugin_Continue;
}

public Action RF2_OnPlayerEquipmentItemCooldownCalculation(int client, float &cooldown)
{
	bool changed = false;
	
	if (RF2_GetPlayerItemAmount(client, g_iHoodOfSorrows) > 0)
	{
		float multiplier = 1.0 / (1.0 + RF2_GetItemMod(g_iHoodOfSorrows, 1) + RF2_CalcItemMod(client, g_iHoodOfSorrows, 2, -1));
		
		cooldown *= multiplier;
		changed = true;
	}
	
	if (changed)
		return Plugin_Changed;
	
	return Plugin_Continue;
}

public Action RF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, 
	float damageForce[3], float damagePosition[3], int damageCustom, int attackerItem, int inflictorItem, int &critType, 
	float &procCoeff)
{
	bool changed = false;
	bool selfDamage = victim == attacker;
	
	if (damageType & DMG_DOT)
	{
		if (g_fCurrentBarrier[victim] > 0.0)
		{
			if(damage > g_fCurrentBarrier[victim])
			{
				damage -= g_fCurrentBarrier[victim];
				g_fCurrentBarrier[victim] = 0.0;
			}
			else
			{
				g_fCurrentBarrier[victim] -= damage;
				damage = 0.0;
			}
			
		}
		return Plugin_Handled;
	}
	
	if (IsValidClient(attacker))
	{
		if (g_bPlayerExploding[attacker])
		{
			damage = 0.0;
			return Plugin_Handled;
		}
	}
	
	
	if (IsValidClient(victim) && IsValidClient(attacker))
	{
		if (attackerItem == g_iBombinomicon && !g_bLastHitByBombinomicon[victim][attacker])
		{
			g_bLastHitByBombinomicon[victim][attacker] = true;
		}
		else if (attackerItem != g_iBombinomicon && g_bLastHitByBombinomicon[victim][attacker])
		{
			g_bLastHitByBombinomicon[victim][attacker] = false;
		}
	}
	
	
	
	if (damageType == 4 || damageCustom == TF_CUSTOM_BLEEDING)
	{
		damageType |= DMG_PREVENT_PHYSICS_FORCE;
		changed = true;
	}
	
	if (inflictor > 0 && !ShouldDamageOwner(inflictor) && victim == GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity"))
	{
		damage = 0.0;
		damageType |= DMG_PREVENT_PHYSICS_FORCE;
		return Plugin_Changed;
	}
	
	if (IsBuilding(victim) && inflictorItem == 0)		// fuck you robro
	{
		int buildingOwner = GetEntPropEnt(victim, Prop_Send, "m_hBuilder");
		
		if (damage > 0.0 && RF2_GetPlayerItemAmount(buildingOwner, Item_SpiralSallet) > 0)
		{
			damage -= RF2_CalcItemMod(buildingOwner, Item_SpiralSallet, 0);
			changed = true;
		}
		
		if (damage > 0.0 && RF2_GetPlayerItemAmount(buildingOwner, g_iBattersBracers) > 0)
		{
			damage -= RF2_CalcItemMod(buildingOwner, g_iBattersBracers, 0);
			changed = true;
		}
	}
	
	if (IsValidClient(attacker))
	{
		if (RF2_GetPlayerItemAmount(attacker, g_iSuckerSlug) > 0 && !selfDamage && IsValidClient(victim))
		{
			float slowPercent = fclamp(RF2_GetItemMod(g_iSuckerSlug, 0) + RF2_CalcItemMod(attacker, g_iSuckerSlug, 1, -1), 0.0, 1.0);
			float duration = RF2_GetItemMod(g_iSuckerSlug, 2) + RF2_CalcItemMod(attacker, g_iSuckerSlug, 3, -1);
			float currentVictimSlow = g_fActiveSlow[victim];
			
			if (currentVictimSlow >= 1.0-slowPercent || currentVictimSlow == 0.0)
			{
				ApplySlowEffect(victim, slowPercent, duration);
			}
		}
		
		if (RF2_GetPlayerItemAmount(attacker, g_iMachoMann) > 0 && !selfDamage)
		{
			if (!(damageType & DMG_SLASH) && damageType != 2056 && RF2_GetEntItemProc(inflictor) == 0 && damageCustom != TF_CUSTOM_BLEEDING) // damageType 4 = bleeding, damageType 2056 = afterburn
			{	
				float chance = RF2_GetItemMod(g_iMachoMann, 0) * procCoeff;
				if (RF2_RandChanceFloatEx(attacker, 0.0, 1.0, chance))
				{
					float angles[3], vel[3];
					float victimPos[3], attackerPos[3];
					GetEntPos(victim, victimPos);
					GetEntPos(attacker, attackerPos);
					GetVectorAnglesTwoPoints(attackerPos, victimPos, angles);
					angles[0] = -40.0;
					GetAngleVectors(angles, vel, NULL_VECTOR, NULL_VECTOR);
					NormalizeVector(vel, vel);
					float force = (RF2_GetItemMod(g_iMachoMann, 1) + RF2_CalcItemMod(attacker, g_iMachoMann, 2, -1)) * fmax(procCoeff, 0.5);
					ScaleVector(vel, force);
					ScaleVector(vel, TF2Attrib_HookValueFloat(1.0, "damage_force_reduction", victim));
					TeleportEntity(victim, _, _, vel);
				}
			}
		}
		
		if (RF2_GetPlayerItemAmount(attacker, g_iVoodooJuju) > 0 && IsValidClient(victim) && !selfDamage && damageCustom != TF_CUSTOM_BLEEDING)
		{
			float chance = RF2_GetItemMod(g_iVoodooJuju, 3) * procCoeff;
			if (RF2_RandChanceFloatEx(attacker, 0.001, 1.0, chance))
			{
				TF2_MakeBleed(victim, attacker, RF2_GetItemMod(g_iVoodooJuju, 4));
			}
		}
		
		if (RF2_GetPlayerItemAmount(attacker, g_iBrimOfFire) > 0 && !selfDamage)
		{
			if (IsValidClient(victim))
			{
				if (!TF2_IsPlayerInCondition(victim, TFCond_OnFire))
				{
					float random = RF2_GetItemMod(g_iBrimOfFire, 1) * procCoeff;
					if (RF2_RandChanceFloatEx(attacker, 0.0, 1.0, random))
					{
						TF2_IgnitePlayer(victim, attacker);
					}
				}
				else
				{
					damage *= 1.0 + RF2_CalcItemMod(attacker, g_iBrimOfFire, 0);
					changed = true;
				}
			}
			else
			{
				damage *= 1.0 + RF2_CalcItemMod(attacker, g_iBrimOfFire, 2);
				changed = true;
			}
		}
		
		if (RF2_GetPlayerItemAmount(attacker, g_iMisterBones) > 0 && IsValidClient(victim) && !selfDamage && g_flPlayerNextMisterBonesProc[victim] <= GetTickedTime())
		{
			float random = RF2_GetItemMod(g_iMisterBones, 0) * procCoeff;
			if (RF2_RandChanceFloatEx(attacker, 0.0, 1.0, random))
			{
				float cooldown = RF2_GetItemMod(g_iMisterBones, 1);
				for (int i = 1; i < RF2_GetPlayerItemAmount(attacker, g_iMisterBones); i++)
				{
					cooldown *= 1.0 - RF2_GetItemMod(g_iMisterBones, 2);
				}
				
				g_flPlayerNextMisterBonesProc[victim] = GetTickedTime() + cooldown;
				RF2_DoItemKillEffects(attacker, inflictor, victim, damageType, critType, INVALID_ENT_REFERENCE, damageCustom);
			}
		}
		
		
		
		if (RF2_GetPlayerItemAmount(attacker, g_iDeadHead) > 0)
		{
			damage *= 1.0 + RF2_CalcItemMod(attacker, g_iDeadHead, 0);
			changed = true;
		}
		
		if (RF2_GetPlayerItemAmount(attacker, g_iParasight) > 0 && !(damageType & DMG_CLUB))
		{
			damage *= 1.0 + RF2_CalcItemMod(attacker, g_iParasight, 2);
			changed = true;
		}
		
		if (RF2_GetPlayerItemAmount(attacker, g_iAimframe) > 0 && HasCustomCondition(victim, 2))
		{
			damage *= 1.0 + RF2_GetItemMod(g_iAimframe, 3);
			g_bAimframeAssists[victim][attacker] = true;
			changed = true;
		}
		
		if (g_iAimframeStacks[attacker] > 0)
		{
			damage *= 1.0 + RF2_CalcItemMod(attacker, g_iAimframe, 2) * g_iAimframeStacks[attacker];
			changed = true;
		}
		
		if (RF2_GetPlayerItemAmount(attacker, g_iDEMOFusedPlates) > 0 && TF2_GetPlayerClass(attacker) == TFClass_DemoMan)
		{
			char classname[64];
			GetEntityClassname(inflictor, classname, sizeof(classname));
			
			if (StrEqual(classname, "tf_wearable_demoshield"))
			{
				damage *= 1.0 + RF2_CalcItemMod(attacker, g_iDEMOFusedPlates, 2);
				changed = true;
			}
		}
		
		if (RF2_GetPlayerItemAmount(attacker, g_iHEAVYOneManArmy) > 0 && TF2_GetPlayerClass(attacker) == TFClass_Heavy && (damageType & DMG_CLUB))
		{
			damage *= 1.0 + RF2_CalcItemMod(attacker, g_iHEAVYOneManArmy, 4);
			changed = true;
		}
		
		if (g_iBombinomiconDeathStacks[attacker] > 0)
		{
			float damagePenalty = Pow(0.8, float(g_iBombinomiconDeathStacks[attacker]));
			
			damage *= damagePenalty;
			changed = true;
		}
		
		if (critType != 0)		// critType 0 = no crit
		{
			if (RF2_GetPlayerItemAmount(attacker, g_iLazerGazers) > 0)
			{
				damage *= 1.0 + RF2_CalcItemMod(attacker, g_iLazerGazers, 0);
				changed = true;
			}
			
			if (RF2_GetPlayerItemAmount(attacker, g_iSpooktacles) > 0)
			{
				damage *= 1.0 + RF2_CalcItemMod(attacker, g_iSpooktacles, 0);
				changed = true;
			}
			
			if (RF2_GetPlayerItemAmount(attacker, g_iSightliner) > 0)
			{
				damage *= 1.0 + RF2_CalcItemMod(attacker, g_iSightliner, 0);
				changed = true;
			}
			
			if (RF2_GetPlayerItemAmount(attacker, g_iGrimTweeter) > 0 && g_flPlayerNextGrimTweeterHealTime[attacker] <= GetTickedTime())
			{
				if (critType == 1)	// mini-crit
				{
					RF2_HealPlayer(attacker, RoundToNearest((RF2_GetItemMod(g_iGrimTweeter, 1) + RF2_CalcItemMod(attacker, g_iGrimTweeter, 2, -1)) / 2));		// heal half if mini-crit
				}
				else
				{
					RF2_HealPlayer(attacker, RoundToNearest(RF2_GetItemMod(g_iGrimTweeter, 1) + RF2_CalcItemMod(attacker, g_iGrimTweeter, 2, -1)));		// full heal on crit
				}
				g_flPlayerNextGrimTweeterHealTime[attacker] = GetTickedTime()+0.1;
			}
		}
	}

	if (IsValidClient(victim))
	{
		if (RF2_GetPlayerItemAmount(victim, g_iDEMOFusedPlates) > 0 && TF2_GetPlayerClass(victim) == TFClass_DemoMan && HasBoots_Wearable(victim) && damageType & DMG_CLUB)
		{
			damage *= 1.0 - RF2_GetItemMod(g_iDEMOFusedPlates, 0) - RF2_CalcItemMod(victim, g_iDEMOFusedPlates, 1, -1);
			changed = true;
		}
		
		if (RF2_GetPlayerItemAmount(victim, g_iSCOUTAirborneAttire) > 0 && TF2_GetPlayerClass(victim) == TFClass_Scout && !g_bIsGrounded[victim] && g_fGroundedDuration[victim] >= 0.0)
		{
			float damageReduction = fmin(g_fGroundedDuration[victim] * RF2_GetItemMod(g_iSCOUTAirborneAttire, 2), RF2_GetItemMod(g_iSCOUTAirborneAttire, 1));
			damage *= 1.0 - damageReduction;
			changed = true;
		}
		
		if (RF2_GetPlayerItemAmount(victim, g_iBattersBracers) > 0)
		{
			GetEntPropVector(victim, Prop_Data, "m_vecVelocity", velocity);
			float speed = SquareRoot(velocity[0]*velocity[0] + velocity[1]*velocity[1] + velocity[2]*velocity[2]);
			if (speed < 5.0)
			{
				damage -= RF2_CalcItemMod(victim, g_iBattersBracers, 0);
				changed = true;
			}
		}
		
		if (RF2_GetPlayerItemAmount(victim, g_iAztecWarrior) > 0 && !selfDamage)
		{
			RF2_HealPlayer(victim, RoundToNearest(RF2_CalcItemMod(victim, g_iAztecWarrior, 0)));
		}
		
		if (RF2_GetPlayerItemAmount(victim, g_iBonkBoy) > 0 && !selfDamage)
		{
			int maxStacks = RoundToNearest(RF2_GetItemMod(g_iBonkBoy, 1) + RF2_CalcItemMod(victim, g_iBonkBoy, 2, -1));
			float duration = RF2_GetItemMod(g_iBonkBoy, 3) + RF2_CalcItemMod(victim, g_iBonkBoy, 4, -1);
			
			if (g_iBonkBoyStacks[victim] < maxStacks)
			{
				g_iBonkBoyStacks[victim] += 1;
			}
			
			if (g_hTimers[victim][BonkBoy] != INVALID_HANDLE)
			{
				delete (g_hTimers[victim][BonkBoy]);
				g_hTimers[victim][BonkBoy] = INVALID_HANDLE;
			}
			
			RF2_CalculatePlayerMaxSpeed(victim);
			g_hTimers[victim][BonkBoy] = CreateTimer(duration, Timer_RemoveBonkBoyBuff, victim, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		if (RF2_GetPlayerItemAmount(victim, g_iDieRegimePanzerung) > 0 && !selfDamage)
		{
			if (damageType & DMG_BULLET || damageType & DMG_BUCKSHOT)
			{
				g_iBulletResistStacks[victim] += 1;
				float bulletResist = 0.0;
				if (g_iBulletResistStacks[victim] <= RoundToNearest(RF2_GetItemMod(g_iDieRegimePanzerung, 4)))
				{
					bulletResist = RF2_GetItemMod(g_iDieRegimePanzerung, 0) * g_iBulletResistStacks[victim];
				}
				else
				{
					bulletResist = RF2_GetItemMod(g_iDieRegimePanzerung, 0) * RF2_GetItemMod(g_iDieRegimePanzerung, 4) + RF2_GetItemMod(g_iDieRegimePanzerung, 5) * (g_iBulletResistStacks[victim] - RoundToNearest(RF2_GetItemMod(g_iDieRegimePanzerung, 4)));
				}
				
				float bulletResistCap = RF2_GetItemMod(g_iDieRegimePanzerung, 1) + RF2_CalcItemMod(victim, g_iDieRegimePanzerung, 2, -1);
				
				if (bulletResist > bulletResistCap || bulletResist > RF2_GetItemMod(g_iDieRegimePanzerung, 3))
				{
					g_iBulletResistStacks[victim] -= 1;
					bulletResist = bulletResistCap;
					
					if (bulletResist > RF2_GetItemMod(g_iDieRegimePanzerung, 3))
					{
						bulletResist = RF2_GetItemMod(g_iDieRegimePanzerung, 3);
					}
				}
				
				if (g_hTimers[victim][BulletResist] != INVALID_HANDLE)
				{
					delete (g_hTimers[victim][BulletResist]);
					g_hTimers[victim][BulletResist] = INVALID_HANDLE;
				}
				
				g_hTimers[victim][BulletResist] = CreateTimer(RF2_GetItemMod(g_iDieRegimePanzerung, 24), Timer_RemoveBulletResist, victim, TIMER_FLAG_NO_MAPCHANGE);
				
				damage *= 1.0 - bulletResist;
				changed = true;
			}
			
			if (damageType & DMG_BLAST)
			{
				g_iBlastResistStacks[victim] += 1;
				float blastResist = 0.0;
				if (g_iBlastResistStacks[victim] <= RoundToNearest(RF2_GetItemMod(g_iDieRegimePanzerung, 10)))
				{
					blastResist = RF2_GetItemMod(g_iDieRegimePanzerung, 6) * g_iBlastResistStacks[victim];
				}
				else
				{
					blastResist = RF2_GetItemMod(g_iDieRegimePanzerung, 6) * RF2_GetItemMod(g_iDieRegimePanzerung, 10) + RF2_GetItemMod(g_iDieRegimePanzerung, 11) * (g_iBlastResistStacks[victim] - RoundToNearest(RF2_GetItemMod(g_iDieRegimePanzerung, 10)));
				}
				
				float blastResistCap = RF2_GetItemMod(g_iDieRegimePanzerung, 7) + RF2_CalcItemMod(victim, g_iDieRegimePanzerung, 8, -1);
				
				if (blastResist > blastResistCap || blastResist > RF2_GetItemMod(g_iDieRegimePanzerung, 9))
				{
					g_iBlastResistStacks[victim] -= 1;
					blastResist = blastResistCap;
					
					if (blastResist > RF2_GetItemMod(g_iDieRegimePanzerung, 9))
					{
						blastResist = RF2_GetItemMod(g_iDieRegimePanzerung, 9);
					}
				}
				
				if (g_hTimers[victim][BlastResist] != INVALID_HANDLE)
				{
					delete (g_hTimers[victim][BlastResist]);
					g_hTimers[victim][BlastResist] = INVALID_HANDLE;
				}
				
				g_hTimers[victim][BlastResist] = CreateTimer(RF2_GetItemMod(g_iDieRegimePanzerung, 24), Timer_RemoveBlastResist, victim, TIMER_FLAG_NO_MAPCHANGE);
				
				damage *= 1.0 - blastResist;
				changed = true;
			}
			
			if (damageType & DMG_CLUB)
			{
				g_iMeleeResistStacks[victim] += 1;
				float meleeResist = 0.0;
				if (g_iMeleeResistStacks[victim] <= RoundToNearest(RF2_GetItemMod(g_iDieRegimePanzerung, 16)))
				{
					meleeResist = RF2_GetItemMod(g_iDieRegimePanzerung, 12) * g_iMeleeResistStacks[victim];
				}
				else
				{
					meleeResist = RF2_GetItemMod(g_iDieRegimePanzerung, 12) * RF2_GetItemMod(g_iDieRegimePanzerung, 16) + RF2_GetItemMod(g_iDieRegimePanzerung, 17) * (g_iMeleeResistStacks[victim] - RoundToNearest(RF2_GetItemMod(g_iDieRegimePanzerung, 16)));
				}
				
				float meleeResistCap = RF2_GetItemMod(g_iDieRegimePanzerung, 13) + RF2_CalcItemMod(victim, g_iDieRegimePanzerung, 14, -1);
				
				if (meleeResist > meleeResistCap || meleeResist > RF2_GetItemMod(g_iDieRegimePanzerung, 15))
				{
					g_iMeleeResistStacks[victim] -= 1;
					meleeResist = meleeResistCap;
					
					if (meleeResist > RF2_GetItemMod(g_iDieRegimePanzerung, 15))
					{
						meleeResist = RF2_GetItemMod(g_iDieRegimePanzerung, 15);
					}
				}
				
				if (g_hTimers[victim][MeleeResist] != INVALID_HANDLE)
				{
					delete (g_hTimers[victim][MeleeResist]);
					g_hTimers[victim][MeleeResist] = INVALID_HANDLE;
				}
				
				g_hTimers[victim][MeleeResist] = CreateTimer(RF2_GetItemMod(g_iDieRegimePanzerung, 24), Timer_RemoveMeleeResist, victim, TIMER_FLAG_NO_MAPCHANGE);
				
				damage *= 1.0 - meleeResist;
				changed = true;
			}
			
			if (damageType & DMG_ACID)
			{
				g_iCritResistStacks[victim] += 1;
				float critResist = 0.0;
				if (g_iCritResistStacks[victim] <= RoundToNearest(RF2_GetItemMod(g_iDieRegimePanzerung, 22)))
				{
					critResist = RF2_GetItemMod(g_iDieRegimePanzerung, 18) * g_iCritResistStacks[victim];
				}
				else
				{
					critResist = RF2_GetItemMod(g_iDieRegimePanzerung, 18) * RF2_GetItemMod(g_iDieRegimePanzerung, 22) + RF2_GetItemMod(g_iDieRegimePanzerung, 23) * (g_iMeleeResistStacks[victim] - RoundToNearest(RF2_GetItemMod(g_iDieRegimePanzerung, 22)));
				}
				
				float critResistCap = RF2_GetItemMod(g_iDieRegimePanzerung, 19) + RF2_CalcItemMod(victim, g_iDieRegimePanzerung, 20, -1);
				
				if (critResist > critResistCap || critResist > RF2_GetItemMod(g_iDieRegimePanzerung, 21))
				{
					g_iCritResistStacks[victim] -= 1;
					critResist = critResistCap;
					
					if (critResist > RF2_GetItemMod(g_iDieRegimePanzerung, 21))
					{
						critResist = RF2_GetItemMod(g_iDieRegimePanzerung, 21);
					}
				}
				
				if (g_hTimers[victim][CritResist] != INVALID_HANDLE)
				{
					delete (g_hTimers[victim][CritResist]);
					g_hTimers[victim][CritResist] = INVALID_HANDLE;
				}
				
				g_hTimers[victim][CritResist] = CreateTimer(RF2_GetItemMod(g_iDieRegimePanzerung, 24), Timer_RemoveCritResist, victim, TIMER_FLAG_NO_MAPCHANGE);
				
				damage *= 1.0 - critResist;
				changed = true;
			}
		}
	}
	
	if (IsPlayer(victim))
	{
		if (HasCustomCondition(victim, 0))		// if player has jade elephant active
		{
			damage *= RF2_GetItemMod(g_isBrassBucket, 0);
			changed = true;
		}
		
		if (RF2_GetPlayerItemAmount(victim, g_iBloodBanker) > 0 && !selfDamage)
		{
			RF2_AddPlayerCash(victim, RF2_CalcItemMod(victim, g_iBloodBanker, 0));
		}
	}
	
	damage = fmax(damage, 1.0);
	
	return changed ? Plugin_Changed : Plugin_Continue;
}

public Action RF2_OnTakeDamage2(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, 
	float damageForce[3], float damagePosition[3], int damageCustom)
{
	bool changed = false;
	bool selfDamage = victim == attacker;
	
	if (IsValidClient(attacker))
	{
		if (g_bPlayerExploding[attacker])
		{
			damage = 0.0;
			return Plugin_Handled;
		}
	}
	
	if (IsValidClient(victim) && selfDamage && damageType & DMG_BLAST && TF2_GetPlayerClass(victim) == TFClass_DemoMan)
	{
		char classname[64];
		GetEdictClassname(inflictor, classname, sizeof(classname));
		
		if (StrEqual(classname, "tf_projectile_pipe"))
		{
			float damageReduction = 1 / ( 1 + ( 1 / RF2_GetItemMod(g_iDEMOFusedPlates, 5) * RF2_GetPlayerItemAmount(victim, g_iDEMOFusedPlates)));	// don't ask
			damage *= damageReduction;
			changed = true;
		}
	}

	if (IsValidClient(victim) && RF2_GetPlayerItemAmount(victim, g_iForgottenKings) > 0 && !(damageType & DMG_DOT) && (!(damageType & DMG_SLASH) || IsSkeleton(attacker)) && damageType != 2056)
	{
		float origDamage = damage;
		
		if (IsBuilding(inflictor) && !IsSentryRocketDamage(inflictor))
		{
			origDamage *= 0.4;
		}
			
		
		float damageInstant = origDamage * RF2_GetItemMod(g_iForgottenKings, 0);
		
		float damageDOT = origDamage - damageInstant;
		
		g_fStoredDOT[victim] += damageDOT;
		g_iForgottenKingsTicksLeft[victim] = RoundToNearest(RF2_GetItemMod(g_iForgottenKings, 1) + RF2_CalcItemMod(victim, g_iForgottenKings, 2, -1));
		g_fDamagePerTick[victim] = g_fStoredDOT[victim] / g_iForgottenKingsTicksLeft[victim];
		
		damage = damageInstant;
		changed = true;
		
		if (g_hTimers[victim][ForgottenKing] == INVALID_HANDLE)
        {
            g_hTimers[victim][ForgottenKing] =
                CreateTimer(1.0, Timer_ForgottenKingDamage, victim, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
	}
	
	if (IsValidClient(victim) && g_fCurrentBarrier[victim] > 0.0)
	{
		if (damage > g_fCurrentBarrier[victim])
		{
			damage -= g_fCurrentBarrier[victim];
			g_fCurrentBarrier[victim] = 0.0;
		}
		else
		{
			g_fCurrentBarrier[victim] -= damage;
			damage = 0.0;
		}
	}
	
	if (IsValidClient(victim) && RF2_GetPlayerItemAmount(victim, g_iSightliner) > 0)
	{
		float hpThreshold = RF2_GetCalculatedMaxHealth(victim) * RF2_GetItemMod(g_iSightliner, 1);
		if (GetClientHealth(victim) - damage < hpThreshold)
		{
			RF2_GivePlayerItem(victim, g_iSightliner, -(RF2_GetPlayerItemAmount(victim, g_iSightliner)));
			EmitSoundToClient(victim, SND_GLASS_BREAK);
		}
	}
	
	damage = fmax(damage, 1.0);
	
	if (IsValidClient(victim) && RF2_GetPlayerItemAmount(victim, g_iBombinomicon) > 0)
	{
		if (GetClientHealth(victim) + g_fCurrentBarrier[victim] - damage < 1)
		{
			damage = 0.0;
			if (!g_bPlayerExploding[victim])
			{
				g_bPlayerExploding[victim] = true;
				RF2_CalculatePlayerMaxSpeed(victim);
			}
			
			changed = true;
			
			if (g_hTimers[victim][Timebomb] == INVALID_HANDLE)
			{
				g_hTimers[victim][Timebomb] = CreateTimer(1.0, Timer_Timebomb, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				g_iTimebombTicks[victim] = 5;
			}
		}
	}

	return changed ? Plugin_Changed : Plugin_Continue;
}

public void RF2_OnTakeDamageAlivePost(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon,
const float damageForce[3], const float damagePosition[3], int &damageCustom)
{
	int procItem = RF2_GetEntItemProc(attacker);
	if (procItem == Item_Null && inflictor > 0)
		procItem = RF2_GetEntItemProc(inflictor);
		
	bool invuln = IsValidClient(victim) && IsInvuln(victim);
	bool selfDamage = victim == attacker;
			
	RF2_SetEntItemProc(attacker, Item_Null);
	
	if (IsValidClient(victim) && (IsValidClient(attacker) || IsSkeleton(attacker)))
	{
		int victimWeapon = GetPlayerWeaponSlot(victim, TFWeaponSlot_Melee);
	
		if (!(damageType & DMG_SLASH) && damageCustom != 458752)
		{
			if (TF2_IsPlayerInCondition(victim, TFCond_RuneResist))
			{
				damage *= 0.5;
			}
			
			if (TF2_IsPlayerInCondition(victim, TFCond_RuneVampire))
			{
				damage *= 0.75;
			}
			
			if (IsValidEntity(victimWeapon) && GetEntProp(victimWeapon, Prop_Send, "m_iItemDefinitionIndex") == 331 && damageType != 2056)  //331 = fists of steel
			{
				if (weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee))
				{
					damage *= 2.0;
				}
				else
				{
					damage *= 0.6;
				}
			}
		}
		
		if (HasCustomCondition(attacker, 1))
		{
			int healing = RoundToNearest(damage * RF2_GetItemMod(g_isFoulCowl, 0));
			RF2_HealPlayer(attacker, healing);
		}
		
		if (!selfDamage && !invuln)
		{
			if (g_flPlayerNextPyrotechnicToteFireTime[victim] <= GetTickedTime() 
				&& RF2_GetPlayerItemAmount(victim, g_iPyrotechnicTote) > 0)
			{
				float hpPercentLost = damage / RF2_GetCalculatedMaxHealth(victim) * 100;
				float random = fmin(RF2_GetItemMod(g_iPyrotechnicTote, 0)*hpPercentLost, 1.0);
				if (RF2_RandChanceFloatEx(victim, 0.0, 1.0, random))
				{
					const float rocketSpeed = 1200.0;
					float angles[3], pos[3], enemyPos[3];
					GetEntPos(victim, pos);
					GetEntPos(attacker, enemyPos);
					pos[2] += 30.0;
					enemyPos[2] += 30.0;
					GetVectorAnglesTwoPoints(pos, enemyPos, angles);
					float dmg = RF2_GetItemMod(g_iPyrotechnicTote, 1) + RF2_CalcItemMod(victim, g_iPyrotechnicTote, 2, -1);
					int rocket = RF2_ShootProjectile(victim, "tf_projectile_rocket", pos, angles, rocketSpeed, dmg);
					SetShouldDamageOwner(rocket, false);
					RF2_SetEntItemProc(rocket, g_iPyrotechnicTote);
					EmitSoundToAll(SND_LAW_FIRE, victim, _, _, _, 0.6);
					g_flPlayerNextPyrotechnicToteFireTime[victim] = GetTickedTime()+RF2_GetItemMod(g_iPyrotechnicTote, 3);
				}
			}
			
			if (!IsSkeleton(attacker) && (g_iVoodooJujuProcs[attacker] < RoundToNearest(RF2_GetItemMod(g_iVoodooJuju, 2))	&& RF2_GetPlayerItemAmount(attacker, g_iVoodooJuju) > 0 && (damageType & DMG_SLASH || damageCustom == TF_CUSTOM_BLEEDING)))
			{
				g_fCurrentBarrier[attacker] += RF2_GetItemMod(g_iVoodooJuju, 0) + RF2_CalcItemMod(attacker, g_iVoodooJuju, 1, -1);
				if (g_fCurrentBarrier[attacker] > float(RF2_GetCalculatedMaxHealth(attacker)))
				{
					g_fCurrentBarrier[attacker] = float(RF2_GetCalculatedMaxHealth(attacker));
				}
				
				if (g_hTimers[attacker][BarrierDepletion] == INVALID_HANDLE)
				{
					g_hTimers[attacker][BarrierDepletion] =
						CreateTimer(1.0, Timer_BarrierDepletion, attacker, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				
				g_iVoodooJujuProcs[attacker] += 1;
			}
		}
	}
}

public Action OnSkeletonDamage(int victim, int &attacker, int &inflictor,
                               float &damage, int &damagetype, int &weapon,
                               float damageForce[3], float damagePosition[3])
{
	bool changed = false;
	
	if (IsSkeleton(attacker) && IsSkeleton(victim))
	{
		return Plugin_Handled;
	}

	bool crit = (damagetype & DMG_CRIT) != 0;
	
	if (IsValidClient(attacker))
	{
		if (RF2_GetPlayerItemAmount(attacker, g_iDeadHead) > 0)
		{
			damage *= 1.0 + RF2_CalcItemMod(attacker, g_iDeadHead, 0);
			changed = true;
		}
		
		if (RF2_GetPlayerItemAmount(attacker, g_iParasight) > 0 && !(damagetype & DMG_CLUB))
		{
			damage *= 1.0 + RF2_CalcItemMod(attacker, g_iParasight, 2);
			changed = true;
		}
		
		if (g_iAimframeStacks[attacker] > 0)
		{
			damage *= 1.0 + RF2_CalcItemMod(attacker, g_iAimframe, 2) * g_iAimframeStacks[attacker];
			changed = true;
		}
		
		if (RF2_GetPlayerItemAmount(attacker, g_iBrimOfFire) > 0)
		{
			damage *= 1.0 + RF2_CalcItemMod(attacker, g_iBrimOfFire, 2);
			changed = true;
		}
		
		if (crit)
		{
			if (RF2_GetPlayerItemAmount(attacker, g_iLazerGazers) > 0)
			{
				damage *= 1.0 + RF2_CalcItemMod(attacker, g_iLazerGazers, 0);
				changed = true;
			}
			
			if (RF2_GetPlayerItemAmount(attacker, g_iSpooktacles) > 0)
			{
				damage *= 1.0 + RF2_CalcItemMod(attacker, g_iLazerGazers, 0);
				changed = true;
			}
			
			if (RF2_GetPlayerItemAmount(attacker, g_iSightliner) > 0)
			{
				damage *= 1.0 + RF2_CalcItemMod(attacker, g_iSightliner, 0);
				changed = true;
			}
			
			if (RF2_GetPlayerItemAmount(attacker, g_iGrimTweeter) > 0 && g_flPlayerNextGrimTweeterHealTime[attacker] <= GetTickedTime())
			{
				RF2_HealPlayer(attacker, RoundToNearest(RF2_GetItemMod(g_iGrimTweeter, 1) + RF2_CalcItemMod(attacker, g_iGrimTweeter, 2, -1)));		// full heal on crit
				g_flPlayerNextGrimTweeterHealTime[attacker] = GetTickedTime()+0.1;
			}
		}
		
		if (HasCustomCondition(attacker, 1))
		{
			int healing = RoundToNearest(damage * RF2_GetItemMod(g_isFoulCowl, 0));
			RF2_HealPlayer(attacker, healing);
		}
	}
	
	if (changed)
		return Plugin_Changed;

	return Plugin_Continue;
}

public Action RF2_OnHealingApplied(int client, int &amount, bool &allowOverheal, float &maxOverheal, bool display)
{
	bool changed = false;
	
	if (g_bPlayerExploding[client])
	{
		amount = 0;
		return Plugin_Handled;
	}
	
	int maxHP = RF2_GetCalculatedMaxHealth(client);
	int currentHP = GetClientHealth(client);

	
	int origHealing = amount;
	float healMult = 1.0;
	float modifiedAmount = float(amount);
	float aegisHealing = 0.0;
	
	if (RF2_GetPlayerItemAmount(client, g_iFestiveRack) > 0)
	{
		healMult *= 1.0 + RF2_CalcItemMod(client, g_iFestiveRack, 0);
	}
	
	if (RF2_GetPlayerItemAmount(client, g_iBombinomicon) > 0)
	{
		float hpThreshold = fmin(0.99, RF2_GetItemMod(g_iBombinomicon, 4) + RF2_CalcItemMod(client, g_iBombinomicon, 5, -1));
		
		if ((float(currentHP) / float(maxHP)) < hpThreshold)
		{
			healMult *= 1.0 - RF2_GetItemMod(g_iBombinomicon, 6);
		}
	}
	
	modifiedAmount *= healMult;
	
	
	if (RF2_GetPlayerItemAmount(client, g_iIronLung) > 0 && !allowOverheal)
	{
		if (RoundToNearest(modifiedAmount) + currentHP > maxHP)
		{
			aegisHealing = modifiedAmount - imax((maxHP - currentHP), 0);		// get the excess healing
			modifiedAmount -= aegisHealing;
		}
		aegisHealing *= RF2_CalcItemMod(client, g_iIronLung, 0);		// scale it based on the amount of aegis owned	
		changed = true;
	}
	
	
	// accursed apparition black magic, any other healing mult item should be coded above this
	if(RF2_GetPlayerItemAmount(client, g_iAccursedApparition) > 0 && (modifiedAmount > 0.0 || aegisHealing > 0.0))
	{		
		g_fStoredHealing[client] += (modifiedAmount + aegisHealing) * (1.0 + RF2_GetItemMod(g_iAccursedApparition, 0) + RF2_CalcItemMod(client, g_iAccursedApparition, 3, -1));
		
		if (RoundToNearest(g_fStoredHealing[client]) > maxHP)
			g_fStoredHealing[client] = float(maxHP);		// cap stored healing to player's max hp
		
		if (g_hTimers[client][AccursedApparition] == INVALID_HANDLE)
        {
            g_hTimers[client][AccursedApparition] =
                CreateTimer(0.1, Timer_CorpseBloomHeal, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
		
		amount = 0;
		return Plugin_Handled;		// prevent base healing
	}
	
	amount = RoundToNearest(modifiedAmount);
	
	if (amount + currentHP> maxHP && allowOverheal == false)
	{
		amount = maxHP - currentHP;
	}
	
	amount = imax(amount, 1);
	g_fCurrentBarrier[client] += aegisHealing;
	if (g_fCurrentBarrier[client] > float(RF2_GetCalculatedMaxHealth(client)))
	{
		g_fCurrentBarrier[client] = float(RF2_GetCalculatedMaxHealth(client));
	}
	
	if (g_hTimers[client][BarrierDepletion] == INVALID_HANDLE)
	{
		g_hTimers[client][BarrierDepletion] =
			CreateTimer(1.0, Timer_BarrierDepletion, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (amount != origHealing || changed == true)
		return Plugin_Changed;
	
	return Plugin_Continue;
}

public Action RF2_OnCritChanceCalculation(int client, float &critChance)
{
	bool changed = false;
	
	if (RF2_GetPlayerItemAmount(client, Item_CrypticKeepsake) > 0)
	{
		if (RF2_GetPlayerItemAmount(client, g_iGrimTweeter) > 0)
		{
			critChance += RF2_GetItemMod(g_iGrimTweeter, 0);
			changed = true;
		}
	}
	
	
	// keep this last, reduces total crit chance with Spooktacles
	if (RF2_GetPlayerItemAmount(client, g_iSpooktacles) > 0)
	{
		for (int i = 1 ; i <= RF2_GetPlayerItemAmount(client, g_iSpooktacles) ; i++)
		{
			critChance *= RF2_GetItemMod(g_iSpooktacles, 1);
		}
		changed = true;
	}
	
	if (changed)
		return Plugin_Changed;
	
	return Plugin_Continue;
}

public Action RF2_OnCrypticCritDmgCalculation(int client, float &mult)
{
	bool changed = false;
	
	if (RF2_GetPlayerItemAmount(client, g_iGrimTweeter) > 0)
	{
		mult += RF2_GetItemMod(g_iGrimTweeter, 0);
		changed = true;
	}
	
	
	// keep this last, reduces total crit chance with Spooktacles
	if (RF2_GetPlayerItemAmount(client, g_iSpooktacles) > 0)
	{
		mult -= 1.0;
		for (int i = 1 ; i <= RF2_GetPlayerItemAmount(client, g_iSpooktacles) ; i++)
		{
			mult *= RF2_GetItemMod(g_iSpooktacles, 1);
		}
		mult += 1.0;
		changed = true;
	}
	
	if (changed)
		return Plugin_Changed;
	
	return Plugin_Continue;
}

public Action RF2_OnFireRateCalculation(int client, float &multiplier)
{
	bool changed = false;
	
	if (RF2_GetPlayerItemAmount(client, g_iDEMOFusedPlates) > 0 && TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		// fire rate is modified if player doesn't have both boots and shield
		if (!HasBoots_Wearable(client) && !HasShield_Wearable(client))
		{
			multiplier *= 1.0 + RF2_CalcItemMod(client, g_iDEMOFusedPlates, 3);
			changed = true;
		}
	}
	
	if (changed)
		return Plugin_Changed;
	
	return Plugin_Continue;
}

public Action RF2_OnReloadSpeedCalculation(int client, float &multiplier)
{
	bool changed = false;
	
	if (RF2_GetPlayerItemAmount(client, g_iDEMOFusedPlates) > 0 && TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		// reload speed is modified if player doesn't have boots AND shield
		if (!HasBoots_Wearable(client) || !HasShield_Wearable(client))
		{
			multiplier *= 1.0 + RF2_CalcItemMod(client, g_iDEMOFusedPlates, 3);
			changed = true;
		}
	}
	
	if (RF2_GetPlayerItemAmount(client, g_iSCOUTAirborneAttire) > 0 && TF2_GetPlayerClass(client) == TFClass_Scout && g_bIsGrounded[client])
	{
		multiplier *= 1.0 + RF2_CalcItemMod(client, g_iSCOUTAirborneAttire, 0);
		changed = true;
	}
	
	if (changed)
		return Plugin_Changed;
	
	return Plugin_Continue;
}

public Action RF2_OnMoveSpeedCalculation(int client, float &speed)
{
	bool changed = false;
	
	if (g_fActiveSlow[client] < 1.0)
	{
		speed *= g_fActiveSlow[client];
		changed = true;
	}
	
	if (g_iBonkBoyStacks[client] > 0)
	{
		speed *= 1.0 + RF2_GetItemMod(g_iBonkBoy, 0) * g_iBonkBoyStacks[client];
		changed = true;
	}
	
	if (g_bPlayerExploding[client])
	{
		speed *= RF2_GetItemMod(g_iBombinomicon, 7);
		changed = true;
	}
	
	if (changed)
		return Plugin_Changed;
	
	return Plugin_Continue;
}

public void RF2_OnDoItemKillEffects(int attacker, int inflictor, int victim, int &damageType, int &critType, int assister, int &damageCustom)
{
	if (RF2_GetPlayerItemAmount(attacker, g_iBareBearBones) > 0 && GetClientRune(attacker) == view_as<TFCond>(0) && GetClientRune(victim) != view_as<TFCond>(0))
	{
		float random = RF2_GetItemMod(g_iBareBearBones, 0);
		TFCond rune = GetClientRune(victim);
		if (RF2_RandChanceFloatEx(attacker, 0.0, 1.0, random))
		{
			TF2_AddCondition(attacker, rune, RF2_GetItemMod(g_iBareBearBones, 1) + RF2_CalcItemMod(attacker, g_iBareBearBones, 2, -1));
		}
	}
	
	if (RF2_GetPlayerItemAmount(attacker, g_iDrGrordbortsCrest) > 0 && attacker != victim)
	{
		g_fCurrentBarrier[attacker] += RF2_CalcItemMod(attacker, g_iDrGrordbortsCrest, 0);
		if (g_fCurrentBarrier[attacker] > float(RF2_GetCalculatedMaxHealth(attacker)))
		{
			g_fCurrentBarrier[attacker] = float(RF2_GetCalculatedMaxHealth(attacker));
		}
		
		if (g_hTimers[attacker][BarrierDepletion] == INVALID_HANDLE)
        {
            g_hTimers[attacker][BarrierDepletion] =
                CreateTimer(1.0, Timer_BarrierDepletion, attacker, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
	}
	
	if (HasCustomCondition(victim, 2))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (g_bAimframeAssists[victim][i])
			{
				g_iAimframeStacks[i] += 1;
			}
		}
	}
	
	if (RF2_GetPlayerItemAmount(attacker, g_iHEAVYOneManArmy) > 0 && TF2_GetPlayerClass(attacker) == TFClass_Heavy)
	{
		int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if (weapon != -1)
		{
			char classname[64];
			GetEntityClassname(weapon, classname, sizeof(classname));
			
			if (StrEqual(classname, "tf_weapon_shotgun_hwg") || StrEqual(classname, "tf_weapon_fists"))
			{
				if (RF2_RandChanceFloatEx(attacker, 0.0, 1.0, heavyOneManArmyProcChance[attacker]))
				{
					heavyOneManArmyProcChance[attacker] = RF2_GetItemMod(g_iHEAVYOneManArmy, 0);
					TF2_AddCondition(attacker, TFCond_DefenseBuffed, RF2_GetItemMod(g_iHEAVYOneManArmy, 2));
				}
				else
				{
					if (!TF2_IsPlayerInCondition(attacker, TFCond_DefenseBuffed))
					{
						heavyOneManArmyProcChance[attacker] += RF2_GetItemMod(g_iHEAVYOneManArmy, 1);
					}
				}
			}
		}
	}
}

public Action RF2_OnEquipmentChargeGain(int client, int charges)
{
	char currentMap[64];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if (RF2_GetPlayerItemAmount(client, g_iHoodOfSorrows) > 0 && !StrEqual(currentMap, "rf2_hellscape_r2", true))
	{
		g_iHoodOfSorrowsEquipmentCharges[client] = charges;
		
		if (g_hTimers[client][HoodOfSorrows] == INVALID_HANDLE)
		{
			RF2_ActivateStrangeItem(client);
			g_iHoodOfSorrowsEquipmentCharges[client]--;
			g_hTimers[client][HoodOfSorrows] = CreateTimer(1.0, Timer_HoodOfSorrows, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

Action Timer_HoodOfSorrows(Handle timer, int client)
{
	if (g_iHoodOfSorrowsEquipmentCharges[client] <= 0 || RF2_GetPlayerEquipmentItem(client) == Item_Null)
	{
		g_hTimers[client][HoodOfSorrows] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	RF2_ActivateStrangeItem(client);
	g_iHoodOfSorrowsEquipmentCharges[client]--;

	
	return Plugin_Continue;
}

void ApplySlowEffect(int client, float slowPercent, float duration)
{
	if (g_hTimers[client][RemoveSlow] != INVALID_HANDLE)
	{
		delete (g_hTimers[client][RemoveSlow]);
		g_hTimers[client][RemoveSlow] = INVALID_HANDLE;
	}
	
	g_fActiveSlow[client] = fclamp(1.0-slowPercent, 0.05, 1.00);
	
	RF2_CalculatePlayerMaxSpeed(client);
	
	g_hTimers[client][RemoveSlow] = CreateTimer(duration, Timer_RemoveSlowEffect, client, TIMER_FLAG_NO_MAPCHANGE);
}

void EndSlowEffect(int client)
{
	g_fActiveSlow[client] = 1.0;
	RF2_CalculatePlayerMaxSpeed(client);
}

void ApplyCustomCondition(int client, int condId, float duration)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || condId < 0 || condId >= MAX_CUSTOM_CONDITIONS)
		return;
	
	g_CustomConditions[client][condId] = true;

	int data = (condId << 16) | client;
	CreateTimer(duration, RemoveCustomCondition, data);
}

Action RemoveCustomCondition(Handle timer, any data)
{
	int client = data & 0xFFFF;
	int condId = (data >> 16) & 0xFFFF;
	
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		g_CustomConditions[client][condId] = false;
	}
	
	return Plugin_Stop;
}

bool HasCustomCondition(int client, int condId)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || condId < 0 || condId >= MAX_CUSTOM_CONDITIONS)
		return false;
		
	return g_CustomConditions[client][condId];
}

Action Timer_Timebomb(Handle timer, int client)
{
	if (g_iTimebombTicks[client] == 0)
	{
		GetClientAbsOrigin(client, g_fPlayerDeathPos[client]);
		g_fPlayerDeathPos[client][2] += 10;
		GetClientAbsAngles(client, g_fPlayerDeathAngles[client]);
		float damage = RF2_GetItemMod(g_iBombinomicon, 2) + RF2_CalcItemMod(client, g_iBombinomicon, 3, -1);
		float radius = RF2_GetItemMod(g_iBombinomicon, 0) + RF2_CalcItemMod(client, g_iBombinomicon, 1, -1);
		
		g_bPlayerExploding[client] = false;
		
		RF2_DoRadiusDamage(client, client, g_fPlayerDeathPos[client], g_iBombinomicon, damage, DMG_BLAST, radius, 1.0);
		RF2_DoExplosionEffect(g_fPlayerDeathPos[client]);
		
		g_hTimers[client][TimebombKillCheck] = CreateTimer(0.1, Timer_TimebombKillCheck, client, TIMER_FLAG_NO_MAPCHANGE);
		g_hTimers[client][Timebomb] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	g_iTimebombTicks[client]--;
	
	if (g_iTimebombTicks[client] > 0)
	{
		EmitSoundToAll(SND_BEEP, client, _, _, _, 0.6);
	}
	else
	{
		EmitSoundToAll(SND_FINAL, client, _, _, _, 0.6);
	}
	
	float pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2] += 10.0;
	
	TE_SetupBeamRingPoint(pos, 10.0, 375.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
	TE_SendToAll();

	TE_SetupBeamRingPoint(pos, 10.0, 375.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, whiteColor, 10, 0);
	TE_SendToAll();
	
	return Plugin_Continue;
}

Action Timer_TimebombKillCheck(Handle timer, int client)
{
	if (!g_bKilledWithBombinomiconExplosion[client])
	{
		ForcePlayerSuicide(client);
	}
	else
	{
		int maxHP = RF2_GetCalculatedMaxHealth(client);
		RF2_HealPlayer(client, RoundToNearest(maxHP*2.5));
		g_bKilledWithBombinomiconExplosion[client] = false;
		g_iBombinomiconDeathStacks[client]++;
		RF2_CalculatePlayerMaxSpeed(client);
	}
	
	return Plugin_Stop;
}

Action Timer_RemoveSlowEffect(Handle timer, int client)
{
	if (client == 0)
		return Plugin_Stop;
	
	if (g_hTimers[client][RemoveSlow] != timer)
		return Plugin_Stop;
	
	g_hTimers[client][RemoveSlow] = INVALID_HANDLE;
	
	
	EndSlowEffect(client);
	return Plugin_Stop;
}

Action Timer_RemoveBulletResist(Handle timer, int client)
{
	if (client == 0)
		return Plugin_Stop;
	
	if (g_hTimers[client][BulletResist] != timer)
		return Plugin_Stop;
	
	g_iBulletResistStacks[client] = 0;
	g_hTimers[client][BulletResist] = INVALID_HANDLE;

	return Plugin_Stop;
}

Action Timer_RemoveBlastResist(Handle timer, int client)
{
	if (client == 0)
		return Plugin_Stop;
	
	if (g_hTimers[client][BlastResist] != timer)
		return Plugin_Stop;
	
	g_iBlastResistStacks[client] = 0;
	g_hTimers[client][BlastResist] = INVALID_HANDLE;

	return Plugin_Stop;
}

Action Timer_RemoveMeleeResist(Handle timer, int client)
{
	if (client == 0)
		return Plugin_Stop;
	
	if (g_hTimers[client][MeleeResist] != timer)
		return Plugin_Stop;
	
	g_iMeleeResistStacks[client] = 0;
	g_hTimers[client][MeleeResist] = INVALID_HANDLE;

	return Plugin_Stop;
}

Action Timer_RemoveCritResist(Handle timer, int client)
{
	if (client == 0)
		return Plugin_Stop;
	
	if (g_hTimers[client][CritResist] != timer)
		return Plugin_Stop;
	
	g_iCritResistStacks[client] = 0;
	g_hTimers[client][CritResist] = INVALID_HANDLE;

	return Plugin_Stop;
}

Action Timer_RemoveBonkBoyBuff(Handle timer, int client)
{
	if (client == 0)
		return Plugin_Stop;
	
	if (g_hTimers[client][BonkBoy] != timer)
		return Plugin_Stop;
	
	g_iBonkBoyStacks[client] = 0;
	g_hTimers[client][BonkBoy] = INVALID_HANDLE;

	return Plugin_Stop;
}
Action Timer_BarrierDepletion(Handle timer, int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		g_hTimers[client][BarrierDepletion] = INVALID_HANDLE;
		g_fCurrentBarrier[client] = 0.0;
		return Plugin_Stop;
	}
	
	if (RF2_GetPlayerItemAmount(client, g_iVoodooJuju) > 0)
	{
		g_iVoodooJujuProcs[client] = 0;
	}
	
	float barrierReduction = float(RF2_GetCalculatedMaxHealth(client)) * 0.033;

	g_fCurrentBarrier[client] -= barrierReduction;
	
	if (g_fCurrentBarrier[client] <= 0.0)
	{
		g_fCurrentBarrier[client] = 0.0;
		g_hTimers[client][BarrierDepletion] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

Action Timer_SentryAmmoRegen(Handle timer, int buildingRef)
{
	int buildingIndex = EntRefToEntIndex(buildingRef);
	
	if (buildingIndex == INVALID_ENT_REFERENCE)
	{
		if (buildingRef >= 0 && buildingRef < 2049)
			g_bRocketRegenToggle[buildingRef] = false;
		
		return Plugin_Stop;
	}
	
	int builder = GetEntPropEnt(buildingIndex, Prop_Send, "m_hBuilder");
	
	if (IsPlayer(builder) && IsPlayerAlive(builder) 
		&& RF2_GetPlayerItemAmount(builder, ItemEngi_Toadstool) > 0
		&& !GetEntProp(buildingIndex, Prop_Send, "m_bBuilding") && !GetEntProp(buildingIndex, Prop_Send, "m_bHasSapper") 
		&& !GetEntProp(buildingIndex, Prop_Send, "m_bCarried") && !GetEntProp(buildingIndex, Prop_Send, "m_bPlacing"))
	{
		int currentSentryBullet = GetEntProp(buildingIndex, Prop_Send, "m_iAmmoShells");
		int currentSentryRocket = GetEntProp(buildingIndex, Prop_Send, "m_iAmmoRockets");
		
		int bulletRegen = RoundToNearest(RF2_CalcItemMod(builder, ItemEngi_Toadstool, 2));
		int rocketRegen = RoundToNearest(RF2_CalcItemMod(builder, ItemEngi_Toadstool, 3));
		
		switch (GetEntProp(buildingIndex, Prop_Send, "m_iUpgradeLevel"))
		{
			case 1:
			{
				SetEntProp(buildingIndex, Prop_Send, "m_iAmmoShells", iclamp(currentSentryBullet + bulletRegen, 0, 150));
			}
			case 2:
			{
				SetEntProp(buildingIndex, Prop_Send, "m_iAmmoShells", iclamp(currentSentryBullet + bulletRegen, 0, 200));
			}
			case 3:
			{
				SetEntProp(buildingIndex, Prop_Send, "m_iAmmoShells", iclamp(currentSentryBullet + bulletRegen, 0, 200));
				
				if (g_bRocketRegenToggle[buildingIndex])
				{
					SetEntProp(buildingIndex, Prop_Send, "m_iAmmoRockets", iclamp(currentSentryRocket + rocketRegen, 0, 20));
				}
				
				g_bRocketRegenToggle[buildingIndex] = !g_bRocketRegenToggle[buildingIndex];
			}
		}
	}
	
	return Plugin_Continue;
}

Action Timer_CorpseBloomHeal(Handle timer, int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || RF2_GetPlayerItemAmount(client, g_iAccursedApparition) == 0)
	{
		g_hTimers[client][AccursedApparition] = INVALID_HANDLE;
		g_fStoredHealing[client] = 0.0;
		return Plugin_Stop;
	}
	
	int currentHealth = GetClientHealth(client);
	int maxHP = RF2_GetCalculatedMaxHealth(client);
	
	float healAmount = maxHP * 0.1 * (RF2_GetItemMod(g_iAccursedApparition, 1) + RF2_CalcItemMod(client, g_iAccursedApparition, 2, -1));
	
	if (RF2_GetPlayerItemAmount(client, g_iBombinomicon) > 0)
	{
		float hpThreshold = fmin(0.99, RF2_GetItemMod(g_iBombinomicon, 4) + RF2_CalcItemMod(client, g_iBombinomicon, 5, -1));
		
		if ((float(currentHealth) / float(maxHP)) < hpThreshold)
		{
			healAmount *= 1.0 - RF2_GetItemMod(g_iBombinomicon, 6);
		}
	}
	
	if (healAmount > g_fStoredHealing[client])		// if the healing per 0.1s is higher than the healing that's left to do, heal for the remainder
	{
		healAmount = g_fStoredHealing[client];
	}
	
	int newHealth = currentHealth + RoundToNearest(healAmount);

	bool allowOverheal = IsPlayerActivelyMedigunHealed(client) != -1;
	float maxOverheal = 1.25;
		
	
	if (allowOverheal)
	{
		if (newHealth > RoundToNearest(float(maxHP)*maxOverheal))	// if the next healing tick gets us above max overheal
		{
			newHealth = RoundToNearest(float(maxHP)*maxOverheal);	// cap the health
		}
	}
	else if (newHealth > maxHP)	// if player isn't overhealed and heal would go above max hp
	{
		if (RF2_GetPlayerItemAmount(client, g_iIronLung) > 0)
		{
			float healthToBarrier = float(newHealth - maxHP);
			g_fCurrentBarrier[client] += healthToBarrier;
			if (g_fCurrentBarrier[client] > float(RF2_GetCalculatedMaxHealth(client)))
			{
				g_fCurrentBarrier[client] = float(RF2_GetCalculatedMaxHealth(client));
			}
			
			if (g_hTimers[client][BarrierDepletion] == INVALID_HANDLE)
			{
				g_hTimers[client][BarrierDepletion] =
					CreateTimer(1.0, Timer_BarrierDepletion, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		newHealth = maxHP;		//cap healing to max hp
	}

	if ((currentHealth < maxHP) || (currentHealth < (maxHP*maxOverheal)) && allowOverheal)
	{
		SetEntityHealth(client, newHealth);
	}

	
	if (IsPlayerActivelyMedigunHealed(client) == -1)
	{
		g_fStoredHealing[client] -= RoundToNearest(healAmount);
	}

	// Stop the timer when empty
	if (g_fStoredHealing[client] <= 0.0)
	{
		g_fStoredHealing[client] = 0.0;
		g_hTimers[client][AccursedApparition] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

Action Timer_ForgottenKingDamage(Handle timer, int client)
{
	int maxTicks = RoundToNearest(RF2_GetItemMod(g_iForgottenKings, 1) + RF2_CalcItemMod(client, g_iForgottenKings, 2, -1));
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || g_iForgottenKingsTicksLeft[client] <= maxTicks - 2)
	{
		RF2_HealPlayer(client, RoundToNearest(g_fStoredDOT[client]));
		CleanupDot(client);
		return Plugin_Stop;
	}
	
	if (RF2_GetPlayerItemAmount(client, g_iForgottenKings) == 0)		// no cheesing :))
	{
		ApplyDotDamage(client, g_fStoredDOT[client]);
		CleanupDot(client);
		return Plugin_Stop;
	}

	ApplyDotDamage(client, g_fDamagePerTick[client]);
	g_fStoredDOT[client] -= g_fDamagePerTick[client];
	g_iForgottenKingsTicksLeft[client]--;

	return Plugin_Continue;
}

Action Timer_FireHomingRocket(Handle timer, int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))	
        return Plugin_Stop;

    float damage = RF2_GetItemMod(g_isPeacebreaker, 3);
    float speed = RF2_GetItemMod(g_isPeacebreaker, 4);

    EmitSoundToAll(SND_LAW_FIRE, client, _, _, _, 0.6);
    RF2_FireHomingProjectile(client, damage, speed);

    
    g_isPeacebreakerRocketsRemaining[client]--;
    if (g_isPeacebreakerRocketsRemaining[client] <= 0)
    {
        
		return Plugin_Stop;
    }

    return Plugin_Continue;
}

Action Timer_AimframeMarkOn(Handle timer, int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || RF2_GetPlayerItemAmount(client, g_iAimframe) == 0)
	{
		g_hTimers[client][AimframeMarkOn] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	int enemy = GetRandomAimframeTarget(client);
	
	if (enemy != -1)
	{
		RF2_ToggleGlow(enemy, true);
		ApplyCustomCondition(enemy, 2, RF2_GetItemMod(g_iAimframe, 1));
		
		g_hTimers[enemy][AimframeMarkOff] = CreateTimer(RF2_GetItemMod(g_iAimframe, 1), Timer_AimframeMarkOff, enemy);
	}
	
	return Plugin_Continue;
}

Action Timer_AimframeMarkOff(Handle timer, int client)
{
	if (client == 0)
		return Plugin_Stop;
	
	if (g_hTimers[client][AimframeMarkOff] != timer)
		return Plugin_Stop;
	
	RF2_ToggleGlow(client, false);
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bAimframeAssists[client][i] = false;
	}
	g_hTimers[client][AimframeMarkOff] = INVALID_HANDLE;
	
	return Plugin_Stop;
}

void ApplyDotDamage(int client, float damage)
{
	if (damage <= 0.0)
		return;
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	int health = GetClientHealth(client);
	
	if (health <= 1)
		return;
	
	if (damage >= float(health))
	{
		damage = float(health - 1);
	}
	
	if (damage <= 0.0)
		return;
		
	SDKHooks_TakeDamage(client, 0, 0, damage, DMG_DOT);
}

void CleanupDot(int client)
{
	if (g_hTimers[client][ForgottenKing] != INVALID_HANDLE)
    {
        
		g_hTimers[client][ForgottenKing] = INVALID_HANDLE;
    }

    g_fStoredDOT[client] = 0.0;
    g_fDamagePerTick[client] = 0.0;
	g_iForgottenKingsTicksLeft[client] = 0;
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}


bool IsPlayer(int entity)
{
	return (entity >= 1 && entity <= MaxClients && IsClientInGame(entity) && !IsFakeClient(entity));
}

bool IsBuilding(int entity)
{
	static char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	return StrContains(classname, "obj_") == 0;
}

bool IsSentryRocketDamage(int inflictor)
{
    if (inflictor > MaxClients && IsValidEntity(inflictor))
    {
        char classname[64];
        GetEntityClassname(inflictor, classname, sizeof(classname));
        if (StrEqual(classname, "tf_projectile_sentryrocket"))
		{
			return true;
		}
    }
    return false;
}

void GetEntPos(int entity, float buffer[3])
{
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", buffer);
}

void GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

/*int imin(int val1, int val2)
{
	return val1 < val2 ? val1 : val2;
}*/

int imax(int val1, int val2)
{
	return val1 > val2 ? val1 : val2;
}

float fmin(float val1, float val2)
{
	return val1 < val2 ? val1 : val2;
}

float fmax(float val1, float val2)
{	
	return val1 > val2 ? val1 : val2;
}

int iclamp(int val, int min, int max)
{
	if (val > max)
		return max;
		
	if (val < min)
		return min;
		
	return val;
}

float fclamp(float val, float min, float max)
{
	if (val > max)
		return max;
		
	if (val < min)
		return min;
		
	return val;
}

int IsPlayerActivelyMedigunHealed(int client)
{
    if (!IsClientInGame(client))
        return -1;

    for (int medic = 1; medic <= MaxClients; medic++)
    {
        if (!IsClientInGame(medic) || !IsPlayerAlive(medic))
            continue;

        if (TF2_GetPlayerClass(medic) != TFClass_Medic)
            continue;

        int medigun = GetPlayerWeaponSlot(medic, TFWeaponSlot_Secondary);
        if (medigun <= MaxClients || !IsValidEntity(medigun))
            continue;

        if (GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget") == client)
		{
			return GetEntProp(medigun, Prop_Send, "m_iItemDefinitionIndex");
		}
    }

    return -1;
}

bool IsInvuln(int client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked) ||
		TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) ||
		!GetEntProp(client, Prop_Data, "m_takedamage"));
}

void SetShouldDamageOwner(int entity, bool value)
{
	if (value)
	{
		g_bDontDamageOwner[entity] = false;
	}
	else
	{
		g_bDontDamageOwner[entity] = true;
	}
}

bool ShouldDamageOwner(int entity)
{
	return !g_bDontDamageOwner[entity];
}

bool HasBoots_Wearable(int client)
{
	int ent = -1;
	
	while ((ent = FindEntityByClassname(ent, "tf_wearable")) != -1)
	{
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != client)
			continue;
		
		int defindex = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
		
		if (defindex == 405 || defindex == 608)
			return true;
	}
	
	return false;
}

bool HasShield_Wearable(int client)
{
	int ent = -1;
	
	while ((ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != -1)
	{
		if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
			return true;
	}
	
	return false;
}

bool IsSkeleton(int entity)
{
	static char classname[16];
	GetEntityClassname(entity, classname, sizeof(classname));
	return !strcmp(classname, "tf_zombie");
}

TFCond GetClientRune(int client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return view_as<TFCond>(0);

    static TFCond runes[] =
	{
		TFCond_RuneRegen,
		TFCond_RuneHaste,
		TFCond_RuneVampire,
		TFCond_RuneResist,
		TFCond_RuneStrength,
		TFCond_RuneAgility,
		TFCond_RunePrecision,
		TFCond_KingRune,
		TFCond_RuneKnockout,
		TFCond_RuneImbalance,
		TFCond_CritRuneTemp,
		TFCond_SupernovaRune,
		TFCond_PlagueRune
	};
	
	for (int i = 0; i < sizeof(runes); i++)
	{
		if (TF2_IsPlayerInCondition(client, runes[i]))
			return runes[i];
	}

    return view_as<TFCond>(0);
}

int GetRandomAimframeTarget(int client)
{
	int clients[MAXPLAYERS];
	int nearbyClients[MAXPLAYERS];
	int count;
	int nearbyCount;
	float pos1[3], pos2[3], diff[3];
	
	GetClientAbsOrigin(client, pos1);
	
	int team = GetClientTeam(client);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (GetClientTeam(i) != team && !HasCustomCondition(client, 2))
			{
				GetClientAbsOrigin(i, pos2);
				MakeVectorFromPoints(pos1, pos2, diff);
				if (GetVectorLength(diff) <= RF2_GetItemMod(g_iAimframe, 4))
				{
					nearbyClients[nearbyCount++] = i;
				}
				clients[count++] = i;
			}
		}
	}
	
	if (nearbyCount > 0)
	{
		int randomIndex = GetRandomInt(0, nearbyCount - 1);
		return nearbyClients[randomIndex];
	}
	
	if (count == 0)
		return -1;
	
	int randomIndex = GetRandomInt(0, count - 1);
	return clients[randomIndex];
}