#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_Factory;

methodmap RF2_CompanionMeleeAttack < RF2_BaseNPCAttackAction
{
	public RF2_CompanionMeleeAttack()
	{
		if (!g_Factory)
		{
			g_Factory = new NextBotActionFactory("RF2_CompanionMeleeAttack");
			g_Factory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_Factory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_Factory.BeginDataMapDesc()
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
				.DefineIntField("m_nHitCounter")
				.EndDataMapDesc();
		}
		
		return view_as<RF2_CompanionMeleeAttack>(g_Factory.Create());
	}
}

static int OnStart(RF2_CompanionMeleeAttack action, RF2_Companion_Base npc, NextBotAction prevAction)
{
	npc.State = STATE_ATTACK_MELEE;
	action.StartTime = GetGameTime();
	action.AttackTime = GetGameTime() + npc.AttackDuration;
	return action.Continue();
}

static int Update(RF2_CompanionMeleeAttack action, RF2_Companion_Base npc, float interval)
{
	if (IsValidEntity2(npc.Target))
	{
		npc.Path.ComputeToTarget(npc.Bot, npc.Target, 6000.0);
		npc.Path.Update(npc.Bot);
		npc.Locomotion.Run();
	}
	
	if (action.TimeSinceAttack >= npc.AttackDelay && action.HitCounter < 1)
	{
		float offset[3], mins[3], maxs[3], force[3];
		npc.GetMeleeOffset(offset);
		npc.GetMeleeMins(mins);
		npc.GetMeleeMaxs(maxs);
		npc.GetMeleeForce(force);
		action.DoAttackHitbox(offset, _, mins, maxs, npc.MeleeDamage, npc.MeleeDamageType, force);
	}
	
	if (GetGameTime() >= action.AttackTime)
	{
		npc.State = STATE_ATTACK_ENDING;
		return action.Done("I'm done performing my melee attack");
	}
	
	return action.Continue();
}
