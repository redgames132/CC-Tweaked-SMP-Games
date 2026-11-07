local monitor = peripheral.find("monitor")

if not monitor then
    print("Could not find a connected monitor.")
    print("Place a monitor next to the computer.")
    return
end

-- 1.5 is a great scale for a 2x2 monitor grid
monitor.setTextScale(1.5) 
local w, h = monitor.getSize()

local score = 0
local playing = true

local function drawCentered(text, yPos, color)
    monitor.setTextColor(color or colors.white)
    local x = math.floor((w - #text) / 2) + 1
    monitor.setCursorPos(x, yPos)
    monitor.write(text)
end

while playing do
    monitor.setBackgroundColor(colors.blue)
    monitor.clear()
    
    -- Draw current score
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.white)
    monitor.write("Score: " .. score)
    
    -- Generate random target coordinates
    local tx = math.random(1, w)
    local ty = math.random(2, h)
    
    monitor.setCursorPos(tx, ty)
    monitor.setTextColor(colors.yellow)
    monitor.write("*")
    
    -- The timer gets faster as your score increases (minimum 0.4 seconds)
    local timeLimit = math.max(0.4, 2.0 - (score * 0.05))
    local timerID = os.startTimer(timeLimit)
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        -- Listen for player clicking the monitor
        if event == "monitor_touch" then
            local touchX, touchY = p2, p3
            
            -- Check if they clicked the exact coordinates of the target
            if touchX == tx and touchY == ty then
                score = score + 1
                os.cancelTimer(timerID)
                
                -- Visual feedback for a successful click
                monitor.setCursorPos(tx, ty)
                monitor.setTextColor(colors.lime)
                monitor.write("*")
                sleep(0.1)
                break
            end
            
        -- Listen for the timer running out
        elseif event == "timer" and p1 == timerID then
            playing = false
            break
        end
    end
end

-- Game Over Screen
monitor.setBackgroundColor(colors.black)
monitor.clear()
drawCentered("GAME OVER", math.floor(h/2) - 1, colors.red)
drawCentered("Score: " .. score, math.floor(h/2) + 1, colors.white)
