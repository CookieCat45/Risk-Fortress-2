"RF2_Events"
{
    "player_hurt"
    {
        "userid" "short"
        "health" "short"
        "attacker" "short"
        "damageamount" "long" // fix damage overflow
        "custom"	"short"
        "showdisguisedcrit" "bool"	// if our attribute specifically crits disguised enemies we need to show it on the client
        "crit" "bool"
        "minicrit" "bool"
        "allseecrit" "bool"
        "weaponid" "short"
        "bonuseffect" "byte"
    }
    
    "npc_hurt"
	{
		"entindex" "short"
		"health" "short"
		"attacker_player" "short"
		"weaponid" "short"
		"damageamount" "long" // fix damage overflow
		"crit" "bool"
		"boss"	"short"		// 1=HHH 2=Monoculus 3=Merasmus
	}
}
