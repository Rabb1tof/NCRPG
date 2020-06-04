#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define VERSION		"1.2"
#define ThisSkillShortName "incidence"
int ThisSkillID;
float cfg_fChance;
float cfg_fRange;
float cfg_fDamage;
bool cfg_bEffects;
//Effects
int FallSprite;

public Plugin myinfo = {
	name		= "NCRPG Skill "...ThisSkillShortName,
	author		= "SenatoR",
	description	= "Skill "...ThisSkillShortName..." for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills(); }

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 30, 10,5,true); }

public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fChance = RPG_Configs.GetFloat(ThisSkillShortName,"chance",0.3);
	cfg_fRange = RPG_Configs.GetFloat(ThisSkillShortName,"range",130.0);
	cfg_fRange = RPG_Configs.GetFloat(ThisSkillShortName,"damage",0.018);
	cfg_bEffects = RPG_Configs.GetInt(ThisSkillShortName,"effects",0)?true:false;
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
	if(cfg_bEffects){
		FallSprite = PrecacheDecal("materials/decals/another-source.ru/incidence_smash");
		AddFileToDownloadsTable("materials/decals/another-source.ru/incidence_smash.vtf");
		AddFileToDownloadsTable("materials/decals/another-source.ru/incidence_smash.vmt");
	}
}

public void OnClientPutInServer(int client) { SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); }

public Action OnTakeDamage(int victim,int &attacker,int &inflictor,float &damage,int &damagetype) 
{
	if(NCRPG_IsValidSkill(ThisSkillID))  return Plugin_Continue;
	int level = NCRPG_GetSkillLevel(victim, ThisSkillID);
	if(IsValidPlayer(victim,true) && level> 0 && victim &&damagetype & DMG_FALL && GetRandomFloat(0.0, 1.0) <= cfg_fChance*level)
	{
		float pos_a[3];float pos_v[3];
		GetClientAbsOrigin(victim,pos_a);
		if(cfg_bEffects) IncidenEffect(pos_a);
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsValidPlayer( i, true )&& (GetClientTeam(i)!=GetClientTeam(victim)))
			{
				if(NCRPG_SkillActivate(ThisSkillID,victim,i)>= Plugin_Handled)return Plugin_Handled;
				GetClientAbsOrigin(i,pos_v);
				float distance=GetVectorDistance(pos_a,pos_v);
				if(distance>cfg_fRange)
                    continue;
				float factor=(cfg_fRange-distance)/cfg_fRange;
				int dmg = RoundToNearest(damage*(cfg_fDamage*level)*factor);
				NCRPG_DealDamage(i, dmg, victim);
				NCRPG_SkillActivated(ThisSkillID,victim);
			}
		}
	}
	return Plugin_Continue; 
}

stock void IncidenEffect(float Origin[3]) { TE_SetupWorldDecal(Origin,FallSprite); TE_SendToAll(); }

stock void TE_SetupWorldDecal(const float vecOrigin[3],int index) { TE_Start("World Decal"); TE_WriteVector("m_vecOrigin",vecOrigin); TE_WriteNum("m_nIndex",index); }

