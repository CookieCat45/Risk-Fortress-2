#pragma semicolon 1
#pragma newdecls required

#define MODEL_CRATE "models/rf2/objects/crate.mdl"
#define MODEL_CRATE_STRANGE "models/props_hydro/water_barrel.mdl"
#define MODEL_CRATE_HAUNTED "models/player/items/crafting/halloween2015_case.mdl"
#define MODEL_CRATE_COLLECTOR "models/props_island/mannco_case_small.mdl"

static CEntityFactory g_Factory;
enum
{
	Crate_Normal,
	Crate_Large,
	Crate_Strange,
	Crate_Collectors,
	Crate_Haunted,
	CrateType_Max,
};

methodmap RF2_Object_Crate < RF2_Object_Base
{
	public RF2_Object_Crate(int entity)
	{
		return view_as<RF2_Object_Crate>(entity);
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
		g_Factory = new CEntityFactory("rf2_object_crate", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Object_Base.GetFactory());
		g_Factory.BeginDataMapDesc()
			.DefineIntField("m_iItem", _, "item")
			.DefineIntField("m_iType", _, "type")
			.DefineBoolField("m_bInitialized")
		.EndDataMapDesc();
		g_Factory.Install();
		HookMapStart(Crate_OnMapStart);
	}
	
	property int Item
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iItem");
		}

		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iItem", value);
		}
	}
	
	property int Type
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iType");
		}

		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iType", value);
		}
	}
	
	property bool Initialized
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bInitialized"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bInitialized", value);
		}
	}
	
	public float CalculateCost()
	{
		float cost;
		if (this.MapPlaced)
		{
			cost = this.Cost;
			// This object's cost was set by the mapper
			if (cost > 0.0)
			{
				return float(RoundToFloor(cost));
			}
		}
		
		float costMult = RF2_Object_Base.GetCostMultiplier();
		switch (this.Type)
		{
			case Crate_Normal: cost = g_cvObjectBaseCost.FloatValue * costMult;
			case Crate_Large, Crate_Collectors: cost = g_cvObjectBaseCost.FloatValue * costMult * 2.0;
			case Crate_Strange: cost =g_cvObjectBaseCost.FloatValue * costMult * 1.5;
		}
		
		return float(RoundToFloor(cost));
	}
	
	public void Initialize()
	{
		switch (this.Type)
		{
			case Crate_Normal:
			{
				this.SetModel(MODEL_CRATE);
				if (this.Item == Item_Null)
					this.Item = GetRandomItem(79, 20, 1);
			}
			
			case Crate_Large:
			{
				this.SetModel(MODEL_CRATE);
				this.SetPropFloat(Prop_Send, "m_flModelScale", 1.35);
				this.TextZOffset = 90.0;
				if (this.Item == Item_Null)
					this.Item = GetRandomItem(_, 85, 15);
			}
			
			case Crate_Strange:
			{
				this.SetModel(MODEL_CRATE_STRANGE);
				this.SetRenderColor(255, 100, 0);
				this.TextZOffset = 100.0;
				if (this.Item == Item_Null)
					this.Item = GetRandomItemEx(Quality_Strange);
			}
			
			case Crate_Collectors:
			{
				// our item is decided when we're opened
				this.SetModel(MODEL_CRATE_COLLECTOR);
			}
			
			case Crate_Haunted:
			{
				this.SetModel(MODEL_CRATE_HAUNTED);
				if (this.Item == Item_Null)
					this.Item = GetRandomItem(_, _, _, 1);
			}
		}
		
		this.Cost = this.CalculateCost();
		if (this.Type == Crate_Haunted)
		{
			this.SetWorldText("1 Gargoyle Key (Whack to Open)");
		}
		else
		{
			char text[256];
			FormatEx(text, sizeof(text), "$%.0f (Whack to Open)", this.Cost);
			this.SetWorldText(text);
		}
		
		this.Initialized = true;
	}
}

RF2_Object_Crate SpawnCrate(int type, const float pos[3])
{
	RF2_Object_Crate crate = RF2_Object_Crate(CreateObject("rf2_object_crate", pos, false).index);
	crate.Type = type;
	crate.Initialize();
	crate.Spawn();
	return crate;
}

void Crate_OnMapStart()
{
	PrecacheModel2(MODEL_CRATE, true);
	PrecacheModel2(MODEL_CRATE_STRANGE, true);
	PrecacheModel2(MODEL_CRATE_HAUNTED, true);
	PrecacheModel2(MODEL_CRATE_COLLECTOR, true);
	AddModelToDownloadsTable(MODEL_CRATE);
}

static void OnCreate(RF2_Object_Crate crate)
{
	SDKHook(crate.index, SDKHook_OnTakeDamage, Hook_OnCrateHit);
	SDKHook(crate.index, SDKHook_Spawn, OnSpawn);
}

static void OnSpawn(int entity)
{
	RF2_Object_Crate crate = RF2_Object_Crate(entity);
	if (!crate.Initialized)
	{
		// Probably spawned with ent_create
		crate.Initialize();
	}
}

public Action Hook_OnCrateHit(int entity, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePosition[3], int damageCustom)
{
	if (!IsValidClient(attacker) || !IsPlayerSurvivor(attacker) || !(damageType & DMG_MELEE))
		return Plugin_Continue;
	
	RF2_Object_Crate crate = RF2_Object_Crate(entity);
	if (!crate.Active)
		return Plugin_Continue;
	
	if (crate.Type == Crate_Haunted)
	{
		if (PlayerHasItem(attacker, Item_HauntedKey))
		{
			GiveItem(attacker, Item_HauntedKey, -1);
		}
		else
		{
			EmitSoundToClient(attacker, SND_NOPE);
			PrintCenterText(attacker, "%t", "NoKeys");
			return Plugin_Continue;
		}
	}
	else if (GetPlayerCash(attacker) >= crate.Cost)
	{
		AddPlayerCash(attacker, -crate.Cost);
	}
	else
	{
		EmitSoundToClient(attacker, SND_NOPE);
		PrintCenterText(attacker, "%t", "NotEnoughMoney", crate.Cost, GetPlayerCash(attacker));
		return Plugin_Continue;
	}
	
	float pos[3];
	crate.GetAbsOrigin(pos);
	pos[2] += 40.0;
	int item;
	if (crate.Type == Crate_Collectors)
	{
		item = GetRandomCollectorItem(TF2_GetPlayerClass(attacker));
	}
	else
	{
		item = crate.Item;
	}
	
	float removeTime, particleRemoveTime;
	char effectName[32];
	switch (GetItemQuality(item))
	{
		case Quality_Unusual:
		{
			EmitAmbientSound(SND_DROP_UNUSUAL, pos);
			EmitAmbientSound(SND_DROP_UNUSUAL, pos);
			EmitAmbientSound(SND_DROP_UNUSUAL, pos);
			EmitAmbientSound(SND_DROP_UNUSUAL, pos);
			effectName = "mvm_pow_gold_seq";
			removeTime = 2.9;
			particleRemoveTime = 10.0;
			CreateTimer(4.0, Timer_UltraRareResponse, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
			g_iPlayerUnusualsUnboxed[attacker]++;
			if (g_iPlayerUnusualsUnboxed[attacker] >= 3)
			{
				TriggerAchievement(attacker, ACHIEVEMENT_LUCKY);
			}
		}
		case Quality_Haunted, Quality_HauntedStrange:
		{
			EmitAmbientSound(SND_DROP_HAUNTED, pos);
			effectName = "ghost_appearation";
			UTIL_ScreenShake(pos, 12.0, 20.0, 3.0, 150.0, SHAKE_START, true);
			particleRemoveTime = 3.0;
		}
		default:
		{
			EmitSoundToAll(SND_DROP_DEFAULT, entity);
			effectName = "mvm_loot_explosion";
			removeTime = 0.0;
			particleRemoveTime = 3.0;
		}
	}
	
	crate.Active = false;
	SpawnInfoParticle(effectName, pos, particleRemoveTime);
	DataPack pack;
	CreateDataTimer(removeTime, Timer_SpawnItem, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(item);
	pack.WriteCell(GetClientUserId(attacker));
	pack.WriteFloat(pos[0]);
	pack.WriteFloat(pos[1]);
	pack.WriteFloat(pos[2]);
	CreateTimer(removeTime, Timer_DeleteEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Timer_UltraRareResponse(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;
	
	SpeakResponseConcept_MVM(client, "TLK_MVM_LOOT_ULTRARARE");
	return Plugin_Continue;
}

public Action Timer_SpawnItem(Handle timer, DataPack pack)
{
	int client, item;
	float pos[3];
	
	pack.Reset();
	item = pack.ReadCell();
	client = GetClientOfUserId(pack.ReadCell());
	pos[0] = pack.ReadFloat();
	pos[1] = pack.ReadFloat();
	pos[2] = pack.ReadFloat();
	SpawnItem(item, pos, client, 6.0);
	
	if (!GetCookieBool(client, g_coTutorialItemPickup))
	{
		PrintKeyHintText(client, "%t", "ItemPickupTutorial");
	}
	
	return Plugin_Continue;
}