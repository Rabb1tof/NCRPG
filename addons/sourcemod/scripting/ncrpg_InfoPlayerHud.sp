#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define VERSION_NUM "1.2"

public Plugin myinfo = {
	name = "NCRPG Info Player Hud",
	author = "SenatoR",
	description="New concept RPG in source",
	version = "1.2"
};

int cfg_iType; float cfg_fHudX; float cfg_fHudY;int iColor[4];

public void OnPluginStart()
{
	NCRPG_Configs RPG_Configs = NCRPG_Configs(CONFIG_CORE);
	cfg_iType = RPG_Configs.GetInt("hud","type_message",0);
	if(cfg_iType)
	{
		cfg_fHudX = RPG_Configs.GetFloat("hud","hud_pos_x", 0.005);
		cfg_fHudY = RPG_Configs.GetFloat("hud","hud_pos_y",-1.0);
		char cfg_iHudColor[16];
		RPG_Configs.GetString("hud","hud_color", cfg_iHudColor, sizeof cfg_iHudColor, "255 100 10 255");
		StringToColor(cfg_iHudColor,iColor);
	}
	RPG_Configs.SaveConfigFile(CONFIG_CORE);
	LoadTranslations("ncrpg_hudinfo.phrases");
}

void PrintHud(int client,char[] Message)
{
	if(cfg_iType)
	{
		SetHudTextParams(cfg_fHudX, cfg_fHudY, 1.0 + 0.1, iColor[0] , iColor[1], iColor[2], iColor[3], 2 , 0.0, 0.0, 0.0);
		ShowHudText(client, -1, Message);
	}
	else
	{
		PrintHintText(client, Message);
	}
}
public void NCRPG_OnPlayerSpawn(int client) {
	CreateTimer(1.0, Info_Timer, client, TIMER_REPEAT);
}

public Action Info_Timer(Handle timer, any client)
{
	if (IsValidPlayer(client))
	{
		if (IsPlayerAlive(client) && GetClientTeam(client) > 1)
		{
			char Message[1024];
			int GetLvl = NCRPG_GetLevel(client);
			int GetCredit = NCRPG_GetCredits(client);
			int GetXp = NCRPG_GetXP(client);
			int GetReqXp = NCRPG_GetReqXP(client);
			FormatST("NCRPG STATS\nLevel: %d XP: %d/%d Credits: %d",Message,sizeof Message,client,"HudInfo", GetLvl, GetXp, GetReqXp,GetCredit);
			PrintHud(client, Message);
		}
		else if (!IsPlayerAlive(client))
		{
			int i = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			if (IsValidPlayer(i,true))
			{
				char Message[1024];
				int GetLvl = NCRPG_GetLevel(i);
				int GetCredit = NCRPG_GetCredits(i);
				int GetXp = NCRPG_GetXP(i);
				int GetReqXp = NCRPG_GetReqXP(i);
				FormatST("NCRPG STATS\nName: %N Level: %d XP: %d/%d Credits: %d",Message,sizeof Message,client,"HudInfoSpec", i, GetLvl, GetXp, GetReqXp,GetCredit);
				PrintHud(client, Message);
				
				
			}
		}
		else
		{
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}


stock bool StringToColor(const char[] str,int color[4], const int defvalue = 0)
{
	bool result = false;
	char Splitter[4][64];
	if (ExplodeString(str, " ", Splitter, sizeof(Splitter), sizeof(Splitter[])) == 3 && String_IsNumeric(Splitter[0]) && String_IsNumeric(Splitter[1]) && String_IsNumeric(Splitter[2])&& String_IsNumeric(Splitter[3]))
	{
		color[0] = StringToInt(Splitter[0]);
		color[1] = StringToInt(Splitter[1]);
		color[2] = StringToInt(Splitter[2]);
		color[3] = StringToInt(Splitter[3]);
		result = true;
	}
	else
	{
		color[0] = defvalue;
		color[1] = defvalue;
		color[2] = defvalue;
		color[3] = defvalue;
	}
	return result;
}


stock bool String_IsNumeric(const char[] str)
{	
	int x=0;
	int numbersFound=0;

	if (str[x] == '+' || str[x] == '-')
		x++;

	while (str[x] != '\0')
	{
		if (IsCharNumeric(str[x]))
			numbersFound++;
		else
			return false;
		x++;
	}
	
	if (!numbersFound)
		return false;
	
	return true;
}
