#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"

#define VERSION				"1.4"
#define ThisSkillShortName "medic"

int ThisSkillID;
int cfg_iAmount;
float cfg_fInterval;float cfg_fRange;
bool cfg_bLevelChange; bool cfg_bSelfRegen;bool cfg_bEffects;
Handle hTimerMedic[MAXPLAYERS+1];
char Medic_Effect[][] ={"dispenser_beam_pluses","dispenser_beam_trail","dispenser_heal","medicgun_beam_drips","medicgun_beam_healing","medicgun_beam_muzzle","overhealedplayer"};

public Plugin myinfo = {
	name		= "NCRPG Skill "...ThisSkillShortName,
	author		= "SenatoR",
	description	= "Skill "...ThisSkillShortName..." for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills(); }

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 16, 10,5,true); }

public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_iAmount = RPG_Configs.GetInt(ThisSkillShortName,"amount",2);
	cfg_fInterval = RPG_Configs.GetFloat(ThisSkillShortName,"interval",1.0);
	cfg_fRange = RPG_Configs.GetFloat(ThisSkillShortName,"range",10.0);
	cfg_bSelfRegen = RPG_Configs.GetInt(ThisSkillShortName,"self_regen",0)?true:false;
	cfg_bLevelChange = RPG_Configs.GetInt(ThisSkillShortName,"level_change",1)?true:false;
	cfg_bEffects = RPG_Configs.GetInt(ThisSkillShortName,"effects",0)?true:false;
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
	if(cfg_bEffects)
	{
		AddFileToDownloadsTable("particles/ncrpg_medic2.pcf");
		AddFileToDownloadsTable("materials/effects/healsign.vmt");
		AddFileToDownloadsTable("materials/effects/healsign.vtf");
		AddFileToDownloadsTable("materials/effects/medicbeam_curl.vtf");
		AddFileToDownloadsTable("materials/effects/medicbeam_curl.vmt");
		AddFileToDownloadsTable("materials/effects/sc_softglow.vmt");
		PrecacheParticle("particles/ncrpg_medic2.pcf");
		for(int i = 0; i<=6;i++)
			PrecacheParticleEffect(Medic_Effect[i]);
	}
}

public Action NCRPG_OnSkillLevelChange(int client,int &skillid,int old_value,int &new_value) {
	if(skillid != ThisSkillID || !NCRPG_IsValidSkill(ThisSkillID)|| !cfg_bLevelChange)
		return;
	
	if(hTimerMedic[client] == INVALID_HANDLE) hTimerMedic[client] = CreateTimer(cfg_fInterval, Timer_medic, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientConnected(int client) {	hTimerMedic[client] = INVALID_HANDLE; }

public void NCRPG_OnPlayerSpawn(int client) {
	if(!NCRPG_IsValidSkill(ThisSkillID)) return;
	if(hTimerMedic[client] != INVALID_HANDLE) { KillTimer(hTimerMedic[client]); hTimerMedic[client] = INVALID_HANDLE; }
	if(NCRPG_GetSkillLevel(client,ThisSkillID) > 0) hTimerMedic[client] = CreateTimer(cfg_fInterval, Timer_medic, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_medic(Handle timer, int client) {
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
				if( IsValidPlayer( i, true )&& GetClientTeam(i) == team && SelfRegen(client,i))
				{
					GetClientAbsOrigin(i,TeamPos);
					if(GetVectorDistance(ClientPos, TeamPos, false) <= Range)
					{
						if(NCRPG_SkillActivate(ThisSkillID,client,i)>= Plugin_Handled)return Plugin_Continue;
						NCRPG_Buffs(i).HealToMaxHP(level*cfg_iAmount);
						if(cfg_bEffects)
						{
							ClientPos[2]+=45;
							AttachParticlePlayer(client,Medic_Effect[2],i,1.0);
							AttachThrowAwayParticle(client,Medic_Effect[6],TeamPos,_,1.0);
						}
						NCRPG_SkillActivated(ThisSkillID,client);
						return Plugin_Continue;
					}
				}
			}
			return Plugin_Continue;
		}
	}
	hTimerMedic[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

bool SelfRegen(int client, int i) {
	if(client != i) return true; 
	else { if(cfg_bSelfRegen) return true; } 
	return false; 
}