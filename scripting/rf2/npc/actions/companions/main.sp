#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_Factory;

methodmap RF2_CompanionMainAction < NextBotAction
{
	public RF2_CompanionMainAction()
	{
		return view_as<RF2_CompanionMainAction>(g_Factory.Create());
	}
	
	public static NextBotActionFactory GetFactory()
	{
		if (!g_Factory)
		{
			g_Factory = new NextBotActionFactory("RF2_CompanionMainAction");
			g_Factory.SetCallback(NextBotActionCallbackType_Update, Update);
			//g_Factory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			//g_Factory.SetEventCallback(EventResponderType_OnKilled, OnKilled);
		}
		
		return g_Factory;
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
