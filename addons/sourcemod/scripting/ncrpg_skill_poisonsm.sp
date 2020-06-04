#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define VERSION		"1.4"
#define ThisSkillShortName "poisonsm"
int ThisSkillID;

enum Poison {
	Handle:timerHandle = 0,
	Handle:Killer,
	ownerIndex,
	Float:Position[3]
};

Handle hArrayTimers;
int cfg_iDamage;float cfg_fInterval; bool cfg_bDeath;
float cfg_fSmokeTime;float cfg_fSmokeRange;bool cfg_bEffect;
char Smoke_Effect[][] ={"ncrpg_explosion_child_01c_green","ncrpg_explosion_child_smoke03d_ring_base_green","ncrpg_explosion_base3_green","ncrpg_explosion_base7_green","ncrpg_explosion_base_bottom_green","ncrpg_smokegrenade_base_green"};

public Plugin myinfo = {
	name		= "NCRPG Skill Poison Smoke",
	author		= "SenatoR",
	description	= "Skill Poison Smoke for NCRPG",
	version		= VERSION
};

public void OnPluginStart() {
	hArrayTimers = CreateArray(view_as<int>(Poison));
	if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills();
	HookEvent("round_start", Event_RoundStart);
	HookEvent("smokegrenade_detonate", Event_SmokegrenadeDetonated,EventHookMode_Pre);
}

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 5, 10,5,true); }

public void OnMapStart() {
	if(hArrayTimers != INVALID_HANDLE) ClearArray(hArrayTimers);
		
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_iDamage = RPG_Configs.GetInt(ThisSkillShortName,"damage",5);
	cfg_fInterval = RPG_Configs.GetFloat(ThisSkillShortName,"interval",0.02);
	cfg_bDeath = RPG_Configs.GetInt(ThisSkillShortName,"death",1)?true:false;
	cfg_fSmokeTime = RPG_Configs.GetFloat(ThisSkillShortName,"smoke_time",20.0);
	cfg_fSmokeRange = RPG_Configs.GetFloat(ThisSkillShortName,"smoke_range",225.0);
	cfg_bEffect = RPG_Configs.GetInt(ThisSkillShortName,"smoke_effect",0)?true:false;
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
	if(cfg_bEffect)
	{
		AddFileToDownloadsTable("particles/ncrpg_smoke.pcf");
		PrecacheParticle("particles/ncrpg_smoke.pcf");
		for(int i = 0; i<6;i++) PrecacheParticleEffect(Smoke_Effect[i]);
	}
}

public Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	int array[Poison];
	for(int i = GetArraySize(hArrayTimers)-1; i >= 0; --i)
	{
		GetArrayArray(hArrayTimers, i, array[0]);
		KillTimer(array[timerHandle]);
		KillTimer(array[Killer]);
	}
	
	ClearArray(hArrayTimers);
}

public Event_SmokegrenadeDetonated(Event event, const char[] name, bool dontBroadcast) {
	if(NCRPG_IsValidSkill(ThisSkillID))  return;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidPlayer(client))
	{
		int level = NCRPG_GetSkillLevel(client, ThisSkillID);
		if(level > 0)
		{			
			int array[Poison]; float pos[3];
			pos[0] = event.GetFloat("x");
			pos[1] = event.GetFloat("y");
			pos[2] = event.GetFloat("z");
			if(cfg_bEffect)
			{
				int entity = event.GetInt("entityid");
				AcceptEntityInput(entity, "kill"); 
				ThrowAwayParticle(Smoke_Effect[5],pos,cfg_fSmokeTime);
			}
			array[timerHandle] 	= CreateTimer(cfg_fInterval, Timer_PoisonInterval, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			array[Killer] 		= CreateTimer(cfg_fSmokeTime, Timer_KillWork, _, TIMER_FLAG_NO_MAPCHANGE);
			array[ownerIndex]	= client;
			array[Position]		= pos;
			PushArrayArray(hArrayTimers, array[0]);
		}
	}
}

public Action Timer_PoisonInterval(Handle timer) {
	int array[Poison]; int i;
	for(i = GetArraySize(hArrayTimers)-1; i >= 0; --i)
	{
		GetArrayArray(hArrayTimers, i, array[0]);
		if(array[timerHandle] == timer)	// не может содержать неправильный таймер
			break;
	}
	
	if(!IsValidPlayer(array[ownerIndex]))
	{
		KillTimer(array[Killer]);
		RemoveFromArray(hArrayTimers, i);
		return Plugin_Stop;
	}
	
	int level = NCRPG_GetSkillLevel(array[ownerIndex], ThisSkillID);
	if(level <= 0)
	{
		KillTimer(array[Killer]);
		RemoveFromArray(hArrayTimers, i);
		return Plugin_Stop;
	}
	
	level *= cfg_iDamage;
	
	float pos[3];float smokepos[3];
	smokepos[0] = array[Position][0];
	smokepos[1] = array[Position][1];
	smokepos[2] = array[Position][2];
	for(int client = 1; client <= MaxClients; ++client)
		if(IsValidPlayer(client, true))
		{
			if(GetClientTeam(client) == GetClientTeam(array[ownerIndex]))
				continue;
				
			GetClientAbsOrigin(client, pos);
			if(GetVectorDistance(pos, smokepos, false) < cfg_fSmokeRange)
			{
				int amount = level;
				if(amount >= GetClientHealth(client))
				{
					if(cfg_bDeath) amount = GetClientHealth(client)+1;
					else amount = GetClientHealth(client)-1;
				}
				if(amount)
				{
					if(NCRPG_SkillActivate(ThisSkillID, array[ownerIndex],client)>= Plugin_Handled)return Plugin_Handled;
					NCRPG_DealDamage(client, amount, array[ownerIndex], DMG_POISON, "weapon_smokegrenade");
					NCRPG_SkillActivated(ThisSkillID, array[ownerIndex]);
				}
			}
		}
	
	return Plugin_Continue;
}

public Action Timer_KillWork(Handle timer) {
	int array[Poison];int i;
	for(i = GetArraySize(hArrayTimers)-1; i >= 0; --i)
	{
		GetArrayArray(hArrayTimers, i, array[0]);
		if(array[Killer] == timer) break;
	}
	
	KillTimer(array[timerHandle]);
	RemoveFromArray(hArrayTimers, i);
}
