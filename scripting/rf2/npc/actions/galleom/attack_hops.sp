#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_ActionFactory;

methodmap RF2_GalleomHopAttack < RF2_BaseNPCAttackAction
{
	public RF2_GalleomHopAttack()
	{
		if (!g_ActionFactory)
		{
			g_ActionFactory = new NextBotActionFactory("RF2_GalleomHopAttack");
			g_ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_ActionFactory.BeginDataMapDesc()
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
				.DefineIntField("m_bHopping")
				.DefineIntField("m_nHitCounter")
				.EndDataMapDesc();
		}
		
		return view_as<RF2_GalleomHopAttack>(g_ActionFactory.Create());
	}

	property bool Hopping
	{
		public get()
		{
			return this.GetData("m_bHopping");
		}
		
		public set(bool value)
		{
			this.SetData("m_bHopping", value);
		}
	}
}

static int OnStart(RF2_GalleomHopAttack action, RF2_RaidBoss_Galleom boss, NextBotAction prevAction)
{
	action.StartTime = GetGameTime();
	action.AttackTime = GetGameTime() + boss.AddGesture("EnmGalleomHopStart")-0.05;
	boss.BaseNpc.flRunSpeed = 300.0;
	return action.Continue();
}

static int Update(RF2_GalleomHopAttack action, RF2_RaidBoss_Galleom boss, float interval)
{
	INextBot bot = boss.MyNextBotPointer();
	NextBotGroundLocomotion loco = boss.BaseNpc.GetLocomotion();
	
	if (action.RecoveryTime > 0.0)
	{
		if (GetGameTime() >= action.RecoveryTime)
		{
			return action.Done("I'm done jumping around.");
		}
	}
	else if (GetGameTime() >= action.AttackTime && action.HitCounter <= 4)
	{
		float duration;
		if (action.Hopping)
		{
			float pos[3];
			action.DoAttackHitbox(_, pos, {-350.0, -350.0, 0.0}, {350.0, 350.0, 100.0}, 300.0, DMG_CLUB, {0.0, 0.0, 850.0});
			TE_TFParticle("hammer_impact_button_dust2", pos);
			UTIL_ScreenShake(pos, 10.0, 20.0, 2.5, 800.0, SHAKE_START, true);
			EmitSoundToAll(SND_JUMP_SLAM, boss.index, _, SNDLEVEL_SCREAMING);
			EmitSoundToAll(SND_JUMP_SLAM, boss.index, _, SNDLEVEL_SCREAMING);		
			switch (action.HitCounter)
			{
				case 1: duration = boss.AddGesture("EnmGalleomHopLand1")-0.05;
				case 2: duration = boss.AddGesture("EnmGalleomHopLand2")-0.05;
				case 3: duration = boss.AddGesture("EnmGalleomHopLand3")-0.05;
				case 4: duration = boss.AddGesture("EnmGalleomHopEnd");
			}
			
			if (action.HitCounter >= 4)
			{
				action.RecoveryTime = GetGameTime() + duration;
			}
			
			boss.SetHitboxSize({-150.0, -150.0, 0.0}, {150.0, 150.0, 300.0});
		}
		else
		{
			switch (action.HitCounter)
			{
				case 0: duration = boss.AddGesture("EnmGalleomHop1")-0.05;
				case 1: duration = boss.AddGesture("EnmGalleomHop2")-0.05;
				case 2: duration = boss.AddGesture("EnmGalleomHop3")-0.05;
				case 3: duration = boss.AddGesture("EnmGalleomHop4")-0.05;
			}
			
			EmitSoundToAll(SND_JUMP, boss.index, _, SNDLEVEL_SCREAMING);
			EmitSoundToAll(SND_JUMP, boss.index, _, SNDLEVEL_SCREAMING);
			boss.SetHitboxSize({-150.0, -150.0, 0.0}, {150.0, 150.0, 600.0});
		}
		
		if (action.HitCounter < 4)
		{
			action.AttackTime = GetGameTime() + duration;
			action.Hopping = !action.Hopping;
		}
	}
	
	if (action.Hopping && action.HitCounter < 4)
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
