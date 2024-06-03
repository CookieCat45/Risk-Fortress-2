#pragma semicolon 1
#pragma newdecls required

static CEntityFactory g_Factory;
methodmap RF2_WorldCenter < CBaseEntity
{
	public RF2_WorldCenter(int entity)
	{
		return view_as<RF2_WorldCenter>(entity);
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
		g_Factory = new CEntityFactory("rf2_world_center");
		g_Factory.DeriveFromClass("info_target");
		g_Factory.Install();
	}
}

// Returns entity index for legacy reasons
int GetWorldCenter(float vec[3])
{
	int entity = EntRefToEntIndex(g_iWorldCenterEntity);
	if (entity != INVALID_ENT)
	{
		GetEntPos(entity, vec, true);
		return entity;
	}
	
	RF2_WorldCenter center = RF2_WorldCenter(FindEntityByClassname(INVALID_ENT, "rf2_world_center"));
	if (center.IsValid())
	{
		center.WorldSpaceCenter(vec);
		g_iWorldCenterEntity = EntIndexToEntRef(center.index);
		return center.index;
	}
	else
	{
		entity = MaxClients+1;
		char targetName[128];
		while ((entity = FindEntityByClassname(entity, "info_target")) != INVALID_ENT)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));
			if (strcmp2(targetName, "rf2_world_center"))
			{
				GetEntPos(entity, vec, true);
				g_iWorldCenterEntity = EntIndexToEntRef(entity);
				return entity;
			}
		}
	}
	
	vec = {0.0, 0.0, 0.0};
	return INVALID_ENT;
}
