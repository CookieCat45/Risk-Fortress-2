#pragma semicolon 1
#pragma newdecls required

static CEntityFactory g_Factory;
methodmap RF2_GameRules < CBaseEntity
{
	public RF2_GameRules(int entity)
	{
		return view_as<RF2_GameRules>(entity);
	}
	
	public bool IsValid()
	{
		if (!IsValidEntity2(this.index))
		{
			return false;
		}
		
		return CEntityFactory.GetFactoryOfEntity(this.index) == g_Factory;
	}
	
	public static void Init()
	{
		g_Factory = new CEntityFactory("rf2_gamerules", OnCreate);
		g_Factory.DeriveFromBaseEntity(true);
		g_Factory.BeginDataMapDesc()
			.DefineStringField("m_szTeleporterModel", _, "teleporter_model")
			.DefineBoolField("m_bTimerPaused", _, "timer_paused")
			.DefineBoolField("m_bAllowEnemySpawning", _, "allow_enemy_spawning")
			.DefineBoolField("m_bDisableDeath", _, "disable_death")
			.DefineBoolField("m_bDisableObjectSpawning", _, "disable_object_spawning")
			.DefineBoolField("m_bDisableItemSharing", _, "disable_item_sharing")
			.DefineBoolField("m_bUseTeamSpawnForEnemies", _, "enemies_teamspawn")
			.DefineBoolField("m_bAllowQuickBuild", _, "allow_quickbuild")
			.DefineBoolField("m_bAllowMinionSpawning", _, "allow_minion_spawning")
			.DefineBoolField("m_bMusicPaused")
			.DefineInputFunc("ForceStartTeleporter", InputFuncValueType_Void, Input_ForceStartTeleporter)
			.DefineInputFunc("TriggerWin", InputFuncValueType_Void, Input_TriggerWin)
			.DefineInputFunc("GameOver", InputFuncValueType_Void, Input_GameOver)
			.DefineInputFunc("GameVictory", InputFuncValueType_Void, Input_GameVictory)
			.DefineInputFunc("EnableEnemySpawning", InputFuncValueType_Void, Input_EnableEnemySpawning)
			.DefineInputFunc("DisableEnemySpawning", InputFuncValueType_Void, Input_DisableEnemySpawning)
			.DefineInputFunc("EnableDeath", InputFuncValueType_Void, Input_EnableDeath)
			.DefineInputFunc("DisableDeath", InputFuncValueType_Void, Input_DisableDeath)
			.DefineInputFunc("EnableQuickBuild", InputFuncValueType_Void, Input_EnableQuickBuild)
			.DefineInputFunc("DisableQuickBuild", InputFuncValueType_Void, Input_DisableQuickBuild)
			.DefineInputFunc("PlayCustomMusicTrack", InputFuncValueType_Integer, Input_PlayCustomMusicTrack)
			.DefineInputFunc("PauseMusic", InputFuncValueType_Void, Input_PauseMusic)
			.DefineInputFunc("ResumeMusic", InputFuncValueType_Void, Input_ResumeMusic)
			.DefineInputFunc("PlayDefaultMusicTrack", InputFuncValueType_Void, Input_PlayDefaultMusicTrack)
			.DefineInputFunc("TriggerAchievement", InputFuncValueType_Integer, Input_TriggerAchievement)
			.DefineInputFunc("SetEnemyGroup", InputFuncValueType_String, Input_SetEnemyGroup)
			.DefineInputFunc("EnableMinionSpawning", InputFuncValueType_Void, Input_EnableMinionSpawning)
			.DefineInputFunc("DisableMinionSpawning", InputFuncValueType_Void, Input_DisableMinionSpawning)
			.DefineInputFunc("RunRF2Command", InputFuncValueType_String, Input_RunRF2Command)
			.DefineOutput("OnTeleporterEventStart")
			.DefineOutput("OnTeleporterEventComplete")
			.DefineOutput("OnTankDestructionStart")
			.DefineOutput("OnTankDestructionComplete")
			.DefineOutput("OnTankDestructionBombDeployed")
			.DefineOutput("OnTankDestroyed")
			.DefineOutput("OnRoundStart")
			.DefineOutput("OnRoundStartPreLoop")
			.DefineOutput("OnRoundStartPostLoop")
			.DefineOutput("OnWaitingForPlayers")
			.DefineOutput("OnWaitingForPlayersPreLoop")
			.DefineOutput("OnWaitingForPlayersPostLoop")
			.DefineOutput("OnGracePeriodEnd")
			.DefineOutput("OnAllSurvivorsDead")
		.EndDataMapDesc();
		g_Factory.Install();
	}
	
	public int GetTeleModel(char[] buffer, int size)
	{
		return this.GetPropString(Prop_Data, "m_szTeleporterModel", buffer, size);
	}
	
	public void SetTeleModel(const char[] model)
	{
		this.SetPropString(Prop_Data, "m_szTeleporterModel", model);
	}

	property bool TimerPaused
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bTimerPaused"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bTimerPaused", value);
		}
	}

	property bool MusicPaused
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bMusicPaused"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bMusicPaused", value);
		}
	}
	
	property bool AllowEnemySpawning
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bAllowEnemySpawning"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bAllowEnemySpawning", value);
		}
	}

	property bool AllowMinionSpawning
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bAllowMinionSpawning"));
		}

		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bAllowMinionSpawning", value);
		}
	}

	property bool UseTeamSpawnForEnemies
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bUseTeamSpawnForEnemies"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bUseTeamSpawnForEnemies", value);
		}
	}

	property bool DisableDeath
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bDisableDeath"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bDisableDeath", value);
		}
	}

	property bool DisableObjectSpawning
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bDisableObjectSpawning"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bDisableObjectSpawning", value);
		}
	}

	property bool DisableItemSharing
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bDisableItemSharing"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bDisableItemSharing", value);
		}
	}

	property bool AllowQuickBuild
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bAllowQuickBuild"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bAllowQuickBuild", value);
		}
	}
}

RF2_GameRules GetRF2GameRules()
{
	if (!IsValidEntity2(g_iRF2GameRulesEntity))
	{
		int entity = FindEntityByClassname(INVALID_ENT, "rf2_gamerules");
		if (IsValidEntity2(entity))
		{
			g_iRF2GameRulesEntity = entity;
		}
		else
		{
			g_iRF2GameRulesEntity = CreateEntityByName("rf2_gamerules");
		}
	}
	
	return RF2_GameRules(g_iRF2GameRulesEntity);
}

static void OnCreate(RF2_GameRules gamerules)
{
	gamerules.AllowEnemySpawning = true;
	gamerules.AllowMinionSpawning = true;
	char teleModel[PLATFORM_MAX_PATH];
	gamerules.GetTeleModel(teleModel, sizeof(teleModel));
	if (teleModel[0] && FileExists(teleModel, true))
	{
		PrecacheModel2(teleModel);
	}
	else
	{
		RF2_Object_Teleporter.GetDefaultTeleModel(teleModel, sizeof(teleModel));
		gamerules.SetTeleModel(teleModel);
	}
}

public void Input_ForceStartTeleporter(int entity, int activator, int caller, int value)
{
	RF2_Object_Teleporter teleporter = GetCurrentTeleporter();
	if (teleporter.IsValid() && teleporter.EventState == TELE_EVENT_INACTIVE)
	{
		teleporter.Prepare();
	}
}

public void Input_RunRF2Command(int entity, int activator, int caller, const char[] value)
{
	static char command[128], val[1024];
	strcopy(val, sizeof(val), value);
	TrimString(val);
	int split = SplitString(val, " ", command, sizeof(command));
	if (split == -1)
	{
		strcopy(command, sizeof(command), val);
	}
	
	// only allow rf2_ commands
	TrimString(command);
	if (StrContains(command, "rf2_") != 0)
		return;
		
	InsertServerCommand(val);
}

public void Input_TriggerWin(int entity, int activator, int caller, int value)
{
	ForceTeamWin(TEAM_SURVIVOR);
}

public void Input_GameOver(int entity, int activator, int caller, int value)
{
	if (!g_bGameOver)
		GameOver();
}

public void Input_GameVictory(int entity, int activator, int caller, int value)
{
	if (!g_bGameWon)
		GameVictory();
}

public void Input_EnableEnemySpawning(int entity, int activator, int caller, int value)
{
	RF2_GameRules(entity).AllowEnemySpawning = true;
}

public void Input_DisableEnemySpawning(int entity, int activator, int caller, int value)
{
	RF2_GameRules(entity).AllowEnemySpawning = false;
}

public void Input_EnableDeath(int entity, int activator, int caller, int value)
{
	RF2_GameRules(entity).DisableDeath = false;
}

public void Input_DisableDeath(int entity, int activator, int caller, int value)
{
	RF2_GameRules(entity).DisableDeath = true;
}

public void Input_EnableQuickBuild(int entity, int activator, int caller, int value)
{
	RF2_GameRules(entity).AllowQuickBuild = true;
}

public void Input_DisableQuickBuild(int entity, int activator, int caller, int value)
{
	RF2_GameRules(entity).AllowQuickBuild = false;
}

public void Input_TriggerAchievement(int entity, int activator, int caller, int value)
{
	if (IsValidClient(activator))
		TriggerAchievement(activator, value);
}

public void Input_SetEnemyGroup(int entity, int activator, int caller, const char[] value)
{
	strcopy(g_szCurrentEnemyGroup, sizeof(g_szCurrentEnemyGroup), value);
}

public void Input_PlayCustomMusicTrack(int entity, int activator, int caller, int value)
{
	PlayCustomMusicTrackAll(value);
}

public void Input_PauseMusic(int entity, int activator, int caller, const char[] value)
{
	RF2_GameRules(entity).MusicPaused = true;
	StopMusicTrackAll();
}

public void Input_ResumeMusic(int entity, int activator, int caller, const char[] value)
{
	RF2_GameRules(entity).MusicPaused = false;
	PlayMusicTrackAll();
}

public void Input_PlayDefaultMusicTrack(int entity, int activator, int caller, const char[] value)
{
	StopMusicTrackAll();
	PlayMusicTrackAll();
}

public void Input_EnableMinionSpawning(int entity, int activator, int caller, const char[] value)
{
	RF2_GameRules(entity).AllowMinionSpawning = true;
}

public void Input_DisableMinionSpawning(int entity, int activator, int caller, const char[] value)
{
	RF2_GameRules(entity).AllowMinionSpawning = false;
}

int SpawnObjects()
{
	if (GetRF2GameRules().DisableObjectSpawning)
		return 0;
	
	// Make sure everything is gone first
	DespawnObjects();
	int entity = MaxClients+1;
	if (!g_bTankBossMode)
	{
		// Find our teleporter spawnpoints
		ArrayList teleporterSpawns = new ArrayList();
		entity = MaxClients+1;
		while ((entity = FindEntityByClassname(entity, "rf2_teleporter_spawn")) != INVALID_ENT)
		{
			teleporterSpawns.Push(entity);
		}
		
		if (teleporterSpawns.Length > 0)
		{
			// now spawn the teleporter at a random location
			int spawnPoint = teleporterSpawns.Get(GetRandomInt(0, teleporterSpawns.Length-1));
			RF2_Object_Teleporter teleporter = RF2_Object_Teleporter(CreateEntityByName("rf2_object_teleporter"));
			float pos[3], angles[3];
			GetEntPos(spawnPoint, pos);
			GetEntPropVector(spawnPoint, Prop_Send, "m_angRotation", angles);
			teleporter.Teleport(pos, angles);
			teleporter.Spawn();
			g_iTeleporterEntRef = EntIndexToEntRef(teleporter.index);
			FireEntityOutput(spawnPoint, "OnChosen");
		}
		
		delete teleporterSpawns;
	}
	
	RF2_Object_Altar altar;
	if (DoesUnderworldExist() && !IsInUnderworld())
	{
		ArrayList altarSpawns = new ArrayList();
		entity = MaxClients+1;
		while ((entity = FindEntityByClassname(entity, "rf2_altar_spawn")) != INVALID_ENT)
		{
			altarSpawns.Push(entity);
		}
		
		if (altarSpawns.Length > 0)
		{
			int spawnPoint = altarSpawns.Get(GetRandomInt(0, altarSpawns.Length-1));
			altar = RF2_Object_Altar(CreateEntityByName("rf2_object_altar"));
			float pos[3], angles[3];
			GetEntPos(spawnPoint, pos);
			GetEntPropVector(spawnPoint, Prop_Send, "m_angRotation", angles);
			altar.Teleport(pos, angles);
			altar.Spawn();
			FireEntityOutput(spawnPoint, "OnChosen");
		}
		
		delete altarSpawns;
	}
	
	// now spawn regular objects
	int maxSurvivors = g_cvMaxSurvivors.IntValue;
	int survivorCount = RF2_GetSurvivorCount();
	float playerMultiplier = 1.0 + (float((survivorCount-1)) * 0.85);
	int spawnCount = RoundToFloor(g_cvObjectBaseCount.FloatValue * playerMultiplier) + RoundToFloor(g_flDifficultyCoeff / (g_cvSubDifficultyIncrement.FloatValue / 5.0));
	int maxSpawns = RoundToFloor(g_cvMaxObjects.FloatValue * fmin(1.0, 1.0 - 0.1*float(maxSurvivors-(survivorCount-1))));
	spawnCount = imin(spawnCount, maxSpawns);
	int spawns, attempts, nearestObject;
	float spawnPos[3], nearestPos[3], worldCenter[3], worldMins[3], worldMaxs[3];
	float spreadDistance = g_cvObjectSpreadDistance.FloatValue;
	
	// Need to get the size of the map so we know how far we can spawn objects
	GetEntPropVector(0, Prop_Send, "m_WorldMins", worldMins);
	GetEntPropVector(0, Prop_Send, "m_WorldMaxs", worldMaxs);
	float length = FloatAbs(worldMins[0]) + FloatAbs(worldMaxs[0]);
	float width = FloatAbs(worldMins[1]) + FloatAbs(worldMaxs[1]);
	float distance = SquareRoot(length * width);
	int worldCenterEnt = GetWorldCenter(worldCenter);
	if (worldCenterEnt == INVALID_ENT)
	{
		char mapName[256];
		GetCurrentMap(mapName, sizeof(mapName));
		// minor issue, so only LogMessage
		LogMessage("Warning! Map %s has no rf2_world_center entity!!", mapName);
	}
	
	ArrayList objectArray = new ArrayList(128);
	ArrayList crateArray = new ArrayList();
	int crateWeight = 50;
	int largeWeight = 8;
	int strangeWeight = 8;
	int hauntedWeight = 5;
	int collectorWeight = 8;
	
	// Non-crate object weights are separate
	int workbenchWeight = 20;
	int scrapperWeight = 5;
	int rouletteWeight = 5;
	int graveWeight = 3;
	int pumpkinWeight = 1;
	
	if (!altar.IsValid())
	{
		pumpkinWeight = 0;
	}
	
	if (g_iStagesCompleted <= 0)
	{
		hauntedWeight = 0;
	}
	
	char name[128];
	int count;
	const int objectCount = 11;
	for (int i = 1; i <= objectCount; i++)
	{
		switch (i-1)
		{
			/*
			* Don't forget to increment objectCount when adding new objects here!!!
			*/

			case Crate_Normal: count = crateWeight;
			case Crate_Large: count = largeWeight;
			case Crate_Strange: count = strangeWeight;
			case Crate_Haunted: count = hauntedWeight;
			case Crate_Collectors: count = collectorWeight;
			case Crate_Unusual: continue; // never spawn naturally
			#if !defined DEVONLY
			case Crate_Weapon: continue;
			#endif
			
			// Non-crate objects
			case CrateType_Max: strcopy(name, sizeof(name), "rf2_object_workbench"), count = workbenchWeight;
			case CrateType_Max+1: strcopy(name, sizeof(name), "rf2_object_scrapper"), count = scrapperWeight;
			case CrateType_Max+2: strcopy(name, sizeof(name), "rf2_object_gravestone"), count = graveWeight;
			case CrateType_Max+3: strcopy(name, sizeof(name), "rf2_object_pumpkin"), count = pumpkinWeight;
			case CrateType_Max+4: strcopy(name, sizeof(name), "rf2_object_pedestal"), count = rouletteWeight;
		}
		
		for (int j = 1; j <= count; j++)
		{
			if (i-1 < CrateType_Max)
			{
				crateArray.Push(i-1);
			}
			else
			{
				objectArray.PushString(name);
			}
		}
	}
	
	const float cratePercent = 0.7;
	int minCrates = RoundToFloor(float(spawnCount) * cratePercent);
	int extraMisc = g_cvExtraMiscObjects.IntValue;
	int bonusCrates;
	int playerBonus;
	if (g_iLoopCount <= 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerSurvivor(i))
			{
				playerBonus = GetPlayerCrateBonus(i);
				if (playerBonus > 0)
				{
					bonusCrates += playerBonus;
					PrintToServer("[RF2] Player %N is lagging behind! Spawning %i extra crates for them.", i, playerBonus);
				}
			}
		}
	}
	
	PrintToServer("[RF2] Object Spawn Counts\nCrates: %i (Bonus: %i)\nOther: %i", minCrates+bonusCrates, bonusCrates, spawnCount-minCrates-bonusCrates);
	int scrapperCount, strangeCrates;
	int strangeCrateLimit = imax(imin(RoundToCeil(float(minCrates)*0.08), survivorCount), 4);
	RF2_Object_Crate crate;
	bool remove;
	while (spawns < spawnCount+bonusCrates+extraMisc)
	{
		GetSpawnPoint(worldCenter, spawnPos, 0.0, distance, _, true);
		if (attempts < 1000)
		{
			nearestObject = GetNearestEntity(spawnPos, "rf2_object*");
			if (nearestObject != INVALID_ENT)
			{
				GetEntPos(nearestObject, nearestPos);
				if (GetVectorDistance(spawnPos, nearestPos, true) <= sq(spreadDistance)) // Too close to another object.
				{
					attempts++;
					continue;
				}
			}
		}
		
		if (spawns > minCrates+bonusCrates)
		{
			remove = false;
			objectArray.GetString(GetRandomInt(0, objectArray.Length-1), name, sizeof(name));
			if (strcmp2(name, "rf2_object_scrapper"))
			{
				scrapperCount++;
				// Only 3 scrappers
				if (scrapperCount >= 3)
					remove = true;
				
			}
			else if (strcmp2(name, "rf2_object_gravestone") || strcmp2(name, "rf2_object_pumpkin"))
			{
				// Only one gravestone/pumpkin
				remove = true;
			}
			
			if (remove)
			{
				char name2[128];
				for (int i = objectArray.Length-1; i >= 0; i--)
				{
					objectArray.GetString(i, name2, sizeof(name2));
					if (strcmp2(name, name2))
					{
						objectArray.Erase(i);
					}
				}
			}
			
			CreateObject(name, spawnPos);
		}
		else
		{
			crate = SpawnCrate(crateArray.Get(GetRandomInt(0, crateArray.Length-1)), spawnPos, spawns > minCrates);
			if (crate.Type == Crate_Strange)
			{
				strangeCrates++;
				if (strangeCrates >= strangeCrateLimit)
				{
					for (int i = 0; i < crateArray.Length; i++)
					{
						if (crateArray.Get(i) == Crate_Strange)
						{
							crateArray.Erase(i);
							i--;
						}
					}
				}
			}
		}
		
		spawns++;
	}
	
	// barrels are separate from the object spawn limit, because they don't matter enough to take up spawn slots for other objects
	int barrelCount = g_cvBarrelSpawnCount.IntValue;
	int barrelSpawns;
	attempts = 0;
	while (barrelSpawns < barrelCount && attempts < 100)
	{
		GetSpawnPoint(worldCenter, spawnPos, 0.0, distance, _, true);
		nearestObject = GetNearestEntity(spawnPos, "rf2_object*");
		if (nearestObject != INVALID_ENT)
		{
			GetEntPos(nearestObject, nearestPos);
			if (GetVectorDistance(spawnPos, nearestPos, true) <= sq(spreadDistance)) // Too close to another object.
			{
				attempts++;
				continue;
			}
		}

		CreateObject("rf2_object_barrel", spawnPos, true, 10.0);
		barrelSpawns++;
	}

	if (IsItemSharingEnabled(false))
	{
		CalculateSurvivorItemShare(false);	
	}
	
	delete objectArray;
	delete crateArray;
	return spawns;
}

void DespawnObjects(bool force=false)
{
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "rf2_item")) != INVALID_ENT)
	{
		RemoveEntity(entity);
	}
	
	while ((entity = FindEntityByClassname(entity, "rf2_object*")) != INVALID_ENT)
	{
		if (force || !RF2_Object_Base(entity).MapPlaced)
		{
			RemoveEntity(entity);
		}
	}
}
