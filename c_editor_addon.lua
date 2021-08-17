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

local function getRepresentation(element, type)
    local elemTable = {}

    for _, elem in pairs(getElementsByType(type, element)) do
        if (elem ~= exports.edf:edfGetHandle(elem)) then
            table.insert(elemTable, elem)
        end
    end

    if (#elemTable == 0) then
        return false
    elseif (#elemTable == 1) then
        return elemTable[1]
    end

    return elemTable
end

local function hex2rgba(hex)
    local hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6)), tonumber("0x" .. hex:sub(7, 8))
end

local function createLight(element)
    element = element or source

    if (not isElement(element)) or (getElementType(element) ~= "addon_light") then return end

    if (isElement(lightMatrix[element])) then
        if (getElementType(lightMatrix[source]) == "searchlight") then
            destroyElement(lightMatrix[source])
        else
            call(getResourceFromName("dl_lightmanager"), "destroyLight", lightMatrix[source])
        end
    end

    local lightType = exports.edf:edfGetElementProperty(element, "type")
    local x, y, z = exports.edf:edfGetElementPosition(element)
    local _, _, rz = exports.edf:edfGetElementRotation(element)
    local _tx, _ty, tz = unpack(exports.edf:edfGetElementProperty(element, "target"))
    local tx, ty = x + (_tx - x) * math.cos(math.rad(rz)) - (_ty - y) * math.sin(math.rad(rz)), y + (_tx - x) * math.sin(math.rad(rz)) + (_ty - y) * math.cos(math.rad(rz))
    local r, g, b, a = hex2rgba(exports.edf:edfGetElementProperty(element, "color"))
    local attenuation = exports.edf:edfGetElementProperty(element, "attenuation") or 5
    local dimension = exports.edf:edfGetElementDimension(element) or 0
    local interior = exports.edf:edfGetElementInterior(element) or 0

    if (lightType == "GTASearchLight") then
        lightMatrix[element] = createSearchLight(
            x, y, z,
            tx, ty, tz,
            exports.edf:edfGetElementProperty(element, "startRadius"),
            exports.edf:edfGetElementProperty(element, "endRadius"),
            exports.edf:edfGetElementProperty(element, "renderSpot") == "true"
        )
        setElementDimension(lightMatrix[element], dimension)
        setElementInterior(lightMatrix[element], interior)
    elseif (lightType == "DLPointLight") then
        lightMatrix[element] = call(
            getResourceFromName("dl_lightmanager"), "createPointLight",
            x, y, z,
            r, g, b, a,
            attenuation,
            exports.edf:edfGetElementProperty(element, "generateNormals") == "true", exports.edf:edfGetElementProperty(element, "skipNormals") == "true", dimension, interior
        )
        call(getResourceFromName("dl_lightmanager"), "setLightDimension", lightMatrix[element], dimension)
        call(getResourceFromName("dl_lightmanager"), "setLightInterior", lightMatrix[element], interior)
    elseif (lightType == "DLSpotLight") then
        lightMatrix[element] = call(
            getResourceFromName("dl_lightmanager"), "createSpotLight",
            x, y, z,
            r, g, b, a,
            tx, ty, tz,
            exports.edf:edfGetElementProperty(element, "falloff") or 5,
            exports.edf:edfGetElementProperty(element, "theta") or 5,
            exports.edf:edfGetElementProperty(element, "phi") or 10,
            attenuation,
            exports.edf:edfGetElementProperty(element, "generateNormals") == "true", exports.edf:edfGetElementProperty(element, "skipNormals") == "true", dimension, interior
        )
        call(getResourceFromName("dl_lightmanager"), "setLightDimension", lightMatrix[element], dimension)
        call(getResourceFromName("dl_lightmanager"), "setLightInterior", lightMatrix[element], interior)
    end

    setElementParent(lightMatrix[element], element)

    setElementAlpha(getRepresentation(element, "marker"), 0)
end

addEventHandler("onClientElementCreate", root, function ()
    setElementData(source, "unplaced", true, false)
    createLight(source)
end)

local function localCleanUp()
    if (not isElement(source)) or (getElementType(source) ~= "addon_light") or (not lightMatrix[source]) then return end

    if (isElement(lightMatrix[source])) then
        if (getElementType(lightMatrix[source]) == "searchlight") then
            destroyElement(lightMatrix[source])
        else
            call(getResourceFromName("dl_lightmanager"), "destroyLight", lightMatrix[source])
        end
    end

    lightMatrix[source] = nil
end
addEventHandler("onClientElementDestroyed", root, localCleanUp)
addEventHandler("onClientElementDestroy", root, localCleanUp)

addEventHandler("onClientElementPropertyChanged", root, function (propertyName, v)
    if (not isElement(source)) or (getElementType(source) ~= "addon_light") or (not lightMatrix[source]) then return end

    if (not isElement(lightMatrix[source])) then
        createLight(source)
        return
    end

    if (getElementType(lightMatrix[source]) ~= "searchlight") then
        if (propertyName == "position") then
            call(getResourceFromName("dl_lightmanager"), "setLightPosition", lightMatrix[source], exports.edf:edfGetElementPosition(source))
        elseif (propertyName == "rotation") then
            call(getResourceFromName("dl_lightmanager"), "setLightRotation", lightMatrix[source], exports.edf:edfGetElementRotation(source))
        elseif (propertyName == "target") then
            call(getResourceFromName("dl_lightmanager"), "setLightDirection", lightMatrix[source], unpack(exports.edf:edfGetElementProperty(source, "target") or {0, 0, 0}))
        elseif (propertyName == "color") then
            call(getResourceFromName("dl_lightmanager"), "setLightColor", lightMatrix[source], hex2rgba(exports.edf:edfGetElementProperty(source, "color") or "#ffffffff"))
        elseif (propertyName == "attenuation") then
            call(getResourceFromName("dl_lightmanager"), "setLightAttenuation", lightMatrix[source], exports.edf:edfGetElementProperty(source, "attenuation") or 5)
        elseif (propertyName == "falloff") then
            call(getResourceFromName("dl_lightmanager"), "setLightFalloff", lightMatrix[source], exports.edf:edfGetElementProperty(source, "falloff") or 5)
        elseif (propertyName == "theta") then
            call(getResourceFromName("dl_lightmanager"), "setLightTheta", lightMatrix[source], exports.edf:edfGetElementProperty(source, "theta") or 5)
        elseif (propertyName == "phi") then
            call(getResourceFromName("dl_lightmanager"), "setLightPhi", lightMatrix[source], exports.edf:edfGetElementProperty(source, "phi") or 5)
        else
            createLight(source)
        end
    elseif (propertyName == "position") then
        setSearchLightStartPosition(lightMatrix[source], getElementPosition(source))
    elseif (propertyName == "target") then
        setSearchLightEndPosition(lightMatrix[source], Vector3(exports.edf:edfGetElementProperty(source, "target") or {0, 0, 0}))
    elseif (propertyName == "startRadius") then
        setSearchLightStartRadius(lightMatrix[source], exports.edf:edfGetElementProperty(source, "startRadius") or 0.1)
    elseif (propertyName == "endRadius") then
        setSearchLightEndRadius(lightMatrix[source], exports.edf:edfGetElementProperty(source, "endRadius") or 20)
    else
        createLight(source)
    end
end)

addEvent("onClientElementDrop", true)
addEventHandler("onClientElementDrop", root, function ()
    if (not isElement(source)) or (getElementType(source) ~= "addon_light") or (not lightMatrix[source]) then return end

    setElementData(source, "unplaced", nil)
end)

addEventHandler("onClientPreRender", root, function ()
    for element, light in pairs(lightMatrix) do
        if (isElement(element)) then
            if (exports.edf:edfGetElementProperty(element, "type") == "GTASearchLight") then
                setSearchLightStartPosition(light, exports.edf:edfGetElementPosition(element))

                local _, _, rz = exports.edf:edfGetElementRotation(element)
                local x, y, z = exports.edf:edfGetElementPosition(element)

                if (getElementData(element, "unplaced")) then
                    exports.edf:edfSetElementProperty(element, "target", { x, y, getGroundPosition(x, y, z) })
                end

                local tx, ty, tz = unpack(exports.edf:edfGetElementProperty(element, "target"))

                setSearchLightEndPosition(
                    light,
                    x + (tx - x) * math.cos(math.rad(rz)) - (ty - y) * math.sin(math.rad(rz)),
                    y + (tx - x) * math.sin(math.rad(rz)) + (ty - y) * math.cos(math.rad(rz)),
                    tz
                )
            else
                call(getResourceFromName("dl_lightmanager"), "setLightPosition", light, exports.edf:edfGetElementPosition(element))
                call(getResourceFromName("dl_lightmanager"), "setLightRotation", light, exports.edf:edfGetElementRotation(element))
            end
        end
    end
end)

function onStart()
    for _, element in pairs(getElementsByType("addon_light")) do
        createLight(element)
    end
end

function onStop()
    for element, light in pairs(lightMatrix) do
        if (isElement(light)) then
            if (getElementType(light) == "searchlight") then
                destroyElement(light)
            else
                call(getResourceFromName("dl_lightmanager"), "destroyLight", light)
            end
        end

        lightMatrix[element] = nil
    end
end
addEventHandler("onClientResourceStop", resourceRoot, onStop)
