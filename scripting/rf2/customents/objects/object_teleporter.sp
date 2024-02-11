#pragma semicolon 1
#pragma newdecls required

#define MODEL_TELEPORTER "models/rf2/objects/teleporter.mdl"
#define MODEL_TELEPORTER_RADIUS "models/rf2/objects/teleporter_radius.mdl"

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
	
	public static void StartVote(int client, bool nextStageVote=false)
	{
		if (IsVoteInProgress())
		{
			RF2_PrintToChat(client, "%t", "VoteInProgress");
			return;
		}
		
		int clients[MAX_SURVIVORS];
		int clientCount;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
				
			if (IsPlayerSurvivor(i))
			{
				clients[clientCount] = i;
				clientCount++;
				if (clientCount >= MAX_SURVIVORS)
				{
					break;
				}
			}
		}
		
		Menu vote;
		if (nextStageVote)
		{
			vote = new Menu(Menu_NextStageVote);
			vote.SetTitle("Depart now? (%N)", client);
		}
		else
		{
			vote = new Menu(Menu_TeleporterVote);
			vote.SetTitle("Start the Teleporter event? (%N)", client);
		}
		
		vote.AddItem("Yes", "Yes");
		vote.AddItem("No", "No");
		vote.ExitButton = false;
		vote.DisplayVote(clients, clientCount, 12);
	}
	
	public void Prepare()
	{
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
		int oldFog[MAXTF2PLAYERS] = {-1, ...};
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;
			
			oldFog[i] = GetEntPropEnt(i, Prop_Data, "m_hCtrl");
			SetEntPropEnt(i, Prop_Data, "m_hCtrl", fog);
			
			DataPack pack;
			CreateDataTimer(time, Timer_RestorePlayerFog, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(GetClientUserId(i));
			pack.WriteCell(EntIndexToEntRef(oldFog[i]));
		}
		
		CreateTimer(time, Timer_KillFog, EntIndexToEntRef(fog), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	public void Start()
	{
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
			if (!IsClientInGame(i) || !IsPlayerAlive(i))
			{
				continue;
			}
				
			if (PlayerHasItem(i, Item_HorsemannHead))
			{
				hhhSpawnCount += GetPlayerItemCount(i, Item_HorsemannHead);
				if (hhhSpawnCount > bossSpawnLimit)
					hhhSpawnCount = bossSpawnLimit;
			}
			
			if (PlayerHasItem(i, Item_Monoculus))
			{
				eyeSpawnCount += GetPlayerItemCount(i, Item_Monoculus);
				if (eyeSpawnCount > bossSpawnLimit)
					eyeSpawnCount = bossSpawnLimit;
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
					if (!IsClientInGame(i) || IsFakeClient(i) || !IsPlayerSurvivor(i))
						continue;

					TriggerAchievement(i, ACHIEVEMENT_HALLOWEENBOSSES);
				}
			}
			
			while (hhhSpawnCount > 0 || eyeSpawnCount > 0)
			{
				area = GetSpawnPoint(pos, resultPos, 0.0, this.Radius, 4, true, mins, maxs, MASK_NPCSOLID, zOffset);
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
						SetEntProp(boss, Prop_Data, "m_iTeamNum", 5);
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
		this.EventState = TELE_EVENT_COMPLETE;
		this.Effects = EF_ITEM_BLINK;
		this.TextSize = 6.0;
		this.SetWorldText("Press [E] to go to the next stage!");
		RemoveEntity2(this.Bubble.index);
		EmitSoundToAll(SND_TELEPORTER_CHARGED);
		StopMusicTrackAll();
		
		bool aliveEnemies;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_ENEMY)
			{
				TF2_StunPlayer(i, 20.0, _, TF_STUNFLAG_BONKSTUCK);
				aliveEnemies = true;
			}
		}
		
		if (aliveEnemies)
		{
			EmitSoundToAll(SND_ENEMY_STUN);
		}
		
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "obj_*")) != -1)
		{
			if (GetEntProp(entity, Prop_Data, "m_iTeamNum") == TEAM_ENEMY)
			{
				SDKHooks_TakeDamage2(entity, 0, 0, 9999999.0, DMG_PREVENT_PHYSICS_FORCE);
			}
		}
		
		int randomItem;
		char name[MAX_NAME_LENGTH], quality[32];
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerSurvivor(i))
				continue;
			
			randomItem = GetRandomInt(1, 10) > 2 ? GetRandomItemEx(Quality_Genuine) : GetRandomCollectorItem(TF2_GetPlayerClass(i));
			GiveItem(i, randomItem, _, true);
			GetItemName(randomItem, name, sizeof(name));
			GetQualityColorTag(GetItemQuality(randomItem), quality, sizeof(quality));
			RF2_PrintToChatAll("%t", "TeleporterItemReward", i, quality, name);
			PrintHintText(i, "%t", "GotItemReward", name);
			TriggerAchievement(i, ACHIEVEMENT_TELEPORTER);
		}
		
		RF2_PrintToChatAll("%t", "TeleporterComplete");
		Call_StartForward(g_fwTeleEventEnd);
		Call_Finish();
		
		RF2_GameRules gamerules = GetRF2GameRules();
		if (gamerules.IsValid())
		{
			gamerules.FireOutput("OnTeleporterEventComplete");
		}
		
		int boss = MaxClients+1;
		while ((boss = FindEntityByClassname(boss, "headless_hatman")) != -1)
		{
			// HHH team number is 0, set to something else so he actually takes damage and dies
			SetEntProp(boss, Prop_Data, "m_iTeamNum", 1);
			SetEntProp(boss, Prop_Data, "m_iHealth", 1);
			SDKHooks_TakeDamage2(boss, 0, 0, 32000.0, DMG_PREVENT_PHYSICS_FORCE);
		}
		
		boss = MaxClients+1;
		while ((boss = FindEntityByClassname(boss, "eyeball_boss")) != -1)
		{
			if (GetEntProp(boss, Prop_Data, "m_iTeamNum") != 5)
				continue;
			
			SetEntProp(boss, Prop_Data, "m_iHealth", 1);
			SDKHooks_TakeDamage2(boss, 0, 0, 32000.0, DMG_PREVENT_PHYSICS_FORCE);
		}
	}
}

void Teleporter_OnMapStart()
{
	PrecacheModel2(MODEL_TELEPORTER, true);
	PrecacheModel2(MODEL_TELEPORTER_RADIUS, true);
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
	
	teleporter.Bubble = CBaseAnimating(-1);
	teleporter.SetProp(Prop_Send, "m_nSolidType", SOLID_VPHYSICS);
	teleporter.SetModel(model);
	teleporter.HookInteract(Teleporter_OnInteract);
	teleporter.SetWorldText("Press [E] to start the Teleporter event!");
	teleporter.TextZOffset = 70.0;
}

static void OnRemove(RF2_Object_Teleporter teleporter)
{
	if (teleporter.Bubble.IsValid())
		RemoveEntity2(teleporter.Bubble.index);
}

static Action Teleporter_OnInteract(int client, RF2_Object_Teleporter teleporter)
{
	RF2_GameRules gamerules = GetRF2GameRules();
	if (g_bGracePeriod || gamerules.IsValid() && !gamerules.AllowTeleporterActivation)
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
		case MenuAction_VoteEnd:
		{
			if (param1 == 0)
			{
				GetCurrentTeleporter().Prepare();
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public int Menu_NextStageVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_VoteEnd:
		{
			if (param1 == 0)
				ForceTeamWin(TEAM_SURVIVOR);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public Action Timer_StartTeleporterEvent(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE)
		return Plugin_Stop;
	
	RF2_Object_Teleporter(entity).Start();
	return Plugin_Continue;
}

public Action Timer_TeleporterThink(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE)
		return Plugin_Stop;
	
	RF2_Object_Teleporter teleporter = RF2_Object_Teleporter(entity);
	int aliveSurvivors, aliveBosses;
	float distance;
	float pos[3], telePos[3];
	float radius = teleporter.Radius;
	teleporter.GetAbsOrigin(telePos);
	
	// calculate alive survivors first
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if (IsPlayerSurvivor(i))
		{
			aliveSurvivors++;
		}
		else if (g_bPlayerIsTeleporterBoss[i])
		{
			aliveBosses++;
		}
	}
	
	float chargeToSet = teleporter.Charge;
	float oldCharge = chargeToSet;
	
	// now let's see how many of them are actually in the radius, so we can add charge based on that
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || !IsPlayerSurvivor(i))
			continue;
		
		if (IsPlayerSurvivor(i))
		{
			GetEntPos(i, pos);
			distance = GetVectorDistance(pos, telePos);
			
			if (distance <= radius)
			{
				if (chargeToSet < 100.0)
				{
					chargeToSet += 0.1 / aliveSurvivors;
				}
				
				FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "Teleporter Charge: %.0f percent...\nBosses Left: %i", oldCharge, aliveBosses);
			}
			else
			{
				FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "Get inside the Teleporter radius! (%.0f)\nBosses Left: %i", oldCharge, aliveBosses);
			}
		}
		else
		{
			FormatEx(g_szObjectiveHud[i], sizeof(g_szObjectiveHud[]), "Teleporter Charge: %.0f percent...\nBosses Left: %i", oldCharge, aliveBosses);
		}
		
		static char text[256];
		FormatEx(text, sizeof(text), "%.0f", oldCharge);
		teleporter.SetWorldText(text);
	}
	
	if (oldCharge < 100.0 && chargeToSet > 0.0 && oldCharge != chargeToSet)
	{
		teleporter.Charge = chargeToSet;
	}
	
	// end once all teleporter bosses are dead and charge is 100%
	if (chargeToSet >= 100.0 && aliveBosses == 0)
	{
		teleporter.End();
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action Timer_DelayHalloweenBossSpawn(Handle timer, int entity)
{
	DispatchSpawn(entity);
	int health = 3000 + (RF2_GetEnemyLevel() * 400);
	SetEntProp(entity, Prop_Data, "m_iMaxHealth", health);
	SetEntProp(entity, Prop_Data, "m_iHealth", health);
	return Plugin_Continue;
}
