local monitor = peripheral.find("monitor")
local speaker = peripheral.find("speaker")

if not monitor then
    print("Could not find a connected monitor.")
    return
end

monitor.setTextScale(1.5) 
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

local function drawMenu()
    clearScreen(colors.cyan)
    
    drawCentered(" PIXEL CATCHER ", math.floor(h/2) - 3, colors.yellow, colors.cyan)
    drawCentered(" Best Score: " .. highScore .. " ", math.floor(h/2) - 1, colors.white, colors.cyan)
    
    local btnY = math.floor(h/2) + 2
    local btnText = " [ PLAY ] "
    drawCentered(btnText, btnY, colors.white, colors.blue)
    
    while true do
        local event, p1, p2, p3 = os.pullEvent("monitor_touch")
        local touchX, touchY = p2, p3
        
        local btnStartX = math.floor((w - #btnText) / 2) + 1
        local btnEndX = btnStartX + #btnText - 1
        
        if touchY == btnY and touchX >= btnStartX and touchX <= btnEndX then
            playSound("block.note_block.pling", 1.5)
            drawCentered(btnText, btnY, colors.white, colors.lime)
            sleep(0.2)
            break
        end
    end
end

local function playGame()
    local paddleWidth = 3
    local paddleX = math.floor((w - paddleWidth) / 2) + 1
    local paddleY = h
    
    local objects = {}
    local score = 0
    local lives = 3
    local playing = true
    
    -- Power-up Timers
    local wideTimer = 0
    local freezeTimer = 0
    
    -- PHYSICS & DIFFICULTY
    local fpsTimer = 0.05 -- 20 FPS
    local baseFallSpeed = 0.2
    local baseSpawnRate = 0.08
    
    -- Countdown
    for i = 3, 1, -1 do
        clearScreen(colors.cyan)
        drawCentered(" GET READY ", math.floor(h/2) - 1, colors.yellow, colors.cyan)
        drawCentered(" " .. i .. " ", math.floor(h/2) + 1, colors.white, colors.gray)
        playSound("block.note_block.hat", 1.0)
        sleep(0.5)
    end
    playSound("block.note_block.pling", 1.5)

    local gameTimer = os.startTimer(fpsTimer)

    while playing do
        local event, p1, p2, p3 = os.pullEvent()

        if event == "monitor_touch" then
            local touchX = p2
            
            -- Teleport basket to finger, keeping it on screen
            paddleX = touchX - math.floor(paddleWidth / 2)
            if paddleX < 1 then paddleX = 1 end
            if paddleX > w - paddleWidth + 1 then paddleX = w - paddleWidth + 1 end
            
        elseif event == "timer" and p1 == gameTimer then
            
            -- Manage Power-up Timers
            if wideTimer > 0 then
                wideTimer = wideTimer - 1
                paddleWidth = 5
            else
                paddleWidth = 3
            end
            
            -- Adjust paddle boundary if width just shrank
            if paddleX > w - paddleWidth + 1 then paddleX = w - paddleWidth + 1 end

            local currentFallSpeed = baseFallSpeed + math.min(0.3, score * 0.005)
            local currentSpawnRate = baseSpawnRate + math.min(0.15, score * 0.002)
            local bgColor = colors.cyan

            if freezeTimer > 0 then
                freezeTimer = freezeTimer - 1
                currentFallSpeed = currentFallSpeed * 0.35 -- Slow motion!
                bgColor = colors.lightBlue -- Icy visual effect
            end
            
            -- 1. Spawn New Objects
            if math.random() < currentSpawnRate then
                local objType = "apple"
                local rand = math.random(1, 100)
                
                if rand <= 18 then
                    objType = "bomb"   -- 18% Bomb
                elseif rand >= 95 then
                    objType = "star"   -- 5% Star
                elseif rand >= 92 then
                    objType = "heart"  -- 3% Extra Life
                elseif rand >= 88 then
                    objType = "freeze" -- 4% Slow Motion
                elseif rand >= 83 then
                    objType = "wide"   -- 5% Wide Basket
                end
                
                table.insert(objects, {
                    x = math.random(1, w),
                    y = 1,
                    type = objType
                })
            end
            
            -- 2. Update Objects & Check Collisions
            for i = #objects, 1, -1 do
                local obj = objects[i]
                obj.y = obj.y + currentFallSpeed
                local oy = math.floor(obj.y)
                
                -- If object reaches the bottom row (where paddle is)
                if oy >= paddleY then
                    -- Check if paddle caught it
                    if obj.x >= paddleX and obj.x < paddleX + paddleWidth then
                        if obj.type == "apple" then
                            score = score + 1
                            playSound("entity.item.pickup", 1.5)
                        elseif obj.type == "star" then
                            score = score + 5
                            playSound("entity.experience_orb.pickup", 1.5)
                        elseif obj.type == "bomb" then
                            lives = lives - 1
                            playSound("entity.generic.explode", 1.0)
                            bgColor = colors.red -- Flash screen red
                        elseif obj.type == "heart" then
                            lives = math.min(lives + 1, 5) -- Max 5 lives
                            playSound("entity.player.levelup", 2.0)
                        elseif obj.type == "wide" then
                            wideTimer = 100 -- 5 seconds
                            playSound("block.amethyst_block.chime", 1.0)
                        elseif obj.type == "freeze" then
                            freezeTimer = 100 -- 5 seconds
                            playSound("block.glass.break", 1.5)
                        end
                    else
                        -- Missed the object
                        if obj.type == "apple" or obj.type == "star" then
                            -- Missing good core items costs a life!
                            lives = lives - 1
                            playSound("block.note_block.bass", 0.5)
                        end
                        -- Missing bombs or power-ups does nothing
                    end
                    
                    table.remove(objects, i)
                    
                    if lives <= 0 then
                        playing = false
                    end
                end
            end
            
            if not playing then break end
            
            -- 3. Render Graphics
            monitor.setBackgroundColor(bgColor)
            monitor.clear()
            
            -- Draw Objects
            for _, obj in ipairs(objects) do
                local oy = math.floor(obj.y)
                monitor.setCursorPos(obj.x, oy)
                
                if obj.type == "apple" then
                    monitor.setBackgroundColor(colors.red)
                    monitor.setTextColor(colors.white)
                    monitor.write("O")
                elseif obj.type == "bomb" then
                    monitor.setBackgroundColor(colors.gray)
                    monitor.setTextColor(colors.black)
                    monitor.write("*")
                elseif obj.type == "star" then
                    monitor.setBackgroundColor(colors.yellow)
                    monitor.setTextColor(colors.orange)
                    monitor.write("$")
                elseif obj.type == "heart" then
                    monitor.setBackgroundColor(colors.pink)
                    monitor.setTextColor(colors.white)
                    monitor.write("V")
                elseif obj.type == "wide" then
                    monitor.setBackgroundColor(colors.blue)
                    monitor.setTextColor(colors.white)
                    monitor.write("W")
                elseif obj.type == "freeze" then
                    monitor.setBackgroundColor(colors.white)
                    monitor.setTextColor(colors.lightBlue)
                    monitor.write("F")
                end
            end
            
            -- Draw Paddle (Basket Design)
            monitor.setCursorPos(paddleX, paddleY)
            monitor.setBackgroundColor(colors.brown)
            monitor.setTextColor(colors.white)
            if paddleWidth == 3 then
                monitor.write("\\_/")
            else
                monitor.write("\\___/")
            end
            
            -- Draw Top UI
            monitor.setCursorPos(1, 1)
            monitor.setBackgroundColor(colors.black)
            monitor.setTextColor(colors.white)
            local uiText = " S:" .. score .. " L:" .. lives
            uiText = uiText .. string.rep(" ", math.max(0, w - #uiText))
            monitor.write(uiText)
            
            -- Queue next frame
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
        playSound("ui.toast.challenge_complete", 1.0)
    else
        playSound("entity.villager.no", 1.0)
    end
    
    clearScreen(colors.black)
    drawCentered(" GAME OVER ", math.floor(h/2) - 2, colors.white, colors.red)
    drawCentered("Score: " .. finalScore, math.floor(h/2), colors.white)
    drawCentered("Best: " .. highScore, math.floor(h/2) + 1, colors.yellow)
    
    local btnY = h - 1
    local btnText = " [ MENU ] "
    drawCentered(btnText, btnY, colors.black, colors.cyan)
    
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
