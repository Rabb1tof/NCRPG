#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define VERSION				"1.2"
#define ThisSkillShortName "engineer"
int ThisSkillID;

int cfg_iAmount; bool cfg_bLevelChange;
float cfg_fInterval;float cfg_fRange;

Handle hTimerEngineer[MAXPLAYERS+1];

public Plugin myinfo = {
	name		= "NCRPG Skill "...ThisSkillShortName,
	author		= "SenatoR",
	description	= "Skill "...ThisSkillShortName..." for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills(); }

public void OnPluginEnd() {	if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 16, 10,5,true); }

public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_iAmount = RPG_Configs.GetInt(ThisSkillShortName,"amount",2);
	cfg_fInterval = RPG_Configs.GetFloat(ThisSkillShortName,"interval",1.0);
	cfg_fRange = RPG_Configs.GetFloat(ThisSkillShortName,"range",10.0);
	cfg_bLevelChange = RPG_Configs.GetInt(ThisSkillShortName,"level_change",1)?true:false;
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
	
}

public Action NCRPG_OnSkillLevelChange(int client, &skillid,int old_value, &new_value) {
	if(skillid != ThisSkillID || NCRPG_IsValidSkill(ThisSkillID)|| !cfg_bLevelChange) return;
	if(hTimerEngineer[client] == INVALID_HANDLE) hTimerEngineer[client] = CreateTimer(cfg_fInterval, Timer_engineer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientConnected(int client) {	hTimerEngineer[client] = INVALID_HANDLE; }

public void NCRPG_OnPlayerSpawn(int client) {
	if(NCRPG_IsValidSkill(ThisSkillID)) return;
	if(hTimerEngineer[client] != INVALID_HANDLE)
	{
		KillTimer(hTimerEngineer[client]);
		hTimerEngineer[client] = INVALID_HANDLE;
	}
	if(NCRPG_GetSkillLevel(client, ThisSkillID) > 0) hTimerEngineer[client] = CreateTimer(cfg_fInterval, Timer_engineer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_engineer(Handle timer, any client) {
	if(IsValidPlayer(client, true))
	{
		int level = NCRPG_GetSkillLevel(client, ThisSkillID);
		if(level > 0)
		{
		
			int team = GetClientTeam(client);
			float ClientPos[3];float TeamPos[3];
			GetClientAbsOrigin(client,ClientPos);
			float Range = level*cfg_fRange;
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsValidPlayer( i, true )&& GetClientTeam(i) == team && client != i)
				{
					GetClientAbsOrigin(i,TeamPos);
					if(GetVectorDistance(ClientPos, TeamPos, false) <= Range)
					{
						int armor = Client_GetArmor(i);
						if(armor >= 100) return Plugin_Continue;
						if(NCRPG_SkillActivate(ThisSkillID,client,i)>= Plugin_Handled) return Plugin_Handled;
						armor += level*cfg_iAmount;
						if(armor > 100) armor = 100;
						Client_SetArmor(i, armor);
						NCRPG_SkillActivated(ThisSkillID,client);
						return Plugin_Continue;
					}
				}
			}
			return Plugin_Continue;
		}
	}
	
	hTimerEngineer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}


stock int Client_GetArmor(int client) { return GetEntProp(client, Prop_Data, "m_ArmorValue"); }

stock void Client_SetArmor(int client,int value) { SetEntProp(client, Prop_Data, "m_ArmorValue", value); }