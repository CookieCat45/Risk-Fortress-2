#if defined _RF2_functions_entities_included
 #endinput
#endif
#define _RF2_functions_entities_included

#pragma semicolon 1
#pragma newdecls required

// ONLY pass SQUARED distances for minDistance.
int GetNearestEntity(float origin[3], char[] classname, char[] targetname="", float minDistance = -1.0, int team = -1)
{
	int nearestEntity = -1;
	float entityOrigin[3];
	char entName[128];
	bool checkName;
	
	if (targetname[0])
		checkName = true;
	
	float distance, nearestDistance = -1.0;
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, classname)) != -1)
	{
		if (checkName)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", entName, sizeof(entName));
			if (strcmp(targetname, entName) != 0)
				continue;
		}
		
		if (team > -1)
		{
			if (GetEntProp(entity, Prop_Data, "m_iTeamNum") != team)
				continue;
		}

		
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityOrigin);
		distance = GetVectorDistance(origin, entityOrigin, true);
	
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
	if (entity < 0)
	{
		LogError("[ShootProjectile] Invalid projectile classname: %s", projectileName);
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
		if (strcmp(projectileName, "tf_projectile_pipebomb") == 0 || 
		strcmp(projectileName, "tf_projectile_spellbats") == 0 ||
		strcmp(projectileName, "tf_projectile_spelltransposeteleport") == 0)
		{
			SetEntPropFloat(entity, Prop_Send, "m_flDamage", damage);
		}
		else if (strcmp(projectileName, "tf_projectile_rocket") == 0)
		{
			SetEntDataFloat(entity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, damage, true);
		}
		else
		{
			g_flProjectileForcedDamage[entity] = damage;
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
	float calculatedDamage;
	float enemyPos[3];
	float distance;
	float falloffMultiplier;
	
	int entCount = GetEntityCount();
	int attackerTeam = GetEntProp(attacker, Prop_Data, "m_iTeamNum");
	
	for (int i = 1; i <= entCount; i++)
	{
		if (!IsValidEntity(i) || i > MaxClients && !IsNPC(i) && !IsBuilding(i) || i == attacker)
			continue;
		
		if (IsValidClient(i) && !IsPlayerAlive(i))
			continue;
				
		if (attackerTeam == GetEntProp(i, Prop_Data, "m_iTeamNum"))
			continue;
		
		GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", enemyPos);
		enemyPos[2] += 30.0;
		
		if ((distance = GetVectorDistance(pos, enemyPos)) <= radius)
		{
			trace = TR_TraceRayFilterEx(pos, enemyPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceWallsOnly);
			if (!TR_DidHit(trace))
			{
				falloffMultiplier = 1.0 - distance / radius;
				if (falloffMultiplier < minimumFalloffMultiplier)
				{
					falloffMultiplier = minimumFalloffMultiplier;
				}
				
				calculatedDamage = baseDamage * falloffMultiplier;
				
				if (IsValidClient(attacker) && item > Item_Null)
					SetEntItemDamageProc(attacker, item);
				
				SDKHooks_TakeDamage(i, attacker, attacker, calculatedDamage, damageFlags, weapon, _, _, false);
			}
			
			delete trace;
		}
	}
	
	if (explosionEffect)
	{
		int explosion = CreateEntityByName("env_explosion");
		DispatchKeyValue(explosion, "iMagnitude", "0.0");
		TeleportEntity(explosion, pos);
		DispatchSpawn(explosion);
		AcceptEntityInput(explosion, "Explode");
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

bool IsBuilding(int entity)
{
	// let's not count sappers
	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	return (HasEntProp(entity, Prop_Send, "m_hBuilder") && strcmp(classname, "obj_attachment_sapper") != 0);
}

public bool TraceWallsOnly(int entity, int mask)
{
	return false;
}

public bool TraceDontHitSelf(int self, int mask, int other)
{
	return !(self == other);
}

public bool TraceFilter_SpawnCheck(int entity, int mask, bool npc)
{
	if ((npc ? mask & MASK_NPCSOLID : mask & MASK_PLAYERSOLID))
		return true;
		
	return false;
}

bool CanTeamQuickBuild(int team)
{
	return team == TEAM_SURVIVOR && g_cvSurvivorQuickBuild.BoolValue || team == TEAM_ENEMY && g_cvEnemyQuickBuild.BoolValue;
}

void SDK_DoQuickBuild(int building, bool forceMaxLevel=false)
{
	if (g_hSDKDoQuickBuild)
		SDKCall(g_hSDKDoQuickBuild, building, forceMaxLevel);
}

int SDK_TakeHealth(int entity, int amount, int flags=DMG_GENERIC)
{
	if (g_hSDKTakeHealth)
		return SDKCall(g_hSDKTakeHealth, entity, float(amount), flags);
	
	return -1;
}

public MRESReturn DHook_StartUpgrading(int entity, DHookReturn returnVal, DHookParam params)
{
	// skip upgrade anim
	if (GetEntProp(entity, Prop_Send, "m_bCarryDeploy") || GameRules_GetProp("m_bInSetup"))
	{
		GameRules_SetProp("m_bPlayingMannVsMachine", true);
	}
	
	return MRES_Ignored;
}

public MRESReturn DHook_StartUpgradingPost(int entity, DHookReturn returnVal, DHookParam params)
{
	GameRules_SetProp("m_bPlayingMannVsMachine", false);
	return MRES_Ignored;
}