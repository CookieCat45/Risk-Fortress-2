#if defined _RF2_overrides_included
 #endinput
#endif
#define _RF2_overrides_included

#pragma semicolon 1
#pragma newdecls required

public void RemoveEntity2(int entity)
{
	if (entity == 0)
	{
		LogStackTrace("RemoveEntity2 with entity index 0, aborting to prevent server crash!");
		return;
	}
	
	RemoveEntity(entity);
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
	
	// Fun Fact: IsValidEntity() returns true for unconnected clients...
	if (entity >= 1 && entity <= MaxClients && !IsClientInGame(entity))
	{
		return false;
	}

	return IsValidEntity(entity);
}
