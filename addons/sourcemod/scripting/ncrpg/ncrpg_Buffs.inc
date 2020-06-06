Handle hArraySlowTimers;
Handle hArraySpeedTimers;
Handle hTimerFreezing[MAXPLAYERS+1];	// Пусть живет // Пусть живет

void ResetPlayerModification(client) {
	SetMaxHP(client, 100);
	SetEntityHealth(client,100); // Нужен на случай наследования игроком максимального хп прошлого игрока, если вдруг здоровье нового игрока не прокачано, случается лишь при первом спавне и если за 0.09 секунд он сумел получить лечение, или при SDKHook_GetMaxHealth с передачей туда MaxHP.
	SetMaxSpeed(client, 1.0);
	SetGravity(client, 1.0);
	SetSlow(client, 0.0);
	SetIsPlayerFrozen(client, false);
	SetSpeed(client, 1.0);
	SetEntityGravity(client,1.0);
	SetMaxPlayerAlpha(client,255);
}

// OnPluginStart
void CreateBuffArrays() {
	hArraySlowTimers = CreateArray();
	hArraySpeedTimers = CreateArray();
}

// round_start
void ResetBuffArrays() {
	for(int i = GetArraySize(hArraySlowTimers)-1; i >= 0; --i)
		CloseHandle(GetArrayCell(hArraySlowTimers, i));
	ClearArray(hArraySlowTimers);
	for(int i = GetArraySize(hArraySpeedTimers)-1; i >= 0; --i)
		CloseHandle(GetArrayCell(hArraySpeedTimers, i));
	ClearArray(hArraySpeedTimers);
}

// OnMapStart
void DeleteBuffArrays() {
	ClearArray(hArraySlowTimers);
	ClearArray(hArraySpeedTimers);
}

int SetMaxHP(int client, int amount) {
	return PlayerBuffs[client][Health] = amount;
}

int GetMaxHP(int client) {
	return PlayerBuffs[client][Health];
}

int SetMaxArmor(int client, amount) {
	return PlayerBuffs[client][Armor] = amount;
}

int GetMaxArmor(int client) {
	return PlayerBuffs[client][Armor];
}


float SetGravity(int client, float amount) {
	SetEntityGravity(client,amount);
	return PlayerBuffs[client][Gravity] = amount;
}

float GetGravity(int client) {
	return PlayerBuffs[client][Gravity];
}

bool IsPlayerFrozen(int client) {
	return PlayerBuffs[client][Freezing];
}

bool SetIsPlayerFrozen(int client, bool enable) {
	return PlayerBuffs[client][Freezing] = enable;
}

void FreezePlayer(client, float time) {
	// старый таймер не удаляется
	if(API_OnFreezePlayer(client, time) >= Plugin_Handled)
		return;
	
	if(hTimerFreezing[client] != INVALID_HANDLE)
	{
		KillTimer(hTimerFreezing[client]);
		hTimerFreezing[client] = INVALID_HANDLE;
	}
	
	PlayerBuffs[client][Freezing] = true;
	switch(cfg_iFreezing)
	{
		case 1: GetEntPropVector(client, Prop_Data, "m_vecVelocity", fLastVecSpeed[client]);
		case 2:
		{
			fLastVecSpeed[client][0] = 0.0;
			fLastVecSpeed[client][1] = 0.0;
			fLastVecSpeed[client][2] = 0.0;
		}
	}
	
	SetSpeed(client, 0.0);
	hTimerFreezing[client] = CreateTimer(time, Timer_RemoveFreezing, client);
}

public Action Timer_RemoveFreezing(Handle timer, int client) {
	hTimerFreezing[client] = INVALID_HANDLE;
	if(IsValidPlayer(client, true) && IsPlayerFrozen(client))
	{
		switch(cfg_iFreezing)
		{
			case 1: SetEntPropVector(client, Prop_Data, "m_vecVelocity", fLastVecSpeed[client]);
			case 2: SetEntPropVector(client, Prop_Data, "m_vecVelocity", fLastVecSpeed[client]);
		}
		
		SetSpeed(client, GetMaxSpeed(client));
	}
	PlayerBuffs[client][Freezing] = false;
	API_OnFreezeEndPlayer(client);
}

float SetSlow(int client, float amount) {
	if(amount > 1.0)
		amount = 1.0;
	else if(amount < 0.0)
		amount = 0.0;
	return PlayerBuffs[client][Slow] = amount;
}

float GetSlow(int client) {
	return PlayerBuffs[client][Slow];
}

float SetPlayerSpeed(int client, float amount) {
	return PlayerBuffs[client][Speed] = amount;
}

float GetPlayerSpeed(int client) {
	return PlayerBuffs[client][Speed];
}

float SetMaxSpeed(int client, float amount) {
	return PlayerBuffs[client][MaxSpeed] = amount;
}

float GetMaxSpeed(int client) {
	return PlayerBuffs[client][MaxSpeed];
}
//ПЕРЕДЕЛАТЬ  1.0
//Надо проверить 1.1
//Вроде пашет 1.2
Handle SlowPlayer(int client, float amount, float time) {
	Handle timer = INVALID_HANDLE;
	if(!IsPlayerFrozen(client))
	{
		float slow = GetSlow(client);
		slow -= SetSlow(client, slow+amount);
		if(slow != 0.0)
		{
			if(API_OnSlowPlayer(client, slow,time) >= Plugin_Handled)
			{
				return timer;
			}
			SetSpeed(client, GetSpeed(client)+slow);	// slow < 0
			
			DataPack datapack = new DataPack();
			datapack.WriteCell(client);
			datapack.WriteFloat(slow);
			datapack.Reset();
			timer =  CreateTimer(time, Timer_RemoveSlow, datapack, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return timer;
}
//
public Action Timer_RemoveSlow(Handle timer, DataPack datapack) {
	int client = datapack.ReadCell();	
	
	for(int i = 0; i < GetArraySize(hArraySlowTimers); ++i)
		if(GetArrayCell(hArraySlowTimers, i) == timer)
		{
			RemoveFromArray(hArraySlowTimers, i);
			break;
		}
	
	float amount = datapack.ReadFloat();
	SetSlow(client, GetSlow(client)-FloatAbs(amount));
	
	if(IsValidPlayer(client, true))
		SetSpeed(client, GetMaxSpeed(client));
	
	API_OnSlowEndPlayer(client);
	//CloseHandle(datapack);
}

Handle SpeedPlayer(int client, float amount, float time) {
	Handle timer = INVALID_HANDLE;
	if(!IsPlayerFrozen(client))
	{
		float speed = GetPlayerSpeed(client);
		speed -= SetPlayerSpeed(client, speed-amount);
		SetSpeed(client, GetSpeed(client)-speed);

		DataPack datapack = new DataPack();
		datapack.WriteCell(client);
		datapack.WriteFloat(speed);
		datapack.Reset();
		timer = CreateTimer(time, Timer_RemoveSpeed, datapack, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
	}
 
	return timer;
}
//new Handle:timer = CreateTimer(time, Timer_RemoveSlow, datapack, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
public Action Timer_RemoveSpeed(Handle timer, DataPack datapack) {
	int client = datapack.ReadCell();
	
	for(int i = 0; i < GetArraySize(hArraySpeedTimers); ++i)
		if(GetArrayCell(hArraySpeedTimers, i) == timer)
		{
			RemoveFromArray(hArraySpeedTimers, i);
			break;
		}
	
	float amount = datapack.ReadFloat();
	SetPlayerSpeed(client, GetPlayerSpeed(client)-amount);
	
	if(IsValidPlayer(client, true))
		SetSpeed(client, GetSpeed(client)+amount);
	
	//CloseHandle(datapack);
}

float SetSpeed(int client, float amount) {
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", amount);
	return GetSpeed(client);
}

float GetSpeed(int client) {
	return GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
}



/* =================================================================== */

int SetMaxPlayerAlpha(int client,int amount) {
	if(amount > 255) amount = 255;
	else if(amount < 0) amount = 0;
	return PlayerBuffs[client][Alpha] = amount;
}

int GetMaxPlayerAlpha(int client) {
	return PlayerBuffs[client][Alpha];
}


/* =================================================================== */