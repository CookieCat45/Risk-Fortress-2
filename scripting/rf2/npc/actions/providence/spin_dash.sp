#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_Factory;

methodmap RF2_ProvidenceSpinDashAttack < RF2_BaseNPCAttackAction
{
	public RF2_ProvidenceSpinDashAttack()
	{
		if (!g_Factory)
		{
			g_Factory = new NextBotActionFactory("RF2_ProvidenceSpinDashAttack");
			g_Factory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_Factory.SetCallback(NextBotActionCallbackType_Update, Update);
            g_Factory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
			g_Factory.BeginDataMapDesc()
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
                .DefineFloatField("m_flSpinHitTime")
                .DefineFloatField("m_flNextPathUpdateTime")
                .DefineIntField("m_nHitCounter")
				.EndDataMapDesc();
		}
		
		return view_as<RF2_ProvidenceSpinDashAttack>(g_Factory.Create());
	}

    property float SpinHitTime
    {
        public get()
        {
            return this.GetDataFloat("m_flSpinHitTime");
        }

        public set(float value)
        {
            this.SetDataFloat("m_flSpinHitTime", value);
        }
    }

    property float NextPathUpdateTime
    {
        public get()
        {
            return this.GetDataFloat("m_flNextPathUpdateTime");
        }

        public set(float value)
        {
            this.SetDataFloat("m_flNextPathUpdateTime", value);
        }
    }
}

static int OnStart(RF2_ProvidenceSpinDashAttack action, RF2_Providence boss, NextBotAction prevAction)
{
    boss.BaseNpc.flRunSpeed = 0.0;
    const float time = 8.0;
	action.StartTime = GetGameTime();
	float duration = boss.AddGesture("spin_begin");
    boss.ResetSequence(boss.LookupSequence("Stand_ITEM1"));
    boss.NextAttackTime += time+duration;
    boss.SpinAttackTime = GetGameTime()+time+duration+25.0;
    action.AttackTime = GetGameTime() + time+duration;
    action.SpinHitTime = GetGameTime()+duration;
    action.NextPathUpdateTime = 0.0;
    EmitSoundToAll(SND_SPIN_START, boss.index, _, SNDLEVEL_AIRCRAFT);
    EmitSoundToAll(SND_SPIN_START, boss.index, _, SNDLEVEL_AIRCRAFT);
    EmitSoundToAll(SND_SPIN_LOOP, boss.index, _, SNDLEVEL_AIRCRAFT);
    EmitSoundToAll(SND_SPIN_LOOP, boss.index, _, SNDLEVEL_AIRCRAFT);
    EmitSoundToAll(SND_TANK_SPEED_UP, boss.index, _, SNDLEVEL_AIRCRAFT);
    float pos[3];
    boss.WorldSpaceCenter(pos);
    int particle = SpawnInfoParticle("steam_plume", pos, time+duration, boss.index);
    CBaseEntity(particle).SetAbsAngles({-90.0, 0.0, 0.0});
	return action.Continue();
}

static int Update(RF2_ProvidenceSpinDashAttack action, RF2_Providence boss, float interval)
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
        action.NextPathUpdateTime = 0.0;
    }

    if (!boss.IsPlayingGesture("spin_begin") && boss.IsTargetValid())
    {
        int runSequence = boss.LookupSequence("Run_ITEM1");
        if (boss.GetProp(Prop_Send, "m_nSequence") != runSequence)
        {
            boss.ResetSequence(runSequence);
        }
        
        boss.BaseNpc.flRunSpeed = fmin(850.0, boss.BaseNpc.flRunSpeed+15.0);
        float playbackRate = boss.GetPropFloat(Prop_Send, "m_flPlaybackRate");
        playbackRate = fmin(playbackRate+0.05, 4.0);
        boss.SetPropFloat(Prop_Send, "m_flPlaybackRate", playbackRate);
        
        if (action.NextPathUpdateTime < GetGameTime())
        {
            // don't constantly beeline for the target - only keep track of their position every so often
            boss.ApproachEntity(boss.Target);
            action.NextPathUpdateTime = GetGameTime()+0.5;
        }
        else
        {
            // make sure to keep updating the path
            boss.Path.Update(boss.Bot);
        }
    }
	
	if (GetGameTime() >= action.SpinHitTime)
	{
        if (!boss.IsPlayingGesture("spin_loop"))
        {
            int layer = boss.AddLayeredSequence(boss.LookupSequence("spin_loop"), 3);
            boss.SetLayerAutokill(layer, false);
            boss.SetLayerLooping(layer, true);
        }
        
        EmitSoundToAll(SND_SWORD_SWING, boss.index, _, SNDLEVEL_SCREAMING);
		ArrayList hitEnts = action.DoAttackHitbox({0.0, 0.0, 0.0}, _, {-250.0, -250.0, 0.0}, {250.0, 250.0, 150.0}, 
            80.0, 
            DMG_SLASH|DMG_MELEE, _, true, 0.5, 10.0);
            
        for (int i = 0; i < hitEnts.Length; i++)
        {
            int entity = hitEnts.Get(i);
            if (IsValidClient(entity))
            {
                TF2_MakeBleed(entity, entity, 8.0);
            }

            if (IsBuilding(entity))
            {
                EmitSoundToAll(SND_SWORD_IMPACT, entity, _, SNDLEVEL_SCREAMING);
            }
            else
            {
                EmitGameSoundToAll(GSND_SWORD_HIT, entity, _, SNDLEVEL_SCREAMING);
            }
        }

        delete hitEnts;
        action.SpinHitTime = GetGameTime()+0.2;
	}
	
    if (GetGameTime() >= action.AttackTime)
    {
        return action.Done("I'm done spinning like a mad man.");
    }

	return action.Continue();
}

static void OnEnd(RF2_ProvidenceSpinDashAttack action, RF2_Providence boss, NextBotAction prevAction)
{
    boss.RemoveAllGestures();
    boss.BaseNpc.flRunSpeed = 250.0;
    boss.SetPropFloat(Prop_Send, "m_flPlaybackRate", 1.0);
    StopSound(boss.index, SNDCHAN_AUTO, SND_SPIN_LOOP);
    StopSound(boss.index, SNDCHAN_AUTO, SND_SPIN_LOOP);
    StopSound(boss.index, SNDCHAN_AUTO, SND_SPIN_LOOP);
    StopSound(boss.index, SNDCHAN_AUTO, SND_SPIN_LOOP);
}
