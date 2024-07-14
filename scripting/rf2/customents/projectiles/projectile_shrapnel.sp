#pragma semicolon 1
#pragma newdecls required
#define MODEL_SHRAPNEL "models/weapons/w_models/w_stickybomb_gib3.mdl"
static CEntityFactory g_Factory;

methodmap RF2_Projectile_Shrapnel < RF2_Projectile_Base
{
	public RF2_Projectile_Shrapnel(int entity)
	{
		return view_as<RF2_Projectile_Shrapnel>(entity);
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
		g_Factory = new CEntityFactory("rf2_projectile_shrapnel", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Projectile_Base.GetFactory());
		g_Factory.Install();
		HookMapStart(Shrapnel_OnMapStart);
	}
}

void Shrapnel_OnMapStart()
{
	PrecacheModel2(MODEL_SHRAPNEL, true);
	PrecacheScriptSound("MVM_Robot.BulletImpact");
}

static void OnCreate(RF2_Projectile_Shrapnel shrapnel)
{
	shrapnel.SetModel(MODEL_SHRAPNEL);
	shrapnel.DeactivateTime = 0.8;
	shrapnel.HookOnCollide(Shrapnel_OnCollide);
	shrapnel.Damage = GetItemMod(ItemHeavy_GoneCommando, 0);
	shrapnel.SetRedTrail("rockettrail_fire_airstrike");
	shrapnel.SetBlueTrail("rockettrail_fire_airstrike");
	shrapnel.SetCharImpactSound("MVM_Robot.BulletImpact");
	SetEntItemProc(shrapnel.index, ItemHeavy_GoneCommando);
}

public void Shrapnel_OnCollide(RF2_Projectile_Shrapnel shrapnel, int other)
{
	if (!IsCombatChar(other))
		return;
	
	RF_TakeDamage(other, shrapnel.index, shrapnel.Owner, shrapnel.Damage, DMG_SLASH|DMG_PREVENT_PHYSICS_FORCE, GetEntItemProc(shrapnel.index));
}
