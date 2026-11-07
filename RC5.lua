local monitor = peripheral.find("monitor")
local speaker = peripheral.find("speaker")

if not monitor then
    print("Could not find a connected monitor.")
    return
end

if not speaker then
    print("Warning: No speaker found. The game will be silent.")
    print("Place a CC:Tweaked Speaker next to the computer for audio!")
end

monitor.setTextScale(1.5) 
local w, h = monitor.getSize()
local highScore = 0

local function playSound(soundName, pitch, volume)
    if speaker then
        speaker.playSound(soundName, volume or 3.0, pitch or 1.0)
    end
end

local function drawCentered(text, yPos, txtColor, bgColor)
    monitor.setTextColor(txtColor or colors.white)
    monitor.setBackgroundColor(bgColor or colors.black)
    local x = math.floor((w - #text) / 2) + 1
    monitor.setCursorPos(x, yPos)
    monitor.write(text)
end

local function clearScreen(color)
    monitor.setBackgroundColor(color or colors.black)
    monitor.clear()
end

local function countdown()
    for i = 3, 1, -1 do
        clearScreen(colors.black)
        drawCentered(" GET READY ", math.floor(h/2) - 1, colors.yellow)
        drawCentered(" " .. tostring(i) .. " ", math.floor(h/2) + 1, colors.white, colors.gray)
        playSound("block.note_block.hat", 1.0) -- Tick sound for countdown
        sleep(0.5)
    end
    playSound("block.note_block.pling", 1.5) -- Higher pitch for "GO!"
end

local function playGame()
    local score = 0
    local lives = 3
    local playing = true
    local difficultyScore = 0 
    
    countdown()

    while playing do
        clearScreen(colors.black)
        
        -- Draw Top Status Bar
        monitor.setCursorPos(1, 1)
        monitor.setBackgroundColor(colors.blue)
        monitor.setTextColor(colors.white)
        local header = " S:" .. score .. "  L:" .. lives
        header = header .. string.rep(" ", math.max(0, w - #header))
        monitor.write(header)
        
        -- Generate random target coordinates (avoid row 1)
        local tx = math.random(1, w)
        local ty = math.random(2, h)
        
        -- 15% chance for a Golden Target
        local isGold = math.random(1, 100) <= 15
        local targetColor = isGold and colors.yellow or colors.red
        local targetChar = isGold and "$" or "X"
        
        monitor.setCursorPos(tx, ty)
        monitor.setBackgroundColor(targetColor)
        monitor.setTextColor(colors.black)
        monitor.write(targetChar)
        
        -- Timer gets faster based on difficulty score
        local timeLimit = math.max(0.35, 2.0 - (difficultyScore * 0.05))
        local timerID = os.startTimer(timeLimit)
        
        while true do
            local event, p1, p2, p3 = os.pullEvent()
            
            if event == "monitor_touch" then
                local touchX, touchY = p2, p3
                
                -- Ignore clicks on the top status bar
                if touchY == 1 then
                    -- Do nothing
                elseif touchX == tx and touchY == ty then
                    os.cancelTimer(timerID)
                    
                    if isGold then
                        score = score + 3
                        difficultyScore = math.max(0, difficultyScore - 2)
                        playSound("entity.experience_orb.pickup", 1.5) -- Golden hit sound
                    else
                        score = score + 1
                        difficultyScore = difficultyScore + 1
                        playSound("block.note_block.bell", 1.0) -- Normal hit sound
                    end
                    
                    -- Visual hit feedback
                    monitor.setCursorPos(tx, ty)
                    monitor.setBackgroundColor(colors.lime)
                    monitor.write(targetChar)
                    sleep(0.1)
                    break
                    
                -- Misclick
                else
                    os.cancelTimer(timerID)
                    lives = lives - 1
                    playSound("block.note_block.bass", 0.5) -- Error buzz
                    
                    clearScreen(colors.red)
                    sleep(0.15)
                    
                    if lives <= 0 then playing = false end
                    break
                end
                
            -- Timer runs out
            elseif event == "timer" and p1 == timerID then
                lives = lives - 1
                playSound("block.note_block.bass", 0.5) -- Error buzz
                
                clearScreen(colors.red)
                sleep(0.15)
                
                if lives <= 0 then playing = false end
                break
            end
        end
    end
    
    return score
end

-- Main Application Loop
while true do
    local finalScore = playGame()
    
    if finalScore > highScore then
        highScore = finalScore
    end
    
    playSound("entity.villager.no", 1.0) -- Game over sad noise
    
    -- Game Over Screen
    clearScreen(colors.black)
    drawCentered(" GAME OVER ", math.floor(h/2) - 2, colors.white, colors.red)
    drawCentered("Score: " .. finalScore, math.floor(h/2), colors.white)
    drawCentered("Best: " .. highScore, math.floor(h/2) + 1, colors.yellow)
    
    -- Draw Restart Button
    local btnY = h - 1
    local btnText = " [ RESTART ] "
    drawCentered(btnText, btnY, colors.black, colors.green)
    
    while true do
        local event, p1, p2, p3 = os.pullEvent("monitor_touch")
        local touchX, touchY = p2, p3
        
        local btnStartX = math.floor((w - #btnText) / 2) + 1
        local btnEndX = btnStartX + #btnText - 1
        
        if touchY == btnY and touchX >= btnStartX and touchX <= btnEndX then
            playSound("block.note_block.pling", 1.0) -- Button click sound
            drawCentered(btnText, btnY, colors.black, colors.lime)
            sleep(0.2)
            break
        end
    end
end
