#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define VERSION		"1.0"
#define ThisSkillShortName "icestab_immun"
#define IceStabSkillShortName "icestab"
int ThisSkillID;
int IceStabSkillID;
float cfg_fChance;

public Plugin myinfo = {
	name		= "NCRPG Skill "...ThisSkillShortName,
	author		= "SenatoR",
	description	= "Skill "...ThisSkillShortName..." for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills(); }
public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 30, 10,5,true); }
public void OnAllPluginsLoaded() { IceStabSkillID = NCRPG_FindSkillByShortname(IceStabSkillShortName);}
public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }


public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fChance = RPG_Configs.GetFloat(ThisSkillShortName,"chance",0.3);
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
}

public Action NCRPG_OnSkillActivatePre(int skillid,int caller,int target)
{
	//IceStabSkillID = IceStabSkillID;
	if(skillid!=IceStabSkillID) return Plugin_Continue;
	if(!NCRPG_IsValidSkill(ThisSkillID) || !NCRPG_IsValidSkill(IceStabSkillID)) return Plugin_Continue;
	int level = NCRPG_GetSkillLevel(target, ThisSkillID);
	if(level==0) return Plugin_Continue;
	if(GetRandomFloat(0.0,100.0) <= level*cfg_fChance) {
		if(NCRPG_SkillActivate(ThisSkillID,target,caller)>= Plugin_Handled) return Plugin_Continue;
		NCRPG_SkillActivated(ThisSkillID,target);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}