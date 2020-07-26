LoadAchivements()
{
	decl String:sPath[PMP];
	BuildPath(Path_SM, SZF(sPath), "configs/achievements.txt");
	
	new Handle:hKeyValues = CreateKeyValues("achievements");
	if ( !FileToKeyValues(hKeyValues, sPath) ) {
		LogError("File \"%s\" not found", sPath);
		SetFailState("File \"%s\" not found", sPath);
	}
	if ( !KvGotoFirstSubKey(hKeyValues) ) {
		LogError("File \"%s\" empty or broken", sPath);
		SetFailState("File \"%s\" empty or broken", sPath);
	}
	
	new Handle:hHookedClientEvents = CreateTrie(),	
		Handle:hHookedAttackerEvents = CreateTrie();
	
	// reload will result in memory leak
	g_hArray_sAchievementNames = CreateArray(ByteCountToCells(64));
	g_hTrie_AchievementData = CreateTrie();
	g_hTrie_EventAchievements = CreateTrie();
	
	decl Handle:hAchievementData, Handle:hEventsArray, String:sName[64], String:sBuffer[256], String:sExecutor[16], iBuffer;
	do {
		KvGetSectionName(hKeyValues, SZF(sName));
		if ( GetTrieValue(g_hTrie_AchievementData, sName, hAchievementData) ) {
			LogError("Duplicate achievement name \"%s\"", sName);
			continue;
		}
		
		hAchievementData = CreateTrie();
		KvGetString(hKeyValues, "event", SZF(sBuffer));
		if ( !GetTrieValue(g_hTrie_EventAchievements, sBuffer, hEventsArray) ) {
			hEventsArray = CreateArray(ByteCountToCells(64));
			SetTrieValue(g_hTrie_EventAchievements, sBuffer, hEventsArray);
		}
		PushArrayString(hEventsArray, sName);
		
		KvGetString(hKeyValues, "executor", SZF(sExecutor));
		if ( strcmp(sExecutor, "userid") == 0 ) {
			if ( !GetTrieValue(hHookedClientEvents, sBuffer, iBuffer) && !HookEventEx(sBuffer, Event_ClientCallback) ) {
				LogError("Invalid event name \"%s\"", sBuffer);
				continue;
			}
			SetTrieValue(hHookedClientEvents, sBuffer, 1);
		}
		else if ( strcmp(sExecutor, "attacker") == 0 ) {
			if ( !GetTrieValue(hHookedAttackerEvents, sBuffer, iBuffer) && !HookEventEx(sBuffer, Event_AttackerCallback) ) {
				LogError("Invalid event name \"%s\"", sBuffer);
				continue;
			}
			SetTrieValue(hHookedAttackerEvents, sBuffer, 1);
		}
		else {
			// all modules now should have unsupported executor
			// LogError("Unsupported executor \"%s\"", sExecutor);
			// continue;
		}
		
		SetTrieString(hAchievementData, "event", sBuffer);
		SetTrieString(hAchievementData, "executor", sExecutor);
		
		KvGetString(hKeyValues, "reward", SZF(sBuffer));
		SetTrieString(hAchievementData, "reward", sBuffer);
		
		KvGetString(hKeyValues, "condition", SZF(sBuffer));
		SetTrieString(hAchievementData, "condition", sBuffer);
		
		SetTrieValue(hAchievementData, "count", KvGetNum(hKeyValues, "count", 666));
		
		SetTrieValue(g_hTrie_AchievementData, sName, hAchievementData);
		PushArrayString(g_hArray_sAchievementNames, sName);
		
		Call_StartForward(g_hForward_OnConfigSectionReaded);
		Call_PushCell(hKeyValues);
		Call_PushString(sName);
		Call_Finish();
		
	} while ( KvGotoNextKey(hKeyValues) );
	
	CloseHandle(hHookedClientEvents);
	CloseHandle(hHookedAttackerEvents);
	CloseHandle(hKeyValues);
	
	g_iTotalAchievements = GetArraySize(g_hArray_sAchievementNames);
}