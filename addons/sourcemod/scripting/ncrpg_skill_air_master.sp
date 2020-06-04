#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
//Constants
#define VERSION		"1.0"
#define ThisSkillShortName "master"
//Variables
int ThisSkillID;
int cfg_iAmount;
ConVar hAirAcceleration; 
//Plugin Info
public Plugin myinfo = {
	name		= "NCRPG Skill "...ThisSkillShortName,
	author		= "SenatoR",
	description	= "Skill "...ThisSkillShortName..." for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() { 
	if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) 
	{
		for(int i = 1; i <= MaxClients; ++i)
		if(IsValidPlayer(i))
		{
			OnClientPutInServer(i);
		}
		NCRPG_OnRegisterSkills(); 
	}
	hAirAcceleration = FindConVar("sv_airaccelerate"); 
}

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 20, 10,5,true); }

public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_iAmount = RPG_Configs.GetInt(ThisSkillShortName,"amount",100);
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
}

public void OnClientPutInServer(int client) 
{
	if(!NCRPG_IsValidSkill(ThisSkillID)) return;
	if(IsValidPlayer(client)) SDKHook(client, SDKHook_PreThinkPost, Hook_PreThink); 
}


public void Hook_PreThink(int client)
{
	if(!IsValidPlayer(client)) return;
	SetConVarInt(hAirAcceleration, hAirAcceleration.IntValue); 
}
public void NCRPG_OnPlayerSpawn(int client) {
	if(!NCRPG_IsValidSkill(ThisSkillID)) return;
	int level = NCRPG_GetSkillLevel(client, ThisSkillID);
	if(level > 0)
	{
		if(NCRPG_SkillActivate(ThisSkillID,client,client)>= Plugin_Handled)return;
		int amount = hAirAcceleration.IntValue+(cfg_iAmount*level);
		char sAirAcc[16]; IntToString(amount, sAirAcc, sizeof sAirAcc); 
		SendConVarValue(client, hAirAcceleration, sAirAcc);  
		NCRPG_SkillActivated(ThisSkillID, client);
	}
}