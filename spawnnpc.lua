local vkeys = require 'vkeys'

-- Таблица состояний клавиш
local key_states = {}

-- Полный список ID женских скинов
local female_ids = {
    9, 10, 11, 12, 13, 31, 38, 39, 40, 41, 53, 54, 55, 56, 63, 64, 69, 75, 76, 77, 78, 79, 
    85, 87, 88, 89, 90, 91, 92, 93, 129, 130, 131, 138, 139, 140, 141, 145, 148, 150, 
    151, 152, 157, 169, 172, 178, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 
    201, 205, 207, 211, 214, 215, 216, 218, 219, 224, 225, 226, 231, 232, 233, 237, 
    238, 243, 244, 245, 246, 251, 256, 257, 258, 259, 263, 298, 306, 307, 308, 309
}

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    
    sampRegisterChatCommand("delpeds", deleteAllPeds)
    
    sampAddChatMessage("{FF69B4}[Spawner]{FFFFFF} Скрипт активен.", -1)
    sampAddChatMessage("{FFFF00}F3{FFFFFF} - спавн девушки, {FF0000}F4{FFFFFF} - очистка.", -1)

    while true do
        wait(0)
        
        -- Спавн одной девушки при нажатии F3
        if isKeyJustPressed(vkeys.VK_F3) then
            spawnRandomFemale()
        end

        -- Очистка при нажатии F4
        if isKeyJustPressed(vkeys.VK_F4) then
            deleteAllPeds()
        end
    end
end

function spawnRandomFemale()
    -- 1. Выбираем рандомный ID и модель оружия (M4 - 356)
    local modelId = female_ids[math.random(1, #female_ids)]
    local weaponModel = 356 
    
    -- 2. Загружаем модели (Критически важно для предотвращения краша 0x004D464E)
    lua_thread.create(function()
        requestModel(modelId)
        requestModel(weaponModel)
        loadAllModelsNow()
        
        while not hasModelLoaded(modelId) or not hasModelLoaded(weaponModel) do 
            wait(0) 
        end
        
        -- 3. Создаем персонажа
        local x, y, z = getCharCoordinates(PLAYER_PED)
        local ped = createChar(4, modelId, x + math.random(-3, 3), y + math.random(-3, 3), z)
        
        if doesCharExist(ped) then
            -- 4. Настраиваем: бессмертие + оружие
            --setCharProofs(ped, true, true, true, true, true) 
            giveWeaponToChar(ped, 31, 500) -- Выдаем M4
            
            sampAddChatMessage(string.format("{FF69B4}[Spawn]{FFFFFF} Создана бессмертная девушка ID: %d", ped), -1)
        end
    end)
end

function deleteAllPeds()
    local count = 0
    local peds = getAllChars()
    for _, handle in ipairs(peds) do
        -- Удаляем всех, кроме самого себя
        if handle ~= PLAYER_PED and doesCharExist(handle) then
            deleteChar(handle)
            count = count + 1
        end
    end
    if count > 0 then
        sampAddChatMessage(string.format("{FF0000}[Clear]{FFFFFF} Удалено %d ботов.", count), -1)
    end
end

-- Функция проверки одиночного нажатия
function isKeyJustPressed(key)
    if isKeyDown(key) then
        if not key_states[key] then
            key_states[key] = true
            return true
        end
    else
        key_states[key] = false
    end
    return false
end