--[[
    This resource is officially available on GitHub at
    https://github.com/patrikjuvonen/editor_addon_lights

    MIT License

    Copyright (c) 2021 patrikjuvonen

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]
local lightMatrix = {}
local deleting = {}

local function hex2rgba(hex)
    local hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6)), tonumber("0x" .. hex:sub(7, 8))
end

local function createLight(element)
    if (not isElement(element)) or (getElementType(element) ~= "addon_light") then return end

    if (isElement(lightMatrix[source])) then
        if (getElementType(lightMatrix[source]) == "searchlight") then
            destroyElement(lightMatrix[source])
        else
            call(getResourceFromName("dl_lightmanager"), "destroyLight", lightMatrix[source])
        end
    end

    local existed = lightMatrix[element] ~= nil

    lightMatrix[element] = true

    if (not existed) then
        setElementDimension(element, getElementData(element, "dimension"))
        setElementInterior(element, getElementData(element, "interior"))

        addEventHandler("onClientElementDimensionChange", element, function (_, newDimension)
            if (newDimension == getElementDimension(localPlayer)) then
                createLight(source)
            elseif (isElement(lightMatrix[source])) then
                if (getElementType(lightMatrix[source]) == "searchlight") then
                    destroyElement(lightMatrix[source])
                else
                    call(getResourceFromName("dl_lightmanager"), "destroyLight", lightMatrix[source])
                end
            end
        end)

        addEventHandler("onClientElementInteriorChange", element, function (_, newInterior)
            if (newInterior == getElementInterior(localPlayer)) then
                createLight(source)
            elseif (isElement(lightMatrix[source])) then
                if (getElementType(lightMatrix[source]) == "searchlight") then
                    destroyElement(lightMatrix[source])
                else
                    call(getResourceFromName("dl_lightmanager"), "destroyLight", lightMatrix[source])
                end
            end
        end)
    end

    local dimension = getElementDimension(element)
    local interior = getElementInterior(element)

    if (dimension == getElementDimension(localPlayer)) and (interior == getElementInterior(localPlayer)) then
        local lightType = getElementData(element, "type")
        local x, y, z = getElementPosition(element)
        local rx, ry, rz = tonumber(getElementData(element, "rotX")), tonumber(getElementData(element, "rotY")), tonumber(getElementData(element, "rotZ"))
        local tx, ty, tz = unpack(split(getElementData(element, "target"), ","))
        tx, ty, tz = tonumber(tx), tonumber(ty), tonumber(tz)
        local r, g, b, a = hex2rgba(getElementData(element, "color"))
        r, g, b, a = tonumber(r), tonumber(g), tonumber(b), tonumber(a)
        local attenuation = tonumber(getElementData(element, "attenuation")) or 5

        if (lightType == "GTASearchLight") then
            lightMatrix[element] = createSearchLight(
                x, y, z,
                x + (tx - x) * math.cos(math.rad(rz)) - (ty - y) * math.sin(math.rad(rz)),
                y + (tx - x) * math.sin(math.rad(rz)) + (ty - y) * math.cos(math.rad(rz)),
                tz,
                getElementData(element, "startRadius"),
                getElementData(element, "endRadius"),
                getElementData(element, "renderSpot") == "true"
            )
            setElementDimension(lightMatrix[element], dimension)
            setElementInterior(lightMatrix[element], interior)
        elseif (lightType == "DLPointLight") then
            lightMatrix[element] = call(
                getResourceFromName("dl_lightmanager"), "createPointLight",
                x, y, z,
                r, g, b, a,
                attenuation,
                getElementData(element, "generateNormals") == "true", getElementData(element, "skipNormals") == "true", dimension, interior
            )
            call(getResourceFromName("dl_lightmanager"), "setLightDimension", lightMatrix[element], dimension)
            call(getResourceFromName("dl_lightmanager"), "setLightInterior", lightMatrix[element], interior)
            call(getResourceFromName("dl_lightmanager"), "setLightRotation", lightMatrix[element], rx, ry, rz)
        elseif (lightType == "DLSpotLight") then
            lightMatrix[element] = call(
                getResourceFromName("dl_lightmanager"), "createSpotLight",
                x, y, z,
                r, g, b, a,
                tx, ty, tz,
                tonumber(getElementData(element, "falloff")) or 5,
                tonumber(getElementData(element, "theta")) or 5,
                tonumber(getElementData(element, "phi")) or 10,
                attenuation,
                getElementData(element, "generateNormals") == "true", getElementData(element, "skipNormals") == "true", dimension, interior
            )
            call(getResourceFromName("dl_lightmanager"), "setLightDimension", lightMatrix[element], dimension)
            call(getResourceFromName("dl_lightmanager"), "setLightInterior", lightMatrix[element], interior)
            call(getResourceFromName("dl_lightmanager"), "setLightRotation", lightMatrix[element], rx, ry, rz)
        end

        setElementParent(lightMatrix[element], element)

        addEventHandler("onClientElementDestroy", lightMatrix[element], function ()
            if (getElementType(source) == "searchlight") then return end
            if (deleting[source]) then return end

            deleting[source] = true

            call(getResourceFromName("dl_lightmanager"), "destroyLight", source)
        end)

        addEventHandler("onClientElementDimensionChange", lightMatrix[element], function (_, newDimension)
            if (newDimension == getElementDimension(localPlayer)) then
                createLight(getElementParent(source))
                return
            elseif (getElementType(source) == "searchlight") then
                destroyElement(source)
            else
                call(getResourceFromName("dl_lightmanager"), "destroyLight", source)
            end
        end)

        addEventHandler("onClientElementInteriorChange", lightMatrix[element], function (_, newInterior)
            if (newInterior == getElementInterior(localPlayer)) then
                createLight(getElementParent(source))
                return
            elseif (getElementType(source) == "searchlight") then
                destroyElement(source)
            else
                call(getResourceFromName("dl_lightmanager"), "destroyLight", source)
            end
        end)
    end
end

addEventHandler("onClientResourceStart", root, function ()
    for _, element in pairs(getElementsByType("addon_light", source == resourceRoot and root or source)) do
        local light = getElementChildren(element, "addon_light")[1]

        if (isElement(light)) then
            lightMatrix[element] = light
        end

        createLight(element)
    end
end)

addEventHandler("onClientResourceStop", resourceRoot, function ()
    for element, light in pairs(lightMatrix) do
        if (isElement(light)) then
            if (getElementType(light) == "searchlight") then
                destroyElement(light)
            else
                call(getResourceFromName("dl_lightmanager"), "destroyLight", light)
            end

            lightMatrix[element] = nil
        end
    end
end)

addEventHandler("onClientElementDimensionChange", localPlayer, function (_, newDimension)
    for element, light in pairs(lightMatrix) do
        if (isElement(element)) and (getElementDimension(element) == newDimension) then
            createLight(element)
        elseif (isElement(light)) then
            if (getElementType(light) == "searchlight") then
                destroyElement(light)
            else
                call(getResourceFromName("dl_lightmanager"), "destroyLight", light)
            end
        end
    end
end)

addEventHandler("onClientElementInteriorChange", localPlayer, function (_, newInterior)
    for element, light in pairs(lightMatrix) do
        if (isElement(element)) and (getElementInterior(element) == newInterior) then
            createLight(element)
        elseif (isElement(light)) then
            if (getElementType(light) == "searchlight") then
                destroyElement(light)
            else
                call(getResourceFromName("dl_lightmanager"), "destroyLight", light)
            end
        end
    end
end)
