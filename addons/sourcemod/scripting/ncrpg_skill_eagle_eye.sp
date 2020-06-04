#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define VERSION		"1.5"
#define ThisSkillShortName "eye"
#define MAX_WEAPON_LENGTH	32
int ThisSkillID;
float cfg_fChance; float cfg_fRange;
bool cfg_bLevelChange; bool cfg_bRestrict;
int cfg_iMinFov; int cfg_iMaxFov;
float cfg_fTimer= 1.0;
//Effects
int HaloSpriteEye; int BeamSpriteEye; int GlowSpriteEye;int GlowSpriteEye2; 
Handle hArrayPermittedWpn;
Handle PlayerSense[MAXPLAYERS+1]; 

public Plugin myinfo = {
	name		= "NCRPG Eagle Eye",
	author		= "SenatoR",
	description	= "Skill Eagle Eye for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills(); }

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 30, 10,5,true); }

public void OnMapStart() {
	if(hArrayPermittedWpn == INVALID_HANDLE) hArrayPermittedWpn = CreateArray(ByteCountToCells(MAX_WEAPON_LENGTH));
	ClearArray(hArrayPermittedWpn);
	
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fTimer = RPG_Configs.GetFloat(ThisSkillShortName,"timer",0.1);
	cfg_fChance = RPG_Configs.GetFloat(ThisSkillShortName,"chance",3.2);
	cfg_fRange = RPG_Configs.GetFloat(ThisSkillShortName,"range",116.6);
	cfg_iMinFov = RPG_Configs.GetInt(ThisSkillShortName,"min_fov",45);
	cfg_iMaxFov = RPG_Configs.GetInt(ThisSkillShortName,"max_fov",90);
	cfg_bLevelChange = RPG_Configs.GetInt(ThisSkillShortName,"level_change",1)?true:false;
	cfg_bRestrict = RPG_Configs.GetInt(ThisSkillShortName,"restrict",1)?true:false;
	if(cfg_bRestrict)
	{
		char source[512];char tmp[64][MAX_WEAPON_LENGTH];
		RPG_Configs.GetString(ThisSkillShortName,"weapons", source, sizeof source, "weapon_ssg08,weapon_awp");
		int count = ExplodeString(source, ",", tmp, 64, sizeof tmp); for(int i = 0; i < count; ++i) PushArrayString(hArrayPermittedWpn, tmp[i]);
	}
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
	
	//Effects
	GlowSpriteEye=PrecacheGlowSprite();
	GlowSpriteEye2=PrecacheGlowSpriteBlue();
	BeamSpriteEye=PrecacheBeamSprite();
	HaloSpriteEye=PrecacheHaloSprite();
}

public Action NCRPG_OnSkillLevelChange(int client, &skillid,int old_value, &new_value) {
	if(skillid != ThisSkillID || !NCRPG_IsValidSkill(ThisSkillID)|| !cfg_bLevelChange)
		return;

	if(PlayerSense[client] == INVALID_HANDLE)
		PlayerSense[client] = CreateTimer(cfg_fTimer, Timer_Sense, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void NCRPG_OnPlayerSpawn(int client) {
	if(!NCRPG_IsValidSkill(ThisSkillID)) return;
	
	if(PlayerSense[client] != INVALID_HANDLE)
	{
		KillTimer(PlayerSense[client]);
		PlayerSense[client] = INVALID_HANDLE;
	}
	
	if(NCRPG_GetSkillLevel(client, ThisSkillID) > 0) 
	{
		PlayerSense[client] = CreateTimer(cfg_fTimer, Timer_Sense, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE); 
	}
}

public Action Timer_Sense(Handle timer, int client) {
	if(IsValidPlayer(client, true))
	{
		int level = NCRPG_GetSkillLevel(client, ThisSkillID);
		if(level > 0)
		{
			if(Client_GetFOV( client ) != 0 && Client_GetFOV( client ) != cfg_iMinFov && Client_GetFOV( client ) != cfg_iMaxFov)
			{
				
				Sense(client);
			}
		}
	}
	PlayerSense[client] = INVALID_HANDLE;
}

void Sense(int client)
{
	char buffer[PLATFORM_MAX_PATH*2];
	GetClientWeapon(client, buffer, sizeof buffer);
	bool wpn = IsPermittedWeapon(buffer);
	if(cfg_bRestrict && !wpn) return;
	int level = NCRPG_GetSkillLevel(client, ThisSkillID);
	
	if(GetRandomFloat(0.0,100.0) <= level*cfg_fChance)
	{
		
		int ElfTeam = GetClientTeam( client );
		float ElfPos[3];
		float VictimPos[3];
		
		GetClientAbsOrigin( client, ElfPos );
		
		ElfPos[2] += 50.0;
		
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsValidPlayer( i, true ) && GetClientTeam( i ) != ElfTeam)
			{
				GetClientAbsOrigin( i, VictimPos );
				VictimPos[2] += 50.0;
				
				if(GetVectorDistance( ElfPos, VictimPos ) <= cfg_fRange*level)
				{
					if(NCRPG_SkillActivate(ThisSkillID,client,i)>= Plugin_Handled) return;
					int VictimTeam = GetClientTeam( i );
					if(VictimTeam == 2) // TT
					{
						TE_SetupGlowSprite(VictimPos,GlowSpriteEye,cfg_fTimer,0.1,80);
						TE_SendToClient(client);
						TE_SetupBeamPoints(ElfPos, VictimPos, BeamSpriteEye, HaloSpriteEye, 0, 8, cfg_fTimer, 1.0, 10.0, 10, 10.0, {255,0,0,155}, 70); // czerwony
						TE_SendToClient(client);
					}
					else // CT
					{
						
						TE_SetupGlowSprite(VictimPos,GlowSpriteEye2,cfg_fTimer,0.1,150);
						TE_SendToClient(client);
						TE_SetupBeamPoints(ElfPos, VictimPos, BeamSpriteEye, HaloSpriteEye, 0, 8, cfg_fTimer, 1.0, 10.0, 10, 10.0, {30,144,255,155}, 70); // niebieski
						TE_SendToClient(client);
					}
				}
			}
		}
		NCRPG_SkillActivated(ThisSkillID,client);
	}
}

bool IsPermittedWeapon(char[] weapon) {
	char buffer[MAX_WEAPON_LENGTH];
	for(int i = GetArraySize(hArrayPermittedWpn)-1; i >= 0; --i)
	{
		GetArrayString(hArrayPermittedWpn, i, buffer, sizeof buffer);
		if(StrEqual(weapon, buffer, false))
			return true;
	}
	
	return false;
}

stock int Client_GetFOV(int client){ return GetEntProp(client, Prop_Send, "m_iFOV");}