#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"

#define VERSION				"1.1"
int ThisSkillID;
int EffectLaserSprite;
bool enabled = false;
public Plugin myinfo = {
	name		= "NCRPG Long Jump 2 Effect",
	author		= "SenatoR",
	description	= "Long Jump 2 Effect for NCRPG",
	version		= VERSION,
	url			= ""
};

public void OnPluginStart() {
	HookEvent("player_jump", Event_PlayerJump);
}

public void OnMapStart() 
{
	if((ThisSkillID = NCRPG_FindSkillByShortname("longjump")) == -1) enabled = false;
	EffectLaserSprite = PrecacheBeamSprite();
}

public Action Event_PlayerJump(Event event, const char[] name, bool dontBroadcast) {
	if(!enabled) return Plugin_Continue;
	if(NCRPG_IsValidSkill(ThisSkillID))  return Plugin_Continue;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidPlayer(client, true))
	{
		int level = NCRPG_GetSkillLevel(client, ThisSkillID);
		if(level > 0)
		{
			int color[4];
			if(GetClientTeam(client)==2)
			{
				color={255,20,0,127};
			}
			else if(GetClientTeam(client)==3)
			{
				color={0,20,255,127};
			}
			TE_SetupBeamFollow(client,EffectLaserSprite,0,0.3,1.0,1.0,1,color);
			int[] clients=new int[MaxClients];
			int numClients;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidPlayer(i) && i!=client)
				{
					clients[numClients++] = i;
				}
			}
			TE_Send(clients, numClients);
		}
	}
	return Plugin_Continue;
}