local monitor = peripheral.find("monitor")
local speaker = peripheral.find("speaker")

if not monitor then
    print("Could not find a connected monitor.")
    return
end

monitor.setTextScale(1.0) 
local w, h = monitor.getSize()
local highScore = 0
local floorY = h -- The bottom row is now the ground

math.randomseed(os.epoch("utc"))

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

local function drawMenu()
    clearScreen(colors.lightBlue)
    
    -- Draw Ground
    monitor.setBackgroundColor(colors.green)
    monitor.setCursorPos(1, floorY)
    monitor.write(string.rep(" ", w))
    
    drawCentered(" FLAPPY PIXEL ", math.floor(h/2) - 2, colors.yellow, colors.lightBlue)
    drawCentered(" Best Score: " .. highScore .. " ", math.floor(h/2), colors.white, colors.lightBlue)
    
    local btnY = math.floor(h/2) + 2
    local btnText = " [ PLAY ] "
    drawCentered(btnText, btnY, colors.white, colors.lime)
    
    while true do
        local event, p1, p2, p3 = os.pullEvent("monitor_touch")
        local touchX, touchY = p2, p3
        
        local btnStartX = math.floor((w - #btnText) / 2) + 1
        local btnEndX = btnStartX + #btnText - 1
        
        if touchY == btnY and touchX >= btnStartX and touchX <= btnEndX then
            playSound("block.note_block.pling", 1.5)
            drawCentered(btnText, btnY, colors.white, colors.green)
            sleep(0.2)
            break
        end
    end
end

local function playGame()
    local birdX = math.floor(w * 0.3)
    local birdY = math.floor(h / 2)
    local velocity = 0
    local birdChar = ">" -- Changes when flapping
    
    -- PHYSICS FOR 20 FPS
    local gravity = 0.12
    local jumpPower = -0.85
    local baseSpeed = 0.45 
    local fpsTimer = 0.05 
    
    local score = 0
    local pillars = {}
    local playing = true
    
    local gapSize = 5 
    local pillarSpacing = 24 
    
    -- Spawn first pillar
    table.insert(pillars, {
        x = w, 
        gapTop = math.random(2, math.max(2, floorY - gapSize - 1)), 
        passed = false
    })

    -- Countdown
    for i = 3, 1, -1 do
        clearScreen(colors.lightBlue)
        monitor.setBackgroundColor(colors.green)
        monitor.setCursorPos(1, floorY)
        monitor.write(string.rep(" ", w))
        
        drawCentered(" GET READY ", math.floor(h/2) - 1, colors.yellow, colors.lightBlue)
        drawCentered(" " .. i .. " ", math.floor(h/2) + 1, colors.white, colors.gray)
        playSound("block.note_block.hat", 1.0)
        sleep(0.5)
    end
    playSound("block.note_block.pling", 1.5)

    local gameTimer = os.startTimer(fpsTimer)

    while playing do
        local event, p1, p2, p3 = os.pullEvent()

        if event == "monitor_touch" then
            velocity = jumpPower
            birdChar = "O" -- Flap animation
            playSound("entity.parrot.fly", 1.2, 1.0)
            
        elseif event == "timer" and p1 == gameTimer then
            -- 1. Apply Physics & Progressive Difficulty
            velocity = velocity + gravity
            birdY = birdY + velocity
            local by = math.floor(birdY)
            
            -- Revert bird char to falling state if velocity is positive
            if velocity > 0 then birdChar = ">" end
            
            -- Speed increases slightly for every point you get (caps at +0.4 extra speed)
            local currentSpeed = baseSpeed + math.min(0.4, score * 0.015)
            
            -- 2. Update Pillars
            for i = #pillars, 1, -1 do
                local p = pillars[i]
                p.x = p.x - currentSpeed
                local px = math.floor(p.x)
                
                -- Check if bird passed the pillar
                if px <= birdX and not p.passed then
                    p.passed = true
                    score = score + 1
                    playSound("block.note_block.bell", 1.5)
                end
                
                -- Remove off-screen pillars
                if px < -2 then
                    table.remove(pillars, i)
                end
            end
            
            -- 3. Spawn New Pillars
            if #pillars == 0 or (w - pillars[#pillars].x) >= pillarSpacing then
                table.insert(pillars, {
                    x = w, 
                    gapTop = math.random(2, math.max(2, floorY - gapSize - 1)), 
                    passed = false
                })
            end
            
            -- 4. Check Collisions
            -- Hit the ceiling or the ground
            if by < 1 or by >= floorY then
                playing = false
            end
            
            -- Hit a pillar
            for _, p in ipairs(pillars) do
                local px = math.floor(p.x)
                if birdX == px or birdX == px + 1 then
                    if by < p.gapTop or by >= p.gapTop + gapSize then
                        playing = false
                    end
                end
            end
            
            if not playing then break end
            
            -- 5. Render Graphics
            monitor.setBackgroundColor(colors.lightBlue)
            monitor.clear()
            
            -- Draw Pillars (Green)
            monitor.setBackgroundColor(colors.lime)
            for _, p in ipairs(pillars) do
                local px = math.floor(p.x)
                if px >= 1 and px <= w then
                    for y = 1, floorY - 1 do
                        if y < p.gapTop or y >= p.gapTop + gapSize then
                            monitor.setCursorPos(px, y)
                            if px == w then
                                monitor.write(" ")
                            else
                                monitor.write("  ")
                            end
                        end
                    end
                end
            end
            
            -- Draw Ground
            monitor.setBackgroundColor(colors.green)
            monitor.setCursorPos(1, floorY)
            -- Simple trick to make the ground look like it's moving
            local groundPattern = (math.floor(os.clock() * 10) % 2 == 0) and "- " or " -"
            monitor.setTextColor(colors.lime)
            monitor.write(string.rep(groundPattern, math.ceil(w/2)))
            
            -- Draw Bird (Yellow)
            monitor.setCursorPos(birdX, by)
            monitor.setBackgroundColor(colors.yellow)
            monitor.setTextColor(colors.black)
            monitor.write(birdChar)
            
            -- Draw Score (Centered at top)
            local scoreText = " " .. score .. " "
            monitor.setCursorPos(math.floor((w - #scoreText) / 2) + 1, 1)
            monitor.setBackgroundColor(colors.black)
            monitor.setTextColor(colors.white)
            monitor.write(scoreText)
            
            -- Queue the next frame
            gameTimer = os.startTimer(fpsTimer)
        end
    end
    
    return score
end

-- Main Application Loop
while true do
    drawMenu()
    
    local finalScore = playGame()
    
    if finalScore > highScore then
        highScore = finalScore
        playSound("ui.toast.challenge_complete", 1.0) -- Special sound for high score!
    else
        playSound("entity.generic.explode", 1.0)
        playSound("block.note_block.bass", 0.5)
    end
    
    clearScreen(colors.black)
    drawCentered(" CRASHED! ", math.floor(h/2) - 2, colors.white, colors.red)
    drawCentered("Score: " .. finalScore, math.floor(h/2), colors.white)
    drawCentered("Best: " .. highScore, math.floor(h/2) + 1, colors.yellow)
    
    local btnY = h - 1
    local btnText = " [ MENU ] "
    drawCentered(btnText, btnY, colors.black, colors.green)
    
    while true do
        local event, p1, p2, p3 = os.pullEvent("monitor_touch")
        local touchX, touchY = p2, p3
        
        local btnStartX = math.floor((w - #btnText) / 2) + 1
        local btnEndX = btnStartX + #btnText - 1
        
        if touchY == btnY and touchX >= btnStartX and touchX <= btnEndX then
            playSound("block.note_block.pling", 1.0)
            drawCentered(btnText, btnY, colors.black, colors.lime)
            sleep(0.2)
            break
        end
    end
end
