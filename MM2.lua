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
local midX = math.floor(w / 2)
local midY = math.floor(h / 2)

local highScore = 0

-- Added 'pitch' values for the note block sounds
local zones = {
    { normal = colors.red,    flash = colors.pink,      pitch = 0.5 }, -- Low note
    { normal = colors.green,  flash = colors.lime,      pitch = 0.8 }, -- Mid-low note
    { normal = colors.blue,   flash = colors.lightBlue, pitch = 1.2 }, -- Mid-high note
    { normal = colors.orange, flash = colors.yellow,    pitch = 1.6 }  -- High note
}

local function playSound(soundName, pitch)
    if speaker then
        -- Volume is set to 3.0 to ensure it's loud enough
        speaker.playSound(soundName, 3.0, pitch or 1.0)
    end
end

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
    playSound("block.note_block.pling", zones[zoneID].pitch)
    drawZone(zoneID, true)
    sleep(delay or 0.4)
    drawZone(zoneID, false)
    sleep(0.15)
end

local function playGame()
    local sequence = {}
    local playing = true
    
    drawBoard()
    sleep(1)

    while playing do
        table.insert(sequence, math.random(1, 4))
        
        sleep(0.5)
        for i, step in ipairs(sequence) do
            local flashSpeed = math.max(0.15, 0.5 - (#sequence * 0.02))
            flashZone(step, flashSpeed)
        end
        
        for i, expectedStep in ipairs(sequence) do
            local waitingForTap = true
            
            while waitingForTap do
                local event, p1, p2, p3 = os.pullEvent("monitor_touch")
                local touchX, touchY = p2, p3
                
                local touchedZone = getTouchedZone(touchX, touchY)
                
                if touchedZone then
                    if touchedZone == expectedStep then
                        flashZone(touchedZone, 0.2)
                        waitingForTap = false
                    else
                        -- Wrong tap: Play a low bass failure sound
                        playSound("block.note_block.bass", 0.5)
                        monitor.setBackgroundColor(colors.red)
                        monitor.clear()
                        sleep(0.5)
                        return #sequence - 1
                    end
                end
            end
        end
        
        -- Success: Play a happy chime before the next round starts
        playSound("entity.experience_orb.pickup", 1.0)
        sleep(0.5) 
    end
end

while true do
    local finalScore = playGame()
    
    if finalScore > highScore then
        highScore = finalScore
    end
    
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    drawCentered(" WRONG SEQUENCE ", math.floor(h/2) - 2, colors.white, colors.red)
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
