NCRPg_LogPrint(LogType Log, char[] text, any ...) {
	char buffer[1024];
	VFormat(buffer, sizeof(buffer), text, 3);
	switch(Log)
	{
		case 0:
			(cfg_iLogMode == 1)?NCRPG_LogToFile(cfg_sLogPath, buffer):LogMessage(buffer);
		case 1:
			(cfg_iLogMode == 1)?NCRPG_LogToFile(cfg_sLogErrorPath, buffer):LogError(buffer);
		case 2:
			SetFailState(buffer); //ThrowError(buffer);
		case 3:
		{
			#if DEBUG
				(cfg_iLogMode == 1)?NCRPG_LogToFile(cfg_sLogPath, buffer):LogMessage(buffer);
			#endif
		}
	}
}

