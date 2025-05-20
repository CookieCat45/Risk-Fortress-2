#pragma semicolon 1
#pragma newdecls required

static CNavArea g_TFBotGoalArea[MAXPLAYERS];
static int g_iTFBotFlags[MAXPLAYERS];
static int g_iTFBotForcedButtons[MAXPLAYERS];
static int g_iTFBotDesiredWeaponSlot[MAXPLAYERS] = {-1, ...}; 
static float g_flTFBotStrafeTime[MAXPLAYERS];
static float g_flTFBotStrafeTimeStamp[MAXPLAYERS];
static float g_flTFBotStuckTime[MAXPLAYERS];
static float g_flTFBotLastSearchTime[MAXPLAYERS];
static float g_flTFBotLastPosCheckTime[MAXPLAYERS];
static CNavArea g_TFBotEngineerSentryArea[MAXPLAYERS];
static float g_flTFBotEngineerSearchRetryTime[MAXPLAYERS];
static bool g_bTFBotEngineerHasBuilt[MAXPLAYERS];
static bool g_bTFBotEngineerAttemptingBuild[MAXPLAYERS];
static bool g_bTFBotForceBannerSwitch[MAXPLAYERS];
static int g_iTFBotEngineerRepairTarget[MAXPLAYERS];
static int g_iTFBotEngineerBuildAttempts[MAXPLAYERS];
static int g_iTFBotSpyBuildingTarget[MAXPLAYERS];
static int g_iTFBotScavengerTarget[MAXPLAYERS] = {INVALID_ENT, ...};
static float g_flTFBotSpyTimeInFOV[MAXPLAYERS][MAXPLAYERS];
static float g_flTFBotLastPos[MAXPLAYERS][3];
static float g_flTFBotSpyForgetTime[MAXPLAYERS][MAXPLAYERS];

#define SPY_REMEMBER_TIME 5.0

enum //AttributeType (most of these probably don't work outside of MvM? Haven't tested much.)
{
	REMOVE_ON_DEATH				= 1<<0,					// 1 kick bot from server when killed
	AGGRESSIVE					= 1<<1,					// 2 in MvM mode, push for the cap point
	IS_NPC						= 1<<2,					// 4 a non-player support character
	SUPPRESS_FIRE				= 1<<3,					// 8
	DISABLE_DODGE				= 1<<4,					// 16
	BECOME_SPECTATOR_ON_DEATH	= 1<<5,					// 32 move bot to spectator team when killed
	QUOTA_MANANGED				= 1<<6,					// 64 managed by the bot quota in CTFBotManager 
	RETAIN_BUILDINGS			= 1<<7,					// 128 don't destroy this bot's buildings when it disconnects
	SPAWN_WITH_FULL_CHARGE		= 1<<8,					// (DOES NOT WORK) 256 all weapons start with full charge (ie: uber)
	ALWAYS_CRIT					= 1<<9,					// 512 always fire critical hits
	IGNORE_ENEMIES				= 1<<10,				// 1024
	HOLD_FIRE_UNTIL_FULL_RELOAD	= 1<<11,				// 2048 don't fire our barrage weapon until it is full reloaded (rocket launcher, etc)
	PRIORITIZE_DEFENSE			= 1<<12,				// 4096 bot prioritizes defending when possible
	ALWAYS_FIRE_WEAPON			= 1<<13,				// 8192 constantly fire our weapon
	TELEPORT_TO_HINT			= 1<<14,				// (DOES NOT WORK) 16384 bot will teleport to hint target instead of walking out from the spawn point
	MINIBOSS					= 1<<15,				// 32768 is miniboss?
	USE_BOSS_HEALTH_BAR			= 1<<16,				// 65536 should I use boss health bar?
	IGNORE_FLAG					= 1<<17,				// 131072 don't pick up flag/bomb
	AUTO_JUMP					= 1<<18,				// (DOES NOT WORK) 262144 auto jump
	AIR_CHARGE_ONLY				= 1<<19,				// 524288 demo knight only charge in the air
	PREFER_VACCINATOR_BULLETS	= 1<<20,				// 1048576 When using the vaccinator, prefer to use the bullets shield
	PREFER_VACCINATOR_BLAST		= 1<<21,				// 2097152 When using the vaccinator, prefer to use the blast shield
	PREFER_VACCINATOR_FIRE		= 1<<22,				// 4194304 When using the vaccinator, prefer to use the fire shield
	BULLET_IMMUNE				= 1<<23,				// 8388608 Has a shield that makes the bot immune to bullets
	BLAST_IMMUNE				= 1<<24,				// 16777216 "" blast
	FIRE_IMMUNE					= 1<<25,				// 33554432 "" fire
	PARACHUTE					= 1<<26,				// 67108864 demo/soldier parachute when falling
	PROJECTILE_SHIELD			= 1<<27,				// (DOES NOT WORK) 134217728 medic projectile shield
};
static int g_iTFBotBehaviorAttributes[MAXPLAYERS];

// Note: these are plugin-specific, not the actual MissionType enum in TF2 code.
enum TFBotMission
{
	MISSION_NONE, // No mission, behave normally
	MISSION_TELEPORTER, // Not to be confused with the building
	MISSION_WANDER, // Wander the map
	MISSION_CHASE, // Chase an enemy
	MISSION_BUILD, // An Engineer trying to build
	MISSION_REPAIR, // An Engineer repairing/upgrading a building
};
static TFBotMission g_TFBotMissionType[MAXPLAYERS];

enum TFBotStrafeDir
{
	Strafe_Left,
	Strafe_Right,
};
static TFBotStrafeDir g_TFBotStrafeDirection[MAXPLAYERS];

methodmap TFBot
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
	property PathFollower Path
	{
		public get() 				{ return g_iEntityPathFollower[this.Client]; }
		public set(PathFollower pf)	{ g_iEntityPathFollower[this.Client] = pf;   }
	}
	property CNavArea GoalArea
	{
		public get() 				{ return g_TFBotGoalArea[this.Client]; }
		public set(CNavArea area) 	{ g_TFBotGoalArea[this.Client] = area; }
	}
	
	// Behavior
	property int BehaviorAttributes
	{
		public get() 				{ return g_iTFBotBehaviorAttributes[this.Client];  }
		public set(int value) 	
		{
			VScriptCmd cmd;
			cmd.Append("self.ClearAllBotAttributes();");
			cmd.Append(Format2("self.AddBotAttribute(%d);", value));
			cmd.Run(this.Client);
			g_iTFBotBehaviorAttributes[this.Client] = value;
		}
	}
	
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
	
	property int ScavengerTarget
	{
		public get() 			{ return g_iTFBotScavengerTarget[this.Client];  }
		public set(int value) 	{ g_iTFBotScavengerTarget[this.Client] = value; }				
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
	
	property bool ForceBannerSwitch
	{
		public get() 			{ return g_bTFBotForceBannerSwitch[this.Client];  }
		public set(bool value) 	{ g_bTFBotForceBannerSwitch[this.Client] = value; }
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

	property int BuildAttempts
	{
		public get() 			{ return g_iTFBotEngineerBuildAttempts[this.Client];  }
		public set(int value) 	{ g_iTFBotEngineerBuildAttempts[this.Client] = value; }
	}

	property int RepairTarget
	{
		public get() 			{ return g_iTFBotEngineerRepairTarget[this.Client];  }
		public set(int value) 	{ g_iTFBotEngineerRepairTarget[this.Client] = value; }
	}
	
	public int GetBuilding(TFObjectType obj, TFObjectMode mode=TFObjectMode_None)
	{
		if (!g_hTFBotEngineerBuildings[this.Client])
			return INVALID_ENT;
		
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
			
			if (TF2_GetObjectType2(entity) == obj && TF2_GetObjectMode(entity) == mode)
				return entity;
		}
		
		return INVALID_ENT;
	}
	
	public int GetPrioritizedBuilding()
	{
		if (!g_hTFBotEngineerBuildings[this.Client])
			return INVALID_ENT;
		
		int building;
		int prioritizedBuilding = INVALID_ENT;
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
			if (GetEntProp(building, Prop_Send, "m_iHealth") < GetEntProp(building, Prop_Send, "m_iMaxHealth")
				&& !GetEntProp(building, Prop_Send, "m_bBuilding"))
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
					if (TF2_GetObjectType2(building) == TFObject_Sentry && GetEntProp(building, Prop_Send, "m_iUpgradeLevel") < 3)
						return building;
				}
			}
		}

		return prioritizedBuilding;
	}
	
	public bool BuiltEverything()
	{
		return this.GetBuilding(TFObject_Sentry) != INVALID_ENT 
			&& this.GetBuilding(TFObject_Dispenser) != INVALID_ENT
			&& this.GetBuilding(TFObject_Teleporter, TFObjectMode_Exit) != INVALID_ENT;
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
	
	public float GetSpyForgetTime(int spy)
	{
		return g_flTFBotSpyForgetTime[this.Client][spy];
	}
	
	public void SetSpyForgetTime(int spy, float val)
	{
		g_flTFBotSpyForgetTime[this.Client][spy] = val;
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
	
	public void RealizeSpy(int spy, bool remember=true)
	{
		if (g_hSDKRealizeSpy)
		{
			// since we are forcing the bot to realize the spy, we should have a short period
			// where the mvm spy detection code will be disabled for them
			if (remember)
			{
				this.SetSpyForgetTime(spy, GetTickedTime()+SPY_REMEMBER_TIME);
			}
			
			SDKCall(g_hSDKRealizeSpy, this.Client, spy);
		}
	}
	
	public bool ShouldRememberSpy(int spy)
	{
		return GetTickedTime() < this.GetSpyForgetTime(spy);
	}
	
	public bool CanScavengeItem(RF2_Item item)
	{
		if (GetClientTeam(this.Client) == TEAM_ENEMY)
		{
			// we can't take these
			if (g_bItemScavengerNoPickup[item.Type])
			{
				return false;
			}
			else if (item.Quality == Quality_Collectors)
			{
				return false;
			}
			
			// steal everything else!
			return true;
		}
		
		// we're probably on RED - only take it if it's ours or is free for taking
		return !IsValidClient(item.Owner) || item.Owner == this.Client || item.Subject == this.Client;
	}
	
	public bool CanScavengeCrate(RF2_Object_Crate crate)
	{
		if (GetPlayerCash(this.Client) < crate.Cost)
			return false;
		
		if (!crate.Active)
			return false;
		
		if (crate.Type == Crate_Weapon)
			return false;
		
		if (crate.Type == Crate_Haunted && GetPlayerItemCount(this.Client, Item_HauntedKey) <= 0)
			return false;
		
		if (crate.Type == Crate_Strange && GetPlayerEquipmentItem(this.Client) != Item_Null)
			return false;
		
		if (GetClientTeam(this.Client) == TEAM_ENEMY)
		{
			// enemies don't want these crates
			if (crate.Type == Crate_Multi || crate.Type == Crate_Collectors)
				return false;
		}
		
		return true;
	}
}

void TFBot_Think(TFBot bot)
{
	float tickedTime = GetTickedTime();
	//ILocomotion locomotion = bot.GetLocomotion();
	CKnownEntity known = bot.GetTarget();
	
	int threat = INVALID_ENT;
	if (known != NULL_KNOWN_ENTITY)
	{
		threat = known.GetEntity();
		if (IsBuilding(threat) && TF2_GetObjectType2(threat) == TFObject_Teleporter)
		{
			// ignore teleporters
			bot.GetVision().ForgetEntity(threat);
			threat = INVALID_ENT;
		}
	}
	
	Enemy enemy = Enemy(bot.Client);
	if (enemy != NULL_ENEMY && enemy == Enemy.FindByInternalName("scavenger_lord"))
	{
		// Scavenger Lord always knows where all players are, though we try to ignore minions
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerSurvivor(i) || IsPlayerMinion(i))
				continue;
				
			if (bot.GetVision().GetKnown(i) == NULL_KNOWN_ENTITY)
			{
				bot.GetVision().AddKnownEntity(i);
			}
		}
	}
	
	float botPos[3];
	bot.GetMyPos(botPos);
	bool aggressiveMode;
	bool rollerMine = IsRollermine(bot.Client);
	TFClassType class = TF2_GetPlayerClass(bot.Client);
	
	// Switch to our desired weapon
	int desiredSlot;
	int desiredWeapon = TFBot_GetDesiredWeapon(bot, desiredSlot);
	if (!rollerMine && desiredWeapon != INVALID_ENT)
	{
		ForceWeaponSwitch(bot.Client, desiredSlot, true);
	}
	
	if (threat > 0 && bot.HasFlag(TFBOTFLAG_SUICIDEBOMBER) && GetEntityFlags(bot.Client) & FL_ONGROUND)
	{
		if (GetClientHealth(bot.Client) <= 1 
			|| DistBetween(bot.Client, threat) <= Enemy(bot.Client).SuicideBombRange*0.25)
		{
			// taunting is what triggers the suicide bomb
			if (!TF2_IsPlayerInCondition(bot.Client, TFCond_Taunting))
			{
				FakeClientCommand(bot.Client, "taunt");
			}
		}
	}
	
	bool isScavenging;
	if (bot.HasFlag(TFBOTFLAG_SCAVENGER) && bot.HasFlag(TFBOTFLAG_DONESCAVENGING) && !rollerMine)
	{
		static float nextScavengeCheckTime[MAXPLAYERS];
		if (nextScavengeCheckTime[bot.Client] <= tickedTime)
		{
			// if there's an item we can grab, continue scavenging
			float cash = GetPlayerCash(bot.Client);
			RF2_Item item = RF2_Item(GetNearestEntity(botPos, "rf2_item"));
			if (item.IsValid() && bot.CanScavengeItem(item))
			{
				bot.ScavengerTarget = EntIndexToEntRef(item.index);
				bot.RemoveFlag(TFBOTFLAG_DONESCAVENGING);
			}
			else if (cash >= g_cvObjectBaseCost.FloatValue * RF2_Object_Crate.GetCostMultiplier())
			{
				// try to find a crate that we can scavenge
				int ent = MaxClients+1;
				while ((ent = FindEntityByClassname(ent, "rf2_object_crate")) != INVALID_ENT)
				{
					RF2_Object_Crate crate = RF2_Object_Crate(ent);
					if (bot.CanScavengeCrate(crate))
					{
						bot.RemoveFlag(TFBOTFLAG_DONESCAVENGING);
						break;
					}
				}
			}
			else if (!IsValidEntity2(bot.ScavengerTarget))
			{
				// find money
				int moneyPack = GetNearestEntity(botPos, "item_currencypack*");
				if (moneyPack != INVALID_ENT)
				{
					bot.ScavengerTarget = EntIndexToEntRef(moneyPack);
					bot.RemoveFlag(TFBOTFLAG_DONESCAVENGING);
				}
			}
			
			nextScavengeCheckTime[bot.Client] = tickedTime+0.5;
		}
	}
	
	if (bot.HasFlag(TFBOTFLAG_SCAVENGER))
	{
		bool scavengerShouldFight = bot.HasFlag(TFBOTFLAG_DONESCAVENGING) && threat > 0 || rollerMine;
		if (scavengerShouldFight)
		{
			// try to switch to a ranged weapon if we have one
			bot.DesiredWeaponSlot = -1;
			int primary = GetPlayerWeaponSlot(bot.Client, WeaponSlot_Primary);
			int secondary = GetPlayerWeaponSlot(bot.Client, WeaponSlot_Secondary);
			if (IsValidEntity2(primary))
			{
				ForceWeaponSwitch(bot.Client, WeaponSlot_Primary, true);
				bot.DesiredWeaponSlot = WeaponSlot_Primary;
			}
			else if (IsValidEntity2(secondary))
			{
				ForceWeaponSwitch(bot.Client, WeaponSlot_Secondary, true);
				bot.DesiredWeaponSlot = WeaponSlot_Secondary;
			}
		}
	}
	
	if (bot.HasFlag(TFBOTFLAG_SCAVENGER) && !bot.HasFlag(TFBOTFLAG_DONESCAVENGING) && !rollerMine)
	{
		isScavenging = true;
		if (IsValidEntity2(bot.ScavengerTarget))
		{
			if (Enemy(bot.Client) != NULL_ENEMY && Enemy(bot.Client).BotScavengerIgnoreEnemies)
			{
				bot.GetVision().ForgetAllKnownEntities();
			}
			
			// path towards our desired item/object
			float distance = DistBetween(bot.Client, bot.ScavengerTarget, true);
			static char classname[64];
			GetEntityClassname(bot.ScavengerTarget, classname, sizeof(classname));
			float targetPos[3];
			GetEntPos(bot.ScavengerTarget, targetPos, true);
			TFBot_PathToPos(bot, targetPos, -1.0, true);
			bot.DesiredWeaponSlot = -1;
			bool isItem;
			if (strcmp2(classname, "rf2_item"))
			{
				isItem = true;
				if (distance <= 22500.0)
				{
					PickupItem(bot.Client, bot.ScavengerTarget);
				}
			}
			else if (strcmp2(classname, "rf2_object_crate"))
			{
				if (RF2_Object_Crate(bot.ScavengerTarget).Cost > GetPlayerCash(bot.Client)
					|| !RF2_Object_Crate(bot.ScavengerTarget).Active)
				{
					bot.ScavengerTarget = INVALID_ENT;
					bot.DesiredWeaponSlot = -1;
				}
				else if (distance <= 22500.0)
				{
					// swing at it once we're close enough
					if (RF2_Object_Crate(bot.ScavengerTarget).Type == Crate_Multi
						&& RF2_Object_Crate(bot.ScavengerTarget).Item == Item_Null)
					{
						// collector multicrate?
						FakeClientCommand(bot.Client, "voicemenu 0 0");	
					}
					
					TFBot_ForceLookAtPos(bot, targetPos);
					bot.AddButtonFlag(IN_ATTACK);
					bot.DesiredWeaponSlot = WeaponSlot_Melee;
				}
				else
				{
					bot.DesiredWeaponSlot = -1;
				}
			}
			
			if (!isItem)
			{
				RF2_Item item = RF2_Item(GetNearestEntity(botPos, "rf2_item", _, 1500.0));
				if (item.IsValid() && bot.CanScavengeItem(item))
				{
					bot.ScavengerTarget = EntIndexToEntRef(item.index);
				}
			}
		}
		else
		{
			// try to find a new target
			bot.ScavengerTarget = INVALID_ENT;
			bot.RemoveButtonFlag(IN_ATTACK);
			bot.DesiredWeaponSlot = -1;
			
			// look for items first
			ArrayList itemList = GetNearestEntities(botPos, "rf2_item");
			for (int i = 0; i < itemList.Length; i++)
			{
				RF2_Item item = RF2_Item(itemList.Get(i));
				if (IsEquipmentItem(item.Type) && GetPlayerEquipmentItem(bot.Client) != Item_Null)
					continue; // skip strange item if we already have one
				
				bool taken;
				for (int a = 1; a <= MaxClients; a++)
				{
					if (a == bot.Client || !IsClientInGame(a) 
					|| !IsFakeClient(a) || !TFBot(a).HasFlag(TFBOTFLAG_SCAVENGER))
						continue;
						
					if (TFBot(a).ScavengerTarget == EntIndexToEntRef(item.index) || !bot.CanScavengeItem(item))
					{
						taken = true;
						break;
					}
				}
				
				if (taken)
					continue; // someone else wants this
				
				bot.ScavengerTarget = EntIndexToEntRef(item.index);
				break;
			}
			
			delete itemList;
			if (bot.ScavengerTarget == INVALID_ENT)
			{
				// no items found, search for crates instead
				ArrayList crateList = GetNearestEntities(botPos, "rf2_object_crate");
				for (int i = 0; i < crateList.Length; i++)
				{
					RF2_Object_Crate crate = RF2_Object_Crate(crateList.Get(i));
					if (!bot.CanScavengeCrate(crate))
						continue;
					
					bool taken;
					for (int a = 1; a <= MaxClients; a++)
					{
						if (a == bot.Client || !IsClientInGame(a) 
						|| !IsFakeClient(a) || !TFBot(a).HasFlag(TFBOTFLAG_SCAVENGER))
							continue;
							
						if (TFBot(a).ScavengerTarget == EntIndexToEntRef(crate.index))
						{
							taken = true;
							break;
						}
					}
					
					if (taken)
						continue; // someone else wants this
					
					bot.ScavengerTarget = EntIndexToEntRef(crate.index);
					break;
				}
				
				delete crateList;
			}
			
			if (bot.ScavengerTarget == INVALID_ENT)
			{
				// we're finished scavenging, add this flag so we can stop
				bot.AddFlag(TFBOTFLAG_DONESCAVENGING);
				bot.DesiredWeaponSlot = -1;
			}
		}
		
		if (!IsValidEntity2(bot.ScavengerTarget))
		{
			bot.ScavengerTarget = INVALID_ENT;
			isScavenging = false;
		}
	}
	else if (threat > 0 && bot.Mission != MISSION_TELEPORTER && class != TFClass_Engineer && !IsValidEntity2(bot.BuildingTarget))
	{
		aggressiveMode = rollerMine || bot.HasFlag(TFBOTFLAG_AGGRESSIVE) || bot.HasFlag(TFBOTFLAG_SUICIDEBOMBER)
			|| GetActiveWeapon(bot.Client) == GetPlayerWeaponSlot(bot.Client, WeaponSlot_Melee);
		
		if (!aggressiveMode && threat > 0)
		{
			float eyePos[3], targetPos[3];
			GetClientEyePosition(bot.Client, eyePos);
			CBaseEntity(threat).WorldSpaceCenter(targetPos);
			TR_TraceRayFilter(eyePos, targetPos, MASK_SOLID, RayType_EndPoint, TraceFilter_DispenserShield, GetEntTeam(bot.Client));
			if (RF2_DispenserShield(TR_GetEntityIndex()).IsValid() && IsLOSClear(bot.Client, TR_GetEntityIndex()))
			{
				// If our target is behind a bubble shield, approach the shield
				aggressiveMode = true;
			}
		}
		
		static float lastStuckTime[MAXPLAYERS];
		if (bot.GetLocomotion().IsStuck())
		{
			lastStuckTime[bot.Client] = GetTickedTime();
		}
		
		bool stuckBoss;
		if (IsBoss(bot.Client) && lastStuckTime[bot.Client]+10.0 > GetTickedTime())
		{
			aggressiveMode = true;
			stuckBoss = true;
		}
		
		// Aggressive AI, relentlessly pursues target
		if (aggressiveMode)
		{
			if (threat > MaxClients || (stuckBoss || g_bPlayerYetiSmash[threat] || !IsInvuln(threat)) && class != TFClass_Spy)
			{
				bot.Mission = MISSION_CHASE;
				TFBot_PathToEntity(bot, threat, 5000.0, true);
			}
		}
	}
	else if (class == TFClass_Engineer && !IsPlayerStunned(bot.Client))
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
			ArrayList sentryAreas = new ArrayList();
			if (area)
			{
				for (int i = 0; i < TheNavAreas.Count; i++)
				{
					tfArea = view_as<CTFNavArea>(TheNavAreas.Get(i));
					if (tfArea && tfArea.HasAttributeTF(SENTRY_SPOT))
					{
						// Does another bot own this area?
						bool owned;
						for (int b = 1; b <= MaxClients; b++)
						{
							if (!IsClientInGame(b) || !IsFakeClient(b) || TF2_GetPlayerClass(b) != TFClass_Engineer)
								continue;
								
							if (g_TFBot[b].SentryArea == tfArea)
							{
								owned = true;
								break;
							}
						}

						if (owned)
							continue;
						
						// Can we make it there?
						if (!TheNavMesh.BuildPath(area, tfArea, NULL_VECTOR, INVALID_FUNCTION))
							continue;
						
						// can't have any other nearby buildings or objects
						if (GetNearestEntity(areaPos, "obj_*", _, 300.0) != INVALID_ENT 
							|| GetNearestEntity(areaPos, "rf2_object*", _, 150.0) != INVALID_ENT)
						{
							continue;
						}

						sentryAreas.Push(tfArea);
					}
				}
			}
			
			// We failed to find an area, try again after a bit
			if (sentryAreas.Length <= 0)
			{
				bot.EngiSearchRetryTime = tickedTime+0.8;
			}
			else
			{
				tfArea = view_as<CTFNavArea>(NULL_AREA);
				while (!tfArea)
				{
					if (sentryAreas.Length <= 0)
					{
						bot.EngiSearchRetryTime = tickedTime+0.8;
						break;
					}

					int index = GetRandomInt(0, sentryAreas.Length-1);
					tfArea = sentryAreas.Get(index);
					tfArea.GetCenter(areaPos);
					TFBot_PathToPos(bot, areaPos, 10000.0, true);
					if (bot.Path.IsValid())
					{
						// We can get to this area, start going there to build
						bot.Mission = MISSION_BUILD;
						bot.SentryArea = tfArea;
						bot.BuildAttempts = 0;
						bot.AttemptingBuild = false;
						break;
					}
					else
					{
						tfArea = view_as<CTFNavArea>(NULL_AREA);
						sentryAreas.Erase(index);
					}
				}
			}

			delete sentryAreas;
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
				if (bot.BuildAttempts >= 3)
				{
					ForceWeaponSwitch(bot.Client, WeaponSlot_Melee);
					bot.BuildAttempts = 0;
					bot.AttemptingBuild = false;
				}
			}
			else
			{
				// Not close enough, keep going.
				TFBot_PathToPos(bot, areaPos, 10000.0);
				bot.AttemptingBuild = false;
				bot.BuildAttempts = 0;
			}
		}
		else if (bot.Mission != MISSION_BUILD) // If we're not building and have an area, check if we need to repair, upgrade, or rebuild
		{
			if (bot.Mission == MISSION_REPAIR)
			{
				int building = EntRefToEntIndex(bot.RepairTarget);
				int prioritizedBuilding = bot.GetPrioritizedBuilding();
				if (bot.HasBuilt && IsValidEntity2(building) &&  (prioritizedBuilding == INVALID_ENT || building == prioritizedBuilding) && 
					(GetEntProp(building, Prop_Send, "m_iHealth") < GetEntProp(building, Prop_Send, "m_iMaxHealth") || GetEntProp(building, Prop_Send, "m_iUpgradeLevel") < 3))
				{
					float pos[3];
					GetEntPos(building, pos);
					pos[2] += 20.0;
					float dist = DistBetween(bot.Client, building);
					
					// Also move around if we're trying to build something so we can place it
					if (dist > 50.0 || GetActiveWeapon(bot.Client) == GetPlayerWeaponSlot(bot.Client, WeaponSlot_Builder))
					{
						TFBot_PathToPos(bot, pos, 10000.0, true);
					}
					
					if (TF2_GetObjectType2(building) == TFObject_Teleporter && dist <= 50.0)
					{
						bot.AddButtonFlag(IN_DUCK);
					}
					else
					{
						bot.RemoveButtonFlag(IN_DUCK);
					}
					
					// Make sure we have our wrench out
					if (GetActiveWeapon(bot.Client) != GetPlayerWeaponSlot(bot.Client, WeaponSlot_Melee))
					{
						bot.DesiredWeaponSlot = WeaponSlot_Melee;
						ForceWeaponSwitch(bot.Client, WeaponSlot_Melee);
					}
					
					TFBot_ForceLookAtPos(bot, pos);
					bot.AddButtonFlag(IN_ATTACK);
				}
				else
				{
					bot.RepairTarget = INVALID_ENT;
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
						if (building == INVALID_ENT)
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
	
	// should we use our strange item?
	if (TFBot_ShouldUseEquipmentItem(bot))
	{
		ActivateStrangeItem(bot.Client);
	}
	
	bool isSniping;
	if (class == TFClass_Sniper)
	{
		int primary = GetPlayerWeaponSlot(bot.Client, WeaponSlot_Primary);
		if (primary != INVALID_ENT && primary == GetActiveWeapon(bot.Client))
		{
			static char classname[32];
			GetEntityClassname(primary, classname, sizeof(classname));
			isSniping = threat > 0 && (StrContains(classname, "tf_weapon_sniperrifle") == 0);
		}
	}
	
	bool isHealing;
	if (class == TFClass_Medic)
	{
		int medigun = GetPlayerWeaponSlot(bot.Client, WeaponSlot_Secondary);
		if (medigun != INVALID_ENT && medigun == GetActiveWeapon(bot.Client))
		{
			isHealing = IsValidClient(GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget"));
		}
	}
	
	// If we aren't doing anything else, wander the map looking for enemies to attack.
	if (!isScavenging && bot.Mission != MISSION_TELEPORTER && !isHealing && !isSniping
		&& (class == TFClass_Spy || threat <= 0)
		&& (class != TFClass_Engineer || bot.EngiSearchRetryTime > 0.0) 
		&& bot.Mission != MISSION_BUILD && !bot.HasBuilt)
	{
		TFBot_TraverseMap(bot);
	}
}

bool TFBot_ShouldUseEquipmentItem(TFBot bot)
{
	if (IsPlayerStunned(bot.Client))
		return false;
		
	int item = GetPlayerEquipmentItem(bot.Client);
	if (item > Item_Null && g_iPlayerEquipmentItemCharges[bot.Client] > 0)
	{
		IVision vision = CBaseEntity(bot.Client).MyNextBotPointer().GetVisionInterface();
		CKnownEntity known = vision.GetPrimaryKnownThreat(true);
		int threat = INVALID_ENT;
		if (known != NULL_KNOWN_ENTITY)
		{
			threat = known.GetEntity();
		}
		
		bool invuln;
		if (threat > 0 && threat <= MaxClients)
		{
			invuln = IsInvuln(threat);
		}
		
		if (threat > 0 && IsBuilding(threat) && TF2_GetObjectType2(threat) != TFObject_Sentry)
		{
			// don't waste on dispensers/teleporters
			return false;
		}
		
		switch (item)
		{
			case ItemStrange_VirtualViewfinder, ItemStrange_PartyHat, ItemStrange_RobotChicken: 
			{
				return threat > 0 && !invuln && vision.IsLookingAtTarget(threat);
			}
			
			case ItemStrange_HeartOfGold:
			{
				// am I low?
				if (GetClientHealth(bot.Client) <= RF2_GetCalculatedMaxHealth(bot.Client)/2)
					return true;
				
				int team = GetClientTeam(bot.Client);
				// are enough nearby teammates low?
				int lowTeammates;
				for (int i = 1; i <= MaxClients; i++)
				{
					if (i == bot.Client || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != team)
						continue;
					
					if (GetClientHealth(i) <= RF2_GetCalculatedMaxHealth(i)/2 && DistBetween(bot.Client, i, true) < 500.0)
					{
						if (IsBoss(i))
							return true; // always heal bosses
						
						lowTeammates++;
					}
				}
				
				return lowTeammates >= 3;
			}
			
			case ItemStrange_LegendaryLid, ItemStrange_CroneDome, ItemStrange_HandsomeDevil, ItemStrange_DemonicDome:
			{
				if (threat > 0 && !invuln && vision.IsLookingAtTarget(threat))
				{
					return DistBetween(bot.Client, threat, true) <= 400000.0;
				}
			}
			
			case ItemStrange_Dragonborn:
			{
				return threat > 0 && DistBetween(bot.Client, threat, true) <= 250000.0;
			}
			
			case ItemStrange_DarkHunter, ItemStrange_NastyNorsemann:
			{
				if (threat <= 0)
					return false;
				
				if (item == ItemStrange_NastyNorsemann && PlayerHasAnyRune(bot.Client))
					return false;

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
		
		return threat > 0 && !invuln;
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
		
		if (stuck || tickedTime >= bot.LastSearchTime + g_cvBotWanderTime.FloatValue || !bot.Path.IsValid() 
		|| GetVectorDistance(myPos, areaPos, true) <= sq(g_cvBotWanderRecomputeDist.FloatValue))
		{
			bot.GoalArea = NULL_AREA;
			bot.Path.Invalidate();
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
			return;
		}
		else if (RF2_GetSubDifficulty() >= SubDifficulty_Impossible && GetClientTeam(bot.Client) == TEAM_ENEMY)
		{
			enemy = GetNearestPlayer(myPos, _, g_cvBotWanderMaxDist.FloatValue, TEAM_SURVIVOR);
		}
		
		if (enemy > 0)
		{
			goal = TheNavMesh.GetNavAreaEntity(enemy, GETNAVAREA_ALLOW_BLOCKED_AREAS, 1000.0);
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

bool TFBot_PathToPos(TFBot &bot, float pos[3], float distance=1000.0, bool ignoreGoal=false)
{
	ILocomotion locomotion = bot.GetLocomotion();
	INextBot nextBot = bot.GetNextBot();
	bool goalReached = bot.Path.ComputeToPos(nextBot, pos, distance);
	
	if ((goalReached || ignoreGoal) && bot.Path.IsValid())
	{
		bot.Path.Update(nextBot);
		locomotion.Run();
	}
	else
	{
		bot.Path.Invalidate();
		locomotion.Stop();
	}
	
	return goalReached;
}

void TFBot_PathToEntity(TFBot bot, int entity, float distance=1000.0, bool ignoreGoal=false)
{
	ILocomotion locomotion = bot.GetLocomotion();
	INextBot nextBot = bot.GetNextBot();
	bool goalReached = bot.Path.ComputeToTarget(nextBot, entity, distance);
	
	if ((goalReached || ignoreGoal) && bot.Path.IsValid())
	{
		bot.Path.Update(nextBot);
		locomotion.Run();
	}
	else
	{
		bot.Path.Invalidate();
		locomotion.Stop();
	}
}

void TFBot_ForceLookAtPos(TFBot bot, const float pos[3])
{
	float angles[3], eyePos[3];
	GetClientEyePosition(bot.Client, eyePos);
	GetVectorAnglesTwoPoints(eyePos, pos, angles);
	
	// avoid DataTable warning spam
	angles[0] = fmin(90.0, angles[0]);
	angles[0] = fmax(-90.0, angles[0]);
	TeleportEntity(bot.Client, _, angles);
	bot.GetLocomotion().FaceTowards(pos); // for good measure
}

void TFBotEngi_AttemptBuild(TFBot &bot)
{
	if (bot.AttemptingBuild)
		return;
	
	bot.Mission = MISSION_BUILD;
	bool buildingSentry = TFBotEngi_BuildObject(bot, TFObject_Sentry);
	if (!buildingSentry && bot.GetBuilding(TFObject_Teleporter, TFObjectMode_Exit) != INVALID_ENT)
	{
		bot.AttemptingBuild = true;
		TFBotEngi_BuildObject(bot, TFObject_Dispenser, _, 60.0);
		CreateTimer(1.0, Timer_TFBotFinishBuilding, GetClientUserId(bot.Client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (!buildingSentry && bot.GetBuilding(TFObject_Dispenser) != INVALID_ENT)
	{
		bot.AttemptingBuild = true;
		TFBotEngi_BuildObject(bot, TFObject_Teleporter, TFObjectMode_Exit, 60.0);
		CreateTimer(1.0, Timer_TFBotFinishBuilding, GetClientUserId(bot.Client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (buildingSentry && (bot.GetBuilding(TFObject_Dispenser) == INVALID_ENT || bot.GetBuilding(TFObject_Teleporter, TFObjectMode_Exit) == INVALID_ENT))
	{
		bot.AttemptingBuild = true;
		CreateTimer(1.5, Timer_TFBotBuildTeleporterExit, GetClientUserId(bot.Client), TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(2.5, Timer_TFBotBuildDispenser, GetClientUserId(bot.Client), TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(3.5, Timer_TFBotFinishBuilding, GetClientUserId(bot.Client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

bool TFBotEngi_BuildObject(TFBot bot, TFObjectType type, TFObjectMode mode=TFObjectMode_Entrance, float yawOffset=0.0)
{
	if (GetBuiltObject(bot.Client, type, mode) != INVALID_ENT)
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
	bot.Path.Invalidate();
	bot.GetLocomotion().Stop();
	bot.AddButtonFlag(IN_DUCK);
	
	DataPack pack;
	const float delay = 0.5;
	CreateDataTimer(delay, Timer_TFBotBuildObject, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(GetClientUserId(bot.Client));
	pack.WriteFloat(yawOffset);
	return true;
}

static void Timer_TFBotBuildDispenser(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return;
		
	if (TFBot(client).Mission != MISSION_BUILD || !IsPlayerAlive(client))
		return;
		
	TFBotEngi_BuildObject(TFBot(client), TFObject_Dispenser, _, 90.0);
}

static void Timer_TFBotBuildTeleporterExit(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return;
	
	if (TFBot(client).Mission != MISSION_BUILD  || !IsPlayerAlive(client))
		return;
	
	TFBotEngi_BuildObject(TFBot(client), TFObject_Teleporter, TFObjectMode_Exit, 180.0);
}

static void Timer_TFBotFinishBuilding(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return;
	
	int entity = MaxClients+1;
	int ref;
	if (!g_hTFBotEngineerBuildings[client])
	{
		g_hTFBotEngineerBuildings[client] = new ArrayList();
	}
	
	while ((entity = FindEntityByClassname(entity, "obj_*")) != INVALID_ENT)
	{
		ref = EntIndexToEntRef(entity);
		if (GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client && g_hTFBotEngineerBuildings[client].FindValue(ref) == INVALID_ENT)
		{
			g_hTFBotEngineerBuildings[client].Push(ref);
		}
	}

	TFBot(client).AttemptingBuild = false;
	TFBot(client).BuildAttempts++;
	TFBot(client).HasBuilt = TFBot(client).BuiltEverything();
	TFBot(client).RemoveButtonFlag(IN_ATTACK);

	if (TFBot(client).Mission == MISSION_BUILD && TFBot(client).HasBuilt)
	{
		TFBot(client).GetLocomotion().Run();
		TFBot(client).Mission = MISSION_NONE;
	}
}

static void Timer_TFBotBuildObject(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if (!client)
		return;
		
	float yawOffset = pack.ReadFloat();
	float angles[3];
	GetClientEyeAngles(client, angles);
	angles[1] += yawOffset;
	TeleportEntity(client, _, angles);
	
	TFBot(client).AddButtonFlag(IN_ATTACK);
	CreateTimer(0.5, Timer_TFBotStopForceAttack, client, TIMER_FLAG_NO_MAPCHANGE);
	
	TFBot(client).RemoveButtonFlag(IN_DUCK);
}

static void Timer_TFBotStopForceAttack(Handle timer, int client)
{
	TFBot(client).RemoveButtonFlag(IN_ATTACK);
}

public Action TFBot_OnPlayerRunCmd(int client, int &buttons, int &impulse)
{
	TFBot bot = TFBot(client);
	if (!bot || !bot.GetNextBot())
	{
		// This can happen, don't know why, but let's just kick the bot and forget about it
		KickClient(client, "Invalid INextBot pointer");
		return Plugin_Continue;
	}
	
	static bool reloading[MAXPLAYERS];
	int activeWep = GetActiveWeapon(client);
	if (activeWep != INVALID_ENT && activeWep != GetPlayerWeaponSlot(client, WeaponSlot_Melee))
	{
		int clip = GetWeaponClip(activeWep);
		int maxClip = GetWeaponClipSize(activeWep);
		if (TF2Attrib_HookValueInt(0, "auto_fires_full_clip", activeWep) != 0)
		{
			CKnownEntity known = bot.GetTarget();
			int target = known != NULL_KNOWN_ENTITY ? known.GetEntity() : INVALID_ENT;
			bool targetInvuln = IsValidClient(target) && IsInvuln(target);
			bool overload = TF2Attrib_HookValueInt(0, "can_overload", activeWep) != 0;
			
			if (clip >= maxClip)
			{
				// unload barrage if target is visible and vulnerable or we can overload the clip (beggars)
				if (overload || target != INVALID_ENT && !targetInvuln)
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
	
	int threat = INVALID_ENT;
	CKnownEntity known = bot.GetTarget(TF2_GetPlayerClass(client) == TFClass_Spy ? false : true);
	if (known != NULL_KNOWN_ENTITY)
	{
		threat = known.GetEntity();
	}
	
	if (IsBoss(client))
	{
		static bool ducking[MAXPLAYERS];
		bool oldDuckState = ducking[client];
		ducking[client] = asBool(GetEntProp(client, Prop_Send, "m_bDucked"));
		if (oldDuckState != ducking[client])
		{
			CalculatePlayerMaxSpeed(client);
		}
	}

	if (!reloading[client] && (buttons & IN_ATTACK || buttons & IN_ATTACK2))
	{
		int secondary = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
		int melee = GetPlayerWeaponSlot(client, WeaponSlot_Melee);
		
		if (secondary != INVALID_ENT && secondary == activeWep)
		{
			static char classname[32];
			GetEntityClassname(secondary, classname, sizeof(classname));
			/*
			bool banner = strcmp2(classname, "tf_weapon_buff_item");
			if (banner && threat > 0 && IsBuilding(threat))
			{
				buttons &= ~IN_ATTACK;
			}
			*/
			
			if ((StrContains(classname, "tf_weapon_jar") == 0 || strcmp2(classname, "tf_weapon_cleaver") || StrContains(classname, "tf_weapon_lunchbox") == 0)
				&& GetEntProp(client, Prop_Send, "m_iAmmo", _, GetEntProp(secondary, Prop_Send, "m_iPrimaryAmmoType")) == 0)
			{
				buttons &= ~IN_ATTACK;
				buttons &= ~IN_ATTACK2;
			}
			else if (strcmp2(classname, "tf_weapon_lunchbox"))
			{
				// Never throw sandvich, always eat
				buttons |= IN_ATTACK;
				buttons &= ~IN_ATTACK2;
			}
		}
		else if (melee != INVALID_ENT && melee == activeWep)
		{
			// Melee bots need to crouch to attack teleporters, they won't realize this by default
			if (threat != INVALID_ENT && threat > MaxClients && IsBuilding(threat) && TF2_GetObjectType2(threat) == TFObject_Teleporter)
			{
				if (DistBetween(bot.Client, threat, true) <= sq(100.0))
					buttons |= IN_DUCK;
			}
		}
	}
	
	bool rocketJumping;
	bool onGround = asBool((GetEntityFlags(client) & FL_ONGROUND));
	TFClassType class = TF2_GetPlayerClass(client);
	if (class == TFClass_Spy)
	{
		// if we are not in our player threat's FOV, go for stab instead
		bool inFov;
		float myPos[3], threatPos[3];
		GetEntPos(client, myPos);
		
		bool sentry, usingSapper, foundBuilding;
		float distance;
		const float maxDistance = 1500.0;
		const float sapRange = 400.0;
		int highestLevel;
		int entity = MaxClients+1;
		int team = GetClientTeam(client);
		int shootTarget = INVALID_ENT;
		int primary = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
		int sapper = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
		int melee = GetPlayerWeaponSlot(client, WeaponSlot_Melee);
		
		// If there are nearby buildings, sap them
		ArrayList sentryList = new ArrayList();
		while ((entity = FindEntityByClassname(entity, "obj_*")) != INVALID_ENT)
		{
			if (GetEntTeam(entity) == team)
				continue;
			
			if (GetEntProp(entity, Prop_Send, "m_bCarried"))
				continue;
			
			if (!bot.GetVision().IsLineOfSightClearToEntity(entity))
				continue;
			
			if (sentry) // Stop searching for sap targets once we find a sentry, but keep adding sentries to our list
			{
				if (TF2_GetObjectType2(entity) == TFObject_Sentry)
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
			}
			
			GetEntPos(entity, threatPos);
			distance = GetVectorDistance(myPos, threatPos, true);
			if (distance <= sq(maxDistance))
			{
				if (bot.GetVision().GetKnown(entity) == NULL_KNOWN_ENTITY)
					bot.GetVision().AddKnownEntity(entity);
				
				bool hasSapper = asBool(GetEntProp(entity, Prop_Send, "m_bHasSapper"));
				if (hasSapper && entity == bot.BuildingTarget)
				{
					bot.BuildingTarget = INVALID_ENT;
				}
				
				if (!hasSapper && !usingSapper && sapper != INVALID_ENT)
				{
					bot.BuildingTarget = entity;
					foundBuilding = true;
					if (distance <= sq(sapRange))
					{
						// Sap immediately if in range
						usingSapper = true;
						bool sapperActive = (GetActiveWeapon(client) == sapper);
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
				if (TF2_GetObjectType2(entity) == TFObject_Sentry)
				{
					sentry = true;
					sentryList.Push(entity);
				}
				
				if (primary != INVALID_ENT && hasSapper && !usingSapper && sentry && !foundBuilding)
				{
					// shoot an already sapped sentry
					shootTarget = entity;
					highestLevel = GetEntProp(entity, Prop_Send, "m_iUpgradeLevel");
				}
			}
		}
		
		bool shouldDecloak = sentry;
		if (IsValidEntity2(bot.BuildingTarget))
		{
			float pos[3];
			GetEntPos(bot.BuildingTarget, pos);
			TFBot_PathToPos(bot, pos, 5000.0);
			shouldDecloak = true;
		}
		else
		{
			bot.BuildingTarget = INVALID_ENT;
		}
		
		bool cloaked = TF2_IsPlayerInCondition(client, TFCond_Cloaked);
		if (shouldDecloak)
		{
			if (cloaked)
			{
				buttons |= IN_ATTACK2;
			}
			else
			{
				buttons &= ~IN_ATTACK2;
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
				if (entity == shootTarget || GetEntTeam(entity) == team)
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
				if (GetActiveWeapon(client) != primary)
				{
					ForceWeaponSwitch(client, WeaponSlot_Primary);
				}
				
				buttons |= IN_ATTACK;
			}
		}
		
		delete sentryList;
		static float timeIdle[MAXPLAYERS];
		if (!sentry && !usingSapper && IsValidClient(threat) && bot.GetVision().IsLineOfSightClearToEntity(threat))
		{
			timeIdle[client] = 0.0;
			// decloak if we have a target and are close enough
			float dist = DistBetween(client, threat, true);
			if (dist <= 360000.0)
			{
				if (cloaked)
				{
					buttons |= IN_ATTACK2;
				}
				else
				{
					buttons &= ~IN_ATTACK2;
				}
			}
			
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
				
				if (primary != INVALID_ENT && !cloaked && bot.GetTimeInFOV(threat) > 1.5 && dist > 122500.0)
				{
					// shoot
					bot.DesiredWeaponSlot = WeaponSlot_Primary;
					if (GetActiveWeapon(client) != primary)
					{
						ForceWeaponSwitch(client, WeaponSlot_Primary);
					}
					
					int perfectAimChance;
					switch (bot.GetSkillLevel())
					{
						case TFBotSkill_Easy: perfectAimChance = 0;
						case TFBotSkill_Normal: perfectAimChance = 20;
						case TFBotSkill_Hard: perfectAimChance = 60;
						case TFBotSkill_Expert: perfectAimChance = 100;
					}
					
					if (RandChanceInt(1, 100, perfectAimChance))
					{
						TFBot_ForceLookAtPos(bot, threatPos);
					}
					
					buttons |= IN_ATTACK;
				}
				else if (melee != INVALID_ENT)
				{
					bot.DesiredWeaponSlot = WeaponSlot_Melee;
					if (GetActiveWeapon(client) != melee)
					{
						ForceWeaponSwitch(client, WeaponSlot_Melee);
					}
					
					const float range = 100.0;
					if (!cloaked && dist <= Pow(range, 2.0))
					{
						buttons |= IN_ATTACK;
					}
					
					// try to get directly behind the player
					float threatCenter[3], pos[3], vec[3];
					GetEntPos(threat, threatCenter, true);
					GetAngleVectors(eyeAng, vec, NULL_VECTOR, NULL_VECTOR);
					NormalizeVector(vec, vec);
					pos[0] = threatCenter[0] - 90.0 * vec[0];
					pos[1] = threatCenter[1] - 90.0 * vec[1];
					pos[2] = threatCenter[2] - 90.0 * vec[2];
					TFBot_PathToPos(bot, pos, 2000.0);
				}
			}
		}
		else
		{
			if (!foundBuilding && !sentry && !usingSapper && bot.BuildingTarget == INVALID_ENT)
			{
				timeIdle[client] += GetTickInterval();
				if (timeIdle[client] >= 2.5)
				{
					// if we aren't doing anything at the moment, cloak
					if (cloaked)
					{
						buttons &= ~IN_ATTACK2;
					}
					else
					{
						buttons |= IN_ATTACK2;
					}
				}
				
			}
			
			SetAllInArray(g_flTFBotSpyTimeInFOV[client], sizeof(g_flTFBotSpyTimeInFOV[]), 0.0);
		}
	}
	else if (!reloading[client] && bot.HasFlag(TFBOTFLAG_ROCKETJUMP) && !bot.HasButtonFlag(IN_RELOAD))
	{
		if (onGround && bot.GetTarget() != NULL_KNOWN_ENTITY)
		{
			int primary = GetPlayerWeaponSlot(client, WeaponSlot_Primary);
			
			if (primary != INVALID_ENT && GetActiveWeapon(client) == primary 
				&& GetWeaponClip(primary) >= GetWeaponClipSize(primary))
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

	if (bot.HasFlag(TFBOTFLAG_SPAMJUMP))
	{
		if (GetEntityFlags(client) & FL_ONGROUND)
		{
			static bool lastJumpState[MAXPLAYERS];
			if (!lastJumpState[client])
			{
				buttons |= IN_JUMP;
				buttons &= ~IN_DUCK;
			}
			
			lastJumpState[client] = !lastJumpState[client];
		}
		else
		{
			buttons &= ~IN_JUMP;
		}
	}
	
	if (bot.HasFlag(TFBOTFLAG_ALWAYSATTACK))
	{
		buttons |= IN_ATTACK;
	}
	
	if (class == TFClass_Medic)
	{
		// should we uber upon sight of an enemy?
		if (Enemy(bot.Client) != NULL_ENEMY && Enemy(bot.Client).BotUberOnSight && bot.GetTarget() != NULL_KNOWN_ENTITY)
		{
			int medigun = GetPlayerWeaponSlot(bot.Client, TFWeaponSlot_Secondary);
			if (medigun != INVALID_ENT && medigun == GetActiveWeapon(bot.Client) && GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel") >= 1.0)
			{
				buttons |= IN_ATTACK2;
			}
		}
	}
	
	// apply our forced button inputs (overrides below)
	buttons |= bot.ForcedButtons;
	
	if (class == TFClass_DemoMan)
	{
		if (activeWep != INVALID_ENT)
		{
			if (activeWep == GetPlayerWeaponSlot(client, WeaponSlot_Melee))
			{
				buttons |= IN_ATTACK2;
			}
			else if (!(buttons & IN_RELOAD))
			{
				static char classname[128];
				GetEntityClassname(activeWep, classname, sizeof(classname));
				if (strcmp2(classname, "tf_weapon_pipebomblauncher"))
				{
					int detCount = Enemy(client) == NULL_ENEMY ? 1 : Enemy(client).BotDemoStickyDetCount;
					int sticky = MaxClients+1;
					int stickyCount;
					while ((sticky = FindEntityByClassname(sticky, "tf_projectile_pipe_remote")) != INVALID_ENT)
					{
						if (GetEntPropEnt(sticky, Prop_Send, "m_hLauncher") == activeWep)
						{
							stickyCount++;
						}
					}
					
					if (stickyCount >= detCount)
					{
						buttons |= IN_ATTACK2;
					}
				}
			}
			
			if (buttons & IN_ATTACK)
			{
				int stickyLauncher = GetPlayerWeaponSlot(client, WeaponSlot_Secondary);
				if (stickyLauncher != INVALID_ENT)
				{
					char classname[128];
					GetEntityClassname(stickyLauncher, classname, sizeof(classname));
					if (strcmp2(classname, "tf_weapon_pipebomblauncher"))
					{
						// Let go of attack - don't charge our sticky launcher
						static bool wasHoldingAttack[MAXPLAYERS];
						float nextAttack = GetEntPropFloat(stickyLauncher, Prop_Send, "m_flNextPrimaryAttack");
						if (GetGameTime() >= nextAttack)
						{
							if (wasHoldingAttack[client])
							{
								wasHoldingAttack[client] = false;
								buttons &= ~IN_ATTACK;
							}
							
							wasHoldingAttack[client] = true;
						}
						else
						{
							wasHoldingAttack[client] = false;
						}
					}
				}
			}
			
		}
		else
		{
			buttons &= ~IN_ATTACK2;
		}
	}
	
	if (bot.ForceBannerSwitch)
	{
		// fix stupid bug where bot doesn't switch away from a banner after blowing the horn
		int weapon = GetActiveWeapon(client);
		bool shouldSwitch;
		if (weapon != INVALID_ENT)
		{
			char classname[128];
			GetEntityClassname(weapon, classname, sizeof(classname));
			if (strcmp2(classname, "tf_weapon_buff_item"))
			{
				shouldSwitch = true;
			}
		}
		
		if (shouldSwitch)
		{
			buttons &= ~IN_ATTACK;
			buttons &= ~IN_ATTACK2;
			buttons &= ~IN_RELOAD;
		}
		else
		{
			bot.ForceBannerSwitch = false;
		}
	}
	
	if (HasJetpack(client))
	{
		if (IsValidEntity2(threat))
		{
			float pos[3], endPos[3];
			GetEntPos(client, pos);
			GetEntPos(threat, endPos);
			float dist = FloatAbs(pos[2]-endPos[2]);
			// stay just above our target
			if (dist > 700.0)
			{
				// descend
				buttons &= ~IN_JUMP;
				buttons &= ~IN_DUCK;
			}
			else if (dist <= 400.0)
			{
				// ascend
				buttons |= IN_JUMP;
				buttons &= ~IN_DUCK;
			}
			else
			{
				// hover
				buttons |= IN_DUCK;
				buttons &= ~IN_JUMP;
			}
		}
	}
	
	return Plugin_Continue;
}

static void Timer_TFBotRocketJump(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)) || GetEntityFlags(client) & FL_ONGROUND || !IsPlayerAlive(client))
		return;
	
	float angles[3];
	GetClientEyeAngles(client, angles);
	angles[0] = 90.0;
	TeleportEntity(client, _, angles); // look directly down
	TFBot(client).AddButtonFlag(IN_ATTACK);
	CreateTimer(0.25, Timer_TFBotStopForceAttack, client, TIMER_FLAG_NO_MAPCHANGE);
}

// -1 = let bot decide
int TFBot_GetDesiredWeapon(TFBot bot, int &slot=WeaponSlot_Primary)
{
	if (Enemy(bot.Client) != NULL_ENEMY)
	{
		int forcedSlot = Enemy(bot.Client).BotForcedWeaponSlot;
		if (forcedSlot != -1)
		{
			int weapon = GetPlayerWeaponSlot(bot.Client, forcedSlot);
			if (weapon != INVALID_ENT)
			{
				slot = forcedSlot;
				return weapon;
			}
		}
	}
	
	int threat = INVALID_ENT;
	CKnownEntity known = bot.GetTarget();
	if (known != NULL_KNOWN_ENTITY)
	{
		threat = known.GetEntity();
	}
	
	if (bot.DesiredWeaponSlot != -1)
	{
		slot = bot.DesiredWeaponSlot;
		return GetPlayerWeaponSlot(bot.Client, bot.DesiredWeaponSlot);
	}
	
	TFClassType class = TF2_GetPlayerClass(bot.Client);
	if (class == TFClass_Scout || class == TFClass_Heavy)
	{
		int lunchbox = GetPlayerWeaponSlot(bot.Client, WeaponSlot_Secondary);
		bool bonk, sandvich;
		if (lunchbox != INVALID_ENT)
		{
			static char classname[32];
			GetEntityClassname(lunchbox, classname, sizeof(classname));
			if (strcmp2(classname, "tf_weapon_lunchbox_drink"))
			{
				bonk = true;
			}
			else if (strcmp2(classname, "tf_weapon_lunchbox"))
			{
				sandvich = true;
			}
		}
		
		if (bonk)
		{
			float drinkEnergy = GetEntPropFloat(bot.Client, Prop_Send, "m_flEnergyDrinkMeter");
			if (drinkEnergy < 100.0 || TF2_IsPlayerInCondition(bot.Client, TFCond_Bonked) || TF2_IsPlayerInCondition(bot.Client, TFCond_CritCola))
			{
				// Switch to primary if available
				int weapon = GetPlayerWeaponSlot(bot.Client, WeaponSlot_Primary);
				slot = WeaponSlot_Primary;
				if (weapon == INVALID_ENT)
				{
					weapon = GetPlayerWeaponSlot(bot.Client, WeaponSlot_Melee);
					slot = WeaponSlot_Melee;
				}
				
				return weapon;
			}
			else if (drinkEnergy >= 100.0)
			{
				slot = WeaponSlot_Secondary;
				return lunchbox;
			}
		}
		else if (sandvich)
		{
			if (GetEntProp(bot.Client, Prop_Send, "m_iAmmo", _, GetEntProp(lunchbox, Prop_Send, "m_iPrimaryAmmoType")) > 0)
			{
				slot = WeaponSlot_Secondary;
				return lunchbox;
			}
			else
			{
				// Switch to primary if available
				int weapon = GetPlayerWeaponSlot(bot.Client, WeaponSlot_Primary);
				slot = WeaponSlot_Primary;
				if (weapon == INVALID_ENT)
				{
					weapon = GetPlayerWeaponSlot(bot.Client, WeaponSlot_Melee);
					slot = WeaponSlot_Melee;
				}
				
				return weapon;
			}
		}
	}
	
	if (TF2_IsPlayerInCondition(bot.Client, TFCond_Charging) 
		|| threat != INVALID_ENT && IsEnemy(bot.Client) && Enemy(bot.Client).BotMeleeDistance > 0.0 && DistBetween(bot.Client, threat) <= Enemy(bot.Client).BotMeleeDistance)
	{
		slot = WeaponSlot_Melee;
		return GetPlayerWeaponSlot(bot.Client, WeaponSlot_Melee);
	}
	
	return INVALID_ENT;
}

public Action Hook_TFBotWeaponCanSwitch(int client, int weapon)
{
	if (!TFBot(client))
		return Plugin_Continue;
	
	int desiredWeapon = TFBot_GetDesiredWeapon(TFBot(client));
	if (desiredWeapon > 0 && weapon != desiredWeapon)
	{
		// do not switch to other weapons if we have a desired weapon
		return Plugin_Stop;
	}
	
	static char classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	if (strcmp2(classname, "tf_weapon_buff_item"))
	{
		if (GetEntPropFloat(client, Prop_Send, "m_flRageMeter") < 100.0)
		{
			// don't switch to banners if we don't have full rage meter
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

public MRESReturn Detour_OnWeaponFired(DHookParam params)
{
	if (!RF2_IsEnabled())
		return MRES_Ignored;
	
	int whoFired = params.Get(1);
	if (IsValidClient(whoFired) && TF2_GetPlayerClass(whoFired) == TFClass_Spy)
	{
		int weapon = params.Get(2);
		static char classname[32];
		GetEntityClassname(weapon, classname, sizeof(classname));
		if (strcmp2(classname, "tf_weapon_invis"))
		{
			return MRES_Supercede; // Silent cloaking
		}
	}
	
	return MRES_Ignored;
}

public MRESReturn DHook_IsAbleToSee(Address vision, DHookReturn returnVal, DHookParam params)
{
	// find the bot
	int bot = INVALID_ENT;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && !IsSpecBot(i))
		{
			IVision botVision = TFBot(i).GetVision();
			if (view_as<Address>(botVision) == vision)
			{
				bot = i;
				break;
			}
		}
	}
	
	if (bot == INVALID_ENT || !IsPlayerAlive(bot))
		return MRES_Ignored;
		
	int subject = params.Get(1);
	if (!IsValidClient(subject))
		return MRES_Ignored;
		
	GameRules_SetProp("m_bPlayingMannVsMachine", true); // match MvM spy logic
	if (TFBot(bot).ShouldRememberSpy(subject) && IsValidClient(subject) && TF2_GetPlayerClass(subject) == TFClass_Spy)
	{
		// we're being forced to remember this spy, so disable the mvm spy detection code
		GameRules_SetProp("m_bPlayingMannVsMachine", false);
	}
	
	float pos[3];
	GetEntPos(subject, pos, true);
	CNavArea area = TheNavMesh.GetNavArea(pos, 200.0);
	if (area == NULL_AREA)
	{
		// subject doesn't have a nav area below them - do our own LOS trace
		// this fixes "godspots"
		float eyePos[3];
		GetClientEyePosition(bot, eyePos);
		TR_TraceRayFilter(eyePos, pos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceFilter_WallsOnly);
		returnVal.Value = !TR_DidHit() && view_as<IVision>(vision).IsVisibleEntityNoticed(subject);
		GameRules_SetProp("m_bPlayingMannVsMachine", false);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

public MRESReturn DHook_IsAbleToSeePost(Address vision, DHookReturn returnVal, DHookParam params)
{
	GameRules_SetProp("m_bPlayingMannVsMachine", false);
	if (returnVal.Value)
	{
		// find the bot
		int bot = INVALID_ENT;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsFakeClient(i) && !IsSpecBot(i))
			{
				IVision botVision = TFBot(i).GetVision();
				if (view_as<Address>(botVision) == vision)
				{
					bot = i;
					break;
				}
			}
		}
		
		if (bot == INVALID_ENT || !IsPlayerAlive(bot))
			return MRES_Ignored;
			
		int subject = params.Get(1);
		if (!IsValidClient(subject))
			return MRES_Ignored;
		
		if (TFBot(bot).ShouldRememberSpy(subject))
		{
			// we can still see this spy, remember him for longer
			TFBot(bot).SetSpyForgetTime(subject, fmin(TFBot(bot).GetSpyForgetTime(subject)+1.0, 
															GetTickedTime()+SPY_REMEMBER_TIME));
		}
	}
	
	return MRES_Ignored;
}

public Action Hook_TFBotTouch(int entity, int other)
{
	if (GetClientTeam(entity) == TEAM_ENEMY && IsValidClient(other) && TF2_GetPlayerClass(other) == TFClass_Spy)
	{
		// match MvM spy logic
		GameRules_SetProp("m_bPlayingMannVsMachine", true);
	}
	
	return Plugin_Continue;
}

public void Hook_TFBotTouchPost(int entity, int other)
{
	if (GetClientTeam(entity) == TEAM_ENEMY && IsValidClient(other) && TF2_GetPlayerClass(other) == TFClass_Spy)
	{
		GameRules_SetProp("m_bPlayingMannVsMachine", false);
	}
}

void UpdateBotQuota()
{
	ConVar quota = FindConVar("tf_bot_quota");
	if (GetTotalHumans(false) <= 0)
	{
		// https://github.com/ValveSoftware/Source-1-Games/issues/5330
		// tf_bot_join_after_player has an issue where it counts the SourceTV/Replay bot as a player, so if either is present and no players are, bots will join.
		// This wastes resources, so make sure there actually are players in the server before we add bots.
		quota.SetInt(0);
	}
	else
	{
		// SourceTV will decrease the max player count in the server browser unless we decrease tf_bot_quota
		bool sourceTv = FindConVar("tv_enable").BoolValue;
		quota.SetInt(MaxClients-g_cvMaxHumanPlayers.IntValue - view_as<int>(sourceTv));
	}
}