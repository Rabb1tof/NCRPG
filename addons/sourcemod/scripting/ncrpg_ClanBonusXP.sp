#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON
#include <sourcemod>
#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS
#include "NCIncs/nc_rpg.inc"
#define VERSION		"1.1"
#define ThisAddonName "ClanBonusXP"

public Plugin myinfo = 
{
    name = "NCRPG Clan Bonus XP",
    author = "SenatoR",
    description = "Give members of a specific steamgroup bonus XP",
	version		= VERSION
};

char cfg_ClanName[32];float cfg_fExpMultipler; bool cfg_bWelcomeMessage; float cfg_fWelcomeMessageTimer;
bool bIsInGroup[MAXPLAYERS+1] = false;

public void OnPluginStart()
{
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisAddonName,CONFIG_ADDON);
	RPG_Configs.GetString(ThisAddonName,"name", cfg_ClanName, sizeof cfg_ClanName, "");
	cfg_fExpMultipler = RPG_Configs.GetFloat(ThisAddonName,"xprate",1.1);
	cfg_bWelcomeMessage = RPG_Configs.GetInt(ThisAddonName,"welcome_msg",1)?true:false;
	if(cfg_bWelcomeMessage) cfg_fWelcomeMessageTimer = RPG_Configs.GetFloat(ThisAddonName,"welcome_msg_timer",30.0);
	RPG_Configs.SaveConfigFile(ThisAddonName,CONFIG_ADDON);
	LoadTranslations ("ncrpg_clanbonus_xp.phrases.txt");
	LoadTranslations ("ncrpg.phrases.txt");
}

public Action NCRPG_OnPlayerGiveExpPre(int client, &Exp)
{
	bool bAwardBonus = false;
	if(GAMECSANY) 
	{
		char buffer[32];
		CS_GetClientClanTag(client,buffer, sizeof(buffer));
		if(strlen(buffer)>0 && strlen(cfg_ClanName)>0)
			if(strcmp(buffer, cfg_ClanName)==0)  bAwardBonus = true;
	}
	if( bAwardBonus ){ Exp = RoundToNearest(Exp*cfg_fExpMultipler); return Plugin_Changed; }
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    if (!IsValidPlayer(client) || IsFakeClient (client)) return;
	
    if(cfg_bWelcomeMessage) CreateTimer (cfg_fWelcomeMessageTimer, WelcomeAdvertTimer, client);
    bIsInGroup[client] = false;
}

stock void FloatToCutString(float value, char[] target, int targetSize,int DecPlaces) {
	char fmt[8];
	FormatEx(fmt, sizeof(fmt), "%%.%df", DecPlaces); // e.g., 2 places = %.2f
	FormatEx(target, targetSize, fmt, value);
}

public Action WelcomeAdvertTimer (Handle timer, int client)
{
	char ClientName[MAX_NAME_LENGTH] = "";
	float xprate = (cfg_fExpMultipler-1)*100.0;
	char str_xprate[8];
	if (strlen(cfg_ClanName)>0 && IsValidPlayer(client)) 
	{
		GetClientName (client, ClientName, sizeof (ClientName));
		FloatToCutString(xprate, str_xprate, sizeof(str_xprate),0);
		Format(ClientName, sizeof(ClientName), "\x01\x03%s\x01", ClientName);
		char buffer2[32];
		Format(buffer2, sizeof(buffer2), "\x01\x04%s\x01", cfg_ClanName);
		Format(str_xprate,sizeof(str_xprate),"\x01\x04%s\x01",str_xprate);
		NCRPG_ChatMessage (client, "%T", "Welcome",client,ClientName,buffer2);
		if (xprate==0) NCRPG_ChatMessage (client, "%T", "Welcome_No_Bonus",client);
		else NCRPG_ChatMessage(client, "%T", "Welcome_XP",client,str_xprate);
	}
	return Plugin_Stop;
}