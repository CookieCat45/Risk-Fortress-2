#pragma semicolon 1
#pragma newdecls required
#define MODEL_BARREL "models/props_farm/wooden_barrel.mdl"
static CEntityFactory g_Factory;

methodmap RF2_Object_Barrel < RF2_Object_Base
{
	public RF2_Object_Barrel(int entity)
	{
		return view_as<RF2_Object_Barrel>(entity);
	}
	
	public static CEntityFactory GetFactory()
	{
		return g_Factory;
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
		g_Factory = new CEntityFactory("rf2_object_barrel", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Object_Base.GetFactory());
		g_Factory.Install();
		HookMapStart(Barrel_OnMapStart);
	}
}

void Barrel_OnMapStart()
{
    PrecacheModel2(MODEL_BARREL, true);
}

static void OnCreate(RF2_Object_Barrel barrel)
{
    barrel.SetModel(MODEL_BARREL);
    barrel.SetPropFloat(Prop_Send, "m_flModelScale", 0.65);
    barrel.SetWorldText("Money Barrel (Whack to Open)");
	barrel.SetGlowColor(255, 255, 0, 255);
	barrel.SetObjectName("Money Barrel");
	barrel.TextZOffset = 30.0;
    SDKHook(barrel.index, SDKHook_OnTakeDamage, Hook_OnBarrelHit);
    SDKHook(barrel.index, SDKHook_Spawn, OnSpawn);
	SDKHook(barrel.index, SDKHook_SpawnPost, OnSpawnPost);
}

static void OnSpawn(int entity)
{
    RF2_Object_Barrel barrel = RF2_Object_Barrel(entity);
    barrel.SetProp(Prop_Data, "m_iTeamNum", TEAM_SURVIVOR); // This is so caber hits don't detonate
}

static void OnSpawnPost(int entity)
{
    RF2_Object_Barrel(entity).ScaleHitbox(2.0);
}

static Action Hook_OnBarrelHit(int entity, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePosition[3], int damageCustom)
{
	if (!(damageType & DMG_MELEE) || !IsValidClient(attacker) || !IsPlayerSurvivor(attacker) && !IsPlayerMinion(attacker))
		return Plugin_Continue;
	
	SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1); // Remove honorbound
	g_bPlayerMeleeMiss[attacker] = false;
	if (!RF2_Object_Barrel(entity).Active)
	{
		return Plugin_Continue;
	}

    float pos[3];
    GetEntPos(entity, pos, true);
    pos[2] += 10.0;
    float money = 35.0 * RF2_Object_Base.GetCostMultiplier() * (1.0 + CalcItemMod(attacker, Item_BanditsBoots, 0));
    SpawnCashDrop(money, pos, 2);
    SpawnInfoParticle("mvm_loot_explosion", pos, 3.0);
    EmitSoundToAll(SND_DROP_DEFAULT, entity);
    EmitSoundToAll(SND_CASH, entity);
    RemoveEntity(entity);
    return Plugin_Continue;
}
