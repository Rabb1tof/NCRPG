#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define ThisSkillShortName "longjump"
#define VERSION				"1.3"

int ThisSkillID;

float cfg_fForce;float cfg_fStart;bool cfg_bBhop;
float g_fPreviousVelocity[MAXPLAYERS+1][3];
float g_fJumpStartTime[MAXPLAYERS+1];
bool g_bPlayerStartedJumping[MAXPLAYERS+1];
bool g_bPlayerJumped[MAXPLAYERS+1];
int g_iFootstepCount[MAXPLAYERS+1];

public Plugin myinfo = {
	name		= "NCRPG Long Jump 2",
	author		= "SenatoR",
	description	= "Skill Long Jump 2 for NCRPG [SM RPG STYLE]",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() {
	if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills();
	HookEventEx("player_footstep", Event_OnPlayerFootstep);
	HookEvent("player_death",	   Event_OnResetJump);
}

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 16, 10,5,true); }

public void OnMapStart() 
{
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName..."2",CONFIG_SKILL);
	cfg_fForce = RPG_Configs.GetFloat(ThisSkillShortName..."2","force",0.1);
	cfg_fStart = RPG_Configs.GetFloat(ThisSkillShortName..."2","force_start",0.2);
	cfg_bBhop = RPG_Configs.GetInt(ThisSkillShortName..."2","auto_bhop",1)?true:false;
	if(cfg_bBhop) SetConVarInt(FindConVar("sv_autobunnyhopping"),cfg_bBhop);
	RPG_Configs.SaveConfigFile(ThisSkillShortName..."2",CONFIG_SKILL);
}


public Action OnPlayerRunCmd(int client,int &buttons,int &impulse, float vel[3],float angles[3],int &weapon)
{
	if(NCRPG_IsValidSkill(ThisSkillID))  return Plugin_Continue;
	static int s_iLastButtons[MAXPLAYERS+1] = {0,...};
	if(!IsValidPlayer(client,true)) return Plugin_Continue;
	
	float vVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
	if(vVelocity[0] == 0.0 && vVelocity[1] == 0.0 && vVelocity[2] == 0.0) ResetJumpingState(client);

	if(buttons & IN_JUMP && (!(s_iLastButtons[client] & IN_JUMP) || cfg_bBhop))
	{
		if(GetEntityFlags(client) & FL_ONGROUND && GetEntityMoveType(client) != MOVETYPE_LADDER)
		{
			g_fPreviousVelocity[client] = vVelocity;
			g_fJumpStartTime[client] = GetEngineTime();
			g_bPlayerStartedJumping[client] = true;
		}
	}
	
	if(g_bPlayerStartedJumping[client])
	{
		if(vVelocity[2] > g_fPreviousVelocity[client][2])
		{
			if(NCRPG_SkillActivate(ThisSkillID,client,client)>= Plugin_Handled)return Plugin_Handled;
			HasJumped(client, vVelocity);
			g_bPlayerStartedJumping[client] = false;
			NCRPG_SkillActivated(ThisSkillID,client);
		}
	}
	
	s_iLastButtons[client] = buttons;
	return Plugin_Continue;
}

public void NCRPG_OnPlayerSpawn(int client) {
	if(NCRPG_IsValidSkill(ThisSkillID))  return;
	ResetJumpingState(client);
}

public void Event_OnPlayerFootstep(Event event, const char[] error, bool dontBroadcast)
{
	if(NCRPG_IsValidSkill(ThisSkillID))  return;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidPlayer(client)) return;
	if (g_bPlayerJumped[client]) g_iFootstepCount[client]++;
	if (g_iFootstepCount[client] < 2) return;
	if(g_fJumpStartTime[client] > 0.0 && (GetEngineTime() - g_fJumpStartTime[client]) > 0.003)
		ResetJumpingState(client);
}

public void OnClientDisconnect(int client) { ResetJumpingState(client); }

void HasJumped(int client, float vVelocity[3])
{
	int level = NCRPG_GetSkillLevel(client, ThisSkillID);
	if(level>0)
	{
		float fMultiplicator;
		if(!g_bPlayerJumped[client]) fMultiplicator = cfg_fStart;
		else fMultiplicator = cfg_fForce;
		g_bPlayerJumped[client] = true;
		g_iFootstepCount[client] = 0;
		fMultiplicator = fMultiplicator * level + 1.0;
		vVelocity[0] *= fMultiplicator;
		vVelocity[1] *= fMultiplicator;
		
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVelocity);
	}
}
public void Event_OnResetJump(Event event, const char[] error, bool dontBroadcast)
{
	if(NCRPG_IsValidSkill(ThisSkillID))  return;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidPlayer(client)) return;
	ResetJumpingState(client);
}
void ResetJumpingState(int client)
{
	g_fJumpStartTime[client] = -1.0;
	g_bPlayerStartedJumping[client] = false;
	g_bPlayerJumped[client] = false;
	g_iFootstepCount[client] = 0;
}