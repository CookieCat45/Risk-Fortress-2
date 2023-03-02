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
	g_coBecomeBoss = RegClientCookie("rf2_become_boss", "Enables or disables becoming the Teleporter boss.", CookieAccess_Protected);
	g_coAutomaticItemMenu = RegClientCookie("rf2_auto_item_menu", "Enables or disables automatic item menu.", CookieAccess_Protected);
	g_coSurvivorPoints = RegClientCookie("rf2_survivor_points", "Survivor queue points.", CookieAccess_Protected);
}

public void OnClientCookiesCached(int client)
{
	if (!RF2_IsEnabled())
		return;
	
	char buffer[256];
	
	// Music Preference
	GetClientCookie(client, g_coMusicEnabled, buffer, sizeof(buffer));
	if (!buffer[0])
	{
		SetClientCookie(client, g_coMusicEnabled, "1");
	}
	else if (buffer[0] == '0')
	{
		g_bPlayerMusicEnabled[client] = false;
	}
	else
	{
		g_bPlayerMusicEnabled[client] = true;
	}
		
	// If the round is active, we can play the music to our client now
	if (g_bRoundActive && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (g_bPlayerMusicEnabled[client])
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
		SetClientCookie(client, g_coBecomeSurvivor, "1");
	}
	else if (buffer[0] == '0')
	{
		g_bPlayerBecomeSurvivor[client] = false;
	}
	else
	{
		g_bPlayerBecomeSurvivor[client] = true;
	}	
	
	// Boss Preference
	GetClientCookie(client, g_coBecomeBoss, buffer, sizeof(buffer));
	if (!buffer[0])
	{
		SetClientCookie(client, g_coBecomeBoss, "1");
	}
	else if (buffer[0] == '0')
	{
		g_bPlayerBecomeBoss[client] = false;
	}
	else
	{
		g_bPlayerBecomeBoss[client] = true;
	}	
		
	// Auto Item Menu Preference
	GetClientCookie(client, g_coAutomaticItemMenu, buffer, sizeof(buffer));
	if (!buffer[0])
	{
		SetClientCookie(client, g_coAutomaticItemMenu, "0");
	}
	else if (buffer[0] == '0')
	{
		g_bPlayerAutomaticItemMenu[client] = false;
	}
	else
	{
		g_bPlayerAutomaticItemMenu[client] = true;
	}
	
	// Survivor Points
	GetClientCookie(client, g_coSurvivorPoints, buffer, sizeof(buffer));
	if (!buffer[0])
	{
		SetClientCookie(client, g_coSurvivorPoints, "0");
	}
	else
	{
		g_iPlayerSurvivorPoints[client] = StringToInt(buffer);
	}
}

void SaveClientCookies(int client)
{
	char buffer[256];
	IntToString(g_iPlayerSurvivorPoints[client], buffer, sizeof(buffer));
	SetClientCookie(client, g_coSurvivorPoints, buffer);
}