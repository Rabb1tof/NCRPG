#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define ThisSkillShortName "teledec"
#define VERSION		"1.0"

int ThisSkillID;

float cfg_fPercent;bool cfg_bRepeatGive;bool cfg_bSpawnGive;
int offDecoy=-1;
int m_vecBaseVelocity=-1;
public Plugin myinfo = {
	name		= "NCRPG Decoy Teleport",
	author		= "SenatoR",
	description	= "Skill Decoy Teleport for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() {
	if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills();
	m_vecBaseVelocity = FindSendPropInfo("CBasePlayer", "m_vecBaseVelocity");
	if(m_vecBaseVelocity == -1) SetFailState("Could not find the offset: CBasePlayer :: m_vecBaseVelocity");
	HookEvent("decoy_firing", Event_Decoy);
}

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 16, 10,5,true); }

public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fPercent = RPG_Configs.GetFloat(ThisSkillShortName,"chance",0.5);
	cfg_bSpawnGive = RPG_Configs.GetInt(ThisSkillShortName,"spawn_give",1)?true:false;
	cfg_bRepeatGive = RPG_Configs.GetInt(ThisSkillShortName,"repeat_give",1)?true:false;
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
	if(cfg_bRepeatGive || cfg_bSpawnGive)
	{
		int entindex = CreateEntityByName("weapon_decoy");
		DispatchSpawn(entindex);
		offDecoy = GetEntProp(entindex, Prop_Send, "m_iPrimaryAmmoType");
		AcceptEntityInput(entindex, "Kill");
	}
}

public Action Event_Decoy(Event event, const char[] name, bool dontBroadcast)
{
	if(NCRPG_IsValidSkill(ThisSkillID)) return Plugin_Continue;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidPlayer(client,true))
	{
		int level = NCRPG_GetSkillLevel(client, ThisSkillID);
		if(level>0 && GetRandomFloat(0.0,1.0) < level*cfg_fPercent)
		{
			float fClientPos[3];
			GetClientAbsOrigin(client,fClientPos);
			int ent = event.GetInt("entityid");
			float fPos[3];
			fPos[0] = event.GetFloat("x");
			fPos[1] = event.GetFloat("y");
			fPos[2] = event.GetFloat("z");
			RemoveEdict(ent);
			DataPack pack = new DataPack();
			pack.WriteCell(client);
			pack.WriteFloat(fClientPos[0]);
			pack.WriteFloat(fClientPos[1]);
			pack.WriteFloat(fClientPos[2]);
			TeleportEntity(client, fPos, NULL_VECTOR, NULL_VECTOR);
			CreateTimer(0.1,StuckCheck,pack,TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public Action StuckCheck(Handle timer, DataPack pack) 
{
	pack.Reset(false);
	int client = pack.ReadCell();
	if(IsValidPlayer(client,true))
	{
		float velocity[3];
		velocity[0] = 50.0;
		velocity[1] = 50.0;
		velocity[2] = 0.0;
		float fClientPos[3];
		GetClientAbsOrigin(client,fClientPos);
		float fStartClientPos[3];
		fStartClientPos[0] = pack.ReadFloat();
		fStartClientPos[1] = pack.ReadFloat();
		fStartClientPos[2] = pack.ReadFloat();
		pack.Reset(true);
		pack.WriteCell(client);
		pack.WriteFloat(fStartClientPos[0]);
		pack.WriteFloat(fStartClientPos[1]);
		pack.WriteFloat(fStartClientPos[2]);
		pack.WriteFloat(fClientPos[0]);
		pack.WriteFloat(fClientPos[1]);
		pack.WriteFloat(fClientPos[2]);
		SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
		
		CreateTimer(0.1,FinalCheck,pack,TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
	}else
	delete pack;
}
public Action FinalCheck(Handle timer, DataPack pack) 
{
	pack.Reset(false);
	int client = pack.ReadCell();
	if(IsValidPlayer(client,true))
	{
		float fStartClientPos[3];
		fStartClientPos[0] = pack.ReadFloat();
		fStartClientPos[1] = pack.ReadFloat();
		fStartClientPos[2] = pack.ReadFloat();
		float fOldClientPos[3];
		fOldClientPos[0] = pack.ReadFloat();
		fOldClientPos[1] = pack.ReadFloat();
		fOldClientPos[2] = pack.ReadFloat();
		float fNewClientPos[3];
		GetClientAbsOrigin(client,fNewClientPos);
		if(GetVectorDistance(fNewClientPos,fOldClientPos)<0.01)
		{
			TeleportEntity(client, fStartClientPos, NULL_VECTOR, NULL_VECTOR);
			if(cfg_bRepeatGive)
			{
				if(GetEntProp(client, Prop_Data, "m_iAmmo", _, offDecoy) == 0) GivePlayerItem(client, "weapon_decoy");
			}
		}
		else
		{
			NCRPG_SkillActivated(ThisSkillID,client);
		}
	}
}
