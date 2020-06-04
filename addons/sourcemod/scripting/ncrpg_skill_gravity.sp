#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define ThisSkillShortName "gravity"
#define VERSION		"1.2"

int ThisSkillID;
float cfg_fPercent;
bool cfg_bLevelChange;

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
	cfg_fPercent = RPG_Configs.GetFloat(ThisSkillShortName,"percent",0.05);
	cfg_bLevelChange = RPG_Configs.GetInt(ThisSkillShortName,"level_change",1)?true:false;
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
}

public Action NCRPG_OnSkillLevelChange(int client,int &skillid,int old_value,int &new_value) {
	if(skillid != ThisSkillID || NCRPG_IsValidSkill(ThisSkillID)|| !cfg_bLevelChange)
		return;
	
	if(IsValidPlayer(client, true))
	{
		if(NCRPG_SkillActivate(ThisSkillID,client,client)>= Plugin_Handled)return;
		NCRPG_Buffs RPG_Player = NCRPG_Buffs(client);
		RPG_Player.Gravity = 1.0-cfg_fPercent*new_value;
		NCRPG_SkillActivated(ThisSkillID,client);
	}
}

public void NCRPG_OnPlayerSpawn(int client) {
	if(NCRPG_IsValidSkill(ThisSkillID)) return;
	int level = NCRPG_GetSkillLevel(client, ThisSkillID);
	if(level > 0)
	{
		if(NCRPG_SkillActivate(ThisSkillID,client,client)>= Plugin_Handled)return;
		NCRPG_Buffs RPG_Player = NCRPG_Buffs(client);
		RPG_Player.Gravity = 1.0-cfg_fPercent*level;
		NCRPG_SkillActivated(ThisSkillID,client);
	}
}