#include <sourcemod>
#include <NCIncs/nc_rpg>
#include <keys_core>

#pragma semicolon 1

public Plugin myinfo = {
	name = "[NCRPG] Keys",
	author = "Rabb1t",
	version = "1.0",
	description = "Keys can give lvl, xp, credits"
}

stock const char g_sKeyType[][]= {"ncrpg_xp", "ncrpg_credits", "ncrpg_lvl"};

public void OnPluginStart()
{
	LoadTranslations("keys_core.phrases");
	LoadTranslations("keys_ncrpg_module.phrases");
	
	if (Keys_IsCoreStarted()) Keys_OnCoreStarted();
}

public void OnPluginEnd()
{
	for(int i = 0; i < sizeof(g_sKeyType); ++i)
	{
		Keys_UnregKey(g_sKeyType[i]);
	}
}

public int Keys_OnCoreStarted()
{
	for(int i = 0; i < sizeof(g_sKeyType); ++i)
	{
		Keys_RegKey(g_sKeyType[i], OnKeyParamsValidate, OnKeyUse, OnKeyPrint);
	}
}

public bool OnKeyParamsValidate(int client, const char[] sKeyType, Handle hParamsArr, char[] sError, int iErrLen)
{
	if(GetArraySize(hParamsArr) != 1)
	{
		FormatEx(sError, iErrLen, "%T", "ERROR_NUM_ARGS", client);
		return false;
	}

	char sParam[KEYS_MAX_LENGTH];
	GetArrayString(hParamsArr, 0, sParam, sizeof(sParam));

	if(StringToInt(sParam) < 1)
	{
		FormatEx(sError, iErrLen, "%T", "ERROR_INVALID_AMONUT", client);
		return false;
	}

	return true;
}

public bool OnKeyUse(int client, const char[] sKeyType, Handle hParamsArr, char[] sError, int iErrLen)
{
	char sParam[KEYS_MAX_LENGTH];
	GetArrayString(hParamsArr, 0, sParam, sizeof(sParam));

	if(!strcmp(sKeyType, g_sKeyType[0]))
	{
		if(!NCRPG_GiveExp(client, StringToInt(sParam)))
		{
			FormatEx(sError, iErrLen, "%T", "ERROR_HAS_OCCURRED", client);
			return false;
		}

		PrintToChat(client, "%t%t", "CHAT_PREFIX", "YOU_RECEIVED_XP", StringToInt(sParam));
		return true;
	}

	if(!strcmp(sKeyType, g_sKeyType[2]))
	{
		if(!NCRPG_SetLevel(client, StringToInt(sParam) + NCRPG_GetLevel(client)))
		{
			FormatEx(sError, iErrLen, "%T", "ERROR_HAS_OCCURRED", client);
			return false;
		}

		PrintToChat(client, "%t%t", "CHAT_PREFIX", "YOU_RECEIVED_LVL", StringToInt(sParam));
		return true;
	}

	if(!NCRPG_GiveCredits(client, StringToInt(sParam)))
	{
		FormatEx(sError, iErrLen, "%T", "ERROR_HAS_OCCURRED", client);
		return false;
	}

	PrintToChat(client, "%t%t", "CHAT_PREFIX", "YOU_RECEIVED_CREDITS", sParam);

	return true;
}

public OnKeyPrint(int client, const char[] sKeyType, Handle hParamsArr, char[] sBuffer, int iBufLen)
{
	char sParam[KEYS_MAX_LENGTH];
	GetArrayString(hParamsArr, 0, sParam, sizeof(sParam));
	if(!strcmp(sKeyType, g_sKeyType[0]))
	{
		FormatEx(sBuffer, iBufLen, "%T: %s", "XP", client, StringToInt(sParam));
		return;
	}

	if(!strcmp(sKeyType, g_sKeyType[1]))
	{
		FormatEx(sBuffer, iBufLen, "%T: %s", "CREDITS", client, StringToInt(sParam));
		return;
	}

	FormatEx(sBuffer, iBufLen, "%T: %s", "LVL", client, StringToInt(sParam));
}
