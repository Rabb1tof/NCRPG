
SayFuncX()
{
	RegConsoleCmd("say",RpgNC_SayCommand);
	RegConsoleCmd("say_team",RpgNC_SayCommand);
}

public Action:RpgNC_SayCommand(client, args) {
	if(IsValidPlayer(client))
	{
		decl String:sArgs[256], String:buffer[MAX_RPG_CMDS][MAX_RPG_CMDS_LENGTH];
		GetCmdArgString(sArgs, sizeof(sArgs));
		StripQuotes(sArgs);

		new count = ExplodeString(cfg_sCommandsRPG, ",", buffer, MAX_RPG_CMDS, MAX_RPG_CMDS_LENGTH);
		for(new i = 0; i < count; ++i)
		{
			if(CommandCheck(buffer[i], sArgs))
			{
				NCRpg_ShowMainMenu(client);
				if(cfg_bCmdsHide)
					return Plugin_Handled;
				
				return Plugin_Continue;
			}
		}	/*
		if(PrintPlayersBug[client])
		{
			new x = strlen(sArgs);
			new y = 0;
			while (y < x) 
			{
				if (!IsCharSpace(sArgs[y])) break;
				y++;
			}
			if(y == x || CommandCheck(sArgs, "cancel") || CommandCheck(sArgs, "отмена"))
			{
				NCRPG_ChatMessage(client,"%T","You cancel the input of the error message",client);
			}
			else
			{
				FeedbackMessage(client,sArgs);
				NCRPG_ChatMessage(client,"%T","Thanks for the error message",client);
			}
			PrintPlayersBug[client] = false;
			return Plugin_Handled;
		}*/
		new top_num;
		if((top_num=CommandCheckEx(sArgs,"rpgtop"))>0)
		{
			if(top_num>100) top_num=100;
			{
				DisplayMenuTOP(client, top_num);
			}
			if(cfg_bCmdsHide)
					return Plugin_Handled;
					
			return Plugin_Continue;
		}
		if(CommandCheck(sArgs, "war3rank")|| CommandCheck(sArgs, "rpgrank"))
		{
			GetRank(client);
			if(cfg_bCmdsHide)
					return Plugin_Handled;
					
			return Plugin_Continue;
		}
		if(CommandCheck(sArgs, "upgrades")|| CommandCheck(sArgs, "умения"))
		{
			DisplayMenu(BuildMenuUpgrades(client), client, MENU_TIME_FOREVER);
			if(cfg_bCmdsHide)
					return Plugin_Handled;
					
			return Plugin_Continue;
		}
		if(CommandCheck(sArgs, "help")|| CommandCheck(sArgs, "помощь"))
		{
			DisplayMenu(BuildMenuHelp(client), client, MENU_TIME_FOREVER);
			if(cfg_bCmdsHide)
					return Plugin_Handled;
					
			return Plugin_Continue;
		}		
		if(CommandCheck(sArgs, "rules")|| CommandCheck(sArgs, "правила"))
		{
			DisplayMenu(BuildMenuHelpRules1(client), client, MENU_TIME_FOREVER);
			if(cfg_bCmdsHide)
					return Plugin_Handled;
					
			return Plugin_Continue;
		}
	}
	
	return Plugin_Continue;
}