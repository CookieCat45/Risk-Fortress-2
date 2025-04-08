#pragma semicolon 1
#pragma newdecls required

#define MODEL_STATUE "models/props_gameplay/tombstone_tankbuster.mdl"

static CEntityFactory g_Factory;
methodmap RF2_Object_Statue < RF2_Object_Base
{
	public RF2_Object_Statue(int entity)
	{
		return view_as<RF2_Object_Statue>(entity);
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
		g_Factory = new CEntityFactory("rf2_object_statue", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Object_Base.GetFactory());
		g_Factory.BeginDataMapDesc()
			.DefineFloatField("m_flNextVoteTime")
		.EndDataMapDesc();
		g_Factory.Install();
		HookMapStart(Statue_OnMapStart);
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

	public static void StartVote(const char[] title)
	{
		Menu vote = new Menu(VoteMenu_EndGame);
		vote.VoteResultCallback = OnEndGameVoteFinish;
		vote.SetTitle(title);
		vote.ExitButton = false;
		vote.AddItem("yes", "Yes");
		vote.AddItem("no", "No");
		int clients[MAXTF2PLAYERS];
		int numClients;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerSurvivor(i, false))
			{
				clients[numClients] = i;
				numClients++;
			}
		}
		
		vote.DisplayVote(clients, numClients, 12);
	}
	
	public static void EndGame()
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;
			
			if (IsPlayerSurvivor(i, false))
			{
				TriggerAchievement(i, ACHIEVEMENT_OBLITERATE);
			}
			
			if (IsPlayerAlive(i))
			{
				float pos[3];
				GetEntPos(i, pos, true);
				TE_TFParticle("ghost_appearation", pos);
				SilentlyKillPlayer(i);
			}
		}
		
		EmitSoundToAll(SND_MERASMUS_APPEAR);
		CreateTimer(2.2, Timer_SetGameWon, _, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(24.0, Timer_GameOver, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

static void Timer_SetGameWon(Handle timer)
{
	g_bGameWon = true;
	PrintToServer("[RF2] Fate Unknown...");
	if (IsServerAutoRestartEnabled())
	{
		if (GetTimeSinceServerStart() >= g_cvTimeBeforeRestart.FloatValue)
		{
			g_bServerRestarting = true;
		}
	}
}

void Statue_OnMapStart()
{
	PrecacheModel2(MODEL_STATUE, true);
}

static void OnCreate(RF2_Object_Statue statue)
{
	statue.SetModel(MODEL_STATUE);
	statue.HookInteract(Statue_OnInteract);
	statue.SetObjectName("Mysterious Gravestone");
	if (IsMapRunning())
	{
		int text = CreateEntityByName("point_worldtext");
		char msg[128];
		if (g_iStagesCompleted < g_cvRequiredStagesForStatue.IntValue)
		{
			FormatEx(msg, sizeof(msg), "%i LEFT.", g_cvRequiredStagesForStatue.IntValue-g_iStagesCompleted);
		}
		else
		{
			msg = "OFFER ME YOUR POWER.";
		}
		
		SetVariantString(msg);
		AcceptEntityInput(text, "SetText");
		DispatchKeyValueInt(text, "orientation", 1);
		DispatchKeyValueFloat(text, "textsize", 16.0);
		SetVariantColor({150, 0, 0, 255});
		AcceptEntityInput(text, "SetColor");
		float pos[3];
		statue.WorldSpaceCenter(pos);
		pos[2] += 100.0;
		TeleportEntity(text, pos);
		DispatchSpawn(text);
		ParentEntity(text, statue.index, _, true);
	}
}

static Action Statue_OnInteract(int client, RF2_Object_Statue statue)
{
	if (g_iStagesCompleted < g_cvRequiredStagesForStatue.IntValue)
	{
		PrintCenterText(client, "%t", "StatueRejected", g_cvRequiredStagesForStatue.IntValue);
		EmitSoundToClient(client, SND_NOPE);
		return Plugin_Handled;
	}
	
	if (IsVoteInProgress())
	{
		RF2_PrintToChat(client, "%t", "VoteInProgress");
		return Plugin_Handled;
	}
	
	if (GameRules_GetRoundState() == RoundState_TeamWin)
	{
		return Plugin_Handled;
	}
	
	if (GetGameTime() < statue.NextVoteTime)
	{
		RF2_PrintToChat(client, "Please wait %.0f seconds.", statue.NextVoteTime-GetGameTime());
		return Plugin_Handled;
	}
	
	if (!IsSingleplayer(false))
	{
		statue.NextVoteTime = GetGameTime()+35.0;
	}
	
	RF2_Object_Statue.StartVote("Offer your power to the mysterious gravestone? (This will end the game.)");
	return Plugin_Handled;
}

static bool g_bIsConfirmation;
public void OnEndGameVoteFinish(Menu menu, int numVotes, int numClients, const int[][] clientInfo, int numItems, const int[][] itemInfo)
{
	if (numVotes > 0)
	{
		int index = itemInfo[0][VOTEINFO_ITEM_INDEX];
		int yesVotes, noVotes;
		if (numItems == 1)
		{
			if (index == 0)
			{
				yesVotes = itemInfo[0][VOTEINFO_ITEM_VOTES];
			}
			else
			{
				noVotes = itemInfo[0][VOTEINFO_ITEM_VOTES];
			}
		}
		else
		{
			yesVotes = index == 0 ? itemInfo[0][VOTEINFO_ITEM_VOTES] : itemInfo[1][VOTEINFO_ITEM_VOTES];
			noVotes =  index == 1 ? itemInfo[0][VOTEINFO_ITEM_VOTES] : itemInfo[1][VOTEINFO_ITEM_VOTES];
		}
		
		if (yesVotes > noVotes || numItems == 1 && yesVotes > 0)
		{
			if (!g_bIsConfirmation)
			{
				RF2_Object_Statue.StartVote("Are you sure you want to do this?");
				g_bIsConfirmation = true;
			}
			else
			{
				RF2_Object_Statue.EndGame();
				g_bIsConfirmation = false;
			}
		}
		else
		{
			g_bIsConfirmation = false;
		}
	}
}

public int VoteMenu_EndGame(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
	}
	
	return 0;
}