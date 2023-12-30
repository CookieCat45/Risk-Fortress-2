#if defined _RF2_buildings_included
 #endinput
#endif
#define _RF2_buildings_included

#pragma semicolon 1
#pragma newdecls required

enum
{
	CB_CAN_BUILD,			// Player is allowed to build this object
	CB_CANNOT_BUILD,		// Player is not allowed to build this object
	CB_LIMIT_REACHED,		// Player has reached the limit of the number of these objects allowed
	CB_NEED_RESOURCES,		// Player doesn't have enough resources to build this object
	CB_NEED_ADRENALIN,		// Commando doesn't have enough adrenalin to build a rally flag
	CB_UNKNOWN_OBJECT,		// Error message, tried to build unknown object
};

bool IsBuilding(int entity)
{
	static char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	return StrContains(classname, "obj_") == 0;
}

int GetBuiltObject(int client, TFObjectType type, TFObjectMode mode=TFObjectMode_Entrance)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "obj_*")) != -1)
	{
		if (GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client && TF2_GetObjectType(entity) == type)
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
	
	return -1;
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
		}
	}
	
	return MRES_Ignored;
}

public MRESReturn DHook_CanBuild(int client, DHookReturn returnVal, DHookParam params)
{
	if (RF2_IsEnabled())
	{
		TFObjectType type = view_as<TFObjectType>(DHookGetParam(params, 1));
		if (type == TFObject_Sentry && PlayerHasItem(client, ItemEngi_HeadOfDefense))
		{
			if (TF2_GetPlayerBuildingCount(client, TFObject_Sentry) <= RoundToFloor(CalcItemMod(client, ItemEngi_HeadOfDefense, 0))+1)
			{
				DHookSetReturn(returnVal, CB_CAN_BUILD);
				return MRES_Supercede;
			}
		}
	}
	
	return MRES_Ignored;
}
