#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_Factory;

methodmap RF2_GalleomHammerKnuckleAttack < RF2_BaseNPCAttackAction
{
	public RF2_GalleomHammerKnuckleAttack()
	{
		if (!g_Factory)
		{
			g_Factory = new NextBotActionFactory("RF2_GalleomHammerKnuckleAttack");
			g_Factory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_Factory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_Factory.BeginDataMapDesc()
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
				.DefineIntField("m_nHitCounter")
				.EndDataMapDesc();
		}
		
		return view_as<RF2_GalleomHammerKnuckleAttack>(g_Factory.Create());
	}
}

static int OnStart(RF2_GalleomHammerKnuckleAttack action, RF2_RaidBoss_Galleom boss, NextBotAction prevAction)
{
	action.StartTime = GetGameTime();
	action.AttackTime = GetGameTime() + 3.0;
	boss.AddGesture("EnmGalleomHammerKnuckle");
	EmitSoundToAllEx(SND_FIST_SLAM, boss.index, _, SNDLEVEL_SCREAMING, _, 2.0);
	EmitSoundToAllEx(SND_GALLEOM_ROAR, boss.index, _, SNDLEVEL_SCREAMING, _, 2.0);
	return action.Continue();
}

static int Update(RF2_GalleomHammerKnuckleAttack action, RF2_RaidBoss_Galleom boss, float interval)
{
	if (action.TimeSinceAttack >= 1.5 && action.HitCounter < 1)
	{
		float pos[3];
		action.DoAttackHitbox({250.0, 0.0, 0.0}, pos, {-350.0, -300.0, 0.0}, {350.0, 300.0, 120.0}, 350.0, DMG_CLUB, {0.0, 0.0, 850.0});
		ArrayList hitEnts = action.DoAttackHitbox({250.0, 0.0, 0.0}, pos, {-100.0, -100.0, 0.0}, {100.0, 100.0, 120.0}, 450.0, DMG_CLUB, _, true);
		for (int i = 0; i < hitEnts.Length; i++)
		{
			int client = hitEnts.Get(i);
			if (IsValidClient(client))
			{
				TF2_StunPlayer(client, 4.0, _, TF_STUNFLAG_BONKSTUCK);
			}
		}
		
		delete hitEnts;
		UTIL_ScreenShake(pos, 15.0, 30.0, 4.0, 1000.0, SHAKE_START, true);
		TE_TFParticle("asplode_hoodoo_shockwave", pos);
		TE_TFParticle("hammer_impact_button_dust2", pos);
	}
	
	if (GetGameTime() >= action.AttackTime)
	{
		return action.Done("I'm done hammering the ground with my fists.");
	}
	
	return action.Continue();
}
