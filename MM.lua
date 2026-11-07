local monitor = peripheral.find("monitor")

if not monitor then
    print("Could not find a connected monitor.")
    return
end

-- 1.5 scale provides a good resolution for drawing quadrants on a 2x2 grid
monitor.setTextScale(1.5) 
local w, h = monitor.getSize()
local midX = math.floor(w / 2)
local midY = math.floor(h / 2)

local highScore = 0

-- Define the 4 color zones (normal color, highlight color)
local zones = {
    { normal = colors.red,    flash = colors.pink },      -- 1: Top Left
    { normal = colors.green,  flash = colors.lime },      -- 2: Top Right
    { normal = colors.blue,   flash = colors.lightBlue }, -- 3: Bottom Left
    { normal = colors.orange, flash = colors.yellow }     -- 4: Bottom Right
}

local function drawCentered(text, yPos, txtColor, bgColor)
    monitor.setTextColor(txtColor or colors.white)
    monitor.setBackgroundColor(bgColor or colors.black)
    local x = math.floor((w - #text) / 2) + 1
    monitor.setCursorPos(x, yPos)
    monitor.write(text)
end

local function drawZone(zoneID, isFlashed)
    local z = zones[zoneID]
    local color = isFlashed and z.flash or z.normal
    monitor.setBackgroundColor(color)
    
    local startX = (zoneID == 1 or zoneID == 3) and 1 or (midX + 1)
    local endX   = (zoneID == 1 or zoneID == 3) and midX or w
    local startY = (zoneID == 1 or zoneID == 2) and 1 or (midY + 1)
    local endY   = (zoneID == 1 or zoneID == 2) and midY or h

    -- Draw the block of color
    for y = startY, endY do
        monitor.setCursorPos(startX, y)
        monitor.write(string.rep(" ", endX - startX + 1))
    end
end

local function drawBoard(highlightZone)
    for i = 1, 4 do
        drawZone(i, highlightZone == i)
    end
end

local function getTouchedZone(x, y)
    if x <= midX and y <= midY then return 1 end
    if x > midX and y <= midY then return 2 end
    if x <= midX and y > midY then return 3 end
    if x > midX and y > midY then return 4 end
    return nil
end

local function flashZone(zoneID, delay)
    drawZone(zoneID, true)
    sleep(delay or 0.4)
    drawZone(zoneID, false)
    sleep(0.15)
end

local function playGame()
    local sequence = {}
    local playing = true
    
    -- Initial blank board
    drawBoard()
    sleep(1)

    while playing do
        -- Add a new random step to the sequence
        table.insert(sequence, math.random(1, 4))
        
        -- Play the sequence for the player to watch
        sleep(0.5)
        for i, step in ipairs(sequence) do
            -- Speed up the flashes slightly as the sequence gets longer
            local flashSpeed = math.max(0.15, 0.5 - (#sequence * 0.02))
            flashZone(step, flashSpeed)
        end
        
        -- Wait for player to repeat the sequence
        for i, expectedStep in ipairs(sequence) do
            local waitingForTap = true
            
            while waitingForTap do
                local event, p1, p2, p3 = os.pullEvent("monitor_touch")
                local touchX, touchY = p2, p3
                
                local touchedZone = getTouchedZone(touchX, touchY)
                
                if touchedZone then
                    -- Visual feedback for the player's tap
                    flashZone(touchedZone, 0.2)
                    
                    if touchedZone == expectedStep then
                        waitingForTap = false -- Correct, move to next expected tap
                    else
                        -- Wrong tap! Game Over.
                        monitor.setBackgroundColor(colors.red)
                        monitor.clear()
                        sleep(0.5)
                        return #sequence - 1
                    end
                end
            end
        end
        -- If they matched the whole sequence, loop repeats and adds 1 more step
        sleep(0.5) 
    end
end

-- Main Application Loop
while true do
    local finalScore = playGame()
    
    if finalScore > highScore then
        highScore = finalScore
    end
    
    -- Game Over Screen
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    drawCentered(" WRONG SEQUENCE ", math.floor(h/2) - 2, colors.white, colors.red)
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
            drawCentered(btnText, btnY, colors.black, colors.lime)
            sleep(0.2)
            break
        end
    end
end
