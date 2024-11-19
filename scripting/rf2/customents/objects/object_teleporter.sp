#pragma semicolon 1
#pragma newdecls required

#define MODEL_TELEPORTER "models/rf2/objects/teleporter.mdl"
#define MODEL_TELEPORTER_RADIUS "models/rf2/objects/teleporter_radius.mdl"
#define TELEPORTER_RADIUS 1500.0

static CEntityFactory g_Factory;
enum
{
	TELE_EVENT_INACTIVE,
	TELE_EVENT_PREPARING,
	TELE_EVENT_ACTIVE,
	TELE_EVENT_COMPLETE,
};

methodmap RF2_Object_Teleporter < RF2_Object_Base
{
	public RF2_Object_Teleporter(int entity)
	{
		return view_as<RF2_Object_Teleporter>(entity);
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
		g_Factory = new CEntityFactory("rf2_object_teleporter", OnCreate, OnRemove);
		g_Factory.DeriveFromFactory(RF2_Object_Base.GetFactory());
		g_Factory.BeginDataMapDesc()
			.DefineIntField("m_iEventState")
			.DefineFloatField("m_flCharge")
			.DefineFloatField("m_flRadius")
			.DefineEntityField("m_hBubble")
		.EndDataMapDesc();
		g_Factory.Install();
		HookMapStart(Teleporter_OnMapStart);
		
		CEntityFactory factory = new CEntityFactory("rf2_teleporter_spawn");
		factory.DeriveFromBaseEntity();
		factory.BeginDataMapDesc()
			.DefineOutput("OnChosen")
		.EndDataMapDesc();
		factory.Install();
	}
	
	public static bool IsEventActive()
	{
		RF2_Object_Teleporter teleporter = GetCurrentTeleporter();
		return teleporter.IsValid() && teleporter.EventState == TELE_EVENT_ACTIVE;
	}

	property int EventState
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iEventState");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iEventState", value);
		}
	}

	property float Charge
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flCharge");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flCharge", value);
		}
	}
	
	property float Radius
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flRadius");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flRadius", value);
		}
	}
	
	property CBaseAnimating Bubble
	{
		public get()
		{
			return CBaseAnimating(this.GetPropEnt(Prop_Data, "m_hBubble"));
		}
		
		public set(CBaseAnimating bubble)
		{
			this.SetPropEnt(Prop_Data, "m_hBubble", bubble.index);
		}
	}

	public static int GetDefaultTeleModel(char[] buffer, int size)
	{
		return strcopy(buffer, size, MODEL_TELEPORTER);
	}
	
	public static void StartVote(int client=INVALID_ENT, bool nextStageVote=false)
	{
		if (GameRules_GetRoundState() == RoundState_TeamWin)
			return;

		if (IsVoteInProgress())
		{
			if (client > 0)
				RF2_PrintToChat(client, "%t", "VoteInProgress");
			
			return;
		}
		
		int clients[MAX_SURVIVORS];
		int clientCount;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;
				
			if (GetClientTeam(i) == TEAM_SURVIVOR)
			{
				clients[clientCount] = i;
				clientCount++;
				if (clientCount >= MAX_SURVIVORS)
				{
					break;
				}
			}
		}
		
		Menu vote = new Menu(Menu_TeleporterVote);
		bool final = nextStageVote && g_iLoopCount >= 1 && IsAboutToLoop() && !IsInUnderworld() && RF2_IsMapValid(g_szFinalMap);
		if (nextStageVote)
		{
			if (final)
			{
				// ask if they want to enter the final area
				if (client > 0)
					vote.SetTitle("A fork appears in the path ahead. Where do you wish to go? (%N)", client);
				else
					vote.SetTitle("A fork appears in the path ahead. Where do you wish to go?");

				vote.VoteResultCallback = OnNextStageVoteFinishFinal;
			}
			else
			{
				if (client > 0)
					vote.SetTitle("Depart now? (%N)", client);
				else
					vote.SetTitle("Depart now?");
				
				vote.VoteResultCallback = OnNextStageVoteFinish;
			}
		}
		else
		{
			if (client > 0)
				vote.SetTitle("Start the Teleporter event? (%N)", client);
			else
				vote.SetTitle("Start the Teleporter event?");

			vote.VoteResultCallback = OnTeleporterVoteFinish;
		}
		
		if (final)
		{
			vote.AddItem("final_area", "Travel towards the large industrial building in the distance");
			vote.AddItem("normal_path", "Continue on the normal path");
			vote.AddItem("nowhere", "I'm not going anywhere yet");
		}
		else
		{
			vote.AddItem("Yes", "Yes");
			vote.AddItem("No", "No");
		}
		
		vote.ExitButton = false;
		vote.DisplayVote(clients, clientCount, final ? 25 : 12);
	}
	
	public void Prepare()
	{
		if (this.EventState != TELE_EVENT_INACTIVE)
			return;

		this.EventState = TELE_EVENT_PREPARING;
		this.SetGlow(true);
		RF2_PrintToChatAll("%t", "TeleporterActivated");
		StopMusicTrackAll();
		float pos[3];
		this.GetAbsOrigin(pos);
		this.Effects = 0;
		CreateTimer(3.0, Timer_StartTeleporterEvent, EntIndexToEntRef(this.index), TIMER_FLAG_NO_MAPCHANGE);
		
		// start some effects (fog and shake)
		UTIL_ScreenShake(pos, 16.0, 50.0, 3.0, MAX_MAP_SIZE, SHAKE_START, true);
		
		int fog = CreateEntityByName("env_fog_controller");
		DispatchKeyValueInt(fog, "spawnflags", 1);
		DispatchKeyValueInt(fog, "fogenabled", 1);
		DispatchKeyValueFloat(fog, "fogstart", 100.0);
		DispatchKeyValueFloat(fog, "fogend", 250.0);
		DispatchKeyValueFloat(fog, "fogmaxdensity", 0.7);
		DispatchKeyValue(fog, "fogcolor", "40 0 0");
		DispatchSpawn(fog);
		AcceptEntityInput(fog, "TurnOn");			
		const float time = 3.0;
		int oldFog[MAXTF2PLAYERS] = {INVALID_ENT, ...};
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i))
				continue;
			
			oldFog[i] = GetEntPropEnt(i, Prop_Data, "m_hCtrl");
			SetEntPropEnt(i, Prop_Data, "m_hCtrl", fog);
			if (fog == INVALID_ENT)
				continue;
			
			DataPack pack;
			CreateDataTimer(time, Timer_RestorePlayerFog, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(GetClientUserId(i));
			pack.WriteCell(EntIndexToEntRef(oldFog[i]));
		}
		
		CreateTimer(time, Timer_KillFog, EntIndexToEntRef(fog), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	public void Start()
	{
		if (this.EventState == TELE_EVENT_ACTIVE || this.EventState == TELE_EVENT_COMPLETE)
			return;

		this.EventState = TELE_EVENT_ACTIVE;
		this.TextSize = 20.0;
		Call_StartForward(g_fwTeleEventStart);
		Call_Finish();
		
		RF2_GameRules gamerules = GetRF2GameRules();
		if (gamerules.IsValid())
		{
			gamerules.FireOutput("OnTeleporterEventStart");
		}
		
		this.Radius = TELEPORTER_RADIUS * g_cvTeleporterRadiusMultiplier.FloatValue;
		this.ToggleObjects(false);
		CBaseAnimating bubble = CBaseAnimating(CreateEntityByName("prop_dynamic_override"));
		this.Bubble = bubble;
		bubble.SetModel(MODEL_TELEPORTER_RADIUS);
		bubble.KeyValueFloat("fademaxdist", 0.0);
		bubble.KeyValueFloat("fademindist", 0.0);
		bubble.SetRenderMode(RENDER_TRANSCOLOR);
		bubble.SetRenderColor(255, 255, 255, 75);
		const float baseModelScale = 1.55;
		bubble.SetPropFloat(Prop_Send, "m_flModelScale", baseModelScale * g_cvTeleporterRadiusMultiplier.FloatValue);
		float pos[3];
		this.GetAbsOrigin(pos);
		bubble.Teleport(pos);
		bubble.Spawn();
		
		// Summon our bosses for this event
		SummonTeleporterBosses(this);
		int hhhSpawnCount, eyeSpawnCount;
		const int bossSpawnLimit = 20;
		
		if (g_szBossBGM[0])
			PlayMusicTrackAll();
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerSurvivor(i))
				continue;
			
			if (PlayerHasItem(i, Item_HorsemannHead, true))
			{
				hhhSpawnCount += GetPlayerItemCount(i, Item_HorsemannHead, true, true);
				if (hhhSpawnCount > bossSpawnLimit)
					hhhSpawnCount = bossSpawnLimit;
				
				// this is so the player can't just drop the item to avoid being targeted
				g_hHHHTargets.Push(GetClientUserId(i));
			}
			
			if (PlayerHasItem(i, Item_Monoculus, true))
			{
				eyeSpawnCount += GetPlayerItemCount(i, Item_Monoculus, true, true);
				if (eyeSpawnCount > bossSpawnLimit)
					eyeSpawnCount = bossSpawnLimit;

				g_hMonoculusTargets.Push(GetClientUserId(i));
			}
		}
		
		if (hhhSpawnCount > 0 || eyeSpawnCount > 0)
		{
			int boss;
			float resultPos[3];
			float mins[3] = PLAYER_MINS;
			float maxs[3] = PLAYER_MAXS;
			ScaleVector(mins, 1.75);
			ScaleVector(maxs, 1.75);
			const float zOffset = 25.0;
			CNavArea area;
			float time;
			
			if (hhhSpawnCount + eyeSpawnCount >= 5)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (!IsClientInGame(i) || IsFakeClient(i) || !IsPlayerSurvivor(i, false) && !IsPlayerMinion(i))
						continue;
					
					TriggerAchievement(i, ACHIEVEMENT_HALLOWEENBOSSES);
				}
			}
			
			while (hhhSpawnCount > 0 || eyeSpawnCount > 0)
			{
				area = GetSpawnPoint(pos, resultPos, 0.0, this.Radius*1.5, -1, true, mins, maxs, MASK_NPCSOLID, zOffset);
				if (area)
				{
					if (hhhSpawnCount > 0)
					{
						boss = CreateEntityByName("headless_hatman");
						hhhSpawnCount--;
					}
					else if (eyeSpawnCount > 0)
					{
						boss = CreateEntityByName("eyeball_boss");
						SetEntTeam(boss, 5);
						eyeSpawnCount--;
					}
					
					TeleportEntity(boss, resultPos);
					// this is really just to prevent earrape, especially with Monoculus...
					CreateTimer(time, Timer_DelayHalloweenBossSpawn, boss, TIMER_FLAG_NO_MAPCHANGE);
					time += 0.3;
				}
			}
		}
		
		CreateTimer(0.1, Timer_TeleporterThink, EntIndexToEntRef(this.index), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	public void End()
	{
		if (this.EventState == TELE_EVENT_COMPLETE)
			return;

		this.ToggleObjects(true);
		this.EventState = TELE_EVENT_COMPLETE;
		this.Effects = EF_ITEM_BLINK;
		this.TextSize = 6.0;
		this.SetWorldText("Call for Medic to go to the next stage!");
		
		if (IsValidEntity2(this.Bubble.index))
			RemoveEntity(this.Bubble.index);
		
		EmitSoundToAll(SND_TELEPORTER_CHARGED);
		StopMusicTrackAll();
		RF2_Object_Teleporter.EventCompletion();
		RF2_PrintToChatAll("%t", "TeleporterComplete");
		RF2_GameRules gamerules = GetRF2GameRules();
		if (gamerules.IsValid())
		{
			gamerules.FireOutput("OnTeleporterEventComplete");
		}
	}
	
	public void ToggleObjects(bool state)
	{
		int entity = MaxClients+1;
		int r, g, b, a;
		while ((entity = FindEntityByClassname(entity, "rf2_object*")) != INVALID_ENT)
		{
			if (entity == this.index)
				continue;
			
			RF2_Object_Pedestal pedestal = RF2_Object_Pedestal(entity);
			if (pedestal.IsValid() && pedestal.Spinning)
				continue;

			if (DistBetween(this.index, entity) > this.Radius)
			{
				RF2_Object_Base(entity).Active = state;
				if (!state)
				{
					SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
					GetEntityRenderColor(entity, r, g, b, a);
					SetEntityRenderColor(entity, r, g, b, 75);
				}
				else
				{
					GetEntityRenderColor(entity, r, g, b, a);
					SetEntityRenderColor(entity, r, g, b, 255);
				}
			}
		}
	}
	
	public static void ToggleObjectsStatic(bool state)
	{
		int entity = MaxClients+1;
		while ((entity = FindEntityByClassname(entity, "rf2_object*")) != INVALID_ENT)
		{
			if (RF2_Object_Teleporter(entity).IsValid())
				continue;
			
			RF2_Object_Pedestal pedestal = RF2_Object_Pedestal(entity);
			if (pedestal.IsValid() && pedestal.Spinning)
				continue;

			RF2_Object_Base(entity).Active = state;
		}
	}
	
	public static void EventCompletion()
	{
		StunRadioWave();
		int entity = MaxClients+1;
		while ((entity = FindEntityByClassname(entity, "obj_*")) != INVALID_ENT)
		{
			if (GetEntTeam(entity) == TEAM_ENEMY)
			{
				SetEntityHealth(entity, 1);
				RF_TakeDamage(entity, 0, 0, MAX_DAMAGE, DMG_PREVENT_PHYSICS_FORCE);
			}
		}
		
		int randomItem;
		bool collector;
		char name[MAX_NAME_LENGTH], quality[32];
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerSurvivor(i, false))
				continue;
			
			TriggerAchievement(i, ACHIEVEMENT_TELEPORTER);
			collector = (!IsSingleplayer(false) && !g_bPlayerTookCollectorItem[i] && g_iLoopCount == 0 || GetRandomInt(1, 10) <= 2);
			randomItem = collector ? GetRandomCollectorItem(TF2_GetPlayerClass(i)) : GetRandomItemEx(Quality_Genuine);
			GiveItem(i, randomItem, _, true);
			GetItemName(randomItem, name, sizeof(name));
			GetQualityColorTag(GetItemQuality(randomItem), quality, sizeof(quality));
			RF2_PrintToChatAll("%t", "TeleporterItemReward", i, quality, name);
			PrintCenterText(i, "%t", "GotItemReward", name);
			if (PlayerHasItem(i, Item_CheatersLament_Recharging, true, true) && !g_bPlayerReviveActivated[i])
			{
				GiveItem(i, Item_CheatersLament, 1, true);
				GiveItem(i, Item_CheatersLament_Recharging, -1);
				RF2_PrintToChat(i, "%t", "ReviveItemCharged");
			}
			
			g_flPlayerTimeSinceLastItemPickup[i] = GetTickedTime(); // so players aren't instantly penalized for not picking up items
		}
		
		int boss = MaxClients+1;
		while ((boss = FindEntityByClassname(boss, "headless_hatman")) != INVALID_ENT)
		{
			// HHH team number is 0, set to something else so he actually takes damage and dies
			SetEntTeam(boss, 1);
			SetEntProp(boss, Prop_Data, "m_iHealth", 1);
			RF_TakeDamage(boss, 0, 0, MAX_DAMAGE, DMG_PREVENT_PHYSICS_FORCE);
		}
		
		boss = MaxClients+1;
		while ((boss = FindEntityByClassname(boss, "eyeball_boss")) != INVALID_ENT)
		{
			if (GetEntTeam(boss) != 5)
				continue;
			
			SetEntProp(boss, Prop_Data, "m_iHealth", 1);
			RF_TakeDamage(boss, 0, 0, MAX_DAMAGE, DMG_PREVENT_PHYSICS_FORCE);
		}
		
		Call_StartForward(g_fwTeleEventEnd);
		Call_Finish();
	}
}

void Teleporter_OnMapStart()
{
	AddModelToDownloadsTable(MODEL_TELEPORTER);
	AddModelToDownloadsTable(MODEL_TELEPORTER_RADIUS);
	AddMaterialToDownloadsTable("materials/rf2/objects/matteleporterclean");
	AddMaterialToDownloadsTable("materials/rf2/objects/teleporterbumpmap");
	AddMaterialToDownloadsTable("materials/rf2/objects/teleporterlightmap");
	AddMaterialToDownloadsTable("materials/rf2/objects/sphere_1");
}

static void OnCreate(RF2_Object_Teleporter teleporter)
{
	char model[PLATFORM_MAX_PATH];
	RF2_GameRules gamerules = GetRF2GameRules();
	if (gamerules.IsValid())
	{
		gamerules.GetTeleModel(model, sizeof(model));
	}
	else
	{
		model = MODEL_TELEPORTER;
	}
	
	teleporter.Bubble = CBaseAnimating(INVALID_ENT);
	teleporter.SetProp(Prop_Send, "m_nSolidType", SOLID_VPHYSICS);
	teleporter.SetModel(model);
	teleporter.HookInteract(Teleporter_OnInteract);
	teleporter.SetWorldText("Call for Medic to start the Teleporter event!");
	teleporter.TextZOffset = 70.0;
	teleporter.SetObjectName("The Teleporter");
	teleporter.SetGlowColor(150, 0, 150, 255);
}

static void OnRemove(RF2_Object_Teleporter teleporter)
{
	if (teleporter.Bubble.IsValid())
	{
		RemoveEntity(teleporter.Bubble.index);
	}
}

static Action Teleporter_OnInteract(int client, RF2_Object_Teleporter teleporter)
{
	if (g_bGracePeriod)
	{
		RF2_PrintToChat(client, "%t", "NoActivateTele");
		return Plugin_Stop;
	}
	else if (teleporter.EventState == TELE_EVENT_PREPARING || teleporter.EventState == TELE_EVENT_ACTIVE)
	{
		return Plugin_Continue;
	}
	
	RF2_Object_Teleporter.StartVote(client, IsStageCleared());
	return Plugin_Handled;
}

RF2_Object_Teleporter GetCurrentTeleporter()
{
	return RF2_Object_Teleporter(EntRefToEntIndex(g_iTeleporterEntRef));
}

public int Menu_TeleporterVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
	}
	
	return 0;
}

static void Timer_StartTeleporterEvent(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return;
	
	RF2_Object_Teleporter(entity).Start();
}

static Action Timer_TeleporterThink(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT || g_bGameOver)
		return Plugin_Stop;
	
	RF2_Object_Teleporter teleporter = RF2_Object_Teleporter(entity);
	int aliveSurvivors, aliveBosses;
	float distance;
	float pos[3], telePos[3];
	float radius = teleporter.Radius;
	teleporter.GetAbsOrigin(telePos);
	float bonus = 1.0;
	
	// calculate alive survivors first
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if (IsPlayerSurvivor(i) && !IsPlayerMinion(i))
		{
			aliveSurvivors++;
			if (PlayerHasItem(i, Item_BeaconFromBeyond))
			{
				bonus += CalcItemMod(i, Item_BeaconFromBeyond, 0);
			}
		}
		else if (g_bPlayerIsTeleporterBoss[i])
		{
			aliveBosses++;
		}
	}
	
	float chargeToSet = teleporter.Charge;
	float oldCharge = chargeToSet;
	float chargeAdd = fmax(0.1 / float(aliveSurvivors), 0.03 -(float(aliveSurvivors-1)*0.001)) * bonus;
	static char text[256];
	FormatEx(text, sizeof(text), "%.0f", oldCharge);
	teleporter.SetWorldText(text);
	
	// now let's see how many of them are actually in the radius, so we can add charge based on that
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || !IsPlayerSurvivor(i) || IsPlayerMinion(i))
			continue;
		
		if (IsPlayerSurvivor(i))
		{
			GetEntPos(i, pos);
			distance = GetVectorDistance(pos, telePos);
			if (distance <= radius)
			{
				if (chargeToSet < 100.0)
				{
					chargeToSet += chargeAdd;
				}
				
				FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "\nTeleporter Charge: %.0f percent...\nBosses Left: %i", oldCharge, aliveBosses);
			}
			else
			{
				FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "\nGet inside the Teleporter radius! (%.0f)\nBosses Left: %i", oldCharge, aliveBosses);
			}
		}
		else
		{
			FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "\nTeleporter Charge: %.0f percent...\nBosses Left: %i", oldCharge, aliveBosses);
		}
	}
	
	if (oldCharge < 100.0 && chargeToSet > 0.0 && oldCharge != chargeToSet)
	{
		teleporter.Charge = fmin(chargeToSet, 100.0);
	}
	
	// end once all teleporter bosses are dead and charge is 100%
	if (chargeToSet >= 100.0 && aliveBosses == 0)
	{
		teleporter.End();
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

static void Timer_DelayHalloweenBossSpawn(Handle timer, int entity)
{
	DispatchSpawn(entity);
	int health = 3000 + ((RF2_GetEnemyLevel()-1) * 500);
	SetEntProp(entity, Prop_Data, "m_iMaxHealth", health);
	SetEntProp(entity, Prop_Data, "m_iHealth", health);
	char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	RF2_HealthText text;
	if (strcmp2(classname, "headless_hatman"))
	{
		text = CreateHealthText(entity, 150.0, 20.0, "HORSELESS HEADLESS HORSEMANN");
		text.SetHealthColor(HEALTHCOLOR_HIGH, {255, 75, 0, 255});
	}
	else if (strcmp2(classname, "eyeball_boss"))
	{
		text = CreateHealthText(entity, 120.0, 25.0, "MONOCULUS!");
		text.SetHealthColor(HEALTHCOLOR_HIGH, {150, 0, 150, 255});
	}
}

public void OnTeleporterVoteFinish(Menu menu, int numVotes, int numClients, const int[][] clientInfo, int numItems, const int[][] itemInfo)
{
	// This is the absolute dumbest shit ever. My god. Please fix the menu API. Thanks.
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
			GetCurrentTeleporter().Prepare();
		}
	}
}

static bool g_bIsConfirmation;
public void OnNextStageVoteFinish(Menu menu, int numVotes, int numClients, const int[][] clientInfo, int numItems, const int[][] itemInfo)
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
			if (!g_bIsConfirmation && (IsInUnderworld() || AreAnyPlayersLackingItems()))
			{
				Menu vote = new Menu(Menu_TeleporterVote);
				if (IsInUnderworld())
				{
					vote.SetTitle("Are you sure?");
				}
				else
				{
					vote.SetTitle("Are you sure you want to leave? There are still players who are lacking items!");
				}
				
				vote.VoteResultCallback = OnNextStageVoteFinish;
				vote.AddItem("Yes", "Yes");
				vote.AddItem("No", "No");
				vote.ExitButton = false;
				
				int clients[MAX_SURVIVORS];
				int clientCount;
				for (int i = 1; i <= MaxClients; i++)
				{
					if (!IsClientInGame(i))
						continue;
						
					if (GetClientTeam(i) == TEAM_SURVIVOR)
					{
						clients[clientCount] = i;
						clientCount++;
						if (clientCount >= MAX_SURVIVORS)
						{
							break;
						}
					}
				}
				
				vote.DisplayVote(clients, clientCount, 12);
				g_bIsConfirmation = true;
			}
			else
			{
				ForceTeamWin(TEAM_SURVIVOR);
				g_bIsConfirmation = false;
			}
		}
		else
		{
			g_bIsConfirmation = false;
		}
	}
}

static bool g_bWasTie;
public void OnNextStageVoteFinishFinal(Menu menu, int numVotes, int numClients, const int[][] clientInfo, int numItems, const int[][] itemInfo)
{
	if (numVotes > 0)
	{
		int finalAreaVotes, loopVotes, noVotes;
		for (int i = 0; i < numItems; i++)
		{
			switch (itemInfo[i][VOTEINFO_ITEM_INDEX])
			{
				case 0: finalAreaVotes = itemInfo[i][VOTEINFO_ITEM_VOTES];
				case 1: loopVotes = itemInfo[i][VOTEINFO_ITEM_VOTES];
				case 2: noVotes = itemInfo[i][VOTEINFO_ITEM_VOTES];
			}
		}
		
		// Decide the winner
		if (noVotes > 0 && (noVotes > finalAreaVotes && noVotes > loopVotes || noVotes == finalAreaVotes && noVotes > loopVotes 
			|| noVotes == loopVotes && noVotes > finalAreaVotes || noVotes == finalAreaVotes && noVotes == loopVotes))
		{
			// No one wins
			g_bWasTie = false;
			return;
		}
		else if (finalAreaVotes > loopVotes)
		{
			g_bEnteringFinalArea = true;
			g_bWasTie = false;
			ForceTeamWin(TEAM_SURVIVOR);
		}
		else if (loopVotes > finalAreaVotes)
		{
			g_bWasTie = false;
			ForceTeamWin(TEAM_SURVIVOR);
		}
		else
		{
			// It's a tie, try again
			RF2_Object_Teleporter.StartVote(INVALID_ENT, true);
			RF2_PrintToChatAll("The voting result was a tie. Casting the vote again.");
			if (g_bWasTie)
			{
				// Another tie! Decide randomly at this point.
				g_bWasTie = false;
				if (GetRandomInt(1, 2) == 1)
				{
					g_bEnteringFinalArea = true;
				}

				ForceTeamWin(TEAM_SURVIVOR);
			}

			g_bWasTie = true;
		}
	}
}
