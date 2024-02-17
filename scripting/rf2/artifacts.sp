#if defined _RF2_artifacts_included
 #endinput
#endif
#define _RF2_artifacts_included

#pragma semicolon 1
#pragma newdecls required

static float g_flArtifactRollTime;
static int g_iOldDifficulty;

enum
{
    REDArtifact_Fortune, // Enemies may drop random items on death
    REDArtifact_Patience, // Slows down the difficulty timer
    REDArtifact_Efficiency, // Strange items have massively reduced cooldowns
    REDArtifact_Restoration, // All healing including health regen is doubled
    REDArtifact_Command, // Survivors can choose their items on pickup
    REDArtifact_Luck, // Unusual drop rate increased significantly
    
    REDArtifact_Max,
};

enum
{
    BLUArtifact_Haste = REDArtifact_Max, // Accelerates the difficulty timer
    BLUArtifact_Swarm, // Accelerates the spawn rate of enemies
    BLUArtifact_Envy, // Enemies may spawn with random items
    BLUArtifact_Silence, // Enemies may spawn with an invisibility buff
    BLUArtifact_Power, // Enemies have increased fire rate and reload speed
    BLUArtifact_Wrath, // Difficulty is forced to Titanium for the duration of the level
    
    BLUArtifact_Max,
};

stock void RollArtifacts()
{
    g_flArtifactRollTime = 0.0;
    CreateTimer(0.1, Timer_ArtifactRoll, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ArtifactRoll(Handle timer)
{
    EmitSoundToAllEx(SND_ARTIFACT_ROLL);
    g_flArtifactRollTime += 0.1;
    static char redName[64], blueName[64], redDesc[128], blueDesc[128];
    int redArtifact = GetRandomArtifact(TEAM_SURVIVOR);
    int blueArtifact = GetRandomArtifact(TEAM_ENEMY);
    GetArtifactDisplayName(redArtifact, redName, sizeof(redName));
    GetArtifactDisplayName(blueArtifact, blueName, sizeof(blueName));
    GetArtifactDescription(redArtifact, redDesc, sizeof(redDesc));
    GetArtifactDescription(blueArtifact, blueDesc, sizeof(blueDesc));
    PrintCenterTextAll("%s\n%s\n\n%s\n%s", redName, redDesc, blueName, blueDesc);
    
    if (g_flArtifactRollTime >= 10.0)
    {
        EmitSoundToAllEx(SND_ARTIFACT_SELECT);
        SetArtifactEnabled(redArtifact, true);
        SetArtifactEnabled(blueArtifact, true);
        g_flArtifactRollTime = 0.0;
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}

int GetRandomArtifact(int team=-1)
{
    int start, end;
    switch (team)
    {
        case TEAM_SURVIVOR:
        {
            start = 0;
            end = REDArtifact_Max;
        }
        
        case TEAM_ENEMY:
        {
            start = REDArtifact_Max;
            end = BLUArtifact_Max;
        }

        default:
        {
            start = 0;
            end = BLUArtifact_Max;
        }
    }
    
    ArrayList artifacts = new ArrayList();
    for (int i = start; i < end; i++)
    {
        if (i == BLUArtifact_Wrath && RF2_GetDifficulty() == DIFFICULTY_TITANIUM)
            continue;
        
        if (IsArtifactActive(i))
            continue;
        
        artifacts.Push(i);
    }
    
    int result = artifacts.Get(GetRandomInt(0, artifacts.Length-1));
    delete artifacts;
    return result;
}

void SetArtifactEnabled(int artifact, bool state)
{
    int index = g_hActiveArtifacts.FindValue(artifact);
    if (state)
    {
        if (index == -1)
        {
            g_hActiveArtifacts.Push(artifact);
            switch (artifact)
            {
                case BLUArtifact_Wrath:
                {
                    g_iOldDifficulty = RF2_GetDifficulty();
                    g_iDifficultyLevel = DIFFICULTY_TITANIUM;
                }
            }
        }
    }
    else if (index >= 0)
    {
        g_hActiveArtifacts.Erase(index);
        switch (artifact)
        {
            case BLUArtifact_Wrath:
            {
                g_iDifficultyLevel = g_iOldDifficulty;
            }
        }
    }
}

bool IsArtifactActive(int artifact)
{
    return g_hActiveArtifacts.FindValue(artifact) != -1;
}

void DisableAllArtifacts()
{
    for (int i = 0; i <= BLUArtifact_Max; i++)
    {
        SetArtifactEnabled(i, false);
    }
}

int GetArtifactInternalName(int artifact, char[] buffer, int size)
{
    static char name[32];
    switch (artifact)
    {
        case REDArtifact_Command: name = "Command";
        case REDArtifact_Efficiency: name = "Efficiency";
        case REDArtifact_Fortune: name = "Fortune";
        case REDArtifact_Luck: name = "Luck";
        case REDArtifact_Patience: name = "Patience";
        case REDArtifact_Restoration: name = "Restoration";

        case BLUArtifact_Envy: name = "Envy";
        case BLUArtifact_Haste: name = "Haste";
        case BLUArtifact_Power: name = "Power";
        case BLUArtifact_Silence: name = "Silence";
        case BLUArtifact_Swarm: name = "Swarm";
        case BLUArtifact_Wrath: name = "Wrath";
    }
    
    return FormatEx(buffer, size, "%s", name);
}

int GetArtifactDisplayName(int artifact, char[] buffer, int size, int client=LANG_SERVER)
{
    static char name[32];
    GetArtifactInternalName(artifact, name, sizeof(name));
    return FormatEx(buffer, size, "%T", name, client);
}

int GetArtifactDescription(int artifact, char[] buffer, int size, int client=LANG_SERVER)
{
    static char name[32];
    GetArtifactInternalName(artifact, name, sizeof(name));
    StrCat(name, sizeof(name), "_Desc");
    return FormatEx(buffer, size, "%T", name, client);
}
