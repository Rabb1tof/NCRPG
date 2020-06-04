void LoadAllConfigs() {
	
	NCRPG_Configs RPG_Configs = NCRPG_Configs(CONFIG_CORE);
	cfg_iLogMode = RPG_Configs.GetInt("logs","mode",1);
	cfg_iLogDebug = RPG_Configs.GetInt("logs","debug",0);
	RPG_Configs.GetString("logs", "path", cfg_sLogPath, sizeof(cfg_sLogPath), "addons/sourcemod/logs/NCRPG/log.log");
	RPG_Configs.GetString("logs", "error_path", cfg_sLogErrorPath, sizeof(cfg_sLogErrorPath), "addons/sourcemod/logs/NCRPG/error_log.log");
	cfg_iExpStart		= RPG_Configs.GetInt("xp", "exp_start", 300);
	cfg_iExpInc			= RPG_Configs.GetInt("xp", "exp_inc", 100);
	cfg_iExpMax			= RPG_Configs.GetInt("xp", "exp_max", 9999);
	cfg_iCreditsStart	= RPG_Configs.GetInt("xp", "credits_start", 500);
	cfg_iCreditsInc		= RPG_Configs.GetInt("xp", "credits_inc", 11);
	cfg_iMinPlayers		= RPG_Configs.GetInt("xp", "min_players", 2);
	cfg_iMaxLevel		= RPG_Configs.GetInt("xp", "level_max", 1);
	cfg_fSavePer		= RPG_Configs.GetFloat("skills", "per_sell", 0.75);
	cfg_bBotSave		= RPG_Configs.GetInt("databases", "bot_save", 1)?true:false;
	cfg_fLoadDelay		= RPG_Configs.GetFloat("databases", "load_delay", 0.1);
	RPG_Configs.SaveConfigFile(CONFIG_CORE);
}