#pragma newdecls required
#pragma semicolon 1

static NextBotActionFactory g_Factory;

methodmap RF2_RobotButlerHealAction < RF2_BaseNPCAttackAction
{
	public RF2_RobotButlerHealAction()
	{
		if (!g_Factory)
		{
			g_Factory = new NextBotActionFactory("RF2_RobotButlerHealAction");
			g_Factory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_Factory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
			g_Factory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_Factory.BeginDataMapDesc()
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
				.DefineIntField("m_nHitCounter")
			.EndDataMapDesc();
			//g_Factory.SetEventCallback(EventResponderType_OnKilled, OnKilled);
		}

		return view_as<RF2_RobotButlerHealAction>(g_Factory.Create());
	}
}

static int OnStart(RF2_RobotButlerHealAction action, RF2_RobotButler bot, NextBotAction prevAction)
{
	action.StartTime = GetGameTime();
	if (IsValidEntity2(bot.HeldItem))
	{
		RemoveEntity(bot.HeldItem);
	}
	
	bot.HeldItem = CreateEntityByName("prop_dynamic_override");
	SetEntityModel2(bot.HeldItem, bot.Team == TEAM_SURVIVOR ? MODEL_MEDKIT : MODEL_MEDKIT_BLUE);
	if (bot.Team == TEAM_ENEMY)
	{
		SetEntityRenderMode(bot.HeldItem, RENDER_TRANSCOLOR);
		SetEntityRenderColor(bot.HeldItem, 0, 255, 255);
	}
	
	DispatchKeyValue(bot.HeldItem, "sequence", "idle");
	DispatchSpawn(bot.HeldItem);
	AcceptEntityInput(bot.HeldItem, "DisableCollision");
	ParentEntity(bot.HeldItem, bot.index, "healthkit");
	bot.SetSequence("idle");
	bot.PlayHealVoice();
	StopSound(bot.index, SNDCHAN_AUTO, SND_BOMB_FUSE);
	return action.Continue();
}

static void OnEnd(NextBotAction action, RF2_RobotButler bot, NextBotAction nextAction)
{
	if (IsValidEntity2(bot.HeldItem))
	{
		RemoveEntity(bot.HeldItem);
	}
	
	bot.Target = INVALID_ENT;
}

static int Update(RF2_RobotButlerHealAction action, RF2_RobotButler bot, float interval)
{
	if (!IsValidClient(bot.Target) || !IsPlayerAlive(bot.Target))
	{
		return action.Done("My target is gone");
	}
	
	if (GetGameTime() >= action.StartTime+15.0)
	{
		return action.Done("I took too long to reach my target");
	}
	
	if (GetClientHealth(bot.Target) >= RoundToFloor(float(RF2_GetCalculatedMaxHealth(bot.Target))*0.7))
	{
		return action.Done("My target already has enough health");
	}
	
	if (DistBetween(bot.index, bot.Target, true) <= 22500.0)
	{
		// we're close enough, heal our target to full health and go on cooldown for them
		// remove debuffs as well
		HealPlayer(bot.Target, RF2_GetCalculatedMaxHealth(bot.Target)*2);
		TF2_RemoveCondition(bot.Target, TFCond_OnFire);
		TF2_RemoveCondition(bot.Target, TFCond_BurningPyro);
		TF2_RemoveCondition(bot.Target, TFCond_Gas);
		TF2_RemoveCondition(bot.Target, TFCond_Bleeding);
		TF2_RemoveCondition(bot.Target, TFCond_Jarated);
		TF2_RemoveCondition(bot.Target, TFCond_Milked);
		TF2_RemoveCondition(bot.Target, TFCond_MarkedForDeath);
		TF2_RemoveCondition(bot.Target, TFCond_MarkedForDeathSilent);
		bot.SetPlayerNextHeal(bot.Target, GetGameTime()+bot.HealCooldown);
		EmitGameSoundToClient(bot.Target, "HealthKit.Touch");
		return action.Done("I've successfully healed my target");
	}
	
	bot.ApproachEntity(bot.Target);
	return action.Continue();
}
