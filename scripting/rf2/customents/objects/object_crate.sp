#pragma semicolon 1
#pragma newdecls required

#define MODEL_CRATE "models/rf2/objects/crate.mdl"
#define MODEL_CRATE_STRANGE "models/props_hydro/water_barrel.mdl"
#define MODEL_CRATE_HAUNTED "models/player/items/crafting/halloween2015_case.mdl"
#define MODEL_CRATE_COLLECTOR "models/props_island/mannco_case_small.mdl"
#define MODEL_CRATE_UNUSUAL "models/workshop/cases/invasion_case/invasion_case_rare.mdl"
#define MODEL_CRATE_WEAPON "models/items/ammocrate_rockets.mdl"
#define MODEL_CRATE_MULTI "models/workshop/cases/invasion_case/invasion_case.mdl"

static CEntityFactory g_Factory;
enum
{
	Crate_Normal,
	Crate_Large,
	Crate_Strange,
	Crate_Collectors,
	Crate_Haunted,
	Crate_Unusual,
	Crate_Weapon,
	Crate_Multi,
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
		if (!IsValidEntity2(this.index))
		{
			return false;
		}
		
		return CEntityFactory.GetFactoryOfEntity(this.index) == g_Factory;
	}
	
	public static void Init()
	{
		g_Factory = new CEntityFactory("rf2_object_crate", OnCreate, OnRemove);
		g_Factory.DeriveFromFactory(RF2_Object_Base.GetFactory());
		g_Factory.BeginDataMapDesc()
			.DefineIntField("m_iItem", _, "item")
			.DefineIntField("m_iType", _, "type")
			.DefineIntField("m_iMultiType", _, "multitype")
			.DefineIntField("m_hMultiItems")
			.DefineIntField("m_hMultiUserTimer")
			.DefineEntityField("m_hMultiDisplay")
			.DefineEntityField("m_hMultiUser")
			.DefineBoolField("m_bInitialized")
			.DefineBoolField("m_bIsBonus")
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
	
	property int MultiType
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iMultiType");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iMultiType", value);
		}
	}
	
	property int MultiDisplay
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hMultiDisplay");
		}
		
		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hMultiDisplay", value);
		}
	}
	
	property int MultiUser
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hMultiUser");
		}
		
		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hMultiUser", value);
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
	
	property ArrayList MultiItems
	{
		public get()
		{
			return view_as<ArrayList>(this.GetProp(Prop_Data, "m_hMultiItems"));
		}
		
		public set(ArrayList value)
		{
			this.SetProp(Prop_Data, "m_hMultiItems", value);
		}
	}
	
	property Handle MultiUserTimer
	{
		public get()
		{
			return view_as<Handle>(this.GetProp(Prop_Data, "m_hMultiUserTimer"));
		}
		
		public set(Handle value)
		{
			this.SetProp(Prop_Data, "m_hMultiUserTimer", value);
		}
	}
	
	property bool IsBonus
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bIsBonus"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bIsBonus", value);
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
				float finalCost = float(RoundToFloor(cost));
				return finalCost;
			}
		}
		
		float costMult = RF2_Object_Base.GetCostMultiplier();
		switch (this.Type)
		{
			case Crate_Normal: cost = g_cvObjectBaseCost.FloatValue * costMult;
			case Crate_Large, Crate_Collectors: 
			{
				cost = g_cvObjectBaseCost.FloatValue * costMult * 2.0;
				
				// The cost of large and collectors crates goes up in multiplayer to discourage hogging unusual/collector items
				cost *= 1.0 + (0.2 * float(RF2_GetSurvivorCount()-1));
			}
			
			case Crate_Multi:
			{
				switch (this.MultiType)
				{
					case Quality_Normal: cost = g_cvObjectBaseCost.FloatValue * costMult * 1.5;
					case Quality_Genuine: cost = g_cvObjectBaseCost.FloatValue * costMult * 3.0;
					case Quality_Strange: cost = g_cvObjectBaseCost.FloatValue * costMult * 3.5;
					case Quality_Collectors: cost = g_cvObjectBaseCost.FloatValue * costMult * 4.0;
					case Quality_Unusual: cost = g_cvObjectBaseCost.FloatValue * costMult * 24.0;
					default: cost = g_cvObjectBaseCost.FloatValue * costMult * 1.5;
				}
			}
			
			case Crate_Strange, Crate_Weapon: cost = g_cvObjectBaseCost.FloatValue * costMult * 1.5;
			case Crate_Unusual: cost = g_cvObjectBaseCost.FloatValue * costMult * 16.0;
		}
		
		float finalCost = float(RoundToFloor(cost));
		return finalCost;
	}
	
	public void CycleMultiItem(int client=INVALID_ENT)
	{
		bool backpack;
		if (!this.Initialized)
		{
			// initialize
			if (this.MultiType != Quality_Collectors)
			{
				this.Item = this.MultiItems.Get(0);
			}
			else
			{
				backpack = true;
			}
		}
		else
		{
			if (this.MultiType != Quality_Collectors)
			{
				int nextIndex = this.MultiItems.FindValue(this.Item)+1;
				if (nextIndex >= this.MultiItems.Length)
				{
					nextIndex = 0;
				}
				
				this.Item = this.MultiItems.Get(nextIndex);
			}
			else if (IsValidClient(client))
			{
				// cycle through the collector items for this player's class
				TFClassType class = TF2_GetPlayerClass(client);
				for (int i = this.Item+1; i < GetTotalItems(); i++)
				{
					if (i+1 >= GetTotalItems())
						i = 0;
						
					if (i != this.Item && GetCollectorItemClass(i) == class)
					{
						this.Item = i;
						break;
					}
				}
			}
			else
			{
				// we are a collector multicrate, but this was called without a client
				// so reset back to the backpack icon
				backpack = true;
				this.Item = Item_Null;
			}
			
			if (!backpack)
			{
				EmitSoundToAll(SND_MULTICRATE_CYCLE, this.index);
				EmitSoundToAll(SND_MULTICRATE_CYCLE, this.index);
			}
			
			if (IsValidClient(client))
			{
				if (this.MultiUserTimer)
				{
					delete this.MultiUserTimer;
				}
				
				this.MultiUser = client;
				this.MultiUserTimer = CreateTimer(6.0, Timer_ClearMultiUser, EntIndexToEntRef(this.index), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		
		if (IsValidEntity2(this.MultiDisplay))
			RemoveEntity(this.MultiDisplay);
			
		this.MultiDisplay = CreateEntityByName("env_sprite");
		float pos[3];
		this.WorldSpaceCenter(pos);
		pos[2] += 50.0;
		if (backpack)
		{
			DispatchKeyValue(this.MultiDisplay, "model", "materials/hud/backpack_01.vmt");
			DispatchKeyValueFloat(this.MultiDisplay, "scale", 0.04);
		}
		else
		{
			DispatchKeyValueFloat(this.MultiDisplay, "scale", g_flItemSpriteScale[this.Item]);
			DispatchKeyValue(this.MultiDisplay, "model", g_szItemSprite[this.Item]);
		}
		
		DispatchKeyValueInt(this.MultiDisplay, "rendermode", 9);
		TeleportEntity(this.MultiDisplay, pos);
		DispatchSpawn(this.MultiDisplay);
		ParentEntity(this.MultiDisplay, this.index);
		switch (this.MultiType)
		{
			case Quality_Normal:		SetEntityRenderColor(this.MultiDisplay, 200, 200, 200, 50);
			case Quality_Genuine:		SetEntityRenderColor(this.MultiDisplay, 75, 205, 75, 50);
			case Quality_Unusual: 		SetEntityRenderColor(this.MultiDisplay, 150, 75, 205, 50);
			case Quality_Strange:		SetEntityRenderColor(this.MultiDisplay, 150, 100, 0, 50);
			case Quality_Collectors:	SetEntityRenderColor(this.MultiDisplay, 205, 50, 50, 50);
			case Quality_Haunted, 
				Quality_HauntedStrange:	SetEntityRenderColor(this.MultiDisplay, 75, 205, 205, 50);
		}
		
		this.MultiDisplay = EntIndexToEntRef(this.MultiDisplay);
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

				this.SetObjectName("Crate");
			}
			
			case Crate_Large:
			{
				this.SetModel(MODEL_CRATE);
				this.SetPropFloat(Prop_Send, "m_flModelScale", 1.35);
				this.TextZOffset = 90.0;
				if (this.Item == Item_Null)
					this.Item = GetRandomItem(_, 85, 15);

				this.SetObjectName("Large Crate");
				this.SetGlowColor(0, 255, 0, 255);
			}
			
			case Crate_Strange:
			{
				this.SetModel(MODEL_CRATE_STRANGE);
				this.SetRenderColor(255, 100, 0);
				this.TextZOffset = 100.0;
				if (this.Item == Item_Null)
					this.Item = GetRandomItemEx(Quality_Strange);
				
				this.SetObjectName("Strange Barrel");
				this.SetGlowColor(255, 150, 0, 255);
			}
			
			case Crate_Collectors:
			{
				// our item is decided when we're opened
				this.SetModel(MODEL_CRATE_COLLECTOR);
				this.SetObjectName("Collector's Crate");
				this.SetGlowColor(255, 0, 0, 255);

				// hack to adjust position, since due to the model it'll be a bit sunk into the ground
				if (!this.MapPlaced)
				{
					float pos[3];
					this.GetAbsOrigin(pos);
					pos[2] += 20.0;
					this.Teleport(pos);
				}
			}
			
			case Crate_Haunted:
			{
				this.SetModel(MODEL_CRATE_HAUNTED);
				if (this.Item == Item_Null)
					this.Item = GetRandomItem(_, _, _, 1);
				
				if (IsMapRunning())
				{
					float pos[3];
					this.GetAbsOrigin(pos);
					SpawnInfoParticle("spell_fireball_small_glow_blue", pos, _, this.index);
					CBaseEntity light = CBaseEntity(CreateEntityByName("light_dynamic"));
					light.KeyValue("_light", "100 255 255 200");
					light.KeyValueInt("brightness", 5);
					light.KeyValueFloat("distance", 100.0);
					this.WorldSpaceCenter(pos);
					light.Teleport(pos);
					light.Spawn();
					ParentEntity(light.index, this.index);
				}
				
				this.SetObjectName("Haunted Case");
				this.SetGlowColor(0, 255, 255, 255);
				// hack to adjust position, since due to the model it'll be a bit sunk into the ground
				if (!this.MapPlaced)
				{
					float pos[3];
					this.GetAbsOrigin(pos);
					pos[2] += 20.0;
					this.Teleport(pos);
				}
			}
			
			case Crate_Unusual:
			{
				this.SetModel(MODEL_CRATE_UNUSUAL);
				this.SetPropFloat(Prop_Send, "m_flModelScale", 1.2);
				this.SetRenderColor(220, 100, 200);
				this.SetGlowColor(255, 0, 255, 255);
				if (this.Item == Item_Null)
					this.Item = GetRandomItem(_, _, 1);
				
				if (IsMapRunning())
				{
					float pos[3];
					this.GetAbsOrigin(pos);
					TE_TFParticle("utaunt_arcane_purple_sparkle2", pos, this.index);
					CBaseEntity light = CBaseEntity(CreateEntityByName("light_dynamic"));
					light.KeyValue("_light", "255 100 255 200");
					light.KeyValueInt("brightness", 6);
					light.KeyValueFloat("distance", 200.0);
					this.WorldSpaceCenter(pos);
					light.Teleport(pos);
					light.Spawn();
					ParentEntity(light.index, this.index);
				}
				
				this.SetObjectName("Unusual Crate");
				// hack to adjust position, since due to the model it'll be a bit sunk into the ground
				if (!this.MapPlaced)
				{
					float pos[3];
					this.GetAbsOrigin(pos);
					pos[2] += 20.0;
					this.Teleport(pos);
				}
			}
			
			case Crate_Weapon:
			{
				this.SetModel(MODEL_CRATE_WEAPON);
				this.SetObjectName("Munitions Crate");
				this.SetGlowColor(255, 255, 0);
			}
			
			case Crate_Multi:
			{
				this.SetModel(MODEL_CRATE_MULTI);
				this.SetPropFloat(Prop_Send, "m_flModelScale", 1.2);
				this.HookInteract(MultiCrate_OnInteract);
				this.TextZOffset = 90.0;
				
				// hack to adjust position, since due to the model it'll be a bit sunk into the ground
				if (!this.MapPlaced)
				{
					float pos[3];
					this.GetAbsOrigin(pos);
					pos[2] += 20.0;
					this.Teleport(pos);
				}
				
				if (this.MultiType == Quality_None)
				{
					int rand = GetRandomInt(0, 30);
					if (rand >= 10)
					{
						this.MultiType = Quality_Normal;
					}
					else if (rand >= 6)
					{
						this.MultiType = Quality_Genuine;
					}
					else if (rand >= 2)
					{
						this.MultiType = Quality_Strange;
					}
					else
					{
						this.MultiType = Quality_Collectors;
					}
				}
				
				switch (this.MultiType)
				{
					case Quality_Normal:
					{
						this.SetGlowColor(255, 255, 255);
						this.SetObjectName("Multicrate (Normal)");
					}
					case Quality_Genuine:		
					{
						this.SetRenderColor(125, 255, 125, 100);
						this.SetGlowColor(0, 255, 0);
						this.SetObjectName("Multicrate (Genuine)");
					}
					case Quality_Unusual: 		
					{
						this.SetRenderColor(200, 125, 255, 100);
						this.SetGlowColor(255, 0, 0);
						this.SetObjectName("Multicrate (Unusual)");
					}
					case Quality_Strange:
					{
						this.SetRenderColor(200, 150, 0, 100);
						this.SetGlowColor(255, 100, 0);
						this.SetObjectName("Multicrate (Strange)");
					}
					case Quality_Collectors:
					{
						this.SetRenderColor(255, 100, 100, 100);
						this.SetGlowColor(255, 0, 0);
						this.SetObjectName("Multicrate (Collectors)");
					}
					case Quality_Haunted, Quality_HauntedStrange:
					{
						this.SetRenderColor(125, 255, 255, 100);
						this.SetGlowColor(255, 0, 0);
						this.SetObjectName("Multicrate (Haunted)");
					}
				}
				
				if (this.MultiType != Quality_Collectors)
				{
					this.MultiItems = new ArrayList();
					while (this.MultiItems.Length < 3)
					{
						int item = GetRandomItemEx(this.MultiType);
						if (this.MultiItems.FindValue(item) == -1)
						{
							this.MultiItems.Push(item);
						}
					}
				}
				
				if (IsMapRunning())
				{
					this.CycleMultiItem();
				}
			}
		}
		
		this.Cost = this.CalculateCost();
		if (this.Type == Crate_Haunted)
		{
			this.SetWorldText("1 Gargoyle Key (Whack to Open)");
		}
		else if (this.Type == Crate_Multi)
		{
			char text[256];
			if (this.MultiType == Quality_Haunted || this.MultiType == Quality_HauntedStrange)
			{
				FormatEx(text, sizeof(text), "Call for Medic to change the item\n1 Gargoyle Key (Whack to Open)");
				this.SetWorldText(text);
			}
			else
			{
				FormatEx(text, sizeof(text), "Call for Medic to change the item\n$%.0f (Whack to Open)", this.Cost);
				this.SetWorldText(text);
			}
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

RF2_Object_Crate SpawnCrate(int type, const float pos[3], bool bonus=false)
{
	RF2_Object_Crate crate = RF2_Object_Crate(CreateObject("rf2_object_crate", pos, false).index);
	crate.Type = type;
	crate.IsBonus = bonus;
	crate.Initialize();
	crate.Spawn();
	return crate;
}

void Crate_OnMapStart()
{
	AddModelToDownloadsTable(MODEL_CRATE);
	PrecacheModel2(MODEL_CRATE_STRANGE, true);
	PrecacheModel2(MODEL_CRATE_HAUNTED, true);
	PrecacheModel2(MODEL_CRATE_COLLECTOR, true);
	PrecacheModel2(MODEL_CRATE_WEAPON, true);
}

static void OnCreate(RF2_Object_Crate crate)
{
	crate.MultiDisplay = INVALID_ENT;
	crate.MultiUser = INVALID_ENT;
	SDKHook(crate.index, SDKHook_OnTakeDamage, Hook_OnCrateHit);
	SDKHook(crate.index, SDKHook_Spawn, OnSpawn);
	SDKHook(crate.index, SDKHook_SpawnPost, OnSpawnPost);
}

static void OnRemove(RF2_Object_Crate crate)
{
	if (crate.MultiItems)
	{
		delete crate.MultiItems;
		crate.MultiItems = null;
	}
}

static void OnSpawn(int entity)
{
	RF2_Object_Crate crate = RF2_Object_Crate(entity);
	crate.SetProp(Prop_Data, "m_iTeamNum", TEAM_SURVIVOR); // This is so caber hits don't detonate
	if (!crate.Initialized)
	{
		// Probably spawned with ent_create
		crate.Initialize();
	}
}

static void OnSpawnPost(int entity)
{
	// Some crate models have a very small bounding box and can be hard to hit
	RF2_Object_Crate crate = RF2_Object_Crate(entity);
	switch (crate.Type)
	{
		case Crate_Collectors, Crate_Unusual, Crate_Multi:
		{
			crate.ScaleHitbox(2.0);
		}

		case Crate_Haunted, Crate_Strange:
		{
			crate.ScaleHitbox(1.5);
		}
	}
}

static void Timer_ClearMultiUser(Handle timer, int entity)
{
	RF2_Object_Crate crate = RF2_Object_Crate(EntRefToEntIndex(entity));
	if (!crate.IsValid())
	{
		return;
	}
	
	crate.MultiUser = INVALID_ENT;
	crate.MultiUserTimer = null;
	if (crate.MultiType == Quality_Collectors)
	{
		crate.CycleMultiItem();
	}
}

static Action MultiCrate_OnInteract(int client, RF2_Object_Crate crate)
{
	if (!IsPlayerSurvivor(client))
	{
		EmitSoundToClient(client, SND_NOPE);
		PrintCenterText(client, "%t", "WaitForNextMap");
		return Plugin_Handled;
	}
	
	if (IsValidClient(crate.MultiUser) && IsPlayerSurvivor(crate.MultiUser))
	{
		if (crate.MultiUser != client)
		{
			EmitSoundToClient(client, SND_NOPE);
			PrintCenterText(client, "%t", "SomeoneElseUsing");
			return Plugin_Handled;
		}
	}
	
	crate.CycleMultiItem(client);
	return Plugin_Handled;
}

public Action Hook_OnCrateHit(int entity, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePosition[3], int damageCustom)
{
	if (!(damageType & DMG_MELEE) || !IsValidClient(attacker))
		return Plugin_Continue;
	
	if (!IsPlayerSurvivor(attacker) && (!IsFakeClient(attacker) || !TFBot(attacker).HasFlag(TFBOTFLAG_SCAVENGER)))
	{
		EmitSoundToClient(attacker, SND_NOPE);
		PrintCenterText(attacker, "%t", "WaitForNextMap");
		return Plugin_Continue;
	}
	
	SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1); // Remove honorbound
	g_bPlayerMeleeMiss[attacker] = false;
	RF2_Object_Crate crate = RF2_Object_Crate(entity);
	if (!crate.Active)
	{
		return Plugin_Continue;
	}
	
	if (IsPlayerSurvivor(attacker) && IsAtItemShareLimit(attacker)
		&& crate.Type != Crate_Strange && crate.Type != Crate_Weapon)
	{
		EmitSoundToClient(attacker, SND_NOPE);
		PrintCenterText(attacker, "%t", "ItemShareLimit", g_iPlayerItemLimit[g_iPlayerSurvivorIndex[attacker]]);
		return Plugin_Continue;
	}
	
	if (crate.Type == Crate_Multi)
	{
		if (IsValidClient(crate.MultiUser) && IsPlayerSurvivor(crate.MultiUser))
		{
			if (crate.MultiUser != attacker)
			{
				EmitSoundToClient(attacker, SND_NOPE);
				PrintCenterText(attacker, "%t", "SomeoneElseUsing");
				return Plugin_Continue;
			}
		}
		
		if (crate.MultiType == Quality_Collectors && crate.Item == Item_Null)
		{
			PrintCenterText(attacker, "%t", "ChooseItemFirst");
			EmitSoundToClient(attacker, SND_NOPE);
			return Plugin_Continue;
		}
	}
	
	if (crate.Type == Crate_Haunted || crate.Type == Crate_Multi 
		&& (crate.MultiType == Quality_Haunted || crate.MultiType == Quality_HauntedStrange))
	{
		if (PlayerHasItem(attacker, Item_HauntedKey, true))
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
	else if (crate.Type == Crate_Weapon)
	{
		pos[2] -= 30.0;
		StringMap data = GetRandomCustomWeaponData(TF2_GetPlayerClass(attacker));
		int dummyWep = CreateCustomWeaponFromData(data, attacker);
		char key[32];
		data.GetString("key", key, sizeof(key));
		int droppedWep = GenerateDroppedWeapon(dummyWep, pos, key);
		if (droppedWep != INVALID_ENT)
		{
			SetEntProp(droppedWep, Prop_Send, "m_fEffects", 
				GetEntProp(droppedWep, Prop_Send, "m_fEffects")|EF_ITEM_BLINK);
			
			float vel[3];
			vel[0] = GetRandomFloat(-150.0, 150.0);
			vel[1] = GetRandomFloat(-150.0, 150.0);
			vel[2] = 400.0;
			ApplyAbsVelocityImpulse(droppedWep, vel);
		}
		
		RemoveEntity(dummyWep);
		delete data;
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
	int r, g, b, a;
	crate.Effects |= EF_ITEM_BLINK;
	crate.GetRenderColor(r, g, b, a);
	crate.SetRenderColor(r, g, b, 255);
	SpawnInfoParticle(effectName, pos, particleRemoveTime);
	if (crate.Type != Crate_Weapon)
	{
		DataPack pack;
		CreateDataTimer(removeTime, Timer_SpawnItem, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(item);
		pack.WriteCell(GetClientUserId(attacker));
		if (crate.Type == Crate_Multi)
		{
			GetEntPos(crate.MultiDisplay, pos);	
		}
		
		pack.WriteFloat(pos[0]);
		pack.WriteFloat(pos[1]);
		pack.WriteFloat(pos[2]);
	}
	
	CreateTimer(removeTime, Timer_DeleteEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

static void Timer_UltraRareResponse(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return;
	
	SpeakResponseConcept_MVM(client, "TLK_MVM_LOOT_ULTRARARE");
}

static void Timer_SpawnItem(Handle timer, DataPack pack)
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
	if (client > 0 && !GetCookieBool(client, g_coTutorialItemPickup))
	{
		PrintKeyHintText(client, "%t", "ItemPickupTutorial");
	}
}