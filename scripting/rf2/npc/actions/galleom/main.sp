#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_ActionFactory;

methodmap RF2_GalleomMainAction < NextBotAction
{
	public RF2_GalleomMainAction()
	{
		return view_as<RF2_GalleomMainAction>(g_ActionFactory.Create());
	}

	public static NextBotActionFactory GetFactory()
	{
		if (!g_ActionFactory)
		{
			g_ActionFactory = new NextBotActionFactory("RF2_GalleomMainAction");
			g_ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_ActionFactory.SetEventCallback(EventResponderType_OnKilled, OnKilled);
		}
		
		return g_ActionFactory;
	}
}

static int OnStart(RF2_GalleomMainAction action, RF2_RaidBoss_Galleom boss, NextBotAction prevAction)
{
	boss.SetSequence("EnmGalleomWait");
	return action.Continue();
}

static int Update(RF2_GalleomMainAction action, RF2_RaidBoss_Galleom boss, float interval)
{
	if (!IsValidEntity2(boss.Target))
	{
		boss.GetNewTarget();
	}
	
	if (IsValidEntity2(boss.Target))
	{
		float dist = DistBetween(boss.index, boss.Target);
		float targetPos[3], ang[3], pos[3];
		boss.GetAbsOrigin(pos);
		GetEntPos(boss.Target, targetPos);
		GetVectorAnglesTwoPoints(pos, targetPos, ang);
		ang[2] = 0.0;
		boss.SetAbsAngles(ang);
		
		if (dist > 700.0)
		{
			return action.SuspendFor(RF2_GalleomTankRamAttack(), "Run people over in tank form.");
		}
		else
		{
			switch (GetRandomInt(1, 4))
			{
				case 1:	return action.SuspendFor(RF2_GalleomHammerKnuckleAttack(), "Slam my fists on this guy.");
				case 2: return action.SuspendFor(RF2_GalleomBodySlamAttack(), "Fall on top of this guy.");
				case 3: return action.SuspendFor(RF2_GalleomDoubleSlamAttack(), "Slam in front of and behind me with my fists.");
				case 4: return action.SuspendFor(RF2_GalleomHopAttack(), "Stomp the ground four times.");
			}
		}
	}
	
	return action.Continue();
}

static int OnKilled(RF2_GalleomMainAction action, RF2_RaidBoss_Galleom boss, CBaseEntity attacker, CBaseEntity inflictor,
	float damage, int damageType, CBaseEntity weapon, const float damageForce[3], const float damagePosition[3], int damageCustom)
{
	return action.TryChangeTo(RF2_GalleomDeathState(), RESULT_CRITICAL,  "I'm dead!");
}
