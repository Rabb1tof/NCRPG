#define DEBUG					true
#define MAX_STEAMID_LENGTH		32
#define MAX_LEVEL_LENGTH		8
#define MAX_XP_LENGTH			16
#define MAX_CREDITS_LENGTH		16
#define MAX_SHORTNAME_LENGTH	16
#define MAX_SKILL_LENGTH		64
#define MAX_SKILL_DESC			256
#define MAX_RPG_CMDS			32
#define MAX_RPG_CMDS_LENGTH		32
#define MAX_MAPS				64
//Skills array
#define ARR_SKILL_ID			0
#define ARR_SKILL_DISABLED		1
#define ARR_SKILL_SHORTNAME		2
#define ARR_SKILL_MAXLEVEL		3
#define ARR_SKILL_COST			4
#define ARR_SKILL_ICOST			5
#define ARR_SKILL_MAPS			6
//Player array
#define ARR_PLAYER_INDEX		0
#define ARR_STEAMID				1
#define ARR_XP					2
#define ARR_REQXP				3
#define ARR_LEVEL				4
#define ARR_CREDITS				5
#define ARR_SKILLS				6
//Buff array
#define ARR_BUFF_ID				0
#define ARR_BUFF_SHORTNAME		1
#define ARR_BUFF_VALUE  		2
#define ARR_BUFF_MAX_VALUE		3

int iCountSkills;
Handle hSQL_DB;
Handle hArraySkills;
Handle hArrayPlayers;


int cfg_iExpStart;			// Необходимый стартовый опыт
int cfg_iExpInc;			// Увелечения опыта за уровень
int cfg_iExpMax;			// Максимальное кол-во опыта за раз

int cfg_iCreditsStart;		// Стартовые кредиты
int cfg_iCreditsInc;		// Кредиты за уровень
int cfg_iMinPlayers;		// Минимальное кол-во игроков для получения опыта
int cfg_iMaxLevel;			// Максимальное кол-во уровней за раз

float cfg_fLoadDelay;		// Задержка загрузки игрока
float cfg_fSavePer;			// Процент возврата кредитов за проданный скилл

int cfg_iFreezing;			// Метод заморозки игроков

bool cfg_bBotSave;
enum Buffs {
	Health,
	Armor,
	bool:Freezing,
	Float:Slow,
	Float:Speed,
	Float:MaxSpeed,
	Float:Gravity,
	Alpha
}

int PlayerBuffs[MAXPLAYERS+1][Buffs];	// Бафы игрока
float fLastVecSpeed[MAXPLAYERS+1][3];	// Последний вектор скорости
bool AuthControl[MAXPLAYERS+1] = {false,...};		// Авторизован ли игрок 

int cfg_iLogMode;									// Как записывать в логи (0 - Использовать стандартные, 1 - Использовать cfg_sLogPath)
int cfg_iLogDebug;									// Будут ли писатьться в логи Debug'и 1 - да 0 - нет
char cfg_sLogPath[PLATFORM_MAX_PATH];			// Путь до логов, если cfg_iLogMode = 1
char cfg_sLogErrorPath[PLATFORM_MAX_PATH];	// Путь до логов с ошибками, если cfg_iLogMode = 1