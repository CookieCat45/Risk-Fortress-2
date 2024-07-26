#pragma newdecls required
#pragma semicolon 1

static NextBotActionFactory g_Factory;

methodmap RF2_RobotButlerMainAction < NextBotAction
{
	public RF2_RobotButlerMainAction()
	{
		return view_as<RF2_RobotButlerMainAction>(g_Factory.Create());
	}
	
	public static NextBotActionFactory GetFactory()
	{
		if (!g_Factory)
		{
			g_Factory = new NextBotActionFactory("RF2_RobotButlerMainAction");
			g_Factory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_Factory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_Factory.SetEventCallback(EventResponderType_OnKilled, OnKilled);
		}
		
		return g_Factory;
	}
}

static int OnStart(RF2_RobotButlerMainAction action, RF2_RobotButler bot, NextBotAction prevAction)
{
	bot.SetSequence("idle");
	return action.Continue();
}

static int Update(RF2_RobotButlerMainAction action, RF2_RobotButler bot, float interval)
{
	if (GetGameTime() >= bot.NextIdleVoiceAt)
	{
		bot.PlayIdleVoice();
		bot.NextIdleVoiceAt = GetGameTime()+8.0;
	}
	
	const float range = 2000.0;
	int target = INVALID_ENT;
	bool suicideBombing;
	if (bot.ShouldSuicideBomb())
	{
		// Suicide bomb mode, find closest enemy
		float closestDist = -1.0;
		float dist;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) == bot.Team || IsInvuln(i))
				continue;
			
			dist = DistBetween(i, bot.index);
			if (dist <= range && (closestDist == -1.0 || dist < closestDist))
			{
				closestDist = dist;
				target = i;
				suicideBombing = true;
			}
		}
	}
	
	if (!suicideBombing)
	{
		// we aren't trying to blow someone up, so look for allies who need healing
		int lowestHealth;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != bot.Team)
				continue;
			
			if (IsPlayerMinion(i)) // minions are less important
				continue;
			
			if (DistBetween(i, bot.index) > range) // too far away
				continue;
			
			if (GetGameTime() < bot.GetPlayerNextHeal(i)) // player is on cooldown
				continue;
			
			int health = GetClientHealth(i);
			if ((lowestHealth <= 0 || health < lowestHealth) && health <= RF2_GetCalculatedMaxHealth(i)/2)
			{
				// heal players at or below half hp, with the most injured taking priority
				lowestHealth = health;
				target = i;
			}
		}
		
		float pos[3];
		bot.WorldSpaceCenter(pos);
		int nearestPlayer = GetNearestPlayer(pos, 0.0, 5000.0, bot.Team);
		if (IsValidClient(nearestPlayer))
		{
			if (DistBetween(bot.index, nearestPlayer) > 125.0)
			{
				bot.ApproachEntity(nearestPlayer, _, true); // stick close to allies
			}
		}
	}
	
	if (IsValidClient(target))
	{
		bot.Target = target;
		if (!suicideBombing)
		{
			return action.SuspendFor(RF2_RobotButlerHealAction(), "I've found someone who needs healing");
		}
		else
		{
			return action.SuspendFor(RF2_RobotButlerSuicideBombAction(), "I've found someone to blow up");
		}
	}
	
	return action.Continue();
}

static int OnKilled(RF2_RobotButlerMainAction action, RF2_RobotButler bot, CBaseEntity attacker, CBaseEntity inflictor,
	float damage, int damageType, CBaseEntity weapon, const float damageForce[3], const float damagePosition[3], int damageCustom)
{
	bot.SelfDestruct();
	return action.TryDone(RESULT_CRITICAL, "I'm dead!");
}
