#pragma semicolon 1
#pragma newdecls required
#define MODEL_CRYSTAL "models/rf2/bosses/providence_crystal.mdl"

#define REGEN_RESIST_TIME 5.0

static CEntityFactory g_Factory;
methodmap RF2_ProvidenceShieldCrystal < RF2_NPC_Base
{
	public RF2_ProvidenceShieldCrystal(int entity)
	{
		return view_as<RF2_ProvidenceShieldCrystal>(entity);
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
		g_Factory = new CEntityFactory("rf2_npc_shield_crystal", OnCreate);
		g_Factory.DeriveFromFactory(GetBaseNPCFactory());
		g_Factory.BeginDataMapDesc()
            .DefineBoolField("m_bDestroyed")
            .DefineFloatField("m_flRegenerateAt")
            .DefineEntityField("m_hBoss")
		.EndDataMapDesc();
		g_Factory.Install();
        HookMapStart(Crystal_OnMapStart);
	}

    property float RegenerateAt
    {
        public get()
        {
            return this.GetPropFloat(Prop_Data, "m_flRegenerateAt");
        }

        public set(float value)
        {
            this.SetPropFloat(Prop_Data, "m_flRegenerateAt", value);
        }
    }

    property RF2_Providence Boss
    {
        public get()
        {
            return view_as<RF2_Providence>(this.GetPropEnt(Prop_Data, "m_hBoss"));
        }

        public set(RF2_Providence value)
        {
            this.SetPropEnt(Prop_Data, "m_hBoss", value.index);
        }
    }

    property bool Destroyed
    {
        public get()
        {
            return asBool(this.GetProp(Prop_Data, "m_bDestroyed"));
        }

        public set(bool value)
        {
            this.SetProp(Prop_Data, "m_bDestroyed", value);
        }
    }

    public void Regenerate()
    {
        this.Destroyed = false;
        // Turn green for a few seconds to indicate that we resist damage heavily after regenerating for a bit
        this.SetRenderColor(0, 255, 0, 255);
        CreateTimer(REGEN_RESIST_TIME, Timer_ResetRenderColor, EntIndexToEntRef(this.index), TIMER_FLAG_NO_MAPCHANGE);
        this.RemoveFlag(FL_NOTARGET);
        this.SetGlow(true);
        this.Health = this.MaxHealth;
        this.SetProp(Prop_Send, "m_fEffects", this.GetProp(Prop_Send, "m_fEffects")|EF_ITEM_BLINK);
        EmitGameSoundToAll("Powerup.PickUpRegeneration", this.index);
        float pos[3];
        this.WorldSpaceCenter(pos);
        TE_TFParticle("drg_cow_explosioncore_charged_blue", pos, this.index);
        if (this.Boss.IsValid())
        {
            this.Boss.UpdateCrystalEffects();
        }
    }
}

void Crystal_OnMapStart()
{
    AddModelToDownloadsTable(MODEL_CRYSTAL);
}

static void OnCreate(RF2_ProvidenceShieldCrystal crystal)
{
    crystal.DoUnstuckChecks = false;
    crystal.SetModel(MODEL_CRYSTAL);
    crystal.SetProp(Prop_Send, "m_fEffects", crystal.GetProp(Prop_Send, "m_fEffects")|EF_ITEM_BLINK);
    crystal.SetProp(Prop_Data, "m_iTeamNum", TEAM_ENEMY);
    crystal.HealthText = CreateHealthText(crystal.index, 65.0, 30.0, "SHIELD CRYSTAL");
    crystal.HealthText.SetHealthColor(HEALTHCOLOR_HIGH, {0, 255, 100, 255});
    crystal.BaseNpc.flGravity = 0.0;
    crystal.BaseNpc.flAcceleration = 0.0;
    crystal.BaseNpc.flFrictionForward = 0.0;
    crystal.BaseNpc.flFrictionSideways = 0.0;
    crystal.SetGlow(true);
    crystal.SetRenderMode(RENDER_TRANSCOLOR);
    crystal.RegenerateAt = GetGameTime();
    SDKHook(crystal.index, SDKHook_SpawnPost, SpawnPost);
    SDKHook(crystal.index, SDKHook_ThinkPost, ThinkPost);
    SDKHook(crystal.index, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKHook(crystal.index, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
    SDKHook(crystal.index, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
}

static void SpawnPost(int entity)
{
    RF2_ProvidenceShieldCrystal crystal = RF2_ProvidenceShieldCrystal(entity);
    float mins[3] = {-35.0, -35.0, -45.0};
    float maxs[3] = {35.0, 35.0, 60.0};
    crystal.SetHitboxSize(mins, maxs);
    crystal.SetMoveType(MOVETYPE_NONE);
    float playerMult = 1.0 + (0.25 * float(RF2_GetSurvivorCount()-1));
    const float baseHealth = 2350.0;
    crystal.MaxHealth = RoundToFloor(baseHealth * playerMult * GetEnemyHealthMult());
    crystal.Regenerate();
}

static Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
		float damageForce[3], float damagePosition[3], int damagecustom)
{
    RF2_ProvidenceShieldCrystal crystal = RF2_ProvidenceShieldCrystal(victim);
    if (crystal.Destroyed)
        return Plugin_Handled;

    return Plugin_Continue;
}

static Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
		float damageForce[3], float damagePosition[3], int damagecustom)
{
    RF2_ProvidenceShieldCrystal crystal = RF2_ProvidenceShieldCrystal(victim);
    Action action = Plugin_Continue;
    if (damagetype & DMG_CRIT)
    {
        // 50% resistance to crits
        float baseDamage = damage/3.0;
        float critDamage = damage-baseDamage;
        damage = baseDamage + (critDamage*0.5);
        action = Plugin_Changed;
    }

    // If we regenerated recently, we resist all damage by 80%
    if (GetGameTime()-crystal.RegenerateAt <= 5.0)
    {
        damage *= 0.2;
        action = Plugin_Changed;
    }

    return action;
}

static void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon,
		const float damageForce[3], const float damagePosition[3], int damagecustom)
{
    RF2_ProvidenceShieldCrystal crystal = RF2_ProvidenceShieldCrystal(victim);
    if (crystal.Health <= 0)
    {
        crystal.Health = 1; // Never actually die, just disappear for a while
        crystal.Destroyed = true;
        crystal.SetRenderColor(1, 1, 1, 80);
        crystal.AddFlag(FL_NOTARGET);
        crystal.SetProp(Prop_Send, "m_fEffects", crystal.GetProp(Prop_Send, "m_fEffects") & ~EF_ITEM_BLINK);
        crystal.SetGlow(false);
        float pos[3];
        crystal.WorldSpaceCenter(pos);
        DoExplosionEffect(pos);
        EmitGameSoundToAll(GSND_SECONDLIFE_EXPLODE, crystal.index);
        const float time = 50.0;
        crystal.RegenerateAt = GetGameTime()+time;
        if (crystal.Boss.IsValid())
        {
            crystal.Boss.UpdateCrystalEffects();
        }
    }
}

static void ThinkPost(int entity)
{
    RF2_ProvidenceShieldCrystal crystal = RF2_ProvidenceShieldCrystal(entity);
    if (crystal.Destroyed)
    {
        if (GetGameTime() >= crystal.RegenerateAt)
        {
            crystal.Regenerate();
        }
    }
    else
    {
        // constantly rotate
        static float angles[3];
        crystal.GetLocalAngles(angles);
        angles[1] += 2.0;
        crystal.SetLocalAngles(angles);
    }

    // zero out velocity so we never move
    crystal.Locomotion.SetVelocity({0.0, 0.0, 0.0});
}

static void Timer_ResetRenderColor(Handle timer, int entity)
{
    RF2_ProvidenceShieldCrystal crystal = RF2_ProvidenceShieldCrystal(EntRefToEntIndex(entity));
    if (!crystal.IsValid() || crystal.Destroyed)
        return;

    crystal.SetRenderColor(255, 255, 255, 255);
}
