#pragma semicolon 1
#pragma newdecls required
#define MODEL_TREE "models/props_manor/deadtree01.mdl"
static CEntityFactory g_Factory;

methodmap RF2_Object_Tree < RF2_Object_Base
{
	public RF2_Object_Tree(int entity)
	{
		return view_as<RF2_Object_Tree>(entity);
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
		g_Factory = new CEntityFactory("rf2_object_tree", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Object_Base.GetFactory());
		g_Factory.Install();
		HookMapStart(Tree_OnMapStart);
	}
	
	public void OnVoteSuccess()
	{
		this.Active = false;
		this.Effects = 0;
		this.SetWorldText("");
	}
}

void Tree_OnMapStart()
{
	PrecacheModel2(MODEL_TREE, true);
}

static void OnCreate(RF2_Object_Tree tree)
{
	tree.DisallowNonSurvivorMinions = true;
	tree.SetModel(MODEL_TREE);
	tree.SetObjectName("Tree of Fate");
	tree.TextZOffset = 100.0;
	ArrayList mapList = g_bEnteringFinalArea ? null : GetMapsForStage(DetermineNextStage());	
	if (g_bEnteringFinalArea || mapList && mapList.Length <= 1)
	{
		// If there's only 1 map for the next stage, there's no point in using this object
		tree.Active = false;
		tree.Effects = 0;
		tree.SetWorldText("Try Again Later :)");
		if (mapList) 
			delete mapList;

		return;
	}
	
	delete mapList;
	tree.HookInteract(Tree_OnInteract);
	tree.SetWorldText("Determine your Fate (1 Gargoyle Key)");
	tree.SetTextColor(0, 255, 255, 255);
}

static int g_iVoteClient = INVALID_ENT;
static int g_iVoteTree = INVALID_ENT;
static Action Tree_OnInteract(int client, RF2_Object_Tree tree)
{
	if (GetPlayerItemCount(client, Item_HauntedKey, true) < 1)
	{
		EmitSoundToClient(client, SND_NOPE);
		PrintCenterText(client, "%t", "AltarNoKeys", 1);
		return Plugin_Handled;
	}
	
	if (IsVoteInProgress())
	{
		RF2_PrintToChat(client, "%t", "VoteInProgress");
		return Plugin_Handled;
	}
	
	char mapName[128];
	Menu vote = new Menu(Vote_SetNextMap);
	vote.SetTitle("Decide your Fate? (%N)", client);
	g_iVoteClient = GetClientUserId(client);
	g_iVoteTree = EntIndexToEntRef(tree.index);
	ArrayList mapList = GetMapsForStage(DetermineNextStage());
	
	// randomize
	for (int i = 0; i < mapList.Length; i++)
	{
		mapList.SwapAt(i, GetRandomInt(0, mapList.Length-1));
	}
	
	// only allow up to 2 options
	if (mapList.Length > 2)
		mapList.Resize(2);
	
	for (int i = 0; i < mapList.Length; i++)
	{
		mapList.GetString(i, mapName, sizeof(mapName));
		vote.AddItem(mapName, mapName);
	}
	
	delete mapList;
	int clients[MAXPLAYERS];
	int clientCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (IsPlayerSurvivor(i, false) || IsPlayerMinion(i)))
		{
			clients[clientCount] = i;
			clientCount++;
		}
	}
	
	vote.AddItem("cancel", "Cancel Vote");
	vote.ExitButton = false;
	vote.DisplayVote(clients, clientCount, 12);
	return Plugin_Handled;
}

public int Vote_SetNextMap(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_VoteEnd:
		{
			int voteClient = GetClientOfUserId(g_iVoteClient);
			if (!IsValidClient(voteClient))
			{
				RF2_PrintToChatAll("{red}The player who started the vote has left. The vote was automatically cancelled.");
				return 0;
			}
			
			char info[128];
			menu.GetItem(param1, info, sizeof(info));
			if (!info[0] || strcmp2(info, "cancel"))
			{
				RF2_PrintToChat(voteClient, "The vote failed. None of your {haunted}Gargoyle Keys {default}were consumed.");
				return 0;
			}
			
			g_szForcedMap = info;
			RF2_PrintToChatAll("The next map has been set to {yellow}%s{default}. {yellow}%N {default}has paid {haunted}1 Gargoyle Key.", info, voteClient);
			GiveItem(voteClient, Item_HauntedKey, -1);
			RF2_Object_Tree tree = RF2_Object_Tree(EntRefToEntIndex(g_iVoteTree));
			if (tree.IsValid())
			{
				tree.OnVoteSuccess();
			}
		}
		
		case MenuAction_End: 
		{
			delete menu;
		}
	}
	
	return 0;
}