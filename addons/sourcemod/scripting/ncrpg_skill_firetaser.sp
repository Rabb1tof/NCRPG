#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"
#define ThisSkillShortName "firet"
#define VERSION				"1.2"
#define MAX_WEAPON_LENGTH	32

int ThisSkillID;

float cfg_fPercent;int cfg_iDamage;
float MaxWorldLength;
public Plugin myinfo = {
	name		= "NCRPG Skill Fire Taser",
	author		= "SenatoR",
	description	= "Skill Fire Taser for NCRPG",
	version		= VERSION
};

public void OnPluginStart() {
	if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) == -1) NCRPG_OnRegisterSkills();
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);
}

public void OnPluginEnd() { if((ThisSkillID = NCRPG_FindSkillByShortname(ThisSkillShortName)) != -1) NCRPG_DisableSkill(ThisSkillID, true); }

public void NCRPG_OnRegisterSkills() { ThisSkillID = NCRPG_RegSkill(ThisSkillShortName, 10, 10,5,true); }

public void OnMapStart() {
	NCRPG_Configs RPG_Configs = NCRPG_Configs(ThisSkillShortName,CONFIG_SKILL);
	cfg_fPercent = RPG_Configs.GetFloat(ThisSkillShortName,"percent",1.5);
	cfg_iDamage = RPG_Configs.GetInt(ThisSkillShortName,"damage",1);
	RPG_Configs.SaveConfigFile(ThisSkillShortName,CONFIG_SKILL);
	
	float WorldMinHull[3]; float WorldMaxHull[3];
	GetEntPropVector(0, Prop_Send, "m_WorldMins", WorldMinHull);
	GetEntPropVector(0, Prop_Send, "m_WorldMaxs", WorldMaxHull);
	MaxWorldLength = GetVectorDistance(WorldMinHull, WorldMaxHull);

}

public void NCRPG_OnPlayerSpawn(int client) {
	if(!NCRPG_IsValidSkill(ThisSkillID)) return;
	int level = NCRPG_GetSkillLevel(client, ThisSkillID);
	if(level > 0) if(GetRandomFloat(0.0, 100.0) <= cfg_fPercent*level) GivePlayerItem(client,"weapon_taser");
	//if(level > 0) GivePlayerItem(client,"weapon_taser");
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast) 
{
	if(!NCRPG_IsValidSkill(ThisSkillID))  return Plugin_Continue;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidPlayer(client,true))
	{
		int level = NCRPG_GetSkillLevel(client, ThisSkillID);
		if(level>0)
		{
			char sWeapon[32];
			event.GetString( "weapon", sWeapon, sizeof sWeapon);
			if(StrEqual(sWeapon, "weapon_taser"))
			{
				if(GetRandomFloat(0.0, 100.0) <= cfg_fPercent*level)
				{
					float origin[3]; float angles[3]; float target_pos[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
					origin[2] += 50.0; AddInFrontOf(origin, angles, 5, origin);
					int target = FindAliveTarget(client, origin, angles, target_pos);
					if(NCRPG_SkillActivate(ThisSkillID,client,target)>= Plugin_Handled) return Plugin_Handled;
					if (target > 0){ RocketAttack(client, origin, angles); }
				}
			}
		}
	}
	return Plugin_Continue;
}

RocketAttack(int client, float client_pos[3], float client_angles[3])
{
	float anglevector[3]; GetAngleVectors(client_angles, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector); NormalizeVector(anglevector, anglevector);
	ScaleVector(anglevector, 1500.0); int rocket = CreateEntityByName("hegrenade_projectile");
	DispatchKeyValue(rocket, "spawnflags", "16"); DispatchSpawn(rocket);
	SetEntityRenderMode(rocket, RENDER_NONE); IgniteEntity(rocket,30.0);
	SetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity", client);
	SetEntPropEnt(rocket, Prop_Send, "m_hThrower", client);
	SetEntityMoveType(rocket, MOVETYPE_FLY);
	float vec1[] = {-4.0, -4.0, -4.0}; float vec2[] = {4.0, 4.0, 4.0};
	SetEntPropVector(rocket, Prop_Send, "m_vecMins", vec1);
	SetEntPropVector(rocket, Prop_Send, "m_vecMaxs", vec2);
	TeleportEntity(rocket, client_pos, client_angles, anglevector);
	char Name[64]; Format(Name, 64, "gren_%f", GetGameTime());
	DispatchKeyValue(rocket, "targetname", Name); SetVariantString(Name);
	HookSingleEntityOutput(rocket, "OnUser2", MissileThink);
	SetVariantString("OnUser1 !self:FireUser2::0.1:-1");
	AcceptEntityInput(rocket, "AddOutput");
	AcceptEntityInput(rocket, "FireUser1");
	SDKHook(rocket, SDKHook_StartTouch, RocketTouchHook);
}
	
public MissileThink(const char[] output,int caller,int activator, float delay)
{
	float CheckVec[3]; GetEntPropVector(caller, Prop_Send, "m_vecVelocity", CheckVec);
	if ((CheckVec[0] == 0.0) && (CheckVec[1] == 0.0) && (CheckVec[2] == 0.0)) { CreateExplosion(caller); return; }
	float NadePos[3]; float EnemyPos[3]; GetEntPropVector(caller, Prop_Send, "m_vecOrigin", NadePos);
	float ClosestDistance = MaxWorldLength;int Tclient = 0; float EnemyDistance;
	int rocket_client = GetEntPropEnt(caller, Prop_Data, "m_hThrower"); int team = GetClientTeam(rocket_client);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != team)
		{
			GetClientAbsOrigin(i, EnemyPos); EnemyPos[2] += 55.0;
			float vec1[] = {-2.5, -2.5, -2.5}; float vec2[] = {-2.5, -2.5, -2.5};
			TR_TraceHullFilter(NadePos, EnemyPos, vec1, vec2, MASK_SOLID, TraceEntityFilterPlayer, caller);
			if (TR_GetEntityIndex() == i)
			{
				EnemyDistance = GetVectorDistance(NadePos, EnemyPos);
				if (EnemyDistance < ClosestDistance) { Tclient = i; ClosestDistance = EnemyDistance; }
			}
		}
	}
	if (Tclient < 1) { AcceptEntityInput(caller, "FireUser1"); return; }
	float TargetVec[3]; GetClientAbsOrigin(Tclient, EnemyPos); EnemyPos[2] += 55.0; MakeVectorFromPoints(NadePos, EnemyPos, TargetVec);
	NormalizeVector(TargetVec, TargetVec); ScaleVector(TargetVec, 500.0); float FinalAng[3]; GetVectorAngles(TargetVec, FinalAng);
	TeleportEntity(caller, NULL_VECTOR, FinalAng, TargetVec); AcceptEntityInput(caller, "FireUser1");
}

public Action RocketTouchHook(int entity,int other) { CreateExplosion(entity); }

void CreateExplosion(int rocket)
{
	UnhookSingleEntityOutput(rocket, "OnUser2", MissileThink);
	SDKUnhook(rocket, SDKHook_StartTouch, RocketTouchHook);
	int rocket_client = GetEntPropEnt(rocket, Prop_Data, "m_hThrower");
	float origin[3]; GetEntPropVector(rocket, Prop_Send, "m_vecOrigin", origin);
	ExtinguishEntity(rocket); AcceptEntityInput(rocket, "Kill");
	int index = CreateEntityByName("env_explosion");
	if (index > 0)
	{
		DispatchKeyValue(index, "targetname", "Rocket_Explosion");
		DispatchKeyValueVector(index, "origin", origin);
		DispatchKeyValue(index, "spawnflags", "6146"); char buffer[256];
		int level = NCRPG_GetSkillLevel(rocket_client, ThisSkillID)*cfg_iDamage;
		IntToString(level,buffer,sizeof buffer); DispatchKeyValue(index, "iMagnitude", buffer); 
		DispatchKeyValue(index, "iRadiusOverride", "250"); DispatchSpawn(index);
		if (rocket_client > 0) SetEntPropEnt(index, Prop_Send, "m_hOwnerEntity", rocket_client);
		AcceptEntityInput(index, "Explode"); AcceptEntityInput(index, "Kill");
	}
}

int FindAliveTarget(int client, const float client_pos[3], float client_angles[3], float target_pos[3])
{
	float VecPoints[3]; float Atan;int index; int team = GetClientTeam(client);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=team)
		{
			GetClientAbsOrigin(i, target_pos); target_pos[2] += 55.0;
			MakeVectorFromPoints(client_pos, target_pos, VecPoints);

			Atan = RadToDeg(ArcTangent(VecPoints[1] / VecPoints[0]));
			if (VecPoints[0] < 0) client_angles[1] = Atan + 180.0;
			else if (VecPoints[1] < 0) client_angles[1] = Atan + 360.0;
			else client_angles[1] = Atan;

			client_angles[2] = target_pos[2];
			client_angles[0] = 0.0 - RadToDeg(ArcTangent(VecPoints[2] / SquareRoot(Pow(VecPoints[1], 2.0) + Pow(VecPoints[0], 2.0)))); 

			TR_TraceRayFilter(client_pos, client_angles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client);
			if ((index = TR_GetEntityIndex()) > 0 && index <= MaxClients){return index;}
		}
	}
	return 0;
}

public bool TraceEntityFilterPlayer(int entity,int contentsMask, any data) { return entity != data; }

void AddInFrontOf(float vecOrigin[3], float vecAngle[3], units, float output[3])
{
	float vecView[3]; GetViewVector(vecAngle, vecView);
	output[0] = vecView[0] * units + vecOrigin[0];
	output[1] = vecView[1] * units + vecOrigin[1];
	output[2] = vecView[2] * units + vecOrigin[2];
}

void GetViewVector(float vecAngle[3], float output[3])
{
	output[0] = Cosine(vecAngle[1] / (180 / FLOAT_PI));
	output[1] = Sine(vecAngle[1] / (180 / FLOAT_PI));
	output[2] = -Sine(vecAngle[0] / (180 / FLOAT_PI));
}
