#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_ActionFactory;

methodmap RF2_MajorShocksMainAction < NextBotAction
{
	public RF2_MajorShocksMainAction()
	{
		return view_as<RF2_MajorShocksMainAction>(g_ActionFactory.Create());
	}

	public static NextBotActionFactory GetFactory()
	{
		if (g_ActionFactory == null)
		{
			g_ActionFactory = new NextBotActionFactory("RF2_MajorShocksMain");
			g_ActionFactory.SetCallback(NextBotActionCallbackType_InitialContainedAction, InitialContainedAction);
			g_ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_ActionFactory.SetEventCallback(EventResponderType_OnAnimationEvent, OnAnimationEvent);
			g_ActionFactory.SetEventCallback(EventResponderType_OnLandOnGround, OnLandGround);
			g_ActionFactory.SetEventCallback(EventResponderType_OnKilled, OnKilled);
			g_ActionFactory.SetQueryCallback(ContextualQueryType_SelectTargetPoint, SelectTargetPoint);
			g_ActionFactory.BeginDataMapDesc()
				.DefineFloatField("m_LastStuckTime")
				.DefineVectorField("m_LastPos")
				.DefineVectorField("m_UnstuckPos")
				.EndDataMapDesc();
		}

		return g_ActionFactory;
	}

	property float LastStuckTime
	{
		public get()
		{
			return this.GetDataFloat("m_LastStuckTime");
		}

		public set(float value)
		{
			this.SetDataFloat("m_LastStuckTime", value);
		}
	}

	public void GetLastPos(float pos[3])
	{
		this.GetDataVector("m_LastPos", pos);
	}

	public void SetLastPos(const float pos[3])
	{
		this.SetDataVector("m_LastPos", pos);
	}

	public void GetUnstuckPos(float pos[3])
	{
		this.GetDataVector("m_UnstuckPos", pos);
	}

	public void SetUnstuckPos(const float pos[3])
	{
		this.SetDataVector("m_UnstuckPos", pos);
	}
}

static NextBotAction InitialContainedAction(RF2_MajorShocksMainAction action, RF2_MajorShocks actor)
{
	return RF2_MajorShocksChaseLayerAction();
}

static void OnStart(RF2_MajorShocksMainAction action, RF2_MajorShocks actor)
{
	float pos[3];
	actor.MyNextBotPointer().GetLocomotionInterface().GetFeet(pos);
	action.SetLastPos(pos);
	action.LastStuckTime = GetGameTime();
}

static int Update(RF2_MajorShocksMainAction action, RF2_MajorShocks actor, float interval)
{
	actor.UpdatePoseParameters();
	actor.UpdateAnimation();
	float gameTime = GetGameTime();
	PathFollower path = actor.Path;
	if (!actor.IsTargetValid() || gameTime >= actor.SwitchTargetTime)
	{
		actor.GetNewTarget(TargetMethod_ClosestNew, TargetType_NoMinions);
		actor.SwitchTargetTime = gameTime + 12.0;
	}
	
	CBaseNPC npc = actor.BaseNpc;
	float speed = npc.flRunSpeed, maxSpeed = 150.0;
	if (actor.WeaponState == MajorShocks_WeaponState_Melee)
	{
		speed = 300.0;
		maxSpeed = 300.0;
	}
	
	if (RF2_GetLoopCount() > 0 || g_cvDebugUseAltMapSettings.BoolValue)
	{
		if (speed < 250.0)
		{
			speed = 250.0;
			maxSpeed = 250.0;
		}
	}
	
	if (actor.Phase == MajorShocks_Phase_Uber)
	{
		speed = 60.0;
		maxSpeed = 60.0;
	}
	
	if (actor.ShouldSlowDown != actor.WasSlowedDown)
	{
		actor.UpdatedAnimation = false;
		actor.WasSlowedDown = actor.ShouldSlowDown;
	}

	if (actor.ShouldSlowDown)
	{
		speed = LerpFloats(speed, 0.0, interval * 5.0);
		if (speed <= 25.0)
		{
			actor.UpdatedAnimation = true;
			if (path.IsValid())
			{
				path.Invalidate();
			}
		}
	}
	else
	{
		speed = LerpFloats(speed, maxSpeed, interval * 5.0);
		if (speed > 25.0)
		{
			actor.UpdatedAnimation = true;
		}
	}
	
	npc.flRunSpeed = speed;
	npc.flWalkSpeed = speed * 0.9;
	//UnstuckCheck(action, actor);
	return action.Continue();
}

static void OnAnimationEvent(RF2_MajorShocksMainAction action, RF2_MajorShocks actor, int event)
{
	if (event == 7001 && actor.Locomotion.IsAttemptingToMove())
	{
		EmitGameSoundToAll(SND_MAJORSHOCKS_STEP, actor.index);
		float center[3];
		GetEntPos(actor.index, center, true);
		UTIL_ScreenShake(center, 10.0, 20.0, 0.8, 1000.0, SHAKE_START, true);
	}
}

static void OnLandGround(RF2_MajorShocksMainAction action, RF2_MajorShocks actor, int ground)
{
	actor.PlayLandAnimation();
}

static int OnKilled(RF2_MajorShocksMainAction action, RF2_MajorShocks actor, CBaseEntity attacker, CBaseEntity inflictor, float damage, int damageType, CBaseEntity weapon, const float damageForce[3], const float damagePosition[3], int damageCustom)
{
	return action.TryChangeTo(RF2_MajorShocksDeathAction(), RESULT_CRITICAL);
}

static void SelectTargetPoint(RF2_MajorShocksMainAction action, INextBot bot, int subject, float pos[3])
{
	if (!IsValidEntity(subject))
	{
		return;
	}

	RF2_MajorShocks actor = RF2_MajorShocks(bot.GetEntity());
	CBaseEntity entity = CBaseEntity(subject);
	float entAbsOrigin[3], myPos[3], entWorldSpace[3];
	actor.GetAbsOrigin(myPos);
	entity.GetAbsOrigin(entAbsOrigin);
	entity.WorldSpaceCenter(entWorldSpace);
	// For any non clients, just aim at their center and then stop
	if (!IsValidClient(subject))
	{
		float newPos[3];
		entity.WorldSpaceCenter(newPos);
		newPos[2] -= 10.0;
		pos = newPos;
		return;
	}

	const float aboveTolerance = 30.0;
	if (entAbsOrigin[2] - aboveTolerance > myPos[2])
	{
		if (IsLOSClear(actor.index, entity.index))
		{
			pos = entAbsOrigin;
			return;
		}

		GetClientEyePosition(subject, pos);
		return;
	}

	// Our target is on the ground, aim at the ground
	if (entity.GetPropEnt(Prop_Send, "m_hGroundEntity") != -1)
	{
		float checkPos[3];
		checkPos = entAbsOrigin;
		checkPos[2] -= 200.0;
		Handle trace = TR_TraceRayFilterEx(entAbsOrigin, checkPos, MASK_SOLID, RayType_EndPoint, TraceFilter_WallsOnly, subject);
		if (TR_DidHit(trace))
		{
			TR_GetEndPosition(pos, trace);
			delete trace;
			return;
		}

		delete trace;
	}

	const float rocketSpeed = 1100.0;
	float rangeBetween = bot.GetRangeToEx(entAbsOrigin);

	const float veryCloseRange = 150.0;
	if (rangeBetween > veryCloseRange)
	{
		float timeToTravel = rangeBetween / rocketSpeed;
		float targetPos[3], entAbsVelocity[3];
		targetPos = entAbsOrigin;
		targetPos[0] += timeToTravel;
		targetPos[1] += timeToTravel;
		targetPos[2] += timeToTravel;

		entity.GetAbsVelocity(entAbsVelocity);
		targetPos[0] *= entAbsVelocity[0];
		targetPos[1] *= entAbsVelocity[1];
		targetPos[2] *= entAbsVelocity[2];

		if (IsLOSClear(actor.index, entity.index))
		{
			pos = targetPos;
			return;
		}

		float eyePos[3];
		GetClientEyePosition(subject, eyePos);
		eyePos[0] += timeToTravel;
		eyePos[1] += timeToTravel;
		eyePos[2] += timeToTravel;

		eyePos[0] *= entAbsVelocity[0];
		eyePos[1] *= entAbsVelocity[1];
		eyePos[2] *= entAbsVelocity[2];

		pos = eyePos;
		return;
	}
}

/*
static bool NPCFindUnstuckPosition(RF2_MajorShocks boss, float lastPos[3], float destination[3])
{
	PathFollower path = boss.Path;
	CBaseNPC npc = TheNPCs.FindNPCByEntIndex(boss.index);
	CNavArea area = TheNavMesh.GetNearestNavArea(lastPos, _, _, _, false);
	area.GetCenter(destination);
	float mins[3], maxs[3], tempMaxs[3];
	boss.GetPropVector(Prop_Send, "m_vecMins", mins);
	boss.GetPropVector(Prop_Send, "m_vecMaxs", maxs);
	npc.GetBodyMaxs(tempMaxs);
	float traceMins[3];
	traceMins[0] = mins[0] - 5.0;
	traceMins[1] = mins[1] - 5.0;
	traceMins[2] = 0.0;

	float traceMaxs[3];
	traceMaxs[0] = maxs[0] + 5.0;
	traceMaxs[1] = maxs[1] + 5.0;
	traceMaxs[2] = tempMaxs[2];
	TR_TraceHullFilter(destination, destination, traceMins, traceMaxs, MASK_NPCSOLID, TraceFilter_DontHitSelf);
	if (GetVectorDistance(destination, lastPos, true) <= 16.0 * 16.0 || TR_DidHit())
	{
		SurroundingAreasCollector collector = TheNavMesh.CollectSurroundingAreas(area, 400.0);
		int areaCount = collector.Count();
		ArrayList areaArray = new ArrayList(1, areaCount);
		int validAreaCount = 0;
		for (int i = 0; i < areaCount; i++)
		{
			areaArray.Set(validAreaCount, i);
			validAreaCount++;
		}

		int randomArea = 0, randomCell = 0;
		areaArray.Resize(validAreaCount);
		area = NULL_AREA;
		while (validAreaCount > 1)
		{
			randomCell = GetRandomInt(0, validAreaCount - 1);
			randomArea = areaArray.Get(randomCell);
			area = collector.Get(randomArea);
			area.GetCenter(destination);

			TR_TraceHullFilter(destination, destination, traceMins, traceMaxs, MASK_NPCSOLID, TraceFilter_DontHitSelf);
			if (TR_DidHit())
			{
				area = NULL_AREA;
				validAreaCount--;
				int findValue = areaArray.FindValue(randomCell);
				if (findValue != -1)
				{
					areaArray.Erase(findValue);
				}
			}
			else
			{
				break;
			}
		}

		delete collector;
		delete areaArray;
	}
	path.GetClosestPosition(destination, destination, path.FirstSegment(), 400.0);
	if (GetVectorDistance(destination, lastPos, true) > 8.0 * 8.0)
	{
		return true;
	}

	Segment first = path.FirstSegment();
	if (first != NULL_PATH_SEGMENT)
	{
		int attempts = 0;
		Segment next = NULL_PATH_SEGMENT;
		while (attempts <= 2)
		{
			next = path.NextSegment(first);
			if (next == NULL_PATH_SEGMENT)
			{
				break;
			}
			float segmentPos[3], temp[3];
			next.GetPos(segmentPos);
			path.GetClosestPosition(segmentPos, temp, next, 800.0);
			if (GetVectorDistance(temp, lastPos, true) > 64.0 * 64.0)
			{
				destination = temp;
				return true;
			}
			first = next;
			attempts++;
		}
	}

	ArrayList spawnPointList = new ArrayList();
	int ent = -1;

	while ((ent = FindEntityByClassname(ent, "rf2_raid_boss_spawner")) != -1)
	{
		char class[64];
		GetEntPropString(ent, Prop_Data, "m_szBossClassname", class, sizeof(class));
		if (!StrContains(class, "rf2_npc_major_shocks", false))
		{
			spawnPointList.Push(ent);
		}
	}

	if (spawnPointList.Length > 0)
	{
		ent = spawnPointList.Get(GetRandomInt(0, spawnPointList.Length - 1));
	}

	delete spawnPointList;

	if (!IsValidEntity(ent))
	{
		return false;
	}

	CBaseEntity(ent).GetAbsOrigin(destination);
	return true;
}


static void UnstuckCheck(RF2_MajorShocksMainAction action, RF2_MajorShocks actor)
{
	INextBot bot = actor.MyNextBotPointer();
	ILocomotion loco = bot.GetLocomotionInterface();
	PathFollower path = actor.Path;
	float gameTime = GetGameTime();
	float goalPos[3], myPos[3];
	if (path.IsValid())
	{
		path.GetEndPosition(goalPos);
	}
	
	actor.GetAbsOrigin(myPos);
	if (!path.IsValid() || !actor.Locomotion.IsAttemptingToMove() || loco.GetDesiredSpeed() <= 0.0 || (path.IsValid() && GetVectorDistance(myPos, goalPos, true) <= Pow(16.0, 2.0)))
	{
		action.LastStuckTime = gameTime;
		return;
	}

	float lastPos[3];
	action.GetLastPos(lastPos);
	if (bot.IsRangeLessThanEx(lastPos, 0.13) || loco.GetGroundSpeed() <= 0.1)
	{
		if (action.LastStuckTime > gameTime - 0.75)
		{
			return;
		}
		
		float destination[3];
		NPCFindUnstuckPosition(actor, lastPos, destination);
		action.LastStuckTime = gameTime + 0.75;
		actor.Teleport(destination, NULL_VECTOR, NULL_VECTOR);
	}
	else
	{
		loco.GetFeet(lastPos);
		action.SetLastPos(lastPos);
		action.LastStuckTime += 0.03;
		if (action.LastStuckTime > gameTime)
		{
			action.LastStuckTime = gameTime;
		}
	}
}
*/