#pragma newdecls required
#pragma semicolon 1
#define MODEL_SENTRYROCKET "models/weapons/w_models/w_rocket.mdl"

static CEntityFactory g_Factory;
public const char g_szRocketExplodeSounds[][] = 
{
	"weapons/explode1.wav",
	"weapons/explode2.wav",
	"weapons/explode3.wav"
};

methodmap RF2_Projectile_HomingRocket < RF2_Projectile_Base
{
	public RF2_Projectile_HomingRocket(int entity)
	{
		return view_as<RF2_Projectile_HomingRocket>(entity);
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
		g_Factory = new CEntityFactory("rf2_projectile_homingrocket", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Projectile_Base.GetFactory());
		g_Factory.Install();
		HookMapStart(HomingRocket_OnMapStart);
	}
}

static void HomingRocket_OnMapStart()
{
	PrecacheModel2(MODEL_SENTRYROCKET, true);
	PrecacheSoundArray(g_szRocketExplodeSounds, sizeof(g_szRocketExplodeSounds), false);
}

static void OnCreate(RF2_Projectile_HomingRocket rocket)
{
	rocket.SetModel(MODEL_SENTRYROCKET);
	rocket.Flying = true;
	rocket.Homing = true;
	rocket.DeactivateTime = 0.0;
	rocket.Radius = 144.0;
	rocket.HomingSpeed = 500.0;
	rocket.SetRedTrail("rockettrail");
	rocket.SetBlueTrail("rockettrail");
	//rocket.SetFireSound(SND_LAW_FIRE);
	rocket.SetWorldImpactSound(g_szRocketExplodeSounds[GetRandomInt(0, sizeof(g_szRocketExplodeSounds)-1)]);
	rocket.HookOnCollide(OnCollide);
}

static void OnCollide(RF2_Projectile_HomingRocket rocket, int other)
{
	rocket.Explode();
}
