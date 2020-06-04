#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define ThisSkillShortName "respawn"
#define VERSION		"1.2"

int ThisSkillID;

float cfg_fPercent;int cfg_iAmount; bool cfg_bType; float cfg_fInterval;

Handle RespawnDelTimer[MAXPLAYERS+1];
int iRespAmount[MAXPLAYERS+1];

public Plugin myinfo = {
	name		= "NCRPG Respawn",
	author		= "SenatoR",
	description	= "Skill Respawn for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() {
	if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills();
	HookEvent("player_death",	OnPlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
}

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 16, 10,5,true); }


public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fPercent = RPG_Configs.GetFloat(ThisSkillShortName,"chance",0.5);
	cfg_iAmount = RPG_Configs.GetInt(ThisSkillShortName,"amount",1);
	cfg_bType = RPG_Configs.GetInt(ThisSkillShortName,"type",1)?true:false;
	cfg_fInterval = RPG_Configs.GetFloat(ThisSkillShortName,"chance",0.5);
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	if(NCRPG_IsValidSkill(ThisSkillID))  return Plugin_Continue;
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(IsValidPlayer(victim)&& IsValidPlayer(attacker))
	{
		int level = NCRPG_GetSkillLevel(victim, ThisSkillID);
		if(level > 0)
		{
			if(GetRandomFloat(0.0, 100.0) <= cfg_fPercent*level)
			{
				if (iRespAmount[victim] < cfg_iAmount)
				{
					if(NCRPG_SkillActivate(ThisSkillID, victim,attacker)>= Plugin_Handled)return Plugin_Handled;
					DataPack pack = new DataPack();pack.WriteCell(victim);
					if(cfg_bType){
						float fRespPos[3];
						GetClientAbsOrigin(victim,fRespPos);
						pack.WriteFloat(fRespPos[0]);
						pack.WriteFloat(fRespPos[1]);
						pack.WriteFloat(fRespPos[2]);
					}
					RespawnDelTimer[victim] = CreateTimer(cfg_fInterval, Respawn, pack, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);					
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Respawn(Handle timer,  DataPack pack) 
{
	pack.Reset(false); int client = pack.ReadCell(); RespawnDelTimer[client] = INVALID_HANDLE;
	if (IsValidPlayer(client) && !IsPlayerAlive(client) && GetClientTeam(client) > 1)
	{
		iRespAmount[client]++; CS_RespawnPlayer(client);
		if(cfg_bType)
		{
			float fRespPos[3];
			fRespPos[0] = pack.ReadFloat();
			fRespPos[1] = pack.ReadFloat();
			fRespPos[2] = pack.ReadFloat();
			TeleportEntity(client,fRespPos,NULL_VECTOR,NULL_VECTOR);
		}
		NCRPG_SkillActivated(ThisSkillID,client);
	}
}


public void NCRPG_OnPlayerSpawn(int client) { ClientKillTimer(client); }
public void OnClientDisconnect(int client) { ClientKillTimer(client); }
void ClientKillTimer(int client) { if (RespawnDelTimer[client] != INVALID_HANDLE) { KillTimer(RespawnDelTimer[client]); RespawnDelTimer[client] = INVALID_HANDLE; } }

public Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) { for (int i = 1; i <= MaxClients; i++) iRespAmount[i] = 0; }
