
Handle GetSQLHandle() {
	return hSQL_DB;
}

void SetSQLHandle(Handle:hndl) {
	hSQL_DB = CloneHandle(hndl);
}

void ConnectToDB() {
	if(GetSQLHandle() != INVALID_HANDLE)
	{
		CloseHandle(GetSQLHandle());
		SetSQLHandle(INVALID_HANDLE);
	}

	if(SQL_CheckConfig("nc_rpg"))
		SQL_TConnect(CallBackConnectToDB, "nc_rpg");
	else if(SQL_CheckConfig("default"))
		SQL_TConnect(CallBackConnectToDB, "default");
	else if(SQL_CheckConfig("storage-local"))
		SQL_TConnect(CallBackConnectToDB, "storage-local");
	else
		NCRPg_LogPrint(LogType_FailState, "Could not connect to database, reason: no config entry found for 'nc_rpg' in databases.cfg");
}

public CallBackConnectToDB(Handle owner, Handle hndl, const char[] error, any:data) {
	if(hndl == INVALID_HANDLE)
	{
		NCRPg_LogPrint(LogType_FailState, "Could not connect to database, reason: %s", error);
		return;
	}

	SetSQLHandle(CloneHandle(hndl));
	if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Normal, "Successfully connected to database");
	CreateTable();
	API_OnConnectedToDB(hndl);	
}

void CreateTable() {
	if(GetSQLHandle() == INVALID_HANDLE)
	{
		NCRPg_LogPrint(LogType_FailState, "Could not create the table, reason: Unable to connect the database");
		return;
	}
	SQL_LockDatabase(GetSQLHandle());
	char query[256];
	Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS nc_rpg (steamid VARCHAR(%d) NOT NULL PRIMARY KEY, name VARCHAR(%d) NOT NULL, level INTEGER(%d) DEFAULT '1', xp INTEGER(%d) DEFAULT '0', reqxp INTEGER(%d) DEFAULT '0', credits INTEGER(%d) DEFAULT '0', lastconnect INTEGER(32))",
									MAX_STEAMID_LENGTH, MAX_NAME_LENGTH, MAX_LEVEL_LENGTH, MAX_XP_LENGTH, MAX_XP_LENGTH, MAX_CREDITS_LENGTH);
	SQL_TQuery(GetSQLHandle(), CallBackCreateTable, query, _, DBPrio_High);
	SQL_UnlockDatabase(GetSQLHandle());
}

public CallBackCreateTable(Handle owner, Handle hndl, const char[] error, any:data) {
	if(hndl == INVALID_HANDLE)
	{
		NCRPg_LogPrint(LogType_FailState, "Could not create the table, reason: %s", error);
		return;
	}
	
	RegistrationSkills();
}


void RegistrationSkills() {
	if(GetSQLHandle() == INVALID_HANDLE)
	{
		return;
	}
	API_OnRegisterSkills();
	char buffer[MAX_SHORTNAME_LENGTH+1]; char buffer2[16]; char maps[MAX_MAPS][PLATFORM_MAX_PATH]; char map[PLATFORM_MAX_PATH];int id;
	GetCurrentMap(map, sizeof map);
	for(id = 0; id < GetSkillCount(); ++id)
	{
		GetSkillShortname(id, buffer, sizeof(buffer));
		Format(buffer, sizeof(buffer), "_%s", buffer);
		Format(buffer2, sizeof(buffer2), "INTEGER(%d)", MAX_SHORTNAME_LENGTH+1);
		CreateColumn(buffer, buffer2);
		for(int i = GetSkillMaps(id, maps)-1; i >= 0; --i)
		if(StrEqual(map, maps[i]))
		{
			DisableSkill(id);
			break;
		}
	}
	if(cfg_iLogDebug)
		PrintToServer("Found %d skills ...", GetSkillCount());
}

bool CreateColumn(const char[] columname, const char[] settings) {
	if(GetSQLHandle() == null)
	{
		NCRPg_LogPrint(LogType_Error, "Could not create column, reason: Unable to connect the database");
		return false;
	}
	
	char query[256];
	Format(query, sizeof(query), "SELECT %s FROM nc_rpg LIMIT 1", columname);
	if(!SQL_FastQuery(GetSQLHandle(), query))
	{
		Format(query, sizeof(query), "ALTER TABLE nc_rpg ADD COLUMN %s %s", columname, settings);
		if(SQL_FastQuery(GetSQLHandle(), query))
		{
			if(cfg_iLogDebug)
				NCRPg_LogPrint(LogType_Error,"[NCRPG] Successfully created column '%s' [%s]", columname, settings);
			return true;
		}
		else
		{
			SQL_GetError(GetSQLHandle(), query, sizeof(query));
			NCRPg_LogPrint(LogType_Error, "Could not create column '%s' [%s], reason: %s", columname, settings, query);
		}
	}
	else
		return true;
	
	return false;
}

int GetSkillCount() {
	return iCountSkills;
}


void ResetSkillCount() 
{
	if(hArraySkills == null) return;
	if(hArraySkills == INVALID_HANDLE) return;
	for(int i = GetArraySize(hArraySkills)-1; i >= 0; --i)
	{
		CloseHandle(GetArrayCell(GetArrayCell(hArraySkills, i), ARR_SKILL_MAPS));
		CloseHandle(GetArrayCell(hArraySkills, i));
	}
	iCountSkills = 0;
	ClearArray(hArraySkills);
}

bool GetSkillShortname(int skillid, char[] buffer,int maxlen) {
	if(IsValidSkillID(skillid))
	{
		int pos = GetSkillArrayPosition(skillid);
		if(pos != -1)
		{
			GetArrayString(GetArrayCell(hArraySkills, pos), ARR_SKILL_SHORTNAME, buffer, maxlen);
			return true;
		}
	}
	
	return false;
}



bool IsValidSkillID(skillid)
{
	if(0 <= skillid < GetSkillCount())
		return true;
	
	return false;
}


void LoadPlayer(int client) {
	if(IsValidPlayer(client))
	{
		if(GetPlayerArrayPosition(client) == -1)
		{
			char buffer[64];
			if(GetClientSteamID(client, buffer, sizeof(buffer)))
			{
				if(!cfg_bBotSave && IsFakeClient(client)) return;
				Handle array = CreateArray(ByteCountToCells(sizeof(buffer)));
				PushArrayCell(hArrayPlayers, array);
				PushArrayCell(array, client);	// Player index
				PushArrayString(array, buffer);	// SteamID
												// Name
				PushArrayCell(array, -1);		// XP
				PushArrayCell(array, -1);		// REQXP
				PushArrayCell(array, -1);		// Level
				PushArrayCell(array, -1);		// Credits
				
				for(int skill = 0; skill < GetSkillCount(); skill++)
					PushArrayCell(array, 0);
				
				
				
				int pos = GetPlayerArrayPosition(client);
				if(pos == -1)
				{
					if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Error, "Could not load the player, reason: The player is not found in the array");
					return;
				}
				
				
				Format(buffer, sizeof(buffer), "SELECT * FROM nc_rpg WHERE SteamID = '%s'", buffer);
				SQL_TQuery(GetSQLHandle(), CallBackLoadPlayer, buffer, client);
			}
			else
				if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Error, "Could not load the player, reason: Failed to get SteamID");
		}
	}
}

void ResetPlayerEx(int client) {
	int pos;
	AuthControl[client] = false;
	if((pos = GetPlayerArrayPosition(client)) != -1)
		RemoveFromArray(hArrayPlayers, pos);
}

int SQL_FetchIntByName(Handle hndl, const char[] columnname, &DBResult:result = DBVal_Error) {
	int column;
	SQL_FieldNameToNum(hndl, columnname, column);
	return SQL_FetchInt(hndl,column, result);
}

public CallBackLoadPlayer(Handle owner, Handle hndl, const char[] error, any:client) {
	if(hndl == null)
	{
		ResetPlayerEx(client);
		if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Error, "Could not load the player, reason: %s", error);
		return;
	}
	
	if(!IsValidPlayer(client))
	{
		if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Error, "Could not load the player, reason: Invalid player (%i)", client);
		if(IsClientConnected(client) && IsClientInGame(client))
			KickClient(client,"ошибка загрузки.\n попробуй еще раз");
		return;
	}
	
	int count;
	while(SQL_FetchRow(hndl))
	{	
		SetLevel(client, SQL_FetchIntByName(hndl, "level"));
		SetXP(client, SQL_FetchIntByName(hndl, "xp"));
		SetReqXP(client, SQL_FetchIntByName(hndl, "reqxp"));
		SetCredits(client, SQL_FetchIntByName(hndl, "credits"));
		
		char buffer[MAX_SHORTNAME_LENGTH];
		for(int id = 0; id < GetSkillCount(); ++id)
		{
			GetSkillShortname(id, buffer, sizeof(buffer));
			Format(buffer, sizeof(buffer), "_%s", buffer);
			SetSkillLevel(client, id, SQL_FetchIntByName(hndl, buffer));
		}
		API_OnClientLoaded(client, ++count);
	}
	
	if(!count)
		InsertPlayerInDB(client);
	AuthControl[client] = true;
	if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Error, "Player %N load and authorization",client);
}

int GetSkillMaps(int skillid, char[][] buffer) {
	if(IsValidSkillID(skillid))
	{
		int pos = GetSkillArrayPosition(skillid);
		if(pos != -1)
		{
			Handle array = GetArrayCell(GetArrayCell(hArraySkills, pos), ARR_SKILL_MAPS);
			char tmp[PLATFORM_MAX_PATH];
			for(int i = GetSkillMapsCount(skillid)-1; i >= 0; --i)
			{
				GetArrayString(array, i, tmp, sizeof tmp);
				strcopy(buffer[i], PLATFORM_MAX_PATH, tmp);
			}
			
			return GetSkillMapsCount(skillid);
		}
	}
	
	return -1;
}
// Ex

int GetSkillMapsCount(int skillid) {
	return GetArraySize(GetArrayCell(GetArrayCell(hArraySkills, skillid), ARR_SKILL_MAPS));
}

int SetXP(int client,int xp) {
	int pos = GetPlayerArrayPosition(client);
	if(pos != -1)
	{
		SetArrayCell(GetArrayCell(hArrayPlayers, pos), ARR_XP, (xp >= -1)?xp:-2);
		return xp;
	}
	
	return -1;
}

int GetXP(int client) {
	int pos = GetPlayerArrayPosition(client);
	if(pos != -1)
		return GetArrayCell(GetArrayCell(hArrayPlayers, pos), ARR_XP);
		
	return -1;
}

int SetLevel(int client,int level) {
	int pos = GetPlayerArrayPosition(client);
	if(pos != -1)
	{
		SetArrayCell(GetArrayCell(hArrayPlayers, pos), ARR_LEVEL, (level >= -1)?level:-2);
		return level;
	}
	
	return -1;
}

int SetReqXP(int client,int xp) {
	int pos = GetPlayerArrayPosition(client);
	if(pos != -1)
	{
		SetArrayCell(GetArrayCell(hArrayPlayers, pos), ARR_REQXP, (xp >= -1)?xp:-2);
		return xp;
	}
	
	return -1;
}

int GetReqXP(int client) {
	int pos = GetPlayerArrayPosition(client);
	if(pos != -1)
		return GetArrayCell(GetArrayCell(hArrayPlayers, pos), ARR_REQXP);
		
	return -1;
}


int GetLevel(int client) {
	int pos = GetPlayerArrayPosition(client);
	if(pos != -1)
		return GetArrayCell(GetArrayCell(hArrayPlayers, pos), ARR_LEVEL);
		
	return -1;
}

int SetCredits(int client,int credits) {
	int pos = GetPlayerArrayPosition(client);
	if(pos != -1)
	{
		SetArrayCell(GetArrayCell(hArrayPlayers, pos), ARR_CREDITS, (credits >= -1)?credits:-2);
		return credits;
	}
	
	return -1;
}

int GetCredits(int client) {
	int pos = GetPlayerArrayPosition(client);
	if(pos != -1)
		return GetArrayCell(GetArrayCell(hArrayPlayers, pos), ARR_CREDITS);
		
	return -1;
}

int SetSkillLevel(int client,int skillid,int level) {
	if(IsValidSkillID(skillid))
	{
		int pos = GetPlayerArrayPosition(client);
		if(pos != -1)
		{
			SetArrayCell(GetArrayCell(hArrayPlayers, pos), ARR_SKILLS+skillid, level);
			return level;
		}
	}
	
	return -1;
}

int GetSkillLevel(int client,int skillid) {
	if(IsValidSkillID(skillid))
	{
		int pos = GetPlayerArrayPosition(client);
		if(pos != -1)
			return GetArrayCell(GetArrayCell(hArrayPlayers, pos), ARR_SKILLS+skillid);
	}
		
	return -1;
}



//db

void InsertPlayerInDB(int client) {
	int pos = GetPlayerArrayPosition(client);
	if(pos == -1)
	{
		if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Error, "Could not create the player, reason: The player is not found in the array");
		return;
	}
	
	char auth[MAX_STEAMID_LENGTH];
	if(!GetClientSteamID(client, auth, sizeof(auth)))
	{
		if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Error, "Could not create the player, reason: Could not get client %d SteamID", client);
		return;
	}
	
	char buffer[MAX_STEAMID_LENGTH]; char query[8192];
	Format(query, sizeof(query), "INSERT INTO nc_rpg (steamid, name, level, xp, reqxp, credits, lastconnect");
	for(int id = 0; id < GetSkillCount(); id++)
	{
		GetSkillShortname(id, buffer, sizeof(buffer));
		Format(query, sizeof(query), "%s, _%s", query, buffer);
	}
	
	GetClientName(client, buffer, sizeof(buffer));
	ReplaceString(buffer, sizeof(buffer), "'", "", false);
	Format(query, sizeof(query), "%s) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d'",
								query, auth, buffer, SetLevel(client, 1), SetXP(client, 0), SetReqXP(client, cfg_iExpStart), SetCredits(client, cfg_iCreditsStart), GetTime());
	for(int id = 0; id < GetSkillCount(); id++)
		Format(query, sizeof(query), "%s, %d", query, 0);
	Format(query, sizeof(query), "%s)", query);
	
	if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Debug, "Insert query: %s", query);
	SQL_TQuery(GetSQLHandle(), CallBackInsertPlayer, query, client);
}

public CallBackInsertPlayer(Handle owner, Handle hndl, const char[] error, any:client) {
	if(hndl == null)
	{
		NCRPg_LogPrint(LogType_Error, "Could not create the player, reason: %s", error);
		return;
	}
	API_OnClientLoaded(client, -1);
}

void LoadSkill(int skillid, const char[] shortname) {
	char buffer[128],client;
	for(client = 1; client <= MaxClients; ++client)
	{
		if(IsValidPlayer(client))
		{
			int pos = GetPlayerArrayPosition(client);
			if(pos == -1)
				continue;
			
			Handle tmp = CreateArray();
			Handle array = GetArrayCell(hArrayPlayers, pos);
			PushArrayCell(tmp, array);
			// Если не существует массива скила у игрока, то создаем
			if(ARR_SKILLS+skillid >= GetArraySize(array))
				PushArrayCell(tmp, PushArrayCell(array, 0));
			
			GetArrayString(array, ARR_STEAMID, buffer, sizeof buffer);
			Format(buffer, sizeof buffer, "SELECT _%s FROM nc_rpg WHERE SteamID = '%s'", shortname, buffer);
			SQL_TQuery(GetSQLHandle(), CallBackLoadSkill, buffer, tmp);
		}	
	}
}

public CallBackLoadSkill(Handle owner, Handle hndl, const char[] error, any:array) {
	if(hndl == null)
	{
		if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Error, "Could not load skill, reason: %s", error);
		return;
	}
	
	SetArrayCell(GetArrayCell(array, 0), GetArrayCell(array, 1), SQL_FetchInt(hndl, 0));
	CloseHandle(array);
}

void LoadAllPlayers() {
	for(int client = 1; client <= MaxClients; client++)
		LoadPlayer(client);
}

stock void SaveAllPlayers() {
	for(int client = 1; client <= MaxClients; client++)
		SavePlayer(client);
}

void SavePlayer(client) {
	if(IsValidPlayer(client))
	{
		if(AuthControl[client])
		{
			int pos = GetPlayerArrayPosition(client);
			if(pos != -1)
			{
				char query[8192]; char buffer[MAX_STEAMID_LENGTH];
				GetClientName(client, query, sizeof(query));
				ReplaceString(query, sizeof(query), "'", "");
				Format(query, sizeof(query), "name = '%s', level = '%d', xp = '%d', reqxp = '%d', credits = '%d', lastconnect = '%d'", query, GetLevel(client), GetXP(client), GetReqXP(client), GetCredits(client), GetTime());
				for(int id = 0; id < GetSkillCount(); id++)
				{
					GetSkillShortname(id, buffer, sizeof(buffer));
					Format(query, sizeof(query), "%s, _%s = '%d'", query, buffer, GetSkillLevel(client, id));
				}
				GetArrayString(GetArrayCell(hArrayPlayers, pos), ARR_STEAMID, buffer, sizeof(buffer));
				Format(query, sizeof(query), "UPDATE nc_rpg SET %s WHERE steamid = '%s'", query, buffer);
				SQL_TQuery(GetSQLHandle(), CallBackSavePlayer, query, client, DBPrio_Normal);
			}
		}
		else
		{
			if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Error, "Error save Player %N . Player is not load.. ",client);
		}
	}

}

public CallBackSavePlayer(Handle owner, Handle hndl, const char[] error, any:client) {
	if(hndl == null)
	{
		ResetPlayerEx(client);
		if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Error, "Could not save the player, reason: %s", error);
		return;
	}
}


int RegSkill(char shortname[MAX_SHORTNAME_LENGTH],int maxlevel,int cost,int icost, bool cfg = true, bool disabled = false) { //, bool trans = true) {
	if(hArraySkills == null)
		return -1;
	
	if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Error, "[DEBUG] RegSkill: %s", shortname);
	if(StrEqual(shortname, "empty"))
	{
		if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Error, "Backing the word 'empty'");
		return -1;
	}
	
	char buffer[PLATFORM_MAX_PATH];
	int empty = -1;
	for(int i = 0; i < GetSkillCount(); ++i)
	{
		if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Error, "[DEBUG] %s: GetSkillCount == %d", shortname, GetSkillCount());
		GetSkillShortname(i, buffer, sizeof buffer);
		if(StrEqual(shortname, buffer, false))
		{
			NCRPg_LogPrint(LogType_Error, "Two identical skills: %s", buffer);
			return -1;
		}
		
		// Если есть пустое место
		if(empty == -1 && StrEqual(buffer, "empty"))
		{
			empty = i;
			if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Debug, "Empty skill index %d", empty);
		}
	}
	Handle maps = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));
	if(cfg)
	{
		KeyValues kv = NCRPG_LoadConfigFile(shortname,CONFIG_SKILL);
		maxlevel = GetConfigValue(kv,shortname,"maxlevel",maxlevel);
		cost = GetConfigValue(kv,shortname,"cost",cost);
		icost = GetConfigValue(kv,shortname,"icost",icost);
		disabled = GetConfigValue(kv,shortname,"disabled",disabled)?true:false;
		char tmp2[MAX_MAPS][64];
		char tmp[MAX_MAPS * sizeof(tmp2[])];
		int count;
		GetConfigValueString(kv,shortname,"maps", tmp,sizeof tmp,"map1,map2");
		if(!StrEqual(tmp,"map1,map2") || !StrEqual(tmp,""))
		{
			count = ExplodeString(tmp, ",", tmp2, MAX_MAPS, sizeof tmp2[]);
			if(count)	for(int i = 0; i < count; ++i)	PushArrayString(maps, tmp2[i]);
		}
		NCRPG_SaveConfigFile(kv,shortname,CONFIG_SKILL);
	}
	Handle array;
	if(empty != -1)
	{
		array = GetArrayCell(hArraySkills, empty);
		
		SetArrayCell(array, ARR_SKILL_ID, empty);
		SetArrayCell(array, ARR_SKILL_DISABLED, disabled);
		SetArrayString(array, ARR_SKILL_SHORTNAME, shortname);
		SetArrayCell(array, ARR_SKILL_MAXLEVEL, maxlevel);
		SetArrayCell(array, ARR_SKILL_COST, cost);
		SetArrayCell(array, ARR_SKILL_ICOST, icost);
		SetArrayCell(array, ARR_SKILL_MAPS, maps);
		
		LoadSkill(empty, shortname);
		
		return empty;
	}
	
	array = CreateArray(MAX_SHORTNAME_LENGTH);
	
	PushArrayCell(array, iCountSkills);		// ARR_SKILL_ID
	PushArrayCell(array, disabled);			// ARR_SKILL_DISABLED
	PushArrayString(array, shortname);		// ARR_SKILL_SHORTNAME
	PushArrayCell(array, maxlevel);			// ARR_SKILL_MAXLEVEL
	PushArrayCell(array, cost);				// ARR_SKILL_COST
	PushArrayCell(array, icost);			// ARR_SKILL_ICOST
	PushArrayCell(array, maps);				// ARR_SKILL_MAPS
	PushArrayCell(hArraySkills, array);
	LoadSkill(iCountSkills, shortname);
	if(cfg_iLogDebug) NCRPg_LogPrint(LogType_Debug, "[DEBUG] %s: count++ (%d++)", shortname, iCountSkills);
	return iCountSkills++;
}


int GetEmptySkills(int pos = -1) {
	char buffer[MAX_SHORTNAME_LENGTH]; 
	int count = 0;
	for(int i = (pos == -1)?(GetArraySize(hArraySkills)-1):pos; i >= 0; --i)
	{
		GetArrayString(GetArrayCell(hArraySkills, i), ARR_SKILL_SHORTNAME, buffer, sizeof buffer);
		if(StrEqual(buffer, "empty"))
			++count;
	}
	
	return count;
}

void EnableSkill(int index) {
	SetArrayCell(GetArrayCell(hArraySkills, index), ARR_SKILL_DISABLED, false);
}

void DisableSkill(int index, bool remove = false) {
	if(index==-1) return;
	SetArrayCell(GetArrayCell(hArraySkills, index), ARR_SKILL_DISABLED, true);
	if(remove)
	{
		SaveAllPlayers();
		SetArrayString(GetArrayCell(hArraySkills, index), ARR_SKILL_SHORTNAME, "empty");
		CloseHandle(GetArrayCell(GetArrayCell(hArraySkills, index), ARR_SKILL_MAPS));
	}
}

bool IsSkillDisabled(int index,int client = 0) {
	if(index==-1 )return true;
	if(!GetArrayCell(GetArrayCell(hArraySkills, index), ARR_SKILL_DISABLED))
	{
		if(client > 0)
			return true;
		
		return false;
	}
	return true;
	
	//return GetArrayCell(GetArrayCell(hArraySkills, index), ARR_SKILL_DISABLED);
}

int FindSkillByShortname(const char[] shortname) {
	if(hArraySkills == null)
		return -1;
	
	char buffer[MAX_SHORTNAME_LENGTH];
	for(new i = GetArraySize(hArraySkills)-1; i >= 0; --i)
	{
		GetArrayString(GetArrayCell(hArraySkills, i), ARR_SKILL_SHORTNAME, buffer, MAX_SHORTNAME_LENGTH);
		if(StrEqual(shortname, buffer))
			return i;
	}
	
	return -1;
}

// Not Safe query
bool GetParamStringBySteamID(const char[] steamid,const char[] param, char[] buffer, int maxlen) 
{
	if(GetSQLHandle() == null)
	{
		NCRPg_LogPrint(LogType_Error, "Could not find %s from %s, reason: Unable to connect the database",param,steamid);
		return false;
	}
	bool ret =  false;
	char szQuery[128];
	FormatEx( szQuery, sizeof( szQuery ),"SELECT %s FROM nc_rpg WHERE steamid='%s'",param,steamid);
	DBResultSet query = SQL_Query( GetSQLHandle(), szQuery, sizeof(szQuery));
	if (query == null)
	{
		char error[255];
		SQL_GetError(GetSQLHandle(), error, sizeof(error));
		NCRPg_LogPrint(LogType_Error, error);
	}
	else {
		if(!query.HasResults) ret = false;
		while(SQL_FetchRow(query)){ SQL_FetchString(query, 0,buffer,maxlen); ret=true;}
		delete query; 
	}
	return ret;
}

int GetParamIntBySteamID(const char[] steamid,char[] param) 
{
	if(GetSQLHandle() == null)
	{
		NCRPg_LogPrint(LogType_Error, "Could not get %s from %s. Reason: Unable to connect the database",param,steamid);
		return false;
	}
	char szQuery[128];
	int ret = -1;
	FormatEx( szQuery, sizeof( szQuery ),"SELECT %s FROM nc_rpg WHERE steamid='%s'",param,steamid);
	DBResultSet query = SQL_Query( GetSQLHandle(), szQuery, sizeof(szQuery));
	if (query == null)
	{
		char error[255];
		SQL_GetError(GetSQLHandle(), error, sizeof(error));
		NCRPg_LogPrint(LogType_Error, error);
	}
	else {
		if(SQL_IsFieldNull(query,0)) ret = -1;
		while(SQL_FetchRow(query)){ ret = SQL_FetchInt(query, 0); }
		delete query; 
	}
	return ret;
}

int SetParamIntBySteamID(const char[] steamid,char[] param,int value) 
{
	if(GetSQLHandle() == null)
	{
		NCRPg_LogPrint(LogType_Error, "Could not set %s from %s. Reason: Unable to connect the database",param,steamid);
		return false;
	}
	char szQuery[128];
	FormatEx( szQuery, sizeof( szQuery ),"UPDATE nc_rpg SET %s ='%d' WHERE steamid='%s'",param,value,steamid);
	if(!SQL_FastQuery( GetSQLHandle(), szQuery, sizeof(szQuery)))
	{
		char error[255];
		SQL_GetError(GetSQLHandle(), error, sizeof(error));
		NCRPg_LogPrint(LogType_Error, error);
		value = -1;
	}
	
	return value;
}



#pragma deprecated Use GetPlayerArrayPosition() instead
stock bool IsClientLoaded(int client) {
	return (GetPlayerArrayPosition(client) == -1)?false:true;
}
