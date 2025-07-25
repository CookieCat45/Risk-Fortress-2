#pragma semicolon 1
#pragma newdecls required

#define SND_BOSS_SUMMON "ui/halloween_boss_summoned.wav"
#define SND_BOSS_RUMBLE "ui/halloween_boss_summon_rumble.wav"
#define SND_BOSS_DEFEATED "ui/halloween_boss_defeated.wav"
#define MODEL_GRAVESTONE "models/props_manor/gravestone_03.mdl"
#define KING_BASE_HEALTH 4000.0
#define MINION_BASE_HEALTH 200.0
static CEntityFactory g_Factory;

methodmap RF2_Object_Gravestone < RF2_Object_Base
{
	public RF2_Object_Gravestone(int entity)
	{
		return view_as<RF2_Object_Gravestone>(entity);
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
		g_Factory = new CEntityFactory("rf2_object_gravestone", OnCreate);
		g_Factory.DeriveFromFactory(RF2_Object_Base.GetFactory());
		g_Factory.Install();
		HookMapStart(Gravestone_OnMapStart);
	}
	
	public int SummonSkeletonKing()
	{
		float gravePos[3], pos[3];
		this.GetAbsOrigin(gravePos);
		float mins[3] = PLAYER_MINS;
		float maxs[3] = PLAYER_MAXS;
		ScaleVector(mins, 2.0);
		ScaleVector(maxs, 2.0);
		CNavArea area = GetSpawnPoint(gravePos, pos, 500.0, 3000.0, TEAM_SURVIVOR, true, mins, maxs, MASK_NPCSOLID, 50.0);
		if (area)
		{
			int king = SDK_SpawnSkeleton(pos, 1);
			int health = RoundToFloor(KING_BASE_HEALTH + ((RF2_GetEnemyLevel()-1)*400));
			SetEntProp(king, Prop_Data, "m_iMaxHealth", health);
			SetEntProp(king, Prop_Data, "m_iHealth", health);
			ToggleGlow(king, true, {0, 200, 50, 255});
			RF2_HealthText text = CreateHealthText(king, 180.0, 25.0, "SKELETON KING");
			text.SetHealthColor(HEALTHCOLOR_HIGH, {0, 150, 0, 255});
			HookSingleEntityOutput(king, "OnDeath", Output_OnSkeletonKingDeath, true);
			UTIL_ScreenShake(gravePos, 10.0, 20.0, 5.0, 99999.0, SHAKE_START, true);
			
			// Spawn smaller skeletons too
			int skeletonCount = imin(2+(g_iSubDifficulty*2), 15);
			int skeleton;
			health = RoundToFloor(MINION_BASE_HEALTH * GetEnemyHealthMult());
			float minionPos[3];
			for (int i = 1; i <= skeletonCount; i++)
			{
				int attempts;
				while (attempts < 5)
				{
					if (GetSpawnPoint(pos, minionPos, 350.0, 3500.0, TEAM_SURVIVOR, _, _, _, MASK_NPCSOLID_BRUSHONLY, 35.0))
					{
						skeleton = CreateEntityByName("tf_zombie");
						SetEntTeam(skeleton, 5);
						TeleportEntity(skeleton, pos);
						DispatchSpawn(skeleton);
						SetEntProp(skeleton, Prop_Data, "m_iMaxHealth", health);
						SetEntProp(skeleton, Prop_Data, "m_iHealth", health);
						break;
					}
					
					attempts++;
				}
			}
			
			return king;
		}
		
		return INVALID_ENT;
	}
}

void Gravestone_OnMapStart()
{
	PrecacheModel2(MODEL_GRAVESTONE, true);
	PrecacheSound2(SND_BOSS_SUMMON, true);
	PrecacheSound2(SND_BOSS_RUMBLE, true);
	PrecacheSound2(SND_BOSS_DEFEATED, true);
}

static void OnCreate(RF2_Object_Gravestone grave)
{
	grave.SetModel(MODEL_GRAVESTONE);
	grave.SetGlowColor(0, 255, 255, 255);
	grave.HookInteract(Gravestone_OnInteract);
	if (grave.Cost <= 0.0)
	{
		grave.Cost = 350.0 * RF2_Object_Base.GetCostMultiplier();
	}
	
	char text[256];
	FormatEx(text, sizeof(text), "($%.0f) Summon the Skeleton King (Call for Medic)", grave.Cost);
	grave.SetWorldText(text);
	grave.TextZOffset = 110.0;
	grave.TextSize = 12.0;
	grave.SetTextColor(75, 200, 200, 255);
	grave.SetObjectName("Gravestone");
}

static Action Gravestone_OnInteract(int client, RF2_Object_Gravestone grave)
{
	if (GetPlayerCash(client) >= grave.Cost)
	{
		AddPlayerCash(client, -grave.Cost);
		float pos[3];
		grave.WorldSpaceCenter(pos);
		TE_TFParticle("ghost_appearation", pos);
		EmitSoundToAll(SND_DROP_HAUNTED, grave.index);
		EmitSoundToAll(SND_BOSS_SUMMON);
		EmitSoundToAll(SND_BOSS_RUMBLE);
		EmitGameSoundToAll("Halloween.skeleton_laugh_giant");
		PrintCenterTextAll("%t", "SkeletonKingSpawn");
		if (grave.SummonSkeletonKing() == INVALID_ENT)
		{
			RequestFrame(RF_GraveSpawnRetry, EntIndexToEntRef(grave.index));
			grave.Active = false;
			grave.SetRenderMode(RENDER_NONE);
			grave.SetProp(Prop_Send, "m_nSolidType", SOLID_NONE);
			SetEntityCollisionGroup(grave.index, COLLISION_GROUP_DEBRIS);
		}
		else
		{
			RemoveEntity(grave.index);
		}
	}
	else
	{
		EmitSoundToClient(client, SND_NOPE);
		PrintCenterText(client, "%t", "NotEnoughMoney", grave.Cost, GetPlayerCash(client));
	}
	
	return Plugin_Handled;
}

public void RF_GraveSpawnRetry(int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return;
	
	RF2_Object_Gravestone grave = RF2_Object_Gravestone(entity);
	if (grave.SummonSkeletonKing() == INVALID_ENT)
	{
		RequestFrame(RF_GraveSpawnRetry, EntIndexToEntRef(grave.index));
	}
	else
	{
		RemoveEntity(grave.index);
	}
}

public void Output_OnSkeletonKingDeath(const char[] output, int caller, int activator, float delay)
{
	PrintCenterTextAll("%t", "SkeletonKingDeath");
	EmitSoundToAll(SND_BOSS_DEFEATED);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerSurvivor(i))
		{
			GiveItem(i, Item_HauntedKey, 1, true);
			PrintCenterText(i, "%t", "GargoyleKeyAward");
		}
	}
}
