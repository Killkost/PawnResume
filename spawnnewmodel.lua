local vkeys = require 'vkeys'

function main()
    while true do
        wait(0)
        

        if isKeyJustPressed(vkeys.VK_K) then
            setCharCoordinates(PLAYER_PED, 0.0, 0.0, 5.0) 
            if isModelAvailable(5500) then
                print("Model 5500 is AVAILABLE in game files!")
            else
                print("Error: Model 15500 NOT FOUND.")
            end
            print("Teleported to 0, 0, 5")
        end


        if isKeyJustPressed(vkeys.VK_L) then
            lua_thread.create(function() 
                local myModelId = 19600
                
                print("Requesting model...")
                requestModel(myModelId)
                while not hasModelLoaded(myModelId) do 
                    wait(0) 
                end
                

                if hasModelLoaded(myModelId) then
                    local x, y, z = getCharCoordinates(PLAYER_PED)

                    local myObj = createObject(myModelId, x + 2.0, y, z)
                    
                    if doesObjectExist(myObj) then
                        print("Object spawned SUCCESSFULLY!")

                        freezeObjectPosition(myObj, true)
                        markModelAsNoLongerNeeded(myModelId)
                    else
                        print("Spawn FAILED! Object does not exist after create.")
                    end
                end
            end)
        end
    end

end
