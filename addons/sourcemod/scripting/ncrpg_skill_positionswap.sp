#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define VERSION		"1.2"
#define ThisSkillShortName "pswap"
int ThisSkillID;
float fPlayerLocation[MAXPLAYERS][3];
float cfg_fPercent; bool cfg_bEffects;
char teleport_Effect[][] ={"blink_dagger_start","blink_dagger_end_sparkles","teleport_screen"};

public Plugin myinfo = {
	name		= "NCRPG Position Swap",
	author		= "SenatoR",
	description	= "Skill Position Swap for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills(); }

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 40, 3,2,true); }

public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fPercent = RPG_Configs.GetFloat(ThisSkillShortName,"chance",0.05);
	cfg_bEffects = RPG_Configs.GetInt(ThisSkillShortName,"effects",0)?true:false;
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
	
	if(cfg_bEffects)
	{
		AddFileToDownloadsTable("particles/ncrpg_pswap.pcf");
		AddFileToDownloadsTable("particles/ncrpg_teleport_scr.pcf");
		AddFileToDownloadsTable("materials/particle/particle_flares/aircraft_blue.vmt");
		AddFileToDownloadsTable("materials/particle/particle_flares/aircraft_blue.vtf");
		AddFileToDownloadsTable("materials/particle/particle_flares/aircraft_blue2.vmt");
		AddFileToDownloadsTable("materials/particle/particle_flares/aircraft_blue2_usez.vmt");
		AddFileToDownloadsTable("materials/particle/particle_flares/aircraft_blue2.vtf");
		AddFileToDownloadsTable("materials/particle/impact/fleks3.vtf");
		AddFileToDownloadsTable("materials/particle/impact/fleks3.vmt");
		AddFileToDownloadsTable("materials/particle/impact/fleks3_mote.vmt");
		AddFileToDownloadsTable("materials/particle/impact/fleks3_outline.vmt");
		AddFileToDownloadsTable("materials/particle/impact/fleks3_outline_soft.vmt");
		AddFileToDownloadsTable("materials/particle/warp_blur.vmt");
		AddFileToDownloadsTable("materials/particle/warp_blur_noz.vmt");
		AddFileToDownloadsTable("materials/particle/warp_ripple2_noz.vmt");
		PrecacheParticle("particles/ncrpg_pswap.pcf");
		PrecacheParticle("particles/ncrpg_teleport_scr.pcf");
		PrecacheParticleEffect(teleport_Effect[0]);
		PrecacheParticleEffect(teleport_Effect[1]);
		PrecacheParticleEffect(teleport_Effect[2]);
		
	}
}


public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim,int &attacker,int &inflictor,float &damage,int &damagetype) 
{
	if(NCRPG_IsValidSkill(ThisSkillID))  return Plugin_Continue;
	if(IsValidPlayer(victim,true) && IsValidPlayer(attacker,true) && victim != attacker)
	{
		if(GetClientTeam(victim) == GetClientTeam(attacker))
			return Plugin_Continue;
					
		int level = NCRPG_GetSkillLevel(victim, ThisSkillID);
		if(level>0 && GetRandomFloat() < level*cfg_fPercent)
		{
			if(NCRPG_SkillActivate(ThisSkillID,victim,attacker)>= Plugin_Handled)return Plugin_Handled;
			GetClientAbsOrigin(victim, fPlayerLocation[victim]);
			GetClientAbsOrigin(attacker, fPlayerLocation[attacker]);
			TeleportEntity(victim, fPlayerLocation[attacker], NULL_VECTOR, NULL_VECTOR);
			TeleportEntity(attacker, fPlayerLocation[victim], NULL_VECTOR, NULL_VECTOR);
			if(cfg_bEffects)
			{
				AttachThrowAwayParticle(attacker,teleport_Effect[2],fPlayerLocation[attacker],_,1.0);
				NCRPG_CreateParticle(teleport_Effect[1], fPlayerLocation[attacker], NULL_VECTOR);
				NCRPG_CreateParticle(teleport_Effect[0], fPlayerLocation[victim], NULL_VECTOR);
			}
			NCRPG_SkillActivated(ThisSkillID, victim);
		}
	}
	return Plugin_Continue;
}