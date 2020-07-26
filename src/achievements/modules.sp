public Native_ProcessEvent(Handle:hPlugin, iParamNum)
{
	new iClient = GetNativeCell(1),
		Handle:hTrie = GetNativeCell(2);
		
	decl String:sEventName[64];
	GetNativeString(3, SZF(sEventName));
	
	ProcessModule(iClient, hTrie, sEventName);
}

ProcessModule(iClient, Handle:hTrie, const String:sEventName[])
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
				if ( !CheckModuleCondition(sParts[j], hTrie) ) {
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

bool:CheckModuleCondition(String:sCondition[], Handle:hTrie)
{
	TrimString(sCondition);
	
	decl String:sConditionParts[3][128];
	new iParts = ExplodeString(sCondition, " ", sConditionParts, sizeof(sConditionParts), sizeof(sConditionParts[]));
	
	switch (iParts) {
		case 1: {
			decl iBuffer;
			if ( sCondition[0] ) {
				if ( !GetTrieValue(hTrie, sCondition, iBuffer) ) {
					LogError("Invalid field for condition \"%s\"", sCondition);
					return false;
				}
				
				return ( iBuffer?true:false );
			}
			else {
				return true;
			}
		}
		
		case 3: {
			if ( IsCharNumeric(sConditionParts[2][0]) ) {
				decl iBuffer;
				switch (sConditionParts[1][0]) {
					case '=': {
						decl String:sParts[3][16];
						new partsCount = ExplodeString(sConditionParts[2], "|", sParts, sizeof(sParts), sizeof(sParts[]));
						if ( partsCount == 1 ) {
							if ( !GetTrieValue(hTrie, sConditionParts[0], iBuffer) ) {
								LogError("Invalid field \"%s\" for condition \"%s\"", sConditionParts[0], sCondition);
								return false;
							}
							
							return (iBuffer==StringToInt(sConditionParts[2]));
						}
						else {
							if ( !GetTrieValue(hTrie, sConditionParts[0], iBuffer) ) {
								LogError("Invalid field \"%s\" for condition \"%s\"", sConditionParts[0], sCondition);
								return false;
							}
							
							for ( new i = 0; i < partsCount; ++i ) {
								if ( iBuffer == StringToInt(sParts[i]) ) {
									return true;
								}
							}
							return false;
						}
					}
					case '>': {
						if ( !GetTrieValue(hTrie, sConditionParts[0], iBuffer) ) {
							LogError("Invalid field \"%s\" for condition \"%s\"", sConditionParts[0], sCondition);
							return false;
						}
							
						return (iBuffer>StringToInt(sConditionParts[2]));
					}
					case '<': {
						if ( !GetTrieValue(hTrie, sConditionParts[0], iBuffer) ) {
							LogError("Invalid field \"%s\" for condition \"%s\"", sConditionParts[0], sCondition);
							return false;
						}
						
						return (iBuffer<StringToInt(sConditionParts[2]));
					}
				}
			}
			else {
				decl String:sParts[8][16], String:sBuffer[128];
				new partsCount = ExplodeString(sConditionParts[2], "|", sParts, sizeof(sParts), sizeof(sParts[]));
				if ( partsCount == 1 ) {
					if ( !GetTrieString(hTrie, sConditionParts[0], SZF(sBuffer)) ) {
						LogError("Invalid field \"%s\" for condition \"%s\"", sConditionParts[0], sCondition);
						return false;
					}
						
					return (!strcmp(sBuffer, sConditionParts[2]));
				}
				else {
					if ( !GetTrieString(hTrie, sConditionParts[0], SZF(sBuffer)) ) {
						LogError("Invalid field \"%s\" for condition \"%s\"", sConditionParts[0], sCondition);
						return false;
					}
					
					for ( new i = 0; i < partsCount; ++i ) {
						if ( !strcmp(sBuffer, sParts[i]) ) {
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