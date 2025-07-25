#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_ActionFactory;

methodmap RF2_SentryBusterMainAction < NextBotAction
{
	public static NextBotActionFactory GetFactory()
	{
		if (!g_ActionFactory)
		{
			g_ActionFactory = new NextBotActionFactory("RF2_SentryBusterMain");
			g_ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_ActionFactory.SetEventCallback(EventResponderType_OnKilled, OnKilled);
			g_ActionFactory.BeginDataMapDesc()
				.DefineFloatField("m_Talker")
				.EndDataMapDesc();
		}

		return g_ActionFactory;
	}

	property float TalkerTime
	{
		public get()
		{
			return this.GetDataFloat("m_Talker");
		}
		public set(float value)
		{
			this.SetDataFloat("m_Talker", value);
		}
	}
}

static int OnStart(RF2_SentryBusterMainAction action, RF2_SentryBuster actor, NextBotAction prevAction)
{
	action.TalkerTime = GetGameTime() + 4.0;
	return action.Continue();
}

static int Update(RF2_SentryBusterMainAction action, RF2_SentryBuster actor, float interval)
{
	float worldSpace[3], pos[3];
	actor.GetAbsOrigin(pos);
	actor.WorldSpaceCenter(worldSpace);
	int target = actor.Target;
	if (actor.Team == TEAM_SURVIVOR)
	{
		if (!IsValidEntity2(target) || IsValidClient(target) && !IsPlayerAlive(target) || GetEntTeam(target) == TEAM_SURVIVOR)
		{
			int newTarget = GetNearestEntity(worldSpace, "player", 0.0, 1200.0, TEAM_ENEMY);
			if (IsValidEntity2(newTarget))
			{
				actor.Target = newTarget;
			}
			else
			{
				newTarget = GetNearestEntity(worldSpace, "rf2_npc*", 0.0, 1200.0, TEAM_ENEMY);
				if (IsValidEntity2(newTarget))
				{
					actor.Target = newTarget;
				}
			}
		}
		
		if (!IsValidEntity2(actor.Target) || IsValidClient(actor.Target) && !IsPlayerAlive(actor.Target))
		{
			int owner = GetEntPropEnt(actor, Prop_Data, "m_hOwnerEntity");
			if (IsValidEntity2(owner))
			{
				actor.Target = owner;
			}
		}
		
		target = actor.Target;
	}
	else if (!IsValidEntity2(target))
	{
		// target the Engineer's dispenser instead, if available
		if (IsValidEntity2(actor.Dispenser))
		{
			actor.Target = actor.Dispenser;
		}
		else
		{
			actor.Target = GetNearestEntity(worldSpace, "obj_sentrygun", _, _, TEAM_SURVIVOR);
			if (!IsValidEntity2(target))
			{
				actor.Target = GetNearestEntity(worldSpace, "obj_dispenser", _, _, TEAM_SURVIVOR);
				if (!IsValidEntity2(target))
				{
					return action.ChangeTo(RF2_SentryBusterDetonateAction(), "No sentry what?");
				}
			}
		}
		
		target = actor.Target;
		if (IsValidEntity2(target))
		{
			int builder = GetEntPropEnt(target, Prop_Send, "m_hBuilder");
			if (IsValidClient(builder))
			{
				ShowAnnotation(builder, _, "Sentry Buster's Target", 8.0, target, target);
			}
		}
	}
	
	if (!IsValidEntity2(target))
	{
		return action.Continue();
	}
	
	CBaseNPC npc = TheNPCs.FindNPCByEntIndex(actor.index);
	NextBotGroundLocomotion loco = npc.GetLocomotion();
	float targetPos[3];
	if (IsBuilding(target) && GetEntProp(target, Prop_Send, "m_bCarried"))
	{
		int owner = GetEntPropEnt(target, Prop_Send, "m_hBuilder");
		if (IsValidEntity2(owner))
		{
			target = owner;
		}
	}
	
	GetEntPos(target, targetPos);
	if (actor.Team != TEAM_SURVIVOR || GetEntTeam(target) != TEAM_SURVIVOR)
	{
		IVision vision = actor.MyNextBotPointer().GetVisionInterface();
		if (GetVectorDistance(pos, targetPos, true) <= Pow(g_cvSuicideBombRange.FloatValue / 3.0, 2.0) 
			&& vision.IsLineOfSightClearToEntity(target) && actor.LastUnstuckTime+1.0 < GetGameTime())
		{
			return action.ChangeTo(RF2_SentryBusterDetonateAction(), "KABOOM");
		}
	}
	
	INextBot bot = actor.MyNextBotPointer();
	PathFollower path = actor.Path;
	path.ComputeToPos(bot, targetPos);
	path.Update(bot);
	loco.Run();
	bool jumping = loco.IsClimbingOrJumping();
	if (!jumping)
	{
		actor.BaseNpc.flGravity = 800.0;
	}
	
	if (actor.Team != TEAM_SURVIVOR)
	{
		if (loco.GetGroundSpeed() <= 85.0 && DistBetween(actor.index, target) <= g_cvSuicideBombRange.FloatValue || loco.IsStuck())
		{
			int attempts = actor.RepathAttempts;
			if (attempts >= 60)
			{
				return action.ChangeTo(RF2_SentryBusterDetonateAction(), "Fuck we're stuck!");
			}
			else if (attempts >= 20 && !jumping)
			{
				loco.Jump();
				actor.BaseNpc.flGravity = 400.0;
				actor.RepathAttempts += 30;
			}
			else if (attempts < 20)
			{
				actor.RepathAttempts++;
			}
		}
		else
		{
			actor.RepathAttempts = 0;
		}
	}
	
	if (action.TalkerTime < GetGameTime() && actor.Team != TEAM_SURVIVOR)
	{
		action.TalkerTime = GetGameTime() + 4.0;
		EmitGameSoundToAll("MVM.SentryBusterIntro", actor.index);
	}
	
	bool onGround = (actor.GetFlags() & FL_ONGROUND) != 0;
	float speed = loco.GetGroundSpeed();
	
	int sequence = actor.GetProp(Prop_Send, "m_nSequence");

	if (speed < 0.01)
	{
		int idleSequence = actor.GetProp(Prop_Data, "m_idleSequence");
		if (idleSequence != -1 && sequence != idleSequence)
		{
			actor.ResetSequence(idleSequence);
		}
	}
	else
	{
		int runSequence = actor.GetProp(Prop_Data, "m_runSequence");
		int airSequence = actor.GetProp(Prop_Data, "m_airSequence");

		if (!onGround && !jumping)
		{
			if (airSequence != -1 && sequence != airSequence)
			{
				actor.ResetSequence(airSequence);
			}
		}
		else
		{
			if (runSequence != -1 && sequence != runSequence)
			{
				actor.ResetSequence(runSequence);
			}
			
			float fwd[3], right[3];
			actor.GetVectors(fwd, right, NULL_VECTOR);
			
			float motion[3];
			loco.GetGroundMotionVector(motion);
			
			actor.SetPoseParameter(actor.GetProp(Prop_Data, "m_moveXPoseParameter"), GetVectorDotProduct(motion, fwd));
			actor.SetPoseParameter(actor.GetProp(Prop_Data, "m_moveYPoseParameter"), GetVectorDotProduct(motion, right));
		}
	}
	
	return action.Continue();
}

static int OnKilled(RF2_SentryBusterMainAction action, RF2_SentryBuster actor, CBaseEntity attacker, CBaseEntity inflictor,
	float damage, int damageType, CBaseEntity weapon, const float damageForce[3], const float damagePosition[3], int damageCustom)
{
	return action.TryChangeTo(RF2_SentryBusterDetonateAction(), RESULT_CRITICAL);
}