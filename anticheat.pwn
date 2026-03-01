#include <open.mp>
#include <a_mysql>

// MySQL connection settings
#define MYSQL_HOST "127.0.0.1"
#define MYSQL_USER "root"
#define MYSQL_PASS ""
#define MYSQL_DB   "samplogin"

new MySQL:db_handle;

// ID Диалогов
enum {
    DLG_NONE,
    DLG_REG,
    DLG_LOGN
}
new PlayerVehicle[MAX_PLAYERS] = {INVALID_VEHICLE_ID, ...};
new PlayerAdmin[MAX_PLAYERS];
new Float:pLastX[MAX_PLAYERS], Float:pLastY[MAX_PLAYERS], Float:pLastZ[MAX_PLAYERS];
// MAX_PLAYERS — это размер сервера (например, 50 или 1000)
// 3 — это количество ячеек для X, Y и Z
new Float:PosTable[MAX_PLAYERS][3];
// Глобальная переменная для денег (Античит-база)
new PlayerMoney[MAX_PLAYERS];
new bool:IsLoggedIn[MAX_PLAYERS]; // Флаг, чтобы античит не кикал до логина
new PlayerTick[MAX_PLAYERS];
// --- Forward-ы ---
forward CheckAccount(playerid);
forward OnLogin(playerid);
forward AntiCheatTimer();

public OnFilterScriptInit()
{
    EnableStuntBonusForAll(false); // Отключаем бонусы за трюки, чтобы не мешали античиту
    db_handle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB);
    if(mysql_errno(db_handle) != 0) {
        print("[MySQL] Ошибка подключения к базе!");
    } else {
        print("[MySQL] Подключение установлено.");
        
        mysql_tquery(db_handle, "SET NAMES cp1251");
        mysql_tquery(db_handle, "CREATE TABLE IF NOT EXISTS players ( \
            id INT AUTO_INCREMENT PRIMARY KEY, \
            name VARCHAR(24) NOT NULL UNIQUE, \
            password VARCHAR(64) NOT NULL, \
            money INT DEFAULT 5000)");
    }
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i)) 
        {
            // Не показываем диалоги, а сразу грузим данные
            LoadPlayerDataSilent(i);
        }
    }
    // Запускаем глобальный таймер античита (раз в 1 секунду)
    SetTimer("AntiCheatTimer", 800, true);
    return 1;
}
public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!strcmp(cmdtext, "/mspawn", true))
    {
        new Float:x, Float:y, Float:z, Float:fa;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, fa);


        new mil_skins[] = {287, 191, 61};
        new rand_skin = mil_skins[random(sizeof(mil_skins))];


        new Float:sX = x + (3.0 * floatsin(-fa, degrees));
        new Float:sY = y + (3.0 * floatcos(-fa, degrees));

        // РЎРѕР·РґР°РµРј Р°РєС‚РµСЂР° (СЃРѕР»РґР°С‚Р°)
        new actorid = CreateActor(rand_skin, sX, sY, z, fa);
        
        if(actorid != INVALID_ACTOR_ID)
        {
            
            ApplyActorAnimation(actorid, "PED", "IDLE_ARMED", 4.1, 1, 1, 1, 1, 0);
            SendClientMessage(playerid, 0x00FF00FF, "[MILITARY] Создан актёр-солдат.");
        }
        return 1;
    }
    if (!strcmp(cmdtext, "/nitro", true))
    {
        // 1. Проверяем, в машине ли игрок
        new vehicleid = GetPlayerVehicleID(playerid);
        if(PlayerAdmin[playerid] < 1) // Проверка: если уровень меньше 1
        {
            return SendClientMessage(playerid, 0xFF0000FF, "Ошибка: Эта команда только для бояр (админов)!");
        }
        if (vehicleid == 0) {
            return SendClientMessage(playerid, 0xFF0000FF, "Вы должны быть в транспорте!");
        }

        // 2. Добавляем компонент нитро (1010 - x10)
        AddVehicleComponent(vehicleid, 1010);
        
        // 3. Сообщаем игроку
        SendClientMessage(playerid, 0x00FF00FF, "Нитро x10 установлено! Нажмите ЛКМ или Ctrl для активации.");
        return 1;
    }
    if (strfind(cmdtext, "/car", true) == 0) // Проверяем первые 4 символа
    {
        new modelid;
        if(PlayerAdmin[playerid] < 1) // Проверка: если уровень меньше 1
        {
            return SendClientMessage(playerid, 0xFF0000FF, "Ошибка: Эта команда только для бояр (админов)!");
        }
        // Проверяем, ввел ли игрок ID после пробела
        if (cmdtext[4] == ' ' && cmdtext[5] != '\0') 
        {
            modelid = strval(cmdtext[5]); // Превращаем текст "512" в число 512
        }
        else 
        {
            modelid = 400 + random(212); // Если ID не введен, берем рандом
        }

        // Валидация ID модели (в GTA SA модели машин от 400 до 611)
        if (modelid < 400 || modelid > 611) 
        {
            return SendClientMessage(playerid, 0xFF0000FF, "Ошибка: ID машины должен быть от 400 до 611!");
        }

        // 1. Удаляем старую машину
        if (PlayerVehicle[playerid] != INVALID_VEHICLE_ID)
        {
            DestroyVehicle(PlayerVehicle[playerid]);
        }

        // 2. Координаты
        new Float:x, Float:y, Float:z, Float:angle;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, angle);

        // 3. Создаем машину
        PlayerVehicle[playerid] = CreateVehicle(modelid, x, y, z + 1.0, angle, -1, -1, -1);

        // 4. Сажаем игрока и ставим НИТРО (раз ты спрашивал)
        PutPlayerInVehicle(playerid, PlayerVehicle[playerid], 0);
        AddVehicleComponent(PlayerVehicle[playerid], 1010); // x10 Nitro

        new string[64];
        format(string, sizeof(string), "Вы заспавнили транспорт ID: %d с нитро", modelid);
        SendClientMessage(playerid, -1, string);
        
        return 1;
    }
    if (!strcmp(cmdtext, "/die", true)){
        SetPlayerHealth(playerid, 0);
        SendClientMessage(playerid, -1, "Вы умерли.");
        return 1;
    }
    if (strcmp(cmdtext, "/gun", true, 4) == 0) // Проверяем первые 4 символа "/gun"
    {
        new weaponid;
        
        // Проверяем, ввел ли игрок что-то после "/gun "
        // cmdtext[4] — это символ сразу после "/gun", cmdtext[5] — начало аргумента
        if (cmdtext[4] == '\0' || cmdtext[5] == '\0') 
        {
            // --- РАНДОМ ---
            new random_guns[] = {24, 25, 30, 31, 34}; 
            weaponid = random_guns[random(sizeof(random_guns))];
            SendClientMessage(playerid, -1, "{FFFF00}Вы не указали ID. Выдано случайное оружие.");
        }
        else 
        {
            // --- КОНКРЕТНЫЙ ID ---
            weaponid = strval(cmdtext[5]); // Превращаем текст после пробела в число
            
            if (weaponid < 1 || weaponid > 46) 
            {
                return SendClientMessage(playerid, -1, "{FF0000}Ошибка: Неверный ID оружия (1-46).");
            }
            SendClientMessage(playerid, -1, "{00FF00}Оружие выдано.");
        }

        GivePlayerWeapon(playerid, weaponid, 100);
        return 1;
    }

    return 0;
}
public OnPlayerStateChange(playerid, PLAYER_STATE:newstate, PLAYER_STATE:oldstate)
{
    if(newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER)
    {
        new veh = GetPlayerVehicleID(playerid);
        new Float:vx, Float:vy, Float:vz;
        GetVehiclePos(veh, vx, vy, vz);

        // Считаем дистанцию от точки, где игрок был СЕКУНДУ НАЗАД (из нашего массива)
        // до текущей позиции машины
        new Float:d = floatsqroot(
            (vx - PosTable[playerid][0]) * (vx - PosTable[playerid][0]) + 
            (vy - PosTable[playerid][1]) * (vy - PosTable[playerid][1]) + 
            (vz - PosTable[playerid][2]) * (vz - PosTable[playerid][2])
        );

        // Если расстояние > 10 метров — это 100% чит или очень жесткий лаг
        if(d > 10.0 && IsLoggedIn[playerid])
        {
            new str[128];
           // format(str, sizeof(str), "{FF0000}[AC] {FFFFFF}Игрок %d кикнут за Teleport в авто (Расстояние: %.1f м)", playerid, d);
            SendClientMessageToAll(-1, str);
            if (PlayerAdmin[playerid] >= 1){
            SendClientMessage(playerid, 0x429645FF,"Ты админ, так что можна");

            } // Если игрок не админ, кикаем
            else{
            Kick(playerid);

            }
        }
    }
    return 1;
}
stock Float:GetVehicleMaxSpeed(modelid)
{
    // Здесь мы группируем модели. 
    // Это упрощенный пример, профи делают огромный switch по всем 212 моделям.
    if(modelid == 411 || modelid == 541) return 5; // Infernus, Bullet (быстрые)
    if(modelid == 447 || modelid == 469) return 4; // Вертолеты (Seasparrow, Sparrow)
    if(modelid == 520) return 10; // Самолеты (Hydra, Beagle)
    if(modelid == 511) return 0.5;
    if(modelid == 481 || modelid == 510) return 3; // Велосипеды
    
    return 7; // Стандарт для обычных колымаг
}
stock LoadPlayerDataSilent(playerid)
{
    new name[MAX_PLAYER_NAME], query[128];
    GetPlayerName(playerid, name, sizeof(name));

    mysql_format(db_handle, query, sizeof(query), "SELECT money FROM players WHERE name = '%e' LIMIT 1", name);
    // Вызываем OnLoginSilent вместо OnLogin
    mysql_tquery(db_handle, query, "OnLoginSilent", "i", playerid);
}
forward OnLoginSilent(playerid);
public OnLoginSilent(playerid)
{
    cache_get_value_name_int(0, "admin_level", PlayerAdmin[playerid]);
    if(cache_num_rows() > 0) 
    {
        new money;
        cache_get_value_name_int(0, "money", money);
        
        PlayerMoney[playerid] = money; 
        ResetPlayerMoney(playerid);
        GivePlayerMoney(playerid, money);
        
        IsLoggedIn[playerid] = true; 
    }
    return 1;
}
public OnPlayerGiveDamage(playerid, damagedid, Float:amount, WEAPON:weaponid, bodypart)
{
    new Float:hp;
    GetPlayerHealth(damagedid, hp); // Узнаем текущее HP жертвы
    SetPlayerHealth(damagedid, hp - amount); // Принудительно отнимаем столько, сколько нанес стрелок

    new string[128];
    format(string, sizeof(string), "Вы нанесли %.1f урона игроку ID %d", amount, damagedid);
    SendClientMessage(playerid, -1, string);
    return 1;
}
public OnPlayerSpawn(playerid)
{
    // Устанавливает игроку скин ID 10 при каждом спавне
    SetPlayerSkin(playerid, 10);
    
    return 1;
}
public OnPlayerConnect(playerid)
{
    IsLoggedIn[playerid] = false;
    PlayerMoney[playerid] = 0;

    new name[MAX_PLAYER_NAME], query[128];
    GetPlayerName(playerid, name, sizeof(name));

    mysql_format(db_handle, query, sizeof(query), "SELECT password FROM players WHERE name = '%e' LIMIT 1", name);
    mysql_tquery(db_handle, query, "CheckAccount", "i", playerid);
    return 1;
}

// --- Система регистрации/логина ---

public CheckAccount(playerid)
{
    if(cache_num_rows() > 0) {
        ShowPlayerDialog(playerid, DLG_LOGN, DIALOG_STYLE_PASSWORD, "Авторизация", "Введите пароль:", "Войти", "Выход");
    } else {
        ShowPlayerDialog(playerid, DLG_REG, DIALOG_STYLE_INPUT, "Регистрация", "Введите пароль для регистрации:", "Ок", "Выход");
    }
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(!response) return Kick(playerid);

    new name[MAX_PLAYER_NAME], query[256];
    GetPlayerName(playerid, name, sizeof(name));

    if(dialogid == DLG_REG) {
        if(strlen(inputtext) < 4) return ShowPlayerDialog(playerid, DLG_REG, DIALOG_STYLE_INPUT, "Ошибка", "Пароль слишком короткий!", "Ок", "Выход");
        
        mysql_format(db_handle, query, sizeof(query), 
            "INSERT INTO players (name, password, money) VALUES ('%e', '%e', 5000)", name, inputtext);
        mysql_tquery(db_handle, query);
        
        GivePlayerMoneyEx(playerid, 5000); // Выдаем начальные деньги через нашу функцию
        IsLoggedIn[playerid] = true;
        SendClientMessage(playerid, -1, "Вы успешно зарегистрированы! Выдано $5000.");
    }

    if(dialogid == DLG_LOGN) {
        mysql_format(db_handle, query, sizeof(query), 
            "SELECT * FROM players WHERE name = '%e' AND password = '%e' LIMIT 1", name, inputtext);
        mysql_tquery(db_handle, query, "OnLogin", "i", playerid);
    }
    return 1;
}
public OnPlayerUpdate(playerid)
{
    // Проверка на авторизацию, чтобы не кикало при спавне
    if(!IsLoggedIn[playerid]) return 1;

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    new currentTime = GetTickCount();
    new deltaTime = currentTime - PlayerTick[playerid];

    new Float:diffX = x - PosTable[playerid][0];
    new Float:diffY = y - PosTable[playerid][1];
    new Float:diffZ = z - PosTable[playerid][2];

    // 2. Считаем дистанцию (корень из суммы квадратов)
    // Квадрат всегда положителен, поэтому NaN исчезнет
    new Float:dist = floatsqroot((diffX * diffX) + (diffY * diffY) + (diffZ * diffZ));
    // Опрашиваем только если прошло хотя бы 50-100 мс, 
    // чтобы не перегружать проц слишком частыми вычислениями
    if(deltaTime >= 100) 
    {
        //new Float:dist = VectorSize(x - PlayerOldPos[playerid][0], y - PlayerOldPos[playerid][1], z - PlayerOldPos[playerid][2]);
        
        // Вычисляем скорость
        new Float:speed = (dist / deltaTime) * 1000.0;

        if(GetPlayerState(playerid) == PLAYER_STATE_ONFOOT)
        {
            // Теперь, когда опрос частый, порог 25.0 м/с — это очень надежно.
            // При обычном беге скорость будет около 8-12 м/с.
            // При рывке сквозь стену она прыгнет до 100+ м/с.
            if(speed > 30.0) 
            {
                // Это 100% рывок (телепорт)
                new str[128];
                format(str, sizeof(str), "[AC] Рывок! Скорость: %.2f м/с | Дист: %.2f", speed, dist);
                SendClientMessage(playerid, 0xFF0000FF, str);
                // Kick(playerid); 
            }
        }

        // Обновляем данные только после проверки
        PosTable[playerid][0] = x;
        PosTable[playerid][1] = y;
        PosTable[playerid][2] = z;
        PlayerTick[playerid] = currentTime;
    }
    return 1;
}
public OnLogin(playerid)
{
    GetPlayerPos(playerid, PosTable[playerid][0], PosTable[playerid][1], PosTable[playerid][2]);
    cache_get_value_name_int(0, "admin_level", PlayerAdmin[playerid]);
    if(cache_num_rows() > 0) {
        new money;
        cache_get_value_name_int(0, "money", money);
        
        PlayerMoney[playerid] = money; 
        ResetPlayerMoney(playerid);
        GivePlayerMoney(playerid, money);
        
        IsLoggedIn[playerid] = true;
        SendClientMessage(playerid, -1, "Добро пожаловать!");
    } else {
        ShowPlayerDialog(playerid, DLG_LOGN, DIALOG_STYLE_PASSWORD, "Ошибка", "Неверный пароль!", "Войти", "Выход");
    }
}

// --- Ядро Античита ---

// Функция для безопасной выдачи денег (используй её вместо стандартной!)
stock GivePlayerMoneyEx(playerid, amount)
{
    PlayerMoney[playerid] += amount; 
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerMoney[playerid]);
    
    // Сохранение в БД
    new query[128], name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    mysql_format(db_handle, query, sizeof(query), "UPDATE players SET money = %d WHERE name = '%e'", PlayerMoney[playerid], name);
    mysql_tquery(db_handle, query);
    return 1;
}

// Таймер, который проверяет всех игроков
public AntiCheatTimer()
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i) || !IsLoggedIn[i]) continue;

        new Float:x, Float:y, Float:z;
        GetPlayerPos(i, x, y, z);

        // Расчет дистанции (дист)
       // 1. Считаем разницу между текущей и прошлой позицией
        new Float:diffX = x - PosTable[i][0];
        new Float:diffY = y - PosTable[i][1];
        new Float:diffZ = z - PosTable[i][2];

    // 2. Считаем дистанцию (корень из суммы квадратов)
    // Квадрат всегда положителен, поэтому NaN исчезнет
        new Float:dist = floatsqroot((diffX * diffX) + (diffY * diffY) + (diffZ * diffZ));

        // Проверка скорости
        new veh = GetPlayerVehicleID(i);
        new Float:max_allowed = (veh != 0) ? GetVehicleMaxSpeed(GetVehicleModel(veh)) : 0.91;
        //SendClientMessage(i, -1, "[Debug AC] ID: %d | Dist: %.2f | Max: %.2f", i, dist, max_allowed * 100.0);
        if(dist > max_allowed) 
        {
            SendClientMessage(i, -1, "Игрок %d подозрение на SH. Дистанция: %.2f", i, dist);
            PosTable[i][0] = x;
            PosTable[i][1] = y;
            PosTable[i][2] = z;
            // Телепорт назад
            //SetPlayerPos(i, PosTable[i][0], PosTable[i][1], PosTable[i][2]);
        }
        else
        {
            // Обновляем таблицу позиций для следующего шага
            PosTable[i][0] = x;
            PosTable[i][1] = y;
            PosTable[i][2] = z;
        }
        // Если визуальные деньги не равны серверным
        if(GetPlayerMoney(i) != PlayerMoney[i])
        {
            // Откат
            if(GetPlayerMoney(i) > PlayerMoney[i]) {
                SendClientMessage(i, 0xFF6666FF, "[Anticheat] Чит на деньги обнаружен и заблокирован.");
            }
            ResetPlayerMoney(i);
            GivePlayerMoney(i, PlayerMoney[i]);
            
        }
        
    }
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    IsLoggedIn[playerid] = false;
    PlayerAdmin[playerid] = 0;
    return 1;
}
