local vkeys = require 'vkeys'

function main()
   -- while not isSampAvailable() do wait(0) end
    
    while true do
        wait(0)
        -- Активация на Shift + F2
        if isKeyDown(vkeys.VK_LSHIFT) then
            -- Вызываем функцию с ПРАВИЛЬНЫМИ именами
            changeClothes("suitjack", "suitjack", 0)
        end
    end
end

function changeClothes(texture, model, bodyPart)
    -- Загружаем компонент (в MoonLoader это requestClothes)
    requestClothes(texture, model, bodyPart)
    
    -- Ждем загрузки
    while not hasClothesLoaded(texture, model, bodyPart) do
        wait(0)
    end
    
    -- Надеваем
    addClothesComponent(playerPed, texture, model, bodyPart)
    
    -- Обновляем модель персонажа
    buildPlayerModel(playerPed)
    
    print("Clothes updated!")
end