#include <discordWebhookAPI>
#include <ExtendedDiscord>
#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

GlobalForward g_hForward_StatusOK;
GlobalForward g_hForward_StatusNotOK;
Handle g_hFwd_OnErrorLogged = INVALID_HANDLE;
ConVar g_cvSteamAPI;

char g_sClientAvatar[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
char g_sLogPath[PLATFORM_MAX_PATH];
char g_sAPIKey[32];

public Plugin myinfo =
{
	name		= "Extended Discord Features",
	author		= ".Rushaway, Dolly",
	description	= "Provide additonal features for Discord API",
	version		= ExtendDiscord_VERSION,
	url			= ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ExtendedDiscord_LogError", Native_LogError);
	CreateNative("ExtendedDiscord_GetAvatarLink", Native_GetAvatarLink);

	g_hForward_StatusOK = CreateGlobalForward("ExtendedDiscord_OnPluginOK", ET_Ignore);
	g_hForward_StatusNotOK = CreateGlobalForward("ExtendedDiscord_OnPluginNotOK", ET_Ignore);
	g_hFwd_OnErrorLogged = CreateGlobalForward("ExtendedDiscord_OnErrorLogged", ET_Ignore, Param_String);

	RegPluginLibrary("ExtendedDiscord");
	return APLRes_Success;
}

public void OnPluginStart()
{
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/discord/errors.log");
	g_cvSteamAPI = CreateConVar("discord_apikey", "", "API Web Steam. Get your own https://steamcommunity.com/dev/apikey", FCVAR_PROTECTED);
	g_cvSteamAPI.AddChangeHook(ConVarChange);

	g_cvSteamAPI.GetString(g_sAPIKey, sizeof(g_sAPIKey));

	AutoExecConfig(true);
}

public void OnAllPluginsLoaded()
{
	SendForward_Available();
}

public void OnPluginPauseChange(bool pause)
{
	if (pause)
		SendForward_NotAvailable();
	else
		SendForward_Available();
}

public void OnPluginEnd()
{
	SendForward_NotAvailable();
}

public void ConVarChange(ConVar CVar, const char[] oldVal, const char[] newVal)
{
	g_cvSteamAPI.GetString(g_sAPIKey, sizeof(g_sAPIKey));
}

public void OnConfigsExecuted()
{
	if (!g_sAPIKey[0]) {
		LogError("Invalid or no STEAM API Key specified.");
		return;
	}
	g_cvSteamAPI.GetString(g_sAPIKey, sizeof(g_sAPIKey));
}

public void OnClientPostAdminCheck(int iClient) {
	if(IsFakeClient(iClient) || IsClientSourceTV(iClient))
		return;

	GetClientSteamAvatar(iClient);
}

public void OnClientDisconnect(int iClient)
{
	g_sClientAvatar[iClient][0] = '\0';
}

stock void GetClientSteamAvatar(int iClient) {
	if (!g_sAPIKey[0]) {
		return;
	}

	char steamID[MAX_AUTHID_LENGTH];
	if (!GetClientAuthId(iClient, AuthId_SteamID64, steamID, sizeof(steamID), false))
		return;

	HTTPRequest request = new HTTPRequest("https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?");
	request.SetHeader("Accept", "application/json");
	request.AppendQueryParam("key", g_sAPIKey);
	request.AppendQueryParam("format", "json");
	request.AppendQueryParam("steamids", steamID);
	request.Get(OnSummaryReceived, GetClientUserId(iClient));
}

stock void OnSummaryReceived(HTTPResponse response, int userid) {
	if (response.Status != HTTPStatus_OK)
		return;

	JSONObject json = view_as<JSONObject>(response.Data); 
	if (json == null)
		return;
	
	JSONObject responseObj = view_as<JSONObject>(json.Get("response"));
	delete json;
	
	if (responseObj == null)
		return;
	
	JSONArray players = view_as<JSONArray>(responseObj.Get("players"));
	delete responseObj;
	
	if (players == null)
		return;
	
	int iClient = GetClientOfUserId(userid);
	if (iClient < 1) {
		delete players;
		return;
	}
		
	if (players.Length <= 0) {
		delete players;
		return;
	}
	
	JSONObject player = view_as<JSONObject>(players.Get(0));
	delete players;
	
	player.GetString("avatarfull", g_sClientAvatar[iClient], sizeof(g_sClientAvatar[]));
	
	delete player;
}

// native ExtendedDiscord_LogError(const char[] format, any...);
public int Native_LogError(Handle plugin, int numParams)
{
	char sBuffer[2048];
	FormatNativeString(0, 1, 2, sizeof(sBuffer), _, sBuffer);
	LogToFileEx(g_sLogPath, "%s", sBuffer);

	// Start forward call
	Call_StartForward(g_hFwd_OnErrorLogged);
	Call_PushString(sBuffer);
	Call_Finish();

	return 1;
}

// native ExtendedDiscord_GetAvatarLink(iClient, buffer, sizeof(buffer));
public int Native_GetAvatarLink(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	return g_sClientAvatar[iClient][0];
}

stock void SendForward_Available()
{
	Call_StartForward(g_hForward_StatusOK);
	Call_Finish();
}

stock void SendForward_NotAvailable()
{
	Call_StartForward(g_hForward_StatusNotOK);
	Call_Finish();
}