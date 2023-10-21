--:: SHORTHANDS ::--
lg = love.graphics
fs = love.filesystem
kb = love.keyboard
lm = love.mouse
lp = love.physics
random = love.math.random
noise = love.math.noise
sin = math.sin
cos = math.cos
floor = math.floor
ceil = math.floor
f = string.format

-- Modifying lg.setColor
local setColor = lg.setColor
love.graphics.setColor = function(r, g, b, a)
    if type(r) == "number" and not g and not b and not a then
        setColor(r, r, r, 1)
    else
        setColor(r, g, b, a)
    end
end

-- Modifting lua print
local _print = print
function print(...) _print(string.format("%s:%d:", debug.getinfo(2).short_src, debug.getinfo(2).currentline), ...) end


function love.load()
    -- Loading util first as it contains the "requireDirectory" function used to load everything else
    Util = require "lib.Util"

    Util.requireDirectory("lib")
    Util.requireDirectory("class")

    -- Keypress events
    Input:keypress("escape", love.event.push, "quit")
    Input:keypress("f3", love.system.openURL, "file://"..love.filesystem.getSaveDirectory())
    Input:keypress("f2", love.graphics.captureScreenshot, os.time() .. ".png")

    lg.setDefaultFilter("nearest", "nearest")

    ------------------------- Color extarction -----------------------
    colorExtract = require "colorExtract"

    -- Loading images
    img    = 1
    images = {}
    for i,file in ipairs(fs.getDirectoryItems("images")) do 
        images[i] = "images/" .. file
    end

    imagePosition = {
        x = lg.getWidth() / 2,
        y = lg.getHeight() / 2
    }
    bgColor = {0, 0, 0}
    textColor = {0, 0, 0}
    anim = {0, 0, 0, 0, 0, 0, 0}


    nextImage()
    Input:keypress("space", nextImage)

    largefont = lg.newFont(25)

    tick = 0
end

function nextImage(_image)
    _image = _image or images[img]
    Flux.to(anim, 0.3, {0, 0, 0, 0, 0, 0, 0}):oncomplete(function()
        palette, image = colorExtract.extract(_image, 20, 5)
        Flux.to(bgColor, 1, {palette[1][1], palette[1][2], palette[1][3]})
        Flux.to(textColor, 1, {palette[3][1], palette[3][2], palette[3][3]})
        Flux.to(anim, 1, {1, 1, 1, 1, 1, 1, 1})
    end)

    img = img + 1
    if img > #images then
        img = 1 
    end
end


function love.update(dt)
    -- tick = tick + dt
    -- if tick > 4 then 
    --     nextImage()
    --     tick = 0
    -- end
    lg.setBackgroundColor(bgColor)
    Input:update()
    Flux.update(dt)
end

function love.draw()
    if palette then
        -- Drawing color palette
        local width = lg.getWidth() / #palette
        for i,color in ipairs(palette) do
            lg.setColor(color or {1, 1, 1})
            Util.setAlpha(anim[i])
            lg.rectangle("fill", (i - 1) * width, 0, width, lg.getHeight())
        end

        -- Drawing the image shadow
        lg.setColor(Color.black)
        Util.setAlpha(anim[1] * 0.2)
        lg.draw(image, imagePosition.x, imagePosition.y + 30, 0, 0.5, 0.5, image:getWidth() / 2, image:getHeight() / 2)

        -- Drawing the image
        lg.setColor(Color.white)
        Util.setAlpha(anim[1])
        lg.draw(image, imagePosition.x, imagePosition.y, 0, 0.5, 0.5, image:getWidth() / 2, image:getHeight() / 2)

        -- Drawing text
        lg.setColor(textColor)
        lg.setFont(largefont)
        lg.print("Color Palette Extraction via K-Means Clustering", 50, lg.getHeight() * 0.9, -math.pi / 2)
        lg.setColor(bgColor)
        lg.printf("Press <space> for another image", 0, lg.getHeight() * 0.9, lg.getWidth(), "center")
    end
end

function love.keypressed(key)
    Input:keypressed(key)
end

function love.filedropped(file)
    local filename  = file:getFilename()
    local extension = Util.getFileType(filename)

    if extension == "png" or extension == "jpg" then
        file:open("r")
        data = love.image.newImageData(file:read("data"))
        nextImage(data)
    end
end
