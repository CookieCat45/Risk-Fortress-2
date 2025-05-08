#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_ActionFactory;

methodmap RF2_CompanionMainAction < NextBotAction
{
	public RF2_CompanionMainAction()
	{
		return view_as<RF2_CompanionMainAction>(g_ActionFactory.Create());
	}
	
	public static NextBotActionFactory GetFactory()
	{
		if (!g_ActionFactory)
		{
			g_ActionFactory = new NextBotActionFactory("RF2_CompanionMainAction");
			g_ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
			//g_ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			//g_ActionFactory.SetEventCallback(EventResponderType_OnKilled, OnKilled);
		}
		
		return g_ActionFactory;
	}
}

static int Update(RF2_CompanionMainAction action, RF2_Companion_Base npc, float interval)
{
	switch (npc.Behavior)
	{
		case AI_CHASER: return action.SuspendFor(RF2_CompanionChaserAI(), "Chasing my target");
	}
	
	return action.Continue();
}
