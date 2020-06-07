#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
//Constants
#define VERSION		"1.2"
#define ThisSkillShortName "speed"
//Variables
int ThisSkillID;
float cfg_fAmount;
bool cfg_bLevelChange;
//Plugin Info
public Plugin myinfo = {
	name		= "NCRPG Skill "...ThisSkillShortName,
	author		= "SenatoR",
	description	= "Skill "...ThisSkillShortName..." for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills(); }

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 20, 10,5,true); }

public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fAmount = RPG_Configs.GetFloat(ThisSkillShortName,"percent",0.05);
	cfg_bLevelChange = RPG_Configs.GetInt(ThisSkillShortName,"level_change",1)?true:false;
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
}

public Action NCRPG_OnSkillLevelChange(int client, &skillid,int old_value, &new_value) {
	if(skillid != ThisSkillID || !NCRPG_IsValidSkill(ThisSkillID)|| !cfg_bLevelChange) return;
	if(IsValidPlayer(client, true))
	{
		if(NCRPG_SkillActivate(ThisSkillID,client,client)>= Plugin_Handled)return;
		NCRPG_Buffs RPG_Player = NCRPG_Buffs(client);
		float Value = RPG_Player.MaxSpeed+(new_value-old_value)*cfg_fAmount;
		RPG_Player.MaxSpeed = Value;
		RPG_Player.Speed = Value;
		NCRPG_SkillActivated(ThisSkillID, client);
	}
}

public void NCRPG_OnPlayerSpawn(int client) {
	if(!NCRPG_IsValidSkill(ThisSkillID)) return;
	int level = NCRPG_GetSkillLevel(client, ThisSkillID);
	if(level > 0)
	{
		if(NCRPG_SkillActivate(ThisSkillID,client,client)>= Plugin_Handled)return;
		NCRPG_Buffs RPG_Player = NCRPG_Buffs(client);
		float Value = RPG_Player.MaxSpeed+cfg_fAmount*level;
		RPG_Player.MaxSpeed = Value;
		RPG_Player.Speed = Value;
		NCRPG_SkillActivated(ThisSkillID, client);
	}
}