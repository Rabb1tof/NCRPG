#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define VERSION_NUM "1.3"

public Plugin myinfo = {
	name = "NCRPG Frags Menu",
	author		= "SenatoR",
	description = "New concept RPG in source",
	version		= VERSION_NUM,
	url			= ""
};

bool cfg_bCmdsHide; //Скрытие сообщений в чат
bool cfg_bFragExchange;int cfg_iPriceFrag;
bool PlayerValue[MAXPLAYERS+1] = false;

public OnPluginStart()
{
	LoadAllConfigs();
	LoadTranslations("ncrpg.phrases");
	LoadTranslations("ncrpg_frags.phrases");
	RegConsoleCmd("say",NCRPG_SayCommand);
	RegConsoleCmd("say_team",NCRPG_SayCommand);
}

public APLRes AskPluginLoad2(Handle myself,bool late,char[] error,int err_max)
{
	RegPluginLibrary("NCRPG");
	CreateNative("NCRPG_OpenMenuExchangeFrag", 	Native_OpenExchangeFragMenu);
	return APLRes_Success;
}

public void OnClientDisconnect(int client) { PlayerValue[client] = false; }

public void OnClientPutInServer(int client) { PlayerValue[client] = false; }

public int Native_OpenExchangeFragMenu(Handle plugin, int numParams) { MenuExchangeFrags(GetNativeCell(1)); }

void LoadAllConfigs() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(CONFIG_CORE);
	cfg_iPriceFrag = RPG_Configs.GetInt("frags","price",1);
	cfg_bFragExchange = RPG_Configs.GetInt("frags","exchange",1)?true:false;
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
		if(CommandCheck(sArgs, "frags")|| CommandCheck(sArgs, "frag"))
		{
			MenuExchangeFrags(client);
			if(cfg_bCmdsHide) return Plugin_Handled;
			return Plugin_Continue;
		}
		if(PlayerValue[client])
		{
			if(StrEqual(sArgs,"stop")||StrEqual(sArgs,"cancel")||StrEqual(sArgs,"стоп")||StrEqual(sArgs,"отмена"))
			{
				PlayerValue[client] = false;
				FormatST("You cancel frags exchange!",sArgs,sizeof sArgs,client,"You exchange cancel");
				NCRPG_ChatMessage(client,sArgs);
			}
			else{
				if(StringIsNumeric(sArgs))
				{
					int val = StringToInt(sArgs);
					if(val>GetClientFrags(client)) val = GetClientFrags(client);
					SetClientFrags(client,GetClientFrags(client)-val);
					NCRPG_SetCredits(client,NCRPG_GetCredits(client)+val*cfg_iPriceFrag);
					FormatST("You succesfull exchange %d frags and get %d credits",sArgs,sizeof sArgs,client,"You succesfull exchange",val,val*cfg_iPriceFrag);
					NCRPG_ChatMessage(client,sArgs);
				}
				else {
					FormatST("You entered an incorrect value frags, your exchange is canceled!",sArgs,sizeof sArgs,client,"You write incorrect num");
					NCRPG_ChatMessage(client,sArgs);
				}
				PlayerValue[client] = false;
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

void MenuExchangeFrags(int client)
{
	if(cfg_bFragExchange)
		BuildMenuExchage(client).Display(client, MENU_TIME_FOREVER);
	else
	{
		char Message[128];
		FormatST("Sorry, this function is disabled",Message,sizeof Message,client,"This function is disabled");
		NCRPG_ChatMessage(client, Message);
	}
}


Menu BuildMenuExchage(int client) {
	Menu menu = CreateMenu(HandlerMenuExchange);
	char display[128];
	FormatST("[Exchanger]\nToday rate: 1 frag to %d credits",display,sizeof display,client,"Exchange Rates",cfg_iPriceFrag);
	menu.SetTitle(display);
	int frags = GetClientFrags(client);
	FormatST("Exchange %d frags",display,sizeof display,client,"exchange",1);
	menu.AddItem("1", display,(frags>=1)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	FormatST("Exchange %d frags",display,sizeof display,client,"exchange",5);
	menu.AddItem("5", display,(frags>=5)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	FormatST("Exchange %d frags",display,sizeof display,client,"exchange",10);
	menu.AddItem( "10", display,(frags>=10)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	FormatST("Exchange %d frags",display,sizeof display,client,"exchange",25);
	menu.AddItem( "25", display,(frags>=25)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	FormatST("Exchange all frags",display,sizeof display,client,"exchange all");
	menu.AddItem("all", display,(frags>0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	Format(display, sizeof(display), "%T", "You value", client);
	FormatST("Enter your number",display,sizeof display,client,"You value");
	menu.AddItem("val", display,(frags>0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.ExitBackButton = true;
	return menu;
}

public int HandlerMenuExchange(Menu menu, MenuAction action, int client, int param2){
	if(action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param2, info, sizeof(info));
		int frags = GetClientFrags(client);
		char Message[264];
		if(StrEqual(info,"all")){
			SetClientFrags(client,0);
			NCRPG_SetCredits(client,NCRPG_GetCredits(client)+frags*cfg_iPriceFrag);
			FormatST("You succesfull exchange %d frags and get %d credits.",Message,sizeof Message,client,"You succesfull exchange",frags,frags*cfg_iPriceFrag);
			NCRPG_ChatMessage(client,Message);
		}
		else if(StrEqual(info,"val")){
			PlayerValue[client] = true;
			FormatST("Write in chat the number of frags, which you want to exchange",Message,sizeof Message,client,"Write in chat you value");
			NCRPG_ChatMessage(client,Message);
		}
		else
		{
			int value = StringToInt(info);
			SetClientFrags(client,frags-value);
			NCRPG_SetCredits(client,NCRPG_GetCredits(client)+(frags-value));
			FormatST("You succesfull exchange %d frags and get %d credits.",Message,sizeof Message,client,"You succesfull exchange",frags,value*cfg_iPriceFrag);
			NCRPG_ChatMessage(client,Message);
		}
		

	}
	else if(action == MenuAction_End)
		delete menu;
}

stock void SetClientFrags(int iClient,int iFrags)
{
    SetEntProp(iClient, Prop_Data, "m_iFrags", iFrags);
}

bool StringIsNumeric(char[] s)
{
	int len = strlen(s);
	int check = 0;
	for(int i=0; i<len;i++) if(IsCharNumeric(s[i])) check++;
	if(check == len) return true;
	else return false;
}