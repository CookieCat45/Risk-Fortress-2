#if defined _RF2_cookies_included
 #endinput
#endif
#define _RF2_cookies_included

void BakeCookies()
{
	g_coMusicEnabled = RegClientCookie("rf2_music_enabled", "Enables or disables music.", CookieAccess_Protected);
	g_coBecomeSurvivor = RegClientCookie("rf2_become_survivor", "Enables or disables becoming a Survivor.", CookieAccess_Protected);
	g_coBecomeBoss = RegClientCookie("rf2_become_boss", "Enables or disables becoming the Teleporter boss.", CookieAccess_Protected);
	g_coSurvivorPoints = RegClientCookie("rf2_survivor_points", "Survivor queue points.", CookieAccess_Protected);
}

public void OnClientCookiesCached(int client)
{
	if (!g_bPluginEnabled)
		return;
	
	char buffer[256];
	
	// Music Preference
	GetClientCookie(client, g_coMusicEnabled, buffer, sizeof(buffer));
	if (buffer[0] == '\0')
		SetClientCookie(client, g_coMusicEnabled, "1");
	else if (buffer[0] == '0')
		g_bMusicEnabled[client] = false;
	else
		g_bMusicEnabled[client] = true;
		
	// If the round is active, we can play the music to our client now
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (g_bMusicEnabled[client] && g_bRoundActive)
			PlayMusicTrack(client, g_bTeleporterEvent);
		else
			StopMusicTrack(client);
	}
		
	// Survivor Preference
	GetClientCookie(client, g_coBecomeSurvivor, buffer, sizeof(buffer));
	if (buffer[0] == '\0')
		SetClientCookie(client, g_coBecomeSurvivor, "1");
	else if (buffer[0] == '0')
		g_bBecomeSurvivor[client] = false;	
	else
		g_bBecomeSurvivor[client] = true;
	
	// Boss Preference
	GetClientCookie(client, g_coBecomeBoss, buffer, sizeof(buffer));
	if (buffer[0] == '\0')
		SetClientCookie(client, g_coBecomeBoss, "1");
	else if (buffer[0] == '0')
		g_bBecomeBoss[client] = false;
	else
		g_bBecomeBoss[client] = true;
	
	// Survivor Points
	GetClientCookie(client, g_coSurvivorPoints, buffer, sizeof(buffer));
	if (buffer[0] == '\0')
		SetClientCookie(client, g_coSurvivorPoints, "0");
	else
		g_iSurvivorPoints[client] = StringToInt(buffer);
}

void SaveClientCookies(int client)
{
	char buffer[256];
	
	IntToString(g_iSurvivorPoints[client], buffer, sizeof(buffer));
	SetClientCookie(client, g_coSurvivorPoints, buffer);
}