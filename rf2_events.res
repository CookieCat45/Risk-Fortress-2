"RF2_Events"
{
    "rf2_player_fireweapon" // Note: The Dragon's Fury and Short Circuit do not fire this event
    {
        "userid"            "short"     // userid of player who fired the weapon
        "weapon_entindex"   "long"      // weapon entity index
        "weapon_classname"  "string"    // weapon classname
        "crit"              "bool"      // was the attack a crit or not
    }
    
    "rf2_entity_created"
    {
        "entindex"  "long"      // entindex of new entity
        "classname" "string"    // classname of new entity
    }
    
    "rf2_entity_destroyed"
    {
        "entindex"  "long"      // entindex of entity being destroyed
        "classname" "string"    // classname of entity being destroyed
    }
}
