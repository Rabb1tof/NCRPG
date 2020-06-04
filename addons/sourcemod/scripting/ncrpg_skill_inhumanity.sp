#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define VERSION		"1.3"
#define ThisSkillShortName "inhumanity"
int ThisSkillID;
float cfg_fChance; float cfg_fRange; int cfg_iAmount;

public Plugin myinfo = {
	name		= "NCRPG Skill "...ThisSkillShortName,
	author		= "SenatoR",
	description	= "Skill "...ThisSkillShortName..." for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() {
	if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills();
	HookEvent("player_death",	OnPlayerDeath);
}

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 30, 10,5); }

public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fChance = RPG_Configs.GetFloat(ThisSkillShortName,"chance",0.3);
	cfg_fRange = RPG_Configs.GetFloat(ThisSkillShortName,"range",130.0);
	cfg_iAmount = RPG_Configs.GetInt(ThisSkillShortName,"amount",1);
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
}


public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	if(NCRPG_IsValidSkill(ThisSkillID))  return Plugin_Continue;
	int victim = GetClientOfUserId(event.GetInt("userid"));
	float deathvec[3];float gainhpvec[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidPlayer(victim) && IsValidPlayer(i,true))
		{
			int level = NCRPG_GetSkillLevel(i, ThisSkillID);
			if(level > 0)
			{
				if(GetRandomFloat(0.0, 1.0) <= cfg_fChance*level)
				{
					int amount = cfg_iAmount*level;
					GetClientAbsOrigin(victim,deathvec); GetClientAbsOrigin(i,gainhpvec);
					if(GetVectorDistance(deathvec,gainhpvec)<=cfg_fRange*level)
					{
						if(NCRPG_SkillActivate(ThisSkillID,i,victim)>= Plugin_Handled)return Plugin_Handled;
						NCRPG_Buffs(i).HealToMaxHP(amount);
						NCRPG_SkillActivated(ThisSkillID,i);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
