#pragma semicolon 1
#pragma newdecls required

static CEntityFactory g_Factory;
typedef OnCollideCallback = function void(RF2_Projectile_Base proj, int other);

enum // Impact sound type
{
	SoundType_Fire, // Projectile firing off
	SoundType_CharImpact, // Projectile hit a player character
	SoundType_WorldImpact, // Projectile hit world or non-player character
};

methodmap RF2_Projectile_Base < CBaseAnimating
{
	public RF2_Projectile_Base(int entity)
	{
		return view_as<RF2_Projectile_Base>(entity);
	}
	
	public bool IsValid()
	{
		if (!IsValidEntity2(this.index))
		{
			return false;
		}
		
		static char classname[128];
		this.GetClassname(classname, sizeof(classname));
		return StrContains(classname, "rf2_projectile") != -1;
	}
	
	public static CEntityFactory GetFactory()
	{
		return g_Factory;
	}
	
	public static void Init()
	{
		g_Factory = new CEntityFactory("rf2_projectile_base", OnCreate, OnRemove);
		g_Factory.IsAbstract = true;
		g_Factory.DeriveFromClass("prop_physics_override");
		g_Factory.BeginDataMapDesc()
			.DefineFloatField("m_flBaseDamage")
			.DefineFloatField("m_flDeactivateTime")
			.DefineFloatField("m_flDirectDamage")
			.DefineFloatField("m_flExplodeRadius")
			.DefineFloatField("m_flFalloffMult")
			.DefineFloatField("m_flLastVPhysicsUpdate")
			.DefineVectorField("m_vecHitboxMins")
			.DefineVectorField("m_vecHitboxMaxs")
			.DefineBoolField("m_bHit")
			.DefineBoolField("m_bRemoveOnHit")
			.DefineBoolField("m_bDamageOwner")
			.DefineBoolField("m_bFlying")
			.DefineBoolField("m_bHoming")
			.DefineBoolField("m_bDeactivateOnHit")
			.DefineBoolField("m_bAltParticleSpawn")
			.DefineEntityField("m_hHomingTarget")
			.DefineFloatField("m_flHomingSpeed")
			.DefineFloatField("m_flLastHomingTime")
			.DefineStringField("m_szRedTrail")
			.DefineStringField("m_szBlueTrail")
			.DefineStringField("m_szCharImpactSound")
			.DefineStringField("m_szWorldImpactSound")
			.DefineStringField("m_szFireSound")
			.DefineEntityField("m_hImpactTarget")
			.DefineEntityField("m_hProjectileOwner")
			.DefineEntityField("m_hThruster")
			.DefineIntField("m_OnCollide")
			.DefineIntField("m_hIgnoredEnts")
		.EndDataMapDesc();
		g_Factory.Install();
	}
	
	property int Owner
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hProjectileOwner");
		}
		
		public set(int owner)
		{
			this.SetPropEnt(Prop_Data, "m_hProjectileOwner", owner);
		}
	}
	
	property int Team
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iTeamNum");
		}

		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iTeamNum", value);
		}
	}
	
	property float Damage
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flBaseDamage");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flBaseDamage", value);
		}
	}

	property float DeactivateTime
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flDeactivateTime");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flDeactivateTime", value);
		}
	}

	property bool HasHit
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bHit"));
		}

		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bHit", value);
		}
	}
	
	property bool RemoveOnHit
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bRemoveOnHit"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bRemoveOnHit", value);
		}
	}

	property ArrayList IgnoredEnts
	{
		public get()
		{
			return view_as<ArrayList>(this.GetProp(Prop_Data, "m_hIgnoredEnts"));
		}
		
		public set(ArrayList value)
		{
			this.SetProp(Prop_Data, "m_hIgnoredEnts", value);
		}
	}
	
	property bool Flying
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bFlying"));
		}
		
		public set(bool value)
		{
			if (IsValidEntity2(this.Thruster))
			{
				value ? AcceptEntityInput(this.Thruster, "Activate") : AcceptEntityInput(this.Thruster, "Deactivate");
			}
			
			this.SetProp(Prop_Data, "m_bFlying", value);
		}
	}
	
	property bool DeactivateOnHit
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bDeactivateOnHit"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bDeactivateOnHit", value);
		}
	}

	property bool Homing
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bHoming"));
		}
		
		public set(bool value)
		{
			bool oldValue = this.Homing;
			this.SetProp(Prop_Data, "m_bHoming", value);
			if (!oldValue && value)
			{
				this.LastHomingTime = GetGameTime();
			}
		}
	}
	
	// Spawns trail particle via TE instead of trigger_particle
	property bool AltParticleSpawn
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bAltParticleSpawn"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bAltParticleSpawn", value);
		}
	}
	
	property float HomingSpeed
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flHomingSpeed");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flHomingSpeed", value);
		}
	}
	
	property float LastHomingTime
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flLastHomingTime");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flLastHomingTime", value);
		}
	}

	property int HomingTarget
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hHomingTarget");
		}
		
		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hHomingTarget", value);
		}
	}
	
	property int Thruster
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hThruster");
		}
		
		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hThruster", value);
		}
	}

	// for explosions
	property float DirectDamage
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flDirectDamage");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flDirectDamage", value);
		}
	}

	// for explosions
	property float Radius
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flExplodeRadius");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flExplodeRadius", value);
		}
	}
	
	// for explosions
	property float FalloffMult
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flFalloffMult");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flFalloffMult", value);
		}
	}

	property float LastVPhysicsUpdate
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flLastVPhysicsUpdate");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flLastVPhysicsUpdate", value);
		}
	}
	
	// for explosions
	property int ImpactTarget
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hImpactTarget");
		}
		
		public set(int entity)
		{
			this.SetPropEnt(Prop_Data, "m_hImpactTarget", entity);
		}
	}
	
	// for explosions
	property bool DamageOwner
	{
		public get()
		{
			return asBool(this.GetProp(Prop_Data, "m_bDamageOwner"));
		}
		
		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_bDamageOwner", value);
		}
	}

	property PrivateForward OnCollide
	{
		public get()
		{
			return view_as<PrivateForward>(this.GetProp(Prop_Data, "m_OnCollide"));
		}

		public set(PrivateForward fwd)
		{
			this.SetProp(Prop_Data, "m_OnCollide", fwd);
		}
	}

	public void GetHitboxMins(float buffer[3])
	{
		this.GetPropVector(Prop_Data, "m_vecHitboxMins", buffer);
	}
	
	public void GetHitboxMaxs(float buffer[3])
	{
		this.GetPropVector(Prop_Data, "m_vecHitboxMaxs", buffer);
	}
	
	public void SetHitboxMins(const float vec[3])
	{
		this.SetPropVector(Prop_Data, "m_vecHitboxMins", vec);
	}
	
	public void SetHitboxMaxs(const float vec[3])
	{
		this.SetPropVector(Prop_Data, "m_vecHitboxMaxs", vec);
	}

	public int GetRedTrail(char[] buffer, int size)
	{
		return this.GetPropString(Prop_Data, "m_szRedTrail", buffer, size);
	}

	public int GetBlueTrail(char[] buffer, int size)
	{
		return this.GetPropString(Prop_Data, "m_szBlueTrail", buffer, size);
	}
	
	public void SetRedTrail(const char[] trail)
	{
		this.SetPropString(Prop_Data, "m_szRedTrail", trail);
	}
	
	public void SetBlueTrail(const char[] trail)
	{
		this.SetPropString(Prop_Data, "m_szBlueTrail", trail);
	}
	
	public int GetCharImpactSound(char[] buffer, int size)
	{
		return this.GetPropString(Prop_Data, "m_szCharImpactSound", buffer, size);
	}
	
	public void SetCharImpactSound(const char[] sound)
	{
		this.SetPropString(Prop_Data, "m_szCharImpactSound", sound);
	}
	
	public int GetWorldImpactSound(char[] buffer, int size)
	{
		return this.GetPropString(Prop_Data, "m_szWorldImpactSound", buffer, size);
	}
	
	public void SetWorldImpactSound(const char[] sound)
	{
		this.SetPropString(Prop_Data, "m_szWorldImpactSound", sound);
	}
	
	public int GetFireSound(char[] buffer, int size)
	{
		return this.GetPropString(Prop_Data, "m_szFireSound", buffer, size);
	}
	
	public void SetFireSound(const char[] sound)
	{
		this.SetPropString(Prop_Data, "m_szFireSound", sound);
	}
	
	public void Remove()
	{
		RemoveEntity2(this.index);
	}
	
	public void PlaySound(int type, int channel=SNDCHAN_AUTO, int level=SNDLEVEL_NORMAL, int flags=SND_NOFLAGS, float volume=SNDVOL_NORMAL, int pitch=SNDPITCH_NORMAL)
	{
		char sound[PLATFORM_MAX_PATH];
		int soundEnt = this.index;
		float soundPos[3];
		soundPos = NULL_VECTOR;
		switch (type)
		{
			case SoundType_Fire: this.GetFireSound(sound, sizeof(sound));
			case SoundType_CharImpact: this.GetCharImpactSound(sound, sizeof(sound));
			case SoundType_WorldImpact: this.GetWorldImpactSound(sound, sizeof(sound));
		}

		if (!sound[0])
			return;
		
		if (type == SoundType_Fire)
		{
			if (IsValidEntity(this.Owner))
			{
				soundEnt = this.Owner;
			}
			else
			{
				this.GetAbsOrigin(soundPos);
				soundEnt = SOUND_FROM_WORLD;
			}
		}
		
		if (StrContains(sound, ".mp3") == -1 && StrContains(sound, ".wav") == -1)
		{
			EmitGameSoundToAll(sound, soundEnt, flags, _, _, soundPos);
		}
		else
		{
			EmitSoundToAll(sound, soundEnt, channel, level, flags, volume, pitch, _, soundPos);
		}
	}
	
	public void HookOnCollide(OnCollideCallback func)
	{
		this.OnCollide.AddFunction(INVALID_HANDLE, func);
	}
	
	public void Deactivate()
	{
		this.HasHit = true;
		if (this.DeactivateTime <= 0.0)
		{
			this.Remove();
		}
		else
		{
			CreateTimer(this.DeactivateTime, Timer_DeleteEntity, EntIndexToEntRef(this.index), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		SDKUnhook(this.index, SDKHook_VPhysicsUpdate, OnVPhysicsUpdate);
	}
	
	public ArrayList Explode(int damageType=DMG_BLAST, bool effect=true, bool sound=true, bool returnHitEnts=false)
	{
		ArrayList blacklist, hitEnts;
		if (IsValidEntity2(this.ImpactTarget) && IsCombatChar(this.ImpactTarget))
		{
			RF_TakeDamage(this.ImpactTarget, this.index, this.Owner, this.DirectDamage, DMG_BLAST, GetEntItemProc(this.index));
			blacklist = new ArrayList();
			blacklist.Push(this.ImpactTarget);
		}
		
		float pos[3];
		this.WorldSpaceCenter(pos);
		hitEnts = DoRadiusDamage(this.Owner, this.index, pos, GetEntItemProc(this.index), 
			this.Damage, DMG_BLAST, this.Radius, this.FalloffMult, this.DamageOwner, blacklist, returnHitEnts);
		
		if (blacklist)
			delete blacklist;
		
		if (effect)
		{
			DoExplosionEffect(pos, sound);
		}
		
		return hitEnts;
	}
	
	public void SelectHomingTarget(bool allowInvuln=false)
	{
		int entity = INVALID_ENT;
		int closestEnt = INVALID_ENT;
		float closestDist = -1.0;
		float dist;
		while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT)
		{
			if (!IsValidEntity2(entity) || !IsCombatChar(entity))
				continue;
			
			if (IsValidClient(entity))
			{
				if (RF2_Projectile_Skull(this.index).IsValid() && RF2_Projectile_Skull.IsPlayerCursed(entity)
					|| !IsPlayerAlive(entity) || !allowInvuln && IsInvuln(entity))
				{
					continue;
				}
			}
			
			if (GetEntTeam(entity) == this.Team)
				continue;
			
			dist = DistBetween(this.index, entity);
			if (closestDist == -1.0 || dist < closestDist)
			{
				closestEnt = entity;
				closestDist = dist;
			}
		}
		
		if (closestEnt != INVALID_ENT)
		{
			this.HomingTarget = closestEnt;
		}
	}

	public void AddIgnoredEnt(int entity)
	{
		if (!this.IgnoredEnts)
			this.IgnoredEnts = new ArrayList();
		
		int ref = EntIndexToEntRef(entity);
		if (this.IgnoredEnts.FindValue(ref) != -1)
			return;
		
		this.IgnoredEnts.Push(ref);
	}

	public void RemoveIgnoredEnt(int entity)
	{
		if (!this.IgnoredEnts)
			this.IgnoredEnts = new ArrayList();
		
		int ref = EntIndexToEntRef(entity);
		int index = this.IgnoredEnts.FindValue(ref);
		if (index == -1)
			return;
		
		this.IgnoredEnts.Erase(index);
	}

	public bool IsEntIgnored(int entity)
	{
		if (!this.IgnoredEnts)
			this.IgnoredEnts = new ArrayList();

		return this.IgnoredEnts.FindValue(EntIndexToEntRef(entity)) != -1;
	}
}

static void OnCreate(RF2_Projectile_Base proj)
{
	proj.ImpactTarget = INVALID_ENT;
	proj.RemoveOnHit = true;
	proj.DeactivateOnHit = true;
	proj.DeactivateTime = 6.0;
	proj.HomingSpeed = 50.0;
	proj.LastHomingTime = GetGameTime();
	proj.LastVPhysicsUpdate = GetGameTime();
	proj.SetHitboxMins({-20.0, -20.0, -20.0});
	proj.SetHitboxMaxs({20.0, 20.0, 20.0});
	SetEntityCollisionGroup(proj.index, COLLISION_GROUP_PROJECTILE);
	proj.AddFlag(FL_GRENADE); // so airblasting works
	proj.OnCollide = new PrivateForward(ET_Hook, Param_Any, Param_Cell);
	proj.HookOnCollide(Projectile_OnCollide);
	SDKHook(proj.index, SDKHook_SpawnPost, OnSpawnPost);
	SDKHook(proj.index, SDKHook_VPhysicsUpdate, OnVPhysicsUpdate);
	CreateTimer(0.5, Timer_CheckVPhysicsUpdate, EntIndexToEntRef(proj.index), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	if (g_hHookVPhysicsCollision)
	{
		g_hHookVPhysicsCollision.HookEntity(Hook_Post, proj.index, DHook_ProjectileCollision);
	}
}

static void OnRemove(RF2_Projectile_Base proj)
{
	if (proj.OnCollide)
	{
		RequestFrame(RF_DeleteForward, proj.OnCollide);
		proj.OnCollide = null;
	}

	if (proj.IgnoredEnts)
	{
		delete proj.IgnoredEnts;
		proj.IgnoredEnts = null;
	}
	
	if (IsValidEntity2(proj.Thruster))
	{
		RemoveEntity2(proj.Thruster);
	}
}

static void RF_DeleteForward(PrivateForward fwd)
{
	delete fwd;
}

static void OnSpawnPost(int entity)
{
	RF2_Projectile_Base proj = RF2_Projectile_Base(entity);
	static char trail[128];
	proj.Team == TEAM_SURVIVOR ? proj.GetRedTrail(trail, sizeof(trail)) : proj.GetBlueTrail(trail, sizeof(trail));
	if (trail[0])
	{
		if (!proj.AltParticleSpawn)
		{
			float pos[3];
			proj.GetAbsOrigin(pos);
			TE_TFParticle(trail, pos, proj.index, PATTACH_ABSORIGIN_FOLLOW);
		}
		else
		{
			SpawnParticleViaTrigger(proj.index, trail, _, PATTACH_ABSORIGIN_FOLLOW);
		}
	}

	proj.PlaySound(SoundType_Fire);
}

public void OnVPhysicsUpdate(int entity)
{
	RF2_Projectile_Base proj = RF2_Projectile_Base(entity);
	proj.LastVPhysicsUpdate = GetGameTime();
	if (!IsValidEntity2(proj.Thruster) && proj.Flying)
	{
		static char name[32];
		FormatEx(name, sizeof(name), "rf2proj_%i", proj.index);
		proj.SetPropString(Prop_Data, "m_iName", name);
		proj.Thruster = CreateEntityByName("phys_thruster");
		DispatchKeyValueInt(proj.Thruster, "spawnflags", 51);
		DispatchKeyValue(proj.Thruster, "attach1", name);
		DispatchKeyValue(proj.Thruster, "force", "800");
		DispatchKeyValueVector(proj.Thruster, "angles", {-90.0, 0.0, 0.0});
		DispatchSpawn(proj.Thruster);
		ActivateEntity(proj.Thruster);
		AcceptEntityInput(proj.Thruster, "Activate");
	}

	if (!proj.HasHit)
	{
		float pos[3], mins[3], maxs[3];
		proj.GetAbsOrigin(pos);
		proj.GetHitboxMins(mins);
		proj.GetHitboxMaxs(maxs);
		TR_TraceHullFilter(pos, pos, mins, maxs, MASK_PLAYERSOLID|MASK_NPCSOLID, TraceFilter_Projectile, proj, TRACE_ENTITIES_ONLY);
		int hitEntity = TR_GetEntityIndex();
		if (hitEntity <= 0)
		{
			TR_TraceHullFilter(pos, pos, mins, maxs, MASK_PLAYERSOLID|MASK_NPCSOLID, TraceFilter_DispenserShield, _, TRACE_ENTITIES_ONLY);
			hitEntity = TR_GetEntityIndex();
		}
		
		if (hitEntity > 0)
		{
			// the dhook doesn't seem to work properly on players/npcs, so pretend we're colliding with them
			if (proj.OnCollide && !proj.HasHit && (!proj.IgnoredEnts || !proj.IsEntIgnored(hitEntity)))
			{
				Call_StartForward(proj.OnCollide);
				Call_PushCell(proj);
				Call_PushCell(hitEntity);
				Call_Finish();
			}
		}
	}
	
	if (proj.Homing)
	{
		if (!IsValidEntity2(proj.HomingTarget) || !IsLOSClear(proj.index, proj.HomingTarget) || IsValidClient(proj.HomingTarget) && !IsPlayerAlive(proj.HomingTarget))
		{
			proj.SelectHomingTarget();
		}
		
		if (IsValidEntity2(proj.HomingTarget) && IsLOSClear(proj.index, proj.HomingTarget) && (!IsValidClient(proj.HomingTarget) || IsPlayerAlive(proj.HomingTarget)))
		{
			proj.LastHomingTime = GetGameTime();
			float ang[3], myPos[3], targetPos[3], vel[3];
			proj.WorldSpaceCenter(myPos);
			CBaseEntity(proj.HomingTarget).WorldSpaceCenter(targetPos);
			GetVectorAnglesTwoPoints(myPos, targetPos, ang);
			GetAngleVectors(ang, vel, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(vel, vel);
			ScaleVector(vel, proj.HomingSpeed);
			proj.SetAbsAngles(ang);
			SDK_ApplyAbsVelocityImpulse(proj.index, vel);
		}
		else if (GetGameTime() > proj.LastHomingTime+5.0)
		{
			proj.Deactivate();
			proj.Flying = false;
		}
	}
}

static Action Timer_CheckVPhysicsUpdate(Handle timer, int entity)
{
	RF2_Projectile_Base proj = RF2_Projectile_Base(EntRefToEntIndex(entity));
	if (!proj.IsValid() || proj.HasHit)
		return Plugin_Stop;
	
	if (GetGameTime() > proj.LastVPhysicsUpdate+8.0)
	{
		proj.Deactivate();
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public MRESReturn DHook_ProjectileCollision(int entity, DHookParam params)
{
	RF2_Projectile_Base proj = RF2_Projectile_Base(entity);
	if (!proj.HasHit)
	{
		int hitEntity = params.GetObjectVar(2, 108, ObjectValueType_CBaseEntityPtr);
		if (hitEntity >= 0 && !RF2_Projectile_Base(hitEntity).IsValid() && (!proj.IgnoredEnts || !proj.IsEntIgnored(hitEntity)))
		{
			Call_StartForward(proj.OnCollide);
			Call_PushCell(proj);
			Call_PushCell(hitEntity);
			Call_Finish();
		}
	}
	
	return MRES_Ignored;
}

public void Projectile_OnCollide(RF2_Projectile_Base proj, int other)
{
	proj.ImpactTarget = other;
	if (!proj.HasHit && (!proj.IgnoredEnts || !proj.IsEntIgnored(other)))
	{
		if (IsValidClient(other) || IsNPC(other))
		{
			proj.PlaySound(SoundType_CharImpact);
		}
		else
		{
			proj.PlaySound(SoundType_WorldImpact);
		}
		
		if (IsCombatChar(other) && !RF2_DispenserShield(other).IsValid())
		{
			// hit character/building
			proj.HasHit = true;
			if (proj.RemoveOnHit)
			{
				proj.Remove();
			}
		}
		else 
		{
			// hit world or shield
			if (RF2_DispenserShield(other).IsValid())
			{
				proj.Remove();
			}
			else if (proj.DeactivateOnHit)
			{
				proj.Deactivate();
			}
		}
	}
}

public bool TraceFilter_Projectile(int entity, int mask, RF2_Projectile_Base self)
{
	if (entity == self.index || !IsValidClient(entity) && !IsNPC(entity))
		return false;
	
	if (self.Team == GetEntTeam(entity) || self.Owner == entity)
		return false;
	
	if (RF2_DispenserShield(entity).IsValid())
	{
		return true;
	}

	return true;
}
