local vkeys = require 'vkeys'
local memory = require 'memory' -- Используем библиотеку memory

local active = false
local camYaw = 0.0
local camPitch = 0.0

-- Те самые "сырые" адреса дельты мыши
local ADDR_MOUSE_X = 0xB73660 
local ADDR_MOUSE_Y = 0xB73664 

function main()
    while not isSampAvailable() do wait(100) end
    
    sampRegisterChatCommand("go", function()
        active = not active
        -- Больше не мучаем CursorMode, работаем в скрытом режиме
        sampAddChatMessage(active and "{00FF00}MANUAL CAM ON" or "{FF0000}MANUAL CAM OFF", -1)
        
        -- При включении синхронизируем углы с текущей камерой
    end)
    
    while true do
        wait(0)
        if active then
            camYaw = memory.getfloat(0xB6F258)
            camPitch = memory.getfloat(0xB6F248)
        end
        if active then
            -- 1. Считываем ДЕЛЬТУ (на сколько сдвинулась мышь)
            local dx = memory.getfloat(ADDR_MOUSE_X)
            local dy = memory.getfloat(ADDR_MOUSE_Y)
            
            -- Читаем чувствительность игры
            local sens = memory.getfloat(0xB6EC1C) * 0.0015

            -- 2. Если есть движение
            if dx ~= 0 or dy ~= 0 then
                camYaw = camYaw - (dx * sens)
                camPitch = camPitch - (dy * sens)
                
                -- Лимиты (радианы: ~90 градусов)
                if camPitch > 1.5 then camPitch = 1.5 end
                if camPitch < -1.5 then camPitch = -1.5 end
                
                -- ВАЖНО: Записываем результат обратно в память камеры, 
                -- чтобы игра видела, куда мы повернули
                memory.setfloat(0xB6F258, camYaw, true)
                memory.setfloat(0xB6F248, camPitch, true)
            end

            -- 3. Считаем вектор для сервера
            local fX = math.cos(camPitch) * math.sin(camYaw)
            local fY = math.cos(camPitch) * math.cos(camYaw)
            local fZ = math.sin(camPitch)

            -- 4. Отправка RPC
            local bS = raknetNewBitStream()
            raknetBitStreamWriteFloat(bS, fX)
            raknetBitStreamWriteFloat(bS, fY)
            raknetBitStreamWriteFloat(bS, fZ)
            
            local zoom = isKeyDown(vkeys.VK_X) and 1 or 0
            raknetBitStreamWriteInt8(bS, zoom)

            raknetSendRpc(210, bS)
            raknetDeleteBitStream(bS)
        end
    end
end