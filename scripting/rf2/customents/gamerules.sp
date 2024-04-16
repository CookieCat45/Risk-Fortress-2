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
		if (this.index == 0 || !IsValidEntity2(this.index))
		{
			return false;
		}
		
		return CEntityFactory.GetFactoryOfEntity(this.index) == g_Factory;
	}
	
	public static void Init()
	{
		g_Factory = new CEntityFactory("rf2_gamerules", OnCreate);
		g_Factory.DeriveFromBaseEntity();
		g_Factory.BeginDataMapDesc()
			.DefineStringField("m_szTeleporterModel", _, "teleporter_model")
			.DefineBoolField("m_bTimerPaused", _, "timer_paused")
			.DefineBoolField("m_bAllowEnemySpawning", _, "allow_enemy_spawning")
			.DefineInputFunc("ForceStartTeleporter", InputFuncValueType_Void, Input_ForceStartTeleporter)
			.DefineInputFunc("TriggerWin", InputFuncValueType_Void, Input_TriggerWin)
			.DefineInputFunc("GameOver", InputFuncValueType_Void, Input_GameOver)
			.DefineInputFunc("EnableEnemySpawning", InputFuncValueType_Void, Input_EnableEnemySpawning)
			.DefineInputFunc("DisableEnemySpawning", InputFuncValueType_Void, Input_DisableEnemySpawning)
			.DefineInputFunc("TriggerAchievement", InputFuncValueType_Integer, Input_TriggerAchievement)
			.DefineOutput("OnTeleporterEventStart")
			.DefineOutput("OnTeleporterEventComplete")
			.DefineOutput("OnTankDestructionStart")
			.DefineOutput("OnTankDestructionComplete")
			.DefineOutput("OnTankDestructionBombDeployed")
			.DefineOutput("OnRoundStart")
			.DefineOutput("OnRoundStartPreLoop")
			.DefineOutput("OnRoundStartPostLoop")
			.DefineOutput("OnWaitingForPlayers")
			.DefineOutput("OnWaitingForPlayersPreLoop")
			.DefineOutput("OnWaitingForPlayersPostLoop")
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
}

RF2_GameRules GetRF2GameRules()
{
	if (g_iRF2GameRulesEntRef == INVALID_ENT || EntRefToEntIndex(g_iRF2GameRulesEntRef) == INVALID_ENT)
	{
		int entity = FindEntityByClassname(INVALID_ENT, "rf2_gamerules");
		if (entity != INVALID_ENT)
		{
			g_iRF2GameRulesEntRef = EntIndexToEntRef(entity);
		}
		else
		{
			entity = CreateEntityByName("rf2_gamerules");
			if (entity != INVALID_ENT)
			{
				g_iRF2GameRulesEntRef = EntIndexToEntRef(entity);
			}
		}
	}
	
	int gameRules = EntRefToEntIndex(g_iRF2GameRulesEntRef);
	if (gameRules == INVALID_ENT)
	{
		LogError("Warning! Failed to find rf2_gamerules entity");
	}
	
	return RF2_GameRules(gameRules);
}

static void OnCreate(RF2_GameRules gamerules)
{
	gamerules.AllowEnemySpawning = true;
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

public void Input_TriggerWin(int entity, int activator, int caller, int value)
{
	ForceTeamWin(TEAM_SURVIVOR);
}

public void Input_GameOver(int entity, int activator, int caller, int value)
{
	GameOver();
}

public void Input_EnableEnemySpawning(int entity, int activator, int caller, int value)
{
	RF2_GameRules(entity).AllowEnemySpawning = true;
}

public void Input_DisableEnemySpawning(int entity, int activator, int caller, int value)
{
	RF2_GameRules(entity).AllowEnemySpawning = false;
}

public void Input_TriggerAchievement(int entity, int activator, int caller, int value)
{
	if (IsValidClient(activator))
		TriggerAchievement(activator, value);
}

int SpawnObjects()
{
	// Make sure everything is gone first
	DespawnObjects();
	int entity = MaxClients+1;
	if (!g_bTankBossMode)
	{
		ArrayList teleporterSpawns = CreateArray();
		// Find our teleporter spawnpoints
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
		else
		{
			char mapName[256];
			GetCurrentMap(mapName, sizeof(mapName));
			LogError("Map %s has no rf2_teleporter_spawn entities!!", mapName);
		}
		
		delete teleporterSpawns;
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
	GetWorldCenter(worldCenter);
	
	ArrayList objectArray = new ArrayList(128);
	ArrayList crateArray = new ArrayList();
	
	int crateWeight = 50;
	int largeWeight = 8;
	int strangeWeight = 8;
	int hauntedWeight = 5;
	int collectorWeight = 8;
	
	// Non-crate object weights are separate
	int workbenchWeight = 16;
	int scrapperWeight = 12;
	int graveWeight = 8;
	
	if (g_iStagesCompleted <= 0)
	{
		hauntedWeight = 0;
	}
	
	char name[64];
	int count;
	const int objectCount = 9;
	for (int i = 1; i <= objectCount; i++)
	{
		switch (i-1)
		{
			// Don't forget to increment objectCount when adding new objects here
			case Crate_Normal: count = crateWeight;
			case Crate_Large: count = largeWeight;
			case Crate_Strange: count = strangeWeight;
			case Crate_Haunted: count = hauntedWeight;
			case Crate_Collectors: count = collectorWeight;
			case Crate_Unusual: continue; // never spawn naturally
			
			// Non-crate objects
			case CrateType_Max: strcopy(name, sizeof(name), "rf2_object_workbench"), count = workbenchWeight;
			case CrateType_Max+1: strcopy(name, sizeof(name), "rf2_object_scrapper"), count = scrapperWeight;
			case CrateType_Max+2: strcopy(name, sizeof(name), "rf2_object_gravestone"), count = graveWeight;
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
	
	int minCrates = RoundToFloor(float(spawnCount) * 0.75);
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
	
	PrintToServer("[RF2] Object Spawn Counts\nCrates: %i (Bonus: %i)\nOther: %i", minCrates+bonusCrates, bonusCrates, spawnCount-minCrates);
	int scrapperCount;
	bool graveStoneSpawn;
	while (spawns < spawnCount+bonusCrates && attempts < 1000)
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
		
		if (spawns > minCrates+bonusCrates)
		{
			objectArray.GetString(GetRandomInt(0, objectArray.Length-1), name, sizeof(name));
			if (strcmp2(name, "rf2_object_scrapper"))
			{
				// Only 2 scrappers
				if (scrapperCount >= 2)
					continue;
				
				scrapperCount++;
			}
			else if (strcmp2(name, "rf2_object_gravestone"))
			{
				// Only one gravestone
				if (graveStoneSpawn)
					continue;
				
				graveStoneSpawn = true;
			}
			
			CreateObject(name, spawnPos);
		}
		else
		{
			SpawnCrate(crateArray.Get(GetRandomInt(0, crateArray.Length-1)), spawnPos, spawns > minCrates);
		}
		
		spawns++;
	}
	
	if (IsItemSharingEnabled())
	{
		CalculateSurvivorItemShare(false);	
	}
	
	delete objectArray;
	delete crateArray;
	return spawns;
}

void DespawnObjects(bool force=false)
{
	char classname[128];
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "rf2_*")) != INVALID_ENT)
	{
		GetEntityClassname(entity, classname, sizeof(classname));
		if (strcmp2(classname, "rf2_item") || StrContains(classname, "rf2_object") == 0 && (force || !RF2_Object_Base(entity).MapPlaced))
		{
			RemoveEntity2(entity);
		}
	}
}

void GetWorldCenter(float vec[3])
{
	if (EntRefToEntIndex(g_iWorldCenterEntity) != INVALID_ENT)
	{
		GetEntPos(EntRefToEntIndex(g_iWorldCenterEntity), vec);
		return;
	}
	
	int entity = MaxClients+1;
	char targetName[128];
	bool found;
	
	while ((entity = FindEntityByClassname(entity, "info_target")) != INVALID_ENT)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));
		if (strcmp2(targetName, WORLD_CENTER))
		{
			GetEntPos(entity, vec);
			found = true;
			g_iWorldCenterEntity = EntIndexToEntRef(entity);
			break;
		}
	}

	if (!found) // last resort. 0 0 0 is not always the center of the map, but sometimes it is
	{
		CopyVectors(NULL_VECTOR, vec);
	}
}
