#pragma semicolon 1
#pragma newdecls required

#define SND_FIREBALL_IMPACT "misc/halloween/spell_fireball_impact.wav"
static CEntityFactory g_Factory;

methodmap RF2_Projectile_Fireball < RF2_Projectile_Base
{
	public RF2_Projectile_Fireball(int entity)
	{
		return view_as<RF2_Projectile_Fireball>(entity);
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
		g_Factory = new CEntityFactory("rf2_projectile_fireball", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Projectile_Base.GetFactory());
		g_Factory.Install();
		HookMapStart(Fireball_OnMapStart);
	}
}

void Fireball_OnMapStart()
{
	PrecacheSound2(SND_FIREBALL_IMPACT, true);
}

static void OnCreate(RF2_Projectile_Fireball fireball)
{
	// Physics props still need a model, so we're just an invisible shuriken
	fireball.SetModel(MODEL_SHURIKEN);
	fireball.SetRenderMode(RENDER_TRANSCOLOR); // RENDER_NONE doesn't seem to work properly
	fireball.SetRenderColor(0, 0, 0, 0);
	fireball.DeactivateTime = 0.0;
	fireball.Radius = 200.0;
	fireball.Flying = true;
	fireball.AltParticleSpawn = true;
	fireball.SetRedTrail("spell_fireball_small_red");
	fireball.SetBlueTrail("spell_fireball_small_blue");
	//fireball.SetFireSound(SND_SPELL_FIREBALL);
	fireball.SetCharImpactSound(SND_FIREBALL_IMPACT);
	fireball.SetWorldImpactSound(SND_FIREBALL_IMPACT);
	fireball.HookOnCollide(OnCollide);
}

static void OnCollide(RF2_Projectile_Fireball fireball, int other)
{
	// special case for old crown, don't explode if we hit world
	if (!IsCombatChar(other) && GetEntItemProc(fireball.index) == Item_OldCrown)
	{
		return;
	}

	ArrayList hitEnts = fireball.Explode(DMG_BURN, true, true, true);
	if (IsValidClient(other))
	{
		TF2_IgnitePlayer(other, IsValidClient(fireball.Owner) ? fireball.Owner : other, 10.0);
	}
	
	int entity;
	for (int i = 0; i < hitEnts.Length; i++)
	{
		entity = hitEnts.Get(i);
		if (!IsValidClient(entity))
			continue;
		
		TF2_IgnitePlayer(entity, IsValidClient(fireball.Owner) ? fireball.Owner : entity, 10.0);
	}
	
	delete hitEnts;
	float pos[3];
	fireball.GetAbsOrigin(pos);
	fireball.Team == TEAM_SURVIVOR ? TE_TFParticle("spell_fireball_tendril_parent_red", pos) : TE_TFParticle("spell_fireball_tendril_parent_blue", pos);
	fireball.Remove();
}
