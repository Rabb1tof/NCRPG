#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"

#define VERSION				"1.2"
#define ThisSkillShortName "adrenaline"

int ThisSkillID;

float cfg_fAmount; float cfg_fInterval; float cfg_fChance;
Handle g_hPlayerIsAdrenalined[MAXPLAYERS+1] = {INVALID_HANDLE,...};

public Plugin myinfo = {
	name		= "NCRPG Skill "...ThisSkillShortName,
	author		= "SenatoR",
	description	= "Skill "...ThisSkillShortName..." for NCRPG",
	version		= VERSION
};

public void OnPluginStart() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1)
	{
		for(int i = 1; i <= MaxClients; ++i)
		if(IsValidPlayer(i))
		{
			OnClientPutInServer(i);
		}
		NCRPG_OnRegisterSkills(); 
	}
}

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 10, 5,3,true); }

public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fAmount = RPG_Configs.GetFloat(ThisSkillShortName,"percent",0.1);
	cfg_fChance = RPG_Configs.GetFloat(ThisSkillShortName,"chance",0.1);
	cfg_fInterval = RPG_Configs.GetFloat(ThisSkillShortName,"interval",1.0);
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
}

public void OnClientPutInServer(int client) { SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); }

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	if(!NCRPG_IsValidSkill(ThisSkillID))  return Plugin_Continue;
	if(IsValidPlayer(victim) && IsValidPlayer(attacker) && g_hPlayerIsAdrenalined[victim]==INVALID_HANDLE)
	{
		if(GetClientTeam(victim) == GetClientTeam(attacker)) return Plugin_Continue;
		int level = NCRPG_GetSkillLevel(victim, ThisSkillID);
		if(level > 0)
		{
			if(GetRandomFloat(0.0, 1.0) <= cfg_fChance*level)
			{
				if(NCRPG_SkillActivate(ThisSkillID,victim,attacker)>= Plugin_Handled)return Plugin_Handled;
				NCRPG_Buffs(victim).Speed = NCRPG_Buffs(victim).Speed+(level*cfg_fAmount);
				g_hPlayerIsAdrenalined[victim]=CreateTimer(cfg_fInterval,Timer_OnAdrenalineStop,victim,TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int client) { StopAdrenaline(client); }

public Action Timer_OnAdrenalineStop(Handle timer,int client)
{
	NCRPG_Buffs(client).Speed = NCRPG_Buffs(client).MaxSpeed;
	g_hPlayerIsAdrenalined[client]=INVALID_HANDLE;
	NCRPG_SkillActivated(ThisSkillID,client);
	return Plugin_Stop;
}

public void StopAdrenaline(int client)
{
	if(IsValidPlayer(client)) NCRPG_SetSpeed(client,NCRPG_GetMaxSpeed(client));
	if(g_hPlayerIsAdrenalined[client]!=INVALID_HANDLE)
	{
		KillTimer(g_hPlayerIsAdrenalined[client]);
		g_hPlayerIsAdrenalined[client]=INVALID_HANDLE;
    }
}