#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_Factory;

methodmap RF2_ProvidenceShockwaveAttack < RF2_BaseNPCAttackAction
{
	public RF2_ProvidenceShockwaveAttack()
	{
		if (!g_Factory)
		{
			g_Factory = new NextBotActionFactory("RF2_ProvidenceShockwaveAttack");
			g_Factory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_Factory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_Factory.BeginDataMapDesc()
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
                .DefineIntField("m_nHitCounter")
			.EndDataMapDesc();
		}
		
		return view_as<RF2_ProvidenceShockwaveAttack>(g_Factory.Create());
	}
}

static int OnStart(RF2_ProvidenceShockwaveAttack action, RF2_Providence boss, NextBotAction prevAction)
{
	const float time = 3.3;
	action.StartTime = GetGameTime();
	action.AttackTime = GetGameTime() + time;
	boss.NextAttackTime += time;
	boss.GroundStabAttackTime = GetGameTime() + time + 12.0;
	boss.AddGesture("ground_stab");
	EmitSoundToAll(SND_GROUND_STAB, boss.index, _, SNDLEVEL_TRAIN);
	EmitSoundToAll(SND_GROUND_STAB, boss.index, _, SNDLEVEL_TRAIN);

	// doesn't need to be that loud in the first phase, but since the attack is arena wide, the sound cue is important
	if (boss.Phase != ProvidencePhase_Solo)
	{
		EmitSoundToAll(SND_GROUND_STAB, boss.index, _, SNDLEVEL_TRAIN);
	}
	
	return action.Continue();
}

static int Update(RF2_ProvidenceShockwaveAttack action, RF2_Providence boss, float interval)
{
	if (action.TimeSinceAttack >= 1.1 && action.HitCounter < 1)
	{
		float pos[3];
		action.DoAttackHitbox({50.0, 0.0, 0.0}, pos, {-75.0, -75.0, 0.0}, {75.0, 75.0, 180.0}, 400.0, DMG_CLUB|DMG_MELEE);

		// Shockwave does no damage to buildings since it is arena wide
		ArrayList hitEnts = action.DoAttackHitbox({50.0, 0.0, 0.0}, pos, {-2500.0, -2500.0, 0.0}, {2500.0, 2500.0, 50.0}, 
			250.0, DMG_CLUB|DMG_MELEE, {0.0, 0.0, 850.0}, true, 0.0);

		for (int i = 0; i < hitEnts.Length; i++)
		{
			int client = hitEnts.Get(i);
			if (IsValidClient(client) && DistBetween(boss.index, client) <= 1000.0)
			{
				TF2_StunPlayer(client, 2.0, _, TF_STUNFLAG_BONKSTUCK);
			}
		}
		
		delete hitEnts;
		DoExplosionEffect(pos);
		TE_TFParticle("ExplosionCore_Wall", pos);
		UTIL_ScreenShake(pos, 15.0, 30.0, 4.0, 1500.0, SHAKE_START, true);
		UTIL_ScreenShake(pos, 15.0, 30.0, 4.0, 1500.0, SHAKE_START, true);
		TE_TFParticle("asplode_hoodoo_shockwave", pos);
		TE_TFParticle("hammer_impact_button_dust2", pos);
		TE_TFParticle("hammer_bell_ring_shockwave", pos);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i))
				continue;

			if (DistBetween(boss.index, i) <= 3000.0)
			{
				UTIL_ScreenFade(i, {255, 255, 255, 200}, 0.1, 0.1, FFADE_OUT);
			}
		}
	}
	
	if (GetGameTime() >= action.AttackTime)
	{
		return action.Done("I'm done stabbing the ground with my sword.");
	}
	
	return action.Continue();
}
