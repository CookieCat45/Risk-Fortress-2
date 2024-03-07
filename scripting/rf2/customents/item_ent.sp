#pragma semicolon 1
#pragma newdecls required

static CEntityFactory g_Factory;
methodmap RF2_Item < CBaseEntity
{
	public RF2_Item(int entity)
	{
		return view_as<RF2_Item>(entity);
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
		g_Factory = new CEntityFactory("rf2_item", OnCreate);
		g_Factory.DeriveFromClass("env_sprite");
		g_Factory.BeginDataMapDesc()
			.DefineIntField("m_iIndex", _, "type")
			.DefineBoolField("m_bDropped")
			.DefineEntityField("m_hItemOwner")
			.DefineEntityField("m_hSubject")
			.DefineEntityField("m_hOriginalItemOwner")
			.DefineEntityField("m_hWorldTextEnt")
		.EndDataMapDesc();
		g_Factory.Install();
	}
	
	property int Type
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iIndex");
		}
		
		public set (int value)
		{
			this.SetProp(Prop_Data, "m_iIndex", value);
		}
	}
	
	property bool Dropped
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bDropped"));
		}
		
		public set (bool value)
		{
			this.SetProp(Prop_Data, "m_bDropped", value);
		}
	}
	
	property int Owner
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hItemOwner");
		}
		
		public set (int entity)
		{
			this.SetPropEnt(Prop_Data, "m_hItemOwner", entity);
		}
	}
	
	property int Subject
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hSubject");
		}
		
		public set (int entity)
		{
			this.SetPropEnt(Prop_Data, "m_hSubject", entity);
		}
	}
	
	property int OriginalOwner
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hOriginalItemOwner");
		}
		
		public set (int entity)
		{
			this.SetPropEnt(Prop_Data, "m_hOriginalItemOwner", entity);
		}
	}

	property int WorldText
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hWorldTextEnt");
		}
		
		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hWorldTextEnt", value);
		}
	}
	
	public void CreateWorldText()
	{
		this.WorldText = CreateEntityByName("point_worldtext");
		CBaseEntity text = CBaseEntity(this.WorldText);
		char worldText[256];
		FormatEx(worldText, sizeof(worldText), "%s\nCall for Medic to pick up", g_szItemName[this.Type]);
		text.KeyValue("message", worldText);
		text.KeyValueFloat("textsize", 6.0);
		text.KeyValue("orientation", "1");
		switch (g_iItemQuality[this.Type])
		{
			case Quality_Normal:		SetVariantColor({255, 255, 255, 160});
			case Quality_Genuine:		SetVariantColor({125, 255, 125, 160});
			case Quality_Unusual: 		SetVariantColor({200, 125, 255, 160});
			case Quality_Strange:		SetVariantColor({200, 150, 0, 160});
			case Quality_Collectors:	SetVariantColor({255, 100, 100, 160});
			case Quality_Haunted, 
				Quality_HauntedStrange:	SetVariantColor({125, 255, 255, 160});
		}
		
		text.AcceptInput("SetColor");
		float pos[3];
		this.GetAbsOrigin(pos);
		pos[2] += 35.0;
		text.Teleport(pos);
		text.Spawn();
		ParentEntity(text.index, this.index);
	}
}

static void OnCreate(RF2_Item item)
{
	item.Owner = INVALID_ENT;
	item.Subject = INVALID_ENT;
	item.WorldText = INVALID_ENT;
	item.KeyValue("rendermode", "9");
	SDKHook(item.index, SDKHook_Spawn, OnSpawn); // should wait for item index to be set
}

static void OnSpawn(int entity)
{
	RF2_Item item = RF2_Item(entity);
	item.KeyValue("model", g_szItemSprite[item.Type]);
	item.KeyValueFloat("scale", g_flItemSpriteScale[item.Type]);
	item.CreateWorldText();
	CreateTimer(0.5, Timer_WorldText, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

RF2_Item SpawnItem(int type, const float pos[3], int spawner=INVALID_ENT, float ownTime=0.0)
{
	RF2_Item item = RF2_Item(CreateEntityByName("rf2_item"));
	item.Type = type;
	item.OriginalOwner = spawner;
	item.Teleport(pos);
	item.Spawn();
	
	if (IsValidClient(spawner)) // We spawned this item, so we own it unless we don't pick it up, assuming we don't want it.
	{
		item.Owner = spawner;
		if (ownTime > 0.0)
		{
			CreateTimer(ownTime, Timer_ClearItemOwner, EntIndexToEntRef(item.index), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	int quality = GetItemQuality(type);
	switch (quality)
	{
		case Quality_Genuine:		item.SetRenderColor(125, 255, 125);
		case Quality_Unusual: 		item.SetRenderColor(200, 125, 255);
		case Quality_Strange:		item.SetRenderColor(200, 150, 0);
		case Quality_Collectors:	item.SetRenderColor(255, 100, 100);
		case Quality_Haunted, 
			Quality_HauntedStrange:	item.SetRenderColor(125, 255, 255);
	}
	
	if (quality == Quality_Unusual && g_iItemSpriteUnusualEffect[type] >= 0)
	{
		float effectPos[3];
		CopyVectors(pos, effectPos);
		effectPos[2] += 25.0;
		TE_TFParticle(g_szUnusualEffectName[g_iItemSpriteUnusualEffect[type]], effectPos, item.index, PATTACH_ABSORIGIN);
	}
	
	return item;
}

static Action Timer_WorldText(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return Plugin_Stop;
	
	RF2_Item item = RF2_Item(entity);
	float pos[3];
	item.GetAbsOrigin(pos);
	int nearestPlayer = GetNearestPlayer(pos, _, 275.0, TEAM_SURVIVOR, _, true);
	if (nearestPlayer != INVALID_ENT)
	{
		if (!IsValidEntity2(item.WorldText))
		{
			item.CreateWorldText();
		}
	}
	else if (IsValidEntity2(item.WorldText))
	{
		RemoveEntity2(item.WorldText);
	}
	
	return Plugin_Continue;
}

// Subject is who we're dropping the item for, or INVALID_ENT if we don't care
RF2_Item DropItem(int client, int type, float pos[3], int subject=INVALID_ENT, float ownTime=0.0)
{
	if (GetPlayerItemCount(client, type) <= 0 && !IsEquipmentItem(type))
		return view_as<RF2_Item>(INVALID_ENT);
	
	if (IsEquipmentItem(type) && GetPlayerEquipmentItem(client) != type)
		return view_as<RF2_Item>(INVALID_ENT);
	
	RF2_Item item = SpawnItem(type, pos, client);
	item.Dropped = true;
	
	if (subject > 0)
	{
		// Only the dropper or the one we dropped the item for can pick this up.
		item.Subject = subject;
		if (subject != client)
		{
			PrintCenterText(subject, "%t", "DroppedItemForYou", client, g_szItemName[type]);
		}
	}
	
	if (ownTime > 0.0) // If we own this item but the owner/subject takes too long to pick it up, it's free for taking
	{
		CreateTimer(ownTime, Timer_ClearItemOwner, EntIndexToEntRef(item.index), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		item.Owner = INVALID_ENT;
	}
	
	if (IsEquipmentItem(type))
	{
		g_iPlayerEquipmentItem[client] = Item_Null;
	}
	else
	{
		g_iPlayerItem[client][type]--;
	}
	
	UpdatePlayerItem(client, type);
	if (IsPlayerSurvivor(client) && GetItemQuality(type) != Quality_Strange)
	{
		int index = RF2_GetSurvivorIndex(client);
		if (g_iItemsTaken[index] > 0)
			g_iItemsTaken[index]--;
	}
	
	return item;
}

bool PickupItem(int client)
{
	if (g_bItemPickupCooldown[client])
		return false;
	
	const float range = 90.0;
	float eyePos[3], endPos[3], eyeAng[3], direction[3];
	GetClientEyePosition(client, eyePos);
	CopyVectors(eyePos, endPos);
	GetClientEyeAngles(client, eyeAng);
	GetAngleVectors(eyeAng, direction, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(direction, direction);
	endPos[0] += direction[0] * range;
	endPos[1] += direction[1] * range;
	endPos[2] += direction[2] * range;
	TR_TraceRayFilter(eyePos, endPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceFilter_DontHitSelf, client);
	TR_GetEndPosition(endPos);
	
	RF2_Item item = RF2_Item(GetNearestEntity(endPos, "rf2_item"));
	if (!item.IsValid())
	{
		return false;
	}
	
	float pos[3];
	item.GetAbsOrigin(pos);
	if (GetVectorDistance(pos, endPos, true) <= sq(range))
	{
		bool itemShare = IsItemSharingEnabled();
		int survivorIndex = RF2_GetSurvivorIndex(client);
		int type = item.Type;
		int owner = item.Owner;
		int subject = item.Subject;
		int originalOwner = item.OriginalOwner;
		int quality = GetItemQuality(item.Type);
		bool dropped = item.Dropped;
		
		// hotfix
		if (GetPlayersOnTeam(TEAM_SURVIVOR, true, true) <= 1)
		{
			g_iItemLimit[survivorIndex] = 0;
		}
		
		// Strange items do not count towards the limit.
		if (itemShare && g_iItemLimit[survivorIndex] > 0 && !IsEquipmentItem(type) && subject != client
		&& ((owner == client || originalOwner == client) || !IsValidClient(owner) 
			|| !IsPlayerSurvivor(owner)) && g_iItemsTaken[survivorIndex] >= g_iItemLimit[survivorIndex])
		{
			EmitSoundToClient(client, SND_NOPE);
			PrintCenterText(client, "%t", "ItemShareLimit", g_iItemLimit[survivorIndex]);
			return true;
		}
		
		if (IsValidClient(owner) && IsPlayerSurvivor(owner) 
			&& client != owner && client != subject)
		{
			EmitSoundToClient(client, SND_NOPE);
			PrintCenterText(client, "%t", "NotForYou");
			return true;
		}

		if (quality == Quality_Collectors)
		{
			g_bPlayerTookCollectorItem[client] = true;
		}
		
		GiveItem(client, type, 1, true);
		RemoveEntity2(item.index);
		ShowItemDesc(client, type);
		char qualityTag[32], itemName[128], qualityName[32];
		GetItemName(type, itemName, sizeof(itemName));
		GetQualityColorTag(quality, qualityTag, sizeof(qualityTag));
		GetQualityName(quality, qualityName, sizeof(qualityName));
		
		if (type == Item_HorrificHeadsplitter)
		{
			TriggerAchievement(client, ACHIEVEMENT_HEADSPLITTER);
		}
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && !GetCookieBool(client, g_coDisableItemMessages))
			{
				if (IsEquipmentItem(type))
				{
					RF2_PrintToChat(i, "%t", "PickupItemStrange", client, qualityTag, itemName);
				}
				else
				{
					RF2_PrintToChat(i, "%t", "PickupItem", client, qualityTag, itemName, GetPlayerItemCount(client, type));
				}
			}
		}
		
		EmitSoundToAll(SND_ITEM_PICKUP, client);
		if (!dropped || owner == client || originalOwner == client)
		{
			if (!dropped)
				g_iTotalItemsFound++;
			
			if (!IsEquipmentItem(type))
			{
				g_iItemsTaken[survivorIndex]++;
				
				// Notify our player that they've reached their limit.
				if (itemShare && g_iItemLimit[survivorIndex] > 0 && g_iItemsTaken[survivorIndex] >= g_iItemLimit[survivorIndex])
				{
					PrintCenterText(client, "%t", "ItemShareLimit", g_iItemLimit[survivorIndex]);
				}
			}
		}
		
		if (g_bPlayerViewingItemMenu[client])
		{
			ShowItemMenu(client);
		}
		
		if (!GetCookieBool(client, g_coTutorialItemPickup))
		{
			PrintKeyHintText(client, "%t", "ItemPickupTutorial2");
			SetCookieBool(client, g_coTutorialItemPickup, true);
		}
		
		g_bItemPickupCooldown[client] = true;
		CreateTimer(0.2, Timer_ItemPickupCooldown, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		return true;
	}
	
	return false;
}

public Action Timer_ItemPickupCooldown(Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0)
		return Plugin_Continue;

	g_bItemPickupCooldown[client] = false;
	return Plugin_Continue;
}

public Action Timer_ClearItemOwner(Handle timer, int entity)
{
	RF2_Item item = RF2_Item(EntRefToEntIndex(entity));
	if (!item.IsValid())
		return Plugin_Continue;
	
	item.Owner = INVALID_ENT;
	item.Subject = INVALID_ENT;	
	return Plugin_Continue;
}
