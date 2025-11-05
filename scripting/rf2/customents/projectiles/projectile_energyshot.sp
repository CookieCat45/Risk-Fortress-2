#pragma semicolon 1
#pragma newdecls required

static CEntityFactory g_Factory;

methodmap RF2_Projectile_EnergyShot < RF2_Projectile_Base
{
	public RF2_Projectile_EnergyShot(int entity)
	{
		return view_as<RF2_Projectile_EnergyShot>(entity);
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
		g_Factory = new CEntityFactory("rf2_projectile_energyshot", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Projectile_Base.GetFactory());
		g_Factory.BeginDataMapDesc()
			.DefineBoolField("m_bRainbow")
		.EndDataMapDesc();
		g_Factory.Install();
	}
	
	property bool Rainbow
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bRainbow"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bRainbow", value);
		}
	}
}

static void OnCreate(RF2_Projectile_EnergyShot shot)
{
	shot.SetModel(MODEL_SHURIKEN);
	shot.SetRenderMode(RENDER_TRANSCOLOR);
	shot.SetRenderColor(0, 0, 0, 0);
	shot.DeactivateTime = 0.0;
	shot.Flying = true;
    shot.UseInfoParticle = true;
    shot.UsesColorTargets = true;
	shot.SetRedTrail("drg_bison_projectile");
	shot.SetBlueTrail("drg_bison_projectile");
	shot.SetCharImpactSound("Weapon_Bison.ProjectileImpactFlesh");
	shot.SetWorldImpactSound("Weapon_Bison.ProjectileImpactWorld");
	shot.HookOnCollide(OnCollide);
    SDKHook(shot.index, SDKHook_Spawn, OnSpawn);
}

static void OnSpawn(int entity)
{
    RF2_Projectile_EnergyShot shot = RF2_Projectile_EnergyShot(entity);
	if (shot.Rainbow)
	{
		float rand1[3], rand2[3];
		rand1[0] = GetRandomFloat(25.0, 255.0);
		rand1[1] = GetRandomFloat(25.0, 255.0);	
		rand1[2] = GetRandomFloat(25.0, 255.0);
		rand2[0] = GetRandomFloat(25.0, 255.0);
		rand2[1] = GetRandomFloat(25.0, 255.0);	
		rand2[2] = GetRandomFloat(25.0, 255.0);	
		shot.SetColorTarget(0, rand1);
		shot.SetColorTarget(1, rand2);
	}
	else
	{
		if (shot.Team == 2)
		{
			shot.SetColorTarget(0, {255.0, 0.0, 0.0});
			shot.SetColorTarget(1, {255.0, 0.0, 0.0});
		}
		else if (shot.Team == 3)
		{
			shot.SetColorTarget(0, {0.0, 70.0, 255.0});
			shot.SetColorTarget(1, {0.0, 70.0, 255.0});
			//shot.SetColorTarget(0, {0.0, 100.0, 255.0});
			//shot.SetColorTarget(1, {0.0, 100.0, 255.0});
		}
	}
    
}

static void OnCollide(RF2_Projectile_EnergyShot shot, int other)
{
	if (IsCombatChar(other))
    {
        
    }
}
