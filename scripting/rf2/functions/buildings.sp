#if defined _RF2_buildings_included
 #endinput
#endif
#define _RF2_buildings_included

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
	// let's not count sappers
	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	return (classname[0] == 'o' && StrContains(classname, "obj_") == 0 && !strcmp2(classname, "obj_attachment_sapper"));
}

bool CanTeamQuickBuild(int team)
{
	return team == TEAM_SURVIVOR && g_cvSurvivorQuickBuild.BoolValue || team == TEAM_ENEMY && g_cvEnemyQuickBuild.BoolValue;
}

void SDK_DoQuickBuild(int building, bool forceMaxLevel=false)
{
	if (g_hSDKDoQuickBuild)
		SDKCall(g_hSDKDoQuickBuild, building, forceMaxLevel);
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
		GameRules_SetProp("m_bPlayingMannVsMachine", false);
		
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
