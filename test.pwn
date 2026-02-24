#include <open.mp>

#if !defined DestroyObject
    #define DestroyObject(%0) Object_Destroy(%0)
#endif
#include <colandreas>
#include <streamer>
#include <Pawn.RakNet>
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

// Глобальная переменная для денег (для удобства)
new PlayerMoney[MAX_PLAYERS];
#define DRONE_MODEL         19107
#define UPDATE_RATE         20 
#define MAX_SPEED           0.2
#define ACCEL               0.8
#define FRICTION            0.97
#define DRONE_VISUAL_OFFSET  1.2
const RPC_MY_CUSTOM_EVENT = 150; 
new bool:InDroneMode[MAX_PLAYERS];
new DroneObj[MAX_PLAYERS];
new Float:DroneSpeed[MAX_PLAYERS][3];
new DroneTimer[MAX_PLAYERS];
new Text:Vignette;
new DroneActor[MAX_PLAYERS] = {INVALID_ACTOR_ID, ...}; // Для хранения актера
new Float:PlayerOldPos[MAX_PLAYERS][3];
new Float:PlayerCamVec[MAX_PLAYERS][3];
new RandomWeapons[] = {
    24, // Desert Eagle
    25, // Shotgun
    27, // Combat Shotgun
    29, // MP5
    30, // AK-47
    31, // M4
    33, // Country Rifle
    34, // Sniper Rifle
    35, // Rocket Launcher (РПГ)
    38  // Minigun (Миниган)
};
new Float:DroneFOV[MAX_PLAYERS] = {1.0, ...}; // Коэффициент приближения
new Float:LastCamVec[MAX_PLAYERS][3];
new GlobalDroneObj[MAX_PLAYERS] = {INVALID_OBJECT_ID, ...};
public OnFilterScriptInit()
{
    CA_Init(); 
    SetWeather(13);
    SetWorldTime(16, 0);
    
    Vignette = TextDrawCreate(-10.0, -10.0, "_");
    TextDrawLetterSize(Vignette, 0.0, 50.0);
    TextDrawTextSize(Vignette, 650.0, 0.0);
    TextDrawUseBox(Vignette, 1);
    TextDrawBoxColor(Vignette, 0xFF990033); 

    db_handle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB);
    if(mysql_errno(db_handle) != 0) {
        print("[MySQL] не удалось подключится samplogin!");
    } else {
        print("[MySQL] Успешное подключение к базе данных samplogin.");
                
        mysql_tquery(db_handle, "SET NAMES cp1251");
        mysql_tquery(db_handle, "SET CHARACTER SET cp1251");

        mysql_tquery(db_handle, "CREATE TABLE IF NOT EXISTS players ( \
            id INT AUTO_INCREMENT PRIMARY KEY, \
            name VARCHAR(24) NOT NULL UNIQUE, \
            password VARCHAR(64) NOT NULL, \
            money INT DEFAULT 5000)");
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
    new name[MAX_PLAYER_NAME], query[128];
    GetPlayerName(playerid, name, sizeof(name));

    mysql_format(db_handle, query, sizeof(query), "SELECT password FROM players WHERE name = '%e' LIMIT 1", name);
    mysql_tquery(db_handle, query, "CheckAccount", "i", playerid);
    
    InDroneMode[playerid] = false;
    return 1;
}

forward CheckAccount(playerid);
public CheckAccount(playerid)
{
    // Проверяем, нашлась ли запись в базе данных
    if(cache_num_rows() > 0) 
    {
        // Аккаунт найден — показываем диалог авторизации
        ShowPlayerDialog(playerid, DLG_LOGN, DIALOG_STYLE_PASSWORD, 
            "Авторизация", 
            "{FFFFFF}Этот ник зарегистрирован.\n{FFFFFF}Введите пароль:", 
            "Войти", "Выход");
    } 
    else 
    {
        // Аккаунт не найден — отправляем на регистрацию
        ShowPlayerDialog(playerid, DLG_REG, DIALOG_STYLE_INPUT, 
            "Регистрация", 
            "{FFFFFF}Добро пожаловать!\n{FFFFFF}Введите пароль для регистрации:", 
            "Далее", "Выход");
    }
    return 1;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    new name[MAX_PLAYER_NAME], query[256];
    GetPlayerName(playerid, name, sizeof(name));

    if(dialogid == DLG_REG) {
        if(!response || strlen(inputtext) < 4) return Kick(playerid);
        
        mysql_format(db_handle, query, sizeof(query), 
            "INSERT INTO players (name, password, money) VALUES ('%e', '%e', 5000)", name, inputtext);
        mysql_tquery(db_handle, query);
        
        PlayerMoney[playerid] = 5000;
        GivePlayerMoney(playerid, 5000);
        SendClientMessage(playerid, -1, "{00FF00}Регистрация успешна! Вы получили бонус $5000.");
        return 1;
    }

    if(dialogid == DLG_LOGN) {
        if(!response) return Kick(playerid);
        
        mysql_format(db_handle, query, sizeof(query), 
            "SELECT * FROM players WHERE name = '%e' AND password = '%e' LIMIT 1", name, inputtext);
        mysql_tquery(db_handle, query, "OnLogin", "i", playerid);
        return 1;
    }
    return 1;
}

forward OnLogin(playerid);
public OnLogin(playerid)
{
    if(cache_num_rows() > 0) 
    {
        new money;
        // Получаем значение из колонки "money" первой строки (индекс 0)
        cache_get_value_name_int(0, "money", money);
        
        // Записываем в переменную игрока и обновляем визуальный баланс
        PlayerMoney[playerid] = money;
        ResetPlayerMoney(playerid); // Убираем старые деньги
        GivePlayerMoney(playerid, money); // Выдаем актуальную сумму
        
        SendClientMessage(playerid, -1, "{00FF00}Вы успешно вошли в систему!");
        
    } 
    else 
    {
        // Если пароль не подошел, возвращаем диалог с ошибкой
        ShowPlayerDialog(playerid, DLG_LOGN, DIALOG_STYLE_PASSWORD, 
            "Авторизация", 
            "{FF0000}Ошибка! {FFFFFF}Неверный пароль. Попробуйте еще раз:", 
            "Войти", "Выход");
    }
    return 1;
}
stock SetDroneStatus(playerid, status)
{
    new BitStream:bs = BS_New();
    BS_WriteUint8(bs, status);
    
    // ПРАВИЛЬНЫЙ ПОРЯДОК: bs, playerid, rpcid, priority, reliability, orderingchannel
    PR_SendRPC(bs, playerid, 180, PR_HIGH_PRIORITY, PR_RELIABLE_ORDERED, 0);
    
    BS_Delete(bs);
    return 1;
}
public OnIncomingRPC(playerid, rpcid, BitStream:bs)
{
    if (rpcid == 210) 
    {
        new Float:vx, Float:vy, Float:vz;
        new key_x, key_z, scroll;

        BS_ReadValue(bs, 
            PR_FLOAT, vx, 
            PR_FLOAT, vy, 
            PR_FLOAT, vz,
            PR_INT8, key_x,
            PR_INT8, key_z,
            PR_INT8, scroll
        );

        
        PlayerCamVec[playerid][0] = vx;
        PlayerCamVec[playerid][1] = vy;
        PlayerCamVec[playerid][2] = vz;

        
        if(key_x == 1 || scroll == 1) // Приблизить
        {
            DroneFOV[playerid] -= 0.1;
            if(DroneFOV[playerid] < 0.1) DroneFOV[playerid] = 0.1;
        }
        else if(key_z == 1 || scroll == -1) // Отдалить
        {
            DroneFOV[playerid] += 0.1;
            if(DroneFOV[playerid] > 5.0) DroneFOV[playerid] = 5.0;
        }
        return 0; 
    }
    return 1;
}
public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!strcmp(cmdtext, "/fpv", true))
    {
        if(!InDroneMode[playerid]) StartDrone(playerid);
        else StopDrone(playerid);
        return 1;
    }
    if(!strcmp(cmdtext, "/spawninv", true))
    {
        new Float:x, Float:y, Float:z, Float:fa;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, fa);

        x += (2.0 * floatsin(-fa, degrees));
        y += (2.0 * floatcos(-fa, degrees));

         new objid = CreateObject(19107, x,y,z, 0.0, 0.0, 96.0); // Object will render at its default distance.
    

        if(objid == INVALID_OBJECT_ID) 
        {
            return SendClientMessage(playerid, 0xFF0000FF, "Не удалось создать объект.");
        }

       
        new msg[64];
        format(msg, sizeof(msg), "Создан объект ID: %d", objid);
        SendClientMessage(playerid, 0xFFFF00FF, msg);
        
        return 1;
    }
    if (strcmp(cmdtext, "/sendcustomrpc", true) == 0)
    {
        // 1. Create a new BitStream
        new BitStream:bs = BS_New();

        // 2. Write data to the BitStream (e.g., an integer and a string)
        new value = 42;
        new const message[] = "Hello from server!";
        BS_WriteValue(bs, PR_INT32, value);
        BS_WriteString(bs, message);

        // 3. Send the RPC to a specific player
        // PR_SendRPC(playerid, RPC_ID, BitStream, priority, reliability, orderingChannel, broadcast, includedTimestamp);
        // A common reliability is PR_RELIABLE_ORDERED (reliable and in order)
        PR_SendRPC(playerid, RPC_MY_CUSTOM_EVENT, bs, PR_HIGH_PRIORITY, PR_RELIABLE_ORDERED, 0);
        
        // 4. Destroy the BitStream after sending
        //BS_Delete(bs);

        SendClientMessage(playerid, 0x00FF00FF, "Custom RPC sent to you!");
        return 1;
    }
    if (!strcmp(cmdtext, "/e", true))
    {
        new Float:x, Float:y, Float:z, Float:ground_z;
        GetPlayerPos(playerid, x, y, z);

        // Стреляем лучом из текущей позиции игрока вниз на 1000 метров
        if (CA_RayCastLine(x, y, z, x, y, z - 20000.0, x, y, ground_z))
        {
        // Прибавляем 1.0 к высоте, чтобы ноги игрока не застряли в асфальте
            SetPlayerPos(playerid, x, y, ground_z + 1.0);
            SendClientMessage(playerid, 0x00FF00FF, "Позиция изменена, игрок не застрял в асфальте.");
        }
        else
        {
            SendClientMessage(playerid, 0xFF0000FF, "Луч не пересек землю (возможно, слишком высокий или низкий).");
        }
    
        return 1;
    }
    if (!strcmp(cmdtext, "/vspawn", true))
    {
        new Float:x, Float:y, Float:z, Float:fa;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, fa);

        // Массив ID военной техники
        new military_cars[] = {432, 433, 470, 520, 425, 601};
        new rand_model = military_cars[random(sizeof(military_cars))];

        // Спавним в 8 метрах перед игроком (военка крупнее, нужно больше места)
        new Float:spawnX = x + (8.0 * floatsin(-fa, degrees));
        new Float:spawnY = y + (8.0 * floatcos(-fa, degrees));

        // Для истребителя Hydra и Hunter добавим чуть больше высоты при спавне
        new vehicleid = CreateVehicle(rand_model, spawnX, spawnY, z + 1.5, fa, 0, 0, 300);
        
        if(vehicleid != INVALID_VEHICLE_ID)
        {
            // Устанавливаем военный цвет (тёмно-зелёный или камуфляж, где применимо)
            ChangeVehicleColor(vehicleid, 43, 0); 
            
            new str[64];
            format(str, sizeof(str), "{FF0000}[MILITARY] {FFFFFF}Создано военное транспортное средство: %d", rand_model);
            SendClientMessage(playerid, -1, str);
        }
        return 1;
    }
    if (!strcmp(cmdtext, "/mspawn", true))
    {
        new Float:x, Float:y, Float:z, Float:fa;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, fa);

        // ID скинов военных: 287 (армия), 191 (спецназ), 61 (пилот)
        new mil_skins[] = {287, 191, 61};
        new rand_skin = mil_skins[random(sizeof(mil_skins))];

        // Позиция в 3 метрах перед игроком
        new Float:sX = x + (3.0 * floatsin(-fa, degrees));
        new Float:sY = y + (3.0 * floatcos(-fa, degrees));

        // Создаем актера (солдата)
        new actorid = CreateActor(rand_skin, sX, sY, z, fa);
        
        if(actorid != INVALID_ACTOR_ID)
        {
            // Даем ему анимацию охраны (чтобы не стоял как столб)
            ApplyActorAnimation(actorid, "PED", "IDLE_ARMED", 4.1, 1, 1, 1, 1, 0);
            SendClientMessage(playerid, 0x00FF00FF, "[MILITARY] Создан военный актер.");
        }
        return 1;
    }
    if (!strcmp(cmdtext, "/rw", true)) // Команда /rw (Random Weapon)
    {
        // 1. Очищаем старое оружие (по желанию)
        ResetPlayerWeapons(playerid);

        // 2. Выбираем случайный индекс из массива
        new rand_index = random(sizeof(RandomWeapons));
        new weaponid = RandomWeapons[rand_index];

        // 3. Выдаем оружие и 500 патронов
        GivePlayerWeapon(playerid, weaponid, 500);

        // 4. Оповещение
        new weapon_name[32], str[64];
        GetWeaponName(weaponid, weapon_name, sizeof(weapon_name));
        format(str, sizeof(str), "{FFFF00}[RANDOM WEAPON] {FFFFFF}Выдано оружие: {00FF00}%s", weapon_name);
        SendClientMessage(playerid, -1, str);
        
        return 1;
    }
    return 0;
}

StartDrone(playerid)
{
    new Float:x, Float:y, Float:z, Float:fa;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, fa);
    
    SetDroneStatus(playerid, 1);
    PlayerOldPos[playerid][0] = x;
    PlayerOldPos[playerid][1] = y;
    PlayerOldPos[playerid][2] = z;

    
    new skin = GetPlayerSkin(playerid);
    DroneActor[playerid] = CreateActor(skin, x, y, z, fa);
    ApplyActorAnimation(DroneActor[playerid], "PLAYIDLES", "IDLE_STANCE", 4.1, 0, 0, 0, 1, 0);

    DroneObj[playerid] = CreatePlayerObject(playerid, 19300, x, y, z + 3.0, 0.0, 0.0, 0.0);
    SetPlayerObjectMaterial(playerid, DroneObj[playerid], 0, 10752, "none", "none", 0x00000000);
    SetPlayerObjectNoCameraCol(playerid, DroneObj[playerid]);

    
    new Float:vx, Float:vy, Float:vz;
    GetPlayerCameraFrontVector(playerid, vx, vy, vz); 

    GlobalDroneObj[playerid] = CreateObject(DRONE_MODEL, 
    x - (vx * DRONE_VISUAL_OFFSET), 
    y - (vy * DRONE_VISUAL_OFFSET), 
    z + 3.0 - (vz * DRONE_VISUAL_OFFSET), 
    0.0, 0.0, fa, 300.0);
    DroneSpeed[playerid][0] = 0.0;
    DroneSpeed[playerid][1] = 0.0;
    DroneSpeed[playerid][2] = 0.0;

    InDroneMode[playerid] = true;
    DroneTimer[playerid] = SetTimerEx("DroneUpdate", UPDATE_RATE, true, "i", playerid);
    return 1;
}

StopDrone(playerid)
{
    KillTimer(DroneTimer[playerid]);
    
    
    if(DroneObj[playerid] != INVALID_OBJECT_ID) {
        DestroyPlayerObject(playerid, DroneObj[playerid]);
        DroneObj[playerid] = INVALID_OBJECT_ID;
    }
    

    if(GlobalDroneObj[playerid] != INVALID_OBJECT_ID) {
        DestroyObject(GlobalDroneObj[playerid]);
        GlobalDroneObj[playerid] = INVALID_OBJECT_ID;
    }

    SetDroneStatus(playerid, 0);
    
    if(DroneActor[playerid] != INVALID_ACTOR_ID) {
        DestroyActor(DroneActor[playerid]);
        DroneActor[playerid] = INVALID_ACTOR_ID;
    }

    SetPlayerVirtualWorld(playerid, 0); 
    SetPlayerPos(playerid, PlayerOldPos[playerid][0], PlayerOldPos[playerid][1], PlayerOldPos[playerid][2]);
    SetPlayerColor(playerid, -1);
    TogglePlayerControllable(playerid, true);
    SetCameraBehindPlayer(playerid);
    
    InDroneMode[playerid] = false;
}

public DroneUpdate(playerid)
{
    if(!InDroneMode[playerid]) return;

    new Float:fX, Float:fY, Float:fZ;
    GetPlayerObjectPos(playerid, DroneObj[playerid], fX, fY, fZ);
    
    new Float:fVX = PlayerCamVec[playerid][0];
    new Float:fVY = PlayerCamVec[playerid][1];
    new Float:fVZ = PlayerCamVec[playerid][2];

    new keys, ud, lr;
    GetPlayerKeys(playerid, keys, ud, lr);


    new Float:targetX = 0.0, Float:targetY = 0.0, Float:targetZ = 0.0;
    
    // Получаем угол поворота камеры по горизонтали (в градусах)
    // atan2 возвращает угол в градусах в большинстве реализаций SAMP
    new Float:angle = atan2(fVY, fVX); 

    // Вперед / Назад (W / S)
    if(ud < 0) { // W (Вперед)
        targetX += floatcos(angle, degrees);
        targetY += floatsin(angle, degrees);
    }
    else if(ud > 0) { // S (Назад)
        targetX -= floatcos(angle, degrees);
        targetY -= floatsin(angle, degrees);
    }

    // Влево / Вправо (A / D)
    if(lr < 0) { // A (Влево)
        // Смещаем угол на 90 градусов для движения боком
        targetX += floatcos(angle - 90.0, degrees);
        targetY += floatsin(angle - 90.0, degrees);
    }
    else if(lr > 0) { // D (Вправо)
        targetX += floatcos(angle + 90.0, degrees);
        targetY += floatsin(angle + 90.0, degrees);
    }

    // Высота (Jump / Crouch)
    if (keys & KEY_JUMP) targetZ = 1.0;
    else if (keys & KEY_CROUCH) targetZ = -1.0;
    if (keys & KEY_JUMP) targetZ = 1.0;
    else if (keys & KEY_CROUCH) targetZ = -1.0;

    for(new i = 0; i < 3; i++) {
        new Float:t = (i == 0) ? targetX : (i == 1 ? targetY : targetZ);
        if(floatabs(t) > 0.01) DroneSpeed[playerid][i] = (DroneSpeed[playerid][i] * (1.0 - ACCEL)) + (t * MAX_SPEED * ACCEL);
        else DroneSpeed[playerid][i] *= FRICTION;
    }

    new Float:nextX = fX + DroneSpeed[playerid][0];
    new Float:nextY = fY + DroneSpeed[playerid][1];
    new Float:nextZ = fZ + DroneSpeed[playerid][2];
    new Float:rotZ = atan2(fVY, fVX) - 90.0;

    MovePlayerObject(playerid, DroneObj[playerid], nextX, nextY, nextZ, 120.0);
    SetPlayerObjectRot(playerid, DroneObj[playerid], 0.0, 0.0, rotZ);

    if(GlobalDroneObj[playerid] != INVALID_OBJECT_ID) 
    {
        new Float:visualX = nextX - (fVX * DRONE_VISUAL_OFFSET);
        new Float:visualY = nextY - (fVY * DRONE_VISUAL_OFFSET);
        new Float:visualZ = nextZ - (fVZ * DRONE_VISUAL_OFFSET) - 0.2;

        MoveObject(GlobalDroneObj[playerid], visualX, visualY, visualZ, 120.0);
        SetObjectRot(GlobalDroneObj[playerid], 0.0, 0.0, rotZ);
    }

    
    InterpolateCameraPos(playerid, fX, fY, fZ, nextX, nextY, nextZ, 25, CAMERA_MOVE);
    InterpolateCameraLookAt(playerid, 
        fX + LastCamVec[playerid][0], fY + LastCamVec[playerid][1], fZ + LastCamVec[playerid][2], 
        nextX + fVX, nextY + fVY, nextZ + fVZ, 25, CAMERA_MOVE);

    LastCamVec[playerid][0] = fVX;
    LastCamVec[playerid][1] = fVY;
    LastCamVec[playerid][2] = fVZ;

    
    SetPlayerPos(playerid, nextX, nextY, 5000.0); 
    Streamer_UpdateEx(playerid, nextX, nextY, nextZ);
}
public OnPlayerKeyStateChange(playerid, KEY:newkeys, KEY:oldkeys)
{
    if(InDroneMode[playerid] && (newkeys & KEY_FIRE))
    {
        new Float:fX, Float:fY, Float:fZ, Float:hX, Float:hY, Float:hZ;
        
        
        GetPlayerObjectPos(playerid, DroneObj[playerid], fX, fY, fZ);
        
        if(CA_RayCastLine(fX, fY, fZ, fX, fY, fZ - 200.0, hX, hY, hZ))
        {
            // 1. Создаем глобальный объект (виден всем)
            // Аргументы: Модель, X, Y, Z, rX, rY, rZ, DrawDistance
            new drop_obj = CreateObject(342, fX, fY, fZ - 0.5, 0.0, 0.0, 0.0, 300.0);
            
            if(drop_obj != INVALID_OBJECT_ID)
            {
                // Чтобы камера дрона не "билась" об падающую гранату
                SetObjectNoCameraCollision(drop_obj); 
                
                // 2. Двигаем объект (без playerid!)
                // Аргументы: ID объекта, X, Y, Z, Скорость
                MoveObject(drop_obj, hX, hY, hZ, 25.0);
                
                PlayerPlaySound(playerid, 1137, fX, fY, fZ);
            }
        }
    }
    return 1;
}

// ВНИМАНИЕ: Для глобальных объектов используется OnObjectMoved (без Player)
public OnObjectMoved(objectid)
{
    if(GetObjectModel(objectid) == 342) 
    {
        new Float:x, Float:y, Float:z;
        GetObjectPos(objectid, x, y, z);
        
        CreateExplosion(x, y, z, 12, 10.0);
        
        // --- 1. УРОН ТРАНСПОРТУ ---
        new Float:vRange = 12.0; 
        for(new v = 1, j = GetVehiclePoolSize(); v <= j; v++)
        {
            new Float:vx, Float:vy, Float:vz;
            if(GetVehiclePos(v, vx, vy, vz))
            {
                new Float:vDist = VectorSize(x - vx, y - vy, z - vz); // Быстрая функция дистанции
                if(vDist <= vRange)
                {
                    new Float:vHealth;
                    GetVehicleHealth(v, vHealth);
                    new Float:damage = 800.0 * (1.0 - (vDist / vRange));
                    
                    if(vHealth - damage <= 250.0) SetVehicleHealth(v, 249.0);
                    else SetVehicleHealth(v, vHealth - damage);
                }
            }
        }

        // --- 2. УРОН АКТЕРАМ (СОЛДАТАМ) ---
        new Float:aRange = 8.0; 
        for(new a = 0, m = GetActorPoolSize(); a < m; a++)
        {
            if(!IsValidActor(a)) continue;

            new Float:ax, Float:ay, Float:az;
            GetActorPos(a, ax, ay, az);
            new Float:aDist = VectorSize(x - ax, y - ay, z - az);

            if(aDist <= aRange)
            {
                new Float:aHealth;
                GetActorHealth(a, aHealth);
                
                // Рассчитываем урон для солдата (минимум 100 HP вблизи)
                new Float:aDamage = 150.0 * (1.0 - (aDist / aRange));
                new Float:newHealth = aHealth - aDamage;

                if(newHealth <= 0.0)
                {
                    SetActorHealth(a, 0.0);
                    // Проигрываем анимацию смерти (лежит на спине)
                    ApplyActorAnimation(a, "PED", "KO_skid_back", 4.1, 0, 1, 1, 1, 0);
                    // Удаляем через 5 секунд, чтобы не засорять карту
                    SetTimerEx("DestroyDeadActor", 5000, false, "i", a);
                }
                else
                {
                    SetActorHealth(a, newHealth);
                }
            }
        }
        DestroyObject(objectid);
    }
    return 1;
}

// Добавь этот сток в конец скрипта для удаления тел
forward DestroyDeadActor(actorid);
public DestroyDeadActor(actorid)
{
    if(IsValidActor(actorid))
    {
        new Float:health;
        GetActorHealth(actorid, health);
        if(health <= 0.0) DestroyActor(actorid);
    }
}
public OnPlayerDisconnect(playerid, reason)
{
    if(InDroneMode[playerid]) StopDrone(playerid);
    
    // Сохранение денег
    new name[MAX_PLAYER_NAME], query[128];
    GetPlayerName(playerid, name, sizeof(name));
    
    mysql_format(db_handle, query, sizeof(query), 
        "UPDATE players SET money = %d WHERE name = '%e'", GetPlayerMoney(playerid), name);
    mysql_tquery(db_handle, query);
    
    return 1;
}