#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define VERSION		"1.4"
#define ThisSkillShortName "bouncybull"
#define MAX_WEAPON_LENGTH	32
int ThisSkillID;
float cfg_fAmount;bool cfg_bRestrict;
Handle hArrayPermittedWpn;

public Plugin myinfo = {
	name		= "NCRPG Bouncy Bullets",
	author		= "SenatoR",
	description	= "Skill Bouncy Bullets for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() {
	if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills();
}

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 16, 10,5,true); }

public void OnMapStart() {
	if(hArrayPermittedWpn == INVALID_HANDLE) hArrayPermittedWpn = CreateArray(ByteCountToCells(MAX_WEAPON_LENGTH));
	ClearArray(hArrayPermittedWpn);
	
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fAmount = RPG_Configs.GetFloat(ThisSkillShortName,"amount",10.0);
	cfg_bRestrict = RPG_Configs.GetInt(ThisSkillShortName,"restrict",1)?true:false;
	if(cfg_bRestrict)
	{
		char source[512];char tmp[64][MAX_WEAPON_LENGTH];
		RPG_Configs.GetString(ThisSkillShortName,"weapons",source, sizeof source, "weapon_knife");
		int count = ExplodeString(source, ",", tmp, 64, sizeof tmp); for(int i = 0; i < count; ++i) PushArrayString(hArrayPermittedWpn, tmp[i]);
	}
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
}

public void OnClientPutInServer(int client) { SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); }

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	if(NCRPG_IsValidSkill(ThisSkillID))  return Plugin_Continue;
	if(IsValidPlayer(victim) && IsValidPlayer(attacker) && victim != attacker)
	{	
		if(GetClientTeam(victim) == GetClientTeam(attacker))
			return Plugin_Continue;
		char buffer[PLATFORM_MAX_PATH*2];
		GetClientWeapon(attacker, buffer, sizeof buffer);
		bool wpn = IsPermittedWeapon(buffer);
			
		int level = NCRPG_GetSkillLevel(attacker, ThisSkillID);
		if(level>0 && damage>=1.0 && !wpn && !cfg_bRestrict)
		{
			if(NCRPG_SkillActivate(ThisSkillID,attacker,victim)>= Plugin_Handled)return Plugin_Handled;
			float victimloc[3]; float attackerloc[3]; float fv[3];
			GetClientEyePosition(victim, victimloc);
			GetClientEyePosition(attacker, attackerloc);
			MakeVectorFromPoints(attackerloc, victimloc, fv);
			NormalizeVector(fv, fv);
			ScaleVector(fv, cfg_fAmount*level);
			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, fv);
			NCRPG_SkillActivated(ThisSkillID,victim);
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
