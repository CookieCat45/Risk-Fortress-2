#if defined _RF2_functions_clients_included
 #endinput
#endif
#define _RF2_functions_clients_included

#pragma semicolon 1
#pragma newdecls required

public const TFCond g_MannpowerRunes[] =
{
	TFCond_RuneAgility,
	TFCond_RuneHaste,
	TFCond_RuneKnockout,
	TFCond_RunePrecision,
	TFCond_RuneRegen,
	TFCond_RuneResist,
	TFCond_RuneStrength,
	TFCond_RuneVampire,
	TFCond_RuneWarlock,
	TFCond_KingRune,
};

void RefreshClient(int client, bool force=false)
{
	g_bPlayerViewingItemMenu[client] = false;
	g_bPlayerIsTeleporterBoss[client] = false;
	g_bPlayerOpenedHelpMenu[client] = false;
	g_bPlayerViewingItemDesc[client] = false;
	g_bPlayerHealOnHitCooldown[client] = false;
	g_iPlayerLastPingedEntity[client] = INVALID_ENT;
	g_iPlayerEnemyType[client] = -1;
	g_iPlayerBossType[client] = -1;
	g_iPlayerFireRateStacks[client] = 0;
	g_iPlayerAirDashCounter[client] = 0;
	g_iPlayerGoombaChain[client] = 0;
	g_iPlayerEnemySpawnType[client] = -1;
	g_iPlayerBossSpawnType[client] = -1;
	g_flPlayerRegenBuffTime[client] = 0.0;
	g_flPlayerRifleHeadshotBonusTime[client] = 0.0;
	g_flPlayerGravityJumpBonusTime[client] = 0.0;
	g_flPlayerTimeSinceLastItemPickup[client] = 0.0;
	g_flPlayerCaberRechargeAt[client] = 0.0;
	g_iPlayerFootstepType[client] = FootstepType_Normal;
	g_bPlayerExtraSentryHint[client] = false;
	g_bPlayerInSpawnQueue[client] = false;
	g_bEquipmentCooldownActive[client] = false;
	g_bPlayerLawCooldown[client] = false;
	g_bPlayerTookCollectorItem[client] = false;
	g_bExecutionerBleedCooldown[client] = false;
	g_bPlayerHealBurstCooldown[client] = false;
	g_bPlayerRifleAutoFire[client] = false;
	g_bMeleeMiss[client] = false;
	g_szObjectiveHud[client] = "";
	
	if (IsClientInGame(client) && !g_bMapChanging)
	{
		TF2Attrib_RemoveAll(client);
		SetEntityGravity(client, 1.0);
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", false);
		RequestFrame(RF_ResetMinionFlag, client); // so the correct death voice sound plays
		ToggleGlow(client, false);
		
		// Clear our custom model on a timer so our ragdoll uses the correct model if we're dying.
		CreateTimer(0.5, Timer_ResetModel, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		g_bPlayerIsMinion[client] = false;
	}
	
	if (force)
	{
		g_bPlayerIsMinion[client] = false;
	}
	
	if (force || !IsPlayerSurvivor(client) || !g_bGracePeriod || g_bMapChanging || !IsClientInGame(client))
	{
		//g_iPlayerSurvivorIndex[client] = -1;
		//g_iPlayerEquipmentItem[client] = Item_Null;
		g_flPlayerEquipmentItemCooldown[client] = 0.0;
	}
	
	if (force || g_bMapChanging || !IsPlayerSurvivor(client))
	{
		SetAllInArray(g_iPlayerItem[client], sizeof(g_iPlayerItem[]), 0);
		g_flPlayerCash[client] = 0.0;
		g_iPlayerEquipmentItem[client] = Item_Null;
		g_iPlayerUnusualsUnboxed[client] = 0;
		g_iPlayerLevel[client] = 1;
		g_flPlayerXP[client] = 0.0;
		g_bHauntedKeyDrop[client] = false;
		g_flPlayerNextLevelXP[client] = g_cvSurvivorBaseXpRequirement.FloatValue;
	}
	
	if (g_bPlayerHasVampireSapper[client] && IsClientInGame(client))
	{
		StopSound(client, SNDCHAN_AUTO, SND_SAPPER_DRAIN);
	}
	
	g_bPlayerHasVampireSapper[client] = false;
	g_bPlayerSpawnedByTeleporter[client] = false;
	g_flPlayerVampireSapperCooldown[client] = 0.0;
	g_flPlayerVampireSapperDuration[client] = 0.0;
	g_flPlayerReloadBuffDuration[client] = 0.0;
	
	TFBot(client).GoalArea = NULL_AREA;
	TFBot(client).ForcedButtons = 0;
	TFBot(client).Flags = 0;
	TFBot(client).Mission = MISSION_NONE;
	TFBot(client).HasBuilt = false;
	TFBot(client).AttemptingBuild = false;
	TFBot(client).SentryArea = view_as<CTFNavArea>(NULL_AREA);
	TFBot(client).BuildingTarget = INVALID_ENT;
	TFBot(client).RepairTarget = INVALID_ENT;
	TFBot(client).DesiredWeaponSlot = -1;
	
	if (g_hTFBotEngineerBuildings[client])
	{
		delete g_hTFBotEngineerBuildings[client];
		g_hTFBotEngineerBuildings[client] = null;
	}
}

public void RF_ResetMinionFlag(int client)
{
	g_bPlayerIsMinion[client] = false;
}

public Action Timer_ResetModel(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || IsPlayerAlive(client))
		return Plugin_Continue;
	
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	return Plugin_Continue;
}

void SilentlyKillPlayer(int client)
{
	TF2_RemoveAllWearables(client);
	TF2_RemoveAllWeapons(client);
	RefreshClient(client);
	int team = GetClientTeam(client);
	ChangeClientTeam(client, 0);
	ChangeClientTeam(client, team);
}

int GetPlayersOnTeam(int team, bool alive=false, bool onlyHumans=false)
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != team)
			continue;
		
		if (alive && !IsPlayerAlive(i))
			continue;
		
		if (onlyHumans && IsFakeClient(i))
			continue;
		
		count++;
	}
	
	return count;
}

int GetRandomPlayer(int team = -1, bool alive=true, bool onlyHumans=false)
{
	int count;
	int playerArray[MAXTF2PLAYERS] = {-1, ...};
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || onlyHumans && IsFakeClient(i))
			continue;

		if (alive && !IsPlayerAlive(i) || team >= 0 && GetClientTeam(i) != team)
			continue;

		playerArray[count] = i;
		count++;
	}

	return playerArray[GetRandomInt(0, count>0 ? count-1 : count)];
}

int GetNearestPlayer(float pos[3], float minDist=-1.0, float maxDist=-1.0, int team = -1, bool trace=false, bool onlyHumans=false)
{
	float playerPos[3];
	float distance;
	float nearestDist = -1.0;
	int nearestPlayer = INVALID_ENT;

	float minDistSq = sq(minDist);
	float maxDistSq = sq(maxDist);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || onlyHumans && IsFakeClient(i))
			continue;

		if (team > -1 && GetClientTeam(i) != team)
			continue;

		GetEntPos(i, playerPos);
		if (trace)
		{
			pos[2] += 20.0;
			playerPos[2] += 20.0;
			TR_TraceRayFilter(playerPos, pos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceFilter_WallsOnly);
			pos[2] -= 20.0;
			playerPos[2] -= 20.0;

			if (TR_DidHit())
			{
				continue;
			}
		}

		distance = GetVectorDistance(pos, playerPos, true);
		if ((minDist <= 0.0 || distance >= minDistSq) && (maxDist <= 0.0 || distance <= maxDistSq))
		{
			if (distance < nearestDist || nearestDist == -1.0)
			{
				nearestPlayer = i;
				nearestDist = distance;
			}
		}
	}

	return nearestPlayer;
}

int GetTotalHumans(bool inGameOnly=true)
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || IsFakeClient(i))
			continue;
		
		if (!inGameOnly || IsClientInGame(i))
		{
			count++;
		}
	}

	return count;
}

int HealPlayer(int client, int amount, bool allowOverheal=false, float maxOverheal=1.5, bool display=true)
{
	int health = GetClientHealth(client);
	int maxHealth = RF2_GetCalculatedMaxHealth(client);
	bool capOverheal = maxOverheal > 0.0;
	
	// we're already overhealed or at max health, don't do anything
	if (!allowOverheal && health >= maxHealth || allowOverheal && capOverheal && float(health) >= float(maxHealth)*maxOverheal)
	{
		return 0;
	}

	int amountHealed = amount;
	SetEntityHealth(client, health+amount);
	
	if (!allowOverheal && GetClientHealth(client) > maxHealth || allowOverheal && capOverheal && float(health) >= float(maxHealth)*maxOverheal)
	{
		SetEntityHealth(client, allowOverheal ? RoundToFloor(float(maxHealth)*maxOverheal) : maxHealth);
		amountHealed = allowOverheal ? RoundToFloor(float(maxHealth)*maxOverheal) - health : maxHealth - health;
	}
	
	if (display)
	{
		Event event = CreateEvent("player_healonhit", true);
		event.SetBool("manual", true);
		event.SetInt("entindex", client);
		event.SetInt("amount", amountHealed);
		event.Fire();
	}
	
	return amountHealed;
}

bool RollAttackCrit(int client, int damageType=DMG_GENERIC, int damageCustom=-1)
{
	float critChance;
	int rollTimes = 1;
	int badRolls;
	bool success;
	bool melee = damageType & DMG_MELEE && damageCustom != TF_CUSTOM_BACKSTAB;
	rollTimes = GetPlayerLuckStat(client)+1;
	
	if (rollTimes < 0)
	{
		badRolls = rollTimes * -1;
		rollTimes = 1;
	}
	
	if (!PlayerHasItem(client, Item_CrypticKeepsake))
	{
		if (PlayerHasItem(client, Item_TombReaders))
		{
			critChance += CalcItemMod(client, Item_TombReaders, 0);
		}
		
		if (PlayerHasItem(client, Item_Executioner))
		{
			critChance += CalcItemMod(client, Item_Executioner, 5);
		}

		if (PlayerHasItem(client, Item_SaxtonHat) && melee)
		{
			critChance += CalcItemMod(client, Item_SaxtonHat, 1);
		}
	}
	else
	{
		critChance += CalcItemMod(client, Item_CrypticKeepsake, 0);
	}
	
	if (melee)
	{
		critChance *= g_cvMeleeCritChanceBonus.FloatValue;
	}
	
	critChance = fmin(critChance, 1.0);
	for (int i = 1; i <= rollTimes; i++)
	{
		if (RandChanceFloat(0.01, 1.0, critChance))
		{
			if (badRolls <= 0)
			{
				success = true;
				break;
			}
			else
			{
				badRolls--;
				i = 0;
			}
		}
	}

	return success;
}

int GetPlayerLevel(int client)
{
	if (IsPlayerSurvivor(client))
	{
		return g_iPlayerLevel[client];
	}
	else
	{
		return RF2_GetEnemyLevel();
	}
}

bool CanPlayerRegen(int client)
{
	return (IsPlayerSurvivor(client) || IsPlayerMinion(client) ||
		PlayerHasItem(client, Item_Archimedes) ||
		PlayerHasItem(client, Item_DapperTopper) ||
		PlayerHasItem(client, Item_ClassCrown));
}

void PrintDeathMessage(int client, int item=Item_Null)
{
	char message[512];
	if (item == Item_HorrificHeadsplitter)
	{
		FormatEx(message, sizeof(message), "HeadsplitterDeath");
	}
	else
	{
		const int maxMessages = 10;
		int randomMessage = GetRandomInt(1, maxMessages);
		FormatEx(message, sizeof(message), "DeathMessage%i", randomMessage);
	}
	
	CPrintToChatAll("%t", message, client);
	Format(message, sizeof(message), "%T", message, LANG_SERVER, client);
	CRemoveTags(message, sizeof(message));
	PrintToServer(message);
}

int CalculatePlayerMaxHealth(int client, bool partialHeal=true, bool fullHeal=false)
{
	int oldMaxHealth = RF2_GetCalculatedMaxHealth(client);
	float healthScale = GetPlayerHealthMult(client);
	int classMaxHealth = GetClassMaxHealth(TF2_GetPlayerClass(client));
	// Max health changes from weapons should be added on top of base health too
	Address attr = TF2Attrib_GetByDefIndex(client, 26);
	int healthAttrib = TF2Attrib_HookValueInt(0, "add_maxhealth", client) - RoundToFloor(attr ? TF2Attrib_GetValue(attr) : 0.0);
	int maxHealth = RoundToFloor(float(RF2_GetBaseMaxHealth(client)+healthAttrib) * healthScale);
	
	// Bosses have less health in single player in the first stage
	if (IsSingleplayer(false) && IsBoss(client) && g_iStagesCompleted == 0)
	{
		maxHealth = RoundToFloor(float(maxHealth) * 0.75);
	}
	
	if (PlayerHasItem(client, Item_PrideScarf))
	{
		maxHealth += CalcItemModInt(client, Item_PrideScarf, 0);
	}
	
	if (PlayerHasItem(client, Item_ClassCrown))
	{
		maxHealth += CalcItemModInt(client, Item_ClassCrown, 0);
	}

	if (PlayerHasItem(client, Item_MisfortuneFedora))
	{
		maxHealth = RoundToFloor(float(maxHealth) * CalcItemMod_HyperbolicInverted(client, Item_MisfortuneFedora, 2));
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		TF2Attrib_SetByDefIndex(client, 286, healthScale); // building health
		
		// If we have any buildings up, update their max health now
		int buildingMaxHealth, oldBuildingMaxHealth;
		bool carried;
		int entity = MaxClients+1;
		while ((entity = FindEntityByClassname(entity, "obj_*")) != INVALID_ENT)
		{
			if (GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client)
			{
				carried = asBool(GetEntProp(entity, Prop_Send, "m_bCarried"));
				if (!carried)
				{
					oldBuildingMaxHealth = GetEntProp(entity, Prop_Send, "m_iMaxHealth");
				}
				
				buildingMaxHealth = CalculateBuildingMaxHealth(client, entity);
				SetEntProp(entity, Prop_Send, "m_iMaxHealth", buildingMaxHealth);
				if (!carried && !GetEntProp(entity, Prop_Send, "m_bBuilding"))
				{
					SetEntityHealth(entity, imax(GetEntProp(entity, Prop_Send, "m_iHealth") + (buildingMaxHealth-oldBuildingMaxHealth), 1));
				}
			}
		}
	}
	
	TF2Attrib_SetByDefIndex(client, 26, float(maxHealth-classMaxHealth-healthAttrib)); // "max health additive bonus"
	int actualMaxHealth = SDK_GetPlayerMaxHealth(client);
	g_iPlayerCalculatedMaxHealth[client] = actualMaxHealth;
	if (fullHeal && GetClientHealth(client) < actualMaxHealth)
	{
		HealPlayer(client, actualMaxHealth+99999, false, _, false);
	}
	else if (partialHeal)
	{
		int heal = actualMaxHealth - oldMaxHealth;
		HealPlayer(client, heal, false);
	}
	
	return actualMaxHealth;
}

int CalculateBuildingMaxHealth(int client, int entity)
{
	int maxHealth;
	if (GetEntProp(entity, Prop_Send, "m_bMiniBuilding"))
	{
		maxHealth = 100;
	}
	else
	{
		switch (GetEntProp(entity, Prop_Send, "m_iHighestUpgradeLevel"))
		{
			case 1: maxHealth = 150;
			case 2: maxHealth = 180;
			case 3: maxHealth = 216;
		}
	}
	
	maxHealth = RoundToFloor(float(maxHealth) * TF2Attrib_HookValueFloat(1.0, "mult_engy_building_health", client));
	if (PlayerHasItem(client, Item_PrideScarf))
	{
		maxHealth += CalcItemModInt(client, Item_PrideScarf, 0);
	}
	
	if (PlayerHasItem(client, Item_ClassCrown))
	{
		maxHealth += CalcItemModInt(client, Item_ClassCrown, 0);
	}

	if (PlayerHasItem(client, Item_MisfortuneFedora))
	{
		maxHealth = RoundToFloor(float(maxHealth) * CalcItemMod_HyperbolicInverted(client, Item_MisfortuneFedora, 2));
	}

	maxHealth = imax(maxHealth, 1); // prevent 0, causes division by zero crash on client
	return maxHealth;
}

int SDK_GetPlayerMaxHealth(int client)
{
	if (g_hSDKGetMaxHealth)
	{
		return SDKCall(g_hSDKGetMaxHealth, client);
	}

	return 0;
}

float CalculatePlayerMaxSpeed(int client)
{
	float classMaxSpeed = GetClassMaxSpeed(TF2_GetPlayerClass(client));
	float speed = g_bWaitingForPlayers ? classMaxSpeed : g_flPlayerMaxSpeed[client];
	
	if (PlayerHasItem(client, Item_RobinWalkers))
	{
		speed *= 1.0 + CalcItemMod(client, Item_RobinWalkers, 0);
	}
	
	if (PlayerHasItem(client, Item_TripleA))
	{
		speed *= 1.0 + CalcItemMod(client, Item_TripleA, 2);
	}
	
	if (PlayerHasItem(client, Item_DarkHelm))
	{
		speed *= CalcItemMod_HyperbolicInverted(client, Item_DarkHelm, 1);
	}
	
	if (PlayerHasItem(client, ItemSpy_StealthyScarf) && CanUseCollectorItem(client, ItemSpy_StealthyScarf) && TF2_IsPlayerInCondition(client, TFCond_Cloaked))
	{
		speed *= 1.0 + CalcItemMod(client, ItemSpy_StealthyScarf, 0);
	}
	
	if (IsBoss(client) && GetEntProp(client, Prop_Send, "m_bDucked"))
	{
		speed *= 3.0; // bosses move at normal speed while crouched to avoid getting stuck
	}
	
	float mult = speed / classMaxSpeed;
	TF2Attrib_RemoveByDefIndex(client, 107);
	
	if (mult != 1.0)
		TF2Attrib_SetByDefIndex(client, 107, mult); // "move speed bonus"
	
	SDK_ForceSpeedUpdate(client);
	g_flPlayerCalculatedMaxSpeed[client] = speed;
	return GetEntPropFloat(client, Prop_Data, "m_flMaxspeed");
}

void CalculatePlayerMiscStats(int client)
{
	// Knockback resistance
	if (!IsBoss(client) && !IsPlayerMinion(client))
	{
		float kbRes = 1.0 / GetEnemyDamageMult();
		if (IsPlayerSurvivor(client))
		{
			kbRes *= 0.75; // Survivors get a bit more
		}
		
		TF2Attrib_SetByDefIndex(client, 252, kbRes); // "damage force reduction"
	}
	
	if (IsPlayerSurvivor(client))
	{
		SetClassAttributes(client);
	}
}

void UpdatePlayerGravity(int client)
{
	float gravity = 1.0;
	if (PlayerHasItem(client, ItemScout_MonarchWings) && CanUseCollectorItem(client, ItemScout_MonarchWings) && g_iPlayerAirDashCounter[client] > 0)
	{
		float angles[3];
		GetClientEyeAngles(client, angles);
		bool weighDown = (angles[0] >= 65.0) && asBool(GetClientButtons(client) & IN_DUCK);
		if (g_flPlayerGravityJumpBonusTime[client] > 0.0)
		{
			if (!weighDown)
			{
				gravity -= GetItemMod(ItemScout_MonarchWings, 1);
			}
			else
			{
				gravity += GetItemMod(ItemScout_MonarchWings, 3);
			}
		}
		else if (weighDown)
		{
			gravity += GetItemMod(ItemScout_MonarchWings, 3);
		}
	}
	
	SetEntityGravity(client, gravity*CalcItemMod_HyperbolicInverted(client, Item_UFO, 0));
}

float GetPlayerCash(int client)
{
	return g_flPlayerCash[client];
}

void SetPlayerCash(int client, float amount)
{
	g_flPlayerCash[client] = amount;
	SetEntProp(client, Prop_Send, "m_nCurrency", RoundToFloor(g_flPlayerCash[client]));
}

void AddPlayerCash(int client, float amount)
{
	g_flPlayerCash[client] += amount;
	SetEntProp(client, Prop_Send, "m_nCurrency", RoundToFloor(g_flPlayerCash[client]));
}

// This is for items, it has nothing to do with the attribute
float GetPlayerFireRateMod(int client, int weapon=-1)
{
	float multiplier = 1.0;
	static char classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	bool sentry = weapon > 0 && strcmp2(classname, "obj_sentrygun");
	if (!sentry && weapon > 0)
	{
		bool flamethrower = strcmp2(classname, "tf_weapon_flamethrower");
		if (flamethrower || strcmp2(classname, "tf_weapon_rocketlauncher_fireball"))
		{
			bool dragonsFury = !flamethrower;
			multiplier += CalcItemMod(client, Item_MaimLicense, 0);
			multiplier += float(g_iPlayerFireRateStacks[client]) * GetItemMod(Item_PointAndShoot, 1);
			multiplier += CalcItemMod(client, Item_MaxHead, 2);
			multiplier += CalcItemMod(client, Item_SaintMark, 3);
			multiplier += CalcItemMod(client, Item_TripleA, 1);
			if (multiplier > 1.0 && dragonsFury)
			{
				// Dragon's Fury has a fire rate scaling penalty, flamethrowers do not (note that flamethrowers scale damage with fire rate items)
				const float penalty = 0.5;
				multiplier = Pow(multiplier, penalty);
			}
			
			return multiplier;
		}
		else if (StrContains(classname, "tf_weapon_flaregun") != -1 || StrContains(classname, "tf_weapon_sniperrifle") != -1)
		{
			// Use reload multipliers instead, makes more sense
			return GetPlayerReloadMod(client);
		}
	}
	
	if (PlayerHasItem(client, Item_MaimLicense))
	{
		multiplier *= CalcItemMod_HyperbolicInverted(client, Item_MaimLicense, 0);
	}
	
	if (PlayerHasItem(client, Item_PointAndShoot) && g_iPlayerFireRateStacks[client] > 0)
	{
		multiplier *= (1.0 / (1.0 + (float(g_iPlayerFireRateStacks[client]) * GetItemMod(Item_PointAndShoot, 1))));
	}
	
	if (PlayerHasItem(client, Item_MaxHead))
	{
		multiplier *= CalcItemMod_HyperbolicInverted(client, Item_MaxHead, 2);
	}
	
	if (PlayerHasItem(client, Item_TripleA))
	{
		multiplier *= CalcItemMod_HyperbolicInverted(client, Item_TripleA, 1);
	}
	
	if (g_flPlayerReloadBuffDuration[client] > 0.0)
	{
		multiplier *= GetItemMod(Item_SaintMark, 3);
	}
	
	if (g_flPlayerRifleHeadshotBonusTime[client] > 0.0)
	{
		multiplier *= CalcItemMod_HyperbolicInverted(client, ItemSniper_VillainsVeil, 1);
	}
	
	if (sentry)
	{
		const float penalty = 0.5;
		multiplier = Pow(multiplier, penalty);
	}
	else if (weapon > 0 && multiplier < 1.0)
	{
		if (strcmp2(classname, "tf_weapon_minigun") || strcmp2(classname, "tf_weapon_syringegun_medic"))
		{
			const float penalty = 0.5;
			multiplier = Pow(multiplier, penalty);
		}
		else
		{
			int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			if (index == 527 || index == 1104) // Widowmaker/Air Strike
			{
				const float penalty = 0.5;
				multiplier = Pow(multiplier, penalty);
			}
		}
	}
	
	return multiplier;
}

float GetPlayerReloadMod(int client)
{
	float multiplier = 1.0;
	multiplier *= CalcItemMod_HyperbolicInverted(client, Item_RoundedRifleman, 0);
	multiplier *= CalcItemMod_HyperbolicInverted(client, Item_TripleA, 0);
	multiplier *= CalcItemMod_HyperbolicInverted(client, Item_MaxHead, 3);
	
	if (g_flPlayerReloadBuffDuration[client] > 0.0)
	{
		multiplier *= GetItemMod(Item_SaintMark, 0);
	}
	
	if (g_flPlayerRifleHeadshotBonusTime[client] > 0.0)
	{
		multiplier *= CalcItemMod_HyperbolicInverted(client, ItemSniper_VillainsVeil, 1);
	}

	if (PlayerHasItem(client, Item_PointAndShoot) && g_iPlayerFireRateStacks[client] > 0)
	{
		multiplier *= (1.0 / (1.0 + (float(g_iPlayerFireRateStacks[client]) * GetItemMod(Item_PointAndShoot, 3))));
	}
	
	return multiplier;
}

int GetPlayerLuckStat(int client)
{
	return CalcItemModInt(client, Item_LuckyCatHat, 0) - CalcItemModInt(client, Item_MisfortuneFedora, 0);
}

bool PingObjects(int client)
{
	int entity = GetClientAimTarget(client, false);
	RF2_Object_Base obj = RF2_Object_Base(entity);
	char text[256];
	if (IsCombatChar(entity) && IsLOSClear(client, entity))
	{
		// ping enemies
		char phrase[64];
		if (InSameTeam(client, entity))
		{
			phrase = "wants to help: ";
		}
		else
		{
			phrase = "wants to attack: ";
		}
		
		if (IsValidClient(entity))
		{
			FormatEx(text, sizeof(text), "%N %s%N", client, phrase, entity);
		}
		else
		{
			if (IsBuilding(entity) && TF2_GetObjectType(entity) == TFObject_Dispenser && GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client)
			{
				// don't ping our own dispenser, since this is the button used to toggle the shield
				return false;
			}
			
			char name[128];
			GetEntityDisplayName(entity, name, sizeof(name));
			FormatEx(text, sizeof(text), "%N %s%s", client, phrase, name);
		}
		
		if (IsGlowing(entity, true) || !IsGlowing(entity, true) && !IsGlowing(entity))
		{
			if (g_hEntityGlowResetTimer[entity])
			{
				delete g_hEntityGlowResetTimer[entity];
				g_hEntityGlowResetTimer[entity] = null;
			}
			
			ToggleGlow(entity, true);
			g_hEntityGlowResetTimer[entity] = CreateTimer(8.0, Timer_ResetCharacterGlow, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		float pos[3];
		GetEntPos(entity, pos, true);
		ShowAnnotationToAll(pos, text, 8.0, entity, entity);
	}
	else if (obj.IsValid() && IsLOSClear(client, entity))
	{
		// ping objects
		char objName[64];
		obj.GetObjectName(objName, sizeof(objName));
		FormatEx(text, sizeof(text), "%N has found: %s", client, objName);
		obj.PingMe(text);
	}
	else
	{
		// ping items
		RF2_Item item = GetItemInPickupRange(client);
		entity = item.index;
		if (item.IsValid())
		{
			FormatEx(text, sizeof(text), "%N has found: %s", client, g_szItemName[item.Type]);
			float pos[3];
			item.GetAbsOrigin(pos);
			pos[2] += 50.0;
			ShowAnnotationToAll(pos, text, 8.0, INVALID_ENT, item.index);
		}
	}
	
	if (IsValidEntity2(entity))
	{
		if (entity != g_iPlayerLastPingedEntity[client] && (g_iPlayerLastPingedEntity[client] == INVALID_ENT || IsValidEntity2(g_iPlayerLastPingedEntity[client])))
		{
			if (g_iPlayerLastPingedEntity[client] >= 0)
				KillAnnotation(g_iPlayerLastPingedEntity[client]);
			
			g_iPlayerLastPingedEntity[client] = entity;
		}
		
		SetCookieBool(client, g_coPingObjectsHint, true);
		return true;
	}

	return false;
}

void ShowAnnotation(int client, float pos[3]=NULL_VECTOR, const char[] text, float duration=8.0, int parent=INVALID_ENT, int id=-1, const char[] sound=SND_HINT)
{
	if (id >= 0)
	{
		KillAnnotation(id);
	}

	Event event = CreateEvent("show_annotation", true);
	event.SetFloat("worldPosX", pos[0]);
	event.SetFloat("worldPosY", pos[1]);
	event.SetFloat("worldPosZ", pos[2]);
	event.SetFloat("lifetime", duration);
	event.SetInt("id", id);
	event.SetInt("follow_entindex", parent);
	event.SetString("text", text);
	event.FireToClient(client);
	if (sound[0])
	{
		EmitSoundToClient(client, sound);
	}
	
	delete event;
}

void ShowAnnotationToAll(float pos[3]=NULL_VECTOR, const char[] text, float duration=8.0, int parent=INVALID_ENT, int id=-1, const char[] sound=SND_HINT)
{
	if (id >= 0)
	{
		KillAnnotation(id);
	}
	
	Event event = CreateEvent("show_annotation", true);
	event.SetFloat("worldPosX", pos[0]);
	event.SetFloat("worldPosY", pos[1]);
	event.SetFloat("worldPosZ", pos[2]);
	event.SetFloat("lifetime", duration);
	event.SetInt("id", id);
	event.SetInt("follow_entindex", parent);
	event.SetString("text", text);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{	
			event.FireToClient(i);
			if (sound[0])
			{
				EmitSoundToClient(i, sound);
			}
		}
	}
	
	delete event;
}

void KillAnnotation(int entity)
{
	Event annotation = CreateEvent("hide_annotation", true);
	annotation.SetInt("id", entity);
	annotation.Fire();
}

public Action Timer_ResetCharacterGlow(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE)
		return Plugin_Continue;
	
	ToggleGlow(entity, false);
	g_hEntityGlowResetTimer[entity] = null;
	return Plugin_Continue;
}

void ApplyVampireSapper(int client, int attacker, float damage=10.0, float duration=8.0)
{
	if (!g_bPlayerHasVampireSapper[client])
	{
		CreateTimer(0.5, Timer_VampireSapper, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	g_bPlayerHasVampireSapper[client] = true;
	g_iPlayerVampireSapperAttacker[client] = GetClientUserId(attacker);
	g_flPlayerVampireSapperDamage[client] = damage;
	g_flPlayerVampireSapperDuration[client] = duration;
	
	EmitSoundToAll(SND_SAPPER_PLANT, client);
	EmitSoundToAll(SND_SAPPER_PLANT, client);
	StopSound(client, SNDCHAN_AUTO, SND_SAPPER_DRAIN);
	EmitSoundToAll(SND_SAPPER_DRAIN, client);
	
	// spawn the sapper particle
	float pos[3];
	GetClientEyePosition(client, pos);
	SpawnInfoParticle("sapper_sentry1_fx", pos, duration, client, "head");
	
	if (!IsBoss(client))
	{
		TF2_StunPlayer(client, duration, 0.4, TF_STUNFLAG_SLOWDOWN, attacker);
	}
	
	if (IsFakeClient(client))
	{
		TFBot(client).RealizeSpy(attacker);
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == attacker || i == client || !IsClientInGame(i) || !IsPlayerAlive(i) || !IsFakeClient(i) || GetClientTeam(i) == GetClientTeam(attacker))
			continue;
	
		if (DistBetween(i, client) <= 800.0 && IsLOSClear(client, i, MASK_OPAQUE|CONTENTS_IGNORE_NODRAW_OPAQUE))
		{
			TFBot(i).RealizeSpy(attacker);
		}
	}
}

public Action Timer_VampireSapper(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || !g_bPlayerHasVampireSapper[client] || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	int sapper = INVALID_ENT;
	int attacker = GetClientOfUserId(g_iPlayerVampireSapperAttacker[client]);
	if (IsValidClient(attacker))
	{
		sapper = GetPlayerWeaponSlot(attacker, WeaponSlot_Secondary);
	}
	
	RF_TakeDamage(client, attacker, attacker, g_flPlayerVampireSapperDamage[client], DMG_SHOCK|DMG_PREVENT_PHYSICS_FORCE, _, sapper);
	int totalHealing = RoundToFloor(g_flPlayerVampireSapperDamage[client]);
	int team = GetClientTeam(client);
	float pos[3], victimPos[3];
	GetEntPos(client, pos);
	const float range = 350.0;
	int count;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != team)
			continue;
		
		GetEntPos(i, victimPos);
		if (GetVectorDistance(pos, victimPos, true) <= Pow(range, 2.0))
		{
			RF_TakeDamage(i, attacker, attacker, g_flPlayerVampireSapperDamage[client]*0.5, DMG_SHOCK|DMG_PREVENT_PHYSICS_FORCE, _, sapper);
			
			if (!IsBoss(i))
			{
				TF2_StunPlayer(i, 1.0, 0.4, TF_STUNFLAG_SLOWDOWN, attacker);
			}

			totalHealing += RoundToFloor(g_flPlayerVampireSapperDamage[client]*0.5);

			pos[2] += 40.0;
			victimPos[2] += 40.0;
			TE_SetupBeamPoints(pos, victimPos, g_iBeamModel, 0, 0, 0, 0.3, 4.0, 4.0, 0, 0.0, {125, 125, 255, 255}, 30);
			TE_SendToAll();

			count++;
			if (count >= 5)
				break;
		}
	}

	if (IsValidClient(attacker) && IsPlayerSurvivor(attacker) && IsPlayerAlive(attacker))
	{
		HealPlayer(attacker, totalHealing);
	}

	g_flPlayerVampireSapperDuration[client] -= 0.5;
	if (g_flPlayerVampireSapperDuration[client] <= 0.0)
	{
		g_bPlayerHasVampireSapper[client] = false;
		StopSound(client, SNDCHAN_AUTO, SND_SAPPER_DRAIN);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

void OnPlayerAirDash(int client)
{
	/*
	int airDashLimit = 1;
	airDashLimit += GetPlayerItemCount(client, ItemScout_MonarchWings);
	
	if (count < airDashLimit)
	{
		SetEntProp(client, Prop_Send, "m_iAirDash", 0);
	}
	
	g_iPlayerAirDashCounter[client] = imin(count, airDashLimit);
	if (count >= 8)
	{
		TriggerAchievement(client, ACHIEVEMENT_AIRJUMPS);
	}
	
	
	if (PlayerHasItem(client, ItemScout_MonarchWings))
	{
		TF2_AddCondition(client, TFCond_Buffed, GetItemMod(ItemScout_MonarchWings, 1));
	}
	*/
	
	if (PlayerHasItem(client, ItemScout_MonarchWings) && CanUseCollectorItem(client, ItemScout_MonarchWings))
	{
		float vel[3], pos[3];
		vel[2] = 125.0 * (1.0+CalcItemMod(client, ItemScout_MonarchWings, 0));
		SDK_ApplyAbsVelocityImpulse(client, vel);
		g_flPlayerGravityJumpBonusTime[client] = GetItemMod(ItemScout_MonarchWings, 2);
		UpdatePlayerGravity(client);
		EmitSoundToAll(SND_PARACHUTE, client);
		GetEntPos(client, pos);
		TE_TFParticle("taunt_flip_land", pos);
	}
}

int GetClassMaxHealth(TFClassType class)
{
	switch (class)
	{
		case TFClass_Scout: return 125;
		case TFClass_Soldier: return 200;
		case TFClass_Pyro: return 175;
		case TFClass_DemoMan: return 175;
		case TFClass_Heavy: return 300;
		case TFClass_Engineer: return 125;
		case TFClass_Medic: return 150;
		case TFClass_Sniper: return 125;
		case TFClass_Spy: return 125;
	}
	
	return 75;
}

float GetClassMaxSpeed(TFClassType class)
{
	switch (class)
	{
		case TFClass_Scout: return 400.0;
		case TFClass_Soldier: return 240.0;
		case TFClass_Pyro: return 300.0;
		case TFClass_DemoMan: return 280.0;
		case TFClass_Heavy: return 230.0;
		case TFClass_Engineer: return 300.0;
		case TFClass_Medic: return 320.0;
		case TFClass_Sniper: return 300.0;
		case TFClass_Spy: return 320.0;
	}

	return 300.0;
}

void GetClassString(TFClassType class, char[] buffer, int size, bool underScore=false, bool capitalize=false)
{
	switch (class)
	{
		case TFClass_Scout: strcopy(buffer, size, "scout");
		case TFClass_Soldier: strcopy(buffer, size, "soldier");
		case TFClass_Pyro: strcopy(buffer, size, "pyro");
		case TFClass_DemoMan: strcopy(buffer, size, "demoman");
		case TFClass_Heavy: strcopy(buffer, size, "heavy");
		case TFClass_Engineer: strcopy(buffer, size, "engineer");
		case TFClass_Medic: strcopy(buffer, size, "medic");
		case TFClass_Sniper: strcopy(buffer, size, "sniper");
		case TFClass_Spy: strcopy(buffer, size, "spy");
		default: strcopy(buffer, size, "unknown");
	}
	
	if (underScore)
	{
		Format(buffer, size, "%s_", buffer);
	}
	
	if (capitalize)
	{
		int chr = buffer[0];
		CharToUpper(chr);
	}
}

int GetClassMenuIndex(TFClassType class)
{
	switch (class)
	{
		case TFClass_Scout: return 1;
		case TFClass_Soldier: return 2;
		case TFClass_Pyro: return 3;
		case TFClass_DemoMan: return 4;
		case TFClass_Heavy: return 5;
		case TFClass_Engineer: return 6;
		case TFClass_Medic: return 7;
		case TFClass_Sniper: return 8;
		case TFClass_Spy: return 9;
	}

	return 0;
}

int GetPlayerBuildingCount(int client, TFObjectType type=view_as<TFObjectType>(-1), bool allowDisposable=true)
{
	int count;
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "obj_*")) != INVALID_ENT)
	{
		if (!allowDisposable && IsSentryDisposable(entity))
			continue;
		
		if (view_as<int>(type) == -1 || TF2_GetObjectType2(entity) == type)
		{
			if (GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client)
				count++;
		}
	}

	return count;
}

int GetPlayerShield(int client)
{
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "tf_wearable_demoshield")) != INVALID_ENT)
	{
		if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
			return entity;
	}
	
	return INVALID_ENT;
}

TFCond GetRandomMannpowerRune(char soundBuffer[PLATFORM_MAX_PATH]="", int size=0)
{
	ArrayList runes = new ArrayList();
	for (int i = 0; i < sizeof(g_MannpowerRunes); i++)
	{
		runes.Push(g_MannpowerRunes[i]);
	}
	
	TFCond rune = runes.Get(GetRandomInt(0, runes.Length-1));
	delete runes;
	if (size > 0)
	{
		switch (rune)
		{
			case TFCond_RuneAgility: strcopy(soundBuffer, size, SND_RUNE_AGILITY);
			case TFCond_RuneHaste: strcopy(soundBuffer, size, SND_RUNE_HASTE);
			case TFCond_RuneKnockout: strcopy(soundBuffer, size, SND_RUNE_KNOCKOUT);
			case TFCond_RunePrecision: strcopy(soundBuffer, size, SND_RUNE_PRECISION);
			case TFCond_RuneRegen: strcopy(soundBuffer, size, SND_RUNE_REGEN);
			case TFCond_RuneResist: strcopy(soundBuffer, size, SND_RUNE_RESIST);
			case TFCond_RuneStrength: strcopy(soundBuffer, size, SND_RUNE_STRENGTH);
			case TFCond_RuneVampire: strcopy(soundBuffer, size, SND_RUNE_VAMPIRE);
			case TFCond_RuneWarlock: strcopy(soundBuffer, size, SND_RUNE_WARLOCK);
		}
	}
	
	return rune;
}

TFCond GetRandomMannpowerRune_Enemies(int client, char soundBuffer[PLATFORM_MAX_PATH]="", int size=0)
{
	ArrayList runes = new ArrayList();
	for (int i = 0; i < sizeof(g_MannpowerRunes); i++)
	{
		runes.Push(g_MannpowerRunes[i]);
	}
	
	// Enemies cannot have Reflect at all, and crit boosted enemies cannot have Strength
	runes.Erase(runes.FindValue(TFCond_RuneWarlock));
	if (IsPlayerCritBoosted(client))
	{
		runes.Erase(runes.FindValue(TFCond_RuneStrength));
	}
	
	// Knockout is pointless if the enemy doesn't have a melee weapon
	if (GetPlayerWeaponSlot(client, WeaponSlot_Melee) == INVALID_ENT)
	{
		runes.Erase(runes.FindValue(TFCond_RuneKnockout));
	}
	
	TFCond rune = runes.Get(GetRandomInt(0, runes.Length-1));
	delete runes;
	if (size > 0)
	{
		switch (rune)
		{
			case TFCond_RuneAgility: strcopy(soundBuffer, size, SND_RUNE_AGILITY);
			case TFCond_RuneHaste: strcopy(soundBuffer, size, SND_RUNE_HASTE);
			case TFCond_RuneKnockout: strcopy(soundBuffer, size, SND_RUNE_KNOCKOUT);
			case TFCond_RunePrecision: strcopy(soundBuffer, size, SND_RUNE_PRECISION);
			case TFCond_RuneRegen: strcopy(soundBuffer, size, SND_RUNE_REGEN);
			case TFCond_RuneResist: strcopy(soundBuffer, size, SND_RUNE_RESIST);
			case TFCond_RuneStrength: strcopy(soundBuffer, size, SND_RUNE_STRENGTH);
			case TFCond_RuneVampire: strcopy(soundBuffer, size, SND_RUNE_VAMPIRE);
			case TFCond_RuneWarlock: strcopy(soundBuffer, size, SND_RUNE_WARLOCK);
		}
	}
	
	return rune;
}

stock bool IsPlayerMiniCritBuffed(int client)
{
	return TF2_IsPlayerInCondition(client, TFCond_CritCola)
		|| TF2_IsPlayerInCondition(client, TFCond_Buffed)
		|| TF2_IsPlayerInCondition(client, TFCond_NoHealingDamageBuff)
		|| TF2_IsPlayerInCondition(client, TFCond_MiniCritOnKill);
}

stock bool IsPlayerCritBoosted(int client)
{
	return TF2_IsPlayerInCondition(client, TFCond_CritCanteen)
		|| TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged)
		|| TF2_IsPlayerInCondition(client, TFCond_CritMmmph)
		|| TF2_IsPlayerInCondition(client, TFCond_CritOnDamage)
		|| TF2_IsPlayerInCondition(client, TFCond_CritOnKill)
		|| TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture)
		|| TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood)
		|| TF2_IsPlayerInCondition(client, TFCond_CritRuneTemp)
		|| TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy)
		|| TF2_IsPlayerInCondition(client, TFCond_CritOnWin);
}

void SDK_ForceSpeedUpdate(int client)
{
	if (g_hSDKUpdateSpeed)
	{
		SDKCall(g_hSDKUpdateSpeed, client);
	}
}

public MRESReturn Detour_HandleRageGain(DHookParam params)
{
	if (!RF2_IsEnabled())
		return MRES_Ignored;
	
	// apparently this can be null
	if (params.IsNull(1))
		return MRES_Ignored;
	
	int client = params.Get(1);
	float damage = params.Get(3);
	float finalDamage;
	
	// Rage needs more damage as player's damage goes up
	finalDamage = damage / GetPlayerDamageMult(client);
	if (IsPlayerSurvivor(client))
	{
		// 50% additional penalty for survivors
		finalDamage *= 0.5;
	}
	
	params.Set(3, finalDamage);
	return MRES_ChangedHandled;
}

public MRESReturn DHook_TakeHealth(int entity, DHookReturn returnVal, DHookParam params)
{
	if (!RF2_IsEnabled())
		return MRES_Ignored;

	if (IsValidClient(entity))
	{
		float health = DHookGetParam(params, 1);
		health *= GetPlayerHealthMult(entity);
		params.Set(1, health);
		return MRES_ChangedHandled;
	}
	
	return MRES_Ignored;
}

public MRESReturn DHook_ForceRespawn(int client)
{
	if (!g_bRoundActive)
		return MRES_Ignored;
	
	int team = GetClientTeam(client);
	if (team == TEAM_ENEMY && (g_bGracePeriod || !IsEnemy(client)))
	{
		// Block spawn because grace period is active or no enemy index
		return MRES_Supercede;
	}
	else if (team == TEAM_SURVIVOR && !IsPlayerSurvivor(client, false) && !IsPlayerMinion(client))
	{
		// Block spawn because client is not a Survivor nor a minion
		ChangeClientTeam(client, TEAM_ENEMY);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

public MRESReturn Detour_ApplyPunchImpulse(int client, DHookReturn returnVal, DHookParam params)
{
	if (!RF2_IsEnabled())
		return MRES_Ignored;
	
	if (TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		returnVal.Value = false;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
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

/*
bool IsInvis(int client, bool fullyInvis=true)
{
	return ((TF2_IsPlayerInCondition(client, TFCond_Cloaked) ||
		TF2_IsPlayerInCondition(client, TFCond_Stealthed) ||
		TF2_IsPlayerInCondition(client, TFCond_StealthedUserBuffFade))
		&& (!fullyInvis || !TF2_IsPlayerInCondition(client, TFCond_CloakFlicker)
		&& !TF2_IsPlayerInCondition(client, TFCond_OnFire)
		&& !TF2_IsPlayerInCondition(client, TFCond_Jarated)
		&& !TF2_IsPlayerInCondition(client, TFCond_Milked)
		&& !TF2_IsPlayerInCondition(client, TFCond_Bleeding)
		&& !TF2_IsPlayerInCondition(client, TFCond_Gas)));
}
*/

void PrintKeyHintText(int client, const char[] format, any ...)
{
	BfWrite userMessage = view_as<BfWrite>(StartMessageOne("KeyHintText", client));
	if (userMessage)
	{
		char buffer[256];
		SetGlobalTransTarget(client);
		VFormat(buffer, sizeof(buffer), format, 3);
		
		if (GetUserMessageType() == UM_Protobuf)
		{
			PbSetString(userMessage, "hints", buffer);
		}
		else
		{
			userMessage.WriteByte(1);
			userMessage.WriteString(buffer);
		}
		
		EndMessage();
	}
}

void SpeakResponseConcept(int client, const char[] response)
{
	AcceptEntityInput(client, "ClearContext");
	SetVariantString("randomnum:100");
	AcceptEntityInput(client, "AddContext");
	SetVariantString(response);
	AcceptEntityInput(client, "SpeakResponseConcept");
	AcceptEntityInput(client, "ClearContext");
}

void SpeakResponseConcept_MVM(int client, const char[] response)
{
	SetVariantString("IsMvMDefender:1");
	AcceptEntityInput(client, "AddContext");
	SetVariantString(response);
	AcceptEntityInput(client, "SpeakResponseConcept");
}

bool ForceWeaponSwitch(int client, int slot)
{
	if (!g_hSDKWeaponSwitch)
		return false;
	
	int weapon = GetPlayerWeaponSlot(client, slot);
	if (weapon == -1 || weapon == GetActiveWeapon(client))
		return false;
	
	return SDKCall(g_hSDKWeaponSwitch, client, weapon, 0);
}

bool IsPlayerAFK(int client)
{
	return g_bPlayerIsAFK[client];
}

void ResetAFKTime(int client)
{
	if (IsClientInGame(client) && IsPlayerAFK(client))
	{
		if (g_bWaitingForPlayers && !GetCookieBool(client, g_coStayInSpecOnJoin))
		{
			ChangeClientTeam(client, GetRandomInt(TEAM_SURVIVOR, TEAM_ENEMY));
		}
	}
	
	g_flPlayerAFKTime[client] = 0.0;
	g_bPlayerIsAFK[client] = false;
}

void OnPlayerEnterAFK(int client)
{
	SetClientName(client, g_szPlayerOriginalName[client]);
}

bool ArePlayersConnecting()
{
	return GetTotalHumans(false) > GetTotalHumans(true);
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

bool IsPlayerStunned(int client)
{
	int stunFlags = GetEntProp(client, Prop_Send, "m_iStunFlags");
	return TF2_IsPlayerInCondition(client, TFCond_Dazed) && (stunFlags & TF_STUNFLAG_THIRDPERSON || stunFlags & TF_STUNFLAG_BONKSTUCK);
}

float GetPlayerHealthMult(int client)
{
	if (IsPlayerSurvivor(client) && !IsPlayerMinion(client))
	{
		return 1.0 + (float(GetPlayerLevel(client)-1) * g_cvSurvivorHealthScale.FloatValue);
	}
	
	return GetEnemyHealthMult();
}

float GetPlayerDamageMult(int client)
{
	if (IsPlayerSurvivor(client) && !IsPlayerMinion(client))
	{
		return 1.0 + (float(GetPlayerLevel(client)-1) * g_cvSurvivorDamageScale.FloatValue);
	}
	
	return GetEnemyDamageMult();
}

bool ClientPlayGesture(int client, const char[] gesture)
{
	if (g_hSDKPlayGesture)
	{
		return SDKCall(g_hSDKPlayGesture, client, gesture);
	}
	
	return false;
}

bool IsPlayerSpectator(int client)
{
	return GetClientTeam(client) <= 1;
}

float GetPercentInvisible(int client)
{
	return GetEntDataFloat(client, FindSendPropInfo("CTFPlayer", "m_flInvisChangeCompleteTime") - 8);
}

int GetPlayerWearableCount(int client, bool itemOnly=false)
{
	int count;
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "tf_wearable*")) != INVALID_ENT)
	{
		if (itemOnly && !g_bItemWearable[entity])
			continue;
		
		if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != client)
			continue;

		count++;
	}
	
	return count;
}

int GetActiveWeapon(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

// Eureka Effect/Vaccinator
bool HoldingReloadUseWeapon(int client)
{
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		int medigun = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
		if (medigun != INVALID_ENT && GetActiveWeapon(client) == medigun)
		{
			if (TF2Attrib_HookValueInt(0, "set_charge_type", medigun) == 3)
			{
				return true;
			}
		}
	}
	else if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		int wrench = GetPlayerWeaponSlot(client, WeaponSlot_Melee);
		if (wrench != INVALID_ENT && GetActiveWeapon(client) == wrench)
		{
			if (TF2Attrib_HookValueInt(0, "alt_fire_teleport_to_spawn", wrench) > 0)
			{
				return true;
			}
		}
	}
	
	return false;
}

int GetSpectateTarget(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
}

bool IsInspectButtonPressed(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flInspectTime") > 0.0;
}

int GetDesiredPlayerCap()
{
	return g_cvMaxHumanPlayers.IntValue;
}

void ToggleHiddenSlot(bool state)
{
	if (state)
	{
		SetMVMPlayerCvar(GetDesiredPlayerCap());
	}
	else
	{
		SetMVMPlayerCvar(GetDesiredPlayerCap()+1);
	}
}

void SetMVMPlayerCvar(int value)
{
	FindConVar("tf_mvm_defenders_team_size").SetInt(value);
	FindConVar("tf_mvm_max_connected_players").SetInt(value);
}

bool IsAdminReserved(int client)
{
	if (GetUserAdmin(client) == INVALID_ADMIN_ID)
		return false;
	
	// If total players is greater than non-admin player cap, this admin is holding a reserved slot.
	return GetTotalHumans(false) > GetDesiredPlayerCap();
}

/*
float GetConditionDuration(int client, TFCond cond)
{
	if (!TF2_IsPlayerInCondition(client, cond)) 
		return 0.0;
	
	int m_Shared = FindSendPropInfo("CTFPlayer", "m_Shared");
	Address condSource = view_as<Address>(LoadFromAddress(GetEntityAddress(client) + view_as<Address>(m_Shared + 8), NumberType_Int32));
	Address condDuration = view_as<Address>(view_as<int>(condSource) + (view_as<int>(cond) * 20) + (2 * 4));
	return view_as<float>(LoadFromAddress(condDuration, NumberType_Int32));
}
*/

public bool TraceFilter_PlayerTeam(int entity, int mask, int client)
{
	if (entity > 0 && entity <= MaxClients && entity != client && GetClientTeam(entity) == GetClientTeam(client))
		return true;
	
	return false;
}

public bool TraceFilter_EnemyTeam(int entity, int mask, int client)
{
	if (entity > 0 && entity <= MaxClients && entity != client && GetClientTeam(entity) != GetClientTeam(client))
		return true;
	
	return false;
}
