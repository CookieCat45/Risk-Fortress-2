#if defined _RF2_effects_included
 #endinput
#endif
#define _RF2_effects_included

#pragma semicolon 1
#pragma newdecls required

int debuffFlags[MAXTF2PLAYERS];

int bleedAttacker[MAXTF2PLAYERS];
int burnAttacker[MAXTF2PLAYERS];
Handle bleedTimer[MAXTF2PLAYERS] = { INVALID_HANDLE, ... };
Handle bleedKillTimer[MAXTF2PLAYERS] = { INVALID_HANDLE, ... };
Handle burnTimer[MAXTF2PLAYERS] = { INVALID_HANDLE, ... };
Handle burnKillTimer[MAXTF2PLAYERS] = { INVALID_HANDLE, ... };

int bleedStacks[MAXTF2PLAYERS];

stock bool RF2_DamageOverTime(int victim, int attacker, float duration, int debuffFlag)
{
	if (!IsValidClient(victim) || !IsValidClient(attacker))
		return false;
		
	switch (debuffFlag)
	{
		case DEBUFF_BLEED:
		{
			bleedStacks[victim]++;
			debuffFlags[victim] |= DEBUFF_BLEED;
			bleedAttacker[victim] = attacker;
			
			if (bleedTimer[victim] == INVALID_HANDLE)
				bleedTimer[victim] = CreateTimer(0.5, Timer_BleedDamage, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
			if (bleedKillTimer[victim] != INVALID_HANDLE)
				KillTimer(bleedKillTimer[victim]);
	
			bleedKillTimer[victim] = CreateTimer(duration, Timer_KillBleed, victim, TIMER_FLAG_NO_MAPCHANGE);
		}
		case DEBUFF_BURN:
		{
			debuffFlags[victim] |= DEBUFF_BURN;
			burnAttacker[victim] = attacker;
	
			burnTimer[victim] = CreateTimer(0.5, Timer_BurnDamage, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
			if (burnKillTimer[victim] != INVALID_HANDLE)
				KillTimer(burnKillTimer[victim]);
			
			burnKillTimer[victim] = CreateTimer(duration, Timer_KillBurn, victim, TIMER_FLAG_NO_MAPCHANGE);
		}
		default:
		{
			return false;
		}
	}
	return true;
}

// DOT timers
public Action Timer_BleedDamage(Handle timer, int victim)
{
	if (!(debuffFlags[victim] & DEBUFF_BLEED) || !IsValidClient(victim, true))
	{
		bleedTimer[victim] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	float damage = 5.0 * bleedStacks[victim];
	int damageFlags;  
	damageFlags |= DMG_PREVENT_PHYSICS_FORCE;
	
	if (RollAttackCrit(bleedAttacker[victim]))
	{
		damageFlags |= DMG_CRIT;
		if (!TF2_IsPlayerInCondition(victim, TFCond_DefenseBuffed) || !TF2_IsPlayerInCondition(victim, TFCond_RuneResist))
			damage /= 3; // because TF2 crits are 3x. we want 2x here. (DMG_CRIT triples damage when used in SDKHooks_TakeDamage)
			
		damage *= 2.0;
	}
	
	debuffFlags[victim] |= DEBUFF_BLEED_NOSELFPROC;
	SDKHooks_TakeDamage(victim, bleedAttacker[victim], bleedAttacker[victim], damage, damageFlags);
	debuffFlags[victim] &= ~DEBUFF_BLEED_NOSELFPROC;
	
	return Plugin_Continue;
}

public Action Timer_KillBleed(Handle timer, int victim)
{
	debuffFlags[victim] &= ~DEBUFF_BLEED;
	debuffFlags[victim] &= ~DEBUFF_BLEED_NOSELFPROC;
	
	bleedStacks[victim] = 0;
	bleedKillTimer[victim] = INVALID_HANDLE;
}

public Action Timer_BurnDamage(Handle timer, int victim)
{
	if (!(debuffFlags[victim] & DEBUFF_BURN))
		return Plugin_Stop;
	
	float damage = 10.0;
	int damageFlags;  
	damageFlags |= DMG_PREVENT_PHYSICS_FORCE | DMG_IGNITE;
	
	if (RollAttackCrit(burnAttacker[victim]))
	{
		damageFlags |= DMG_CRIT | DMG_PREVENT_PHYSICS_FORCE | DMG_IGNITE;
		if (!TF2_IsPlayerInCondition(victim, TFCond_DefenseBuffed) || !TF2_IsPlayerInCondition(victim, TFCond_RuneResist))
			damage /= 3; // because TF2 crits are 3x. we want 2x here. (DMG_CRIT triples damage when used in SDKHooks_TakeDamage)
			
		damage *= 2.0;
	}
	
	SDKHooks_TakeDamage(victim, burnAttacker[victim], burnAttacker[victim], damage, damageFlags);
	return Plugin_Continue;
}

public Action Timer_KillBurn(Handle timer, int victim)
{
	debuffFlags[victim] &= ~DEBUFF_BURN;
	burnKillTimer[victim] = INVALID_HANDLE;
}