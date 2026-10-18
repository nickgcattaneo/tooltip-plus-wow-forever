-- ToolTip+
-- Positions the default game tooltip on WoW Forever (interface 16001).
--
-- Re-anchor only through hooksecurefunc. Replacing GameTooltip_SetDefaultAnchor
-- taints the global, and later Blizzard callers inherit that taint. Forever
-- treats that as untrusted code, so secret-value reads (unit names, health
-- comparisons) start throwing.

local ADDON_NAME, ns = ...

local PREFIX = "|cffd4a85aToolTip+|r"

local DEFAULTS = {
    enabled = true,
    -- cursor: follow the mouse
    -- corner: pin to a screen corner
    -- default: leave Blizzard's anchor alone
    mode = "cursor",
    offsetX = 12,
    offsetY = -12,
    corner = "BOTTOMRIGHT",
}

local CORNERS = {
    BOTTOMRIGHT = true,
    BOTTOMLEFT = true,
    TOPRIGHT = true,
    TOPLEFT = true,
}

local function GetSetting(key)
    local db = ToolTipPlusDB
    if type(db) ~= "table" then
        return DEFAULTS[key]
    end
    local value = db[key]
    if value == nil then
        return DEFAULTS[key]
    end
    return value
end

local function SetSetting(key, value)
    if type(ToolTipPlusDB) ~= "table" then
        ToolTipPlusDB = {}
    end
    ToolTipPlusDB[key] = value
end

local function ApplyAnchor(tooltip, parent)
    if not GetSetting("enabled") then
        return
    end

    local mode = GetSetting("mode")
    if mode == "default" then
        return
    end

    if mode == "cursor" then
        -- Offsets are ignored by ANCHOR_CURSOR on some builds. Keep them in
        -- SavedVariables so corner mode and later tweaks share one setting.
        tooltip:SetOwner(parent, "ANCHOR_CURSOR", GetSetting("offsetX"), GetSetting("offsetY"))
        return
    end

    if mode == "corner" then
        local point = GetSetting("corner")
        if not CORNERS[point] then
            point = DEFAULTS.corner
        end
        tooltip:SetOwner(parent, "ANCHOR_NONE")
        tooltip:ClearAllPoints()
        tooltip:SetPoint(point, UIParent, point, GetSetting("offsetX"), GetSetting("offsetY"))
    end
end

if type(GameTooltip_SetDefaultAnchor) == "function" then
    hooksecurefunc("GameTooltip_SetDefaultAnchor", ApplyAnchor)
end

local function PrintHelp()
    print(PREFIX .. " commands:")
    print("  /tt+ on | off")
    print("  /tt+ mode cursor | corner | default")
    print("  /tt+ corner BOTTOMRIGHT | BOTTOMLEFT | TOPRIGHT | TOPLEFT")
    print("  /tt+ offset <x> <y>")
end

local function PrintStatus()
    local enabled = GetSetting("enabled")
    print(PREFIX .. " " .. (enabled and "on" or "off")
        .. ", mode=" .. tostring(GetSetting("mode"))
        .. ", corner=" .. tostring(GetSetting("corner"))
        .. (", offset=%d %d"):format(GetSetting("offsetX"), GetSetting("offsetY")))
end

SLASH_TOOLTIPPLUS1 = "/tt+"
SLASH_TOOLTIPPLUS2 = "/tooltipplus"
SlashCmdList["TOOLTIPPLUS"] = function(msg)
    local cmd, rest = (msg or ""):match("^(%S*)%s*(.-)$")
    cmd = string.lower(cmd or "")

    if cmd == "on" then
        SetSetting("enabled", true)
        print(PREFIX .. " enabled.")
    elseif cmd == "off" then
        SetSetting("enabled", false)
        print(PREFIX .. " disabled. Default tooltip position is used.")
    elseif cmd == "mode" then
        local mode = string.lower(rest or "")
        if mode ~= "cursor" and mode ~= "corner" and mode ~= "default" then
            print(PREFIX .. " usage: /tt+ mode cursor | corner | default")
            return
        end
        SetSetting("mode", mode)
        print(PREFIX .. " mode set to " .. mode .. ".")
    elseif cmd == "corner" then
        local point = string.upper(rest or "")
        if not CORNERS[point] then
            print(PREFIX .. " usage: /tt+ corner BOTTOMRIGHT | BOTTOMLEFT | TOPRIGHT | TOPLEFT")
            return
        end
        SetSetting("corner", point)
        SetSetting("mode", "corner")
        print(PREFIX .. " pinned to " .. point .. ".")
    elseif cmd == "offset" then
        local x, y = (rest or ""):match("^(%-?%d+)%s+(%-?%d+)$")
        if not x then
            print(PREFIX .. " usage: /tt+ offset <x> <y>")
            return
        end
        SetSetting("offsetX", tonumber(x))
        SetSetting("offsetY", tonumber(y))
        print(PREFIX .. (" offset set to %d, %d."):format(tonumber(x), tonumber(y)))
    elseif cmd == "" or cmd == "status" then
        PrintStatus()
        PrintHelp()
    else
        PrintHelp()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, loaded)
    if event ~= "ADDON_LOADED" or loaded ~= ADDON_NAME then
        return
    end
    ToolTipPlusDB = ToolTipPlusDB or {}
    ns.db = ToolTipPlusDB
    self:UnregisterEvent("ADDON_LOADED")
    print(PREFIX .. " loaded. Type /tt+ for help.")
end)
