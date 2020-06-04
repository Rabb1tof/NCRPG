#pragma semicolon 1
#include <vip_core>
#include "NCIncs/nc_rpg.inc"


// For Vip by R1KO
public Plugin myinfo =
{
	name = "[VIP] NCRPG XP CREDITS RATE",
	author = "SenatoR",
	version = "1.2"
};

#define XP				"NCRPG_XP_RATE"
#define CRED			"NCRPG_CREDITS_RATE"

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(XP, FLOAT, HIDE);
	VIP_RegisterFeature(CRED, FLOAT, HIDE);
}

public Action NCRPG_OnPlayerGiveExpPre(int client,int &Exp)
{
	if (VIP_IsClientVIP(client) && VIP_IsClientFeatureUse(client, XP))
	{
		Exp = RoundToNearest(Exp*VIP_GetClientFeatureFloat(client, XP));
		return Plugin_Changed; 
	}
	return Plugin_Continue;
}

public Action NCRPG_OnPlayerGiveCreditsPre(int client,int &Credits)
{
	if (VIP_IsClientVIP(client) && VIP_IsClientFeatureUse(client, CRED))
	{
		Credits = RoundToNearest(Credits*VIP_GetClientFeatureFloat(client, CRED));
		return Plugin_Changed; 
	}
	return Plugin_Continue;
}
