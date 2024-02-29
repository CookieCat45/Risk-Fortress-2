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
	g_iPlayerEnemyType[client] = -1;
	g_iPlayerBossType[client] = -1;
	g_iPlayerFireRateStacks[client] = 0;
	g_iPlayerAirDashCounter[client] = 0;
	g_iPlayerEnemySpawnType[client] = -1;
	g_iPlayerBossSpawnType[client] = -1;
	g_flPlayerRegenBuffTime[client] = 0.0;
	g_iPlayerFootstepType[client] = FootstepType_Normal;
	g_bPlayerExtraSentryHint[client] = false;
	g_bPlayerInSpawnQueue[client] = false;
	g_bEquipmentCooldownActive[client] = false;
	g_bItemPickupCooldown[client] = false;
	g_bPlayerLawCooldown[client] = false;
	g_bPlayerTookCollectorItem[client] = false;
	g_bExecutionerBleedCooldown[client] = false;
	g_bPlayerHealBurstCooldown[client] = false;
	g_szObjectiveHud[client] = "";
	
	if (IsClientInGame(client) && !g_bMapChanging)
	{
		TF2Attrib_RemoveAll(client);
		SetEntityGravity(client, 1.0);
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", false);
		
		// Clear our custom model on a timer so our ragdoll uses the correct model if we're dying.
		CreateTimer(0.5, Timer_ResetModel, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (force || !IsPlayerSurvivor(client) || !g_bGracePeriod || g_bMapChanging || !IsClientInGame(client))
	{
		g_iPlayerLevel[client] = 1;
		g_flPlayerXP[client] = 0.0;
		g_flPlayerCash[client] = 0.0;
		g_flPlayerNextLevelXP[client] = g_cvSurvivorBaseXpRequirement.FloatValue;
		g_iPlayerSurvivorIndex[client] = -1;
		g_iPlayerEquipmentItem[client] = Item_Null;
		g_flPlayerEquipmentItemCooldown[client] = 0.0;
		g_iPlayerUnusualsUnboxed[client] = 0;
		SetAllInArray(g_iPlayerItem[client], sizeof(g_iPlayerItem[]), 0);
	}
	
	if (g_bPlayerHasVampireSapper[client])
	{
		StopSound(client, SNDCHAN_AUTO, SND_SAPPER_DRAIN);
	}
	
	g_bPlayerHasVampireSapper[client] = false;
	g_bPlayerSpawnedByTeleporter[client] = false;
	g_flPlayerVampireSapperCooldown[client] = 0.0;
	g_flPlayerVampireSapperDuration[client] = 0.0;
	g_flPlayerReloadBuffDuration[client] = 0.0;
	
	g_TFBot[client].GoalArea = NULL_AREA;
	g_TFBot[client].ForcedButtons = 0;
	g_TFBot[client].Flags = 0;
	g_TFBot[client].Mission = MISSION_NONE;
	g_TFBot[client].HasBuilt = false;
	g_TFBot[client].AttemptingBuild = false;
	g_TFBot[client].SentryArea = view_as<CTFNavArea>(NULL_AREA);
	g_TFBot[client].BuildingTarget = INVALID_ENT;
	g_TFBot[client].RepairTarget = INVALID_ENT;
	g_TFBot[client].DesiredWeaponSlot = -1;
	
	if (g_hTFBotEngineerBuildings[client])
	{
		delete g_hTFBotEngineerBuildings[client];
		g_hTFBotEngineerBuildings[client] = null;
	}
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
	
	if (IsPlayerSurvivor(client) && IsArtifactActive(REDArtifact_Restoration))
	{
		amount *= 2;
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
	rollTimes = GetPlayerLuckStat(client);
	
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
	if (PlayerHasItem(client, Item_HorrificHeadsplitter))
		return false;

	return (IsPlayerSurvivor(client) ||
	PlayerHasItem(client, Item_Archimedes) ||
	PlayerHasItem(client, Item_ClassCrown));
}

void PrintDeathMessage(int client, int customkill=0)
{
	char message[512];
	if (customkill == TF_CUSTOM_BLEEDING && PlayerHasItem(client, Item_HorrificHeadsplitter))
	{
		FormatEx(message, sizeof(message), "HeadsplitterDeath");
		CPrintToChatAll("%t", message, client);
		Format(message, sizeof(message), "%T", message, LANG_SERVER, client);
		CRemoveTags(message, sizeof(message));
		PrintToServer(message);
		return;
	}
	
	const int maxMessages = 10;
	int randomMessage = GetRandomInt(1, maxMessages);
	FormatEx(message, sizeof(message), "DeathMessage%i", randomMessage);
	CPrintToChatAll("%t", message, client);
	Format(message, sizeof(message), "%T", message, LANG_SERVER, client);
	CRemoveTags(message, sizeof(message));
	PrintToServer(message);
}

int CalculatePlayerMaxHealth(int client, bool partialHeal=true, bool fullHeal=false)
{
	int oldMaxHealth = RF2_GetCalculatedMaxHealth(client);
	float healthScale = GetPlayerHealthMult(client);
	int maxHealth = RoundToFloor(float(RF2_GetBaseMaxHealth(client)) * healthScale);
	
	// Bosses have less health in single player (for now) to avoid overly long fights
	if (IsSingleplayer(false) && IsBoss(client))
	{
		maxHealth = RoundToFloor(float(maxHealth) * 0.75);
	}
	
	if (PlayerHasItem(client, Item_PrideScarf))
	{
		maxHealth += RoundToFloor(float(maxHealth) * (1.0 + CalcItemMod(client, Item_PrideScarf, 0))) - maxHealth;
	}
	
	if (PlayerHasItem(client, Item_ClassCrown))
	{
		maxHealth += RoundToFloor(float(maxHealth) * (1.0 + CalcItemMod(client, Item_ClassCrown, 0))) - maxHealth;
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		TF2Attrib_SetByDefIndex(client, 286, healthScale); // building health
		
		// If we have any buildings up, update their max health now
		int buildingMaxHealth, oldBuildingMaxHealth, buildingHealth;
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
					buildingHealth = GetEntProp(entity, Prop_Send, "m_iHealth") + (buildingMaxHealth-oldBuildingMaxHealth);
					SetVariantInt(imax(buildingHealth, 1));
					// NOTE: The SetHealth input is very misleading. It sets the building's MAX HEALTH, not the HEALTH value. Use AddHealth to change building health.
					AcceptEntityInput(entity, "SetHealth");
				}
			}
		}
	}
	
	int classMaxHealth = GetClassMaxHealth(TF2_GetPlayerClass(client));
	TF2Attrib_SetByDefIndex(client, 26, float(maxHealth-classMaxHealth)); // "max health additive bonus"
	int actualMaxHealth = SDK_GetPlayerMaxHealth(client);
	g_iPlayerCalculatedMaxHealth[client] = actualMaxHealth;
	
	if (fullHeal)
	{
		HealPlayer(client, actualMaxHealth, false, _, false);
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
		switch (GetEntProp(entity, Prop_Send, "m_iUpgradeLevel"))
		{
			case 1: maxHealth = 150;
			case 2: maxHealth = 180;
			case 3: maxHealth = 216;
		}
	}
	
	if (PlayerHasItem(client, Item_PrideScarf))
	{
		maxHealth += RoundToFloor(float(maxHealth) * (1.0 + CalcItemMod(client, Item_PrideScarf, 0))) - maxHealth;
	}
	
	if (PlayerHasItem(client, Item_ClassCrown))
	{
		maxHealth += RoundToFloor(float(maxHealth) * (1.0 + CalcItemMod(client, Item_ClassCrown, 0))) - maxHealth;
	}
	
	maxHealth = RoundToFloor(float(maxHealth) * TF2Attrib_HookValueFloat(1.0, "mult_engy_building_health", client));
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
	if (g_bWaitingForPlayers)
	{
		return GetClassMaxSpeed(TF2_GetPlayerClass(client));
	}
	
	float speed = g_flPlayerMaxSpeed[client];
	float classMaxSpeed = GetClassMaxSpeed(TF2_GetPlayerClass(client));
	
	if (PlayerHasItem(client, Item_RobinWalkers))
	{
		speed *= 1.0 + CalcItemMod(client, Item_RobinWalkers, 0);
	}
	
	if (PlayerHasItem(client, Item_TripleA))
	{
		speed *= 1.0 + CalcItemMod(client, Item_TripleA, 2);
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
	if (!IsBoss(client))
	{
		float kbRes = 1.0 / GetEnemyDamageMult();
		if (IsPlayerSurvivor(client))
		{
			kbRes *= 0.75; // Survivors get a bit more
		}

		TF2Attrib_SetByDefIndex(client, 252, kbRes); // "damage force reduction"
	}
}

float GetPlayerCash(int client)
{
	return g_flPlayerCash[client];
}

void SetPlayerCash(int client, float amount)
{
	g_flPlayerCash[client] = amount;
}

void AddPlayerCash(int client, float amount)
{
	g_flPlayerCash[client] += amount;
}

// This is for items, it has nothing to do with the attribute
float GetPlayerFireRateMod(int client, int weapon=-1)
{
	float multiplier = 1.0;
	static char classname[64];
	if (weapon > 0)
	{
		GetEntityClassname(weapon, classname, sizeof(classname));
		
		// Dragon's Fury is different
		if (strcmp2(classname, "tf_weapon_rocketlauncher_fireball"))
		{
			multiplier += CalcItemMod(client, Item_MaimLicense, 0);
			multiplier += float(g_iPlayerFireRateStacks[client]) * GetItemMod(Item_PointAndShoot, 1);
			multiplier += CalcItemMod(client, Item_MaxHead, 2);
			multiplier += CalcItemMod(client, Item_SaintMark, 3);
			multiplier += CalcItemMod(client, Item_TripleA, 1);
			return multiplier;
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
	
	if (weapon > 0 && multiplier < 1.0)
	{
		if (strcmp2(classname, "tf_weapon_minigun") || strcmp2(classname, "tf_weapon_syringegun_medic"))
		{
			const float penalty = 0.5;
			multiplier = Pow(multiplier, penalty);
		}
	}
	
	return multiplier;
}

float GetPlayerReloadMod(int client)
{
	float reloadMult = 1.0;
	reloadMult *= CalcItemMod_HyperbolicInverted(client, Item_RoundedRifleman, 0);
	reloadMult *= CalcItemMod_HyperbolicInverted(client, Item_TripleA, 0);
	if (g_flPlayerReloadBuffDuration[client] > 0.0)
	{
		reloadMult *= GetItemMod(Item_SaintMark, 0);
	}
	
	return reloadMult;
}

int GetPlayerLuckStat(int client)
{
	return CalcItemModInt(client, Item_LuckyCatHat, 0) - CalcItemModInt(client, Item_MisfortuneFedora, 0);
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
		g_TFBot[client].RealizeSpy(attacker);
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == attacker || i == client || !IsClientInGame(i) || !IsPlayerAlive(i) || !IsFakeClient(i) || GetClientTeam(i) == GetClientTeam(attacker))
			continue;
	
		if (DistBetween(i, client) <= 800.0 && IsLOSClear(client, i, MASK_OPAQUE|CONTENTS_IGNORE_NODRAW_OPAQUE))
		{
			g_TFBot[i].RealizeSpy(attacker);
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

void OnPlayerAirDash(int client, int count)
{
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

int GetPlayerBuildingCount(int client, TFObjectType type=view_as<TFObjectType>(-1), bool allowMini=true)
{
	int count;
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "obj_*")) != INVALID_ENT)
	{
		if (!allowMini && GetEntProp(entity, Prop_Send, "m_bMiniBuilding"))
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
	TFCond rune = view_as<TFCond>(g_MannpowerRunes[GetRandomInt(0, sizeof(g_MannpowerRunes)-1)]);
	
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

bool IsPlayerMiniCritBuffed(int client)
{
	return TF2_IsPlayerInCondition(client, TFCond_CritCola)
		|| TF2_IsPlayerInCondition(client, TFCond_Buffed)
		|| TF2_IsPlayerInCondition(client, TFCond_NoHealingDamageBuff)
		|| TF2_IsPlayerInCondition(client, TFCond_MiniCritOnKill);
}

void SDK_ForceSpeedUpdate(int client)
{
	if (g_hSDKUpdateSpeed)
	{
		SDKCall(g_hSDKUpdateSpeed, client);
	}
}

public MRESReturn DHook_HandleRageGain(DHookParam params)
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

public MRESReturn DHook_TakeHealth(int entity, Handle returnVal, Handle params)
{
	if (IsValidClient(entity))
	{
		float health = DHookGetParam(params, 1);
		health *= GetPlayerHealthMult(entity);
		if (IsPlayerSurvivor(entity) && IsArtifactActive(REDArtifact_Restoration))
		{
			health *= 2.0;
		}
		
		DHookSetParam(params, 1, health);
		return MRES_ChangedHandled;
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
	if (weapon == -1 || weapon == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
		return false;
	
	return SDKCall(g_hSDKWeaponSwitch, client, weapon, 0);
}

bool IsPlayerAFK(int client)
{
	return g_bPlayerIsAFK[client];
}

void ResetAFKTime(int client, bool message=true)
{
	if (IsClientInGame(client) && IsPlayerAFK(client))
	{
		if (message && g_cvEnableAFKManager.BoolValue)
		{
			PrintCenterText(client, "%t", "NoLongerAFK");
		}
		
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
	if (g_bWaitingForPlayers)
	{
		ChangeClientTeam(client, 1);
	}
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
	if (IsPlayerSurvivor(client))
	{
		return 1.0 + (float(GetPlayerLevel(client)-1) * g_cvSurvivorHealthScale.FloatValue);
	}

	return GetEnemyHealthMult();
}

float GetPlayerDamageMult(int client)
{
	if (IsPlayerSurvivor(client))
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
	if (entity <= MaxClients && entity != client && GetClientTeam(entity) == GetClientTeam(client))
		return true;

	return false;
}

public bool TraceFilter_EnemyTeam(int entity, int mask, int client)
{
	if (entity <= MaxClients && entity != client && GetClientTeam(entity) != GetClientTeam(client))
		return true;

	return false;
}
