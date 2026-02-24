-- Библиотека vkeys не нужна для команд, но пусть будет для будущего
local vkeys = require 'vkeys'

function main()
    -- Проверка на наличие SAMP и SAMPFUNCS
    if not isSampLoaded() or not isSampfuncsLoaded() then 
        return -- Если их нет, скрипт просто выключится (терминируется)
    end

    -- Ждем, пока заспавнимся (чтобы команда точно зарегистрировалась в чате)
    while not isSampAvailable() do 
        wait(100) 
    end

    -- РЕГИСТРАЦИЯ КОМАНДЫ
    -- Важно: команда регистрируется ОДИН РАЗ вне цикла
    sampRegisterChatCommand("addmoney", function(arg)
        local amount = tonumber(arg)
        if amount then
            givePlayerMoney(PLAYER_HANDLE, amount)
            sampAddChatMessage("{00FF00}[Money]{FFFFFF} Добавлено: " .. amount, -1)
        else
            sampAddChatMessage("{FF0000}[Ошибка]{FFFFFF} Введите: /addmoney [число]", -1)
        end
    end)

    sampAddChatMessage("{00FF00}[Loader]{FFFFFF} Скрипт успешно запущен. Команда /addmoney готова!", -1)

    -- ВЕЧНЫЙ ЦИКЛ
    -- Если скрипт дошел сюда, он будет работать вечно
    while true do
        wait(0) -- Даем игре дышать
        
        -- Пример проверки клавиши (не обязательно для команд)
        if isKeyDown(vkeys.VK_F2) then
            -- Тут мог бы быть какой-то код
        end
    end
end