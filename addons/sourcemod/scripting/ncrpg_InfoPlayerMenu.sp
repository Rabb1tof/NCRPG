#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#include "NCIncs/ncrpg_Menu.inc"
#define VERSION_NUM "1.2"

public Plugin myinfo = {
	name = "NCRPG Info Player Menu",
	author		= "SenatoR",
	description = "New concept RPG in source",
	version		= VERSION_NUM,
	url			= ""
};

bool cfg_iPlayerinfo; //Просмотр статистики других игроков
bool cfg_bCmdsHide; //Скрытие сообщений в чат

public void OnPluginStart()
{
	LoadAllConfigs();
	LoadTranslations("ncrpg.phrases");
	RegConsoleCmd("say",NCRPG_SayCommand);
	RegConsoleCmd("say_team",NCRPG_SayCommand);
}

public APLRes AskPluginLoad2(Handle myself,bool late,char[] error,int err_max)
{
	RegPluginLibrary("NCRPG");
	CreateNative("NCRPG_OpenMenuPlayersInfo", 	Native_OpenPlayerInfoMenu);
	return APLRes_Success;
}

public int Native_OpenPlayerInfoMenu(Handle plugin, int numParams) {
	MenuInfoChoosePlayers(GetNativeCell(1));
}

void LoadAllConfigs() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(CONFIG_CORE);
	cfg_iPlayerinfo = RPG_Configs.GetInt("player","playerinfo",1)?true:false;
	cfg_bCmdsHide = RPG_Configs.GetInt("other","cmds_hide",1)?true:false;
	RPG_Configs.SaveConfigFile(CONFIG_CORE);
}

public Action NCRPG_SayCommand(int client,int args) 
{
	if(IsValidPlayer(client))
	{
		char sArgs[256];
		GetCmdArgString(sArgs, sizeof(sArgs));
		StripQuotes(sArgs);
		if(CommandCheck(sArgs, "playersinfo")|| CommandCheck(sArgs, "pi"))
		{
			MenuInfoChoosePlayers(client);
			if(cfg_bCmdsHide) return Plugin_Handled;
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

void MenuInfoChoosePlayers(client)
{
	if(cfg_iPlayerinfo) BuildMenuInfoChoosePlayer(client).Display(client, MENU_TIME_FOREVER);
	else NCRPG_ChatMessage(client,"%t", "This function is disabled");
}

// Info Player
Menu BuildMenuInfoChoosePlayer(int client) {
	Menu menu = CreateMenu(HandlerMenuInfoChoosePlayer);
	menu.SetTitle( "%T", "Choose a player:", client);
	AddMenuPlayers(menu, client);
	
	if(menu.ItemCount < 1)
	{
		char buffer[64];
		Format(buffer, sizeof(buffer), "%T", "On the server, there are no other players!", client);
		menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	}
	
	menu.ExitBackButton = true;
	
	return menu;
}

public int HandlerMenuInfoChoosePlayer(Menu menu, MenuAction action, int client, int param2){
	if(action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param2, info, sizeof(info));
		int target = GetClientOfUserId(StringToInt(info));
		if(IsValidPlayer(target)) BuildMenuPlayerInfo(client,target).Display(client, MENU_TIME_FOREVER);
		else
		{
			NCRPG_ChatMessage(client,"%t", "The player you selected has left the server");
			BuildMenuInfoChoosePlayer(client).Display(client, MENU_TIME_FOREVER);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
			NCRPG_OpenMenuStats(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}


Menu BuildMenuPlayerInfo(int client,int target) {
	Menu menu = CreateMenu(HandlerMenuPlayerInfo);
	menu.SetTitle("%T", "Stats title", client, target);
	char buffer[64];
	if(cfg_iPlayerinfo)
	{
		char userid[8];
		IntToString(GetClientUserId(target), userid, sizeof(userid));
		Format(buffer, sizeof(buffer), "%T", "Info about skills", client);
		menu.AddItem(userid, buffer);
	}
	
	Format(buffer, sizeof(buffer), "%T", "Level:", client,  NCRPG_GetLevel(target));
	menu.AddItem("", buffer, ITEMDRAW_DISABLED);
		
	Format(buffer, sizeof(buffer), "%T", "XP:", client,  NCRPG_GetXP(target),  NCRPG_GetReqXP(target));
	menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	
	Format(buffer, sizeof(buffer), "%T", "Credits:", client, NCRPG_GetCredits(target));
	menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	
	menu.ExitBackButton = true;
	
	return menu;
}

public int HandlerMenuPlayerInfo(Menu menu, MenuAction action, int client, int param2){
	if(action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param2, info, sizeof(info));
		int target = GetClientOfUserId(StringToInt(info));
		if(IsValidPlayer(target)) BuildMenuPlayerInfoSkills(client, target).Display(client, MENU_TIME_FOREVER);
		else
		{
			NCRPG_ChatMessage(client,"%t", "The player you selected has left the server");
			BuildMenuInfoChoosePlayer(client).Display(client, MENU_TIME_FOREVER);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack) BuildMenuInfoChoosePlayer(client).Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_End)
		delete menu;
}

Menu BuildMenuPlayerInfoSkills(int client,int target) {
	Menu menu = CreateMenu(HandlerMenuPlayerInfoSkills);
	menu.SetTitle("%T", "Info about skills title", client, target);

	char buffer[MAX_SKILL_LENGTH+16]; char userid[8];
	Format(buffer, sizeof(buffer), "%T", "Refresh", client);
	IntToString(GetClientUserId(target), userid, sizeof(userid));
	menu.AddItem(userid, buffer);
	int iSkillCount = NCRPG_GetSkillCount();
	for(int i = 0; i < iSkillCount; i++)
	{
		if(!NCRPG_IsValidSkill(i)) continue;
		NCRPG_GetSkillName(i, buffer, sizeof(buffer), client);
		Format(buffer, sizeof(buffer), "%T", "Skill info", client, NCRPG_GetSkillLevel(target, i), NCRPG_GetSkillMaxLevel(i), buffer);
		menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	}
	menu.ExitBackButton = true;
	return menu;
}

public int HandlerMenuPlayerInfoSkills(Menu menu, MenuAction action, int client, int param2){
	if(action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param2, info, sizeof(info));
		int target = GetClientOfUserId(StringToInt(info));
		if(IsValidPlayer(target)) BuildMenuPlayerInfoSkills(client, target).DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		else
		{
			NCRPG_ChatMessage(client,"%t", "The player you selected has left the server");
			BuildMenuInfoChoosePlayer(client).Display(client, MENU_TIME_FOREVER);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
			BuildMenuInfoChoosePlayer(client).Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_End)
		delete menu;
}
