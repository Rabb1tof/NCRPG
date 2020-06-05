#pragma semicolon 1
#pragma dynamic 128000
#include "NCIncs/nc_rpg.inc"
#include "NCRPG/NCRPG_Variables.inc"
#include "NCRPG/NCRPG_api.inc"
#include "NCRPG/NCRPG_Arrays.inc"
#include "NCRPG/NCRPG_Configs.inc"
#include "NCRPG/NCRPG_Databases.inc"
#include "NCRPG/NCRPG_Xp.inc"
#include "NCRPG/NCRPG_Buffs.inc"
#include "NCRPG/NCRPG_Events.inc"
#include "NCRPG/NCRPG_Logs.inc"

#define VERSION_NUM "1.3.8.4"

public Plugin myinfo =
{
	name = "NCRPG",
	author = "SenatoR",
	description="New concept RPG in source",
	version=VERSION_NUM
};

public APLRes AskPluginLoad2(Handle myself,bool late,char[] error,int err_max)
{
	RegPluginLibrary("NCRPG");
	PrintToServer("[NCRPG] -= LOADING New Concept Roly Play Game =-");
	PrintToServer("[NCRPG] ##	    # ######  ######  ######  ########");
	PrintToServer("[NCRPG] # #    # #	   #  #    #  #    #  #       ");
	PrintToServer("[NCRPG] #   #  # #       ######  #    #  #       ");
	PrintToServer("[NCRPG] #    # # #	  	  # #     ######  #	  ####");
	PrintToServer("[NCRPG] #     ## #	   #  #  #    # 	  #	     #");
	PrintToServer("[NCRPG] #      # ######  #   #	  #       ########");
	PrintToServer("[NCRPG] -= LOADING IS COMPLETE [NCRPG by SenatoR] =-");
	CreateNative("NCRPG_RegSkill", 			Native_RegSkill);
	CreateNative("NCRPG_IsValidSkill",		Native_IsValidSkill);
	CreateNative("NCRPG_IsValidSkillID",		Native_IsValidSkillID);
	CreateNative("NCRPG_EnableSkill",			Native_EnableSkill);
	CreateNative("NCRPG_DisableSkill", 		Native_DisableSkill);
	CreateNative("NCRPG_IsSkillDisabled",		Native_IsSkillDisabled);
	CreateNative("NCRPG_GetSkillMaxLevel",	Native_GetSkillMaxLevel);
	CreateNative("NCRPG_GetSkillShortName",	Native_GetSkillShortName);
	CreateNative("NCRPG_GetSkillName",		Native_GetSkillName);
	CreateNative("NCRPG_GetSkillDesc",		Native_GetSkillDesc);
	CreateNative("NCRPG_GetClientSkillCost",	Native_GetClientSkillCost);
	CreateNative("NCRPG_GetSkillCost",		Native_GetSkillCost);
	CreateNative("NCRPG_GetSkillCostSales",	Native_GetSkillCostSales);
	CreateNative("NCRPG_GetSkillCount",		Native_GetSkillCount);
	CreateNative("NCRPG_GetEmptySkills",		Native_GetEmptySkills);
	CreateNative("NCRPG_FindSkillByShortname",Native_FindSkillByShortname);
	CreateNative("NCRPG_SetSkillLevel", 		Native_SetSkillLevel);
	CreateNative("NCRPG_GetSkillLevel", 		Native_GetSkillLevel);	
	CreateNative("NCRPG_SetMaxHP", 			Native_SetMaxHP);	
	CreateNative("NCRPG_GetMaxHP", 			Native_GetMaxHP);		
	CreateNative("NCRPG_SetMaxArmor", 		Native_SetMaxArmor);	
	CreateNative("NCRPG_GetMaxArmor", 		Native_GetMaxArmor);	
	CreateNative("NCRPG_FreezePlayer",		Native_FreezePlayer);
	CreateNative("NCRPG_SetIsPlayerFrozen",	Native_SetIsPlayerFrozen);
	CreateNative("NCRPG_IsPlayerFrozen",		Native_IsPlayerFrozen);
	CreateNative("NCRPG_SlowPlayer",			Native_SlowPlayer);
	CreateNative("NCRPG_SetSlow",				Native_SetSlow);
	CreateNative("NCRPG_GetSlow",				Native_GetSlow);
	CreateNative("NCRPG_SetSpeed",			Native_SetSpeed);
	CreateNative("NCRPG_GetSpeed",			Native_GetSpeed);		
	CreateNative("NCRPG_SetMaxSpeed",			Native_SetMaxSpeed);
	CreateNative("NCRPG_GetMaxSpeed",			Native_GetMaxSpeed);	
	CreateNative("NCRPG_SpeedPlayer",			Native_SpeedPlayer);	
	CreateNative("NCRPG_SetGravity",			Native_SetGravity);
	CreateNative("NCRPG_GetGravity",			Native_GetGravity);
	CreateNative("NCRPG_SetAlpha",			Native_SetAlpha);
	CreateNative("NCRPG_GetAlpha",			Native_GetAlpha);	
	CreateNative("NCRPG_SetMaxAlpha",			Native_SetMaxAlpha);
	CreateNative("NCRPG_GetMaxAlpha",			Native_GetMaxAlpha);
	CreateNative("NCRPG_SetXP",	 			Native_SetXP);
	CreateNative("NCRPG_GetXP",	 			Native_GetXP);
	CreateNative("NCRPG_SetReqXP",	 		Native_SetReqXP);
	CreateNative("NCRPG_GetReqXP",	 		Native_GetReqXP);
	CreateNative("NCRPG_SetLevel", 			Native_SetLevel);
	CreateNative("NCRPG_GetLevel", 			Native_GetLevel);
	CreateNative("NCRPG_SetCredits", 			Native_SetCredits);
	CreateNative("NCRPG_GiveCredits", 		Native_GiveCredits);
	CreateNative("NCRPG_GetCredits", 			Native_GetCredits);
	CreateNative("NCRPG_GiveExp", 			Native_GiveExp);
	CreateNative("NCRPG_SetExp", 				Native_SetExp);
	CreateNative("NCRPG_TakeExp", 			Native_TakeExp);
	CreateNative("NCRPG_ResetPlayer", 		Native_ResetPlayer);
	CreateNative("NCRPG_LogMessage", 			Native_LogMessage);
	CreateNative("NCRPG_GetDbHandle", 		Native_GetDbHandle);	
	CreateNative("NCRPG_SkillActivate", 		Native_OnSkillActivatedPre);
	CreateNative("NCRPG_SkillActivated", 		Native_OnSkillActivatedPost);
	CreateNative("NCRPG_GetParamStringBySteamID",	Native_GetParamStringBySteamID);
	CreateNative("NCRPG_SetParamIntBySteamID",	Native_SetParamIntBySteamID);
	CreateNative("NCRPG_GetParamIntBySteamID",	Native_GetParamIntBySteamID);
	CreateNative("NCRPG_ChatMessage",	 		Native_ChatMessage);
	CreateNative("NCRPG_GiveExpBySteamID",	Native_GiveExpBySteamID);
	CreateNative("NCRPG_SetExpBySteamID",	 	Native_SetExpBySteamID);
	CreateNative("NCRPG_TakeExpBySteamID",	Native_TakeExpBySteamID);
	hFWD_OnConnectedToDB 			= CreateGlobalForward("NCRPG_OnConnectedToDB",	ET_Ignore, Param_Cell);
	hFWD_OnClientLoaded				= CreateGlobalForward("NCRPG_OnClientLoaded",		ET_Ignore, Param_Cell, Param_Cell);
	hFWD_OnRegisterSkills			= CreateGlobalForward("NCRPG_OnRegisterSkills",	ET_Ignore);
	hFWD_OnPlayerSpawned				= CreateGlobalForward("NCRPG_OnPlayerSpawn",		ET_Ignore, Param_Cell);
	hFWD_OnPlayerLevelUp				= CreateGlobalForward("NCRPG_OnPlayerLevelUp",		ET_Ignore, Param_Cell,Param_Cell);
	hFWD_OnPlayerSpawnedPost			= CreateGlobalForward("NCRPG_OnPlayerSpawnedPost", ET_Ignore, Param_Cell);
	hFWD_OnFreezePlayer				= CreateGlobalForward("NCRPG_OnFreezePlayer",		ET_Hook, Param_Cell, Param_CellByRef);
	hFWD_OnSlowPlayer					= CreateGlobalForward("NCRPG_OnSlowPlayer",			ET_Hook, Param_Cell, Param_CellByRef);
	hFWD_OnSlowEndPlayer				= CreateGlobalForward("NCRPG_OnSlowEndPlayer",			ET_Hook, Param_Cell);
	hFWD_OnFreezeEndPlayer			= CreateGlobalForward("NCRPG_OnFreezeEndPlayer",			ET_Hook, Param_Cell);
	hFWD_OnPlayerGiveExpPre			= CreateGlobalForward("NCRPG_OnPlayerGiveExpPre",		ET_Event, Param_Cell, Param_CellByRef,Param_String);
	hFWD_OnPlayerGiveExpPost			= CreateGlobalForward("NCRPG_OnPlayerGiveExpPost",		ET_Hook, Param_Cell, Param_Cell,Param_String);	
	hFWD_OnPlayerGiveCreditsPre		= CreateGlobalForward("NCRPG_OnPlayerGiveCreditsPre",		ET_Event, Param_Cell, Param_CellByRef,Param_String);
	hFWD_OnPlayerGiveCreditsPost	= CreateGlobalForward("NCRPG_OnPlayerGiveCreditsPost",		ET_Hook, Param_Cell, Param_Cell,Param_String);
	hFWD_OnSkillActivatedPre			= CreateGlobalForward("NCRPG_OnSkillActivatePre",		ET_Event, Param_Cell, Param_Cell,Param_Cell);
	hFWD_OnSkillActivatedPost		= CreateGlobalForward("NCRPG_OnSkillActivatedPost",		ET_Hook, Param_Cell, Param_Cell);
	return APLRes_Success;
}



public void OnPluginStart()
{
	if(!CheckSMVersion(11006385)) NCRPg_LogPrint(LogType_FailState,"[NCRPG] Need to update SOURCEMOD minimal req version 1.10.6385");
	ConnectToDB();
	HookEvents();
	CreateBuffArrays();
	LoadTranslations("ncrpg.phrases");
}

public void OnMapStart() {
	LoadAllConfigs();
	CreateSkillsArray();
	RegistrationSkills();
	CreatePlayersArray();
	DeleteBuffArrays();
}

public void OnClientConnected(client) {
	ResetPlayerEx(client);
}

public void OnClientDisconnect(client) {
	SavePlayer(client);
	ResetPlayerEx(client);
}