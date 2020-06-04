#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"

#define VERSION				"1.3"
#define ThisSkillShortName "regenhp"
int ThisSkillID;
int cfg_iAmount;
float cfg_fInterval;
bool cfg_bLevelChange;
Handle hTimerRegenHP[MAXPLAYERS+1];

public Plugin myinfo = {
	name		= "NCRPG Skill Regen HP",
	author		= "SenatoR",
	description	= "Skill Regen HP for NCRPG",
	version		= VERSION
};

public void OnPluginStart() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills(); }

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 16, 10,5,true); }

public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_iAmount = RPG_Configs.GetInt(ThisSkillShortName,"amount",2);
	cfg_fInterval = RPG_Configs.GetFloat(ThisSkillShortName,"interval",1.0);
	cfg_bLevelChange = RPG_Configs.GetInt(ThisSkillShortName,"level_change",1)?true:false;
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
}

public Action NCRPG_OnSkillLevelChange(int client, &skillid,int old_value, &new_value) {
	if(skillid != ThisSkillID || NCRPG_IsValidSkill(ThisSkillID)|| !cfg_bLevelChange) return;

	if(hTimerRegenHP[client] == INVALID_HANDLE)
	{
		if(NCRPG_SkillActivate(ThisSkillID,client,client)>= Plugin_Handled)return;
		hTimerRegenHP[client] = CreateTimer(cfg_fInterval, Timer_RegenHP, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnClientConnected(int client) {	hTimerRegenHP[client] = INVALID_HANDLE; }

public void NCRPG_OnPlayerSpawn(int client) {
	if(NCRPG_IsValidSkill(ThisSkillID)) return;
	if(hTimerRegenHP[client] != INVALID_HANDLE)
	{
		KillTimer(hTimerRegenHP[client]);
		hTimerRegenHP[client] = INVALID_HANDLE;
	}
	
	if(NCRPG_GetSkillLevel(client, ThisSkillID) > 0){
		if(NCRPG_SkillActivate(ThisSkillID,client,client)>= Plugin_Handled)return;
		hTimerRegenHP[client] = CreateTimer(cfg_fInterval, Timer_RegenHP, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_RegenHP(Handle timer, int client) {
	if(IsValidPlayer(client, true))
	{
		int level = NCRPG_GetSkillLevel(client, ThisSkillID);
		if(level > 0)
		{
			NCRPG_Buffs(client).HealToMaxHP(level*cfg_iAmount);
			return Plugin_Continue;
		}
	}
	
	hTimerRegenHP[client] = INVALID_HANDLE;
	NCRPG_SkillActivated(ThisSkillID, client);
	return Plugin_Stop;
}