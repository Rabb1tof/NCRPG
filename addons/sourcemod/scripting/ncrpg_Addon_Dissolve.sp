#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"

#define VERSION	"1.1"

char death_effect[][] ={"death_effect1p","death_effect1c"};

public Plugin myinfo = {
	name		= "NCRPG Dissolve",
	author		= "SenatoR",
	description	= "",
	version		= VERSION
};

public void OnPluginStart() {
	HookEvent("player_death",	OnPlayerDeath);
}


public OnMapStart()
{
	AddFileToDownloadsTable("particles/ncrpg_death_effect.pcf");
	PrecacheParticle("particles/ncrpg_death_effect.pcf");
	PrecacheParticleEffect(death_effect[0]);
	PrecacheParticleEffect(death_effect[1]);
}


public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidPlayer(client))
	{
		int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if (ragdoll<0)
			return Plugin_Continue;
		float fPos[3];
		fPos[2]+=45;
		GetClientAbsOrigin(client,fPos);
		AttachParticle(client,death_effect[0],fPos);
		RemoveEdict(ragdoll);
	}
	return Plugin_Continue;
}
