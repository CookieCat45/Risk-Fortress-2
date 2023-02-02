#if defined _RF2_functions_entities_included
 #endinput
#endif
#define _RF2_functions_entities_included

#pragma semicolon 1
#pragma newdecls required

// ONLY pass SQUARED distances for minDistance.
int GetNearestEntity(float origin[3], const char[] classname, float minDistance = -1.0, int team = -1)
{
	int nearestEntity = -1;
	float pos[3];
	float distance, nearestDistance = -1.0;
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, classname)) != -1)
	{
		if (team > -1 && GetEntProp(entity, Prop_Data, "m_iTeamNum") != team)
		{
			continue;
		}
		
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
		distance = GetVectorDistance(origin, pos, true);
		
		if (distance >= minDistance)
		{
			if (distance < nearestDistance || nearestDistance == -1.0)
			{
				nearestEntity = entity;
				nearestDistance = distance;
			}
		}
	}
	
	return nearestEntity;
}

// ONLY pass SQUARED distances for minDistance.
// Checks StrContains() on the classname instead of using FindEntityByClassname.
int GetNearestEntityEx(float origin[3], const char[] str, float minDistance = -1.0, int team = -1)
{
	int nearestEntity = -1;
	char classname[128];
	float pos[3];
	float distance, nearestDistance = -1.0;
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		GetEntityClassname(entity, classname, sizeof(classname));
		if (StrContains(classname, str) != 0)
		{
			continue;
		}
		
		if (team > -1 && GetEntProp(entity, Prop_Data, "m_iTeamNum") != team)
		{
			continue;
		}
		
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
		distance = GetVectorDistance(origin, pos, true);
		
		if (distance >= minDistance)
		{
			if (distance < nearestDistance || nearestDistance == -1.0)
			{
				nearestEntity = entity;
				nearestDistance = distance;
			}
		}
	}
	
	return nearestEntity;
}

// SPELL PROJECTILES WILL ONLY WORK IF THE OWNER ENTITY IS A PLAYER! DO NOT TRY THEM WITH ANYTHING ELSE!
int ShootProjectile(int owner=-1, const char[] projectileName, const float pos[3], const float angles[3], float speed, float damage=-1.0, float arc=0.0)
{
	int entity = CreateEntityByName(projectileName);
	if (entity == -1)
	{
		return -1;
	}
	
	SetEntityOwner(entity, owner);
	if (owner > 0)
	{
		SetEntProp(entity, Prop_Data, "m_iTeamNum", GetEntProp(owner, Prop_Data, "m_iTeamNum"));
	}
		
	float projectileAngles[3], velocity[3];
	CopyVectors(angles, projectileAngles);
	projectileAngles[0] += arc;
	
	if (damage >= 0.0)
	{
		if (strcmp2(projectileName, "tf_projectile_pipebomb") || 
		strcmp2(projectileName, "tf_projectile_spellbats") ||
		strcmp2(projectileName, "tf_projectile_spelltransposeteleport"))
		{
			SetEntPropFloat(entity, Prop_Send, "m_flDamage", damage);
		}
		else if (strcmp2(projectileName, "tf_projectile_rocket"))
		{
			SetEntDataFloat(entity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, damage, true);
		}
		else
		{
			g_flProjectileForcedDamage[entity] = damage;
			if (strcmp2(projectileName, "tf_projectile_spellfireball")) // fireballs do 2 instances of damage for some reason
			{
				g_flProjectileForcedDamage[entity] *= 0.5;
			}
			
			SDKHook(entity, SDKHook_StartTouch, Hook_ForceProjectileDamage);
		}
	}
	
	GetAngleVectors(projectileAngles, velocity, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(velocity, velocity);
	ScaleVector(velocity, speed);
	
	DispatchSpawn(entity);
	ActivateEntity(entity);
	TeleportEntity(entity, pos, projectileAngles, velocity);
	SetEntPropVector(entity, Prop_Send, "m_vecForce", velocity);
	
	return entity;
}

void DoRadiusDamage(int attacker, int item=Item_Null, const float pos[3], float baseDamage, int damageFlags, float radius, int weapon=-1, float minimumFalloffMultiplier=0.3, bool explosionEffect=false)
{
	Handle trace;
	float enemyPos[3];
	float distance, falloffMultiplier, calculatedDamage;
	
	int attackerTeam = GetEntProp(attacker, Prop_Data, "m_iTeamNum");
	int entity = -1;
	
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		if (entity < 1)
			continue;
		
		if (!IsValidClient(entity) && !IsNPC(entity) && !IsBuilding(entity) || entity == attacker)
			continue;
		
		if (IsValidClient(entity) && !IsPlayerAlive(entity))
			continue;
				
		if (attackerTeam == GetEntProp(entity, Prop_Data, "m_iTeamNum"))
			continue;
		
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", enemyPos);
		enemyPos[2] += 30.0;
		
		if ((distance = GetVectorDistance(pos, enemyPos)) <= radius)
		{
			trace = TR_TraceRayFilterEx(pos, enemyPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceFilter_WallsOnly);
			if (!TR_DidHit(trace))
			{
				falloffMultiplier = 1.0 - distance / radius;
				if (falloffMultiplier < minimumFalloffMultiplier)
				{
					falloffMultiplier = minimumFalloffMultiplier;
				}
				
				calculatedDamage = baseDamage * falloffMultiplier;
				
				if (IsValidClient(attacker) && item > Item_Null)
				{
					SetEntItemDamageProc(attacker, item);
				}
				
				SDKHooks_TakeDamage(entity, attacker, attacker, calculatedDamage, damageFlags, weapon, _, _, false);
			}
			
			delete trace;
		}
	}
	
	if (explosionEffect)
	{
		int explosion = CreateEntityByName("env_explosion");
		DispatchKeyValueFloat(explosion, "iMagnitude", 0.0);
		TeleportEntity(explosion, pos);
		DispatchSpawn(explosion);
		AcceptEntityInput(explosion, "Explode");
	}
}

void SpawnCashDrop(float cashValue, float pos[3], int size=1, float vel[3]=NULL_VECTOR)
{
	char classname[128];
	switch (size)
	{
		case 1: classname = "item_currencypack_small";
		case 2: classname = "item_currencypack_medium";
		case 3: classname = "item_currencypack_large";
		default: classname = "item_currencypack_small";
	}
	
	int entity = CreateEntityByName(classname);
	g_flCashValue[entity] = cashValue;
	
	TeleportEntity(entity, pos, _, vel);
	DispatchSpawn(entity);
	SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
	
	CreateTimer(0.25, Timer_CashMagnet, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(g_cvCashBurnTime.FloatValue, Timer_DeleteCash, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DeleteCash(Handle timer, int entity)
{
	if (EntRefToEntIndex(entity) == INVALID_ENT_REFERENCE)
		return Plugin_Continue;
		
	float pos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
	TE_TFParticle("mvm_cash_explosion", pos);
	RemoveEntity(entity);
	
	return Plugin_Continue;
}

public Action Timer_CashMagnet(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE)
		return Plugin_Stop;
	
	float pos[3], scoutPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameEx(i) || !IsPlayerAlive(i) || !IsPlayerSurvivor(i))
			continue;
		
		// Scouts pick up cash in a radius automatically, like in MvM. Though the healing is on an item: the Heart Of Gold.
		if (TF2_GetPlayerClass(i) == TFClass_Scout)
		{
			GetClientAbsOrigin(i, scoutPos);
			
			if (GetVectorDistance(pos, scoutPos, true) <= sq(450.0))
			{
				EmitSoundToAll(SOUND_MONEY_PICKUP, entity);
				PickupCash(i, entity);
			}
		}
	}
	
	return Plugin_Continue;
}

void PickupCash(int client, int entity)
{
	// If client is 0 or below, the cash is most likely being collected automatically.
	if (client < 1 || IsPlayerSurvivor(client))
	{
		float modifier = 1.0;
		ArrayList clientArray = CreateArray();
		
		// Check for Proof of Purchase item first to make sure everyone gets the bonus
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGameEx(i) || !IsPlayerSurvivor(i))
				continue;
			
			clientArray.Push(i);		
			
			if (PlayerHasItem(i, Item_ProofOfPurchase))
			{
				modifier += CalcItemMod(i, Item_ProofOfPurchase, 0);
			}
		}
		
		for (int i = 0; i < clientArray.Length; i++)
		{
			g_flPlayerCash[clientArray.Get(i)] += g_flCashValue[entity] * modifier;
		}
		
		if (client > 0)
		{
			if (PlayerHasItem(client, Item_HeartOfGold))
			{
				int heal = RoundToFloor(CalcItemMod(client, Item_HeartOfGold, 0));
				HealPlayer(client, heal, GetItemModBool(Item_HeartOfGold, 1));
			}
			
			if (GetRandomInt(1, 20) == 1)
			{
				SetVariantString("randomnum:100");
				AcceptEntityInput(client, "AddContext");
				
				SetVariantString("IsMvMDefender:1");
				AcceptEntityInput(client, "AddContext");
				
				SetVariantString("TLK_MVM_MONEY_PICKUP");
				AcceptEntityInput(client, "SpeakResponseConcept");
				AcceptEntityInput(client, "ClearContext");
			}
		}
		
		delete clientArray;
		RemoveEntity(entity);
	}
}

void SetEntItemDamageProc(int entity, int item)
{
	g_iItemDamageProc[entity] = item;
}

int GetEntItemDamageProc(int entity)
{
	return g_iItemDamageProc[entity];
}

bool IsNPC(int entity)
{
	if (entity <= MaxClients) // we don't want player bots
		return false;
	
	return (CBaseEntity(entity).MyNextBotPointer() != NULL_NEXT_BOT);
}