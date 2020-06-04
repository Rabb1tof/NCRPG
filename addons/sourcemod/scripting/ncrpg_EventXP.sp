#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"

#define VERSION	"1.4"

public Plugin myinfo = {
	name		= "NCRPG XP events",
	author		= "SenatoR",
	description	= "",
	version		= VERSION
};
int cfg_iExpWin[3];// Опыт за победу команды
int cfg_iExpPlanted[3];// Опыт за установку бомбы
int cfg_iExpExploded[3];// Опыт за взрыв бомбы
int cfg_iExpDefused[3];// Опыт за обезвреживание бомбы
int cfg_iExpHeadshot[3];	// Опыт за убийство в голову
int cfg_iExpKill[3];	// Опыт за убийство
int cfg_iExpKnife[3];	// Опыт за убийство ножом
int cfg_iExpAssist[3];	// Опыт за помощь в убийстве
int cfg_iExpMVP[3];	// Опыт за MVP

public void OnPluginStart()
{
	HookEvent("player_death",	Event_PlayerDeath);
	HookEvent("bomb_planted",	Event_BombPlanted);
	HookEvent("bomb_exploded",	Event_BombExploded);
	HookEvent("bomb_defused",	Event_BombDefused);
	HookEvent("round_end",		Event_RoundEnd);
	HookEvent("round_mvp", 		Event_RoundMVP);
}

public void OnMapStart() {
	char buffer[3*16];
	NCRPG_Configs RPG_Configs = NCRPG_Configs(CONFIG_CORE);
	
	RPG_Configs.GetString("xp","exp_kill",buffer, sizeof buffer, "100-200R"); 
	CfgGetExp(buffer,cfg_iExpKill);
	
	RPG_Configs.GetString("xp","exp_head",buffer, sizeof buffer, " 5 0 ");CfgGetExp(buffer,cfg_iExpHeadshot);
	RPG_Configs.GetString("xp","exp_kill_knife",buffer, sizeof buffer, " 5 0 ");CfgGetExp(buffer,cfg_iExpKnife);
	RPG_Configs.GetString("xp","exp_kill_assist",buffer, sizeof buffer, "R 5 0 ");CfgGetExp(buffer,cfg_iExpAssist);
	RPG_Configs.GetString("xp","exp_win",buffer, sizeof buffer, "1 0 0 - 1 5 0");CfgGetExp(buffer,cfg_iExpWin);
	RPG_Configs.GetString("xp","exp_planted",buffer, sizeof buffer, "100"); CfgGetExp(buffer,cfg_iExpPlanted);
	RPG_Configs.GetString("xp","exp_exploded",buffer, sizeof buffer, "125-150R");CfgGetExp(buffer,cfg_iExpExploded);
	RPG_Configs.GetString("xp","exp_defused",buffer, sizeof buffer, "R 200-250"); CfgGetExp(buffer,cfg_iExpDefused);
	RPG_Configs.GetString("xp","exp_mvp",buffer, sizeof buffer, "R200"); CfgGetExp(buffer,cfg_iExpMVP);
	RPG_Configs.SaveConfigFile(CONFIG_CORE);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int assister = GetClientOfUserId(event.GetInt("assister"));
	if(IsValidPlayer(assister) && IsValidPlayer(victim))
	{
		int xp = GetRandomInt(cfg_iExpAssist[1],cfg_iExpAssist[2]);
		if(cfg_iExpAssist[0]) xp=NCRPG_GetLevel(victim)*xp/NCRPG_GetLevel(attacker);
		if(xp>0) NCRPG_GiveExp(attacker, xp, true);
	}
	if(IsValidPlayer(attacker) && IsValidPlayer(victim) && victim != attacker)
	{
		int xp = GetRandomInt(cfg_iExpKill[1],cfg_iExpKill[2]);
		if(cfg_iExpKill[0]) xp=NCRPG_GetLevel(victim)*xp/NCRPG_GetLevel(attacker);
		if(xp>0)
		{
			char buffer[32];
			GetClientWeapon(attacker, buffer, sizeof(buffer));
			if(StrEqual(buffer, "knife"))
			{	
				if(cfg_iExpKnife[0]) xp+= NCRPG_GetLevel(victim)*GetRandomInt(cfg_iExpKnife[1],cfg_iExpKnife[2])/NCRPG_GetLevel(attacker);
				else xp+=GetRandomInt(cfg_iExpKnife[1],cfg_iExpKnife[2]);
			}
			if(event.GetBool("headshot"))
			{
				if(cfg_iExpHeadshot[0]) xp+= NCRPG_GetLevel(victim)*GetRandomInt(cfg_iExpHeadshot[1],cfg_iExpHeadshot[2])/NCRPG_GetLevel(attacker);
				else xp+=GetRandomInt(cfg_iExpHeadshot[1],cfg_iExpHeadshot[2]);
			}
			NCRPG_GiveExp(attacker, xp, true);
		}
		else NCRPG_LogMessage(LogType_Error,"Player %N got negative Xp Info: XP = %d, Victim Level = %d, Attacker Level = %d [exp_kill]",attacker,xp,NCRPG_GetLevel(victim),NCRPG_GetLevel(attacker));
	}
	
}


public Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	int winner = event.GetInt("winner");
	if(winner>1)
		for(int client = 1; client <= MaxClients; client++)
			if(IsValidPlayer(client) && GetClientTeam(client) == winner)  NCRPG_GiveExp(client, GetExpResult(winner,cfg_iExpWin));
}

public Event_BombPlanted(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidPlayer(client)) NCRPG_GiveExp(client, GetExpResult(client,cfg_iExpPlanted));
}

public Event_BombExploded(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidPlayer(client)) NCRPG_GiveExp(client, GetExpResult(client,cfg_iExpExploded));
}

public Event_BombDefused(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidPlayer(client)) NCRPG_GiveExp(client, GetExpResult(client,cfg_iExpDefused));
}

public Action Event_RoundMVP(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidPlayer(client)) NCRPG_GiveExp(client, GetExpResult(client,cfg_iExpMVP));
}

int CfgGetExp(char[] cfg,int out[3])
{
	TrimString(cfg);
	bool ratio=false;
	if(ReplaceString(cfg,16*3,"R","")) ratio=true;
	out[0] = ratio;
	if(FindCharInString(cfg,'-')) 
	{
		char buffer[2][16];
		ExplodeString(cfg, "-", buffer, 2, 16);
		out[1] = StringToInt(buffer[0]);
		out[2] = StringToInt(buffer[1]);
	}else
	{
		out[1] = StringToInt(cfg);
		out[2] = out[0];
	}
}

int GetExpResult(int client,int cfg[3])
{
	int r = GetRandomInt(cfg[1],cfg[2]);
	if(cfg[0]) RoundToNearest(GetTeamRatio(GetClientTeam(client))*r);
	return r;
}