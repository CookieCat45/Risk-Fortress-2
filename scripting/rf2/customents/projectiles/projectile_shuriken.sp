#pragma semicolon 1
#pragma newdecls required

#define MODEL_SHURIKEN "models/rf2/projectiles/shuriken.mdl"
#define GSND_SHURIKEN_HITCHAR "Cleaver.ImpactFlesh"
#define GSND_SHURIKEN_HITWORLD "Cleaver.ImpactWorld"
static CEntityFactory g_Factory;

methodmap RF2_Projectile_Shuriken < RF2_Projectile_Base
{
	public RF2_Projectile_Shuriken(int entity)
	{
		return view_as<RF2_Projectile_Shuriken>(entity);
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
		g_Factory = new CEntityFactory("rf2_projectile_shuriken", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Projectile_Base.GetFactory());
		g_Factory.Install();
		HookMapStart(Shuriken_OnMapStart);
	}
}

void Shuriken_OnMapStart()
{
	PrecacheModel2(MODEL_SHURIKEN, true);
	PrecacheScriptSound(GSND_SHURIKEN_HITCHAR);
	PrecacheScriptSound(GSND_SHURIKEN_HITWORLD);
	AddModelToDownloadsTable(MODEL_SHURIKEN);
	AddMaterialToDownloadsTable("materials/rf2/projectiles/body");
	AddMaterialToDownloadsTable("materials/rf2/projectiles/blade");
	AddMaterialToDownloadsTable("materials/rf2/projectiles/ring");
}

static void OnCreate(RF2_Projectile_Shuriken shuriken)
{
	shuriken.SetModel(MODEL_SHURIKEN);
	shuriken.SetCharImpactSound(GSND_SHURIKEN_HITCHAR);
	shuriken.SetWorldImpactSound(GSND_SHURIKEN_HITWORLD);
	shuriken.SetRedTrail("stunballtrail_red_crit");
	shuriken.SetBlueTrail("stunballtrail_blue_crit");
	shuriken.HookOnCollide(OnCollide);
}

static void OnCollide(RF2_Projectile_Shuriken shuriken, int other)
{
	if (!IsCombatChar(other))
		return;
	
	int damageType = DMG_SLASH;
	if (IsValidClient(other))
	{
		if (TF2_IsPlayerInCondition2(other, TFCond_Bleeding))
			damageType |= DMG_CRIT;
			
		TF2_MakeBleed(other, shuriken.Owner, GetItemMod(ItemStrange_LegendaryLid, 1));
	}
	
	SDKHooks_TakeDamage2(other, shuriken.index, shuriken.Owner, shuriken.Damage, damageType);
}
