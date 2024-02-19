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
			.DefineBoolField("m_bPlayerTeleporterActivation", _, "player_can_activate_teleporter")
			.DefineInputFunc("ForceStartTeleporter", InputFuncValueType_Void, Input_ForceStartTeleporter)
			.DefineOutput("OnTeleporterEventStart")
			.DefineOutput("OnTeleporterEventComplete")
			.DefineOutput("OnTankDestructionStart")
			.DefineOutput("OnTankDestructionComplete")
			.DefineOutput("OnTankDestructionBombDeployed")
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

	property bool AllowTeleporterActivation
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bPlayerTeleporterActivation"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bPlayerTeleporterActivation", value);
		}
	}
}

RF2_GameRules GetRF2GameRules()
{
	return RF2_GameRules(EntRefToEntIndex(g_iRF2GameRulesEntRef));
}

static void OnCreate(RF2_GameRules gamerules)
{
	g_iRF2GameRulesEntRef = EntIndexToEntRef(gamerules.index);
	char teleModel[PLATFORM_MAX_PATH];
	gamerules.GetTeleModel(teleModel, sizeof(teleModel));
	if (teleModel[0] && FileExists(teleModel, true, NULL_STRING))
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
		while ((entity = FindEntityByClassname(entity, "rf2_teleporter_spawn")) != -1)
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
	
	ArrayList objectArray = CreateArray(128);
	ArrayList crateArray = CreateArray();

	const int objectCount = 8;
	int crateWeight = 50;
	int largeWeight = 8;
	int strangeWeight = 8;
	int hauntedWeight = 5;
	int collectorWeight = 8;
	
	// Non-crate object weights are separate
	int workbenchWeight = 16;
	int scrapperWeight = 12;
	int graveWeight = 12;
	
	if (g_iStagesCompleted <= 0)
	{
		hauntedWeight = 0;
	}
	
	char name[64];
	int count;
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
			
			// Non-crate objects
			case CrateType_Max: strcopy(name, sizeof(name), "rf2_object_workbench"), count = workbenchWeight;
			case CrateType_Max+1: strcopy(name, sizeof(name), "rf2_object_scrapper"), count = scrapperWeight;
			case CrateType_Max+2: strcopy(name, sizeof(name), "rf2_object_gravestone"), count = graveWeight;
		}
		
		for (int j = 1; j <= count; j++)
		{
			if (i < CrateType_Max)
			{
				crateArray.Push(i);
			}
			else
			{
				objectArray.PushString(name);
			}
		}
	}
	
	int minCrates = RoundToFloor(float(spawnCount) * 0.7);
	int scrapperCount;
	while (spawns < spawnCount && attempts < 1000)
	{
		GetSpawnPoint(worldCenter, spawnPos, 0.0, distance, _, true);
		nearestObject = GetNearestEntity(spawnPos, "rf2_object*");
		if (nearestObject != -1)
		{
			GetEntPos(nearestObject, nearestPos);
			if (GetVectorDistance(spawnPos, nearestPos, true) <= sq(spreadDistance)) // Too close to another object.
			{
				attempts++;
				continue;
			}
		}
		
		if (spawns > minCrates)
		{
			objectArray.GetString(GetRandomInt(0, objectArray.Length-1), name, sizeof(name));
			if (strcmp2(name, "rf2_object_scrapper"))
			{
				scrapperCount++;
				if (scrapperCount >= g_iStagesCompleted <= 0 && IsSingleplayer(false) ? 1 : 2)
				{
					// Only 1-2 scrappers
					ClearStringFromArrayList(objectArray, "rf2_object_scrapper");
				}
			}
			else if (strcmp2(name, "rf2_object_gravestone"))
			{
				// Only one gravestone
				ClearStringFromArrayList(objectArray, "rf2_object_gravestone");
			}
			
			CreateObject(name, spawnPos);
		}
		else
		{
			SpawnCrate(crateArray.Get(GetRandomInt(0, crateArray.Length-1)), spawnPos);
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

void DespawnObjects()
{
	char classname[128];
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		GetEntityClassname(entity, classname, sizeof(classname));
		if (strcmp2(classname, "rf2_item") || StrContains(classname, "rf2_object") == 0 && !RF2_Object_Base(entity).MapPlaced)
		{
			RemoveEntity2(entity);
		}
	}
}

void GetWorldCenter(float vec[3])
{
	if (EntRefToEntIndex(g_iWorldCenterEntity) != INVALID_ENT_REFERENCE)
	{
		GetEntPos(EntRefToEntIndex(g_iWorldCenterEntity), vec);
		return;
	}
	
	int entity = MaxClients+1;
	char targetName[128];
	bool found;
	
	while ((entity = FindEntityByClassname(entity, "info_target")) != -1)
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
