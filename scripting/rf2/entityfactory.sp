#pragma newdecls required
#pragma semicolon 1

void InstallEnts()
{
	g_fwOnMapStart = new PrivateForward(ET_Ignore);
	RF2_GameRules.Init();
	RF2_Item.Init();
	RF2_HealthText.Init();
	RF2_WorldCenter.Init();
	RF2_TankSpawner.Init();
	RF2_Object_Base.Init();
	RF2_Object_Crate.Init();
	RF2_Object_Teleporter.Init();
	RF2_Object_Workbench.Init();
	RF2_Object_Scrapper.Init();
	RF2_Object_Gravestone.Init();
	RF2_Object_Altar.Init();
	RF2_Object_Pumpkin.Init();
	RF2_Object_Statue.Init();
	RF2_Object_Tree.Init();
	RF2_Object_Barrel.Init();
	RF2_Trigger_Exit.Init();
	RF2_Projectile_Base.Init();
	RF2_Projectile_Shuriken.Init();
	RF2_Projectile_Bomb.Init();
	RF2_Projectile_Beam.Init();
	RF2_Projectile_Fireball.Init();
	RF2_Projectile_Kunai.Init();
	RF2_Projectile_Skull.Init();
	RF2_Projectile_HomingRocket.Init();
	RF2_Projectile_Shrapnel.Init();
	RF2_DispenserShield.Init();
	RF2_NPC_Base.Init();
	RF2_CustomHitbox.Init();
	RF2_SentryBuster.Init();
	RF2_TankBoss.Init();
	RF2_RobotButler.Init();
	RF2_Logic_BotDeath.Init();
	RF2_Providence.Init();
	RF2_RaidBossSpawner.Init();
	RF2_ProvidenceShieldCrystal.Init();

	#if defined DEVONLY
	RF2_RaidBoss_Galleom.Init();
	RF2_Companion_Base.Init();
	RF2_Companion_HeavyBot.Init();
	#endif
}

void HookMapStart(Function func)
{
	g_fwOnMapStart.AddFunction(INVALID_HANDLE, func);
}
