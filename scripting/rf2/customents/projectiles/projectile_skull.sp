#pragma newdecls required
#pragma semicolon 1
#define MODEL_SKULL "models/props_mvm/mvm_human_skull_collide.mdl"

static CEntityFactory g_Factory;
public const char g_szSkullFireSounds[][] = 
{
	"rf2/sfx/wisp1.mp3",
	"rf2/sfx/wisp2.mp3",
	"rf2/sfx/wisp3.mp3",
	"rf2/sfx/wisp4.mp3",
	"rf2/sfx/wisp5.mp3"
};

static float g_flDeathSecsLeft[MAXTF2PLAYERS];
static int g_iDeathWorldText[MAXTF2PLAYERS] = {INVALID_ENT, ...};
static int g_iDeathInflictor[MAXTF2PLAYERS] = {INVALID_ENT, ...};

methodmap RF2_Projectile_Skull < RF2_Projectile_Base
{
	public RF2_Projectile_Skull(int entity)
	{
		return view_as<RF2_Projectile_Skull>(entity);
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
		g_Factory = new CEntityFactory("rf2_projectile_skull", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Projectile_Base.GetFactory());
		g_Factory.Install();
		HookMapStart(Skull_OnMapStart);
	}
	
	public static bool IsPlayerCursed(int client)
	{
		return IsValidEntity2(g_iDeathWorldText[client]);
	}
}

static void Skull_OnMapStart()
{
	PrecacheModel2(MODEL_SKULL, true);
	PrecacheSoundArray(g_szSkullFireSounds, sizeof(g_szSkullFireSounds));
}

static void OnCreate(RF2_Projectile_Skull skull)
{
	skull.SetModel(MODEL_SKULL);
	skull.Flying = true;
	skull.DeactivateOnHit = false;
	skull.Homing = true;
	skull.HomingSpeed = GetItemMod(ItemStrange_DemonicDome, 2);
	skull.SetRedTrail("flaregun_trail_crit_red");
	skull.SetBlueTrail("flaregun_trail_crit_blue");
	skull.SetFireSound(g_szSkullFireSounds[GetRandomInt(0, sizeof(g_szSkullFireSounds)-1)]);
	skull.HookOnCollide(OnCollide);
}

static void OnCollide(RF2_Projectile_Skull skull, int other)
{
	if (IsCombatChar(other) && IsValidClient(skull.Owner))
	{
		RF_TakeDamage(other, skull.index, skull.Owner, skull.Damage, DMG_GENERIC, ItemStrange_DemonicDome);
		if (IsValidClient(other))
		{
			if (!IsPlayerAlive(other))
			{
				// Summon a skeleton immediately if the enemy was killed by the projectile
				SummonSkeleton(other);
			}
			if (!IsBoss(other) && !RF2_Projectile_Skull.IsPlayerCursed(other)
			&& RandChanceFloatEx(skull.Owner, 0.0001, 1.0, GetItemMod(ItemStrange_DemonicDome, 3)) && GetClientHealth(other) > 0)
			{
				InstantDeathCurse(other, skull.Owner);
			}
		}
	}
}

static void InstantDeathCurse(int client, int inflictor)
{
	TF2_AddCondition(client, TFCond_MarkedForDeath);
	g_flDeathSecsLeft[client] = GetItemMod(ItemStrange_DemonicDome, 4);
	int text = CreateEntityByName("point_worldtext");
	SetEntPropFloat(text, Prop_Send, "m_flTextSize", 15.0);
	SetEntProp(text, Prop_Send, "m_nOrientation", 1);
	char str[8];
	FormatEx(str, sizeof(str), "%.0f", GetItemMod(ItemStrange_DemonicDome, 4));
	SetVariantString(str);
	AcceptEntityInput(text, "SetText");
	float eyePos[3];
	GetClientEyePosition(client, eyePos);
	eyePos[2] += 45.0;
	TeleportEntity(text, eyePos);
	DispatchSpawn(text);
	ParentEntity(text, client, _, true);
	g_iDeathWorldText[client] = EntIndexToEntRef(text);
	g_iDeathInflictor[client] = GetClientUserId(inflictor);
	CreateTimer(1.0, Timer_InstantDeath, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_InstantDeath(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)) || !IsClientInGame(client))
		return Plugin_Stop;
	
	if (!IsPlayerAlive(client))
	{
		if (IsValidEntity2(g_iDeathWorldText[client]))
		{
			RemoveEntity(g_iDeathWorldText[client]);
		}
		
		SummonSkeleton(client);
		return Plugin_Stop;
	}
	
	g_flDeathSecsLeft[client] -= 1.0;
	char str[8];
	FormatEx(str, sizeof(str), "%.0f", g_flDeathSecsLeft[client]);
	SetVariantString(str);
	int text = EntRefToEntIndex(g_iDeathWorldText[client]);
	AcceptEntityInput(text, "SetText");
	if (g_flDeathSecsLeft[client] <= 0.0)
	{
		RemoveEntity(text);
		ForcePlayerSuicide(client);
		int inflictor = GetClientOfUserId(g_iDeathInflictor[client]);
		// manually trigger on kill items, we don't want to have the player dealing damage here
		if (IsValidClient(inflictor) && IsPlayerAlive(inflictor))
		{
			DoItemKillEffects(inflictor, inflictor, client);
		}
		
		SummonSkeleton(client);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

static int SummonSkeleton(int client)
{
	float pos[3];
	GetEntPos(client, pos);
	TE_TFParticle("ghost_smoke", pos);
	int skeleton = CreateEntityByName("tf_zombie");
	SetEntProp(skeleton, Prop_Data, "m_iTeamNum", 5);
	TeleportEntity(skeleton, pos);
	DispatchSpawn(skeleton);
	int health = RoundToFloor(400.0 * GetEnemyHealthMult());
	SetEntProp(skeleton, Prop_Data, "m_iMaxHealth", health);
	SetEntProp(skeleton, Prop_Data, "m_iHealth", health);
	EmitGameSoundToAll("Player.ReceiveSouls", client);
	return skeleton;
}
