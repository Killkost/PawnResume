local vkeys = require 'vkeys'

function main()
    -- Ждем загрузки игры
    
    print("Camera script active. Press 'P' for camera.")

    while true do
        wait(0)
        -- Проверка нажатия клавиши P
        if isKeyJustPressed(vkeys.VK_X) then
            local modelId = 367 -- Прямой ID модели фотоаппарата (CAMERA)
            
            -- Загружаем модель в память
            requestModel(modelId)
            while not hasModelLoaded(modelId) do wait(0) end
            
            -- Выдаем фотик (оружие 43)
            giveWeaponToChar(PLAYER_PED, 43, 100)
            
            -- Помечаем, что модель больше не нужна (освобождаем память)
            markModelAsNoLongerNeeded(modelId)
            
            print("Done! Camera in inventory.")
        end
    end
end