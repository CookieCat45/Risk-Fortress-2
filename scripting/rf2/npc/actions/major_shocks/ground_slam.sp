#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_Factory;

methodmap RF2_MajorShocksGroundSlamAction < RF2_BaseNPCAttackAction
{
	public RF2_MajorShocksGroundSlamAction()
	{
		if (g_Factory == null)
		{
			g_Factory = new NextBotActionFactory("RF2_MajorShocksGroundSlam");
			g_Factory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_Factory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_Factory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
			g_Factory.BeginDataMapDesc()
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
				.DefineIntField("m_nHitCounter")
			.EndDataMapDesc();
		}
		return view_as<RF2_MajorShocksGroundSlamAction>(g_Factory.Create());
	}
}

static int OnStart(RF2_MajorShocksGroundSlamAction action, RF2_MajorShocks actor)
{
	float gameTime = GetGameTime();
	actor.LockAnimations = true;
	action.StartTime = 5.25 + gameTime;
	action.AttackTime = 7.5 + gameTime;
	actor.EmitSpecialAttackQuote();
	actor.Path.Invalidate();
	actor.ResetSequence(actor.LookupSequence("taunt_yeti_layer"));
	actor.SetPropFloat(Prop_Data, "m_flCycle", 0.0);
	return action.Continue();
}

static int Update(RF2_MajorShocksGroundSlamAction action, RF2_MajorShocks actor, float interval)
{
	float gameTime = GetGameTime();
	if (action.AttackTime <= gameTime)
	{
		return action.Done();
	}

	if (action.StartTime > -1.0 && action.StartTime <= gameTime)
	{
		float pos[3];
		action.DoAttackHitbox({0.0, 0.0, 0.0}, pos, {-900.0, -900.0, 0.0}, {900.0, 900.0, 66.0},
			200.0, 64, {200.0, 0.0, 850.0}, false, 0.0);
		EmitSoundToAll(SND_DOOMSDAY_EXPLODE, actor.index, _, 150);
		int particle = CreateEntityByName("info_particle_system");
		DispatchKeyValue(particle, "effect_name", "cinefx_goldrush");
		SetEntityOwner(particle, actor.index);
		TeleportEntity(particle, pos);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(2.0, Timer_StopSlamParticle, EnsureEntRef(particle));
		actor.DoShake();
		action.StartTime = -1.0;
	}

	return action.Continue();
}

static void OnEnd(RF2_MajorShocksGroundSlamAction action, RF2_MajorShocks actor, NextBotAction prevAction)
{
	actor.LockAnimations = false;
}

static Action Timer_StopSlamParticle(Handle timer, any entref)
{
	int particle = EntRefToEntIndex(entref);
	if (!particle || particle == INVALID_ENT_REFERENCE)
	{
		return Plugin_Stop;
	}

	AcceptEntityInput(particle, "stop");
	RemoveEntity(particle);

	return Plugin_Stop;
}
