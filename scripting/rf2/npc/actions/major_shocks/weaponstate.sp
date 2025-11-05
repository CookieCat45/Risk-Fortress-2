#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_ActionFactory;

methodmap RF2_MajorShocksWeaponStateAction < RF2_BaseNPCAttackAction
{
	public RF2_MajorShocksWeaponStateAction()
	{
		if (!g_ActionFactory)
		{
			g_ActionFactory = new NextBotActionFactory("RF2_MajorShocksWeaponState");
			g_ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
			g_ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
			g_ActionFactory.SetCallback(NextBotActionCallbackType_OnResume, OnResume);
			g_ActionFactory.BeginDataMapDesc()
				.DefineFloatField("m_NextWeaponTime")
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
				.DefineIntField("m_nHitCounter")
			.EndDataMapDesc();
		}
		
		return view_as<RF2_MajorShocksWeaponStateAction>(g_ActionFactory.Create());
	}
	
	property float NextWeaponType
	{
		public get()
		{
			return this.GetDataFloat("m_NextWeaponTime");
		}

		public set(float value)
		{
			this.SetDataFloat("m_NextWeaponTime", value);
		}
	}
}

static int OnStart(RF2_MajorShocksWeaponStateAction action, RF2_MajorShocks actor, NextBotAction prevAction)
{
	SwitchWeapon(action, actor, MajorShocks_WeaponType_BurstFire);
	return action.Continue();
}

static int Update(RF2_MajorShocksWeaponStateAction action, RF2_MajorShocks actor, float interval)
{
	if (action.NextWeaponType <= 0.0)
	{
		SwitchWeapon(action, actor);
	}

	INextBot bot = actor.MyNextBotPointer();
	if (actor.WeaponState != MajorShocks_WeaponState_Melee)
	{
		if (!actor.IsReloading)
		{
			actor.FireTime -= interval;
			if (actor.FireTime <= 0.0 && actor.ClipSize <= 0)
			{
				actor.IsReloading = true;
			}
			
			if (!actor.IsReloading && actor.IsTargetValid() && IsLOSClear(actor.index, actor.Target) && actor.FireTime <= 0.0)
			{
				Activity activity = ACT_MP_ATTACK_STAND_PRIMARY;
				actor.FireTime = actor.FireRate;
				actor.ClipSize--;
				float posToShoot[3], baseAng[3], targetPos[3];
				CBaseEntity(actor.Target).WorldSpaceCenter(targetPos);
				int attachmentIndex = actor.Item.LookupAttachment("muzzle");
				actor.Item.GetAttachment(attachmentIndex, posToShoot, baseAng);
				float range = bot.GetRangeTo(actor.Target);
				const float closeRange = 150.0;
				if (range > closeRange)
				{
					float timeToTravel = range / actor.ProjectileSpeed;
					float velocity[3], worldSpace[3], check[3];
					actor.WorldSpaceCenter(worldSpace);
					CBaseEntity(actor.Target).GetAbsVelocity(velocity);
					ScaleVector(velocity, timeToTravel);
					check = targetPos;
					AddVectors(check, velocity, check);
					TR_TraceRayFilter(worldSpace, check, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceFilter_WallsOnly, actor.index);
					if (TR_DidHit())
					{
						const float errorTolerance = 300.0;
						float length[3];
						TR_GetEndPosition(length);
						SubtractVectors(length, targetPos, length);
						if (GetVectorLength(length) > errorTolerance)
						{
							float origin[3];
							velocity = origin;
						}
					}

					AddVectors(targetPos, velocity, targetPos);
				}

				float shootDirection[3], shootAng[3];
				SubtractVectors(targetPos, posToShoot, shootDirection);
				shootDirection[0] += GetRandomFloat(-actor.Deviation, actor.Deviation);
				shootDirection[1] += GetRandomFloat(-actor.Deviation, actor.Deviation);
				shootDirection[2] += GetRandomFloat(-actor.Deviation, actor.Deviation);
				NormalizeVector(shootDirection, shootDirection);
				GetVectorAngles(shootDirection, shootAng);
				bool crits = actor.IsCrits;
				if (actor.WeaponState == MajorShocks_WeaponState_Primary)
				{
					int rocket = ShootProjectile(actor.index, "tf_projectile_rocket", posToShoot, shootAng, 
						actor.ProjectileSpeed, actor.Damage);
					
					SetEntProp(rocket, Prop_Send, "m_bCritical", crits);
					SetEntityCollisionGroup(rocket, TFCOLLISION_GROUP_ROCKET_BUT_NOT_WITH_OTHER_ROCKETS);
					//rocket.IsCrits = true;
					//rocket.Radius = actor.BlastRadius;
				}
				else if (actor.WeaponState == MajorShocks_WeaponState_Secondary)
				{
					ShootProjectile(
						actor.index, "rf2_projectile_energyshot",
						posToShoot, shootAng, actor.ProjectileSpeed, 
						actor.Damage);
				}
				
				switch (actor.WeaponType)
				{
					case MajorShocks_WeaponType_BurstFire, MajorShocks_WeaponType_GigaBurstFire:
					{
						EmitSoundToAll(crits ? g_MajorShocksWeaponShootCritSounds[0] : g_MajorShocksWeaponShootSounds[0], 
							actor.index, SNDCHAN_ITEM, SNDLEVEL_SCREAMING);
					}
					
					case MajorShocks_WeaponType_Barrage,
						MajorShocks_WeaponType_Multi,
						MajorShocks_WeaponType_GigaBarrage,
						MajorShocks_WeaponType_GigaMulti:
					{
						EmitSoundToAll(crits ? g_MajorShocksWeaponShootCritSounds[1] : g_MajorShocksWeaponShootSounds[1],
							actor.index, SNDCHAN_ITEM, SNDLEVEL_SCREAMING);
					}
					
					case MajorShocks_WeaponType_Homing, MajorShocks_WeaponType_GigaHoming:
					{
						EmitSoundToAll(crits ? g_MajorShocksWeaponShootCritSounds[3] : g_MajorShocksWeaponShootSounds[3],
							actor.index, SNDCHAN_ITEM, SNDLEVEL_SCREAMING);
					}

					case MajorShocks_WeaponType_Nuke, MajorShocks_WeaponType_GigaNuke:
					{
						EmitSoundToAll(crits ? g_MajorShocksWeaponShootCritSounds[2] : g_MajorShocksWeaponShootSounds[2],
							actor.index, SNDCHAN_ITEM, SNDLEVEL_SCREAMING);
					}

					case MajorShocks_WeaponType_GigaBison:
					{
						EmitSoundToAll(crits ? g_MajorShocksWeaponShootCritSounds[5] : g_MajorShocksWeaponShootSounds[5],
							actor.index, SNDCHAN_ITEM, SNDLEVEL_TRAIN);
							
						EmitSoundToAll(crits ? g_MajorShocksWeaponShootCritSounds[5] : g_MajorShocksWeaponShootSounds[5],
							actor.index, SNDCHAN_ITEM, SNDLEVEL_TRAIN);
					}
				}

				if (actor.IsValidLayer(actor.CurrentLayer))
				{
					actor.FastRemoveLayer(actor.CurrentLayer);
				}
				
				int tempLayer = actor.AddLayeredSequence(actor.SelectWeightedSequence(activity), 1);
				CAnimationLayer layer = actor.GetAnimOverlay(tempLayer);
				layer.m_fFlags |= ANIM_LAYER_AUTOKILL;
				layer.m_flBlendIn = 0.0;
				layer.m_flBlendOut = 0.0;
				layer.m_flCycle = 0.0;
				layer.m_flPrevCycle = 0.0;
				actor.CurrentLayer = tempLayer;
				StopSound(actor.index, SNDCHAN_AUTO, SND_MAJORSHOCKS_RELOAD1);
				StopSound(actor.index, SNDCHAN_AUTO, SND_MAJORSHOCKS_RELOAD1);
				StopSound(actor.index, SNDCHAN_AUTO, SND_MAJORSHOCKS_RELOAD2);
				StopSound(actor.index, SNDCHAN_AUTO, SND_MAJORSHOCKS_RELOAD2);
			}
		}
		else
		{
			actor.ReloadTime -= interval;
			if (actor.ReloadTime <= 0.0 && actor.FireTime <= 0.0)
			{
				actor.ReloadTime = actor.ReloadRate;
				actor.ClipSize++;
				if (actor.HoldUntilFullReload)
				{
					if (actor.ClipSize >= actor.MaxClipSize)
					{
						actor.IsReloading = false;
					}
				}
				else if (actor.IsTargetValid() && IsLOSClear(actor.index, actor.Target) && actor.FireTime <= 0.0)
				{
					actor.IsReloading = false;
				}
				
				if (actor.ClipSize > actor.MaxClipSize)
				{
					actor.ClipSize = actor.MaxClipSize;
				}
				
				Activity activity = ACT_MP_RELOAD_STAND_PRIMARY;
				if (actor.WeaponState == MajorShocks_WeaponState_Secondary)
				{
					activity = ACT_MP_RELOAD_STAND_SECONDARY2;
					EmitSoundToAll(SND_MAJORSHOCKS_RELOAD2, actor.index);
				}
				else
				{
					EmitSoundToAll(SND_MAJORSHOCKS_RELOAD1, actor.index, _, SNDLEVEL_TRAIN);
					EmitSoundToAll(SND_MAJORSHOCKS_RELOAD1, actor.index, _, SNDLEVEL_TRAIN);
				}
				
				if (actor.IsValidLayer(actor.CurrentLayer))
				{
					actor.FastRemoveLayer(actor.CurrentLayer);
				}
				
				int tempLayer = actor.AddLayeredSequence(actor.SelectWeightedSequence(activity), 1);
				CAnimationLayer layer = actor.GetAnimOverlay(tempLayer);
				layer.m_fFlags |= ANIM_LAYER_AUTOKILL;
				layer.m_flBlendIn = 0.0;
				layer.m_flBlendOut = 0.0;
				layer.m_flCycle = 0.0;
				layer.m_flPrevCycle = 0.0;
				layer.m_flPlaybackRate = fmin(1.0 / actor.ReloadRate, 2.0);
				actor.CurrentLayer = tempLayer;
			}
		}
	}
	else
	{
		actor.FireTime -= interval;
		if (actor.IsTargetValid() && IsLOSClear(actor.index, actor.Target) && actor.FireTime <= 0.0)
		{
			action.AttackTime = GetGameTime()+0.4;
			actor.FireTime = actor.FireRate;
			Activity activity = ACT_MP_ATTACK_STAND_MELEE;
			int tempLayer = actor.AddLayeredSequence(actor.SelectWeightedSequence(activity), 1);
			CAnimationLayer layer = actor.GetAnimOverlay(tempLayer);
			layer.m_fFlags |= ANIM_LAYER_AUTOKILL;
			layer.m_flBlendIn = 0.0;
			layer.m_flBlendOut = 0.0;
			layer.m_flCycle = 0.0;
			layer.m_flPrevCycle = 0.0;
			layer.m_flPlaybackRate = 1.0;
			actor.CurrentLayer = tempLayer;
			EmitSoundToAll(actor.IsCrits ? g_MajorShocksWeaponShootCritSounds[4] : g_MajorShocksWeaponShootSounds[4],
				actor.index, SNDCHAN_ITEM, SNDLEVEL_TRAIN);
		}
		
		if (action.AttackTime > 0.0 && GetGameTime() <= action.AttackTime)
		{
			ArrayList hitEnts = action.DoAttackHitbox({50.0, 0.0, 50.0}, _, {-200.0, -70.0, 0.0}, {200.0, 70.0, 200.0}, 
				actor.Damage, actor.IsCrits ? DMG_CRIT|DMG_MELEE|DMG_CLUB : DMG_MELEE|DMG_CLUB, _, true);
				
			for (int i = 0; i < hitEnts.Length; i++)
			{
				int entity = hitEnts.Get(i);
				if (IsBuilding(entity))
				{
					EmitSoundToAll(SND_SWORD_IMPACT, entity, _, SNDLEVEL_SCREAMING);
				}
				else
				{
					EmitGameSoundToAll(GSND_SWORD_HIT, entity, _, SNDLEVEL_SCREAMING);
				}
			}
			
			delete hitEnts;
			action.AttackTime = 0.0;
		}
	}
	
	action.NextWeaponType -= interval;
	return action.Continue();
}

static int OnResume(RF2_MajorShocksWeaponStateAction action, RF2_MajorShocks actor, NextBotAction interruptingAction)
{
	SwitchWeapon(action, actor);
	return action.Continue();
}

static void SwitchWeapon(RF2_MajorShocksWeaponStateAction action, RF2_MajorShocks actor, MajorShocks_WeaponType override = MajorShocks_WeaponType_Invalid)
{
	ArrayList list = new ArrayList();
	if (actor.Phase != MajorShocks_Phase_Final)
	{
		action.NextWeaponType = 10.0;
		for (int i = 0; i < view_as<int>(MajorShocks_WeaponType_GigaBurstFire); i++)
		{
			list.Push(view_as<MajorShocks_WeaponType>(i));
		}
	}
	else
	{
		action.NextWeaponType = 7.0;
		for (int i = view_as<int>(MajorShocks_WeaponType_GigaBurstFire); i <= view_as<int>(MajorShocks_WeaponType_GigaVortex); i++)
		{
			list.Push(view_as<MajorShocks_WeaponType>(i));
		}
	}

	int item = list.FindValue(actor.WeaponType);
	if (item > -1)
	{
		list.Erase(item);
	}

	MajorShocks_WeaponType type = list.Get(GetRandomInt(0, list.Length - 1));
	if (override != MajorShocks_WeaponType_Invalid)
	{
		type = override;
	}
	
	switch (type)
	{
		case MajorShocks_WeaponType_BurstFire, MajorShocks_WeaponType_GigaBurstFire:
		{
			actor.WeaponState = MajorShocks_WeaponState_Primary;
			actor.EquipItem(g_MajorShocksWeaponModels[0]);
			actor.HoldUntilFullReload = true;
			actor.MaxClipSize = 9;
			actor.FireRate = 0.16;
			actor.ReloadRate = 0.32;
			actor.Damage = 45.0;
			actor.ProjectileSpeed = 1980.0;
			actor.Deviation = 0.0;
			actor.BlastRadius = 38.4;
		}

		case MajorShocks_WeaponType_Barrage,
			MajorShocks_WeaponType_Multi,
			MajorShocks_WeaponType_GigaBarrage,
			MajorShocks_WeaponType_GigaMulti:
		{
			actor.WeaponState = MajorShocks_WeaponState_Primary;
			actor.EquipItem(g_MajorShocksWeaponModels[1]);
			actor.HoldUntilFullReload = true;
			actor.MaxClipSize = 30;
			actor.FireRate = 0.16;
			actor.ReloadRate = 0.0016;
			actor.Deviation = 5.0;
			actor.ProjectileSpeed = 440.0;
			actor.Damage = 90.0;
			actor.BlastRadius = 128.0;
		}

		case MajorShocks_WeaponType_Homing, MajorShocks_WeaponType_GigaHoming:
		{
			actor.WeaponState = MajorShocks_WeaponState_Primary;
			actor.EquipItem(g_MajorShocksWeaponModels[3]);
			actor.HoldUntilFullReload = true;
			actor.MaxClipSize = 17;
			actor.FireRate = 0.0016;
			actor.ReloadRate = 0.12;
			actor.Damage = 65.0;
			actor.ProjectileSpeed = 1540.0;
			actor.Deviation = 120.0;
			actor.BlastRadius = 128.0;
		}

		case MajorShocks_WeaponType_Nuke, MajorShocks_WeaponType_GigaNuke:
		{
			actor.WeaponState = MajorShocks_WeaponState_Primary;
			actor.EquipItem(g_MajorShocksWeaponModels[2]);
			actor.HoldUntilFullReload = true;
			actor.MaxClipSize = 3;
			actor.FireRate = 2.0;
			actor.ReloadRate = 0.0016;
			actor.Deviation = 0.0;
			actor.ProjectileSpeed = 1100.0;
			actor.Damage = 180.0;
			actor.BlastRadius = 256.0;
		}

		case MajorShocks_WeaponType_GigaBison:
		{
			actor.WeaponState = MajorShocks_WeaponState_Secondary;
			actor.EquipItem(g_MajorShocksWeaponModels[5]);
			actor.HoldUntilFullReload = true;
			actor.MaxClipSize = 15;
			actor.FireRate = 0.2;
			actor.ReloadRate = 0.12;
			actor.Damage = 20.0;
			actor.Deviation = 2.0;
			actor.ProjectileSpeed = 1200.0;
		}

		case MajorShocks_WeaponType_GigaMelee:
		{
			actor.WeaponState = MajorShocks_WeaponState_Melee;
			action.AttackTime = 0.0;
			actor.FireRate = 0.8;
			actor.Damage = 100.0;
			actor.EquipItem(g_MajorShocksWeaponModels[4]);
		}

		case MajorShocks_WeaponType_GroundSlam,
			MajorShocks_WeaponType_Vortex,
			MajorShocks_WeaponType_GigaGroundSlam,
			MajorShocks_WeaponType_GigaVortex:
		{
			action.NextWeaponType = 10.0;
			actor.WeaponState = MajorShocks_WeaponState_Primary;
			actor.RemoveItem();
		}
	}
	
	actor.WeaponType = type;
	actor.ClipSize = actor.MaxClipSize;
	actor.IsReloading = false;
	delete list;
}
