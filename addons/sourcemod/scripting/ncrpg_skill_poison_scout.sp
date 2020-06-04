#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define ThisSkillShortName "pscout"
#define VERSION		"1.2"
#define MAX_WEAPON_LENGTH	32

int ThisSkillID;
float cfg_fTimer; float cfg_fChance;
int cfg_iDamage; int cfg_iAttack; bool cfg_bDeath; bool cfg_bEffects;
Handle hArrayPermittedWpn;
char Posion_Effect[][] ={"Poison","poison_loop","poison_loop_black","poison_screen","poison_spore","poison_spores_child"};

public Plugin myinfo = {
	name		= "NCRPG Poison scout",
	author		= "SenatoR",
	description	= "Skill poison scout for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() {if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills();}
public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }
public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 16, 10,5,true); }


public void OnMapStart() {

	if(hArrayPermittedWpn == INVALID_HANDLE) hArrayPermittedWpn = CreateArray(ByteCountToCells(MAX_WEAPON_LENGTH));
	ClearArray(hArrayPermittedWpn);
		
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fTimer = RPG_Configs.GetFloat(ThisSkillShortName,"timer",3.0);
	cfg_fChance = RPG_Configs.GetFloat(ThisSkillShortName,"chance",3.2);
	cfg_iDamage = RPG_Configs.GetInt(ThisSkillShortName,"damage",10);
	cfg_bDeath = RPG_Configs.GetInt(ThisSkillShortName,"death",1)?true:false;
	cfg_bEffects = RPG_Configs.GetInt(ThisSkillShortName,"effects",1)?true:false;
	cfg_iAttack = RPG_Configs.GetInt(ThisSkillShortName,"poison_attack",3);
	char source[512];char tmp[64][MAX_WEAPON_LENGTH];
	RPG_Configs.GetString(ThisSkillShortName,"weapons", source, sizeof source, "weapon_ssg08,weapon_scout");
	int count = ExplodeString(source, ",", tmp, 64, sizeof tmp); for(int i = 0; i < count; ++i) PushArrayString(hArrayPermittedWpn, tmp[i]);
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
	if(cfg_bEffects)
	{
		AddFileToDownloadsTable("particles/ncrpg_poison.pcf");
		PrecacheParticle("particles/ncrpg_poison.pcf");
		for(int i = 0; i<6;i++) PrecacheParticleEffect(Posion_Effect[i]);
	}
}

public void OnClientPutInServer(client) { SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); }

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if(IsValidPlayer(victim) && IsValidPlayer(attacker) && victim != attacker && GetClientTeam(attacker) != GetClientTeam(victim))
	{
		//PrintToConsoleAll("%d", damagetype);
		if(damagetype & DMG_BULLET > 0)
		{
			char buffer[PLATFORM_MAX_PATH*2];
			GetClientWeapon(attacker, buffer, sizeof buffer);
			//PrintToChatAll(buffer);
			bool wpn = IsPermittedWeapon(buffer);
			if(!wpn) return Plugin_Continue;
			int level = NCRPG_GetSkillLevel(attacker, ThisSkillID);
			if(level>0 && GetRandomFloat(0.0,100.0) < level*cfg_fChance)
			{
				PoisonAttack(attacker,victim,cfg_iAttack);
			}
		}
	}
	return Plugin_Continue;
}



/*-----------------------------------------------*/
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

void PoisonAttack(int attacker, int victim,int count)
{
	if(IsValidPlayer(attacker) && IsValidPlayer(victim,true))
	{
		DataPack datapack = new DataPack();
		datapack.WriteCell(attacker);
		datapack.WriteCell(victim);
		datapack.WriteCell(count);
		datapack.Reset();
		CreateTimer(cfg_fTimer, Timer_PoisonDamage, datapack,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_PoisonDamage(Handle timer, DataPack datapack) {
	int attacker= datapack.ReadCell();	
	int victim = datapack.ReadCell();	
	int count = datapack.ReadCell()-1;
	CloseHandle(datapack);
	if(IsValidPlayer(attacker) && IsValidPlayer(victim,true))
	{
		int dmg = cfg_iDamage;
		int health = GetClientHealth(victim);
		if(health<=dmg && !cfg_bDeath) dmg=health-1;
		DealPoisonDamage(victim,attacker,dmg);
		if(count>0)
		{
			if(cfg_bEffects &&  IsValidPlayer(victim,true))
			{
				float pos[3];
				GetClientAbsOrigin(victim,pos);
				AttachThrowAwayParticle(victim,Posion_Effect[0], pos,"",cfg_fTimer);
			}
			DataPack datapack1 = new DataPack();
			datapack1.WriteCell(attacker);
			datapack1.WriteCell(victim);
			datapack1.WriteCell(count);
			datapack1.Reset();
			CreateTimer(cfg_fTimer, Timer_PoisonDamage, datapack1,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

void DealPoisonDamage(int victim,int attacker,int damage) { NCRPG_DealDamage(victim, damage, attacker, DMG_POISON, "poison_scout"); }
