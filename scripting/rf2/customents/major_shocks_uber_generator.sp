#pragma semicolon 1
#pragma newdecls required
#define MODEL_UBERGENERATOR "models/buildables/amplifier_test/amplifier.mdl"

static CEntityFactory g_Factory;
methodmap RF2_MajorShocksUberGenerator < RF2_NPC_Base
{
	public RF2_MajorShocksUberGenerator(int entity)
	{
		return view_as<RF2_MajorShocksUberGenerator>(entity);
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
		g_Factory = new CEntityFactory("rf2_npc_uber_generator", OnCreate, OnRemove);
		g_Factory.DeriveFromFactory(GetBaseNPCFactory());
		g_Factory.BeginDataMapDesc()
			.DefineEntityField("m_Boss")
		.EndDataMapDesc();
		g_Factory.Install();
		HookMapStart(Generator_OnMapStart);
	}

	property RF2_MajorShocks Boss
	{
		public get()
		{
			return view_as<RF2_MajorShocks>(this.GetPropEnt(Prop_Data, "m_Boss"));
		}

		public set(RF2_MajorShocks value)
		{
			this.SetPropEnt(Prop_Data, "m_Boss", value.index);
		}
	}
}

void Generator_OnMapStart()
{
	AddModelToDownloadsTable(MODEL_UBERGENERATOR);
}

static void OnCreate(RF2_MajorShocksUberGenerator generator)
{
	generator.DoUnstuckChecks = false;
	generator.Team = TEAM_ENEMY;
	generator.SetModel(MODEL_UBERGENERATOR);
	generator.SetProp(Prop_Send, "m_fEffects", generator.GetProp(Prop_Send, "m_fEffects") | EF_ITEM_BLINK);
	generator.HealthText = CreateHealthText(generator.index, 65.0, 30.0, "Uber Generator");
	generator.HealthText.SetHealthColor(HEALTHCOLOR_HIGH, {0, 255, 100, 255});
	generator.BaseNpc.flGravity = 0.0;
	generator.BaseNpc.flAcceleration = 0.0;
	generator.BaseNpc.flFrictionForward = 0.0;
	generator.BaseNpc.flFrictionSideways = 0.0;
	generator.SetProp(Prop_Send, "m_nSkin", 1);
	generator.SetGlow(true);
	generator.SetGlowColor(50, 255, 200);
	generator.SetRenderMode(RENDER_TRANSCOLOR);
	SDKHook(generator.index, SDKHook_SpawnPost, SpawnPost);
	SDKHook(generator.index, SDKHook_ThinkPost, ThinkPost);
	SDKHook(generator.index, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(generator.index, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(generator.index, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
}

static void OnRemove(RF2_MajorShocksUberGenerator generator)
{
	bool remaining;
	int entity = INVALID_ENT;
	while ((entity = FindEntityByClassname(entity, "rf2_npc_uber_generator")) != INVALID_ENT)
	{
		RF2_MajorShocksUberGenerator other = RF2_MajorShocksUberGenerator(entity);
		if (generator.index == other.index || generator.Boss.index != other.Boss.index)
			continue;
			
		remaining = true;
		break;
	}
	
	if (!remaining)
	{
		generator.Boss.DoFinalPhase();
	}
}

static void SpawnPost(int entity)
{
	RF2_MajorShocksUberGenerator generator = RF2_MajorShocksUberGenerator(entity);
	float mins[3] = {-35.0, -35.0, -45.0};
	float maxs[3] = {35.0, 35.0, 60.0};
	generator.SetHitboxSize(mins, maxs);
	generator.SetMoveType(MOVETYPE_NONE);
	float playerMult = 1.0 + (0.25 * float(RF2_GetSurvivorCount() - 1));
	const float baseHealth = 1500.0;
	generator.MaxHealth = RoundToFloor(baseHealth * playerMult * GetEnemyHealthMult());
	generator.Health = generator.MaxHealth;
}

static void ThinkPost(int entity)
{
	RF2_MajorShocksUberGenerator generator = RF2_MajorShocksUberGenerator(entity);
	// zero out velocity so we never move
	generator.Locomotion.SetVelocity({0.0, 0.0, 0.0});
}

static Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
		float damageForce[3], float damagePosition[3], int damagecustom)
{
	RF2_MajorShocksUberGenerator generator = RF2_MajorShocksUberGenerator(victim);
	if (GetEntTeam(attacker) == generator.Team)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

static Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
		float damageForce[3], float damagePosition[3], int damagecustom)
{
	//RF2_MajorShocksUberGenerator generator = RF2_MajorShocksUberGenerator(victim);
	Action action = Plugin_Continue;
	if (damagetype & DMG_CRIT)
	{
		// 50% resistance to crits
		float baseDamage = damage / 3.0;
		float critDamage = damage - baseDamage;
		damage = baseDamage + (critDamage * 0.5);
		action = Plugin_Changed;
	}

	return action;
}

static void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon,
		const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	RF2_MajorShocksUberGenerator generator = RF2_MajorShocksUberGenerator(victim);
	if (generator.Health <= 0)
	{
		float pos[3];
		generator.WorldSpaceCenter(pos);
		DoExplosionEffect(pos);
		EmitAmbientGameSound("Weapon_TackyGrendadier.Explode", pos);
		RemoveEntity(generator.index);
	}
}