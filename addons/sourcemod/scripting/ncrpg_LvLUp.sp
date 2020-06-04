#pragma semicolon 1
#include "NCIncs/nc_rpg.inc"

#define ThisAddonName "LvlUp"
public Plugin myinfo = {
	name = "NCRPG LvlUp",
	author = "SenatoR",
	description="New concept RPG in source",
	version = "1.2"
};

Handle OverlayDelTimer[MAXPLAYERS+1];
char ModelBuf[30][PLATFORM_MAX_PATH];
char SoundBuf[30][PLATFORM_MAX_PATH];
int EffectCount = 0;

#define AbilityUp "ncrpg/ability_up1.mp3"

public void OnMapStart()
{
	KeyValues hConfig = new KeyValues("NCRPG");
	char full_path[512];
	FormatEx(full_path,sizeof full_path,"configs/NCRPG/Addon.%s.txt",ThisAddonName);
	BuildPath(Path_SM, full_path, sizeof full_path, full_path);
	if(FileExists(full_path))
	{
		hConfig.ImportFromFile(full_path);
		if(hConfig.GotoFirstSubKey())
		{
			do
			{
				
				hConfig.GetString("overlay",ModelBuf[EffectCount],PLATFORM_MAX_PATH,"");
				hConfig.GetString("sound", SoundBuf[EffectCount],PLATFORM_MAX_PATH,"");
				if(strlen(ModelBuf[EffectCount])!=0 || strlen(SoundBuf[EffectCount])) EffectCount++;
			}
			while (hConfig.GotoNextKey());
		}
	}
	else EffectCount = 0;
	if(EffectCount>0)
	{
		AddFolderDecalToDownloadsTable("materials/overlays/ncrpg");
		AddFolderSoundToDownloadsTable("ncrpg");
		PrecacheSound(AbilityUp);
	}
}

public void NCRPG_OnPlayerLevelUp(int client,int level)
{
	if(EffectCount>0)
	{
		if(!IsFakeClient(client))
		{
			if (OverlayDelTimer[client] != INVALID_HANDLE)
			{
				KillTimer(OverlayDelTimer[client]);
				OverlayDelTimer[client] = INVALID_HANDLE;
			}
			int i = GetRandomInt(1,EffectCount);	
			ClientCommand(client, "r_screenoverlay \"%s\"", ModelBuf[i]);
			OverlayDelTimer[client] = CreateTimer(4.0, OverlayOffTimer, client, TIMER_FLAG_NO_MAPCHANGE);
			char Path[80];
			Format(Path, sizeof(Path), "*%s", SoundBuf[i]);
			EmitSoundToClient(client,Path,SOUND_FROM_PLAYER,SNDCHAN_VOICE);
		}
	}
}

public Action OverlayOffTimer(Handle timer, any client)
{
	OverlayDelTimer[client] = INVALID_HANDLE;
	if (IsClientInGame(client))
	{
		ClientCommand(client, "r_screenoverlay off");
	}
	return Plugin_Stop;
}

public void OnClientDisconnect(int client)
{
	if (OverlayDelTimer[client] != INVALID_HANDLE)
	{
		KillTimer(OverlayDelTimer[client]);
		OverlayDelTimer[client] = INVALID_HANDLE;
	}
}


public Action NCRPG_OnSkillLevelChange(int client,int &skillid,int old_value,int &new_value)
{
	if(IsValidPlayer(client))
	{
		if(old_value < new_value)
		{
			char Path[80];
			Format(Path, sizeof(Path), "*%s", AbilityUp);
			EmitSoundToClient(client,Path,SOUND_FROM_PLAYER,SNDCHAN_VOICE);
		}
	}
}