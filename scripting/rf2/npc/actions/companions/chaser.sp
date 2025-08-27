#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_ActionFactory;

methodmap RF2_CompanionChaserAI < NextBotAction
{
	public RF2_CompanionChaserAI()
	{
		if (!g_ActionFactory)
		{
			g_ActionFactory = new NextBotActionFactory("RF2_CompanionChaserAI");
			g_ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
		}
		
		return view_as<RF2_CompanionChaserAI>(g_ActionFactory.Create());
	}
}

static int Update(RF2_CompanionChaserAI action, RF2_Companion_Base npc, float interval)
{
	if (npc.Behavior != AI_CHASER)
	{
		return action.Done("My behavior type was changed");
	}
	
	if (!IsValidEntity2(npc.Target))
	{
		npc.GetNewTarget();
	}
	
	if (IsValidEntity2(npc.Target))
	{
		npc.Path.ComputeToTarget(npc.Bot, npc.Target, 6000.0);
		npc.Path.Update(npc.Bot);
		npc.Locomotion.Run();
		if (DistBetween(npc.index, npc.Target, true) <= Pow(npc.AttackRange, 2.0) && IsLOSClear(npc.index, npc.Target, MASK_NPCSOLID_BRUSHONLY))
		{
			return action.SuspendFor(RF2_CompanionMeleeAttack(), "What is a man? A miserable little pile of secrets! But enough talk, HAVE AT YOU!!");
		}
	}
	
	return action.Continue();
}
