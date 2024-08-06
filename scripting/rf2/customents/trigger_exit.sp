#pragma semicolon 1
#pragma newdecls required

static CEntityFactory g_Factory;
methodmap RF2_Trigger_Exit < CBaseEntity
{
	public RF2_Trigger_Exit(int entity)
	{
		return view_as<RF2_Trigger_Exit>(entity);
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
		g_Factory = new CEntityFactory("rf2_trigger_exit", OnCreate, OnRemove);
		g_Factory.DeriveFromClass("trigger_multiple");
		g_Factory.BeginDataMapDesc()
			.DefineIntField("m_hPlayersArray")
			.DefineFloatField("m_flNextVoteTime")
			.DefineFloatField("m_flMinTimeBeforeUse")
			.DefineEntityField("m_hWorldText")
		.EndDataMapDesc();
		g_Factory.Install();
	}
	
	property ArrayList PlayersArray
	{
		public get()
		{
			return view_as<ArrayList>(this.GetProp(Prop_Data, "m_hPlayersArray"));
		}
		
		public set(ArrayList value)
		{
			this.SetProp(Prop_Data, "m_hPlayersArray", value);
		}
	}
	
	property float NextVoteTime
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flNextVoteTime");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flNextVoteTime", value);
		}
	}

	property float MinTimeBeforeUse
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flMinTimeBeforeUse");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flMinTimeBeforeUse", value);
		}
	}

	property int WorldText
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hWorldText");
		}
		
		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hWorldText", value);
		}
	}
	
	public int GetRequiredPlayers()
	{
		if (IsSingleplayer(false))
			return 1;
		
		int players = GetPlayersOnTeam(TEAM_SURVIVOR, false, true);
		return imax(1, RoundToFloor(float(players) * 0.67));
	}
	
	public bool IsToucherValid(int entity)
	{
		return IsValidClient(entity) && !IsFakeClient(entity) && (IsPlayerSurvivor(entity) || IsPlayerMinion(entity));
	}

	public void AddPlayer(int client)
	{
		int userId = GetClientUserId(client);
		if (this.PlayersArray.FindValue(userId) == -1)
		{
			this.PlayersArray.Push(userId);
		}
	}
	
	public void RemovePlayer(int client)
	{
		int userId = GetClientUserId(client);
		int index;
		if ((index = this.PlayersArray.FindValue(userId)) != -1)
		{
			this.PlayersArray.Erase(index);
		}
	}
	
	public int GetPlayerCount()
	{
		int client, userId, count;
		for (int i = this.PlayersArray.Length-1; i >= 0; i--)
		{
			userId = this.PlayersArray.Get(i);
			if (!(client = GetClientOfUserId(userId)) || !IsPlayerSurvivor(client, false) && !IsPlayerMinion(client))
			{
				this.PlayersArray.Erase(this.PlayersArray.FindValue(userId));
				continue;
			}

			count++;
		}
		
		return count;
	}
	
	public void UpdateWorldText()
	{
		char msg[128];
		if (!IsSingleplayer(false) && GetGameTime() < this.MinTimeBeforeUse)
		{
			FormatEx(msg, sizeof(msg), "Please Wait... (%.0f)", this.MinTimeBeforeUse-GetGameTime());
		}
		else if (GetGameTime() < this.NextVoteTime)
		{
			FormatEx(msg, sizeof(msg), "Vote Failed, Please Wait... (%.0f)", this.NextVoteTime-GetGameTime());
		}
		else
		{
			FormatEx(msg, sizeof(msg), "Stand Here to Depart (%i/%i)", this.GetPlayerCount(), this.GetRequiredPlayers());
		}
		
		SetVariantString(msg);
		AcceptEntityInput(this.WorldText, "SetText");
	}
}

static void OnCreate(RF2_Trigger_Exit trigger)
{
	if (!IsMapRunning() || g_bWaitingForPlayers)
		return;
	
	trigger.PlayersArray = new ArrayList();
	trigger.MinTimeBeforeUse = GetGameTime()+120.0;
	SDKHook(trigger.index, SDKHook_StartTouchPost, Hook_ExitStartTouch);
	SDKHook(trigger.index, SDKHook_EndTouchPost, Hook_ExitEndTouch);
	CreateTimer(0.2, Timer_VoteCheck, EntIndexToEntRef(trigger.index), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	trigger.WorldText = CreateEntityByName("point_worldtext");
	trigger.UpdateWorldText();
	CBaseEntity text = CBaseEntity(trigger.WorldText);
	text.KeyValueFloat("textsize", 18.0);
	text.KeyValue("orientation", "1");
	SetVariantColor({0, 255, 255, 255});
	text.AcceptInput("SetColor");
	float pos[3];
	trigger.WorldSpaceCenter(pos);
	text.Teleport(pos);
	text.Spawn();
	ParentEntity(text.index, trigger.index, _, true);
}

static void OnRemove(RF2_Trigger_Exit trigger)
{
	if (trigger.PlayersArray)
	{
		delete trigger.PlayersArray;
		trigger.PlayersArray = null;
	}
}

public Action Timer_VoteCheck(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return Plugin_Stop;
	
	if (GameRules_GetRoundState() == RoundState_TeamWin)
	{
		RemoveEntity2(entity);
		return Plugin_Stop;
	}
	
	if (IsVoteInProgress())
		return Plugin_Continue;
	
	RF2_Trigger_Exit trigger = RF2_Trigger_Exit(entity);
	if (!IsSingleplayer(false) && GetGameTime() < trigger.MinTimeBeforeUse)
	{
		trigger.UpdateWorldText();
		return Plugin_Continue;
	}
	
	if (GetGameTime() >= trigger.NextVoteTime && trigger.GetPlayerCount() >= trigger.GetRequiredPlayers())
	{
		RF2_Object_Teleporter.StartVote(_, true);
		float value = IsSingleplayer(false) ? 6.0 : 50.0;
		trigger.NextVoteTime = GetGameTime() + value;
	}
	else
	{
		trigger.UpdateWorldText();
	}
	
	return Plugin_Continue;
}

static void Hook_ExitStartTouch(int entity, int other)
{
	RF2_Trigger_Exit trigger = RF2_Trigger_Exit(entity);
	if (trigger.IsToucherValid(other))
	{
		trigger.AddPlayer(other);
		if (!IsVoteInProgress())
			trigger.UpdateWorldText();
	}
}

static void Hook_ExitEndTouch(int entity, int other)
{
	RF2_Trigger_Exit trigger = RF2_Trigger_Exit(entity);
	if (trigger.IsToucherValid(other))
	{
		trigger.RemovePlayer(other);
		if (!IsVoteInProgress())
			trigger.UpdateWorldText();
	}
}
