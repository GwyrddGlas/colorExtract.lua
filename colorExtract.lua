-------------------------------------------------------------------------------------
--                  A library for löve capable of extracting a                     --
--             color palettte from an image via K-Means clustering.                --
-------------------------------------------------------------------------------------
--                                   LICENSE                                       --
-------------------------------------------------------------------------------------
-- Copyright (c) 2023 Pawel Þorkelsson                                             --
--                                                                                 --
-- Permission is hereby granted, free of charge, to any person obtaining a copy of --
-- this software and associated documentation files (the "Software"), to deal in   --
-- the Software without restriction, including without limitation the rights to    --
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies   --
-- of the Software, and to permit persons to whom the Software is furnished to do  --
-- so, subject to the following conditions:                                        --
--                                                                                 --
-- The above copyright notice and this permission notice shall be included in all  --
-- copies or substantial portions of the Software.                                 --
--                                                                                 --
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR      --
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,        --
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE     --
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER          --
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,   --
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE   --
-- SOFTWARE.                                                                       --
-------------------------------------------------------------------------------------

local colorExtract = {}

-- Converts rgb to HSL. Used for sorting purposes.
-- Source: https://github.com/Wavalab/rgb-hsl-rgb/blob/master/rgbhsl.lua
local function rgbToHsl(r, g, b)
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local b = max + min
    local h = b / 2
    if max == min then return 0, 0, h end
    local s, l = h, h
    local d = max - min
    s = l > .5 and d / (2 - b) or d / b
    if max == r then h = (g - b) / d + (g < b and 6 or 0)
    elseif max == g then h = (b - r) / d + 2
    elseif max == b then h = (r - g) / d + 4
    end
    return h * .16667, s, l
end

-- Returns the euclidean distance between n-dimensional coordinates
local function distance(a, b)
    if #a ~= #b then return end
    local sum = 0
    for i, v in ipairs(a) do
        sum = sum + math.pow(b[i] - v, 2)
    end
    return math.sqrt(sum)
end

-- Gathers all colors from an image. The skip arguments lets it skip
-- over a number of pixels each step for performance reasons.
local function getPoints(path, skip)
    local imageData = path
    if type(path) == "string" then 
        imageData = love.image.newImageData(path) 
    end
    local points    = {}

    for y=0, imageData:getHeight() - 1, (skip or 1) do
        for x=0, imageData:getWidth() - 1, (skip or 1) do
            local r, g, b = imageData:getPixel(x, y)
            points[#points + 1] = {r, g, b}
        end
    end

    return points
end

-- Gets the center (mean) of a collection of points
local function getCenter(points)
    local sum = {}

    -- Adding up each axis
    for _,point in ipairs(points) do
        for i, val in ipairs(point) do
            if not sum[i] then sum[i] = 0 end
            sum[i] = sum[i] + val 
        end
    end

    -- Divifing by #points
    for i, v in ipairs(sum) do
        sum[i] = sum[i] / #points
    end

    return sum
end

-- Picks a random points from a set of points
function getRandomPoint(points)
    return points[random(#points)]
end

-- Assings points to clusters
local function assign(points, clusters)
    for _, point in ipairs(points) do
        local minDistance     = 1000000
        local assignedCluster = 1

        for i, cluster in ipairs(clusters) do
            local dist = distance(point, cluster.center)
            if dist < minDistance then
                assignedCluster = i
                minDistance = dist
            end
        end

        table.insert(clusters[assignedCluster].points, point)
    end

end

-- Updates a clusters center (Mean)
local function update(clusters)
    for _, cluster in ipairs(clusters) do
        cluster.center = getCenter(cluster.points)
    end
end

-- Sorts a list of colors by hue
local function sortByHue(colors)
    table.sort(colors, function(a, b) 
        local aHue = rgbToHsl(a[1], a[2], a[3])
        local bHue = rgbToHsl(b[1], b[2], b[3])
        return aHue < bHue
    end)
end

-- Sorts a list of colors by saturation
local function sortBySaturation(colors)
    table.sort(colors, function(a, b) 
        local _, aSaturation = rgbToHsl(a[1], a[2], a[3])
        local _, bSaturation = rgbToHsl(b[1], b[2], b[3])
        return aSaturation < bSaturation
    end)
end

-- Sorts a list of colors by lightness
local function sortByLightness(colors)
    table.sort(colors, function(a, b) 
        local _, _, aLightness = rgbToHsl(a[1], a[2], a[3])
        local _, _, bLightness = rgbToHsl(b[1], b[2], b[3])
        return aLightness < bLightness
    end)
end

-- Sorts a list of colors by distance from white
local function sortByDistance(colors)
    table.sort(colors, function(a, b) 
        local aDistance = distance(a, {1, 1, 1})
        local bDistance = distance(b, {1, 1, 1})
        return aDistance > bDistance
    end)
end

-- Extracts a color palette from an image
function colorExtract.extract(path, skip, paletteSize, iterations)
    -- Acquire points from an image
    local points = getPoints(path, skip)

    -- Sort the points by their saturation so points[1] is the most saturated one
    sortBySaturation(points)
    
    -- Initializing clusters such that their centers are the most saturated colors
    local clusters = {}
    for i=1, paletteSize or 5 do
        clusters[i] = {
            center = points[i],
            -- center = getRandomPoint(points),
            points = {}
        }
    end

    -- Clustering
    for i=1, iterations or 30 do 
        -- Resetting clusters
        for i,v in ipairs(clusters) do v.points = {} end

        -- Assigning and updating
        assign(points, clusters)
        update(clusters)

        -- Checking for and dealing with empty clusters by assigning a random point to their center
        for _, cluster in ipairs(clusters) do
            if #cluster.points < 1 then
                cluster.center = getRandomPoint(points)                
            end
        end
    end

    -- Gathering, sorting and returning the cluster centers, which will be the final palette
    local extractedColors = {}
    for i, cluster in ipairs(clusters) do
        extractedColors[i] = cluster.center
    end

    sortByLightness(extractedColors)

    return extractedColors, lg.newImage(path)
end

return colorExtract
