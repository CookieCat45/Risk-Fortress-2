#pragma newdecls required
#pragma semicolon 1

#define MVM_CLASS_FLAG_NONE				0
#define MVM_CLASS_FLAG_NORMAL			(1<<0)
#define MVM_CLASS_FLAG_SUPPORT			(1<<1)
#define MVM_CLASS_FLAG_MISSION			(1<<2)
#define MVM_CLASS_FLAG_MINIBOSS			(1<<3)
#define MVM_CLASS_FLAG_ALWAYSCRIT		(1<<4)
#define MVM_CLASS_FLAG_SUPPORT_LIMITED	(1<<5)

/**
Experimental Feature: MvM Wavebar display during waiting for players (rf2_enable_mvm_wavebar)
So this has a plethora of issues, some of which are likely not fixable:

- The MvM scoreboard is forced to show.
- Waiting for players completely breaks, the round cannot be started and the timer is hidden.
- All players are forced to RED, and players will not be able to join RED if bots take up all of the slots.
- The number in the wavebar cannot be hidden without adding MVM_CLASS_FLAG_SUPPORT, which causes other problems.

*/

// Taken from Zombie Riot
void MvMHUD_Enable()
{
    //find populator
    int populator = FindEntityByClassname(-1, "info_populator");
    if (populator == INVALID_ENT || populator != g_iMvMPopulator)
    {
        if(!IsValidEntity(populator))
            populator = EntIndexToEntRef(CreateEntityByName("info_populator"));
        
        g_iMvMPopulator = populator;
        
        // EFL_NO_THINK_FUNCTION (1 << 22)
        SetEntityFlags(g_iMvMPopulator, GetEntityFlags(g_iMvMPopulator)|4194304);
    }

    //GameRules_SetProp("m_iRoundState", RoundState_BetweenRounds);
    GameRules_SetProp("m_bPlayingMannVsMachine", true);
    GameRules_SetProp("m_bPlayingSpecialDeliveryMode", true);
}

void MvMHUD_UpdateStats()
{
    if (!IsValidEntity2(g_iMvMPopulator))
    {
        MvMHUD_Enable();
    }
    
    int objective = GetObjectiveResource();
    //SetEntProp(objective, Prop_Send, "m_nMvMWorldMoney", Rogue_GetChaosLevel() > 2 ? (GetURandomInt() % 99999) : RoundToNearest(cashLeft));
    SetEntProp(objective, Prop_Send, "m_nMannVsMachineWaveEnemyCount", g_iEnemyCount);
    SetEntProp(objective, Prop_Send, "m_nMannVsMachineWaveCount", g_iStagesCompleted+1);
    SetEntProp(objective, Prop_Send, "m_nMannVsMachineMaxWaveCount", 0);
    int offset = GetEntSendPropOffs(objective, "m_iszMannVsMachineWaveClassNames", true);
    int size1 = GetEntPropArraySize(objective, Prop_Send, "m_nMannVsMachineWaveClassCounts");
    int size2 = GetEntPropArraySize(objective, Prop_Send, "m_nMannVsMachineWaveClassCounts2");
    
    char icon[128];
    for (int i = 0; i < g_iEnemyCount; i++)
    {
        Enemy enemy = EnemyByIndex(i);
        if (enemy == NULL_ENEMY)
            continue;
        
        if (i < size1)
        {
            SetEntProp(objective, Prop_Send, "m_bMannVsMachineWaveClassActive", true, _, i);
            SetEntProp(objective, Prop_Send, "m_nMannVsMachineWaveClassCounts", 1, _, i);
            
            int flags = MVM_CLASS_FLAG_NORMAL;
            if (enemy.IsBoss)
            {
                flags |= MVM_CLASS_FLAG_MINIBOSS;
            }
            
            if (enemy.AlwaysCrit)
            {
                flags |= MVM_CLASS_FLAG_ALWAYSCRIT;
            }
            
            SetEntProp(objective, Prop_Send, "m_nMannVsMachineWaveClassFlags", flags, _, i);
            enemy.GetIcon(icon, sizeof(icon));
            SetEntDataAllocString(objective, offset + (i * 4), icon);
        }
        else if (i-size1 < size2)
        {
            SetEntProp(objective, Prop_Send, "m_bMannVsMachineWaveClassActive2", true, _, i);
            SetEntProp(objective, Prop_Send, "m_nMannVsMachineWaveClassCounts2", 1, _, i);
            
            int flags = MVM_CLASS_FLAG_NORMAL;
            if (enemy.IsBoss)
            {
                flags |= MVM_CLASS_FLAG_MINIBOSS;
            }
            
            if (enemy.AlwaysCrit)
            {
                flags |= MVM_CLASS_FLAG_ALWAYSCRIT;
            }
            
            SetEntProp(objective, Prop_Send, "m_nMannVsMachineWaveClassFlags2", flags, _, i);
            enemy.GetIcon(icon, sizeof(icon));
            SetEntDataAllocString(objective, offset + (i * 4), icon);
        }
        else
        {
            break;
        }
    }
}

void MVMHud_Disable()
{
    GameRules_SetProp("m_bPlayingMannVsMachine", false);
    GameRules_SetProp("m_bPlayingSpecialDeliveryMode", false);
}

bool MvMHUD_IsEnabled()
{
    return asBool(GameRules_GetProp("m_bPlayingSpecialDeliveryMode"));
}

static void SetEntDataAllocString(int entity, int offset, const char[] string)
{
	Address address = AllocPooledString(string);
	if (address != view_as<Address>(GetEntData(entity, offset, 4)))
    {
        SetEntData(entity, offset, address, 4, true);
    }
}

/**
 * Inserts a string into the game's string pool.  This uses the same implementation that is in
 * SourceMod's core:
 * 
 * https://github.com/alliedmodders/sourcemod/blob/b14c18ee64fc822dd6b0f5baea87226d59707d5a/core/HalfLife2.cpp#L1415-L1423
 */
static Address AllocPooledString(const char[] value) 
{
	if (!g_hAllocPooledStringCache)
    {
        g_hAllocPooledStringCache = new StringMap();
    }
	
	Address addr;
	if (g_hAllocPooledStringCache.GetValue(value, addr)) 
    {
		return addr;
	}
	
	int ent = FindEntityByClassname(-1, "worldspawn");
	if (ent != 0) 
    {
		return Address_Null;
	}
    
	int offset = FindDataMapInfo(ent, "m_iName");
	if (offset <= 0) 
    {
		return Address_Null;
	}
    
	Address orig = view_as<Address>(GetEntData(ent, offset));
	DispatchKeyValue(ent, "targetname", value);
	addr = view_as<Address>(GetEntData(ent, offset));
	SetEntData(ent, offset, orig);
	g_hAllocPooledStringCache.SetValue(value, addr);
	return addr;
}
