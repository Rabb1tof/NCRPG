#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define ThisSkillShortName "health"
#define VERSION		"1.3"

int ThisSkillID;

int cfg_iAmount; bool cfg_bLevelChange; bool cfg_bLevelChangeHealth;

public Plugin myinfo = {
	name		= "NCRPG Skill "...ThisSkillShortName,
	author		= "SenatoR",
	description	= "Skill "...ThisSkillShortName..." for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills(); }

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 16, 10,5,true); }

public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_iAmount = RPG_Configs.GetInt(ThisSkillShortName,"amount",25);
	cfg_bLevelChange = RPG_Configs.GetInt(ThisSkillShortName,"level_change",1)?true:false;
	cfg_bLevelChangeHealth = RPG_Configs.GetInt(ThisSkillShortName,"level_change_health",0)?true:false;
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
}



public Action NCRPG_OnSkillLevelChange(int client, &skillid,int old_value, &new_value) {
	if(skillid != ThisSkillID || NCRPG_IsValidSkill(ThisSkillID)|| !cfg_bLevelChange)
		return;
	
	if(IsValidPlayer(client, true) && new_value> old_value)
	{
		if(NCRPG_SkillActivate(ThisSkillID,client,client)>= Plugin_Handled)return;
		int level = (new_value-old_value)*cfg_iAmount;
		NCRPG_Buffs RPG_Player = NCRPG_Buffs(client);
		RPG_Player.MaxHP = RPG_Player.MaxHP+level;
		if(cfg_bLevelChangeHealth){
			RPG_Player.HealToMaxHP(level);
			if(GetClientHealth(client) <= 0)
				SetEntityHealth(client, 1);
		}
		NCRPG_SkillActivated(ThisSkillID,client);
	}
}


public void NCRPG_OnPlayerSpawn(int client) {
	if(NCRPG_IsValidSkill(ThisSkillID)) { }
	int level = NCRPG_GetSkillLevel(client, ThisSkillID);
	if(level > 0)
	{
		if(NCRPG_SkillActivate(ThisSkillID,client,client)>= Plugin_Handled)return;
		level = cfg_iAmount*level;
		NCRPG_Buffs RPG_Player = NCRPG_Buffs(client);
		RPG_Player.MaxHP = RPG_Player.MaxHP+level;
		RPG_Player.HealToMaxHP(level);
		NCRPG_SkillActivated(ThisSkillID,client);
	}
}