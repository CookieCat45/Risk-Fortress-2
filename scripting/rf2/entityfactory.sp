/**
 * This file is for any non-NPC entity factories ONLY.
 *
 */
#if defined _RF2_entityfactory_included
 #endinput
#endif
#define _RF2_entityfactory_included

#pragma semicolon 1
#pragma newdecls required

#define MODEL_TELEPORTER "models/rf2/objects/teleporter.mdl"
#define MODEL_TELEPORTER_RADIUS "models/rf2/objects/teleporter_radius.mdl"
#define MODEL_CRATE "models/rf2/objects/crate.mdl"
#define MODEL_CRATE_STRANGE "models/props_hydro/water_barrel.mdl"
#define MODEL_CRATE_HAUNTED "models/player/items/crafting/halloween2015_case.mdl"
#define MODEL_KEY_HAUNTED "models/crafting/halloween2015_gargoyle_key.mdl"
#define MODEL_CRATE_COLLECTOR "models/props_island/mannco_case_small.mdl"
#define MODEL_WORKBENCH "models/props_manor/table_01.mdl"
#define MODEL_SCRAPPER "models/props_trainyard/blast_furnace_skybox002.mdl"

int g_iRF2GameRulesEntRef = -1;

void InstallEntities()
{
	CEntityFactory factory;
	
	factory = new CEntityFactory("rf2_gamerules", RF2GameRules_OnCreate);
	factory.DeriveFromBaseEntity();
	factory.BeginDataMapDesc()
		.DefineStringField("m_szTeleporterModel", _, "teleporter_model")
		.DefineBoolField("m_bPlayerTeleporterActivation", _, "player_can_activate_teleporter")
		.DefineInputFunc("ForceStartTeleporter", InputFuncValueType_Void, RF2GameRules_ForceStartTeleporter)
		.DefineOutput("OnTeleporterEventStart")
		.DefineOutput("OnTeleporterEventComplete")
		.DefineOutput("OnTankDestructionStart")
		.DefineOutput("OnTankDestructionComplete")
		.DefineOutput("OnTankDestructionBombDeployed")
	.EndDataMapDesc();
	factory.Install();
	
	factory = new CEntityFactory("rf2_bot_incursion_point");
	factory.DeriveFromBaseEntity();
	factory.Install();
	
	factory = new CEntityFactory("rf2_object_base", ObjectBase_OnCreate);
	factory.DeriveFromClass("prop_dynamic_override");
	factory.IsAbstract = true;
	factory.BeginDataMapDesc()
		.DefineBoolField("m_bActive", _, "active")
		.DefineBoolField("m_bMapPlaced")
	.EndDataMapDesc();
	factory.Install();
	
	factory = new CEntityFactory("rf2_teleporter_spawn");
	factory.DeriveFromBaseEntity();
	factory.BeginDataMapDesc()
		.DefineOutput("OnChosen")
	.EndDataMapDesc();
	factory.Install();
	
	factory = new CEntityFactory("rf2_item", Item_OnCreate);
	factory.DeriveFromClass("env_sprite");
	factory.BeginDataMapDesc()
		.DefineIntField("m_iIndex", _, "type")
		.DefineBoolField("m_bDropped")
		.DefineEntityField("m_hSpawner")
		.DefineEntityField("m_hSubject")
	.EndDataMapDesc();
	factory.Install();
}

public void CEntityFactory_OnInstalled(const char[] classname, CEntityFactory installedFactory)
{
	CEntityFactory factory;
	
	if (strcmp2(classname, "rf2_object_base"))
	{
		factory = new CEntityFactory("rf2_object_teleporter", Teleporter_OnCreate, Teleporter_OnDestroy);
		factory.DeriveFromFactory(installedFactory);
		factory.BeginDataMapDesc()
			.DefineIntField("m_iEventState")
			.DefineFloatField("m_flCharge")
			.DefineFloatField("m_flRadius")
			.DefineEntityField("m_hBubble")
		.EndDataMapDesc();
		factory.Install();
		
		factory = new CEntityFactory("rf2_object_crate", Crate_OnCreate);
		factory.DeriveFromFactory(installedFactory);
		factory.BeginDataMapDesc()
			.DefineIntField("m_iItem", _, "item")
			.DefineFloatField("m_flCost", _, "cost")
		.EndDataMapDesc();
		factory.Install();
		
		factory = new CEntityFactory("rf2_object_workbench", Workbench_OnCreate, Workbench_OnDestroy);
		factory.DeriveFromFactory(installedFactory);
		factory.BeginDataMapDesc()
			.DefineIntField("m_iItem", _, "type")
			.DefineIntField("m_iQuality", _, "quality")
			.DefineEntityField("m_hDisplaySprite")
		.EndDataMapDesc();
		factory.Install();
		
		factory = new CEntityFactory("rf2_object_scrapper", Scrapper_OnCreate);
		factory.DeriveFromFactory(installedFactory);
		factory.Install();
	}
	else if (strcmp2(classname, "rf2_object_crate"))
	{
		factory = new CEntityFactory("rf2_object_crate_large", CrateLarge_OnCreate);
		factory.DeriveFromFactory(installedFactory);
		factory.Install();
		
		factory = new CEntityFactory("rf2_object_crate_strange", CrateStrange_OnCreate);
		factory.DeriveFromFactory(installedFactory);
		factory.Install();
		
		factory = new CEntityFactory("rf2_object_crate_haunted", CrateHaunted_OnCreate);
		factory.DeriveFromFactory(installedFactory);
		factory.Install();
		
		factory = new CEntityFactory("rf2_object_crate_collector", CrateCollector_OnCreate);
		factory.DeriveFromFactory(installedFactory);
		factory.Install();
	}
}

void PrecacheFactoryAssets()
{
	PrecacheModel(MODEL_TELEPORTER, true);
	PrecacheModel(MODEL_TELEPORTER_RADIUS, true);
	PrecacheModel(MODEL_CRATE, true);
	PrecacheModel(MODEL_CRATE_STRANGE, true);
	PrecacheModel(MODEL_CRATE_HAUNTED, true);
	PrecacheModel(MODEL_CRATE_COLLECTOR, true);
	PrecacheModel(MODEL_WORKBENCH, true);
	PrecacheModel(MODEL_SCRAPPER, true);
	
	AddModelToDownloadsTable(MODEL_TELEPORTER);
	AddModelToDownloadsTable(MODEL_TELEPORTER_RADIUS);
	AddMaterialToDownloadsTable("materials/rf2/objects/matteleporterclean");
	AddMaterialToDownloadsTable("materials/rf2/objects/teleporterbumpmap");
	AddMaterialToDownloadsTable("materials/rf2/objects/teleporterlightmap");
	AddMaterialToDownloadsTable("materials/rf2/objects/sphere_1");
}

int GetRF2GameRules()
{
	return EntRefToEntIndex(g_iRF2GameRulesEntRef);
}

static void RF2GameRules_OnCreate(int entity)
{
	g_iRF2GameRulesEntRef = EntIndexToEntRef(entity);
	char teleModel[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_szTeleporterModel", teleModel, sizeof(teleModel));
	
	if (teleModel[0] && FileExists(teleModel, true, NULL_STRING))
	{
		PrecacheModel(teleModel);
	}
	else
	{
		SetEntPropString(entity, Prop_Data, "m_szTeleporterModel", MODEL_TELEPORTER);
	}
}

static void RF2GameRules_ForceStartTeleporter(int entity, int activator, int caller, int value)
{
	if (GetTeleporterEventState() == TELE_EVENT_INACTIVE)
	{
		PrepareTeleporterEvent(GetTeleporterEntity());
	}
}

static void Item_OnCreate(int entity)
{
	SetEntPropEnt(entity, Prop_Data, "m_hSpawner", -1);
	SetEntPropEnt(entity, Prop_Data, "m_hSubject", -1);
	DispatchKeyValueInt(entity, "rendermode", 9);
	SDKHook(entity, SDKHook_Spawn, Hook_ItemSpawn); // should wait for item index to be set
}

public void Hook_ItemSpawn(int entity)
{
	int index = GetEntProp(entity, Prop_Data, "m_iIndex");
	DispatchKeyValue(entity, "model", g_szItemSprite[index]);
	DispatchKeyValueFloat(entity, "scale", g_flItemSpriteScale[index]);
}

static void ObjectBase_OnCreate(int entity)
{
	SetEntProp(entity, Prop_Send, "m_fEffects", EF_ITEM_BLINK);
	SetEntProp(entity, Prop_Data, "m_bActive", true);
	SetEntProp(entity, Prop_Send, "m_nSolidType", SOLID_OBB);
	
	AcceptEntityInput(entity, "EnableCollision");
}

static void Teleporter_OnCreate(int entity)
{
	char model[PLATFORM_MAX_PATH];
	int gamerules = GetRF2GameRules();
	
	if (gamerules != INVALID_ENT_REFERENCE)
	{
		GetEntPropString(gamerules, Prop_Data, "m_szTeleporterModel", model, sizeof(model));
	}
	else
	{
		model = MODEL_TELEPORTER;
	}
	
	SetEntPropEnt(entity, Prop_Data, "m_hBubble", -1);
	SetEntProp(entity, Prop_Send, "m_nSolidType", SOLID_VPHYSICS);
	SetEntityModel(entity, model);
}

static void Teleporter_OnDestroy(int entity)
{
	int bubble = GetEntPropEnt(entity, Prop_Data, "m_hBubble");
	if (IsValidEntity(bubble))
	{
		RemoveEntity(bubble);
	}
}

static void Crate_OnCreate(int entity)
{
	// There is a case where map entities get created before OnMapStart() can be fired, which crashes the server if we try to set a model.
	if (g_bMapChanging)
	{
		SetEntityRenderMode(entity, RENDER_NONE);
	}
	else
	{
		SetEntityModel(entity, MODEL_CRATE);
	}
	
	SetEntityCollisionGroup(entity, COLLISION_GROUP_CRATE);
	SetEntPropFloat(entity, Prop_Data, "m_flCost", CalculateObjectCost(entity));
	SetEntProp(entity, Prop_Data, "m_iItem", GetRandomItem(79, 20, 1));
	SDKHook(entity, SDKHook_OnTakeDamage, Hook_OnCrateHit);
}

static void CrateLarge_OnCreate(int entity)
{
	if (g_bMapChanging)
	{
		SetEntityRenderMode(entity, RENDER_NONE);
	}
	else
	{
		SetEntityModel(entity, MODEL_CRATE);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 1.35);
	}
	
	SetEntProp(entity, Prop_Data, "m_iItem", GetRandomItem(_, 85, 15));
}

static void CrateStrange_OnCreate(int entity)
{
	if (g_bMapChanging)
	{
		SetEntityRenderMode(entity, RENDER_NONE);
	}
	else
	{
		SetEntityModel(entity, MODEL_CRATE_STRANGE);
		SetEntityRenderColor(entity, 255, 100, 0);
	}
	
	SetEntProp(entity, Prop_Data, "m_iItem", GetRandomItemEx(Quality_Strange));
}

static void CrateHaunted_OnCreate(int entity)
{
	if (g_bMapChanging)
	{
		SetEntityRenderMode(entity, RENDER_NONE);
	}
	else
	{
		SetEntityModel(entity, MODEL_CRATE_HAUNTED);
	}
	
	int item = GetRandomItem(_, _, _, 1, _, 1);
	SetEntProp(entity, Prop_Data, "m_iItem", item);
}

static void CrateCollector_OnCreate(int entity) // our item is decided when we're opened
{
	if (g_bMapChanging)
	{
		SetEntityRenderMode(entity, RENDER_NONE);
	}
	else
	{
		SetEntityModel(entity, MODEL_CRATE_COLLECTOR);
	}
}

static void Workbench_OnCreate(int entity)
{
	SetEntityModel(entity, MODEL_WORKBENCH);
	SetEntityCollisionGroup(entity, COLLISION_GROUP_CRATE);
	
	int result, quality;
	if (RandChanceInt(1, 100, 65, result))
	{
		quality = Quality_Normal;
	}
	else if (result <= 95)
	{
		quality = Quality_Genuine;
	}
	else
	{
		quality = Quality_Unusual;
	}
	
	SetEntProp(entity, Prop_Data, "m_iQuality", quality);
	
	int item = GetRandomItemEx(quality);
	SetEntProp(entity, Prop_Data, "m_iItem", item);
	
	SDKHook(entity, SDKHook_SpawnPost, Hook_WorkbenchSpawnPost);
}

public void Hook_WorkbenchSpawnPost(int entity)
{
	int item = GetEntProp(entity, Prop_Data, "m_iItem");
	int sprite = CreateEntityByName("env_sprite");
	DispatchKeyValue(sprite, "model", g_szItemSprite[item]);
	DispatchKeyValueFloat(sprite, "scale", g_flItemSpriteScale[item]);
	DispatchKeyValueInt(sprite, "rendermode", 9);
	
	float pos[3];
	GetEntPos(entity, pos);
	pos[2] += 50.0;
	TeleportEntity(sprite, pos);
	DispatchSpawn(sprite);
	SetEntPropEnt(entity, Prop_Data, "m_hDisplaySprite", sprite);
}

static void Workbench_OnDestroy(int entity)
{
	int sprite = GetEntPropEnt(entity, Prop_Data, "m_hDisplaySprite");
	if (IsValidEntity(sprite))
	{
		RemoveEntity(sprite);
	}
}

static void Scrapper_OnCreate(int entity)
{
	if (g_bMapChanging)
	{
		SetEntityRenderMode(entity, RENDER_NONE);
	}
	else
	{
		SetEntityModel(entity, MODEL_SCRAPPER);
	}
		
	SetEntityCollisionGroup(entity, COLLISION_GROUP_CRATE);
}