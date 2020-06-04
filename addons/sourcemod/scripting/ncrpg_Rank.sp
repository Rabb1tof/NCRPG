#pragma semicolon 1
#pragma dynamic 86000
#include "NCIncs/nc_rpg.inc"

#define VERSION	"1.5"

public Plugin myinfo = {
	name		= "NCRPG Rank & Top",
	author		= "SenatoR",
	description	= "",
	version		= VERSION
};

bool cfg_bCmdsHide;bool cfg_ShowSpawnXP;int cfg_iTopSize;
char cfg_sCommandsRank[MAX_RPG_CMDS*MAX_RPG_CMDS_LENGTH];
char cfg_sCommandsXP[MAX_RPG_CMDS*MAX_RPG_CMDS_LENGTH];
char cfg_sCommandsTOP[MAX_RPG_CMDS*MAX_RPG_CMDS_LENGTH];

public OnPluginStart()
{
	RegConsoleCmd("say",NCRPG_SayCommand);
	RegConsoleCmd("say_team",NCRPG_SayCommand);
}

public OnMapStart() { LoadAllConfigs(); LoadTranslations("ncrpg_rank.phrases");}

void LoadAllConfigs() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(CONFIG_CORE);
	cfg_bCmdsHide = RPG_Configs.GetInt("rank_top","cmds_hide",1)?true:false;
	RPG_Configs.GetString("rank_top","cmds_rank",cfg_sCommandsRank, sizeof cfg_sCommandsRank, "rpgrank,war3rank");
	RPG_Configs.GetString("rank_top","cmds_xp",cfg_sCommandsXP, sizeof cfg_sCommandsXP, "xp,showxp");
	cfg_ShowSpawnXP = RPG_Configs.GetInt("rank_top","cmds_xp_spawn",1)?true:false;
	RPG_Configs.GetString("rank_top","cmds_top",cfg_sCommandsTOP, sizeof cfg_sCommandsTOP, "rpgtop,war3top");
	cfg_iTopSize = RPG_Configs.GetInt("rank_top","cmds_top_size",100); if(cfg_iTopSize==0) cfg_iTopSize=1; else if(cfg_iTopSize>100) cfg_iTopSize=100;
	RPG_Configs.SaveConfigFile(CONFIG_CORE);
}

public Action NCRPG_SayCommand(int client,int args) {
	if(IsValidPlayer(client) )
	{
		char sArgs[256]; GetCmdArgString(sArgs, sizeof sArgs); StripQuotes(sArgs); char buffer[MAX_RPG_CMDS][MAX_RPG_CMDS_LENGTH];
		int count = ShortExplodeStr(cfg_sCommandsRank,buffer);
		for(int i = 0; i < count; ++i) { if(CommandCheck(buffer[i], sArgs)){ GetRank(client); if(cfg_bCmdsHide) return Plugin_Handled; return Plugin_Continue; } }
		count = ShortExplodeStr(cfg_sCommandsXP,buffer);
		for(int i = 0; i < count; ++i) { if(CommandCheck(buffer[i], sArgs)){ GetXP(client); if(cfg_bCmdsHide) return Plugin_Handled; return Plugin_Continue; } }
		count = ShortExplodeStr(cfg_sCommandsTOP,buffer);
		for(int i = 0; i < count; ++i) { if(CommandCheck(sArgs,buffer[i])){ DisplayMenuTOP(client, cfg_iTopSize); if(cfg_bCmdsHide) return Plugin_Handled; return Plugin_Continue;}}
		for(int i = 0; i < count; ++i) {
			int top_num;
			if((top_num=CommandCheckEx(sArgs,buffer[i]))>0)
			{
				if(top_num>100) top_num=100; 
				if(top_num<=0) top_num=1;
				DisplayMenuTOP(client, top_num); 
				if(cfg_bCmdsHide) return Plugin_Handled; return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}


int ShortExplodeStr(char[] input, char[][] out){ return ExplodeString(input, ",", out, MAX_RPG_CMDS, MAX_RPG_CMDS_LENGTH);}

//XP

public void NCRPG_OnPlayerSpawn(int client){ if(cfg_ShowSpawnXP && IsValidPlayer(client,true) && NCRPG_GetLevel(client) > 0 && NCRPG_GetDbHandle() != null) GetXP(client);}
void GetXP(int client) {
	char msg[196];
	FormatST("Your have %i level and your %i/%i XP.",msg,sizeof msg,client,"Spawn message your xp", NCRPG_GetLevel(client), NCRPG_GetXP(client), NCRPG_GetReqXP(client));
	NCRPG_ChatMessage(client,msg);
}
// Rank & Top


//Rank

void GetRank(int client)
{
	char buffer[256];
	FormatEx(buffer,sizeof buffer,"SELECT COUNT(*) FROM nc_rpg WHERE level > %d OR (level = %d AND xp > %d) OR (level = %d AND xp = %d AND credits > %d)",NCRPG_GetLevel(client),NCRPG_GetLevel(client),NCRPG_GetXP(client),NCRPG_GetLevel(client),NCRPG_GetXP(client),NCRPG_GetCredits(client));
	Database db = view_as<Database>(NCRPG_GetDbHandle());
	if ( db == null ) NCRPG_LogMessage(LogType_FailState,"Couldn't retrieve database handle!" );
	db.Query(GetPlayerRankCallback, buffer, client, DBPrio_Low);
}

public void GetPlayerRankCallback(Database db, DBResultSet results, const char[] error, int client)
{
	if (results == null) { NCRPG_LogMessage(LogType_Error, "Could not get rank Player %N, reason: %s",client, error); return; }
	if(results.HasResults)
	{
		int rank = results.FetchInt(0)+1; char msg[256];
		FormatST("Your position in the top %i! You are at level %i, %i XP and %i credits",msg,sizeof msg,client,"Your rank", rank, NCRPG_GetLevel(client), NCRPG_GetXP(client), NCRPG_GetCredits(client));
		NCRPG_ChatMessage(client,msg);
	}
}

void DisplayMenuTOP(int client,int count) {
	char buffer[256];
	FormatEx(buffer, sizeof(buffer), "SELECT name, level, xp, reqxp FROM nc_rpg ORDER BY level DESC, xp DESC LIMIT %d", count); // DESC
	Database db = view_as<Database>(NCRPG_GetDbHandle());
	if ( db == null ) NCRPG_LogMessage(LogType_FailState,"Couldn't retrieve database handle!" );
	db.Query(CallBackDisplayMenuTOP, buffer, client, DBPrio_Low);
}

public void CallBackDisplayMenuTOP(Database db, DBResultSet results, const char[] error, int client)
{
	if (results == null) { NCRPG_LogMessage(LogType_Error, "Could not get Top Players, reason: %s", error); return; }
	int count = results.RowCount;
	if(count > 0)
	{
		Menu menu = CreateMenu(HandlerMenuTopPlayers);
		char buffer[512]; FormatST("TOP {%i} Players",buffer,sizeof buffer,client,"TOP Players", count);
		Format(buffer, sizeof(buffer), "\n%s\n-------------------------------------------\n",buffer);
		char name[32];
		menu.SetTitle(buffer);
		int i = 0;
		while(results.FetchRow()) // while
		{
			results.FetchString(0,name,sizeof name);
			FormatST("[%i] %s [LVL: {%d}, XP: {%d}/{%d}]",buffer,sizeof buffer,client,"TOP Player", ++i,name, results.FetchInt(1),results.FetchInt(2),results.FetchInt(3));
			menu.AddItem("",buffer,ITEMDRAW_DISABLED);
		}
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int HandlerMenuTopPlayers(Menu menu, MenuAction action, int client, int param2){ if(action == MenuAction_End) delete menu;}