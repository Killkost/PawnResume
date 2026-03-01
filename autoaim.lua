local vkeys = require 'vkeys'
local memory = require 'memory'

-- НАСТРОЙКИ
local aim_smooth = 4.0    -- Базовая плавность
local target_height = 0.5 -- Высота (голова)

local locked_target = nil

function main()
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage("{FFFF00}[ProAim]{FFFFFF} Синхронизация с FOV и экраном включена.", -1)

    while true do
        wait(0)

        if isKeyDown(vkeys.VK_RBUTTON) then
            if locked_target == nil or not isTargetValid(locked_target) then
                locked_target = findBestTargetOnScreen()
            end

            if locked_target then
                aimAtTarget(locked_target)
            end
        else
            locked_target = nil
        end
    end
end

-- Читаем FOV из памяти (0xB6F0E0)
function getDynamicFov()
    local fov = memory.getfloat(0xB6F0E0, true)
    if fov == nil or fov < 1 then return 70.0 end
    return fov
end

function isTargetValid(ped)
    if not doesCharExist(ped) or isCharDead(ped) then return false end
    local x, y, z = getCharCoordinates(ped)
    -- Проверяем, что convert3D вообще выдает координаты (враг на экране)
    local x2, y2 = convert3DCoordsToScreen(x, y, z + target_height)
    return x2 ~= nil and y2 ~= nil
end

function findBestTargetOnScreen()
    local peds = getAllChars()
    local sw, sh = getScreenResolution()
    local centerX, centerY = sw / 2, sh / 2
    local closest_ped = nil
    local min_dist = 10000

    for _, handle in ipairs(peds) do
        if handle ~= PLAYER_PED and not isCharDead(handle) then
            local x, y, z = getCharCoordinates(handle)
            local x2, y2 = convert3DCoordsToScreen(x, y, z + target_height)
            
            if x2 and y2 then
                local dist = math.sqrt((x2 - centerX)^2 + (y2 - centerY)^2)
                if dist < min_dist then
                    min_dist = dist
                    closest_ped = handle
                end
            end
        end
    end
    return closest_ped
end
function aimAtTarget(ped)
    local tx, ty, tz = getCharCoordinates(ped)
    local cx, cy, cz = getActiveCameraCoordinates()

    local dx, dy = tx - cx, ty - cy
    local dist2d = math.sqrt(dx * dx + dy * dy)

    -- 1. КОРРЕКЦИИ (базируются на твоих множителях)
    local h_corr = 0.0
    local w_corr = 0.0
    if dist2d > 1 then
        h_corr = (dist2d / 10.0) * 0.9 -- по вертикали (метры)
        w_corr = (dist2d / 10.0) * 0.5   -- по горизонтали (метры)
    end

    -- 2. МАГИЯ ВЕКТОРОВ: Находим направление "вбок"
    -- Нормализуем вектор направления (делим на дистанцию)
    local nx = dx / dist2d
    local ny = dy / dist2d
   -- sampAddChatMessage(string.format("DEBUG: dist=%.2f, h_corr=%.2f, w_corr=%.2f", dist2d, h_corr, w_corr), -1)
    --sampAddChatMessage(string.format("DEBUG: normX=%.2f, normY=%.2f", nx, ny), -1)
    -- Перпендикулярный вектор в 2D (поворот на 90 градусов):
    -- Если nx, ny это "вперед", то -ny, nx это "влево"
    local sideX = -ny
    local sideY = nx

    -- 3. ПРИМЕНЯЕМ СМЕЩЕНИЕ
    -- Теперь final_tx/ty смещаются ОТНОСИТЕЛЬНО линии взгляда
    local final_tx = tx + (sideX * w_corr)
    local final_ty = ty + (sideY * w_corr)
    local final_z  = tz - h_corr

    -- 4. РАСЧЕТ УГЛОВ (стандартный)
    local vx, vy, vz = final_tx - cx, final_ty - cy, final_z - cz
    
    local target_h = math.atan2(vy, vx) - (math.pi)
    local target_v = math.atan2(vz, dist2d)

    -- 5. ПЛАВНОСТЬ И ПРИМЕНЕНИЕ
    local current_fov = getDynamicFov()
    local final_smooth = aim_smooth * (70.0 / current_fov)

    local cur_h, cur_v = getCamRot()
    local diff_h = normalizeAngle(target_h - cur_h)
    local diff_v = target_v - cur_v

    setCamRot(cur_h + (diff_h / final_smooth), cur_v + (diff_v / final_smooth))
end

function getCamRot()
    return memory.getfloat(0xB6F258, true), memory.getfloat(0xB6F248, true)
end

function setCamRot(h, v)
    if v > 1.5 then v = 1.5 end
    if v < -1.5 then v = -1.5 end
    memory.setfloat(0xB6F258, h, true)
    memory.setfloat(0xB6F248, v, true)
end

function normalizeAngle(angle)
    while angle > math.pi do angle = angle - (math.pi * 2) end
    while angle < -math.pi do angle = angle + (math.pi * 2) end
    return angle
end
