local ADDON_NAME, ns = ...

ns.Content = ns.Content or {}

local hideHealth = setmetatable({}, { __mode = "k" })

local function Sealed(value)
    return type(issecretvalue) == "function" and issecretvalue(value)
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        return nil
    end
    return a, b, c
end

-- Names can be secret. The unit token ("mouseover", "player") usually is not.
local function TooltipUnit(tooltip)
    if tooltip and tooltip.GetUnit then
        local name, unit = SafeCall(tooltip.GetUnit, tooltip)
        if unit and not Sealed(unit) and type(unit) == "string" and unit ~= "" then
            return unit
        end
    end
    if UnitExists and SafeCall(UnitExists, "mouseover") then
        return "mouseover"
    end
    return nil
end

local function LineLeft(tooltip, index)
    if not tooltip or not tooltip.GetName then
        return nil
    end
    local name = tooltip:GetName()
    if type(name) ~= "string" then
        return nil
    end
    return _G[name .. "TextLeft" .. index]
end

local function LineText(fontString)
    if not fontString or not fontString.GetText then
        return nil
    end
    local text = fontString:GetText()
    if Sealed(text) or type(text) ~= "string" then
        return nil
    end
    return text
end

local function FindLineByText(tooltip, needle)
    if not needle or Sealed(needle) or not tooltip.NumLines then
        return nil
    end
    local count = tooltip:NumLines() or 0
    for i = 1, count do
        local left = LineLeft(tooltip, i)
        if LineText(left) == needle then
            return left
        end
    end
    return nil
end

local function StatusBarFor(tooltip)
    if not tooltip then
        return nil
    end
    return tooltip.StatusBar or tooltip.statusBar or _G.GameTooltipStatusBar
end

local function HookHealthBar(bar)
    if not bar or bar._ttPlusHealthHooked then
        return
    end
    bar._ttPlusHealthHooked = true
    bar:HookScript("OnShow", function(self)
        if hideHealth[self] then
            self:Hide()
        end
    end)
end

local function SetHealthBarShown(tooltip, shown)
    local bar = StatusBarFor(tooltip)
    if not bar then
        return
    end
    HookHealthBar(bar)
    hideHealth[bar] = not shown
    if shown then
        return
    end
    bar:Hide()
end

local function ApplyClassColor(tooltip, unit, enabled)
    if not UnitClass then
        return
    end
    local _, classFile = SafeCall(UnitClass, unit)
    if Sealed(classFile) or type(classFile) ~= "string" then
        return
    end
    local left = LineLeft(tooltip, 1)
    if not left or not left.SetTextColor then
        return
    end
    if enabled then
        local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
        if color then
            left:SetTextColor(color.r, color.g, color.b)
        end
        return
    end
    left:SetTextColor(1, 0.82, 0)
end

local function ApplyGuild(tooltip, unit, enabled)
    if not GetGuildInfo then
        return false
    end
    local guild = SafeCall(GetGuildInfo, unit)
    if not guild or Sealed(guild) or type(guild) ~= "string" or guild == "" then
        return false
    end
    local line = FindLineByText(tooltip, guild)
    if enabled then
        if line then
            return false
        end
        tooltip:AddLine(guild, 0.8, 0.8, 0.8)
        return true
    end
    if line then
        line:SetText("")
        if line.Hide then
            line:Hide()
        end
        return true
    end
    return false
end

local function ApplyTarget(tooltip, unit, enabled)
    if not enabled or Sealed(unit) or not UnitName then
        return false
    end
    local targetUnit = unit .. "target"
    if UnitExists and not SafeCall(UnitExists, targetUnit) then
        return false
    end
    local target = SafeCall(UnitName, targetUnit)
    if not target or Sealed(target) or type(target) ~= "string" or target == "" then
        return false
    end
    local label = "Target: " .. target
    if FindLineByText(tooltip, label) then
        return false
    end
    tooltip:AddLine(label, 0.9, 0.9, 0.6)
    return true
end

function ns.Content.Apply(tooltip, typeId)
    if not tooltip or not typeId then
        return
    end

    local resolved = ns.Resolve(typeId)
    if not resolved.enabled then
        return
    end

    local content = resolved.content
    local scale = tonumber(content.scale) or 1
    if tooltip.SetScale then
        tooltip:SetScale(scale)
    end

    if content.hideInCombat and InCombatLockdown and InCombatLockdown() then
        tooltip:Hide()
        return
    end

    if not ns.IsUnitContentType(typeId) then
        return
    end

    local unit = TooltipUnit(tooltip)
    if not unit then
        return
    end

    SetHealthBarShown(tooltip, content.showHealthBar and true or false)
    ApplyClassColor(tooltip, unit, content.classColorName and true or false)

    local resized = false
    if ApplyGuild(tooltip, unit, content.showGuild and true or false) then
        resized = true
    end
    if ApplyTarget(tooltip, unit, content.showTarget and true or false) then
        resized = true
    end
    if resized then
        tooltip:Show()
    end
end

function ns.Content.Hook()
    if ns.Content.hooked then
        return
    end
    ns.Content.hooked = true

    local function applyFromOwner(tooltip)
        if tooltip ~= GameTooltip then
            return
        end
        local owner = tooltip.GetOwner and tooltip:GetOwner()
        ns.Content.Apply(tooltip, ns.Classify.FromTooltip(tooltip, owner))
    end

    if GameTooltip then
        GameTooltip:HookScript("OnShow", applyFromOwner)
    end
    HookHealthBar(StatusBarFor(GameTooltip) or _G.GameTooltipStatusBar)

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        local all = TooltipDataProcessor.AllTypes
        if all then
            TooltipDataProcessor.AddTooltipPostCall(all, applyFromOwner)
        elseif Enum and Enum.TooltipDataType then
            local types = Enum.TooltipDataType
            local keys = { "Unit", "Item", "Spell", "UnitAura", "Object", "Quest", "MinimapMouseover" }
            for i = 1, #keys do
                local dataType = types[keys[i]]
                if dataType then
                    TooltipDataProcessor.AddTooltipPostCall(dataType, applyFromOwner)
                end
            end
        end
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:SetScript("OnEvent", function()
        if GameTooltip and GameTooltip:IsShown() then
            applyFromOwner(GameTooltip)
        end
    end)
end
