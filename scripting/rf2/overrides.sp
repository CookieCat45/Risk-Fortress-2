#if defined _RF2_overrides_included
 #endinput
#endif
#define _RF2_overrides_included

#pragma semicolon 1
#pragma newdecls required

bool g_bPlayerInCondition[MAXTF2PLAYERS][MAX_TF_CONDITIONS];
bool TF2_IsPlayerInCondition2(int client, TFCond condition)
{
	return g_bPlayerInCondition[client][condition];
}

public void RemoveEntity2(int entity)
{
	if (entity == 0)
	{
		LogStackTrace("RemoveEntity2 with entity index 0, aborting to prevent server crash!");
		return;
	}
	
	RemoveEntity(entity);
}

void SDKHooks_TakeDamage2(int entity, int inflictor, int attacker, float damage, int damageType=DMG_GENERIC, int weapon=-1, const float damageForce[3]=NULL_VECTOR, const float damagePosition[3]=NULL_VECTOR)
{
	SDKHooks_TakeDamage(entity, inflictor, attacker, damage, damageType, weapon, damageForce, damagePosition, false);
}

bool PrecacheSound2(const char[] sound, bool preload=false)
{
	if (!sound[0])
	{
		LogStackTrace("Sound string is NULL");
		return false;
	}
	
	return PrecacheSound(sound, preload);
}

int PrecacheModel2(const char[] model, bool preload=false)
{
	if (!model[0])
	{
		LogStackTrace("Model string is NULL");
		return 0;
	}
	
	return PrecacheModel(model, preload);
}

void SetEntityModel2(int entity, const char[] model)
{
	if (!IsModelPrecached(model))
	{
		// just precache it, better than a server crash
		PrecacheModel2(model);
	}
	
	SetEntityModel(entity, model);
}

bool IsValidEntity2(int entity)
{
	if (entity == 0)
		return false;
	
	return IsValidEntity(entity);
}