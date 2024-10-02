#include <sourcemod>
#include <sdkhooks>

public void OnEntityCreated(int entity, const char[] classname)
{
    if (strcmp(classname, "obj_dispenser") == 0)
    {
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
    }
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon,
		float damageForce[3], float damagePosition[3], int damageCustom)
{
    const float newDamage = 40000.0;
    damage = newDamage;
    return Plugin_Changed;
}

public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damageType, int weapon,
		float damageForce[3], float damagePosition[3], int damageCustom)
{
    PrintToChatAll("Damage Dealt = %.0f", damage);
}