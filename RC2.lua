local monitor = peripheral.find("monitor")

if not monitor then
    print("Could not find a connected monitor.")
    return
end

monitor.setTextScale(1.5) 
local w, h = monitor.getSize()
local highScore = 0

-- Helper function to draw text perfectly centered
local function drawCentered(text, yPos, txtColor, bgColor)
    monitor.setTextColor(txtColor or colors.white)
    monitor.setBackgroundColor(bgColor or colors.black)
    local x = math.floor((w - #text) / 2) + 1
    monitor.setCursorPos(x, yPos)
    monitor.write(text)
end

-- Helper to clear the screen with a specific color
local function clearScreen(color)
    monitor.setBackgroundColor(color or colors.black)
    monitor.clear()
end

local function countdown()
    for i = 3, 1, -1 do
        clearScreen(colors.black)
        drawCentered(" GET READY ", math.floor(h/2) - 1, colors.yellow)
        drawCentered(" " .. tostring(i) .. " ", math.floor(h/2) + 1, colors.white, colors.gray)
        sleep(0.5)
    end
end

local function playGame()
    local score = 0
    local playing = true
    
    countdown()

    while playing do
        clearScreen(colors.black)
        
        -- Draw Top Status Bar
        monitor.setCursorPos(1, 1)
        monitor.setBackgroundColor(colors.blue)
        monitor.setTextColor(colors.white)
        local header = " Score: " .. score
        header = header .. string.rep(" ", math.max(0, w - #header))
        monitor.write(header)
        
        -- Generate random target coordinates (avoid row 1 to keep header clean)
        local tx = math.random(1, w)
        local ty = math.random(2, h)
        
        monitor.setCursorPos(tx, ty)
        monitor.setBackgroundColor(colors.red)
        monitor.setTextColor(colors.white)
        monitor.write("X")
        
        -- Timer gets faster as score increases
        local timeLimit = math.max(0.35, 2.0 - (score * 0.08))
        local timerID = os.startTimer(timeLimit)
        
        while true do
            local event, p1, p2, p3 = os.pullEvent()
            
            if event == "monitor_touch" then
                local touchX, touchY = p2, p3
                
                -- Check if they clicked the exact target
                if touchX == tx and touchY == ty then
                    score = score + 1
                    os.cancelTimer(timerID)
                    
                    -- Visual hit feedback
                    monitor.setCursorPos(tx, ty)
                    monitor.setBackgroundColor(colors.lime)
                    monitor.write("X")
                    sleep(0.1)
                    break
                end
                
            elseif event == "timer" and p1 == timerID then
                playing = false
                break
            end
        end
    end
    
    return score
end

-- Main Application Loop
while true do
    local finalScore = playGame()
    
    -- Update High Score
    if finalScore > highScore then
        highScore = finalScore
    end
    
    -- Game Over Screen
    clearScreen(colors.black)
    drawCentered(" GAME OVER ", math.floor(h/2) - 2, colors.white, colors.red)
    drawCentered("Score: " .. finalScore, math.floor(h/2), colors.white)
    drawCentered("Best: " .. highScore, math.floor(h/2) + 1, colors.yellow)
    
    -- Draw Restart Button
    local btnY = h - 1
    local btnText = " [ RESTART ] "
    drawCentered(btnText, btnY, colors.white, colors.green)
    
    -- Wait for the player to click the restart button
    while true do
        local event, p1, p2, p3 = os.pullEvent("monitor_touch")
        local touchX, touchY = p2, p3
        
        -- Calculate the button's boundaries
        local btnStartX = math.floor((w - #btnText) / 2) + 1
        local btnEndX = btnStartX + #btnText - 1
        
        -- Check if touch was on the button row AND within the text width
        if touchY == btnY and touchX >= btnStartX and touchX <= btnEndX then
            -- Visual click feedback
            drawCentered(btnText, btnY, colors.white, colors.lime)
            sleep(0.2)
            break -- Breaks the "wait for click" loop and restarts the game
        end
    end
end
