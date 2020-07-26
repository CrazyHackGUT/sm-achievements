public Event_ClientCallback(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	new iClient = CID(GetEventInt(hEvent, "userid"));
	ProcessEvents(iClient, hEvent, sEventName);
}

public Event_AttackerCallback(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	new iClient = CID(GetEventInt(hEvent, "attacker"));
	if ( iClient > 0 && iClient <= MaxClients ) {
		ProcessEvents(iClient, hEvent, sEventName);
	}
}

ProcessEvents(iClient, Handle:hEvent, const String:sEventName[])
{
	decl Handle:hEventArray;
	if ( !GetTrieValue(g_hTrie_EventAchievements, sEventName, hEventArray) ) {
		return;
	}
	
	decl Handle:hAchievementData, String:sName[64], String:sBuffer[256], String:sParts[8][256], bool:bUpdate, bool:bFlag, iBuffer, iCount, iParts;
	new iLength = GetArraySize(hEventArray);
	for ( new i = 0; i < iLength; ++i ) {
		GetArrayString(hEventArray, i, SZF(sName));
		if ( !GetTrieValue(g_hTrie_AchievementData, sName, hAchievementData) ) {
			// this can't be, but maybe...
			LogError("???");
			continue;
		}
		
		bFlag = true;
		bUpdate = false;
		iCount = 0;
		
		bUpdate = GetTrieValue(g_hTrie_ClientProgress[iClient], sName, iCount);
		GetTrieValue(hAchievementData, "count", iBuffer);
		
		if ( iCount < iBuffer ) {
			GetTrieString(hAchievementData, "condition", SZF(sBuffer));
			iParts = ExplodeString(sBuffer, ",", sParts, sizeof(sParts), sizeof(sParts[]));
			
			for (new j = 0; j < iParts; ++j ) {
				if ( !CheckCondition(sParts[j], hEvent) ) {
					bFlag = false;
					break;
				}
			}
			
			if ( bFlag ) {
				iCount++;
				SetTrieValue(g_hTrie_ClientProgress[iClient], sName, iCount);
				SaveProgress(iClient, sName, bUpdate);
				
				if ( iCount >= iBuffer ) {
					decl String:sTranslation[64], String:sClientName[32];
					GetClientName(iClient, SZF(sClientName));
					FormatEx(SZF(sTranslation), "%s: name", sName);
					Format(SZF(sTranslation), "%t", sTranslation);
					PrintToChatAll("%t", "client got achievement", sClientName, sTranslation);
					GiveReward(iClient, sName);
					CreateProgressMenu(iClient);
					
					Call_StartForward(g_hForward_OnGotAchievement);
					Call_PushCell(iClient);
					Call_PushString(sName);
					Call_Finish();
				}
			}
		}
	}
}

bool:CheckCondition(String:sCondition[], Handle:hEvent)
{
	TrimString(sCondition);
	
	decl String:sConditionParts[3][128];
	new iParts = ExplodeString(sCondition, " ", sConditionParts, sizeof(sConditionParts), sizeof(sConditionParts[]));
	
	switch (iParts) {
		case 1: {
			if ( sCondition[0] ) {
				return ( GetEventBool(hEvent, sCondition) );
			}
			else {
				return true;
			}
		}
		
		case 3: {
			if ( IsCharNumeric(sConditionParts[2][0]) ) {
				switch (sConditionParts[1][0]) {
					case '=': {
						decl String:sParts[3][16];
						new partsCount = ExplodeString(sConditionParts[2], "|", sParts, sizeof(sParts), sizeof(sParts[]));
						if ( partsCount == 1 ) {
							return (GetEventInt(hEvent, sConditionParts[0])==StringToInt(sConditionParts[2]));
						}
						else {
							new buffer = GetEventInt(hEvent, sConditionParts[0]);
							for ( new i = 0; i < partsCount; ++i ) {
								if ( buffer == StringToInt(sParts[i]) ) {
									return true;
								}
							}
							return false;
						}
					}
					case '>': {
						return (GetEventInt(hEvent, sConditionParts[0])>StringToInt(sConditionParts[2]));
					}
					case '<': {
						return (GetEventInt(hEvent, sConditionParts[0])<StringToInt(sConditionParts[2]));
					}
				}
			}
			else {
				decl String:sParts[8][16];
				new partsCount = ExplodeString(sConditionParts[2], "|", sParts, sizeof(sParts), sizeof(sParts[]));
				if ( partsCount == 1 ) {
					decl String:eventValue[16];
					GetEventString(hEvent, sConditionParts[0], SZF(eventValue));
					return (!strcmp(eventValue, sConditionParts[2]));
				}
				else {
					decl String:eventValue[16];
					GetEventString(hEvent, sConditionParts[0], SZF(eventValue));
					for ( new i = 0; i < partsCount; ++i ) {
						if ( !strcmp(eventValue, sParts[i]) ) {
							return true;
						}
					}
					return false;
				}
				
			}
		}
		
		default: {
			LogError("Invalid condition: \"%s\"", sCondition);
			return false;
		}
	}
	
	return true;
}