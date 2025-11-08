#pragma newdecls required
#pragma semicolon 1

#define MODEL_MAJORSHOCKS "models/rf2/bosses/major_shocks.mdl"
#define SND_MAJORSHOCKS_STEP "MVM.GiantSoldierStep"
#define SND_MAJORSHOCKS_DEATHSCREAM "vo/mvm/mght/soldier_mvm_m_paincrticialdeath01.mp3"
#define SND_MAJORSHOCKS_DEATHEXPLOSION "ambient/explosions/explode_1.wav"
#define SND_MAJORSHOCKS_DEATHEXPLOSION_2 "mvm/mvm_tank_end.wav"
#define SND_MAJORSHOCKS_DEATHEXPLOSION_3 "mvm/mvm_tank_explode.wav"
#define SND_MAJORSHOCKS_DEATHEXPLOSION_4 "npc/turret_floor/die.wav"
#define SND_MAJORSHOCKS_VORTEXSTART "ambient/halloween/windgust_10.wav"
#define SND_MAJORSHOCKS_VORTEXEND "ambient/halloween/thunder_01.wav"
#define SND_MAJORSHOCKS_RELOAD1 "weapons/rocket_reload.wav"
#define SND_MAJORSHOCKS_RELOAD2 "weapons/bison_reload.wav"
#define SND_GENERATOR_SPAWN "ui/rd_2base_alarm.wav"

char g_MajorShocksWeaponModels[][] =
{
	"models/weapons/c_models/c_directhit/c_directhit.mdl",
	"models/weapons/c_models/c_rocketlauncher/c_rocketlauncher.mdl",
	"models/weapons/c_models/c_blackbox/c_blackbox.mdl",
	"models/weapons/c_models/c_liberty_launcher/c_liberty_launcher.mdl",
	"models/weapons/c_models/c_pickaxe/c_pickaxe.mdl",
	"models/workshop/weapons/c_models/c_drg_righteousbison/c_drg_righteousbison.mdl"
};

char g_MajorShocksWeaponShootSounds[][] =
{
	")weapons/rocket_directhit_shoot.wav",
	")mvm/giant_soldier/giant_soldier_rocket_shoot.wav",
	")weapons/rocket_blackbox_shoot.wav",
	")weapons/rocket_ll_shoot.wav",
	")weapons/pickaxe_swing.wav",
	")weapons/bison_main_shot_01.wav"
};

char g_MajorShocksWeaponShootCritSounds[][] =
{
	")weapons/rocket_directhit_shoot_crit.wav",
	")mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav",
	")weapons/rocket_blackbox_shoot_crit.wav",
	")weapons/rocket_ll_shoot_crit.wav",
	")weapons/pickaxe_swing_crit.wav",
	")weapons/bison_main_shot_crit.wav"
};

char g_MajorShocksEscapePlanHit[][] =
{
	")weapons/blade_slice_2.wav",
	")weapons/blade_slice_3.wav",
	")weapons/blade_slice_4.wav"
};

enum MajorShocks_WeaponState
{
	MajorShocks_WeaponState_Primary = 0,
	MajorShocks_WeaponState_Secondary,
	MajorShocks_WeaponState_Melee
}

enum MajorShocks_Phase
{
	MajorShocks_Phase_Intro,
	MajorShocks_Phase_Uber,
	MajorShocks_Phase_Final
}

enum MajorShocks_WeaponType
{
	MajorShocks_WeaponType_Invalid = -1,
	MajorShocks_WeaponType_BurstFire = 0,
	MajorShocks_WeaponType_Barrage,
	MajorShocks_WeaponType_Multi,
	MajorShocks_WeaponType_Homing,
	MajorShocks_WeaponType_Nuke,
	MajorShocks_WeaponType_GroundSlam = 5,
	MajorShocks_WeaponType_Vortex,
	MajorShocks_WeaponType_GigaBurstFire,
	MajorShocks_WeaponType_GigaBarrage,
	MajorShocks_WeaponType_GigaMulti,
	MajorShocks_WeaponType_GigaHoming = 10,
	MajorShocks_WeaponType_GigaNuke,
	MajorShocks_WeaponType_GigaBison,
	MajorShocks_WeaponType_GigaMelee,
	MajorShocks_WeaponType_GigaGroundSlam,
	MajorShocks_WeaponType_GigaVortex = 15
}

#include "actions/major_shocks/main.sp"
#include "actions/major_shocks/chaselayer.sp"
#include "actions/major_shocks/death.sp"
#include "actions/major_shocks/ground_slam.sp"
#include "actions/major_shocks/vortex.sp"
#include "actions/major_shocks/weaponstate.sp"

static CEntityFactory g_Factory;

methodmap RF2_MajorShocks < RF2_NPC_Base
{
	public RF2_MajorShocks(int entity)
	{
		return view_as<RF2_MajorShocks>(entity);
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
		g_Factory = new CEntityFactory("rf2_npc_major_shocks", OnCreate, OnRemove);
		g_Factory.DeriveFromFactory(GetBaseNPCFactory());
		g_Factory.SetInitialActionFactory(RF2_MajorShocksMainAction.GetFactory());
		g_Factory.BeginDataMapDesc()
			.DefineBoolField("m_LockAnimations")
			.DefineIntField("m_CurrentLayer")
			.DefineEntityField("m_Item")
			.DefineEntityField("m_CritEffect")
			.DefineIntField("m_WeaponSlot")
			.DefineFloatField("m_ReloadRate")
			.DefineFloatField("m_ReloadTime")
			.DefineFloatField("m_FireRate")
			.DefineFloatField("m_FireTime")
			.DefineIntField("m_MaxClipSize")
			.DefineIntField("m_ClipSize")
			.DefineFloatField("m_Deviation")
			.DefineFloatField("m_ProjectileSpeed")
			.DefineFloatField("m_Damage")
			.DefineFloatField("m_BlastRadius")
			.DefineBoolField("m_IsCrits")
			.DefineBoolField("m_IsReloading")
			.DefineBoolField("m_HoldUntilFullReload")
			.DefineBoolField("m_RainbowLasers")
			.DefineFloatField("m_SwitchTargetTime")
			.DefineIntField("m_WeaponState")
			.DefineIntField("m_Phase")
			.DefineIntField("m_WeaponType")
			.DefineIntField("m_ShouldSlowDown")
			.DefineIntField("m_WasSlowedDown")
			.DefineIntField("m_UpdatedAnimation")
			.DefineIntField("m_Generators")
		.EndDataMapDesc();
		g_Factory.Install();
		HookMapStart(MajorShocks_OnMapStart);
	}

	property bool LockAnimations
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_LockAnimations") != 0;
		}

		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_LockAnimations", value);
		}
	}
	
	property int CurrentLayer
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_CurrentLayer") != 0;
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_CurrentLayer", value);
		}
	}
	
	property ArrayList Generators
	{
		public get()
        {
            return view_as<ArrayList>(this.GetProp(Prop_Data, "m_Generators"));
        }
        
        public set(ArrayList list)
        {
            this.SetProp(Prop_Data, "m_Generators", list);
        }
	}

	property CBaseAnimating Item
	{
		public get()
		{
			return CBaseAnimating(EntRefToEntIndex(this.GetPropEnt(Prop_Data, "m_Item")));
		}

		public set(CBaseAnimating value)
		{
			this.SetPropEnt(Prop_Data, "m_Item", value.index);
		}
	}

	property CBaseEntity CritEffect
	{
		public get()
		{
			return CBaseEntity(EntRefToEntIndex(this.GetPropEnt(Prop_Data, "m_CritEffect")));
		}

		public set(CBaseEntity value)
		{
			this.SetPropEnt(Prop_Data, "m_CritEffect", value.index);
		}
	}

	property int WeaponSlot
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_WeaponSlot") != 0;
		}

		public set(int value)
		{
			this.SetProp(Prop_Data, "m_WeaponSlot", value);
		}
	}

	property float ReloadRate
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_ReloadRate");
		}

		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_ReloadRate", value);
		}
	}

	property float ReloadTime
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_ReloadTime");
		}

		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_ReloadTime", value);
		}
	}

	property float FireRate
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_FireRate");
		}

		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_FireRate", value);
		}
	}

	property float FireTime
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_FireTime");
		}

		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_FireTime", value);
		}
	}

	property int MaxClipSize
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_MaxClipSize");
		}

		public set(int value)
		{
			this.SetProp(Prop_Data, "m_MaxClipSize", value);
		}
	}

	property int ClipSize
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_ClipSize");
		}

		public set(int value)
		{
			this.SetProp(Prop_Data, "m_ClipSize", value);
		}
	}

	property float Deviation
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_Deviation");
		}

		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_Deviation", value);
		}
	}

	property float ProjectileSpeed
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_ProjectileSpeed");
		}

		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_ProjectileSpeed", value);
		}
	}

	property float Damage
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_Damage");
		}

		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_Damage", value);
		}
	}

	property float BlastRadius
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_BlastRadius");
		}

		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_BlastRadius", value);
		}
	}

	property bool IsCrits
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_IsCrits") != 0;
		}

		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_IsCrits", value);
		}
	}

	property bool IsReloading
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_IsReloading") != 0;
		}

		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_IsReloading", value);
		}
	}

	property bool HoldUntilFullReload
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_HoldUntilFullReload") != 0;
		}

		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_HoldUntilFullReload", value);
		}
	}
	
	property bool RainbowLasers
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_RainbowLasers") != 0;
		}

		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_RainbowLasers", value);
		}
	}

	property float SwitchTargetTime
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_SwitchTargetTime");
		}

		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_SwitchTargetTime", value);
		}
	}

	property MajorShocks_WeaponState WeaponState
	{
		public get()
		{
			return view_as<MajorShocks_WeaponState>(this.GetProp(Prop_Data, "m_WeaponState"));
		}

		public set(MajorShocks_WeaponState value)
		{
			this.SetProp(Prop_Data, "m_WeaponState", value);
		}
	}

	property MajorShocks_Phase Phase
	{
		public get()
		{
			return view_as<MajorShocks_Phase>(this.GetProp(Prop_Data, "m_Phase"));
		}

		public set(MajorShocks_Phase value)
		{
			this.SetProp(Prop_Data, "m_Phase", value);
			if (value == MajorShocks_Phase_Uber)
			{
				this.SetProp(Prop_Send, "m_nSkin", 3);
			}
			else
			{
				this.SetProp(Prop_Send, "m_nSkin", 1);
			}
		}
	}

	property MajorShocks_WeaponType WeaponType
	{
		public get()
		{
			return view_as<MajorShocks_WeaponType>(this.GetProp(Prop_Data, "m_WeaponType"));
		}

		public set(MajorShocks_WeaponType value)
		{
			this.SetProp(Prop_Data, "m_WeaponType", value);
		}
	}

	property bool ShouldSlowDown
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_ShouldSlowDown") != 0;
		}

		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_ShouldSlowDown", value);
		}
	}

	property bool WasSlowedDown
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_WasSlowedDown") != 0;
		}

		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_WasSlowedDown", value);
		}
	}

	property bool UpdatedAnimation
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_UpdatedAnimation") != 0;
		}

		public set(bool value)
		{
			this.SetProp(Prop_Data, "m_UpdatedAnimation", value);
		}
	}

	public void EquipItem(const char[] model)
	{
		if (this.Item.index && this.Item.index != INVALID_ENT_REFERENCE)
		{
			RemoveEntity(this.Item.index);
		}

		if (this.CritEffect.IsValid())
		{
			this.CritEffect.AcceptInput("stop");
		}
		
		CBaseAnimating item = CBaseAnimating(CreateEntityByName("prop_dynamic"));
		item.KeyValue("model", model);
		float pos[3];
		this.GetAbsOrigin(pos);
		item.Teleport(pos);
		item.Spawn();
		item.SetProp(Prop_Send, "m_nSkin", 1);
		item.SetProp(Prop_Send, "m_fEffects", EF_BONEMERGE|EF_PARENT_ANIMATES);
		SetVariantString("!activator");
		item.AcceptInput("SetParent", this.index);
		SetVariantString("head");
		item.AcceptInput("SetParentAttachmentMaintainOffset");
		item.AcceptInput("DisableCollision");
		if (this.IsCrits)
		{
			item.SetRenderMode(RENDER_GLOW);
			item.SetRenderColor(0, 255, 255);
			TE_TFParticle("critgun_weaponmodel_blu", pos, item.index, PATTACH_ABSORIGIN_FOLLOW);
		}

		this.Item = item;
	}

	public void RemoveItem()
	{
		if (this.Item.index && this.Item.index != INVALID_ENT_REFERENCE)
		{
			RemoveEntity(this.Item.index);
			this.Item = CBaseAnimating(INVALID_ENT_REFERENCE);
		}
	}

	public void UpdateAnimation()
	{
		if (this.LockAnimations)
			return;

		Activity activity;
		if (this.BaseNpc.flRunSpeed <= 25.0 || !this.Locomotion.IsAttemptingToMove())
		{
			switch (this.WeaponState)
			{
				case MajorShocks_WeaponState_Primary: activity = ACT_MP_STAND_PRIMARY;
				case MajorShocks_WeaponState_Secondary: activity = ACT_MP_STAND_SECONDARY2;
				case MajorShocks_WeaponState_Melee: activity = ACT_MP_STAND_MELEE;
			}
		}
		else
		{
			switch (this.WeaponState)
			{
				case MajorShocks_WeaponState_Primary: activity = ACT_MP_RUN_PRIMARY;
				case MajorShocks_WeaponState_Secondary: activity = ACT_MP_RUN_SECONDARY2;
				case MajorShocks_WeaponState_Melee: activity = ACT_MP_RUN_MELEE;
			}
		}

		if ((this.GetFlags() & FL_ONGROUND) == 0)
		{
			switch (this.WeaponState)
			{
				case MajorShocks_WeaponState_Primary: activity = ACT_MP_JUMP_FLOAT_PRIMARY;
				case MajorShocks_WeaponState_Secondary: activity = ACT_MP_JUMP_FLOAT_SECONDARY2;
				case MajorShocks_WeaponState_Melee: activity = ACT_MP_JUMP_FLOAT_MELEE;
			}
		}

		this.ResetSequence(this.SelectWeightedSequence(activity));
		this.SetProp(Prop_Data, "m_bSequenceLoops", true);
	}

	public void UpdatePoseParameters()
	{
		if (this.LockAnimations)
			return;

		if (this.Locomotion.IsAttemptingToMove())
		{
			float speed = this.Locomotion.GetGroundSpeed();
			if (speed < 0.01)
			{
				this.SetPoseParameter(this.LookupPoseParameter("move_x"), 0.0);
				this.SetPoseParameter(this.LookupPoseParameter("move_y"), 0.0);
			}
			else
			{
				float forwardVector[3], rightVector[3], motionVector[3];
				this.GetVectors(forwardVector, rightVector, NULL_VECTOR);
				this.Locomotion.GetGroundMotionVector(motionVector);
				this.SetPoseParameter(this.LookupPoseParameter("move_x"), GetVectorDotProduct(motionVector, forwardVector));
				this.SetPoseParameter(this.LookupPoseParameter("move_y"), GetVectorDotProduct(motionVector, rightVector));
				float groundSpeed = this.GetPropFloat(Prop_Data, "m_flGroundSpeed");
				if (groundSpeed != 0.0 && this.Locomotion.IsOnGround() && speed > groundSpeed)
				{
					float rate = fclamp((speed / groundSpeed), 0.0, 12.0);
					this.SetPropFloat(Prop_Send, "m_flPlaybackRate", rate);
				}
				else
				{
					this.SetPropFloat(Prop_Send, "m_flPlaybackRate", 1.0);
				}
			}
		}

		float dir[3], ang[3], npcCenter[3], lookPos[3], myAng[3];
		this.GetAbsAngles(myAng);
		this.WorldSpaceCenter(npcCenter);
		CBaseEntity target = CBaseEntity(this.Target);
		if (!target.IsValid())
			return;
		
		if (IsValidClient(target.index))
		{
			GetClientEyePosition(target.index, lookPos);
		}
		else
		{
			target.WorldSpaceCenter(lookPos);
		}
		
		lookPos[2] -= 40.0;
		SubtractVectors(npcCenter, lookPos, dir);
		NormalizeVector(dir, dir);
		GetVectorAngles(dir, ang);
		int pitchPose = this.LookupPoseParameter("body_pitch");
		int yawPose = this.LookupPoseParameter("body_yaw");
		float pitchValue = this.GetPoseParameter(pitchPose);
		float yawValue = this.GetPoseParameter(yawPose);
		
		CBaseNPC npc = this.BaseNpc;
		ang[0] = UTIL_Clamp(UTIL_AngleNormalize(ang[0]), -44.0, 89.0);
		this.SetPoseParameter(pitchPose, UTIL_ApproachAngle(
			(this.HasLOSTo(target)) ? ang[0] : 0.0, pitchValue,
			(npc.flMaxYawRate / 2000.0) * 12.0));
		
		ang[1] = UTIL_Clamp(-UTIL_AngleNormalize(UTIL_AngleDiff(UTIL_AngleNormalize(ang[1]), UTIL_AngleNormalize(myAng[1] + 180.0))), -44.0,  44.0);
		this.SetPoseParameter(yawPose, UTIL_ApproachAngle(
			(this.HasLOSTo(target)) ? ang[1] : 0.0, yawValue,
			(npc.flMaxYawRate / 2000.0) * 12.0));
	}

	public void PlayLandAnimation()
	{
		if (this.LockAnimations)
			return;

		Activity activity;
		switch (this.WeaponState)
		{
			case MajorShocks_WeaponState_Primary: activity = ACT_MP_JUMP_LAND_PRIMARY;
			case MajorShocks_WeaponState_Secondary: activity = ACT_MP_JUMP_LAND_SECONDARY2;
			case MajorShocks_WeaponState_Melee: activity = ACT_MP_JUMP_LAND_MELEE;
		}

		int layer = this.AddLayeredSequence(this.SelectWeightedSequence(activity), 1);
		this.SetLayerAutokill(layer, true);
	}

	public void PlayJumpAnimation()
	{
		if (this.LockAnimations)
			return;

		Activity activity;
		switch (this.WeaponState)
		{
			case MajorShocks_WeaponState_Primary: activity = ACT_MP_JUMP_START_PRIMARY;
			case MajorShocks_WeaponState_Secondary: activity = ACT_MP_JUMP_START_SECONDARY2;
			case MajorShocks_WeaponState_Melee:activity = ACT_MP_JUMP_START_MELEE;
		}

		this.ResetSequence(this.SelectWeightedSequence(activity));
	}

	public void EmitSpecialAttackQuote()
	{
		char sound[PLATFORM_MAX_PATH];
		int value = GetRandomInt(1, 21);
		FormatEx(sound, sizeof(sound), ")vo/mvm/mght/taunts/soldier_mvm_m_taunts%s%i.mp3", value < 10 ? "0" : "", value + 1);
		EmitSoundToAll(sound, this.index, _, 150);
		EmitSoundToAll(sound, this.index, _, 150);
	}

	public void DoShake()
	{
		float pos[3];
		this.WorldSpaceCenter(pos);
		UTIL_ScreenShake(pos, 8.0, 9.0, 1.0, 999999999999.9, SHAKE_START, true);
	}
	
	public void DoSecondPhase()
	{
		this.Phase = MajorShocks_Phase_Uber;
		this.DoUnstuckChecks = false;
		char name[32];
		int entity = INVALID_ENT;
		RF2_MajorShocksUberGenerator amp;
		while ((entity = FindEntityByClassname(entity, "info_target")) != INVALID_ENT)
        {
            GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
            if (strcmp2(name, "spawnbot_emp"))
            {
				float pos[3];
				GetEntPos(entity, pos);
				amp = RF2_MajorShocksUberGenerator(CreateEntityByName("rf2_npc_uber_generator"));
				amp.Boss = this;
				this.Generators.Push(EntIndexToEntRef(amp.index));
				amp.Teleport(pos);
				amp.Spawn();
				TE_TFParticle("eyeboss_tp_player", pos);
			}
		}
		
		int relay = FindEntityByName("boss_secondphase");
		if (relay != INVALID_ENT)
		{
			AcceptEntityInput(relay, "Trigger");
		}
		
		float pos[3];
		amp.WorldSpaceCenter(pos);
		EmitSoundToAll(SND_MEDSHIELD_DEPLOY, this.index, _, 80);
		CreateTimer(0.1, Timer_UpdateGeneratorBeams, EntIndexToEntRef(this.index), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	public void DoFinalPhase()
	{
		this.Phase = MajorShocks_Phase_Final;
		this.DoUnstuckChecks = true;
		int relay = FindEntityByName("boss_thirdphase");
		if (relay != INVALID_ENT)
		{
			AcceptEntityInput(relay, "Trigger");
		}
	}
}

static void MajorShocks_OnMapStart()
{
	AddModelToDownloadsTable(MODEL_MAJORSHOCKS);
	PrecacheScriptSound(SND_MAJORSHOCKS_STEP);
	PrecacheSound(SND_MAJORSHOCKS_DEATHSCREAM);
	PrecacheSound(SND_MAJORSHOCKS_DEATHEXPLOSION);
	PrecacheSound(SND_MAJORSHOCKS_DEATHEXPLOSION_2);
	PrecacheSound(SND_MAJORSHOCKS_DEATHEXPLOSION_3);
	PrecacheSound(SND_MAJORSHOCKS_DEATHEXPLOSION_4);
	PrecacheSound(SND_MAJORSHOCKS_VORTEXSTART);
	PrecacheSound(SND_MAJORSHOCKS_VORTEXEND);
	PrecacheSound(SND_MAJORSHOCKS_RELOAD1);
	PrecacheSound(SND_MAJORSHOCKS_RELOAD2);
	PrecacheSound(SND_GENERATOR_SPAWN);

	for (int i = 0; i < sizeof(g_MajorShocksWeaponModels); i++)
	{
		PrecacheModel(g_MajorShocksWeaponModels[i]);
		PrecacheSound(g_MajorShocksWeaponShootSounds[i]);
		PrecacheSound(g_MajorShocksWeaponShootCritSounds[i]);
	}

	for (int i = 0; i < sizeof(g_MajorShocksEscapePlanHit); i++)
	{
		PrecacheSound(g_MajorShocksEscapePlanHit[i]);
	}

	for (int i = 0; i < 21; i++)
	{
		char sound[PLATFORM_MAX_PATH];
		FormatEx(sound, sizeof(sound), ")vo/mvm/mght/taunts/soldier_mvm_m_taunts%s%i.mp3", i < 10 ? "0" : "", i + 1);
		PrecacheSound(sound);
	}
}

static void OnCreate(RF2_MajorShocks boss)
{
	boss.SetPropFloat(Prop_Send, "m_flModelScale", 2.5);
	boss.SetModel(MODEL_MAJORSHOCKS);
	boss.SetProp(Prop_Send, "m_nSkin", 1);
	boss.BaseNpc.SetBodyMins({-150.0, -150.0, 0.0});
	boss.BaseNpc.SetBodyMaxs({150.0, 150.0, 300.0});
	float health = 15000.0 * (1.0 + (float(RF2_GetEnemyLevel() - 1) * 0.1));
	health *= (1.0 + 0.15 * float(RF2_GetSurvivorCount() - 1));
	boss.SetProp(Prop_Data, "m_iHealth", RoundToFloor(health));
	boss.MaxHealth = RoundToFloor(health);
	boss.IsCrits = RF2_GetLoopCount() >= 1 || g_cvDebugUseAltMapSettings.BoolValue;
	RF2_Object_Teleporter.ToggleObjectsStatic(false);
	CBaseNPC npc = boss.BaseNpc;
	boss.Generators = new ArrayList();
	npc.flStepSize = 18.0;
	npc.flGravity = 800.0;
	npc.flAcceleration = 9001.0;
	npc.flMaxYawRate = 500.0;
	npc.flJumpHeight = 360.0;
	npc.flWalkSpeed = 150.0 * 0.9;
	npc.flRunSpeed = 150.0;
	npc.flDeathDropHeight = 99999999.0;
	npc.SetBodyMins(PLAYER_MINS);
	npc.SetBodyMaxs(PLAYER_MAXS);
	boss.CanBeHeadshot = true;
	boss.CanBeBackstabbed = true;
	boss.BaseBackstabDamage = 750.0;
	SDKHook(boss.index, SDKHook_SpawnPost, SpawnPost);
	SDKHook(boss.index, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(boss.index, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(boss.index, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
	boss.HealthText = CreateHealthText(boss.index, 230.0, 35.0, "Major Shocks");
	boss.HealthText.SetHealthColor(HEALTHCOLOR_HIGH, {100, 255, 255, 255});
	boss.SetGlow(true);
	boss.SetGlowColor(100, 255, 255, 255);
}

static void OnRemove(RF2_MajorShocks boss)
{
	delete boss.Generators;
    boss.Generators = null;
}

static void SpawnPost(int entity)
{
	RF2_MajorShocks boss = RF2_MajorShocks(entity);
	float mins[3] = PLAYER_MINS;
	float maxs[3] = PLAYER_MAXS;
	ScaleVector(mins, 3.0);
	ScaleVector(maxs, 3.0);
	boss.SetHitboxSize(mins, maxs);
	boss.Team = TEAM_ENEMY;
	boss.UpdateAnimation();
}

static Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
		float damageForce[3], float damagePosition[3], int damagecustom)
{
	RF2_MajorShocks actor = RF2_MajorShocks(victim);
	if (actor.Phase == MajorShocks_Phase_Uber)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

static Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon,
		float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (damagetype & DMG_CRIT)
    {
		bool backstab = IsValidClient(attacker) && IsValidEntity2(weapon) && TF2_GetPlayerClass(attacker) == TFClass_Spy
            && GetPlayerWeaponSlot(attacker, WeaponSlot_Melee) == weapon;
            
        if (!backstab)
        {
            // 50% resistance to crits
			float baseDamage = damage/3.0;
			float critDamage = damage-baseDamage;
			damage = baseDamage + (critDamage*0.5);
			return Plugin_Changed;
        }
    }
	
	return Plugin_Continue;
}

static void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon,
		const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	RF2_MajorShocks actor = RF2_MajorShocks(victim);
	int halfHealth = actor.MaxHealth/2;
	if (actor.Health <= halfHealth && actor.Phase == MajorShocks_Phase_Intro)
	{
		actor.Health = halfHealth;
		actor.DoSecondPhase();
	}
}

static Action Timer_UpdateGeneratorBeams(Handle timer, int entity)
{
    RF2_MajorShocks boss = RF2_MajorShocks(EntRefToEntIndex(entity));
    if (!boss.IsValid() || !boss.Generators || boss.Phase != MajorShocks_Phase_Uber)
        return Plugin_Stop;
    
    float pos1[3], pos2[3];
    boss.WorldSpaceCenter(pos1);
    RF2_MajorShocksUberGenerator amp;
    for (int i = 0; i < boss.Generators.Length; i++)
    {
        amp = RF2_MajorShocksUberGenerator(EntRefToEntIndex(boss.Generators.Get(i)));
        if (!amp.IsValid())
            continue;

        amp.WorldSpaceCenter(pos2);
		pos2[2] += 20.0;
        TE_SetupBeamPoints(pos2, pos1, g_iBeamModel, 0, 0, 0, 0.12, 15.0, 15.0, 0, 0.2, {0, 255, 255, 150}, 10);
        TE_SendToAll();
    }
    
    return Plugin_Continue;
}
