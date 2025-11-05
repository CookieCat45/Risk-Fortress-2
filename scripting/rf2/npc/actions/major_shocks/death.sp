#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_ActionFactory;

methodmap RF2_MajorShocksDeathAction < NextBotAction
{
	public RF2_MajorShocksDeathAction()
	{
		if (g_ActionFactory == null)
		{
			g_ActionFactory = new NextBotActionFactory("RF2_MajorShocksDeath");
			g_ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
			g_ActionFactory.BeginDataMapDesc()
				.DefineFloatField("m_Time")
				.DefineFloatField("m_NextAnimTime")
				.DefineIntField("m_AnimationIndex")
				.DefineFloatField("m_NextSoundTime")
				.DefineIntField("m_SoundIndex")
				.DefineEntityField("m_ChargeParticle")
				.EndDataMapDesc();
		}
		return view_as<RF2_MajorShocksDeathAction>(g_ActionFactory.Create());
	}

	property float Time
	{
		public get()
		{
			return this.GetDataFloat("m_Time");
		}

		public set(float value)
		{
			this.SetDataFloat("m_Time", value);
		}
	}

	property float NextAnimTime
	{
		public get()
		{
			return this.GetDataFloat("m_NextAnimTime");
		}

		public set(float value)
		{
			this.SetDataFloat("m_NextAnimTime", value);
		}
	}

	property int AnimationIndex
	{
		public get()
		{
			return this.GetData("m_AnimationIndex");
		}

		public set(int value)
		{
			this.SetData("m_AnimationIndex", value);
		}
	}

	property float NextSoundTime
	{
		public get()
		{
			return this.GetDataFloat("m_NextSoundTime");
		}

		public set(float value)
		{
			this.SetDataFloat("m_NextSoundTime", value);
		}
	}

	property int SoundIndex
	{
		public get()
		{
			return this.GetData("m_SoundIndex");
		}

		public set(int value)
		{
			this.SetData("m_SoundIndex", value);
		}
	}

	property int ChargeParticle
	{
		public get()
		{
			return EntRefToEntIndex(this.GetDataEnt("m_ChargeParticle"));
		}

		public set(int entity)
		{
			this.SetDataEnt("m_ChargeParticle", entity);
		}
	}

	public void DoExplosion(RF2_MajorShocks actor)
	{
		float pos[3];
		actor.WorldSpaceCenter(pos);

		actor.DoShake();

		TE_TFParticle("ExplosionCore_Wall", pos);

		EmitSoundToAll(SND_MAJORSHOCKS_DEATHEXPLOSION);
	}
}

static int OnStart(RF2_MajorShocksDeathAction action, RF2_MajorShocks actor, NextBotAction priorAction)
{
	float gameTime = GetGameTime();
	float pos[3];
	actor.LockAnimations = true;
	actor.GetAbsOrigin(pos);
	actor.RemoveItem();
	action.NextAnimTime = 3.0 + gameTime;
	action.NextSoundTime = 3.3 + gameTime;
	action.Time = 7.62 + gameTime;
	actor.ResetSequence(actor.LookupSequence("primary_death_backStab"));
	actor.SetPropFloat(Prop_Data, "m_flCycle", 0.0);
	actor.SetPropFloat(Prop_Send, "m_flPlaybackRate", 0.2);
	EmitSoundToAll(SND_SENTRYBUSTER_BOOM);
	TE_TFParticle("fireSmokeExplosion", pos);
	StopMusicTrackAll();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		UTIL_ScreenFade(i, {255, 255, 255, 255}, 0.35, 0.1, FFADE_PURGE);
	}

	GetRF2GameRules().AllowEnemySpawning = false;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_ENEMY)
			continue;

		SDKHooks_TakeDamage(i, i, i, GetEntProp(i, Prop_Data, "m_iHealth") * 20.0);
	}
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "obj_*")) != INVALID_ENT)
	{
		if (GetEntProp(entity, Prop_Send, "m_iTeamNum") != TEAM_ENEMY)
			continue;

		SDKHooks_TakeDamage(entity, entity, entity, GetEntProp(entity, Prop_Data, "m_iHealth") * 20.0);
	}

	RF2_GameRules gamerules = GetRF2GameRules();
	if (gamerules.IsValid())
	{
		gamerules.FireOutput("OnTeleporterEventComplete");
	}

	RemoveEntity(actor.HealthText.index);
	actor.SetGlow(false);
	RF2_Object_Teleporter.ToggleObjectsStatic(true);
	RF2_Object_Teleporter.EventCompletion();
	return action.Continue();
}

static int Update(RF2_MajorShocksDeathAction action, RF2_MajorShocks actor, float interval)
{
	float gameTime = GetGameTime();
	if (action.Time <= gameTime)
	{
		return action.Done("I am actually fully dead now.");
	}

	float pos[3];
	actor.GetAbsOrigin(pos);
	if (action.NextSoundTime <= gameTime)
	{
		switch (action.SoundIndex)
		{
			case 0:
			{
				action.DoExplosion(actor);
				action.SoundIndex++;
				action.NextSoundTime = 1.0 + gameTime;
			}

			case 1:
			{
				action.DoExplosion(actor);
				action.SoundIndex++;
				action.NextSoundTime = 0.7 + gameTime;
			}

			case 2:
			{
				EmitSoundToAll(SND_MAJORSHOCKS_DEATHSCREAM);
				action.SoundIndex++;
				action.NextSoundTime = 0.3 + gameTime;
			}

			case 3, 4:
			{
				action.DoExplosion(actor);
				action.SoundIndex++;
				action.NextSoundTime = 1.0 + gameTime;
			}
		}
	}

	if (action.NextAnimTime <= gameTime)
	{
		switch (action.AnimationIndex)
		{
			case 0:
			{
				action.AnimationIndex = 1;
				action.NextAnimTime = 3.0 + gameTime;
				action.ChargeParticle = CreateEntityByName("info_particle_system");
				DispatchKeyValue(action.ChargeParticle, "effect_name", "charge_up");
				float particlePos[3];
				particlePos = pos;
				particlePos[2] += 82;
				SetEntityOwner(action.ChargeParticle, actor.index);
				TeleportEntity(action.ChargeParticle, particlePos);
				DispatchSpawn(action.ChargeParticle);
				ActivateEntity(action.ChargeParticle);
				AcceptEntityInput(action.ChargeParticle, "start");
				actor.ResetSequence(actor.LookupSequence("primary_death_burning"));
				actor.SetPropFloat(Prop_Send, "m_flPlaybackRate", 0.5);
			}

			case 1:
			{
				actor.SetPropFloat(Prop_Send, "m_flPlaybackRate", 1.5);
				action.AnimationIndex = 2;
				action.NextAnimTime = 3.25 + gameTime;
			}
		}
	}

	return action.Continue();
}

static void OnEnd(RF2_MajorShocksDeathAction action, RF2_MajorShocks actor)
{
	float pos[3];
	actor.GetAbsOrigin(pos);
	TE_TFParticle("rd_robot_explosion", pos);
	TE_TFParticle("mvm_tank_destroy", pos);
	UTIL_ScreenShake(pos, 16.0, 9.0, 3.0, 999999999999.9, SHAKE_START, true);
	EmitSoundToAll(SND_SENTRYBUSTER_BOOM);
	EmitSoundToAll(SND_MAJORSHOCKS_DEATHEXPLOSION_2);
	EmitSoundToAll(SND_MAJORSHOCKS_DEATHEXPLOSION_3);
	EmitSoundToAll(SND_MAJORSHOCKS_DEATHEXPLOSION_4);
	AcceptEntityInput(action.ChargeParticle, "stop");
	RemoveEntity(action.ChargeParticle);
	RemoveEntity(actor.index);
}