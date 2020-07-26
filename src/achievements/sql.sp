new Handle:		g_hSQLdb;

new String:		g_sAuth[MPS][32];

new 			g_iClientId[MPS];

CreateDatabase()
{
	if ( SQL_CheckConfig("achivements") ) {
		SQL_TConnect(SQLT_OnConnect, "achivements");
	}
	else {
		decl String:sError[256];
		g_hSQLdb = SQLite_UseDatabase("achivements", SZF(sError));
		if ( !g_hSQLdb ) {
			LogError("SQLite_UseDatabase failure: \"%s\"", sError);
			SetFailState("SQLite_UseDatabase failure: \"%s\"", sError);
		}
		
		CreateTables();
	}
}

public SQLT_OnConnect(Handle:hOwner, Handle:hQuery, const String:sError[], any:data)
{
	if ( !hQuery ) {
		LogError("SQLT_OnConnect failure: \"%s\"", sError);
		SetFailState("SQLT_OnConnect failure: \"%s\"", sError);
	}
	
	g_hSQLdb = hQuery;
	CreateTables();
}

CreateTables()
{
	// decl String:sQuery[256];
	// FormatEx(SZF(sQuery), "CREATE TABLE IF NOT EXISTS `clients` (`auth` VARCHAR(32), `userid` INTEGER, `last_connection` INTEGER, PRIMARY KEY(`userid`));");
	// SQL_TQuery(g_hSQLdb, SQLT_OnCreateTables, sQuery);
	SQL_TQuery(g_hSQLdb, SQLT_OnCreateTables, "CREATE TABLE IF NOT EXISTS `clients` (`auth` VARCHAR(32), `userid` INTEGER, `last_connection` INTEGER, PRIMARY KEY(`userid`));");
	
	// FormatEx(SZF(sQuery), "CREATE TABLE IF NOT EXISTS `progress` (`userid` INTEGER, `achivement` VARCHAR(64), `count` INTEGER, PRIMARY KEY(`userid`, `achivement`));");
	// SQL_TQuery(g_hSQLdb, SQLT_OnCreateTables, sQuery);
	SQL_TQuery(g_hSQLdb, SQLT_OnCreateTables, "CREATE TABLE IF NOT EXISTS `progress` (`userid` INTEGER, `achivement` VARCHAR(64), `count` INTEGER, PRIMARY KEY(`userid`, `achivement`));");
	
	LC(i) {
		OnClientConnected(i);
		OnClientPutInServer(i);
	}
}

public SQLT_OnCreateTables(Handle:hOwner, Handle:hQuery, const String:sError[], any:data)
{
	if ( !hQuery ) {
		LogError("SQLT_OnCreateTables failure: \"%s\"", sError);
		SetFailState("SQLT_OnCreateTables failure: \"%s\"", sError);
	}
}

LoadClient(iClient)
{
	GetClientAuthId(iClient, AuthId_Steam2, g_sAuth[iClient], sizeof(g_sAuth[]));
	
	decl String:sQuery[256];
	FormatEx(SZF(sQuery), "SELECT `userid` FROM `clients` WHERE `auth` = '%s' LIMIT 1;", g_sAuth[iClient]);
	SQL_TQuery(g_hSQLdb, SQLT_OnLoadClient, sQuery, UID(iClient));
}

public SQLT_OnLoadClient(Handle:hOwner, Handle:hQuery, const String:sError[], any:iUserId)
{
	if ( !hQuery ) {
		LogError("SQLT_OnLoadClient failure: \"%s\"", sError);
		return;
	}
	
	new iClient = CID(iUserId);
	if ( !iClient ) return;
	
	if ( SQL_FetchRow(hQuery) ) {
		g_iClientId[iClient] = SQL_FetchInt(hQuery, 0);
		LoadProgress(iClient);
	}
	else {
		decl String:sQuery[256];
		FormatEx(SZF(sQuery), "INSERT INTO `clients` (`auth`) VALUES ('%s')", g_sAuth[iClient]);
		SQL_TQuery(g_hSQLdb, SQLT_OnSaveClient, sQuery, iUserId);
	}
}

public SQLT_OnSaveClient(Handle:hOwner, Handle:hQuery, const String:sError[], any:iUserId)
{
	if ( !hQuery ) {
		LogError("SQLT_OnSaveClient failure: \"%s\"", sError);
		return;
	}
	
	new iClient = CID(iUserId);
	if ( !iClient ) return;
	
	LoadClient(iClient);
}

LoadProgress(iClient)
{
	decl String:sQuery[256];
	FormatEx(SZF(sQuery), "SELECT `achivement`, `count` FROM `progress` WHERE `userid` = %d;", g_iClientId[iClient]);
	SQL_TQuery(g_hSQLdb, SQLT_OnLoadProgress, sQuery, UID(iClient));
}

public SQLT_OnLoadProgress(Handle:hOwner, Handle:hQuery, const String:sError[], any:iUserId)
{
	if ( !hQuery ) {
		LogError("SQLT_OnLoadProgress failure: \"%s\"", sError);
		return;
	}
	
	new iClient = CID(iUserId);
	if ( !iClient ) return;
	
	decl String:sName[64], iCount;
	while ( SQL_FetchRow(hQuery) ) {
		SQL_FetchString(hQuery, 0, SZF(sName));
		iCount = SQL_FetchInt(hQuery, 1);
		
		SetTrieValue(g_hTrie_ClientProgress[iClient], sName, iCount);
	}
	
	CreateProgressMenu(iClient);
}

SaveProgress(iClient, const String:sName[], bool:bUpdate)
{
	decl iCount;
	GetTrieValue(g_hTrie_ClientProgress[iClient], sName, iCount);
	
	decl String:sQuery[256];
	if ( bUpdate ) {
		FormatEx(SZF(sQuery), "UPDATE `progress` SET `count` = %d WHERE `userid` = %d AND `achivement` = '%s';", iCount, g_iClientId[iClient], sName);
		SQL_TQuery(g_hSQLdb, SQLT_OnUpdateProgress, sQuery);
	}
	else {
		FormatEx(SZF(sQuery), "INSERT INTO `progress` (`userid`, `achivement`, `count`) VALUES (%d, '%s', %d)", g_iClientId[iClient], sName, iCount);
		SQL_TQuery(g_hSQLdb, SQLT_OnInsertProgress, sQuery);
	}
	
}

public SQLT_OnInsertProgress(Handle:hOwner, Handle:hQuery, const String:sError[], any:hDatapack)
{
	if ( !hQuery ) {
		LogError("SQLT_OnInsertProgress failure: \"%s\"", sError);
	}
}

public SQLT_OnUpdateProgress(Handle:hOwner, Handle:hQuery, const String:sError[], any:hDatapack)
{
	if ( !hQuery ) {
		LogError("SQLT_OnUpdateProgress failure: \"%s\"", sError);
	}
}