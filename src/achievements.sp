// ==============================================================================================================================
// >>> GLOBAL INCLUDES
// ==============================================================================================================================
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// ==============================================================================================================================
// >>> PLUGIN INFORMATION
// ==============================================================================================================================
#define PLUGIN_VERSION "1.6"
public Plugin:myinfo =
{
	name 			= "[Achievements] Core",
	author 			= "AlexTheRegent",
	description 	= "",
	version 		= PLUGIN_VERSION,
	url 			= ""
}

// ==============================================================================================================================
// >>> DEFINES
// ==============================================================================================================================
//#pragma newdecls required
#define MPS 		MAXPLAYERS+1
#define PMP 		PLATFORM_MAX_PATH
#define MTF 		MENU_TIME_FOREVER
#define CID(%0) 	GetClientOfUserId(%0)
#define UID(%0) 	GetClientUserId(%0)
#define SZF(%0) 	%0, sizeof(%0)
#define LC(%0) 		for (new %0 = 1; %0 <= MaxClients; ++%0) if ( IsClientInGame(%0) ) 

// debug stuff
#define DEBUG
#if defined DEBUG
stock DebugMessage(const String:message[], any:...)
{
	decl String:sMessage[256];
	VFormat(sMessage, sizeof(sMessage), message, 2);
	PrintToServer("[Debug] %s", sMessage);
}
#define DbgMsg(%0); DebugMessage(%0);
#else
#define DbgMsg(%0);
#endif

// ==============================================================================================================================
// >>> CONSOLE VARIABLES
// ==============================================================================================================================


// ==============================================================================================================================
// >>> GLOBAL VARIABLES
// ==============================================================================================================================
new Handle:		g_hArray_sAchievementNames;			// array with names
new Handle:		g_hTrie_AchievementData;			// name -> event, executor, condition, count, reward
new Handle:		g_hTrie_ClientProgress[MPS];		// name -> count
new Handle:		g_hTrie_EventAchievements;			// event -> array with achievement names

// forward handles
new Handle:		g_hForward_OnConfigSectionReaded;
new Handle:		g_hForward_OnGotAchievement;

// panel stuff
new 			g_iExitBackButtonSlot;
new 			g_iExitButtonSlot;
// total achievements count
new 			g_iTotalAchievements;

// ==============================================================================================================================
// >>> LOCAL INCLUDES
// ==============================================================================================================================
#include "achievements/menus.sp"
// CreateProgressMenu(iClient)
// DisplayAchivementsMenu(iClient)
// DisplayAchivementsTypeMenu(iClient)
// DisplayInProgressMenu(iClient, iTarget, iItem=0)
// DisplayCompletedMenu(iClient, iTarget, iItem=0)
// DisplayAchivementDetailsMenu(iClient, iTarget, const String:sName[])

#include "achievements/handlers.sp"
// menu handles 

#include "achievements/configuration.sp"
// LoadAchivements();

#include "achievements/sql.sp"
// CreateDatabase();
// LoadClient(iClient);
// LoadProgress(iClient);
// SaveProgress(iClient, const String:sName[]);

#include "achievements/events.sp"
// ProcessEvent(iClient, Handle:hEvent, const String:sEventName[])

#include "achievements/modules.sp"
// ProcessModule(Handle:hTrie, const String:sEventName[]);

#include "achievements/reward.sp"
// GiveReward(iClient, const String:sName[]);

// ==============================================================================================================================
// >>> FORWARDS
// ==============================================================================================================================
public APLRes:AskPluginLoad2(Handle:hMySelf, bool:bLate, String:sError[], iErrorMax)
{
	// register natives
	CreateNative("Achievements_ProcessEvent", Native_ProcessEvent);
	return APLRes_Success;
}

public OnPluginStart() 
{
	// create forwards
	g_hForward_OnConfigSectionReaded = CreateGlobalForward("Achievements_OnConfigSectionReaded", ET_Ignore, Param_Cell, Param_String);
	g_hForward_OnGotAchievement = CreateGlobalForward("Achievements_OnGotAchievement", ET_Ignore, Param_Cell, Param_String);
	
	// load translations
	LoadTranslations("achievements_common.phrases.txt");
	LoadTranslations("achievements.phrases.txt");
	// establish database connection
	CreateDatabase();
	
	// dependency of panel keys from game engine
	// decl String:sGameName[32];
	// GetGameFolderName(SZF(sGameName));
	// if ( strcmp(sGameName, "csgo") == 0 ) {
	if ( GetEngineVersion() == Engine_CSGO ) {
		g_iExitBackButtonSlot = 7;
		g_iExitButtonSlot = 9;
	}
	else {
		g_iExitBackButtonSlot = 8;
		g_iExitButtonSlot = 10;
	}
	
	// register commands
	RegConsoleCmd("sm_achievements", 	Command_Achievements);
	RegConsoleCmd("sm_ach", 			Command_Achievements);
	
	// create convars
	CreateConVar("sm_achievements_version", PLUGIN_VERSION, "[Achievements] core plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnMapStart() 
{
	// do nothing
}

public OnConfigsExecuted() 
{
	// do nothing
}

public OnAllPluginsLoaded()
{
	// bad but ok for first time. 
	// will be replaced with forward
	LoadAchivements();
}

public OnClientConnected(iClient)
{
	// allocate memory
	g_hTrie_ClientProgress[iClient] = CreateTrie();
}

public OnClientPutInServer(iClient)
{
	// load client data
	LoadClient(iClient);
}

public OnClientDisconnect(iClient)
{
	// free memory
	CloseHandle(g_hTrie_ClientProgress[iClient]);
}

// ==============================================================================================================================
// >>> 
// ==============================================================================================================================
public Action:Command_Achievements(iClient, iArgc)
{
	DisplayAchivementsMenu(iClient);
	return Plugin_Handled;
}
