#pragma newdecls required
#pragma semicolon 1

static NextBotActionFactory g_Factory;

methodmap RF2_RobotButlerSuicideBombAction < RF2_BaseNPCAttackAction
{
	public RF2_RobotButlerSuicideBombAction()
	{
		if (!g_Factory)
		{
			g_Factory = new NextBotActionFactory("RF2_RobotButlerSuicideBombAction");
			g_Factory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_Factory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
			g_Factory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_Factory.BeginDataMapDesc()
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
				.DefineIntField("m_nHitCounter")
			.EndDataMapDesc();
		}
		
		return view_as<RF2_RobotButlerSuicideBombAction>(g_Factory.Create());
	}
}

static int OnStart(RF2_RobotButlerSuicideBombAction action, RF2_RobotButler bot, NextBotAction prevAction)
{
	action.StartTime = GetGameTime();
	if (IsValidEntity2(bot.HeldItem))
	{
		RemoveEntity(bot.HeldItem);
	}
	else
	{
		// if we weren't already holding the bomb, play the sound
		EmitSoundToAll(SND_BOMB_FUSE, bot.index);
	}
	
	bot.HeldItem = CreateEntityByName("prop_dynamic_override");
	SetEntityModel2(bot.HeldItem, MODEL_BOMB);
	DispatchSpawn(bot.HeldItem);
	AcceptEntityInput(bot.HeldItem, "DisableCollision");
	ParentEntity(bot.HeldItem, bot.index, "bomb");
	bot.SetSequence("panic");
	return action.Continue();
}

static void OnEnd(NextBotAction action, RF2_RobotButler bot, NextBotAction nextAction)
{
	/*
	if (IsValidEntity2(bot.HeldItem))
	{
		RemoveEntity(bot.HeldItem);
	}
	*/
	
	bot.Target = INVALID_ENT;
}

static int Update(RF2_RobotButlerSuicideBombAction action, RF2_RobotButler bot, float interval)
{
	if (!IsValidClient(bot.Target) || !IsPlayerAlive(bot.Target))
	{
		return action.Done("My target is gone");
	}
	
	if (GetGameTime() >= action.StartTime+8.0)
	{
		return action.Done("I took too long to reach my target");
	}
	
	if (IsInvuln(bot.Target))
	{
		return action.Done("My target is invulnerable");
	}
	
	if (DistBetween(bot.index, bot.Target, true) <= 15000.0)
	{
		// we're close enough, blow ourselves up
		bot.SelfDestruct();
		return action.Done("I've successfully exploded near my target");
	}
	
	bot.ApproachEntity(bot.Target);
	return action.Continue();
}
