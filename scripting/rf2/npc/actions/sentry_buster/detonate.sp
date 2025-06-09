#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_ActionFactory;

methodmap RF2_SentryBusterDetonateAction < NextBotAction
{
	public RF2_SentryBusterDetonateAction()
	{
		if (!g_ActionFactory)
		{
			g_ActionFactory = new NextBotActionFactory("RF2_SentryBusterDetonate");
			g_ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_ActionFactory.BeginDataMapDesc()
				.DefineFloatField("m_DetonateTime")
				.EndDataMapDesc();
		}
		return view_as<RF2_SentryBusterDetonateAction>(g_ActionFactory.Create());
	}
	
	property float DetonateTime
	{
		public get()
		{
			return this.GetDataFloat("m_DetonateTime");
		}

		public set(float value)
		{
			this.SetDataFloat("m_DetonateTime", value);
		}
	}
}

static int OnStart(RF2_SentryBusterDetonateAction action, RF2_SentryBuster actor, NextBotAction prevAction)
{
	actor.DoUnstuckChecks = false;
	int sequence = actor.LookupSequence("taunt04");
	actor.SetProp(Prop_Data, "m_takedamage", DAMAGE_NO);
	if (sequence == -1)
	{
		actor.Detonate();
		return action.Done();
	}
	
	actor.ResetSequence(sequence);
	actor.SetPropFloat(Prop_Data, "m_flCycle", 0.0);
	actor.SetProp(Prop_Data, "m_takedamage", 0);
	EmitGameSoundToAll("MVM.SentryBusterSpin", actor.index);
	float duration = actor.SequenceDuration(sequence);
	if (actor.Team == TEAM_SURVIVOR)
	{
		duration *= 0.25;
	}
	
	action.DetonateTime = GetGameTime() + duration;
	CBaseNPC npc = TheNPCs.FindNPCByEntIndex(actor.index);
	npc.flWalkSpeed = 0.0;
	npc.flRunSpeed = 0.0;

	return action.Continue();
}

static int Update(RF2_SentryBusterDetonateAction action, RF2_SentryBuster actor, float interval)
{
	if (GetGameTime() > action.DetonateTime)
	{
		actor.Detonate();
	}
	return action.Continue();
}