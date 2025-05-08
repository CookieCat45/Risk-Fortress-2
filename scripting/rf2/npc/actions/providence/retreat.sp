#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_ActionFactory;

methodmap RF2_ProvidenceRetreatAction < NextBotAction
{
	public RF2_ProvidenceRetreatAction()
	{
		if (!g_ActionFactory)
		{
			g_ActionFactory = new NextBotActionFactory("RF2_ProvidenceRetreatAction");
			g_ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
            g_ActionFactory.SetEventCallback(EventResponderType_OnCommandString, OnCommandString);
		}
		
		return view_as<RF2_ProvidenceRetreatAction>(g_ActionFactory.Create());
	}
}

static int OnStart(RF2_ProvidenceRetreatAction action, RF2_Providence boss, NextBotAction prevAction)
{
    boss.Phase = ProvidencePhase_Retreat;
    boss.HealthText.TextSize = 0.0;
    boss.RemoveAllGestures();
    boss.SetGlow(false);
    boss.AddFlag(FL_NOTARGET);
    boss.Path.Invalidate();
    boss.Locomotion.Stop();
    boss.DetermineSequence();
    float pos[3];
    boss.WorldSpaceCenter(pos);
    DoExplosionEffect(pos);
    UTIL_ScreenShake(pos, 10.0, 20.0, 3.0, 3000.0, SHAKE_START, true);
    TE_TFParticle("hightower_explosion", pos);
    SpawnInfoParticle("smoke_train", pos, 40.0, boss.index);
    EmitGameSoundToAll(GSND_SECONDLIFE_EXPLODE, boss.index, _, SNDLEVEL_SCREAMING);
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
            continue;

        if (DistBetween(boss.index, i) <= 3000.0)
        {
            UTIL_ScreenFade(i, {255, 255, 255, 200}, 0.1, 0.1, FFADE_OUT);
        }
    }

    CreateTimer(3.0, Timer_Retreat, EntIndexToEntRef(boss.index), TIMER_FLAG_NO_MAPCHANGE);
	return action.Continue();
}

static void Timer_Retreat(Handle timer, int entity)
{
    RF2_Providence boss = RF2_Providence(EntRefToEntIndex(entity));
    if (!boss.IsValid() || !boss.IsRaidBoss())
        return;
    
    // Start retreating
    boss.ApproachEntity(boss.RaidBossSpawner);
}

static int Update(RF2_ProvidenceRetreatAction action, RF2_Providence boss, float interval)
{
    boss.DetermineSequence();
    if (boss.Locomotion.IsAttemptingToMove() && boss.Path.IsValid())
    {
        // Retreat to the spawner
        boss.ApproachEntity(boss.RaidBossSpawner);
        if (DistBetween(boss.index, boss.RaidBossSpawner) <= 70.0)
        {
            boss.Path.Invalidate();
            boss.Locomotion.Stop();
        }
    }

	return action.Continue();
}

static int OnCommandString(RF2_ProvidenceMainAction action, RF2_Providence boss, const char[] command)
{
    if (strcmp2(command, "final_phase"))
    {
        boss.Phase = ProvidencePhase_Crystals;
        boss.Health = boss.MaxHealth;
        boss.HealthText.TextSize = 35.0;
        boss.UpdateCrystalEffects();
        boss.SetGlow(true);
        boss.RemoveFlag(FL_NOTARGET);
        return action.TryChangeTo(RF2_ProvidenceMainAction(), RESULT_CRITICAL, "Entering final phase");
    }

    return action.TryContinue();
}
