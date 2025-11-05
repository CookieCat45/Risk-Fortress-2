#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory g_ActionFactory;

methodmap RF2_MajorShocksChaseLayerAction < NextBotAction
{
	public RF2_MajorShocksChaseLayerAction()
	{
		if (g_ActionFactory == null)
		{
			g_ActionFactory = new NextBotActionFactory("RF2_MajorShocksChaseLayer");
			g_ActionFactory.SetCallback(NextBotActionCallbackType_InitialContainedAction, InitialContainedAction);
			g_ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
		}
		return view_as<RF2_MajorShocksChaseLayerAction>(g_ActionFactory.Create());
	}
}

static NextBotAction InitialContainedAction(RF2_MajorShocksChaseLayerAction action, RF2_MajorShocks actor)
{
	return RF2_MajorShocksWeaponStateAction();
}

static int Update(RF2_MajorShocksChaseLayerAction action, RF2_MajorShocks actor, float interval)
{
	PathFollower path = actor.Path;
	INextBot bot = actor.MyNextBotPointer();
	ILocomotion loco = bot.GetLocomotionInterface();
	if (actor.WeaponType == MajorShocks_WeaponType_GroundSlam || actor.WeaponType == MajorShocks_WeaponType_GigaGroundSlam)
	{
		return action.SuspendFor(RF2_MajorShocksGroundSlamAction());
	}

	if (actor.WeaponType == MajorShocks_WeaponType_Vortex || actor.WeaponType == MajorShocks_WeaponType_GigaVortex)
	{
		return action.SuspendFor(RF2_MajorShocksVortexAction());
	}

	if (actor.IsTargetValid())
	{
		if (IsLOSClear(actor.index, actor.Target))
		{
			float pos[3];
			CBaseEntity(actor.Target).GetAbsOrigin(pos);
			loco.FaceTowards(pos);
			float dist = DistBetween(actor.index, actor.Target);
			if (dist > 350.0 || actor.WeaponState == MajorShocks_WeaponState_Melee)
			{
				path.ComputeToTarget(bot, actor.Target);
				actor.ShouldSlowDown = false;
			}
			else
			{
				actor.ShouldSlowDown = true;
			}
		}
		else
		{
			path.ComputeToTarget(bot, actor.Target);
		}
	}

	if (path.IsValid())
	{
		path.Update(bot);
	}

	return action.Continue();
}