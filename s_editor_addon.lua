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
function onStart()
    local dl_lightmanager = getResourceFromName("dl_lightmanager")
    local failed = not dl_lightmanager

    if (dl_lightmanager) then
        if (getResourceState(dl_lightmanager) == "loaded") then
            failed = not startResource(dl_lightmanager)
        elseif (getResourceState(dl_lightmanager) ~= "running") then
            return
        end
    end

    if (failed) then
        outputDebugString("dl_lightmanager resource must be available and running. Lights add-on will not work.", 1)
    end
end
