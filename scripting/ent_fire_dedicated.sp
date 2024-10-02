#include <sourcemod>
#include <sdktools>

public void OnPluginStart()
{
    RegAdminCmd("sm_ent_fire", Command_EntFire, ADMFLAG_RCON, "Fires an input on named entities. Usage: sm_ent_fire <target> [action] [value]");
}

public Action Command_EntFire(int client, int args)
{
    char target[128], action[64], value[64];
    GetCmdArg(1, target, sizeof(target));
    GetCmdArg(2, action, sizeof(action));
    GetCmdArg(3, value, sizeof(value));
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, target)) != -1)
    {
        if (!IsValidEntity2(entity))
            continue;

        SetVariantString(value);
        if (!AcceptEntityInput(entity, action))
        {
            ReplyToCommand(client, "Unknown input: %s on entity: %s", action, target);
            return Plugin_Handled;
        }
    }

    entity = -1;
    while ((entity = FindEntityByName(entity, target)) != -1)
    {
        // don't stop execution for targetnames on invalid inputs as we don't want to assume things
        SetVariantString(value);
        AcceptEntityInput(entity, action);
    }
    
    return Plugin_Handled;
}

int FindEntityByName(int startEnt, const char[] name)
{
    int entity = startEnt;
    char entName[128];
    while ((entity = FindEntityByClassname(entity, "*")) != -1)
    {
        if (!IsValidEntity2(entity))
            continue;

        GetEntPropString(entity, Prop_Data, "m_iName", entName, sizeof(entName));
        if (StrEqual(name, entName))
        {
            return entity;
        }
    }

    return -1;
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