new Handle:		g_hInProgressMenu[MPS];
new Handle:		g_hCompletedMenu[MPS];

new 			g_iCompletedAchievements[MPS];

CreateProgressMenu(iClient)
{
	// create|clear menu from previos use
	if ( !g_hInProgressMenu[iClient] ) {
		g_hInProgressMenu[iClient] = CreateMenu(Handler_ShowAchievements, MenuAction_DisplayItem);
		SetMenuExitBackButton(g_hInProgressMenu[iClient], true);
	}
	RemoveAllMenuItems(g_hInProgressMenu[iClient]);
	
	// create|clear menu from previos use
	if ( !g_hCompletedMenu[iClient] ) {
		g_hCompletedMenu[iClient] = CreateMenu(Handler_ShowAchievements, MenuAction_DisplayItem);
		SetMenuExitBackButton(g_hCompletedMenu[iClient], true);
	}
	RemoveAllMenuItems(g_hCompletedMenu[iClient]);
	
	// create progress menu
	g_iCompletedAchievements[iClient] = 0;
	decl Handle:hAchievementData, String:sName[64], iCount, iBuffer;
	for ( new i = 0; i < g_iTotalAchievements; ++i ) {
		GetArrayString(g_hArray_sAchievementNames, i, SZF(sName));
		if ( !GetTrieValue(g_hTrie_AchievementData, sName, hAchievementData) ) {
			// this can't be, but maybe...
			LogError("???");
			continue;
		}
		
		if ( GetTrieValue(g_hTrie_ClientProgress[iClient], sName, iCount) ) {
			if ( !GetTrieValue(hAchievementData, "count", iBuffer) ) {
				// this can't be, but maybe...
				LogError("?!");
				continue;
			}
			
			// continue !!!
			if ( iCount >= iBuffer ) {
				AddMenuItem(g_hCompletedMenu[iClient], sName, "");
				g_iCompletedAchievements[iClient]++;
				continue;
			}
		}
		
		AddMenuItem(g_hInProgressMenu[iClient], sName, "");
	}
	
	// if menu is empty
	if ( GetMenuItemCount(g_hInProgressMenu[iClient]) == 0 ) {
		AddMenuItem(g_hInProgressMenu[iClient], "", "", ITEMDRAW_DISABLED);
	}
	
	// if menu is empty
	if ( GetMenuItemCount(g_hCompletedMenu[iClient]) == 0 ) {
		AddMenuItem(g_hCompletedMenu[iClient], "", "", ITEMDRAW_DISABLED);
	}
}

DisplayAchivementsMenu(iClient)
{
	new Handle:hMenu = CreateMenu(Handler_AchivementsMenu);
	SetMenuTitle(hMenu, "%t", "achievements menu: title");
	
	decl String:sBuffer[64];
	FormatEx(SZF(sBuffer), "%t", "achievements menu: own achievements");
	AddMenuItem(hMenu, "own", sBuffer);
	FormatEx(SZF(sBuffer), "%t", "achievements menu: players achievements");
	AddMenuItem(hMenu, "players", sBuffer);
	
	DisplayMenu(hMenu, iClient, MTF);
}

DisplayPlayersMenu(iClient)
{
	new Handle:hMenu = CreateMenu(Handler_PlayersMenu);
	SetMenuTitle(hMenu, "%t", "players menu: title");
	
	decl String:sUserId[8], String:sName[32];
	LC(i) {
		if ( !IsFakeClient(i) && !IsClientSourceTV(i) && i != iClient ) {
			IntToString(UID(i), SZF(sUserId));
			GetClientName(i, SZF(sName));
			AddMenuItem(hMenu, sUserId, sName);
		}
	}
	
	// if menu is empty
	if ( GetMenuItemCount(hMenu) == 0 ) {
		decl String:sBuffer[64];
		FormatEx(SZF(sBuffer), "%t", "players menu: no other players");
		AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
	}
	
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, iClient, MTF);
}

DisplayAchivementsTypeMenu(iClient, iTarget)
{
	// new Handle:hMenu = CreateMenu(Handler_AchivementTypeMenu);
	// SetMenuTitle(hMenu, "%t", "achievements menu: title");
	
	// decl String:sBuffer[64];
	// FormatEx(SZF(sBuffer), "%t", "achievements type menu: in progress");
	// AddMenuItem(hMenu, "in progress", sBuffer);
	// FormatEx(SZF(sBuffer), "%t", "achievements type menu: completed");
	// AddMenuItem(hMenu, "completed", sBuffer);
	
	// SetMenuExitBackButton(hMenu, true);
	// DisplayMenu(hMenu, iClient, MTF);
	
	new Handle:hPanel = CreatePanel();
	
	decl String:sBuffer[64], String:sName[32];
	GetClientName(iTarget, SZF(sName));
	FormatEx(SZF(sBuffer), "%t", "achievements type menu: title", sName);
	SetPanelTitle(hPanel, sBuffer);
	
	FormatEx(SZF(sBuffer), "%t", "achievements type menu: overall progress", 
		g_iCompletedAchievements[iTarget], g_iTotalAchievements, 
		(g_iCompletedAchievements[iTarget]/float(g_iTotalAchievements)*100));
	DrawPanelText(hPanel, sBuffer);
	
	FormatEx(SZF(sBuffer), "%t", "achievements type menu: in progress");
	DrawPanelItem(hPanel, sBuffer);
	FormatEx(SZF(sBuffer), "%t", "achievements type menu: completed");
	DrawPanelItem(hPanel, sBuffer);
	
	DrawPanelText(hPanel, " ");
	
	SetPanelCurrentKey(hPanel, g_iExitBackButtonSlot);
	FormatEx(SZF(sBuffer), "%t", "menu: back");
	DrawPanelItem(hPanel, sBuffer);
	
	DrawPanelText(hPanel, " ");
	
	SetPanelCurrentKey(hPanel, g_iExitButtonSlot);
	FormatEx(SZF(sBuffer), "%t", "menu: exit");
	DrawPanelItem(hPanel, sBuffer);
	
	SendPanelToClient(hPanel, iClient, Handler_AchivementTypeMenu, MTF);
	CloseHandle(hPanel);
}

DisplayInProgressMenu(iClient, iTarget, iItem=0)
{
	if ( !g_hInProgressMenu[iTarget] ) {
		PrintToChat(iClient, "%t", "client is not loaded");
		
		if ( iTarget == iClient ) {
			DisplayAchivementsMenu(iClient);
		}
		else {
			DisplayPlayersMenu(iClient);
		}
	}
	else {
		decl String:sName[32];
		GetClientName(iTarget, SZF(sName));
		SetMenuTitle(g_hInProgressMenu[iTarget], "%t", "achievements in progress menu: title", sName);
		DisplayMenuAtItem(g_hInProgressMenu[iTarget], iClient, iItem, MTF);
	}
}

DisplayCompletedMenu(iClient, iTarget, iItem=0)
{
	if ( !g_hCompletedMenu[iTarget] ) {
		PrintToChat(iClient, "%t", "client is not loaded");
		
		if ( iTarget == iClient ) {
			DisplayAchivementsMenu(iClient);
		}
		else {
			DisplayPlayersMenu(iClient);
		}
	}
	else {
		decl String:sName[32];
		GetClientName(iTarget, SZF(sName));
		SetMenuTitle(g_hCompletedMenu[iTarget], "%t", "completed achievements menu: title", sName);
		DisplayMenuAtItem(g_hCompletedMenu[iTarget], iClient, iItem, MTF);
	}
}

DisplayAchivementDetailsMenu(iClient, iTarget, const String:sName[])
{
	decl Handle:hAchievementData;
	if ( !GetTrieValue(g_hTrie_AchievementData, sName, hAchievementData) ) {
		// this can't be, but maybe...
		LogError("???");
		return;
	}
	
	new iCount = (GetTrieValue(hAchievementData, "count", iCount)?iCount:-1);
	
	new Handle:hPanel = CreatePanel();
	
	decl String:sClientName[32];
	GetClientName(iTarget, SZF(sClientName));
	
	decl String:sBuffer[256], String:sTranslation[64];
	FormatEx(SZF(sBuffer), "%t", "achievement details menu: title", sClientName);
	SetPanelTitle(hPanel, sBuffer);
	
	FormatEx(SZF(sTranslation), "%s: name", sName);
	FormatEx(SZF(sBuffer), "%t%t", "achievement details menu: name", sTranslation);
	DrawPanelText(hPanel, sBuffer);
	
	FormatEx(SZF(sTranslation), "%s: description", sName);
	FormatEx(SZF(sBuffer), "%t%t", "achievement details menu: description", sTranslation, iCount);
	DrawPanelText(hPanel, sBuffer);
	
	FormatEx(SZF(sTranslation), "%s: reward", sName);
	FormatEx(SZF(sBuffer), "%t%t", "achievement details menu: reward", sTranslation);
	DrawPanelText(hPanel, sBuffer);
	
	decl iBuffer;
	if ( !GetTrieValue(g_hTrie_ClientProgress[iTarget], sName, iBuffer) ) {
		iBuffer = 0;
	}
	
	FormatEx(SZF(sBuffer), "%t", "achievement details menu: progress", 
		iBuffer, iCount, (iBuffer/float(iCount))*100);
	DrawPanelText(hPanel, sBuffer);
	
	DrawPanelText(hPanel, " ");
	
	SetPanelCurrentKey(hPanel, g_iExitBackButtonSlot);
	FormatEx(SZF(sBuffer), "%t", "menu: back");
	DrawPanelItem(hPanel, sBuffer);
	
	DrawPanelText(hPanel, " ");
	
	SetPanelCurrentKey(hPanel, g_iExitButtonSlot);
	FormatEx(SZF(sBuffer), "%t", "menu: exit");
	DrawPanelItem(hPanel, sBuffer);
	
	SendPanelToClient(hPanel, iClient, Handler_ShowAchievementDetails, MTF);
	CloseHandle(hPanel);
}