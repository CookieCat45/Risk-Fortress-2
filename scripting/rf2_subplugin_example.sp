#include <sourcemod>
#include <sdktools>
#include <rf2>

#pragma semicolon 1
#pragma newdecls required

int g_iCustomItemIndex;

public void OnPluginStart()
{
	// In case this plugin reloaded and item data is already loaded
	g_iCustomItemIndex = RF2_FindItemBySectionName("test_item");
}

public void RF2_OnCustomItemLoaded(const char[] fileName, const char[] sectionName, int index)
{
	if (!strcmp(fileName, "custom_items_example.cfg") && !strcmp(sectionName, "test_item"))
	{
		g_iCustomItemIndex = index;
	}
}

public void RF2_OnPlayerItemUpdate(int client, int item)
{
	if (item == g_iCustomItemIndex)
	{
		SetEntPropFloat(client, Prop_Send, "m_flHeadScale", 1.0+RF2_CalcItemMod(client, item, 0));
	}
}

public Action RF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, 
	float damageForce[3], float damagePosition[3], int damageCustom, int &critType, int attackerItem, int inflictorItem, float procCoeff)
{
	if (IsValidClient(attacker) && RF2_GetPlayerItemAmount(attacker, g_iCustomItemIndex) > 0)
	{
		PrintToChat(attacker, "Ouch! You hit %i", victim);
		SlapPlayer(attacker, RoundToFloor(RF2_CalcItemMod(attacker, g_iCustomItemIndex, 1)));
		damage *= 1.0+RF2_CalcItemMod(attacker, g_iCustomItemIndex, 2);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}