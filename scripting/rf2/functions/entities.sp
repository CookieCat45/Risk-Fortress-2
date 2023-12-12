#if defined _RF2_functions_entities_included
 #endinput
#endif
#define _RF2_functions_entities_included

#pragma semicolon 1
#pragma newdecls required

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
		if (team > -1 && GetEntProp(entity, Prop_Data, "m_iTeamNum") != team)
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

// SPELL PROJECTILES WILL ONLY WORK IF THE OWNER ENTITY IS A PLAYER! DO NOT TRY THEM WITH ANYTHING ELSE!
int ShootProjectile(int owner=-1, const char[] classname, const float pos[3], const float angles[3], 
	float speed, float damage=-1.0, float arc=0.0, bool allowCrit=true, float critProc=1.0)
{
	int entity = CreateEntityByName(classname);
	if (entity == -1)
	{
		return -1;
	}
	
	SetEntityOwner(entity, owner);
	if (owner > 0)
	{
		int team = GetEntProp(owner, Prop_Data, "m_iTeamNum");
		SetEntProp(entity, Prop_Data, "m_iTeamNum", team);
	}
	
	float projectileAngles[3], velocity[3];
	CopyVectors(angles, projectileAngles);
	projectileAngles[0] += arc;
	
	if (damage >= 0.0)
	{
		if (strcmp2(classname, "tf_projectile_pipebomb") || 
		strcmp2(classname, "tf_projectile_spellbats") ||
		strcmp2(classname, "tf_projectile_spelltransposeteleport"))
		{
			SetEntPropFloat(entity, Prop_Send, "m_flDamage", damage);
		}
		else if (strcmp2(classname, "tf_projectile_rocket") || strcmp2(classname, "tf_projectile_sentryrocket"))
		{
			int offset = FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4;
			SetEntDataFloat(entity, offset, damage, true);
		}
		else if (IsEntityFromFactory(entity))
		{
			SetEntPropFloat(entity, Prop_Data, "m_flBaseDamage", damage);
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
		if (RollAttackCrit(owner, critProc) || PlayerHasItem(owner, Item_Executioner) && IsPlayerMiniCritBuffed(owner))
		{
			SetEntProp(entity, Prop_Send, "m_bCritical", true);
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

// Shoots a fake fireball (tf_projectile_rocket)
int ShootProjectile_Fireball(int owner=-1, const float pos[3], const float angles[3], 
	float speed, float damage=-1.0, float arc=0.0, bool allowCrit=true, float critProc=1.0)
{
	int entity = ShootProjectile(owner, "tf_projectile_rocket", pos, angles, speed, damage, arc, allowCrit, critProc);
	SetEntityModel(entity, MODEL_INVISIBLE);
	
	switch (view_as<TFTeam>(GetEntProp(entity, Prop_Data, "m_iTeamNum")))
	{
		case TFTeam_Red:	SpawnInfoParticle("spell_fireball_small_red", pos, _, entity);
		case TFTeam_Blue:	SpawnInfoParticle("spell_fireball_small_blue", pos, _, entity);
		default:			SpawnInfoParticle("spellbook_major_fire", pos, _, entity);
	}
	
	EmitSoundToAll(SND_SPELL_FIREBALL, entity);
	g_bFakeFireball[entity] = true;
	return entity;
}

void DoRadiusDamage(int attacker, int inflictor, int item=Item_Null, const float pos[3], 
	float baseDamage, int damageFlags, float radius, int weapon=-1, 
	float minimumFalloffMultiplier=0.3, bool explosionEffect=false, bool sound=true, bool allowSelfDamage=false)
{
	float enemyPos[3];
	float distance, falloffMultiplier, calculatedDamage;
	int attackerTeam = GetEntProp(attacker, Prop_Data, "m_iTeamNum");
	int entity = -1;
	int directTarget = -1;
	if (inflictor > MaxClients && HasEntProp(inflictor, Prop_Data, "m_flExplodeRadius"))
	{
		directTarget = GetEntPropEnt(inflictor, Prop_Data, "m_hDirectTarget");
	}
	
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		if (entity < 1)
			continue;
		
		// this is a bomb direct hit, don't deal damage to our direct target
		if (directTarget > 0 && entity == directTarget)
			continue;
		
		if ((!IsValidClient(entity) || !IsPlayerAlive(entity)) && !IsNPC(entity) && !IsBuilding(entity) || entity == attacker && !allowSelfDamage)
			continue;
		
		if (attackerTeam == GetEntProp(entity, Prop_Data, "m_iTeamNum") && (entity != attacker || entity == attacker && !allowSelfDamage))
			continue;
		
		GetEntPos(entity, enemyPos);
		enemyPos[2] += 30.0;
		
		if ((distance = GetVectorDistance(pos, enemyPos)) <= radius)
		{
			TR_TraceRayFilter(pos, enemyPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceFilter_WallsOnly);
			
			if (!TR_DidHit())
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
				
				SDKHooks_TakeDamage(entity, inflictor, attacker, calculatedDamage, damageFlags, weapon);
			}
		}
	}
	
	if (explosionEffect)
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
}

int SpawnCashDrop(float cashValue, float pos[3], int size=1, float vel[3]=NULL_VECTOR)
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
	
	SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
	SetEntityGravity(entity, 1.0);
	TeleportEntity(entity, pos, _, vel);
	DispatchSpawn(entity);
	
	CreateTimer(0.25, Timer_CashMagnet, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(g_cvCashBurnTime.FloatValue, Timer_DeleteCash, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	return entity;
}

public Action Timer_DeleteCash(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE)
		return Plugin_Continue;
		
	float pos[3];
	GetEntPos(entity, pos);
	TE_TFParticle("mvm_cash_explosion", pos);
	RemoveEntity(entity);
	
	return Plugin_Continue;
}

public Action Timer_CashMagnet(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE)
		return Plugin_Stop;
	
	float pos[3], scoutPos[3];
	GetEntPos(entity, pos);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || !IsPlayerSurvivor(i))
			continue;
		
		// Scouts pick up cash in a radius automatically, like in MvM. Though the healing is on an item: the Heart Of Gold.
		if (TF2_GetPlayerClass(i) == TFClass_Scout)
		{
			GetEntPos(i, scoutPos);
			
			if (GetVectorDistance(pos, scoutPos, true) <= sq(450.0))
			{
				EmitSoundToAll(SND_MONEY_PICKUP, entity);
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
			if (!IsClientInGame(i) || !IsPlayerSurvivor(i))
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

int SpawnInfoParticle(const char[] effectName, const float pos[3], float duration=0.0, int parent=-1, const char[] attachment="")
{
	int particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", effectName);
	TeleportEntity(particle, pos);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");

	if (parent != -1)
	{
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", parent);
		
		if (attachment[0])
		{
			SetVariantString(attachment);
			AcceptEntityInput(particle, "SetParentAttachment");
		}
	}
	
	if (duration > 0.0)
	{
		CreateTimer(duration, Timer_DeleteEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return particle;
}

void TE_TFParticle(const char[] effectName, const float pos[3], int entity=-1, int attachType=PATTACH_ABSORIGIN, const char[] attachmentName="",
bool reset=false, int clientArray[MAXTF2PLAYERS] = {-1, ...}, int clientAmount=0)
{
	TE_Start("TFParticleEffect");
	
	int index = GetParticleEffectIndex(effectName);
	if (index == -1)
	{
		// try to cache it
		index = PrecacheParticleEffect(effectName);
	}
	
	if (index > -1)
	{
		TE_WriteNum("m_iParticleSystemIndex", index);
		
		if (attachmentName[0])
		{
			int attachPoint = LookupEntityAttachment(entity, attachmentName);
			if (attachPoint != 0)
			{
				TE_WriteNum("m_iAttachmentPointIndex", attachPoint);
			}
		}
		
		if (entity > -1)
		{
			TE_WriteNum("entindex", entity);
		}

		TE_WriteFloat("m_vecOrigin[0]", pos[0]);
		TE_WriteFloat("m_vecOrigin[1]", pos[1]);
		TE_WriteFloat("m_vecOrigin[2]", pos[2]);
		TE_WriteFloat("m_vecStart[0]", pos[0]);
		TE_WriteFloat("m_vecStart[1]", pos[1]);
		TE_WriteFloat("m_vecStart[2]", pos[2]);
		
		TE_WriteNum("m_iAttachType", attachType);
		TE_WriteNum("m_bResetParticles", asBool(reset));
		
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
}

int PrecacheParticleEffect(const char[] name)
{
	int index;
	int table = FindStringTable("ParticleEffectNames");
	int count = GetStringTableNumStrings(table);
	char buffer[128];
	
	for (int i = 0; i < count; i++)
	{
		ReadStringTable(table, i, buffer, sizeof(buffer));
		if (strcmp2(buffer, name))
		{
			index = i;
			g_hParticleEffectTable.Resize(i+1);
			g_hParticleEffectTable.SetString(i, name);
			break;
		}
	}
	
	if (index < 0)
	{
		LogError("[PrecacheParticleEffect] Couldn't find particle effect \"%s\".", name);
	}
	
	return index;
}

int GetParticleEffectIndex(const char[] name)
{
	return g_hParticleEffectTable.FindString(name);
}

void SetEntItemDamageProc(int entity, int item)
{
	g_iItemDamageProc[entity] = item;
	if (IsValidClient(entity) && item != Item_Null)
	{
		g_iPlayerKillfeedItem[entity] = item; // We have to reset our damage proc item, this is for killfeed icons
	}
}

int GetEntItemDamageProc(int entity)
{
	return g_iItemDamageProc[entity];
}

bool IsNPC(int entity)
{
	if (entity <= MaxClients) // we don't want player bots
		return false;
	
	return (CBaseEntity(entity).MyNextBotPointer() && CBaseEntity(entity).IsCombatCharacter());
}

void GetEntPos(int entity, float buffer[3])
{
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", buffer);
}

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

public MRESReturn DHook_TakeHealth(int entity, Handle returnVal, Handle params)
{
	if (IsValidClient(entity))
	{
		float health = DHookGetParam(params, 1); 
		health *= GetPlayerHealthMult(entity);
		DHookSetParam(params, 1, health); 
		return MRES_ChangedHandled;
	}
	
	return MRES_Ignored;
}