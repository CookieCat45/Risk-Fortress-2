#if defined _RF2_cookies_included
 #endinput
#endif
#define _RF2_cookies_included

#pragma semicolon 1
#pragma newdecls required

void BakeCookies()
{
	g_coMusicEnabled = RegClientCookie("rf2_music_enabled", "Enables or disables music.", CookieAccess_Protected);
	g_coBecomeSurvivor = RegClientCookie("rf2_become_survivor", "Enables or disables becoming a Survivor.", CookieAccess_Protected);
	g_coBecomeEnemy = RegClientCookie("rf2_become_enemy", "Enables spawning as an enemy.", CookieAccess_Protected);
	g_coBecomeBoss = RegClientCookie("rf2_become_boss", "Enables or disables becoming the Teleporter boss.", CookieAccess_Protected);
	g_coSurvivorPoints = RegClientCookie("rf2_survivor_points", "Survivor queue points.", CookieAccess_Protected);
	g_coStayInSpecOnJoin = RegClientCookie("rf2_stay_in_spec", "Stay in spectate upon joining.", CookieAccess_Protected);
	g_coSpecOnDeath = RegClientCookie("rf2_spec_on_death", "Join spectator after dying on RED.", CookieAccess_Protected);
	g_coItemsCollected[0] = RegClientCookie("rf2_items_collected_1", "Items collected for logbook.", CookieAccess_Private);
	g_coItemsCollected[1] = RegClientCookie("rf2_items_collected_2", "Items collected for logbook.", CookieAccess_Private);
	g_coItemsCollected[2] = RegClientCookie("rf2_items_collected_3", "Items collected for logbook.", CookieAccess_Private);
	g_coItemsCollected[3] = RegClientCookie("rf2_items_collected_4", "Items collected for logbook.", CookieAccess_Private);
	g_coTutorialItemPickup = RegClientCookie("rf2_tutorial_item_pickup", "Item pickup tutorial.", CookieAccess_Public);
	g_coTutorialSurvivor = RegClientCookie("rf2_tutorial_survivor", "Survivor tutorial.", CookieAccess_Public);
	g_coNewPlayer = RegClientCookie("rf2_new_player", "New Player", CookieAccess_Private);
	g_coDisableItemMessages = RegClientCookie("rf2_disable_item_msg", "Disable item chat messages", CookieAccess_Protected);
	g_coSwapStrangeButton = RegClientCookie("rf2_swap_strange_button", "Changes the strange activation button to ATTACK3 instead of RELOAD.", CookieAccess_Protected);
	
	char name[64];
	for (int i = 0; i < MAX_ACHIEVEMENTS; i++)
	{
		FormatEx(name, sizeof(name), "rf2_achievement_%i", i);
		g_coAchievementCookies[i] = RegClientCookie(name, "RF2 Achievement Cookie", CookieAccess_Private);
	}
}

public void OnClientCookiesCached(int client)
{
	if (!RF2_IsEnabled() || IsFakeClient(client))
		return;
	
	char buffer[MAX_COOKIE_LENGTH];
	
	// Music Preference
	GetClientCookie(client, g_coMusicEnabled, buffer, sizeof(buffer));
	if (!buffer[0])
	{
		SetCookieBool(client, g_coMusicEnabled, true);
	}
	
	// If the round is active, we can play the music to our client now
	if (g_bRoundActive && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetCookieBool(client, g_coMusicEnabled))
		{
			PlayMusicTrack(client);
		}
		else
		{
			StopMusicTrack(client);
		}	
	}
		
	// Survivor Preference
	GetClientCookie(client, g_coBecomeSurvivor, buffer, sizeof(buffer));
	if (!buffer[0])
	{
		SetCookieBool(client, g_coBecomeSurvivor, true);
	}
	
	// Boss Preference
	GetClientCookie(client, g_coBecomeBoss, buffer, sizeof(buffer));
	if (!buffer[0])
	{
		SetCookieBool(client, g_coBecomeBoss, true);
	}
	
	// Spectate Preference
	GetClientCookie(client, g_coStayInSpecOnJoin, buffer, sizeof(buffer));
	if (!buffer[0])
	{
		SetCookieBool(client, g_coStayInSpecOnJoin, false);
	}

	GetClientCookie(client, g_coSpecOnDeath, buffer, sizeof(buffer));
	if (!buffer[0])
	{
		SetCookieBool(client, g_coSpecOnDeath, false);
	}
	
	// Enemy Preference
	GetClientCookie(client, g_coBecomeEnemy, buffer, sizeof(buffer));
	if (!buffer[0])
	{
		SetCookieBool(client, g_coBecomeEnemy, true);
	}
	
	// Item Message Preference
	GetClientCookie(client, g_coDisableItemMessages, buffer, sizeof(buffer));
	if (!buffer[0])
	{
		SetCookieBool(client, g_coDisableItemMessages, false);
	}
	
	// Survivor Points
	GetClientCookie(client, g_coSurvivorPoints, buffer, sizeof(buffer));
	if (!buffer[0])
	{
		SetCookieInt(client, g_coSurvivorPoints, 0);
	}
	
	GetClientCookie(client, g_coNewPlayer, buffer, sizeof(buffer));
	if (!buffer[0])
	{
		SetCookieBool(client, g_coNewPlayer, false);
	}
	
	if (!g_bRoundActive && !GetCookieBool(client, g_coStayInSpecOnJoin) && GetTotalHumans(false) > 1)
	{
		CreateTimer(1.0, Timer_ChangeTeam, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (!GetCookieBool(client, g_coNewPlayer) && g_bRoundActive)
	{
		RF2_SetSurvivorPoints(client, RF2_GetSurvivorPoints(client)+99999);
		SetCookieBool(client, g_coNewPlayer, true);
		CreateTimer(1.0, Timer_NewPlayerMessage, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_NewPlayerMessage(Handle timer, int client)
{
	if (!(client = GetClientOfUserId(client)))
		return Plugin_Stop;
	
	// Client may not be fully in game at this point, wait for them to be
	if (!IsClientInGame(client))
		return Plugin_Continue;
	
	/*
	Menu menu = new Menu(Menu_HelpMenu);
	char msg[512];
	FormatEx(msg, sizeof(msg), "%T", "Help1", client);
	menu.AddItem("help1", msg, ITEMDRAW_DISABLED);
	FormatEx(msg, sizeof(msg), "%T", "Help2", client);
	menu.AddItem("help2", msg, ITEMDRAW_DISABLED);
	FormatEx(msg, sizeof(msg), "%T", "Help3", client);
	menu.AddItem("help3", msg, ITEMDRAW_DISABLED);
	FormatEx(msg, sizeof(msg), "%T", "Help4", client);
	menu.AddItem("help4", msg, ITEMDRAW_DISABLED);
	FormatEx(msg, sizeof(msg), "%T", "Help5", client);
	menu.AddItem("help5", msg, ITEMDRAW_DISABLED);
	menu.Display(client, MENU_TIME_FOREVER);
	*/
	
	// player is most likely going to join blue, wait for them to do so, so we can make sure they see the message
	if (g_bRoundActive && GetClientTeam(client) == TEAM_ENEMY)
	{
		PrintCenterText(client, "You will join RED Team shortly next map");
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action Timer_ChangeTeam(Handle timer, int client)
{
	if (g_bRoundActive || !(client = GetClientOfUserId(client)) || IsClientInGame(client) && (IsPlayerAlive(client) || GetClientTeam(client) > 1))
		return Plugin_Stop;
	
	// Client may not be fully in game at this point, wait for them to be
	if (!IsClientInGame(client))
		return Plugin_Continue;
	
	ChangeClientTeam(client, GetRandomInt(2, 3));
	TF2_RespawnPlayer(client);
	return Plugin_Stop;
}

int GetCookieInt(int client, Cookie cookie)
{
	char buffer[16];
	GetClientCookie(client, cookie, buffer, sizeof(buffer));
	return StringToInt(buffer);
}

bool GetCookieBool(int client, Cookie cookie)
{
	return asBool(GetCookieInt(client, cookie));
}

void SetCookieInt(int client, Cookie cookie, int value)
{
	char buffer[MAX_COOKIE_LENGTH];
	IntToString(value, buffer, sizeof(buffer));
	cookie.Set(client, buffer);
}

void SetCookieBool(int client, Cookie cookie, bool value)
{
	SetCookieInt(client, cookie, view_as<int>(value));
}

int GetItemLogCookie(int client, char[] buffer, int size)
{
	int total;
	char buffers[4][100];
	for (int i = 0; i < sizeof(g_coItemsCollected); i++)
	{
		GetClientCookie(client, g_coItemsCollected[i], buffers[i], sizeof(buffers[]));
		total += strlen(buffers[i]);
	}
	
	ImplodeStrings(buffers, sizeof(buffers), "", buffer, size);
	return total;
}

void SetItemLogCookie(int client, const char[] value)
{
	char cookie[MAX_COOKIE_LENGTH], buffer[512];
	strcopy(buffer, sizeof(buffer), value);
	for (int i = 0; i < sizeof(g_coItemsCollected); i++)
	{
		SetClientCookie(client, g_coItemsCollected[i], buffer);
		GetClientCookie(client, g_coItemsCollected[i], cookie, sizeof(cookie));
		ReplaceStringEx(buffer, sizeof(buffer), cookie, "");
		if (strlen(buffer) <= 0)
			break;
	}
}
