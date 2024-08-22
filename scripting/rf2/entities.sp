#pragma semicolon 1
#pragma newdecls required

void RF_TakeDamage(int entity, int inflictor, int attacker, float damage, int damageType=DMG_GENERIC, int procItem=Item_Null, 
	int weapon=-1, const float damageForce[3]=NULL_VECTOR, const float damagePosition[3]=NULL_VECTOR)
{
	if (procItem > Item_Null)
	{
		if (attacker > 0)
			SetEntItemProc(attacker, procItem);
		
		if (inflictor > 0)
			SetEntItemProc(inflictor, procItem);
	}
	
	SDKHooks_TakeDamage(entity, inflictor, attacker, damage, damageType, weapon, damageForce, damagePosition, false);
}

int GetNearestEntity(float origin[3], const char[] classname, float minDist=-1.0, float maxDist=-1.0, int team=-1, bool trace=false)
{
	int nearestEntity = -1;
	float pos[3];
	float distance;
	float nearestDist = -1.0;

	int entity = -1;
	float minDistSq = sq(minDist);
	float maxDistSq = sq(maxDist);

	while ((entity = FindEntityByClassname(entity, classname)) != -1)
	{
		if (team > -1 && GetEntTeam(entity) != team)
			continue;
		
		GetEntPos(entity, pos);
		if (trace)
		{
			pos[2] += 20.0;
			origin[2] += 20.0;
			TR_TraceRayFilter(origin, pos, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceFilter_WallsOnly);
			pos[2] -= 20.0;
			origin[2] -= 20.0;

			if (TR_DidHit())
			{
				continue;
			}
		}

		distance = GetVectorDistance(origin, pos, true);

		if ((minDist <= 0.0 || distance >= minDistSq) && (maxDist <= 0.0 || distance <= maxDistSq))
		{
			if (distance < nearestDist || nearestDist == -1.0)
			{
				nearestEntity = entity;
				nearestDist = distance;
			}
		}
	}

	return nearestEntity;
}

float DistBetween(int ent1, int ent2, bool squared=false)
{
	float pos1[3], pos2[3];
	GetEntPropVector(ent1, Prop_Data, "m_vecAbsOrigin", pos1);
	GetEntPropVector(ent2, Prop_Data, "m_vecAbsOrigin", pos2);
	return GetVectorDistance(pos1, pos2, squared);
}

bool IsLOSClear(int ent1, int ent2, int mask=MASK_PLAYERSOLID_BRUSHONLY)
{
	float pos1[3], pos2[3];
	CBaseEntity(ent1).WorldSpaceCenter(pos1);
	CBaseEntity(ent2).WorldSpaceCenter(pos2);
	TR_TraceRayFilter(pos1, pos2, mask, RayType_EndPoint, TraceFilter_WallsOnly);
	return !TR_DidHit();
}

/*
float DistToPos(int entity, const float pos[3], bool squared=false)
{
	float entPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", entPos);
	return GetVectorDistance(entPos, pos, squared);
}
*/

bool DoEntitiesIntersect(int ent1, int ent2)
{
	if (g_hSDKIntersects)
	{
		return SDKCall(g_hSDKIntersects, ent1, ent2);
	}
	
	return false;
}

// SPELL PROJECTILES WILL ONLY WORK IF THE OWNER ENTITY IS A PLAYER! DO NOT TRY THEM WITH ANYTHING ELSE!
int ShootProjectile(int owner=INVALID_ENT, const char[] classname, const float pos[3], const float angles[3],
	float speed, float damage=-1.0, float arc=0.0, bool allowCrit=true, bool spawn=true)
{
	int entity = CreateEntityByName(classname);
	if (entity == INVALID_ENT)
	{
		if (StrContains(classname, "rf2_") == 0)
		{
			LogError("[ShootProjectile] Invalid projectile entity %s. Did you possibly forget to call the Init() method on a custom projectile?", classname);
		}
		
		return INVALID_ENT;
	}
	
	if (RF2_Projectile_Base(entity).IsValid())
	{
		RF2_Projectile_Base(entity).Owner = owner;
	}
	
	SetEntityOwner(entity, owner);
	if (owner > 0)
	{
		SetEntTeam(entity, GetEntTeam(owner));
	}
	
	float projectileAngles[3], velocity[3];
	CopyVectors(angles, projectileAngles);
	projectileAngles[0] += arc;
	
	if (damage >= 0.0)
	{
		if (RF2_Projectile_Base(entity).IsValid())
		{
			RF2_Projectile_Base(entity).Damage = damage;
			RF2_Projectile_Base(entity).DirectDamage = damage;
		}
		else if (strcmp2(classname, "tf_projectile_pipebomb") 
			|| strcmp2(classname, "tf_projectile_spellbats")
			|| strcmp2(classname, "tf_projectile_spelltransposeteleport"))
		{
			SetEntPropFloat(entity, Prop_Send, "m_flDamage", damage);
		}
		else if (strcmp2(classname, "tf_projectile_rocket") || strcmp2(classname, "tf_projectile_sentryrocket"))
		{
			int offset = FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4;
			SetEntDataFloat(entity, offset, damage, true);
		}
		else
		{
			g_flProjectileForcedDamage[entity] = damage;
			SDKHook(entity, SDKHook_StartTouch, Hook_ProjectileForceDamage);
		}
	}
	
	// no annoying server console message
	if (strcmp2(classname, "tf_projectile_arrow"))
	{
		int offset = FindSendPropInfo("CTFProjectile_Arrow", "m_iProjectileType") + 32; // m_flInitTime
		SetEntDataFloat(entity, offset, GetGameTime()+9999.0, true);
	}
	
	if (allowCrit && IsValidClient(owner) && HasEntProp(entity, Prop_Send, "m_bCritical"))
	{
		if (RollAttackCrit(owner) || PlayerHasItem(owner, Item_Executioner) && IsPlayerMiniCritBuffed(owner))
		{
			SetEntProp(entity, Prop_Send, "m_bCritical", true);
		}
	}
	
	GetAngleVectors(projectileAngles, velocity, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(velocity, velocity);
	ScaleVector(velocity, speed);
	if (spawn)
	{
		DispatchSpawn(entity);
		ActivateEntity(entity);
	}
	
	TeleportEntity(entity, pos, projectileAngles, velocity);
	SetEntPropVector(entity, Prop_Send, "m_vecForce", velocity);
	return entity;
}

/* Does damage to entities in the specified radius.
* @param attacker 			Entity responsible for the daamge.
* @param inflictor 			Entity dealing the damage.
* @param pos 				Position to deal damage from.
* @param item 				Item index associated with the damage, if any. Only works if attacker is a client.
* @param baseDamage 		Base damage.
* @param damageFlags 		Damage flags.
* @param radius 			Radius of the damage.
* @param minFalloffMult		Minimum damage falloff.
* @param allowSelfDamage	Allow self damage.
* @param blacklist			ArrayList of entities to ignore when dealing damage.
* @param returnHitEnts		If true, return an ArrayList of entities that were hit.
*
* @return If returnHitEnts is TRUE, return ArrayList of hit entities, otherwise return NULL.
*/
ArrayList DoRadiusDamage(int attacker, int inflictor, const float pos[3], int item=Item_Null,
	float baseDamage, int damageFlags, float radius, float minFalloffMult=0.3, 
	bool allowSelfDamage=false, ArrayList blacklist=null, bool returnHitEnts=false)
{
	float enemyPos[3];
	float distance, falloffMultiplier, calculatedDamage;
	int attackerTeam = GetEntTeam(attacker);
	int entity = INVALID_ENT;
	ArrayList hitEnts;
	if (returnHitEnts)
	{
		hitEnts = new ArrayList();
	}
	
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		if (entity < 1 || !allowSelfDamage && entity == attacker)
			continue;
		
		if (blacklist && blacklist.FindValue(entity) != -1)
			continue;
		
		if ((!IsValidClient(entity) || !IsPlayerAlive(entity)) && !IsNPC(entity) && !IsBuilding(entity) || entity == attacker && !allowSelfDamage)
			continue;
		
		if (attackerTeam == GetEntTeam(entity) && (entity != attacker || entity == attacker && !allowSelfDamage))
			continue;
		
		GetEntPos(entity, enemyPos);
		enemyPos[2] += 30.0;
		
		if ((distance = GetVectorDistance(pos, enemyPos)) <= radius)
		{
			TR_TraceRayFilter(pos, enemyPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceFilter_WallsOnly);
			if (!TR_DidHit())
			{
				// check for shields as well
				TR_TraceRayFilter(pos, enemyPos, MASK_SOLID, RayType_EndPoint, TraceFilter_DispenserShield, GetEntTeam(attacker), TRACE_ENTITIES_ONLY);
				if (!TR_DidHit())
				{
					falloffMultiplier = 1.0 - distance / radius;
					if (falloffMultiplier < minFalloffMult)
					{
						falloffMultiplier = minFalloffMult;
					}
					
					calculatedDamage = baseDamage * falloffMultiplier;
					RF_TakeDamage(entity, inflictor, attacker, calculatedDamage, damageFlags, item);
					if (returnHitEnts)
					{
						hitEnts.Push(entity);
					}
				}
			}
		}
	}
	
	return hitEnts;
}

void DoExplosionEffect(const float pos[3], bool sound=true)
{
	int explosion = CreateEntityByName("env_explosion");
	DispatchKeyValueFloat(explosion, "iMagnitude", 0.0);
	if (!sound)
	{
		DispatchKeyValueInt(explosion, "spawnflags", 64);
	}
	
	TeleportEntity(explosion, pos);
	DispatchSpawn(explosion);
	AcceptEntityInput(explosion, "Explode");
}

void SetEntityMoveCollide(int entity, int moveCollide)
{
	SetEntProp(entity, Prop_Send, "movecollide", moveCollide);
}

int SpawnCashDrop(float cashValue, float pos[3], int size=1, float vel[3]={0.0, 0.0, 400.0})
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
	DispatchKeyValueInt(entity, "spawnflags", SF_NORESPAWN);
	SDKHook(entity, SDKHook_GroundEntChangedPost, Hook_CashGroundEntChangedPost);
	TeleportEntity(entity, pos);
	DispatchSpawn(entity);
	SetEntProp(entity, Prop_Send, "m_bDistributed", true); // prevent money from being removed when resting in an area with no nav mesh
	SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
	SetEntityMoveCollide(entity, MOVECOLLIDE_FLY_BOUNCE);
	CBaseEntity(entity).SetAbsVelocity(vel);
	RequestFrame(RF_CashThinkRate, EntIndexToEntRef(entity));
	CreateTimer(0.25, Timer_CashMagnet, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(g_cvCashBurnTime.FloatValue, Timer_DeleteCash, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	return entity;
}

public void Hook_CashGroundEntChangedPost(int entity)
{
	SetEntPropEnt(entity, Prop_Data, "m_hGroundEntity", -1);
	CBaseEntity(entity).RemoveFlag(FL_ONGROUND);
}

public void RF_CashThinkRate(int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return;
	
	CBaseEntity(entity).SetNextThink(GetGameTime()); // Fixes laggy movement
	RequestFrame(RF_CashThinkRate, EntIndexToEntRef(entity));
}

public Action Timer_DeleteCash(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return Plugin_Continue;
	
	float pos[3];
	GetEntPos(entity, pos);
	TE_TFParticle("mvm_cash_explosion", pos);
	RemoveEntity2(entity);

	return Plugin_Continue;
}

public Action Timer_CashMagnet(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return Plugin_Stop;
	
	float pos[3], playerPos[3], angles[3], vel[3];
	GetEntPos(entity, pos);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || !IsPlayerSurvivor(i))
			continue;
		
		if (PlayerHasItem(i, Item_BanditsBoots))
		{
			GetEntPos(i, playerPos);
			playerPos[2] += 75.0;
			if (GetVectorDistance(pos, playerPos, true) <= sq(CalcItemMod(i, Item_BanditsBoots, 2)))
			{
				GetVectorAnglesTwoPoints(pos, playerPos, angles);
				GetAngleVectors(angles, vel, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(vel, vel);
				ScaleVector(vel, 550.0);
				SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
				SetEntityMoveCollide(entity, MOVECOLLIDE_FLY_BOUNCE);
				CBaseEntity(entity).RemoveFlag(FL_ONGROUND);
				CBaseEntity(entity).SetAbsVelocity(vel);
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
		ArrayList clientArray = new ArrayList();
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerSurvivor(i) && !IsPlayerMinion(i))
				continue;
			
			clientArray.Push(i);
		}
		
		int receiver;
		float mult;
		for (int i = 0; i < clientArray.Length; i++)
		{
			receiver = clientArray.Get(i);
			mult = 1.0;
			if (GetPlayerCrateBonus(receiver) > 0 && !IsBossEventActive())
			{
				mult += 0.5;
			}
			
			if (g_bRingCashBonus)
			{
				mult += GetItemMod(ItemStrange_SpecialRing, 0);
			}
			
			AddPlayerCash(receiver, g_flCashValue[entity] * mult);
		}
		
		if (client > 0)
		{
			SpeakResponseConcept_MVM(client, "TLK_MVM_MONEY_PICKUP");
			
			if (PlayerHasItem(client, Item_BanditsBoots))
			{
				HealPlayer(client, CalcItemModInt(client, Item_BanditsBoots, 1));
			}
		}
		
		delete clientArray;
		RemoveEntity2(entity);
	}
}

int SpawnInfoParticle(const char[] effectName, const float pos[3], float duration=0.0, int parent=-1, const char[] attachment="")
{
	int particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", effectName);
	TeleportEntity(particle, pos);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "Start");
	
	if (parent != INVALID_ENT)
	{
		ParentEntity(particle, parent, attachment);
	}
	
	if (duration > 0.0)
	{
		CreateTimer(duration, Timer_DeleteEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return particle;
}

void TE_TFParticle(const char[] effectName, const float pos[3]=OFF_THE_MAP, int entity=-1, int attachType=PATTACH_ABSORIGIN, const char[] attachmentName="",
bool reset=false, bool controlPoint=false, const float controlPointOffset[3]=NULL_VECTOR, int clientArray[MAXTF2PLAYERS] = {-1, ...}, int clientAmount=0)
{
	TE_Start("TFParticleEffect");
	int index = GetParticleEffectIndex(effectName);
	if (index > -1)
	{
		TE_WriteNum("m_iParticleSystemIndex", index);
		if (attachmentName[0])
		{
			int attachPoint = LookupEntityAttachment(entity, attachmentName);
			TE_WriteNum("m_iAttachmentPointIndex", attachPoint);
			if (attachPoint == 0)
			{
				LogStackTrace("Invalid entity attachment %s", attachmentName);
			}
		}
		else
		{
			TE_WriteNum("m_iAttachmentPointIndex", 0);
		}
		
		TE_WriteNum("entindex", entity);
		TE_WriteFloat("m_vecOrigin[0]", pos[0]);
		TE_WriteFloat("m_vecOrigin[1]", pos[1]);
		TE_WriteFloat("m_vecOrigin[2]", pos[2]);
		TE_WriteFloat("m_vecStart[0]", pos[0]);
		TE_WriteFloat("m_vecStart[1]", pos[1]);
		TE_WriteFloat("m_vecStart[2]", pos[2]);
		TE_WriteNum("m_iAttachType", attachType);
		TE_WriteNum("m_bResetParticles", reset);
		TE_WriteNum("m_bControlPoint1", controlPoint);
		
		if (controlPoint && !IsNullVector(controlPointOffset))
		{
			TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", controlPointOffset[0]);
			TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", controlPointOffset[1]);
			TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", controlPointOffset[2]);
		}
		else
		{
			TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", 0.0);
			TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", 0.0);
			TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", 0.0);
		}
		
		if (clientAmount <= 0)
		{
			TE_SendToAll();
		}
		else
		{
			for (int i = 0; i < clientAmount; i++)
				TE_SendToClient(clientArray[i]);
		}
	}
	else
	{
		LogStackTrace("Invalid TE particle %s", effectName);
	}
}

int GetParticleEffectIndex(const char[] name)
{
	int index;
	int table = FindStringTable("ParticleEffectNames");
	int count = GetStringTableNumStrings(table);
	static char buffer[128];
	
	for (int i = 0; i < count; i++)
	{
		ReadStringTable(table, i, buffer, sizeof(buffer));
		if (strcmp2(buffer, name))
		{
			index = i;
			break;
		}
	}
	
	if (index < 0)
	{
		LogError("[GetParticleEffectIndex] Couldn't find particle effect \"%s\".", name);
	}
	
	return index;
}

void SpawnParticleViaTrigger(int entity, const char[] effectName, const char[] attachmentName="", int attachType=PATTACH_ABSORIGIN)
{
	int trigger = CreateEntityByName("trigger_particle");
	DispatchKeyValue(trigger, "particle_name", effectName);
	DispatchKeyValue(trigger, "attachment_name", attachmentName);
	DispatchKeyValueInt(trigger, "attachment_type", attachType);
	DispatchKeyValueInt(trigger, "spawnflags", 64);
	DispatchSpawn(trigger);
	SetVariantString("!activator");
	AcceptEntityInput(trigger, "StartTouch", entity, entity);
	RemoveEdict(trigger);
}

stock void TE_DrawBox(int client, const float origin[3], const float endOrigin[3], const float constMins[3], const float constMaxs[3], 
	float duration = 0.1, int laserIndex, const int color[4])
{
	float mins[3], maxs[3];
	CopyVectors(constMins, mins);
	CopyVectors(constMaxs, maxs);
	if( mins[0] == maxs[0] && mins[1] == maxs[1] && mins[2] == maxs[2] )
	{
		mins = {-15.0, -15.0, -15.0};
		maxs = {15.0, 15.0, 15.0};
	}
	else
	{
		AddVectors(endOrigin, maxs, maxs);
		AddVectors(origin, mins, mins);
	}

	float pos1[3], pos2[3], pos3[3], pos4[3], pos5[3], pos6[3];
	pos1 = maxs;
	pos1[0] = mins[0];
	pos2 = maxs;
	pos2[1] = mins[1];
	pos3 = maxs;
	pos3[2] = mins[2];
	pos4 = mins;
	pos4[0] = maxs[0];
	pos5 = mins;
	pos5[1] = maxs[1];
	pos6 = mins;
	pos6[2] = maxs[2];
	
	TE_SendBeam(client, maxs, pos1, duration, laserIndex, color);
	TE_SendBeam(client, maxs, pos2, duration, laserIndex, color);
	TE_SendBeam(client, maxs, pos3, duration, laserIndex, color);
	TE_SendBeam(client, pos6, pos1, duration, laserIndex, color);
	TE_SendBeam(client, pos6, pos2, duration, laserIndex, color);
	TE_SendBeam(client, pos6, mins, duration, laserIndex, color);
	TE_SendBeam(client, pos4, mins, duration, laserIndex, color);
	TE_SendBeam(client, pos5, mins, duration, laserIndex, color);
	TE_SendBeam(client, pos5, pos1, duration, laserIndex, color);
	TE_SendBeam(client, pos5, pos3, duration, laserIndex, color);
	TE_SendBeam(client, pos4, pos3, duration, laserIndex, color);
	TE_SendBeam(client, pos4, pos2, duration, laserIndex, color);
}

stock void TE_DrawBoxAll(const float origin[3], const float endOrigin[3], const float constMins[3], const float constMaxs[3], 
	float duration = 0.1, int laserIndex, const int color[4])
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			TE_DrawBox(i, origin, endOrigin, constMins, constMaxs, duration, laserIndex, color);
		}
	}
}

stock void TE_SendBeam(int client, const float mins[3], const float maxs[3], float duration = 0.1, int laserIndex, const int color[4])
{
	TE_SetupBeamPoints(mins, maxs, laserIndex, laserIndex, 0, 30, duration, 1.0, 1.0, 1, 0.0, color, 30);
	TE_SendToClient(client);
}

stock void DebugTinyBox(float pos[3], float duration=0.5)
{
	TE_DrawBoxAll(pos, pos, {8.0, 8.0, 0.0}, {8.0, 8.0, 8.0}, duration, g_iBeamModel, {0, 255, 255, 255});
}

void SetEntItemProc(int entity, int item)
{
	g_iItemDamageProc[entity] = item;
	if (item != Item_Null)
	{
		g_iLastItemDamageProc[entity] = item;
	}
}

int GetEntItemProc(int entity)
{
	return g_iItemDamageProc[entity];
}

// Returns the last item damage proc that was set on the entity, since GetEntItemProc() commonly gets reset
int GetLastEntItemProc(int entity)
{
	return g_iLastItemDamageProc[entity];
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

bool IsNPC(int entity)
{
	if (entity <= MaxClients) // we don't want player bots
		return false;
	
	return IsCombatChar(entity) && CBaseEntity(entity).MyNextBotPointer() != NULL_NEXT_BOT;
}

bool IsCombatChar(int entity)
{
	// Dispenser shields extend tf_taunt_prop, which extends CBaseCombatCharacter
	if (RF2_DispenserShield(entity).IsValid())
		return false;
	
	return entity > 0 && CBaseEntity(entity).IsCombatCharacter();
}

void GetEntPos(int entity, float buffer[3], bool center=false)
{
	if (center)
	{
		CBaseEntity(entity).WorldSpaceCenter(buffer);
	}
	else
	{
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", buffer);
	}
}

/*
void SetSequence(int entity, const char[] sequence, float playbackrate=1.0)
{
	int seq = CBaseAnimating(entity).LookupSequence(sequence);
	if (seq != -1)
	{
		SetEntProp(entity, Prop_Send, "m_nSequence", seq);
		SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", playbackrate);
	}
	else
	{
		LogError("[SetSequence] Couldn't find sequence \"%s\".", sequence);
	}
}
*/

float AddGesture(int entity, const char[] sequence, float duration=0.0, bool autokill=true, float playbackrate=1.0, int priority=1)
{
	int seq = CBaseAnimating(entity).LookupSequence(sequence);
	if (seq != -1)
	{
		if (duration <= 0.0)
		{
			duration = CBaseAnimating(entity).SequenceDuration(seq);
		}
		
		int layer = CBaseAnimatingOverlay(entity).AddGestureSequence(seq, duration, autokill);
		CBaseAnimatingOverlay(entity).SetLayerPlaybackRate(layer, playbackrate);
		CBaseAnimatingOverlay(entity).SetLayerPriority(layer, priority);
	}
	else
	{
		LogError("[AddGesture] Couldn't find sequence \"%s\".", sequence);
	}
	
	return duration;
}

float AddGestureByIndex(int entity, int seq, float duration=0.0, bool autokill=true, float playbackrate=1.0, int priority=1)
{
	if (duration <= 0.0)
	{
		duration = CBaseAnimating(entity).SequenceDuration(seq);
	}
	
	int layer = CBaseAnimatingOverlay(entity).AddGestureSequence(seq, duration, autokill);
	CBaseAnimatingOverlay(entity).SetLayerPlaybackRate(layer, playbackrate);
	CBaseAnimatingOverlay(entity).SetLayerPriority(layer, priority);
	return duration;
}

bool IsPlayingGesture(int entity, const char[] sequence)
{
	int seq = CBaseAnimating(entity).LookupSequence(sequence);
	if (seq == -1)
	{
		LogError("[IsPlayingGesture] Couldn't find sequence \"%s\".", sequence);
		return false;
	}
	
	return (CBaseAnimatingOverlay(entity).FindGestureLayerBySequence(seq) >= 0);
}

bool IsPlayingGestureByIndex(int entity, int seq)
{
	return (CBaseAnimatingOverlay(entity).FindGestureLayerBySequence(seq) >= 0);
}

void ParentEntity(int child, int parent, const char[] attachment="", bool maintainOffset=false)
{
	SetVariantString("!activator");
	AcceptEntityInput(child, "SetParent", parent, parent);
	if (attachment[0])
	{
		SetVariantString(attachment);
		maintainOffset ? AcceptEntityInput(child, "SetParentAttachmentMaintainOffset") : AcceptEntityInput(child, "SetParentAttachment");
	}
}

int ToggleGlow(int entity, bool state, int color[4]={255, 255, 255, 255})
{
	int glow = MaxClients+1;
	char name[32], name2[32];
	FormatEx(name2, sizeof(name2), "glowent%i", entity);
	bool found;
	while ((glow = FindEntityByClassname(glow, "tf_glow")) != -1)
	{
		GetEntPropString(glow, Prop_Data, "m_iName", name, sizeof(name));
		if (strcmp2(name, name2))
		{
			found = true;
			break;
		}
	}
	
	if (!found)
	{
		glow = CreateEntityByName("tf_glow");
		DispatchKeyValue(glow, "targetname", name2);
		char target[32];
		FormatEx(target, sizeof(target), "glowtarget%i", entity);
		DispatchKeyValue(entity, "targetname", target);
		DispatchKeyValue(glow, "target", target);
		SetVariantColor(color);
		AcceptEntityInput(glow, "SetGlowColor");
		float pos[3];
		GetEntPos(entity, pos);
		TeleportEntity(glow, pos);
		DispatchSpawn(glow);
		AcceptEntityInput(glow, "Enable");
		ParentEntity(glow, entity);
	}
	
	state ? AcceptEntityInput(glow, "Enable") : AcceptEntityInput(glow, "Disable");
	g_bEntityGlowing[entity] = state;
	return glow;
}

bool IsGlowing(int entity, bool pingGlow=false)
{
	if (pingGlow && !g_hEntityGlowResetTimer[entity])
		return false;
	
	return g_bEntityGlowing[entity] || IsValidClient(entity) && GetEntProp(entity, Prop_Send, "m_bGlowEnabled");
}

stock void PrintEntClassname(int entity)
{
	char classname[128];
	GetEntityClassname(entity, classname, sizeof(classname));
	PrintToChatAll(classname);
}

int GetEntTeam(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_iTeamNum");
}

void SetEntTeam(int entity, int team)
{
	SetEntProp(entity, Prop_Data, "m_iTeamNum", team);
	SetEntProp(entity, Prop_Send, "m_iTeamNum", team);
}

bool InSameTeam(int ent1, int ent2)
{
	return GetEntTeam(ent1) == GetEntTeam(ent2);
}

// Type of tf_zombie: 0 = normal, 1 = king, 2 = small
int SDK_SpawnSkeleton(const float pos[3], int type, int team=5, int owner=INVALID_ENT, float lifeTime=0.0)
{
	if (g_hSDKSpawnZombie)
	{
		return SDKCall(g_hSDKSpawnZombie, pos, lifeTime, team, owner, type);
	}
	
	return INVALID_ENT;
}

bool IsSkeleton(int entity)
{
	static char classname[16];
	GetEntityClassname(entity, classname, sizeof(classname));
	return strcmp2(classname, "tf_zombie");
}

int GetEntityDisplayName(int entity, char[] buffer, int size)
{
	static char classname[128];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (strcmp2(classname, "rf2_npc_sentry_buster"))
	{
		return strcopy(buffer, size, "Sentry Buster");
	}
	else if (strcmp2(classname, "rf2_npc_robot_butler"))
	{
		return strcopy(buffer, size, "Botler 2000");
	}
	else if (strcmp2(classname, "tank_boss"))
	{
		return strcopy(buffer, size, "Tank");
	}
	else if (strcmp2(classname, "rf2_tank_boss_badass"))
	{
		return strcopy(buffer, size, "Badass Tank");
	}
	else if (strcmp2(classname, "headless_hatman"))
	{
		return strcopy(buffer, size, "The Horseless Headless Horsemann");
	}
	else if (strcmp2(classname, "eyeball_boss"))
	{
		return strcopy(buffer, size, "MONOCULUS!");
	}
	else if (strcmp2(classname, "tf_zombie"))
	{
		if (GetEntPropFloat(entity, Prop_Send, "m_flModelScale") > 1.0)
		{
			return strcopy(buffer, size, "Skeleton King");
		}
		
		return strcopy(buffer, size, "Skeleton");
	}
	else if (IsBuilding(entity))
	{
		switch (TF2_GetObjectType2(entity))
		{
			case TFObject_Sentry: return strcopy(buffer, size, "Sentry Gun");
			case TFObject_Dispenser: return strcopy(buffer, size, "Dispenser");
			case TFObject_Teleporter: return strcopy(buffer, size, "Teleporter");
		}
	}
	
	return strcopy(buffer, size, "[unknown]");
}

void SDK_ApplyAbsVelocityImpulse(int entity, const float vel[3])
{
	if (g_hSDKAbsVelImpulse)
	{
		SDKCall(g_hSDKAbsVelImpulse, entity, vel);
	}
}

PathFollower GetEntPathFollower(int entity)
{
	if (g_iEntityPathFollowerIndex[entity] < 0)
		return view_as<PathFollower>(0);
	
	return g_PathFollowers[g_iEntityPathFollowerIndex[entity]];
}

int GetFreePathFollowerIndex(int target=INVALID_ENT)
{
	int entity = INVALID_ENT;
	ArrayList combatChars = new ArrayList();
	while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT)
	{
		if (CBaseEntity(entity).MyNextBotPointer() && entity != target)
		{
			combatChars.Push(entity);
		}
	}
	
	bool valid;
	for (int i = 0; i < MAX_PATH_FOLLOWERS; i++)
	{
		valid = true;
		for (int a = 0; a < combatChars.Length; a++)
		{
			entity = combatChars.Get(a);
			if (g_iEntityPathFollowerIndex[entity] == i)
			{
				valid = false;
				break;
			}
		}
		
		if (valid)
		{
			delete combatChars;
			return i;
		}
	}
	
	LogError("[GetFreePathFollowerIndex] No more path followers available. Consider raising MAX_PATH_FOLLOWERS.");
	delete combatChars;
	return -1;
}

public MRESReturn Detour_IsPotentiallyChaseablePost(Address addr, DHookReturn returnVal, DHookParam params)
{
	if (!RF2_IsEnabled() || params.IsNull(2))
		return MRES_Ignored;
	
	int hhh = params.Get(1);
	int victim = params.Get(2);
	bool result = returnVal.Value && IsValidHHHTarget(hhh, victim);
	returnVal.Value = result;
	return MRES_Supercede;
}

static bool g_bHidingFromMonoculus[MAXTF2PLAYERS];
static float g_flOldAbsOrigin[MAXTF2PLAYERS][3];
public MRESReturn Detour_EyeFindVictim(int monoculus, DHookReturn returnVal)
{
	if (!RF2_IsEnabled())
		return MRES_Ignored;
	
	float pos[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsValidMonoculusTarget(monoculus, i))
		{
			// set absorigin Z to a very low amount so Monoculus thinks we are in purgatory and will completely ignore us.
			GetEntPos(i, pos);
			CopyVectors(pos, g_flOldAbsOrigin[i]);
			pos[2] = -2000.0;
			SetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", pos);
			g_bHidingFromMonoculus[i] = true;
		}
	}
	
	return MRES_Ignored;
}

public MRESReturn Detour_EyeFindVictimPost(int monoculus, DHookReturn returnVal)
{
	if (!RF2_IsEnabled())
		return MRES_Ignored;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && g_bHidingFromMonoculus[i])
		{
			SetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", g_flOldAbsOrigin[i]);
		}
		
		g_bHidingFromMonoculus[i] = false;
	}
	
	return MRES_Ignored;
}

public MRESReturn Detour_EyePickSpot(int monoculus, DHookReturn returnVal)
{
	if (!RF2_IsEnabled())
		return MRES_Ignored;
	
	// When Monoculus picks a teleport spot, he will move up 75 units even if he doesn't find a spot, which gets him stuck in ceilings. 
	// Yes, this is dumb.
	float pos[3];
	GetEntPos(monoculus, pos);
	pos[2] -= 75.0;
	returnVal.SetVector(pos);
	return MRES_Supercede;
}

bool IsValidHHHTarget(int hhh, int client)
{
	// did this guy attack us recently?
	float lastAttackTime = g_flLastHalloweenBossAttackTime[hhh][client];
	if (lastAttackTime > 0.0 && GetGameTime() < lastAttackTime+12.0)
	{
		return true;
	}
	
	return PlayerHasItem(client, Item_HorsemannHead) || g_hHHHTargets.FindValue(GetClientUserId(client)) != -1 || GetClientTeam(client) == TEAM_ENEMY;
}

bool IsValidMonoculusTarget(int monoculus, int client)
{
	float lastAttackTime = g_flLastHalloweenBossAttackTime[monoculus][client];
	if (lastAttackTime > 0.0 && GetGameTime() < lastAttackTime+12.0)
	{
		return true;
	}
	
	return PlayerHasItem(client, Item_Monoculus) || g_hMonoculusTargets.FindValue(GetClientUserId(client)) != -1 || GetClientTeam(client) == TEAM_ENEMY;
}
