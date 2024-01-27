#pragma semicolon 1
#pragma newdecls required

#define MODEL_KUNAI "models/workshop_partner/weapons/c_models/c_shogun_kunai/c_shogun_kunai.mdl"
static CEntityFactory g_Factory;

methodmap RF2_Projectile_Kunai < RF2_Projectile_Base
{
	public RF2_Projectile_Kunai(int entity)
	{
		return view_as<RF2_Projectile_Kunai>(entity);
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
		g_Factory = new CEntityFactory("rf2_projectile_kunai", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Projectile_Base.GetFactory());
		g_Factory.Install();
		HookMapStart(Kunai_OnMapStart);
	}
}

void Kunai_OnMapStart()
{
	PrecacheModel2(MODEL_KUNAI, true);
}

static void OnCreate(RF2_Projectile_Kunai kunai)
{
	kunai.SetModel(MODEL_KUNAI);
	kunai.SetCharImpactSound(GSND_SHURIKEN_HITCHAR);
	kunai.SetWorldImpactSound(GSND_SHURIKEN_HITWORLD);
	kunai.SetRedTrail("stunballtrail_red_crit");
	kunai.SetBlueTrail("stunballtrail_blue_crit");
	kunai.HookOnCollide(OnCollide);
}

static void OnCollide(RF2_Projectile_Kunai kunai, int other)
{
	if (!IsCombatChar(other))
		return;
	
	int damageType = DMG_SLASH;
	if (IsValidClient(other))
	{
		if (TF2_IsPlayerInCondition2(other, TFCond_MarkedForDeath) || TF2_IsPlayerInCondition2(other, TFCond_MarkedForDeathSilent))
			damageType |= DMG_CRIT;
	}
	
	SDKHooks_TakeDamage2(other, kunai.index, kunai.Owner, kunai.Damage, damageType);
	TF2_AddCondition(other, TFCond_MarkedForDeath, GetItemMod(ItemStrange_HandsomeDevil, 1), kunai.Owner);
}
