#pragma semicolon 1
#pragma newdecls required

static CEntityFactory g_Factory;
methodmap RF2_Logic_BotDeath < CBaseEntity
{
	public RF2_Logic_BotDeath(int entity)
	{
		return view_as<RF2_Logic_BotDeath>(entity);
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
		g_Factory = new CEntityFactory("rf2_logic_bot_death");
		g_Factory.DeriveFromBaseEntity(true);
		g_Factory.BeginDataMapDesc()
			.DefineStringField("m_szBotName", _, "bot_name")
			.DefineOutput("OnBotDeath")
		.EndDataMapDesc();
		g_Factory.Install();
	}

    public int GetBotName(char[] buffer, int size)
    {
        return this.GetPropString(Prop_Data, "m_szBotName", buffer, size);
    }

    public void SetBotName(const char[] name)
    {
        this.SetPropString(Prop_Data, "m_szBotName", name);
    }
}
