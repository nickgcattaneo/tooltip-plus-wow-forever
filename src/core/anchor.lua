local ADDON_NAME, ns = ...

ns.Anchor = ns.Anchor or {}

local applying = false
local cursorOffsets = setmetatable({}, { __mode = "k" })

local function IsCursorAnchor(anchor)
    return anchor == "ANCHOR_CURSOR"
        or anchor == "ANCHOR_CURSOR_RIGHT"
        or anchor == "ANCHOR_CURSOR_LEFT"
end

-- Built-in ANCHOR_CURSOR ignores x/y offsets. Place the tip ourselves.
local function PlaceAtCursor(tooltip, offsetX, offsetY)
    if not tooltip or not tooltip.SetPoint then
        return
    end
    local x, y = GetCursorPosition()
    local scale = tooltip.GetEffectiveScale and tooltip:GetEffectiveScale() or 1
    if not scale or scale == 0 then
        scale = 1
    end
    tooltip:ClearAllPoints()
    tooltip:SetPoint(
        "BOTTOMLEFT",
        UIParent,
        "BOTTOMLEFT",
        (x / scale) + (offsetX or 0),
        (y / scale) + (offsetY or 0)
    )
end

local function OnCursorUpdate(self)
    local pos = cursorOffsets[self]
    if not pos or applying then
        return
    end
    if self.IsShown and not self:IsShown() then
        cursorOffsets[self] = nil
        return
    end
    PlaceAtCursor(self, pos.offsetX, pos.offsetY)
end

local function EnsureCursorHook(tooltip)
    if tooltip._ttPlusCursorHooked then
        return
    end
    tooltip._ttPlusCursorHooked = true
    if tooltip.HookScript then
        tooltip:HookScript("OnUpdate", OnCursorUpdate)
        tooltip:HookScript("OnHide", function(self)
            cursorOffsets[self] = nil
        end)
    end
end

local function OwnNone(tooltip, parent)
    local owner = parent
    if not owner and tooltip.GetOwner then
        owner = tooltip:GetOwner()
    end
    if not owner then
        owner = UIParent
    end
    local currentOwner
    if tooltip.GetOwner then
        currentOwner = tooltip:GetOwner()
    end
    local currentAnchor
    if tooltip.GetAnchorType then
        currentAnchor = tooltip:GetAnchorType()
    end
    if currentOwner == owner and currentAnchor == "ANCHOR_NONE" then
        return
    end
    tooltip:SetOwner(owner, "ANCHOR_NONE")
end

local function ApplyMode(tooltip, parent, position)
    local mode = position.mode or "cursor"

    applying = true
    if mode == "cursor" then
        local x = position.offsetX or 0
        local y = position.offsetY or 0
        OwnNone(tooltip, parent)
        cursorOffsets[tooltip] = { offsetX = x, offsetY = y }
        EnsureCursorHook(tooltip)
        PlaceAtCursor(tooltip, x, y)
    else
        cursorOffsets[tooltip] = nil
        if mode == "corner" then
            local corner = position.corner
            if not ns.CORNERS[corner] then
                corner = ns.DEFAULT_POSITION.corner
            end
            tooltip:SetOwner(parent, "ANCHOR_NONE")
            tooltip:ClearAllPoints()
            tooltip:SetPoint(corner, UIParent, corner, position.offsetX or 0, position.offsetY or 0)
        elseif mode == "point" then
            tooltip:SetOwner(parent or UIParent, "ANCHOR_NONE")
            tooltip:ClearAllPoints()
            tooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", position.pointX or 0, position.pointY or 0)
        end
    end
    applying = false
end

function ns.Anchor.Apply(tooltip, parent, forcedType)
    if not tooltip or applying then
        return
    end

    local typeId = forcedType or ns.Classify.FromTooltip(tooltip, parent)
    if not typeId then
        cursorOffsets[tooltip] = nil
        return
    end
    local resolved = ns.Resolve(typeId)
    if not resolved.enabled then
        cursorOffsets[tooltip] = nil
        return
    end

    ApplyMode(tooltip, parent, resolved.position)
end

function ns.Anchor.OnDefault(tooltip, parent)
    ns.Anchor.Apply(tooltip, parent)
end

function ns.Anchor.OnSetOwner(tooltip, owner, anchor)
    if applying or tooltip ~= GameTooltip then
        return
    end
    -- SetDefaultAnchor calls SetOwner(ANCHOR_NONE) then SetPoint. Re-owning
    -- in the middle of that breaks cursor tracking. Handle that path in
    -- OnDefault after the helper finishes.
    if not anchor or anchor == "ANCHOR_NONE" or IsCursorAnchor(anchor) then
        return
    end
    ns.Anchor.Apply(tooltip, owner)
end

if type(GameTooltip_SetDefaultAnchor) == "function" then
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        ns.Anchor.OnDefault(tooltip, parent)
    end)
end

if GameTooltip and GameTooltip.SetOwner then
    hooksecurefunc(GameTooltip, "SetOwner", function(tooltip, owner, anchor)
        ns.Anchor.OnSetOwner(tooltip, owner, anchor)
    end)
end
