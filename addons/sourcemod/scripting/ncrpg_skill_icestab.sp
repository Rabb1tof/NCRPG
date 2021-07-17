#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define VERSION				"1.7"
#define ThisSkillShortName "icestab"
#define MAX_WEAPON_LENGTH	32

int ThisSkillID;

float cfg_fPercent;float cfg_fTime;float cfg_fSlow;
bool cfg_bSound; bool cfg_bFreeze; bool cfg_bSumm; bool cfg_bFrozenRest; bool cfg_bStatTime;bool cfg_bEffects;
Handle hArrayAttackerTimers[MAXPLAYERS+1];
Handle hArrayPermittedWpn;

enum Freezing {
	Handle:TimerHandle = 0,
	Handle:UnslowTimer,
	attackerIndex,
	FreezLevel
};

public Plugin myinfo = {
	name		= "NCRPG Skill Ice Stab",
	author		= "SenatoR",
	description	= "Skill Ice Stab for NCRPG",
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

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 3, 20,10,true); }

public void OnMapStart() {
	ClearArray(hArrayPermittedWpn);
	
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fPercent = RPG_Configs.GetFloat(ThisSkillShortName,"percent",0.6);
	cfg_bStatTime = RPG_Configs.GetInt(ThisSkillShortName,"stattime",0)?true:false;
	cfg_fTime	 = RPG_Configs.GetFloat(ThisSkillShortName,"time",0.3);
	cfg_bFreeze = RPG_Configs.GetInt(ThisSkillShortName,"freeze",1)?true:false;
	cfg_fSlow = RPG_Configs.GetFloat(ThisSkillShortName,"slow",0.06);
	cfg_bSumm = RPG_Configs.GetInt(ThisSkillShortName,"sum",1)?true:false;
	cfg_bFrozenRest = RPG_Configs.GetInt(ThisSkillShortName,"frrest",1)?true:false;
	cfg_bSound = RPG_Configs.GetInt(ThisSkillShortName,"sound",1)?true:false;
	cfg_bEffects = RPG_Configs.GetInt(ThisSkillShortName,"effects",0)?true:false;
	char source[512];char tmp[64][MAX_WEAPON_LENGTH];
	RPG_Configs.GetString(ThisSkillShortName,"weapons",source, sizeof source, "weapon_knife");
	int count = ExplodeString(source, ",", tmp, 64, sizeof tmp);
	for(int i = 0; i < count; ++i) PushArrayString(hArrayPermittedWpn, tmp[i]);
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
	
	if(cfg_bSound)
	{
		FakePrecacheSound("physics/glass/glass_impact_bullet1.wav");
		FakePrecacheSound("physics/glass/glass_impact_bullet2.wav");
		FakePrecacheSound("physics/glass/glass_impact_bullet3.wav");
		FakePrecacheSound("physics/glass/glass_impact_bullet4.wav");
	}
	if(cfg_bEffects)
	{
		AddFileToDownloadsTable("materials/models/hypy/hype.vmt");
		AddFileToDownloadsTable("materials/models/spree/spree.vtf");
		AddFileToDownloadsTable("models/spree/spree.mdl");
		AddFileToDownloadsTable("models/spree/spree.phy");
		AddFileToDownloadsTable("models/spree/spree.vvd");
		AddFileToDownloadsTable("models/spree/spree.dx80.vtx");
		AddFileToDownloadsTable("models/spree/spree.dx90.vtx");
		AddFileToDownloadsTable("models/spree/spree.sw.vtx");
		PrecacheModel("models/spree/spree.mdl");
	}
}

public void OnClientConnected(int client){ hArrayAttackerTimers[client] = CreateArray(view_as<int>(Freezing)); }

public void OnClientDisconnect(int client) { KillAttackerTimers(client,true); }

public void NCRPG_OnPlayerSpawn(int client) { KillAttackerTimers(client,false); }

public void OnClientPutInServer(client) { SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); }

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	if(!NCRPG_IsValidSkill(ThisSkillID)) return Plugin_Continue;
	if(IsValidPlayer(victim) && IsValidPlayer(attacker) && victim != attacker)
	{
		if(GetClientTeam(victim) == GetClientTeam(attacker)) return Plugin_Continue;

		char buffer[PLATFORM_MAX_PATH*2];
		if(inflictor > MaxClients)	// projectile
			GetEdictClassname(inflictor, buffer, sizeof buffer);
		else
			GetClientWeapon(attacker, buffer, sizeof buffer);
		bool wpn = IsPermittedWeapon(buffer);
		
		int level = NCRPG_GetSkillLevel(attacker, ThisSkillID);
		if(IsPlayerFrozenInternal(victim))
		{
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
				
				if(!cfg_bFreeze && array[UnslowTimer] != null)
					TriggerTimer(array[UnslowTimer]);
					
				if (array[TimerHandle] != null)
					TriggerTimer(array[TimerHandle]);
			}
		}
		
		if(cfg_bFrozenRest && IsPlayerFrozenInternal(attacker))
			return Plugin_Changed;
		
		if(inflictor == attacker)
		{
			if(IsAcitveWeaponKnife(attacker))
				if(level > 0)
				{
					if(NCRPG_SkillActivate(ThisSkillID,attacker,victim)>= Plugin_Handled) return Plugin_Changed;
					float time = cfg_bStatTime?cfg_fTime:cfg_fTime*level;
					
					int array[Freezing];
					if(cfg_bFreeze)
					{
						NCRPG_FreezePlayer(victim, time);
						if(cfg_bEffects)CreateIce(victim,time);
					}
					else
					{
						array[UnslowTimer] = NCRPG_SlowPlayer(victim, cfg_fSlow*level, time);
					}
					
					array[TimerHandle] = CreateTimer(time, Timer_DeleteAttackerFromArray, victim);
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
		hArrayAttackerTimers[client] = null;
	}
}

bool IsPlayerFrozenInternal(int client) { return GetArraySize(hArrayAttackerTimers[client])?true:false; }

bool IsAcitveWeaponKnife(int client) {
	int entity = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if(entity > MaxClients)
		if(entity == GetPlayerWeaponSlot(client, 2))
			return true;
			
	return false;
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

void CreateIce(int client,float time)
{
	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.WriteFloat(time);
	CreateTimer(0.0,TimerFuncIce,pack,TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
	
	
}

public Action TimerFuncIce(Handle timer, DataPack pack) {
	pack.Reset(false);
	int client = pack.ReadCell();
	if(IsValidPlayer(client,true) && IsPlayerFrozenInternal(client))
	{
		float time = pack.ReadFloat();
		float origin[3];
		GetClientAbsOrigin(client, origin);
		int ent = SpawnPropPhysicsOverrideByOrigin("models/spree/spree.mdl", origin);
	
		char output[64];
		FormatEx(output, sizeof(output), "OnUser1 !self:kill::%f:1", time);
		SetVariantString(output);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}
}

int SpawnPropPhysicsOverrideByOrigin(const char[] sModel, const float vOrigin[3], const float vAngles[3]={0.0, 0.0, 0.0})
{
	int iEntity = CreateEntityByName("prop_dynamic_override");
	if ( IsValidEdict(iEntity) ) {
		DispatchKeyValueVector(iEntity, "origin", vOrigin);
		DispatchKeyValueVector(iEntity, "angles", vAngles);
		DispatchKeyValue(iEntity, "model", sModel);
		
		if ( DispatchSpawn(iEntity) ) {
			return iEntity;
		}
		else {
			LogError("Can't dispatch prop_physics_override");
		}
	}
	else {
		LogError("Can't create prop_physics_override");
	}
	
	return -1;
}