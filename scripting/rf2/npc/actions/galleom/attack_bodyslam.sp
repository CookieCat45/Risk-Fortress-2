#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_ActionFactory;

methodmap RF2_GalleomBodySlamAttack < RF2_BaseNPCAttackAction
{
	public RF2_GalleomBodySlamAttack()
	{
		if (!g_ActionFactory)
		{
			g_ActionFactory = new NextBotActionFactory("RF2_GalleomBodySlamAttack");
			g_ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_ActionFactory.BeginDataMapDesc()
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
				.DefineIntField("m_nHitCounter")
				.EndDataMapDesc();
		}
		
		return view_as<RF2_GalleomBodySlamAttack>(g_ActionFactory.Create());
	}
}

static int OnStart(RF2_GalleomBodySlamAttack action, RF2_RaidBoss_Galleom boss, NextBotAction prevAction)
{
	action.StartTime = GetGameTime();
	action.AttackTime = GetGameTime() + 1.5;
	boss.AddGesture("EnmGalleomChangeMiss");
	EmitSoundToAll(SND_BODYSLAM_START, boss.index, _, SNDLEVEL_SCREAMING);
	EmitSoundToAll(SND_BODYSLAM_START, boss.index, _, SNDLEVEL_SCREAMING);
	return action.Continue();
}

static int Update(RF2_GalleomBodySlamAttack action, RF2_RaidBoss_Galleom boss, float interval)
{
	if (action.RecoveryTime > 0.0)
	{
		if (GetGameTime() >= action.RecoveryTime)
		{
			return action.Done("I've recovered from my slam attack.");
		}
	}
	else if (GetGameTime() >= action.AttackTime)
	{
		float pos[3];
		action.DoAttackHitbox({350.0, 0.0, 0.0}, pos, {-300.0, -200.0, 0.0}, {75.0, 200.0, 80.0}, 600.0, DMG_CLUB|DMG_CRUSH|DMG_BLAST);
		DoRadiusDamage(boss.index, boss.index, pos, _, 500.0, DMG_BLAST|DMG_CLUB, 550.0);
		TE_TFParticle("hightower_explosion", pos);
		EmitSoundToAll(SND_BODYSLAM_LAND, boss.index, _, SNDLEVEL_SCREAMING);
		EmitSoundToAll(SND_BODYSLAM_LAND, boss.index, _, SNDLEVEL_SCREAMING);
		EmitSoundToAll(SND_BODYSLAM_LAND, boss.index, _, SNDLEVEL_SCREAMING);
		UTIL_ScreenShake(pos, 15.0, 30.0, 4.0, 1000.0, SHAKE_START, true);
		action.RecoveryTime = GetGameTime() + 2.5;
	}
	
	return action.Continue();
}