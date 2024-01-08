#if defined _RF2_raidboss_galleom_included
 #endinput
#endif
#define _RF2_raidboss_galleom_included

#pragma semicolon 1
#pragma newdecls required
#define MODEL_GALLEOM "models/rf2/bosses/galleom.mdl"
#define SND_FIST_SLAM "rf2/sfx/galleom/hammerknuckle.wav"
#define SND_JUMP "rf2/sfx/galleom/jump.wav"
#define SND_JUMP_SLAM "rf2/sfx/galleom/jump_slam.wav"
#define SND_BODYSLAM_START "rf2/sfx/galleom/bodyslam_start.wav"
#define SND_BODYSLAM_LAND "rf2/sfx/galleom/bodyslam_land.wav"
#define SND_DOUBLESLAM "rf2/sfx/galleom/doubleslam.wav"
#define SND_TANKLOOP "rf2/sfx/galleom/tank_loop.wav"
#define SND_TANKEXIT "rf2/sfx/galleom/tank_exit.wav"
#define SND_GALLEOM_ROAR "rf2/sfx/galleom/roar.wav"
#define SND_JET_LOOP "weapons/flame_thrower_dg_loop.wav"
#define SND_JET_START "weapons/flame_thrower_dg_start.wav"

static CEntityFactory g_Factory;

#include "actions/galleom/main.sp"
#include "actions/galleom/attack_hammerknuckle.sp"
#include "actions/galleom/attack_bigjump.sp"
#include "actions/galleom/attack_bodyslam.sp"
#include "actions/galleom/attack_doubleslam.sp"
#include "actions/galleom/attack_hops.sp"
#include "actions/galleom/attack_tankram.sp"
#include "actions/galleom/death.sp"

#define GALLEOM_BASE_HEALTH 15000.0

methodmap RF2_RaidBoss_Galleom < RF2_RaidBoss_Base
{
	public RF2_RaidBoss_Galleom(int entity)
	{
		return view_as<RF2_RaidBoss_Galleom>(entity);
	}
	
	public bool IsValid()
	{
		if (!RF2_RaidBoss_Base(this.index).IsValid())
		{
			return false;
		}
		
		return CEntityFactory.GetFactoryOfEntity(this.index) == g_Factory;
	}
	
	public static void Initialize()
	{
		g_Factory = new CEntityFactory("rf2_npc_raidboss_galleom", OnCreate, OnRemove);
		g_Factory.DeriveFromClass("rf2_npc_raidboss_base");
		g_Factory.SetInitialActionFactory(RF2_GalleomMainAction.GetFactory());
		g_Factory.BeginDataMapDesc()
			.DefineEntityField("m_Target")
			.DefineIntField("m_PathFollower")
		.EndDataMapDesc();
		g_Factory.Install();
	}
}

void Galleom_OnMapStart()
{
	static bool init;
	if (!init)
	{
		RF2_RaidBoss_Galleom.Initialize();
		init = true;
	}
	
	PrecacheModel(MODEL_GALLEOM, true);
	PrecacheSound(SND_FIST_SLAM, true);
	PrecacheSound(SND_JUMP, true);
	PrecacheSound(SND_JUMP_SLAM, true);
	PrecacheSound(SND_BODYSLAM_START, true);
	PrecacheSound(SND_BODYSLAM_LAND, true);
	PrecacheSound(SND_DOUBLESLAM, true);
	PrecacheSound(SND_TANKLOOP, true);
	PrecacheSound(SND_TANKEXIT, true);
	PrecacheSound(SND_GALLEOM_ROAR, true);
	PrecacheSound(SND_JET_LOOP, true);
	PrecacheSound(SND_JET_START, true);
	//AddModelToDownloadsTable(MODEL_GALLEOM);
}

static void OnCreate(RF2_RaidBoss_Galleom boss)
{
	SDKHook(boss.index, SDKHook_ThinkPost, ThinkPost);
	SDKHook(boss.index, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
	SDKHook(boss.index, SDKHook_SpawnPost, OnSpawnPost);
	boss.SetModel(MODEL_GALLEOM);
	boss.BaseNpc.SetBodyMins({-150.0, -150.0, 0.0});
	boss.BaseNpc.SetBodyMaxs({150.0, 150.0, 300.0});
	float health = GALLEOM_BASE_HEALTH * GetEnemyHealthMult();
	health *= 1.0 + (0.25 * float(RF2_GetSurvivorCount()-1));
	boss.SetProp(Prop_Data, "m_iHealth", RoundToFloor(health));
	boss.Path = PathFollower(_, GalleomPath_FilterIgnoreActors, GalleomPath_FilterOnlyActors);
	boss.BaseNpc.flAcceleration = 2000.0;
}

static void ThinkPost(int entity)
{
	RF2_RaidBoss_Galleom(entity).SetNextThink(GetGameTime());
}

static void OnSpawnPost(int entity)
{
	RF2_RaidBoss_Galleom boss = RF2_RaidBoss_Galleom(entity);
	boss.SetHitboxSize({-150.0, -150.0, 0.0}, {150.0, 150.0, 300.0});
}

static void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3])
{
	RF2_RaidBoss_Galleom boss = RF2_RaidBoss_Galleom(victim);
	int health = boss.GetProp(Prop_Data, "m_iHealth");
	TE_TFParticle("bot_impact_heavy", damagePosition);
	Event event = CreateEvent("npc_hurt");
	if (event)
	{
		event.SetInt("entindex", boss.index);
		event.SetInt("health", health > 0 ? health : 0);
		event.SetInt("damageamount", RoundToFloor(damage));
		event.SetBool("crit", (damagetype & DMG_CRIT) == DMG_CRIT);

		if (attacker > 0 && attacker <= MaxClients)
		{
			event.SetInt("attacker_player", GetClientUserId(attacker));
			event.SetInt("weaponid", 0);
		}
		else
		{
			event.SetInt("attacker_player", 0);
			event.SetInt("weaponid", 0);
		}

		event.Fire();
	}
}

static void OnRemove(RF2_RaidBoss_Galleom boss)
{
	if (boss.Path)
	{
		boss.Path.Destroy();
		boss.Path = view_as<PathFollower>(0);
	}
}

public bool GalleomPath_FilterIgnoreActors(int entity, int contentsMask, int desiredcollisiongroup)
{
	return true;
}

public bool GalleomPath_FilterOnlyActors(int entity, int contentsMask, int desiredcollisiongroup)
{
	return false;
}