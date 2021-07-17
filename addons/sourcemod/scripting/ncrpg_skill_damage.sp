#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define VERSION		"1.4"
#define MAX_WEAPON_LENGTH	32
#define ThisSkillShortName "damage"
int ThisSkillID;

float cfg_fPercent;bool cfg_bRestrict;bool cfg_bEffects;bool cfg_bStaticChance; float cfg_fChance;
Handle hArrayPermittedWpn;
char Damage_Effect[][] = {"text_minicrit","text_crit","text_miss"};
public Plugin myinfo = {
	name		= "NCRPG Skill "...ThisSkillShortName,
	author		= "SenatoR",
	description	= "Skill "...ThisSkillShortName..." for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills(); }

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 16, 3,2,true); }

public OnMapStart() {
	if(hArrayPermittedWpn == INVALID_HANDLE) hArrayPermittedWpn = CreateArray(ByteCountToCells(MAX_WEAPON_LENGTH));
	ClearArray(hArrayPermittedWpn);

	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_bStaticChance = RPG_Configs.GetInt(ThisSkillShortName,"static",1)?true:false;
	if(!cfg_bStaticChance) cfg_fChance = RPG_Configs.GetFloat(ThisSkillShortName,"chance",0.1);
	cfg_fPercent = RPG_Configs.GetFloat(ThisSkillShortName,"percent",0.05);
	cfg_bEffects = RPG_Configs.GetInt(ThisSkillShortName,"effects",1)?true:false;
	cfg_bRestrict = RPG_Configs.GetInt(ThisSkillShortName,"restrict",1)?true:false;
	if(cfg_bRestrict)
	{
		char source[512];char tmp[64][MAX_WEAPON_LENGTH];
		RPG_Configs.GetString(ThisSkillShortName,"weapons",source, sizeof source, "weapon_knife");
		int count = ExplodeString(source, ",", tmp, 64, sizeof tmp); for(int i = 0; i < count; ++i) PushArrayString(hArrayPermittedWpn, tmp[i]);
	}
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
	
	if(cfg_bEffects)
	{
		AddFileToDownloadsTable("particles/ncrpg_crit.pcf");
		AddFileToDownloadsTable("materials/effects/crit.vmt");
		AddFileToDownloadsTable("materials/effects/crit.vtf");
		AddFileToDownloadsTable("materials/effects/miss.vmt");
		AddFileToDownloadsTable("materials/effects/miss.vtf");
		AddFileToDownloadsTable("materials/effects/minicrit.vmt");
		AddFileToDownloadsTable("materials/effects/minicrit.vtf");
		PrecacheParticle("particles/ncrpg_crit.pcf");
		for(int i = 0; i<=2;i++)
			PrecacheParticleEffect(Damage_Effect[i]);
	}
}


public void OnClientPutInServer(int client) { SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); }

public Action OnTakeDamage(int victim,int &attacker,int &inflictor,float &damage,int &damagetype) 
{
	if(!NCRPG_IsValidSkill(ThisSkillID))  return Plugin_Continue;
	if(IsValidPlayer(victim) && IsValidPlayer(attacker) && victim != attacker)
	{
		if(GetClientTeam(victim) == GetClientTeam(attacker)) return Plugin_Continue;
		
		int level = NCRPG_GetSkillLevel(attacker, ThisSkillID);
		char buffer[PLATFORM_MAX_PATH*2];
		GetClientWeapon(attacker, buffer, sizeof buffer);
		bool wpn = IsPermittedWeapon(buffer);
		if(cfg_bRestrict && wpn) return Plugin_Continue; 
		
		if(level>0 && damage>=1.0)
		{
			if(cfg_bStaticChance){
				if(NCRPG_SkillActivate(ThisSkillID,attacker,victim)>= Plugin_Handled)return Plugin_Continue;
				damage*= 1.0+cfg_fPercent*level;
				NCRPG_SkillActivated(ThisSkillID,attacker);
				return Plugin_Changed;
			}
			else
			{
				if(GetRandomFloat(0.0, 1.0) <= cfg_fChance*level)
				{
					if(NCRPG_SkillActivate(ThisSkillID,attacker,victim)>= Plugin_Handled)return Plugin_Continue;
					if(cfg_bEffects)
					{
						float pos[3]; GetClientAbsOrigin(victim, pos); pos[2] += 65.0;
						AttachThrowAwayParticle(victim,Damage_Effect[0],pos,_,1.0);
					}
					damage*= 1.0+cfg_fPercent*level;
					NCRPG_SkillActivated(ThisSkillID,attacker);
					return Plugin_Changed;
				}
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
		if(StrEqual(weapon, buffer, false)) return true;
	}
	
	return false;
}