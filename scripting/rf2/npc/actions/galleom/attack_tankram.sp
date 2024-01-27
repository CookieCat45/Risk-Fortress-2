#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_Factory;

methodmap RF2_GalleomTankRamAttack < RF2_BaseNPCAttackAction
{
	public RF2_GalleomTankRamAttack()
	{
		if (!g_Factory)
		{
			g_Factory = new NextBotActionFactory("RF2_GalleomTankRamAttack");
			g_Factory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_Factory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_Factory.BeginDataMapDesc()
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
				.DefineIntField("m_nHitCounter")
				.DefineFloatField("m_flJetStartTime")
				.DefineEntityField("m_hTrailL")
				.DefineEntityField("m_hTrailR")
				.EndDataMapDesc();
		}
		
		return view_as<RF2_GalleomTankRamAttack>(g_Factory.Create());
	}

	property CBaseEntity RocketTrailL
	{
		public get()
		{
			return CBaseEntity(this.GetDataEnt("m_hTrailL"));
		}
		
		public set(CBaseEntity entity)
		{
			this.SetDataEnt("m_hTrailL", entity.index);
		}
	}

	property CBaseEntity RocketTrailR
	{
		public get()
		{
			return CBaseEntity(this.GetDataEnt("m_hTrailR"));
		}
		
		public set(CBaseEntity entity)
		{
			this.SetDataEnt("m_hTrailR", entity.index);
		}
	}
	
	property float JetStartTime
	{
		public get()
		{
			return this.GetDataFloat("m_flJetStartTime");
		}
		
		public set(float value)
		{
			this.SetDataFloat("m_flJetStartTime", value);
		}
	}
}

static int OnStart(RF2_GalleomTankRamAttack action, RF2_RaidBoss_Galleom boss, NextBotAction prevAction)
{
	action.StartTime = GetGameTime();
	action.AttackTime = GetGameTime() + boss.AddGesture("EnmGalleomManToTank")-0.05;
	boss.SetSequence("EnmGalleomTankAttack1");
	boss.BaseNpc.flAcceleration = 750.0;
	boss.BaseNpc.flRunSpeed = 1500.0;
	EmitSoundToAllEx(SND_TANKLOOP, boss.index, _, SNDLEVEL_SCREAMING, _, 2.0);
	return action.Continue();
}

static int Update(RF2_GalleomTankRamAttack action, RF2_RaidBoss_Galleom boss, float interval)
{
	INextBot bot = boss.MyNextBotPointer();
	NextBotGroundLocomotion loco = boss.BaseNpc.GetLocomotion();

	if (action.RecoveryTime > 0.0)
	{
		if (GetGameTime() >= action.RecoveryTime)
		{
			boss.BaseNpc.flAcceleration = 2000.0;
			boss.SetHitboxSize({-150.0, -150.0, 0.0}, {150.0, 150.0, 300.0});
			RemoveEntity2(action.RocketTrailL.index);
			RemoveEntity2(action.RocketTrailR.index);
			return action.Done("I'm done running people over.");
		}
	}
	else if (GetGameTime() >= action.AttackTime)
	{
		if (action.HitCounter == 0) // we're finished transforming, initialize some stuff
		{
			boss.SetHitboxSize({-200.0, -200.0, 0.0}, {200.0, 200.0, 200.0});
			float pos[3];
			boss.GetAttachment(boss.LookupAttachment("jet_r"), pos, NULL_VECTOR);
			action.RocketTrailR = CBaseEntity(SpawnInfoParticle("spell_fireball_small_blue", pos, _, boss.index, "jet_r"));
			boss.GetAttachment(boss.LookupAttachment("jet_l"), pos, NULL_VECTOR);
			action.RocketTrailL = CBaseEntity(SpawnInfoParticle("spell_fireball_small_blue", pos, _, boss.index, "jet_l"));
			EmitSoundToAll(SND_JET_START, boss.index, _, SNDLEVEL_SCREAMING);
			action.JetStartTime = GetEngineTime();
		}
		
		float mins[3], maxs[3];
		boss.GetPropVector(Prop_Send, "m_vecMins", mins);
		boss.GetPropVector(Prop_Send, "m_vecMaxs", maxs);
		action.DoAttackHitbox(_, _, mins, maxs, 75.0, DMG_CLUB, {0.0, 0.0, 500.0});
		if (action.HitCounter >= 20)
		{
			action.RecoveryTime = GetGameTime() + boss.AddGesture("EnmGalleomTankToMan")-0.05;
			boss.SetSequence("EnmGalleomWait");
			StopSound(boss.index, SNDCHAN_AUTO, SND_TANKLOOP);
			StopSound(boss.index, SNDCHAN_AUTO, SND_TANKLOOP);
			StopSound(boss.index, SNDCHAN_AUTO, SND_TANKLOOP);
			StopSound(boss.index, SNDCHAN_AUTO, SND_TANKLOOP);
			StopSound(boss.index, SNDCHAN_AUTO, SND_JET_LOOP);
			StopSound(boss.index, SNDCHAN_AUTO, SND_JET_LOOP);
			EmitSoundToAll(SND_TANKEXIT, boss.index, _, SNDLEVEL_SCREAMING, _, 2.0);
		}
		
		action.AttackTime = GetGameTime() + 0.2;
	}
	
	if (action.JetStartTime > 0.0 && GetEngineTime() >= action.JetStartTime+3.4)
	{
		EmitSoundToAll(SND_JET_LOOP, boss.index, _, SNDLEVEL_SCREAMING);
		action.JetStartTime = 0.0;
	}
	
	if (action.HitCounter > 0 && action.HitCounter < 20)
	{
		if (IsValidEntity2(boss.Target))
		{
			float targetPos[3];
			GetEntPos(boss.Target, targetPos);
			boss.Path.ComputeToPos(bot, targetPos);
			boss.Path.Update(bot);
			loco.Run();
		}
		else
		{
			boss.GetNewTarget();
		}
	}
	else
	{
		boss.Path.Invalidate();
		loco.Stop();
	}
	
	return action.Continue();
}