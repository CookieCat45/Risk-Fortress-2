#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_Factory;

methodmap RF2_GalleomDeathState < NextBotAction
{
	public RF2_GalleomDeathState()
	{
		if (!g_Factory)
		{
			g_Factory = new NextBotActionFactory("RF2_GalleomDeathState");
			g_Factory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
		}
		
		return view_as<RF2_GalleomDeathState>(g_Factory.Create());
	}
}

static int OnStart(RF2_GalleomDeathState action, RF2_RaidBoss_Galleom boss, NextBotAction prevAction)
{
	float pos[3];
	boss.GetAbsOrigin(pos);
	pos[2] += 80.0;
	TE_TFParticle("grenade_smoke", pos);
	EmitSoundToAll(SND_BOSS_DEATH);
	EmitSoundToAll(SND_BOSS_DEATH);
	EmitSoundToAll(SND_GALLEOM_ROAR, boss.index, _, SNDLEVEL_SCREAMING);
	EmitSoundToAll(SND_GALLEOM_ROAR, boss.index, _, SNDLEVEL_SCREAMING);
	float time;
	if (GetRandomInt(1, 2) == 1)
	{
		time = boss.AddGesture("EnmGalleomDown1") * 0.5;
	}
	else
	{
		time = boss.AddGesture("EnmGalleomDown2") * 0.5;
	}
	
	ConVar timescale = FindConVar("host_timescale");
	ConVar cheats = FindConVar("sv_cheats");
	timescale.Flags &= ~FCVAR_CHEAT;
	timescale.FloatValue = 0.05;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		UTIL_ScreenFade(i, {200, 200, 200, 50}, 0.2, 0.5, FFADE_OUT|FFADE_PURGE);
		SendConVarValue(i, cheats, "1");
	}
	
	CreateTimer(0.5, Timer_HostTimescaleReset, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(time, Timer_GalleomDeathExplosion, EntIndexToEntRef(boss.index), TIMER_FLAG_NO_MAPCHANGE);
	return action.Continue();
}

static void Timer_HostTimescaleReset(Handle timer)
{
	ConVar timescale = FindConVar("host_timescale");
	ConVar cheats = FindConVar("sv_cheats");
	timescale.FloatValue = 1.0;
	timescale.Flags |= FCVAR_CHEAT;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		SendConVarValue(i, cheats, "0");
	}
}

static void Timer_GalleomDeathExplosion(Handle timer, int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT)
		return;
	
	RF2_RaidBoss_Galleom boss = RF2_RaidBoss_Galleom(entity);
	float pos[3];
	boss.GetAbsOrigin(pos);
	TE_TFParticle("hightower_explosion", pos);
	TE_TFParticle("fireSmokeExplosion3", pos);
	UTIL_ScreenShake(pos, 30.0, 40.0, 10.0, 9000.0, SHAKE_START, true);
	EmitSoundToAll(SND_DOOMSDAY_EXPLODE);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || DistBetween(i, entity) > 9000.0)
			continue;
		
		UTIL_ScreenFade(i, {255, 255, 255, 255}, 0.3, 0.1, FFADE_PURGE);
	}
	
	RemoveEntity(entity);
}
