#pragma semicolon 1
#pragma newdecls required

#define SND_DEMO_BEAM "rf2/sfx/sword_beam.wav"
static CEntityFactory g_Factory;

methodmap RF2_Projectile_Beam < RF2_Projectile_Base
{
	public RF2_Projectile_Beam(int entity)
	{
		return view_as<RF2_Projectile_Beam>(entity);
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
		g_Factory = new CEntityFactory("rf2_projectile_beam", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Projectile_Base.GetFactory());
		g_Factory.Install();
		HookMapStart(Beam_OnMapStart);
	}
}

void Beam_OnMapStart()
{
	PrecacheSound2(SND_DEMO_BEAM, true);
}

static void OnCreate(RF2_Projectile_Beam beam)
{
	// Physics props still need a model, so we're just an invisible shuriken
	beam.SetModel(MODEL_SHURIKEN);
	beam.SetRenderMode(RENDER_TRANSCOLOR); // RENDER_NONE doesn't seem to work properly
	beam.SetRenderColor(0, 0, 0, 0);
	beam.DeactivateTime = 0.0;
	beam.SetRedTrail("drg_cow_rockettrail_fire");
	beam.SetBlueTrail("drg_cow_rockettrail_fire_blue");
	beam.AltParticleSpawn = true;
	beam.SetFireSound(SND_DEMO_BEAM);
	beam.HookOnCollide(Beam_OnCollide);
}

public void Beam_OnCollide(RF2_Projectile_Beam beam, int other)
{
	if (!IsCombatChar(other))
		return;
	
	RF_TakeDamage(other, beam.index, beam.Owner, beam.Damage, DMG_SONIC, GetEntItemProc(beam.index));
}
