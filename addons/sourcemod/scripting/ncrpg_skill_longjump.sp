#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define ThisSkillShortName "longjump"
#define VERSION				"1.3"

int ThisSkillID;
int m_vecVelocity_0;int m_vecVelocity_1;int m_vecVelocity_2;
int m_vecBaseVelocity;
float cfg_fForce; float cfg_fVec2;
bool cfg_bEffects;
int EffectLaserSprite;

public Plugin myinfo = {
	name		= "NCRPG Long Jump",
	author		= "SenatoR",
	description	= "Skill Long Jump for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() {

	if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills();
	HookEvent("player_jump", Event_PlayerJump);
	
	m_vecVelocity_0 = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	if(m_vecVelocity_0 == -1) SetFailState("Could not find the offset: CBasePlayer :: m_vecVelocity[0]");
		
	m_vecVelocity_1 = FindSendPropInfo("CBasePlayer", "m_vecVelocity[1]");
	if(m_vecVelocity_1 == -1) SetFailState("Could not find the offset: CBasePlayer :: m_vecVelocity[1]");
	
	m_vecVelocity_2 = FindSendPropInfo("CBasePlayer", "m_vecVelocity[2]");
	if(m_vecVelocity_2 == -1) SetFailState("Could not find the offset: CBasePlayer :: m_vecVelocity[2]");
		
	m_vecBaseVelocity = FindSendPropInfo("CBasePlayer", "m_vecBaseVelocity");
	if(m_vecBaseVelocity == -1) SetFailState("Could not find the offset: CBasePlayer :: m_vecBaseVelocity");
}

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 16, 10,5,true); }

public void OnMapStart() 
{
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fForce = RPG_Configs.GetFloat(ThisSkillShortName,"force",0.2);
	cfg_fVec2 = RPG_Configs.GetFloat(ThisSkillShortName,"vec2",50.0);
	cfg_bEffects = RPG_Configs.GetInt(ThisSkillShortName,"effects",0)?true:false;
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
	if(cfg_bEffects) EffectLaserSprite = PrecacheBeamSprite();
}

public Action Event_PlayerJump(Event event, const char[] name, bool dontBroadcast) {
	if(ThisSkillID == -1 || !NCRPG_IsValidSkill(ThisSkillID))  return Plugin_Continue;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidPlayer(client, true))
	{
		int level = NCRPG_GetSkillLevel(client, ThisSkillID);
		if(level > 0)
		{
			if(NCRPG_SkillActivate(ThisSkillID,client,client)>= Plugin_Handled)return Plugin_Continue;
			float velocity[3];
			velocity[0] = GetEntDataFloat(client, m_vecVelocity_0)*cfg_fForce*level;
			velocity[1] = GetEntDataFloat(client, m_vecVelocity_1)*cfg_fForce*level;
			velocity[2] = cfg_fVec2*cfg_fForce*level;
			SetEntDataVector(client, m_vecBaseVelocity, velocity, true);
			if(cfg_bEffects)
			{
				int color[4];
				if(GetClientTeam(client)==2) color={255,20,0,127};
				else if(GetClientTeam(client)==3) color={0,20,255,127};
				TE_SetupBeamFollow(client,EffectLaserSprite,0,0.3,1.0,1.0,1,color);
				TE_SendToAll();
			}
			NCRPG_SkillActivated(ThisSkillID,client);
		}
	}
	return Plugin_Continue;
}