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
#define MODEL_SHURIKEN "models/rf2/projectiles/shuriken.mdl"
#define MODEL_BOMB "models/weapons/w_models/w_cannonball.mdl"
#define MODEL_KUNAI "models/workshop_partner/weapons/c_models/c_shogun_kunai/c_shogun_kunai.mdl"

int g_iRF2GameRulesEntRef = -1;

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
	PrecacheModel(MODEL_SHURIKEN, true);
	PrecacheModel(MODEL_BOMB, true);
	PrecacheModel(MODEL_KUNAI, true);
	
	AddModelToDownloadsTable(MODEL_TELEPORTER);
	AddModelToDownloadsTable(MODEL_TELEPORTER_RADIUS);
	AddModelToDownloadsTable(MODEL_CRATE);
	AddModelToDownloadsTable(MODEL_SHURIKEN);
	AddMaterialToDownloadsTable("materials/rf2/objects/matteleporterclean");
	AddMaterialToDownloadsTable("materials/rf2/objects/teleporterbumpmap");
	AddMaterialToDownloadsTable("materials/rf2/objects/teleporterlightmap");
	AddMaterialToDownloadsTable("materials/rf2/objects/sphere_1");
	AddMaterialToDownloadsTable("materials/rf2/projectiles/body");
	AddMaterialToDownloadsTable("materials/rf2/projectiles/blade");
	AddMaterialToDownloadsTable("materials/rf2/projectiles/ring");
}

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
		.DefineEntityField("m_hItemOwner")
		.DefineEntityField("m_hSubject")
		.DefineEntityField("m_hOriginalItemOwner")
	.EndDataMapDesc();
	factory.Install();
	
	factory = new CEntityFactory("rf2_projectile_base", Projectile_OnCreate);
	factory.DeriveFromClass("prop_physics_override");
	factory.BeginDataMapDesc()
		.DefineFloatField("m_flBaseDamage")
		.DefineVectorField("m_vecHitboxMins")
		.DefineVectorField("m_vecHitboxMaxs")
		.DefineIntField("m_nProcItem")
		.DefineBoolField("m_bHit")
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
	else if (strcmp2(classname, "rf2_projectile_base"))
	{
		factory = new CEntityFactory("rf2_projectile_shuriken", Shuriken_OnCreate);
		factory.DeriveFromFactory(installedFactory);
		factory.Install();

		factory = new CEntityFactory("rf2_projectile_bomb", Bomb_OnCreate);
		factory.DeriveFromFactory(installedFactory);
		factory.BeginDataMapDesc()
			.DefineFloatField("m_flExplodeRadius")
			.DefineFloatField("m_flDirectDamage")
			.DefineEntityField("m_hDirectTarget")
		.EndDataMapDesc();
		factory.Install();
		
		factory = new CEntityFactory("rf2_projectile_kunai", Kunai_OnCreate);
		factory.DeriveFromFactory(installedFactory);
		factory.Install();
	}
}

bool IsEntityFromFactory(int entity)
{
	CEntityFactory factory = CEntityFactory.GetFactoryOfEntity(entity);
	if (!factory)
		return false;
		
	char classname[128];
	factory.GetClassname(classname, sizeof(classname));
	return StrContains(classname, "rf2_") == 0;
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
	SetEntPropEnt(entity, Prop_Data, "m_hItemOwner", -1);
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
	
	static char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (!strcmp2(classname, "rf2_object_teleporter"))
	{
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", FSOLID_TRIGGER_TOUCH_DEBRIS|FSOLID_TRIGGER|FSOLID_NOT_SOLID|FSOLID_CUSTOMBOXTEST);
		SetEntProp(entity, Prop_Send, "m_nSolidType", SOLID_OBB);
		SetEntityCollisionGroup(entity, COLLISION_GROUP_DEBRIS_TRIGGER);
	}
	
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
	SetEntityModel(entity, MODEL_CRATE);
	SetEntPropFloat(entity, Prop_Data, "m_flCost", CalculateObjectCost(entity));
	SetEntProp(entity, Prop_Data, "m_iItem", GetRandomItem(79, 20, 1));
	SDKHook(entity, SDKHook_OnTakeDamage, Hook_OnCrateHit);
}

static void CrateLarge_OnCreate(int entity)
{
	SetEntityModel(entity, MODEL_CRATE);
	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 1.35);
	SetEntProp(entity, Prop_Data, "m_iItem", GetRandomItem(_, 85, 15));
}

static void CrateStrange_OnCreate(int entity)
{
	SetEntityModel(entity, MODEL_CRATE_STRANGE);
	SetEntityRenderColor(entity, 255, 100, 0);
	SetEntProp(entity, Prop_Data, "m_iItem", GetRandomItemEx(Quality_Strange));
}

static void CrateHaunted_OnCreate(int entity)
{
	SetEntityModel(entity, MODEL_CRATE_HAUNTED);
	int item = GetRandomItem(_, _, _, 1);
	SetEntProp(entity, Prop_Data, "m_iItem", item);
}

static void CrateCollector_OnCreate(int entity) // our item is decided when we're opened
{
	SetEntityModel(entity, MODEL_CRATE_COLLECTOR);
}

static void Workbench_OnCreate(int entity)
{
	SetEntityModel(entity, MODEL_WORKBENCH);
	int result, quality;
	if (RandChanceInt(1, 100, 65, result))
	{
		quality = Quality_Normal;
	}
	else if (result <= 98)
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

	switch (GetItemQuality(item))
	{
		case Quality_Genuine:		SetEntityRenderColor(sprite, 125, 255, 125);
		case Quality_Unusual: 		SetEntityRenderColor(sprite, 200, 125, 255);
		case Quality_Strange:		SetEntityRenderColor(sprite, 200, 150, 0);
		case Quality_Collectors:	SetEntityRenderColor(sprite, 255, 100, 100);
		case Quality_Haunted, 
			Quality_HauntedStrange:	SetEntityRenderColor(sprite, 125, 255, 255);
	}
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
	SetEntityModel(entity, MODEL_SCRAPPER);
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * *

 					PROJECTILES

* * * * * * * * * * * * * * * * * * * * * * * * * * */


static void Projectile_OnCreate(int entity)
{
	SDKHook(entity, SDKHook_VPhysicsUpdate, Hook_ProjectileThink);
	SDKHook(entity, SDKHook_SpawnPost, Hook_CustomProjectileSpawnPost);
	SetEntPropVector(entity, Prop_Data, "m_vecHitboxMins", {-20.0, -20.0, -20.0});
	SetEntPropVector(entity, Prop_Data, "m_vecHitboxMaxs", {20.0, 20.0, 20.0});
	if (g_hSDKVPhysicsCollision)
	{
		DHookEntity(g_hSDKVPhysicsCollision, true, entity, _, DHook_ProjectileCollision);
	}
}

static void Shuriken_OnCreate(int entity)
{
	SDKHook(entity, SDKHook_SpawnPost, Hook_ShurikenSpawnPost);
	SetEntProp(entity, Prop_Data, "m_nProcItem", ItemStrange_LegendaryLid);
	SetEntPropFloat(entity, Prop_Data, "m_flBaseDamage", 30.0);
	SetEntityModel(entity, MODEL_SHURIKEN);
}

static void Bomb_OnCreate(int entity)
{
	SetEntProp(entity, Prop_Data, "m_nProcItem", ItemStrange_CroneDome);
	SetEntPropFloat(entity, Prop_Data, "m_flExplodeRadius", GetItemMod(ItemStrange_CroneDome, 0));
	SetEntPropFloat(entity, Prop_Data, "m_flDirectDamage", GetItemMod(ItemStrange_CroneDome, 2));
	SetEntityModel(entity, MODEL_BOMB);
}

static void Kunai_OnCreate(int entity)
{
	SDKHook(entity, SDKHook_SpawnPost, Hook_KunaiSpawnPost);
	SetEntProp(entity, Prop_Data, "m_nProcItem", ItemStrange_HandsomeDevil);
	SetEntityModel(entity, MODEL_KUNAI);
}

public void Hook_CustomProjectileSpawnPost(int entity)
{
	SetEntItemDamageProc(entity, GetEntProp(entity, Prop_Data, "m_nProcItem"));
}

public void Hook_ShurikenSpawnPost(int entity)
{
	CreateProjectileTrail(entity, "stunballtrail_red_crit", "stunballtrail_blue_crit");
}

public void Hook_KunaiSpawnPost(int entity)
{
	CreateProjectileTrail(entity, "stunballtrail_red_crit", "stunballtrail_blue_crit");
}

public void Hook_ProjectileThink(int entity)
{
	if (!GetEntProp(entity, Prop_Data, "m_bHit"))
	{
		float pos[3], mins[3], maxs[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
		GetEntPropVector(entity, Prop_Data, "m_vecHitboxMins", mins);
		GetEntPropVector(entity, Prop_Data, "m_vecHitboxMaxs", maxs);
		TR_TraceHullFilter(pos, pos, mins, maxs, MASK_PLAYERSOLID, TraceFilter_Projectile, entity);
		int hitEntity = TR_GetEntityIndex();
		if (hitEntity > 0)
		{
			SetEntProp(entity, Prop_Data, "m_bHit", true);
			char classname[128];
			GetEntityClassname(entity, classname, sizeof(classname));
			OnProjectileHit(entity, hitEntity, classname);
			DeactivateProjectile(entity);
		}
	}
}

public MRESReturn DHook_ProjectileCollision(int entity, DHookParam params)
{
	if (!GetEntProp(entity, Prop_Data, "m_bHit"))
	{
		int hitEntity = params.GetObjectVar(2, 108, ObjectValueType_CBaseEntityPtr);
		if (hitEntity >= 0 && !IsCustomProjectile(hitEntity)) // don't collide with other projectiles
		{
			SetEntProp(entity, Prop_Data, "m_bHit", true);
			static char classname[128];
			GetEntityClassname(entity, classname, sizeof(classname));
			OnProjectileCollide(entity, hitEntity, classname);
		}
	}
	
	return MRES_Ignored;
}

// Called when colliding with world/engineer building. Player and NPC hits will just call OnProjectileHit.
static void OnProjectileCollide(int entity, int hitEntity, const char[] classname)
{
	static char hitClassname[128];
	GetEntityClassname(hitEntity, hitClassname, sizeof(hitClassname));
	bool building = IsBuilding(hitEntity);
	if (building)
	{
		OnProjectileHit(entity, hitEntity, classname);
	}
	else if (HasEntProp(entity, Prop_Data, "m_flExplodeRadius"))
	{
		ExplodeProjectile(entity);
		RemoveEntity(entity);
		return;
	}
	
	DeactivateProjectile(entity);
}

static void OnProjectileHit(int entity, int victim, const char[] classname)
{
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	float damage = GetEntPropFloat(entity, Prop_Data, "m_flBaseDamage");
	int flags = DMG_GENERIC;
	
	if (HasEntProp(entity, Prop_Data, "m_flExplodeRadius"))
	{
		SetEntPropEnt(entity, Prop_Data, "m_hDirectTarget", victim);
		damage = GetEntPropFloat(entity, Prop_Data, "m_flDirectDamage");
		flags = DMG_BLAST;
		ExplodeProjectile(entity);
	}
	else if (strcmp2(classname, "rf2_projectile_shuriken"))
	{
		EmitGameSoundToAll(GSND_CLEAVER_HIT, entity);
		flags = DMG_SLASH;
		
		if (IsValidClient(victim))
		{
			if (TF2_IsPlayerInCondition(victim, TFCond_Bleeding))
				flags |= DMG_CRIT;
			
			TF2_MakeBleed(victim, owner, GetItemMod(ItemStrange_LegendaryLid, 1));
		}
	}
	else if (strcmp2(classname, "rf2_projectile_kunai"))
	{
		EmitGameSoundToAll(GSND_CLEAVER_HIT, entity);
		flags = DMG_SLASH;
		
		if (IsValidClient(victim))
		{
			// deal damage before adding
			if (damage > 0.0)
			{
				SDKHooks_TakeDamage(victim, entity, owner, damage, flags);
			}
			
			TF2_AddCondition(victim, TFCond_MarkedForDeath, GetItemMod(ItemStrange_HandsomeDevil, 1), owner);
			RemoveEntity(entity);
			return;
		}
	}
	
	if (damage > 0.0)
	{
		SDKHooks_TakeDamage(victim, entity, owner, damage, flags);
	}
	
	RemoveEntity(entity);
}

static void ExplodeProjectile(int entity)
{
	float pos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
	float damage = GetEntPropFloat(entity, Prop_Data, "m_flBaseDamage");
	float radius = GetEntPropFloat(entity, Prop_Data, "m_flExplodeRadius");
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	int item = GetEntProp(entity, Prop_Data, "m_nProcItem");
	EmitSoundToAll(SND_BOMB_EXPLODE, entity);
	DoRadiusDamage(owner, entity, item, pos, damage, DMG_BLAST, radius, _, _, true, false, true);
}

void CreateProjectileTrail(int entity, const char[] redTrail, const char[] blueTrail)
{
	float pos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
	if (GetEntProp(entity, Prop_Data, "m_iTeamNum") == view_as<int>(TFTeam_Red))
	{
		TE_TFParticle(redTrail, pos, entity, PATTACH_ABSORIGIN_FOLLOW);
	}
	else
	{
		TE_TFParticle(blueTrail, pos, entity, PATTACH_ABSORIGIN_FOLLOW);
	}
}

static void DeactivateProjectile(int entity)
{
	CreateTimer(6.0, Timer_DeleteEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	SDKUnhook(entity, SDKHook_VPhysicsUpdate, Hook_ProjectileThink);
}

public bool TraceFilter_Projectile(int entity, int mask, int self)
{
	if (!IsValidClient(entity) && !IsNPC(entity))
		return false;
	
	if (GetEntProp(self, Prop_Data, "m_iTeamNum") == GetEntProp(entity, Prop_Data, "m_iTeamNum"))
		return false;
	
	return true;
}

bool IsCustomProjectile(int entity)
{
	static char classname[128];
	GetEntityClassname(entity, classname, sizeof(classname));
	return StrContains(classname, "rf2_projectile") == 0;
}
