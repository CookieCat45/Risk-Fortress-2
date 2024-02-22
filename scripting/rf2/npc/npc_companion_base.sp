#pragma newdecls required
#pragma semicolon 1

static CEntityFactory g_Factory;
typedef OnStateChangeCallback = function void (RF2_Companion_Base npc, CompanionState oldState, CompanionState newState);
enum AIType
{
	AI_CHASER, 			// Chase target
	AI_PROTECTOR,		// Follow leader, attack targets close to leader
	AI_HEALER,			// Follow leader, heal them
	AI_RANGER,			// Follow leader, attack enemies from a distance
	AI_CUSTOM,			// Don't use an AI preset
};

enum CompanionState
{
	STATE_NONE,				// Null state
	STATE_IDLE,				// Standing around
	STATE_MOVING,			// Moving around
	STATE_HEALING_ALLY,		// Healing an ally
	STATE_ATTACK_MELEE,		// Melee attack
	STATE_ATTACK_RANGED,	// Ranged attack
	STATE_ATTACK_CUSTOM,	// Custom attack
	STATE_ATTACK_ENDING,	// An attack just ended
};

enum CompanionSoundType
{
	SOUND_IDLE,
	SOUND_ATTACK_MELEE,
}

methodmap RF2_Companion_Base < RF2_NPC_Base
{
	public RF2_Companion_Base(int entity)
	{
		return view_as<RF2_Companion_Base>(entity);
	}
	
	public bool IsValid()
	{
		if (!IsValidEntity2(this.index))
		{
			return false;
		}
		
		static char classname[128];
		this.GetClassname(classname, sizeof(classname));
		return StrContains(classname, "rf2_npc_companion") != -1;
	}
	
	public static void Init()
	{
		g_Factory = new CEntityFactory("rf2_npc_companion", OnCreate, OnRemove);
		g_Factory.IsAbstract = true;
		g_Factory.DeriveFromFactory(GetBaseNPCFactory());
		g_Factory.SetInitialActionFactory(RF2_CompanionMainAction.GetFactory());
		g_Factory.BeginDataMapDesc()
			.DefineEntityField("m_hLeader")
			.DefineIntField("m_iBaseHealth")
			.DefineIntField("m_iAIType")
			.DefineIntField("m_iLevel")
			.DefineIntField("m_iState")
			.DefineIntField("m_OnStateChanged")
			.DefineFloatField("m_flMeleeDamage")
			.DefineIntField("m_iMeleeDamageType")
			.DefineFloatField("m_flAttackRange")
			.DefineFloatField("m_flAttackDelay")
			.DefineFloatField("m_flAttackDuration")
			.DefineVectorField("m_vecMeleeAttackMins")
			.DefineVectorField("m_vecMeleeAttackMaxs")
			.DefineVectorField("m_vecMeleeAttackOffset")
			.DefineVectorField("m_vecMeleeDamageForce")
			.DefineIntField("m_iIdleSequence")
			.DefineIntField("m_iRunSequence")
			.DefineIntField("m_iMeleeGesture")
			.DefineIntField("m_iMoveXPoseParam")
			.DefineIntField("m_iMoveYPoseParam")
		.EndDataMapDesc();
		g_Factory.Install();
		HookMapStart(BaseNPC_OnMapStart);
	}
	
	public static CEntityFactory GetFactory()
	{
		return g_Factory;
	}

	property AIType Behavior
	{
		public get()
		{
			return view_as<AIType>(this.GetProp(Prop_Data, "m_iAIType"));
		}
		
		public set(AIType value)
		{
			this.SetProp(Prop_Data, "m_iAIType", value);
		}
	}
	
	property int Leader
	{
		public get()
		{
			return this.GetPropEnt(Prop_Data, "m_hLeader");
		}
		
		public set(int value)
		{
			this.SetPropEnt(Prop_Data, "m_hLeader", value);
		}
	}
	
	property int Level
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iLevel");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iLevel", value);
		}
	}
	
	property CompanionState State
	{
		public get()
		{
			return view_as<CompanionState>(this.GetProp(Prop_Data, "m_iState"));
		}
		
		public set(CompanionState value)
		{
			CompanionState oldState = this.State;
			this.SetProp(Prop_Data, "m_iState", value);
			if (this.OnStateChange && oldState != value)
			{
				Call_StartForward(this.OnStateChange);
				Call_PushCell(this);
				Call_PushCell(oldState);
				Call_PushCell(value);
				Call_Finish();
			}
		}
	}
	
	property PrivateForward OnStateChange
	{
		public get()
		{
			return view_as<PrivateForward>(this.GetProp(Prop_Data, "m_OnStateChanged"));
		}
		
		public set(PrivateForward value)
		{
			this.SetProp(Prop_Data, "m_OnStateChanged", value);
		}
	}
	
	property int BaseHealth
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iBaseHealth");
		}

		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iBaseHealth", value);
		}
	}
	
	property float AttackRange
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flAttackRange");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flAttackRange", value);
		}
	}
	
	property float AttackDelay
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flAttackDelay");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flAttackDelay", value);
		}
	}

	property float AttackDuration
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flAttackDuration");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flAttackDuration", value);
		}
	}

	property float MeleeDamage
	{
		public get()
		{
			return this.GetPropFloat(Prop_Data, "m_flMeleeDamage");
		}
		
		public set(float value)
		{
			this.SetPropFloat(Prop_Data, "m_flMeleeDamage", value);
		}
	}
	
	property int MeleeDamageType
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iMeleeDamageType");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iMeleeDamageType", value);
		}
	}

	property int IdleSequence
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iIdleSequence");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iIdleSequence", value);
		}
	}

	property int RunSequence
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iRunSequence");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iRunSequence", value);
		}
	}

	property int MeleeGesture
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iMeleeGesture");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iMeleeGesture", value);
		}
	}
	
	property int MoveX
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iMoveXPoseParam");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iMoveXPoseParam", value);
		}
	}
	
	property int MoveY
	{
		public get()
		{
			return this.GetProp(Prop_Data, "m_iMoveYPoseParam");
		}
		
		public set(int value)
		{
			this.SetProp(Prop_Data, "m_iMoveYPoseParam", value);
		}
	}
	
	public void GetMeleeMins(float buffer[3])
	{
		this.GetPropVector(Prop_Data, "m_vecMeleeAttackMins", buffer);
	}
	
	public void GetMeleeMaxs(float buffer[3])
	{
		this.GetPropVector(Prop_Data, "m_vecMeleeAttackMaxs", buffer);
	}
	
	public void SetMeleeMins(const float vec[3])
	{
		this.SetPropVector(Prop_Data, "m_vecMeleeAttackMins", vec);
	}
	
	public void SetMeleeMaxs(const float vec[3])
	{
		this.SetPropVector(Prop_Data, "m_vecMeleeAttackMaxs", vec);
	}
	
	public void GetMeleeOffset(float buffer[3])
	{
		this.GetPropVector(Prop_Data, "m_vecMeleeAttackOffset", buffer);
	}
	
	public void SetMeleeOffset(const float vec[3])
	{
		this.SetPropVector(Prop_Data, "m_vecMeleeAttackOffset", vec);
	}

	public void GetMeleeForce(float buffer[3])
	{
		this.GetPropVector(Prop_Data, "m_vecMeleeDamageForce", buffer);
	}
	
	public void SetMeleeForce(const float vec[3])
	{
		this.SetPropVector(Prop_Data, "m_vecMeleeDamageForce", vec);
	}
	
	public int GetMyLeader()
	{
		if (IsValidClient(this.Leader) && IsPlayerAlive(this.Leader) && this.Team == CBaseEntity(this.Leader).GetProp(Prop_Data, "m_iTeamNum"))
		{
			return this.Leader;
		}
		
		return INVALID_ENT;
	}
	
	public void HookStateChange(OnStateChangeCallback func)
	{
		this.OnStateChange.AddFunction(INVALID_HANDLE, func);
	}
	
	public bool IsAttacking()
	{
		CompanionState state = this.State;
		return state == STATE_ATTACK_MELEE || state == STATE_ATTACK_RANGED || state == STATE_ATTACK_CUSTOM;
	}
}

#include "rf2/npc/actions/companions/main.sp"
#include "rf2/npc/actions/companions/chaser.sp"
#include "rf2/npc/actions/companions/attack_melee.sp"
#include "rf2/npc/companions/npc_companion_heavybot.sp"

static void OnCreate(RF2_Companion_Base npc)
{
	npc.Leader = INVALID_ENT;
	npc.BaseNpc.flWalkSpeed = 200.0;
	npc.BaseNpc.flRunSpeed = 200.0;
	npc.BaseNpc.flGravity = 800.0;
	npc.BaseNpc.flAcceleration = 2000.0;
	npc.BaseNpc.flJumpHeight = 50.0;
	npc.BaseNpc.flDeathDropHeight = 99999.0;
	npc.Level = 1;
	npc.BaseHealth = 500;
	
	npc.MeleeDamage = 65.0;
	npc.MeleeDamageType = DMG_MELEE|DMG_CLUB|DMG_PREVENT_PHYSICS_FORCE;
	npc.AttackRange = 250.0;
	npc.AttackDelay = 0.3;
	npc.AttackDuration = 0.9;
	npc.SetMeleeMins({-50.0, -50.0, -50.0});
	npc.SetMeleeMaxs({50.0, 50.0, 50.0});
	npc.SetMeleeOffset({25.0, 0.0, 25.0});
	npc.SetMeleeForce({250.0, 0.0, 250.0});
	
	npc.IdleSequence = -1;
	npc.RunSequence = -1;
	npc.MeleeGesture = -1;
	npc.MoveX = -1;
	npc.MoveY = -1;
	npc.Path = PathFollower(_, FilterIgnoreActors, FilterOnlyActors);
	npc.OnStateChange = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	npc.HookStateChange(OnStateChanged);
	SDKHook(npc.index, SDKHook_Think, CompanionThink);
}

static void OnRemove(RF2_Companion_Base npc)
{
	RequestFrame(RF_DeleteForward, npc.OnStateChange);
}

static void RF_DeleteForward(PrivateForward fwd)
{
	delete fwd;
}

static void CompanionThink(int entity)
{
	RF2_Companion_Base npc = RF2_Companion_Base(entity);
	
	// Determine our state
	if (!npc.IsAttacking() && npc.State != STATE_HEALING_ALLY)
	{
		CompanionState newState;
		if (npc.BaseNpc.GetLocomotion().GetGroundSpeed() > 0.0)
		{
			newState = STATE_MOVING;
		}
		else
		{
			newState = STATE_IDLE;
		}
		
		if (newState != STATE_NONE)
		{
			npc.State = newState;
		}
	}
	
	if ((npc.MoveX > -1 || npc.MoveY > -1) && npc.Locomotion.IsAttemptingToMove())
	{
		float fwd[3], right[3], motion[3];
		npc.GetVectors(fwd, right, NULL_VECTOR);
		npc.Locomotion.GetGroundMotionVector(motion);
		
		if (npc.MoveX > -1)
		{
			npc.SetPoseParameter(npc.MoveX, GetVectorDotProduct(motion, fwd));
		}
		
		if (npc.MoveY > -1)
		{
			npc.SetPoseParameter(npc.MoveY, GetVectorDotProduct(motion, right));
		}
	}
}

static void OnStateChanged(RF2_Companion_Base npc, CompanionState oldState, CompanionState newState)
{
	if (oldState != STATE_ATTACK_ENDING)
	{
		// Determine animation
		switch (newState)
		{
			case STATE_IDLE:
			{
				if (npc.IdleSequence > -1)
					npc.ResetSequence(npc.IdleSequence);
			}
			
			case STATE_MOVING, STATE_HEALING_ALLY:
			{
				if (npc.RunSequence > -1)
				{
					npc.ResetSequence(npc.RunSequence);
				}
			}
			
			case STATE_ATTACK_MELEE:
			{
				if (npc.MeleeGesture > -1 && !npc.IsPlayingGestureByIndex(npc.MeleeGesture))
				{
					npc.AddGestureByIndex(npc.MeleeGesture);
				}
			}
		}
	}
}

static bool FilterIgnoreActors(int entity, int contentsMask, int desiredcollisiongroup)
{
	if ((entity > 0 && entity <= MaxClients) || !IsCombatChar(entity))
	{
		return false;
	}
	
	return true;
}

static bool FilterOnlyActors(int entity, int contentsMask, int desiredcollisiongroup)
{
	return ((entity > 0 && entity <= MaxClients) || IsCombatChar(entity));
}
