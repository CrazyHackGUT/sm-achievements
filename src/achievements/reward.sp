GiveReward(iClient, const String:sName[])
{
	decl Handle:hAchievementData, String:sRewardCmd[256], String:sBuffer[64];
	GetTrieValue(g_hTrie_AchievementData, sName, hAchievementData);
	
	if ( GetTrieString(hAchievementData, "reward", SZF(sRewardCmd)) && sRewardCmd[0] ) {
		IntToString(UID(iClient), SZF(sBuffer));
		ReplaceString(SZF(sRewardCmd), "{uid}", sBuffer);
		IntToString(iClient, SZF(sBuffer));
		ReplaceString(SZF(sRewardCmd), "{cid}", sBuffer);
		
		GetClientName(iClient, SZF(sBuffer));
		ReplaceString(SZF(sRewardCmd), "{name}", sBuffer);
		
		ServerCommand(sRewardCmd);
	}
}