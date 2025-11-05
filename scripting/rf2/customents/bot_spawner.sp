#pragma semicolon 1
#pragma newdecls required

static CEntityFactory g_Factory;
methodmap RF2_BotSpawner < CBaseEntity
{
	public RF2_BotSpawner(int entity)
	{
		return view_as<RF2_BotSpawner>(entity);
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
		g_Factory = new CEntityFactory("rf2_bot_spawner");
		g_Factory.DeriveFromBaseEntity(true);
        g_Factory.BeginDataMapDesc()
            .DefineStringField("m_szBotName", _, "bot_name")
            .DefineInputFunc("SpawnBot", InputFuncValueType_Void, Input_SpawnBot)
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
    
    public void SpawnBot()
    {
        char botName[128];
        this.GetBotName(botName, sizeof(botName));
        Enemy enemy = Enemy.FindByInternalName(botName);
        if (enemy == NULL_ENEMY)
        {
            LogError("rf2_bot_spawner: bot '%s' doesn't exist.", botName);
            return;
        }
        
        ArrayList players = FindBestPlayersToSpawn(1, enemy.IsBoss);
        if (players.Length <= 0)
        {
            delete players;
            CreateTimer(0.2, Timer_SpawnBotRecursive, this, TIMER_FLAG_NO_MAPCHANGE);
            return;
        }
        
        int client = players.Get(0);
        delete players;
        float pos[3];
        this.GetAbsOrigin(pos);
        bool result = enemy.IsBoss ? SpawnBoss(client, enemy.Index, pos, _, _, _, false) : SpawnEnemy(client, enemy.Index, pos, _, _, false);
        if (!result)
        {
            CreateTimer(0.2, Timer_SpawnBotRecursive, this, TIMER_FLAG_NO_MAPCHANGE);
        }
        else
        {
            TeleportEntity(client, pos);
        }
    }
}

static void Timer_SpawnBotRecursive(Handle timer, RF2_BotSpawner spawner)
{
    if (!spawner.IsValid())
        return;
        
    spawner.SpawnBot();
}

static void Input_SpawnBot(int entity, int activator, int caller)
{
    RF2_BotSpawner(entity).SpawnBot();
}
