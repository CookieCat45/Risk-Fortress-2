#pragma newdecls required
#pragma semicolon 1

#define MODEL_BOTLER "models/rf2/bots/botler.mdl"
#define MODEL_MEDKIT "models/items/medkit_small.mdl"
#define SND_BOMB_FUSE "ambient/gas/cannister_loop.wav"
static CEntityFactory g_Factory;

static const char g_szIdleVoices[][] =
{
	"rf2/sfx/botler/idle_01.mp3",
	"rf2/sfx/botler/idle_02.mp3",
	"rf2/sfx/botler/idle_03.mp3",
	"rf2/sfx/botler/idle_04.mp3"
};

static const char g_szHealVoices[][] =
{
	"rf2/sfx/botler/heal_01.mp3",
	"rf2/sfx/botler/heal_02.mp3",
};

static const char g_szHurtVoices[][] =
{
	"rf2/sfx/botler/pain_01.mp3",
	"rf2/sfx/botler/pain_02.mp3",
};

static const char g_szBotGibs[][] =
{
	"models/bots/bot_worker/bot_worker_head_gib.mdl",
	"models/bots/bot_worker/bot_worker_arm_gib.mdl",
	"models/bots/bot_worker/bot_worker_wheel_gib.mdl",
	"models/bots/bot_worker/bot_worker_body_gib.mdl",
	"models/bots/bot_worker/bot_worker_body_gib.mdl",
	"models/bots/bot_worker/bot_worker_a_body_gib_L.mdl",
	"models/bots/bot_worker/bot_worker_a_body_gib_R.mdl",
	"models/bots/bot_worker/bot_worker_a_head_gib_L.mdl",
	"models/bots/bot_worker/bot_worker_a_head_gib_R.mdl"
};

methodmap RF2_RobotButler < RF2_NPC_Base
{
	public RF2_RobotButler(int entity)
	{
		return view_as<RF2_RobotButler>(entity);
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
		g_Factory = new CEntityFactory("rf2_npc_robot_butler", OnCreate, OnRemove);
		g_Factory.DeriveFromFactory(GetBaseNPCFactory());
		g_Factory.SetInitialActionFactory(RF2_RobotButlerMainAction.GetFactory());
		g_Factory.BeginDataMapDesc()
			.DefineFloatField("m_flSuicideBombAt")
			.DefineFloatField("m_flBombDamage")
			.DefineFloatField("m_flBombRadius")
			.DefineFloatField("m_flHealCooldown")
			.DefineFloatField("m_flLastHealedPlayerAt", MAXTF2PLAYERS)
			.DefineFloatField("m_flNextIdleVoiceAt")
			.DefineFloatField("m_flNextHurtVoiceAt")
			.DefineEntityField("m_hHeldItem")
			.DefineEntityField("m_hMaster")
			.DefineEntityField("m_hTimerText")
		.EndDataMapDesc();
		g_Factory.Install();
		HookMapStart(RobotButler_OnMapStart);
	}
	
	property int TimerText
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hTimerText");
		}
		
		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hTimerText", value);
		}
	}

	property int Master
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hMaster");
		}

		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hMaster", value);
		}
	}

	property float SuicideBombAt
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flSuicideBombAt");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flSuicideBombAt", value);
		}
	}
	
	property float NextIdleVoiceAt
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flNextIdleVoiceAt");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flNextIdleVoiceAt", value);
		}
	}
	
	property float NextHurtVoiceAt
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flNextHurtVoiceAt");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flNextHurtVoiceAt", value);
		}
	}
	
	property float BombDamage
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flBombDamage");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flBombDamage", value);
		}
	}
	
	property float BombRadius
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flBombRadius");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flBombRadius", value);
		}
	}
	
	property float HealCooldown
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flHealCooldown");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flHealCooldown", value);
		}
	}

	property int HeldItem
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hHeldItem");
		}
		
		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hHeldItem", value);
		}
	}
	
	public void PlayIdleVoice()
	{
		int num = GetRandomInt(0, sizeof(g_szIdleVoices)-1);
		EmitSoundToAll(g_szIdleVoices[num], this.index, SNDCHAN_VOICE);
	}
	
	public void PlayHealVoice()
	{
		int num = GetRandomInt(0, sizeof(g_szHealVoices)-1);
		EmitSoundToAll(g_szHealVoices[num], this.index, SNDCHAN_VOICE);
	}
	
	public void PlayHurtVoice()
	{
		int num = GetRandomInt(0, sizeof(g_szHurtVoices)-1);
		EmitSoundToAll(g_szHurtVoices[num], this.index, SNDCHAN_VOICE);
	}
	
	public void SetPlayerNextHeal(int client, float value)
	{
		this.SetPropFloat(Prop_Data, "m_flLastHealedPlayerAt", value, client);
	}
	
	public float GetPlayerNextHeal(int client)
	{
		return this.GetPropFloat(Prop_Data, "m_flLastHealedPlayerAt", client);
	}
	
	public bool ShouldSuicideBomb()
	{
		return this.GetTimeLeftUntilBomb() <= 0.0;
	}
	
	public float GetTimeLeftUntilBomb()
	{
		return FloatAbs(fmax(this.SuicideBombAt - GetGameTime(), 0.0));
	}
	
	public void SelfDestruct()
	{
		EmitSoundToAll("misc/null.wav", this.index, SNDCHAN_VOICE); // so he stops talking
		this.SpewGibs(g_szBotGibs, sizeof(g_szBotGibs));
		float pos[3];
		this.WorldSpaceCenter(pos);
		EmitAmbientGameSound("Weapon_TackyGrendadier.Explode", pos);
		DoExplosionEffect(pos);
		DoRadiusDamage(IsValidClient(this.Master) ? this.Master : this.index, this.index, pos, ItemStrange_Botler, this.BombDamage, DMG_BLAST, this.BombRadius);
		RemoveEntity2(this.index);
	}
	
	public void UpdateTimerText()
	{
		if (IsValidEntity2(this.TimerText))
		{
			char text[8];
			FormatEx(text, sizeof(text), "%.0f", this.GetTimeLeftUntilBomb());
			SetVariantString(text);
			AcceptEntityInput(this.TimerText, "SetText");
		}
	}
}

#include "rf2/npc/actions/robot_butler/main.sp"
#include "rf2/npc/actions/robot_butler/heal.sp"
#include "rf2/npc/actions/robot_butler/suicide_bomb.sp"

void RobotButler_OnMapStart()
{
	PrecacheSoundArray(g_szIdleVoices, sizeof(g_szIdleVoices));
	PrecacheSoundArray(g_szHealVoices, sizeof(g_szHealVoices));
	PrecacheSoundArray(g_szHurtVoices, sizeof(g_szHurtVoices));
	PrecacheModelArray(g_szBotGibs, sizeof(g_szBotGibs), false);
	PrecacheSound2(SND_BOMB_FUSE, true);
	AddModelToDownloadsTable(MODEL_BOTLER);
	AddMaterialToDownloadsTable("materials/rf2/bots/robot_butler");
	AddMaterialToDownloadsTable("materials/rf2/bots/robot_butler_1");
	AddMaterialToDownloadsTable("materials/rf2/bots/robot_butler_blu");
	AddMaterialToDownloadsTable("materials/rf2/bots/robot_butler_1_blu");
	AddMaterialToDownloadsTable("materials/rf2/bots/robot_butler_color");
	AddMaterialToDownloadsTable("materials/rf2/bots/robot_butler_normal");
	AddMaterialToDownloadsTable("materials/rf2/bots/robot_butler_blue_color");
	AddMaterialToDownloadsTable("materials/rf2/bots/robot_butler_1_color");
	AddMaterialToDownloadsTable("materials/rf2/bots/robot_butler_1_blue_color");
	// the file pathing is messed up in the VMTs, this is the easier way to fix it
	AddMaterialToDownloadsTable("materials/models/props_embargo/robot_butler_phongexponent");
	AddMaterialToDownloadsTable("materials/models/props_embargo/robot_butler_blue_color");
	AddMaterialToDownloadsTable("materials/models/props_embargo/robot_butler_1_color");
	AddMaterialToDownloadsTable("materials/models/props_embargo/robot_butler_1_blue_color");
	AddMaterialToDownloadsTable("materials/models/props_embargo/robot_butler_color");
	AddMaterialToDownloadsTable("materials/models/props_embargo/robot_butler_normal");
}

static void OnCreate(RF2_RobotButler bot)
{
	bot.SetModel(MODEL_BOTLER);
	PrecacheModel2(MODEL_MEDKIT, true);
	SDKHook(bot.index, SDKHook_SpawnPost, OnSpawnPost);
	
	// TODO: add friendly fire blocking to npc_base instead
	SDKHook(bot.index, SDKHook_OnTakeDamage, OnTakeDamage); // hooking this instead to actually block friendly fire damage so items don't proc
	SDKHook(bot.index, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
	
	bot.SuicideBombAt = GetGameTime()+90.0;
	bot.HealCooldown = 25.0;
	bot.BombDamage = 650.0;
	bot.BombRadius = 500.0;
	int health = RoundToFloor(800.0 * GetEnemyHealthMult());
	bot.MaxHealth = health;
	bot.Health = health;
	CreateTimer(1.0, Timer_BotRegenHealth, EntIndexToEntRef(bot.index), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	CBaseNPC npc = bot.BaseNpc;
	npc.flStepSize = 18.0;
	npc.flGravity = 800.0;
	npc.flAcceleration = 2000.0;
	npc.flJumpHeight = 60.0;
	npc.flWalkSpeed = 175.0;
	npc.flRunSpeed = 350.0;
	npc.flDeathDropHeight = 99999999.0;
}

static void OnRemove(RF2_RobotButler bot)
{
	StopSound(bot.index, SNDCHAN_AUTO, SND_BOMB_FUSE);
	StopSound(bot.index, SNDCHAN_AUTO, SND_BOMB_FUSE);
}

static void OnSpawnPost(int entity)
{
	RF2_RobotButler bot = RF2_RobotButler(entity);
	ToggleGlow(bot.index, true, {0, 255, 0, 255});
	CreateHealthText(bot.index, 75.0, 15.0, "BOTLER");
	bot.TimerText = CreateEntityByName("point_worldtext");
	CBaseEntity text = CBaseEntity(bot.TimerText);
	text.KeyValueFloat("textsize", 18.0);
	text.KeyValue("orientation", "1");
	SetVariantColor({255, 255, 255, 255});
	text.AcceptInput("SetColor");
	float pos[3];
	bot.WorldSpaceCenter(pos);
	pos[2] += 55.0;
	text.Teleport(pos);
	text.Spawn();
	ParentEntity(text.index, bot.index, _, true);
}

static Action Timer_BotRegenHealth(Handle timer, int entity)
{
	RF2_RobotButler bot = RF2_RobotButler(EntRefToEntIndex(entity));
	if (!bot.IsValid())
		return Plugin_Stop;
	
	// might as well do this here
	bot.UpdateTimerText();

	if (bot.Health >= bot.MaxHealth)
		return Plugin_Continue;
	
	// Regenerate 5% of our health every second
	bot.Health = imin(bot.MaxHealth, bot.Health+RoundToFloor(float(bot.MaxHealth)*0.05));
	return Plugin_Continue;
}

static Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
		float damageForce[3], float damagePosition[3], int damagecustom)
{
	RF2_RobotButler bot = RF2_RobotButler(victim);
	if (GetEntTeam(attacker) == bot.Team || GetEntTeam(inflictor) == bot.Team)
	{
		// no friendly fire
		return Plugin_Stop;
	}
	
	if (damagetype & DMG_CRIT)
	{
		damagetype &= ~DMG_CRIT; // crit damage immunity
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

static void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon,
		const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	RF2_RobotButler bot = RF2_RobotButler(victim);
	if (GetGameTime() >= bot.NextHurtVoiceAt)
	{
		bot.PlayHurtVoice();
		bot.NextHurtVoiceAt = GetGameTime()+1.0;
	}
}
