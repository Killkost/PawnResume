local vkeys = require 'vkeys'


local speed_multiplier = 0.5 

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FF00}[Cheat]{FFFFFF} SpeedHack çàãðóæåí. Çàæìè {FFFF00}LSHIFT{FFFFFF} â ìàøèíå.", -1)


    while true do
        wait(0) 

        
        if isCharInAnyCar(PLAYER_PED) and isKeyDown(vkeys.VK_LSHIFT) then
            
            local vehicle = storeCarCharIsInNoSave(PLAYER_PED)
            
            if doesVehicleExist(vehicle) then

                setCarForwardSpeed(vehicle, 100)
                

            end
        end
    end

end
