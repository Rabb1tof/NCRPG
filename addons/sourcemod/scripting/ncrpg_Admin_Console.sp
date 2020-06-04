#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define VERSION		"2.1"
#define RELOAD_TIME	60
bool cfg_bLogs;bool cfg_bShowAdminsMessage;bool cfg_bShowRconMessage; AdminFlag cfg_afAdminFlag;
cfg_iCreditsInc;char cfg_sLogPath[PLATFORM_MAX_PATH];int iNextReload;
bool FirstLog=false;
public Plugin myinfo = {
	name			= "NCRPG Admin Console",
	author		= "SenatoR",
	description	= "New concept RPG in source",
	version		= VERSION
};

public void OnPluginStart()
{
	RegConsoleCmd("ncrpg_admin_reload", Command_Reload, 		"NCRPG Admin Command");
	RegConsoleCmd("ncrpg_xp",	         Command_NCRPG_XP, 		"NCRPG Admin Command");
	RegConsoleCmd("ncrpg_credits", 	 Command_NCRPG_CREDITS, 	"NCRPG Admin Command");
	RegConsoleCmd("ncrpg_level",  	 Command_NCRPG_LEVEL,   	"NCRPG Admin Command");
	RegConsoleCmd("ncrpg_upgrade",	 Command_NCRPG_UPGRADE, 	"NCRPG Admin Command");
	RegConsoleCmd("ncrpg_reset",  	 Command_NCRPG_RESET,	"NCRPG Admin Command");
	RegConsoleCmd("ncrpg_remove", 	 Command_NCRPG_REMOVE, 	"NCRPG Admin Command");
	LoadTranslations("ncrpg_admin_console.phrases");
	FirstLog=true;
}
public void OnMapStart() { LoadAdminConfig(); FirstLog=true;}


bool LoadAdminConfig() {
	if(iNextReload > GetTime()) return false;
	
	iNextReload = GetTime()+RELOAD_TIME;
	char buffer[PLATFORM_MAX_PATH];
	NCRPG_Configs RPG_Configs = NCRPG_Configs(CONFIG_CORE);
	cfg_iCreditsInc = RPG_Configs.GetInt("xp","credits_inc",1000);
	cfg_bShowAdminsMessage = RPG_Configs.GetInt("admin","show_adm_console_action",1)?true:false;
	cfg_bShowRconMessage = RPG_Configs.GetInt("admin","show_adm_rcon_action",1)?true:false;
	
	RPG_Configs.GetString("admin","flag",buffer,2,"z",false);
	if(!FindFlagByChar(buffer[0], cfg_afAdminFlag))cfg_afAdminFlag = Admin_Root;
	cfg_bLogs = RPG_Configs.GetInt("logs","admins",1)?true:false;
	
	if(cfg_bLogs)
	{
		RPG_Configs.GetString("logs","admins_path",cfg_sLogPath, sizeof cfg_sLogPath, "addons/sourcemod/logs/NCRPG/admins");
		FormatTime(buffer, sizeof buffer, "%Y%m%d", GetTime());
		Format(cfg_sLogPath, sizeof cfg_sLogPath, "%s_%s.log", cfg_sLogPath, buffer);
	}
	RPG_Configs.SaveConfigFile(CONFIG_CORE);
	return true;
}

public Action Command_Reload(int client,int args) {
	char buffer[128];
	if(!CheckAdminAccess(client)) {
		
		FormatST("No Access",buffer,sizeof buffer,client,"No Access");
		NCRPG_ChatMessage(client,buffer); return Plugin_Handled;
	}
	if(!LoadAdminConfig()){
		FormatST("Please wait",buffer,sizeof buffer,client,"Please wait");
	}
	return Plugin_Handled;
}

public Action Command_NCRPG_XP(int client,int args) {
	char buffer[PLATFORM_MAX_PATH];
	if(!CheckAdminAccess(client)) {
		FormatST("No Access",buffer,sizeof buffer,client,"No Access");
		NCRPG_ChatMessage(client,buffer); return Plugin_Handled;
	}
	GetCmdArg(1, buffer, sizeof(buffer));
	int mode = GetModeAction(buffer);
	if(mode<0) { PrintToConsole(client,"Use: ncrpg_xp <take/set/add> <steamid> <amount>" ); return Plugin_Handled; }
	GetCmdArg(3, buffer, sizeof(buffer)); int amount = StringToInt(buffer); GetCmdArg(2, buffer, sizeof(buffer));
	int target = IsConnectedPlayer(buffer); char name[32];char AdminName[32];
	if(target==-1){ if(NCRPG_GetParamStringBySteamID(buffer,"name",name,sizeof name)) target = 0; }
	else GetClientName(target, name, sizeof name);
	if(target==-1) {  PrintToConsole(client,"Steamid is invalid" ); return Plugin_Handled; }
	if(mode==0)
	{
		GetAdminName(client, AdminName, sizeof(AdminName)); 
		if(cfg_bLogs){
			char admin_steam[MAX_STEAMID_LENGTH]; char Log[MAX_MESSAGE_LENGTH]; 
			if(client>0)GetClientAuthId(client,AuthId_Steam2, admin_steam, sizeof(admin_steam)); 
			else FormatEx(admin_steam,sizeof admin_steam,"");
			FormatST("%s (%s) took %d XP a player %s (%s)",Log,sizeof Log,Translate_Server,"Logs: Admin: take xp",AdminName,admin_steam, amount, name, buffer);
			AdminLog(Log);
		}
		if(target>0)
		{
			if(client!= target){
				char msg[MAX_MESSAGE_LENGTH]; 
				FormatST("%s took %d XP a player %s",msg,sizeof msg,target,"Admin: take xp", AdminName, amount,name);
				NCRPG_ChatMessage(target,msg); // Сообщение для цели
			}
			ShowMessageToAdmin(client,"%s took %d XP a player %s","Admin: take xp",AdminName, amount,name); //Сообщение админам
			NCRPG_TakeExp(target, amount, true, false);
		}
		else if(target==0) NCRPG_TakeExpBySteamID(buffer, amount);
	}
	else if(mode==1)
	{
		GetAdminName(client, AdminName, sizeof(AdminName)); 
		if(cfg_bLogs){
			char admin_steam[MAX_STEAMID_LENGTH]; char Log[MAX_MESSAGE_LENGTH]; 
			if(client>0)GetClientAuthId(client,AuthId_Steam2, admin_steam, sizeof(admin_steam)); 
			else FormatEx(admin_steam,sizeof admin_steam,"");
			FormatST("%s (%s) set %d XP a player %s (%s)",Log,sizeof Log,Translate_Server,"Logs: Admin: set xp",AdminName,admin_steam, amount, name, buffer);
			AdminLog(Log);
		}
		if(target>0)
		{
			if(client!= target){
				char msg[MAX_MESSAGE_LENGTH]; 
				FormatST("%s set %d XP a player %s",msg,sizeof msg,target,"Admin: set xp", AdminName, amount,name);
				NCRPG_ChatMessage(target,msg); // Сообщение для цели
			}
			ShowMessageToAdmin(client,"%s set %d XP a player %s","Admin: set xp",AdminName, amount,name); //Сообщение админам
			NCRPG_SetExp(target, amount, false, true, false, false, false);
		}
		else if(target==0) NCRPG_SetExpBySteamID(buffer,amount, false, true,false);
	}
	else if(mode==2)
	{
		GetAdminName(client, AdminName, sizeof(AdminName));
		if(cfg_bLogs){
			char admin_steam[MAX_STEAMID_LENGTH]; char Log[MAX_MESSAGE_LENGTH]; 
			if(client>0)GetClientAuthId(client,AuthId_Steam2, admin_steam, sizeof(admin_steam)); 
			else FormatEx(admin_steam,sizeof admin_steam,"");
			FormatST("%s (%s) added %d XP a player %s (%s)",Log,sizeof Log,Translate_Server,"Logs: Admin: add xp",AdminName,admin_steam, amount, name, buffer);
			AdminLog(Log);
		}
		if(target>0)
		{
			if(client!= target){
				char msg[MAX_MESSAGE_LENGTH]; 
				FormatST("%s added %d XP a player %s",msg,sizeof msg,target,"Admin: add xp",AdminName, amount,name );
				NCRPG_ChatMessage(target,msg); // Сообщение для цели
			}
			ShowMessageToAdmin(client,"%s added %d XP a player %s","Admin: add xp",AdminName, amount,name); //Сообщение админам
			NCRPG_GiveExp(target, amount, true, false, false, false,EVENT_NONE);
		}
		else if(target==0)  NCRPG_GiveExpBySteamID(buffer,amount,true, false);
	}
	return Plugin_Handled;
}

public Action Command_NCRPG_CREDITS(int client,int args) {
	char buffer[PLATFORM_MAX_PATH];
	if(!CheckAdminAccess(client)) {
		FormatST("No Access",buffer,sizeof buffer,client,"No Access");
		NCRPG_ChatMessage(client,buffer); return Plugin_Handled;
	}
	GetCmdArg(1, buffer, sizeof(buffer));
	int mode = GetModeAction(buffer);
	if(mode<0) { PrintToConsole(client,"Use: ncrpg_credits <take/set/add> <steamid> <amount>" ); return Plugin_Handled; }
	GetCmdArg(3, buffer, sizeof(buffer)); int amount = StringToInt(buffer); GetCmdArg(2, buffer, sizeof(buffer));
	int target = IsConnectedPlayer(buffer); char name[32];char AdminName[32];
	if(target==-1){ if(NCRPG_GetParamStringBySteamID(buffer,"name",name,sizeof name)) target = 0; }
	else GetClientName(target, name, sizeof name);
	if(target==-1) {  PrintToConsole(client,"Steamid is invalid" ); return Plugin_Handled; }
	if(mode==0)
	{
		GetAdminName(client, AdminName, sizeof(AdminName)); 
		if(cfg_bLogs){
			char admin_steam[MAX_STEAMID_LENGTH]; char Log[MAX_MESSAGE_LENGTH]; 
			if(client>0)GetClientAuthId(client,AuthId_Steam2, admin_steam, sizeof(admin_steam)); 
			else FormatEx(admin_steam,sizeof admin_steam,"");
			FormatST("%s (%s) took %d credits a player %s (%s)",Log,sizeof Log,Translate_Server,"Logs: Admin: take credits",AdminName,admin_steam, amount, name, buffer);
			AdminLog(Log);
		}
		if(target>0)
		{
			if(client!= target){
				char msg[MAX_MESSAGE_LENGTH]; 
				FormatST("%s took %d credits a player %s",msg,sizeof msg,target,"Admin: take credits",AdminName, amount,name);
				NCRPG_ChatMessage(target,msg); // Сообщение для цели
			}
			ShowMessageToAdmin(client,"%s took %d credits a player %s","Admin: take credits",AdminName, amount,name); //Сообщение админам
			NCRPG_SetCredits(target, NCRPG_GetCredits(target)-amount);
		}
		else if(target==0) NCRPG_SetParamIntBySteamID(buffer,"credits", NCRPG_GetParamIntBySteamID(buffer,"credits")-amount);
	}
	else if(mode==1)
	{
		GetAdminName(client, AdminName, sizeof(AdminName)); 
		if(cfg_bLogs){
			char admin_steam[MAX_STEAMID_LENGTH]; char Log[MAX_MESSAGE_LENGTH]; 
			if(client>0)GetClientAuthId(client,AuthId_Steam2, admin_steam, sizeof(admin_steam)); 
			else FormatEx(admin_steam,sizeof admin_steam,"");
			FormatST("%s (%s) set %d credits a player %s (%s)",Log,sizeof Log,Translate_Server,"Logs: Admin: set credits",AdminName,admin_steam, amount, name, buffer);
			AdminLog(Log);
		}
		if(target>0)
		{
			if(client!= target){
				char msg[MAX_MESSAGE_LENGTH]; 
				FormatST("%s set %d credits a player %s",msg,sizeof msg,target,"Admin: set credits", AdminName, amount,name);
				NCRPG_ChatMessage(target,msg); // Сообщение для цели
			}
			ShowMessageToAdmin(client,"%s set %d credits a player %s","Admin: set credits",AdminName, amount,name); //Сообщение админам
			NCRPG_SetCredits(target, amount);
		}
		else if(target==0) NCRPG_SetParamIntBySteamID(buffer,"credits", amount);
	}
	else if(mode==2)
	{
		GetAdminName(client, AdminName, sizeof(AdminName));
		if(cfg_bLogs){
			char admin_steam[MAX_STEAMID_LENGTH]; char Log[MAX_MESSAGE_LENGTH]; 
			if(client>0)GetClientAuthId(client,AuthId_Steam2, admin_steam, sizeof(admin_steam)); 
			else FormatEx(admin_steam,sizeof admin_steam,"");
			FormatST("%s (%s) added %d credits a player %s (%s)",Log,sizeof Log,Translate_Server,"Logs: Admin: add credits",AdminName,admin_steam, amount, name, buffer);
			AdminLog(Log);
		}
		if(target>0)
		{
			if(client!= target){
				char msg[MAX_MESSAGE_LENGTH]; 
				FormatST("%s added %d credits a player %s",msg,sizeof msg,target,"Admin: add credits", AdminName, amount,name );
				NCRPG_ChatMessage(target,msg); // Сообщение для цели
			}
			ShowMessageToAdmin(client,"%s added %d credits a player %s","Admin: add credits",AdminName, amount,name); //Сообщение админам
			NCRPG_GiveCredits(target,amount,EVENT_NONE);
		}
		else if(target==0) NCRPG_SetParamIntBySteamID(buffer,"credits", NCRPG_GetParamIntBySteamID(buffer,"credits")+amount);
	}
	return Plugin_Handled;
}

public Action Command_NCRPG_LEVEL(int client,int args) {
	char buffer[PLATFORM_MAX_PATH];
	if(!CheckAdminAccess(client)) {
		FormatST("No Access",buffer,sizeof buffer,client,"No Access");
		NCRPG_ChatMessage(client,buffer); return Plugin_Handled;
	}
	GetCmdArg(1, buffer, sizeof(buffer));
	int mode = GetModeAction(buffer);
	if(mode<0) { PrintToConsole(client,"Use: ncrpg_level <take/set/add> <steamid> <amount>" ); return Plugin_Handled; }
	GetCmdArg(3, buffer, sizeof(buffer)); int amount = StringToInt(buffer); GetCmdArg(2, buffer, sizeof(buffer));
	int target = IsConnectedPlayer(buffer); char name[32];char AdminName[32];
	if(target==-1){ if(NCRPG_GetParamStringBySteamID(buffer,"name",name,sizeof name)) target = 0; }
	else GetClientName(target, name, sizeof name);
	if(target==-1) {  PrintToConsole(client,"Steamid is invalid" ); return Plugin_Handled; }
	if(mode==0)
	{
		GetAdminName(client, AdminName, sizeof(AdminName)); 
		if(cfg_bLogs){
			char admin_steam[MAX_STEAMID_LENGTH]; char Log[MAX_MESSAGE_LENGTH]; 
			if(client>0)GetClientAuthId(client,AuthId_Steam2, admin_steam, sizeof(admin_steam)); 
			else FormatEx(admin_steam,sizeof admin_steam,"");
			FormatST("%s (%s) took %d level a player %s (%s)",Log,sizeof Log,Translate_Server,"Logs: Admin: take level",AdminName,admin_steam, amount, name, buffer);
			AdminLog(Log);
		}
		if(target>0)
		{
			if(client!= target){
				char msg[MAX_MESSAGE_LENGTH]; 
				FormatST("%s took %d level a player %s",msg,sizeof msg,target,"Admin: take level", AdminName, amount,name);
				NCRPG_ChatMessage(target,msg); // Сообщение для цели
			}
			ShowMessageToAdmin(client,"%s took %d level a player %s","Admin: take level",AdminName, amount,name); //Сообщение админам
			NCRPG_SetLevel(target, NCRPG_GetLevel(target)-amount);
		}
		else if(target==0) NCRPG_SetParamIntBySteamID(buffer,"level", NCRPG_GetParamIntBySteamID(buffer,"level")-amount);
	}
	else if(mode==1)
	{
		GetAdminName(client, AdminName, sizeof(AdminName)); 
		if(cfg_bLogs){
			char admin_steam[MAX_STEAMID_LENGTH]; char Log[MAX_MESSAGE_LENGTH]; 
			if(client>0)GetClientAuthId(client,AuthId_Steam2, admin_steam, sizeof(admin_steam)); 
			else FormatEx(admin_steam,sizeof admin_steam,"");
			FormatST("%s (%s) set %d level a player %s (%s)",Log,sizeof Log,Translate_Server,"Logs: Admin: set level",AdminName,admin_steam, amount, name, buffer);
			AdminLog(Log);
		}
		if(target>0)
		{
			if(client!= target){
				char msg[MAX_MESSAGE_LENGTH]; 
				FormatST("%s set %d level a player %s",msg,sizeof msg,target,"Admin: set level",AdminName, amount,name);
				NCRPG_ChatMessage(target,msg); // Сообщение для цели
			}
			ShowMessageToAdmin(client,"%s set %d level a player %s","Admin: set level",AdminName, amount,name); //Сообщение админам
			NCRPG_SetLevel(target,amount);
		}
		else if(target==0) NCRPG_SetParamIntBySteamID(buffer,"level", amount);
	}
	else if(mode==2)
	{
		GetAdminName(client, AdminName, sizeof(AdminName));
		if(cfg_bLogs){
			char admin_steam[MAX_STEAMID_LENGTH]; char Log[MAX_MESSAGE_LENGTH]; 
			if(client>0)GetClientAuthId(client,AuthId_Steam2, admin_steam, sizeof(admin_steam)); 
			else FormatEx(admin_steam,sizeof admin_steam,"");
			FormatST("%s (%s) added %d level a player %s (%s)",Log,sizeof Log,Translate_Server,"Logs: Admin: add level",AdminName,admin_steam, amount, name, buffer);
			AdminLog(Log);
		}
		if(target>0)
		{
			if(client!= target){
				char msg[MAX_MESSAGE_LENGTH]; 
				FormatST("%s added %d level a player %s",msg,sizeof msg,target,"Admin: add level", AdminName, amount,name );
				NCRPG_ChatMessage(target,msg); // Сообщение для цели
			}
			ShowMessageToAdmin(client,"%s added %d level a player %s","Admin: add level",AdminName, amount,name); //Сообщение админам
			NCRPG_SetLevel(target,NCRPG_GetLevel(target)+amount);
			NCRPG_GiveCredits(target,amount*cfg_iCreditsInc,EVENT_NONE);
		}
		else if(target==0){
			NCRPG_SetParamIntBySteamID(buffer,"level", NCRPG_GetParamIntBySteamID(buffer,"level")+amount);
			NCRPG_SetParamIntBySteamID(buffer,"credits", cfg_iCreditsInc*amount);
		}
	}
	return Plugin_Handled;
}


public Action Command_NCRPG_UPGRADE(int client,int args) {
	char buffer[PLATFORM_MAX_PATH];
	if(!CheckAdminAccess(client)) {
		FormatST("No Access",buffer,sizeof buffer,client,"No Access");
		NCRPG_ChatMessage(client,buffer); return Plugin_Handled;
	}
	GetCmdArg(1, buffer, sizeof(buffer));
	int mode = GetModeAction(buffer);
	if(mode<0) { PrintToConsole(client,"Use: ncrpg_upgrade <take/set/add> <steamid> <shortname> <amount>" ); return Plugin_Handled; }
	GetCmdArg(3, buffer, sizeof(buffer)); int amount = StringToInt(buffer); GetCmdArg(2, buffer, sizeof(buffer));
	int target = IsConnectedPlayer(buffer); char name[32];char AdminName[32];char shortname[MAX_SHORTNAME_LENGTH];
	if(target==-1){ if(NCRPG_GetParamStringBySteamID(buffer,"name",name,sizeof name)) target = 0; }
	else GetClientName(target, name, sizeof name);
	if(target==-1) {  PrintToConsole(client,"Steamid is invalid" ); return Plugin_Handled; }
	GetCmdArg(3, shortname, sizeof(shortname));
	int skillid = NCRPG_FindSkillByShortname(shortname);
	if(skillid==-1) { PrintToConsole(client,"shortname is invalid" ); return Plugin_Handled; }
	int skillmax =NCRPG_GetSkillMaxLevel(skillid);
	if(mode==0)
	{
		GetAdminName(client, AdminName, sizeof(AdminName)); 
		if(cfg_bLogs){
			char admin_steam[MAX_STEAMID_LENGTH]; char Log[MAX_MESSAGE_LENGTH]; 
			if(client>0)GetClientAuthId(client,AuthId_Steam2, admin_steam, sizeof(admin_steam)); 
			else FormatEx(admin_steam,sizeof admin_steam,"");
			FormatST("%s(%s) took %d levels skill %s a player %s (%s)",Log,sizeof Log,Translate_Server,"Logs: Admin: take upgrade",AdminName,admin_steam, amount,shortname, name, buffer);
			AdminLog(Log);
		}
		int skilllvl =NCRPG_GetSkillLevel(target,skillid)-amount;
		if(skilllvl<0) skilllvl=0;
		else if(skilllvl>skillmax) skilllvl =skillmax;
		if(target>0)
		{
			if(client!= target){
				char msg[MAX_MESSAGE_LENGTH]; 
				FormatST("{%s} took {%d} level skill {%s} a player {%s}.",msg,sizeof msg,target,"Admin: take upgrade",AdminName, amount,shortname,name);
				NCRPG_ChatMessage(target,msg); // Сообщение для цели
			}
			ShowMessageToAdmin(client,"{%s} took {%d} level skill {%s} a player {%s}.","Admin: take upgrade",AdminName, amount,name,shortname); //Сообщение админам
			NCRPG_SetSkillLevel(target, skillid,skilllvl);
		}
		else if(target==0){
			Format(shortname,sizeof shortname,"_%s",shortname);
			NCRPG_SetParamIntBySteamID(buffer,shortname, skilllvl);
		}
	}
	else if(mode==1)
	{
		GetAdminName(client, AdminName, sizeof(AdminName)); 
		if(cfg_bLogs){
			char admin_steam[MAX_STEAMID_LENGTH]; char Log[MAX_MESSAGE_LENGTH]; 
			if(client>0)GetClientAuthId(client,AuthId_Steam2, admin_steam, sizeof(admin_steam)); 
			else FormatEx(admin_steam,sizeof admin_steam,"");
			FormatST("%s(%s) set %d level skill %s a player %s (%s)",Log,sizeof Log,Translate_Server,"Logs: Admin: set upgrade",AdminName,admin_steam, amount,shortname, name, buffer);
			AdminLog(Log);
		}
		if(amount<0) amount=0;
		else if(amount>skillmax) amount =skillmax;
		if(target>0)
		{
			if(client!= target){
				char msg[MAX_MESSAGE_LENGTH]; 
				FormatST("{%s} set {%d} level skill {%s} a player {%s}.",msg,sizeof msg,target,"Admin: set upgrade", AdminName, amount,shortname,name);
				NCRPG_ChatMessage(target,msg); // Сообщение для цели
			}
			ShowMessageToAdmin(client,"{%s} set {%d} level skill {%s} a player {%s}.","Admin: set upgrade",AdminName, amount,name,shortname); //Сообщение админам
			NCRPG_SetSkillLevel(target, skillid,amount);
		}
		else if(target==0){
			Format(shortname,sizeof shortname,"_%s",shortname);
			NCRPG_SetParamIntBySteamID(buffer,shortname, amount);
		}
	}
	else if(mode==2)
	{
		GetAdminName(client, AdminName, sizeof(AdminName)); 
		if(cfg_bLogs){
			char admin_steam[MAX_STEAMID_LENGTH]; char Log[MAX_MESSAGE_LENGTH]; 
			if(client>0)GetClientAuthId(client,AuthId_Steam2, admin_steam, sizeof(admin_steam)); 
			else FormatEx(admin_steam,sizeof admin_steam,"");
			FormatST("%s(%s) added %d levels skill %s a player %s (%s)",Log,sizeof Log,Translate_Server,"Logs: Admin: take upgrade",AdminName,admin_steam, amount,shortname, name, buffer);
			AdminLog(Log);
		}
		int skilllvl =NCRPG_GetSkillLevel(target,skillid)+amount;
		if(skilllvl<0) skilllvl=0;
		else if(skilllvl>skillmax) skilllvl =skillmax;
		if(target>0)
		{
			if(client!= target){
				char msg[MAX_MESSAGE_LENGTH]; 
				FormatST("{%s} added {%d} level skill {%s} a player {%s}.",msg,sizeof msg,target,"Admin: take upgrade", AdminName, amount,shortname,name);
				NCRPG_ChatMessage(target,msg); // Сообщение для цели
			}
			ShowMessageToAdmin(client,"{%s} added {%d} level skill {%s} a player {%s}.","Admin: take upgrade",AdminName, amount,name,shortname); //Сообщение админам
			NCRPG_SetSkillLevel(target, skillid,skilllvl);
		}
		else if(target==0){
			Format(shortname,sizeof shortname,"_%s",shortname);
			NCRPG_SetParamIntBySteamID(buffer,shortname, skilllvl);
		}
	}
	return Plugin_Handled;
}

public Action Command_NCRPG_RESET(int client,int args) {
	char buffer[PLATFORM_MAX_PATH];
	if(!CheckAdminAccess(client)) {
		FormatST("No Access",buffer,sizeof buffer,client,"No Access");
		NCRPG_ChatMessage(client,buffer); return Plugin_Handled;
	}
	GetCmdArg(1, buffer, sizeof(buffer));
	int target = IsConnectedPlayer(buffer); char name[32];char AdminName[32];
	if(target==-1){ if(NCRPG_GetParamStringBySteamID(buffer,"name",name,sizeof name)) target = 0; }
	else GetClientName(target, name, sizeof name);
	if(target==-1) {  PrintToConsole(client,"Steamid is invalid" ); return Plugin_Handled; }
	if(target>0)
	{
		if(cfg_bLogs){
			char admin_steam[MAX_STEAMID_LENGTH]; char Log[MAX_MESSAGE_LENGTH]; 
			if(client>0)GetClientAuthId(client,AuthId_Steam2, admin_steam, sizeof(admin_steam)); 
			else FormatEx(admin_steam,sizeof admin_steam,"");
			FormatST("%s (%s) reset a player %s (%s)",Log,sizeof Log,Translate_Server,"Logs: Admin: reset",AdminName,admin_steam, name, buffer);
			AdminLog(Log);
		}
		if(client!= target){
			char msg[MAX_MESSAGE_LENGTH]; 
			FormatST("{%s} reset a player {%s}.",msg,sizeof msg,target,"Admin: reset",AdminName,name);
			NCRPG_ChatMessage(target,msg); // Сообщение для цели
		}
		ShowMessageToAdmin(client,"{%s} reset a player {%s}.","Admin: reset",AdminName, _,name); //Сообщение админам
		NCRPG_ResetPlayer(target);
	}
	else if(target==0){
		PrintToConsole(client,"Use: ncrpg_remove <steamid>" );
	}
	return Plugin_Handled;
}

public Action Command_NCRPG_REMOVE(int client,int args) {
	char buffer[PLATFORM_MAX_PATH];
	if(!CheckAdminAccess(client)) {
		FormatST("No Access",buffer,sizeof buffer,client,"No Access");
		NCRPG_ChatMessage(client,buffer); return Plugin_Handled;
	}
	GetCmdArg(1, buffer, sizeof(buffer));
	int target = IsConnectedPlayer(buffer); char name[32];char AdminName[32];
	if(target==-1){ if(NCRPG_GetParamStringBySteamID(buffer,"name",name,sizeof name)) target = 0; }
	else GetClientName(target, name, sizeof name);
	if(target==-1) {  PrintToConsole(client,"Steamid is invalid" ); return Plugin_Handled; }
	if(target>0)
	{
		PrintToConsole(client,"Target is not got connected. Kick him and Reuse this command" );
	}
	else if(target==0){
		if(cfg_bLogs){
			char admin_steam[MAX_STEAMID_LENGTH]; char Log[MAX_MESSAGE_LENGTH]; 
			if(client>0)GetClientAuthId(client,AuthId_Steam2, admin_steam, sizeof(admin_steam)); 
			else FormatEx(admin_steam,sizeof admin_steam,"");
			FormatST("%s (%s) remove from BD a player %s (%s)",Log,sizeof Log,Translate_Server,"Logs: Admin: remove",AdminName,admin_steam, name, buffer);
			AdminLog(Log);
		}
		char msg[MAX_MESSAGE_LENGTH]; 
		FormatST("{%s} remove a player {%s}.",msg,sizeof msg,target,"Admin: remove", AdminName,name);
		if(IsValidPlayer) NCRPG_ChatMessage(client,msg); // Сообщение для админа
		Format(buffer,sizeof buffer,"DELETE FROM nc_rpg WHERE steamid='%s'", buffer);
		if(!SQL_FastQuery( NCRPG_GetDbHandle(), buffer, sizeof buffer))
		{
			char err[255];
			SQL_GetError(NCRPG_GetDbHandle(), err, sizeof err );
			NCRPG_LogMessage(LogType_Error, "Could not remove players, reason: %s",err);
		}
	}
	return Plugin_Handled;
}
// Helper -------------------------------------------------------------------------------------------------------------------
int GetModeAction(char[] action)
{
	if(StrEqual(action, "take", false)) return 0;
	else if(StrEqual(action, "set", false)) return 1;
	else if(StrEqual(action, "add", false)) return 2;
	else return-1;
}

int IsConnectedPlayer(char[] steamid)
{
	char buffer[32];
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsValidPlayer(client) && GetClientSteamID(client,buffer, sizeof buffer))
		{
			if(strcmp(steamid,buffer)==0) return client;
		}
	}
	return -1;
}


void ShowMessageToAdmin(int i,char[] Safe,char[] translate,char[] Name,int amount=-1,char[] AdminName,char[] shortname="")
{
	if(i==0 && !cfg_bShowRconMessage) return;
	char msg[MAX_MESSAGE_LENGTH]; 
	if(cfg_bShowAdminsMessage)
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsValidPlayer(client) && CheckAdminAccess(client) && client!=i)
			{
				if(strlen(shortname)>1) FormatST(Safe,msg,sizeof msg,client,translate, Name, amount,shortname, AdminName);
				else FormatST(Safe,msg,sizeof msg,client,translate, Name, amount, AdminName);
				if(amount==-1) FormatST(Safe,msg,sizeof msg,client,translate, Name, AdminName);
				NCRPG_ChatMessage(client,msg);
			}
		}
	}
	else if(i!=0)
	{
		if(strlen(shortname)>1) FormatST(Safe,msg,sizeof msg,i,translate, Name, amount,shortname, AdminName);
		else FormatST(Safe,msg,sizeof msg,i,translate, Name, amount, AdminName);
		if(amount==-1) FormatST(Safe,msg,sizeof msg,i,translate, Name, AdminName);
		NCRPG_ChatMessage(i,msg);
	}
}


int GetAdminName(int client, char[] buffer,int maxlength) 
{
	FormatST("Admin",buffer,sizeof maxlength,client,"Admin");
	Format(buffer, maxlength, "%s %N", buffer,client);
	return client;
}

bool CheckAdminAccess(int client) 
{
	if(!client) return true;
	
	AdminId adminId = GetUserAdmin(client);
	if(adminId == INVALID_ADMIN_ID) return false;
	if(!adminId.HasFlag(cfg_afAdminFlag,Access_Effective))
	{
		// CReplyToCommand(client, "%T", "No Access", client);
		return false;
	}
	
	return true;
}

void AdminLog(char[] text)
{
	if(!FileExists(cfg_sLogPath))
	{
		CloseHandle(CreateFile(cfg_sLogPath));
		FirstLog=true;
	}
	if(FirstLog)
	{
		char buffer[PLATFORM_MAX_PATH];
		GetCurrentMap(buffer, sizeof buffer);
		Format(buffer,sizeof buffer,"-------- Map %s Logging--------",buffer);
		LogToFile(cfg_sLogPath, text);
		FirstLog=false;
	}
	LogToFile(cfg_sLogPath, text);
}

