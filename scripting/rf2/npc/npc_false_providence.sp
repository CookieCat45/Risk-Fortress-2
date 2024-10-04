#pragma newdecls required
#pragma semicolon 1

#define MODEL_PROVIDENCE "models/rf2/bosses/false_providence.mdl"
#define SND_GROUND_STAB "rf2/sfx/false_providence/ground_stab.wav"
#define SND_SWORD_SWING "weapons/demo_sword_swing1.wav"
#define SND_SWORD_IMPACT "weapons/demo_sword_hit_world1.wav"
#define SND_SPIN_START "misc/doomsday_lift_start.wav"
#define SND_SPIN_LOOP "misc/doomsday_lift_loop.wav"
#define GSND_PROVIDENCE_FOOTSTEP "MVM.GiantDemomanStep"
#define GSND_SWORD_HIT "Weapon_PickAxe.HitFlesh"
#define GSND_SECONDLIFE_EXPLODE "RD.BotDeathExplosion"
static CEntityFactory g_Factory;

methodmap RF2_Providence < RF2_NPC_Base
{
	public RF2_Providence(int entity)
	{
		return view_as<RF2_Providence>(entity);
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
		g_Factory = new CEntityFactory("rf2_npc_false_providence", OnCreate, OnRemove);
		g_Factory.DeriveFromFactory(GetBaseNPCFactory());
		g_Factory.SetInitialActionFactory(RF2_ProvidenceMainAction.GetFactory());
        g_Factory.BeginDataMapDesc()
            .DefineFloatField("m_flNextAttackTime")
            .DefineFloatField("m_flSwitchTargetTime")
            .DefineFloatField("m_flSpinAttackTime")
            .DefineFloatField("m_flGroundStabAttackTime")
            .DefineIntField("m_iPhase")
            .DefineIntField("m_hCrystals")
            .DefineEntityField("m_hResistParticle")
            .DefineEntityField("m_hRegenParticle")
        .EndDataMapDesc();
		g_Factory.Install();
		HookMapStart(Providence_OnMapStart);
	}

    property float NextAttackTime
    {
        public get()
        {
            return this.GetPropFloat(Prop_Data, "m_flNextAttackTime");
        }

        public set(float value)
        {
            this.SetPropFloat(Prop_Data, "m_flNextAttackTime", value);
        }
    }

    property float SwitchTargetTime
    {
        public get()
        {
            return this.GetPropFloat(Prop_Data, "m_flSwitchTargetTime");
        }

        public set(float value)
        {
            this.SetPropFloat(Prop_Data, "m_flSwitchTargetTime", value);
        }
    }

    property float SpinAttackTime
    {
        public get()
        {
            return this.GetPropFloat(Prop_Data, "m_flSpinAttackTime");
        }

        public set(float value)
        {
            this.SetPropFloat(Prop_Data, "m_flSpinAttackTime", value);
        }
    }

    property float GroundStabAttackTime
    {
        public get()
        {
            return this.GetPropFloat(Prop_Data, "m_flGroundStabAttackTime");
        }

        public set(float value)
        {
            this.SetPropFloat(Prop_Data, "m_flGroundStabAttackTime", value);
        }
    }

    property int Phase
    {
        public get()
        {
            return this.GetProp(Prop_Data, "m_iPhase");
        }

        public set(int value)
        {
            this.SetProp(Prop_Data, "m_iPhase", value);
        }
    }

    property ArrayList Crystals
    {
        public get()
        {
            return view_as<ArrayList>(this.GetProp(Prop_Data, "m_hCrystals"));
        }

        public set(ArrayList list)
        {
            this.SetProp(Prop_Data, "m_hCrystals", list);
        }
    }

    property int ResistParticle
    {
        public get()
        {
            return this.GetPropEnt(Prop_Data, "m_hResistParticle");
        }

        public set(int value)
        {
            this.SetPropEnt(Prop_Data, "m_hResistParticle", value);
        }
    }

    property int RegenParticle
    {
        public get()
        {
            return this.GetPropEnt(Prop_Data, "m_hRegenParticle");
        }

        public set(int value)
        {
            this.SetPropEnt(Prop_Data, "m_hRegenParticle", value);
        }
    }

    public void DetermineSequence()
    {
        int currentSequence = this.GetProp(Prop_Send, "m_nSequence");
        int newSequence;
        bool onGround = asBool(this.GetFlags() & FL_ONGROUND);
        if (!onGround)
        {
            newSequence = this.LookupSequence("Airwalk_ITEM1");
        }
        else if (this.Locomotion.IsAttemptingToMove())
        {
			newSequence = this.LookupSequence("Run_ITEM1");
			float fwd[3], right[3], motion[3];
			this.GetVectors(fwd, right, NULL_VECTOR);
			this.Locomotion.GetGroundMotionVector(motion);
			this.SetPoseParameter(this.LookupPoseParameter("move_x"), GetVectorDotProduct(motion, fwd));
			this.SetPoseParameter(this.LookupPoseParameter("move_y"), GetVectorDotProduct(motion, right));
        }
        else
        {
            newSequence = this.LookupSequence("Stand_ITEM1");
        }

        if (currentSequence != newSequence)
        {
            this.ResetSequence(newSequence);
        }
    }

    public bool CanDoSpinAttack()
    {
        return GetGameTime() >= this.SpinAttackTime;
    }

    public bool CanDoGroundStabAttack()
    {
        return GetGameTime() >= this.GroundStabAttackTime;
    }

    public int GetCrystalPower()
    {
        if (!this.Crystals)
            return 0;

        int power;
        RF2_ProvidenceShieldCrystal crystal;
        for (int i = 0; i < this.Crystals.Length; i++)
        {
            crystal = RF2_ProvidenceShieldCrystal(EntRefToEntIndex(this.Crystals.Get(i)));
            if (!crystal.IsValid() || crystal.Destroyed)
                continue;

            power++;
        }

        return power;
    }

    public void UpdateCrystalEffects()
    {
        int power = this.GetCrystalPower();
        this.SetProp(Prop_Send, "m_nSkin", (power >= 3) ? 3 : 1);
        if (power >= 2)
        {
            if (!IsValidEntity2(this.RegenParticle))
            {
                float pos[3];
                this.GetAbsOrigin(pos);
                this.RegenParticle = SpawnInfoParticle("medic_megaheal_blue", pos, _, this.index);
            }
        }
        else if (IsValidEntity2(this.RegenParticle))
        {
            RemoveEntity2(this.RegenParticle);
            this.RegenParticle = INVALID_ENT;
        }

        if (power >= 1)
        {
            if (!IsValidEntity2(this.ResistParticle))
            {
                float pos[3];
                this.WorldSpaceCenter(pos);
                pos[2] += 150.0;
                this.ResistParticle = SpawnInfoParticle("powerup_icon_resist_blue", pos, _, this.index);
            }
        }
        else if (IsValidEntity2(this.ResistParticle))
        {
            RemoveEntity2(this.ResistParticle);
            this.ResistParticle = INVALID_ENT;
        }
    }
}

enum
{
    ProvidenceAttack_Shockwave = 1,
    ProvidenceAttack_Projectile,
    ProvidenceAttack_ExplosiveSlash,
    ProvidenceAttack_SpinDash,
};

enum
{
    ProvidencePhase_Intro,
    ProvidencePhase_Solo,
    ProvidencePhase_Retreat,
    ProvidencePhase_Crystals,
};

#include "rf2/customents/providence_shield_crystal.sp"
#include "rf2/npc/actions/providence/main.sp"
#include "rf2/npc/actions/providence/shockwave.sp"
#include "rf2/npc/actions/providence/projectile.sp"
#include "rf2/npc/actions/providence/explosive_slash.sp"
#include "rf2/npc/actions/providence/spin_dash.sp"
#include "rf2/npc/actions/providence/retreat.sp"
#include "rf2/npc/actions/providence/death.sp"

void Providence_OnMapStart()
{
    AddModelToDownloadsTable(MODEL_PROVIDENCE);
    AddSoundToDownloadsTable(SND_GROUND_STAB);
    PrecacheScriptSound(GSND_PROVIDENCE_FOOTSTEP);
    PrecacheScriptSound(GSND_SWORD_HIT);
    PrecacheScriptSound(GSND_SECONDLIFE_EXPLODE);
    PrecacheSound2(SND_SWORD_SWING, true);
    PrecacheSound2(SND_SWORD_IMPACT, true);
    PrecacheSound2(SND_SPIN_START, true);
    PrecacheSound2(SND_SPIN_LOOP, true);
}

static void OnCreate(RF2_Providence boss)
{
	SDKHook(boss.index, SDKHook_SpawnPost, SpawnPost);
    SDKHook(boss.index, SDKHook_ThinkPost, ThinkPost);
    SDKHook(boss.index, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKHook(boss.index, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
    SDKHook(boss.index, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
    boss.SetPropFloat(Prop_Send, "m_flModelScale", 2.5);
	boss.SetModel(MODEL_PROVIDENCE);
    boss.NextAttackTime = GetGameTime()+1.0;
    boss.SpinAttackTime = GetGameTime()+25.0;
    boss.Crystals = new ArrayList();
    boss.HookOnAction(OnAction);
    boss.SetProp(Prop_Send, "m_nSkin", 1);
	boss.BaseNpc.SetBodyMins({-150.0, -150.0, 0.0});
	boss.BaseNpc.SetBodyMaxs({150.0, 150.0, 300.0});
    const float baseHealth = 21500.0;
	float health = baseHealth * GetEnemyHealthMult();
	health *= 1.0 + (0.25 * float(RF2_GetSurvivorCount()-1));
	boss.SetProp(Prop_Data, "m_iHealth", RoundToFloor(health));
	CBaseNPC npc = boss.BaseNpc;
	npc.flStepSize = 18.0;
	npc.flGravity = 800.0;
	npc.flAcceleration = 400.0;
    npc.flMaxYawRate = 100.0;
	npc.flJumpHeight = 150.0;
	npc.flWalkSpeed = 150.0;
	npc.flRunSpeed = 250.0;
	npc.flDeathDropHeight = 99999999.0;
    npc.SetBodyMins(PLAYER_MINS);
	npc.SetBodyMaxs(PLAYER_MAXS);
    boss.Hook_HandleAnimEvent(HandleAnimEvent);
    boss.CanBeHeadshot = true;
    boss.CanBeBackstabbed = true;
    boss.BaseBackstabDamage = 750.0;
}

static void OnRemove(RF2_Providence boss)
{
    delete boss.Crystals;
    boss.Crystals = null;
}

static void SpawnPost(int entity)
{
	RF2_Providence boss = RF2_Providence(entity);
    float mins[3] = PLAYER_MINS;
    float maxs[3] = PLAYER_MAXS;
    ScaleVector(mins, 3.0);
    ScaleVector(maxs, 3.0);
	boss.SetHitboxSize(mins, maxs);
	boss.Team = TEAM_ENEMY;
}

static void ThinkPost(int entity)
{
    RF2_Providence boss = RF2_Providence(entity);
    if (boss.Phase == ProvidencePhase_Crystals && boss.GetCrystalPower() >= 2)
    {
        boss.Health = imin(boss.Health+imax(RoundToFloor(float(boss.MaxHealth) * 0.0035 * GetTickInterval()), 1), boss.MaxHealth);
    }
}

static void OnAction(RF2_Providence boss, const char[] action)
{
    if (strcmp2(action, "spawn_crystals"))
    {
        // Spawn the crystals for the final phase
        int entity = INVALID_ENT;
        char name[32];
        while ((entity = FindEntityByClassname(entity, "info_target")) != INVALID_ENT)
        {
            GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
            if (strcmp2(name, "crystal_spawn"))
            {
                float pos[3];
                GetEntPos(entity, pos);
                RF2_ProvidenceShieldCrystal crystal = RF2_ProvidenceShieldCrystal(CreateEntityByName("rf2_npc_shield_crystal"));
                crystal.Boss = boss;
                crystal.Teleport(pos);
                crystal.Spawn();
                boss.Crystals.Push(EntIndexToEntRef(crystal.index));
            }
        }

        CreateTimer(0.1, Timer_UpdateCrystalBeams, EntIndexToEntRef(boss.index), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
}

static Action Timer_UpdateCrystalBeams(Handle timer, int entity)
{
    RF2_Providence boss = RF2_Providence(EntRefToEntIndex(entity));
    if (!boss.IsValid() || !boss.Crystals)
        return Plugin_Stop;

    float pos1[3], pos2[3];
    boss.WorldSpaceCenter(pos1);
    RF2_ProvidenceShieldCrystal crystal;
    int color[4];
    switch (boss.GetCrystalPower())
    {
        case 1: color = {255, 0, 0, 80};
        case 2: color = {255, 255, 0, 80};
        case 3: color = {0, 255, 150, 80};
    }

    for (int i = 0; i < boss.Crystals.Length; i++)
    {
        crystal = RF2_ProvidenceShieldCrystal(EntRefToEntIndex(boss.Crystals.Get(i)));
        if (!crystal.IsValid() || crystal.Destroyed)
            continue;

        crystal.WorldSpaceCenter(pos2);
        TE_SetupBeamPoints(pos2, pos1, g_iBeamModel, 0, 0, 0, 0.12, 15.0, 15.0, 0, 0.2, color, 10);
        TE_SendToAll();
    }

    return Plugin_Continue;
}

static Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
		float damageForce[3], float damagePosition[3], int damagecustom)
{
    RF2_Providence boss = RF2_Providence(victim);
    if (boss.Phase == ProvidencePhase_Intro || boss.Phase == ProvidencePhase_Retreat)
        return Plugin_Handled;

    if (boss.Phase == ProvidencePhase_Crystals && boss.GetCrystalPower() >= 3)
        return Plugin_Handled;

    return Plugin_Continue;
}

static Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
		float damageForce[3], float damagePosition[3], int damagecustom)
{
    RF2_Providence boss = RF2_Providence(victim);
    Action action = Plugin_Continue;
    if (damagetype & DMG_CRIT)
    {
        bool backstab = IsValidClient(attacker) && IsValidEntity2(weapon) && TF2_GetPlayerClass(attacker) == TFClass_Spy
            && GetPlayerWeaponSlot(attacker, WeaponSlot_Melee) == weapon;

        if (!backstab)
        {
            // 50% resistance to crits, or immunity if we have any crystal power
            float baseDamage = damage/3.0;
            float critDamage;
            if (boss.GetCrystalPower() >= 1)
            {
                critDamage = 0.0;
                damagetype &= ~DMG_CRIT;
            }
            else
            {
                critDamage = damage-baseDamage;
            }

            damage = baseDamage + (critDamage*0.5);
            action = Plugin_Changed;
        }
    }

    if (boss.Phase == ProvidencePhase_Crystals && boss.GetCrystalPower() >= 1)
    {
        damage *= 0.75;
        action = Plugin_Changed;
    }

    return action;
}

static void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon,
		const float damageForce[3], const float damagePosition[3], int damagecustom)
{
    RF2_Providence boss = RF2_Providence(victim);
    if (boss.Health <= 0 && boss.IsRaidBoss())
    {
        if (boss.Phase != ProvidencePhase_Crystals)
        {
            // don't die until last phase
            boss.Health = 1;
            if (boss.Phase == ProvidencePhase_Solo)
            {
                boss.DoAction("retreat_phase");
                boss.Phase = ProvidencePhase_Retreat;
            }
        }
        else
        {
            // Finally die
            boss.DoAction("death");
        }
    }
}

static MRESReturn HandleAnimEvent(int boss, Handle params)
{
	int event = DHookGetParamObjectPtrVar(params, 1, 0, ObjectValueType_Int);
	if (event == 7001 && RF2_Providence(boss).Locomotion.IsAttemptingToMove())
	{
		EmitGameSoundToAll(GSND_PROVIDENCE_FOOTSTEP, boss);
        float center[3];
        GetEntPos(boss, center, true);
        UTIL_ScreenShake(center, 10.0, 20.0, 0.8, 1000.0, SHAKE_START, true);
	}

	return MRES_Ignored;
}

public bool ProvidencePath_FilterIgnoreActors(int entity, int contentsMask, int desiredcollisiongroup)
{
	if ((entity > 0 && entity <= MaxClients) || !IsCombatChar(entity))
	{
		return false;
	}
	
	return true;
}

public bool ProvidencePath_FilterOnlyActors(int entity, int contentsMask, int desiredcollisiongroup)
{
	return ((entity > 0 && entity <= MaxClients) || IsCombatChar(entity));
}