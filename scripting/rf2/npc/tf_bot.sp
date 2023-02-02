#if defined _RF2_tfbot_included
 #endinput
#endif
#define _RF2_tfbot_included

#pragma semicolon 1
#pragma newdecls required

static PathFollower g_TFBotPathFollower[MAXTF2PLAYERS];
static CNavArea g_TFBotGoalArea[MAXTF2PLAYERS];

static int g_iTFBotFlags[MAXTF2PLAYERS];
static int g_iTFBotForcedButtons[MAXTF2PLAYERS];

static float g_flTFBotMinReloadTime[MAXTF2PLAYERS];
static float g_flTFBotReloadTimeStamp[MAXTF2PLAYERS];
static float g_flTFBotStrafeTime[MAXTF2PLAYERS];
static float g_flTFBotStrafeTimeStamp[MAXTF2PLAYERS];
static float g_flTFBotStuckTime[MAXTF2PLAYERS];
static float g_flTFBotLastSearchTime[MAXTF2PLAYERS];
static float g_flTFBotLastPosCheckTime[MAXTF2PLAYERS];

static CNavArea g_TFBotEngineerSentryArea[MAXTF2PLAYERS];
static float g_flTFBotEngineerSearchRetryTime[MAXTF2PLAYERS];
static bool g_bTFBotEngineerHasBuilt[MAXTF2PLAYERS];
static bool g_bTFBotEngineerIsBuilding[MAXTF2PLAYERS];

static float g_flTFBotLastPos[MAXTF2PLAYERS][3];

enum TFBotMission
{
	MISSION_NONE,
	MISSION_TELEPORTER,
	MISSION_BUILD,
	MISSION_WANDER,
	MISSION_CHASE,
};
static TFBotMission g_TFBotMissionType[MAXTF2PLAYERS];

enum TFBotStrafeDir
{
	Strafe_Left,
	Strafe_Right,
};
static TFBotStrafeDir g_TFBotStrafeDirection[MAXTF2PLAYERS];

methodmap TFBot < Handle
{
	public TFBot(int client) 
	{
		return view_as<TFBot>(client);
	}
	property int Client 
	{
		public get() 
			return view_as<int>(this);
	}
	
	// Pathing
	property PathFollower Follower
	{
		public get() 				{ return g_TFBotPathFollower[this.Client]; }
		public set(PathFollower pf) { g_TFBotPathFollower[this.Client] = pf;   }
	}
	property CNavArea GoalArea 
	{
		public get() 				{ return g_TFBotGoalArea[this.Client]; }
		public set(CNavArea area) 	{ g_TFBotGoalArea[this.Client] = area; }
	}
	
	// Behavior
	property TFBotMission Mission
	{
		public get() 					{ return g_TFBotMissionType[this.Client];  }
		public set(TFBotMission value) 	{ g_TFBotMissionType[this.Client] = value; }
	}
	
	property int Flags
	{
		public get() 			{ return g_iTFBotFlags[this.Client];  }
		public set(int value) 	{ g_iTFBotFlags[this.Client] = value; }
	}
	
	property int ForcedButtons
	{
		public get() 			{ return g_iTFBotForcedButtons[this.Client];  }
		public set(int value) 	{ g_iTFBotForcedButtons[this.Client] = value; }
	}
	
	property float MinReloadTime 
	{
		public get() 			{ return g_flTFBotMinReloadTime[this.Client];  }
		public set(float value) { g_flTFBotMinReloadTime[this.Client] = value; }
	}
	
	property float ReloadTimeStamp 
	{
		public get() 			{ return g_flTFBotReloadTimeStamp[this.Client];  }
		public set(float value) { g_flTFBotReloadTimeStamp[this.Client] = value; }
	}
	
	property float StrafeTime 
	{
		public get() 			{ return g_flTFBotStrafeTime[this.Client];  }
		public set(float value) { g_flTFBotStrafeTime[this.Client] = value; }
	}
	
	property float StrafeTimeStamp
	{
		public get() 			{ return g_flTFBotStrafeTimeStamp[this.Client];  }
		public set(float value) { g_flTFBotStrafeTimeStamp[this.Client] = value; }
	}
	
	property float StuckTime 
	{
		public get() 			{ return g_flTFBotStuckTime[this.Client];  }
		public set(float value) { g_flTFBotStuckTime[this.Client] = value; }
	}
	
	property TFBotStrafeDir StrafeDirection 
	{
		public get() 					 { return g_TFBotStrafeDirection[this.Client];  }
		public set(TFBotStrafeDir value) { g_TFBotStrafeDirection[this.Client] = value; }
	}
	
	// Wandering
	property float LastSearchTime 
	{
		public get() 			{ return g_flTFBotLastSearchTime[this.Client];  }
		public set(float value) { g_flTFBotLastSearchTime[this.Client] = value; }
	}
	
	property float LastPosCheckTime 
	{
		public get() 			{ return g_flTFBotLastPosCheckTime[this.Client];  }
		public set(float value) { g_flTFBotLastPosCheckTime[this.Client] = value; }
	}
	
	// Engineer
	property CNavArea SentryArea
	{
		public get() 			  { return g_TFBotEngineerSentryArea[this.Client]; }
		public set(CNavArea area) { g_TFBotEngineerSentryArea[this.Client] = area; }
	}
	
	property float EngiSearchRetryTime
	{
		public get() 			{ return g_flTFBotEngineerSearchRetryTime[this.Client];  }
		public set(float value) { g_flTFBotEngineerSearchRetryTime[this.Client] = value; }
	}
	
	property bool HasBuilt
	{
		public get() 			{ return g_bTFBotEngineerHasBuilt[this.Client];  }
		public set(bool value) 	{ g_bTFBotEngineerHasBuilt[this.Client] = value; }
	}
	
	property bool IsBuilding
	{
		public get() 			{ return g_bTFBotEngineerIsBuilding[this.Client];  }
		public set(bool value) 	{ g_bTFBotEngineerIsBuilding[this.Client] = value; }
	}
	
	// NextBot
	public INextBot GetNextBot() 
	{
		return CBaseEntity(this.Client).MyNextBotPointer();
	}
	
	public IVision GetVision()
	{
		return this.GetNextBot().GetVisionInterface();
	}
	
	public ILocomotion GetLocomotion()
	{
		return this.GetNextBot().GetLocomotionInterface();
	}
	
	public CKnownEntity GetTarget(bool onlyVisible=true)
	{
		return this.GetVision().GetPrimaryKnownThreat(onlyVisible);
	}
	
	// Flags
	public void AddFlag(int flags)
	{
		this.Flags|flags;
	}
	
	public void RemoveFlag(int flags)
	{
		this.Flags &= ~flags;
	}
	
	public bool HasFlag(int flags)
	{
		return this.Flags & flags != 0;
	}
	
	public void AddButtonFlag(int flags)
	{
		this.ForcedButtons|flags;
	}
	
	public void RemoveButtonFlag(int flags)
	{
		this.ForcedButtons &= ~flags;
	}
	
	public bool HasButtonFlag(int flags)
	{
		return this.ForcedButtons & flags != 0;
	}
	
	public TFBotStrafeDir DecideStrafeDirection()
	{
		this.StrafeDirection = view_as<TFBotStrafeDir>(GetRandomInt(0, 1));
		return this.StrafeDirection;
	}
	
	public int GetSkillLevel()
	{
		return GetEntProp(this.Client, Prop_Send, "m_nBotSkill");
	}
	public void SetSkillLevel(int level)
	{
		SetEntProp(this.Client, Prop_Send, "m_nBotSkill", level);
	}
	
	public void GetMyPos(float buffer[3])
	{
		GetClientAbsOrigin(this.Client, buffer);
	}
	
	public void GetLastWanderPos(float buffer[3]) 
	{
		CopyVectors(g_flTFBotLastPos[this.Client], buffer);
	}
	
	public void SetLastWanderPos(float buffer[3]) 
	{
		CopyVectors(buffer, g_flTFBotLastPos[this.Client]);
	}
}

void TFBot_Think(TFBot bot)
{
	float tickedTime = GetTickedTime();
	//bool survivor = IsPlayerSurvivor(bot.Client);
	
	if (bot.MinReloadTime > 0.0)
	{
		int activeWeapon = GetEntPropEnt(bot.Client, Prop_Send, "m_hActiveWeapon");
		if (activeWeapon != -1 && activeWeapon == GetPlayerWeaponSlot(bot.Client, WeaponSlot_Primary) || activeWeapon == GetPlayerWeaponSlot(bot.Client, WeaponSlot_Secondary))
		{
			if (!bot.HasButtonFlag(IN_RELOAD) && GetEntProp(activeWeapon, Prop_Send, "m_iClip1") == 0)
			{
				bot.AddButtonFlag(IN_RELOAD);
				bot.ReloadTimeStamp = tickedTime;
			}
			else if (tickedTime >= bot.ReloadTimeStamp + bot.MinReloadTime || GetEntProp(activeWeapon, Prop_Send, "m_iClip1") == SDK_GetWeaponClipSize(activeWeapon))
			{
				bot.RemoveButtonFlag(IN_RELOAD);
			}
		}
	}
	
	ILocomotion locomotion = bot.GetLocomotion();
	CKnownEntity known = bot.GetTarget();
	
	int threat = -1;
	if (known != NULL_KNOWN_ENTITY)
		threat = known.GetEntity();
		
	float botPos[3];
	bot.GetMyPos(botPos);
	
	bool aggressiveMode;
	if (threat > 0 && bot.Mission != MISSION_TELEPORTER)
	{
		TFClassType class = TF2_GetPlayerClass(bot.Client);
		aggressiveMode = bot.HasFlag(TFBOTFLAG_AGGRESSIVE) || GetEntPropEnt(bot.Client, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(bot.Client, WeaponSlot_Melee);
		
		// Aggressive AI, relentlessly pursues target and strafes on higher difficulties. Mostly for melee.
		if (aggressiveMode)
		{
			if (threat > MaxClients || !IsInvuln(threat) && class != TFClass_Engineer && class != TFClass_Spy)
			{
				float threatPos[3];
				GetEntPropVector(threat, Prop_Data, "m_vecAbsOrigin", threatPos);
				
				int skill = bot.GetSkillLevel();
				if (threat <= MaxClients && skill >= TFBotDifficulty_Hard)
				{
					float angles[3];
					float direction[3];
					
					GetVectorAnglesTwoPoints(botPos, threatPos, angles);
					angles[0] = 0.0;
					GetAngleVectors(angles, NULL_VECTOR, direction, NULL_VECTOR);
					NormalizeVector(direction, direction);
					
					if (!bot.HasFlag(TFBOTFLAG_STRAFING)) // Do not change direction if we are already strafing
					{
						if (bot.DecideStrafeDirection() == Strafe_Left)
						{
							threatPos[0] += direction[0] * 120.0;
							threatPos[1] += direction[1] * 120.0;
							threatPos[2] += direction[2] * 120.0;
						}
						else
						{
							threatPos[0] += direction[0] * -120.0;
							threatPos[1] += direction[1] * -120.0;
							threatPos[2] += direction[2] * -120.0;
						}
					}
					
					// Don't bother if we can't "access" that area, we're most likely in a closed space such as a hallway.
					if (TR_PointOutsideWorld(threatPos) || TR_GetPointContents(threatPos) & MASK_PLAYERSOLID)
						GetEntPropVector(threat, Prop_Data, "m_vecAbsOrigin", threatPos);
					
					if (!bot.HasFlag(TFBOTFLAG_STRAFING))
					{
						// Expert bots strafe more often.
						if (skill >= TFBotDifficulty_Expert)
						{
							bot.StrafeTime = GetRandomFloat(0.8, 1.35);
						}
						else
						{
							bot.StrafeTime = GetRandomFloat(1.25, 1.75);
						}
						
						bot.StrafeTimeStamp = tickedTime;
						bot.AddFlag(TFBOTFLAG_STRAFING);
					}
					else if (bot.StrafeTimeStamp + bot.StrafeTime >= tickedTime)
					{
						bot.RemoveFlag(TFBOTFLAG_STRAFING);
					}
				}
				
				bot.Mission = MISSION_CHASE;
				TFBot_PathToPos(bot, threatPos, 3000.0, true);
			}
		}
	}
	else if (TF2_GetPlayerClass(bot.Client) == TFClass_Engineer)
	{
		if (!bot.HasBuilt && tickedTime >= bot.EngiSearchRetryTime && !bot.SentryArea)
		{
			bot.EngiSearchRetryTime = -1.0;
			
			float navPos[3];
			CopyVectors(botPos, navPos);
			navPos[2] += 30.0;
			CNavArea area = TheNavMesh.GetNearestNavArea(navPos, true, 1000.0, false, true);
			CTFNavArea tfArea;
			
			SurroundingAreasCollector collector = TheNavMesh.CollectSurroundingAreas(area, 10000.0);
			int areaCount = collector.Count();
			for (int i = 0; i < areaCount; i++)
			{
				tfArea = view_as<CTFNavArea>(collector.Get(i));
				
				if (tfArea.HasAttributeTF(SENTRY_SPOT))
				{
					// Does another bot own this area?
					bool owned;
					for (int b = 1; b <= MaxClients; b++)
					{
						if (owned || !g_bPlayerInGame[b] || !IsFakeClientEx(b) || TF2_GetPlayerClass(b) != TFClass_Engineer)
							continue;
							
						if (g_TFBot[b].SentryArea == tfArea)
							owned = true;
					}
					
					if (!owned) // No one owns this area, we can take it.
					{	
						bot.Mission = MISSION_BUILD;
						float areaPos[3];
						bot.SentryArea = tfArea;
						bot.SentryArea.GetCenter(areaPos);
						TFBot_PathToPos(bot, areaPos, 10000.0); // Start marching towards our desired area now

						break;
					}
				}
			}
			
			// We failed to find an area, wander around and try again after a while.
			if (!bot.SentryArea)
			{
				bot.EngiSearchRetryTime = tickedTime+10.0;
			}
			
			delete collector;
		}
		else if (bot.SentryArea && bot.Follower.IsValid() && !bot.IsBuilding)
		{
			float areaPos[3];
			bot.SentryArea.GetCenter(areaPos);
			if (GetVectorDistance(areaPos, botPos, true) <= sq(50.0))
			{
				// Try and build at this spot.
				TFBotEngi_AttemptBuild(bot);
			}
			else
			{
				// Not close enough, keep going.
				TFBot_PathToPos(bot, areaPos, 10000.0);
			}
		}
		else if (!bot.IsBuilding && !bot.HasBuilt)
		{
			// Find a new area.
			bot.SentryArea = view_as<CTFNavArea>(NULL_AREA);
		}
	}
	
	// bots suck at swimming normally, this will make them tread water
	if (!aggressiveMode && GetEntProp(bot.Client, Prop_Send, "m_nWaterLevel") > 1)
	{
		bot.AddButtonFlag(IN_JUMP);
	}
	else
	{
		bot.RemoveButtonFlag(IN_JUMP);
	}
	
	if (GetTeleporterEventState() == TELE_EVENT_ACTIVE)
	{
		float teleporterPos[3];
		int teleporter = GetTeleporterEntity();
		GetEntPropVector(teleporter, Prop_Data, "m_vecAbsOrigin", teleporterPos);
		CNavArea area = TheNavMesh.GetNearestNavArea(teleporterPos, true, 800.0, false, false);
		area.GetCenter(teleporterPos);
		
		// stick close to the teleporter
		float radius = GetEntPropFloat(teleporter, Prop_Data, "m_flRadius");
		bool tooFar = GetVectorDistance(botPos, teleporterPos, true) > sq(radius);
		
		if (tooFar)
		{
			bot.Mission = MISSION_TELEPORTER;
			TFBot_PathToPos(bot, teleporterPos, 99999.0, true);
		}
		else if (bot.Mission == MISSION_TELEPORTER)
		{
			bot.Mission = MISSION_NONE;
			bot.Follower.Invalidate();
			bot.GetLocomotion().Stop();
		}
	}
	
	// Only for bosses for now, as they are large.
	if (GetPlayerBossType(bot.Client) >= 0)
	{
		if (locomotion.IsAttemptingToMove() && locomotion.IsStuck())
		{
			bot.StuckTime += GetTickInterval();
		}
		else
		{
			bot.StuckTime -= GetTickInterval() * 2.0;
			if (bot.StuckTime < 0.0 || !locomotion.IsStuck())
			{
				bot.StuckTime = 0.0;
			}
		}
		
		// Crouch if we're stuck
		if (bot.StuckTime > 2.0 && GetEntityFlags(bot.Client) & FL_ONGROUND)
		{
			bot.AddButtonFlag(IN_DUCK);
		}
		else if (bot.StuckTime <= 0.0)
		{
			bot.RemoveButtonFlag(IN_DUCK);
		}
	}
	
	// should we use our strange item?
	if (TFBot_ShouldUseEquipmentItem(bot))
	{
		ActivateStrangeItem(bot.Client);
	}
	
	// If we aren't doing anything else, wander the map looking for players to attack.
	if (bot.Mission != MISSION_TELEPORTER && threat <= 0 && (TF2_GetPlayerClass(bot.Client) != TFClass_Engineer || bot.EngiSearchRetryTime > 0.0) 
	&& !bot.IsBuilding && !bot.HasBuilt)
	{
		TFBot_WanderMap(bot);
	}
}
	
bool TFBot_ShouldUseEquipmentItem(TFBot bot)
{
	int item = GetPlayerEquipmentItem(bot.Client);
	if (item > Item_Null && g_iPlayerEquipmentItemCharges[bot.Client] > 0)
	{
		IVision vision = CBaseEntity(bot.Client).MyNextBotPointer().GetVisionInterface();
		CKnownEntity known = vision.GetPrimaryKnownThreat(true);
		
		int threat = -1;
		
		if (known != NULL_KNOWN_ENTITY)
			threat = known.GetEntity();
		
		bool invuln;
		if (threat > 0 && threat <= MaxClients)
		{
			invuln = IsInvuln(threat);
		}
		
		switch (item)
		{
			case ItemStrange_VirtualViewfinder, ItemStrange_SpellbookMagazine: return threat > 0 && vision.IsLookingAtTarget(threat) && !invuln;
			
			case ItemStrange_RoBro: return threat > 0 && GetClientHealth(bot.Client) < RF2_GetCalculatedMaxHealth(bot.Client) / 2;
		}
	}
	
	return false;
}
	
void TFBot_WanderMap(TFBot bot)
{
	float myPos[3], areaPos[3], goalPos[3], lastPos[3];
	float tickedTime = GetTickedTime();
	bot.GetMyPos(myPos);
	
	if (bot.GoalArea)
	{
		bot.GoalArea.GetCenter(areaPos);
		bool stuck;
		
		if (tickedTime >= bot.LastPosCheckTime+5.0)
		{
			bot.GetLastWanderPos(lastPos);
			
			if (GetVectorDistance(myPos, lastPos, true) <= sq(g_cvBotWanderRecomputeDist.FloatValue))
			{
				stuck = true;
			}
			
			bot.LastPosCheckTime = tickedTime;
			bot.SetLastWanderPos(myPos);
		}
		
		if (stuck || tickedTime >= bot.LastSearchTime + g_cvBotWanderTime.FloatValue || !bot.Follower.IsValid() 
		|| GetVectorDistance(myPos, areaPos, true) <= sq(g_cvBotWanderRecomputeDist.FloatValue))
		{
			bot.GoalArea = NULL_AREA;
			bot.Follower.Invalidate();
		}
		else // continue on our path
		{
			TFBot_PathToPos(bot, areaPos, g_cvBotWanderMaxDist.FloatValue, true);
		}
	}
	else
	{
		CNavArea area = CBaseCombatCharacter(bot.Client).GetLastKnownArea();
		
		if (area)
		{
			SurroundingAreasCollector collector = TheNavMesh.CollectSurroundingAreas(area, g_cvBotWanderMaxDist.FloatValue, 100.0);
			ArrayList areaArray = CreateArray();
			float cost, radius;
			int teleporter = -1;
			float telePos[3];
			bool event = GetTeleporterEventState() != TELE_EVENT_INACTIVE;
			
			if (event)
			{
				teleporter = GetTeleporterEntity();
				GetEntPropVector(teleporter, Prop_Data, "m_vecAbsOrigin", telePos);
				radius = GetEntPropFloat(teleporter, Prop_Data, "m_flRadius");
			}
			
			for (int i = 0; i < collector.Count(); i++)
			{
				cost = collector.Get(i).GetCostSoFar();
				if (cost >= g_cvBotWanderMinDist.FloatValue)
				{
					if (event)
					{
						collector.Get(i).GetCenter(areaPos);
						if (GetVectorDistance(areaPos, telePos, true) >= sq(radius))
						{
							continue;
						}
					}
					
					areaArray.Push(i);
				}
			}
			
			if (areaArray.Length > 0)
			{
				bot.GoalArea = collector.Get(areaArray.Get(GetRandomInt(0, areaArray.Length-1)));
				bot.GoalArea.GetCenter(goalPos);
				TFBot_PathToPos(bot, goalPos, g_cvBotWanderMaxDist.FloatValue, true);
				
				bot.Mission = MISSION_WANDER;
				bot.SetLastWanderPos(myPos);
				bot.LastSearchTime = tickedTime;
				bot.LastPosCheckTime = tickedTime;
			}
			
			delete collector;
			delete areaArray;
		}
	}
}

void TFBot_PathToPos(TFBot bot, float pos[3], float distance=1000.0, bool ignoreGoal=false)
{
	ILocomotion locomotion = bot.GetLocomotion();
	INextBot nextBot = bot.GetNextBot();
	bool goalReached = bot.Follower.ComputeToPos(nextBot, pos, distance);
	
	if ((goalReached || ignoreGoal) && bot.Follower.IsValid())
	{
		bot.Follower.Update(nextBot);
		locomotion.Run();
	}
	else
	{
		bot.Follower.Invalidate();
		locomotion.Stop();
	}
}

void TFBotEngi_AttemptBuild(TFBot bot)
{
	bot.IsBuilding = true;
	
	// Sentry first.
	TFBotEngi_BuildObject(bot, TFObject_Sentry);
	
	// Dispenser. Delay the rest of our actions by a bit.
	CreateTimer(1.5, Timer_TFBotBuildDispenser, GetClientUserId(bot.Client), TIMER_FLAG_NO_MAPCHANGE);
	
	// Teleporter exit.
	CreateTimer(3.0, Timer_TFBotBuildTeleporterExit, GetClientUserId(bot.Client), TIMER_FLAG_NO_MAPCHANGE);
	
	CreateTimer(5.0, Timer_TFBotFinishBuilding, GetClientUserId(bot.Client), TIMER_FLAG_NO_MAPCHANGE);
}

void TFBotEngi_BuildObject(TFBot bot, TFObjectType type, TFObjectMode mode=TFObjectMode_Entrance, float yawOffset=0.0)
{
	char command[32];
	switch (type)
	{
		case TFObject_Sentry: command = "build 2";
		case TFObject_Dispenser: command = "build 0";
		case TFObject_Teleporter:
		{
			if (mode == TFObjectMode_Entrance)
			{
				command = "build 1 0";
			}
			else
			{
				command = "build 1 1";
			}
		}
	}
	
	FakeClientCommand(bot.Client, command);
	bot.Follower.Invalidate();
	bot.GetLocomotion().Stop();
	bot.AddButtonFlag(IN_DUCK);
	
	DataPack pack;
	const float delay = 0.5;
	CreateDataTimer(delay, Timer_TFBotBuildObject, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(GetClientUserId(bot.Client));
	pack.WriteFloat(yawOffset);
}

public Action Timer_TFBotBuildDispenser(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
		
	if (!g_TFBot[client].IsBuilding || !IsPlayerAlive(client))
		return Plugin_Continue;
		
	TFBotEngi_BuildObject(g_TFBot[client], TFObject_Dispenser, _, 90.0);
	return Plugin_Continue;
}

public Action Timer_TFBotBuildTeleporterExit(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
	
	if (!!g_TFBot[client].IsBuilding || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	TFBotEngi_BuildObject(g_TFBot[client], TFObject_Teleporter, TFObjectMode_Exit, 180.0);
	return Plugin_Continue;
}

public Action Timer_TFBotFinishBuilding(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
	
	g_TFBot[client].IsBuilding = false;
	g_TFBot[client].HasBuilt = true;
	
	g_TFBot[client].GetLocomotion().Run();

	return Plugin_Continue;
}

public Action Timer_TFBotBuildObject(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if (client == 0)
		return Plugin_Continue;
		
	float yawOffset = pack.ReadFloat();
	float angles[3];
	GetClientEyeAngles(client, angles);
	angles[1] += yawOffset;
	TeleportEntity(client, _, angles);
	
	g_TFBot[client].AddButtonFlag(IN_ATTACK);
	CreateTimer(0.1, Timer_TFBotStopForceAttack, client, TIMER_FLAG_NO_MAPCHANGE);
	
	g_TFBot[client].RemoveButtonFlag(IN_DUCK);
	return Plugin_Continue;
}

public Action Timer_TFBotStopForceAttack(Handle timer, int client)
{
	g_TFBot[client].RemoveButtonFlag(IN_ATTACK);
	return Plugin_Continue;
}

public Action TFBot_OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype)
{
	bool onGround = bool(GetEntityFlags(client) & FL_ONGROUND);
	TFBot bot = g_TFBot[client];
	
	if (buttons & IN_JUMP && !bot.HasButtonFlag(IN_JUMP) && !bot.HasButtonFlag(IN_DUCK) && !onGround)
	{
		buttons |= IN_DUCK; // Bots always crouch jump
	}
	
	if (buttons & IN_ATTACK || buttons & IN_ATTACK2)
	{
		if (bot.HasButtonFlag(IN_RELOAD))
		{
			buttons &= ~IN_ATTACK;
			buttons &= ~IN_ATTACK2;
		}
		else
		{
			int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			int secondary = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
			int melee = GetPlayerWeaponSlot(client, WeaponSlot_Melee);
			
			if (secondary > -1 && secondary == activeWeapon)
			{
				// TFBots have a bug where they won't switch off jar-type weapons after throwing. Forcing them to let go of IN_ATTACK fixes this.
				int ammoType = GetEntProp(secondary, Prop_Data, "m_iPrimaryAmmoType");
				if (ammoType >= TFAmmoType_Jarate && GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType) == 0)
				{
					buttons &= ~IN_ATTACK;
					buttons &= ~IN_ATTACK2;
				}
			}
			else if (melee > -1 && melee == activeWeapon)
			{
				int threat = -1;
				CKnownEntity known = bot.GetTarget();
				
				if (known != NULL_KNOWN_ENTITY)
					threat = known.GetEntity();
				
				// Melee bots need to crouch to attack teleporters, they won't realize this by default
				if (threat > -1 && threat > MaxClients && IsBuilding(threat) && TF2_GetObjectType(threat) == TFObject_Teleporter)
				{
					float myPos[3], threatPos[3];
					bot.GetMyPos(myPos);
					GetEntPropVector(threat, Prop_Data, "m_vecAbsOrigin", threatPos);
					
					if (GetVectorDistance(myPos, threatPos, true) <= sq(100.0))
					{
						buttons |= IN_DUCK;
					}
				}
			}
		}
	}
	
	if (bot.HasFlag(TFBOTFLAG_ROCKETJUMP) && !bot.HasButtonFlag(IN_RELOAD) && onGround)
	{
		int primary = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
		
		if (bot.GetTarget() != NULL_KNOWN_ENTITY && primary > -1 && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == primary)
		{
			// is there enough space above us?
			const float requiredSpace = 750.0;
			float eyePos[3], endPos[3];
			
			GetClientEyePosition(client, eyePos);
			TR_TraceRayFilter(eyePos, {-90.0, 0.0, 0.0}, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite, TraceFilter_WallsOnly);
			TR_GetEndPosition(endPos);
			
			if (GetVectorDistance(eyePos, endPos, true) >= sq(requiredSpace))
			{	
				buttons |= IN_JUMP; // jump, then attack shortly after
				
				// only actually rocket jump if we have enough health
				const float healthThreshold = 0.35;
				if (GetClientHealth(client) > RoundToFloor(float(RF2_GetCalculatedMaxHealth(client)) * (healthThreshold * TF2Attrib_HookValueFloat(1.0, "rocket_jump_dmg_reduction", client))))
				{
					float eyeAng[3];
					GetClientEyeAngles(client, eyeAng);
					eyeAng[0] = 90.0;
					TeleportEntity(client, _, eyeAng); // look directly down
					
					CreateTimer(0.1, Timer_TFBotRocketJump, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
	
	if (bot.HasButtonFlag(IN_DUCK))
	{
		buttons &= ~IN_JUMP;
	}
	
	buttons |= bot.ForcedButtons;
	return Plugin_Continue;
}

public Action Timer_TFBotRocketJump(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || GetEntityFlags(client) & FL_ONGROUND || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	float angles[3];
	GetClientEyeAngles(client, angles);
	angles[0] = 90.0;
	TeleportEntity(client, _, angles); // look directly down
	
	g_TFBot[client].AddButtonFlag(IN_ATTACK);
	CreateTimer(0.25, Timer_TFBotStopForceAttack, client, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public bool Path_FilterIgnoreObjects(int entity, int contentsMask, int desiredcollisiongroup)
{	
	if (IsObject(entity))
	{
		return true;
	}
	
	return false;
}