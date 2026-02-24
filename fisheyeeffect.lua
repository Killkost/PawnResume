
script_name('FishEyeEffect')
script_version_number(002)
script_author('Receiver & Nasif')
script_url('https://vk.com/supreme1696')

local imgui = require 'mimgui'
local new = imgui.new
local sizeX, sizeY = getScreenResolution()

local enabled = false
local locked = false
local X = new.float(150.0)

local showFOVMenu = new.bool()

local newFrame = imgui.OnFrame(
	function() return showFOVMenu[0] end,
    function(player)	
		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(220, 100), imgui.Cond.FirstUseEver)
		imgui.Begin('FOV Editor', showConfigMenu)
		imgui.SliderFloat("FOV", X, 0.0, 150.0)
		imgui.End() 
	end
)

function main()
	repeat wait(0) until isSampAvailable()
	
	--[[_______________COMMANDS_______________]]--
	sampRegisterChatCommand('camm', function()
		enabled = not enabled
	end)
	
	sampRegisterChatCommand('fee_help', function()
		sampShowDialog(1337, string.format('{CD5C5C}%s', thisScript().name), string.format('{ffffff}˜˜˜˜˜˜˜˜: {CD5C5C}[%s]\n{ffffff}˜˜˜˜˜˜˜˜˜˜˜˜˜˜: {CD5C5C}[%s]\n\n{ffffff}˜˜˜˜˜˜˜:\n{CD5C5C}/camm {ffffff}˜ ˜˜˜˜˜˜˜˜/˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜\n{CD5C5C}/fee_help {ffffff}˜ ˜˜˜˜˜˜˜˜˜ ˜˜˜ ˜˜˜˜', thisScript().authors[1], thisScript().url), '˜˜˜˜˜˜˜', '', 0)
	end)

	sampRegisterChatCommand('fov', function()
		showFOVMenu[0] = not showFOVMenu[0]
	end)

	--[[_______________COMMANDS_______________]]--
	
	msg(string.format('/camm: {CD5C5C}[%s]', thisScript().authors[1]))
	while true do
		wait(0)
		if enabled then
			if isCurrentCharWeapon(PLAYER_PED, 34) and isKeyDown(2) then
				if not locked then 
					cameraSetLerpFov(90.0, 30.0, 990, 1)
					locked = true
				end
			else
				cameraSetLerpFov(math.ceil(X[0]), 150.0, 300, 1)
				locked = false
			end
		end
	end
end

function msg(text)
	sampAddChatMessage(string.format('[%s] {ffffff}%s', thisScript().name, text), 0xFFCD5C5C)
end