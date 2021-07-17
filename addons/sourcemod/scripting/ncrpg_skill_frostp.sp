#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define ThisSkillShortName "frostp"
#define VERSION				"1.3"
#define MAX_WEAPON_LENGTH	32

int ThisSkillID;

float cfg_fPercent;float cfg_fTime;float cfg_fSlow;
bool cfg_bRestrict; bool cfg_bSound; bool cfg_bFreeze; bool cfg_bSumm; bool cfg_bFrozenRest; bool cfg_bStatTime;
Handle hArrayAttackerTimers[MAXPLAYERS+1];
Handle hArrayPermittedWpn;


enum Freezing {
	Handle:TimerHandle = 0,
	Handle:UnslowTimer,
	attackerIndex,
	FreezLevel
};

public Plugin myinfo = {
	name		= "NCRPG Skill Frost Pistol",
	author		= "SenatoR",
	description	= "Skill Frost Pistol for NCRPG",
	version		= VERSION
};

public void OnPluginStart() {
	if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1)
	{
		for(int i = 1; i <= MaxClients; ++i)
			if(IsValidPlayer(i))
			{
				OnClientConnected(i);
				OnClientPutInServer(i);
			}
		
		NCRPG_OnRegisterSkills();
	}
	hArrayPermittedWpn = CreateArray(ByteCountToCells(MAX_WEAPON_LENGTH));
}

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 10, 10,5,true); }

public void OnMapStart() {
	ClearArray(hArrayPermittedWpn);

	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fPercent = RPG_Configs.GetFloat(ThisSkillShortName,"percent",0.6);
	cfg_bStatTime = RPG_Configs.GetInt(ThisSkillShortName,"stattime",0)?true:false;
	cfg_fTime	 = RPG_Configs.GetFloat(ThisSkillShortName,"time",0.3);
	cfg_bFreeze = RPG_Configs.GetInt(ThisSkillShortName,"freeze",1)?true:false;
	cfg_fSlow = RPG_Configs.GetFloat(ThisSkillShortName,"slow",0.06);
	cfg_bSumm = RPG_Configs.GetInt(ThisSkillShortName,"sum",1)?true:false;
	cfg_bRestrict = RPG_Configs.GetInt(ThisSkillShortName,"restrict",1)?true:false;
	cfg_bFrozenRest = RPG_Configs.GetInt(ThisSkillShortName,"frrest",0)?true:false;
	cfg_bSound = RPG_Configs.GetInt(ThisSkillShortName,"sound",1)?true:false;
	if(cfg_bRestrict)
	{
		char source[512];char tmp[64][MAX_WEAPON_LENGTH];
		RPG_Configs.GetString(ThisSkillShortName,"weapons",source, sizeof source, "weapon_glock,weapon_usp,weapon_p228,weapon_deagle,weapon_fiveseven,weapon_elite,weapon_tec9,weapon_cz75a,weapon_p250,usp_silencer");
		int count = ExplodeString(source, ",", tmp, 64, sizeof tmp);
		for(int i = 0; i < count; ++i)
			PushArrayString(hArrayPermittedWpn, tmp[i]);
	}		
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
	if(cfg_bSound)
	{
		FakePrecacheSound("physics/glass/glass_impact_bullet1.wav");
		FakePrecacheSound("physics/glass/glass_impact_bullet2.wav");
		FakePrecacheSound("physics/glass/glass_impact_bullet3.wav");
		FakePrecacheSound("physics/glass/glass_impact_bullet4.wav");
	}
}

public void OnClientConnected(int client) { hArrayAttackerTimers[client] = CreateArray(view_as<int>(Freezing)); }

public void OnClientDisconnect(int client) { KillAttackerTimers(client,true); }

public void NCRPG_OnPlayerSpawn(int client) { KillAttackerTimers(client,false); }

public void OnClientPutInServer(int client) { SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); }

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	//PrintToChatAll("-1");	
	if(!NCRPG_IsValidSkill(ThisSkillID)) 
	{
		//PrintToChatAll("-0");	
		return Plugin_Continue;
	}
	if(IsValidPlayer(victim) && IsValidPlayer(attacker) && victim != attacker)
	{
		//PrintToChatAll("0");	
		if(GetClientTeam(victim) == GetClientTeam(attacker))
			return Plugin_Continue;
		
		char buffer[PLATFORM_MAX_PATH*2];
		if(inflictor > MaxClients)	// projectile
			GetEdictClassname(inflictor, buffer, sizeof buffer);
		else
			GetClientWeapon(attacker, buffer, sizeof buffer);
		bool wpn = IsPermittedWeapon(buffer);
		
		if(cfg_bRestrict && IsAttackerInArray(victim, attacker))
		{		
			//PrintToChatAll("1");		
			if(!wpn)
			{
				//if(IsPlayerAlive(attacker)) // other plugins
				//	ForcePlayerSuicide(attacker);
				
				return Plugin_Handled;
			}
		}
		
		int level = NCRPG_GetSkillLevel(attacker, ThisSkillID);
		if(IsPlayerFrozenInternal(victim))
		{
			//PrintToChatAll("2");
			if(!wpn)
				damage *= cfg_fPercent;
			
			if(!cfg_bSumm)
			{				
				int array[Freezing];
				for(int i = GetArraySize(hArrayAttackerTimers[victim])-1; i >= 0; --i)
				{
					GetArrayArray(hArrayAttackerTimers[victim], i, array[0]);
					if(array[FreezLevel] > level)
						return Plugin_Changed;
				}
				
				if(!cfg_bFreeze && array[UnslowTimer] != INVALID_HANDLE)
					TriggerTimer(array[UnslowTimer]);
					
				if (array[TimerHandle] != INVALID_HANDLE)
					TriggerTimer(array[TimerHandle]);
			}
		}
		
		if(cfg_bFrozenRest && IsPlayerFrozenInternal(attacker))
		{
			//PrintToChatAll("3");
			return Plugin_Changed;
		}
		
		if(inflictor == attacker)
		{
			//PrintToChatAll("4");
			if(IsAcitveWeaponPistol(attacker))
			{
				if(level > 0)
				{
					if(NCRPG_SkillActivate(ThisSkillID,attacker,victim)>= Plugin_Handled)return Plugin_Continue;
					float time = cfg_bStatTime?cfg_fTime:cfg_fTime*level;
					
					int array[Freezing];
					if(cfg_bFreeze)
					{
						//PrintToChatAll("5");
						NCRPG_FreezePlayer(victim, time);
					}
					else
					{
						//PrintToChatAll("6");
						array[UnslowTimer] = NCRPG_SlowPlayer(victim, cfg_fSlow*level, time);
					}
					
					array[TimerHandle] = CreateTimer(time, Timer_DeleteAttackerFromArray, victim);	// TIMER_FLAG_NO_MAPCHANGE don't need, disconnect do it
					array[attackerIndex] = attacker;
					array[FreezLevel] = level;
					
					PushArrayArray(hArrayAttackerTimers[victim], array[0]);
					
					if(cfg_bSound)
					{
						Format(buffer, sizeof(buffer), "physics/glass/glass_impact_bullet%d.wav", GetRandomInt(1, 4));
						EmitSoundToAll(buffer, victim);
					}
					NCRPG_SkillActivated(ThisSkillID,attacker);
				}
			}
		}
	}
	return Plugin_Changed;
}

public Action Timer_DeleteAttackerFromArray(Handle timer, int client)
{
	int array[Freezing];
	for(int i = GetArraySize(hArrayAttackerTimers[client])-1; i >= 0; --i)
	{
		GetArrayArray(hArrayAttackerTimers[client], i, array[0]);
		if(array[TimerHandle] == timer)
		{
			RemoveFromArray(hArrayAttackerTimers[client], i);
			break;
		}
	}
}


//THX R1KO 
void KillAttackerTimers(int client,bool del)
{
	int iSize = GetArraySize(hArrayAttackerTimers[client]);
	if(iSize)
	{
		for(int i = 0, array[Freezing]; i < iSize; ++i)
		{
			GetArrayArray(hArrayAttackerTimers[client], i, array[0]);
			KillTimer(array[TimerHandle]);
		}
	}
	ClearArray(hArrayAttackerTimers[client]);
	if(del)
	{
		CloseHandle(hArrayAttackerTimers[client]);
		hArrayAttackerTimers[client] = INVALID_HANDLE;
	}
}
bool IsAttackerInArray(int client,int attacker) {
	int array[Freezing];
	for(int i = GetArraySize(hArrayAttackerTimers[client])-1; i >= 0; --i)
	{
		GetArrayArray(hArrayAttackerTimers[client], i, array[0]);
		if(array[attackerIndex] == attacker)
			return true;
	}
	
	return false;
}

bool IsPlayerFrozenInternal(int client) {	// or slowed
	return GetArraySize(hArrayAttackerTimers[client])?true:false;
}


bool IsPermittedWeapon(const char[] weapon) {
	char buffer[MAX_WEAPON_LENGTH];
	for(int i = GetArraySize(hArrayPermittedWpn)-1; i >= 0; --i)
	{
		GetArrayString(hArrayPermittedWpn, i, buffer, sizeof buffer);
		if(StrEqual(weapon, buffer, false))
			return true;
	}
	
	return false;
}


bool IsAcitveWeaponPistol(int client) {
	int entity = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if(entity > MaxClients)
		if(entity == GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY))
			return true;
			
	return false;
}