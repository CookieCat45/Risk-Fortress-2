#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_ActionFactory;

methodmap RF2_GalleomDoubleSlamAttack < RF2_BaseNPCAttackAction
{
	public RF2_GalleomDoubleSlamAttack()
	{
		if (!g_ActionFactory)
		{
			g_ActionFactory = new NextBotActionFactory("RF2_GalleomDoubleSlamAttack");
			g_ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_ActionFactory.BeginDataMapDesc()
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
				.DefineIntField("m_nHitCounter")
				.EndDataMapDesc();
		}
		
		return view_as<RF2_GalleomDoubleSlamAttack>(g_ActionFactory.Create());
	}
}

static int OnStart(RF2_GalleomDoubleSlamAttack action, RF2_RaidBoss_Galleom boss, NextBotAction prevAction)
{
	action.StartTime = GetGameTime();
	boss.AddGesture("EnmGalleomDoubleArm");
	EmitSoundToAll(SND_DOUBLESLAM, boss.index, _, SNDLEVEL_SCREAMING);
	EmitSoundToAll(SND_DOUBLESLAM, boss.index, _, SNDLEVEL_SCREAMING);
	EmitSoundToAll(SND_GALLEOM_ROAR, boss.index, _, SNDLEVEL_SCREAMING);
	EmitSoundToAll(SND_GALLEOM_ROAR, boss.index, _, SNDLEVEL_SCREAMING);
	return action.Continue();
}

static int Update(RF2_GalleomDoubleSlamAttack action, RF2_RaidBoss_Galleom boss, float interval)
{
	if (action.TimeSinceAttack >= 1.0 && action.HitCounter < 1)
	{
		float pos[3];
		action.DoAttackHitbox({300.0, 0.0, 0.0}, pos, {-400.0, -200.0, 0.0}, {150.0, 200.0, 100.0}, 450.0, DMG_CLUB, {0.0, 0.0, 650.0});
		TE_TFParticle("asplode_hoodoo_shockwave", pos);
		TE_TFParticle("hammer_impact_button_dust2", pos);
		action.DoAttackHitbox({-300.0, 0.0, 0.0}, pos, {-150.0, -200.0, 0.0}, {400.0, 200.0, 100.0}, 450.0, DMG_CLUB, {0.0, 0.0, 650.0});
		TE_TFParticle("asplode_hoodoo_shockwave", pos);
		TE_TFParticle("hammer_impact_button_dust2", pos);
		UTIL_ScreenShake(pos, 15.0, 30.0, 4.0, 1000.0, SHAKE_START, true);
	}
	
	if (action.TimeSinceAttack >= 2.0)
	{
		return action.Done("I'm done my double-slam attack.");
	}
	
	return action.Continue();
}
