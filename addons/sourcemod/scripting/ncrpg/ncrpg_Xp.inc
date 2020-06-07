int GiveExp(int client,int exp, bool msg = true, bool checkexp = true, bool minplayers = true, bool maxlevel = true, NCRPG_EventMode event=EVENT_ALL, char[] event_name="") {
	if(IsValidPlayer(client) && AuthControl[client])
	{
		if(!exp)
			return 0;
		
		int level;	
		if(minplayers)
		{
			for(int i = 1; i <= MaxClients; i++)
			if(IsValidPlayer(i))
				if(GetClientTeam(i) >= CS_TEAM_T)
					++level;
					
			if(level < cfg_iMinPlayers)
			{
				NCRPG_ChatMessage(client,"%t", "Minimum players", cfg_iMinPlayers);
				return 0;
			}
		}
		if(event==EVENT_ALL||event== EVENT_PRE)
		{
			if(API_OnPlayerGiveExpPre(client, exp,event_name) >= Plugin_Handled)
			{
				return 0;
			}
		}
		if(checkexp && cfg_iExpMax && exp > cfg_iExpMax)
			exp = cfg_iExpMax;
		
		level = 0;
		int xp = exp+GetXP(client);
		int reqxp = GetReqXP(client);
		while(xp >= reqxp)
		{
			xp -= reqxp;
			level++;
			if(maxlevel && level >= cfg_iMaxLevel)
			{
				xp = 0;
				break;
			}
		}
		if(xp>=0)
			SetXP(client, xp);
		else
			NCRPg_LogPrint(LogType_Error, "Player %N got Negative Xp",client);
		if(msg)
			NCRPG_ChatMessage(client,"%t", "Got XP", exp, GetXP(client), GetReqXP(client));
		
		if(level)
		{
			int clevel = GetLevel(client);
			reqxp = (clevel-1)*cfg_iExpInc+cfg_iExpStart;
			SetReqXP(client,reqxp);
			SetLevel(client,clevel+level);
			xp = level*cfg_iCreditsInc;
			GiveCreditsE(client, xp,_,"levelup");
			int clientlevel = GetLevel(client);
			API_OnPlayerLevelUp(client,clientlevel);
			if(msg)
			{
				NCRPG_ChatMessage(client,"%t", "Got levels", level, clientlevel);
				NCRPG_ChatMessage(client,"%t", "Got credits", xp, GetCredits(client));
			}
		}
		if(event==EVENT_ALL||event== EVENT_POST) API_OnPlayerGiveExpPost(client, exp,event_name);
		return exp;
	}
	else return 0;
}

int GiveExpBySteamID(const char[] steamid,int exp,bool checkexp = true, bool maxlevel = true) {
	if(!exp) return 0;
	
	int level=0;	
	if(checkexp && cfg_iExpMax && exp > cfg_iExpMax)
		exp = cfg_iExpMax;
	
	int xp = exp+GetParamIntBySteamID(steamid,"xp");
	int reqxp = GetParamIntBySteamID(steamid,"reqxp");
	while(xp >= reqxp)
	{
		xp -= reqxp;
		level++;
		if(maxlevel && level >= cfg_iMaxLevel)
		{
			xp = 0;
			break;
		}
	}
	if(level)
	{
		int clevel = GetParamIntBySteamID(steamid,"level");
		reqxp = (clevel-1)*cfg_iExpInc+cfg_iExpStart;
		SetParamIntBySteamID(steamid,"reqxp",reqxp);
		SetParamIntBySteamID(steamid,"level",clevel+level);
		SetParamIntBySteamID(steamid,"credits",clevel+cfg_iCreditsInc);
	}
	if(xp>=0) SetParamIntBySteamID(steamid,"xp",xp);
	return exp;
}

int GiveCreditsE(int client,int credits, NCRPG_EventMode event=EVENT_ALL, char[] event_name="") {
	if(IsValidPlayer(client))
	{
		if(event==EVENT_ALL||event== EVENT_PRE)
		{
			if(API_OnPlayerGiveCreditsPre(client, credits, event_name) >= Plugin_Handled)
			{
				return 0;
			}
		}
		SetCredits(client,GetCredits(client)+credits);
		
		if(event==EVENT_ALL||event== EVENT_POST) API_OnPlayerGiveCreditsPost(client, credits,event_name);
		return credits;
	}
	return 0;
}

int TakeExp(int client,int exp, bool msg = true, bool minplayers = true) {
	if(!exp)
		return 0;
	
	int level;	
	if(minplayers)
	{
		for(int i = 1; i <= MaxClients; i++)
		if(IsValidPlayer(i))
			if(GetClientTeam(i) >= CS_TEAM_T)
				++level;
		
		if(level < cfg_iMinPlayers)
		{
			NCRPG_ChatMessage(client,"%t", "Minimum players", cfg_iMinPlayers);
			return 0;
		}
	}
	
	level = 0;
	int xp = GetXP(client)-exp;
	if(xp < 0)
	{
		do
		{
			if(GetLevel(client) <= 1)
			{
				xp = 0;
				break;
			}
			
			xp += GetReqXP(client)-cfg_iExpStart;
			SetReqXP(client, GetReqXP(client)-cfg_iExpInc);
			SetLevel(client, GetLevel(client)-1);
		}
		while(xp < 0);
		SetXP(client, xp);
	}
	else
		SetXP(client, xp);
	
	if(msg)
		NCRPG_ChatMessage(client,"%t", "Lose XP", exp, GetXP(client), GetReqXP(client));
	
	if(level)
	{
		xp = level*cfg_iCreditsInc;
		SetCredits(client, GetCredits(client)-xp);
		if(msg)
		{
			NCRPG_ChatMessage(client,"%t", "Lose levels", exp, level, GetLevel(client));
			NCRPG_ChatMessage(client,"%t", "Lose credits", exp,xp, GetCredits(client));
		}
	}
	
	return exp;
}


int SetExp(int client,int exp, bool totalXP, bool msg = true, bool checkexp = true, bool minplayers = true, bool maxlevel = true) {
	if(totalXP)
	{
		int total = GetTotalXP(client);
		if(exp > total)
			return GiveExp(client, exp-total, msg, checkexp, minplayers, maxlevel);
		else if(exp < total)
			return TakeExp(client, total-exp, msg, minplayers);
		
		return 0;
	}
	
	int xp = GetXP(client);
	if(exp > xp)
		return GiveExp(client, exp-xp, msg, checkexp, minplayers, maxlevel);
	else if(exp < xp)
		return TakeExp(client, xp-exp, msg, minplayers);
	
	return 0;
}


int TakeExpBySteamID(const char[] steamid,int exp) {
	if(!exp)
		return 0;
	
	int level = 0;
	int xp = GetParamIntBySteamID(steamid,"xp")-exp;
	int clevel =GetParamIntBySteamID(steamid,"level");
	int reqxp =GetParamIntBySteamID(steamid,"reqxp");
	if(xp < 0)
	{
		do
		{
			if(clevel-level <= 1)
			{
				xp = 0;
				break;
			}
			reqxp-=cfg_iExpInc;
			xp = reqxp-xp;
			level++;
		}
		while(xp< 0);
		SetParamIntBySteamID(steamid,"xp",xp);
	}
	else SetParamIntBySteamID(steamid,"xp",xp);
	
	if(level)
	{
		xp = level*cfg_iCreditsInc;
		int cred = GetParamIntBySteamID(steamid,"credits");
		if(cred<xp) cred= 0;
		else cred-=xp;
		SetParamIntBySteamID(steamid,"credits",cred);
	}
	
	return exp;
}

int SetExpBySteamID(const char[] steamid, int exp, bool totalXP, bool checkexp = true, bool maxlevel = true) {
	if(totalXP)
	{
		int total = GetTotalXPBySteamID(steamid);
		if(exp > total)
			return GiveExpBySteamID(steamid, exp-total, checkexp, maxlevel);
		else if(exp < total)
			return TakeExpBySteamID(steamid, total-exp);
		
		return 0;
	}
	
	int xp = GetParamIntBySteamID(steamid,"xp");
	if(exp > xp)
		return GiveExpBySteamID(steamid, exp-xp, checkexp, maxlevel);
	else if(exp < xp)
		return TakeExpBySteamID(steamid, xp-exp);
	
	return 0;
}

int GetTotalXP(client) {
	int xp = GetXP(client)+cfg_iExpStart;	// Last and 1 lvl exp
	for(int level = 2; level < GetLevel(client); level++)
	{
		xp += (level-1)*cfg_iExpInc+cfg_iExpStart;
	}
	
	return xp;
}

int GetTotalXPBySteamID(const char[] steamid) {
	int xp = GetParamIntBySteamID(steamid,"xp")+cfg_iExpStart;	// Last and 1 lvl exp
	int clevel = GetParamIntBySteamID(steamid,"level");
	for(int level = 2; level < clevel; level++)
	{
		xp += (level-1)*cfg_iExpInc+cfg_iExpStart;
	}
	
	return xp;
}

bool GetSkillName(skillid, char[] buffer,int maxlen,int client = 0) {
	if(IsValidSkillID(skillid))
	{
		GetSkillShortname(skillid, buffer, maxlen);
		Format(buffer, maxlen, "%s_Name", buffer);
		Format(buffer, maxlen, "%T", buffer, client);
		return true;
	}
	
	return false;
}

bool GetSkillDesc(int skillid, char[] buffer,int maxlen,int client = 0) {
	if(IsValidSkillID(skillid))
	{
		GetSkillShortname(skillid, buffer, maxlen);
		Format(buffer, maxlen, "%s_Desc", buffer);
		Format(buffer, maxlen, "%T", buffer, client);
		return true;
	}
	
	return false;
}

int GetSkillMaxLevel(int skillid) {
	if(IsValidSkillID(skillid))
	{
		int pos = GetSkillArrayPosition(skillid);
		if(pos != -1)
			return GetArrayCell(GetArrayCell(hArraySkills, pos), ARR_SKILL_MAXLEVEL);
	}
	
	return -1;
}

bool IsValidSkill(int skillid, bool disabled = true)  {
	char buffer[MAX_SHORTNAME_LENGTH];
	if(GetSkillShortname(skillid, buffer, sizeof buffer) && !StrEqual(buffer, "empty"))
	{
		if(disabled && GetArrayCell(GetArrayCell(hArraySkills, skillid), ARR_SKILL_DISABLED))
			return false;
		
		return true;
	}
	
	return false;
}

GetClientSkillCost(client, skillid) {
	return GetSkillCost(skillid, GetSkillLevel(client, skillid));
}

int GetSkillCost(int skillid, int level = 0) 
{
	if(IsValidSkillID(skillid))
	{
		int pos = GetSkillArrayPosition(skillid);
		if(pos != -1)
		{
			if(level == 0)
			{
				return GetArrayCell(GetArrayCell(hArraySkills, pos), ARR_SKILL_COST);
			}
			else
			{
				return GetArrayCell(GetArrayCell(hArraySkills, pos), ARR_SKILL_COST)+GetArrayCell(GetArrayCell(hArraySkills, pos), ARR_SKILL_ICOST)*level;
			}
		}
	}
	return -1;
}

int GetSkillCostSales(int skillid,int level) {
	return RoundToFloor(GetSkillCost(skillid, level)*cfg_fSavePer);
}


void ResetPlayer(int client, int xp = 0) {
	ResetPlayerStats(client);
	ResetPlayerModification(client);
	GiveExp(client, xp, _, false, false);
	SavePlayer(client);
}

void ResetAllPlayers() {
	char query[128];
	Format(query, sizeof(query), "DELETE FROM nc_rpg;");
	if(!SQL_Query(GetSQLHandle(), query, sizeof(query)))
	{
		char error[255];
		SQL_GetError(GetSQLHandle(), error, sizeof(error));
		NCRPg_LogPrint(LogType_Error, error);
	}
	for(int i; i < MaxClients; ++i)
	{
		OnClientConnected(i);
	}
	LoadAllPlayers();
}

void ResetPlayerStats(int client) {
	SetXP(client, 0);
	SetReqXP(client, cfg_iExpStart);
	SetCredits(client, cfg_iCreditsStart);
	SetLevel(client, 1);
	for(new i = 0; i < GetSkillCount(); ++i)
		SetSkillLevel(client, i, 0);
}