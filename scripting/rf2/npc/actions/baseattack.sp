#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_Factory;

methodmap RF2_BaseNPCAttackAction < NextBotAction
{
	public RF2_BaseNPCAttackAction()
	{
		if (!g_Factory)
		{
			g_Factory = new NextBotActionFactory("RF2_BaseNPCAttackAction");
			g_Factory.BeginDataMapDesc()
				.DefineFloatField("m_flStartTime")
				.DefineFloatField("m_flAttackTime")
				.DefineFloatField("m_flRecoveryTime")
				.DefineIntField("m_nHitCounter")
				.EndDataMapDesc();
		}
		
		return view_as<RF2_BaseNPCAttackAction>(g_Factory.Create());
	}
	
	// Does a trace hull hitbox attack, offset is relative to entity's origin and angles. resultPos is filled with the origin position of the attack.
	// returnArray=true returns an ArrayList of entities hit, otherwise returns null
	public ArrayList DoAttackHitbox(const float offset[3]=NULL_VECTOR, float resultPos[3]=NULL_VECTOR, const float mins[3], const float maxs[3], 
		float damage, int damageType=DMG_GENERIC, const float forceVector[3]=NULL_VECTOR, bool returnArray=false)
	{
		this.HitCounter++;
		float pos[3], end[3], ang[3];
		CBaseEntity(this.Actor).GetAbsOrigin(pos);
		CBaseEntity(this.Actor).GetAbsAngles(ang);
		if (!IsNullVector(offset))
		{
			float vecFwd[3], vecSide[3], vecUp[3];
			GetAngleVectors(ang, vecFwd, vecSide, vecUp);
			NormalizeVector(vecFwd, vecFwd);
			end[0] = pos[0] + (vecFwd[0] * offset[0]) + (vecSide[0] * offset[1]) + (vecUp[0] * offset[2]);
			end[1] = pos[1] + (vecFwd[1] * offset[0]) + (vecSide[1] * offset[1]) + (vecUp[1] * offset[2]);
			end[2] = pos[2] + (vecFwd[2] * offset[0]) + (vecSide[2] * offset[1]) + (vecUp[2] * offset[2]);
			CopyVectors(end, resultPos);
		}
		else
		{
			CopyVectors(pos, resultPos);
			CopyVectors(pos, end);
		}
		
		RF2_CustomHitbox hitbox = RF2_CustomHitbox.Create(this.Actor);
		hitbox.SetMins(mins);
		hitbox.SetMaxs(maxs);
		hitbox.Damage = damage;
		hitbox.DamageFlags = damageType;
		hitbox.SetDamageForce(forceVector);
		hitbox.ReturnHitEnts = returnArray;
		hitbox.Teleport(end, ang);
		hitbox.Spawn();
		return hitbox.DoDamage();
	}
	
	property float StartTime
	{
		public get()
		{
			return this.GetDataFloat("m_flStartTime");
		}
		
		public set(float value)
		{
			this.SetDataFloat("m_flStartTime", value);
		}
	}
	
	property float AttackTime
	{
		public get()
		{
			return this.GetDataFloat("m_flAttackTime");
		}

		public set(float value)
		{
			this.SetDataFloat("m_flAttackTime", value);
		}
	}

	property float TimeSinceAttack
	{
		public get()
		{
			return GetGameTime() - this.StartTime;
		}
	}
	
	property float RecoveryTime
	{
		public get()
		{
			return this.GetDataFloat("m_flRecoveryTime");
		}

		public set(float value)
		{
			this.SetDataFloat("m_flRecoveryTime", value);
		}
	}

	property int HitCounter
	{
		public get()
		{
			return this.GetData("m_nHitCounter");
		}

		public set(int value)
		{
			this.SetData("m_nHitCounter", value);
		}
	}
}
