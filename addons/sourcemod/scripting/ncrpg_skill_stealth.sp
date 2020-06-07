#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"

#define VERSION				"1.3"
#define ThisSkillShortName "stealth"

int ThisSkillID;int cfg_iAmount; bool cfg_bLevelChange;

public Plugin myinfo = {
	name		= "NCRPG Skill "...ThisSkillShortName,
	author		= "SenatoR",
	description	= "Skill "...ThisSkillShortName..." for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills(); }

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 5, 15, 10,true); }

public void OnMapStart() {	
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_iAmount = RPG_Configs.GetInt(ThisSkillShortName,"amount",34);
	cfg_bLevelChange = RPG_Configs.GetInt(ThisSkillShortName,"level_change",1)?true:false;
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
}

public Action NCRPG_OnSkillLevelChange(int client,int &skillid,int old_value,int &new_value) {
	if(skillid != ThisSkillID || !NCRPG_IsValidSkill(ThisSkillID) || !cfg_bLevelChange) return;
		
	if(IsValidPlayer(client, true))
	{
		if(NCRPG_SkillActivate(ThisSkillID,client,client)>= Plugin_Handled) return;
		NCRPG_Buffs RPG_Player = NCRPG_Buffs(client);
		int Value = 255-cfg_iAmount*new_value;
		RPG_Player.MaxAlpha = Value;
		RPG_Player.Alpha = Value;
		NCRPG_SkillActivated(ThisSkillID, client);
	}
}

public void NCRPG_OnPlayerSpawnedPost(int client) {
	if(!NCRPG_IsValidSkill(ThisSkillID)) return;
	int level = NCRPG_GetSkillLevel(client, ThisSkillID);
	if(level > 0)
	{
		if(NCRPG_SkillActivate(ThisSkillID,client,client)>= Plugin_Handled) return;
		NCRPG_Buffs RPG_Player = NCRPG_Buffs(client);
		int Value = 255-cfg_iAmount*level;
		RPG_Player.MaxAlpha = Value;
		RPG_Player.Alpha = Value;
		NCRPG_SkillActivated(ThisSkillID, client);
	}
}