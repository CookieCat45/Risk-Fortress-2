#pragma semicolon 1
#pragma newdecls required

#define MODEL_DISPENSER_SHIELD "models/rf2/dispenser_shield.mdl"
#define MODEL_DISPENSER_SHIELD_L2 "models/rf2/dispenser_shield_smaller.mdl"
#define MODEL_DISPENSER_SHIELD_L1 "models/rf2/dispenser_shield_smallest.mdl"

static CEntityFactory g_Factory;
methodmap RF2_DispenserShield < CBaseEntity
{
	public RF2_DispenserShield(int entity)
	{
		return view_as<RF2_DispenserShield>(entity);
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
		g_Factory = new CEntityFactory("rf2_dispenser_shield", OnCreate);
		g_Factory.DeriveFromClass("tf_taunt_prop"); // so bots and NPCs don't treat it as solid, since it's a CBaseCombatCharacter
		g_Factory.BeginDataMapDesc()
			.DefineEntityField("m_hDispenser")
			.DefineBoolField("m_bEnabled")
			.DefineIntField("m_iLevel")
		.EndDataMapDesc();
		g_Factory.Install();
		HookMapStart(DispenserShield_OnMapStart);
	}
	
	property int Dispenser
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hDispenser");
		}
		
		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hDispenser", value);
		}
	}
	
	property int Level
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iLevel");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iLevel", value);
		}
	}
	
	property bool Enabled
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bEnabled"));
		}

		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bEnabled", value);
		}
	}
	
	public void Toggle(bool state, bool playSound=false)
	{
		if (state)
		{
			this.SetRenderMode(RENDER_NORMAL);
			this.SetProp(Prop_Send, "m_nSolidType", SOLID_VPHYSICS);
			if (!this.Enabled && playSound)
			{
				EmitGameSoundToAll("WeaponMedi_Shield.Deploy", this.index);
			}
		}
		else
		{
			this.SetRenderMode(RENDER_NONE);
			this.SetProp(Prop_Send, "m_nSolidType", SOLID_NONE);
			if (this.Enabled && playSound)
			{
				EmitGameSoundToAll("WeaponMedigun.HealingDetachTarget", this.index);
			}
		}
		
		this.Enabled = state;
	}
}

void DispenserShield_OnMapStart()
{
	AddModelToDownloadsTable(MODEL_DISPENSER_SHIELD);
	AddModelToDownloadsTable(MODEL_DISPENSER_SHIELD_L2);
	AddModelToDownloadsTable(MODEL_DISPENSER_SHIELD_L1);
	AddMaterialToDownloadsTable("materials/rf2/mvm_resist_shield");
	AddMaterialToDownloadsTable("materials/rf2/resist_shield_blue");
}

RF2_DispenserShield CreateDispenserShield(int team, int dispenser=INVALID_ENT, float pos[3]=NULL_VECTOR)
{
	RF2_DispenserShield shield = RF2_DispenserShield(CreateEntityByName("rf2_dispenser_shield"));
	SetEntTeam(shield.index, team);
	if (dispenser != INVALID_ENT)
	{
		float center[3];
		GetEntPos(dispenser, center, true);
		shield.Teleport(center);
		ParentEntity(shield.index, dispenser);
		shield.Dispenser = dispenser;
		if (GameRules_GetProp("m_bInSetup"))
		{
			shield.Level = 3;
		}
		else
		{
			shield.SetModel(MODEL_DISPENSER_SHIELD_L1);
		}
		
		shield.Toggle(false);
		shield.Spawn();
	}
	else if (!IsNullVector(pos))
	{
		shield.Teleport(pos);
		shield.Spawn();
	}
	
	return shield;
}

RF2_DispenserShield GetDispenserShield(int dispenser)
{
	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "rf2_dispenser_shield")) != INVALID_ENT)
	{
		if (RF2_DispenserShield(entity).Dispenser == dispenser)
		{
			return RF2_DispenserShield(entity);
		}
	}
	
	return RF2_DispenserShield(INVALID_ENT);
}

static void OnCreate(RF2_DispenserShield shield)
{
	shield.Enabled = true;
	shield.SetModel(MODEL_DISPENSER_SHIELD);
	shield.SetProp(Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
	shield.SetProp(Prop_Data, "m_bloodColor", -1);
	shield.SetProp(Prop_Data, "m_iEFlags", shield.GetProp(Prop_Data, "m_iEFlags")|EFL_DONTBLOCKLOS);
	shield.SetProp(Prop_Send, "m_fEffects", EF_NOSHADOW);
	shield.SetProp(Prop_Send, "m_nSolidType", SOLID_VPHYSICS);
	shield.SetProp(Prop_Send, "m_usSolidFlags", FSOLID_TRIGGER|FSOLID_TRIGGER_TOUCH_DEBRIS);
	SetEntityCollisionGroup(shield.index, TFCOLLISION_GROUP_COMBATOBJECT);
	SDKHook(shield.index, SDKHook_ShouldCollide, Hook_DispenserShieldShouldCollide);
	SDKHook(shield.index, SDKHook_SpawnPost, Hook_DispenserShieldSpawnPost);
	g_hHookIsCombatItem.HookEntity(Hook_Pre, shield.index, DHook_IsCombatItem);
}

public void Hook_DispenserShieldSpawnPost(int entity)
{
	RF2_DispenserShield shield = RF2_DispenserShield(entity);
	TFTeam team = view_as<TFTeam>(GetEntTeam(entity));
	if (team == TFTeam_Red || team == TFTeam_Blue)
	{
		shield.SetProp(Prop_Send, "m_nSkin", view_as<int>(team)-2);
	}
	
	shield.SetMoveType(MOVETYPE_NONE);
	//shield.SetNextThink(GetGameTime()+99999.0);
}

public bool Hook_DispenserShieldShouldCollide(int entity, int collisionGroup, int mask, bool originalResult)
{
	// mimic medigun shield collision rules
	if ( collisionGroup == COLLISION_GROUP_PROJECTILE || 
		 collisionGroup == TFCOLLISION_GROUP_ROCKETS || 
		 collisionGroup == TFCOLLISION_GROUP_ROCKET_BUT_NOT_WITH_OTHER_ROCKETS )
	{
		switch(view_as<TFTeam>(GetEntTeam(entity)))
		{
			case TFTeam_Red:
			{
				if (mask & CONTENTS_TEAM2)
					return false;
			}
			
			case TFTeam_Blue:
			{
				if (mask & CONTENTS_TEAM1)
					return false;
			}
		}
	}
	
	return originalResult;
}

static MRESReturn DHook_IsCombatItem(int entity, DHookReturn returnVal)
{
	// true to allow bullets/projectiles from my team to pass through the shield.
	returnVal.Value = true;
	return MRES_Supercede;
}
