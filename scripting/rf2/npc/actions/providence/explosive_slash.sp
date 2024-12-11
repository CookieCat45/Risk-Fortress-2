#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_Factory;

methodmap RF2_ProvidenceExplosiveSlashAttack < RF2_BaseNPCAttackAction
{
	public RF2_ProvidenceExplosiveSlashAttack()
	{
		if (!g_Factory)
		{
			g_Factory = new NextBotActionFactory("RF2_ProvidenceExplosiveSlashAttack");
			g_Factory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_Factory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_Factory.BeginDataMapDesc()
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
                .DefineIntField("m_nHitCounter")
				.EndDataMapDesc();
		}
		
		return view_as<RF2_ProvidenceExplosiveSlashAttack>(g_Factory.Create());
	}
}

static int OnStart(RF2_ProvidenceExplosiveSlashAttack action, RF2_Providence boss, NextBotAction prevAction)
{
	action.StartTime = GetGameTime();
	action.AttackTime = GetGameTime() + 1.1;
    boss.NextAttackTime += 1.1;
	boss.AddGesture("ground_slash");
    CreateTimer(0.1, Timer_PlaySound, EntIndexToEntRef(boss.index), TIMER_FLAG_NO_MAPCHANGE);
	return action.Continue();
}

static void Timer_PlaySound(Handle timer, int entity)
{
    if (!RF2_Providence(EntRefToEntIndex(entity)).IsValid())
        return;

    EmitSoundToAll(SND_SWORD_SWING, entity, _, SNDLEVEL_SCREAMING);
}

static int Update(RF2_ProvidenceExplosiveSlashAttack action, RF2_Providence boss, float interval)
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

	if (action.TimeSinceAttack >= 0.5 && action.HitCounter < 1)
	{
        EmitSoundToAll(SND_SWORD_IMPACT, boss.index, _, SNDLEVEL_SCREAMING);
		action.DoAttackHitbox({50.0, 0.0, 0.0}, _, {-100.0, -100.0, 0.0}, {150.0, 100.0, 180.0}, 
            350.0, 
            DMG_SLASH|DMG_MELEE, _, true);
            
        const int count = 30;
        float explodePos[3], dir[3];
        boss.GetAbsOrigin(pos);
        pos[2] += 25.0;
        CopyVectors(pos, explodePos);
        angles[0] = 0.0;
        GetAngleVectors(angles, dir, NULL_VECTOR, NULL_VECTOR);
        NormalizeVector(dir, dir);
        for (int i = 0; i < count; i++)
        {
            DataPack pack;
            CreateDataTimer(0.1*float(i), Timer_DoExplosionAt, pack, TIMER_FLAG_NO_MAPCHANGE);
            pack.WriteFloatArray(explodePos, 3);
            pack.WriteCell(EntIndexToEntRef(boss.index));
            explodePos[0] += 100.0 * dir[0];
            explodePos[1] += 100.0 * dir[1];
            explodePos[2] += 100.0 * dir[2];
        }
	}
	
    if (GetGameTime() >= action.AttackTime)
    {
        return action.Done("I'm done doing my explosive slash.");
    }

	return action.Continue();
}

static void Timer_DoExplosionAt(Handle timer, DataPack pack)
{
    pack.Reset();
    float pos[3];
    pack.ReadFloatArray(pos, 3);
    int boss = EntRefToEntIndex(pack.ReadCell());
    if (!IsValidEntity2(boss))
        return;

    // trace up, then down
    TR_TraceRayFilter(pos, {-90.0, 0.0, 0.0}, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite, TraceFilter_WallsOnly, _, TRACE_WORLD_ONLY);
    TR_GetEndPosition(pos);
    TR_TraceRayFilter(pos, {90.0, 0.0, 0.0}, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite, TraceFilter_WallsOnly, _, TRACE_WORLD_ONLY);
    TR_GetEndPosition(pos);
    pos[2] += 25.0;
    DoExplosionEffect(pos);
    TE_TFParticle("ExplosionCore_Wall", pos);
    DoRadiusDamage(boss, boss, pos, _, 175.0, DMG_BLAST, 250.0, 0.5, _, _, _, 0.25);
    UTIL_ScreenShake(pos, 10.0, 20.0, 0.8, 500.0, SHAKE_START, true);
}
