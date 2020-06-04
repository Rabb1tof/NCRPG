#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define ThisSkillShortName "spy"
#define MAX_WEAPON_LENGTH	32
#define VERSION		"1.2"
int ThisSkillID;

float cfg_fPercent;bool cfg_bRestrict;
Handle hArrayPermittedWpn;
public Plugin myinfo = {
	name		= "NCRPG Skill "...ThisSkillShortName,
	author		= "SenatoR",
	description	= "Skill "...ThisSkillShortName..." for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() {
	if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills();
	HookEvent("player_death", OnPlayerDeath);
}

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }


public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 20, 1000,500,true); }

public void OnMapStart() {
	if(hArrayPermittedWpn == INVALID_HANDLE) hArrayPermittedWpn = CreateArray(ByteCountToCells(MAX_WEAPON_LENGTH));
	ClearArray(hArrayPermittedWpn);
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fPercent = RPG_Configs.GetFloat(ThisSkillShortName,"chance",0.03);
	cfg_bRestrict = RPG_Configs.GetInt(ThisSkillShortName,"restrict",1)?true:false;
	if(cfg_bRestrict)
	{
		char source[512];char tmp[64][MAX_WEAPON_LENGTH];
		RPG_Configs.GetString(ThisSkillShortName,"weapons",source, sizeof source, "weapon_knife");
		int count = ExplodeString(source, ",", tmp, 64, sizeof tmp); for(int i = 0; i < count; ++i) PushArrayString(hArrayPermittedWpn, tmp[i]);
	}
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	if(NCRPG_IsValidSkill(ThisSkillID))  return Plugin_Continue;
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int level = NCRPG_GetSkillLevel(attacker, ThisSkillID);
	if(IsValidPlayer(attacker,true) && IsValidPlayer(victim) && GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		if(level>0)
		{
			char buffer[PLATFORM_MAX_PATH*2];
			GetClientWeapon(attacker, buffer, sizeof buffer);
			bool wpn = IsPermittedWeapon(buffer);
			if(cfg_bRestrict && !wpn) return Plugin_Continue; 
			if(GetRandomFloat(0.0, 1.0) <= cfg_fPercent*level)
			{
				if(NCRPG_SkillActivate(ThisSkillID,attacker,victim)>= Plugin_Handled) return Plugin_Continue;
				SetSpyModel(victim,attacker);
				NCRPG_SkillActivated(ThisSkillID, attacker);
			}
		}
	}
	return Plugin_Continue; 
}

bool IsPermittedWeapon(const char[] weapon) {
	char buffer[MAX_WEAPON_LENGTH];
	for(int i = GetArraySize(hArrayPermittedWpn)-1; i >= 0; --i)
	{
		GetArrayString(hArrayPermittedWpn, i, buffer, sizeof buffer);
		if(StrEqual(weapon, buffer, false))
			return true;
	}
	
	return false;
}

void SetSpyModel(int victim,int attacker)
{
	
	char buffer[PLATFORM_MAX_PATH];
	GetClientModel(victim, buffer, sizeof(buffer));
	SetEntityModel(attacker, buffer);
	GetClientModel(attacker, buffer, sizeof(buffer));
}