#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define ThisSkillShortName "clone"
#define VERSION		"1.2"

int ThisSkillID;

float cfg_fPercent;
int TerroristSprite; int CTerroristSprite;

public Plugin myinfo = {
	name		= "NCRPG Decoy Clone",
	author		= "SenatoR",
	description	= "Skill Decoy Clone for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() {
	if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills();
	HookEvent("decoy_started", Event_DecoyStarted);
}

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 16, 10,5,true); }

public void OnMapStart() {
	char SpritesPath[128][2];
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fPercent = RPG_Configs.GetFloat(ThisSkillShortName,"chance",0.5);
	RPG_Configs.GetString(ThisSkillShortName,"t_model", SpritesPath[0], sizeof SpritesPath[], "models/player/tm_phoenix.mdl");
	RPG_Configs.GetString(ThisSkillShortName,"ct_model", SpritesPath[1], sizeof SpritesPath[], "models/player/ctm_st6.mdl");
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
	TerroristSprite=PrecacheModel(SpritesPath[0]);
	CTerroristSprite=PrecacheModel(SpritesPath[1]);
}

public Action Event_DecoyStarted(Event event, const char[] name, bool dontBroadcast) {
	if(NCRPG_IsValidSkill(ThisSkillID)) return Plugin_Continue;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidPlayer(client))
	{
		int level = NCRPG_GetSkillLevel(client, ThisSkillID);
		if(level>0 && GetRandomFloat(0.0,1.0) < level*cfg_fPercent)
		{
			if(NCRPG_SkillActivate(ThisSkillID,client,client)>= Plugin_Handled)return Plugin_Handled;
			float pos[3];
			pos[0] = event.GetFloat("x");
			pos[1] = event.GetFloat("y");
			pos[2] = event.GetFloat("z");
			if(GetClientTeam(client) == 2)
			{
				TE_SetupGlowSprite(pos,TerroristSprite,14.5,1.0,250);
				TE_SendToAll();
				NCRPG_SkillActivated(ThisSkillID,client);
			}
			else if(GetClientTeam(client) == 3)
			{
				TE_SetupGlowSprite(pos,CTerroristSprite,14.5,1.0,250);
				TE_SendToAll();
				NCRPG_SkillActivated(ThisSkillID,client);
			}
		}
	}
	return Plugin_Continue;
}
