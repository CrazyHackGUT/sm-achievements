new 			g_iViewTarget[MPS];
new 			g_iLastMenuType[MPS];
new 			g_iLastMenuSelection[MPS];

public Handler_AchivementsMenu(Handle:hMenu, MenuAction:action, iClient, iSlot)
{
	switch ( action ) {
		case MenuAction_Select: {
			decl String:sInfo[32];
			GetMenuItem(hMenu, iSlot, SZF(sInfo));
			
			if ( strcmp(sInfo, "own") == 0 ) {
				g_iViewTarget[iClient] = UID(iClient);
				DisplayAchivementsTypeMenu(iClient, iClient);
			}
			else if ( strcmp(sInfo, "players") == 0 ) {
				DisplayPlayersMenu(iClient);
			}
			else {
				LogError("Invalid menu selection \"%s\" (slot %d)", sInfo, iSlot);
			}
		}
		
		case MenuAction_End: {
			CloseHandle(hMenu);
		}
	}
}

public Handler_PlayersMenu(Handle:hMenu, MenuAction:action, iClient, iSlot)
{
	switch ( action ) {
		case MenuAction_Select: {
			decl String:sInfo[32];
			GetMenuItem(hMenu, iSlot, SZF(sInfo));
			
			new iUserId = StringToInt(sInfo), 
				iTarget = CID(iUserId);
			
			if ( iTarget ) {
				g_iViewTarget[iClient] = iUserId;
				DisplayAchivementsTypeMenu(iClient, iTarget);
			}
			else {
				PrintToChat(iClient, "%t", "players menu: player left");
				DisplayPlayersMenu(iClient);
			}
		}
		
		case MenuAction_Cancel: {
			if ( iSlot == MenuCancel_ExitBack ) {
				DisplayAchivementsMenu(iClient);
			}
		}
		
		case MenuAction_End: {
			CloseHandle(hMenu);
		}
	}
}

public Handler_AchivementTypeMenu(Handle:hMenu, MenuAction:action, iClient, iSlot)
{
	switch ( action ) {
		case MenuAction_Select: {
			if ( iSlot == g_iExitButtonSlot ) {
				// do nothing
			}
			else {
				new iTarget = CID(g_iViewTarget[iClient]);
				if ( iTarget ) {
					if ( iSlot == 1 ) {
						g_iLastMenuType[iClient] = 1;
						DisplayInProgressMenu(iClient, iTarget);
					}
					else if ( iSlot == 2 ) {
						g_iLastMenuType[iClient] = 2;
						DisplayCompletedMenu(iClient, iTarget);
					}
					else if ( iSlot == g_iExitBackButtonSlot ) {
						if ( iTarget == iClient ) {
							DisplayAchivementsMenu(iClient);
						}
						else {
							DisplayPlayersMenu(iClient);
						}
					}
					else {
						LogError("Invalid menu selection (slot %d)", iSlot);
					}
					
				}
				else {
					PrintToChat(iClient, "%t", "players menu: player left");
					DisplayPlayersMenu(iClient);
				}
			}
			
			
		}
		
		// case MenuAction_Cancel: {
			// if ( iSlot == MenuCancel_ExitBack ) {
				// DisplayAchivementsMenu(iClient);
			// }
		// }
		
		// case MenuAction_End: {
			// CloseHandle(hMenu);
		// }
	}
}

public Handler_ShowAchievements(Handle:hMenu, MenuAction:action, iClient, iSlot)
{
	switch ( action ) {
		case MenuAction_DisplayItem: {
			decl String:sInfo[64];
			GetMenuItem(hMenu, iSlot, SZF(sInfo));
			
			if ( sInfo[0] ) {
				Format(SZF(sInfo), "%s: name", sInfo);
				Format(SZF(sInfo), "%t", sInfo);
			}
			else {
				switch (g_iLastMenuType[iClient]) {
					case 1: {
						FormatEx(SZF(sInfo), "%t", "achievements in progress menu: empty");
					}
					
					case 2: {
						FormatEx(SZF(sInfo), "%t", "completed achievements menu: empty");
					}
					
					default: {
						LogError("Invalid menu type %d", g_iLastMenuType[iClient]);
						g_iLastMenuType[iClient] = 0;
					}
				}
			}
			
			return RedrawMenuItem(sInfo);
		}
		
		case MenuAction_Select: {
			decl String:sInfo[64];
			GetMenuItem(hMenu, iSlot, SZF(sInfo));
			
			new iTarget = CID(g_iViewTarget[iClient]);
			if ( iTarget ) {
				DisplayAchivementDetailsMenu(iClient, iTarget, sInfo);
				g_iLastMenuSelection[iClient] = GetMenuSelectionPosition();
			}
			else {
				PrintToChat(iClient, "%t", "players menu: player left");
				DisplayPlayersMenu(iClient);
			}
		}
		
		case MenuAction_Cancel: {
			if ( iSlot == MenuCancel_ExitBack ) {
				new iTarget = CID(g_iViewTarget[iClient]);
				if ( iTarget ) {
					DisplayAchivementsTypeMenu(iClient, iTarget);
				}
				else {
					PrintToChat(iClient, "%t", "players menu: player left");
					DisplayPlayersMenu(iClient);
				}
			}
		}
	}
	
	return 0;
}

public Handler_ShowAchievementDetails(Handle:hMenu, MenuAction:action, iClient, iSlot)
{
	switch ( action ) {
		case MenuAction_Select: {
			if ( iSlot == g_iExitBackButtonSlot ) {
				new iTarget = CID(g_iViewTarget[iClient]);
				
				if ( iTarget ) {
					switch (g_iLastMenuType[iClient]) {
						case 1: {
							DisplayInProgressMenu(iClient, iTarget, g_iLastMenuSelection[iClient]);
						}
						
						case 2: {
							DisplayCompletedMenu(iClient, iTarget, g_iLastMenuSelection[iClient]);
						}
						
						default: {
							LogError("Invalid menu type %d", g_iLastMenuType[iClient]);
							g_iLastMenuType[iClient] = 0;
						}
					}
				}
				else {
					PrintToChat(iClient, "%t", "players menu: player left");
					DisplayPlayersMenu(iClient);
				}
			}
			else if ( iSlot == g_iExitButtonSlot ) {
				
			}
		}
	}
}
