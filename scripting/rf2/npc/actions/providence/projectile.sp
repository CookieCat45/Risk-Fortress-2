#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_Factory;

methodmap RF2_ProvidenceProjectileAttack < RF2_BaseNPCAttackAction
{
	public RF2_ProvidenceProjectileAttack()
	{
		if (!g_Factory)
		{
			g_Factory = new NextBotActionFactory("RF2_ProvidenceProjectileAttack");
			g_Factory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_Factory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_Factory.BeginDataMapDesc()
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
                .DefineIntField("m_nHitCounter")
				.EndDataMapDesc();
		}
		
		return view_as<RF2_ProvidenceProjectileAttack>(g_Factory.Create());
	}
}

static int OnStart(RF2_ProvidenceProjectileAttack action, RF2_Providence boss, NextBotAction prevAction)
{
	action.StartTime = GetGameTime();
	action.AttackTime = GetGameTime() + 1.3;
	boss.AddGesture("sword_toss");
    boss.NextAttackTime += 1.3;
	return action.Continue();
}

static int Update(RF2_ProvidenceProjectileAttack action, RF2_Providence boss, float interval)
{
    float pos[3], angles[3];
    boss.WorldSpaceCenter(pos);
    if (boss.IsTargetValid())
    {
        float enemyPos[3];
        GetEntPos(boss.Target, enemyPos, true);
        GetVectorAnglesTwoPoints(pos, enemyPos, angles);
        float absAngles[3];
        CopyVectors(angles, absAngles);
        absAngles[0] = 0.0;
        boss.SetAbsAngles(absAngles);
    }
    else
    {
        boss.GetAbsAngles(angles);
        boss.GetNewTarget(TargetMethod_Closest, TargetType_NoMinions);
    }

	if (action.TimeSinceAttack >= 0.4 && action.HitCounter < 1)
	{
        EmitSoundToAll(SND_SWORD_SWING, boss.index, _, SNDLEVEL_SCREAMING);
        EmitAmbientSound(SND_SPELL_FIREBALL, pos, _, SNDLEVEL_SCREAMING);
		action.DoAttackHitbox({50.0, 0.0, 0.0}, _, {-100.0, -100.0, 0.0}, {100.0, 100.0, 150.0}, 
            350.0, 
            DMG_SLASH|DMG_MELEE, _, true);
            
        for (int i = 1; i <= 3; i++)
        {
            switch (i)
            {
                case 2: angles[1] += 30.0;
                case 3: angles[1] -= 60.0;
            }

            RF2_Projectile_Fireball fireball = RF2_Projectile_Fireball(ShootProjectile(boss.index, 
                "rf2_projectile_fireball", 
                pos, angles, 1500.0, 
                400.0));

            fireball.BuildingDamageMult = 0.3;
        }
	}
	
    if (GetGameTime() >= action.AttackTime)
    {
        return action.Done("I'm done tossing a projectile.");
    }

	return action.Continue();
}
