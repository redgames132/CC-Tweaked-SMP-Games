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
        local ty = math.random(2,
