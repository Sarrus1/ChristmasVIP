#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <colorvariables>
#pragma newdecls required
#pragma semicolon 1


ConVar g_cTimeLowerBound,
	g_cTimeHigherBound,
	g_cFlag;

int g_iFlags[20],
	g_iFlagCount = 0;

Handle g_iNotificationTimer[MAXPLAYERS+1];


public Plugin myinfo =
{
	name = "ChristmasVIP",
	author = "Sarrus",
	description = "",
	version = "1.0",
	url = "https://github.com/Sarrus1/"
};


public void OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

	LoadTranslations("ChristmasVIP.phrases");

	g_cTimeLowerBound = CreateConVar("sm_christmas_vip_lower_bound", "1608854400", "The UNIX time at which people will start getting VIP.", _,true, 0.0);
	g_cTimeHigherBound = CreateConVar("sm_christmas_vip_higher_bound", "1608940799", "The UNIX time at which people will no longer have VIP.", _,true, 0.0);
	g_cFlag = CreateConVar("sm_christmas_vip_flag", "20", "20=Custom6, 19=Custom5 etc. Numeric Flag See: 'https://wiki.alliedmods.net/Checking_Admin_Flags_(SourceMod_Scripting)' for Definitions ---- Multiple flags seperated with Space: '16 17 18 19' !!");

	AutoExecConfig(true, "ChristmasVIP");
}


public void OnMapStart()
{
	for ( int i = 1; i <= MaxClients; i++ )
		delete g_iNotificationTimer[i];
}


public void OnClientDisconnect(int client)
{
	delete g_iNotificationTimer[client];
}


public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for ( int i = 1; i <= MaxClients; i++ )
		delete g_iNotificationTimer[i];
}


public void OnConfigsExecuted() 
{
	int lower_bound = GetConVarInt(g_cTimeLowerBound),
		higher_bound = GetConVarInt(g_cTimeHigherBound);
	g_iFlagCount = 0;
	char szFlags[256],
		szSplinters[20][6];
	
	GetConVarString(g_cFlag, szFlags, sizeof(szFlags));
	
	for (int i = 0; i < 20; i++)
		strcopy(szSplinters[i], 6, "");

	ExplodeString(szFlags, " ", szSplinters, 20, 6);
	for (int i = 0; i < 20; i++)
	{
		if (StrEqual(szSplinters[i], ""))
			break;
		g_iFlags[g_iFlagCount++] = StringToInt(szSplinters[i]);
	}
	if(lower_bound>higher_bound)
	{
		PrintToServer("[ChristmasVIP] ERROR, your lower_bound is higher than your higher_bound, please fix it in the config. Plugin has been unloaded.");
		UnloadMyself();
	}

}


public void OnClientPostAdminCheck(int client)
{
	int time = GetTime(),
		lower_bound = GetConVarInt(g_cTimeLowerBound),
		higher_bound = GetConVarInt(g_cTimeHigherBound);
	if(time>lower_bound && time<higher_bound)
	{
		for (int i = 0; i < g_iFlagCount; i++)
			SetUserFlagBits(client, GetUserFlagBits(client) | (1 << g_iFlags[i]));
		g_iNotificationTimer[client] = CreateTimer(10.0, NotificationTimer, GetClientUserId(client));
	}
}


public Action NotificationTimer(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if ( client && IsClientInGame(client) )
	{
		g_iNotificationTimer[client] = null;
		CPrintToChat(client, "%t", "VIP notification");
		return Plugin_Handled;
	}
	return Plugin_Handled;
} 


stock void UnloadMyself() 
{
	char filename[256];
	GetPluginFilename(INVALID_HANDLE, filename, sizeof(filename));
	ServerCommand("sm plugins unload %s", filename);
} 