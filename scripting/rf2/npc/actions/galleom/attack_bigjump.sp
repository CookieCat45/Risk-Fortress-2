#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_Factory;

methodmap RF2_GalleomBigJumpAttack < RF2_BaseNPCAttackAction
{
	public RF2_GalleomBigJumpAttack()
	{
		if (!g_Factory)
		{
			g_Factory = new NextBotActionFactory("RF2_GalleomBigJumpAttack");
			g_Factory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_Factory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_Factory.BeginDataMapDesc()
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
				.DefineIntField("m_nHitCounter")
				.EndDataMapDesc();
		}
		
		return view_as<RF2_GalleomBigJumpAttack>(g_Factory.Create());
	}
}

static int OnStart(RF2_GalleomBigJumpAttack action, RF2_RaidBoss_Galleom boss, NextBotAction prevAction)
{
	action.StartTime = GetGameTime();
	action.AttackTime = GetGameTime() + boss.AddGesture("EnmGalleomJumpAttack")-0.05;
	EmitSoundToAll(SND_JUMP, boss.index, _, SNDLEVEL_SCREAMING);
	EmitSoundToAll(SND_JUMP, boss.index, _, SNDLEVEL_SCREAMING);
	boss.BaseNpc.flRunSpeed = 300.0;
	boss.SetHitboxSize({-150.0, -150.0, 0.0}, {150.0, 150.0, 700.0});
	return action.Continue();
}

static int Update(RF2_GalleomBigJumpAttack action, RF2_RaidBoss_Galleom boss, float interval)
{
	INextBot bot = boss.MyNextBotPointer();
	NextBotGroundLocomotion loco = boss.BaseNpc.GetLocomotion();
	
	if (GetGameTime() < action.AttackTime && action.RecoveryTime <= 0.0)
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
			float pos[3];
			boss.WorldSpaceCenter(pos);
			boss.GetNewTarget();
		}
	}
	else
	{
		if (action.RecoveryTime <= 0.0)
		{
			float pos[3];
			action.DoAttackHitbox(_, pos, {-350.0, -350.0, 0.0}, {350.0, 350.0, 120.0}, 600.0, DMG_CLUB|DMG_USEDISTANCEMOD, {0.0, 0.0, 1100.0});
			UTIL_ScreenShake(pos, 10.0, 40.0, 6.0, 1000.0, SHAKE_START, true);
			TE_TFParticle("asplode_hoodoo_shockwave", pos);
			TE_TFParticle("hammer_impact_button_dust2", pos);
			boss.Path.Invalidate();
			loco.Stop();
			boss.SetHitboxSize({-150.0, -150.0, 0.0}, {150.0, 150.0, 300.0});
			
			// Wait until landing animation finishes
			action.RecoveryTime = GetGameTime() + boss.AddGesture("EnmGalleomJumpLand", _, _, _, 2);
			EmitSoundToAll(SND_JUMP_SLAM, boss.index, _, SNDLEVEL_SCREAMING);
			EmitSoundToAll(SND_JUMP_SLAM, boss.index, _, SNDLEVEL_SCREAMING);
		}
		else if (GetGameTime() >= action.RecoveryTime)
		{
			return action.Done("I've finished landing on the ground.");
		}
	}
	
	return action.Continue();
}
