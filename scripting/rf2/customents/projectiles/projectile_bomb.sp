#pragma semicolon 1
#pragma newdecls required

#define MODEL_BOMB "models/weapons/w_models/w_cannonball.mdl"
#define SND_BOMB_EXPLODE "weapons/loose_cannon_explode.wav"
static CEntityFactory g_Factory;

methodmap RF2_Projectile_Bomb < RF2_Projectile_Base
{
	public RF2_Projectile_Bomb(int entity)
	{
		return view_as<RF2_Projectile_Bomb>(entity);
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
		g_Factory = new CEntityFactory("rf2_projectile_bomb", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Projectile_Base.GetFactory());
		g_Factory.Install();
		HookMapStart(Bomb_OnMapStart);
	}
}

void Bomb_OnMapStart()
{
	PrecacheModel2(MODEL_BOMB);
	PrecacheSound2(SND_BOMB_EXPLODE);
}

static void OnCreate(RF2_Projectile_Bomb bomb)
{
	bomb.SetModel(MODEL_BOMB);
	bomb.SetProp(Prop_Send, "m_nSkin", bomb.Team-2);
	bomb.DeactivateTime = 0.0;
	bomb.SetWorldImpactSound(SND_BOMB_EXPLODE);
	bomb.Damage = GetItemMod(ItemStrange_CroneDome, 1);
	bomb.DirectDamage = GetItemMod(ItemStrange_CroneDome, 2);
	bomb.Radius = GetItemMod(ItemStrange_CroneDome, 0);
	bomb.HookOnCollide(OnCollide);
}

static void OnCollide(RF2_Projectile_Bomb bomb, int other)
{
	bomb.Explode();
}
