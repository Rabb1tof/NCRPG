#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define ThisSkillShortName "ghoul"
#define VERSION		"1.2"

int ThisSkillID;

int cfg_iAmount;int cfg_iMaxHP;

int iHealth[MAXPLAYERS+1];
int MaxHpInternal[MAXPLAYERS+1];

public Plugin myinfo = {
	name		= "NCRPG Skill "...ThisSkillShortName,
	author		= "SenatoR",
	description	= "Skill "...ThisSkillShortName..." for NCRPG",
	version		= VERSION,
	url			= ""
};


public void OnPluginStart() {	
	HookEvent("player_death", OnPlayerDeath);
	if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills();
}

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 10, 3,2,true); }

public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_iAmount = RPG_Configs.GetInt(ThisSkillShortName,"amount",3);
	cfg_iMaxHP = RPG_Configs.GetInt(ThisSkillShortName,"maxhp",600);
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
}

public void OnClientPutInServer(int client) {
	iHealth[client] = 0;
	MaxHpInternal[client] = NCRPG_GetMaxHP(client);
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	if(NCRPG_IsValidSkill(ThisSkillID))  return Plugin_Continue;
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidPlayer(victim))
	{
		iHealth[victim] = 0;
		
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if(IsValidPlayer(attacker, true) && victim != attacker && IsAcitveWeaponKnife(attacker))
		{
			int val = NCRPG_GetSkillLevel(attacker, ThisSkillID);
			if(val > 0)
			{
				val *= cfg_iAmount;
				int hp = iHealth[attacker];
				iHealth[attacker] += val;
				if(cfg_iMaxHP && iHealth[attacker] > cfg_iMaxHP)
				{
					val = cfg_iMaxHP-hp;
					iHealth[attacker] = cfg_iMaxHP;
				}
				
				if(val)
				{
					if(NCRPG_SkillActivate(ThisSkillID,attacker,victim)>= Plugin_Handled)return Plugin_Handled;
					NCRPG_SetMaxHP(attacker, NCRPG_GetMaxHP(attacker)+val);
					SetEntityHealth(attacker, GetClientHealth(attacker)+val);
					NCRPG_SkillActivated(ThisSkillID,attacker);
				}
			}
		}
	}
	return Plugin_Continue;
}

public void NCRPG_OnPlayerSpawn(int client) {
	if(NCRPG_IsValidSkill(ThisSkillID)) return;
	if(iHealth[client] > 0) NCRPG_SetMaxHP(client, MaxHpInternal[client]);
}

bool IsAcitveWeaponKnife(int client) {
	int entity = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if(entity > MaxClients) if(entity == GetPlayerWeaponSlot(client, 2)) return true;
	return false;
}
