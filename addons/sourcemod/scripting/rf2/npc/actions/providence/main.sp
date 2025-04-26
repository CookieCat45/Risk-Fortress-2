#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_Factory;

methodmap RF2_ProvidenceMainAction < NextBotAction
{
	public RF2_ProvidenceMainAction()
	{
		return view_as<RF2_ProvidenceMainAction>(g_Factory.Create());
	}

	public static NextBotActionFactory GetFactory()
	{
		if (!g_Factory)
		{
			g_Factory = new NextBotActionFactory("RF2_ProvidenceMainAction");
			g_Factory.SetCallback(NextBotActionCallbackType_Update, Update);
            g_Factory.SetEventCallback(EventResponderType_OnCommandString, OnCommandString);
		}
		
		return g_Factory;
	}
}

static int Update(RF2_ProvidenceMainAction action, RF2_Providence boss, float interval)
{
    boss.DetermineSequence();
    if (boss.Phase == ProvidencePhase_Intro)
    {
        // don't do anything yet
        return action.Continue();
    }

	if (!boss.IsTargetValid() || GetGameTime() >= boss.SwitchTargetTime)
	{
		boss.GetNewTarget(TargetMethod_ClosestNew, TargetType_NoMinions);
        boss.SwitchTargetTime = GetGameTime() + 12.0;
	}

    if (boss.IsTargetValid())
    {
        if (GetGameTime() >= boss.NextAttackTime && IsLOSClear(boss.index, boss.Target))
        {
            float dist = DistBetween(boss.index, boss.Target);
            if (dist <= 1750.0)
            {
                boss.Locomotion.Stop();
                ArrayList allowedAttacks = new ArrayList();
                allowedAttacks.Push(ProvidenceAttack_Projectile);
                allowedAttacks.Push(ProvidenceAttack_ExplosiveSlash);
                if (boss.CanDoSpinAttack())
                {
                    allowedAttacks.Clear(); // Always use spin when available
                    allowedAttacks.Push(ProvidenceAttack_SpinDash);
                }
                else if (boss.CanDoGroundStabAttack())
                {
                    allowedAttacks.Push(ProvidenceAttack_Shockwave);
                }

                boss.NextAttackTime = GetGameTime()+GetRandomFloat(1.25, 1.75); // attacks should add to this value automatically based on their length
                int attack = allowedAttacks.Get(GetRandomInt(0, allowedAttacks.Length-1));
                delete allowedAttacks;
                switch (attack)
                {
                    case ProvidenceAttack_Shockwave: return action.SuspendFor(RF2_ProvidenceShockwaveAttack(), "Create a huge shockwave");
                    case ProvidenceAttack_Projectile: return action.SuspendFor(RF2_ProvidenceProjectileAttack(), "Shooting fireballs");
                    case ProvidenceAttack_ExplosiveSlash: return action.SuspendFor(RF2_ProvidenceExplosiveSlashAttack(), "Kaboom!");
                    case ProvidenceAttack_SpinDash: return action.SuspendFor(RF2_ProvidenceSpinDashAttack(), "Spin to win");
                }
            }
            else
            {
                // Move closer until we're in range
                boss.ApproachEntity(boss.Target);
            }
        }
        else
        {
            boss.ApproachEntity(boss.Target);
        }
    }
    else if (boss.Locomotion.IsRunning())
    {
        boss.Locomotion.Stop();
    }

	return action.Continue();
}

static int OnCommandString(RF2_ProvidenceMainAction action, RF2_Providence boss, const char[] command)
{
    if (strcmp2(command, "endintro") && boss.Phase == ProvidencePhase_Intro)
    {
        EmitSoundToAll(SND_LASTMAN);
        boss.Phase = ProvidencePhase_Solo;
        boss.NextAttackTime = GetGameTime()+3.5;
        boss.HealthText = CreateHealthText(boss.index, 230.0, 35.0, "FALSE PROVIDENCE");
	    boss.HealthText.SetHealthColor(HEALTHCOLOR_HIGH, {65, 0, 100, 255});
        boss.SetGlow(true);
        boss.SetGlowColor(120, 0, 120, 255);
    }
    else if (strcmp2(command, "retreat_phase") && boss.Phase == ProvidencePhase_Solo)
    {
        // Retreat into second phase
        boss.RemoveAllGestures();
        return action.TryChangeTo(RF2_ProvidenceRetreatAction(), RESULT_CRITICAL, "Retreating because I'm damaged badly");
    }
    else if (strcmp2(command, "death") && boss.Phase == ProvidencePhase_Crystals)
    {
        boss.RemoveAllGestures();
        return action.TryChangeTo(RF2_ProvidenceDeathAction(), RESULT_CRITICAL, "I'm dead");
    }

    return action.TryContinue();
}
