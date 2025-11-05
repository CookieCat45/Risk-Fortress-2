#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_ActionFactory;

methodmap RF2_MajorShocksVortexAction < RF2_BaseNPCAttackAction
{
	public RF2_MajorShocksVortexAction()
	{
		if (!g_ActionFactory)
		{
			g_ActionFactory = new NextBotActionFactory("RF2_MajorShocksVortex");
			g_ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
			g_ActionFactory.BeginDataMapDesc()
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
				.DefineIntField("m_nHitCounter")
				.DefineEntityField("m_Particle")
				.DefineEntityField("m_PushField")
			.EndDataMapDesc();
		}
		return view_as<RF2_MajorShocksVortexAction>(g_ActionFactory.Create());
	}

	property CBaseEntity Particle
	{
		public get()
		{
			return CBaseEntity(EntRefToEntIndex(this.GetDataEnt("m_Particle")));
		}

		public set(CBaseEntity value)
		{
			this.SetDataEnt("m_Particle", value.index);
		}
	}
	
	property CBaseEntity PushField
	{
		public get()
		{
			return CBaseEntity(EntRefToEntIndex(this.GetDataEnt("m_PushField")));
		}

		public set(CBaseEntity value)
		{
			this.SetDataEnt("m_PushField", value.index);
		}
	}
}

static int OnStart(RF2_MajorShocksVortexAction action, RF2_MajorShocks actor)
{
	float gameTime = GetGameTime();
	actor.LockAnimations = true;
	action.StartTime = 7.0 + gameTime;
	action.AttackTime = 7.3 + gameTime;
	actor.EmitSpecialAttackQuote();
	actor.Path.Invalidate();
	//actor.ResetSequence(actor.LookupSequence("taunt_unleashed_rage_soldier"));
	//actor.SetPropFloat(Prop_Data, "m_flCycle", 0.0);
	//actor.SetPropFloat(Prop_Send, "m_flPlaybackRate", 0.2);
	actor.AddGesture("taunt_unleashed_rage_soldier", _, _, 0.2);
	EmitSoundToAll(SND_MAJORSHOCKS_VORTEXSTART, actor.index, _, 110);
	action.PushField = CBaseEntity(CreateEntityByName("point_push"));
	float pos[3];
	actor.GetAbsOrigin(pos);
	pos[2] += 10.0;
	action.PushField.Teleport(pos);
	action.PushField.Spawn();
	action.PushField.Activate();
	action.PushField.KeyValueFloat("radius", 2600.0);
	action.PushField.KeyValueFloat("magnitude", -80.0);
	action.PushField.KeyValueFloat("innerradius", 400.0);
	action.PushField.KeyValue("spawnflags", "8");
	action.PushField.AcceptInput("Enable");
	
	action.Particle = CBaseEntity(CreateEntityByName("info_particle_system"));
	action.Particle.KeyValue("effect_name", "eb_death_vortex01");
	SetEntityOwner(action.Particle.index, actor.index);
	pos[2] += 80.0;
	action.Particle.Teleport(pos);
	action.Particle.Spawn();
	action.Particle.Activate();
	action.Particle.AcceptInput("start");
	return action.Continue();
}

static int Update(RF2_MajorShocksVortexAction action, RF2_MajorShocks actor, float interval)
{
	float gameTime = GetGameTime();
	if (action.AttackTime <= gameTime)
	{
		return action.Done();
	}

	if (action.StartTime > -1.0 && action.StartTime <= gameTime)
	{
		float pos[3];
		action.DoAttackHitbox({0.0, 0.0, 0.0}, pos, {-350.0, -350.0, 0.0}, {350.0, 350.0, 8000.0},
			300.0, DMG_ENERGYBEAM|DMG_SHOCK, {0.0, 0.0, 0.0}, false, 0.0);
		EmitSoundToAll(SND_MAJORSHOCKS_VORTEXEND, actor.index, _, 110);
		RemoveEntity(action.PushField.index);
		actor.DoShake();
		action.Particle.AcceptInput("stop");
		RemoveEntity(action.Particle.index);

		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i))
				continue;
			
			UTIL_ScreenFade(i, {255, 255, 255, 255}, 0.35, 0.1, FFADE_PURGE);
		}

		action.StartTime = -1.0;
	}

	return action.Continue();
}

static void OnEnd(RF2_MajorShocksVortexAction action, RF2_MajorShocks actor, NextBotAction prevAction)
{
	actor.LockAnimations = false;
	actor.RemoveAllGestures();
	if (action.Particle.IsValid())
	{
		action.Particle.AcceptInput("stop");
		RemoveEntity(action.Particle.index);
	}
	
	if (action.PushField.IsValid())
	{
		RemoveEntity(action.PushField.index);
	}
}