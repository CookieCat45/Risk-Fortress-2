#if defined _RF2_buildings_included
 #endinput
#endif
#define _RF2_buildings_included

#pragma semicolon 1
#pragma newdecls required

bool IsBuilding(int entity)
{
	static char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	return StrContains(classname, "obj_") == 0;
}

int GetBuiltObject(int client, TFObjectType type, TFObjectMode mode=TFObjectMode_Entrance)
{
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "obj_*")) != INVALID_ENT)
	{
		if (GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client && TF2_GetObjectType2(entity) == type)
		{
			if (type == TFObject_Teleporter)
			{
				if (TF2_GetObjectMode(entity) == mode)
					return entity;
			}
			else
			{
				return entity;
			}
		}
	}
	
	return INVALID_ENT;
}

public Action Timer_BuildingHealthRegen(Handle timer, int building)
{
	if ((building = EntRefToEntIndex(building)) == INVALID_ENT)
		return Plugin_Stop;
	
	int builder = GetEntPropEnt(building, Prop_Send, "m_hBuilder");
	if (IsValidClient(builder) && IsPlayerAlive(builder) 
		&& PlayerHasItem(builder, ItemEngi_Toadstool) && CanUseCollectorItem(builder, ItemEngi_Toadstool)
		&& !GetEntProp(building, Prop_Send, "m_bBuilding") && !GetEntProp(building, Prop_Send, "m_bHasSapper") 
		&& !GetEntProp(building, Prop_Send, "m_bCarried") && !GetEntProp(building, Prop_Send, "m_bPlacing"))
	{
		int health = GetEntProp(building, Prop_Send, "m_iHealth");
		int maxHealth = GetEntProp(building, Prop_Send, "m_iMaxHealth");
		if (maxHealth-health > 0)
		{
			int heal = CalcItemModInt(builder, ItemEngi_Toadstool, 0);
			SetVariantInt(heal);
			AcceptEntityInput(building, "AddHealth");
			Event event = CreateEvent("building_healed", true);
			event.SetInt("priority", 1);
			event.SetInt("building", building);
			event.SetInt("healer", builder);
			event.SetInt("amount", heal);
			event.Fire();
		}
	}
	
	return Plugin_Continue;
}

bool CanTeamQuickBuild(int team)
{
	return team == TEAM_SURVIVOR && g_cvSurvivorQuickBuild.BoolValue || team == TEAM_ENEMY && g_cvEnemyQuickBuild.BoolValue;
}

void SDK_DoQuickBuild(int building, bool forceMaxLevel=false)
{
	if (g_hSDKDoQuickBuild)
	{
		SDKCall(g_hSDKDoQuickBuild, building, forceMaxLevel);
	}
}

TFObjectType TF2_GetObjectType2(int entity)
{
	static char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (strcmp2(classname, "obj_sentrygun"))
	{
		// Sometimes sentries are set to TFObject_Sapper to allow building multiple at once
		return TFObject_Sentry;
	}
	
	return TF2_GetObjectType(entity);
}

// True = Allow building (PDA out)
// False = Allow destroying
void SetSentryBuildState(int client, bool state)
{
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "obj_sentrygun")) != INVALID_ENT)
	{
		if (GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client)
		{
			// Sapper object type makes game think that sentry is not built, but we need to set it back to allow destruction and show sentries in the HUD
			SetEntProp(entity, Prop_Send, "m_iObjectType", state ? TFObject_Sapper : TFObject_Sentry);
		}
	}
}

bool IsSentryDisposable(int sentry)
{
	return TF2_GetObjectMode(sentry) == TFObjectMode_Disposable;
}

public MRESReturn DHook_StartUpgrading(int entity, DHookReturn returnVal, DHookParam params)
{
	if (RF2_IsEnabled())
	{
		// skip upgrade anim
		if (GetEntProp(entity, Prop_Send, "m_bCarryDeploy") || g_bGracePeriod)
		{
			GameRules_SetProp("m_bPlayingMannVsMachine", true);
		}
	}
	
	return MRES_Ignored;
}

public MRESReturn DHook_StartUpgradingPost(int entity, DHookReturn returnVal, DHookParam params)
{
	if (RF2_IsEnabled())
	{
		GameRules_SetProp("m_bPlayingMannVsMachine", false);
	}
	
	return MRES_Ignored;
}

public MRESReturn DHook_SentryGunAttack(int entity)
{
	if (RF2_IsEnabled())
	{
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
		if (IsValidClient(owner) && IsPlayerAlive(owner))
		{
			if (GetEntProp(entity, Prop_Send, "m_bPlayerControlled") || GetEntPropEnt(entity, Prop_Send, "m_hEnemy") > 0)
			{
				float gameTime = GetGameTime();
				int offset = FindSendPropInfo("CObjectSentrygun", "m_iState") + 4; // m_flNextAttack
				float time = GetEntDataFloat(entity, offset);
				time -= gameTime;
				time *= GetPlayerFireRateMod(owner);
				SetEntDataFloat(entity, offset, gameTime+time, true);
			}
			
			if (IsSentryDisposable(entity) && GetEntProp(entity, Prop_Send, "m_iAmmoShells") <= 0)
			{
				SetEntityHealth(entity, 1);
				RF_TakeDamage(entity, 0, 0, MAX_DAMAGE, DMG_PREVENT_PHYSICS_FORCE);
			}
		}
	}
	
	return MRES_Ignored;
}
