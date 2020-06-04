#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define VERSION		"1.2"
#define ThisSkillShortName "tesla"
int ThisSkillID;
float cfg_fChance; float cfg_fInterval; float cfg_fRange;
int cfg_iAmount; int cfg_bDeath; int cfg_bEffects; bool cfg_bLevelChange;
Handle hTimerTeslaCoil[MAXPLAYERS+1];
char Tesla_Effect[][] ={"st_elmos_fire","st_elmos_fire_cp0","st_elmos_fire_cp1","tesla_vitcim"};

public Plugin myinfo = {
	name		= "NCRPG Tesla Coil",
	author		= "SenatoR",
	description	= "Skill Tesla Coil for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills(); }

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 20, 10,5,true); }

public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_iAmount = RPG_Configs.GetInt(ThisSkillShortName,"amount",1);
	cfg_fInterval = RPG_Configs.GetFloat(ThisSkillShortName,"interval",1.5);
	cfg_fChance = RPG_Configs.GetFloat(ThisSkillShortName,"chance",0.05);
	cfg_fRange = RPG_Configs.GetFloat(ThisSkillShortName,"range",5.0);
	cfg_bDeath = RPG_Configs.GetInt(ThisSkillShortName,"death",0)?true:false;
	cfg_bLevelChange = RPG_Configs.GetInt(ThisSkillShortName,"level_change",1)?true:false;
	cfg_bEffects = RPG_Configs.GetInt(ThisSkillShortName,"effects",0)?true:false;
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
	if(cfg_bEffects)
	{
		AddFileToDownloadsTable("particles/ncrpg_tesla_coil.pcf");
		AddFileToDownloadsTable("materials/effects/electric1.vmt");
		AddFileToDownloadsTable("materials/effects/electric1.vtf");
		PrecacheParticle("particles/ncrpg_tesla_coil.pcf");
		for(int i = 0; i<=3;i++)
			PrecacheParticleEffect(Tesla_Effect[i]);
	}
}



public Action NCRPG_OnSkillLevelChange(int client, &skillid,int old_value, &new_value) {
	if(skillid != ThisSkillID || NCRPG_IsValidSkill(ThisSkillID)|| !cfg_bLevelChange) return;
	
	if(hTimerTeslaCoil[client] == INVALID_HANDLE)		hTimerTeslaCoil[client] = CreateTimer(cfg_fInterval, Timer_TeslaCoil, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientConnected(int client) {	
	hTimerTeslaCoil[client] = INVALID_HANDLE;
}
public void NCRPG_OnPlayerSpawn(int client) {
	if(NCRPG_IsValidSkill(ThisSkillID)) return;
	if(hTimerTeslaCoil[client] != INVALID_HANDLE)
	{
		KillTimer(hTimerTeslaCoil[client]);
		hTimerTeslaCoil[client] = INVALID_HANDLE;
	}
	if(NCRPG_GetSkillLevel(client, ThisSkillID) > 0) hTimerTeslaCoil[client] = CreateTimer(cfg_fInterval, Timer_TeslaCoil, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_TeslaCoil(Handle timer, int client) {
	if(IsValidPlayer(client, true))
	{
		int level = NCRPG_GetSkillLevel(client, ThisSkillID);
		if(level > 0)
		{
			TeslaCoil(client,level);
			return Plugin_Continue;
		}
	}
	
	hTimerTeslaCoil[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

void TeslaCoil(int client,int level)
{
	float ClientPos[3]; float AttackerPos[3];float Range = cfg_fRange*level;int amount= cfg_iAmount;
	GetClientAbsOrigin(client,ClientPos);
	ClientPos[2]+=45;
	for(int attacker = 1; attacker <= MaxClients; ++attacker)
	{
		if(!IsValidPlayer(attacker,true))
			continue;
		if(GetClientTeam(attacker) == GetClientTeam(client))
			continue;
		GetClientAbsOrigin(attacker, AttackerPos);
		AttackerPos[2]+=45;
		if(GetVectorDistance(AttackerPos, ClientPos, false) < Range)
		{
			if(GetRandomFloat(0.0, 1.0) <= cfg_fChance*level)
			{
				if(NCRPG_SkillActivate(ThisSkillID,client,attacker)>= Plugin_Handled) return;
				if(cfg_bEffects)
				{
					AttachParticlePlayer(client,Tesla_Effect[0],attacker,cfg_fInterval);
					//AttachParticle(client,Tesla_Effect[0],ClientPos);
					AttachThrowAwayParticle(client,Tesla_Effect[3],ClientPos,_,cfg_fInterval);
				}
				
				if(amount >= GetClientHealth(attacker))
					if(cfg_bDeath)
						amount = GetClientHealth(attacker)+1;
					else
						amount = GetClientHealth(attacker)-1;
				
				if(amount)
				{
					NCRPG_DealDamage(attacker, amount, client, DMG_SHOCK, "weapon_taser");
					NCRPG_SkillActivated(ThisSkillID, client);
				}
			}
		}
	}
}