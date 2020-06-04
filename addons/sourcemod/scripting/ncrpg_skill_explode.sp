#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define ThisSkillShortName "explode"
#define VERSION				"1.3"

int ThisSkillID;

float cfg_fChance;bool cfg_bEffects;int cfg_iAmount;float cfg_fRange;

public Plugin myinfo = {
	name		= "NCRPG Skill "...ThisSkillShortName,
	author		= "SenatoR",
	description	= "Skill "...ThisSkillShortName..." for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() {
	if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills();
	HookEvent("player_death",	OnPlayerDeath);
}

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 10, 5,3,true); }

public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_iAmount = RPG_Configs.GetInt(ThisSkillShortName,"damage",1);
	cfg_fChance = RPG_Configs.GetFloat(ThisSkillShortName,"chance",0.05);
	cfg_fRange = RPG_Configs.GetFloat(ThisSkillShortName,"range",5.0);
	cfg_bEffects = RPG_Configs.GetInt(ThisSkillShortName,"effects",0)?true:false;
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
	if(cfg_bEffects)
	{
		PrecacheParticle("gas_cannister_impact_child_sparks2");
		PrecacheParticle("gas_cannister_impact_child_flash");
		PrecacheParticle("gas_cannister_impact_child_explosion");
	}
}


public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	if(NCRPG_IsValidSkill(ThisSkillID))  return Plugin_Continue;
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(IsValidPlayer(victim) && IsValidPlayer(attacker))
	{
		int level = NCRPG_GetSkillLevel(victim, ThisSkillID);
		if(level > 0)
		{
			if(GetRandomFloat(0.0, 1.0) <= cfg_fChance*level)
			{
				float pos_a[3];float pos_v[3];
				GetClientAbsOrigin(victim,pos_a);
				float range = cfg_fRange*level;
				if(cfg_bEffects){
					ThrowAwayParticle("gas_cannister_impact_child_flash", pos_a, 0.6);
					ThrowAwayParticle("gas_cannister_impact_child_sparks2", pos_a, 1.0);
					ThrowAwayParticle("gas_cannister_impact_child_explosion", pos_a, 1.0);
				}
				
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsValidPlayer( i, true )&& (GetClientTeam(i)!=GetClientTeam(victim)))
					{
						if(NCRPG_SkillActivate(ThisSkillID,victim,attacker)>= Plugin_Handled) return Plugin_Handled;
						GetClientAbsOrigin(i,pos_v);
						float distance=GetVectorDistance(pos_a,pos_v);
						if(distance>range) return Plugin_Continue;
						float factor=(range-distance)/range;
						int dmg = RoundToNearest((cfg_iAmount*level)*factor);
						NCRPG_DealDamage(i, dmg, victim,_,"prop_exploding_barrel");
					}
				}
				NCRPG_SkillActivated(ThisSkillID,victim);
			}
		}
	}
	return Plugin_Continue;
}