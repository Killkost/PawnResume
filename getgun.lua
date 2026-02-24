local vkeys = require 'vkeys'

-- Таблица соответствия ID оружия к ID модели (DFF/TXD)
local weaponModels = {
    [1] = 331, [2] = 333, [3] = 334, [4] = 335, [5] = 336, [6] = 337, [7] = 338, [8] = 339, [9] = 341,
    [10] = 321, [11] = 322, [12] = 323, [13] = 324, [14] = 325, [15] = 326, [16] = 342, [17] = 343, [18] = 344,
    [22] = 346, [23] = 347, [24] = 348, [25] = 349, [26] = 350, [27] = 351, [28] = 352, [29] = 353, [30] = 355,
    [31] = 356, [32] = 372, [33] = 357, [34] = 358, [35] = 359, [36] = 360, [37] = 361, [38] = 362, [39] = 363,
    [41] = 365, [42] = 366, [43] = 367, [44] = 368, [45] = 369, [46] = 371
}

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand("getgun", function(arg)
        local id, ammo = arg:match("(%d+)%s+(%d+)")
        
        if id and ammo then
            id = tonumber(id)
            ammo = tonumber(ammo)
            
            local model = weaponModels[id]
            if model then
                -- Поток для загрузки модели, чтобы не вешать игру
                lua_thread.create(function()
                    requestModel(model)
                    loadAllModelsNow()
                    while not hasModelLoaded(model) do wait(0) end
                    
                    giveWeaponToChar(PLAYER_PED, id, ammo)
                    sampAddChatMessage("{00FF00}[Gun-Cheat]{FFFFFF} Вы выдали себе оружие ID: " .. id, -1)
                end)
            else
                sampAddChatMessage("{FF0000}[Ошибка]{FFFFFF} Неверный ID или модель оружия не найдена.", -1)
            end
        else
            sampAddChatMessage("{FFFF00}[Подсказка]{FFFFFF} Используйте: /getgun [ID] [Ammo]", -1)
        end
    end)

    wait(-1)
end