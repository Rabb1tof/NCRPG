#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define ThisSkillShortName "parasite"
#define VERSION				"1.2"

int ThisSkillID;

float cfg_fChance;
bool bDucking[MAXPLAYERS];

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


public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 10, 5,3,true); }

public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fChance = RPG_Configs.GetFloat(ThisSkillShortName,"chance",0.03);
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
}

public Action OnPlayerRunCmd(int client,int &buttons,int &impulse, float vel[3], float angles[3],int &weapon)
{
	if(IsValidPlayer(client,true)) bDucking[client]=(buttons & IN_DUCK)?true:false;
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	if(NCRPG_IsValidSkill(ThisSkillID))  return Plugin_Continue;
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(IsValidPlayer(victim) && IsValidPlayer(attacker,true))
	{
		int level = NCRPG_GetSkillLevel(attacker, ThisSkillID);
		if(level > 0)
		{
			if(GetRandomFloat(0.0, 100.0) <= cfg_fChance*level)
			{
				if(bDucking[attacker])
				{
					if(NCRPG_SkillActivate(ThisSkillID,attacker,victim)>= Plugin_Handled)return Plugin_Handled;
					float GlobPos[3];
					GetClientAbsOrigin(victim, GlobPos);
					TeleportEntity(attacker, GlobPos, NULL_VECTOR, NULL_VECTOR);
					NCRPG_SkillActivated(ThisSkillID,attacker);
				}
			}
		}
	}
	return Plugin_Continue;
}