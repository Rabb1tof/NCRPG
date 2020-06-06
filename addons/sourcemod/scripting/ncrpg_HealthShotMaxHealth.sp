#include <NCIncs/ncrpg_Buffs>
#include <sdkhooks>

public Plugin myinfo = {
	name = "[NCRPG] Healthshot max heal increaser",
	author = "inklesspen",
	version = "1.0",
	description = "Increases max health for engine. Healthshot heal to max health of RPG"
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth)
}

public Action OnGetMaxHealth(int client, int &maxhealth)
{
	maxhealth = NCRPG_GetMaxHP(client)
	if(maxhealth)
		return Plugin_Changed
	return Plugin_Continue
}