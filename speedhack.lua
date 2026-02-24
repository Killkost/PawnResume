local vkeys = require 'vkeys'

-- Настройка силы ускорения (чем выше число, тем сильнее рывок)
local speed_multiplier = 0.5 

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FF00}[Cheat]{FFFFFF} SpeedHack загружен. Зажми {FFFF00}LSHIFT{FFFFFF} в машине.", -1)

    -- ВЕЧНЫЙ ЦИКЛ
    while true do
        wait(0) -- Даем игре работать

        -- Проверяем: игрок в машине и зажат Левый Шифт
        if isCharInAnyCar(PLAYER_PED) and isKeyDown(vkeys.VK_LSHIFT) then
            -- Получаем хендл машины, в которой сидит игрок
            local vehicle = storeCarCharIsInNoSave(PLAYER_PED)
            
            if doesVehicleExist(vehicle) then
                -- Получаем текущую скорость машины
                --local cur_speed = getCarForwardSpeed(vehicle)
                
                -- Устанавливаем новую скорость (текущая + надбавка)
                setCarForwardSpeed(vehicle, 100)
                
                -- Опционально: можно добавить визуальный эффект или звук
                -- printStringNow("~g~SPEEDHACK ACTIVE", 100)
            end
        end
    end
end