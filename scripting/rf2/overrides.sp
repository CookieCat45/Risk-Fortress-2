#if defined _RF2_overrides_included
 #endinput
#endif
#define _RF2_overrides_included

#pragma semicolon 1
#pragma newdecls required

bool TF2_IsPlayerInCondition2(int client, TFCond condition)
{
	return g_bPlayerInCondition[client][condition];
}
#define TF2_IsPlayerInCondition TF2_IsPlayerInCondition2

void FixConditionFlag(int client, TFCond condition, bool state)
{
	g_bPlayerInCondition[client][condition] = state;
}

void TF2_AddCondition2(int client, TFCond condition, float duration=TFCondDuration_Infinite, int inflictor=0)
{
	TF2_AddCondition(client, condition, duration, inflictor);
	FixConditionFlag(client, condition, true);
}
#define TF2_AddCondition TF2_AddCondition2

void TF2_RemoveCondition2(int client, TFCond condition)
{
	TF2_RemoveCondition(client, condition);
	FixConditionFlag(client, condition, false);
}
#define TF2_RemoveCondition TF2_RemoveCondition2

public void RemoveEntity2(int entity)
{
	if (entity == 0)
		return;
	
	RemoveEntity(entity);
}
#define RemoveEntity RemoveEntity2

void SDKHooks_TakeDamage2(int entity, int inflictor, int attacker, float damage, int damageType=DMG_GENERIC, int weapon=-1, const float damageForce[3]=NULL_VECTOR, const float damagePosition[3]=NULL_VECTOR)
{
	SDKHooks_TakeDamage(entity, inflictor, attacker, damage, damageType, weapon, damageForce, damagePosition, false);
}
#define SDKHooks_TakeDamage SDKHooks_TakeDamage2

bool PrecacheSound2(const char[] sound, bool preload=false)
{
	if (!sound[0])
	{
		LogStackTrace("Sound string is NULL");
		return false;
	}
	
	return PrecacheSound(sound, preload);
}
#define PrecacheSound PrecacheSound2

int PrecacheModel2(const char[] model, bool preload=false)
{
	if (!model[0])
	{
		LogStackTrace("Model string is NULL");
		return 0;
	}
	
	return PrecacheModel(model, preload);
}
#define PrecacheModel PrecacheModel2

void SetEntityModel2(int entity, const char[] model)
{
	if (!IsModelPrecached(model))
	{
		LogStackTrace("Model \"%s\" is not precached", model);
		return;
	}
	
	SetEntityModel(entity, model);
}
#define SetEntityModel SetEntityModel2