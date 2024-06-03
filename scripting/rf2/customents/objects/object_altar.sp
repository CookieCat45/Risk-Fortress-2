#pragma semicolon 1
#pragma newdecls required

#define MODEL_ALTAR "models/props_halloween/gargoyle_backpack.mdl"
#define SND_ALTAR "misc/halloween/spell_spawn_boss.wav"

static CEntityFactory g_Factory;
methodmap RF2_Object_Altar < RF2_Object_Base
{
	public RF2_Object_Altar(int entity)
	{
		return view_as<RF2_Object_Altar>(entity);
	}
	
	public static CEntityFactory GetFactory()
	{
		return g_Factory;
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
		g_Factory = new CEntityFactory("rf2_object_altar", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Object_Base.GetFactory());
		g_Factory.Install();
		HookMapStart(Altar_OnMapStart);
		
		CEntityFactory factory = new CEntityFactory("rf2_altar_spawn");
		factory.DeriveFromBaseEntity();
		factory.BeginDataMapDesc()
			.DefineOutput("OnChosen")
		.EndDataMapDesc();
		factory.Install();
	}
}

void Altar_OnMapStart()
{
	PrecacheModel2(MODEL_ALTAR, true);
	PrecacheSound2(SND_ALTAR, true);
}

static void OnCreate(RF2_Object_Altar altar)
{
	altar.TextSize = 3.0;
	altar.TextDist = 100.0;
	altar.Effects = 0; // no flashing
	altar.SetModel(MODEL_ALTAR);
	altar.SetWorldText("(1 Gargoyle Key) Call for Medic to activate");
	altar.SetObjectName("Gargoyle Altar");
	altar.HookInteract(OnInteract);
}

static Action OnInteract(int client, RF2_Object_Altar altar)
{
	if (PlayerHasItem(client, Item_HauntedKey))
	{
		GiveItem(client, Item_HauntedKey, -1);
		float pos[3];
		altar.WorldSpaceCenter(pos);
		TE_TFParticle("ghost_appearation", pos);
		UTIL_ScreenShake(pos, 15.0, 10.0, 5.0, 9000000.0, SHAKE_START, true);
		PrintCenterTextAll("%t", "AltarActivated");
		EmitSoundToAll(SND_ALTAR);
		RemoveEntity2(altar.index);
		g_bEnteringUnderworld = true;
		TriggerAchievement(client, ACHIEVEMENT_GARGOYLE);
		int entity = MaxClients+1;
		while ((entity = FindEntityByClassname(entity, "rf2_object_pumpkin")) != INVALID_ENT)
		{
			GetEntPos(entity, pos, true);
			TE_TFParticle("pumpkin_explode", pos);
			RemoveEntity2(entity);
		}
	}
	else
	{
		EmitSoundToClient(client, SND_NOPE);
		PrintCenterText(client, "%t", "AltarNoKeys");
	}
	
	return Plugin_Handled;
}
