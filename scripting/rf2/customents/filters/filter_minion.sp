#pragma semicolon 1
#pragma newdecls required

static CEntityFactory g_Factory;
methodmap RF2_Filter_Minion < CBaseEntity
{
	public RF2_Filter_Minion(int entity)
	{
		return view_as<RF2_Filter_Minion>(entity);
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
		g_Factory = new CEntityFactory("rf2_filter_minion", OnCreate);
		g_Factory.DeriveFromClass("filter_activator_class");
		g_Factory.Install();
	}
}

static void OnCreate(RF2_Filter_Minion filter)
{
    g_hHookPassesFilterImpl.HookEntity(Hook_Pre, filter.index, DHook_PassesFilterImpl);
}

static MRESReturn DHook_PassesFilterImpl(int filter, DHookReturn returnVal, DHookParam params)
{
    int client = params.Get(2);
    if (!IsValidClient(client) || !IsPlayerMinion(client));
    {
        returnVal.Value = false;
        return MRES_Supercede;
    }

    returnVal.Value = true;
    return MRES_Supercede;
}
