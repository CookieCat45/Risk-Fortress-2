#pragma semicolon 1
#pragma newdecls required

#define MODEL_PUMPKIN "models/props_halloween/jackolantern_02.mdl"
#define SND_PUMPKIN_USE "misc/halloween/spell_meteor_cast.wav"
static CEntityFactory g_Factory;

methodmap RF2_Object_Pumpkin < RF2_Object_Base
{
	public RF2_Object_Pumpkin(int entity)
	{
		return view_as<RF2_Object_Pumpkin>(entity);
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
		g_Factory = new CEntityFactory("rf2_object_pumpkin", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Object_Base.GetFactory());
		g_Factory.Install();
		HookMapStart(Pumpkin_OnMapStart);
	}
}

void Pumpkin_OnMapStart()
{
	PrecacheModel2(MODEL_PUMPKIN, true);
	PrecacheSound2(SND_PUMPKIN_USE, true);
}

static void OnCreate(RF2_Object_Pumpkin pumpkin)
{
	pumpkin.SetModel(MODEL_PUMPKIN);
	pumpkin.SetGlowColor({255, 255, 0, 255});
	pumpkin.HookInteract(Pumpkin_OnInteract);
	pumpkin.SetObjectName("Magical Pumpkin");
	if (pumpkin.Cost <= 0.0)
	{
		pumpkin.Cost = 350.0 * RF2_Object_Base.GetCostMultiplier();
	}
	
	char text[128];
	FormatEx(text, sizeof(text), "($%.0f) Reveal Gargoyle Altar Location", pumpkin.Cost);
	pumpkin.SetWorldText(text);
	pumpkin.SetTextColor({200, 200, 0, 255});
	pumpkin.TextZOffset = 75.0;
}

static Action Pumpkin_OnInteract(int client, RF2_Object_Pumpkin pumpkin)
{
	if (GetPlayerCash(client) >= pumpkin.Cost)
	{
		RF2_Object_Altar altar = RF2_Object_Altar(FindEntityByClassname(MaxClients+1, "rf2_object_altar"));
		if (altar.IsValid())
		{
			AddPlayerCash(client, -pumpkin.Cost);
			altar.SetGlow(true);
			altar.Effects |= EF_ITEM_BLINK;
			ShowAnnotationToAll(_, "Gargoyle Altar", 15.0, altar.index);
			EmitSoundToAll(SND_PUMPKIN_USE, pumpkin.index);
		}
		
		float pos[3];
		pumpkin.WorldSpaceCenter(pos);
		TE_TFParticle("pumpkin_explode", pos);
		RemoveEntity2(pumpkin.index);
	}
	else
	{
		EmitSoundToClient(client, SND_NOPE);
		PrintCenterText(client, "%t", "NotEnoughMoney", pumpkin.Cost, GetPlayerCash(client));
	}
	
	return Plugin_Handled;
}