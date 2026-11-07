local monitor = peripheral.find("monitor")
local speaker = peripheral.find("speaker")

if not monitor then
    print("Could not find a connected monitor.")
    return
end

monitor.setTextScale(1.0) 
local w, h = monitor.getSize()
local highScore = 0

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

local function playGame()
    local birdX = math.floor(w * 0.3)
    local birdY = math.floor(h / 2)
    local velocity = 0
    
    -- PHYSICS FOR 20 FPS
    local gravity = 0.22
    local jumpPower = -1.15
    local gameSpeed = 0.5 
    local fpsTimer = 0.05 
    
    local score = 0
    local pillars = {}
    local playing = true
    
    -- FIXED DIFFICULTY SETTINGS
    local gapSize = 5 -- Lowered from 8 to fit the screen
    local pillarSpacing = 24 
    
    -- Bulletproof spawn for first pillar
    table.insert(pillars, {
        x = w, 
        gapTop = math.random(2, math.max(2, h - gapSize - 1)), 
        passed = false
    })

    for i = 3, 1, -1 do
        clearScreen(colors.lightBlue)
        drawCentered(" FLAPPY PIXEL ", math.floor(h/2) - 2, colors.yellow, colors.lightBlue)
        drawCentered(" Tap to Fly! ", math.floor(h/2), colors.white, colors.lightBlue)
        drawCentered(" " .. i .. " ", math.floor(h/2) + 2, colors.white, colors.gray)
        playSound("block.note_block.hat", 1.0)
        sleep(0.5)
    end
    playSound("block.note_block.pling", 1.5)

    local gameTimer = os.startTimer(fpsTimer)

    while playing do
        local event, p1, p2, p3 = os.pullEvent()

        if event == "monitor_touch" then
            velocity = jumpPower
            playSound("entity.parrot.fly", 1.2, 1.0)
            
        elseif event == "timer" and p1 == gameTimer then
            -- 1. Apply Physics
            velocity = velocity + gravity
            birdY = birdY + velocity
            local by = math.floor(birdY)
            
            -- 2. Update Pillars
            for i = #pillars, 1, -1 do
                local p = pillars[i]
                p.x = p.x - gameSpeed
                local px = math.floor(p.x)
                
                -- Check if bird passed the pillar (Score point)
                if px <= birdX and not p.passed then
                    p.passed = true
                    score = score + 1
                    playSound("block.note_block.bell", 1.5)
                end
                
                -- Remove pillars that are off screen
                if px < -2 then
                    table.remove(pillars, i)
                end
            end
            
            -- 3. Spawn New Pillars
            if (w - pillars[#pillars].x) >= pillarSpacing then
                -- Bulletproof spawn for continuing pillars
                table.insert(pillars, {
                    x = w, 
                    gapTop = math.random(2, math.max(2, h - gapSize - 1)), 
                    passed = false
                })
            end
            
            -- 4. Check Collisions
            -- Hit the floor or ceiling
            if by < 1 or by > h then
                playing = false
            end
            
            -- Hit a pillar
            for _, p in ipairs(pillars) do
                local px = math.floor(p.x)
                -- The pillar is 2 blocks wide
                if birdX == px or birdX == px + 1 then
                    -- If the bird is NOT safely inside the gap
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
                -- Only draw if it's on the screen
                if px >= 1 and px <= w then
                    for y = 1, h do
                        if y < p.gapTop or y >= p.gapTop + gapSize then
                            monitor.setCursorPos(px, y)
                            -- Ensure we don't draw off the right side of the screen
                            if px == w then
                                monitor.write(" ")
                            else
                                monitor.write("  ")
                            end
                        end
                    end
                end
            end
            
            -- Draw Bird (Yellow)
            monitor.setCursorPos(birdX, by)
            monitor.setBackgroundColor(colors.yellow)
            monitor.setTextColor(colors.black)
            monitor.write(">")
            
            -- Draw Score
            monitor.setCursorPos(1, 1)
            monitor.setBackgroundColor(colors.lightBlue)
            monitor.setTextColor(colors.white)
            monitor.write(" " .. score .. " ")
            
            -- Queue the next frame
            gameTimer = os.startTimer(fpsTimer)
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
    
    playSound("entity.generic.explode", 1.0)
    playSound("block.note_block.bass", 0.5)
    
    clearScreen(colors.black)
    drawCentered(" CRASHED! ", math.floor(h/2) - 2, colors.white, colors.red)
    drawCentered("Score: " .. finalScore, math.floor(h/2), colors.white)
    drawCentered("Best: " .. highScore, math.floor(h/2) + 1, colors.yellow)
    
    local btnY = h - 1
    local btnText = " [ RESTART ] "
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
