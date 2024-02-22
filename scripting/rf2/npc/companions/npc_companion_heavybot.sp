#pragma newdecls required
#pragma semicolon 1

static CEntityFactory g_Factory;

methodmap RF2_Companion_HeavyBot < RF2_Companion_Base
{
	public RF2_Companion_HeavyBot(int entity)
	{
		return view_as<RF2_Companion_HeavyBot>(entity);
	}
	
	public bool IsValid()
	{
		if (!IsValidEntity2(this.index))
		{
			return false;
		}
		
		return CEntityFactory.GetFactoryOfEntity(this.index) == g_Factory;
	}
	
	public static void Init()
	{
		g_Factory = new CEntityFactory("rf2_npc_companion_heavybot", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Companion_Base.GetFactory());
		g_Factory.Install();
	}
}

static void OnCreate(RF2_Companion_HeavyBot npc)
{
	npc.SetModel("models/rf2/bots/bot_heavy.mdl");
	npc.SetPropFloat(Prop_Send, "m_flModelScale", 0.5);
	npc.IdleSequence = npc.LookupSequence("Stand_MELEE");
	npc.RunSequence = npc.LookupSequence("Run_MELEE");
	npc.MeleeGesture = npc.LookupSequence("AttackStand_MELEE_U");
	npc.MoveX = npc.LookupPoseParameter("move_x");
	npc.MoveY = npc.LookupPoseParameter("move_y");
}
