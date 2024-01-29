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
static int g_iTFBotDesiredWeaponSlot[MAXTF2PLAYERS] = {-1, ...}; 

static float g_flTFBotStrafeTime[MAXTF2PLAYERS];
static float g_flTFBotStrafeTimeStamp[MAXTF2PLAYERS];
static float g_flTFBotStuckTime[MAXTF2PLAYERS];
static float g_flTFBotLastSearchTime[MAXTF2PLAYERS];
static float g_flTFBotLastPosCheckTime[MAXTF2PLAYERS];

static CNavArea g_TFBotEngineerSentryArea[MAXTF2PLAYERS];
static float g_flTFBotEngineerSearchRetryTime[MAXTF2PLAYERS];
static bool g_bTFBotEngineerHasBuilt[MAXTF2PLAYERS];
static bool g_bTFBotEngineerAttemptingBuild[MAXTF2PLAYERS];
static int g_iTFBotEngineerRepairTarget[MAXTF2PLAYERS];

static int g_iTFBotSpyBuildingTarget[MAXTF2PLAYERS];
static float g_flTFBotSpyTimeInFOV[MAXTF2PLAYERS][MAXTF2PLAYERS];

static float g_flTFBotLastPos[MAXTF2PLAYERS][3];

enum TFBotMission
{
	MISSION_NONE, // No mission, behave normally
	MISSION_TELEPORTER, // Not to be confused with the building
	MISSION_WANDER, // Wander the map
	MISSION_CHASE, // Chase an enemy
	MISSION_BUILD, // An Engineer trying to build
	MISSION_REPAIR, // An Engineer repairing/upgrading a building
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
		{
			return view_as<int>(this);
		}
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
	
	property int DesiredWeaponSlot
	{
		public get() 			{ return g_iTFBotDesiredWeaponSlot[this.Client];  }
		public set(int value) 	{ g_iTFBotDesiredWeaponSlot[this.Client] = value; }
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
	
	property bool AttemptingBuild
	{
		public get() 			{ return g_bTFBotEngineerAttemptingBuild[this.Client];  }
		public set(bool value) 	{ g_bTFBotEngineerAttemptingBuild[this.Client] = value; }
	}

	property int RepairTarget
	{
		public get() 			{ return g_iTFBotEngineerRepairTarget[this.Client];  }
		public set(int value) 	{ g_iTFBotEngineerRepairTarget[this.Client] = value; }
	}
	
	public int GetBuilding(TFObjectType obj, TFObjectMode mode=TFObjectMode_None)
	{
		if (!g_hTFBotEngineerBuildings[this.Client])
			return -1;
		
		int entity;
		for (int i = 0; i < g_hTFBotEngineerBuildings[this.Client].Length; i++)
		{
			entity = EntRefToEntIndex(g_hTFBotEngineerBuildings[this.Client].Get(i));
			if (!IsValidEntity2(entity) || !IsBuilding(entity))
			{
				int index = g_hTFBotEngineerBuildings[this.Client].FindValue(entity);
				if (index >= 0)
				{
					g_hTFBotEngineerBuildings[this.Client].Erase(index);
					i--;
				}
				
				continue;
			}
			
			if (TF2_GetObjectType(entity) == obj && TF2_GetObjectMode(entity) == mode)
				return entity;
		}
		
		return -1;
	}
	
	public int GetPrioritizedBuilding()
	{
		if (!g_hTFBotEngineerBuildings[this.Client])
			return -1;
		
		int building;
		int prioritizedBuilding = -1;
		bool lowHealth;
		int sentry = this.GetBuilding(TFObject_Sentry);
		bool sentryUpgraded = IsValidEntity2(sentry) && GetEntProp(sentry, Prop_Send, "m_iUpgradeLevel") >= 3;
		
		for (int i = 0; i < g_hTFBotEngineerBuildings[this.Client].Length; i++)
		{
			building = EntRefToEntIndex(g_hTFBotEngineerBuildings[this.Client].Get(i));
			if (!IsValidEntity2(building))
				continue;
			
			// remove sappers first, always top priority
			if (GetEntProp(building, Prop_Send, "m_bHasSapper"))
			{
				prioritizedBuilding = building;
				break;
			}
			
			// repair low health buildings second
			if (GetEntProp(building, Prop_Send, "m_iHealth") < GetEntProp(building, Prop_Send, "m_iMaxHealth"))
			{
				prioritizedBuilding = building;
				lowHealth = true;
			}
			
			// upgrade sentry third
			if (!lowHealth)
			{
				if (sentryUpgraded)
				{
					if (GetEntProp(building, Prop_Send, "m_iUpgradeLevel") < 3)
						return building;
				}
				else
				{
					if (TF2_GetObjectType(building) == TFObject_Sentry && GetEntProp(building, Prop_Send, "m_iUpgradeLevel") < 3)
						return building;
				}
			}
		}

		return prioritizedBuilding;
	}
	
	public bool BuiltEverything()
	{
		return this.GetBuilding(TFObject_Sentry) != -1 
			&& this.GetBuilding(TFObject_Dispenser) != -1
			&& this.GetBuilding(TFObject_Teleporter, TFObjectMode_Exit) != -1;
	}
	
	// Spy
	public float GetTimeInFOV(int victim)
	{
		return g_flTFBotSpyTimeInFOV[this.Client][victim];
	}
	
	property int BuildingTarget
	{
		public get()			{ return EntRefToEntIndex(g_iTFBotSpyBuildingTarget[this.Client]); }
		public set(int entity)	{ g_iTFBotSpyBuildingTarget[this.Client] = entity <= 0 ? entity : EntIndexToEntRef(entity); }
	}

	// NextBot
	public INextBot GetNextBot() 
	{
		INextBot bot = CBaseEntity(this.Client).MyNextBotPointer();
		if (bot == view_as<INextBot>(0))
			LogError("[WARNING] Invalid INextBot for client %N", this.Client);
		
		return bot;
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
		this.Flags |= flags;
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
		this.ForcedButtons |= flags;
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
		GetEntPos(this.Client, buffer);
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

void TFBot_Think(TFBot &bot)
{
	float tickedTime = GetTickedTime();
	ILocomotion locomotion = bot.GetLocomotion();
	CKnownEntity known = bot.GetTarget();
	
	int threat = -1;
	if (known != NULL_KNOWN_ENTITY)
		threat = known.GetEntity();
	
	float botPos[3];
	bot.GetMyPos(botPos);
	bool aggressiveMode;
	TFClassType class = TF2_GetPlayerClass(bot.Client);
	
	// Switch to our desired weapon
	int desiredSlot;
	int desiredWeapon = TFBot_GetDesiredWeapon(bot, desiredSlot);
	if (desiredWeapon != -1)
	{
		ForceWeaponSwitch(bot.Client, desiredSlot);
	}
	
	if (threat > 0 && bot.Mission != MISSION_TELEPORTER && class != TFClass_Engineer)
	{
		aggressiveMode = bot.HasFlag(TFBOTFLAG_AGGRESSIVE) || GetEntPropEnt(bot.Client, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(bot.Client, WeaponSlot_Melee);
		// Aggressive AI, relentlessly pursues target and strafes on higher difficulties. Mostly for melee.
		if (aggressiveMode)
		{
			if (threat > MaxClients || !IsInvuln(threat) && class != TFClass_Spy)
			{
				float threatPos[3];
				GetEntPos(threat, threatPos);
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
					{
						GetEntPos(threat, threatPos);
					}
					
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
	else if (TF2_GetPlayerClass(bot.Client) == TFClass_Engineer && !IsPlayerStunned(bot.Client))
	{
		bot.HasBuilt = bot.BuiltEverything();
		if (bot.Mission == MISSION_NONE && bot.HasBuilt && threat > 0)
		{
			// Shoot at enemies if we're not doing anything else
			bot.DesiredWeaponSlot = WeaponSlot_Primary;
		}
		
		if (!bot.HasBuilt && tickedTime >= bot.EngiSearchRetryTime && !bot.SentryArea) // Do we have an area to build in?
		{
			bot.EngiSearchRetryTime = -1.0;
			float navPos[3], areaPos[3];
			CTFNavArea tfArea;
			CopyVectors(botPos, navPos);
			navPos[2] += 30.0;
			CNavArea area = TheNavMesh.GetNearestNavArea(navPos, true, 1000.0, false, true);
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
						if (owned || !IsClientInGame(b) || !IsFakeClient(b) || TF2_GetPlayerClass(b) != TFClass_Engineer)
							continue;
							
						if (g_TFBot[b].SentryArea == tfArea)
						{
							owned = true;
							break;
						}
					}
					
					tfArea.GetCenter(areaPos);
					// No one owns this area and there are no other things nearby, we can take it.
					if (!owned && GetNearestEntity(areaPos, "obj_*", _, 300.0) == -1 && GetNearestEntity(areaPos, "rf2_object*", _, 150.0) == -1) 
					{
						bot.Mission = MISSION_BUILD;
						bot.SentryArea = tfArea;
						TFBot_PathToPos(bot, areaPos, 10000.0); // Start marching towards our desired area now
						break;
					}
				}
			}
			
			// We failed to find an area, try again after a bit
			if (!bot.SentryArea)
			{
				bot.EngiSearchRetryTime = tickedTime+1.0;
			}
			
			delete collector;
		}
		else if (!bot.HasBuilt && bot.SentryArea && bot.Mission == MISSION_BUILD) // Should we try to build?
		{
			float areaPos[3];
			bot.SentryArea.GetCenter(areaPos);
			if (GetVectorDistance(areaPos, botPos, true) <= sq(40.0))
			{
				// Try and build at this spot.
				bot.DesiredWeaponSlot = WeaponSlot_Builder;
				TFBotEngi_AttemptBuild(bot);
			}
			else
			{
				// Not close enough, keep going.
				TFBot_PathToPos(bot, areaPos, 10000.0);
			}
		}
		else if (bot.Mission != MISSION_BUILD) // If we're not building and have an area, check if we need to repair, upgrade, or rebuild
		{
			if (bot.Mission == MISSION_REPAIR)
			{
				int building = EntRefToEntIndex(bot.RepairTarget);
				int prioritizedBuilding = bot.GetPrioritizedBuilding();
				if (bot.HasBuilt && IsValidEntity2(building) &&  (prioritizedBuilding == -1 || building == prioritizedBuilding) && 
					(GetEntProp(building, Prop_Send, "m_iHealth") < GetEntProp(building, Prop_Send, "m_iMaxHealth") || GetEntProp(building, Prop_Send, "m_iUpgradeLevel") < 3))
				{
					float pos[3];
					GetEntPos(building, pos);
					pos[2] += 20.0;
					
					float dist = DistBetween(bot.Client, building);
					
					// Also move around if we're trying to build something so we can place it
					if (dist > 50.0 || GetEntPropEnt(bot.Client, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(bot.Client, WeaponSlot_Builder))
						TFBot_PathToPos(bot, pos, 10000.0, true);
					
					if (TF2_GetObjectType(building) == TFObject_Teleporter && dist <= 50.0)
					{
						bot.AddButtonFlag(IN_DUCK);
					}
					else
					{
						bot.RemoveButtonFlag(IN_DUCK);
					}
					
					// Make sure we have our wrench out
					if (GetEntPropEnt(bot.Client, Prop_Send, "m_hActiveWeapon") != GetPlayerWeaponSlot(bot.Client, WeaponSlot_Melee))
					{
						bot.DesiredWeaponSlot = WeaponSlot_Melee;
						ForceWeaponSwitch(bot.Client, WeaponSlot_Melee);
					}
					
					TFBot_ForceLookAtPos(bot, pos);
					bot.AddButtonFlag(IN_ATTACK);
				}
				else
				{
					bot.RepairTarget = -1;
					bot.Mission = MISSION_NONE;
					bot.RemoveButtonFlag(IN_ATTACK);
					bot.RemoveButtonFlag(IN_DUCK);
				}
			}
			else
			{
				// We've built something already, maintain it
				TFObjectType type;
				int building = bot.GetPrioritizedBuilding();
				if (building > 0)
				{
					bot.RepairTarget = EntIndexToEntRef(building);
					bot.Mission = MISSION_REPAIR;
				}
				else
				{
					for (int i = 0; i <= 3; i++)
					{
						type = view_as<TFObjectType>(i);
						building = bot.GetBuilding(type);
						if (building == -1)
							continue;
						
						// does this building need to be repaired/upgraded?
						if (GetEntProp(building, Prop_Send, "m_iHealth") < GetEntProp(building, Prop_Send, "m_iMaxHealth")
							|| GetEntProp(building, Prop_Send, "m_iUpgradeLevel") < 3)
						{
							bot.RepairTarget = EntIndexToEntRef(building);
							bot.Mission = MISSION_REPAIR;
							break;
						}
					}
				}
				
				if (!bot.HasBuilt)
				{
					bot.Mission = MISSION_BUILD;
				}
			}
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
	
	// Only for bosses for now, as they are large.
	if (IsBoss(bot.Client))
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
	
	bool isSniping;
	if (class == TFClass_Sniper)
	{
		int primary = GetPlayerWeaponSlot(bot.Client, WeaponSlot_Primary);
		if (primary != -1 && primary == GetEntPropEnt(bot.Client, Prop_Send, "m_hActiveWeapon"))
		{
			static char classname[32];
			GetEntityClassname(primary, classname, sizeof(classname));
			isSniping = (StrContains(classname, "tf_weapon_sniperrifle") == 0);
		}
	}
	
	// If we aren't doing anything else, wander the map looking for enemies to attack.
	if (bot.Mission != MISSION_TELEPORTER && (class == TFClass_Spy || threat <= 0) && !isSniping && (class != TFClass_Engineer || bot.EngiSearchRetryTime > 0.0) 
	&& bot.Mission != MISSION_BUILD && !bot.HasBuilt)
	{
		TFBot_TraverseMap(bot);
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
			case ItemStrange_VirtualViewfinder, ItemStrange_Spellbook, ItemStrange_PartyHat, ItemStrange_RobotChicken: 
			{
				return threat > 0 && !invuln && vision.IsLookingAtTarget(threat);
			}
			
			case ItemStrange_RoBro: return threat > 0 && GetClientHealth(bot.Client) < RF2_GetCalculatedMaxHealth(bot.Client) / 2;
			
			case ItemStrange_HeartOfGold: return true; // we check when we use this item instead, so always try to use
			
			case ItemStrange_LegendaryLid, ItemStrange_CroneDome, ItemStrange_HandsomeDevil:
			{
				if (threat > 0 && !invuln && vision.IsLookingAtTarget(threat))
				{
					return DistBetween(bot.Client, threat, true) <= 400000.0;
				}
			}
			
			case ItemStrange_DarkHunter, ItemStrange_NastyNorsemann:
			{
				if (threat <= 0)
					return false;
				
				if (IsBuilding(threat))
				{
					return TF2_GetObjectType(threat) == TFObject_Sentry;
				}
				
				return true;
			}
			
			case ItemStrange_ScaryMask:
			{
				if (IsValidClient(threat) && !invuln)
				{
					return DistBetween(bot.Client, threat, true) < sq(GetItemMod(ItemStrange_ScaryMask, 0));
				}
			}
		}
	}
	
	return false;
}

void TFBot_TraverseMap(TFBot &bot)
{
	float myPos[3], areaPos[3], goalPos[3], lastPos[3];
	float tickedTime = GetTickedTime();
	bot.GetMyPos(myPos);
	
	if (bot.GoalArea && (!IsValidEntity2(bot.BuildingTarget) || GetEntProp(bot.BuildingTarget, Prop_Send, "m_bCarried")))
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
		CNavArea goal;
		int enemy;
		
		// Are we after a building?
		if (IsValidEntity2(bot.BuildingTarget) && !GetEntProp(bot.BuildingTarget, Prop_Send, "m_bCarried"))
		{
			TFBot_PathToEntity(bot, bot.BuildingTarget, 2500.0, true);
			return;
		}
		else if (RF2_GetSubDifficulty() >= SubDifficulty_Impossible && GetClientTeam(bot.Client) == TEAM_ENEMY)
		{
			enemy = GetNearestPlayer(myPos, _, g_cvBotWanderMaxDist.FloatValue, TEAM_SURVIVOR);
		}
		
		if (enemy > 0)
		{
			goal = TheNavMesh.GetNavAreaEntity(enemy, GETNAVAREA_ALLOW_BLOCKED_AREAS, 400.0);
		}
		
		CNavArea area = !goal ? CBaseCombatCharacter(bot.Client).GetLastKnownArea() : NULL_AREA;
		if (area && enemy <= 0)
		{
			SurroundingAreasCollector collector = TheNavMesh.CollectSurroundingAreas(area, g_cvBotWanderMaxDist.FloatValue, 100.0);
			ArrayList areaArray = CreateArray();
			float cost, radius;
			float telePos[3];
			RF2_Object_Teleporter teleporter = GetCurrentTeleporter();
			bool event = teleporter.IsValid() && teleporter.EventState != TELE_EVENT_INACTIVE;
			
			if (event)
			{
				teleporter.GetAbsOrigin(telePos);
				radius = teleporter.Radius;
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
				goal = collector.Get(areaArray.Get(GetRandomInt(0, areaArray.Length-1)));
			}
			
			delete collector;
			delete areaArray;
		}
		
		if (goal)
		{
			bot.GoalArea = goal;
			bot.GoalArea.GetCenter(goalPos);
			TFBot_PathToPos(bot, goalPos, g_cvBotWanderMaxDist.FloatValue, true);
			bot.Mission = MISSION_WANDER;
			bot.SetLastWanderPos(myPos);
			bot.LastSearchTime = tickedTime;
			bot.LastPosCheckTime = tickedTime;
		}
	}
}

void TFBot_PathToPos(TFBot &bot, float pos[3], float distance=1000.0, bool ignoreGoal=false)
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

void TFBot_PathToEntity(TFBot bot, int entity, float distance=1000.0, bool ignoreGoal=false)
{
	ILocomotion locomotion = bot.GetLocomotion();
	INextBot nextBot = bot.GetNextBot();
	bool goalReached = bot.Follower.ComputeToTarget(nextBot, entity, distance);
	
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

void TFBot_ForceLookAtPos(TFBot bot, const float pos[3])
{
	float angles[3], eyePos[3];
	GetClientEyePosition(bot.Client, eyePos);
	GetVectorAnglesTwoPoints(eyePos, pos, angles);
	TeleportEntity(bot.Client, _, angles);
	bot.GetLocomotion().FaceTowards(pos); // for good measure
}

void TFBotEngi_AttemptBuild(TFBot &bot)
{
	if (bot.AttemptingBuild)
		return;
	
	bot.AttemptingBuild = true;
	bot.Mission = MISSION_BUILD;
	bool buildingSentry = TFBotEngi_BuildObject(bot, TFObject_Sentry);
	if (!buildingSentry && bot.GetBuilding(TFObject_Teleporter, TFObjectMode_Exit) != -1)
	{
		TFBotEngi_BuildObject(bot, TFObject_Dispenser, _, 60.0);
		CreateTimer(1.0, Timer_TFBotFinishBuilding, GetClientUserId(bot.Client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (!buildingSentry && bot.GetBuilding(TFObject_Dispenser) != -1)
	{
		TFBotEngi_BuildObject(bot, TFObject_Teleporter, TFObjectMode_Exit, 60.0);
		CreateTimer(1.0, Timer_TFBotFinishBuilding, GetClientUserId(bot.Client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (buildingSentry && (bot.GetBuilding(TFObject_Dispenser) == -1 || bot.GetBuilding(TFObject_Teleporter, TFObjectMode_Exit) == -1))
	{
		CreateTimer(1.5, Timer_TFBotBuildTeleporterExit, GetClientUserId(bot.Client), TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(2.5, Timer_TFBotBuildDispenser, GetClientUserId(bot.Client), TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(3.5, Timer_TFBotFinishBuilding, GetClientUserId(bot.Client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

bool TFBotEngi_BuildObject(TFBot &bot, TFObjectType type, TFObjectMode mode=TFObjectMode_Entrance, float yawOffset=0.0)
{
	if (GetBuiltObject(bot.Client, type, mode) != -1)
		return false;
	
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
	return true;
}

public Action Timer_TFBotBuildDispenser(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
		
	if (g_TFBot[client].Mission != MISSION_BUILD || !IsPlayerAlive(client))
		return Plugin_Continue;
		
	TFBotEngi_BuildObject(g_TFBot[client], TFObject_Dispenser, _, 90.0);
	return Plugin_Continue;
}

public Action Timer_TFBotBuildTeleporterExit(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
	
	if (g_TFBot[client].Mission != MISSION_BUILD  || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	TFBotEngi_BuildObject(g_TFBot[client], TFObject_Teleporter, TFObjectMode_Exit, 180.0);
	return Plugin_Continue;
}

public Action Timer_TFBotFinishBuilding(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
	
	g_TFBot[client].AttemptingBuild = false;
	g_TFBot[client].HasBuilt = g_TFBot[client].BuiltEverything();
	g_TFBot[client].RemoveButtonFlag(IN_ATTACK);
	if (g_TFBot[client].Mission == MISSION_BUILD)
	{
		g_TFBot[client].GetLocomotion().Run();
		g_TFBot[client].Mission = MISSION_NONE;
	}
	
	int entity = -1;
	int ref;
	if (!g_hTFBotEngineerBuildings[client])
		g_hTFBotEngineerBuildings[client] = new ArrayList();
	
	while ((entity = FindEntityByClassname(entity, "obj_*")) != -1)
	{
		ref = EntIndexToEntRef(entity);
		if (GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client && g_hTFBotEngineerBuildings[client].FindValue(ref) == -1)
		{
			g_hTFBotEngineerBuildings[client].Push(ref);
		}
	}
	
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
	CreateTimer(0.5, Timer_TFBotStopForceAttack, client, TIMER_FLAG_NO_MAPCHANGE);
	
	g_TFBot[client].RemoveButtonFlag(IN_DUCK);
	return Plugin_Continue;
}

public Action Timer_TFBotStopForceAttack(Handle timer, int client)
{
	g_TFBot[client].RemoveButtonFlag(IN_ATTACK);
	return Plugin_Continue;
}

public Action TFBot_OnPlayerRunCmd(int client, int &buttons, int &impulse)
{
	TFBot bot = g_TFBot[client];
	
	if (!bot)
	{
		return Plugin_Continue;
	}
	
	static bool reloading[MAXTF2PLAYERS];
	int activeWep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (activeWep > -1 && activeWep != GetPlayerWeaponSlot(client, WeaponSlot_Melee))
	{
		int clip = GetEntProp(activeWep, Prop_Send, "m_iClip1");
		int maxClip = SDK_GetWeaponClipSize(activeWep);
		
		if (TF2Attrib_HookValueInt(0, "auto_fires_full_clip", activeWep) != 0)
		{
			CKnownEntity known = bot.GetTarget();
			int target = known != NULL_KNOWN_ENTITY ? known.GetEntity() : -1;
			bool targetInvuln = IsValidClient(target) && IsInvuln(target);
			bool overload = TF2Attrib_HookValueInt(0, "can_overload", activeWep) != 0;
			
			if (clip >= maxClip)
			{
				// unload barrage if target is visible and vulnerable or we can overload the clip (beggars)
				if (overload || target > -1 && !targetInvuln)
				{
					buttons &= ~IN_ATTACK;
				}
			}
			else if (!overload)
			{
				// load chamber if we have no enemy we can see and can't overload
				buttons |= IN_ATTACK;
			}
		}
		else if (bot.HasFlag(TFBOTFLAG_HOLDFIRE))
		{
			if (!reloading[client] && clip == 0)
			{
				buttons &= ~IN_ATTACK;
				reloading[client] = true;
				return Plugin_Continue;
			}
			else if (reloading[client])
			{
				if (maxClip <= 0 || clip >= maxClip)
				{
					reloading[client] = false;
				}
				else
				{
					buttons &= ~IN_ATTACK;
				}
			}
		}
	}
	else
	{
		reloading[client] = false;
	}
	
	int threat = -1;
	CKnownEntity known = bot.GetTarget(TF2_GetPlayerClass(client) == TFClass_Spy ? false : true);
	if (known != NULL_KNOWN_ENTITY)
		threat = known.GetEntity();
	
	if (!reloading[client] && (buttons & IN_ATTACK || buttons & IN_ATTACK2))
	{
		int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		int secondary = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
		int melee = GetPlayerWeaponSlot(client, WeaponSlot_Melee);
		
		if (secondary > -1 && secondary == activeWeapon)
		{
			// TFBots have a stupid bug where they won't switch off certain weapons after use. Forcing them to let go of IN_ATTACK fixes this.
			static char classname[32];
			GetEntityClassname(secondary, classname, sizeof(classname));
			bool banner = strcmp2(classname, "tf_weapon_buff_item");
			if (banner && threat > 0 && IsBuilding(threat))
			{
				buttons &= ~IN_ATTACK;
			}
			
			if ((StrContains(classname, "tf_weapon_jar") == 0 || strcmp2(classname, "tf_weapon_cleaver"))
				&& GetEntProp(client, Prop_Send, "m_iAmmo", _, GetEntProp(secondary, Prop_Send, "m_iPrimaryAmmoType")) == 0)
			{
				buttons &= ~IN_ATTACK;
				buttons &= ~IN_ATTACK2;
			}
		}
		else if (melee > -1 && melee == activeWeapon)
		{
			// Melee bots need to crouch to attack teleporters, they won't realize this by default
			if (threat > -1 && threat > MaxClients && IsBuilding(threat) && TF2_GetObjectType(threat) == TFObject_Teleporter)
			{
				if (DistBetween(bot.Client, threat, true) <= sq(100.0))
					buttons |= IN_DUCK;
			}
		}
	}
	
	bool rocketJumping;
	bool onGround = asBool((GetEntityFlags(client) & FL_ONGROUND));
	
	if (TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		// if we are not in our player threat's FOV, go for stab instead
		bool inFov;
		float myPos[3], threatPos[3];
		GetEntPos(client, myPos);
		
		bool sentry, usingSapper;
		float distance;
		const float maxDistance = 1500.0;
		const float sapRange = 400.0;
		int highestLevel;
		int entity = MaxClients+1;
		int team = GetClientTeam(client);
		int shootTarget = -1;
		int primary = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
		int sapper = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
		int melee = GetPlayerWeaponSlot(client, WeaponSlot_Melee);
		
		// If there are nearby buildings, sap them
		ArrayList sentryList = CreateArray();
		while ((entity = FindEntityByClassname(entity, "obj_*")) != -1)
		{
			if (GetEntProp(entity, Prop_Data, "m_iTeamNum") == team)
				continue;
			
			if (GetEntProp(entity, Prop_Send, "m_bCarried"))
				continue;
			
			if (!bot.GetVision().IsLineOfSightClearToEntity(entity))
				continue;
			
			if (sentry) // Stop searching for sap targets once we find a sentry, but keep adding sentries to our list
			{
				if (TF2_GetObjectType(entity) == TFObject_Sentry)
				{
					sentryList.Push(entity);
					
					// Prioritize higher-leveled sentries first
					if (shootTarget > 0)
					{
						int level = GetEntProp(entity, Prop_Send, "m_iUpgradeLevel");
						if (level > highestLevel)
						{
							shootTarget = entity;
							highestLevel = level;
						}
					}
				}
				
				continue;
			}
			
			GetEntPos(entity, threatPos);
			distance = GetVectorDistance(myPos, threatPos, true);
			if (distance <= sq(maxDistance))
			{
				bot.BuildingTarget = entity;
				
				if (bot.GetVision().GetKnown(entity) == NULL_KNOWN_ENTITY)
					bot.GetVision().AddKnownEntity(entity);
				
				bool hasSapper = asBool(GetEntProp(entity, Prop_Send, "m_bHasSapper"));
				
				if (!hasSapper && !usingSapper && distance <= sq(sapRange))
				{
					// Sap immediately if in range
					if (sapper != -1)
					{
						usingSapper = true;
						bool sapperActive = (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == sapper);
						bot.DesiredWeaponSlot = WeaponSlot_Secondary;
						threatPos[2] += 25.0;
						TFBot_ForceLookAtPos(bot, threatPos);
						
						// Don't force an attack too early, we might end up shooting the building instead. We want to sap it.
						if (sapperActive)
						{
							buttons |= IN_ATTACK;
						}
					}
				}
				
				// Sentries are important
				if (TF2_GetObjectType(entity) == TFObject_Sentry)
				{
					sentry = true;
					sentryList.Push(entity);
				}
				
				if (primary != -1 && hasSapper && !usingSapper && sentry)
				{
					// shoot an already sapped sentry
					shootTarget = entity;
					highestLevel = GetEntProp(entity, Prop_Send, "m_iUpgradeLevel");
				}
			}
		}
		
		if (shootTarget > 0)
		{
			// make sure no other non-sapped sentries can see us
			const float sentryRange = 1100.0;
			float sentryPos[3];
			bool visible;
			
			for (int i = 0; i < sentryList.Length; i++)
			{
				entity = sentryList.Get(i);
				if (entity == shootTarget || GetEntProp(entity, Prop_Data, "m_iTeamNum") == team)
					continue;
				
				if (!GetEntProp(entity, Prop_Send, "m_bDisabled"))
				{
					GetEntPos(entity, sentryPos);
					if (GetVectorDistance(myPos, sentryPos, true) <= Pow(sentryRange, 2.0))
					{
						if (bot.GetVision().IsLineOfSightClearToEntity(entity))
						{
							visible = true;
							break;
						}
					}
				}
			}
			
			// no other sentries, shoot
			if (!visible)
			{
				GetEntPos(shootTarget, sentryPos);
				sentryPos[2] += 25.0;
				TFBot_ForceLookAtPos(bot, sentryPos);
				bot.DesiredWeaponSlot = WeaponSlot_Primary;
				if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") != primary)
				{
					ForceWeaponSwitch(client, WeaponSlot_Primary);
				}
				
				buttons |= IN_ATTACK;
			}
		}
		
		delete sentryList;
		
		if (IsValidClient(threat) && !sentry && !usingSapper && bot.GetVision().IsLineOfSightClearToEntity(threat))
		{
			if (bot.GetVision().IsLookingAtTarget(threat, 0.7))
			{
				GetClientEyePosition(client, myPos);
				GetClientEyePosition(threat, threatPos);
				
				float eyeAng[3], angles[3];
				const float fov = 70.0;
				GetClientEyeAngles(threat, eyeAng);
				GetVectorAnglesTwoPoints(myPos, threatPos, angles);
				
				if (eyeAng[1] < 0.0)
				{
					eyeAng[1] = 360.0 - FloatAbs(eyeAng[1]);
				}
				
				if (angles[1] >= eyeAng[1]+fov || angles[1] <= eyeAng[1]-fov)
				{
					inFov = true;
				}
				
				if (inFov)
				{
					g_flTFBotSpyTimeInFOV[client][threat] += GetTickInterval();
				}
				else if (g_flTFBotSpyTimeInFOV[client][threat] > 0.0)
				{
					g_flTFBotSpyTimeInFOV[client][threat] -= GetTickInterval();
					g_flTFBotSpyTimeInFOV[client][threat] = fmax(g_flTFBotSpyTimeInFOV[client][threat], 0.0);
				}
				
				if (bot.GetTimeInFOV(threat) > 0.7 && primary > -1)
				{
					// shoot
					bot.DesiredWeaponSlot = WeaponSlot_Primary;
					if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") != primary)
					{
						ForceWeaponSwitch(client, WeaponSlot_Primary);
					}
					
					int perfectAimChance;
					switch (bot.GetSkillLevel())
					{
						case TFBotDifficulty_Easy: perfectAimChance = 0;
						case TFBotDifficulty_Normal: perfectAimChance = 20;
						case TFBotDifficulty_Hard: perfectAimChance = 50;
						case TFBotDifficulty_Expert: perfectAimChance = 100;
					}
					
					if (RandChanceInt(1, 100, perfectAimChance))
					{
						TFBot_ForceLookAtPos(bot, threatPos);
					}
					
					buttons |= IN_ATTACK;
				}
				else if (melee > -1)
				{
					bot.DesiredWeaponSlot = WeaponSlot_Melee;
					if (GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") != melee)
					{
						ForceWeaponSwitch(client, WeaponSlot_Melee);
					}
					
					const float range = 200.0;
					if (GetVectorDistance(myPos, threatPos, true) <= Pow(range, 2.0))
					{
						buttons |= IN_ATTACK;
					}
				}
			}
		}
		else
		{
			SetAllInArray(g_flTFBotSpyTimeInFOV[client], sizeof(g_flTFBotSpyTimeInFOV[]), 0.0);
		}
	}
	else if (!reloading[client] && bot.HasFlag(TFBOTFLAG_ROCKETJUMP) && !bot.HasButtonFlag(IN_RELOAD))
	{
		if (onGround && bot.GetTarget() != NULL_KNOWN_ENTITY)
		{
			int primary = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
			
			if (primary > -1 && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == primary 
			&& GetEntProp(primary, Prop_Send, "m_iClip1") >= SDK_GetWeaponClipSize(primary))
			{
				// is there enough space above us?
				const float requiredSpace = 750.0;
				float eyePos[3], endPos[3];
				
				GetClientEyePosition(client, eyePos);
				TR_TraceRayFilter(eyePos, {-90.0, 0.0, 0.0}, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite, TraceFilter_WallsOnly);
				TR_GetEndPosition(endPos);
				
				if (GetVectorDistance(eyePos, endPos, true) >= sq(requiredSpace))
				{
					// only actually rocket jump if we have enough health
					const float healthThreshold = 0.35;
					if (GetClientHealth(client) > RoundToFloor(float(RF2_GetCalculatedMaxHealth(client)) * (healthThreshold * TF2Attrib_HookValueFloat(1.0, "rocket_jump_dmg_reduction", client))))
					{
						buttons |= IN_JUMP|IN_DUCK; // jump, then attack shortly after
						rocketJumping = true;
						
						eyePos[2] -= 50.0;
						TFBot_ForceLookAtPos(bot, eyePos); // look directly down

						CreateTimer(0.1, Timer_TFBotRocketJump, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
		else if (!bot.HasButtonFlag(IN_DUCK))
		{
			buttons &= ~IN_DUCK; // likely landed after a rocket jump, stop bot from continuously crouching
		}
	}
	
	if (!rocketJumping && !onGround && buttons & IN_JUMP && !bot.HasButtonFlag(IN_JUMP) && !bot.HasButtonFlag(IN_DUCK))
	{
		buttons |= IN_DUCK; // Bots always crouch jump
	}
	
	if (!rocketJumping && bot.HasButtonFlag(IN_DUCK))
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

void UpdateBotQuota()
{
	ConVar quota = FindConVar("tf_bot_quota");
	quota.IntValue = imin((MaxClients-g_cvMaxSurvivors.IntValue)+GetTotalHumans(false), MaxClients);
}

// -1 = let bot decide
int TFBot_GetDesiredWeapon(TFBot bot, int &slot=0)
{
	int threat = -1;
	CKnownEntity known = bot.GetTarget();
	if (known != NULL_KNOWN_ENTITY)
		threat = known.GetEntity();
	
	if (bot.DesiredWeaponSlot != -1)
	{
		slot = bot.DesiredWeaponSlot;
		return GetPlayerWeaponSlot(bot.Client, bot.DesiredWeaponSlot);
	}
	
	if (TF2_IsPlayerInCondition2(bot.Client, TFCond_Charging) 
		|| threat > 0 && IsEnemy(bot.Client) && Enemy(bot.Client).BotMeleeDistance > 0.0 && DistBetween(bot.Client, threat) <= Enemy(bot.Client).BotMeleeDistance)
	{
		slot = WeaponSlot_Melee;
		return GetPlayerWeaponSlot(bot.Client, WeaponSlot_Melee);
	}
	
	return -1;
}

public Action Hook_TFBotWeaponCanSwitch(int client, int weapon)
{
	if (!g_TFBot[client])
		return Plugin_Continue;
	
	int desiredWeapon = TFBot_GetDesiredWeapon(g_TFBot[client]);
	if (desiredWeapon > 0 && weapon != desiredWeapon)
	{
		// do not switch to other weapons if we have a desired weapon
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}
